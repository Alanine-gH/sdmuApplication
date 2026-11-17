import { router } from '@kit.ArkUI';

/**
 * 通用标题栏 — 1:1 复刻 toolbar_normal.xml
 * 结构：toolBarView 状态栏占位(paddingTop安全区) + LinearLayout 45vp 高（白底 main_bg）
 *   - Toolbar 44vp：左侧返回、中央标题 17fp(px_to_sp_34/2) common_color_1 居中 maxLength 18
 *   - divider_horizontal_grey_thin 细分隔线 0.5vp
 * 安全区：expandSafeArea顶部跟随，标题不被状态栏遮挡
 */
@Component
export struct TitleBar {
  @Prop title: string = '';
  @Prop showBack: boolean = true;

  build() {
    Column() {
      Row() {
        if (this.showBack) {
          Text('＜')
            .fontSize(17)
            .fontColor($r('app.color.common_color_1'))
            .width(40)
            .height('100%')
            .textAlign(TextAlign.Center)
            .margin({ left: 15 })
            .onClick(() => {
              router.back();
            })
        }
        Text(this.title)
          .fontSize(17)
          .fontColor($r('app.color.common_color_1'))
          .layoutWeight(1)
          .textAlign(TextAlign.Center)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        if (this.showBack) {
          Blank()
            .width(40)
        } else {
          Blank()
            .width(16)
        }
      }
      .width('100%')
      .height(44)
      .alignItems(VerticalAlign.Center)
      .backgroundColor($r('app.color.main_bg'))

      Divider()
        .color($r('app.color.common_color_5'))
        .strokeWidth(0.5)
        .width('100%')
    }
    .width('100%')
    .height(45)
    .backgroundColor($r('app.color.main_bg'))
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP])
  }
}


