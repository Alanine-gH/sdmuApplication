import { router } from '@kit.ArkUI';

/**
 * 选择学校项 — 1:1 复刻 school_item.xml
 * 结构：Column[ Row(校名+附加信息+右箭头) + 底部分隔线 ]
 */
@Component
export struct ChooseSchoolItem {
  @Prop schoolName: string = '';
  @Prop extraInfo: string = '';

  build() {
    Column() {
      Row() {
        Text(this.schoolName)
          .fontSize(17)
          .fontColor($r('app.color.common_color_1'))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .padding({ top: 15, bottom: 15 })
          .margin({ left: 15, right: 4 })
          .layoutWeight(1)

        Text(this.extraInfo)
          .fontSize(14)
          .fontColor($r('app.color.common_color_4'))
          .margin({ right: 4 })

        Image($r('app.media.arrow_right2'))
          .width(14)
          .height(14)
          .margin({ right: 15 })
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)
      .backgroundColor($r('app.color.white'))
      .onClick(() => {
        router.pushUrl({ url: 'pages/LoginPage' });
      })

      Divider()
        .color($r('app.color.common_color_5'))
        .strokeWidth(0.5)
        .width('100%')
    }
    .width('100%')
  }
}
