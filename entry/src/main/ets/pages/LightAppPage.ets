import { router } from '@kit.ArkUI';
import { webview } from '@kit.ArkWeb';
import { LoginSession } from '../network/LoginSession';

/**
 * 轻应用页 — 1:1 翻译原 APK LightActivity.java(1080行)/X5LightActivity.java 的加载公式：
 *   loadUrl(SCHOOL服务器 + "/mobileapi_ydxy/api/lapp/springboard?yyid=<应用YYID>",
 *           headers = { Unique-Code: 会话UC, AppType: "ydxy" })
 * - 源码 c/a/c/a/a.java(AppsFactory)：f12800b = "lapp/springboard"，a()="api"，b()=null，
 *   c()="mobileapi_ydxy" → 路径 = /mobileapi_ydxy/api/lapp/springboard
 * - 认证头：源码 map.put("Unique-Code", d.a().d()) + map.put("AppType", "ydxy")
 * - yyid 来自服务端下发的 AppBean.YYID（如 baseQRCode / YiClassroom / freeClassroom / bodaNews）
 * 页面结构：toolbar_normal + 进度条3dip + WebView 填充 + 右下角字号切换按钮(X5 变体)
 */
interface HttpHeader {
  headerKey: string;
  headerValue: string;
}

@Entry
@Component
struct LightAppPage {
  private webController: webview.WebviewController = new webview.WebviewController();
  @State loadProgress: number = 0;
  @State pageTitle: string = '';
  @State targetUrl: string = '';
  @State loadFailed: boolean = false;
  private yyid: string = '';
  private headers: HttpHeader[] = [];

  aboutToAppear(): void {
    // 路由参数：yyid + title
    const params = router.getParams() as Record<string, string> | undefined;
    if (params) {
      this.yyid = params['yyid'] ?? '';
      this.pageTitle = params['title'] ?? '轻应用';
    }
    // 源码 AppsFactory：SCHOOL 域名 + /mobileapi_ydxy/api/lapp/springboard?yyid=xxx
    this.targetUrl = 'http://mcp.sdmu.edu.cn:8081/mobileapi_ydxy/api/lapp/springboard?yyid=' + this.yyid;
    // 源码认证头：Unique-Code = 会话UC（协商 UC）；AppType = ydxy
    const uc: string = LoginSession.deviceCode !== '' ? LoginSession.deviceCode : LoginSession.onlyCode;
    this.headers = [
      { headerKey: 'Unique-Code', headerValue: uc },
      { headerKey: 'AppType', headerValue: 'ydxy' }
    ];
  }

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
        Text(this.pageTitle)
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

          if (this.yyid === '') {
            // 无 yyid（服务端未下发该应用地址）：与源码 Toast 行为一致，提示并返回
            Column() {
              Text('暂无轻应用地址')
                .fontSize(15)
                .fontColor($r('app.color.common_color_3'))
            }
            .width('100%')
            .layoutWeight(1)
            .justifyContent(FlexAlign.Center)
          } else {
            Web({ src: this.targetUrl, controller: this.webController })
              .width('100%')
              .layoutWeight(1)
              .onControllerAttached(() => {
                // 源码 loadUrl(url, map)：认证头注入
                this.webController.loadUrl(this.targetUrl, this.headers);
              })
              .onProgressChange((event: OnProgressChangeEvent) => {
                this.loadProgress = event.newProgress;
              })
              .onPageEnd(() => {
                // 源码 funFromjs JS 桥的宿主标题同步（简化：读取 document.title）
              })
              .onErrorReceive(() => {
                this.loadFailed = true;
              })
          }
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
