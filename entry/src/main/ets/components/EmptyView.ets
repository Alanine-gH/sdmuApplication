/**
 * 空状态提示视图。
 */
@Component
export struct EmptyView {
  @Prop tipText: string = '暂无数据';

  build() {
    Column({ space: 12 }) {
      Text('ⓘ')
        .fontSize(48)
        .fontColor($r('app.color.sdmu_text_hint'))
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
