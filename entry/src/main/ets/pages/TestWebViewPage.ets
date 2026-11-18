import { TitleBar } from '../components/TitleBar';
import { webview } from '@kit.ArkWeb';

/**
 * WebView 测试页 — 源码级翻译（TestWebviewActivity.java 逐行 → ArkTS，[W25 misc-b]）：
 *
 * 【布局】mobile_campus_activity_test_webview.xml：toolbar_normal（无标题，H0()=null）+ mWebView fill
 * 【加载】f1() 固定 loadUrl("http://www.360banke.com/xiaotu/index.html?libid=shutu")（开发测试页，
 *   书图插件测试源；无路由入参 y() 空实现）
 * 【WebView 设置】JavaScript 开启/domStorage/宽视口/mixedContent 允许/cacheMode LOAD_NO_CACHE(2)/
 *   定位开启/自动播放/单列布局/TextZoom 100/网络图片放行——ArkWeb 等价：javaScriptAccess/
 *   domStorageAccess/zoomAccess/forceDarkAccess 等默认开启，cacheMode 等价 .cacheMode
 */
@Entry
@Component
struct TestWebViewPage {
  /** 源码固定测试地址（360banke 书图测试页） */
  @State pageUrl: string = 'http://www.360banke.com/xiaotu/index.html?libid=shutu';
  controller: webview.WebviewController = new webview.WebviewController();

  build() {
    Column() {
      // 源码 toolbar 无标题
      TitleBar({ title: '', showBack: true })

      Web({ src: this.pageUrl, controller: this.controller })
        .domStorageAccess(true)
        .javaScriptAccess(true)
        .zoomAccess(true)
        .fileAccess(true)
        .onControllerAttached(() => {
        })
        .width('100%')
        .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.main_bg'))
  }
}
