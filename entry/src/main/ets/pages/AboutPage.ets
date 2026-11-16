import { TitleBar } from '../components/TitleBar';

/**
 * 关于我们页 — 1:1 复刻 mobile_campus_about_us.xml
 * 结构：
 *   - toolbar_normal
 *   - RoundedImageView：icon 120x120dip、marginTop 140dip、
 *     圆角 28dip、边框 #E7E7E7 1dip
 *   - 应用名 17sp 黑 marginTop 24dip
 *   - 版本 14sp #999999(explainColor) marginTop 4dip
 */
@Entry
@Component
struct AboutPage {
  build() {
    Column() {
      TitleBar({ title: '关于我们', showBack: true })

      Column() {
        // rivImage：120vp 圆角 28vp 边框 #E7E7E7 1vp
        Image($r('app.media.app_icon'))
          .width(120)
          .height(120)
          .borderRadius(28)
          .border({ width: 1, color: $r('app.color.common_color_5') })
          .margin({ top: 140 })

        // tvAppName：17fp 黑
        Text($r('app.string.app_name'))
          .fontSize(17)
          .fontColor($r('app.color.black'))
          .margin({ top: 24 })

        // tvAppVersion：14fp #999999
        Text('V1.0.0')
          .fontSize(14)
          .fontColor($r('app.color.explain_color'))
          .margin({ top: 4 })
      }
      .width('100%')
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Center)
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.white'))
  }
}
