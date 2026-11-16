import { router } from '@kit.ArkUI';

/**
 * 通用标题栏：左侧可选返回按钮 + 居中标题，底部细分隔线。
 */
@Component
export struct TitleBar {
  @Prop title: string = '';
  @Prop showBack: boolean = true;

  build() {
    Row() {
      if (this.showBack) {
        Text('＜')
          .fontSize(22)
          .fontColor($r('app.color.sdmu_text_primary'))
          .width(40)
          .height('100%')
          .textAlign(TextAlign.Center)
          .onClick(() => {
            router.back();
          })
      }
      Text(this.title)
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.sdmu_text_primary'))
        .layoutWeight(1)
        .textAlign(TextAlign.Center)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
      if (this.showBack) {
        Blank().width(40)
      } else {
        Blank().width(16)
      }
    }
    .width('100%')
    .height(50)
    .backgroundColor($r('app.color.sdmu_card_bg'))
    .border({ width: { bottom: 1 }, color: $r('app.color.sdmu_divider') })
  }
}
