import { router } from '@kit.ArkUI';
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { ApiService } from '../network/ApiService';
import { ApiResponse } from '../model/ResponseModel';
import { CourseItem, ScheduleTermParams, SCHEDULE_FALLBACK_START, SCHEDULE_FALLBACK_END,
  parseYmdMs, apkCurrentWeek, sectionTimeLabel } from '../model/CourseModel';
import { BreakpointSystem } from '../common/BreakpointSystem';

/**
 * I校园 Tab — 按 APK 实拍（mobile_campus_fragment_icampus 运行态）逐块复刻：
 *   1. 我的课表卡：teal 表格图标 + "我的课表"17fp + "第N周"14fp灰 + 右侧"更多"；
 *      课程行 = 左时间列(开始时间20fp黑 / 结束+下课 12fp灰) + 右侧(课程名 20fp / 📍教室 14fp灰)；
 *      右下"添加至桌面 ?"。
 *   2. 今日日程/会议卡：黄色日历图标 + 标题 + 右"更多"；周历一~日（今日红圆白字，周末灰）；
 *      浅灰圆角空态框"—— 暂未添加日程 ——"。
 */

/** 当前/下一节课信息 */
class NextCourse {
  startLabel: string = '';
  endLabel: string = '';
  name: string = '';
  location: string = '';
  has: boolean = false;
}

@Component
export struct ICampusTab {
  @State nextCourse: NextCourse = new NextCourse();
  /** 周历：本周七天 {label: '一'..'日', date: 16..22, isToday, isWeekend} */
  @State weekDays: WeekDay[] = [];
  /** 当前周次（第13周） */
  @State weekNo: number = 13;
  @StorageProp('currentBreakpoint') currentBreakpoint: string = 'sm';
  @StorageProp('heightBreakpoint') heightBreakpoint: string = 'lg';
  @StorageProp('isLandscape') isLandscape: boolean = false;
  @StorageProp('isCompactHeight') isCompactHeight: boolean = false;
  @StorageProp('avoidAreaBottomVp') avoidAreaBottomVp: number = 0;
  scroller: Scroller = new Scroller();

  private useSideRail(): boolean {
    return BreakpointSystem.shouldUseSideRail(
      this.currentBreakpoint,
      this.heightBreakpoint,
      this.isLandscape
    );
  }

  aboutToAppear(): void {
    this.buildWeekDays();
    // 源码 TimeTableNetPresenter.n()：termInfo.ksrq → 真实当前周，替代常量
    ApiService.getScheduleTermParams()
      .then((response: ApiResponse<ScheduleTermParams>) => {
        const term: ScheduleTermParams = response.data;
        if (term.hasStart()) {
          const startMs: number = parseYmdMs(term.ksrq);
          const endMs: number = parseYmdMs(term.jsrq);
          if (startMs > 0 && endMs > 0) {
            const week: number = apkCurrentWeek(startMs, endMs, new Date().getTime());
            if (week >= 1) {
              this.weekNo = week;
            }
          }
        }
        return ApiService.getScheduleList();
      })
      .then((response: ApiResponse<CourseItem[]>) => {
        if (response.data.length > 0) {
          this.pickNextCourse(response.data);
        }
      })
      .catch((error: BusinessError) => {
        hilog.info(0x0000, 'ICampus', 'load fail: %{public}s', error.message);
      });
  }

  /** 生成本周周历（周一为起点） */
  private buildWeekDays(): void {
    const labels: string[] = ['一', '二', '三', '四', '五', '六', '日'];
    const now: Date = new Date();
    // 周一=1..周日=7
    const dayIdx: number = now.getDay() === 0 ? 7 : now.getDay();
    const monday: Date = new Date(now.getFullYear(), now.getMonth(), now.getDate() - (dayIdx - 1));
    const days: WeekDay[] = [];
    for (let i = 0; i < 7; i++) {
      const d: Date = new Date(monday.getFullYear(), monday.getMonth(), monday.getDate() + i);
      days.push(new WeekDay(labels[i], d.getDate(), i + 1 === dayIdx, i >= 5));
    }
    this.weekDays = days;
    // 学期起始周一（termInfo.ksrq，兜底 2026-08-24，2026-11-17 服务器实测），APK e() 公式推算当前周次
    const termStartMs: number = parseYmdMs(SCHEDULE_FALLBACK_START);
    const termEndMs: number = parseYmdMs(SCHEDULE_FALLBACK_END);
    const week: number = apkCurrentWeek(termStartMs, termEndMs, monday.getTime());
    this.weekNo = week >= 1 ? week : 1;
  }

  /** 从周课表里挑出当前/下一节课 */
  private pickNextCourse(courses: CourseItem[]): void {
    const now: Date = new Date();
    const nowMin: number = now.getHours() * 60 + now.getMinutes();
    const dayIdx: number = now.getDay() === 0 ? 7 : now.getDay();
    // scheduleOfTerm 按 djz 周次拆行：取本周今日课程（APK timetable_djz==当前周 + xqj==星期几）
    const today: CourseItem[] = courses.filter((c: CourseItem): boolean => {
      if (c.dayOfWeek !== dayIdx) {
        return false;
      }
      return c.djz <= 0 || c.djz === this.weekNo;
    });
    const list: CourseItem[] = today.length > 0 ? today : courses;
    let picked: CourseItem | null = null;
    for (const c of list) {
      // 第1节 08:00 起，每节 45min + 10min 课间
      const startMin: number = 480 + (c.sectionStart - 1) * 55;
      const endMin: number = 480 + (c.sectionEnd - 1) * 55 + 45;
      if (endMin >= nowMin) {
        picked = c;
        break;
      }
    }
    if (picked === null && list.length > 0) {
      picked = list[0];
    }
    if (picked !== null) {
      const next: NextCourse = new NextCourse();
      next.has = true;
      next.name = picked.name;
      next.location = picked.location;
      // sectionTimeLabel(s,s) = "HH:MM - HH:MM+45"，拆出开始/结束
      const startFull: string = sectionTimeLabel(picked.sectionStart, picked.sectionStart);
      const endFull: string = sectionTimeLabel(picked.sectionEnd, picked.sectionEnd);
      next.startLabel = startFull.split(' - ')[0];
      next.endLabel = endFull.split(' - ').length > 1 ? endFull.split(' - ')[1] : startFull.split(' - ')[0];
      this.nextCourse = next;
    }
  }

  /** 我的课表卡 */
  @Builder
  scheduleCard() {
    Column() {
      // 卡头：图标 + 我的课表 第N周 …… 更多
      Row() {
        Image($r('app.media.mobile_campus_icon_calendar'))
          .width(22)
          .height(22)
        Text('我的课表')
          .fontSize(17)
          .fontColor($r('app.color.common_color_1'))
          .margin({ left: 8 })
        Text('第' + this.weekNo + '周')
          .fontSize(14)
          .fontColor($r('app.color.common_color_3'))
          .margin({ left: 8 })
        Blank()
        Text('更多')
          .fontSize(15)
          .fontColor($r('app.color.common_color_2'))
          .padding({ left: 6, right: 2, top: 4, bottom: 4 })
          .borderRadius(6)
          .hoverEffect(HoverEffect.Highlight)
          .onClick(() => {
            router.pushUrl({ url: 'pages/SchedulePage' });
          })
      }
      .width('100%')
      .padding({ left: 12, right: 12, top: 12, bottom: 8 })
      .alignItems(VerticalAlign.Center)

      // 课程行：左时间列 + 右课程信息
      if (this.nextCourse.has) {
        Row() {
          Column() {
            Text(this.nextCourse.startLabel)
              .fontSize(20)
              .fontColor($r('app.color.common_color_1'))
            Text(this.nextCourse.endLabel + '下课')
              .fontSize(12)
              .fontColor($r('app.color.common_color_3'))
              .margin({ top: 6 })
          }
          .width(84)
          .padding({ left: 12 })
          .alignItems(HorizontalAlign.Start)

          Column() {
            Text(this.nextCourse.name)
              .fontSize(20)
              .fontColor($r('app.color.common_color_1'))
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
            Row() {
              Image($r('app.media.mobile_campus_schedule_icon_location'))
                .width(14)
                .height(14)
              Text(this.nextCourse.location)
                .fontSize(14)
                .fontColor($r('app.color.common_color_3'))
                .margin({ left: 4 })
            }
            .margin({ top: 8 })
            .alignItems(VerticalAlign.Center)
          }
          .layoutWeight(1)
          .padding({ right: 12 })
          .alignItems(HorizontalAlign.Start)
        }
        .width('100%')
        .padding({ top: 6, bottom: 6 })
        .alignItems(VerticalAlign.Center)

        Divider()
          .color($r('app.color.common_color_6'))
          .strokeWidth(0.5)
          .margin({ left: 12, right: 12 })

        // 右下：添加至桌面 ?
        Row() {
          Blank()
          Text('添加至桌面')
            .fontSize(15)
            .fontColor($r('app.color.common_color_3'))
          Text('?')
            .fontSize(13)
            .fontColor($r('app.color.white'))
            .backgroundColor($r('app.color.common_color_3'))
            .borderRadius(10)
            .width(20)
            .height(20)
            .textAlign(TextAlign.Center)
            .margin({ left: 6 })
        }
        .width('100%')
        .padding({ left: 12, right: 12, top: 8, bottom: 10 })
        .alignItems(VerticalAlign.Center)
      } else {
        Text('今日暂无课程')
          .fontSize(15)
          .fontColor($r('app.color.common_color_3'))
          .width('100%')
          .textAlign(TextAlign.Center)
          .padding({ top: 20, bottom: 20 })
      }
    }
    .width('100%')
    .borderRadius(12)
    .backgroundColor($r('app.color.white'))
  }

  /** 今日日程/会议卡 */
  @Builder
  scheduleMeetingCard() {
    Column() {
      // 卡头
      Row() {
        Image($r('app.media.mobile_campus_main_message_course'))
          .width(22)
          .height(22)
        Text('今日日程/会议')
          .fontSize(17)
          .fontColor($r('app.color.common_color_1'))
          .margin({ left: 8 })
        Blank()
        Text('更多')
          .fontSize(15)
          .fontColor($r('app.color.common_color_2'))
          .padding({ left: 6, right: 2, top: 4, bottom: 4 })
          .borderRadius(6)
          .hoverEffect(HoverEffect.Highlight)
          .onClick(() => {
            router.pushUrl({ url: 'pages/ScheduleMainActivity' });
          })
      }
      .width('100%')
      .padding({ left: 12, right: 12, top: 12, bottom: 4 })
      .alignItems(VerticalAlign.Center)

      // 周历行（APK 实拍：今日为正圆红底白字，周末灰）
      Row() {
        ForEach(this.weekDays, (day: WeekDay) => {
          Stack({ alignContent: Alignment.Center }) {
            if (day.isToday) {
              Column()
                .width(46)
                .height(46)
                .borderRadius(23)
                .backgroundColor($r('app.color.mobile_campus_schedule_color1'))
            }
            Column() {
              Text(day.label)
                .fontSize(15)
                .fontColor(day.isToday ? $r('app.color.white') :
                  (day.isWeekend ? $r('app.color.common_color_3') : $r('app.color.common_color_1')))
              Text(day.date.toString())
                .fontSize(15)
                .margin({ top: 2 })
                .fontColor(day.isToday ? $r('app.color.white') :
                  (day.isWeekend ? $r('app.color.common_color_3') : $r('app.color.common_color_2')))
            }
            .alignItems(HorizontalAlign.Center)
          }
          .layoutWeight(1)
          .height(56)
        }, (day: WeekDay) => 'wd' + day.label + day.date.toString())
      }
      .width('100%')
      .padding({ left: 6, right: 6 })

      // 空态框：浅灰圆角 + 左右短横线
      Column() {
        Row() {
          Row()
            .width(20)
            .height(1)
            .backgroundColor($r('app.color.common_color_3'))
          Text('暂未添加日程')
            .fontSize(16)
            .fontColor($r('app.color.common_color_3'))
            .margin({ left: 12, right: 12 })
          Row()
            .width(20)
            .height(1)
            .backgroundColor($r('app.color.common_color_3'))
        }
        .width('100%')
        .padding({ top: 34, bottom: 34 })
        .backgroundColor($r('app.color.common_color_6'))
        .borderRadius(6)
        .justifyContent(FlexAlign.Center)
        .alignItems(VerticalAlign.Center)
      }
      .width('100%')
      .padding({ top: 12, bottom: 12, left: 12, right: 12 })
    }
    .width('100%')
    .borderRadius(12)
    .backgroundColor($r('app.color.white'))
  }

  build() {
    Column() {
      Scroll(this.scroller) {
        Column() {
          GridRow({ columns: { xs: 1, sm: 1, md: 2, lg: 2, xl: 2 }, gutter: { x: 12, y: 12 } }) {
            GridCol({ span: 1 }) {
              this.scheduleCard()
            }
            GridCol({ span: 1 }) {
              this.scheduleMeetingCard()
            }
          }
          .width('100%')
        }
        .width('100%')
        .padding({
          left: 12,
          right: 12,
          top: 10,
          bottom: this.useSideRail() ? Math.max(16, this.avoidAreaBottomVp + 16) : Math.max(92, this.avoidAreaBottomVp + 76)
        })
      }
      .scrollable(ScrollDirection.Vertical)
      .width('100%')
      .height('100%')
      .align(Alignment.Top)
      .backgroundColor($r('app.color.common_color_6'))
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.common_color_6'))
  }
}

/** 周历单日 */
class WeekDay {
  label: string;
  date: number;
  isToday: boolean;
  isWeekend: boolean;

  constructor(label: string, date: number, isToday: boolean, isWeekend: boolean) {
    this.label = label;
    this.date = date;
    this.isToday = isToday;
    this.isWeekend = isWeekend;
  }
}
