import { router } from '@kit.ArkUI';
import { TitleBar } from '../components/TitleBar';

/**
 * 周计划 — 1:1 复刻（px_to_dip_N = N/2 vp, px_to_sp_N = N/2 fp）：
 * mobile_campus_meeting_fragment_week_plan.xml：weekView marginTop 8 + 会议列表
 * mobile_campus_meeting_weekdate_layout.xml：日期行 padding 10（日期 16fp #B2BDC9 / 今天 16fp #B2BDC9
 *   weight1 marginLeft 20 / 星期 16fp 主色居右）+ 星期表头（px_to_sp_26=13fp，paddingTop/Bottom 5）
 *   + MeetingWeekPager 44vp（7 个日期格，选中主色圆底白字）
 * mobile_campus_meeting_view_weekplan_detail.xml：详情卡白底：tvTitle 19fp margin 18/19/15 单行；
 *   tvCancelContent 14fp #FF6666；btnCancel 14fp #C80D28 边框圆角 padding 5/12；imgCancel 61vp；
 *   0.5 分隔线 #F2F2F2；layoutContainer marginTop 12（复用会议条目）
 * 条目复刻 meeting_view_main_child.xml
 */

interface WeekDay {
  dayLabel: string;
  dateNum: string;
  selected: boolean;
  hasMeeting: boolean;
}

interface WeekPlanItem {
  id: string;
  day: string;
  title: string;
  hasReport: boolean;
  mustAttend: boolean;
  location: string;
  time: string;
  cancelled: boolean;
}

function buildWeekDays(): WeekDay[] {
  const days: WeekDay[] = [
    { dayLabel: '周日', dateNum: '15', selected: false, hasMeeting: false },
    { dayLabel: '周一', dateNum: '16', selected: false, hasMeeting: false },
    { dayLabel: '周二', dateNum: '17', selected: true, hasMeeting: true },
    { dayLabel: '周三', dateNum: '18', selected: false, hasMeeting: true },
    { dayLabel: '周四', dateNum: '19', selected: false, hasMeeting: false },
    { dayLabel: '周五', dateNum: '20', selected: false, hasMeeting: false },
    { dayLabel: '周六', dateNum: '21', selected: false, hasMeeting: false }
  ];
  return days;
}

function buildWeekItems(): WeekPlanItem[] {
  const item1: WeekPlanItem = {
    id: 'w1', day: '17', title: '2026年秋季学期教学工作推进会', hasReport: true, mustAttend: false,
    location: '行政楼三楼会议室', time: '09:00 - 11:00', cancelled: false
  };
  const item2: WeekPlanItem = {
    id: 'w2', day: '17', title: '学生工作例会', hasReport: false, mustAttend: true,
    location: '学生活动中心201', time: '14:30 - 16:00', cancelled: false
  };
  const item3: WeekPlanItem = {
    id: 'w3', day: '18', title: '期末考试安排协调会', hasReport: true, mustAttend: false,
    location: '教务处会议室', time: '10:00 - 11:30', cancelled: true
  };
  return [item1, item2, item3];
}

@Component
struct WeekPlanChildItem {
  item: WeekPlanItem = {
    id: '', day: '', title: '', hasReport: false, mustAttend: false, location: '', time: '', cancelled: false
  };

  build() {
    Row() {
      Text(this.item.day)
        .fontSize(20)
        .fontColor(this.item.cancelled ? $r('app.color.common_color_3') : $r('app.color.common_color_1'))
        .width(44)
        .textAlign(TextAlign.Center)

      Image($r('app.media.mobile_campus_meeting_timeline'))
        .width(16)
        .height(44)
        .objectFit(ImageFit.Contain)

      Column() {
        Row() {
          if (this.item.hasReport) {
            Text('报告')
              .fontSize(9)
              .fontColor($r('app.color.ybg_white'))
              .textAlign(TextAlign.Center)
              .width(24)
              .height(16)
              .backgroundColor($r('app.color.mobile_campus_primary_color_default'))
              .borderRadius(3)
              .margin({ right: 4 })
          }
          Text(this.item.title)
            .fontSize(17)
            .fontColor(this.item.cancelled
              ? $r('app.color.common_color_3')
              : $r('app.color.common_color_1'))
            .layoutWeight(1)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .decoration({ type: this.item.cancelled ? TextDecorationType.LineThrough : TextDecorationType.None })
          if (this.item.mustAttend) {
            Text('必须参加')
              .fontSize(11)
              .fontColor($r('app.color.mobile_campus_meeting_must_attend_text'))
              .padding({ left: 8, right: 8, top: 2, bottom: 2 })
              .border({
                width: 1,
                color: $r('app.color.mobile_campus_meeting_must_attend_border'),
                radius: 3
              })
              .margin({ left: 4, right: 4 })
          }
        }
        .width('100%')
        .alignItems(VerticalAlign.Center)

        Row() {
          Image($r('app.media.mobile_campus_meeting_location_s'))
            .width(12)
            .height(12)
            .margin({ right: 6 })
          Text(this.item.location)
            .fontSize(12)
            .fontColor($r('app.color.common_color_3'))
            .maxLines(1)
        }
        .width('100%')
        .margin({ top: 6 })
        .alignItems(VerticalAlign.Center)

        Row() {
          Image($r('app.media.mobile_campus_meeting_time_s'))
            .width(12)
            .height(12)
            .margin({ right: 6 })
          Text(this.item.time)
            .fontSize(12)
            .fontColor($r('app.color.common_color_3'))
            .maxLines(1)
        }
        .width('100%')
        .margin({ top: 6 })
        .alignItems(VerticalAlign.Center)
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
      .margin({ left: 10, top: 14, bottom: 14 })
    }
    .width('100%')
    .backgroundColor($r('app.color.white'))
    .padding({ left: 8 })
    .alignItems(VerticalAlign.Top)
    .onClick(() => {
      router.pushUrl({ url: 'pages/MeetingDetailPage', params: { id: this.item.id } });
    })
  }
}

@Component
struct WeekPlanDetailCard {
  item: WeekPlanItem = {
    id: '', day: '', title: '', hasReport: false, mustAttend: false, location: '', time: '', cancelled: false
  };

  build() {
    Column() {
      Row() {
        Text(this.item.title)
          .fontSize(19)
          .fontColor(this.item.cancelled
            ? $r('app.color.common_color_3')
            : $r('app.color.common_color_1'))
          .margin({ left: 18, top: 19, bottom: 15 })
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .layoutWeight(1)

        if (this.item.cancelled) {
          Image($r('app.media.mobile_campus_meeting_cancel'))
            .width(61)
            .height(61)
        } else {
          Text('取消')
            .fontSize(14)
            .fontColor($r('app.color.mobile_campus_meeting_must_attend_text'))
            .padding({ left: 12, right: 12, top: 5, bottom: 5 })
            .border({ width: 1, color: '#C80D28', radius: 4 })
            .margin({ right: 18 })
        }
      }
      .width('100%')
      .alignItems(VerticalAlign.Top)

      if (this.item.cancelled) {
        Text('注：发起人由于临时原因取消会议')
          .fontSize(14)
          .fontColor('#FF6666')
          .margin({ left: 18, bottom: 12 })
          .width('100%')
      }

      Divider()
        .color($r('app.color.mobile_campus_bg_color'))
        .strokeWidth(0.5)
        .width('100%')

      Column() {
        WeekPlanChildItem({ item: this.item })
      }
      .width('100%')
      .margin({ top: 12 })
    }
    .width('100%')
    .backgroundColor($r('app.color.white'))
    .alignItems(HorizontalAlign.Start)
  }
}

@Entry
@Component
struct MeetingWeekPlanPage {
  @State weekDays: WeekDay[] = buildWeekDays();
  @State planItems: WeekPlanItem[] = buildWeekItems();
  private weekHeaders: string[] = ['日', '一', '二', '三', '四', '五', '六'];

  private selectDay(dayLabel: string): void {
    const updated: WeekDay[] = [];
    for (const d of this.weekDays) {
      const target: WeekDay = {
        dayLabel: d.dayLabel, dateNum: d.dateNum, hasMeeting: d.hasMeeting,
        selected: d.dayLabel === dayLabel
      };
      updated.push(target);
    }
    this.weekDays = updated;
  }

  build() {
    Column() {
      TitleBar({ title: '周计划', showBack: true })

      Scroll() {
        Column() {
          // weekdate_layout：weekView marginTop 8
          Column() {
            Row() {
              Text('2026年11月')
                .fontSize(16)
                .fontColor($r('app.color.mobile_campus_schedule_color2'))
              Text('今天 11月17日')
                .fontSize(16)
                .fontColor($r('app.color.mobile_campus_schedule_color2'))
                .layoutWeight(1)
                .margin({ left: 20 })
              Text('月视图')
                .fontSize(16)
                .fontColor($r('app.color.mobile_campus_primary_color_default'))
            }
            .width('100%')
            .padding(10)
            .alignItems(VerticalAlign.Center)

            Row() {
              ForEach(this.weekHeaders, (header: string, index: number) => {
                Text(header)
                  .fontSize(13)
                  .fontColor(index === 0 || index === 6
                    ? $r('app.color.mobile_campus_schedule_color2')
                    : $r('app.color.common_color_1'))
                  .textAlign(TextAlign.Center)
                  .layoutWeight(1)
              }, (header: string) => 'wh_' + header)
            }
            .width('100%')
            .padding({ top: 5, bottom: 5 })

            // MeetingWeekPager 44vp
            Row() {
              ForEach(this.weekDays, (day: WeekDay) => {
                Column() {
                  Text(day.dateNum)
                    .fontSize(15)
                    .fontColor(day.selected
                      ? $r('app.color.white')
                      : $r('app.color.common_color_1'))
                    .textAlign(TextAlign.Center)
                  if (day.hasMeeting) {
                    Circle({ width: 4, height: 4 })
                      .fill(day.selected ? $r('app.color.white') : $r('app.color.mobile_campus_primary_color_default'))
                      .margin({ top: 2 })
                  }
                }
                .width(32)
                .height(32)
                .borderRadius(16)
                .backgroundColor(day.selected
                  ? $r('app.color.mobile_campus_primary_color_default')
                  : Color.Transparent)
                .justifyContent(FlexAlign.Center)
                .alignItems(HorizontalAlign.Center)
                .onClick(() => {
                  this.selectDay(day.dayLabel);
                })
              }, (day: WeekDay) => day.dayLabel + (day.selected ? '_sel' : ''))
            }
            .width('100%')
            .height(44)
            .justifyContent(FlexAlign.SpaceAround)
            .alignItems(VerticalAlign.Center)
          }
          .width('100%')
          .margin({ top: 8 })
          .backgroundColor($r('app.color.white'))

          // view_weekplan_detail 详情卡列表
          ForEach(this.planItems, (item: WeekPlanItem) => {
            WeekPlanDetailCard({ item: item })
              .margin({ top: 12 })
          }, (item: WeekPlanItem) => item.id)
        }
        .width('100%')
        .padding({ bottom: 24 })
      }
      .width('100%')
      .layoutWeight(1)
      .align(Alignment.Top)
      .scrollBar(BarState.Off)
      .backgroundColor($r('app.color.mobile_campus_bg_color'))
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.mobile_campus_bg_color'))
  }
}
