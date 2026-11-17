import { TitleBar } from '../components/TitleBar';

/**
 * 课程详情页 — 1:1 复刻 mobile_campus_timetable_activity_coursedetail.xml
 * 结构：LinearLayout(#F2F2F2) + toolbar_normal + ScrollView
 *   1. 课程信息卡（白底 padding 15vp）：课程名 19fp #333333 + 周数/节数/地点行
 *      （图标 21x21 + 标签 17fp #999999 + 值 16fp #333333）
 *   2. 上课时间行（白底 padding 15vp）
 *   3. 成绩区块（挂科率/平均分/历史最高分/最高分保持者）
 *   4. 授课恩师 / 上课学生行 + 男女生比例块
 *
 * 数据源：无服务器接口 — ApiService 未提供课程详情/挂科率/男女比例等统计端点，
 * 且本页未从路由接收课程参数，页面数据为内置示例数据，未接 ApiService。
 */
class CourseDetailInfo {
  courseName: string = '';
  weekTime: string = '';
  session: string = '';
  place: string = '';
  classTime: string = '';
  teacher: string = '';
  noPassRate: string = '';
  averageScore: string = '';
  highestScore: string = '';
  highestScorePeople: string = '';
  classStudent: string = '';
  boyPercent: number = 50;

  constructor(courseName: string, weekTime: string, session: string, place: string, classTime: string,
    teacher: string, noPassRate: string, averageScore: string, highestScore: string,
    highestScorePeople: string, classStudent: string, boyPercent: number) {
    this.courseName = courseName;
    this.weekTime = weekTime;
    this.session = session;
    this.place = place;
    this.classTime = classTime;
    this.teacher = teacher;
    this.noPassRate = noPassRate;
    this.averageScore = averageScore;
    this.highestScore = highestScore;
    this.highestScorePeople = highestScorePeople;
    this.classStudent = classStudent;
    this.boyPercent = boyPercent;
  }
}

@Entry
@Component
struct CourseDetailPage {
  @State course: CourseDetailInfo = new CourseDetailInfo('高等数学（下册）', '第1-18周', '第1-2节',
    '教学楼A栋302多媒体教室', '周一 08:00 - 09:40', '王建国 教授', '12.5%', '82.5分', '98分',
    '李明（2023级）', '45人', 50);

  build() {
    Column() {
      TitleBar({ title: '课程详情', showBack: true })

      Scroll() {
        Column() {
          // divider_horizontal_grey_normal
          Divider()
            .color($r('app.color.common_color_5'))
            .strokeWidth(0.5)
            .width('100%')

          // 课程信息卡
          Column() {
            Text(this.course.courseName)
              .fontSize(19)
              .fontColor($r('app.color.common_color_1'))
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
              .width('100%')

            // 周数行
            Row() {
              Image($r('app.media.mobile_campus_timetable_course_week'))
                .width(21)
                .height(21)
              Text('周数')
                .fontSize(17)
                .fontColor($r('app.color.common_color_3'))
                .margin({ left: 6 })
              Text(this.course.weekTime)
                .fontSize(16)
                .fontColor($r('app.color.common_color_1'))
                .margin({ left: 10 })
                .layoutWeight(1)
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
            }
            .width('100%')
            .alignItems(VerticalAlign.Center)
            .margin({ top: 15 })

            // 节数行
            Row() {
              Image($r('app.media.mobile_campus_timetable_course_section'))
                .width(21)
                .height(21)
              Text('节数')
                .fontSize(17)
                .fontColor($r('app.color.common_color_3'))
                .margin({ left: 6 })
                .maxLines(1)
              Text(this.course.session)
                .fontSize(16)
                .fontColor($r('app.color.common_color_1'))
                .margin({ left: 10 })
                .layoutWeight(1)
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
            }
            .width('100%')
            .alignItems(VerticalAlign.Center)
            .margin({ top: 15 })

            // 地点行
            Row() {
              Image($r('app.media.mobile_campus_timetable_course_place'))
                .width(21)
                .height(21)
              Text('地点')
                .fontSize(17)
                .fontColor($r('app.color.common_color_3'))
                .margin({ left: 6 })
              Text(this.course.place)
                .fontSize(16)
                .fontColor($r('app.color.common_color_1'))
                .margin({ left: 10 })
                .layoutWeight(1)
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
            }
            .width('100%')
            .alignItems(VerticalAlign.Center)
            .margin({ top: 15 })
          }
          .width('100%')
          .padding(15)
          .backgroundColor($r('app.color.white'))

          // divider_horizontal_grey_normal
          Divider()
            .color($r('app.color.common_color_5'))
            .strokeWidth(0.5)
            .width('100%')

          // 上课时间行
          Row() {
            Image($r('app.media.mobile_campus_timetable_course_classtime'))
              .width(21)
              .height(21)
            Text('上课时间')
              .fontSize(16)
              .fontColor($r('app.color.common_color_1'))
              .margin({ left: 6 })
            Text(this.course.classTime)
              .fontSize(16)
              .fontColor($r('app.color.common_color_1'))
              .margin({ left: 10 })
              .layoutWeight(1)
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
          }
          .width('100%')
          .alignItems(VerticalAlign.Center)
          .padding(15)
          .backgroundColor($r('app.color.white'))

          // divider_horizontal_grey_normal
          Divider()
            .color($r('app.color.common_color_5'))
            .strokeWidth(0.5)
            .width('100%')

          // 成绩区块（挂科率 / 平均分 / 历史最高分 / 最高分保持者）
          Column() {
            Row() {
              Image($r('app.media.no_pass_rate'))
                .width(23)
                .height(23)
              Text('挂科率')
                .fontSize(16)
                .fontColor($r('app.color.common_color_1'))
                .margin({ left: 6 })
                .layoutWeight(1)
              Text(this.course.noPassRate)
                .fontSize(17)
                .fontColor($r('app.color.common_color_3'))
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
            }
            .width('100%')
            .alignItems(VerticalAlign.Center)
            .padding({ left: 15, right: 15, top: 15, bottom: 15 })

            Divider()
              .color($r('app.color.common_color_5'))
              .strokeWidth(0.5)
              .width('100%')

            Row() {
              Image($r('app.media.average_score'))
                .width(23)
                .height(23)
              Text('平均分')
                .fontSize(16)
                .fontColor($r('app.color.common_color_1'))
                .margin({ left: 6 })
                .layoutWeight(1)
              Text(this.course.averageScore)
                .fontSize(17)
                .fontColor($r('app.color.common_color_3'))
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
            }
            .width('100%')
            .alignItems(VerticalAlign.Center)
            .padding({ left: 15, right: 15, top: 15, bottom: 15 })

            Divider()
              .color($r('app.color.common_color_5'))
              .strokeWidth(0.5)
              .width('100%')

            Row() {
              Image($r('app.media.mobile_campus_timetable_course_highestscore'))
                .width(23)
                .height(23)
              Text('历史最高分')
                .fontSize(16)
                .fontColor($r('app.color.common_color_1'))
                .margin({ left: 6 })
                .layoutWeight(1)
              Text(this.course.highestScore)
                .fontSize(17)
                .fontColor($r('app.color.common_color_3'))
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
            }
            .width('100%')
            .alignItems(VerticalAlign.Center)
            .padding({ left: 15, right: 15, top: 15, bottom: 15 })

            Divider()
              .color($r('app.color.common_color_5'))
              .strokeWidth(0.5)
              .width('100%')

            // 最高分保持者行（右箭头）
            Row() {
              Image($r('app.media.mobile_campus_timetable_course_highestscorepeople'))
                .width(23)
                .height(23)
              Text('最高分保持者')
                .fontSize(16)
                .fontColor($r('app.color.common_color_1'))
                .margin({ left: 6 })
              Text(this.course.highestScorePeople)
                .fontSize(16)
                .fontColor($r('app.color.common_color_3'))
                .margin({ left: 10 })
                .layoutWeight(1)
                .textAlign(TextAlign.End)
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
              Image($r('app.media.arrow_right2'))
                .width(23)
                .height(23)
                .margin({ left: 4 })
            }
            .width('100%')
            .alignItems(VerticalAlign.Center)
            .padding({ left: 15, right: 5, top: 15, bottom: 15 })
          }
          .width('100%')
          .backgroundColor($r('app.color.white'))

          // divider_horizontal_grey_normal
          Divider()
            .color($r('app.color.common_color_5'))
            .strokeWidth(0.5)
            .width('100%')

          // 授课恩师行
          Row() {
            Image($r('app.media.mobile_campus_timetable_course_teacher'))
              .width(23)
              .height(23)
            Text('授课恩师')
              .fontSize(16)
              .fontColor($r('app.color.common_color_1'))
              .margin({ left: 6 })
              .layoutWeight(1)
            Text(this.course.teacher)
              .fontSize(16)
              .fontColor($r('app.color.common_color_3'))
              .margin({ left: 10 })
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
          }
          .width('100%')
          .alignItems(VerticalAlign.Center)
          .padding(15)
          .backgroundColor($r('app.color.white'))

          // divider_horizontal_grey_normal
          Divider()
            .color($r('app.color.common_color_5'))
            .strokeWidth(0.5)
            .width('100%')

          // 上课学生行（右箭头）
          Row() {
            Image($r('app.media.mobile_campus_timetable_course_biconditional_gate_disciple'))
              .width(23)
              .height(23)
            Text('上课学生')
              .fontSize(16)
              .fontColor($r('app.color.common_color_1'))
              .margin({ left: 6 })
            Text(this.course.classStudent)
              .fontSize(16)
              .fontColor($r('app.color.common_color_3'))
              .margin({ left: 10 })
              .layoutWeight(1)
              .textAlign(TextAlign.End)
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
            Image($r('app.media.arrow_right2'))
              .width(23)
              .height(23)
              .margin({ left: 4 })
          }
          .width('100%')
          .alignItems(VerticalAlign.Center)
          .padding({ left: 15, right: 5, top: 15, bottom: 15 })
          .backgroundColor($r('app.color.white'))

          Divider()
            .color($r('app.color.common_color_5'))
            .strokeWidth(0.5)
            .width('100%')

          // 男女生比例块（mobile_campus_timetable_include_item）
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
            .padding({ left: 4, right: 8 })

            Column() {
              Row() {
                Stack() {
                  Image($r('app.media.mobile_campus_timetable_course_boy_bg'))
                  Text(`${this.course.boyPercent}%`)
                    .fontSize(14)
                    .fontColor($r('app.color.white'))
                    .padding({ left: 4, top: 4, right: 4, bottom: 6 })
                }
                .align(Alignment.Center)

                Blank()

                Stack() {
                  Image($r('app.media.mobile_campus_timetable_course_girl_bg'))
                  Text(`${100 - this.course.boyPercent}%`)
                    .fontSize(14)
                    .fontColor($r('app.color.white'))
                    .padding({ left: 4, top: 4, right: 4, bottom: 6 })
                }
                .align(Alignment.Center)
              }
              .width('100%')
              .alignItems(VerticalAlign.Center)
              .margin({ top: 6 })

              Row() {
                Row()
                  .width('50%')
                  .height(7)
                  .borderRadius({ topLeft: 4, bottomLeft: 4 })
                  .backgroundColor($r('app.color.timetable_per_blue'))
                Row()
                  .width(6)
                  .height(13)
                  .backgroundColor($r('app.color.ybg_orange'))
                Row()
                  .width('50%')
                  .height(7)
                  .borderRadius({ topRight: 4, bottomRight: 4 })
                  .backgroundColor($r('app.color.timetable_per_red'))
              }
              .width('100%')
              .alignItems(VerticalAlign.Center)
              .margin({ top: 2 })
            }
            .layoutWeight(1)
            .alignItems(HorizontalAlign.Center)

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
            .padding({ left: 8, right: 4 })
          }
          .width('100%')
          .alignItems(VerticalAlign.Center)
          .padding(19)
          .backgroundColor($r('app.color.white'))

          // divider_horizontal_grey_normal
          Divider()
            .color($r('app.color.common_color_5'))
            .strokeWidth(0.5)
            .width('100%')
        }
        .width('100%')
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
