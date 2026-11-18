import { router } from '@kit.ArkUI';
import { webview } from '@kit.ArkWeb';
import { BusinessError } from '@kit.BasicServicesKit';
import { TitleBar } from '../components/TitleBar';
import { HttpClient } from '../network/HttpClient';
import { CryptoUtil } from '../network/CryptoUtil';
import { LoginSession } from '../network/LoginSession';
import { ApiService } from '../network/ApiService';
import { Api } from '../network/Api';
import { Constants } from '../data/Constants';

/**
 * 学习报告页 — 源码级翻译（StudyReportActivity.java 逐行 → ArkTS，[W26 partial-finish]）：
 *
 * 【入口】宫格 yyid=studyReport（LX=1 原生，manifest action sdgy_studyReport → StudyReportActivity）。
 * 【布局】student_report_layout_main.xml：toolbar（标题=AppInfo.YYMC，宫格入口无 AppInfo extra
 *   → T1() n("学期学习报告") 默认标题）+ MultiStateView + report_web WebView 填充。
 * 【数据】f1()：q={xn:null,xq:null}（Gson serializeNulls=false → "{}"）；
 *   a.a.a(str, webView, q)（MyWebViewSetting.java）：
 *   strE=randomBase64AESKey（协商 AES key，空 → return 不加载）；
 *   Access-Token = c.i(4字段明文AT, strE)（AES/ECB → Base64）；
 *   Unique-Code = d.a.d()（登录会话 onlyCode）；AppType="ydxy"；
 *   data = c.i(k.m(q), strE)（"{}" 加密）→ loadUrl(url, headers)。
 *   URL = ReportFactory.b.f14967c="gradeReport/index"：super.d(SCHOOL, path)
 *   = d.d() + "/" + c.f12863a("mobileapi_ydxy") + "/" + a()("api") + "/" + path
 *   （b()=null 跳过）。2026-11-18 探针实测带免登头 200 HTML 6694B（裸请求 code=0006）。
 * 【JS 桥】SetJavascriptInterface：addJavascriptInterface("ybginterface")，
 *   JumpToDetail() → DetailActivity{appInfo}(1872) → HAP pushUrl StudyReportDetailPage。
 * 【返回】onBackPressed：webView.canGoBack() → goBack()；否则默认返回。
 * 【无关闭按钮】OPENAPPLICATION 仅 AppInfo extra 携带，宫格入口无 AppInfo → 无"关闭"分支。
 */
interface HttpHeader {
  headerKey: string;
  headerValue: string;
}

/** ybginterface JS 桥对象（StudyReportJsInteraction.JumpToDetail 逐行等价） */
class YbgJsBridge {
  private owner: string = 'StudyReportPage';

  /** 源码 StudyReportActivity.3.a.run：new Intent(l, DetailActivity.class){appInfo}(1872)；
   *  宫格入口 AppInfo=null → DetailActivity 自拉 TermInfo，HAP 传 title 等价。 */
  JumpToDetail(): void {
    router.pushUrl({ url: 'pages/StudyReportDetailPage', params: { 'title': '学期学习报告' } });
  }
}

@Entry
@Component
struct StudyReportPage {
  private webController: webview.WebviewController = new webview.WebviewController();
  private jsBridge: YbgJsBridge = new YbgJsBridge();
  @State loadProgress: number = 0;
  @State pageTitle: string = '学期学习报告';
  private targetUrl: string = '';
  private headers: HttpHeader[] = [];

  aboutToAppear(): void {
    // 源码 URL：ReportFactory.g("gradeReport/index") = d.d() + /mobileapi_ydxy + /api + /gradeReport/index
    this.targetUrl = Constants.SOCKET_HOST + Api.GRADE_REPORT_INDEX;
    // 源码 f1()：q={xn:null,xq:null} → k.m(q)="{}"（serializeNulls=false 省略 null 值）→ c.i("{}", aesKey)
    let dataHeader: string = '';
    try {
      dataHeader = CryptoUtil.encryptAES('{}', LoginSession.aesKey);
    } catch (error) {
      const be = error as BusinessError;
      ApiService.logError('StudyReportPage enc data fail: ' + be.message);
    }
    let at: string = '';
    try {
      // 源码 c.i(B3().get("Access-Token"), strE)：4字段明文 AT → AES → Base64
      at = HttpClient.buildWebEncryptedAccessToken();
    } catch (error) {
      const be = error as BusinessError;
      ApiService.logError('StudyReportPage enc AT fail: ' + be.message);
    }
    // 源码 map：Access-Token / Unique-Code / AppType / data；strE 空 → "" 分支 return（不加载）
    if (at !== '') {
      this.headers.push({ headerKey: 'Access-Token', headerValue: at });
    }
    this.headers.push({ headerKey: 'Unique-Code',
      headerValue: LoginSession.onlyCode === '' ? Constants.UNIQUE_CODE : LoginSession.onlyCode });
    this.headers.push({ headerKey: 'AppType', headerValue: 'ydxy' });
    if (dataHeader !== '') {
      this.headers.push({ headerKey: 'data', headerValue: dataHeader });
    }
    // 源码 a.a.a："".equals(strE) → return（AES key 缺失不发起 loadUrl）
    if (at === '') {
      this.targetUrl = '';
    }
  }

  /** 源码 a 类 onReceivedTitle：webView 标题同步 toolbar（空串不覆盖默认"学期学习报告"） */
  build() {
    Column() {
      TitleBar({ title: this.pageTitle, showBack: true })

      Stack() {
        Column() {
          Progress({ value: this.loadProgress, total: 100, type: ProgressType.Linear })
            .width('100%')
            .height(3)
            .color($r('app.color.sdmu_primary'))
            .backgroundColor($r('app.color.common_color_5'))

          // 源码 report_web：JavaScript/domStorage/zoom 开（MyWebViewSetting.b）
          Web({ src: '', controller: this.webController })
            .width('100%')
            .layoutWeight(1)
            .javaScriptAccess(true)
            .domStorageAccess(true)
            .zoomAccess(true)
            .javaScriptProxy({
              object: this.jsBridge,
              name: 'ybginterface',
              methodList: ['JumpToDetail'],
              controller: this.webController
            })
            .onControllerAttached(() => {
              // 源码 a.a.a(str, webView, q)：loadUrl(url, headers) 免登头注入；strE 空 → 不加载
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
              ApiService.logError('StudyReportPage web error url=' + event.request.getRequestUrl() +
                ' code=' + event.error.getErrorCode());
            })
        }
        .width('100%')
        .height('100%')
        .alignItems(HorizontalAlign.Start)
      }
      .width('100%')
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
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
      ApiService.logError('StudyReportPage back fail: ' + be.message);
    }
    return false;
  }
}
