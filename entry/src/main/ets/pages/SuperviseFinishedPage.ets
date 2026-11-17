import { router } from '@kit.ArkUI';
import { TitleBar } from '../components/TitleBar';

/**
 * 已督导 — 1:1 复刻 mobile_campus_supervise_activity_supervise_finished.xml
 * LectureDetailView + LectureEvaluateEditView（layout_evaluate_editable.xml：
 * 教学评价标题 / 应到实到 / 星级（touchable=false）/ 评价内容 / 删除听课红描边按钮）
 */
class SuperviseFinishedStar {
  index: number;
  lit: boolean;

  constructor(index: number, lit: boolean) {
    this.index = index;
    this.lit = lit;
  }
}

@Entry
@Component
struct SuperviseFinishedPage {
  @State className: string = '毛泽东思想和中国特色社会主义理论体系概论';
  @State teacherName: string = '陈静';
  @State teacherNumber: string = '5003187';
  @State academyName: string = '马克思主义学院';
  @State weekText: string = '第11周';
  @State sectionText: string = '8-9节';
  @State locationText: string = '博学楼C102';
  @State attendanceExpect: string = '45';
  @State attendanceActual: string = '43';
  @State evaluateContent: string = '课堂气氛活跃，讲授内容充实，理论联系实际，学生参与度高。';
  @State stars: SuperviseFinishedStar[] = [
    new SuperviseFinishedStar(1, true),
    new SuperviseFinishedStar(2, true),
    new SuperviseFinishedStar(3, false),
    new SuperviseFinishedStar(4, false),
    new SuperviseFinishedStar(5, false)
  ];

  private deleteListen(): void {
    router.back();
  }

  build() {
    Column() {
      TitleBar({ title: '已督导', showBack: true })

      Scroll() {
        Column() {
          // 课程信息卡（LectureDetailView）
          Column() {
            Text(this.className)
              .fontSize(16)
              .fontColor($r('app.color.mobile_campus_primary_color_default'))
              .margin({ bottom: 22 })

            Row() {
              Row() {
                Text('任课教师')
                  .fontSize(14)
                  .fontColor($r('app.color.common_color_3'))
                Text(this.teacherName)
                  .fontSize(14)
                  .fontColor($r('app.color.common_color_1'))
              }
              .layoutWeight(1)

              Row() {
                Text('工号')
                  .fontSize(14)
                  .fontColor($r('app.color.common_color_3'))
                Text(this.teacherNumber)
                  .fontSize(14)
                  .fontColor($r('app.color.common_color_1'))
              }
              .layoutWeight(1)
            }
            .width('100%')

            Row() {
              Text('开课院系')
                .fontSize(14)
                .fontColor($r('app.color.common_color_3'))
              Text(this.academyName)
                .fontSize(14)
                .fontColor($r('app.color.common_color_1'))
            }
            .width('100%')
            .margin({ top: 12 })

            Divider()
              .color($r('app.color.common_color_5'))
              .strokeWidth(0.5)
              .width('100%')
              .margin({ top: 17, bottom: 17 })

            Row() {
              Text('开课周数')
                .fontSize(14)
                .fontColor($r('app.color.common_color_3'))
              Text(this.weekText)
                .fontSize(14)
                .fontColor($r('app.color.common_color_1'))
            }
            .width('100%')

            Row() {
              Text('上课节数')
                .fontSize(14)
                .fontColor($r('app.color.common_color_3'))
              Text(this.sectionText)
                .fontSize(14)
                .fontColor($r('app.color.common_color_1'))
            }
            .width('100%')
            .margin({ top: 12 })

            Row() {
              Text('上课地点')
                .fontSize(14)
                .fontColor($r('app.color.common_color_3'))
              Text(this.locationText)
                .fontSize(14)
                .fontColor($r('app.color.common_color_1'))
            }
            .width('100%')
            .margin({ top: 12 })
          }
          .width('100%')
          .padding({ left: 12, right: 12, top: 20, bottom: 20 })
          .backgroundColor($r('app.color.white'))

          // 教学评价卡（LectureEvaluateEditView）：白底 padding H12 B20，marginTop 12
          Column() {
            Text('教学评价')
              .fontSize(14)
              .fontColor($r('app.color.common_color_3'))
              .padding({ top: 12, bottom: 12 })

            Divider()
              .color($r('app.color.common_color_5'))
              .strokeWidth(0.5)
              .width('100%')

            Row() {
              Row() {
                Text('应到人数')
                  .fontSize(14)
                  .fontColor($r('app.color.common_color_1'))
                Text(this.attendanceExpect)
                  .fontSize(14)
                  .fontColor($r('app.color.common_color_1'))
                  .textAlign(TextAlign.Center)
                  .width(68)
                  .height(36)
                  .padding({ top: 8, bottom: 8 })
                  .backgroundColor($r('app.color.mobile_campus_supervise_evaluate_edittext_solid'))
                  .borderRadius(4)
                  .border({ width: 0.5, color: $r('app.color.mobile_campus_supervise_evaluate_edittext_stroke') })
              }
              .layoutWeight(1)

              Row() {
                Text('实到人数')
                  .fontSize(14)
                  .fontColor($r('app.color.common_color_1'))
                Text(this.attendanceActual)
                  .fontSize(14)
                  .fontColor($r('app.color.common_color_1'))
                  .textAlign(TextAlign.Center)
                  .width(68)
                  .height(36)
                  .padding({ top: 8, bottom: 8 })
                  .backgroundColor($r('app.color.mobile_campus_supervise_evaluate_edittext_solid'))
                  .borderRadius(4)
                  .border({ width: 0.5, color: $r('app.color.mobile_campus_supervise_evaluate_edittext_stroke') })
              }
              .layoutWeight(1)
            }
            .width('100%')
            .margin({ top: 24, bottom: 21 })
            .alignItems(VerticalAlign.Center)

            Divider()
              .color($r('app.color.common_color_5'))
              .strokeWidth(0.5)
              .width('100%')

            // BaseRatingBar：touchable=false 只读星级
            Row({ space: 4 }) {
              ForEach(this.stars, (star: SuperviseFinishedStar) => {
                Image(star.lit ? $r('app.media.mobile_campus_supervise_star_light') : $r('app.media.mobile_campus_supervise_star_grey'))
                  .width(10)
                  .height(10)
              }, (star: SuperviseFinishedStar) => star.index.toString())
            }
            .margin({ top: 15, bottom: 15 })

            TextArea({ text: this.evaluateContent, placeholder: '本次课程整体效果如何呢？' })
              .fontSize(14)
              .fontColor($r('app.color.common_color_1'))
              .placeholderColor($r('app.color.edit_hint_color'))
              .placeholderFont({ size: 14 })
              .enabled(false)
              .backgroundColor($r('app.color.mobile_campus_supervise_evaluate_edittext_solid'))
              .borderRadius(4)
              .border({ width: 0.5, color: $r('app.color.mobile_campus_supervise_evaluate_edittext_stroke') })
              .padding(7)
              .height(120)
              .width('100%')
              .margin({ top: 15 })

            // 删除听课：红描边按钮
            Text('删除听课')
              .fontSize(14)
              .fontColor($r('app.color.mobile_campus_supervise_edit_textcolor'))
              .textAlign(TextAlign.Center)
              .width('100%')
              .padding({ top: 10, bottom: 10 })
              .margin({ left: 9, right: 9, top: 21 })
              .borderRadius(4)
              .border({ width: 0.5, color: $r('app.color.mobile_campus_supervise_edit_textcolor') })
              .onClick(() => {
                this.deleteListen();
              })
          }
          .width('100%')
          .padding({ left: 12, right: 12, bottom: 20 })
          .backgroundColor($r('app.color.white'))
          .margin({ top: 12 })
        }
        .width('100%')
      }
      .layoutWeight(1)
      .width('100%')
      .scrollBar(BarState.Off)
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.common_color_6'))
  }
}
