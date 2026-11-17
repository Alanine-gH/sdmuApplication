import { TitleBar } from '../components/TitleBar';
import { webview } from '@kit.ArkWeb';

/**
 * WebView 测试壳页 — 1:1 复刻 mobile_campus_activity_test_webview.xml
 * 结构：LinearLayout(vertical, fitsSystemWindows) + toolbar_normal + WebView(fill)
 * 内置数据：默认加载学校官网地址。
 */
@Entry
@Component
struct TestWebViewPage {
  @State pageUrl: string = 'https://www.sdmu.edu.cn/';
  controller: webview.WebviewController = new webview.WebviewController();

  build() {
    Column() {
      TitleBar({ title: 'WebView测试', showBack: true })

      Web({ src: this.pageUrl, controller: this.controller })
        .domStorageAccess(true)
        .javaScriptAccess(true)
        .width('100%')
        .height('100%')
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.main_bg'))
  }
}
