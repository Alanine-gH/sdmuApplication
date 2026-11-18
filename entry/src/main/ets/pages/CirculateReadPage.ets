import { router } from '@kit.ArkUI';
import { ApiService } from '../network/ApiService';
import { ApiResponse } from '../model/ResponseModel';
import { OaSubDeptUser } from '../model/OaTodoModel';
import { TitleBar } from '../components/TitleBar';
import { BusinessError } from '@kit.BasicServicesKit';

/**
 * 传阅页 — 源码级翻译（W23，原空占位重写）：
 * APK CirculateReadActivity（oa/todo/view，ARouter /todo/CirculateRead = base.e.a.M）。
 *
 * 【入口】TodoDetailActivity g 类"传阅"按钮 bundle{processId, docUnid}（HAP 上游 TodoDetailPage
 *   未翻译，管道 AppStorage 'circulate_nav' = JSON {processId, docUnid} 就绪，无编造入口）。
 * 【布局】mobile_campus_oa_activity_circulate_read.xml：
 *   toolbar"流程处理"（T1 gVar.n）+ 24 灰条 + MultiStateView（ScrollView[CopyViewLayout mCopyView]
 *   + tvCirculateRead BLTextView 226dip×44dip 右下角，XML enabled=false）。
 *   CopyViewLayout 默认标题"抄送人员"（源码无 setTitleText 调用）+ GridRecyclerView + imgDelete。
 * 【数据流源码还原】
 *   b 类添加 → CarbonCopyListActivity multiUserPicker {bmdm:"", mode, currentSize=A.p(),
 *   routeName} rc121 → onActivityResult list → A.addData + size>0 → m.setEnabled(true)。
 *   c 类选择变化 → tvCirculateRead.setEnabled(A.getAdapter().m() > 0)。
 *   imgDelete（>3 显示）→ 清空新加。
 *   a 类提交：processId/docUnid 空 return；n() 选中空 return；userInfos=逐人 "GH#BMDM,"
 *   拼接去尾 → TodoPImpl.q(map) → TodoModel.W0 POST circulate {processId, docUnid, userInfos}
 *   （2026-11-18 实测假参 0001 系统异常=端点存活）→ 成功 "传阅成功"+finish / 失败 "传阅失败"。
 * 【禁 mock】circulate 真实接口；无上游入口时页面可见但按钮禁用（真实语义）。
 */
interface CirculateNavParams {
  processId: string;
  docUnid: string;
}

const COPY_SEPARATOR: string = ',';

@Entry
@Component
struct CirculateReadPage {
  @State users: OaSubDeptUser[] = [];
  @State canSubmit: boolean = false;
  private nav: CirculateNavParams = { processId: '', docUnid: '' };

  aboutToAppear(): void {
    // 源码 y(Intent)：processId/docUnid（HAP 管道 AppStorage 'circulate_nav'）
    const json: string | undefined = AppStorage.get<string>('circulate_nav');
    if (json !== undefined && json !== '') {
      try {
        const rec: Record<string, Object> = JSON.parse(json) as Record<string, Object>;
        this.nav.processId = this.strOf(rec, 'processId');
        this.nav.docUnid = this.strOf(rec, 'docUnid');
      } catch (error) {
        const err = error as BusinessError;
        ApiService.logError('CirculateRead parse nav fail: ' + err.message);
      }
      return;
    }
    const params: Record<string, Object> | undefined = router.getParams() as Record<string, Object> | undefined;
    if (params !== undefined && params !== null) {
      this.nav.processId = this.strOf(params, 'processId');
      this.nav.docUnid = this.strOf(params, 'docUnid');
    }
  }

  private strOf(rec: Record<string, Object>, key: string): string {
    const v: Object = rec[key];
    if (typeof v === 'string') {
      return v as string;
    }
    if (typeof v === 'number') {
      return String(v as number);
    }
    return '';
  }

  onPageShow(): void {
    // 源码 onActivityResult(121)：添加返回 list → A.addData + size>0 → enabled
    const result: string | undefined = AppStorage.get<string>('oa_copy_result');
    if (result !== undefined && result !== '') {
      AppStorage.setOrCreate<string>('oa_copy_result', '');
      try {
        const parsed: Object = JSON.parse(result) as Object;
        for (const one of ApiService.extractArray(parsed)) {
          this.users.push(OaSubDeptUser.fromRecord(ApiService.asRecord(one)));
        }
        this.canSubmit = this.users.length > 0;
      } catch (error) {
        const err = error as BusinessError;
        ApiService.logError('CirculateRead consume result fail: ' + err.message);
      }
    }
  }

  /** 源码 b 类：添加 → CarbonCopyListPage multiUserPicker（bmdm 空、无 processId/userFilterNodeId） */
  private openUserPicker(): void {
    router.pushUrl({ url: 'pages/CarbonCopyListPage',
      params: {
        'bmdm': '',
        'mode': 'multiUserPicker',
        'currentSize': String(this.users.length)
      } as Record<string, string> });
  }

  /** 源码 CopyViewLayout.a 类：imgDelete 清空（i()：全部 isSelected=false + 清列表） */
  private clearUsers(): void {
    this.users = [];
    this.canSubmit = false;
  }

  /** 源码 c 类：选择变化 → setEnabled(m() > 0) */
  private toggleUser(index: number): void {
    const u: OaSubDeptUser | undefined = this.users[index];
    if (u === undefined) {
      return;
    }
    u.isSelected = !u.isSelected;
    this.users = this.users.slice();
    this.canSubmit = this.selectedUsers().length > 0;
  }

  /** 源码 TodoProcedureAdapter.n()：选中项 */
  private selectedUsers(): OaSubDeptUser[] {
    const out: OaSubDeptUser[] = [];
    for (const u of this.users) {
      if (u.isSelected) {
        out.push(u);
      }
    }
    return out;
  }

  /** 源码 a 类提交：userInfos = "GH#BMDM," 拼接去尾 → circulate POST */
  private submitCirculate(): void {
    if (this.nav.processId === '' || this.nav.docUnid === '') {
      return;
    }
    const selected: OaSubDeptUser[] = this.selectedUsers();
    if (selected.length === 0) {
      return;
    }
    let userInfos: string = '';
    for (const u of selected) {
      userInfos = userInfos + u.GH + '#' + u.BMDM + COPY_SEPARATOR;
    }
    if (userInfos.length > 0) {
      userInfos = userInfos.substring(0, userInfos.length - 1);
    }
    ApiService.circulateOaTodo(this.nav.processId, this.nav.docUnid, userInfos)
      .then((response: ApiResponse<Object>) => {
        if (response.code === 1000) {
          return;
        }
        if (response.code === 0) {
          this.toast('传阅成功');
          this.getUIContext().getRouter().back();
        } else {
          this.toast('传阅失败');
        }
      })
      .catch((error: BusinessError) => {
        ApiService.logError('circulate fail: ' + error.message);
        this.toast('传阅失败');
      });
  }

  private toast(message: string): void {
    this.getUIContext().getPromptAction().showToast({ message: message });
  }

  build() {
    Column() {
      TitleBar({ title: '流程处理', showBack: true })
      Divider().color($r('app.color.common_color_5')).strokeWidth(0.5)
      Stack({ alignContent: Alignment.BottomEnd }) {
        Scroll() {
          Column() {
            this.copyArea()
          }
          .width('100%')
        }
        .scrollBar(BarState.Off)
        .width('100%')
        .height('100%')

        Text('传阅')
          .fontSize(17)
          .fontColor($r('app.color.white'))
          .backgroundColor(this.canSubmit ? $r('app.color.mobile_campus_primary_color_default')
            : $r('app.color.mobile_campus_schedule_color12'))
          .width(113)
          .height(44)
          .textAlign(TextAlign.Center)
          .margin({ right: 0, bottom: 0 })
          .onClick(() => {
            if (this.canSubmit) {
              this.submitCirculate();
            }
          })
      }
      .width('100%')
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.white'))
  }

  /** CopyViewLayout（默认标题"抄送人员"） */
  @Builder
  copyArea() {
    Column() {
      Row() {
        Image($r('app.media.mobile_campus_oa_nextapprover'))
          .width(16)
          .height(16)
          .margin({ right: 12 })
        Text('抄送人员')
          .fontSize(15)
          .fontColor($r('app.color.mobile_campus_schedule_color11'))
          .layoutWeight(1)
        if (this.users.length > 3) {
          Image($r('app.media.mobile_campus_oa_issue_clean'))
            .width(18)
            .height(18)
            .padding(4)
            .margin({ right: 16 })
            .onClick(() => {
              this.clearUsers();
            })
        }
      }
      .width('100%')
      .padding({ left: 13, right: 13, top: 10, bottom: 10 })
      .alignItems(VerticalAlign.Center)

      Divider().color($r('app.color.common_color_5')).strokeWidth(0.5)

      Grid() {
        ForEach(this.users, (u: OaSubDeptUser, index: number) => {
          GridItem() {
            Column() {
              Stack() {
                Text(u.XM.length > 0 ? u.XM.substring(0, 1) : '')
                  .fontSize(18.5)
                  .fontColor($r('app.color.white'))
                  .width(38)
                  .height(38)
                  .textAlign(TextAlign.Center)
                  .borderRadius(19)
                  .backgroundColor($r('app.color.mobile_campus_primary_color_default'))
                if (u.isSelected) {
                  Text('✓')
                    .fontSize(10)
                    .fontColor($r('app.color.white'))
                    .width(16)
                    .height(16)
                    .textAlign(TextAlign.Center)
                    .borderRadius(8)
                    .backgroundColor('#4CD964')
                    .margin({ top: 2, left: 26 })
                }
              }
              .width(48)
              .height(48)
              .alignContent(Alignment.TopStart)

              Text(u.XM)
                .fontSize(12)
                .fontColor($r('app.color.common_color_1'))
                .margin({ top: 8 })
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
                .width(56)
                .textAlign(TextAlign.Center)
            }
            .alignItems(HorizontalAlign.Center)
            .onClick(() => {
              this.toggleUser(index);
            })
          }
        }, (u: OaSubDeptUser, index: number) => index + '_' + u.GH + '_' + String(u.isSelected))

        GridItem() {
          Column() {
            Image($r('app.media.mobile_campus_oa_addto_white'))
              .width(38)
              .height(38)
              .borderRadius(19)
              .backgroundColor($r('app.color.mobile_campus_primary_color_default'))
              .objectFit(ImageFit.Contain)
            Text('添加')
              .fontSize(12)
              .fontColor('#B2BDC9')
              .margin({ top: 8 })
          }
          .alignItems(HorizontalAlign.Center)
          .onClick(() => {
            this.openUserPicker();
          })
        }
        .visibility(this.users.length < 200 ? Visibility.Visible : Visibility.None)
      }
      .columnsTemplate('1fr 1fr 1fr 1fr 1fr')
      .rowsGap(8)
      .padding(12)
      .width('100%')
      .height(this.users.length <= 5 ? 100 : 174)

      Column()
        .width('100%')
        .height(12)
        .backgroundColor('#F2F2F2')
    }
    .width('100%')
    .backgroundColor($r('app.color.white'))
  }
}
