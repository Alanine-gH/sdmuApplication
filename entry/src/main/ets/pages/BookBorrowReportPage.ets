import { webview } from '@kit.ArkWeb';
import { BusinessError } from '@kit.BasicServicesKit';
import { TitleBar } from '../components/TitleBar';
import { HttpClient } from '../network/HttpClient';
import { LoginSession } from '../network/LoginSession';
import { ApiService } from '../network/ApiService';
import { Api } from '../network/Api';
import { Constants } from '../data/Constants';

/**
 * 图书借阅报表页 — 1:1 翻译 LibraryReportActvity.java（manifest L514 action sdgy_libraryReport）。
 *
 * 【源码】student_report_layout_main.xml：toolbar + MultiStateView + report_web WebView。
 *   T1()：标题 = AppInfo.YYMC 或默认 "借阅排行"（入口无 AppInfo → 默认）；OPENAPPLICATION=="1" 才有"关闭"。
 * 【数据链】f1()：this.h.d()（LibraryReportPresenter.d → LibraryReportModel.d → e.b GET schedule/termInfo）
 *   → j1(TermInfo{xn,xq}) 回调：
 *     - termInfo==null：有网 s.o() → Page.EMPTY_LIBRARY（strings empty_library_report="小奕数据不足，暂无借阅排名"）；
 *       无网 → Page.NETWORK_ERROR。
 *     - termInfo 有值：k.b() 设置 WebView，SetJavascriptInterface()，有网 → k.a(g("rank/libraryReport"), webView, null)
 *       （MyWebViewSetting.a，map=null 无 data 头；AT=AES(4字段AT)/UC=onlyCode/AppType=ydxy），无网 → NETWORK_ERROR。
 *   URL = ReportFactory.g("rank/libraryReport") = /mobileapi_ydxy/api/rank/libraryReport。
 *   2026-11-18 探针实测：termInfo GET code=0（xn=2026-2027 xq=1）；H5 HTTP 404（服务器未部署该页 →
 *   WebView 呈现真实网络/页面错误，绝不编造排名数据）。
 * 【JS 桥】ybginterface.praise(str)/cancelPraise(str) → e.c.a.a$a/b$a.run：
 *   run 内 h.c/b(str, termInfo.xn?:"", termInfo.xq?:"") → POST rank/libraryReport/praise|cancelPraise
 *   {broder:str, xn, xq}（实测该页 praise 随 H5 404；端点结构按源码忠实还原）。
 * 【返回】onBackPressed：canGoBack → goBack 优先。
 */
interface HttpHeader {
  headerKey: string;
  headerValue: string;
}

/** ybginterface JS 桥（LibraryReportActvity.3 逐行等价；run 内仅发写请求无 UI 回写） */
class LibraryJsBridge {
  private termXn: string = '';
  private termXq: string = '';

  setTerm(xn: string, xq: string): void {
    this.termXn = xn;
    this.termXq = xq;
  }

  cancelPraise(str: string): void {
    ApiService.libraryReportPraise(true, str, this.termXn, this.termXq)
      .catch((error: BusinessError) => ApiService.logError('library cancelPraise fail: ' + error.message));
  }

  praise(str: string): void {
    ApiService.libraryReportPraise(false, str, this.termXn, this.termXq)
      .catch((error: BusinessError) => ApiService.logError('library praise fail: ' + error.message));
  }
}

@Entry
@Component
struct BookBorrowReportPage {
  private webController: webview.WebviewController = new webview.WebviewController();
  private jsBridge: LibraryJsBridge = new LibraryJsBridge();
  @State loadProgress: number = 0;
  @State pageTitle: string = '借阅排行';
  /** 源码 Page.EMPTY_LIBRARY / NETWORK_ERROR 分支 */
  @State pageState: string = 'loading'; // loading | empty | error | web
  private targetUrl: string = '';
  private headers: HttpHeader[] = [];

  aboutToAppear(): void {
    this.loadTermAndWeb();
  }

  /** 源码 f1() → h.d() → j1(TermInfo)：termInfo 门控后决定是否加载 H5 */
  private async loadTermAndWeb(): Promise<void> {
    let at: string = '';
    try {
      at = HttpClient.buildWebEncryptedAccessToken();
    } catch (error) {
      const be = error as BusinessError;
      ApiService.logError('BookBorrowReportPage enc AT fail: ' + be.message);
    }
    if (at === '') {
      this.pageState = 'error'; // 无 AES key：源码 a.a() return → 页面停留错误态
      return;
    }
    const resp = await ApiService.getReportTermInfo();
    if (resp.code !== 0) {
      this.pageState = 'error'; // 无网/失败 → Page.NETWORK_ERROR
      return;
    }
    if (resp.data.xn === '' && resp.data.xq === '') {
      this.pageState = 'empty'; // termInfo==null 语义 → Page.EMPTY_LIBRARY
      return;
    }
    this.jsBridge.setTerm(resp.data.xn, resp.data.xq);
    this.headers = [
      { headerKey: 'Access-Token', headerValue: at },
      { headerKey: 'Unique-Code',
        headerValue: LoginSession.onlyCode === '' ? Constants.UNIQUE_CODE : LoginSession.onlyCode },
      { headerKey: 'AppType', headerValue: 'ydxy' }
    ];
    this.targetUrl = Constants.SOCKET_HOST + Api.RANK_LIBRARY_REPORT;
    this.pageState = 'web';
  }

  build() {
    Column() {
      TitleBar({ title: this.pageTitle, showBack: true })
      Stack() {
        if (this.pageState === 'empty') {
          Column() {
            Image($r('app.media.mobile_campus_page_empty'))
              .width(120).objectFit(ImageFit.Contain)
            Text('小奕数据不足，暂无借阅排名')
              .fontSize(14).fontColor($r('app.color.sdmu_text_hint')).margin({ top: 16 })
          }
          .width('100%').height('100%').justifyContent(FlexAlign.Center)
          .backgroundColor($r('app.color.main_bg'))
        } else if (this.pageState === 'error') {
          Column() {
            Image($r('app.media.mobile_campus_page_internet'))
              .width(120).objectFit(ImageFit.Contain)
            Text('网络好像有点问题，过一会再试吧')
              .fontSize(14).fontColor($r('app.color.sdmu_text_hint')).margin({ top: 16 })
          }
          .width('100%').height('100%').justifyContent(FlexAlign.Center)
          .backgroundColor($r('app.color.main_bg'))
        } else {
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
                if (event.title !== '') {
                  this.pageTitle = event.title;
                }
              })
              .onErrorReceive((event: OnErrorReceiveEvent) => {
                ApiService.logError('BookBorrowReportPage web err=' + event.error.getErrorCode() +
                  ' url=' + event.request.getRequestUrl());
              })
          }
          .width('100%').height('100%').alignItems(HorizontalAlign.Start)
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
      ApiService.logError('BookBorrowReportPage back fail: ' + be.message);
    }
    return false;
  }
}
