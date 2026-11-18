import { router } from '@kit.ArkUI';
import { webview } from '@kit.ArkWeb';
import { BusinessError } from '@kit.BasicServicesKit';
import { TitleBar } from '../components/TitleBar';
import { EmptyView } from '../components/EmptyView';
import { ApiService } from '../network/ApiService';
import { CryptoUtil } from '../network/CryptoUtil';
import { HttpClient } from '../network/HttpClient';
import { LoginSession } from '../network/LoginSession';
import { ApiResponse } from '../model/ResponseModel';
import { StudyTermInfo } from '../model/ContactModel';
import { Api } from '../network/Api';
import { Constants } from '../data/Constants';

/**
 * 学业报告详情页 — 源码级翻译（studyReport/view/DetailActivity.java 逐行 → ArkTS，
 * [W26 partial-finish]；原占位空态版替换为真实数据链）：
 *
 * 【入口】StudyReportActivity ybginterface.JumpToDetail → Intent(l, DetailActivity){appInfo}(1872)。
 * 【布局】student_report_layout_main.xml：toolbar（标题=AppInfo.YYMC，无 extra → "学期学习报告"）
 *   + MultiStateView(apppage_light_app_state) + report_web。
 * 【数据链】f1()：h=new g.c.a(this)（MainActivityPresenter）→ h.b() → StudyReportModel.d：
 *   e.b(StudyReportFactory.g("gradeReport/getRecentTermInfo")) GET 加密通道 → TermInfo{XN,XQ}。
 *   z(TermInfo)：null → MultiStateView EMPTY_SCORE（R.string.student_report_empty_score_report
 *   ="成绩还没出完呢，再等等"）；网络不可用 → NETWORK_ERROR；
 *   有值 → m={xn: XN==null?"":XN, xq: XQ!=null?XQ:""} → k.a(g("gradeReport/index"), o, m)：
 *   WebView loadUrl(url, {Access-Token:c.i(4字段AT,aesKey), Unique-Code:d.a.d(), AppType:"ydxy",
 *   data:c.i(k.m(m), aesKey)})。
 * 【2026-11-18 探针实测】getRecentTermInfo code=0 真实 TermInfo{XN:"2025-2026", XQ:"1"}。
 * 【无 JS 桥】DetailActivity 未调 SetJavascriptInterface（仅 StudyReportActivity 有）。
 * 【无关闭按钮】OPENAPPLICATION 仅 AppInfo extra 携带，JumpToDetail 入口 AppInfo=null。
 */
interface HttpHeader {
  headerKey: string;
  headerValue: string;
}

@Entry
@Component
struct StudyReportDetailPage {
  private webController: webview.WebviewController = new webview.WebviewController();
  @State pageTitle: string = '学期学习报告';
  @State loadProgress: number = 0;
  /** null=加载中 / true=WebView / false=EMPTY_SCORE 空态（源码 z(null)） */
  @State loadState: number = 0;
  @State emptyTip: string = '';
  private targetUrl: string = '';
  private headers: HttpHeader[] = [];

  aboutToAppear(): void {
    const params = router.getParams() as Record<string, string> | undefined;
    if (params !== undefined && params !== null) {
      const t: string | undefined = params['title'];
      if (t !== undefined && t !== '') {
        this.pageTitle = t;
      }
    }
    this.targetUrl = Constants.SOCKET_HOST + Api.GRADE_REPORT_INDEX;
    this.loadTermInfo();
  }

  /** 源码 MainActivityPresenter.b() → StudyReportModel.d(c<TermInfo>)：GET getRecentTermInfo */
  private loadTermInfo(): void {
    ApiService.getStudyReportTermInfo()
      .then((response: ApiResponse<StudyTermInfo>) => {
        if (response.code === 1000) {
          return;
        }
        if (response.code !== 0) {
          // 源码 h() 失败回调 f(...) → z(null) → EMPTY_SCORE 固定文案（不透传服务器 message）
          this.loadState = 2;
          this.emptyTip = '成绩还没出完呢，再等等';
          return;
        }
        // 源码 z(TermInfo)：null → EMPTY_SCORE；有值 → m={xn,xq} → k.a(...)
        this.applyTermInfo(response.data);
      })
      .catch(() => {
        ApiService.logError('StudyReportDetailPage termInfo error');
        this.loadState = 2;
        this.emptyTip = '成绩还没出完呢，再等等';
      });
  }

  /** 源码 z(TermInfo)：xn=XN==null?"":XN；xq=XQ!=null?XQ:"" → loadUrl */
  private applyTermInfo(term: StudyTermInfo): void {
    if (term === null) {
      this.loadState = 2;
      this.emptyTip = '成绩还没出完呢，再等等';
      return;
    }
    const xn: string = term.XN;
    const xq: string = term.XQ;
    const dataPayload: Record<string, string> = { 'xn': xn, 'xq': xq };
    let dataHeader: string = '';
    let at: string = '';
    try {
      dataHeader = CryptoUtil.encryptAES(JSON.stringify(dataPayload), LoginSession.aesKey);
      at = HttpClient.buildWebEncryptedAccessToken();
    } catch (error) {
      const be = error as BusinessError;
      ApiService.logError('StudyReportDetailPage enc fail: ' + be.message);
    }
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
    this.loadState = 1;
  }

  build() {
    Column() {
      TitleBar({ title: this.pageTitle, showBack: true })

      if (this.loadState === 2) {
        // 源码 t(this.i, Page.EMPTY_SCORE.extra("成绩还没出完呢，再等等")) 空态
        Column() {
          EmptyView({ tipText: this.emptyTip })
        }
        .width('100%')
        .layoutWeight(1)
        .backgroundColor($r('app.color.main_bg'))
      } else {
        Stack() {
          Column() {
            Progress({ value: this.loadProgress, total: 100, type: ProgressType.Linear })
              .width('100%')
              .height(3)
              .color($r('app.color.sdmu_primary'))
              .backgroundColor($r('app.color.common_color_5'))
              .visibility(this.loadState === 1 ? Visibility.Visible : Visibility.None)

            // 源码 report_web：MyWebViewSetting.b（JS/domStorage/zoom 开）
            Web({ src: '', controller: this.webController })
              .width('100%')
              .layoutWeight(1)
              .javaScriptAccess(true)
              .domStorageAccess(true)
              .zoomAccess(true)
              .onControllerAttached(() => {
                // 源码 k.a(...)：strE 空 → return 不加载
                if (this.targetUrl !== '') {
                  this.webController.loadUrl(this.targetUrl, this.headers);
                }
              })
              .onProgressChange((event: OnProgressChangeEvent) => {
                this.loadProgress = event.newProgress;
              })
              .onErrorReceive((event: OnErrorReceiveEvent) => {
                ApiService.logError('StudyReportDetailPage web error code=' + event.error.getErrorCode());
              })
          }
          .width('100%')
          .height('100%')
          .alignItems(HorizontalAlign.Start)
          .visibility(this.loadState === 1 ? Visibility.Visible : Visibility.None)
        }
        .width('100%')
        .layoutWeight(1)
      }
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
      ApiService.logError('StudyReportDetailPage back fail: ' + be.message);
    }
    return false;
  }
}
