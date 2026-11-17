import { router } from '@kit.ArkUI';
import { webview } from '@kit.ArkWeb';
import { connection } from '@kit.NetworkKit';
import { geoLocationManager } from '@kit.LocationKit';
import { abilityAccessCtrl, common, PermissionRequestResult, Want } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { ApiService, NewsWebViewHeaders } from '../network/ApiService';
import { Constants } from '../data/Constants';
import { LoadingView } from '../components/LoadingView';

/**
 * 新闻页（资讯 Tab）— 1:1 翻译原 APK NewsFragment.java(1212行)：
 *
 * 【页面结构】mobile_campus_fragment_news.xml：
 *   LinearLayout(llLayout, bg=@color/mobile_campus_bg_color)
 *   - RelativeLayout(白底 45vp)：ivBack(70×45vp padT/B12 icon_back_black invisible↔visible)
 *     + TextView("资讯" 18sp common_color_1 全宽居中) + ivRefresh(icon_refresh_black padL/R15 T/B12)
 *   - MultiStateView(apppage_light_app_state, bg=@color/main_bg; msv_empty/error/loading)
 *     - ProgressBar(3vp max=100 progressDrawable=mobile_campus_progress: 白底+主题红进度)
 *     - WebView(mWebView, weight=1, 白底)
 *
 * 【加载链源码还原】NewsFragment.K1()(:831-890)：
 *   1. d2()(:905)：GNYX 学校特判 + SystemSwitch.cleanData.clean_yyids 含 yyid 时清 Cookie/缓存；
 *      本应用 schoolId=SDGY≠GNYX 且 clean_yyids 对 bodaNews 无下发 → 循环体不执行（no-op）；
 *      g2()(:943) 恒 false → removeAllCookie/clearCache 分支同样短路。
 *   2. s.o(application) 网络检查失败 → t0(this.r, CampusPage.ERROR_NETWORK) 错误态。
 *   3. v(this.r) → MultiStateView loading 态。
 *   4. strE = d.a.e(null,false) = Hawk "randomBase64AESKey"（协商 AES key）→ LoginSession.aesKey；
 *      为空 → B1(this.r) 非内容态（会话未协商）。
 *   5. headers = { Access-Token: BaseSecretUtil.i(e2().get("Access-Token"), strE)（AES 加密）,
 *                  Unique-Code: d.a.d() }（ApiService.getNewsPageWebViewHeaders 1:1 还原）。
 *   6. isH5=false（MainActivity.f1():1393 h2(json,false)）→ loadUrl(s.g("lapp/springboard")
 *      + "?yyid=" + j.getYYID(), map)；yyid="bodaNews"（MainActivity.f1():1392）。
 *      isH5=true 分支（i2 cookie 注入/leavingSchool 直载/LX=6 拼前缀）在本页唯一入口恒 false，未平移。
 *
 * 【WebViewClient】NewsFragment$3$c + X5YBGWebViewClient + X5CommonWebViewClient：
 *   shouldOverrideUrlLoading：lianyi:///tmast 拦截；alipay/bankabc/weixin://wap/pay 跳外部
 *   （无客户端提示）；m.amap.com/map.baidu.com 继续加载；tel: 拨号；sms: 短信；
 *   /seeyon/rest/attachment/file/ 拦截；其余放行。
 *   onReceivedError（主文档）→ 非内容态；onPageFinished → canGoBack ? 显示 ivBack : invisible。
 * 【WebChromeClient】$3$b：onProgressChanged(进度条 100 隐藏)；onGeolocationPermissionsShowPrompt
 *   权限通过后 invoke(origin,true,true)；onShowFileChooser 系统文件选择。
 * 【JS 桥】c2():902 addJavascriptInterface(AnonymousClass6, "ybgLightApp")：
 *   定位回调 funFromjs(addr,lat,lng,s.f(context))；closeWindow/signInSuccess 空实现；
 *   commitShare/JsUpdateBadgeNum(EventBus 18) 日志；selectPicture/Video/File、record* 为
 *   Android Intent/MediaRecorder 特有流程（HAP 容器记录日志，未接原生选择器）。
 */

/**
 * AnonymousClass6（NewsFragment$6 extends X5LocateJsInteration）→ H5 注入名 "ybgLightApp"。
 * 宿主能力经构造注入（openBrowser/startAbility、定位回调、toast、日志）。
 */
class YbgLightAppJsBridge {
  private logFn: (msg: string) => void;
  private toastFn: (msg: string) => void;
  private openBrowserFn: (url: string) => void;
  private locateFn: () => void;

  constructor(logFn: (msg: string) => void, toastFn: (msg: string) => void,
    openBrowserFn: (url: string) => void, locateFn: () => void) {
    this.logFn = logFn;
    this.toastFn = toastFn;
    this.openBrowserFn = openBrowserFn;
    this.locateFn = locateFn;
  }

  /** 源码 :377 closeWindow：空实现 */
  closeWindow(): void {
  }

  /** 源码 :433 signInSuccess：空实现 */
  signInSuccess(): void {
  }

  /** 源码 :382 commitShare：m.a("commitShare", str) 日志 */
  commitShare(shareData: string): void {
    this.logFn('commitShare ' + shareData);
  }

  /** 源码 :354 JsUpdateBadgeNum：EventBus f.a(18,null) 主界面角标刷新（HAP 宿主未接，记录日志） */
  JsUpdateBadgeNum(): void {
    this.logFn('JsUpdateBadgeNum: EventBus 18 badge refresh (host not wired)');
  }

  /** 源码 :388 openBrowser：ACTION_VIEW 外部浏览器 */
  openBrowser(url: string): void {
    this.openBrowserFn(url);
  }

  /** 源码 :360 clickOnAndroid：权限检查后高德定位回调（HAP 走系统能力等价实现） */
  clickOnAndroid(): void {
    this.locateFn();
  }

  /** 源码 :371 clickOnAndroidSystem：系统 GPS + 逆地理回调（HAP 走系统能力等价实现） */
  clickOnAndroidSystem(): void {
    this.locateFn();
  }

  /** 源码 :397 record：RECORD_SOUND 录音入口（Android Intent 特有，HAP 记录日志） */
  record(): void {
    this.logFn('record: RECORD_SOUND intent (not wired)');
  }

  /** 源码 :409 recordStart：MediaRecorder 启动（Android 特有，HAP 记录日志） */
  recordStart(): void {
    this.logFn('recordStart: MediaRecorder start (not wired)');
  }

  /** 源码 :403 recordEnd：录音 base64 回传 getLocalFileData（Android 特有，HAP 记录日志） */
  recordEnd(): void {
    this.logFn('recordEnd: audio base64 callback (not wired)');
  }

  /** 源码 :421 selectPicture：GET_CONTENT image（Android 特有，HAP 记录日志） */
  selectPicture(): void {
    this.logFn('selectPicture: GET_CONTENT image (not wired)');
  }

  /** 源码 :427 selectVideo：GET_CONTENT audio/video（Android 特有，HAP 记录日志） */
  selectVideo(): void {
    this.logFn('selectVideo: GET_CONTENT audio/video (not wired)');
  }

  /** 源码 :415 selectFile：GET_CONTENT application（Android 特有，HAP 记录日志） */
  selectFile(): void {
    this.logFn('selectFile: GET_CONTENT application (not wired)');
  }
}

@Entry
@Component
struct NewsPage {
  private webController: webview.WebviewController = new webview.WebviewController();
  @State loadProgress: number = 0;
  @State showProgress: boolean = false;
  @State pageState: string = 'loading';
  @State showBack: boolean = false;
  @State errorMsg: string = '';
  private targetUrl: string = '';
  private jsBridge: YbgLightAppJsBridge = new YbgLightAppJsBridge(
    (msg: string) => {
      hilog.info(0x0000, 'SDMU', 'news %{public}s', msg);
    },
    (tip: string) => {
      this.toast(tip);
    },
    (url: string) => {
      this.openExternal(url, '未找到可打开的应用');
    },
    () => {
      this.fetchLocation();
    });

  aboutToAppear(): void {
    // 源码 K1():865 加载地址：s.g("lapp/springboard") + "?yyid=" + j.getYYID()
    this.targetUrl = ApiService.buildNewsPageUrl();
  }

  private logBridge(msg: string): void {
    hilog.info(0x0000, 'SDMU', 'news %{public}s', msg);
  }

  // ===== 源码 m(str)：Toast =====
  private toast(message: string): void {
    if (message === '') {
      return;
    }
    this.getUIContext().getPromptAction().showToast({ message: message });
  }

  // ===== 源码 K1():831-890 主加载链（f1():1102 初次 + ivRefresh class d 重载） =====
  private startLoadNews(): void {
    // d2():905 GNYX 特判 + clean_yyids 清缓存：本应用 schoolId=SDGY≠GNYX 且 clean_yyids
    // 未下发 bodaNews → 循环体不执行（no-op）；g2():943 恒 false 同样短路清缓存分支。
    if (!connection.hasDefaultNetSync()) {
      // K1:839-841 s.o() 失败 → t0(this.r, CampusPage.ERROR_NETWORK)
      this.applyError('网络连接失败，请检查网络设置');
      return;
    }
    // K1:843 v(this.r) → MultiStateView loading
    this.pageState = 'loading';
    ApiService.getNewsPageWebViewHeaders()
      .then((headers: NewsWebViewHeaders | null) => {
        if (headers === null) {
          // K1:846-848 strE(randomBase64AESKey) 为空 → B1(this.r)：会话未协商 → 跳登录重取
          this.onSessionExpired();
          return;
        }
        // K1:865 loadUrl(s.g("lapp/springboard") + "?yyid=" + j.getYYID(), map)
        const headersArr: webview.WebHeader[] = [
          { headerKey: 'Access-Token', headerValue: headers.accessToken },
          { headerKey: 'Unique-Code', headerValue: headers.uniqueCode }
        ];
        this.webController.loadUrl(this.targetUrl, headersArr);
      })
      .catch((error: BusinessError) => {
        ApiService.logError('news load fail: ' + error.message);
        this.applyError('页面加载失败，请点击重试');
      });
  }

  // ===== 源码 MultiStateView 错误态（onReceivedError t0/B1/D1 系列方法） =====
  private applyError(message: string): void {
    this.errorMsg = message;
    this.showProgress = false;
    this.pageState = 'error';
  }

  /** 源码 code=1000/会话缺失 →"登录已失效，请重新登录" + 跳登录页（TodoPage/PersonalDetail 样板） */
  private onSessionExpired(): void {
    this.applyError('登录已失效，请重新登录');
    this.getUIContext().getPromptAction().showToast({ message: '登录已失效，请重新登录' });
    router.replaceUrl({ url: 'pages/LoginPage' });
  }

  /**
   * 源码 X5YBGWebViewClient.shouldOverrideUrlLoading(:42) + NewsFragment$3$c(:748) 全链：
   * 返回 true 拦截（外跳/拨号/短信/seeyon 附件），false 放行（Web 容器继续加载）。
   */
  private handleLoadIntercept(url: string): boolean {
    // X5YBGWebViewClient:43-45 lianyi:// / tmast 拦截
    if (url.startsWith('lianyi://') || url.startsWith('tmast')) {
      return true;
    }
    // X5YBGWebViewClient:46-53 alipay 系 → 外部打开（无客户端提示"未检测到支付宝客户端"）
    if (url.startsWith('alipays:') || url.startsWith('alipay')) {
      this.openExternal(url, '未检测到支付宝客户端，请安装后重试');
      return true;
    }
    // X5YBGWebViewClient:54-65 bankabc / weixin://wap/pay → 外部打开（无客户端 toast"请先安装应用"）
    if (url.startsWith('bankabc://') || url.startsWith('weixin://wap/pay?')) {
      this.openExternal(url, '请先安装应用');
      return true;
    }
    // NewsFragment$3$c:749-752 m.amap.com / map.baidu.com → 继续加载
    if (url.indexOf('m.amap.com') >= 0 || url.indexOf('map.baidu.com') >= 0) {
      return false;
    }
    // $3$c:753-759 SCHEME_TEL("tel:") → 拨号盘（号码截取与源码一致）
    if (url.indexOf('tel:') >= 0) {
      this.dialTel(url);
      return true;
    }
    // $3$c:761-766 不含 sms: → /seeyon/rest/attachment/file/ 拦截，其余 super（放行）
    if (url.indexOf('sms:') < 0) {
      return url.indexOf('/seeyon/rest/attachment/file/') >= 0;
    }
    // $3$c:767-769 sms: → 短信
    this.sendSms(url);
    return true;
  }

  /** 源码 openBrowser(:388)/alipay/bank/weixin：ACTION_VIEW 外部打开，失败提示 failTip */
  private openExternal(url: string, failTip: string): void {
    const ctx = this.getUIContext().getHostContext() as common.UIAbilityContext;
    const want: Want = { action: 'ohos.want.action.viewData', uri: url };
    ctx.startAbility(want).catch((error: BusinessError) => {
      this.logBridge('openExternal fail: ' + error.message);
      this.toast(failTip);
    });
  }

  /** 源码 $3$c:753-759 ACTION_DIAL Uri.fromParts("tel", 号码)；号码 = lastIndexOf("/")+1 截取 */
  private dialTel(raw: string): void {
    let number: string = raw.substring(raw.lastIndexOf('/') + 1);
    if (number.indexOf('tel:') === 0) {
      number = number.substring(4);
    }
    const ctx = this.getUIContext().getHostContext() as common.UIAbilityContext;
    const want: Want = { action: 'ohos.want.action.dial', uri: 'tel:' + number };
    ctx.startAbility(want).catch((error: BusinessError) => {
      this.logBridge('dial fail: ' + error.message);
    });
  }

  /** 源码 $3$c:767-769 d0.c(context, 号码)：短信发送界面 */
  private sendSms(raw: string): void {
    let number: string = raw.substring(raw.lastIndexOf('/') + 1);
    if (number.indexOf('sms:') === 0) {
      number = number.substring(4);
    }
    const ctx = this.getUIContext().getHostContext() as common.UIAbilityContext;
    const want: Want = { action: 'ohos.want.action.sendData', uri: 'sms:' + number };
    ctx.startAbility(want).catch((error: BusinessError) => {
      this.logBridge('sms fail: ' + error.message);
    });
  }

  /**
   * 源码 AnonymousClass6.clickOnAndroid(:360)/clickOnAndroidSystem(:371) → O0(权限) → 定位回调。
   * HAP：LOCATION/APPROXIMATELY_LOCATION 权限已在 module.json5 声明，此处动态申请后系统定位。
   */
  private fetchLocation(): void {
    const ctx = this.getUIContext().getHostContext() as common.UIAbilityContext;
    const atManager: abilityAccessCtrl.AtManager = abilityAccessCtrl.createAtManager();
    atManager.requestPermissionsFromUser(ctx,
      ['ohos.permission.LOCATION', 'ohos.permission.APPROXIMATELY_LOCATION'])
      .then((result: PermissionRequestResult) => {
        if (result.authResults.length > 0 && result.authResults[0] === 0) {
          this.getCurrentLocation();
        } else {
          // 源码定位失败 m("获取经纬度出错，请重试1")
          this.toast('获取经纬度出错，请重试');
        }
      })
      .catch((error: BusinessError) => {
        ApiService.logError('news perm fail: ' + error.message);
        this.toast('获取经纬度出错，请重试');
      });
  }

  /** 源码 $6$b$a 高德定位成功回调 / $6$c 系统 GPS：成功后逆地理 → funFromjs 回调 */
  private getCurrentLocation(): void {
    geoLocationManager.getCurrentLocation()
      .then((loc: geoLocationManager.Location) => {
        this.reverseGeocode(loc.latitude, loc.longitude);
      })
      .catch((error: BusinessError) => {
        ApiService.logError('news locate fail: ' + error.message);
        this.toast('获取经纬度出错，请重试');
      });
  }

  /** 源码 $6$c$b + v.e(坐标) 高德逆地理：HAP getAddressesFromLocation 等价实现 */
  private reverseGeocode(lat: number, lng: number): void {
    const req: geoLocationManager.ReverseGeoCodeRequest =
      { latitude: lat, longitude: lng, maxItems: 1 };
    geoLocationManager.getAddressesFromLocation(req)
      .then((addrs: Array<geoLocationManager.GeoAddress>) => {
        // GeoAddress.placeName = 详细地址（对应高德 AddressEntity.getAddr 语义）；
        // 无 placeName 时退回 descriptions[0]（附加描述）
        let addr: string = '';
        if (addrs.length > 0 && addrs[0].placeName !== undefined && addrs[0].placeName !== '') {
          addr = addrs[0].placeName as string;
        } else if (addrs.length > 0 && addrs[0].descriptions !== undefined &&
          addrs[0].descriptions.length > 0) {
          addr = addrs[0].descriptions[0];
        }
        this.postFunFromjs(addr, lat, lng);
      })
      .catch((error: BusinessError) => {
        // 源码 $6$c$b$a$f 逆地理失败仅日志，坐标仍按空地址回调
        ApiService.logError('news geocode fail: ' + error.message);
        this.postFunFromjs('', lat, lng);
      });
  }

  /** 源码 $6$b$a RunnableC0390a:134 javascript:funFromjs('%s','%f','%f','%s')
   *  （addr, 纬度, 经度, s.f(context)=设备标识 → HAP 取 DEVICE_ID 同语义）
   */
  private postFunFromjs(addr: string, lat: number, lng: number): void {
    const js: string = "javascript:funFromjs('" + addr + "','" + lat.toFixed(6) + "','" +
      lng.toFixed(6) + "','" + Constants.DEVICE_ID + "')";
    this.webController.loadUrl(js);
  }

  // ===== mobile_campus_fragment_news.xml 顶部 RelativeLayout（白底 45vp） =====
  @Builder
  titleBar() {
    Stack({ alignContent: Alignment.Center }) {
      // TextView "资讯"：textSize=18sp、textColor=common_color_1、gravity=center、fill_parent
      Text('资讯')
        .fontSize(18)
        .fontColor($r('app.color.common_color_1'))
        .textAlign(TextAlign.Center)
        .width('100%')
        .height(45)
      // 操作层：ivBack alignParentLeft（70×45dip padT/B12）+ ivRefresh alignParentRight（padL/R15 T/B12）
      Row() {
        Image($r('app.media.icon_back_black'))
          .width(70)
          .height(45)
          .padding({ top: 12, bottom: 12 })
          .objectFit(ImageFit.Contain)
          .visibility(this.showBack ? Visibility.Visible : Visibility.Hidden)
          .onClick(() => {
            // 源码 class e(:788)：ivBack → i.goBack()
            this.webController.backward();
          })
        Blank()
        Image($r('app.media.icon_refresh_black'))
          .height(45)
          .padding({ left: 15, top: 12, right: 15, bottom: 12 })
          .objectFit(ImageFit.Contain)
          .onClick(() => {
            // 源码 class d(:778)：ivRefresh → K1() 完整重载（含 headers）
            this.startLoadNews();
          })
      }
      .width('100%')
      .height(45)
      .alignItems(VerticalAlign.Center)
    }
    .width('100%')
    .height(45)
    .alignContent(Alignment.Center)
    .backgroundColor($r('app.color.white'))
  }

  build() {
    // llLayout：vertical、bg=mobile_campus_bg_color、fill_parent
    Column() {
      this.titleBar()
      // MultiStateView：bg=main_bg，四态容器（loading/error 覆盖 + progressBar + WebView）
      Stack() {
        Column() {
          // progressBar：3dip、max=100、progressDrawable 白底+主题红（onProgressChanged 控制）
          if (this.showProgress) {
            Progress({ value: this.loadProgress, total: 100, type: ProgressType.Linear })
              .width('100%')
              .height(3)
              .color($r('app.color.mobile_campus_primary_color'))
              .backgroundColor($r('app.color.white'))
          }
          Web({ src: 'about:blank', controller: this.webController })
            .width('100%')
            .layoutWeight(1)
            .backgroundColor($r('app.color.white'))
            .javaScriptAccess(true)                     // f1():1068 setJavaScriptEnabled(true)
            .fileAccess(true)                           // f1():1071 setAllowFileAccess(true)
            .mixedMode(MixedMode.All)                  // f1():1075/1097 setMixedContentMode(0)=ALWAYS_ALLOW
            .domStorageAccess(true)                     // f1():1090 setDomStorageEnabled(true)
            .mediaPlayGestureAccess(false)              // f1():1091 setMediaPlaybackRequiresUserGesture(false)
            .verticalScrollBarAccess(false)             // f1():1092 setVerticalScrollBarEnabled(false)
            .textZoomAtio(100)                          // f1():1095 setTextZoom(100)
            .cacheMode(CacheMode.Online)                // f1():1087 setCacheMode(2)=LOAD_NO_CACHE（不读缓存）
            .geolocationAccess(true)                    // f1():1088 setGeolocationEnabled(true)
            .zoomAccess(false)                          // j2():988 bodaNews 不在 zoom 名单 → setSupportZoom(false)
            .onControllerAttached(() => {
              // 源码 f1():1102 配置完成后 K1() 首次加载
              this.startLoadNews();
            })
            .javaScriptProxy({
              // 源码 c2():902 addJavascriptInterface(AnonymousClass6, "ybgLightApp")
              name: 'ybgLightApp',
              object: this.jsBridge,
              methodList: ['closeWindow', 'signInSuccess', 'commitShare', 'JsUpdateBadgeNum',
                'openBrowser', 'clickOnAndroid', 'clickOnAndroidSystem', 'record', 'recordStart',
                'recordEnd', 'selectPicture', 'selectVideo', 'selectFile'],
              controller: this.webController
            })
            .onLoadIntercept((event: OnLoadInterceptEvent) => {
              // 源码 shouldOverrideUrlLoading 全链（X5YBG 父类 + $3$c 子类）
              return this.handleLoadIntercept(event.data.getRequestUrl());
            })
            .onProgressChange((event: OnProgressChangeEvent) => {
              // 源码 $3$b.onProgressChanged:635-645：==100 隐藏，否则显示并 setProgress
              this.loadProgress = event.newProgress;
              this.showProgress = event.newProgress < 100;
              if (this.pageState === 'loading' && event.newProgress > 0) {
                this.pageState = 'content';
              }
            })
            .onPageBegin(() => {
              // 源码 $3$c.onPageStarted:701（无操作）；HAP 侧退出 MultiStateView loading 覆盖
              if (this.pageState === 'loading') {
                this.pageState = 'content';
              }
            })
            .onPageEnd(() => {
              // 源码 $3$c.onPageFinished:693：canGoBack ? VISIBLE : INVISIBLE(ivBack)
              this.showBack = this.webController.accessBackward();
            })
            .onErrorReceive((event: OnErrorReceiveEvent) => {
              // 源码 $3$c.onReceivedError:706-745：主文档错误 → 非内容态（错误视图）
              if (event.request.isMainFrame()) {
                this.applyError('页面加载失败，请点击重试');
              }
            })
            .onGeolocationShow((event: OnGeolocationShowEvent) => {
              // 源码 $3$b.onGeolocationPermissionsShowPrompt:614-616 → 权限通过 invoke(origin,true,true)
              event.geolocation.invoke(event.origin, true, true);
            })
            .onShowFileSelector((event: OnShowFileSelectorEvent): boolean => {
              // 源码 $3$b.onShowFileChooser:653 系统文件选择（新闻 H5 未用上传，取消语义）
              event.result.handleFileList([]);
              return true;
            })
        }
        .width('100%')
        .height('100%')
        .alignItems(HorizontalAlign.Start)

        // MultiStateView loadingView（loading_light_view）
        if (this.pageState === 'loading') {
          Column() {
            LoadingView()
          }
          .width('100%')
          .height('100%')
          .backgroundColor($r('app.color.main_bg'))
        }
        // MultiStateView errorView（error_view + 重试 = K1() 重载语义）
        if (this.pageState === 'error') {
          Column({ space: 12 }) {
            Text(this.errorMsg)
              .fontSize(14)
              .fontColor($r('app.color.common_color_3'))
              .textAlign(TextAlign.Center)
            Text('点击重试')
              .fontSize(14)
              .fontColor($r('app.color.sdmu_primary'))
          }
          .width('100%')
          .height('100%')
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)
          .backgroundColor($r('app.color.main_bg'))
          .onClick(() => {
            this.startLoadNews();
          })
        }
      }
      .width('100%')
      .layoutWeight(1)
      .backgroundColor($r('app.color.main_bg'))
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.mobile_campus_bg_color'))
  }
}
