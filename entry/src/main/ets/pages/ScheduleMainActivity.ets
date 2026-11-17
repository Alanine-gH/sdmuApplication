import { TitleBar } from '../components/TitleBar';

/**
 * 日程主页 — 1:1 复刻 mobile_campus_schedule_activity_schedule.xml
 * 结构：LinearLayout(竖向) + toolbar_normal
 *   + mobile_campus_schedule_weekdate_layout（日期行 padding 10vp：
 *     schedule_date_tv / schedule_today_tv(color2, marginL 20vp) / schedule_week_tv(右, primary_color_default)）
 *   + CalendarLayout：CalendarView 周历条(week_bar_height 23vp, 白底) + ScheduleContentLayout(common_color_6)
 *   日程项复刻 mobile_campus_schedule_item.xml：白色圆角卡片 margin 20vp，标题/时间/地点行
 */
class ScheduleEntry {
  name: string;
  time: string;
  local: string;
  type: string;

  constructor(name: string, time: string, local: string, type: string) {
    this.name = name;
    this.time = time;
    this.local = local;
    this.type = type;
  }
}

class WeekDay {
  label: string;
  date: string;

  constructor(label: string, date: string) {
    this.label = label;
    this.date = date;
  }
}

@Entry
@Component
struct ScheduleMainActivity {
  @State selectedDay: number = new Date().getDay() === 0 ? 7 : new Date().getDay();
  private weekDays: WeekDay[] = [
    new WeekDay('日', '15'),
    new WeekDay('一', '16'),
    new WeekDay('二', '17'),
    new WeekDay('三', '18'),
    new WeekDay('四', '19'),
    new WeekDay('五', '20'),
    new WeekDay('六', '21')
  ];
  private scheduleItems: ScheduleEntry[] = [
    new ScheduleEntry('班会：期中学风建设主题班会', '08:30 - 10:10', '第一教学楼 301', '会议'),
    new ScheduleEntry('高等数学辅导答疑', '14:00 - 15:40', '答疑室 A204', '日程'),
    new ScheduleEntry('班级篮球友谊赛', '16:30 - 18:00', '体育馆', '活动'),
    new ScheduleEntry('晚自习', '19:00 - 21:30', '图书馆三楼', '日程')
  ];

  build() {
    Column() {
      TitleBar({ title: '日程', showBack: true })

      // weekdate_layout 日期行
      Row() {
        Text('2026年11月')
          .fontSize(16)
          .fontColor($r('app.color.mobile_campus_schedule_color2'))
        Text('今天 11月17日')
          .fontSize(16)
          .fontColor($r('app.color.mobile_campus_schedule_color2'))
          .layoutWeight(1)
          .margin({ left: 20 })
        Text('第12周')
          .fontSize(16)
          .fontColor($r('app.color.mobile_campus_primary_color_default'))
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)
      .padding(10)

      // CalendarView 周历条：week_bar_height 23vp 白底
      Row() {
        ForEach(this.weekDays, (item: WeekDay, index: number) => {
          Column() {
            Text(item.label)
              .fontSize(10)
              .fontColor(index + 1 === this.selectedDay ? $r('app.color.mobile_campus_schedule_color4') : $r('app.color.common_color_1'))
            Text(item.date)
              .fontSize(14)
              .fontColor(index + 1 === this.selectedDay ? $r('app.color.white') : $r('app.color.common_color_1'))
              .width(24)
              .height(24)
              .textAlign(TextAlign.Center)
              .borderRadius(12)
              .backgroundColor(index + 1 === this.selectedDay ? $r('app.color.mobile_campus_schedule_color4') : Color.Transparent)
              .margin({ top: 2 })
          }
          .layoutWeight(1)
        }, (item: WeekDay) => item.label + item.date)
      }
      .width('100%')
      .height(46)
      .alignItems(VerticalAlign.Center)
      .padding({ left: 5, right: 5 })
      .backgroundColor('#FFFFFF')

      // ScheduleContentLayout
      Scroll() {
        Column() {
          ForEach(this.scheduleItems, (item: ScheduleEntry) => {
            // schedule_item_container：白色圆角卡片 margin 20vp
            Row() {
              Column() {
                Text(item.name)
                  .fontSize(16)
                  .fontWeight(FontWeight.Bold)
                  .fontColor($r('app.color.common_color_1'))
                  .maxLines(2)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
                  .margin({ top: 5, bottom: 13 })
                  .width('100%')

                Row() {
                  Text('时间 ' + item.time)
                    .fontSize(15)
                    .fontColor($r('app.color.mobile_campus_schedule_color3'))
                    .maxLines(1)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                    .layoutWeight(1)
                }
                .width('100%')

                Row() {
                  Text('地点 ' + item.local)
                    .fontSize(15)
                    .fontColor($r('app.color.mobile_campus_schedule_color3'))
                    .maxLines(1)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                    .layoutWeight(1)

                  // schedule_item_type：深蓝底白字标签
                  Text(item.type)
                    .fontSize(14)
                    .fontWeight(FontWeight.Bold)
                    .fontColor($r('app.color.white'))
                    .padding({ left: 5, right: 10, top: 3, bottom: 3 })
                    .backgroundColor($r('app.color.mobile_campus_schedule_confirm_blue'))
                }
                .width('100%')
                .alignItems(VerticalAlign.Center)
                .margin({ top: 8 })
              }
              .alignItems(HorizontalAlign.Start)
              .layoutWeight(1)
              .padding({ left: 17, right: 13, top: 10, bottom: 10 })
              .margin({ left: 15 })

              Image($r('app.media.arrow_right'))
                .width(14)
                .height(14)
                .margin({ right: 12 })
            }
            .width('100%')
            .alignItems(VerticalAlign.Center)
            .margin({ left: 20, right: 20, top: 20 })
            .borderRadius(6)
            .backgroundColor($r('app.color.ybg_white'))
            .onClick(() => {
              this.getUIContext().getPromptAction().showToast({ message: '查看日程：' + item.name });
            })
          }, (item: ScheduleEntry) => item.name + item.time)
        }
        .width('100%')
        .padding({ bottom: 20 })
      }
      .width('100%')
      .layoutWeight(1)
      .scrollBar(BarState.Off)
      .backgroundColor($r('app.color.common_color_6'))
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.main_bg'))
  }
}
