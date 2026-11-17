import { TitleBar } from '../components/TitleBar';

/**
 * 日程周详情页 — 1:1 复刻 mobile_campus_timetable_activity_weekcourse.xml
 * 结构：ScrollView > FrameLayout
 *   + timetable_week_view_lv 周视图列表（左侧月份/节次列 timetable_month_width 50dip + CourseBox 偏移 px_to_dip_100=50vp）
 *   + 底部复刻 timetable_layout_day_course_appwidget.xml 今日课程条：
 *     节次(px_to_dip_24=12fp color31) + 课程(px_to_dip_34=17fp color1) + 地点/时间(12fp color31 带图标) + 上下箭头
 */
class WeekCourseCell {
  day: number;
  section: number;
  name: string;
  room: string;
  color: string;

  constructor(day: number, section: number, name: string, room: string, color: string) {
    this.day = day;
    this.section = section;
    this.name = name;
    this.room = room;
    this.color = color;
  }
}

@Entry
@Component
struct ScheduleWeekDetailPage {
  @State todayIndex: number = 2;
  @State widgetSection: string = '第3节';
  @State widgetName: string = '数据结构与算法';
  @State widgetRoom: string = '第一教学楼 402';
  @State widgetTeacher: string = '王老师 · 10:00 - 11:40';
  @State todayCourses: WeekCourseCell[] = [
    new WeekCourseCell(2, 3, '数据结构与算法', '第一教学楼 402', '#52BEFF'),
    new WeekCourseCell(2, 4, '大学英语（二）', '外语楼 105', '#FF9999')
  ];
  private dayLabels: string[] = ['一', '二', '三', '四', '五', '六', '日'];
  private sections: number[] = [1, 2, 3, 4, 5];
  private courses: WeekCourseCell[] = [
    new WeekCourseCell(0, 0, '高等数学（上）', 'A301', '#52BEFF'),
    new WeekCourseCell(1, 1, '大学英语（二）', 'B105', '#FF9999'),
    new WeekCourseCell(2, 2, '数据结构与算法', 'C402', '#52BEFF'),
    new WeekCourseCell(3, 0, '大学物理', 'B203', '#FF9999'),
    new WeekCourseCell(4, 3, '体育（篮球）', '体育馆', '#57C06B')
  ];

  private courseAt(day: number, section: number): WeekCourseCell | undefined {
    for (let c of this.courses) {
      if (c.day === day && c.section === section) {
        return c;
      }
    }
    return undefined;
  }

  build() {
    Column() {
      TitleBar({ title: '本周课表', showBack: true })

      // 星期头
      Row() {
        Text('11月')
          .fontSize(12)
          .fontColor($r('app.color.common_color_3'))
          .width(50)
          .textAlign(TextAlign.Center)
        ForEach(this.dayLabels, (label: string, index: number) => {
          Text('周' + label)
            .fontSize(13)
            .fontColor(index === this.todayIndex ? $r('app.color.mobile_campus_schedule_color4') : $r('app.color.common_color_1'))
            .layoutWeight(1)
            .textAlign(TextAlign.Center)
        }, (label: string) => 'weekhead_' + label)
      }
      .width('100%')
      .height(36)
      .alignItems(VerticalAlign.Center)
      .backgroundColor($r('app.color.ybg_white'))

      // 周视图：ScrollView > 左节次列(50vp) + 7列课程格
      Scroll() {
        Row() {
          // timetable_week_view_lv 左侧节次列：timetable_month_width 50dip
          Column() {
            ForEach(this.sections, (section: number) => {
              Text('第' + section + '节')
                .fontSize(13)
                .fontColor($r('app.color.common_color_3'))
                .width(50)
                .height(90)
                .textAlign(TextAlign.Center)
            }, (section: number) => 'section_' + section)
          }
          .width(50)

          // CourseBox 区域：margin-left px_to_dip_100 = 50vp
          Column() {
            ForEach(this.sections, (section: number) => {
              Row() {
                ForEach(this.dayLabels, (label: string, dayIndex: number) => {
                  Stack() {
                    Column()
                      .width('100%')
                      .height(90)
                      .border({
                        width: 0.5,
                        color: $r('app.color.common_color_5')
                      })

                    if (this.courseAt(dayIndex, section - 1) !== undefined) {
                      Column() {
                        Text(this.courseAt(dayIndex, section - 1)!.name)
                          .fontSize(12)
                          .fontColor($r('app.color.white'))
                          .maxLines(2)
                          .textOverflow({ overflow: TextOverflow.Ellipsis })
                          .textAlign(TextAlign.Center)
                        Text(this.courseAt(dayIndex, section - 1)!.room)
                          .fontSize(10)
                          .fontColor($r('app.color.white'))
                          .maxLines(1)
                          .margin({ top: 4 })
                      }
                      .width('100%')
                      .height(88)
                      .justifyContent(FlexAlign.Center)
                      .padding(3)
                      .borderRadius(4)
                      .backgroundColor(this.courseAt(dayIndex, section - 1)!.color)
                    }
                  }
                  .layoutWeight(1)
                  .height(90)
                }, (label: string, dayIndex: number) => 'cell_' + section + '_' + dayIndex)
              }
              .width('100%')
              .height(90)
            }, (section: number) => 'row_' + section)
          }
          .layoutWeight(1)
          .margin({ left: 50 })
        }
        .width('100%')
        .alignItems(VerticalAlign.Top)
        .padding({ bottom: 10 })
      }
      .width('100%')
      .layoutWeight(1)
      .scrollBar(BarState.Off)
      .backgroundColor($r('app.color.ybg_white'))

      // 今日课程条：timetable_layout_day_course_appwidget.xml
      Row() {
        Row() {
          Text(this.widgetSection)
            .fontSize(12)
            .fontColor($r('app.color.common_color_31'))
            .margin({ left: 9, right: 15 })

          Column() {
            Text(this.widgetName)
              .fontSize(17)
              .fontColor($r('app.color.common_color_1'))
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
              .margin({ bottom: 20 })

            Row() {
              Row() {
                Image($r('app.media.mobile_campus_timetable_widget_timetable_locale'))
                  .width(12)
                  .height(12)
                Text(this.widgetRoom)
                  .fontSize(12)
                  .fontColor($r('app.color.common_color_31'))
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
                  .margin({ left: 8 })
              }
              .margin({ right: 24 })

              Row() {
                Image($r('app.media.mobile_campus_timetable_widget_timetable_time'))
                  .width(12)
                  .height(12)
                Text(this.widgetTeacher)
                  .fontSize(12)
                  .fontColor($r('app.color.common_color_31'))
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
                  .margin({ left: 8 })
              }
            }
            .width('100%')
          }
          .alignItems(HorizontalAlign.Start)
          .layoutWeight(1)
          .padding({ top: 20, bottom: 20 })
        }
        .layoutWeight(1)
        .alignItems(VerticalAlign.Center)
        .backgroundColor($r('app.color.white'))
        .onClick(() => {
          this.getUIContext().getPromptAction().showToast({ message: '今日课程：' + this.widgetName });
        })

        // 白色间隔条 px_to_dip_4 = 2vp
        Column()
          .width(2)
          .backgroundColor($r('app.color.white'))

        Column() {
          Row() {
            Image($r('app.media.arrow_up'))
              .width(16)
              .height(16)
          }
          .layoutWeight(1)
          .width('100%')
          .justifyContent(FlexAlign.Center)
          .alignItems(VerticalAlign.Center)
          .padding({ left: 7, right: 7 })
          .onClick(() => {
            this.getUIContext().getPromptAction().showToast({ message: '上一节课程' });
          })

          Row() {
            Image($r('app.media.arrow_down'))
              .width(16)
              .height(16)
          }
          .layoutWeight(1)
          .width('100%')
          .justifyContent(FlexAlign.Center)
          .alignItems(VerticalAlign.Center)
          .padding({ left: 7, right: 7 })
          .onClick(() => {
            this.getUIContext().getPromptAction().showToast({ message: '下一节课程' });
          })
        }
        .height('100%')
      }
      .width('100%')
      .height(80)
      .alignItems(VerticalAlign.Center)
      .border({ width: 0.5, color: $r('app.color.common_color_5') })
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.main_bg'))
  }
}
