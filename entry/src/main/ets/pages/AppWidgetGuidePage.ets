import { TitleBar } from '../components/TitleBar';

/**
 * 桌面小部件引导页 — 1:1 复刻 mobile_campus_timetable_activity_guide.xml
 * 结构：LinearLayout(common_color_6) + toolbar_normal + WebView(mWebView)
 * WebView 加载桌面小部件预览，此处按引导内容用小部件布局 1:1 静态还原：
 *   mobile_campus_timetable_timetable_desk.xml：
 *     round_shape_timetable_bg 卡（圆角6vp、timetable_bg #60FFFFFF）
 *     + "第1周" 14fp(px_to_sp_28) timetable_text paddingTop 6 paddingBottom 3
 *     + desk_head：日期行 paddingBottom 9vp(px_to_dip_18)，首列 30vp，7列 12fp(px_to_sp_24)
 *     + 0.8vp timetable_bg2 分隔线
 *     + time_item：8行×30vp(timetable_desk_item_height) 交替 timetable_bg3/timetable_bg2，
 *       竖分隔线 0.8vp @31vp(px_to_dip_62)，container 7列 marginLeft 32vp(px_to_dip_64)，高240vp
 *     + course_box：课程名 11fp(px_to_dip_22) 白字 padding 3vp(px_to_dip_6)，右上 multi_tag 角标
 *     + desk_button：上/下周按钮 padding 12vp(px_to_dip_24)
 *
 * 数据源：无服务器接口 — 桌面小部件数据来自 AppWidgetProvider 本地缓存，预览为内置示例数据。
 */
class DeskCourse {
  name: string;
  startSection: number;
  span: number;
  color: string;
  multi: boolean;

  constructor(name: string, startSection: number, span: number, color: string, multi: boolean) {
    this.name = name;
    this.startSection = startSection;
    this.span = span;
    this.color = color;
    this.multi = multi;
  }
}

class DeskColumn {
  day: string;
  date: string;
  courses: DeskCourse[];

  constructor(day: string, date: string, courses: DeskCourse[]) {
    this.day = day;
    this.date = date;
    this.courses = courses;
  }
}

@Entry
@Component
struct AppWidgetGuidePage {
  private static readonly SECTION_HEIGHT: number = 30;
  private static readonly GRID_HEIGHT: number = 240;
  private headColumns: DeskColumn[] = [
    new DeskColumn('一', '11/16', [new DeskCourse('高等数学', 0, 2, '#1B68B7', false), new DeskCourse('大学英语', 4, 2, '#52BEFF', false)]),
    new DeskColumn('二', '11/17', [new DeskCourse('数据结构', 6, 2, '#67B438', false)]),
    new DeskColumn('三', '11/18', [new DeskCourse('大学英语', 2, 2, '#52BEFF', false), new DeskCourse('体育', 4, 2, '#FF8900', false)]),
    new DeskColumn('四', '11/19', [new DeskCourse('毛泽东思想概论', 0, 2, '#FF9999', true)]),
    new DeskColumn('五', '11/20', [new DeskCourse('高等数学', 2, 2, '#1B68B7', false)]),
    new DeskColumn('六', '11/21', []),
    new DeskColumn('日', '11/22', [])
  ];

  build() {
    Column() {
      TitleBar({ title: '桌面小部件引导', showBack: true })

      Scroll() {
        Column() {
          Text('长按桌面空白处，选择"添加工具"，找到"山东管理学院"即可将课表小部件添加到桌面')
            .fontSize(14)
            .fontColor($r('app.color.common_color_3'))
            .margin({ top: 12 })

          // timetable_desk 卡片：round_shape_timetable_bg
          Column() {
            // "第1周" 标题 paddingTop 6(pb 3)
            Text('第1周')
              .fontSize(14)
              .fontColor($r('app.color.timetable_text'))
              .textAlign(TextAlign.Center)
              .width('100%')
              .padding({ top: 6, bottom: 3 })

            // desk_head：日期行 paddingBottom 9vp
            Row() {
              Blank().width(30)
              ForEach(this.headColumns, (col: DeskColumn) => {
                Text(col.day + ' ' + col.date)
                  .fontSize(12)
                  .fontColor($r('app.color.timetable_text'))
                  .textAlign(TextAlign.Center)
                  .layoutWeight(1)
              }, (col: DeskColumn) => col.day + col.date)
            }
            .width('100%')
            .padding({ bottom: 9 })

            // 0.8vp 分隔线
            Text()
              .width('100%')
              .height(0.8)
              .backgroundColor($r('app.color.timetable_bg2'))

            // 时间列 + 竖分隔线 + 7列课程容器
            Stack({ alignContent: Alignment.Start }) {
              // time_item：8行
              Column() {
                ForEach([1, 2, 3, 4, 5, 6, 7, 8], (num: number) => {
                  Row() {
                    Text(num.toString())
                      .fontSize(12)
                      .fontColor($r('app.color.timetable_text'))
                      .textAlign(TextAlign.Center)
                      .width(30)
                  }
                  .width('100%')
                  .height(AppWidgetGuidePage.SECTION_HEIGHT)
                  .alignItems(VerticalAlign.Center)
                  .backgroundColor(num % 2 === 1 ? $r('app.color.timetable_bg3') : $r('app.color.timetable_bg2'))
                }, (num: number) => 'section' + num.toString())
              }
              .width('100%')

              // 竖分隔线 @31vp
              Text()
                .width(0.8)
                .height(AppWidgetGuidePage.GRID_HEIGHT)
                .backgroundColor($r('app.color.timetable_bg2'))
                .margin({ left: 31 })

              // container：7列 marginLeft 32vp
              Row() {
                ForEach(this.headColumns, (col: DeskColumn, colIndex: number) => {
                  Stack() {
                    Column()
                      .width('100%')
                      .height(AppWidgetGuidePage.GRID_HEIGHT)
                    ForEach(col.courses, (course: DeskCourse) => {
                      // course_box：白字 11fp padding 3vp
                      Stack({ alignContent: Alignment.TopEnd }) {
                        Text(course.name)
                          .fontSize(11)
                          .fontColor($r('app.color.white'))
                          .maxLines(3)
                          .textOverflow({ overflow: TextOverflow.Ellipsis })
                          .padding({ left: 3, right: 3, top: 1 })
                          .width('100%')
                        if (course.multi) {
                          Image($r('app.media.mobile_campus_timetable_course_box_multi_tag'))
                            .width(10)
                            .height(10)
                        }
                      }
                      .width('100%')
                      .height(course.span * AppWidgetGuidePage.SECTION_HEIGHT)
                      .backgroundColor(course.color)
                      .margin({ top: course.startSection * AppWidgetGuidePage.SECTION_HEIGHT })
                    }, (course: DeskCourse) => col.day + course.name)
                  }
                  .layoutWeight(1)
                  .alignContent(Alignment.Start)
                }, (col: DeskColumn) => 'container' + col.day)
              }
              .width('100%')
              .height(AppWidgetGuidePage.GRID_HEIGHT)
              .margin({ left: 32 })
            }
            .width('100%')

            // 0.8vp 分隔线
            Text()
              .width('100%')
              .height(0.8)
              .backgroundColor($r('app.color.timetable_bg2'))

            // desk_button：上/下周
            Row() {
              Row() {
                Image($r('app.media.arrow_up_grey_desk_widget'))
                  .width(15)
                  .height(9)
              }
              .layoutWeight(1)
              .justifyContent(FlexAlign.Center)
              .padding(12)

              Row() {
                Image($r('app.media.arrow_down_grey_desk_widget'))
                  .width(15)
                  .height(9)
              }
              .layoutWeight(1)
              .justifyContent(FlexAlign.Center)
              .padding(12)
            }
            .width('100%')
          }
          .width('100%')
          .backgroundColor($r('app.color.timetable_bg'))
          .borderRadius(6)
          .clip(true)
          .margin({ top: 12 })
        }
        .padding({ left: 12, right: 12, bottom: 12 })
      }
      .width('100%')
      .layoutWeight(1)
      .scrollBar(BarState.Off)
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.common_color_6'))
  }
}
