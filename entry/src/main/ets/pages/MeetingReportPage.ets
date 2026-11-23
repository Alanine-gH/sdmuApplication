import { router } from '@kit.ArkUI';
import { webview } from '@kit.ArkWeb';
import { pasteboard } from '@kit.BasicServicesKit';
import { TitleBar } from '../components/TitleBar';
import { LoadingView } from '../components/LoadingView';
import { ApiService, NewsWebViewHeaders } from '../network/ApiService';
import { ApiResponse } from '../model/ResponseModel';
import { BusinessError } from '@kit.BasicServicesKit';
import { MeetingReportEntity } from '../model/MeetingApiModel';
import { Constants } from '../data/Constants';
import { BreakpointSystem } from '../common/BreakpointSystem';

/**
 * 会议报告页 — MeetingReportShowActivity.java(463行) 源码级翻译
 * 【源码链路】MeetingDetailActivity.e.d.c()（底栏"会议报告"）→ bundle{HYID, isCreator, canEdit,
 *   isCancel, switchState(IS_SHOW 非空才放)} → g0=/meeting/report。
 * 【布局】mobile_campus_meeting_activity_report.xml：toolbar + MultiStateView + reportWebview
 *   （WebView layoutWeight 1）+ layoutReport（gone 默认；canEdit && !isCancel 显示）：
 *   白底 49vp（px_to_dip_98）0.5 分隔线 + tvSituation"编辑会议报告"16fp 主色 + edit 图标
 *   drawablePadding 4。
 * 【toolbar】toolBar_text_but="删除"（compound 左 delete 图标，canEdit 才可见）+
 *   toolBar_image_but=share（恒显）+ toolBar_icon_but=开关（switchState 非空才可见，
 *   初始 report_open/report_close 按 "1".equals(w)）。
 * 【WebView】f1 → b3()（showMeetingReport {meetingXLH=HYID} 存 r）+ h3()（JS 开启）+ e3()：
 *   url = netconstant.d.d() + "/mobileapi_ydxy/open/meeting/share/" + HYID；
 *   headers = Access-Token（4字段明文 k.m → c.i(token, 协商key) AES，getNewsPageWebViewHeaders
 *   等价复用）+ Unique-Code（onlyCode）+ AppType=ydxy（W1 免登链同源，NewsPage 同款 WebHeader）。
 * 【分享 e.onClick】X2() isCancel → "当前会议已被取消"；Y2() 报告空（MEETING_CONTENT/PIC 均 null）
 *   → "当前会议报告内容为空"；否则剪贴板复制 l+HYID + "分享链接已经复制到粘贴板" +
 *   系统分享（HAP：pasteboard 复制 + toast；系统 chooser 无等价 API 保留复制语义）。
 * 【删除 d.onClick】Y2() 拦截 → "您确定删除当前文档？"确认 → Z2() = p.Y(new b).L(q) →
 *   MeetingModel.j1 POST delMeetingReport {meetingXLH} → data!=STATUS_TRUE("1") → "会议报告删除失败"
 *   （实测无报告会议 data=false）；否则 "会议报告删除成功" + q2 空态 + b3() + e3()。
 * 【开关 f.onClick】X2() 拦截；!s(isCreator) → "当前用户不能进行该操作"；否则 f3(w=="0"?"1":"0")
 *   → openMeetingReport {meetingId, openType:"on"/"off"}（h.g "0".equals(code) 成功）→
 *   g3 + "开启，会议报告内容所有人可见"/"关闭，会议报告内容均不可见"。
 * 【编辑入口】layoutReport 点击 d3()：r!=null → bundle{HYID, MEETING_CONTENT, PIC, MEETING_XLH,
 *   STATE} → MeetingReportEditPage；返回（onActivityResult(1)）→ b3()+e3() 刷新。
 * 【返回】onBackPressed → setResult(switchState)（详情页 150 分支写回 IS_SHOW，HAP=AppStorage）。
 * 【接口实测】showMeetingReport 无报告会议 code=0001（真实空态）；delMeetingReport 无效 xlh
 *   data=false；openMeetingReport 无效 openType code=开放会议报告给参会人员失败（f→toast）。
 * 【数据规则】禁止 mock：WebView 渲染服务器分享页，无编造报告文本。
 */
@Entry
@Component
struct MeetingReportPage {
  /** 报告数据（源码 r，仅存内存供编辑页传参与空判定） */
  @State report: MeetingReportEntity = new MeetingReportEntity();
  /** 报告已拉取过（源码 r!=null） */
  @State reportLoaded: boolean = false;
  /** 开关状态（源码 w） */
  @State switchState: string = '';
  /** 开关图标（源码 g3：true=open false=close） */
  @State switchOpen: boolean = false;
  @State loading: boolean = true;
  /** 删除确认弹窗（framework dialog.g） */
  @State showDeleteDialog: boolean = false;
  @StorageProp('currentBreakpoint') currentBreakpoint: string = 'sm';
  @StorageProp('windowWidthVp') windowWidthVp: number = 360;
  @StorageProp('windowHeightVp') windowHeightVp: number = 780;
  private hyid: string = '';
  private isCreator: boolean = false;
  private canEdit: boolean = false;
  private isCancel: boolean = true;
  private webController: webview.WebviewController = new webview.WebviewController();
  private shareUrlBase: string = Constants.SOCKET_HOST + '/mobileapi_ydxy/open/meeting/share/';

  aboutToAppear(): void {
    // 源码 y(intent)：q=HYID、s=isCreator、x=canEdit、v=isCancel（默认 true）、w=switchState
    const params: object | undefined = router.getParams() as object | undefined;
    if (params !== null && params !== undefined) {
      const record = params as Record<string, Object>;
      this.hyid = MeetingReportPage.pickStr(record, ['HYID']);
      this.isCreator = MeetingReportPage.pickBool(record, ['isCreator']);
      this.canEdit = MeetingReportPage.pickBool(record, ['canEdit']);
      this.isCancel = MeetingReportPage.pickBool(record, ['isCancel'], true);
      const sw: Object | undefined = record['switchState'];
      if (typeof sw === 'string') {
        this.switchState = sw as string;
      }
    }
    // 源码 T1：switchState 非空 → 开关图标可见 + 初始图标
    if (this.switchState !== '') {
      this.switchOpen = this.switchState === '1';
    }
    this.loadReport();
    this.loadWebView();
  }

  /** 源码 onActivityResult(1) 等价：编辑页返回 → b3()+e3() 刷新 */
  onPageShow(): void {
    const edited: boolean | undefined = AppStorage.get<boolean>('meeting_report_edited');
    if (edited === true) {
      AppStorage.setOrCreate('meeting_report_edited', false);
      this.loadReport();
      this.loadWebView();
    }
  }

  /** 返回前回写开关状态（源码 onBackPressed setResult(switchState)，详情页 150 分支读） */
  private backWithState(): void {
    AppStorage.setOrCreate('meeting_report_switch_state', this.switchState);
    router.back();
  }

  /** 物理返回键同源码 onBackPressed：回写 switchState 后放行系统返回 */
  onBackPress(): boolean {
    AppStorage.setOrCreate('meeting_report_switch_state', this.switchState);
    return false;
  }

  /** 源码 b3()：p.a0(new a).M(q) → MeetingModel.k1 GET showMeetingReport {meetingXLH=HYID} */
  private loadReport(): void {
    ApiService.showMeetingReport(this.hyid)
      .then((response: ApiResponse<MeetingReportEntity>) => {
        if (response.code === 1000) {
          // 登录失效统一处理已在网络层触发
          this.loading = false;
          return;
        }
        if (response.code === 0) {
          // 源码 a.g()：r = report（无 toast 无状态切换）
          this.report = response.data;
          this.reportLoaded = true;
        } else {
          // 源码 a.f/a.b 空实现：失败静默（r 保持 null）
          this.reportLoaded = false;
        }
        this.loading = false;
      })
      .catch((error: BusinessError) => {
        ApiService.logError('MeetingReportPage loadReport fail: ' + error.message);
        this.loading = false;
      });
  }

  /** 源码 e3()：headers(AT 4字段 AES + Unique-Code) → loadUrl(l + HYID)（AppType 由免登页自身处理） */
  private loadWebView(): void {
    if (this.hyid === '') {
      return;
    }
    ApiService.getNewsPageWebViewHeaders()
      .then((headers: NewsWebViewHeaders | null) => {
        if (headers === null) {
          this.loading = false;
          return;
        }
        const headersArr: webview.WebHeader[] = [
          { headerKey: 'Access-Token', headerValue: headers.accessToken },
          { headerKey: 'Unique-Code', headerValue: headers.uniqueCode },
          { headerKey: 'AppType', headerValue: 'ydxy' }
        ];
        this.webController.loadUrl(this.shareUrlBase + this.hyid, headersArr);
      })
      .catch((error: BusinessError) => {
        ApiService.logError('MeetingReportPage loadWebView fail: ' + error.message);
        this.loading = false;
      });
  }

  /** 源码 X2()：isCancel → "当前会议已被取消" */
  private cancelledBlocked(): boolean {
    if (this.isCancel) {
      this.toast('当前会议已被取消');
      return true;
    }
    return false;
  }

  /** 源码 Y2()：r.MEETING_CONTENT/PIC 均 null → "当前会议报告内容为空" */
  private emptyReportBlocked(): boolean {
    if (this.report.MEETING_CONTENT === '' && this.report.PIC === '' && !this.reportLoaded) {
      this.toast('当前会议报告内容为空');
      return true;
    }
    return false;
  }

  /** 源码 e.onClick（share）：拦截 → 剪贴板复制 + "分享链接已经复制到粘贴板" + 系统分享 */
  private onShareClick(): void {
    if (this.cancelledBlocked() || this.emptyReportBlocked()) {
      return;
    }
    const link: string = this.shareUrlBase + this.hyid;
    const systemPasteboard: pasteboard.SystemPasteboard = pasteboard.getSystemPasteboard();
    systemPasteboard.setData(pasteboard.createPlainTextData(link));
    this.toast('分享链接已经复制到粘贴板');
    // 源码续段：Intent.createChooser 系统分享面板（HAP 无通用 chooser API，保留复制语义）
  }

  /** 源码 d.onClick（删除）：Y2 拦截 → 确认弹窗 */
  private onDeleteClick(): void {
    if (this.emptyReportBlocked()) {
      return;
    }
    this.showDeleteDialog = true;
  }

  /** 源码 Z2() → MeetingModel.j1：POST delMeetingReport {meetingXLH} */
  private submitDelete(): void {
    ApiService.delMeetingReport(this.hyid)
      .then((response: ApiResponse<Object>) => {
        if (response.code === 1000) {
          return;
        }
        if (response.code === 0 && ApiService.meetingReportDataOk(response.data)) {
          // 源码 b.g()：m("会议报告删除成功") + q2 空态 + b3() + e3()
          this.toast('会议报告删除成功');
          this.loadReport();
          this.loadWebView();
        } else if (response.code === 0) {
          this.toast('会议报告删除失败');
        } else {
          this.toast(response.message === '' ? '会议报告删除失败' : response.message);
        }
      })
      .catch((error: BusinessError) => {
        ApiService.logError('MeetingReportPage delete fail: ' + error.message);
        this.toast('会议报告删除失败');
      });
  }

  /** 源码 f.onClick（开关）：X2 拦截 → 非本人拦截 → f3(翻转值) */
  private onSwitchClick(): void {
    if (this.cancelledBlocked()) {
      return;
    }
    if (!this.isCreator) {
      this.toast('当前用户不能进行该操作');
      return;
    }
    const next: string = this.switchState === '0' ? '1' : '0';
    this.submitSwitch(next);
  }

  /** 源码 f3(str)：p.f0(new h).P(q, openType on/off) → openMeetingReport {meetingId, openType} */
  private submitSwitch(next: string): void {
    if (next === '') {
      return;
    }
    const openType: string = next === '1' ? 'on' : 'off';
    ApiService.openMeetingReport(this.hyid, openType)
      .then((response: ApiResponse<Object>) => {
        if (response.code === 1000) {
          return;
        }
        if (response.code === 0) {
          // 源码 h.g()："0".equals(code) → g3 + w=新值 + toast
          this.switchOpen = next === '1';
          this.switchState = next;
          this.toast(next === '1' ? '开启，会议报告内容所有人可见' : '关闭，会议报告内容均不可见');
        } else {
          // 源码 h.f(str2)：toast 服务器文案（实测无效 openType code=开放会议报告给参会人员失败）
          this.toast(response.message === '' ? '操作失败' : response.message);
        }
      })
      .catch((error: BusinessError) => {
        ApiService.logError('MeetingReportPage switch fail: ' + error.message);
        this.toast('操作失败');
      });
  }

  /** 源码 d3()：r!=null → bundle{HYID, MEETING_CONTENT, PIC, MEETING_XLH, STATE} → 编辑页 */
  private openReportEdit(): void {
    const params: Record<string, Object> = {
      'HYID': this.hyid,
      'MEETING_CONTENT': this.report.MEETING_CONTENT,
      'PIC': this.report.PIC,
      'MEETING_XLH': this.report.MEETING_XLH,
      'STATE': this.report.STATE
    };
    this.pushRoute('pages/MeetingReportEditPage', params);
  }

  private pushRoute(url: string, params: Record<string, Object>): void {
    try {
      router.pushUrl({ url: url, params: params }).catch((error: BusinessError) => {
        ApiService.logError('MeetingReportPage route fail @' + url + ': ' + error.message);
      });
    } catch (error) {
      const err = error as BusinessError;
      ApiService.logError('MeetingReportPage route throw @' + url + ': ' + err.message);
    }
  }

  private toast(message: string): void {
    this.getUIContext().getPromptAction().showToast({ message: message });
  }

  private static pickStr(record: Record<string, Object>, keys: string[]): string {
    for (const key of keys) {
      const v: Object | undefined = record[key];
      if (typeof v === 'string') {
        return v as string;
      }
      if (typeof v === 'number') {
        return String(v as number);
      }
    }
    return '';
  }

  private static pickBool(record: Record<string, Object>, keys: string[], def: boolean = false): boolean {
    for (const key of keys) {
      const v: Object | undefined = record[key];
      if (typeof v === 'boolean') {
        return v as boolean;
      }
      if (typeof v === 'string') {
        return (v as string) === 'true';
      }
    }
    return def;
  }

  // 登录失效统一处理已下沉网络层（HttpClient.bizRequest code=1000 拦截），页面 1000 分支只 return

  build() {
    Stack() {
      Column() {
        TitleBar({ title: '会议报告', showBack: true, onBack: (): void => {
          this.backWithState();
        } })
        // toolbar 右按钮组（toolBar_icon_but 开关 / toolBar_image_but share / toolBar_text_but 删除，
        // Toolbar 内 right gravity 子项按声明序从右往左排：icon_but 最左 → share → 删除最右）
        Row() {
          if (this.switchState !== '') {
            Image(this.switchOpen ? $r('app.media.mobile_campus_meeting_report_open')
              : $r('app.media.mobile_campus_meeting_report_close'))
              .width(20)
              .height(20)
              .margin({ right: 14 })
              .onClick(() => {
                this.onSwitchClick();
              })
          }
          Image($r('app.media.mobile_campus_meeting_share'))
            .width(20)
            .height(20)
            .margin({ right: 14 })
            .onClick(() => {
              this.onShareClick();
            })
          if (this.canEdit) {
            Row() {
              Image($r('app.media.mobile_campus_meeting_delete'))
                .width(14)
                .height(14)
                .margin({ right: 4 })
              Text('删除')
                .fontSize(16)
                .fontColor($r('app.color.common_color_1'))
            }
            .alignItems(VerticalAlign.Center)
            .margin({ right: 15 })
            .onClick(() => {
              this.onDeleteClick();
            })
          }
        }
        .height(44)
        .alignItems(VerticalAlign.Center)

        // reportWebview：WebView layoutWeight 1（JS 开启，源码 h3）
        if (this.loading) {
          LoadingView()
        } else {
          Web({ src: 'about:blank', controller: this.webController })
            .javaScriptAccess(true)
            .domStorageAccess(true)
            .verticalScrollBarAccess(false)
            .width('100%')
            .layoutWeight(1)
            .onControllerAttached(() => {
              this.loadWebView();
            })
        }

        // layoutReport：canEdit && !isCancel → 白底 49vp（0.5 分隔线 + 编辑会议报告 16fp 主色）
        if (this.canEdit && !this.isCancel) {
          Column() {
            Divider()
              .color($r('app.color.common_color_5'))
              .strokeWidth(0.5)
              .width('100%')
            Row() {
              Image($r('app.media.mobile_campus_meeting_edit'))
                .width(16)
                .height(16)
                .margin({ right: 4 })
              Text('编辑会议报告')
                .fontSize(16)
                .fontColor($r('app.color.mobile_campus_primary_color_default'))
            }
            .width('100%')
            .height(48.5)
            .justifyContent(FlexAlign.Center)
            .onClick(() => {
              this.openReportEdit();
            })
          }
          .width('100%')
          .height(49)
          .backgroundColor($r('app.color.white'))
        }
      }
      .width('100%')
      .height('100%')
      .alignItems(HorizontalAlign.Start)

      // "您确定删除当前文档？"（源码 framework dialog.g）
      if (this.showDeleteDialog) {
        this.deleteDialog()
      }
    }
    .width('100%')
    .height('100%')
    .alignContent(Alignment.Center)
  }

  /** 删除确认弹窗（源码 dialog.g：a()=Z2() 执行删除） */
  @Builder
  deleteDialog() {
    Column() {
      Scroll() {
        Column() {
          Text('您确定删除当前文档？')
            .fontSize(17)
            .fontColor($r('app.color.common_color_1'))
            .margin({ top: 16, bottom: 16 })
          Divider()
            .color($r('app.color.common_color_5'))
            .strokeWidth(0.5)
            .width('100%')
          Row() {
            Text('取消')
              .fontSize(17)
              .fontColor($r('app.color.common_color_3'))
              .textAlign(TextAlign.Center)
              .layoutWeight(1)
              .height(44)
              .hoverEffect(HoverEffect.Highlight)
              .onClick(() => {
                this.showDeleteDialog = false;
              })
            Divider()
              .vertical(true)
              .color($r('app.color.common_color_5'))
              .strokeWidth(0.5)
              .height(44)
            Text('确定')
              .fontSize(17)
              .fontColor($r('app.color.mobile_campus_primary_color_default'))
              .textAlign(TextAlign.Center)
              .layoutWeight(1)
              .height(44)
              .hoverEffect(HoverEffect.Highlight)
              .onClick(() => {
                this.showDeleteDialog = false;
                this.submitDelete();
              })
          }
          .width('100%')
          .alignItems(VerticalAlign.Center)
        }
        .width('100%')
        .alignItems(HorizontalAlign.Center)
      }
      .scrollBar(BarState.Off)
      .width(BreakpointSystem.getDialogMaxWidth(this.currentBreakpoint, this.windowWidthVp))
      .constraintSize({ maxHeight: BreakpointSystem.getDialogMaxHeight(this.windowHeightVp) })
      .borderRadius(8)
      .backgroundColor($r('app.color.white'))
      .clip(true)
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
      this.showDeleteDialog = false;
    })
  }
}
