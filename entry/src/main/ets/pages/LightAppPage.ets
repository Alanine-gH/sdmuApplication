import { router } from '@kit.ArkUI';
import { webview } from '@kit.ArkWeb';

/**
 * 轻应用页 — 1:1 复刻 mobile_campus_activity_light.xml / mobile_campus_activity_x5_light.xml：
 * toolbar_normal + 进度条3dip(mobile_campus_progress) + WebView 填充
 * x5 变体：右下角字号切换按钮 50dip 边距20
 */
@Entry
@Component
struct LightAppPage {
  private webController: webview.WebviewController = new webview.WebviewController();
  @State loadProgress: number = 0;

  build() {
    Column() {
      Row() {
        Text('＜')
          .fontSize(16)
          .fontColor($r('app.color.common_color_1'))
          .width(40)
          .height('100%')
          .textAlign(TextAlign.Center)
          .margin({ left: 15 })
          .onClick(() => {
            router.back();
          })
        Text('轻应用')
          .fontSize(16)
          .fontColor($r('app.color.common_color_1'))
          .layoutWeight(1)
          .textAlign(TextAlign.Center)
          .maxLines(1)
        Blank()
          .width(40)
      }
      .width('100%')
      .height(44)
      .alignItems(VerticalAlign.Center)
      .backgroundColor($r('app.color.main_bg'))

      Stack() {
        Column() {
          Progress({ value: this.loadProgress, total: 100, type: ProgressType.Linear })
            .width('100%')
            .height(3)
            .color($r('app.color.sdmu_primary'))
            .backgroundColor($r('app.color.common_color_5'))

          Web({ src: 'https://www.sdwu.edu.cn/', controller: this.webController })
            .width('100%')
            .layoutWeight(1)
            .onProgressChange((event: OnProgressChangeEvent) => {
              this.loadProgress = event.newProgress;
            })
        }
        .width('100%')
        .height('100%')
        .alignItems(HorizontalAlign.Start)

        Image($r('app.media.icon_text_size_switch'))
          .width(50)
          .height(50)
          .objectFit(ImageFit.Contain)
          .margin({ right: 20, bottom: 20 })
          .alignSelf(ItemAlign.End)
      }
      .width('100%')
      .layoutWeight(1)
      .backgroundColor($r('app.color.main_bg'))
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.main_bg'))
  }
}
