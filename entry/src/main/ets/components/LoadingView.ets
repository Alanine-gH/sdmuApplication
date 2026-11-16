/**
 * 加载中提示视图。
 */
@Component
export struct LoadingView {
  @Prop tipText: string = '加载中...';

  build() {
    Column({ space: 12 }) {
      LoadingProgress()
        .width(40)
        .height(40)
        .color($r('app.color.sdmu_primary'))
      Text(this.tipText)
        .fontSize(14)
        .fontColor($r('app.color.sdmu_text_hint'))
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }
}
