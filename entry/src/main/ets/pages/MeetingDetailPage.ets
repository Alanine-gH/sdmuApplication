import { router } from '@kit.ArkUI';
import { common, Want } from '@kit.AbilityKit';
import { scanBarcode, scanCore } from '@kit.ScanKit';
import { PdfView, pdfService, pdfViewManager } from '@kit.PDFKit';
import { ApiService } from '../network/ApiService';
import { ApiResponse } from '../model/ResponseModel';
import { BusinessError, pasteboard } from '@kit.BasicServicesKit';
import { call } from '@kit.TelephonyKit';
import { LiveViewIntentHelper } from '../common/LiveViewIntentHelper';
import { FilePreviewHelper } from '../common/FilePreviewHelper';
import { BreakpointSystem } from '../common/BreakpointSystem';
import { AdaptiveLayoutHelper } from '../common/AdaptiveLayoutHelper';
import { ImmersiveLightHelper } from '../common/ImmersiveLightHelper';
import { NluEntityHelper, NluEntityChip } from '../common/NluEntityHelper';
import { ReminderCalendarHelper } from '../common/ReminderCalendarHelper';
import { LoadingView } from '../components/LoadingView';
import { EmptyView } from '../components/EmptyView';
import { MeetingObjEntity, MeetingAttachmentEntity, MeetingExtraEntity,
  MeetingExtraDataEntity } from '../model/MeetingApiModel';
import { LoginSession } from '../network/LoginSession';

/**
 * 会议详情页 — MeetingDetailActivity.java(585行) 源码级翻译
 * 【源码链路】MeetingPage 子项点击（bundle {xlh, TASK_TYPE}）→ MeetingDetailActivity.y(intent)：
 *   q=TASK_TYPE、p=xlh（appInfo.XLH 或 xlh）→ f1() → p3() = MeetingPImpl.X → MeetingModel.c1：
 *   GET getMeetingObj {xlh} → MeetingObj。
 * 【布局】mobile_campus_meeting_activity_detail.xml：toolbar + MultiStateView(#F2F2F2)
 *   + ScrollView(detailView + detailFileView marginTop 12) + layoutBottom 底栏。
 * 【detailView】mobile_campus_meeting_view_weekplan_detail.xml：tvTitle(19fp) + 取消态
 *   （STATUS=0 → imgCancel 61×61 + tvCancelContent=QXLY #FF6666；STATUS=1 且本人发起 → btnCancel
 *   "取消" #C80D28 → MeetingEditeDialog"取消会议理由"→ cancelMeeting{meetingXLH,cancel_remark}）
 *   + 行项（非空才加）：会议地点(ADDRESS)/会议时间(KSSJ\nJSSJ)/举办单位(JBDW)/主持人(ZCR)/联系人(LXR)/
 *   联系电话(LXRDH)/参会领导(CHLD 判空+值取 LXRDH 源码原样)/参会人员(CHRY maxLines 7)/外部人员(FNBRY)。
 * 【底栏】IS_JOIN==2 → view_attend_choose_btn（不参加→MeetingEditeDialog"请填写不参会理由"→
 *   upJoin{xlh,zt:"0",reason}；参加→upJoin{xlh,zt:"1"}）；否则 view_detail_report_btn
 *   （查看参会情况→f0；会议报告→g0；公告 badge=findMeetingFeedBack 计数，feedBackType 空→隐藏）。
 *   meetingReportType="0" 或（非本人且空）→隐藏报告；三项全隐藏→无底栏。
 * 【右上图标】本人发起 → mobile_campus_meeting_qrcode → MeetingSignPage{HYID}；否则 scan →
 *   ScanKit 起扫（等价 ScanBookQRNewActivity）→ MeetingAttendPage{result}；
 *   STATUS=0 或 TASK_TYPE=past_meeting → 隐藏（源码 b.g()）。
 * 【接口实测】getMeetingObj/getJoinList/getPastList 管道通（probe_w13_meeting_series*.py）；
 *   测试账号 join/past 组无真实会议 → 数据空走真实空态，不编造。
 */
@Entry
@Component
struct MeetingDetailPage {
  /** 详情数据（源码 v） */
  @State obj: MeetingObjEntity = new MeetingObjEntity();
  /** 是否本人发起（IS_CURRENT_USER_PLAN=="1"） */
  @State isCreator: boolean = false;
  /** 公告角标数（源码 t.o(count)，>99 显示 99+） */
  @State noticeCount: number = -1;
  /** 空态/错误态（接口失败或无数据） */
  @State loadFail: boolean = false;
  @State loading: boolean = true;
  /** 取消会议弹窗（MeetingEditeDialog） */
  @State showCancelDialog: boolean = false;
  @State cancelReason: string = '由于临时原因取消会议。';
  /** 不参会理由弹窗 */
  @State showNoAttendDialog: boolean = false;
  @State noAttendReason: string = '';
  @State downloadingAttach: boolean = false;
  @State showPdfModal: boolean = false;
  @State pdfTitle: string = '';
  @State pendingPdfPath: string = '';
  @State nluEntities: NluEntityChip[] = [];
  @StorageProp('currentBreakpoint') currentBreakpoint: string = 'sm';
  @StorageProp('isCompactHeight') isCompactHeight: boolean = false;
  @StorageProp('windowWidthVp') windowWidthVp: number = 360;
  @StorageProp('windowHeightVp') windowHeightVp: number = 780;
  @StorageProp('avoidAreaLeftVp') avoidAreaLeftVp: number = 0;
  @StorageProp('avoidAreaRightVp') avoidAreaRightVp: number = 0;
  @StorageProp('avoidAreaBottomVp') avoidAreaBottomVp: number = 0;
  private xlh: string = '';
  private taskType: string = '';
  private nluRequestToken: number = 0;
  private pdfController: pdfViewManager.PdfController = new pdfViewManager.PdfController();

  aboutToDisappear(): void {
    this.closePdfModal();
  }

  private closePdfModal(): void {
    this.pendingPdfPath = '';
    if (this.showPdfModal) {
      this.showPdfModal = false;
      try {
        this.pdfController.releaseDocument();
      } catch {
        // 忽略释放异常
      }
    }
  }

  private async loadPendingPdf(): Promise<void> {
    const path: string = this.pendingPdfPath;
    if (path === '') {
      return;
    }
    try {
      const parseRes = await this.pdfController.loadDocument(path);
      if (parseRes !== pdfService.ParseResult.PARSE_SUCCESS) {
        this.toast('PDF 文档解析失败');
      }
    } catch {
      this.toast('PDF 文档加载失败');
    }
  }

  private async openAttachment(att: MeetingAttachmentEntity): Promise<void> {
    if (att.DOWNLOAD_URL === '') {
      this.toast('附件下载地址为空');
      return;
    }
    if (this.downloadingAttach) {
      return;
    }
    this.downloadingAttach = true;
    this.toast('正在加载附件...');
    try {
      const ctx = this.getUIContext().getHostContext() as common.UIAbilityContext;
      const res = await FilePreviewHelper.downloadAndPreview(ctx, att.DOWNLOAD_URL, att.FILENAME, 'meeting');
      if (res.success) {
        return;
      }
      if (res.method === 'pdfView' && res.localPath !== '') {
        this.pendingPdfPath = res.localPath;
        this.pdfTitle = att.FILENAME;
        this.showPdfModal = true;
        return;
      }
      if (res.message !== '') {
        this.toast(res.message);
      }
    } finally {
      this.downloadingAttach = false;
    }
  }

  aboutToAppear(): void {
    // 源码 y(intent)：p = intent "xlh"（无 appInfo 序列化通道，HAP 直传 xlh）
    const params: object | undefined = router.getParams() as object | undefined;
    if (params !== null && params !== undefined) {
      const record = params as Record<string, Object>;
      const v: Object | undefined = record['xlh'];
      if (typeof v === 'string') {
        this.xlh = v as string;
      }
      const t: Object | undefined = record['TASK_TYPE'];
      if (typeof t === 'string') {
        this.taskType = t as string;
      }
    }
    this.loadDetail();
  }

  /** 公告/参会情况/报告页返回刷新（源码 onActivityResult(151)/(100)/(150) 等价） */
  onPageShow(): void {
    // 151：公告返回 → t.o(meetingNotice) 角标刷新
    if (this.obj.HYID !== '' && this.obj.feedBackType !== '') {
      this.loadNoticeCount();
    }
    // 100：参会情况返回 → 底栏重建 + 本人发起 q3()（JOIN→NO_JOIN 本人移动）+ p3() 重拉详情
    const staffChanged: boolean | undefined = AppStorage.get<boolean>('meeting_staff_changed');
    if (staffChanged === true) {
      AppStorage.setOrCreate('meeting_staff_changed', false);
      this.moveSelfJoinToNoJoin();
      this.loadDetail();
    }
    // 150：报告返回 → switchState 写回 v.IS_SHOW
    const switchState: string | undefined = AppStorage.get<string>('meeting_report_switch_state');
    if (switchState !== undefined && switchState !== '') {
      AppStorage.setOrCreate('meeting_report_switch_state', '');
      this.obj.IS_SHOW = switchState;
    }
  }

  /** 源码 q3()：本人发起 → EXTRA 中 JOIN_LIST 的本人行移入 NO_JOIN_LIST（本地联动） */
  private moveSelfJoinToNoJoin(): void {
    const extras: MeetingExtraEntity[] = this.obj.EXTRA;
    let selfRow: MeetingExtraDataEntity | null = null;
    for (const group of extras) {
      if (group.TYPE === 'JOIN_LIST' && selfRow === null) {
        for (let i = 0; i < group.DATA.length; i++) {
          if (group.DATA[i].YHID === LoginSession.userId) {
            selfRow = group.DATA[i];
            group.DATA.splice(i, 1);
            break;
          }
        }
        if (selfRow !== null) {
          break;
        }
      }
    }
    if (selfRow !== null) {
      for (const group of extras) {
        if (group.TYPE === 'NO_JOIN_LIST') {
          group.DATA.push(selfRow);
          return;
        }
      }
    }
  }

  /** 源码 p3()：l.X(new b).E(p) → GET getMeetingObj {xlh} */
  private loadDetail(): void {
    if (this.xlh === '') {
      this.loadFail = true;
      this.loading = false;
      return;
    }
    ApiService.getMeetingObj(this.xlh)
      .then((response: ApiResponse<MeetingObjEntity>) => {
        if (response.code === 1000) {
          // 登录失效统一处理已在网络层触发（HttpClient.bizRequest 拦截：清会话+toast+跳登录）
          this.loadFail = true;
          this.loading = false;
          return;
        }
        if (response.code === 0 && response.data.TITLE !== '') {
          this.obj = response.data;
          this.isCreator = this.obj.IS_CURRENT_USER_PLAN === '1';
          this.loadFail = false;
          this.extractMeetingEntities();
          // 源码 l3()：feedBackType 非空 → o3() 拉公告角标
          if (this.obj.feedBackType !== '') {
            this.loadNoticeCount();
          }
        } else {
          this.loadFail = true;
        }
        this.loading = false;
      })
      .catch((error: BusinessError) => {
        ApiService.logError('MeetingDetailPage loadDetail fail: ' + error.message);
        this.loadFail = true;
        this.loading = false;
      });
  }

  private async extractMeetingEntities(): Promise<void> {
    this.nluEntities = [];
    this.nluRequestToken += 1;
    const token: number = this.nluRequestToken;
    const source: string = NluEntityHelper.buildMeetingNluSource(
      this.obj.TITLE,
      this.obj.ADDRESS,
      this.obj.KSSJ,
      this.obj.JSSJ,
      this.obj.LXR,
      this.obj.LXRDH
    );
    const result = await NluEntityHelper.extractEntities(source);
    if (token !== this.nluRequestToken) {
      return;
    }
    this.nluEntities = result.entities;
  }

  private async onEntityChipTap(chip: NluEntityChip): Promise<void> {
    if (chip.action === 'calendar') {
      const ctx = this.getUIContext().getHostContext() as common.UIAbilityContext;
      const startMs: number = chip.timestampMs !== null ? chip.timestampMs : Date.now() + 3600000;
      const endMs: number = startMs + 3600000;
      const calRes = await ReminderCalendarHelper.addCalendarEventWithResult(
        ctx,
        this.obj.TITLE !== '' ? this.obj.TITLE : '会议日程',
        chip.text,
        startMs,
        endMs,
        this.obj.ADDRESS
      );
      if (calRes.success) {
        this.toast(calRes.message);
        return;
      }
      if (startMs > Date.now()) {
        const remRes = await ReminderCalendarHelper.publishCalendarReminderWithResult(
          this.obj.TITLE !== '' ? this.obj.TITLE : '会议提醒',
          chip.text,
          new Date(startMs),
          ctx
        );
        this.toast(remRes.success ? remRes.message : (remRes.message || calRes.message));
        return;
      }
      this.toast(calRes.message);
      return;
    }
    if (chip.action === 'dial') {
      try {
        call.makeCall(chip.text, () => {
        });
      } catch {
        this.toast('无法拉起拨号');
      }
      return;
    }
    if (chip.action === 'email') {
      const ctx = this.getUIContext().getHostContext() as common.UIAbilityContext;
      try {
        ctx.startAbility({
          action: 'mailto:' + chip.text,
          entities: ['entity.system.default'],
          parameters: { 'email': [chip.text] }
        } as Want).catch(() => {
          this.toast('请安装邮箱应用');
        });
      } catch {
        this.toast('请安装邮箱应用');
      }
      return;
    }
    if (chip.action === 'url') {
      const lower: string = chip.text.toLowerCase();
      const targetUrl: string = (lower.startsWith('http://') || lower.startsWith('https://'))
        ? chip.text
        : 'https://' + chip.text;
      this.pushRoute('pages/WebViewPage', { 'url': targetUrl, 'title': '网页详情' });
      return;
    }
    if (chip.action === 'location') {
      try {
        const data: pasteboard.PasteData = pasteboard.createData(pasteboard.MIMETYPE_TEXT_PLAIN, chip.text);
        await pasteboard.getSystemPasteboard().setData(data);
        this.toast('已复制地点：' + chip.text);
      } catch {
        this.toast('复制地点失败');
      }
    }
  }

  /** 源码 o3()：l.W(new a).D(v.HYID) → POST findMeetingFeedBack {meetingId}（仅取 size 作角标） */
  private loadNoticeCount(): void {
    ApiService.findMeetingFeedback(this.obj.HYID)
      .then((response: ApiResponse<Object[]>) => {
        if (response.code === 0) {
          this.noticeCount = response.data.length;
        } else {
          this.noticeCount = -1;
        }
      })
      .catch((error: BusinessError) => {
        ApiService.logError('MeetingDetailPage loadNoticeCount fail: ' + error.message);
        this.noticeCount = -1;
      });
  }

  /** 源码 WeekPlanDetailView.setData：STATUS="1" 且本人发起 → btnCancel 弹取消理由 */
  private showCancelDialogIfAllowed(): void {
    if (this.obj.STATUS === '1' && this.isCreator) {
      this.cancelReason = '由于临时原因取消会议。';
      this.showCancelDialog = true;
    }
  }

  /** 源码 g.a → MeetingModel.W0：POST cancelMeeting {meetingXLH, cancel_remark} */
  private submitCancelMeeting(): void {
    if (this.cancelReason.trim() === '') {
      this.toast('请填写取消会议的理由！');
      return;
    }
    ApiService.cancelMeeting(this.obj.HYID, this.cancelReason)
      .then((response: ApiResponse<string>) => {
        if (response.code === 0) {
          this.toast('取消成功！');
          this.showCancelDialog = false;
          this.loadDetail();
        } else {
          this.toast(response.message === '' ? '取消失败！' : response.message);
        }
      })
      .catch((error: BusinessError) => {
        ApiService.logError('MeetingDetailPage cancelMeeting fail: ' + error.message);
        this.toast('取消失败！');
      });
  }

  /** 源码 r3(zt, reason)：l.i0(new i).p0(p, zt, reason) → POST upJoin {xlh,zt,reason} */
  private submitJoinState(zt: string, reason: string): void {
    ApiService.upJoinMeeting(this.xlh, zt, reason)
      .then((response: ApiResponse<string>) => {
        if (response.code === 0) {
          if (zt === '1') {
            this.toast('参会提交成功');
          }
          this.showNoAttendDialog = false;
          // 源码 i.g()：移除底栏视图后 p3() 重拉详情
          this.obj.IS_JOIN = 0;
          this.loadDetail();
        } else {
          this.toast(response.message === '' ? '提交失败' : response.message);
        }
      })
      .catch((error: BusinessError) => {
        ApiService.logError('MeetingDetailPage upJoin fail: ' + error.message);
        this.toast('提交失败');
      });
  }

  /** 源码 f.a.confirm：不参会必须填理由（"请填写不参会理由"） */
  private submitNoAttend(): void {
    if (this.noAttendReason.trim() === '') {
      this.toast('请填写不参会理由');
      return;
    }
    this.submitJoinState('0', this.noAttendReason);
  }

  /** 源码 c.onClick：本人发起 → MeetingSignPage{HYID}(e0)；否则起扫码（ScanBookQRNewActivity 等价） */
  private onToolbarIconClick(): void {
    if (this.isCreator) {
      this.pushRoute('pages/MeetingSignPage', { 'HYID': this.obj.HYID });
      return;
    }
    const options: scanBarcode.ScanOptions = { scanTypes: [scanCore.ScanType.QR_CODE] };
    scanBarcode.startScan(options)
      .then((result: scanBarcode.ScanResult) => {
        // 源码 onActivityResult(415)：result → g2(d0) → MeetingAttendActivity{result}
        this.pushRoute('pages/MeetingAttendPage', { 'result': result.originalValue });
      })
      .catch((error: BusinessError) => {
        ApiService.logError('MeetingDetailPage startScan fail: ' + error.message);
      });
  }

  /** 源码 e.d.a()：公告 badge 点击 → h0 bundle{canRelease, meetingId, meetingTitle} */
  private openAnnouncement(): void {
    this.pushRoute('pages/MeetingAnnouncementPage', {
      'canRelease': this.obj.feedBackType === '1' && this.obj.STATUS === '1',
      'meetingId': this.obj.HYID,
      'meetingTitle': this.obj.TITLE
    });
  }

  /** 源码 e.d.b()：查看参会情况 → f0 bundle{xlh, HYID} + i.e.a.k(EXTRA) 静态共享（HAP=AppStorage） */
  private openStaffSituation(): void {
    // 源码 i.e.a.k(MeetingDetailActivity.this.v.EXTRA)：参会人员列表经静态内存共享给参会情况页
    AppStorage.setOrCreate('meeting_staff_changed', false);
    AppStorage.setOrCreate('meeting_staff_extra', JSON.stringify(this.obj.EXTRA));
    this.pushRoute('pages/MeetingStaffSituationPage', { 'xlh': this.xlh, 'HYID': this.obj.HYID });
  }

  /** 源码 e.d.c()：会议报告 → g0 bundle{HYID, isCreator, canEdit, isCancel, switchState} */
  private openMeetingReport(): void {
    this.pushRoute('pages/MeetingReportPage', {
      'HYID': this.obj.HYID,
      'isCreator': this.isCreator,
      'canEdit': (this.isCreator && this.obj.meetingReportType === '') || this.obj.meetingReportType === '2',
      'isCancel': this.obj.STATUS === '0',
      'switchState': this.obj.IS_SHOW === '' ? '' : this.obj.IS_SHOW
    });
  }

  /** 底栏三区可见性（源码 l3 + n()：全隐藏 → 不渲染底栏） */
  private showReportBar(): boolean {
    const noticeVisible: boolean = this.obj.feedBackType !== '';
    const detailVisible: boolean = this.isCreator || this.obj.feedBackType === '1';
    const reportVisible: boolean = this.obj.meetingReportType !== '0'
      && (this.isCreator || this.obj.meetingReportType !== '');
    return noticeVisible || detailVisible || reportVisible;
  }

  /** 源码 b.g()：STATUS=0 或 TASK_TYPE=past_meeting → 右上图标隐藏 */
  private showToolbarIcon(): boolean {
    return this.obj.STATUS !== '0' && this.taskType !== 'past_meeting';
  }

  /** FNBRY 拆分（源码 WeekPlanDetailMultiItemView：;分隔多段，无 ; 单段） */
  private externalPersons(): string[] {
    if (this.obj.FNBRY === '') {
      return [];
    }
    if (this.obj.FNBRY.indexOf(';') >= 0) {
      return this.obj.FNBRY.split(';');
    }
    return [this.obj.FNBRY];
  }

  private pushRoute(url: string, params: Record<string, Object>): void {
    try {
      router.pushUrl({ url: url, params: params }).catch((error: BusinessError) => {
        ApiService.logError('MeetingDetailPage route fail @' + url + ': ' + error.message);
      });
    } catch (error) {
      const err = error as BusinessError;
      ApiService.logError('MeetingDetailPage route throw @' + url + ': ' + err.message);
    }
  }

  private toast(message: string): void {
    this.getUIContext().getPromptAction().showToast({ message: message });
  }

  // ===== UI =====

  build() {
    Stack() {
      Column() {
        this.topBar()
        if (this.loading) {
          LoadingView()
        } else if (this.loadFail || this.obj.TITLE === '') {
          EmptyView({ tipText: '暂无会议详情' })
        } else {
          this.contentView()
        }
      }
      .width('100%')
      .height('100%')
      .alignItems(HorizontalAlign.Center)

      // MeetingEditeDialog 复刻：带遮罩与自适应宽度
      if (this.showCancelDialog || this.showNoAttendDialog) {
        this.editDialog()
      }

      if (this.showPdfModal) {
        this.pdfPreviewOverlay()
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.mobile_campus_bg_color'))
    .alignContent(Alignment.Center)
  }

  @Builder
  topBar() {
    Column() {
      Row() {
        Text('＜')
          .fontSize(17)
          .fontColor($r('app.color.common_color_1'))
          .width(34)
          .height(34)
          .textAlign(TextAlign.Center)
          .margin({ left: 15 })
          .borderRadius(17)
          .systemMaterial(ImmersiveLightHelper.pillMaterial())
          .clickEffect({ level: ClickEffectLevel.LIGHT, scale: 0.94 })
          .hoverEffect(HoverEffect.Highlight)
          .onClick(() => {
            router.back();
          })
        Text('会议详情')
          .fontSize(17)
          .fontColor($r('app.color.common_color_1'))
          .layoutWeight(1)
          .textAlign(TextAlign.Center)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        Row({ space: 6 }) {
          Text('实况窗')
            .fontSize(14)
            .fontColor($r('app.color.black'))
            .padding({ left: 8, right: 8, top: 4, bottom: 4 })
            .borderRadius(14)
            .systemMaterial(ImmersiveLightHelper.pillMaterial())
            .clickEffect({ level: ClickEffectLevel.LIGHT, scale: 0.95 })
            .hoverEffect(HoverEffect.Highlight)
            .onClick(() => {
              LiveViewIntentHelper.startLocalLiveView(
                1001,
                this.obj.TITLE || '会议提醒',
                (this.obj.KSSJ || '') + ' ' + (this.obj.ADDRESS || '')
              ).then((ok: boolean) => {
                this.toast(ok ? '已开启会议实况窗' : '当前设备暂不支持实况窗');
              });
            })
          if (this.showToolbarIcon() && !this.loading && !this.loadFail) {
            Image(this.isCreator ? $r('app.media.mobile_campus_meeting_qrcode')
              : $r('app.media.mobile_campus_meeting_scan'))
              .width(22)
              .height(22)
              .hoverEffect(HoverEffect.Highlight)
              .onClick(() => {
                this.onToolbarIconClick();
              })
          }
        }
        .margin({ right: 12 })
        .alignItems(VerticalAlign.Center)
      }
      .width('100%')
      .height(this.isCompactHeight ? 37 : 44)
      .padding({
        left: this.avoidAreaLeftVp > 0 ? this.avoidAreaLeftVp : 0,
        right: this.avoidAreaRightVp > 0 ? this.avoidAreaRightVp : 0
      })
      .alignItems(VerticalAlign.Center)
      .backgroundColor($r('app.color.main_bg'))
      .constraintSize({ maxWidth: BreakpointSystem.getContentMaxWidth(this.currentBreakpoint) })
      .alignSelf(ItemAlign.Center)

      Divider()
        .color($r('app.color.common_color_5'))
        .strokeWidth(0.5)
        .width('100%')
        .constraintSize({ maxWidth: BreakpointSystem.getContentMaxWidth(this.currentBreakpoint) })
        .alignSelf(ItemAlign.Center)
    }
    .width('100%')
    .height(this.isCompactHeight ? 38 : 45)
    .backgroundColor($r('app.color.main_bg'))
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP])
  }

  /** mobile_campus_meeting_activity_detail.xml：ScrollView(detailView+detailFileView) + layoutBottom */
  @Builder
  contentView() {
    Column() {
      Scroll() {
        Column() {
          this.detailView()
          if (this.nluEntities.length > 0) {
            this.nluEntitySection()
          }
          this.fileView()
        }
        .width('100%')
        .constraintSize({ maxWidth: BreakpointSystem.getContentMaxWidth(this.currentBreakpoint) })
        .padding({ bottom: 12 })
        .alignItems(HorizontalAlign.Start)
      }
      .width('100%')
      .layoutWeight(1)
      .scrollBar(BarState.Off)
      .align(Alignment.Top)

      if (this.obj.STATUS === '0' && !this.isCreator) {
        // 源码 b.g() 末段：取消的会议非发起人 → r.removeAllViews()（底栏整体移除）
      } else if (this.obj.IS_JOIN === 2) {
        this.attendChooseBar()
      } else if (this.showReportBar()) {
        this.reportBar()
      }
    }
    .width('100%')
    .layoutWeight(1)
    .alignItems(HorizontalAlign.Center)
  }

  /** mobile_campus_meeting_view_weekplan_detail.xml：标题区（≤50 行规范拆分入口） */
  @Builder
  detailView() {
    Column() {
      this.detailHeader()
      Divider()
        .color($r('app.color.mobile_campus_bg_color'))
        .strokeWidth(0.5)
        .width('100%')
      this.detailRows()
    }
    .width('100%')
  }

  /** 标题 + 取消态（STATUS=0 → imgCancel+QXLY）/ 取消按钮（STATUS=1 本人发起） */
  @Builder
  detailHeader() {
    Stack({ alignContent: Alignment.TopEnd }) {
      Column() {
        Row() {
          Text(this.obj.TITLE)
            .fontSize(19)
            .fontColor($r('app.color.common_color_1'))
            .maxLines(2)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .layoutWeight(1)
          if (this.obj.STATUS === '1' && this.isCreator) {
            Text('取消')
              .fontSize(14)
              .fontColor('#C80D28')
              .padding({ left: 12, right: 12, top: 5, bottom: 5 })
              .margin({ left: 10 })
              .borderRadius(16)
              .border({ width: 0.5, color: '#C80D28' })
              .hoverEffect(HoverEffect.Highlight)
              .onClick(() => {
                this.showCancelDialogIfAllowed();
              })
          }
        }
        .width('100%')
        .padding({ left: 18, right: 18, top: 19, bottom: 15 })
        .alignItems(VerticalAlign.Center)

        if (this.obj.STATUS === '0') {
          Text(this.obj.QXLY)
            .fontSize(13)
            .fontColor('#FF6666')
            .padding({ left: 18, right: 76, bottom: 12 })
        }
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)

      if (this.obj.STATUS === '0') {
        Image($r('app.media.mobile_campus_meeting_cancel'))
          .width(61)
          .height(61)
          .margin({ right: 12, top: 4 })
      }
    }
    .width('100%')
    .backgroundColor($r('app.color.white'))
  }

  /** 行项列表（非空才加）：地点/时间/举办单位/主持人/联系人/电话/参会领导/参会人员/外部人员 */
  @Builder
  detailRows() {
    Column() {
      if (this.obj.ADDRESS !== '') {
        this.detailRow($r('app.media.mobile_campus_meeting_local_2'), '会议地点', this.obj.ADDRESS, false, 1)
      }
      if (this.obj.KSSJ !== '' && this.obj.JSSJ !== '') {
        this.detailRow($r('app.media.mobile_campus_meeting_time_2'), '会议时间',
          this.obj.KSSJ + '\n' + this.obj.JSSJ, false, 1)
      }
      if (this.obj.JBDW !== '') {
        this.detailRow($r('app.media.mobile_campus_meeting_class'), '举办单位', this.obj.JBDW, false, 1)
      }
      if (this.obj.ZCR !== '') {
        // 源码：主持人行 topMargin 12dip
        this.detailRow($r('app.media.mobile_campus_meeting_staff'), '主持人', this.obj.ZCR, false, 2)
      }
      if (this.obj.LXR !== '') {
        this.detailRow($r('app.media.mobile_campus_meeting_contacts'), '联系人', this.obj.LXR, false, 1)
      }
      if (this.obj.LXRDH !== '') {
        this.detailRow($r('app.media.mobile_campus_meeting_contact_number'), '联系电话', this.obj.LXRDH, true, 1)
      }
      if (this.obj.CHLD !== '') {
        // 源码原样：参会领导行判空用 CHLD，值取 LXRDH.replace("\n","")
        this.detailRow($r('app.media.mobile_campus_meeting_staff'), '参会领导',
          this.obj.LXRDH.replace('\n', ''), false, 1)
      }
      if (this.obj.CHRY !== '') {
        this.detailRow($r('app.media.mobile_campus_meeting_staff'), '参会人员',
          this.obj.CHRY.replace('\n', ''), false, 7)
      }
      if (this.obj.FNBRY !== '' && this.obj.FNBRY !== 'null') {
        Column() {
          ForEach(this.externalPersons(), (person: string) => {
            this.detailRow($r('app.media.mobile_campus_meeting_staff'), '外部人员', person, false, 1)
          }, (person: string) => 'fnbry_' + person)
        }
        .width('100%')
      }
    }
    .width('100%')
    .margin({ top: 12 })
    .padding({ bottom: 6 })
    .backgroundColor($r('app.color.white'))
  }

  /** WeekPlanDetailItemView 复刻：icon 12×12 + label 12fp #999 + value（maxLines 可变） */
  @Builder
  detailRow(icon: Resource, label: string, value: string, phone: boolean, maxLines: number) {
    Row() {
      Image(icon)
        .width(12)
        .height(12)
        .margin({ right: 6 })
      Text(label)
        .fontSize(12)
        .fontColor($r('app.color.common_color_3'))
        .width(56)
      if (phone) {
        Text(value)
          .fontSize(13)
          .fontColor($r('app.color.mobile_campus_primary_color_default'))
          .layoutWeight(1)
      } else {
        Text(value)
          .fontSize(13)
          .fontColor($r('app.color.common_color_1'))
          .layoutWeight(1)
          .maxLines(maxLines)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
    }
    .width('100%')
    .padding({ left: 18, right: 18, top: 8, bottom: 8 })
    .alignItems(VerticalAlign.Top)
    .margin({ top: maxLines === 2 ? 12 : 0 })
  }

  /** mobile_campus_meeting_view_weekplan_file.xml：附件区（ATTACHMENT_LIST 空 → 整块隐藏） */
  @Builder
  fileView() {
    if (this.obj.ATTACHMENT_LIST.length > 0) {
      Column() {
        Text('附件')
          .fontSize(15)
          .fontColor($r('app.color.common_color_1'))
          .padding({ left: 18, top: 12, bottom: 8 })
        ForEach(this.obj.ATTACHMENT_LIST, (att: MeetingAttachmentEntity) => {
          Row() {
            Image($r('app.media.mobile_campus_meeting_clip'))
              .width(14)
              .height(14)
              .margin({ right: 6 })
            Text(att.FILENAME)
              .fontSize(13)
              .fontColor($r('app.color.mobile_campus_primary_color_default'))
              .layoutWeight(1)
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
          }
          .width('100%')
          .padding({ left: 18, right: 18, top: 8, bottom: 8 })
          .hoverEffect(HoverEffect.Highlight)
          .onClick(() => {
            this.openAttachment(att);
          })
        }, (att: MeetingAttachmentEntity) => 'att_' + att.FILENAME)
      }
      .width('100%')
      .margin({ top: 12 })
      .backgroundColor($r('app.color.white'))
      .alignItems(HorizontalAlign.Start)
    }
  }

  /** mobile_campus_meeting_view_attend_choose_btn.xml：主色底 48dip 双按钮（IS_JOIN==2） */
  @Builder
  attendChooseBar() {
    Row() {
      Text('不参加')
        .fontSize(16)
        .fontColor($r('app.color.white'))
        .textAlign(TextAlign.Center)
        .layoutWeight(1)
        .height('100%')
        .hoverEffect(HoverEffect.Highlight)
        .onClick(() => {
          this.noAttendReason = '';
          this.showNoAttendDialog = true;
        })
      Divider()
        .color('#084B8F')
        .strokeWidth(1)
        .vertical(true)
        .height(30)
        .margin({ top: 8, bottom: 8 })
      Text('参加')
        .fontSize(16)
        .fontColor($r('app.color.white'))
        .textAlign(TextAlign.Center)
        .layoutWeight(1)
        .height('100%')
        .hoverEffect(HoverEffect.Highlight)
        .onClick(() => {
          this.submitJoinState('1', '');
        })
    }
    .width('100%')
    .constraintSize({ maxWidth: BreakpointSystem.getContentMaxWidth(this.currentBreakpoint) })
    .height(48 + this.avoidAreaBottomVp)
    .padding({ bottom: this.avoidAreaBottomVp })
    .backgroundColor($r('app.color.mobile_campus_primary_color_default'))
    .alignItems(VerticalAlign.Center)
  }

  /** mobile_campus_meeting_view_detail_report_btn.xml：白底 45.5dip（查看参会情况|会议报告|公告badge） */
  @Builder
  reportBar() {
    Row() {
      if (this.isCreator || this.obj.feedBackType === '1') {
        Row() {
          Image($r('app.media.arrow_up'))
            .width(14)
            .height(14)
            .margin({ right: 8 })
          Text('查看参会情况')
            .fontSize(16)
            .fontColor($r('app.color.mobile_campus_primary_color_default'))
        }
        .layoutWeight(1)
        .height(48)
        .justifyContent(FlexAlign.Center)
        .hoverEffect(HoverEffect.Highlight)
        .onClick(() => {
          this.openStaffSituation();
        })
      }
      if (this.obj.meetingReportType !== '0'
        && (this.isCreator || this.obj.meetingReportType !== '')) {
        Divider()
          .color($r('app.color.common_color_5'))
          .strokeWidth(1)
          .vertical(true)
          .height(21)
        Text('会议报告')
          .fontSize(16)
          .fontColor($r('app.color.mobile_campus_primary_color_default'))
          .layoutWeight(1)
          .textAlign(TextAlign.Center)
          .height(48)
          .hoverEffect(HoverEffect.Highlight)
          .onClick(() => {
            this.openMeetingReport();
          })
      }
      if (this.obj.feedBackType !== '') {
        Row() {
          Image($r('app.media.mobile_campus_meeting_announcement'))
            .width(20)
            .height(20)
          if (this.noticeCount > 0) {
            Text(this.noticeCount > 99 ? '99+' : String(this.noticeCount))
              .fontSize(12)
              .fontColor($r('app.color.white'))
              .margin({ left: 2 })
          }
        }
        .padding({ left: 9, right: 9 })
        .height(48)
        .backgroundColor($r('app.color.mobile_campus_schedule_color9'))
        .alignItems(VerticalAlign.Center)
        .hoverEffect(HoverEffect.Highlight)
        .onClick(() => {
          this.openAnnouncement();
        })
      }
    }
    .width('100%')
    .constraintSize({ maxWidth: BreakpointSystem.getContentMaxWidth(this.currentBreakpoint) })
    .height(48 + this.avoidAreaBottomVp)
    .padding({ bottom: this.avoidAreaBottomVp })
    .backgroundColor($r('app.color.white'))
    .alignItems(VerticalAlign.Center)
  }

  /** mobile_campus_meeting_edite.xml MeetingEditeDialog 复刻（取消会议/不参会理由共用） */
  @Builder
  editDialog() {
    Column() {
      Column() {
        Text(this.showCancelDialog ? '取消会议理由' : '不参与会议的原因')
          .fontSize(17)
          .fontColor($r('app.color.common_color_1'))
          .margin({ top: 12 })
        TextArea({
          text: this.showCancelDialog ? this.cancelReason : this.noAttendReason,
          placeholder: this.showCancelDialog ? '请输入取消会议理由，所有拟参会人均可见。' : '请输入不参与会议原因'
        })
          .fontSize(16)
          .fontColor($r('app.color.common_color_1'))
          .backgroundColor($r('app.color.mobile_campus_bg_color'))
          .width('100%')
          .height(68)
          .margin({ top: 10, bottom: 10 })
          .maxLength(50)
          .onChange((value: string) => {
            if (this.showCancelDialog) {
              this.cancelReason = value;
            } else {
              this.noAttendReason = value;
            }
          })
        Divider()
          .color($r('app.color.common_color_5'))
          .strokeWidth(0.5)
          .width('100%')
        Text('提交')
          .fontSize(17)
          .fontColor($r('app.color.mobile_campus_primary_color_default'))
          .textAlign(TextAlign.Center)
          .width('100%')
          .height(44)
          .hoverEffect(HoverEffect.Highlight)
          .onClick(() => {
            if (this.showCancelDialog) {
              this.submitCancelMeeting();
            } else {
              this.submitNoAttend();
            }
          })
      }
      .width(AdaptiveLayoutHelper.getDialogMaxWidth(this.currentBreakpoint, this.windowWidthVp))
      .constraintSize({ maxHeight: AdaptiveLayoutHelper.getDialogMaxHeight(this.windowHeightVp) })
      .padding({ left: 12, right: 12 })
      .borderRadius(8)
      .backgroundColor($r('app.color.white'))
      .alignItems(HorizontalAlign.Center)
      .clip(true)
      .onClick(() => {
        // 拦截点击
      })
    }
    .width('100%')
    .height('100%')
    .padding({ left: 16, right: 16 })
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .backgroundColor('#66000000')
    .onClick(() => {
      this.showCancelDialog = false;
      this.showNoAttendDialog = false;
    })
  }

  @Builder
  pdfPreviewOverlay() {
    Column() {
      Column() {
        Row() {
          Text(this.pdfTitle)
            .fontSize(15)
            .fontWeight(FontWeight.Medium)
            .fontColor($r('app.color.common_color_1'))
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .layoutWeight(1)
          Text('关闭')
            .fontSize(14)
            .fontColor('#3A92ED')
            .padding({ left: 10, right: 4, top: 4, bottom: 4 })
            .hoverEffect(HoverEffect.Highlight)
            .onClick(() => {
              this.closePdfModal();
            })
        }
        .width('100%')
        .padding({ left: 14, right: 14, top: 10, bottom: 10 })
        .backgroundColor($r('app.color.white'))

        Divider().color($r('app.color.common_color_5')).strokeWidth(0.5).width('100%')

        PdfView({
          controller: this.pdfController,
          pageLayout: pdfService.PageLayout.LAYOUT_SINGLE,
          isContinuous: true,
          showScroll: true
        })
          .width('100%')
          .layoutWeight(1)
          .onAppear(() => {
            this.loadPendingPdf();
          })
      }
      .width(AdaptiveLayoutHelper.getDialogMaxWidth(this.currentBreakpoint, this.windowWidthVp))
      .height(AdaptiveLayoutHelper.getDialogMaxHeight(this.windowHeightVp))
      .backgroundColor($r('app.color.white'))
      .borderRadius(10)
      .clip(true)
      .onClick(() => {
        // 拦截点击
      })
    }
    .width('100%')
    .height('100%')
    .padding({ left: 16, right: 16 })
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .backgroundColor('#66000000')
    .onClick(() => {
      this.closePdfModal();
    })
  }

  @Builder
  nluEntitySection() {
    Column() {
      Text('智能识别与快捷操作')
        .fontSize(12)
        .fontColor($r('app.color.common_color_3'))
        .margin({ bottom: 6 })
      Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.Start }) {
        ForEach(this.nluEntities, (chip: NluEntityChip, idx: number) => {
          Row({ space: 4 }) {
            Text(chip.typeLabel)
              .fontSize(11)
              .fontColor('#1B68B7')
              .padding({ left: 5, right: 5, top: 1, bottom: 1 })
              .borderRadius(4)
              .backgroundColor('#EBF4FF')
            Text(chip.text)
              .fontSize(12)
              .fontColor($r('app.color.common_color_1'))
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
              .constraintSize({ maxWidth: 180 })
            Text(chip.actionLabel)
              .fontSize(11)
              .fontColor('#1B68B7')
          }
          .padding({ left: 8, right: 8, top: 5, bottom: 5 })
          .margin({ right: 8, bottom: 8 })
          .borderRadius(14)
          .backgroundColor('#F7F9FC')
          .border({ width: 0.5, color: '#D6E4F5' })
          .alignItems(VerticalAlign.Center)
          .hoverEffect(HoverEffect.Highlight)
          .onClick(() => {
            this.onEntityChipTap(chip);
          })
        }, (chip: NluEntityChip, idx: number) => `${idx}_${chip.type}_${chip.text}`)
      }
      .width('100%')
    }
    .width('100%')
    .padding({ left: 18, right: 18, top: 10, bottom: 6 })
    .margin({ top: 12 })
    .backgroundColor($r('app.color.white'))
    .alignItems(HorizontalAlign.Start)
  }
}
