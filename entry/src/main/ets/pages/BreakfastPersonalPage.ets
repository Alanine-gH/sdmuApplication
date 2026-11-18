import { webview } from '@kit.ArkWeb';
import { BusinessError } from '@kit.BasicServicesKit';
import { TitleBar } from '../components/TitleBar';
import { HttpClient } from '../network/HttpClient';
import { LoginSession } from '../network/LoginSession';
import { ApiService } from '../network/ApiService';
import { Api } from '../network/Api';
import { Constants } from '../data/Constants';

/**
 * 早餐打卡个人页 — 1:1 翻译 PersonalActivity.java（manifest L539；breakfastReport/view/PersonalActivity）。
 *
 * 【入口】StudentReportHomePage "早餐打卡"卡片（学生报表主页；pages/ 路由已修）。
 * 【源码】student_report_layout_main.xml：toolbar + report_web WebView（本页 MultiStateView id=apppage_light_app_state，
 *   源码未对其 t()/v()，仅 WebView 填充）。H0()=null。
 *   T1()：标题 = AppInfo.YYMC 或默认 "我的首页"；OPENAPPLICATION=="1" 才有"关闭"按钮（setResult(-1)+finish），
 *   宫格入口无 AppInfo → 不触发。
 * 【数据】f1()：this.o.b(context, webView) 设置 WebView（JS/domStorage/zoom 开），
 *   this.o.a(this.q.g("rank/breakfast/getPersonal"), webView, null)（MyWebViewSetting.a，map=null 无 data 头）：
 *     strE = randomBase64AESKey（LoginSession.aesKey，空 → return 不加载）；
 *     Access-Token = AES(4字段AT, strE)；Unique-Code = onlyCode；AppType="ydxy"。
 *   URL = ReportFactory.g("rank/breakfast/getPersonal") = d.d() + /mobileapi_ydxy/api/rank/breakfast/getPersonal。
 *   源码 f1() 无 s.o() 网络判断（区别于 Library/Onecard），AES key 缺失即 a() 内 return。
 *   2026-11-18 探针实测：H5 HTTP 200 title="我的主页"（真实页面可加载，onReceivedTitle 覆盖默认标题）。
 * 【JS 桥】本页无 SetJavascriptInterface（源码 PersonalActivity 未调用）。
 * 【返回】onBackPressed：canGoBack → goBack 优先。
 */
interface HttpHeader {
  headerKey: string;
  headerValue: string;
}

@Entry
@Component
struct BreakfastPersonalPage {
  private webController: webview.WebviewController = new webview.WebviewController();
  @State loadProgress: number = 0;
  @State pageTitle: string = '我的首页';
  @State netError: boolean = false;
  private targetUrl: string = '';
  private headers: HttpHeader[] = [];

  aboutToAppear(): void {
    this.targetUrl = Constants.SOCKET_HOST + Api.RANK_BREAKFAST_PERSONAL;
    this.headers = [];
    let at: string = '';
    try {
      at = HttpClient.buildWebEncryptedAccessToken(); // 4字段明文 AT→AES（StudyReport 同款免登链）
    } catch (error) {
      const be = error as BusinessError;
      ApiService.logError('BreakfastPersonalPage enc AT fail: ' + be.message);
    }
    if (at !== '') {
      this.headers.push({ headerKey: 'Access-Token', headerValue: at });
    }
    this.headers.push({ headerKey: 'Unique-Code',
      headerValue: LoginSession.onlyCode === '' ? Constants.UNIQUE_CODE : LoginSession.onlyCode });
    this.headers.push({ headerKey: 'AppType', headerValue: 'ydxy' });
    // 源码 a.a.a："".equals(strE) → return（AES key 缺失不加载）
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
            .onControllerAttached(() => {
              if (this.targetUrl !== '') {
                this.webController.loadUrl(this.targetUrl, this.headers);
              }
            })
            .onProgressChange((event: OnProgressChangeEvent) => {
              this.loadProgress = event.newProgress;
            })
            .onTitleReceive((event: OnTitleReceiveEvent) => {
              // 源码 a 类 WebChromeClient.onReceivedTitle：非空才覆盖（H5 title="我的主页"）
              if (event.title !== '') {
                this.pageTitle = event.title;
              }
            })
            .onErrorReceive((event: OnErrorReceiveEvent) => {
              ApiService.logError('BreakfastPersonalPage web err=' + event.error.getErrorCode() +
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
      ApiService.logError('BreakfastPersonalPage back fail: ' + be.message);
    }
    return false;
  }
}
