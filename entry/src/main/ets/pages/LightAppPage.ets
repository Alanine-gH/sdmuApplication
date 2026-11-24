import { router } from '@kit.ArkUI';
import { webview } from '@kit.ArkWeb';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { BreakpointSystem } from '../common/BreakpointSystem';
import { LoginSession } from '../network/LoginSession';
import { HttpClient } from '../network/HttpClient';
import { Constants } from '../data/Constants';

/**
 * 轻应用页 — 1:1 翻译原 APK LightActivity.java(1080行)/X5LightActivity.java 的加载公式：
 *   loadUrl(SCHOOL服务器 + "/mobileapi_ydxy/api/lapp/springboard?yyid=<应用YYID>",
 *           headers = { Unique-Code: 会话UC, AppType: "ydxy" })
 * - 源码 c/a/c/a/a.java(AppsFactory)：f12800b = "lapp/springboard"，a()="api"，b()=null，
 *   c()="mobileapi_ydxy" → 路径 = /mobileapi_ydxy/api/lapp/springboard
 * - 认证头：源码 map.put("Unique-Code", d.a().d()) + map.put("AppType", "ydxy")
 * - yyid 来自服务端下发的 AppBean.YYID（如 baseQRCode / YiClassroom / freeClassroom / bodaNews）
 * [W1 light-url] APK URL 二次加工（免登核心攻坚，2026-11-17 源码还原+服务器实测定案）：
 *   分支矩阵（module/app/util/a.java switch LX → X5LightActivity.I2()）：
 *   - LX=2/4 及缺省（非 h5 非 LX8）→ springboard 跳板（X5 I2() L1621-1623 / Light I2() L761）：
 *     GET SOCKET_HOST + /mobileapi_ydxy/api/lapp/springboard?yyid=<YYID>
 *     头 = {Access-Token, Unique-Code, AppType}；WebView 跟随 302 免登链：
 *     thirdAuth?accessToken=<服务端AT> → 应用页?t=<ticket> (+Set-Cookie ydxy_accessToken) → 免登成功
 *   - LX=8（X5 I2() L1626-1638"第三方应用对接移动校园单点"）→ URL 拼
 *     ?accessToken=<urlencode(4字段AES-AT)>&uniqueCode=<UC>&yyid=<YYID>，头仅 {AT, UC}
 *   - LX=6 → 相对路径前缀域名（X5 L1604-1607 / Light L781-784，均在 h5 直载分支内）；
 *     注：APK 默认入口（无 h5 extra）LX=6 仍走 springboard，前缀分支仅 h5=true 生效；
 *     本工程 dispatchApp 对 lx='6' 不路由进本页（掉原生 YYID 映射），此处保留为直载兜底。
 *   - APK X5 this.w=isLoadOnly extra 直载分支（L1552-1556 无头 loadUrl）未复刻：
 *     本工程无 isLoadOnly 路由参数，真实入口不可达，略。
 *   明文 AT = B3()/l3() Gson(HeadParamsEntity) 4 字段（serializeNulls=false 省略 null），
 *   加密 = c.i() → Base64(AES/ECB/PKCS5) —— 见 HttpClient.buildWebEncryptedAccessToken()。
 *   UC 实测定案：springboard/免登会话只认登录会话 onlyCode（d.a.d() 同款）；协商 deviceCode 无效。
 *   cookie 兜底（X5 S3()/Light n3()）：accessToken/uniqueCode/AppType=ydxy，loadUrl 前写入。
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
  // [R57] 用字符串视图状态替代布尔：避免 Web 销毁/重建回调与 loadFailed 布尔的竞态导致错误态不显示
  @State viewState: string = 'web';
  // [R61] 主帧错误码（-7=超时等），错误页按码细分提示
  @State lastErrorCode: number = 0;
  @StorageProp('currentBreakpoint') currentBreakpoint: string = 'sm';
  @StorageProp('isCompactHeight') isCompactHeight: boolean = false;
  @StorageProp('avoidAreaLeftVp') avoidAreaLeftVp: number = 0;
  @StorageProp('avoidAreaRightVp') avoidAreaRightVp: number = 0;
  @StorageProp('avoidAreaBottomVp') avoidAreaBottomVp: number = 0;
  private loadFailed: boolean = false;
  private yyid: string = '';
  private headers: HttpHeader[] = [];
  private webAttached: boolean = false;
  // [R61b] setHttpDns 为全局静态接口，只需调用一次；用标记防止每个轻应用页重复调用
  private httpDnsSet: boolean = false;
  // [W1 light-url] WebView 免登加密 AT（4字段版）+ 路由 LX（决定 APK 加载分支）
  private webAccessToken: string = '';
  private lx: string = '';
  // [W26 partial-finish] APK X5LightActivity I2() 分支路由参：
  //   h5='1' → u=true 直载分支（L1583-1610：loadUrl(url, {AT,UC})，LX=6 相对路径前缀域名）；
  //   loadOnly='1' → w=true 分支（L1552-1555：无头 loadUrl(url)）。QrCodeScanPage 分流 a.k/a.m 场景。
  private h5: string = '';
  private loadOnly: string = '';

  /** [W6 light-diag] 诊断日志：hilog tag 'SDMU'，前缀 'LightDiag'（onLoadIntercept/页面生命周期/console 全链路） */
  private diag(msg: string): void {
    hilog.info(0x0000, 'SDMU', 'LightDiag %{public}s', msg);
  }

  aboutToAppear(): void {
    // [release] 生产版关闭 WebView 远程调试（chrome://inspect 排障通道，仅开发期开启）
    try {
      webview.WebviewController.setWebDebuggingAccess(false);
    } catch {
      this.diag('setWebDebuggingAccess failed (non-fatal)');
    }
    // [R61b 崩溃修复] setHttpDns 严禁在首个 Web 创建前调用——引擎 NetworkService 未就绪时
    // GetNetworkService() 返回 NULL 直接 SIGSEGV（真机 Mate 60 Pro 崩溃实证）。
    // 已挪至 onControllerAttached（Web 创建后）时机，见下方回调。
    // 路由参数：url（服务端 app/list 下发地址）+ yyid（AppBean.YYID）+ lx（AppBean.LX，APK 分支依据）+ title
    // [W26 partial-finish] 扫码分流追加：h5（AppBean.h5 extra）/ loadOnly（isLoadOnly extra）
    const params = router.getParams() as Record<string, string> | undefined;
    if (params) {
      this.yyid = params['yyid'] ?? '';
      this.pageTitle = params['title'] ?? '轻应用';
      this.lx = params['lx'] ?? '';
      this.h5 = params['h5'] ?? '';
      this.loadOnly = params['loadOnly'] ?? '';
      const directUrl: string = params['url'] ?? '';
      if (directUrl !== '') {
        this.targetUrl = directUrl;
      }
    }
    if (this.targetUrl === '' && this.yyid === '') {
      // 无 url/yyid（本地清单项无服务端地址）：提示并保持空态
      this.targetUrl = '';
    }
    // ===== [W1 light-url] APK URL 二次加工复刻（X5LightActivity.I2() 分支矩阵，2026-11-17 服务器实测定案）=====
    // 实测结论（probe_lighturl5/uc_semantics）：
    //   a) LX=2 真实路径 = springboard 跳板：GET /mobileapi_ydxy/api/lapp/springboard?yyid=<YYID>
    //      + 头{Access-Token, Unique-Code, AppType} → 302 thirdAuth?accessToken=<服务端加密AT>
    //      → 302 应用页(带 t=ticket) + Set-Cookie ydxy_accessToken → 免登成功；
    //      Unique-Code 只认登录会话 UC（onlyCode 过 / 协商 deviceCode 返回非302未登录态）——APK d.a.d() 同款。
    //   b) LX=8：URL 拼 ?accessToken=<urlencode(AT)>&uniqueCode=<UC>&yyid=<YYID> + 头{AT, UC}（X5 L1626-1638）。
    //   c) LX=6：相对路径前缀域名（X5 L1604-1607 / Light L781-784）。
    // UC 优先级：登录会话 onlyCode（springboard 实测唯一有效）> 协商 deviceCode 兜底
    const uc: string = LoginSession.onlyCode !== '' ? LoginSession.onlyCode : LoginSession.deviceCode;
    try {
      // APK B3()/l3()：4字段明文 Gson(serializeNulls=false) → c.i()/z.d() AES(协商aesKey) → Base64
      this.webAccessToken = HttpClient.buildWebEncryptedAccessToken();
    } catch {
      this.webAccessToken = '';
    }
    if (this.loadOnly === '1' && this.targetUrl !== '') {
      // [W26 partial-finish] (d) APK X5 I2() w=true（L1552-1555）：isLoadOnly 无头直载。
      //   QrCodeScanPage 分流 a.m（y3 type=3/5 data 直载）场景。
      this.headers = [];
    } else if (this.h5 === '1' && this.targetUrl !== '') {
      // [W26 partial-finish] (e) APK X5 I2() u=true h5 直载分支（L1583-1610）：
      //   loadUrl(url, {AT(加密), UC})（无 AppType 头）；LX=6 相对路径前缀域名；
      //   YiClassroom/leavingSchool/unifyTodo 特例（yyid 不同时不涉及）。
      if (this.lx === '6' && !this.targetUrl.startsWith('http')) {
        this.targetUrl = Constants.SOCKET_HOST + this.targetUrl;
      }
      const h5Headers: HttpHeader[] = [{ headerKey: 'Unique-Code', headerValue: uc }];
      if (this.webAccessToken !== '') {
        h5Headers.unshift({ headerKey: 'Access-Token', headerValue: this.webAccessToken });
      }
      this.headers = h5Headers;
    } else if (this.lx === '8' && this.targetUrl !== '' && this.webAccessToken !== '') {
      // (b) LX=8"第三方应用对接移动校园单点"：URL query 单点参数；头仅 AT+UC（X5 L1580-1581）
      const yyidPart: string = this.yyid === '' ? '' : '&yyid=' + this.yyid;
      const glue: string = this.targetUrl.includes('?') ? '&' : '?';
      this.targetUrl = this.targetUrl + glue + 'accessToken=' + encodeURIComponent(this.webAccessToken) +
        '&uniqueCode=' + uc + yyidPart;
      this.headers = [
        { headerKey: 'Access-Token', headerValue: this.webAccessToken },
        { headerKey: 'Unique-Code', headerValue: uc }
      ];
    } else if (this.lx === '6' && this.targetUrl !== '' && !this.targetUrl.startsWith('http')) {
      // (c) LX=6：相对路径前缀服务器域名（APK netconstant.d.d() + getURL()）；
      //     APK 中该前缀仅 h5 直载模式生效（Light L781-784 在 o=h5 分支 / X5 L1604-1607 在 u=h5 分支），
      //     本工程 dispatchApp lx='6' 不入此页，保留为直载兜底分支
      this.targetUrl = Constants.SOCKET_HOST + this.targetUrl;
      this.headers = this.buildAuthHeaders(uc);
    } else {
      // (a) LX=2/4 及缺省：springboard 跳板（APK 非 h5 分支 Light L761 / X5 L1621 —— URL 字段弃用）；
      //     WebView 自动跟随 302 免登链；yyid 空时保留服务端直载 URL + 头 + cookie 兜底
      if (this.yyid !== '') {
        this.targetUrl = Constants.SOCKET_HOST + '/mobileapi_ydxy/api/lapp/springboard?yyid=' + this.yyid;
      }
      this.headers = this.buildAuthHeaders(uc);
    }
    // Cookie 兜底（APK X5 S3() L1852-1859 / Light n3() L863-871 并集：accessToken/uniqueCode/AppType=ydxy；
    // loadUrl 前写入，直载场景 thirdAuth 可从 cookie 取凭据；springboard 场景由服务端 302 自种 ydxy_accessToken）
    if (this.webAccessToken !== '' && this.targetUrl.startsWith('http')) {
      try {
        webview.WebCookieManager.configCookieSync(this.targetUrl, 'accessToken=' + this.webAccessToken);
        webview.WebCookieManager.configCookieSync(this.targetUrl, 'uniqueCode=' + uc);
        webview.WebCookieManager.configCookieSync(this.targetUrl, 'AppType=ydxy');
        this.diag('cookieSeed url=' + this.targetUrl + ' ok, final loadUrl=' + this.targetUrl +
          ' headers=' + JSON.stringify(this.headers) + ' lx=' + this.lx + ' yyid=' + this.yyid);
      } catch {
        // cookie 写入失败不阻断首屏，仍有 header 通道
        this.diag('cookieSeed failed (non-fatal), loadUrl=' + this.targetUrl);
      }
    }
    // 原 7 字段异步 AT 直载实现已被上方 APK 分支矩阵替代（注释溯源）
  }

  /** [R59/R61] 错误态文案：一卡通系列按错误码细分；-7 超时提示 IPv6/DNS 优化已启用 */
  private errorTip(): string {
    const cardYYIDs: string[] = ['ewm', 'yktsy', 'common_ybg_onecard', 'schoolCard', 'gsjg'];
    const isCard: boolean = cardYYIDs.indexOf(this.yyid.toLowerCase()) >= 0;
    if (isCard) {
      if (this.lastErrorCode === -7) {
        return '一卡通服务连接超时\n已启用公共DNS优化解析\n请点击重试，或在 Wi-Fi 与移动网络间切换';
      }
      return '一卡通服务需在校园网内使用\n请连接校园网后重试';
    }
    if (this.lastErrorCode === -7) {
      return '连接超时，请检查网络后重试';
    }
    return '网络异常，请检查网络后重试';
  }

  /** [W1 light-url] 免登头组（Light I2() L745-752 / X5 L1573-1582：AT + Unique-Code + AppType） */
  private buildAuthHeaders(uc: string): HttpHeader[] {
    const list: HttpHeader[] = [
      { headerKey: 'Unique-Code', headerValue: uc },
      { headerKey: 'AppType', headerValue: 'ydxy' }
    ];
    if (this.webAccessToken !== '') {
      list.unshift({ headerKey: 'Access-Token', headerValue: this.webAccessToken });
    }
    return list;
  }

  build() {
    Column() {
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
        .height(this.isCompactHeight ? 38 : 44)
        .padding({ left: this.avoidAreaLeftVp, right: this.avoidAreaRightVp })
        .constraintSize({ maxWidth: BreakpointSystem.getContentMaxWidth(this.currentBreakpoint) })
        .alignItems(VerticalAlign.Center)
      }
      .width('100%')
      .alignItems(HorizontalAlign.Center)
      .backgroundColor($r('app.color.main_bg'))
      .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP])

      Stack() {
        Column() {
          Progress({ value: this.loadProgress, total: 100, type: ProgressType.Linear })
            .width('100%')
            .height(3)
            .color($r('app.color.sdmu_primary'))
            .backgroundColor($r('app.color.common_color_5'))

          if (this.targetUrl === '') {
            // 无 url/yyid（服务端未下发该应用地址）：与源码 Toast 行为一致，提示并返回
            Column() {
              Text('暂无轻应用地址')
                .fontSize(15)
                .fontColor($r('app.color.common_color_3'))
            }
            .width('100%')
            .layoutWeight(1)
            .justifyContent(FlexAlign.Center)
          } else if (this.viewState === 'error') {
            // [R57] 主帧加载失败（如 ERR_TIMED_OUT / 目标站点不可达）：明确错误态 + 重试，
            // 避免 WebView 无限转圈白屏。APK 无对应错误态（X5 内核自带），HAP 补体验兜底。
            Column() {
              Image($r('app.media.mobile_campus_page_error'))
                .width(120)
                .objectFit(ImageFit.Contain)
              Text(this.errorTip())
                .fontSize(14)
                .fontColor($r('app.color.sdmu_text_hint'))
                .textAlign(TextAlign.Center)
                .margin({ top: 12 })
              Text('重试')
                .fontSize(15)
                .fontColor($r('app.color.white'))
                .textAlign(TextAlign.Center)
                .padding({ left: 17, right: 17, top: 3, bottom: 3 })
                .backgroundColor($r('app.color.blue_default'))
                .margin({ top: 16 })
                .onClick(() => {
                  this.loadFailed = false;
                  this.loadProgress = 0;
                  // viewState 切回 'web' 会重建 Web，onControllerAttached 自动 loadUrl（loadFailed 已复位）
                  this.viewState = 'web';
                })
            }
            .width('100%')
            .layoutWeight(1)
            .justifyContent(FlexAlign.Center)
          } else {
            // [W1 light-url] src 置空防裸请求：统一在 onControllerAttached 带免登头加载（springboard 302 链依赖 AT 头）
            // [W6 light-diag] domStorageAccess 开启：taskcenter-v4 等 Vue SPA 依赖 localStorage/sessionStorage，
            // ArkWeb 默认关闭该 API，SPA 启动即抛异常 → 白屏（先排 JS 错误，再看请求链）
            Web({ src: '', controller: this.webController })
              .width('100%')
              .layoutWeight(1)
              .javaScriptAccess(true)
              .domStorageAccess(true)
              .databaseAccess(true)
              .fileAccess(true)
              .imageAccess(true)
              .onlineImageAccess(true)
              .zoomAccess(true)
              .mixedMode(MixedMode.All)
              .cacheMode(CacheMode.Default)
              .onControllerAttached(() => {
                this.webAttached = true;
                // 源码 loadUrl(url, map)：认证头注入
                // [R57] loadFailed=true 时由重试按钮手动 loadUrl，此处不重复加载
                if (!this.loadFailed) {
                  this.diag('controllerAttached, loadUrl=' + this.targetUrl);
                  this.webController.loadUrl(this.targetUrl, this.headers);
                }
              })
              .onLoadIntercept((event: OnLoadInterceptEvent) => {
                // [W6 light-diag] 请求链全量打印（主帧+子资源）：对照 Python probe_lighturl5 逐跳核对
                const req: WebResourceRequest = event.data;
                this.diag('loadIntercept main=' + req.isMainFrame() + ' method=' + req.getRequestMethod() +
                  ' url=' + req.getRequestUrl());
                return false;
              })
              .onPageBegin((event: OnPageBeginEvent) => {
                this.diag('pageBegin url=' + event.url);
              })
              .onProgressChange((event: OnProgressChangeEvent) => {
                this.loadProgress = event.newProgress;
              })
              .onTitleReceive((event: OnTitleReceiveEvent) => {
                this.diag('titleReceive title=' + event.title);
              })
              .onPageEnd((event: OnPageEndEvent) => {
                this.diag('pageEnd url=' + event.url);
                // 源码 funFromjs JS 桥的宿主标题同步（简化：读取 document.title）
              })
              .onErrorReceive((event: OnErrorReceiveEvent) => {
                const reqUrl: string = event.request.getRequestUrl();
                const errCode: number = event.error.getErrorCode();
                const isMain: boolean = event.request.isMainFrame();
                this.diag('errorReceive main=' + isMain + ' url=' + reqUrl +
                  ' code=' + errCode + ' info=' + event.error.getErrorInfo());
                // 仅在主帧发生实质加载失败（排除 302 重定向取消 ERR_ABORTED=-3 及静态子资源）时才进入错误页，
                // 避免毕业报告、督评系统、公寓系统在 302 免登跳转或 favicon/图片加载失败时被误判为“网络异常”。
                const lowerUrl: string = reqUrl.toLowerCase();
                const isSubAsset: boolean = lowerUrl.endsWith('.ico') || lowerUrl.endsWith('.png') ||
                  lowerUrl.endsWith('.jpg') || lowerUrl.endsWith('.jpeg') || lowerUrl.endsWith('.gif') ||
                  lowerUrl.endsWith('.svg') || lowerUrl.endsWith('.woff') || lowerUrl.endsWith('.woff2') ||
                  lowerUrl.endsWith('.ttf') || lowerUrl.endsWith('.css') || lowerUrl.endsWith('.map');
                if (!isMain || errCode === -3 || isSubAsset) {
                  return;
                }
                this.loadFailed = true;
                this.lastErrorCode = errCode;
                this.viewState = 'error';
              })
              .onSslErrorEventReceive((event: OnSslErrorEventReceiveEvent) => {
                // 对齐 Android APK X5LightActivity.onReceivedSslError(handler.proceed())：
                // 校园轻应用（毕业报告、督评系统、公寓系统、财务跳板等）在 302 免登链中可能跳转校内网关或合作域名，
                // 放行 SSL 证书校验以防止白屏或连接中断。
                this.diag('sslError code=' + event.error + ' confirm proceed');
                event.handler.handleConfirm();
              })
              .onHttpErrorReceive((event: OnHttpErrorReceiveEvent) => {
                // [W6 light-diag] HTTP >=400 响应（302 不触发）：CAS/myhall 拒绝时可在此看到
                this.diag('httpError url=' + event.request.getRequestUrl() +
                  ' status=' + event.response.getResponseCode());
              })
              .onConsole((event: OnConsoleEvent) => {
                // [W6 light-diag] JS console 全量透传：SPA 报错（白屏最常见根因）直接落 hilog
                this.diag('console[' + event.message.getMessageLevel() + '] ' + event.message.getMessage());
                return false;
              })
          }
        }
        .width('100%')
        .height('100%')
        .alignItems(HorizontalAlign.Start)

        // [R60] 字号切换按钮（Aa）已移除：APK X5LightActivity L2157-2160 实证该按钮仅
        //   schoolId=="XNZY"（另一所定制学校）时 setVisibility(0)，SDMU 下 XML 默认不可见——
        //   山东管理学院 APK 里此按钮不存在，HAP 无条件渲染属翻译错误，删除对齐源码。
      }
      .width('100%')
      .layoutWeight(1)
      .padding({
        left: this.avoidAreaLeftVp,
        right: this.avoidAreaRightVp,
        bottom: this.avoidAreaBottomVp
      })
      .backgroundColor($r('app.color.main_bg'))
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.main_bg'))
  }
}
