import { router } from '@kit.ArkUI';
import { common } from '@kit.AbilityKit';
import { image } from '@kit.ImageKit';
import { TitleBar } from '../components/TitleBar';
import { ApiService } from '../network/ApiService';
import { ApiResponse } from '../model/ResponseModel';
import { CourseDetailEntry, LeaveStudentEntry } from '../model/CourseModel';
import { LoginSession } from '../network/LoginSession';
import { ReminderCalendarHelper } from '../common/ReminderCalendarHelper';
import { BarcodeHelper } from '../common/BarcodeHelper';
import { BreakpointSystem } from '../common/BreakpointSystem';
import { AdaptiveLayoutHelper } from '../common/AdaptiveLayoutHelper';

/**
 * 课程详情页 — 1:1 复刻 timetable/view/CourseDetailActivity.java（页名 course_detail）
 * + CourseDetailActivityEx（自定义课表 WeekCourseFragmentEx 课格点击的基础信息模式）
 *
 * 源码还原的 UI 与行为：
 *   1. 布局 mobile_campus_timetable_activity_coursedetail.xml：白底基础块(padding15)：
 *      课程名 19fp + 周数/节数/地点/班级 行(icon21+label17fp Color3+value16fp Color1)
 *      + 上课时间行 + 授课恩师行(extra_teacher=skdx) + extra 统计块：
 *      挂科率(c3(): <1 → ×100 保留1位)/平均分/历史最高分/最高分保持者(N人+arrow→同门弟子列表
 *      pagetype=2)/授课恩师(skls)/上课学生(N人+arrow→pagetype=1)/男女比例条
 *      (weight=nansbl/nvsbl 蓝|橙隔|红+百分比气泡)+请假名单(头像24+姓名17fp+学号14fp+班级14fp，
 *      行点击→LeaveStudentDetailDialog)
 *   2. term 模式（SchedulePage 课格）：e3→l.b(xlh,djz,xqj) GET courseDetail → J0 填充；
 *      基础信息先用路由参数回显（i3 语义），请求失败仅展示基础信息
 *   3. custom 模式（CustomTimetablePage 课格）：Ex.R2 基础信息（bean+BJCache），无统计请求
 *   4. 删除按钮：T1 需 SystemSwitch.time_table_btn_delete=="1"（HAP 未持久化 SystemSwitch，
 *      等价 systemSwitch==null 分支 → 按钮隐藏，ContactPage/MessageListPage 同款结论）
 *   5. e.c(xqj)：数字 1..6 → 一..六，7 → 日，其余空串
 */
const AXIS_LABEL_WIDTH: number = 100;

/** 星期字符（baselibrary util/e.c 1:1） */
function weekdayChar(xqj: string): string {
  if (xqj === '' || !/^[0-9]+$/.test(xqj)) {
    return '';
  }
  const day: number = Number(xqj);
  if (day > 7 || day < 1) {
    return '';
  }
  return day === 7 ? '日' : ['一', '二', '三', '四', '五', '六'][day - 1];
}

/** c3()：挂科率展示（<1 视为小数比例 ×100，保留 1 位） */
function failRateText(gkl: string): string {
  const value: number = Number(gkl);
  if (Number.isNaN(value)) {
    return gkl + '%';
  }
  if (value < 1) {
    return (value * 100).toFixed(1) + '%';
  }
  return gkl + '%';
}

interface DetailParams {
  mode?: string;
  xlh?: string;
  djz?: string;
  xqj?: string;
  courseName?: string;
  weekTime?: string;
  session?: string;
  place?: string;
  className?: string;
  classtime?: string;
  teacher?: string;
}

function pickParam(params: Record<string, Object> | null, key: string): string {
  if (params === null) {
    return '';
  }
  const v: Object = params[key];
  return typeof v === 'string' ? v as string : '';
}

@Entry
@Component
struct CourseDetailPage {
  @State mode: string = 'term';
  @State xlh: string = '';
  @State djz: string = '';
  @State xqj: string = '';
  @State courseName: string = '';
  @State weekTime: string = '';
  @State session: string = '';
  @State place: string = '';
  @State className: string = '';
  @State showClassRow: boolean = false;
  @State classtime: string = '';
  @State showTopTeacherRow: boolean = false;
  @State topTeacher: string = '';
  @State showExtraBlock: boolean = false;
  @State failRate: string = '';
  @State averageScore: string = '';
  @State highestScore: string = '';
  @State scoreKeeper: string = '';
  @State teacher: string = '';
  @State studentCount: string = '';
  @State maleRatio: number = 0;
  @State femaleRatio: number = 0;
  @State showRatioBar: boolean = false;
  @State leaveStudents: LeaveStudentEntry[] = [];
  @State leaveDetail: LeaveStudentEntry | null = null;
  @State showQrModal: boolean = false;
  @State qrPixelMap: image.PixelMap | null = null;
  @State qrLoading: boolean = false;
  @State qrSaving: boolean = false;
  @StorageProp('currentBreakpoint') currentBreakpoint: string = 'sm';
  @StorageProp('windowWidthVp') windowWidthVp: number = 360;
  @StorageProp('windowHeightVp') windowHeightVp: number = 780;
  @StorageProp('avoidAreaBottomVp') avoidAreaBottomVp: number = 0;
  private detail: CourseDetailEntry | null = null;

  aboutToDisappear(): void {
    this.releaseQrPixelMap();
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

  private async openCourseQrModal(): Promise<void> {
    const teacherName: string = this.teacher !== '' ? this.teacher : this.topTeacher;
    const payload: string = BarcodeHelper.buildCourseQrPayload(
      this.courseName,
      this.weekTime,
      this.session,
      this.place,
      this.classtime,
      teacherName
    );
    if (payload === '') {
      this.toast('暂无可生成二维码的课程信息');
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
      this.toast(res.message);
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
      this.toast(res.message);
    } finally {
      this.qrSaving = false;
      if (!this.showQrModal) {
        this.releaseQrPixelMap();
      }
    }
  }

  aboutToAppear(): void {
    const params: Record<string, Object> | null =
      router.getParams() as Record<string, Object> | null;
    this.mode = pickParam(params, 'mode') === '' ? 'term' : pickParam(params, 'mode');
    this.xlh = pickParam(params, 'xlh');
    this.djz = pickParam(params, 'djz');
    this.xqj = pickParam(params, 'xqj');
    this.courseName = pickParam(params, 'courseName');
    this.weekTime = pickParam(params, 'weekTime');
    this.session = pickParam(params, 'session');
    this.place = pickParam(params, 'place');
    this.classtime = pickParam(params, 'classtime');
    // Ex.R2：custom 模式基础信息 + 授课恩师(skdx)；term 模式拉 courseDetail → J0
    if (this.mode === 'custom') {
      this.showTopTeacherRow = true;
      this.topTeacher = pickParam(params, 'teacher');
      this.applyDszSuffix('');
      return;
    }
    this.fetchDetail();
  }

  /** dsz 周次后缀（CourseDetailActivityEx.T2/J0：dsz=="1"→" (单周)"、"2"→" (双周)"；
   *  custom 路由无 dsz 字段 → 空串 no-op，与 h.e() setDsz("") 语义一致） */
  private applyDszSuffix(dsz: string): void {
    if (dsz === '1') {
      this.weekTime = this.weekTime === '' ? '(单周)' : this.weekTime + ' (单周)';
    } else if (dsz === '2') {
      this.weekTime = this.weekTime === '' ? '(双周)' : this.weekTime + ' (双周)';
    }
  }

  /** e3→l.b：GET courseDetail {xlh,djz,xqj} → J0 填充 */
  private fetchDetail(): void {
    ApiService.getCourseDetail(this.xlh, this.djz, this.xqj)
      .then((resp: ApiResponse<CourseDetailEntry>) => {
        if (resp.code === 0) {
          this.applyDetail(resp.data);
        }
        // 失败：保留路由参数基础信息（源码 f() 空实现 + m() 静默语义）
      })
      .catch(() => {
        // 网络失败仅展示基础信息
      });
  }

  /** J0(CourseDetailEntity) 1:1 填充 */
  private applyDetail(detail: CourseDetailEntry): void {
    this.detail = detail;
    this.showExtraBlock = true;
    this.courseName = detail.kcmc;
    if (this.xqj === '' && detail.xqj !== '') {
      this.xqj = detail.xqj;
    }
    // J0：q.setText(getQsjsz()) —— 周数以响应 qsjsz 为准（term 模式源码无 dsz 后缀，后缀仅 Ex.T2）
    this.weekTime = detail.qsjsz;
    const weekChar: string = weekdayChar(detail.xqj);
    // J0 非 HNDS："周" + e.c(xqj) + 空格 + (djj 空 ? "" : djj+"节")（djj 自带 SERVER="-"）
    this.session = '周' + weekChar + (detail.djj === '' ? '' : ' ' + detail.djj + '节');
    this.place = detail.skdd;
    this.showClassRow = detail.skbj !== '';
    this.className = detail.skbj === 'null' ? '' : detail.skbj;
    this.classtime = detail.sksj;
    this.failRate = detail.gkl === '' ? '' : failRateText(detail.gkl);
    this.averageScore = detail.pjf;
    this.highestScore = detail.lszgf;
    this.scoreKeeper = detail.zgfbczrs === '' ? '' : detail.zgfbczrs + '人';
    if (LoginSession.userType === '1' || LoginSession.userType === '') {
      this.teacher = detail.skls;
    }
    this.studentCount = detail.skrs === '' ? '' : detail.skrs + '人';
    this.applyRatio(detail);
    this.leaveStudents = detail.leaveStudent;
  }

  /** J0 男女比例段：skrs 数字>0 才展示，weight=nansbl/nvsbl */
  private applyRatio(detail: CourseDetailEntry): void {
    const skrs: number = Number(detail.skrs);
    if (detail.skrs === '' || Number.isNaN(skrs) || skrs <= 0 || !/^[0-9]+$/.test(detail.skrs)) {
      this.showRatioBar = false;
      return;
    }
    const male: number = /^[0-9]+$/.test(detail.nansbl) ? Number(detail.nansbl) : 0;
    const female: number = /^[0-9]+$/.test(detail.nvsbl) ? Number(detail.nvsbl) : 0;
    if (male <= 0 && female <= 0) {
      this.showRatioBar = false;
      return;
    }
    this.maleRatio = male;
    this.femaleRatio = female;
    this.showRatioBar = true;
  }

  /** 同门弟子/上课学生列表跳转（d/e 回调：pagetype 2=最高分保持者 1=上课学生） */
  private goClassmates(pagetype: number): void {
    if (this.detail === null) {
      return;
    }
    router.pushUrl({
      url: 'pages/ClassmatesListPage',
      params: {
        'xn': this.detail.xn,
        'xq': this.detail.xq,
        'dm': this.detail.dm,
        'kcmc': this.detail.kcmc,
        'zgfzscj': this.detail.zgfzscj,
        'num': pagetype === 1 ? this.detail.skrs : this.detail.zgfbczrs,
        'djz': this.djz,
        'xqj': this.detail.xqj,
        'djj': this.detail.djj,
        'pagetype': pagetype
      }
    });
  }

  private toast(message: string): void {
    this.getUIContext().getPromptAction().showToast({ message: message, duration: 2000 });
  }

  private async scheduleCourseReminder(): Promise<void> {
    const win = ReminderCalendarHelper.computeNextCourseWindow(this.xqj, this.session, this.classtime);
    if (win === null) {
      this.toast('当前课程缺少具体上课时间，无法创建提醒');
      return;
    }
    const nowMs: number = Date.now();
    const triggerMs: number = win.reminderMs > nowMs
      ? win.reminderMs
      : (win.startMs > nowMs + 60000 ? nowMs + 60000 : win.startMs);
    const ctx = this.getUIContext().getHostContext() as common.UIAbilityContext;
    const contentParts: string[] = [];
    if (this.place !== '') { contentParts.push(this.place); }
    if (this.session !== '') { contentParts.push(this.session); }
    const res = await ReminderCalendarHelper.publishCalendarReminderWithResult(
      `上课提醒：${this.courseName}`,
      contentParts.join(' · '),
      new Date(triggerMs),
      ctx
    );
    if (res.success) {
      this.toast(`已设置上课提醒（${win.label} 前）`);
    } else {
      this.toast(res.message);
    }
  }

  private async addCourseToCalendar(): Promise<void> {
    const win = ReminderCalendarHelper.computeNextCourseWindow(this.xqj, this.session, this.classtime);
    if (win === null) {
      this.toast('当前课程缺少具体上课时间，无法写入日历');
      return;
    }
    const ctx = this.getUIContext().getHostContext() as common.UIAbilityContext;
    const descParts: string[] = [];
    if (this.weekTime !== '') { descParts.push('周数：' + this.weekTime); }
    if (this.session !== '') { descParts.push('节数：' + this.session); }
    const teacherName: string = this.teacher !== '' ? this.teacher : this.topTeacher;
    if (teacherName !== '') { descParts.push('授课教师：' + teacherName); }
    const res = await ReminderCalendarHelper.addCalendarEventWithResult(
      ctx,
      this.courseName,
      descParts.join('  '),
      win.startMs,
      win.endMs,
      this.place,
      [15]
    );
    this.toast(res.message);
  }

  @Builder
  infoRow(icon: Resource, label: string, value: string) {
    Row() {
      Image(icon)
        .width(21)
        .height(21)
      Text(label)
        .fontSize(17)
        .fontColor($r('app.color.common_color_3'))
        .margin({ left: 6 })
      Text(value)
        .fontSize(16)
        .fontColor($r('app.color.common_color_1'))
        .margin({ left: 10 })
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
    }
    .width('100%')
    .alignItems(VerticalAlign.Center)
    .margin({ top: 15 })
  }

  /** timetablecoursedetail_linearhor2：统计行（icon23+label16fp Color1+value17fp Color3） */
  @Builder
  statRow(icon: Resource, label: string, value: string, arrow: boolean, onClick: () => void) {
    Row() {
      Image(icon)
        .width(23)
        .height(23)
      Text(label)
        .fontSize(16)
        .fontColor($r('app.color.common_color_1'))
        .margin({ left: 6 })
        .layoutWeight(1)
      Text(value)
        .fontSize(17)
        .fontColor($r('app.color.common_color_3'))
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
      if (arrow) {
        Image($r('app.media.arrow_right2'))
          .width(16)
          .height(16)
          .margin({ left: 4 })
      }
    }
    .width('100%')
    .height(48)
    .alignItems(VerticalAlign.Center)
    .padding({ left: 15, right: 15 })
    .onClick(() => {
      onClick();
    })
  }

  /** mobile_campus_timetable_leave_student_detail 弹窗（LeaveStudentDetailDialog 1:1） */
  @Builder
  leaveDialog() {
    Column() {
      Scroll() {
        Column() {
          Row() {
            Text('请假详情')
              .fontSize(18)
              .fontColor($r('app.color.common_color_1'))
              .layoutWeight(1)
              .textAlign(TextAlign.Center)
            Image($r('app.media.mobile_campus_base_close_g'))
              .width(20)
              .height(20)
              .padding(6)
              .hoverEffect(HoverEffect.Highlight)
              .onClick(() => {
                this.leaveDetail = null;
              })
          }
          .width('100%')
          .alignItems(VerticalAlign.Center)
          .margin({ top: 12, bottom: 12 })
          Divider()
            .color($r('app.color.common_color_6'))
            .strokeWidth(0.5)
            .width('100%')
          Text(this.leaveDetail === null ? '' : this.leaveDetail.student_name)
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor($r('app.color.ybg_blue'))
            .margin({ top: 12 })
            .width('100%')
          this.leaveRow('学号:', this.leaveDetail === null ? '' : this.leaveDetail.student_no)
          this.leaveRow('专业:', this.leaveDetail === null ? '' : this.leaveDetail.profession)
          this.leaveRow('班级:', this.leaveDetail === null ? '' : this.leaveDetail.class_name)
          this.leaveRow('开始时间:', this.leaveDetail === null ? '' : this.leaveDetail.start_date)
          this.leaveRow('结束时间:', this.leaveDetail === null ? '' : this.leaveDetail.end_date)
          this.leaveRow('开始节次:', this.leaveDetail === null ? '' : this.leaveDetail.ksjc)
          this.leaveRow('结束节次:', this.leaveDetail === null ? '' : this.leaveDetail.jsjc)
          this.leaveRow('请假事由:', this.leaveDetail === null ? '' : this.leaveDetail.reason)
        }
        .width('100%')
        .padding({ left: 12, right: 12, bottom: 24 })
      }
      .scrollBar(BarState.Off)
      .width(BreakpointSystem.getDialogMaxWidth(this.currentBreakpoint, this.windowWidthVp))
      .constraintSize({ maxHeight: BreakpointSystem.getDialogMaxHeight(this.windowHeightVp) })
      .backgroundColor($r('app.color.white'))
      .borderRadius(8)
      .onClick(() => {
        // 拦截面板内点击
      })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .padding({ left: 16, right: 16 })
    .backgroundColor('#66000000')
    .onClick(() => {
      this.leaveDetail = null;
    })
  }

  @Builder
  leaveRow(label: string, value: string) {
    Row() {
      Text(label)
        .fontSize(18)
        .fontColor($r('app.color.common_color_3'))
        .width(AXIS_LABEL_WIDTH)
      Text(value)
        .fontSize(18)
        .fontColor($r('app.color.common_color_1'))
        .margin({ left: 6 })
        .layoutWeight(1)
    }
    .width('100%')
    .alignItems(VerticalAlign.Center)
    .margin({ top: 12 })
  }

  build() {
    Stack() {
      Column() {
        TitleBar({
          title: '课程详情',
          showBack: true,
          rightText: '课程码',
          onRightClick: () => {
            this.openCourseQrModal();
          }
        })
        Scroll() {
          Column() {
            // 基础信息块（白底 padding15）
            Column() {
              Text(this.courseName)
                .fontSize(19)
                .fontColor($r('app.color.common_color_1'))
                .width('100%')
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
              this.infoRow($r('app.media.mobile_campus_timetable_course_week'), '周数', this.weekTime)
              this.infoRow($r('app.media.mobile_campus_timetable_course_section'), '节数', this.session)
              this.infoRow($r('app.media.mobile_campus_timetable_course_place'), '地点', this.place)
              if (this.showClassRow) {
                this.infoRow($r('app.media.mobile_campus_timetable_course_section'), '班级', this.className)
              }
            }
            .width('100%')
            .padding(15)
            .backgroundColor($r('app.color.ybg_white'))
            Divider()
              .color($r('app.color.common_color_5'))
              .strokeWidth(0.5)
              .width('100%')
            // 上课时间行（timetablecoursedetail_classtimelinear）
            Row() {
              Image($r('app.media.mobile_campus_timetable_course_classtime'))
                .width(21)
                .height(21)
              Text('上课时间')
                .fontSize(16)
                .fontColor($r('app.color.common_color_1'))
                .margin({ left: 6 })
              Text(this.classtime)
                .fontSize(16)
                .fontColor($r('app.color.common_color_1'))
                .margin({ left: 6 })
                .layoutWeight(1)
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
            }
            .width('100%')
            .padding(15)
            .alignItems(VerticalAlign.Center)
            .backgroundColor($r('app.color.ybg_white'))
            if (this.courseName !== '') {
              Divider()
                .color($r('app.color.common_color_5'))
                .strokeWidth(0.5)
                .width('100%')
              Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.End }) {
                Text('上课提醒')
                  .fontSize(14)
                  .fontColor('#18B4ED')
                  .backgroundColor('#E8F7FD')
                  .borderRadius(16)
                  .padding({ left: 14, right: 14, top: 7, bottom: 7 })
                  .margin({ left: 8, top: 4, bottom: 4 })
                  .onClick(() => {
                    this.scheduleCourseReminder();
                  })
                Text('加入系统日历')
                  .fontSize(14)
                  .fontColor($r('app.color.sdmu_primary'))
                  .backgroundColor('#FDECEE')
                  .borderRadius(16)
                  .padding({ left: 14, right: 14, top: 7, bottom: 7 })
                  .margin({ left: 8, top: 4, bottom: 4 })
                  .onClick(() => {
                    this.addCourseToCalendar();
                  })
                Text('课程二维码')
                  .fontSize(14)
                  .fontColor('#2E7D32')
                  .backgroundColor('#EAF7EC')
                  .borderRadius(16)
                  .padding({ left: 14, right: 14, top: 7, bottom: 7 })
                  .margin({ left: 8, top: 4, bottom: 4 })
                  .onClick(() => {
                    this.openCourseQrModal();
                  })
              }
              .width('100%')
              .padding({ left: 15, right: 15, top: 6, bottom: 6 })
              .backgroundColor($r('app.color.ybg_white'))
            }
            // course_detail_teacher（custom 模式 / term-i3 教师=skdx）
            if (this.showTopTeacherRow) {
              Divider()
                .color($r('app.color.common_color_5'))
                .strokeWidth(0.5)
                .width('100%')
              Row() {
                Image($r('app.media.mobile_campus_timetable_course_teacher'))
                  .width(23)
                  .height(23)
                Text('授课恩师')
                  .fontSize(16)
                  .fontColor($r('app.color.common_color_1'))
                  .margin({ left: 6 })
                  .layoutWeight(1)
                Text(this.topTeacher)
                  .fontSize(16)
                  .fontColor($r('app.color.common_color_3'))
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
              }
              .width('100%')
              .height(48)
              .padding({ left: 15, right: 15 })
              .alignItems(VerticalAlign.Center)
              .backgroundColor($r('app.color.ybg_white'))
            }
            // course_detail_extra（courseDetail 响应成功后展示，J0）
            if (this.showExtraBlock) {
              Column() {
                Divider()
                  .color($r('app.color.common_color_5'))
                  .strokeWidth(0.5)
                  .width('100%')
                if (this.failRate !== '') {
                  this.statRow($r('app.media.no_pass_rate'), '挂科率', this.failRate, false, () => {
                  })
                  Divider()
                    .color($r('app.color.common_color_5'))
                    .strokeWidth(0.5)
                    .width('100%')
                }
                if (this.averageScore !== '') {
                  this.statRow($r('app.media.average_score'), '平均分', this.averageScore, false, () => {
                  })
                  Divider()
                    .color($r('app.color.common_color_5'))
                    .strokeWidth(0.5)
                    .width('100%')
                }
                if (this.highestScore !== '') {
                  this.statRow($r('app.media.mobile_campus_timetable_course_highestscore'),
                    '历史最高分', this.highestScore, false, () => {
                    })
                  Divider()
                    .color($r('app.color.common_color_5'))
                    .strokeWidth(0.5)
                    .width('100%')
                }
                if (this.scoreKeeper !== '') {
                  this.statRow($r('app.media.mobile_campus_timetable_course_highestscorepeople'),
                    '最高分保持者', this.scoreKeeper, true, () => {
                      this.goClassmates(2);
                    })
                }
              }
              .width('100%')
              .backgroundColor($r('app.color.ybg_white'))
              Divider()
                .color($r('app.color.common_color_5'))
                .strokeWidth(0.5)
                .width('100%')
              // 授课恩师（timetable_course_detail_ll_teacher_container，userType=学生→skls）
              Row() {
                Image($r('app.media.mobile_campus_timetable_course_teacher'))
                  .width(23)
                  .height(23)
                Text('授课恩师')
                  .fontSize(16)
                  .fontColor($r('app.color.common_color_1'))
                  .margin({ left: 6 })
                  .layoutWeight(1)
                Text(this.teacher)
                  .fontSize(16)
                  .fontColor($r('app.color.common_color_3'))
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
              }
              .width('100%')
              .height(48)
              .padding({ left: 15, right: 15 })
              .alignItems(VerticalAlign.Center)
              .backgroundColor($r('app.color.ybg_white'))
              Divider()
                .color($r('app.color.common_color_5'))
                .strokeWidth(0.5)
                .width('100%')
              if (this.studentCount !== '') {
                this.statRow($r('app.media.mobile_campus_timetable_course_biconditional_gate_disciple'),
                  '上课学生', this.studentCount, this.showRatioBar, () => {
                    this.goClassmates(1);
                  })
              }
              if (this.showRatioBar) {
                Divider()
                  .color($r('app.color.common_color_5'))
                  .strokeWidth(0.5)
                  .width('100%')
                // ll_tongmendizibili：男|比例条|女
                Row() {
                  Column() {
                    Text('男')
                      .fontSize(16)
                      .fontColor($r('app.color.common_color_1'))
                      .padding({ bottom: 10 })
                    Image($r('app.media.mobile_campus_timetable_course_boy'))
                      .width(24)
                      .height(24)
                  }
                  .alignItems(HorizontalAlign.Center)
                  Column() {
                    Row() {
                      Text(this.maleRatio + '%')
                        .fontSize(14)
                        .fontColor($r('app.color.ybg_white'))
                        .backgroundColor($r('app.color.timetable_per_blue'))
                        .padding({ left: 4, right: 4, top: 4, bottom: 6 })
                        .layoutWeight(this.maleRatio > 0 ? this.maleRatio : 1)
                        .textAlign(TextAlign.Center)
                      Text(this.femaleRatio + '%')
                        .fontSize(14)
                        .fontColor($r('app.color.ybg_white'))
                        .backgroundColor($r('app.color.timetable_per_red'))
                        .padding({ left: 4, right: 4, top: 4, bottom: 6 })
                        .layoutWeight(this.femaleRatio > 0 ? this.femaleRatio : 1)
                        .textAlign(TextAlign.Center)
                    }
                    .width('100%')
                    .margin({ top: 6 })
                    Row() {
                      Row()
                        .height(7)
                        .borderRadius({ topLeft: 4, bottomLeft: 4 })
                        .backgroundColor($r('app.color.timetable_per_blue'))
                        .layoutWeight(this.maleRatio > 0 ? this.maleRatio : 1)
                      Row()
                        .width(6)
                        .height(7)
                        .backgroundColor($r('app.color.ybg_orange'))
                      Row()
                        .height(7)
                        .borderRadius({ topRight: 4, bottomRight: 4 })
                        .backgroundColor($r('app.color.timetable_per_red'))
                        .layoutWeight(this.femaleRatio > 0 ? this.femaleRatio : 1)
                    }
                    .width('100%')
                    .margin({ top: 6 })
                  }
                  .layoutWeight(1)
                  .margin({ left: 4, right: 4 })
                  Column() {
                    Text('女')
                      .fontSize(16)
                      .fontColor($r('app.color.common_color_1'))
                      .padding({ bottom: 10 })
                    Image($r('app.media.mobile_campus_timetable_course_girl'))
                      .width(24)
                      .height(24)
                  }
                  .alignItems(HorizontalAlign.Center)
                }
                .width('100%')
                .padding(19)
                .alignItems(VerticalAlign.Center)
                .backgroundColor($r('app.color.ybg_white'))
              }
              Divider()
                .color($r('app.color.common_color_5'))
                .strokeWidth(0.5)
                .width('100%')
            }
            // 请假名单（leave_student_list_view：header + item 行）
            if (this.leaveStudents.length > 0) {
              Column() {
                Text('请假名单')
                  .fontSize(17)
                  .fontColor($r('app.color.common_color_1'))
                  .width('100%')
                  .padding(12)
              }
              .width('100%')
              .backgroundColor($r('app.color.ybg_white'))
              ForEach(this.leaveStudents, (student: LeaveStudentEntry) => {
                Row() {
                  Image($r('app.media.mobile_campus_timetable_leave_student_avatar'))
                    .width(24)
                    .height(24)
                  Text(student.student_name)
                    .fontSize(17)
                    .fontColor($r('app.color.common_color_1'))
                    .width(60)
                    .margin({ left: 12 })
                    .maxLines(1)
                  Text(student.student_no)
                    .fontSize(14)
                    .fontColor($r('app.color.common_color_3'))
                    .width(110)
                    .margin({ left: 12 })
                    .maxLines(1)
                  Text(student.class_name)
                    .fontSize(14)
                    .fontColor($r('app.color.common_color_1'))
                    .margin({ left: 12 })
                    .layoutWeight(1)
                    .maxLines(1)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                }
                .width('100%')
                .padding(12)
                .alignItems(VerticalAlign.Center)
                .backgroundColor($r('app.color.ybg_white'))
                .onClick(() => {
                  this.leaveDetail = student;
                })
              }, (student: LeaveStudentEntry) => 'leave' + student.student_no)
            }
          }
          .width('100%')
          .constraintSize({ maxWidth: BreakpointSystem.getContentMaxWidth(this.currentBreakpoint) })
          .padding({ bottom: Math.max(12, this.avoidAreaBottomVp) })
        }
        .width('100%')
        .layoutWeight(1)
        .scrollBar(BarState.Off)
        .backgroundColor($r('app.color.common_color_6'))
      }
      .width('100%')
      .height('100%')

      if (this.leaveDetail !== null) {
        this.leaveDialog()
      }

      if (this.showQrModal) {
        this.courseQrOverlay()
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.common_color_6'))
  }

  @Builder
  courseQrOverlay() {
    Column() {
      Scroll() {
        Column() {
          Row() {
            Text('课程信息二维码')
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

          if (this.courseName !== '') {
            Text(this.courseName)
              .fontSize(16)
              .fontWeight(FontWeight.Bold)
              .fontColor($r('app.color.common_color_1'))
              .margin({ top: 10 })
              .maxLines(2)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
          }
          if (this.place !== '' || this.session !== '') {
            Text(`${this.session}${this.place !== '' ? ' · ' + this.place : ''}`)
              .fontSize(13)
              .fontColor($r('app.color.common_color_3'))
              .margin({ top: 4 })
              .maxLines(1)
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

          Text('扫码分享课程时间与地点信息')
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
                  this.toast('未获得保存授权');
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
}
