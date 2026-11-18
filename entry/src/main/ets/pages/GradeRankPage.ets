import { router } from '@kit.ArkUI';
import { webview } from '@kit.ArkWeb';
import { BusinessError } from '@kit.BasicServicesKit';
import { TitleBar } from '../components/TitleBar';
import { ApiService } from '../network/ApiService';
import { Api } from '../network/Api';
import { Constants } from '../data/Constants';
import { CryptoUtil } from '../network/CryptoUtil';
import { LoginSession } from '../network/LoginSession';
import { HttpClient } from '../network/HttpClient';

/**
 * 绩点排行页 — 源码级翻译 GradeReportActvity（student_report/gradeReport/view，[P-B placeholder]）：
 *
 * 【入口】学生报表主页"绩点排行"卡片（manifest action sdgy_gradeReport；StudentReportHomePage）。
 * 【布局】student_report_layout_main：toolbar（标题=appInfo.YYMC，宫格入口无 appInfo→"绩点排行"）
 *   + MultiStateView + report_web WebView 填充。OPENAPPLICATION=="1" 时右上"关闭"finish。
 * 【数据】f1()：t={xn:intent.xn, xq:intent.xq}；有网 s.o()→p.a(u.g(b.f14965a),webView,t)：
 *   URL=ReportFactory.g("rank/gradeReport")=/mobileapi_ydxy/api/rank/gradeReport；
 *   头=Access-Token(AES 4字段 AT)/Unique-Code(onlyCode)/AppType:ydxy/data(AES({xn,xq}))；
 *   无网→t0(n, NETWORK_ERROR) 错误态。探针实测：带免登头 200 HTML 10601B（title=绩点排行）/
 *   裸请求 code=0006 → 头必须。
 * 【JS桥】SetJavascriptInterface addJavascriptInterface("ybginterface")：
 *   praise(broder,phb)→GradeReportModel.a→POST rank/gradeReport/praise；
 *   cancelPraise(broder,phb)→.b→POST rank/gradeReport/cancelPraise（JSUtil.processJSRunnable 异步）。
 * 【返回】onBackPressed：canGoBack→goBack 优先。
 */
interface PbHttpHeader {
  headerKey: string;
  headerValue: string;
}

/** ybginterface JS 桥（GradeReportActvity.3 逐行等价；源码 run 内仅发写请求无 UI 回写） */
class GradeRankJsBridge {
  cancelPraise(str: string, str2: string): void {
    ApiService.gradeRankPraise(str, str2, true)
      .then(() => { /* 源码 a.run 仅 m.c(b,c) 发起写请求 */ })
      .catch((error: BusinessError) => ApiService.logError('gradeRank cancelPraise fail: ' + error.message));
  }

  praise(str: string, str2: string): void {
    ApiService.gradeRankPraise(str, str2, false)
      .then(() => { /* 源码 b.run 仅 m.b(b,c) 发起写请求 */ })
      .catch((error: BusinessError) => ApiService.logError('gradeRank praise fail: ' + error.message));
  }
}

@Entry
@Component
struct GradeRankPage {
  private webController: webview.WebviewController = new webview.WebviewController();
  private jsBridge: GradeRankJsBridge = new GradeRankJsBridge();
  @State loadProgress: number = 0;
  @State pageTitle: string = '绩点排行';
  @State netError: boolean = false;
  private targetUrl: string = '';
  private headers: PbHttpHeader[] = [];

  aboutToAppear(): void {
    const params: Record<string, Object> = (router.getParams() ?? {}) as Record<string, Object>;
    const pick = (k: string): string => {
      const v: Object | undefined = params[k];
      return typeof v === 'string' ? v as string : '';
    };
    // 源码 t={xn:intent.xn,xq:intent.xq}（空串仍 put，Gson 序列化为 {"xn":"","xq":""}）
    let dataHeader: string = '';
    let at: string = '';
    try {
      dataHeader = CryptoUtil.encryptAES(JSON.stringify({ 'xn': pick('xn'), 'xq': pick('xq') }), LoginSession.aesKey);
      at = HttpClient.buildWebEncryptedAccessToken(); // 4字段明文 AT→AES（StudyReport 同款免登链）
    } catch (error) {
      const be = error as BusinessError;
      ApiService.logError('GradeRankPage enc fail: ' + be.message);
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
    // 源码 strE(aesKey) 空 → a.a() return 不加载；!s.o(网络) → t0(NETWORK_ERROR)
    if (at === '' || dataHeader === '') {
      this.netError = true;
    } else {
      this.targetUrl = Constants.SOCKET_HOST + Api.GRADE_RANK_INDEX;
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
            .javaScriptAccess(true).domStorageAccess(true).zoomAccess(true)
            .javaScriptProxy({
              object: this.jsBridge, name: 'ybginterface',
              methodList: ['praise', 'cancelPraise'], controller: this.webController
            })
            .onControllerAttached(() => {
              if (this.targetUrl !== '') {
                this.webController.loadUrl(this.targetUrl, this.headers);
              }
            })
            .onProgressChange((event: OnProgressChangeEvent) => { this.loadProgress = event.newProgress; })
            .onTitleReceive((event: OnTitleReceiveEvent) => {
              if (event.title !== '') {
                this.pageTitle = event.title; // 源码 a 类 onReceivedTitle：非空才覆盖
              }
            })
            .onErrorReceive((event: OnErrorReceiveEvent) => {
              ApiService.logError('GradeRankPage web err=' + event.error.getErrorCode() +
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

  onBackPress(): boolean {
    try {
      if (this.webController.accessBackward()) {
        this.webController.backward();
        return true;
      }
    } catch (error) {
      const be = error as BusinessError;
      ApiService.logError('GradeRankPage back fail: ' + be.message);
    }
    return false;
  }
}
