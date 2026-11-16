import { router } from '@kit.ArkUI';
import { webview } from '@kit.ArkWeb';
import { TitleBar } from '../components/TitleBar';

/**
 * 通用 WebView 页：通过路由参数传入 url 与 title。
 */
@Entry
@Component
struct WebViewPage {
  @State pageTitle: string = '隐私政策';
  @State pageUrl: string = 'https://www.sdgu.edu.cn/';
  controller: webview.WebviewController = new webview.WebviewController();

  aboutToAppear(): void {
    const params: object = router.getParams();
    if (params !== null && params !== undefined) {
      const record = params as Record<string, Object>;
      const urlValue: Object = record['url'];
      if (typeof urlValue === 'string') {
        this.pageUrl = urlValue as string;
      }
      const titleValue: Object = record['title'];
      if (typeof titleValue === 'string') {
        this.pageTitle = titleValue as string;
      }
    }
  }

  build() {
    Column() {
      TitleBar({ title: this.pageTitle, showBack: true })
      Web({ src: this.pageUrl, controller: this.controller })
        .domStorageAccess(true)
        .layoutWeight(1)
        .width('100%')
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.sdmu_card_bg'))
  }
}
