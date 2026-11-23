import { router } from '@kit.ArkUI';
import { ApiService } from '../network/ApiService';
import { ApiResponse } from '../model/ResponseModel';
import { CourseItem, ScheduleTermParams, SCHEDULE_FALLBACK_START, SCHEDULE_FALLBACK_END,
  parseYmdMs, apkCurrentWeek, apkTotalWeeks } from '../model/CourseModel';
import { BusinessError } from '@kit.BasicServicesKit';
import { common } from '@kit.AbilityKit';
import { WidgetDataHelper, WidgetCourseSummary } from '../common/WidgetDataHelper';

/**
 * 课表页 — 源码级对齐 TimetableActivity + WeekCourseFragment + CourseBox + ChooseWeeksPopup + ChooseTermDialog
 *
 * 源码还原的 UI 行为（TimetableActivity.java 666 行逐项）：
 *   1. 顶部 Toolbar：中央"第N周"文本(17fp)+schedule_down_btn 箭头(展开时向上翻转)，
 *      右侧 termbtn(43.5x14) → ChooseTermDialog（T1/Y0/b 类）
 *   2. 周次选择弹窗 ChooseWeeksPopup(widget/f.java)：全屏 0x77000000 遮罩+白底列表(高=6项)，
 *      条目"第N周/第N周 (本周)"，当前周背景 common_color_7 白字，scrollToIndex(curWeek-3)，
 *      点选后 G=week、I 日期条重算、网格按周刷新（h 类 a 回调）
 *   3. 日期条 I3()：左侧"MM月"(TextSize3.Color7=16fp common_color_7 宽50)，
 *      7 列"dd\n周X"(13fp common_color_3；每月1日显示"MM月"；e.f 周字数组 日一二三四五六)，
 *      今日列 17fp common_color_7 + 底线 common_color_7(3dip=1.5vp)，非本周无高亮(u()=-1)
 *   4. 课程网格 CourseBox.java：单格高 55vp(week_view_section_item/55dip)，节次轴宽 50vp
 *      (timetable_month_width)，格子文字"kcmc\n@skdd"(TextSize5.Color6=12fp common_color_6，
 *      padding 2vp，maxLines=3*节数)，配色 timetable_showcolor1..14 按 kcmc 顺序循环分配
 *      (setCourseShowColor)，重叠课程折叠进首格+multi_tag 角标(getFoldTagImageView)，
 *      单格点击→课程详情，折叠格点击→MultiCoursesDialog(widget/h.java: 3列Grid 间距13vp)
 *   5. 右下 FAB 组(v3/D3/F3)：主钮 mobile_campus_timetable_course_iv_open 点击 45° 旋转
 *      +展开 custom(添加课程→AddCourseActivity)/audit(添加班级→ChooseAcademyActivity)，
 *      500ms Decelerate；主钮点击仅切换展开(c/e 类)
 *   6. 学期切换 ChooseTermDialog(widget/d.java)：标题"Xn学年    第Xq学期"(TextSize2.Color2)
 *      +右上"完成"(TextSize2.Color7=主色)，选择后 H3→重载
 *   7. 周次过滤：APK timetable_djz==当前周（scheduleOfTerm 按 djz 拆行）；
 *      学期起始日 = termInfo.ksrq（失败兜底 2026-08-24），当前周 = APK GetTimeTableUtil.e() 公式
 *   8. 底部脚注 G2()：*课表数据以教务单位提供为准
 * 说明：APK 源码中无月/周视图切换(TimetableActivity 仅加载 WeekCourseFragment)，
 *       timetable_tv_month 为静态月份显示；本次按源码不虚构月视图。
 */
// 学期起始日来源：GET /mobileapi_ydxy/api/schedule/termInfo → {ksrq,jsrq,dqxq,...}（TermParamsEntity），
// 2026-11-17 服务器实测当前学期 ksrq=2026-08-24 jsrq=2027-01-15（此处仅作接口失败兜底）
const FALLBACK_START_YMD: string = SCHEDULE_FALLBACK_START;
const FALLBACK_END_YMD: string = SCHEDULE_FALLBACK_END;
const MAX_WEEK: number = 25;
const SECTION_HEIGHT: number = 55;
const AXIS_WIDTH: number = 50;
const SHOW_COLOR_COUNT: number = 14;
const WEEK_ITEM_HEIGHT: number = 53;
const WHEEL_ITEM_HEIGHT: number = 53;
const WHEEL_EDGE_ITEMS: number = 3;
const WHEEL_VISIBLE_ITEMS: number = 7;
const WEEK_CHARS: string[] = ['一', '二', '三', '四', '五', '六'];

class ScheduleDateCell {
  dateText: string;
  weekChar: string;
  highlight: boolean;

  constructor(dateText: string, weekChar: string, highlight: boolean) {
    this.dateText = dateText;
    this.weekChar = weekChar;
    this.highlight = highlight;
  }
}

class CourseFoldGroup {
  items: CourseItem[] = [];
  start: number = 1;
  end: number = 1;
  display: CourseItem | null = null;
}

class TermOption {
  xn: string;
  xq: string;

  constructor(xn: string, xq: string) {
    this.xn = xn;
    this.xq = xq;
  }

  label(): string {
    return this.xn + '学年    第' + this.xq + '学期';
  }
}

class DetailParams {
  courseName: string;
  weekTime: string;
  session: string;
  place: string;
  // [W10 timetable-series] CourseDetailActivity courseDetail GET 所需三元组：
  // xlh=课行周次描述原文、djz=教学周次、xqj=星期几（y(Intent) 校验 xlh/bean 至少其一）
  xlh: string;
  djz: string;
  xqj: string;

  constructor(courseName: string, weekTime: string, session: string, place: string,
    xlh: string, djz: string, xqj: string) {
    this.courseName = courseName;
    this.weekTime = weekTime;
    this.session = session;
    this.place = place;
    this.xlh = xlh;
    this.djz = djz;
    this.xqj = xqj;
  }
}

@Entry
@Component
struct SchedulePage {
  @State courseList: CourseItem[] = [];
  @State weekNumber: number = 1;
  @State todayWeek: number = 1;
  @State dateCells: ScheduleDateCell[] = [];
  @State monthLabel: string = '--月';
  @State showWeekPopup: boolean = false;
  @State showTermDialog: boolean = false;
  @State termWheelIndex: number = 0;
  @State fabExpanded: boolean = false;
  @State gridShown: boolean = true;
  @State multiCourses: CourseItem[] = [];
  @State multiColorIdx: number = 0;
  @State showMultiDialog: boolean = false;
  // 学期起止毫秒（termInfo 失败时用服务器实测兜底值，与 APK 常量语义一致）
  @State semesterStartMs: number = 0;
  @State semesterEndMs: number = 0;
  // APK GetTimeTableUtil.r() 总周数（ChooseWeeksPopup 周次列表上限）
  @State maxWeek: number = MAX_WEEK;
  private weekScroller: Scroller = new Scroller();
  private termScroller: Scroller = new Scroller();
  private termXn: string = '2026-2027';
  private termXq: string = '1';
  private sectionTimes: string[] = ['08:00', '08:55', '10:00', '10:55', '14:00', '14:55',
    '16:00', '16:55', '19:00', '19:55', '20:50', '21:45'];
  // APK CourseBox.boxBgColorResIdArray = timetable_showcolor1..14
  private colorPool: Resource[] = [
    $r('app.color.timetable_showcolor1'), $r('app.color.timetable_showcolor2'),
    $r('app.color.timetable_showcolor3'), $r('app.color.timetable_showcolor4'),
    $r('app.color.timetable_showcolor5'), $r('app.color.timetable_showcolor6'),
    $r('app.color.timetable_showcolor7'), $r('app.color.timetable_showcolor8'),
    $r('app.color.timetable_showcolor9'), $r('app.color.timetable_showcolor10'),
    $r('app.color.timetable_showcolor11'), $r('app.color.timetable_showcolor12'),
    $r('app.color.timetable_showcolor13'), $r('app.color.timetable_showcolor14')
  ];

  aboutToAppear(): void {
    // 兜底学期（服务器实测 2026-11-17），termInfo 到达后覆盖
    this.semesterStartMs = parseYmdMs(FALLBACK_START_YMD);
    this.semesterEndMs = parseYmdMs(FALLBACK_END_YMD);
    const initWeek: number = apkCurrentWeek(this.semesterStartMs, this.semesterEndMs, this.todayMidnightMs());
    this.todayWeek = initWeek >= 1 ? initWeek : 1;
    this.applyWeek(this.todayWeek);
    // 源码 TimeTableNetPresenter.n()：termInfo/termParams → 真实学期起始日 → 当前周
    ApiService.getScheduleTermParams()
      .then((response: ApiResponse<ScheduleTermParams>) => {
        this.applyTermParams(response.data);
      })
      .catch((error: BusinessError) => {
        console.info('SchedulePage termParams fail: ' + error.message);
      });
    this.loadCourses();
  }

  /** 用服务器学期参数覆盖常量：ksrq/jsrq → 当前周 + 总周数（APK e()/r()） */
  private applyTermParams(term: ScheduleTermParams): void {
    if (!term.hasStart()) {
      return;
    }
    const startMs: number = parseYmdMs(term.ksrq);
    const endMs: number = parseYmdMs(term.jsrq);
    if (startMs > 0) {
      this.semesterStartMs = startMs;
    }
    if (endMs > 0) {
      this.semesterEndMs = endMs;
    }
    if (term.xn !== '') {
      this.termXn = term.xn;
    }
    if (term.xq !== '') {
      this.termXq = term.xq;
    }
    const apkWeek: number = apkCurrentWeek(this.semesterStartMs, this.semesterEndMs, this.todayMidnightMs());
    // TimetableActivity.l1()：今天不在学期区间时兜底第 1 周
    this.todayWeek = apkWeek >= 1 ? apkWeek : 1;
    const total: number = apkTotalWeeks(this.semesterStartMs, this.semesterEndMs);
    if (total >= 1) {
      this.maxWeek = total > MAX_WEEK ? MAX_WEEK : total;
    }
    this.applyWeek(this.todayWeek);
  }

  private todayMidnightMs(): number {
    const now: Date = new Date();
    return new Date(now.getFullYear(), now.getMonth(), now.getDate()).getTime();
  }

  // APK onActivityResult RESULT_OK→K3 重载：页面回显时刷新数据
  onPageShow(): void {
    this.loadCourses();
  }

  private loadCourses(): void {
    ApiService.getScheduleList()
      .then((response: ApiResponse<CourseItem[]>) => {
        const data: CourseItem[] = response.data;
        console.info('TT SchedulePage loadCourses code=' + response.code + ' size=' + data.length);
        if (data.length > 0) {
          this.courseList = data;
          this.syncScheduleToWidget();
        } else if (response.code !== 0) {
          console.info('SchedulePage degrade: code=' + response.code + ' msg=' + response.message);
        }
      })
      .catch((error: BusinessError) => {
        console.info('TT SchedulePage loadCourses fail: ' + error.message);
        this.courseList = [];
      });
  }

  private syncScheduleToWidget(): void {
    try {
      const ctx = this.getUIContext().getHostContext() as common.UIAbilityContext;
      const jsDay: number = new Date().getDay();
      const todayWeekday: number = jsDay === 0 ? 7 : jsDay;
      const summaries: WidgetCourseSummary[] = [];
      for (const c of this.weekCourses()) {
        if (c.dayOfWeek === todayWeekday) {
          summaries.push({
            name: c.name,
            time: `第${c.sectionStart}-${c.sectionEnd}节`,
            place: c.location
          });
        }
      }
      WidgetDataHelper.saveTodaySchedule(ctx, `第${this.weekNumber}周·今日课表`, summaries);
    } catch {
      // 忽略桌面卡片同步异常
    }
  }

  private twoDigit(value: number): string {
    return value < 10 ? '0' + value : '' + value;
  }

  // APK I3()/GetTimeTableUtil.c()：周起始日=ksrq+(week-1)*7，日期条+月份标签重算；今日列高亮仅限本周
  private applyWeek(week: number): void {
    this.weekNumber = week;
    const weekStart: Date = new Date(this.semesterStartMs);
    weekStart.setDate(weekStart.getDate() + (week - 1) * 7);
    this.monthLabel = this.twoDigit(weekStart.getMonth() + 1) + '月';
    const todayIdx: number = this.todayIndexInWeek(weekStart);
    const cells: ScheduleDateCell[] = [];
    for (let i = 0; i < 7; i++) {
      const date: Date = new Date(weekStart.getFullYear(), weekStart.getMonth(), weekStart.getDate() + i);
      // f.b.c()：第一列(i==0)始终显示日期号；非第一列且每月1日该列显示"MM月"
      const dateText: string = (i > 0 && date.getDate() === 1) ?
        this.twoDigit(date.getMonth() + 1) + '月' : this.twoDigit(date.getDate());
      const jsDay: number = date.getDay();
      const weekChar: string = jsDay === 0 ? '日' : WEEK_CHARS[jsDay - 1];
      cells.push(new ScheduleDateCell(dateText, weekChar, i === todayIdx));
    }
    this.dateCells = cells;
    this.gridShown = false;
    setTimeout(() => {
      this.gridShown = true;
    }, 50);
  }

  // APK d.a.u()：今日在展示周内的列索引(0..6)，不在则 -1
  private todayIndexInWeek(weekStart: Date): number {
    const now: Date = new Date();
    const today: Date = new Date(now.getFullYear(), now.getMonth(), now.getDate());
    const diff: number = Math.floor((today.getTime() - weekStart.getTime()) / 86400000);
    return diff >= 0 && diff < 7 ? diff : -1;
  }

  private clampWeek(week: number): number {
    return week < 1 ? 1 : (week > this.maxWeek ? this.maxWeek : week);
  }

  private shiftWeek(delta: number): void {
    this.applyWeek(this.clampWeek(this.weekNumber + delta));
  }

  // APK GetTimeTableUtil.o()：本地查询 timetable_djz==当前周（scheduleOfTerm 按 djz 周次拆行）；
  // djz=0（无周次字段的历史/离线数据）时退回 week 字符串解析
  private courseVisibleInWeek(course: CourseItem): boolean {
    if (course.djz > 0) {
      return course.djz === this.weekNumber;
    }
    const weeks: number[] = this.weekNumbersOf(course);
    return weeks.length === 0 || weeks.indexOf(this.weekNumber) >= 0;
  }

  // APK 课表 week 字符串兜底解析："1-16周"、"1,3,5"、"1-16(单)"
  private weekNumbersOf(course: CourseItem): number[] {
    const out: number[] = [];
    const raw: string = course.week;
    if (raw === '') {
      return out;
    }
    const odd: boolean = raw.indexOf('单') >= 0;
    const even: boolean = raw.indexOf('双') >= 0;
    let cleaned: string = '';
    for (let i = 0; i < raw.length; i++) {
      const ch: string = raw.charAt(i);
      if ((ch >= '0' && ch <= '9') || ch === '-' || ch === ',' || ch === '~') {
        cleaned += ch;
      } else if (ch === '，' || ch === '、' || ch === '/') {
        cleaned += ',';
      }
    }
    const tokens: string[] = cleaned.split(',');
    for (const token of tokens) {
      this.parseWeekToken(token, odd, even, out);
    }
    return out;
  }

  private parseWeekToken(token: string, odd: boolean, even: boolean, out: number[]): void {
    const seg: string = token.trim();
    if (seg.length === 0) {
      return;
    }
    const dash: number = seg.indexOf('-');
    if (dash > 0) {
      const from: number = this.parseIntSafe(seg.substring(0, dash));
      const to: number = this.parseIntSafe(seg.substring(dash + 1));
      for (let i = from; i <= to; i++) {
        this.pushWeekNum(out, i, odd, even);
      }
      return;
    }
    this.pushWeekNum(out, this.parseIntSafe(seg), odd, even);
  }

  private parseIntSafe(text: string): number {
    let digits: string = '';
    for (let i = 0; i < text.length; i++) {
      const ch: string = text.charAt(i);
      if (ch >= '0' && ch <= '9') {
        digits += ch;
      }
    }
    return digits === '' ? 0 : Number(digits);
  }

  private pushWeekNum(out: number[], num: number, odd: boolean, even: boolean): void {
    if (num < 1 || (odd && num % 2 === 0) || (even && num % 2 === 1) || out.indexOf(num) >= 0) {
      return;
    }
    out.push(num);
  }

  private weekCourses(): CourseItem[] {
    const list: CourseItem[] = [];
    for (const course of this.courseList) {
      if (this.courseVisibleInWeek(course)) {
        list.push(course);
      }
    }
    return list;
  }

  private visibleDayCourses(day: number): CourseItem[] {
    const list: CourseItem[] = [];
    for (const course of this.weekCourses()) {
      if (course.dayOfWeek === day) {
        list.push(course);
      }
    }
    return list.sort((a: CourseItem, b: CourseItem) => a.sectionStart - b.sectionStart);
  }

  // APK CourseBox.initSinleDayCourseBoxView()：重叠课程折叠规则
  private foldGroups(day: number): CourseFoldGroup[] {
    const groups: CourseFoldGroup[] = [];
    for (const course of this.visibleDayCourses(day)) {
      const last: CourseFoldGroup | null = groups.length > 0 ? groups[groups.length - 1] : null;
      if (last === null || course.sectionStart > last.end) {
        const group: CourseFoldGroup = new CourseFoldGroup();
        group.items.push(course);
        group.start = course.sectionStart;
        group.end = course.sectionEnd;
        group.display = course;
        groups.push(group);
      } else if (course.sectionStart === last.start && course.sectionEnd > last.end) {
        last.items.unshift(course);
        last.end = course.sectionEnd;
        last.display = course;
      } else {
        last.items.push(course);
      }
    }
    return groups;
  }

  // APK CourseBox.setCourseShowColor()：同名课程同色，按天序循环 showcolor1..14
  private colorIndexOf(course: CourseItem): number {
    const names: string[] = [];
    for (let day = 1; day <= 7; day++) {
      for (const one of this.visibleDayCourses(day)) {
        if (names.indexOf(one.name) < 0) {
          names.push(one.name);
        }
      }
    }
    const idx: number = names.indexOf(course.name);
    return idx < 0 ? 0 : idx % SHOW_COLOR_COUNT;
  }

  private colorOfGroup(group: CourseFoldGroup): number {
    return group.display === null ? 0 : this.colorIndexOf(group.display);
  }

  private openDetail(course: CourseItem): void {
    // WeekCourseFragment.a 回调：putExtra bean/term/xlh；HAP 传 xlh/djz/xqj 三元组
    router.pushUrl({
      url: 'pages/CourseDetailPage',
      params: new DetailParams(course.name, course.week,
        '第' + course.sectionStart + '-' + course.sectionEnd + '节', course.location,
        course.xlh, course.djz > 0 ? String(course.djz) : String(this.weekNumber),
        String(course.dayOfWeek))
    });
  }

  private openMulti(group: CourseFoldGroup): void {
    if (group.display === null) {
      return;
    }
    this.multiCourses = group.items;
    this.multiColorIdx = this.colorIndexOf(group.display);
    this.showMultiDialog = true;
  }

  private termOptions(): TermOption[] {
    return [new TermOption(this.termXn, this.termXq)];
  }

  @Builder
  weekPopupRow(num: number) {
    // ChooseWeeksPopup 条目 timetable_choose_week_item：17fp、padding 15、当前周高亮 common_color_7
    Text('第' + num + '周' + (num === this.todayWeek ? ' (本周)' : ''))
      .fontSize(17)
      .fontColor(num === this.weekNumber ? $r('app.color.ybg_white') : $r('app.color.common_color_3'))
      .backgroundColor(num === this.weekNumber ? $r('app.color.common_color_7') : Color.Transparent)
      .height(WEEK_ITEM_HEIGHT)
      .width('100%')
      .textAlign(TextAlign.Center)
      .maxLines(1)
      .textOverflow({ overflow: TextOverflow.Ellipsis })
      .padding({ left: 15, right: 15 })
      .onClick(() => {
        this.showWeekPopup = false;
        this.applyWeek(num);
      })
  }

  // ChooseWeeksPopup：0x77000000 全屏遮罩 + 白底 6 项列表(setSelection(cur-3))
  @Builder
  weekPopup() {
    Column() {
      Column() {
        List({ scroller: this.weekScroller, space: 0 }) {
          ForEach(this.weekNumbers(), (num: number) => {
            ListItem() {
              this.weekPopupRow(num)
            }
          }, (num: number) => 'wk' + num)
        }
        .scrollBar(BarState.Off)
        .width('100%')
        .height(WEEK_ITEM_HEIGHT * 6)
        .backgroundColor($r('app.color.white'))
      }
      .margin({ top: 46 })
      .onClick(() => {
        // 拦截面板内点击，避免冒泡关闭
      })
    }
    .width('100%')
    .height('100%')
    .alignItems(HorizontalAlign.Start)
    .backgroundColor('#77000000')
    .onClick(() => {
      this.showWeekPopup = false;
    })
  }

  private weekNumbers(): number[] {
    const out: number[] = [];
    for (let i = 1; i <= this.maxWeek; i++) {
      out.push(i);
    }
    return out;
  }

  // WheelView 前后空白填充（使首尾数据项可居中，对应 setVisibleItems(7)）
  private wheelEdgeIndexes(): number[] {
    const out: number[] = [];
    for (let i = 0; i < WHEEL_EDGE_ITEMS; i++) {
      out.push(i);
    }
    return out;
  }

  // wl_chooseterm 滚轮条目：中心项主色高亮
  @Builder
  termWheelRow(option: TermOption, dataIndex: number) {
    Text(option.label())
      .fontSize(dataIndex === this.termWheelIndex ? 17 : 15)
      .fontColor(dataIndex === this.termWheelIndex ? $r('app.color.mobile_campus_primary_color') :
        $r('app.color.common_color_2'))
      .width('100%')
      .height(WHEEL_ITEM_HEIGHT)
      .textAlign(TextAlign.Center)
      .onClick(() => {
        this.termWheelIndex = dataIndex;
        this.termScroller.scrollToIndex(WHEEL_EDGE_ITEMS + dataIndex, true);
      })
  }

  // ChooseTermDialog(d.java)：标题 tv_chooseterm(TextSize2.Color2/px_to_dip_24) +
  // 右上 tv_finish(TextSize2.Color7/hover_grey) + wl_chooseterm 滚轮（滚动停下→完成确认回调）
  @Builder
  termDialog() {
    Stack({ alignContent: Alignment.Bottom }) {
      Column() {
        Blank()
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#66000000')
      .onClick(() => {
        this.showTermDialog = false;
      })

      Column() {
        Row() {
          Text(new TermOption(this.termXn, this.termXq).label())
            .fontSize(17)
            .fontColor($r('app.color.common_color_2'))
            .layoutWeight(1)
            .textAlign(TextAlign.Center)
            .padding(12)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
          Text('完成')
            .fontSize(17)
            .fontColor($r('app.color.mobile_campus_primary_color'))
            .padding(10)
            .backgroundColor($r('app.color.hover_grey'))
            .onClick(() => {
              // d.java a()：滚轮停止→回调当前项→H3(xn,xq) 重载
              const options: TermOption[] = this.termOptions();
              if (this.termWheelIndex < options.length) {
                this.termXq = options[this.termWheelIndex].xq;
              }
              this.showTermDialog = false;
              this.applyWeek(this.clampWeek(this.todayWeek));
            })
        }
        .width('100%')
        .alignItems(VerticalAlign.Center)
        List({ scroller: this.termScroller, space: 0 }) {
          ForEach(this.wheelEdgeIndexes(), (item: number) => {
            ListItem() {
              Column()
                .width('100%')
                .height(WHEEL_ITEM_HEIGHT)
            }
          }, (item: number) => 'edgeTop' + item)
          ForEach(this.termOptions(), (option: TermOption, dataIndex: number) => {
            ListItem() {
              this.termWheelRow(option, dataIndex)
            }
          }, (option: TermOption) => 'term' + option.xq)
          ForEach(this.wheelEdgeIndexes(), (item: number) => {
            ListItem() {
              Column()
                .width('100%')
                .height(WHEEL_ITEM_HEIGHT)
            }
          }, (item: number) => 'edgeEnd' + item)
        }
        .scrollSnapAlign(ScrollSnapAlign.CENTER)
        .onScrollIndex((start: number, end: number) => {
          const dataIdx: number = end - WHEEL_EDGE_ITEMS;
          if (dataIdx >= 0 && dataIdx < this.termOptions().length) {
            this.termWheelIndex = dataIdx;
          }
        })
        .scrollBar(BarState.Off)
        .width('100%')
        .height(WHEEL_ITEM_HEIGHT * WHEEL_VISIBLE_ITEMS)
      }
      .width('100%')
      .backgroundColor($r('app.color.white'))
      .onClick(() => {
        // 拦截面板内点击
      })
    }
  }

  @Builder
  topToolbar() {
    // T1：Toolbar 中央"第N周"(17fp)+右箭头；右侧 termbtn 学年学期入口
    Column() {
      Row() {
        Text('＜')
          .fontSize(17)
          .fontColor($r('app.color.common_color_1'))
          .width(40)
          .height('100%')
          .textAlign(TextAlign.Center)
          .margin({ left: 15 })
          .onClick(() => {
            router.back();
          })
        Row() {
          Text('第' + this.weekNumber + '周')
            .fontSize(17)
            .fontColor($r('app.color.common_color_1'))
          Image($r('app.media.schedule_down_btn'))
            .width(11.5)
            .height(6)
            .margin({ left: 7.5 })
            .rotate({ angle: this.showWeekPopup ? 180 : 0 })
        }
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
        .height('100%')
        .onClick(() => {
          this.showWeekPopup = !this.showWeekPopup;
          if (this.showWeekPopup) {
            setTimeout(() => {
              this.weekScroller.scrollToIndex(Math.max(0, this.weekNumber - 3));
            }, 60);
          }
        })
        Image($r('app.media.mobile_campus_timetable_termbtn'))
          .width(43.5)
          .height(14)
          .margin({ right: 15 })
          .onClick(() => {
            this.termWheelIndex = 0;
            this.showTermDialog = true;
            setTimeout(() => {
              this.termScroller.scrollToIndex(WHEEL_EDGE_ITEMS);
            }, 60);
          })
      }
      .width('100%')
      .height(44)
      .alignItems(VerticalAlign.Center)
      .backgroundColor($r('app.color.main_bg'))
      Divider()
        .color($r('app.color.common_color_5'))
        .strokeWidth(0.5)
        .width('100%')
    }
    .width('100%')
    .height(45)
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP])
  }

  @Builder
  weekHeader() {
    // I3()：month 块宽 50 + 7 列"dd\n周X"(今日 17fp #18B4ED) + 上下周切换
    Row() {
      Text(this.monthLabel)
        .fontSize(16)
        .fontColor($r('app.color.common_color_7'))
        .width(AXIS_WIDTH)
        .textAlign(TextAlign.Center)
      Column() {
        Row() {
          ForEach(this.dateCells, (cell: ScheduleDateCell) => {
            Text(cell.dateText + '\n' + cell.weekChar)
              .fontSize(cell.highlight ? 17 : 13)
              .fontColor(cell.highlight ? $r('app.color.common_color_7') : $r('app.color.common_color_3'))
              .layoutWeight(1)
              .height('100%')
              .textAlign(TextAlign.Center)
          }, (cell: ScheduleDateCell) => 'date' + cell.dateText + cell.weekChar)
        }
        .width('100%')
        .height(45)
        Row() {
          ForEach(this.dateCells, (cell: ScheduleDateCell) => {
            Row()
              .layoutWeight(1)
              .height(1.5)
              .backgroundColor(cell.highlight ? $r('app.color.common_color_7') : Color.Transparent)
          }, (cell: ScheduleDateCell) => 'ul' + cell.dateText + cell.weekChar)
        }
        .width('100%')
      }
      .layoutWeight(1)
      Column() {
        Text('‹')
          .fontSize(18)
          .fontColor($r('app.color.common_color_3'))
          .width(22)
          .height(22)
          .textAlign(TextAlign.Center)
          .onClick(() => {
            this.shiftWeek(-1);
          })
        Text('›')
          .fontSize(18)
          .fontColor($r('app.color.common_color_3'))
          .width(22)
          .height(22)
          .textAlign(TextAlign.Center)
          .onClick(() => {
            this.shiftWeek(1);
          })
      }
      .justifyContent(FlexAlign.Center)
    }
    .width('100%')
    .backgroundColor($r('app.color.common_color_5'))
    .alignItems(VerticalAlign.Center)
  }

  @Builder
  sectionAxisItem(time: string, section: number) {
    Column() {
      Column() {
        Text(time)
          .fontSize(12)
          .fontColor($r('app.color.common_color_3'))
          .width('100%')
          .textAlign(TextAlign.Center)
        Text(section + '')
          .fontSize(16)
          .fontColor($r('app.color.common_color_2'))
          .margin({ top: 4 })
          .width('100%')
          .textAlign(TextAlign.Center)
      }
      .layoutWeight(1)
      .width('100%')
      .backgroundColor($r('app.color.common_color_6'))
      .justifyContent(FlexAlign.Center)
      Divider()
        .color($r('app.color.common_color_5'))
        .strokeWidth(0.5)
        .width('100%')
    }
    .width('100%')
    .height(SECTION_HEIGHT)
  }

  @Builder
  courseBoxCell(group: CourseFoldGroup) {
    Stack({ alignContent: Alignment.TopEnd }) {
      Column() {
        Text(group.display === null ? '' :
          group.display.name + '\n@' + group.display.location)
          .fontSize(12)
          .fontColor($r('app.color.common_color_6'))
          .maxLines((group.end - group.start + 1) * 3)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%')
      }
      .width('100%')
      .height('100%')
      .padding(2)
      .justifyContent(FlexAlign.Start)
      if (group.items.length > 1) {
        Image($r('app.media.mobile_campus_timetable_course_box_multi_tag'))
          .width(9)
          .height(9)
          .margin({ right: 2, top: 2 })
      }
    }
    .width('100%')
    .height((group.end - group.start + 1) * SECTION_HEIGHT)
    .backgroundColor(this.colorPool[this.colorOfGroup(group)])
    .onClick(() => {
      if (group.items.length > 1) {
        this.openMulti(group);
      } else if (group.display !== null) {
        this.openDetail(group.display);
      }
    })
  }

  @Builder
  dayColumn(day: number) {
    Stack({ alignContent: Alignment.TopStart }) {
      ForEach(this.foldGroups(day), (group: CourseFoldGroup) => {
        Column() {
          this.courseBoxCell(group)
        }
        .width('100%')
        .position({ x: 0, y: (group.start - 1) * SECTION_HEIGHT })
      }, (group: CourseFoldGroup) => 'fold' + day + '_' + group.start)
    }
    .layoutWeight(1)
    .height(this.sectionTimes.length * SECTION_HEIGHT)
  }

  @Builder
  courseGrid() {
    Row() {
      Column() {
        ForEach(this.sectionTimes, (time: string, index: number) => {
          this.sectionAxisItem(time, index + 1)
        }, (time: string) => 'axis' + time)
      }
      .width(AXIS_WIDTH)
      Row() {
        ForEach([1, 2, 3, 4, 5, 6, 7], (day: number) => {
          this.dayColumn(day)
        }, (day: number) => 'daycol' + day)
      }
      .layoutWeight(1)
      .height(this.sectionTimes.length * SECTION_HEIGHT)
    }
    .width('100%')
    .opacity(this.gridShown ? 1 : 0.01)
    .animation({ duration: 500, curve: Curve.EaseOut })
  }

  @Builder
  emptyCourseView() {
    Column() {
      Row() {
        Row()
          .width(14)
          .height(1)
          .backgroundColor($r('app.color.timetable_empty_color'))
        Text($r('app.string.timetable_empty'))
          .fontSize(16)
          .fontColor($r('app.color.timetable_empty_color'))
          .margin({ left: 15, right: 15 })
        Row()
          .width(14)
          .height(1)
          .backgroundColor($r('app.color.timetable_empty_color'))
      }
    }
    .width('100%')
    .padding({ top: 25, bottom: 25 })
  }

  // v3/D3/F3：主钮 45° 旋转 + custom/audit 从主钮位置 translationY 上滑展开（500ms 减速）
  @Builder
  fabCluster() {
    Image($r('app.media.mobile_campus_timetable_course_custom'))
      .width(71.5)
      .height(71.5)
      .margin({ right: 10, bottom: 15 + 71.5 })
      .opacity(this.fabExpanded ? 1 : 0)
      .translate({ y: this.fabExpanded ? 0 : 71.5 })
      .enabled(this.fabExpanded)
      .onClick(() => {
        this.fabExpanded = false;
        router.pushUrl({ url: 'pages/AddCoursePage' });
      })
    Image($r('app.media.mobile_campus_timetable_course_audit'))
      .width(71.5)
      .height(71.5)
      .margin({ right: 10, bottom: 15 + 143 })
      .opacity(this.fabExpanded ? 1 : 0)
      .translate({ y: this.fabExpanded ? 0 : 143 })
      .enabled(this.fabExpanded)
      .onClick(() => {
        this.fabExpanded = false;
        router.pushUrl({ url: 'pages/ChooseAcademyPage' });
      })
    Image($r('app.media.mobile_campus_timetable_course_iv_open'))
      .width(71.5)
      .height(71.5)
      .margin({ right: 10, bottom: 15 })
      .rotate({ angle: this.fabExpanded ? 45 : 0 })
      .onClick(() => {
        this.getUIContext().animateTo({ duration: 500, curve: Curve.EaseOut }, () => {
          this.fabExpanded = !this.fabExpanded;
        });
      })
  }

  @Builder
  multiDialogCell(course: CourseItem) {
    Column() {
      Text(course.name + '\n@' + course.location)
        .fontSize(17)
        .fontColor($r('app.color.common_color_6'))
        .maxLines(6)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .padding(20)
    }
    .width('100%')
    .height(140)
    .justifyContent(FlexAlign.Center)
    .backgroundColor(this.colorPool[this.colorIndexOf(course)])
    .onClick(() => {
      this.showMultiDialog = false;
      this.openDetail(course);
    })
  }

  // MultiCoursesDialog(widget/h.java)：透明全屏，内边距 L/R80 T/B100，3 列 Grid 间距 13
  @Builder
  multiDialog() {
    Column() {
      Grid() {
        ForEach(this.multiCourses, (course: CourseItem) => {
          GridItem() {
            this.multiDialogCell(course)
          }
        }, (course: CourseItem) => 'multi' + course.id)
      }
      .columnsTemplate('1fr 1fr 1fr')
      .columnsGap(13)
      .rowsGap(13)
      .width('100%')
      .padding({ left: 80, right: 80, top: 100, bottom: 100 })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .onClick(() => {
      this.showMultiDialog = false;
    })
  }

  build() {
    Stack({ alignContent: Alignment.TopStart }) {
      Column() {
        this.topToolbar()
        this.weekHeader()
        Row()
          .width('100%')
          .height(0.3)
          .backgroundColor($r('app.color.common_color_4'))
        Stack({ alignContent: Alignment.BottomEnd }) {
          if (this.courseList.length === 0) {
            Column() {
              this.emptyCourseView()
            }
            .width('100%')
            .height('100%')
            .justifyContent(FlexAlign.Center)
          } else {
            Scroll() {
              this.courseGrid()
            }
            .width('100%')
            .height('100%')
            .align(Alignment.Top)
            .scrollBar(BarState.Off)
          }
          // G2() 脚注
          Text('*课表数据以教务单位提供为准')
            .fontSize(12)
            .fontColor($r('app.color.common_color_3'))
            .width('100%')
            .textAlign(TextAlign.Center)
            .padding(10)
          this.fabCluster()
        }
        .width('100%')
        .layoutWeight(1)
        .backgroundColor($r('app.color.white'))
      }
      .width('100%')
      .height('100%')
      if (this.showWeekPopup) {
        this.weekPopup()
      }
      if (this.showMultiDialog) {
        this.multiDialog()
      }
      if (this.showTermDialog) {
        this.termDialog()
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.white'))
  }
}
