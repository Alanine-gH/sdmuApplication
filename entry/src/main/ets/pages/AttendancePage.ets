import { router } from '@kit.ArkUI';
import { BusinessError } from '@kit.BasicServicesKit';
import { ApiService } from '../network/ApiService';
import { ApiResponse } from '../model/ResponseModel';
import { AttendanceIsBoss, AttendanceIndex, AttendanceRecordByMonthBean, AttendanceByDayBean,
  AttendanceBossIndex, AttendanceGroupBean, AttendancePeopleListBean } from '../model/AttendanceModel';
import { TitleBar } from '../components/TitleBar';
import { EmptyView } from '../components/EmptyView';
import { LoadingView } from '../components/LoadingView';
import { Constants } from '../data/Constants';

/**
 * 考勤页 — 源码级逐行翻译：
 *   com.lysoft.android.lyyd.attendance.view.AttendanceMainActivity（159 行）
 *   + AttendancePersonalFragment（335 行）+ AttendanceListFragment（140 行）
 *   + AttendanceLeaderFragment（179 行）+ adapter/a（AttendanceAdapter 168 行）
 *   + widget/AttendanceStateView / AttendanceDateStateView / AttendanceSingleMonthView /
 *     AttendanceSingleWeekView / AttendanceContentLayout
 *
 * 【页面结构 attendance_activity_main.xml】toolbar_normal(标题"考勤月历" T1)+TabLayout
 *   (高 px_to_dip_80=40vp、tabGravity=center、指示条高 0、选中 mobile_campus_primary_color_default
 *   #1B68B7、未选中 #333333、textSize px_to_dip_28=14fp；l={"个人考勤记录","院系月份统计"})
 *   + ViewPager(FragmentPagerAdapter：个人页恒有，isBoss=="1" 时加院系页)
 *
 * 【数据流】（AttendancePresenter c/e/a/a/a/c/a + AttendanceModel c/e/a/a/a/b/a）
 *   M2 → GET /mobileapi_ydxy/api/attendanceByMonth/isBoss → isBoss=="1" 才显示两页签
 *   个人页 l1(month="yyyyMM") → POST .../index → attendanceRecordByMonth{days→tvDay1,
 *     dayOfAttendance→tvDay2, errorRecord→B1 三/两个 AttendanceStateView,
 *     attendanceByDay→日历 scheme 点(n/e1 type→色) + n(dayMap)}
 *   院系页 T1(month="yyyy-MM") → POST .../bossIndex → tvCount"考勤人数N人" + ExpandableListView
 *     (组=attendance_view_group 48vp；子=attendance_view_child 64vp；子点击→/attendance/personal{id})
 *
 * 【日历】haibin CalendarView：default_status=shrink（初始周模式）、month_view=mode_only_current、
 *   week_start_with=mon、calendar_height=40dip、calendar_padding=10dip、week_bar_height=40dip、
 *   selected_theme_color=#388CFC、current_day_text_color=#388CFC、scheme_theme_color=#128C4B、
 *   scheme 圆点 b.a(3)=3vp 半径（dip→px，非 px→dip）；月↔周手势切换 = CalendarLayout 展开/收起。
 *   源码 b.a(onMonthChange)：tvDate="i年i2月" + l1(String(year)+String(month))；源码单月不补零，
 *   实测服务器 "20263"→0001，HAP 补零为 "202603"（唯一有意偏离，详见报告）。
 *   c.a(onWeekChange)：周有数据日期进列表 tips 隐藏；d.a(select)：tvDate+班次/考勤组 tips+单日列表。
 */
const WEEK_LABELS: string[] = ['一', '二', '三', '四', '五', '六', '日'];
/** 源码 AttendanceMainActivity.l 静态数组 */
const TAB_TITLES: string[] = ['个人考勤记录', '院系月份统计'];
/** 源码 AttendanceStateView.setState：type → 前缀（default "缺勤:"） */
const STATE_PREFIX: Record<string, string> = { 'Absense': '缺勤：', 'NotSigned': '缺卡：', 'Leave': '请假：' };
/** 源码 AttendanceStateView.setState：type → 圆点色（attendance_shape_round_*） */
const STATE_DOT: Record<string, string> = { 'Absense': '#EE6D60', 'NotSigned': '#F4AD4E', 'Leave': '#F9D730' };
/** 源码 AttendancePersonalFragment.e1：type → attendance_*_color */
const SCHEME_COLOR: Record<string, string> = {
  'Normal': '#388CFC', 'NotSigned': '#F4AD4E', 'Leave': '#F9D730', 'Absense': '#EE6D60'
};

/** haibin Calendar 单元格载体（key=yyyy-MM-dd，对齐 n/dayMap 与 schemeMap） */
class CalCell {
  year: number;
  month: number;
  day: number;
  key: string;
  inMonth: boolean;

  constructor(year: number, month: number, day: number, key: string, inMonth: boolean) {
    this.year = year;
    this.month = month;
    this.day = day;
    this.key = key;
    this.inMonth = inMonth;
  }
}

/** 子页路由参数（源码 Bundle putString("id", userId)） */
interface AttendanceNavParams {
  id: string;
}

function pad2(n: number): string {
  return n < 10 ? '0' + String(n) : String(n);
}

function dateKey(year: number, month: number, day: number): string {
  return String(year) + '-' + pad2(month) + '-' + pad2(day);
}

@Entry
@Component
struct AttendancePage {
  // ===== AttendanceMainActivity =====
  @State showLeaderTabs: boolean = false;
  @State activeTab: number = 0;
  // ===== AttendancePersonalFragment（个人考勤记录） =====
  @State dateTitle: string = '';
  @State day1: string = '0';
  @State day2: string = '0';
  @State errorTimes: Record<string, string> = {};
  @State schemeMap: Record<string, string> = {};
  @State dayMap: Record<string, AttendanceByDayBean> = {};
  @State calYear: number = 2026;
  @State calMonth: number = 1;
  @State expanded: boolean = false;
  @State selectedKey: string = '';
  @State tips: string = '';
  @State dayRecords: AttendanceByDayBean[] = [];
  @State personalLoading: boolean = false;
  @State showPicker: boolean = false;
  @State selYear: number = 2026;
  @State selMonth: number = 1;
  // ===== AttendanceLeaderFragment（院系月份统计） =====
  @State leaderMonth: string = '';
  @State leaderNum: string = '';
  @State bossGroups: AttendanceGroupBean[] = [];
  @State expandedGroup: number = -1;
  @State leaderLoading: boolean = false;
  /** 周模式锚点（周一 key）；'' 时按选中日/今天推导（haibin getCurrentWeekCalendars） */
  private weekAnchorKey: string = '';

  aboutToAppear(): void {
    const now: Date = new Date();
    this.calYear = now.getFullYear();
    this.calMonth = now.getMonth() + 1;
    this.selYear = this.calYear;
    this.selMonth = this.calMonth;
    // 源码 b.a：tvDate = "i年i2月"（CalendarView 初始化即回调 onMonthChange）
    this.dateTitle = String(this.calYear) + '年' + String(this.calMonth) + '月';
    this.loadIsBoss();
    // 源码 onViewCreated：l1(e.e(new SimpleDateFormat("yyyyMM")))
    this.loadIndex(this.currentPersonalMonth());
  }

  // ===== 数据加载 =====

  /** 源码 AttendanceMainActivity.M2 + 内部类 a：isBoss=="1" → 显示两页签；否则/失败仅个人页 */
  private loadIsBoss(): void {
    ApiService.getAttendanceIsBoss()
      .then((response: ApiResponse<AttendanceIsBoss>) => {
        if (response.code === 1000) {
          this.handleNotLogin();
          return;
        }
        if (response.code === 0 && response.data.isBoss === '1') {
          this.showLeaderTabs = true;
          this.loadBossIndex(this.currentLeaderMonth());
        }
      })
      .catch((error: BusinessError) => {
        ApiService.logError('Attendance isBoss fail: ' + error.message);
      });
  }

  /** 源码 AttendancePersonalFragment.l1 → AttendanceModel.V0：POST index {month} */
  private loadIndex(month: string): void {
    this.personalLoading = true;
    ApiService.getAttendanceIndex(month)
      .then((response: ApiResponse<AttendanceIndex>) => {
        this.personalLoading = false;
        if (response.code === 1000) {
          this.handleNotLogin();
          return;
        }
        if (response.code === 0) {
          this.applyIndex(response.data);
        }
      })
      .catch((error: BusinessError) => {
        this.personalLoading = false;
        ApiService.logError('Attendance index fail: ' + error.message);
      });
  }

  /** 源码 内部类 h.g()：tvDay1/tvDay2 + B1(state) + n/setSchemeDate 全部回填 */
  private applyIndex(index: AttendanceIndex): void {
    const month: AttendanceRecordByMonthBean = index.attendanceRecordByMonth;
    this.day1 = month.days;
    this.day2 = month.dayOfAttendance;
    const times: Record<string, string> = {};
    for (const err of month.errorRecord) {
      times[err.errorDetailType] = err.errorDetailTimes;
    }
    this.errorTimes = times;
    const days: Record<string, AttendanceByDayBean> = {};
    const schemes: Record<string, string> = {};
    for (const bean of month.attendanceByDay) {
      // 源码 split(Constants.ACCEPT_TIME_SEPARATOR_SERVER="-")：date 为 yyyy-MM-dd
      const parts: string[] = bean.date.split('-');
      if (parts.length < 3) {
        continue;
      }
      const key: string = dateKey(Number(parts[0]), Number(parts[1]), Number(parts[2]));
      days[key] = bean;
      schemes[key] = this.schemeColorOf(bean.type);
    }
    this.dayMap = days;
    this.schemeMap = schemes;
    // 源码 CalendarView 初始化/setSchemeDate 后由 WeekViewPager.onPageSelected 回调 c.a：
    // 周模式默认把当前周有数据的日期填入列表（否则进页后列表为空，需等用户点日期）
    if (!this.expanded) {
      this.onWeekChanged();
    }
  }

  /** 源码 AttendanceLeaderFragment.T1 → AttendanceModel.T0：POST bossIndex {month} */
  private loadBossIndex(month: string): void {
    this.leaderMonth = month;
    this.leaderLoading = true;
    ApiService.getAttendanceBossIndex(month)
      .then((response: ApiResponse<AttendanceBossIndex>) => {
        this.leaderLoading = false;
        if (response.code === 1000) {
          this.handleNotLogin();
          return;
        }
        if (response.code === 0) {
          this.leaderNum = response.data.num;
          this.bossGroups = response.data.attendanceList;
          this.expandedGroup = -1;
        }
      })
      .catch((error: BusinessError) => {
        this.leaderLoading = false;
        ApiService.logError('Attendance bossIndex fail: ' + error.message);
      });
  }

  /** 会话失效统一处理（PersonalDetailPage 样板：toast + 重登） */
  private handleNotLogin(): void {
    this.getUIContext().getPromptAction().showToast({ message: '登录已失效，请重新登录' });
    router.replaceUrl({ url: 'pages/LoginPage' });
  }

  /** 当前月（SimpleDateFormat yyyyMM） */
  private currentPersonalMonth(): string {
    return String(this.calYear) + pad2(this.calMonth);
  }

  /** 当前月（SimpleDateFormat yyyy-MM，Leader 页 tvDate 初值） */
  private currentLeaderMonth(): string {
    const now: Date = new Date();
    return String(now.getFullYear()) + '-' + pad2(now.getMonth() + 1);
  }

  // ===== 个人页交互 =====

  /** 源码 内部类 b.a：月切换 → tvDate + l1(month)。
   *  源码原文 String.valueOf(year)+String.valueOf(month)（单月不补零）；实测服务器 "20263" 返回 0001，
   *  故 HAP 按 SimpleDateFormat("yyyyMM") 语义补零为 "202603"（唯一有意偏离，见报告）。 */
  private onMonthChanged(year: number, month: number): void {
    this.calYear = year;
    this.calMonth = month;
    this.weekAnchorKey = '';
    this.dateTitle = String(year) + '年' + String(month) + '月';
    this.loadIndex(String(year) + pad2(month));
    if (this.selectedKey !== '' && !this.selectedKey.startsWith(String(year) + '-' + pad2(month))) {
      this.selectedKey = '';
    }
  }

  /** 源码 内部类 d.a：选中日 → tvDate + "班次：..    考勤组：.." + 单日记录 */
  private onDaySelected(cell: CalCell): void {
    // 源码 d.a：点击周视图的前/后月补位日会先切换 CalendarView 月份（MonthView.onClick → setCurrentItem）
    if (!cell.inMonth && (cell.year !== this.calYear || cell.month !== this.calMonth)) {
      this.onMonthChanged(cell.year, cell.month);
    }
    this.selectedKey = cell.key;
    this.weekAnchorKey = this.mondayKeyOf(cell.year, cell.month, cell.day);
    this.dateTitle = String(cell.year) + '年' + String(cell.month) + '月';
    const bean: AttendanceByDayBean | null = this.dayOf(cell.key);
    const beans: AttendanceByDayBean[] = [];
    if (bean !== null) {
      beans.push(bean);
      this.tips = '班次：' + bean.classes + '    考勤组：' + bean.attendanceGroup;
    } else {
      this.tips = '';
    }
    this.dayRecords = beans;
  }

  /** 源码 内部类 c.a + f.a(false)：周模式 → 本周有数据日期进列表、tips 隐藏 */
  private onWeekChanged(): void {
    const cells: CalCell[] = this.currentWeekCells();
    const beans: AttendanceByDayBean[] = [];
    for (const cell of cells) {
      const bean: AttendanceByDayBean | null = this.dayOf(cell.key);
      if (bean !== null) {
        beans.push(bean);
      }
    }
    this.tips = '';
    this.dayRecords = beans;
  }

  /** 源码 内部类 f.a（onViewChange）：收起时刷新周列表 */
  private setExpanded(value: boolean): void {
    if (this.expanded === value) {
      return;
    }
    this.expanded = value;
    if (!value) {
      this.onWeekChanged();
    }
  }

  /** 水平翻月（CalendarView 左右滑动 → b.a） */
  private shiftMonth(delta: number): void {
    const total: number = this.calYear * 12 + (this.calMonth - 1) + delta;
    const year: number = Math.floor(total / 12);
    const month: number = total % 12 + 1;
    this.onMonthChanged(year, month);
  }

  /** 周模式翻周（跨月时同步 b.a 月切换） */
  private shiftWeek(delta: number): void {
    const cells: CalCell[] = this.currentWeekCells();
    const anchor: CalCell = cells[0];
    const target: Date = new Date(anchor.year, anchor.month - 1, anchor.day + delta * 7);
    const y: number = target.getFullYear();
    const m: number = target.getMonth() + 1;
    this.weekAnchorKey = dateKey(y, m, target.getDate());
    if (y !== this.calYear || m !== this.calMonth) {
      this.calYear = y;
      this.calMonth = m;
      this.dateTitle = String(y) + '年' + String(m) + '月';
      this.loadIndex(String(y) + pad2(m));
    }
    this.onWeekChanged();
  }

  /** 打开年月选择器（源码 r1()/U1()：bigkoo pickerview 默认选中今天） */
  private pickMonth(): void {
    const now: Date = new Date();
    this.selYear = now.getFullYear();
    this.selMonth = now.getMonth() + 1;
    this.showPicker = true;
  }

  /** 选择器确定：个人页 expand+scrollToCalendar(y,m,1)；Leader 页 set tvDate + T1 重载 */
  private onPickerConfirm(): void {
    const year: number = this.selYear;
    const month: number = this.selMonth;
    this.showPicker = false;
    if (this.showLeaderTabs && this.activeTab === 1) {
      this.loadBossIndex(String(year) + '-' + pad2(month));
      return;
    }
    this.expanded = true;
    if (year !== this.calYear || month !== this.calMonth) {
      this.onMonthChanged(year, month);
    }
    this.onDaySelected(new CalCell(year, month, 1, dateKey(year, month, 1), true));
  }

  /** 源码 c.a：子项点击 → Z0("/attendance/personal", {id:userId}) */
  private openPersonalPage(userId: string): void {
    const params: AttendanceNavParams = { id: userId };
    router.pushUrl({ url: 'pages/AttendancePersonalPage', params: params });
  }

  /** 源码 d.a：手风琴展开（展开新组先收起上一组；点已展开组收起） */
  private toggleGroup(index: number): void {
    this.expandedGroup = this.expandedGroup === index ? -1 : index;
  }

  // ===== 数据/日期小工具 =====

  private dayOf(key: string): AttendanceByDayBean | null {
    const bean: AttendanceByDayBean = this.dayMap[key];
    return bean === undefined ? null : bean;
  }

  private schemeColorOf(type: string): string {
    const color: string = SCHEME_COLOR[type];
    return color === undefined ? '#388CFC' : color;
  }

  private dayDotColor(key: string): string {
    // 源码 AttendanceSingleMonthView.onDrawText：选中且有 scheme 时圆点用 mSelectTextPaint（白色）
    if (key === this.selectedKey && this.schemeMap[key] !== undefined) {
      return '#FFFFFF';
    }
    const color: string = this.schemeMap[key];
    return color === undefined ? '#00000000' : color;
  }

  /** 源码 AttendanceStateView.setState + setData：前缀 + 次数 + "天" */
  private stateText(type: string): string {
    const prefix: string = STATE_PREFIX[type];
    const times: string = this.errorTimes[type];
    return (prefix === undefined ? '缺勤:' : prefix) + (times === undefined ? '0' : times) + '天';
  }

  /** 源码 AttendanceStateView.setState：圆点色（default=absenteeism） */
  private stateDotColor(type: string): string {
    const color: string = STATE_DOT[type];
    return color === undefined ? '#EE6D60' : color;
  }

  /** AttendanceDateStateView：sbdkzt/xbdkzt → 点色（attendance_shape_blue/red/gray） */
  private stateFillColor(state: string): ResourceColor {
    if (state === '正常') {
      return $r('app.color.attendance_enable_color');
    }
    if (state === '缺勤' || state === '缺卡') {
      return $r('app.color.attendance_error_color');
    }
    return $r('app.color.attendance_unable_color');
  }

  /** AttendanceDateStateView：状态文字色（enable/error/unable） */
  private stateTextColor(state: string): ResourceColor {
    if (state === '正常') {
      return $r('app.color.attendance_enable_color');
    }
    if (state === '缺勤' || state === '缺卡') {
      return $r('app.color.attendance_error_color');
    }
    return $r('app.color.attendance_unable_color');
  }

  /** AttendanceDateStateView：desc 标签仅 正常/缺勤/缺卡 可见 */
  private descVisible(state: string): boolean {
    return state === '正常' || state === '缺勤' || state === '缺卡';
  }

  /** 当月 1 日距周一的天数（week_start_with=mon） */
  private mondayIndex(year: number, month: number, day: number): number {
    const weekday: number = new Date(year, month - 1, day).getDay();
    return (weekday + 6) % 7;
  }

  private daysInMonth(year: number, month: number): number {
    return new Date(year, month, 0).getDate();
  }

  /** 某日所在周的周一 key */
  private mondayKeyOf(year: number, month: number, day: number): string {
    const offset: number = this.mondayIndex(year, month, day);
    const monday: Date = new Date(year, month - 1, day - offset);
    return dateKey(monday.getFullYear(), monday.getMonth() + 1, monday.getDate());
  }

  private todayKey(): string {
    const now: Date = new Date();
    return dateKey(now.getFullYear(), now.getMonth() + 1, now.getDate());
  }

  /** 月历单元格：当月全部日 + 前后月补位（inMonth=false，周视图显示为灰色） */
  private buildMonthCells(year: number, month: number): CalCell[] {
    const cells: CalCell[] = [];
    const firstWeekday: number = this.mondayIndex(year, month, 1);
    const prev: number = month === 1 ? 12 : month - 1;
    const prevYear: number = month === 1 ? year - 1 : year;
    const next: number = month === 12 ? 1 : month + 1;
    const nextYear: number = month === 12 ? year + 1 : year;
    const prevDays: number = this.daysInMonth(prevYear, prev);
    const curDays: number = this.daysInMonth(year, month);
    for (let i = firstWeekday - 1; i >= 0; i--) {
      const day: number = prevDays - i;
      cells.push(new CalCell(prevYear, prev, day, dateKey(prevYear, prev, day), false));
    }
    for (let d = 1; d <= curDays; d++) {
      cells.push(new CalCell(year, month, d, dateKey(year, month, d), true));
    }
    let fill: number = 7 - (cells.length % 7);
    if (fill === 7) {
      fill = 0;
    }
    for (let d = 1; d <= fill; d++) {
      cells.push(new CalCell(nextYear, next, d, dateKey(nextYear, next, d), false));
    }
    return cells;
  }

  private weeksOfMonth(): CalCell[][] {
    const cells: CalCell[] = this.buildMonthCells(this.calYear, this.calMonth);
    const weeks: CalCell[][] = [];
    for (let i = 0; i < cells.length; i += 7) {
      weeks.push(cells.slice(i, i + 7));
    }
    return weeks;
  }

  /** 周模式当前周（锚点：weekAnchor > 选中日 > 今天 > 首格） */
  private currentWeekCells(): CalCell[] {
    const cells: CalCell[] = this.buildMonthCells(this.calYear, this.calMonth);
    const anchors: string[] = [this.weekAnchorKey, this.selectedKey, this.todayKey()];
    let anchor: CalCell | null = null;
    for (const key of anchors) {
      if (anchor !== null || key === '') {
        continue;
      }
      for (const cell of cells) {
        if (cell.key === key) {
          anchor = cell;
        }
      }
    }
    if (anchor !== null) {
      return this.weekAround(cells, anchor);
    }
    // 周模式跨月翻周：锚点（周一）不在当前月格网中时按日期直接构造一周（WeekViewPager 跨月页）
    const parts: string[] = this.weekAnchorKey.split('-');
    if (parts.length === 3) {
      const monday: Date = new Date(Number(parts[0]), Number(parts[1]) - 1, Number(parts[2]));
      return this.weekCellsFromMonday(monday.getFullYear(), monday.getMonth() + 1, monday.getDate());
    }
    return cells.slice(0, 7);
  }

  /** 从周一日期向后构造 7 格（inMonth 以当前月为界，用于文字色） */
  private weekCellsFromMonday(year: number, month: number, day: number): CalCell[] {
    const cells: CalCell[] = [];
    for (let i = 0; i < 7; i++) {
      const date: Date = new Date(year, month - 1, day + i);
      const y: number = date.getFullYear();
      const m: number = date.getMonth() + 1;
      const d: number = date.getDate();
      cells.push(new CalCell(y, m, d, dateKey(y, m, d), y === this.calYear && m === this.calMonth));
    }
    return cells;
  }

  private weekAround(cells: CalCell[], anchor: CalCell): CalCell[] {
    const index: number = cells.indexOf(anchor);
    const start: number = Math.floor(index / 7) * 7;
    return cells.slice(start, start + 7);
  }

  // ===== UI：TabLayout（attendance_activity_main.xml） =====

  /** TabLayout：高 40vp、14fp、居中、指示条高 0；两签间 1px #CECECE 竖线（源码 setShowDividers） */
  @Builder
  tabBar() {
    Row() {
      ForEach(TAB_TITLES, (title: string, index: number) => {
        if (index > 0) {
          // 源码 setShowDividers(MIDDLE)+setDividerPadding(10px=5vp)：40-5*2=30vp 竖线
          Row().width(1).height(30).backgroundColor('#CECECE').margin({ left: 24, right: 24 })
        }
        Text(title)
          .fontSize(14)
          .fontColor((index === this.activeTab ?
            $r('app.color.mobile_campus_primary_color_default') : '#333333') as ResourceColor)
          .onClick(() => {
            this.activeTab = index;
          })
      }, (title: string) => 'attTab' + title)
    }
    .width('100%')
    .height(40)
    .justifyContent(FlexAlign.Center)
    .alignItems(VerticalAlign.Center)
    .backgroundColor($r('app.color.white'))
  }

  // ===== UI：个人考勤记录（attendance_fragment_personal.xml） =====

  /** 统计卡（attendance_shape_rect_blue：#DDECFF 圆角 px_to_dip_8=4vp） */
  @Builder
  statCard(value: string, label: string) {
    Column() {
      Row() {
        Text(value)
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.attendance_enable_color'))
        Text('天')
          .fontSize(16)
          .fontColor($r('app.color.attendance_enable_color'))
      }
      Text(label)
        .fontSize(12)
        .fontColor($r('app.color.attendance_enable_color'))
        .margin({ top: 16 })
    }
    .layoutWeight(1)
    .padding({ top: 21, bottom: 12 })
    .justifyContent(FlexAlign.Center)
    .backgroundColor($r('app.color.attendance_tag_bg'))
    .borderRadius(4)
  }

  /** AttendanceStateView：14fp #333333 + 左侧 12dip=6vp 圆点 + drawablePadding 8vp */
  @Builder
  stateView(type: string) {
    Row() {
      Row()
        .width(6)
        .height(6)
        .borderRadius(3)
        .backgroundColor(this.stateDotColor(type))
      Text(this.stateText(type))
        .fontSize(14)
        .fontColor($r('app.color.common_color_1'))
        .margin({ left: 8 })
        .maxLines(1)
    }
    .layoutWeight(1)
    .alignItems(VerticalAlign.Center)
  }

  /** tvDate：16fp #333333 高 40vp 居中 + 右侧 attendance_timeselect_nor（drawablePadding 8vp） */
  @Builder
  personalDateBar() {
    Row() {
      Text(this.dateTitle)
        .fontSize(16)
        .fontColor($r('app.color.common_color_1'))
      Image($r('app.media.attendance_timeselect_nor'))
        .width(14)
        .height(14)
        .margin({ left: 8 })
    }
    .width('100%')
    .height(40)
    .justifyContent(FlexAlign.Center)
    .alignItems(VerticalAlign.Center)
    .backgroundColor($r('app.color.white'))
    .onClick(() => {
      this.pickMonth();
    })
  }

  @Builder
  personalTab() {
    Column() {
      this.personalSummary()
      this.personalCalendar()
    }
    .width('100%')
    .layoutWeight(1)
    .backgroundColor($r('app.color.white'))
  }

  /** 统计卡 + 三态视图 + 分隔线 + tvDate（attendance_fragment_personal.xml 上半部） */
  @Builder
  personalSummary() {
    Column() {
      Row() {
        this.statCard(this.day1, '月需打卡天数')
        Blank().width(13)
        this.statCard(this.day2, '正常打卡天数')
      }
      .width('100%')
      .padding({ left: 12, right: 12, top: 8, bottom: 12 })

      // layoutState1：Absense / NotSigned / Leave 三等分（layoutStateContainer2 源码恒 gone）
      Row() {
        this.stateView('Absense')
        this.stateView('NotSigned')
        this.stateView('Leave')
      }
      .width('100%')
      .padding({ left: 12, right: 12 })

      Row() {
        this.stateView('NotSigned')
        this.stateView('Leave')
      }
      .width('100%')
      .padding({ left: 12, right: 12 })
      .visibility(Visibility.None)

      Divider().color($r('app.color.common_color_5')).strokeWidth(0.5)
      this.personalDateBar()
      Divider().color($r('app.color.common_color_5')).strokeWidth(0.5)
    }
    .width('100%')
  }

  /** CalendarLayout（default_status=shrink）：周/月视图（手势区）+ 内容区 */
  @Builder
  personalCalendar() {
    Column() {
      Column() {
        this.weekBar()
        if (this.expanded) {
          this.monthGrid()
        } else {
          this.weekRow()
        }
      }
      .width('100%')
      .gesture(
        GestureGroup(GestureMode.Parallel,
          SwipeGesture({ direction: SwipeDirection.Vertical })
            .onAction((event: GestureEvent) => {
              // CalendarLayout 月↔周：上滑展开、下滑收起
              this.setExpanded(event.angle < 0);
            }),
          SwipeGesture({ direction: SwipeDirection.Horizontal })
            .onAction((event: GestureEvent) => {
              // 月视图翻月（b.a）/ 周视图翻周（c.a）
              const next: boolean = event.angle <= -90 || event.angle >= 90;
              if (this.expanded) {
                this.shiftMonth(next ? 1 : -1);
              } else {
                this.shiftWeek(next ? 1 : -1);
              }
            })
        )
      )
      this.attendanceList()
    }
    .layoutWeight(1)
    .width('100%')
  }

  /** CalendarView 周条：week_text_size 11fp #999999、week_bar_height 40vp、周一为首 */
  @Builder
  weekBar() {
    Row() {
      ForEach(WEEK_LABELS, (label: string) => {
        Text(label)
          .fontSize(11)
          .fontColor('#999999')
          .textAlign(TextAlign.Center)
          .layoutWeight(1)
      }, (label: string) => 'attWeek' + label)
    }
    .width('100%')
    .height(40)
    .padding({ left: 10, right: 10 })
    .alignItems(VerticalAlign.Center)
  }

  /** 月视图（month_view_show_mode=mode_only_current：仅当月日期） */
  @Builder
  monthGrid() {
    Column() {
      ForEach(this.weeksOfMonth(), (week: CalCell[], wi: number) => {
        Row() {
          ForEach(week, (cell: CalCell) => {
            if (cell.inMonth) {
              this.dayCell(cell)
            } else {
              Row().layoutWeight(1).height(40)
            }
          }, (cell: CalCell) => 'attMd' + cell.key)
        }
        .width('100%')
      }, (week: CalCell[], wi: number) => 'attMw' + String(this.calYear) + String(this.calMonth) + String(wi))
    }
    .width('100%')
    .padding({ left: 10, right: 10 })
  }

  /** 周视图（AttendanceSingleWeekView：含前后月补位日，other_month_text_color #E1E1E1） */
  @Builder
  weekRow() {
    Row() {
      ForEach(this.currentWeekCells(), (cell: CalCell) => {
        this.dayCell(cell)
      }, (cell: CalCell) => 'attWd' + cell.key)
    }
    .width('100%')
    .padding({ left: 10, right: 10 })
  }

  /** 单格：选中 #388CFC 圆白字 / 今日 #DDECFF 圆蓝字 / scheme 圆点 3vp 半径 */
  @Builder
  dayCell(cell: CalCell) {
    Column() {
      Stack({ alignContent: Alignment.Center }) {
        Row()
          .width(26.7)
          .height(26.7)
          .borderRadius(13.35)
          .backgroundColor(this.dayCircleColor(cell))
        Text(String(cell.day))
          .fontSize(cell.key === this.selectedKey ? 17 : 14)
          .fontColor(this.dayTextColor(cell))
      }
      Row()
        .width(6)
        .height(6)
        .borderRadius(3)
        .backgroundColor(this.dayDotColor(cell.key))
        .margin({ top: 2 })
    }
    .width('100%')
    .height(40)
    .justifyContent(FlexAlign.Center)
    .onClick(() => {
      if (this.expanded && !cell.inMonth) {
        return;
      }
      this.onDaySelected(cell);
    })
  }

  /** 选中/今日底色（AttendanceSingleMonthView：selected_theme #388CFC、today #DDECFF） */
  private dayCircleColor(cell: CalCell): ResourceColor | string {
    if (cell.key === this.selectedKey) {
      return $r('app.color.attendance_enable_color');
    }
    if (cell.key === this.todayKey()) {
      // 源码 onDrawText：有 scheme 的日期走 z 分支，不再绘制今日 #DDECFF 圆
      return this.schemeMap[cell.key] === undefined ? $r('app.color.attendance_tag_bg') : '#00000000';
    }
    return '#00000000';
  }

  /** 日期文字色：选中白 / 今日 #388CFC / 当月 #333333 / 补位 #E1E1E1 */
  private dayTextColor(cell: CalCell): ResourceColor | string {
    if (cell.key === this.selectedKey) {
      return '#FFFFFF';
    }
    if (cell.key === this.todayKey()) {
      return $r('app.color.attendance_enable_color');
    }
    return cell.inMonth ? '#333333' : '#E1E1E1';
  }

  // ===== UI：AttendanceContentLayout + AttendanceListFragment =====

  @Builder
  attendanceList() {
    Column() {
      if (this.tips !== '') {
        Text(this.tips)
          .fontSize(14)
          .fontColor('#999999')
          .width('100%')
          .height(36)
          .padding({ left: 16, right: 16 })
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      if (this.personalLoading) {
        LoadingView()
      } else {
        if (this.dayRecords.length === 0) {
          EmptyView()
        } else {
          List() {
            ForEach(this.dayRecords, (bean: AttendanceByDayBean) => {
              ListItem() {
                this.attendanceDateItem(bean)
              }
            }, (bean: AttendanceByDayBean) => 'attDay' + bean.date)
          }
          .width('100%')
          .layoutWeight(1)
          .scrollBar(BarState.Off)
        }
      }
    }
    .width('100%')
    .layoutWeight(1)
    .backgroundColor($r('app.color.common_color_6'))
  }

  /** attendance_view_date.xml：tvDate(16fp #333 高40vp padL12 + attendance_time pad8) + 线 + 时间轴 */
  @Builder
  attendanceDateItem(bean: AttendanceByDayBean) {
    Column() {
      Row() {
        Image($r('app.media.attendance_time'))
          .width(14)
          .height(14)
        Text(bean.date)
          .fontSize(16)
          .fontColor($r('app.color.common_color_1'))
          .margin({ left: 8 })
      }
      .width('100%')
      .height(40)
      .padding({ left: 12 })
      .alignItems(VerticalAlign.Center)
      Divider().color($r('app.color.common_color_5')).strokeWidth(0.5)
      this.dateStateView(bean)
    }
    .width('100%')
    .backgroundColor($r('app.color.white'))
  }

  /** attendance_view_state.xml + AttendanceDateStateView.setData 逐行翻译（27/24vp 上下 padding） */
  @Builder
  dateStateView(bean: AttendanceByDayBean) {
    Column() {
      this.dateStartRow(bean)
      this.dateEndRow(bean)
      if (this.descVisible(bean.xbdkzt)) {
        Row() {
          Row().width(112.5)
          // 源码原文：缺勤/缺卡分支 tvEndDesc 取 sbdkfs（非 xbdkfs），照源码翻译
          Text(bean.xbdkzt === '正常' ? bean.xbdkfs : bean.sbdkfs)
            .fontSize(12)
            .fontColor($r('app.color.attendance_enable_color'))
            .backgroundColor($r('app.color.attendance_tag_bg'))
            .borderRadius(1000)
            .padding({ left: 4, right: 4, top: 2, bottom: 2 })
        }
        .width('100%')
        .margin({ top: 12 })
      }
    }
    .width('100%')
    .padding({ top: 27, bottom: 24 })
    .backgroundColor($r('app.color.white'))
  }

  /** attendance_view_state 上班行：tvStartTime 18.5fp 宽56 + 点/线 + tvStart/tvStartDesc */
  @Builder
  dateStartRow(bean: AttendanceByDayBean) {
    Row() {
      Text(bean.sbdksj)
        .fontSize(18.5)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.common_color_1'))
        .width(56)
      Column() {
        Row()
          .width(16)
          .height(16)
          .borderRadius(8)
          .backgroundColor(this.stateFillColor(bean.sbdkzt))
          .margin({ top: 4 })
        Row().width(2).height(48).backgroundColor('#E7E7E7')
      }
      .margin({ left: 12 })
      .alignItems(HorizontalAlign.Center)
      Column() {
        Text(bean.sbdkzt)
          .fontSize(14)
          .fontColor(this.stateTextColor(bean.sbdkzt))
        if (this.descVisible(bean.sbdkzt)) {
          Text(bean.sbdkfs)
            .fontSize(12)
            .fontColor($r('app.color.attendance_enable_color'))
            .backgroundColor($r('app.color.attendance_tag_bg'))
            .borderRadius(1000)
            .padding({ left: 4, right: 4, top: 2, bottom: 2 })
            .margin({ top: 12 })
        }
      }
      .margin({ left: 16 })
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .padding({ left: 12 })
    .alignItems(VerticalAlign.Center)
  }

  /** attendance_view_state 下班行：tvEndTime 18.5fp 宽56 + 线/点 + tvEnd */
  @Builder
  dateEndRow(bean: AttendanceByDayBean) {
    Row() {
      Text(bean.xbdksj)
        .fontSize(18.5)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.common_color_1'))
        .width(56)
      Column() {
        Row().width(2).height(48).backgroundColor('#E7E7E7')
        Row()
          .width(16)
          .height(16)
          .borderRadius(8)
          .backgroundColor(this.stateFillColor(bean.xbdkzt))
          .margin({ bottom: 4 })
      }
      .margin({ left: 12 })
      .alignItems(HorizontalAlign.Center)
      Column() {
        Text(bean.xbdkzt)
          .fontSize(14)
          .fontColor(this.stateTextColor(bean.xbdkzt))
      }
      .margin({ left: 16 })
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .padding({ left: 12 })
    .alignItems(VerticalAlign.Bottom)
  }

  // ===== UI：院系月份统计（attendance_fragment_leader.xml） =====

  @Builder
  leaderTab() {
    Column() {
      this.leaderHeader()
      Row().width('100%').height(0.5)
      this.leaderList()
    }
    .width('100%')
    .layoutWeight(1)
    .backgroundColor($r('app.color.white'))
  }

  /** Leader 顶栏：tvDate(yyyy-MM #50b3fe+arrow) + tvCount("考勤人数N人" #999999) 高36vp */
  @Builder
  leaderHeader() {
    Row() {
      Row() {
        Text(this.leaderMonth)
          .fontSize(15)
          .fontColor('#50b3fe')
        Image($r('app.media.arrow_down_blue_desk_widget'))
          .width(12)
          .height(12)
          .margin({ left: 8 })
      }
      .alignItems(VerticalAlign.Center)
      .onClick(() => {
        this.pickMonth();
      })
      Text('考勤人数' + this.leaderNum + '人')
        .fontSize(15)
        .fontColor('#999999')
        .margin({ top: 8 })
    }
    .width('100%')
    .height(36)
    .padding({ left: 12, right: 12 })
    .alignItems(VerticalAlign.Center)
    .justifyContent(FlexAlign.SpaceBetween)
  }

  /** ExpandableListView（MultiStateView：loading / empty / content） */
  @Builder
  leaderList() {
    if (this.leaderLoading) {
      LoadingView()
    } else {
      if (this.bossGroups.length === 0) {
        EmptyView()
      } else {
        List() {
          ForEach(this.bossGroups, (group: AttendanceGroupBean, gi: number) => {
            ListItem() {
              Column() {
                this.leaderGroupItem(group, gi)
                if (this.expandedGroup === gi) {
                  ForEach(group.peopleList, (person: AttendancePeopleListBean) => {
                    this.leaderChildItem(person)
                  }, (person: AttendancePeopleListBean) => 'attChild' + person.userId)
                }
              }
              .width('100%')
            }
          }, (group: AttendanceGroupBean) => 'attGroup' + group.groupName)
        }
        .width('100%')
        .layoutWeight(1)
        .scrollBar(BarState.Off)
      }
    }
  }

  /** attendance_view_group.xml：高 48vp、padL12/R20、展开时 #50b3fe + attendance_open */
  @Builder
  leaderGroupItem(group: AttendanceGroupBean, index: number) {
    Row() {
      Text(group.groupName)
        .fontSize(16)
        .fontColor($r('app.color.common_color_1'))
      Row() {
        Text(String(group.peopleList.length) + '人')
          .fontSize(16)
          .fontColor((this.expandedGroup === index ?
            '#50b3fe' : $r('app.color.common_color_1')) as ResourceColor)
        Image(this.expandedGroup === index ? $r('app.media.attendance_open') : $r('app.media.attendance_close'))
          .width(14)
          .height(14)
          .margin({ left: 12 })
      }
      .alignItems(VerticalAlign.Center)
    }
    .width('100%')
    .height(48)
    .padding({ left: 12, right: 20 })
    .alignItems(VerticalAlign.Center)
    .justifyContent(FlexAlign.SpaceBetween)
    .onClick(() => {
      this.toggleGroup(index);
    })
  }

  /** attendance_view_child.xml：高 64vp、头像 40vp 圆形、姓名/部门、times+"次" */
  @Builder
  leaderChildItem(person: AttendancePeopleListBean) {
    Row() {
      if (person.imgUrl !== '') {
        Image(Constants.SOCKET_HOST + person.imgUrl)
          .width(40)
          .height(40)
          .borderRadius(20)
          .objectFit(ImageFit.Cover)
          .margin({ left: 8 })
      } else {
        Row().width(40).height(40).margin({ left: 8 })
      }
      Column() {
        Text(person.userName)
          .fontSize(16)
          .fontColor($r('app.color.common_color_1'))
        Text(person.departmentName)
          .fontSize(12)
          .fontColor('#999999')
          .margin({ top: 8 })
      }
      .margin({ left: 12 })
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
      Text(person.times + '次')
        .fontSize(16)
        .fontColor($r('app.color.common_color_1'))
    }
    .width('100%')
    .height(64)
    .padding({ left: 12, right: 20 })
    .alignItems(VerticalAlign.Center)
    .onClick(() => {
      this.openPersonalPage(person.userId);
    })
  }

  // ===== UI：年月选择器（bigkoo pickerview：年+月两轮，底部滑入） =====

  private pickerYears(): string[] {
    const now: Date = new Date();
    const years: string[] = [];
    for (let y = now.getFullYear() - 10; y <= now.getFullYear() + 10; y++) {
      years.push(String(y));
    }
    return years;
  }

  private pickerMonths(): string[] {
    const months: string[] = [];
    for (let m = 1; m <= 12; m++) {
      months.push(String(m));
    }
    return months;
  }

  private selYearIndex(): number {
    const years: string[] = this.pickerYears();
    for (let i = 0; i < years.length; i++) {
      if (years[i] === String(this.selYear)) {
        return i;
      }
    }
    return 10;
  }

  @Builder
  monthPickerOverlay() {
    Column() {
      Blank()
        .onClick(() => {
          this.showPicker = false;
        })
      this.monthPickerPanel()
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#66000000')
    .justifyContent(FlexAlign.End)
  }

  /** bigkoo pickerview 顶栏：取消 #333333 / 确定 #057DFF（pickerview_timebtn_nor） */
  @Builder
  monthPickerPanel() {
    Column() {
      Row() {
        Text('取消')
          .fontSize(16)
          .fontColor('#333333')
          .padding({ left: 16, right: 16, top: 12, bottom: 12 })
          .onClick(() => {
            this.showPicker = false;
          })
        Blank().layoutWeight(1)
        Text('确定')
          .fontSize(16)
          .fontColor('#057DFF')
          .padding({ left: 16, right: 16, top: 12, bottom: 12 })
          .onClick(() => {
            this.onPickerConfirm();
          })
      }
      .width('100%')
      .backgroundColor('#F5F5F5')
      this.monthPickerWheels()
    }
    .width('100%')
    .backgroundColor($r('app.color.white'))
    .borderRadius({ topLeft: 12, topRight: 12 })
  }

  /** 年+月两轮（源码 c(new boolean[]{true,true,false,false,false,false})） */
  @Builder
  monthPickerWheels() {
    Row() {
      TextPicker({ range: this.pickerYears(), selected: this.selYearIndex() })
        .layoutWeight(1)
        .height(160)
        .onChange((value: string | string[], index: number | number[]) => {
          const idx: number = Array.isArray(index) ? (index.length > 0 ? index[0] : 0) : index;
          const years: string[] = this.pickerYears();
          if (idx >= 0 && idx < years.length) {
            this.selYear = Number(years[idx]);
          }
        })
      TextPicker({ range: this.pickerMonths(), selected: this.selMonth - 1 })
        .layoutWeight(1)
        .height(160)
        .onChange((value: string | string[], index: number | number[]) => {
          const idx: number = Array.isArray(index) ? (index.length > 0 ? index[0] : 0) : index;
          this.selMonth = idx + 1;
        })
    }
    .width('100%')
  }

  build() {
    Stack() {
      Column() {
        TitleBar({ title: '考勤月历', showBack: true })
        if (this.showLeaderTabs) {
          this.tabBar()
        }
        if (!this.showLeaderTabs || this.activeTab === 0) {
          this.personalTab()
        } else {
          this.leaderTab()
        }
      }
      .width('100%')
      .height('100%')
      .backgroundColor($r('app.color.white'))

      if (this.showPicker) {
        this.monthPickerOverlay()
      }
    }
    .width('100%')
    .height('100%')
  }
}
