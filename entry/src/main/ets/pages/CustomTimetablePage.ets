import { router } from '@kit.ArkUI';
import { TitleBar } from '../components/TitleBar';
import { ApiService } from '../network/ApiService';
import { ApiResponse } from '../model/ResponseModel';
import { CourseItem, ScheduleTermParams, CourseSectionsEntry, ClassEntry,
  ScheduleWeekCourse, parseYmdMs, apkCurrentWeek, apkTotalWeeks } from '../model/CourseModel';
import { PreferencesUtil } from '../data/PreferencesUtil';
import { BreakpointSystem } from '../common/BreakpointSystem';
import { AdaptiveLayoutHelper } from '../common/AdaptiveLayoutHelper';

/**
 * 自定义课表页 — 1:1 复刻 timetable/view/CustomTimetableActivity.java（页名 course）
 *
 * 源码还原的 UI 与数据链：
 *   1. 布局 activity_custom_timetable.xml：toolbar_normal(标题"Xn学年第Xq学期" p().get(0)) +
 *      CustomTableSelector(view_custom_table_selector.xml 高38vp：左"第N周▼"|右"班级▼" 平分) +
 *      timetable_week_container(common_color_5)：月宽50 + 7列"dd\n周X"(13fp 今日17fp#18B4ED+
 *      底线) + divider 0.3vp + content；CustomFloatButton 源码 visibility=gone 不渲染
 *   2. 数据链 Z2()：BJCache 命中(cacheBJMC+cacheWeek匹配) 先渲染本地 → 后台刷新；
 *      未命中 c3()：termParams(GetTimeTableUtil 缓存) → getClassList(c 回调) →
 *      getScheduleList{xq,xq,bjmc,djz}(f→X) → BJCache 持久化(i()) → a3→d() 本地读 →
 *      e3→i3() 渲染（K1）
 *   3. 弹窗：ChooseWeeksPopup(widget/f.java 1-25周+"(本周)"标记+当前周高亮)、
 *      ChooseClassPopup(ChooseYearPopup weiget/d.java 班级列表当前行高亮)
 *   4. 网格 WeekCourseFragmentEx+CourseBox：55vp 格/50vp 节次轴/showcolor1..14 按课名分配/
 *      重叠折叠 multi_tag/多课 3 列弹窗；课格点击→CourseDetailActivityEx(bean+xlh) 基础信息
 *   5. 节次轴 courseSections(djj/sksj/xksj)，空列表回退 scheduleMaxClassNum(V1 默认 15)
 *   6. BJCache/courseSections 持久化 = 源码 Hawk d.a.j()/k() 本地缓存语义（PreferencesUtil）
 */
const SECTION_HEIGHT: number = 55;
const AXIS_WIDTH: number = 50;
const SHOW_COLOR_COUNT: number = 14;
const POPUP_ITEM_HEIGHT: number = 53;
const POPUP_VISIBLE: number = 6;
const WEEK_CHARS: string[] = ['一', '二', '三', '四', '五', '六'];
const FALLBACK_MAX_CLASS_NUM: number = 15;
const PREF_BJ_CACHE: string = 'timetable_bj_cache';
const PREF_COURSE_SECTIONS: string = 'timetable_course_sections';

class CustomDateCell {
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

/** 源码 BJCache.java（Hawk 持久化实体）：cacheBJMC/cacheWeek/classes/scheduleOfWeekEntities */
class BJCache {
  cacheBJMC: string = '';
  cacheWeek: string = '';
  classes: ClassEntry[] = [];
  scheduleOfWeekEntities: ScheduleWeekCourse[] = [];

  static fromJson(json: string): BJCache | null {
    if (json === '') {
      return null;
    }
    try {
      const obj: Object = JSON.parse(json) as Object;
      const rec: Record<string, Object> = obj as Record<string, Object>;
      const cache: BJCache = new BJCache();
      const bjmc: Object = rec['cacheBJMC'];
      cache.cacheBJMC = typeof bjmc === 'string' ? bjmc as string : '';
      const week: Object = rec['cacheWeek'];
      cache.cacheWeek = typeof week === 'string' ? week as string : '';
      const rawClasses: Object = rec['classes'];
      if (Array.isArray(rawClasses)) {
        for (const one of rawClasses as Object[]) {
          cache.classes.push(ClassEntry.fromRecord(one as Record<string, Object>));
        }
      }
      const rawCourses: Object = rec['scheduleOfWeekEntities'];
      if (Array.isArray(rawCourses)) {
        for (const one of rawCourses as Object[]) {
          cache.scheduleOfWeekEntities.push(ScheduleWeekCourse.fromRecord(one as Record<string, Object>));
        }
      }
      return cache;
    } catch {
      return null;
    }
  }
}

@Entry
@Component
struct CustomTimetablePage {
  @State termTitle: string = '';
  @State weekNumber: number = 1;
  @State todayWeek: number = -1;
  @State maxWeek: number = 25;
  @State classes: ClassEntry[] = [];
  @State curBjmc: string = '';
  @State curClassIndex: number = 0;
  @State sections: CourseSectionsEntry[] = [];
  @State courseList: CourseItem[] = [];
  @State dateCells: CustomDateCell[] = [];
  @State monthLabel: string = '--月';
  @State showWeekPopup: boolean = false;
  @State showClassPopup: boolean = false;
  @State gridShown: boolean = true;
  @State multiCourses: CourseItem[] = [];
  @State multiColorIdx: number = 0;
  @State showMultiDialog: boolean = false;
  @State loading: boolean = true;
  @StorageProp('currentBreakpoint') currentBreakpoint: string = 'sm';
  @StorageProp('windowWidthVp') windowWidthVp: number = 360;
  @StorageProp('windowHeightVp') windowHeightVp: number = 640;
  @StorageProp('isCompactHeight') isCompactHeight: boolean = false;
  @StorageProp('avoidAreaBottomVp') avoidAreaBottomVp: number = 0;
  private weekScroller: Scroller = new Scroller();
  private classScroller: Scroller = new Scroller();
  private termXn: string = '';
  private termXq: string = '';
  private termStartMs: number = 0;
  private termEndMs: number = 0;
  private cacheHit: boolean = false;
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
    this.loadTermAndCache();
  }

  /** Z2()：BJCache 命中先渲染，再走 termParams→sections→classes→schedule 刷新链 */
  private async loadTermAndCache(): Promise<void> {
    const termResp: ApiResponse<ScheduleTermParams> = await ApiService.getScheduleTermParams();
    const term: ScheduleTermParams = termResp.data;
    if (term.hasStart()) {
      this.applyTermParams(term);
    }
    await this.loadSectionsFromCache();
    const cacheJson: string = await PreferencesUtil.getString(PREF_BJ_CACHE, '');
    const cache: BJCache | null = BJCache.fromJson(cacheJson);
    if (cache !== null && cache.cacheWeek === String(this.weekNumber)) {
      // d()：BJCache 命中 → 本地渲染（classes 供选择器回显）
      this.cacheHit = true;
      this.curBjmc = cache.cacheBJMC;
      this.classes = cache.classes;
      this.applyCourses(cache.scheduleOfWeekEntities);
    }
    await this.refreshChain();
  }

  /** e3()：termParams → 标题/当前周/总周数 */
  private applyTermParams(term: ScheduleTermParams): void {
    this.termXn = term.xn;
    this.termXq = term.xq;
    this.termTitle = term.xn + '学年第' + term.xq + '学期';
    this.termStartMs = parseYmdMs(term.ksrq);
    this.termEndMs = parseYmdMs(term.jsrq);
    const weeks: number = apkTotalWeeks(this.termStartMs, this.termEndMs);
    if (weeks > 0) {
      this.maxWeek = weeks;
    }
    const cur: number = apkCurrentWeek(this.termStartMs, this.termEndMs, new Date().getTime());
    this.todayWeek = cur;
    this.weekNumber = cur > 0 ? cur : 1;
  }

  /** V1() 本地节次轴：courseSections 缓存优先，空表回退 scheduleMaxClassNum */
  private async loadSectionsFromCache(): Promise<void> {
    const json: string = await PreferencesUtil.getString(PREF_COURSE_SECTIONS, '');
    const list: CourseSectionsEntry[] = [];
    if (json !== '') {
      try {
        const raw: Object = JSON.parse(json) as Object;
        if (Array.isArray(raw)) {
          for (const one of raw as Object[]) {
            list.push(CourseSectionsEntry.fromRecord(one as Record<string, Object>));
          }
        }
      } catch {
        // 缓存损坏 → 走网络
      }
    }
    if (list.length === 0) {
      const resp: ApiResponse<CourseSectionsEntry[]> = await ApiService.getCourseSections();
      if (resp.code === 0 && resp.data.length > 0) {
        for (const one of resp.data) {
          list.push(one);
        }
        await PreferencesUtil.putString(PREF_COURSE_SECTIONS, JSON.stringify(list));
      }
    }
    this.sections = list;
  }

  /** c 回调 → X2()：getClassList → 默认班=首项 bjmc（setClassData） */
  private async refreshChain(): Promise<void> {
    if (!this.cacheHit) {
      const classResp: ApiResponse<ClassEntry[]> = await ApiService.getClassList();
      if (classResp.code === 0 && classResp.data.length > 0) {
        this.classes = classResp.data;
        this.curBjmc = this.classes[0].bjmc;
        this.curClassIndex = 0;
      }
    }
    if (this.curBjmc !== '') {
      await this.fetchSchedule();
    } else {
      this.loading = false;
    }
  }

  /** b3()：有网 z.f(xn,xq,bjmc,week) → getScheduleList；成功后 BJCache 持久化（i()） */
  private async fetchSchedule(): Promise<void> {
    this.loading = true;
    const resp: ApiResponse<ScheduleWeekCourse[]> = await ApiService.getScheduleListByClass(
      this.termXn, this.termXq, this.curBjmc, String(this.weekNumber));
    if (resp.code === 0) {
      const cache: BJCache = new BJCache();
      cache.cacheBJMC = this.curBjmc;
      cache.cacheWeek = String(this.weekNumber);
      cache.classes = this.classes;
      cache.scheduleOfWeekEntities = resp.data;
      await PreferencesUtil.putString(PREF_BJ_CACHE, JSON.stringify(cache));
      this.applyCourses(resp.data);
    }
    this.loading = false;
  }

  /** e()/g()：ScheduleOfWeekEntity[] → CourseItem[]（按 xqj 定列）→ 日期条重算 */
  private applyCourses(rows: ScheduleWeekCourse[]): void {
    const items: CourseItem[] = [];
    for (const row of rows) {
      items.push(new CourseItem(row.xlh, row.kcmc, row.skls, row.skdd, row.djz,
        Number(row.xqj) || 0, Number(row.ksjc) || 0, Number(row.jsjc) || 0,
        Number(row.xf) || 0, row.kcxz));
    }
    this.courseList = items;
    this.applyWeekHeader();
    this.gridShown = false;
    setTimeout(() => {
      this.gridShown = true;
    }, 50);
  }

  /** c()/u()/g3()：周起始=ksrq+(week-1)*7，日期条+月份标签+今日列高亮 */
  private applyWeekHeader(): void {
    if (this.termStartMs <= 0) {
      this.dateCells = [];
      return;
    }
    const weekStartMs: number = this.termStartMs + (this.weekNumber - 1) * 604800000;
    const weekStart: Date = new Date(weekStartMs);
    this.monthLabel = this.twoDigit(weekStart.getMonth() + 1) + '月';
    const todayIdx: number = this.todayIndexInWeek(weekStart);
    const cells: CustomDateCell[] = [];
    for (let i = 0; i < 7; i++) {
      const date: Date = new Date(weekStart.getFullYear(), weekStart.getMonth(), weekStart.getDate() + i);
      const dateText: string = (i > 0 && date.getDate() === 1) ?
        this.twoDigit(date.getMonth() + 1) + '月' : this.twoDigit(date.getDate());
      const jsDay: number = date.getDay();
      const weekChar: string = jsDay === 0 ? '日' : WEEK_CHARS[jsDay - 1];
      cells.push(new CustomDateCell(dateText, weekChar, i === todayIdx));
    }
    this.dateCells = cells;
  }

  private todayIndexInWeek(weekStart: Date): number {
    const now: Date = new Date();
    const today: Date = new Date(now.getFullYear(), now.getMonth(), now.getDate());
    const diff: number = Math.floor((today.getTime() - weekStart.getTime()) / 86400000);
    return diff >= 0 && diff < 7 ? diff : -1;
  }

  private twoDigit(value: number): string {
    return value < 10 ? '0' + value : '' + value;
  }

  // ===== 网格（WeekCourseFragmentEx + CourseBox 折叠/配色 1:1） =====

  private visibleDayCourses(day: number): CourseItem[] {
    const list: CourseItem[] = [];
    for (const course of this.courseList) {
      if (course.dayOfWeek === day) {
        list.push(course);
      }
    }
    return list.sort((a: CourseItem, b: CourseItem) => a.sectionStart - b.sectionStart);
  }

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

  /** CourseBox.a 回调：单格点击 → CourseDetailActivityEx(bean,xlh)（基础信息模式） */
  private openDetail(course: CourseItem): void {
    // CourseDetailActivityEx.T2：周数=djz、节次="周X ksjc-jsjc节"（SERVER="-"）、上课时间=d.a.b(ksjc,jsjc)
    router.pushUrl({
      url: 'pages/CourseDetailPage',
      params: {
        'mode': 'custom',
        'xlh': course.xlh,
        'courseName': course.name,
        'weekTime': course.week,
        'session': '周' + this.weekCharOf(course.dayOfWeek) + ' ' +
          course.sectionStart + '-' + course.sectionEnd + '节',
        'place': course.location,
        'teacher': course.teacher
      }
    });
  }

  private weekCharOf(day: number): string {
    return day >= 1 && day <= 6 ? WEEK_CHARS[day - 1] : '日';
  }

  private openMulti(group: CourseFoldGroup): void {
    if (group.display === null) {
      return;
    }
    this.multiCourses = group.items;
    this.multiColorIdx = this.colorIndexOf(group.display);
    this.showMultiDialog = true;
  }

  // ===== UI =====

  @Builder
  weekPopupRow(num: number) {
    Text('第' + num + '周' + (num === this.todayWeek ? ' (本周)' : ''))
      .fontSize(17)
      .fontColor(num === this.weekNumber ? $r('app.color.ybg_white') : $r('app.color.common_color_3'))
      .backgroundColor(num === this.weekNumber ? $r('app.color.common_color_7') : Color.Transparent)
      .height(POPUP_ITEM_HEIGHT)
      .width('100%')
      .textAlign(TextAlign.Center)
      .maxLines(1)
      .textOverflow({ overflow: TextOverflow.Ellipsis })
      .padding({ left: 15, right: 15 })
      .hoverEffect(HoverEffect.Highlight)
      .onClick(() => {
        this.showWeekPopup = false;
        if (num !== this.weekNumber) {
          this.weekNumber = num;
          this.applyWeekHeader();
          this.fetchSchedule();
        }
      })
  }

  @Builder
  weekPopup() {
    Column() {
      Scroll() {
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
          .height(Math.min(POPUP_ITEM_HEIGHT * POPUP_VISIBLE, BreakpointSystem.getDialogMaxHeight(this.windowHeightVp)))
          .backgroundColor($r('app.color.white'))
        }
        .width('100%')
      }
      .width('100%')
      .constraintSize({
        maxWidth: AdaptiveLayoutHelper.getSheetMaxWidth(this.currentBreakpoint, this.windowWidthVp),
        maxHeight: BreakpointSystem.getDialogMaxHeight(this.windowHeightVp)
      })
      .margin({ top: this.isCompactHeight ? 75 : 83 })
      .borderRadius(this.currentBreakpoint === 'xs' || this.currentBreakpoint === 'sm' ? 0 : 12)
      .clip(true)
      .onClick(() => {
        // 拦截面板内点击
      })
    }
    .width('100%')
    .height('100%')
    .alignItems(HorizontalAlign.Center)
    .backgroundColor('#66000000')
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

  /** ChooseClassPopup（ChooseYearPopup）：班级名列表，当前行高亮 */
  @Builder
  classPopupRow(name: string, index: number) {
    Text(name)
      .fontSize(17)
      .fontColor(index === this.curClassIndex ? $r('app.color.ybg_white') : $r('app.color.common_color_3'))
      .backgroundColor(index === this.curClassIndex ? $r('app.color.common_color_7') : Color.Transparent)
      .height(POPUP_ITEM_HEIGHT)
      .width('100%')
      .textAlign(TextAlign.Center)
      .maxLines(1)
      .textOverflow({ overflow: TextOverflow.Ellipsis })
      .padding({ left: 15, right: 15 })
      .hoverEffect(HoverEffect.Highlight)
      .onClick(() => {
        this.showClassPopup = false;
        if (index !== this.curClassIndex) {
          this.curClassIndex = index;
          this.curBjmc = name;
          this.fetchSchedule();
        }
      })
  }

  @Builder
  classPopup() {
    Column() {
      Scroll() {
        Column() {
          List({ scroller: this.classScroller, space: 0 }) {
            ForEach(this.classes, (cls: ClassEntry, index: number) => {
              ListItem() {
                this.classPopupRow(cls.bjmc, index)
              }
            }, (cls: ClassEntry) => 'cls' + cls.bjmc)
          }
          .scrollBar(BarState.Off)
          .width('100%')
          .height(Math.min(POPUP_ITEM_HEIGHT * POPUP_VISIBLE, BreakpointSystem.getDialogMaxHeight(this.windowHeightVp)))
          .backgroundColor($r('app.color.white'))
        }
        .width('100%')
      }
      .width('100%')
      .constraintSize({
        maxWidth: AdaptiveLayoutHelper.getSheetMaxWidth(this.currentBreakpoint, this.windowWidthVp),
        maxHeight: BreakpointSystem.getDialogMaxHeight(this.windowHeightVp)
      })
      .margin({ top: this.isCompactHeight ? 75 : 83 })
      .borderRadius(this.currentBreakpoint === 'xs' || this.currentBreakpoint === 'sm' ? 0 : 12)
      .clip(true)
      .onClick(() => {
        // 拦截面板内点击
      })
    }
    .width('100%')
    .height('100%')
    .alignItems(HorizontalAlign.Center)
    .backgroundColor('#66000000')
    .onClick(() => {
      this.showClassPopup = false;
    })
  }

  @Builder
  selectorRow() {
    Row() {
      Row() {
        Text('第' + this.weekNumber + '周')
          .fontSize(15)
          .fontColor($r('app.color.common_color_1'))
        Image($r('app.media.schedule_down_btn'))
          .width(11.5)
          .height(6)
          .margin({ left: 8 })
      }
      .layoutWeight(1)
      .height('100%')
      .justifyContent(FlexAlign.Center)
      .onClick(() => {
        this.showWeekPopup = !this.showWeekPopup;
        if (this.showWeekPopup) {
          setTimeout(() => {
            this.weekScroller.scrollToIndex(Math.max(0, this.weekNumber - 3));
          }, 60);
        }
      })
      Divider()
        .vertical(true)
        .color($r('app.color.common_color_5'))
        .strokeWidth(0.5)
        .height('100%')
      Row() {
        Text(this.curBjmc === '' ? '选择班级' : this.curBjmc)
          .fontSize(15)
          .fontColor($r('app.color.common_color_1'))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        Image($r('app.media.schedule_down_btn'))
          .width(11.5)
          .height(6)
          .margin({ left: 8 })
      }
      .layoutWeight(1)
      .height('100%')
      .justifyContent(FlexAlign.Center)
      .padding({ left: 8, right: 8 })
      .onClick(() => {
        // [W16 course-select] 源码 CustomTableSelector.layoutClass onClick → showClassPopWindow()
        // 无 classes 非空守卫：空列表同样弹出（数据源 getClassList 已接）
        this.showClassPopup = !this.showClassPopup;
        if (this.showClassPopup) {
          setTimeout(() => {
            this.classScroller.scrollToIndex(Math.max(0, this.curClassIndex - 3));
          }, 60);
        }
      })
    }
    .width('100%')
    .height(38)
    .alignItems(VerticalAlign.Center)
    .backgroundColor($r('app.color.white'))
  }

  @Builder
  weekHeader() {
    Row() {
      Text(this.monthLabel)
        .fontSize(16)
        .fontColor($r('app.color.common_color_7'))
        .width(AXIS_WIDTH)
        .textAlign(TextAlign.Center)
      Column() {
        Row() {
          ForEach(this.dateCells, (cell: CustomDateCell) => {
            Text(cell.dateText + '\n' + cell.weekChar)
              .fontSize(cell.highlight ? 17 : 13)
              .fontColor(cell.highlight ? $r('app.color.common_color_7') : $r('app.color.common_color_3'))
              .layoutWeight(1)
              .height('100%')
              .textAlign(TextAlign.Center)
          }, (cell: CustomDateCell) => 'date' + cell.dateText + cell.weekChar)
        }
        .width('100%')
        .height(45)
        Row() {
          ForEach(this.dateCells, (cell: CustomDateCell) => {
            Row()
              .layoutWeight(1)
              .height(1.5)
              .backgroundColor(cell.highlight ? $r('app.color.common_color_7') : Color.Transparent)
          }, (cell: CustomDateCell) => 'ul' + cell.dateText + cell.weekChar)
        }
        .width('100%')
      }
      .layoutWeight(1)
    }
    .width('100%')
    .backgroundColor($r('app.color.common_color_5'))
    .alignItems(VerticalAlign.Center)
  }

  @Builder
  sectionAxisItem(timeTop: string, section: number) {
    Column() {
      Column() {
        Text(timeTop)
          .fontSize(12)
          .fontColor($r('app.color.common_color_3'))
          .width('100%')
          .textAlign(TextAlign.Center)
          .maxLines(1)
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
    .height(this.axisRows() * SECTION_HEIGHT)
  }

  private axisRows(): number {
    return this.sections.length > 0 ? this.sections.length : FALLBACK_MAX_CLASS_NUM;
  }

  private sectionTimeOf(index: number): string {
    // b(ksjc,jsjc)：courseSections.sksj → 轴顶时间；无数据留空
    if (index < this.sections.length) {
      return this.sections[index].sksj;
    }
    return '';
  }

  @Builder
  courseGrid() {
    Row() {
      Column() {
        ForEach(this.axisRowIndexes(), (row: number) => {
          this.sectionAxisItem(this.sectionTimeOf(row), row + 1)
        }, (row: number) => 'axis' + row)
      }
      .width(AXIS_WIDTH)
      Row() {
        ForEach([1, 2, 3, 4, 5, 6, 7], (day: number) => {
          this.dayColumn(day)
        }, (day: number) => 'daycol' + day)
      }
      .layoutWeight(1)
      .height(this.axisRows() * SECTION_HEIGHT)
    }
    .width('100%')
    .opacity(this.gridShown ? 1 : 0.01)
    .animation({ duration: 500, curve: Curve.EaseOut })
  }

  private axisRowIndexes(): number[] {
    const out: number[] = [];
    for (let i = 0; i < this.axisRows(); i++) {
      out.push(i);
    }
    return out;
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
    .borderRadius(8)
    .justifyContent(FlexAlign.Center)
    .backgroundColor(this.colorPool[this.colorIndexOf(course)])
    .hoverEffect(HoverEffect.Highlight)
    .onClick(() => {
      this.showMultiDialog = false;
      this.openDetail(course);
    })
  }

  @Builder
  multiDialog() {
    Column() {
      Scroll() {
        Column() {
          Grid() {
            ForEach(this.multiCourses, (course: CourseItem) => {
              GridItem() {
                this.multiDialogCell(course)
              }
            }, (course: CourseItem) => 'multi' + course.xlh + course.dayOfWeek)
          }
          .columnsTemplate(AdaptiveLayoutHelper.buildColumnsTemplate(
            BreakpointSystem.getGridColumns(this.currentBreakpoint, 3)
          ))
          .columnsGap(13)
          .rowsGap(13)
          .width('100%')
          .height(AdaptiveLayoutHelper.computeGridHeightVp(
            this.multiCourses.length,
            BreakpointSystem.getGridColumns(this.currentBreakpoint, 3),
            140,
            13,
            32
          ))
          .padding(16)
        }
        .width('100%')
      }
      .width('100%')
      .constraintSize({
        maxWidth: BreakpointSystem.getDialogMaxWidth(this.currentBreakpoint, this.windowWidthVp),
        maxHeight: BreakpointSystem.getDialogMaxHeight(this.windowHeightVp)
      })
      .backgroundColor($r('app.color.white'))
      .borderRadius(12)
      .clip(true)
      .onClick(() => {
        // 拦截弹窗内部点击
      })
    }
    .width('100%')
    .height('100%')
    .padding({ left: 16, right: 16 })
    .backgroundColor('#66000000')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .onClick(() => {
      this.showMultiDialog = false;
    })
  }

  build() {
    Stack({ alignContent: Alignment.TopStart }) {
      Column() {
        TitleBar({ title: this.termTitle === '' ? '自定义课表' : this.termTitle, showBack: true })
        Column() {
          this.selectorRow()
          this.weekHeader()
          Row()
            .width('100%')
            .height(0.3)
            .backgroundColor($r('app.color.common_color_4'))
          Stack() {
            if (this.loading) {
              Column()
                .width('100%')
                .height('100%')
            } else if (this.courseList.length === 0) {
              Scroll() {
                Column() {
                  Text($r('app.string.timetable_empty'))
                    .fontSize(16)
                    .fontColor($r('app.color.timetable_empty_color'))
                }
                .width('100%')
                .constraintSize({ minHeight: 280 })
                .justifyContent(FlexAlign.Center)
              }
              .width('100%')
              .height('100%')
            } else {
              Scroll() {
                Column() {
                  this.courseGrid()
                }
                .width('100%')
                .padding({ bottom: this.avoidAreaBottomVp })
              }
              .width('100%')
              .height('100%')
              .align(Alignment.Top)
              .scrollBar(BarState.Off)
            }
          }
          .width('100%')
          .layoutWeight(1)
          .backgroundColor($r('app.color.white'))
        }
        .width('100%')
        .layoutWeight(1)
        .constraintSize({ maxWidth: BreakpointSystem.getContentMaxWidth(this.currentBreakpoint) })
        .alignSelf(ItemAlign.Center)
      }
      .width('100%')
      .height('100%')
      if (this.showWeekPopup) {
        this.weekPopup()
      }
      if (this.showClassPopup) {
        this.classPopup()
      }
      if (this.showMultiDialog) {
        this.multiDialog()
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.white'))
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.BOTTOM])
  }
}
