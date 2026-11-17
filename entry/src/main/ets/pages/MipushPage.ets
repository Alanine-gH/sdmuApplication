/**
 * 推送透传页 — 1:1 复刻 activity_mipush.xml：
 * - 纯透传中转页：LinearLayout 竖向、背景 #00000000（全透明）、fill_parent；
 * - 源布局无任何可见 UI 元素，收到的透传消息仅在逻辑层处理分发。
 */
@Entry
@Component
struct MipushPage {
  build() {
    Column()
      .width('100%')
      .height('100%')
      .backgroundColor(Color.Transparent)
  }
}
