import { router } from '@kit.ArkUI';
import { TitleBar } from '../components/TitleBar';
import { ApiService } from '../network/ApiService';
import { ApiResponse } from '../model/ResponseModel';
import { ScheduleDetailRow, ScheduleMonthItem } from '../model/ContactModel';
import { EmptyView } from '../components/EmptyView';
import { LoadingView } from '../components/LoadingView';

/**
 * 今日日程主页 — 源码级翻译（ScheduleMainActivity.java + ScheduleListNewFragment + ScheduleAdapter
 * 逐行 → ArkTS，[W25 misc-b]）：
 *
 * 【关系核对】ScheduleMainActivity（/schedule/main？T1 标题"今日日程"）与 SchedulePage（TimetableActivity
 * 课程表）是两个模块：本页=haibin CalendarView 月历 + 当日日程列表；SchedulePage 已由 E3/W10 翻译，互不替代。
 * 【布局】mobile_campus_schedule_activity_schedule.xml：toolbar("今日日程"+右上 add_schedule 图标 PopupMenu)
 *   + CalendarLayout(CalendarView 月历 + WeekViewPager 周视图) + schedule_container(ScheduleListNewFragment)
 * 【数据】f1 a3(yyyy-MM) → ScheduleModel.b1 POST getListByMonth {year_month} → ScheduleItem{rq,detail[]}
 *   → d3()：rq("yyyy-MM-dd" 拆"-") → Calendar scheme 红点(setSchemeColor 红 CATEGORY_MASK) +
 *   w map[yyyy-MM-dd]→detail[]；选中日期 → m.X1(w.get(fmt)) 列表；月切换 g 类/h 类 → 重拉
 * 【月历】CalendarView 等价（HAP 自实现月网格：周日始=haibin 默认；SDGY 才周一开始，SDMU 非 SDGY）；
 *   CalendarLayout 周月手势切换无 HAP 等价，保留月视图（注释记录）；o 点击 → showYearSelectLayout 等价
 *   年份滚轮 bindSheet；首次 GuideView 引导（c3+schedule/b.a 持久化）无 HAP 等价浮层组件，省略
 * 【行】mobile_campus_schedule_item.xml：白卡 ml20 mt20 mr20（shape_two 左偏 8dip 双层卡）+ padL17 padT10
 *   padR13 padB10：tag（schedule_color 1紧急/2重要 红描边 14fp）+ name 16fp bold ml15 + type 胶囊
 *   （会议=蓝 meeting icon/课表=橙 class icon/日程=黄 schedule icon，按 task_type setTextStyle 1:1）+
 *   时间行/地点行 15fp#5d5d5d（e.a.j 课程式/e.a.k 其余式时间格式）+ arrow_right + state 右下角
 *   （MY_MEETING && is_current_user_plan=="1" → my 图标）
 * 【点击】a 类分流：mymeeting→MeetingDetailPage{xlh,TASK_TYPE}；customSchedule→ScheduleAddPage{schedule_id}
 *   （编辑 1460）；course/customCourse→CourseDetailPage{xlh}；weekPlan→MeetingWeekPlanPage{xlh,is_join}；
 *   oa_* 与默认→/schedule/oa_detail=ScheduleOADetailActivity（HAP 无对应页，无跳转保真）
 * 【菜单】f3 PopupMenu：添加课程(/message/addcourse→AddCoursePage)/添加日程(/message/addschedule→
 *   ScheduleAddPage)/创建会议(/meeting/create=AddMeetingActivity→MeetingAddPage 占位)；meeting 项按
 *   canCreateMeeting(y 入参默认 true)；HJJGC 才隐藏 course（SDMU 显示）
 * 【onActivityResult 等价】onPageShow 重拉月数据
 */
interface MonthWeek {
  days: number[];
  inMonth: boolean[];
}

@Entry
@Component
struct ScheduleMainActivity {
  @State year: number = 2026;
  @State month: number = 1;
  @State selectedDay: number = 1;
  @State dayText: string = '';
  @State weekText: string = '';
  /** rq → 当日日程（源码 w map） */
  @State dayDetailMap: Record<string, ScheduleDetailRow[]> = {};
  @State dayDetailList: ScheduleDetailRow[] = [];
  @State hasDotMap: Record<string, boolean> = {};
  @State weeks: MonthWeek[] = [];
  @State isLoading: boolean = true;
  @State showYearPicker: boolean = false;
  /** 源码 x：canCreateMeeting（y 入参默认 true） */
  private canCreateMeeting: boolean = true;
  private yearPickValue: string = '';

  onPageShow(): void {
    // 源码 onActivityResult：3417/详情返回 → j() 重拉月数据
    this.loadMonth();
  }

  aboutToAppear(): void {
    const now = new Date();
    this.year = now.getFullYear();
    this.month = now.getMonth() + 1;
    this.selectedDay = now.getDate();
    this.buildGrid();
    // 源码 i 类初始：选中今天 → 显示星期文本
    this.dayText = `${this.year}年${this.month}月${this.selectedDay}日`;
    this.weekText = '星期' + this.weekNameOf(now.getDay());
    this.loadMonth();
  }

  /** 源码 a3+ScheduleModel.b1：POST getListByMonth {year_month:"yyyy-MM"} */
  private loadMonth(): void {
    this.isLoading = this.dayDetailList.length === 0;
    const ym: string = `${this.year}-${this.month < 10 ? '0' + this.month : this.month}`;
    ApiService.getScheduleListByMonth(ym)
      .then((response: ApiResponse<ScheduleMonthItem[]>) => {
        this.isLoading = false;
        if (response.code === 1000) {
          return;
        }
        if (response.code !== 0) {
          const msg: string = response.message === '' ? '服务器繁忙，请稍后再试' : response.message;
          this.getUIContext().getPromptAction().showToast({ message: msg });
          return;
        }
        // 源码 d3：rq → scheme 红点 + w map
        const dots: Record<string, boolean> = {};
        const map: Record<string, ScheduleDetailRow[]> = {};
        for (const item of response.data) {
          if (item.detail.length > 0) {
            map[item.rq] = item.detail;
            dots[item.rq] = true;
          }
        }
        this.hasDotMap = dots;
        this.dayDetailMap = map;
        // 源码 d3 尾部：选中日期 → X1(w.get(fmt))
        this.applySelectedDayList();
      })
      .catch(() => {
        ApiService.logError('ScheduleMainActivity load month error');
        this.isLoading = false;
      });
  }

  /** 源码 i 类/d3 尾部：选中日期的 detail → 列表（空 → EMPTY_SCHEDULE 在 build 分流） */
  private applySelectedDayList(): void {
    const key: string = `${this.year}-${this.month < 10 ? '0' + this.month : this.month}-${this.selectedDay < 10 ? '0' + this.selectedDay : this.selectedDay}`;
    const list: ScheduleDetailRow[] = this.dayDetailMap[key];
    this.dayDetailList = list !== undefined && list !== null ? list : [];
  }

  /** 月网格（周日始，haibin CalendarView 默认；SDMU 非 SDGY） */
  private buildGrid(): void {
    const first = new Date(this.year, this.month - 1, 1);
    const offset: number = first.getDay();
    const daysInMonth: number = new Date(this.year, this.month, 0).getDate();
    const weeks: MonthWeek[] = [];
    let day: number = 1 - offset;
    while (day <= daysInMonth) {
      const days: number[] = [];
      const inMonth: boolean[] = [];
      for (let i = 0; i < 7; i++) {
        days.push(day);
        inMonth.push(day >= 1 && day <= daysInMonth);
        day++;
      }
      weeks.push({ days: days, inMonth: inMonth });
    }
    this.weeks = weeks;
  }

  /** 日期 key（rq 格式 yyyy-MM-dd 补零，与源码 split("-") 拆分语义一致） */
  private keyOf(day: number): string {
    const mm: string = this.month < 10 ? '0' + this.month : String(this.month);
    const dd: string = day < 10 ? '0' + day : String(day);
    return `${this.year}-${mm}-${dd}`;
  }

  /** 源码 e.a.i(week)：0..6 → 日一二三四五六 */
  private weekNameOf(week: number): string {
    const names: string[] = ['日', '一', '二', '三', '四', '五', '六'];
    return week >= 0 && week <= 6 ? names[week] : '';
  }

  /** 源码 i 类：选中日期 → 更新标题/星期 + 列表 */
  private selectDay(day: number): void {
    this.selectedDay = day;
    const sel = new Date(this.year, this.month - 1, day);
    this.dayText = `${this.year}年${this.month}月${day}日`;
    this.weekText = '星期' + this.weekNameOf(sel.getDay());
    this.applySelectedDayList();
  }

  /** 源码 g 类（月切换）：翻月重拉 */
  private shiftMonth(delta: number): void {
    let m: number = this.month + delta;
    let y: number = this.year;
    if (m < 1) {
      m = 12;
      y--;
    } else if (m > 12) {
      m = 1;
      y++;
    }
    this.month = m;
    this.year = y;
    const daysInMonth: number = new Date(y, m, 0).getDate();
    if (this.selectedDay > daysInMonth) {
      this.selectedDay = daysInMonth;
    }
    this.buildGrid();
    this.selectDay(this.selectedDay);
    // 源码 g 类：a3(s + "-" + t) 重拉
    this.loadMonth();
  }

  /** 源码 f3 PopupMenu：添加课程/添加日程/创建会议（showActionSheet 等价） */
  private showAddMenu(): void {
    const sheets: SheetInfo[] = [];
    sheets.push({
      title: '添加课程',
      action: (): void => {
        // 源码 a 类 course → /message/addcourse 3417
        router.pushUrl({ url: 'pages/AddCoursePage' });
      }
    });
    sheets.push({
      title: '添加日程',
      action: (): void => {
        // 源码 a 类 event → /message/addschedule 3417
        router.pushUrl({ url: 'pages/ScheduleAddPage' });
      }
    });
    if (this.canCreateMeeting) {
      sheets.push({
        title: '创建会议',
        action: (): void => {
          // 源码 a 类 meeting → /meeting/create（AddMeetingActivity）
          router.pushUrl({ url: 'pages/MeetingAddPage' });
        }
      });
    }
    this.getUIContext().showActionSheet({ title: '', message: '', sheets: sheets });
  }

  /** 源码 a 类（ListNewFragment）：条目点击分流 */
  private openDetail(bean: ScheduleDetailRow): void {
    if (bean.task_type === 'mymeeting') {
      router.pushUrl({ url: 'pages/MeetingDetailPage',
        params: { 'xlh': bean.xlh, 'TASK_TYPE': bean.task_type } as Record<string, string> });
      return;
    }
    if (bean.task_type === 'customSchedule') {
      // 源码 W1：{schedule_id} 1460（/message/scheduledetail）
      router.pushUrl({ url: 'pages/ScheduleDetailPage',
        params: { 'xlh': bean.schedule_id } as Record<string, string> });
      return;
    }
    if (bean.task_type === 'course' || bean.task_type === 'customCourse') {
      router.pushUrl({ url: 'pages/CourseDetailPage',
        params: { 'xlh': bean.xlh } as Record<string, string> });
      return;
    }
    if (bean.task_type === 'weekPlan') {
      router.pushUrl({ url: 'pages/MeetingWeekPlanPage',
        params: { 'xlh': bean.xlh, 'is_join': String(bean.is_join) } as Record<string, string> });
      return;
    }
    // oa_* 与默认 → /schedule/oa_detail = ScheduleOADetailActivity（HAP 无对应页，无跳转保真）
  }

  /** 源码 setTextStyle：type 胶囊文案/色/图标 */
  private typeStyleOf(taskType: string): [string, string, Resource] {
    if (taskType === 'oa_weekPlan' || taskType === 'oa_mymeeting' || taskType === 'weekPlan'
      || taskType === 'mymeeting') {
      return ['会议', '#3F72AF', $r('app.media.mobile_campus_schedule_icon_meeting')];
    }
    if (taskType === 'course' || taskType === 'customCourse') {
      return ['课表', '#F5A623', $r('app.media.mobile_campus_schedule_icon_class')];
    }
    return ['日程', '#FFB100', $r('app.media.mobile_campus_schedule_icon_schedule')];
  }

  /** 源码 e.a.j（课程时间）：同天今天 "HH:mm,HH:mm"；同天非今天 "MM-dd HH:mm,HH:mm"；否则原样 */
  private courseTimeOf(kssj: string, jssj: string): string {
    if (jssj === '') {
      return kssj;
    }
    const s = new Date(kssj.replace(/-/g, '/').replace(',', ' '));
    const e = new Date(jssj.replace(/-/g, '/').replace(',', ' '));
    if (isNaN(s.getTime()) || isNaN(e.getTime())) {
      return kssj + ',' + jssj;
    }
    const fmt = (d: Date, withDate: boolean): string => {
      const hm = `${d.getHours() < 10 ? '0' + d.getHours() : d.getHours()}:${d.getMinutes() < 10 ? '0' + d.getMinutes() : d.getMinutes()}`;
      if (!withDate) {
        return hm;
      }
      const md = `${d.getMonth() + 1 < 10 ? '0' + (d.getMonth() + 1) : d.getMonth() + 1}-${d.getDate() < 10 ? '0' + d.getDate() : d.getDate()}`;
      return md + ' ' + hm;
    };
    const now = new Date();
    const sameDay = s.getFullYear() === e.getFullYear() && s.getMonth() === e.getMonth()
      && s.getDate() === e.getDate();
    if (sameDay) {
      const isToday = s.getFullYear() === now.getFullYear() && s.getMonth() === now.getMonth()
        && s.getDate() === now.getDate();
      return fmt(s, !isToday) + ',' + fmt(e, !isToday);
    }
    return kssj + ',' + jssj;
  }

  /** 源码 e.a.k（其余时间）：同天今天 "HH:mm,HH:mm"；否则 "MM月dd日 HH:mm,MM月dd日 HH:mm" */
  private commonTimeOf(kssj: string, jssj: string): string {
    if (jssj === '') {
      return kssj;
    }
    const s = new Date(kssj.replace(/-/g, '/').replace(',', ' '));
    const e = new Date(jssj.replace(/-/g, '/').replace(',', ' '));
    if (isNaN(s.getTime()) || isNaN(e.getTime())) {
      return '';
    }
    const hm = (d: Date): string =>
      `${d.getHours() < 10 ? '0' + d.getHours() : d.getHours()}:${d.getMinutes() < 10 ? '0' + d.getMinutes() : d.getMinutes()}`;
    const mdy = (d: Date): string =>
      `${d.getMonth() + 1}月${d.getDate()}日 ${d.getHours() < 10 ? '0' + d.getHours() : d.getHours()}:${d.getMinutes() < 10 ? '0' + d.getMinutes() : d.getMinutes()}`;
    const now = new Date();
    if (s.getFullYear() === e.getFullYear() && s.getMonth() === e.getMonth()
      && s.getDate() === e.getDate() && s.getFullYear() === now.getFullYear()
      && s.getMonth() === now.getMonth() && s.getDate() === now.getDate()) {
      return hm(s) + ',' + hm(e);
    }
    return mdy(s) + ',' + mdy(e);
  }

  /** 源码 setContainerStyle：schedule_color 1紧急/2重要 → 红描边 tag；其余白卡 */
  private tagTextOf(bean: ScheduleDetailRow): string {
    if (bean.schedule_color === '1') {
      return '紧急';
    }
    if (bean.schedule_color === '2') {
      return '重要';
    }
    return '';
  }

  build() {
    Column() {
      TitleBar({ title: '今日日程', showBack: true,
        rightIcon: $r('app.media.mobile_campus_schedule_add_schedule'),
        onRightClick: (): void => {
          // 源码 T1：add_schedule 图标 → f3(view) PopupMenu
          this.showAddMenu();
        } })

      this.calendarHeader()
      this.calendarGrid()

      if (this.isLoading) {
        LoadingView()
      } else if (this.dayDetailList.length === 0) {
        // 源码 X1：空 → EMPTY_SCHEDULE
        Column() {
          EmptyView({ tipText: '暂无日程' })
        }
        .width('100%')
        .layoutWeight(1)
      } else {
        List() {
          ForEach(this.dayDetailList, (bean: ScheduleDetailRow, idx: number) => {
            ListItem() {
              this.scheduleRow(bean, idx)
            }
          }, (bean: ScheduleDetailRow, idx: number) => bean.xlh + '_' + idx)
        }
        .width('100%')
        .layoutWeight(1)
        .scrollBar(BarState.Off)
        .backgroundColor('#F2F2F2')
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F2F2F2')
    .bindSheet(this.showYearPicker, this.yearPickerBuilder(), {
      height: 280,
      showClose: false,
      backgroundColor: '#F2F2F2'
    })
  }
  /** 日期头：o=YYYY年M月（点击年选择）+ p=星期X + q */
  @Builder
  calendarHeader() {
    Row() {
      Text(`${this.year}年${this.month}月`)
        .fontSize(16)
        .fontColor($r('app.color.common_color_1'))
        .onClick(() => {
          // 源码 j 类：showYearSelectLayout(s)
          this.yearPickValue = String(this.year);
          this.showYearPicker = true;
        })
      Text(this.weekText)
        .fontSize(14)
        .fontColor($r('app.color.common_color_1'))
        .margin({ left: 12 })
        .visibility(this.weekText === '' ? Visibility.None : Visibility.Visible)
      Blank()
      Text('‹')
        .fontSize(20)
        .fontColor($r('app.color.common_color_1'))
        .padding({ left: 10, right: 10 })
        .onClick(() => {
          this.shiftMonth(-1);
        })
      Text('›')
        .fontSize(20)
        .fontColor($r('app.color.common_color_1'))
        .padding({ left: 10, right: 10 })
        .onClick(() => {
          this.shiftMonth(1);
        })
    }
    .width('100%')
    .height(44)
    .padding({ left: 12, right: 12 })
    .backgroundColor($r('app.color.white'))
    .alignItems(VerticalAlign.Center)
  }

  /** 月历网格（周日始；scheme 红点；选中蓝圈） */
  @Builder
  calendarGrid() {
    Column() {
      Row() {
        ForEach(['日', '一', '二', '三', '四', '五', '六'], (w: string) => {
          Text(w)
            .fontSize(13)
            .fontColor($r('app.color.common_color_1'))
            .layoutWeight(1)
            .textAlign(TextAlign.Center)
        }, (w: string) => w)
      }
      .width('100%')
      .padding({ top: 4, bottom: 4 })
      .backgroundColor($r('app.color.white'))

      ForEach(this.weeks, (week: MonthWeek, wi: number) => {
        Row() {
          ForEach(week.days, (day: number, di: number) => {
            Stack({ alignContent: Alignment.Bottom }) {
              Text(day >= 1 && day <= 31 && week.inMonth[di] ? String(day) : '')
                .fontSize(15)
                .fontColor(this.selectedDay === day && week.inMonth[di]
                  ? $r('app.color.ybg_white') : $r('app.color.common_color_1'))
                .width(32)
                .height(32)
                .textAlign(TextAlign.Center)
                .borderRadius(16)
                .backgroundColor(this.selectedDay === day && week.inMonth[di]
                  ? '#1B68B7' : Color.Transparent)
              Circle({ width: 5, height: 5 })
                .fill('#F00000')
                .visibility(this.hasDot(day, week.inMonth[di]) ? Visibility.Visible : Visibility.None)
                .margin({ bottom: 2 })
            }
            .layoutWeight(1)
            .height(40)
            .onClick(() => {
              if (week.inMonth[di]) {
                this.selectDay(day);
              }
            })
          }, (day: number, di: number) => `${wi}_${di}_${day}`)
        }
        .width('100%')
        .backgroundColor($r('app.color.white'))
      }, (week: MonthWeek, wi: number) => 'w' + wi)
    }
    .width('100%')
    .backgroundColor($r('app.color.white'))
  }

  private hasDot(day: number, inMonth: boolean): boolean {
    if (!inMonth) {
      return false;
    }
    const key: string = this.keyOf(day);
    return this.hasDotMap[key] === true;
  }

  // mobile_campus_schedule_item.xml：日程行（双层白卡 + tag + 名称 + 类型胶囊 + 时间/地点 + my 角标）
  @Builder
  scheduleRow(bean: ScheduleDetailRow, idx: number) {
    Stack({ alignContent: Alignment.BottomEnd }) {
      Column() {
        Row() {
          if (this.tagTextOf(bean) !== '') {
            Text(this.tagTextOf(bean))
              .fontSize(14)
              .fontColor('#FF5151')
              .border({ width: 0.5, color: '#FF5151' })
              .padding({ left: 3, right: 3, top: 2, bottom: 2 })
              .margin({ top: 4 })
          }
          Text(bean.task_type === 'course' || bean.task_type === 'customCourse'
            ? bean.kcmc : bean.title)
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor($r('app.color.common_color_1'))
            .margin({ left: 15, top: 5, right: 8, bottom: 13 })
            .maxLines(2)
            .layoutWeight(1)
          Blank()
          // type 胶囊
          Row() {
            Image(this.typeStyleOf(bean.task_type)[2])
              .width(14)
              .height(14)
            Text(this.typeStyleOf(bean.task_type)[0])
              .fontSize(15)
              .fontColor($r('app.color.ybg_white'))
              .margin({ left: 3 })
          }
          .backgroundColor(this.typeStyleOf(bean.task_type)[1])
          .padding({ left: 5, right: 10, top: 3, bottom: 3 })
          .margin({ top: 8 })
          .alignItems(VerticalAlign.Center)
        }
        .width('100%')
        .alignItems(VerticalAlign.Top)

        // 时间行
        Row() {
          Image($r('app.media.mobile_campus_schedule_time'))
            .width(14)
            .height(14)
          Text(bean.task_type === 'course' || bean.task_type === 'customCourse'
            ? this.courseTimeOf(bean.kssj, bean.jssj) : this.commonTimeOf(bean.kssj, bean.jssj))
            .fontSize(15)
            .fontColor('#5D5D5D')
            .margin({ left: 25 })
            .maxLines(1)
        }
        .width('100%')
        .margin({ bottom: 8 })
        .alignItems(VerticalAlign.Center)

        // 地点行
        Row() {
          Image($r('app.media.mobile_campus_schedule_local'))
            .width(14)
            .height(14)
            .visibility(bean.task_type === 'course' || bean.task_type === 'customCourse'
              ? Visibility.None : Visibility.Visible)
          Text(bean.task_type === 'course' || bean.task_type === 'customCourse'
            ? bean.skdd : bean.locate)
            .fontSize(15)
            .fontColor('#5D5D5D')
            .margin({ left: 25 })
            .maxLines(1)
        }
        .width('100%')
        .alignItems(VerticalAlign.Center)
      }
      .width('100%')
      .padding({ left: 17, right: 13, top: 10, bottom: 10 })
      .backgroundColor($r('app.color.white'))
      .borderRadius(6)
      .alignItems(HorizontalAlign.Start)
      .onClick(() => {
        this.openDetail(bean);
      })

      // state 角标：MY_MEETING 且 is_current_user_plan=="1"
      Image($r('app.media.mobile_campus_schedule_my'))
        .width(22)
        .height(22)
        .margin({ right: -6, bottom: -6 })
        .visibility(bean.task_type === 'mymeeting' && bean.is_current_user_plan === '1'
          ? Visibility.Visible : Visibility.None)
    }
    .width('100%')
    .padding({ left: 20, right: 20, top: 20 })
  }

  /** 年份选择 bindSheet（源码 showYearSelectLayout 等价：选择后 o=YYYY年 + p/q gone） */
  @Builder
  yearPickerBuilder() {
    Column() {
      TextPicker({ range: ['2020', '2021', '2022', '2023', '2024', '2025', '2026', '2027', '2028', '2029', '2030'],
        value: this.yearPickValue })
        .onCancel(() => {
          this.showYearPicker = false;
        })
        .onChange((value: string | string[]) => {
          // [W23 协作解堵] OnTextPickerChangeCallback 签名：value 为 string|string[]
          this.yearPickValue = typeof value === 'string' ? value as string : String((value as string[])[0]);
        })
      Text('确定')
        .fontSize(16)
        .fontColor($r('app.color.ybg_blue'))
        .width('100%')
        .height(44)
        .textAlign(TextAlign.Center)
        .onClick(() => {
          this.showYearPicker = false;
          this.year = Number(this.yearPickValue);
          this.dayText = `${this.year}年`;
          this.weekText = '';
          this.buildGrid();
          this.loadMonth();
        })
    }
    .width('100%')
    .padding({ top: 12, bottom: 12 })
  }
}

