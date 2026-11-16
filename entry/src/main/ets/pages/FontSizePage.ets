import { TitleBar } from '../components/TitleBar';

/**
 * 字体大小设置页 — 1:1 复刻 mobile_campus_activity_font_size_setting.xml
 * 结构：
 *   - toolbar_normal
 *   - 中央提示文本"拖动下面的滑块，可设置字体大小"（20px=10fp 黑色 padding 11vp/px22÷2）
 *   - FontResizeView：白底高 140vp、minSize 13dip、maxSize 25dip、totalGrade 5、
 *     standardGrade 2、sliderColor #97000C、sliderRadius 12dip
 * 档位字号（13~25dip 等分 5 档）：13 / 16 / 19 / 22 / 25 fp，默认标准档(第3档)
 */
@Entry
@Component
struct FontSizePage {
  @State gradeIndex: number = 2;
  private fontSizes: number[] = [13, 16, 19, 22, 25];

  build() {
    Column() {
      TitleBar({ title: '字体大小', showBack: true })

      // 中央预览文本
      Column() {
        Text('拖动下面的滑块，可设置字体大小')
          .fontSize(this.fontSizes[this.gradeIndex])
          .fontColor($r('app.color.black'))
          .padding(11)
      }
      .width('100%')
      .layoutWeight(1)
      .justifyContent(FlexAlign.Center)

      // FontResizeView：白底 140vp
      Column() {
        // 档位标尺行
        Row() {
          ForEach(this.fontSizes, (size: number, index: number) => {
            Text(index === this.gradeIndex ? '●' : '○')
              .fontSize(10)
              .fontColor($r('app.color.mobile_campus_primary_color'))
              .layoutWeight(1)
              .textAlign(TextAlign.Center)
          }, (size: number) => 'grade' + size)
        }
        .width('100%')
        .margin({ left: 30, right: 30 })
        .margin({ bottom: 8 })

        // 滑块：min 13dip max 25dip 5档、sliderColor #97000C、radius 12dip
        Slider({ value: 2, min: 0, max: 4, step: 1, style: SliderStyle.OutSet })
          .blockColor($r('app.color.mobile_campus_primary_color'))
          .selectedColor($r('app.color.mobile_campus_primary_color'))
          .trackColor($r('app.color.common_color_5'))
          .blockSize({ width: 24, height: 24 })
          .width('100%')
          .margin({ left: 30, right: 30 })
          .onChange((value: number, mode: SliderChangeMode) => {
            if (mode === SliderChangeMode.End || mode === SliderChangeMode.Click) {
              this.gradeIndex = Math.round(value);
            }
          })
      }
      .width('100%')
      .height(140)
      .backgroundColor($r('app.color.white'))
      .justifyContent(FlexAlign.Center)
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.white'))
  }
}
