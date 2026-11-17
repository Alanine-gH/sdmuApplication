import { router } from '@kit.ArkUI';
import { TitleBar } from '../components/TitleBar';

/**
 * 评课表单 — 1:1 复刻 mobile_campus_supervise_activity_supervise_evaluate.xml
 * 内容卡复刻 layout_evaluate_show.xml / layout_evaluate_editable.xml 结构
 * 提交按钮：shape_evaluate #1B68B7（enabled），文字 selector_filter（enabled 白色）
 */
class SuperviseStar {
  index: number;
  lit: boolean;

  constructor(index: number, lit: boolean) {
    this.index = index;
    this.lit = lit;
  }
}

@Entry
@Component
struct SuperviseEvaluatePage {
  @State attendanceExpect: string = '';
  @State attendanceActual: string = '';
  @State evaluateContent: string = '';
  @State starRating: number = 0;
  @State stars: SuperviseStar[] = [
    new SuperviseStar(1, false),
    new SuperviseStar(2, false),
    new SuperviseStar(3, false),
    new SuperviseStar(4, false),
    new SuperviseStar(5, false)
  ];

  private refreshStars(rating: number): void {
    this.starRating = rating;
    this.stars = this.stars.map((star: SuperviseStar): SuperviseStar => {
      return new SuperviseStar(star.index, star.index <= rating);
    });
  }

  private submitEvaluate(): void {
    router.back();
  }

  build() {
    Column() {
      TitleBar({ title: '听课评价', showBack: true })

      // 白色内容卡：marginTop 12，padding L/R 12，bottom 18
      Column() {
        // 应到/实到人数两列（TextStyle5：宽 68vp，padding V8，编辑框底 #F8F8F9 描边 #DFE4EA 圆角 4）
        Row() {
          Row() {
            Text('应到人数')
              .fontSize(14)
              .fontColor($r('app.color.common_color_1'))
            TextInput({ text: this.attendanceExpect, placeholder: '' })
              .fontSize(14)
              .fontColor($r('app.color.common_color_1'))
              .maxLength(3)
              .type(InputType.Number)
              .textAlign(TextAlign.Center)
              .width(68)
              .height(36)
              .padding({ top: 8, bottom: 8 })
              .backgroundColor($r('app.color.mobile_campus_supervise_evaluate_edittext_solid'))
              .borderRadius(4)
              .border({ width: 0.5, color: $r('app.color.mobile_campus_supervise_evaluate_edittext_stroke') })
              .onChange((value: string) => {
                this.attendanceExpect = value;
              })
          }
          .layoutWeight(1)

          Row() {
            Text('实到人数')
              .fontSize(14)
              .fontColor($r('app.color.common_color_1'))
            TextInput({ text: this.attendanceActual, placeholder: '' })
              .fontSize(14)
              .fontColor($r('app.color.common_color_1'))
              .maxLength(3)
              .type(InputType.Number)
              .textAlign(TextAlign.Center)
              .width(68)
              .height(36)
              .padding({ top: 8, bottom: 8 })
              .backgroundColor($r('app.color.mobile_campus_supervise_evaluate_edittext_solid'))
              .borderRadius(4)
              .border({ width: 0.5, color: $r('app.color.mobile_campus_supervise_evaluate_edittext_stroke') })
              .onChange((value: string) => {
                this.attendanceActual = value;
              })
          }
          .layoutWeight(1)
        }
        .width('100%')
        .margin({ top: 12, bottom: 12 })
        .alignItems(VerticalAlign.Center)

        Divider()
          .color($r('app.color.common_color_5'))
          .strokeWidth(0.5)
          .width('100%')

        Text('课程评价')
          .fontSize(17)
          .fontColor($r('app.color.common_color_1'))
          .margin({ top: 24 })

        // BaseRatingBar：numStars 5，starSize 20px→10vp，starPadding 8px→4vp
        Row({ space: 4 }) {
          ForEach(this.stars, (star: SuperviseStar) => {
            Image(star.lit ? $r('app.media.mobile_campus_supervise_star_light') : $r('app.media.mobile_campus_supervise_star_grey'))
              .width(10)
              .height(10)
              .onClick(() => {
                this.refreshStars(star.index);
              })
          }, (star: SuperviseStar) => star.index.toString())
        }
        .margin({ top: 21, bottom: 17 })

        TextArea({ text: this.evaluateContent, placeholder: '本次课程整体效果如何呢？' })
          .fontSize(14)
          .fontColor($r('app.color.common_color_1'))
          .placeholderColor($r('app.color.edit_hint_color'))
          .placeholderFont({ size: 14 })
          .backgroundColor($r('app.color.mobile_campus_supervise_evaluate_edittext_solid'))
          .borderRadius(4)
          .border({ width: 0.5, color: $r('app.color.mobile_campus_supervise_evaluate_edittext_stroke') })
          .padding(7)
          .height(120)
          .width('100%')
          .margin({ top: 15 })
          .onChange((value: string) => {
            this.evaluateContent = value;
          })
      }
      .width('100%')
      .backgroundColor($r('app.color.white'))
      .padding({ left: 12, right: 12, bottom: 18 })
      .margin({ top: 12 })

      Blank()
        .layoutWeight(1)

      // 提交评价：shape_evaluate 纯色 #1B68B7 无圆角，文字白色 17fp，padding V10
      Text('提交评价')
        .fontSize(17)
        .fontColor(Color.White)
        .textAlign(TextAlign.Center)
        .width('100%')
        .padding({ top: 10, bottom: 10 })
        .backgroundColor($r('app.color.mobile_campus_primary_color_default'))
        .onClick(() => {
          this.submitEvaluate();
        })
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.common_color_6'))
  }
}
