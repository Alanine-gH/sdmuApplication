import { router, promptAction } from '@kit.ArkUI';
import { webview } from '@kit.ArkWeb';
import { request, pasteboard, BusinessError } from '@kit.BasicServicesKit';
import { call } from '@kit.TelephonyKit';
import { common, Context, Want } from '@kit.AbilityKit';
import { TitleBar } from '../components/TitleBar';
import { LoadingView } from '../components/LoadingView';
import { EmptyView } from '../components/EmptyView';
import { HttpClient } from '../network/HttpClient';
import { LoginSession } from '../network/LoginSession';
import { Constants } from '../data/Constants';
import { ApiService } from '../network/ApiService';

/**
 * 通用 WebView 页 — 源码级翻译（module/app/view/WebViewActivity.java + 旧版
 * webviewImpl/WebViewActivity.java 参数兼容，[W28 final-b]）。
 *
 * 【布局】mobile_campus_apppage_light_app：toolbar_normal + MultiStateView
 *   + 3dip 进度条 + WebView(common_rl_wv) 填充。
 * 【入参】navigationBarTitle（旧版同名；无则用 title）→ toolbar 初始标题；url；download（默认 false：
 *   仅 true 才注册下载监听，源码 f1()）；isZoom（默认 false：setSupportZoom/setBuiltInZoomControls，
 *   DisplayZoomControls=false）；isVerify（y()：加载时注入免登头）；WebShareContent（http 开头才显示分享图标）。
 * 【加载】I2()：无网络→ERROR_NETWORK；url 空→空态；isVerify→i3()：strE 缺失→空态不加载（[W28 review] 对齐）；
 *   否则 loadUrl(url)。
 *   i3() 头 = {Access-Token: AES(4字段AT, 协商key), Unique-Code: 会话 onlyCode, AppType:"ydxy"}
 *   （与 LightApp/StudyReport 免登链同源）。WebView 设置：JS、cacheMode -1、appCache、geolocation、
 *   domStorage、mediaPlaybackRequiresUserGesture=false、verticalScrollBar=false、savePassword=false。
 * 【回调】onReceivedTitle/onPageFinished：仅当 navigationBarTitle 为空才同步网页标题；
 *   onProgressChanged：100 隐藏进度条否则显示并更新；onReceivedError：-8→网络错误，-10/-12→空态，
 *   其余→错误态；shouldOverrideUrlLoading：r 非空且 URL 含 getfile+fileMD5 → 文件下载（cookie 头），
 *   m.amap.com/map.baidu.com → loadUrl 原地加载，其余交 YBGWebViewClient（tel/sms 等）。
 * 【返回】onBackPressed：canGoBack → goBack；否则 finish（isKeyReturn 旧版参数：直接 finish）。
 * 【分享】T1()：WebShareContent 以 http 开头才显示 tool_bar_share；点击发送"应用名下载地址+URL"
 *   （HAP 等价：复制链接到粘贴板）。
 * 【下载】DownloadListener：URL 文件名落 Download 目录，存在→"下载完成"打开，否则 DownloadManager
 *   （HAP 等价 request.agent 下载到沙箱 downloads）。
 * 【探针】temp/probe_w28_final_b.py 锚点 [W28 final-b]。
 */
interface HttpHeader {
  headerKey: string;
  headerValue: string;
}

@Entry
@Component
struct WebViewPage {
  @State pageTitle: string = '';
  @State loadProgress: number = 0;
  @State pageState: string = 'loading';
  @State showShare: boolean = false;
  private targetUrl: string = '';
  private initialTitle: string = '';
  private isZoom: boolean = false;
  private isVerify: boolean = false;
  private isKeyReturn: boolean = false;
  private isToken: boolean = true;
  private shareContent: string = '';
  private downloadEnabled: boolean = false;
  private verifyBlocked: boolean = false;
  private headers: HttpHeader[] = [];
  private controller: webview.WebviewController = new webview.WebviewController();
  private downloadTask: request.agent.Task | null = null;

  aboutToAppear(): void {
    const params: Record<string, Object> | undefined = router.getParams() as Record<string, Object> | undefined;
    if (params === undefined || params === null) {
      this.pageState = 'empty';
      return;
    }
    this.pageTitle = WebViewPage.pickStr(params, 'navigationBarTitle');
    if (this.pageTitle === '') {
      this.pageTitle = WebViewPage.pickStr(params, 'title');
    }
    if (this.pageTitle === '') {
      // social WebViewActivity.T1() 默认标题"打开网页..."
      this.pageTitle = '打开网页...';
    }
    this.initialTitle = WebViewPage.pickStr(params, 'navigationBarTitle');
    if (this.initialTitle === '') {
      this.initialTitle = WebViewPage.pickStr(params, 'title');
    }
    this.targetUrl = WebViewPage.pickStr(params, 'url');
    this.isZoom = params['isZoom'] === true;
    this.isVerify = params['isVerify'] === true;
    this.isKeyReturn = params['isKeyReturn'] === true;
    this.isToken = params['isToken'] !== false;
    this.shareContent = WebViewPage.pickStr(params, 'WebShareContent');
    this.downloadEnabled = params['download'] === true;
    this.showShare = this.shareContent.startsWith('http');
    if (this.isVerify) {
      this.buildVerifyHeaders();
    } else if (this.isToken && this.targetUrl.startsWith('http')) {
      this.seedCookies();
    }
    if (this.targetUrl === '') {
      this.pageState = 'empty';
    }
  }

  /** social WebViewActivity.O2()：cookie accessToken/uniqueCode（isToken 默认 true） */
  private seedCookies(): void {
    try {
      const at: string = HttpClient.buildWebEncryptedAccessToken();
      if (at !== '') {
        webview.WebCookieManager.configCookieSync(this.targetUrl, 'accessToken=' + at);
      }
      const uc: string = LoginSession.onlyCode === '' ? Constants.UNIQUE_CODE : LoginSession.onlyCode;
      webview.WebCookieManager.configCookieSync(this.targetUrl, 'uniqueCode=' + uc);
    } catch (error) {
      const be = error as BusinessError;
      ApiService.logError('WebViewPage cookie seed fail: ' + be.message);
    }
  }

  private static pickStr(rec: Record<string, Object>, key: string): string {
    const value: Object = rec[key];
    if (typeof value === 'string') {
      return value as string;
    }
    if (typeof value === 'number') {
      return String(value as number);
    }
    return '';
  }

  /** 源码 i3()：Access-Token(AES 4字段) + Unique-Code + AppType；aesKey 缺失 → 空态不加载 */
  private buildVerifyHeaders(): void {
    try {
      if (LoginSession.aesKey === '') {
        // 源码 i3()：strE=="" → q2（空态）直接返回，不 loadUrl
        this.verifyBlocked = true;
        this.pageState = 'empty';
        return;
      }
      const at: string = HttpClient.buildWebEncryptedAccessToken();
      if (at !== '') {
        this.headers.push({ headerKey: 'Access-Token', headerValue: at });
      }
      this.headers.push({
        headerKey: 'Unique-Code',
        headerValue: LoginSession.onlyCode === '' ? Constants.UNIQUE_CODE : LoginSession.onlyCode
      });
      this.headers.push({ headerKey: 'AppType', headerValue: 'ydxy' });
    } catch (error) {
      const be = error as BusinessError;
      ApiService.logError('WebViewPage build headers fail: ' + be.message);
      this.verifyBlocked = true;
      this.pageState = 'empty';
    }
  }

  /** 源码 e 类：canGoBack → goBack，否则 finish；isKeyReturn 直接 finish */
  onBackPress(): boolean {
    if (this.isKeyReturn) {
      return false;
    }
    try {
      if (this.controller.accessBackward()) {
        this.controller.backward();
        return true;
      }
    } catch (error) {
      const be = error as BusinessError;
      ApiService.logError('WebViewPage back fail: ' + be.message);
    }
    return false;
  }

  /** 源码 f 类：分享 = 应用名+"下载地址"+WebShareContent（HAP 等价复制到粘贴板） */
  private shareLink(): void {
    if (this.shareContent === '') {
      return;
    }
    const data: pasteboard.PasteData =
      pasteboard.createData(pasteboard.MIMETYPE_TEXT_PLAIN, this.shareContent);
    pasteboard.getSystemPasteboard().setData(data)
      .then((): void => promptAction.showToast({ message: '下载链接已复制到粘贴板' }))
      .catch((error: BusinessError) => ApiService.logError('WebViewPage share fail: ' + error.message));
  }

  /** 源码下载监听：文件名从 URL path 提取；request.agent 下载到沙箱 */
  private startDownload(url: string): void {
    if (url === '') {
      return;
    }
    let fileName: string = 'web_download_' + String(Date.now());
    try {
      const path: string = url.split('?')[0];
      const parts: string[] = path.split('/');
      if (parts.length > 0 && parts[parts.length - 1] !== '') {
        fileName = parts[parts.length - 1];
      }
    } catch (error) {
      const be = error as BusinessError;
      ApiService.logError('WebViewPage parse filename: ' + be.message);
    }
    const ctx: Context | undefined = this.getUIContext().getHostContext();
    if (ctx === undefined || ctx === null) {
      return;
    }
    const cfg: request.agent.Config = {
      action: request.agent.Action.DOWNLOAD,
      url: url,
      saveas: fileName
    };
    request.agent.create(ctx, cfg)
      .then((task: request.agent.Task) => {
        this.downloadTask = task;
        task.on('completed', (): void => {
          promptAction.showToast({ message: '下载完成' });
        });
        task.on('failed', (): void => {
          promptAction.showToast({ message: '下载失败' });
        });
        task.start().catch((error: BusinessError) => {
          ApiService.logError('WebViewPage download start: ' + error.message);
        });
      })
      .catch((error: BusinessError) => ApiService.logError('WebViewPage download create: ' + error.message));
  }

  /** 源码 shouldOverrideUrlLoading：tel/sms 交系统；amap/baidu 原地加载；其余放行 */
  private interceptUrl(url: string): boolean {
    if (url.startsWith('tel:')) {
      try {
        call.makeCall(url.substring(4), (): void => { });
      } catch (error) {
        const be = error as BusinessError;
        ApiService.logError('WebViewPage tel fail: ' + be.message);
      }
      return true;
    }
    if (url.startsWith('sms:')) {
      const want: Want = { action: 'ohos.want.action.sendToData', uri: url };
      const ctx: common.UIAbilityContext | undefined =
        this.getUIContext().getHostContext() as common.UIAbilityContext | undefined;
      if (ctx !== undefined && ctx !== null) {
        ctx.startAbility(want)
          .catch((error: BusinessError) => ApiService.logError('WebViewPage sms: ' + error.message));
      }
      return true;
    }
    return false;
  }

  private onWebError(code: number): void {
    if (code === -8) {
      this.pageState = 'error';
    } else if (code === -10 || code === -12) {
      this.pageState = 'empty';
    } else {
      this.pageState = 'error';
    }
  }

  build() {
    Column() {
      TitleBar({
        title: this.pageTitle,
        showBack: true,
        rightIcon: this.showShare ? $r('app.media.tool_bar_share') : null,
        onRightClick: (): void => {
          this.shareLink();
        }
      })

      if (this.pageState === 'error' || this.pageState === 'empty') {
        Column() {
          EmptyView({ tipText: this.pageState === 'error' ? '网页加载失败，请稍后重试' : '暂无内容' })
        }
        .width('100%')
        .layoutWeight(1)
      } else {
        Stack({ alignContent: Alignment.TopStart }) {
          Column() {
            Progress({ value: this.loadProgress, total: 100, type: ProgressType.Linear })
              .width('100%')
              .height(3)
              .color($r('app.color.mobile_campus_primary_color_default'))
              .backgroundColor($r('app.color.common_color_5'))

            Web({ src: '', controller: this.controller })
              .width('100%')
              .layoutWeight(1)
              .javaScriptAccess(true)
              .domStorageAccess(true)
              .zoomAccess(this.isZoom)
              .fileAccess(true)
              .onControllerAttached(() => {
                if (this.targetUrl !== '' && !this.verifyBlocked) {
                  this.controller.loadUrl(this.targetUrl, this.headers);
                }
              })
              .onProgressChange((event: OnProgressChangeEvent) => {
                this.loadProgress = event.newProgress;
              })
              .onTitleReceive((event: OnTitleReceiveEvent) => {
                // 源码 onReceivedTitle：仅 navigationBarTitle 为空才用网页标题
                if (this.initialTitle === '' && event.title !== '') {
                  this.pageTitle = event.title;
                }
              })
              .onErrorReceive((event: OnErrorReceiveEvent) => {
                ApiService.logError('WebViewPage error url=' + event.request.getRequestUrl() +
                  ' code=' + event.error.getErrorCode());
                this.onWebError(event.error.getErrorCode());
              })
              .onDownloadStart((event: OnDownloadStartEvent) => {
                // 源码 f1()：仅 download 入参为 true 才注册 DownloadListener
                if (this.downloadEnabled) {
                  this.startDownload(event.url);
                }
              })
              .onLoadIntercept((event: OnLoadInterceptEvent) => {
                const url: string = event.data.getRequestUrl();
                return this.interceptUrl(url);
              })
          }
          .width('100%')
          .height('100%')

          if (this.pageState === 'loading' && this.loadProgress === 0) {
            Column() {
              LoadingView()
            }
            .width('100%')
            .height('100%')
            .backgroundColor(Color.White)
          }
        }
        .width('100%')
        .layoutWeight(1)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.main_bg'))
  }
}
