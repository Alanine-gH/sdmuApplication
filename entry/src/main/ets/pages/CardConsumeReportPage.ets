import { webview } from '@kit.ArkWeb';
import { BusinessError } from '@kit.BasicServicesKit';
import { TitleBar } from '../components/TitleBar';
import { HttpClient } from '../network/HttpClient';
import { LoginSession } from '../network/LoginSession';
import { ApiService } from '../network/ApiService';
import { Api } from '../network/Api';
import { Constants } from '../data/Constants';

/**
 * 一卡通消费报表页 — 1:1 翻译 OnecardReportActvity.java（manifest L520 action sdgy_onecardReport）。
 *
 * 【源码】student_report_layout_main.xml：TitleBar + MultiStateView + report_web WebView。
 *   T1()：标题 = AppInfo.YYMC 或默认 "消费排行"（入口 StudentReportHomePage 无 AppInfo → 默认）。
 *   OPENAPPLICATION=="1" 才有"关闭"按钮（宫格入口无 AppInfo，不触发）。
 * 【数据】f1()：k.b() 设置 WebView（JS/domStorage/zoom 开），SetJavascriptInterface()，
 *   this.k.a(this.m.g("rank/onecardReport"), webView, null)（MyWebViewSetting.a，map=null 无 data 头）：
 *     strE = randomBase64AESKey（LoginSession.aesKey，空 → return 不加载）；
 *     Access-Token = AES(4字段AT, strE)；Unique-Code = onlyCode；AppType="ydxy"。
 *   URL = ReportFactory.g("rank/onecardReport") = d.d() + /mobileapi_ydxy/api/rank/onecardReport。
 *   2026-11-18 探针实测：H5 HTTP 200 title="消费排行"（真实页面可加载）。
 * 【JS 桥】ybginterface.praise(str,str2)/cancelPraise(str,str2) → f.c.a.c/b：
 *   POST rank/onecardReport/praise|cancelPraise {broder:str, time:str2}（实测 code=0）。
 * 【返回】onBackPressed：webView.canGoBack → goBack 优先。
 */
interface HttpHeader {
  headerKey: string;
  headerValue: string;
}

/** ybginterface JS 桥（OnecardReportActvity.3 逐行等价；源码 run 内仅发写请求无 UI 回写） */
class OneCardJsBridge {
  cancelPraise(str: string, time: string): void {
    ApiService.oneCardReportPraise(true, str, time)
      .catch((error: BusinessError) => ApiService.logError('onecard cancelPraise fail: ' + error.message));
  }

  praise(str: string, time: string): void {
    ApiService.oneCardReportPraise(false, str, time)
      .catch((error: BusinessError) => ApiService.logError('onecard praise fail: ' + error.message));
  }
}

@Entry
@Component
struct CardConsumeReportPage {
  private webController: webview.WebviewController = new webview.WebviewController();
  private jsBridge: OneCardJsBridge = new OneCardJsBridge();
  @State loadProgress: number = 0;
  @State pageTitle: string = '消费排行';
  @State netError: boolean = false;
  private targetUrl: string = '';
  private headers: HttpHeader[] = [];

  aboutToAppear(): void {
    this.targetUrl = Constants.SOCKET_HOST + Api.RANK_ONECARD_REPORT;
    this.headers = [];
    let at: string = '';
    try {
      at = HttpClient.buildWebEncryptedAccessToken(); // 4字段明文 AT→AES（StudyReport 同款免登链）
    } catch (error) {
      const be = error as BusinessError;
      ApiService.logError('CardConsumeReportPage enc AT fail: ' + be.message);
    }
    if (at !== '') {
      this.headers.push({ headerKey: 'Access-Token', headerValue: at });
    }
    this.headers.push({ headerKey: 'Unique-Code',
      headerValue: LoginSession.onlyCode === '' ? Constants.UNIQUE_CODE : LoginSession.onlyCode });
    this.headers.push({ headerKey: 'AppType', headerValue: 'ydxy' });
    // 源码 a.a.a："".equals(strE) → return（AES key 缺失不加载，落 NETWORK_ERROR 错误态）
    if (at === '') {
      this.netError = true;
      this.targetUrl = '';
    }
  }

  build() {
    Column() {
      TitleBar({ title: this.pageTitle, showBack: true })
      Stack() {
        Column() {
          Progress({ value: this.loadProgress, total: 100, type: ProgressType.Linear })
            .width('100%').height(3)
            .color($r('app.color.sdmu_primary'))
            .backgroundColor($r('app.color.common_color_5'))
          Web({ src: '', controller: this.webController })
            .width('100%').layoutWeight(1)
            .javaScriptAccess(true)
            .domStorageAccess(true)
            .zoomAccess(true)
            .javaScriptProxy({
              object: this.jsBridge,
              name: 'ybginterface',
              methodList: ['praise', 'cancelPraise'],
              controller: this.webController
            })
            .onControllerAttached(() => {
              if (this.targetUrl !== '') {
                this.webController.loadUrl(this.targetUrl, this.headers);
              }
            })
            .onProgressChange((event: OnProgressChangeEvent) => {
              this.loadProgress = event.newProgress;
            })
            .onTitleReceive((event: OnTitleReceiveEvent) => {
              // 源码 a 类 onReceivedTitle：TextUtils.isEmpty 不覆盖
              if (event.title !== '') {
                this.pageTitle = event.title;
              }
            })
            .onErrorReceive((event: OnErrorReceiveEvent) => {
              ApiService.logError('CardConsumeReportPage web err=' + event.error.getErrorCode() +
                ' url=' + event.request.getRequestUrl());
            })
        }
        .width('100%').height('100%').alignItems(HorizontalAlign.Start)
        if (this.netError) {
          Column() {
            Image($r('app.media.mobile_campus_page_internet'))
              .width(120).objectFit(ImageFit.Contain)
            Text('网络好像有点问题，过一会再试吧')
              .fontSize(14).fontColor($r('app.color.sdmu_text_hint')).margin({ top: 16 })
          }
          .width('100%').height('100%').justifyContent(FlexAlign.Center)
          .backgroundColor($r('app.color.main_bg'))
        }
      }
      .width('100%').layoutWeight(1)
    }
    .width('100%').height('100%')
    .backgroundColor($r('app.color.main_bg'))
  }

  /** 源码 onBackPressed：canGoBack → goBack 优先 */
  onBackPress(): boolean {
    try {
      if (this.webController.accessBackward()) {
        this.webController.backward();
        return true;
      }
    } catch (error) {
      const be = error as BusinessError;
      ApiService.logError('CardConsumeReportPage back fail: ' + be.message);
    }
    return false;
  }
}
