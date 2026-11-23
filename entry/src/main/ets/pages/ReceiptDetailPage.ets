import { router } from '@kit.ArkUI';
import { common } from '@kit.AbilityKit';
import { image } from '@kit.ImageKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { ApiService } from '../network/ApiService';
import { ApiResponse } from '../model/ResponseModel';
import { ReimburseProjectDetail } from '../model/ContactModel';
import { TitleBar } from '../components/TitleBar';
import { EmptyView } from '../components/EmptyView';
import { LoadingView } from '../components/LoadingView';
import { PrivacyWindowHelper } from '../common/PrivacyWindowHelper';
import { BarcodeHelper } from '../common/BarcodeHelper';
import { BreakpointSystem } from '../common/BreakpointSystem';
import { AdaptiveLayoutHelper } from '../common/AdaptiveLayoutHelper';

/**
 * 报销项目详情页 — 源码级翻译 [P-C placeholder]（ProjectDetailActivity.java 逐行 → ArkTS）：
 *
 * 【考证结论】APK manifest 无 ReceiptDetailActivity；入口 ProgramListPage:81"查看项目详情"
 *   跳 /reimburse/detail{PROJECT_NUMBER}（ARouter$$Group$$reimburse.java:18）→
 *   com.lysoft.android.lyyd.reimburse.view.ProjectDetailActivity（manifest L416）。
 *   同模块另有 ProjectDetailActivityV2=/new_reimburse/detail（L430，另一路由，非本入口）与
 *   AchievementListActivity=/reimburse/achievement（L417，成果列表，非本入口）→ 排除，定案 ProjectDetailActivity。
 * 【布局】mobile_campus_reimburse_activity_project_detail.xml：toolbar_normal（T1 gVar.n("项目详情")）
 *   + MultiStateView（empty_view/error_view/loading_view）内竖排 LinearLayout
 *   padding L/R=36px→18vp、T/B=42px→21vp；8 行 label 14sp #333 + value 14sp #999 ml12vp，行距 mt12vp。
 * 【字段映射】a.g（8 TextView）：
 *   项目名称=PROJECT_NAME / 项目分类=PROJECT_TYPE / 项目成员=PROJECT_MEMBER /
 *   项目状态=PROJECT_STATUS / 合同金额=(空?"0":CONTRACT_AMOUNT)+" 元" /
 *   到账金额=(空?"0":RECEIVE_AMOUNT)+" 元" / 支付金额=(空?"0":PAY_AMOUNT)+" 元" /
 *   外拨金额=(空?"0":OUTSIDE_AMOUNT)+" 元"。
 * 【数据】y(intent) v=PROJECT_NUMBER → R2() → ReimburseModel.T0（reimburse/d/b.java）→
 *   ReimburseFactory b()="project" f12640d="detail" → e.d POST /api/project/detail {PROJECT_NUMBER}；
 *   a.g→content / a.f→EMPTY / a.e→ERROR。
 * 【探针】probe_p_c_placeholder.py：POST body HTTP200 空体、GET data= code=0001（假号业务错误，
 *   端点存活）；ProgramListPage 实测本账号 reimbursement rows=0 → 无真实项目 → 真实空态，不编造详情。
 */

@Entry
@Component
struct ReceiptDetailPage {
  @State detail: ReimburseProjectDetail | null = null;
  @State isLoading: boolean = true;
  @State showError: boolean = false;
  @State projectNumber: string = '';
  @State showQrModal: boolean = false;
  @State qrPixelMap: image.PixelMap | null = null;
  @State qrLoading: boolean = false;
  @State qrSaving: boolean = false;
  @StorageProp('currentBreakpoint') currentBreakpoint: string = 'sm';
  @StorageProp('windowWidthVp') windowWidthVp: number = 360;
  @StorageProp('windowHeightVp') windowHeightVp: number = 780;
  @StorageProp('avoidAreaBottomVp') avoidAreaBottomVp: number = 0;

  aboutToAppear(): void {
    const params: object | undefined = router.getParams() as object | undefined;
    if (params !== undefined && params !== null) {
      const rec: Record<string, Object> = params as Record<string, Object>;
      const v: Object = rec['PROJECT_NUMBER'];
      if (typeof v === 'string') { this.projectNumber = v as string; }
    }
    this.loadDetail();
  }

  onPageShow(): void {
    const ctx = this.getUIContext().getHostContext() as common.UIAbilityContext;
    PrivacyWindowHelper.enterSensitivePage('ReceiptDetailPage', ctx);
  }

  onPageHide(): void {
    const ctx = this.getUIContext().getHostContext() as common.UIAbilityContext;
    PrivacyWindowHelper.leaveSensitivePage('ReceiptDetailPage', ctx);
  }

  aboutToDisappear(): void {
    this.releaseQrPixelMap();
    const ctx = this.getUIContext().getHostContext() as common.UIAbilityContext;
    PrivacyWindowHelper.leaveSensitivePage('ReceiptDetailPage', ctx);
  }

  private releaseQrPixelMap(): void {
    if (this.qrPixelMap !== null) {
      const pm: image.PixelMap = this.qrPixelMap;
      this.qrPixelMap = null;
      try {
        pm.release();
      } catch {
        // 忽略释放异常
      }
    }
  }

  private closeQrModal(): void {
    this.showQrModal = false;
    if (!this.qrSaving) {
      this.releaseQrPixelMap();
    }
  }

  private async openProjectQrModal(): Promise<void> {
    if (this.detail === null) {
      this.getUIContext().getPromptAction().showToast({ message: '暂无项目详情' });
      return;
    }
    const d: ReimburseProjectDetail = this.detail;
    const payload: string = BarcodeHelper.buildProjectQrPayload(
      this.projectNumber,
      d.PROJECT_NAME,
      d.PROJECT_TYPE,
      d.PROJECT_STATUS,
      this.money(d.CONTRACT_AMOUNT),
      this.money(d.RECEIVE_AMOUNT),
      this.money(d.PAY_AMOUNT)
    );
    if (payload === '') {
      this.getUIContext().getPromptAction().showToast({ message: '暂无项目二维码内容' });
      return;
    }
    this.releaseQrPixelMap();
    this.qrLoading = true;
    this.showQrModal = true;
    const res = await BarcodeHelper.generateQrPixelMap(payload, 480);
    this.qrLoading = false;
    if (!this.showQrModal) {
      if (res.pixelMap !== null) {
        try {
          res.pixelMap.release();
        } catch {
          // 忽略释放异常
        }
      }
      return;
    }
    if (res.success && res.pixelMap !== null) {
      this.qrPixelMap = res.pixelMap;
    } else {
      this.showQrModal = false;
      this.getUIContext().getPromptAction().showToast({ message: res.message });
    }
  }

  private async saveQrToGallery(): Promise<void> {
    if (this.qrPixelMap === null || this.qrSaving) {
      return;
    }
    this.qrSaving = true;
    try {
      const ctx = this.getUIContext().getHostContext() as common.Context;
      const res = await BarcodeHelper.savePixelMapToGallery(ctx, this.qrPixelMap);
      this.getUIContext().getPromptAction().showToast({ message: res.message });
    } finally {
      this.qrSaving = false;
      if (!this.showQrModal) {
        this.releaseQrPixelMap();
      }
    }
  }

  /** 源码 f1()→R2()：l.g(a).d(PROJECT_NUMBER) → ReimburseModel.T0 project/detail */
  private loadDetail(): void {
    this.isLoading = true;
    this.showError = false;
    ApiService.getProjectDetail(this.projectNumber)
      .then((response: ApiResponse<ReimburseProjectDetail>) => {
        this.isLoading = false;
        if (response.code !== 0 || response.data.PROJECT_NAME === '') {
          this.showError = true;
          return;
        }
        this.detail = response.data;
      })
      .catch((error: BusinessError) => {
        this.isLoading = false;
        this.showError = true;
        ApiService.logError('ReceiptDetailPage load fail: ' + error.message);
      });
  }

  /** 源码 a.g：TextUtils.isEmpty(金额) ? "0" : 金额，后拼 " 元" */
  private money(raw: string): string {
    return (raw === '' ? '0' : raw) + ' 元';
  }

  build() {
    Stack() {
      Column() {
        // T1：项目详情
        TitleBar({
          title: '项目详情',
          showBack: true,
          rightText: '二维码',
          onRightClick: () => {
            this.openProjectQrModal();
          }
        })

        if (this.isLoading) {
          LoadingView()
        } else if (this.showError || this.detail === null) {
          EmptyView({ tipText: '暂无项目详情' })
        } else {
          Scroll() {
            Column() {
              this.detailRow('项目名称', (this.detail as ReimburseProjectDetail).PROJECT_NAME)
              this.detailRow('项目分类', (this.detail as ReimburseProjectDetail).PROJECT_TYPE, 12)
              this.detailRow('项目成员', (this.detail as ReimburseProjectDetail).PROJECT_MEMBER, 12)
              this.detailRow('项目状态', (this.detail as ReimburseProjectDetail).PROJECT_STATUS, 12)
              this.detailRow('合同金额',
                this.money((this.detail as ReimburseProjectDetail).CONTRACT_AMOUNT), 12)
              this.detailRow('到账金额',
                this.money((this.detail as ReimburseProjectDetail).RECEIVE_AMOUNT), 12)
              this.detailRow('支付金额',
                this.money((this.detail as ReimburseProjectDetail).PAY_AMOUNT), 12)
              this.detailRow('外拨金额',
                this.money((this.detail as ReimburseProjectDetail).OUTSIDE_AMOUNT), 12)
            }
            .width('100%')
            .constraintSize({ maxWidth: BreakpointSystem.getContentMaxWidth(this.currentBreakpoint) })
            .padding({ left: 18, right: 18, top: 21, bottom: Math.max(21, this.avoidAreaBottomVp + 12) })
          }
          .scrollBar(BarState.Off)
          .layoutWeight(1)
        }
      }
      .width('100%').height('100%')
      .backgroundColor($r('app.color.white'))

      if (this.showQrModal) {
        this.projectQrOverlay()
      }
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  projectQrOverlay() {
    Column() {
      Scroll() {
        Column() {
          Row() {
            Text('报销项目二维码')
              .fontSize(17)
              .fontWeight(FontWeight.Medium)
              .fontColor($r('app.color.common_color_1'))
              .layoutWeight(1)
            Text('关闭')
              .fontSize(15)
              .fontColor('#3A92ED')
              .padding({ left: 8, right: 4, top: 4, bottom: 4 })
              .onClick(() => {
                this.closeQrModal();
              })
          }
          .width('100%')

          if (this.detail !== null) {
            Text((this.detail as ReimburseProjectDetail).PROJECT_NAME)
              .fontSize(15)
              .fontWeight(FontWeight.Bold)
              .fontColor($r('app.color.common_color_1'))
              .margin({ top: 10 })
              .maxLines(2)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
          }

          if (this.qrLoading) {
            LoadingProgress()
              .width(42)
              .height(42)
              .margin({ top: 40, bottom: 40 })
          } else if (this.qrPixelMap !== null) {
            Image(this.qrPixelMap)
              .width(200)
              .height(200)
              .objectFit(ImageFit.Contain)
              .margin({ top: 14, bottom: 10 })
              .backgroundColor($r('app.color.white'))
          }

          Text('扫码查看项目经费与报销摘要')
            .fontSize(12)
            .fontColor($r('app.color.common_color_3'))
            .margin({ bottom: 14 })

          if (this.qrPixelMap !== null) {
            SaveButton({
              icon: SaveIconStyle.FULL_FILLED,
              text: SaveDescription.SAVE_TO_GALLERY,
              buttonType: ButtonType.Capsule
            })
              .height(38)
              .fontSize(14)
              .fontColor($r('app.color.white'))
              .iconColor($r('app.color.white'))
              .backgroundColor('#3A92ED')
              .padding({ left: 18, right: 18 })
              .onClick((_event: ClickEvent, result: SaveButtonOnClickResult) => {
                if (result === SaveButtonOnClickResult.SUCCESS) {
                  this.saveQrToGallery();
                } else {
                  this.getUIContext().getPromptAction().showToast({ message: '未获得保存授权' });
                }
              })
          }
        }
        .width('100%')
        .alignItems(HorizontalAlign.Center)
        .padding({ left: 20, right: 20, top: 16, bottom: 20 })
      }
      .scrollBar(BarState.Off)
      .width(AdaptiveLayoutHelper.getDialogMaxWidth(this.currentBreakpoint, this.windowWidthVp))
      .constraintSize({ maxHeight: AdaptiveLayoutHelper.getDialogMaxHeight(this.windowHeightVp) })
      .backgroundColor($r('app.color.white'))
      .borderRadius(12)
      .onClick(() => {
        // 拦截弹窗内点击
      })
    }
    .width('100%')
    .height('100%')
    .padding({ left: 16, right: 16 })
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .backgroundColor('#66000000')
    .onClick(() => {
      this.closeQrModal();
    })
  }

  @Builder
  detailRow(label: string, value: string, top: number = 0) {
    Row() {
      Text(label)
        .fontSize(14)
        .fontColor($r('app.color.common_color_1'))
      Text(value)
        .fontSize(14)
        .fontColor($r('app.color.common_color_3'))
        .margin({ left: 12 })
        .layoutWeight(1)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
    }
    .width('100%')
    .margin({ top: top })
    .alignItems(VerticalAlign.Center)
  }
}
