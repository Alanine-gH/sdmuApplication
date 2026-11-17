import { TitleBar } from '../components/TitleBar';

/**
 * 校圈入口页 — 1:1 复刻 social_main_activity.xml（SocialMainActivity）
 * 结构：LinearLayout(vertical) + toolbar_normal + FrameLayout(fl_container)
 * 容器内容为校圈社区空态（social_no_pager.xml）：
 *   - 社区空态插图 social_no_page.png、左右 margin 25vp(px50÷2)
 *   - 提示文案 12fp(px24÷2) common_color_4 居中、padding 30vp(px60÷2)
 * 内置数据：空态提示"说点新鲜事儿分享给同学们吧~"。
 */
@Entry
@Component
struct SchoolCircleEntryPage {
  @State emptyTips: string = '说点新鲜事儿分享给同学们吧~';

  build() {
    Column() {
      TitleBar({ title: '校圈', showBack: true })

      Stack() {
        // social_no_pager 空态视图
        Column() {
          Image($r('app.media.social_no_page'))
            .margin({ left: 25, right: 25 })

          Text(this.emptyTips)
            .fontSize(12)
            .fontColor($r('app.color.common_color_4'))
            .textAlign(TextAlign.Center)
            .padding(30)
        }
        .width('100%')
        .alignItems(HorizontalAlign.Center)
      }
      .width('100%')
      .height('100%')
      .alignContent(Alignment.Top)
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.main_bg'))
  }
}
