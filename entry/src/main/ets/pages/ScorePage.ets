import { router } from '@kit.ArkUI';
import { webview } from '@kit.ArkWeb';
import { ApiService, NewsWebViewHeaders } from '../network/ApiService';
import { ApiResponse } from '../model/ResponseModel';
import { TitleBar } from '../components/TitleBar';
import { LoadingView } from '../components/LoadingView';
import { BusinessError } from '@kit.BasicServicesKit';

/**
 * 成绩页 — 1:1 翻译原 APK ScoreMainFragment.java：
 *
 * 【源码结构】成绩页主体 = 3 个 WebView（ECharts H5 图表），按 hasSubject.code 分流：
 *   - chartOne（score_view_top，j）   = SCHOOL + /mobileapi_ydxy/api/avgCheck/chartOne?xn=..&xq=..
 *   - chartTh（score_view_mid，l）   = .../avgCheck/chartTh?xn=..&xq=..（有科目时高度 (code+1)*72vp）
 *   - chartTwo（score_view_bottom，k）= .../avgCheck/chartTwo?xn=..&xq=..
 *   hasSubject.code == 0 → 隐藏 top/mid，chartTwo 全屏（源码 g() 回调 setLayoutParams(-1,-1)）
 *   code > 0 → 三段显示，mid 高度 = (code+1)*72vp
 *
 * 【WebView 请求形态】（WebViewFragment.java N1():104-120 实测定案 2026-11-17）：
 *   - URL 明文 query：chartXxx?xn=<学年>&xq=<学期>（U1() 直接字符串拼接，无 data= 加密）
 *   - Access-Token = AES-ECB( Base64 JSON {"sessionKey","userId","userType","xxdm"}, 协商key )
 *     （M1() 仅填四字段，clientVersion/deviceId/deviceModel 为 null 被 Gson 省略；
 *      key = d.a.e(null,false) = Hawk randomBase64AESKey = 协商产物 LoginSession.aesKey）
 *   - Unique-Code = d.a.d() = Hawk onlyCode（协商响应解密产物；实测用 deviceCode 必现
 *     {"code":"0006","msg":"解密数据出错"} —— 服务器按 UC 索引协商密钥）
 *   - AppType = "ydxy"（APK 携带；实测缺失也可 200，保留以贴合源码）
 *   - 无 Cookie、无 UA 特殊化、URL 参数不加密
 *
 * 【数据接口】（ScoreModel.java，走加密管道）
 *   GET  /mobileapi_ydxy/api/avgCheck/getSemester  → {nowSemester:{XN,XQ}, lastSemester:{XN,XQ}}
 *   POST /mobileapi_ydxy/api/avgCheck/hasSubject {xn,xq} → {code:int}
 *
 * 【学年学期默认】SDGY 实测 getSemester 返回空对象 → 回退当前学年（源码 TextUtils.isEmpty 分支）
 *
 * 【W2 验收修订 2026-11-17】reviewer：chartUrlsReady 增加 semesterReady 双闸，
 * 保证 Web 挂载时 xn/xq 已是最终值（onControllerAttached 仅触发一次）。
 */
interface HttpHeader {
  headerKey: string;
  headerValue: string;
}

@Entry
@Component
struct ScorePage {
  private webTopController: webview.WebviewController = new webview.WebviewController();
  private webMidController: webview.WebviewController = new webview.WebviewController();
  private webBottomController: webview.WebviewController = new webview.WebviewController();
  @State isLoading: boolean = true;
  @State xn: string = '2025-2026';
  @State xq: string = '1';
  /** 源码 hasSubject.code：0=纯图表全屏；>0=三段 WebView */
  @State subjectCode: number = 0;
  @State headers: HttpHeader[] = [];
  @State baseUrl: string = 'http://mcp.sdmu.edu.cn:8081/mobileapi_ydxy/api/avgCheck';
  @State chartUrlTop: string = '';
  @State chartUrlMid: string = '';
  @State chartUrlBottom: string = '';
  /** headers 就绪后才允许渲染 Web（APK N1()：strE 为空直接 return 不加载） */
  @State headersReady: boolean = false;
  /** 学期参数就绪（getSemester 回包或失败回退）后才放行 Web，防 headers 先到时
   * Web 用默认学期加载、后续 URL 重建不触发重载 → 学期错位 */
  @State semesterReady: boolean = false;
  @State chartUrlsReady: boolean = false;

  aboutToAppear(): void {
    // 源码 N1(): strE=d.a.e(null,false)；M1() 四字段 token；UC=d.a.d()=onlyCode；AppType=ydxy
    ApiService.getNewsPageWebViewHeaders()
      .then((headers: NewsWebViewHeaders | null) => {
        if (headers === null) {
          // APK N1() strE 为空 → return 不加载；会话未协商 → 登录页重取
          this.getUIContext().getPromptAction().showToast({ message: '登录已失效，请重新登录' });
          router.replaceUrl({ url: 'pages/LoginPage' });
          return;
        }
        this.headers = [
          { headerKey: 'Access-Token', headerValue: headers.accessToken },
          { headerKey: 'Unique-Code', headerValue: headers.uniqueCode },
          { headerKey: 'AppType', headerValue: 'ydxy' }
        ];
        this.headersReady = true;
        this.rebuildChartUrls();
      })
      .catch((error: BusinessError) => {
        ApiService.logError('Score chart headers fail: ' + error.message);
      });
    this.loadSemester();
  }

  /** 源码 ScoreModel.T0：GET getSemester → nowSemester.XN/XQ（空则回退默认） */
  private loadSemester(): void {
    ApiService.getSemester()
      .then((response: ApiResponse<Record<string, Object>>) => {
        if (response.code === 0 && response.data) {
          const now = response.data['nowSemester'] as Record<string, Object> | undefined;
          if (now) {
            const xn = now['XN'];
            const xq = now['XQ'];
            if (typeof xn === 'string' && xn !== '') {
              this.xn = xn;
            }
            if (typeof xq === 'string' && xq !== '') {
              this.xq = xq;
            }
          }
        }
        // 学期参数就绪后重建 URL（headers 后到时由 then 链兜底重建）
        this.semesterReady = true;
        this.rebuildChartUrls();
        this.loadHasSubject();
      })
      .catch((error: BusinessError) => {
        ApiService.logError('Score getSemester fail: ' + error.message);
        // 失败也放行：回退默认学年学期（源码 TextUtils.isEmpty 分支）
        this.semesterReady = true;
        this.rebuildChartUrls();
        this.loadHasSubject();
      });
  }

  /** 源码 ScoreModel.V0：POST hasSubject {xn,xq} → code 分流 */
  private loadHasSubject(): void {
    ApiService.hasSubject(this.xn, this.xq)
      .then((response: ApiResponse<Record<string, Object>>) => {
        if (response.code === 1000) {
          // 登录失效统一处理已在网络层触发（HttpClient.bizRequest 拦截：清会话+toast+跳登录）
          return;
        }
        if (response.code === 0 && response.data) {
          const code = response.data['code'];
          this.subjectCode = typeof code === 'number' ? code : Number(code);
        }
        this.isLoading = false;
      })
      .catch((error: BusinessError) => {
        ApiService.logError('Score hasSubject fail: ' + error.message);
        this.isLoading = false;
      });
  }

  /** 源码 U1()+a.g()：URL 明文 query（xn=..&xq=.. 直接拼接，无加密参数）；
   * headers 与学期参数双就绪才放行渲染（Web 只挂载一次，onControllerAttached
   * 只触发一次，故必须保证挂载时 xn/xq 已是最终值） */
  private rebuildChartUrls(): void {
    this.chartUrlTop = this.baseUrl + '/chartOne?xn=' + this.xn + '&xq=' + this.xq;
    this.chartUrlMid = this.baseUrl + '/chartTh?xn=' + this.xn + '&xq=' + this.xq;
    this.chartUrlBottom = this.baseUrl + '/chartTwo?xn=' + this.xn + '&xq=' + this.xq;
    this.chartUrlsReady = this.headersReady && this.semesterReady;
  }

  /** 源码 WebViewFragment.N1():119 loadUrl(url, map)：
   * src 置 about:blank 防无头首载竞态，onControllerAttached 带认证头加载（NewsPage 同款实证模式） */
  @Builder
  chartWeb(controller: webview.WebviewController, url: string, heightSpec: Length) {
    Web({ src: 'about:blank', controller: controller })
      .width('100%')
      .height(heightSpec)
      .onControllerAttached(() => {
        ApiService.logError('ScoreChart attached, pending url=' + url);
      })
      .onLoadIntercept((event) => {
        ApiService.logError('ScoreChart request: ' + event.data.getRequestUrl());
        return false;
      })
      .onPageEnd((event: OnPageEndEvent) => {
        ApiService.logError('ScoreChart onPageEnd: ' + event.url);
        // about:blank 首载完成后再带头发起真实请求（attach 时立即 loadUrl 会被首载吞掉）
        if (event.url === 'about:blank' && this.headersReady && this.chartUrlsReady) {
          controller.loadUrl(url, this.headers);
        }
      })
      .onErrorReceive((event: OnErrorReceiveEvent) => {
        ApiService.logError('ScoreChart onError: ' + event.error.getErrorInfo());
        return false;
      })
      .javaScriptAccess(true)
      .domStorageAccess(true)
  }

  build() {
    Column() {
      TitleBar({ title: '我的成绩', showBack: true })

      if (this.isLoading) {
        LoadingView()
      } else {
        Column() {
          if (!this.chartUrlsReady) {
            LoadingView()
          } else if (this.subjectCode === 0) {
            // 源码：code==0 → chartTwo 全屏（setLayoutParams(-1,-1)=MATCH_PARENT → '100%'）
            this.chartWeb(this.webBottomController, this.chartUrlBottom, '100%')
          } else {
            // 源码：三段——top chartOne / mid chartTh（高 (code+1)*72vp）/ bottom chartTwo
            this.chartWeb(this.webTopController, this.chartUrlTop, 260)
            Row() {
              Text('查看学生具体成绩')
                .fontSize(16)
                .fontColor($r('app.color.sdmu_primary'))
                .padding(12)
                .layoutWeight(1)
            }
            .width('100%')
            .backgroundColor($r('app.color.white'))
            .onClick(() => {
              // 源码链：ScoreMainActivity → Q0(/score/studentList)=StudentListActivity（PARAMS=xn_xq[,xn_xq]）
              // → 班级页签 → 点学生 → StudentScoreActivity{studentName,studentId}（HAP StudentScorePage）
              // [W27 final-a] StudentListPage 已源码级落地，按源码入口传 PARAMS。
              router.pushUrl({
                url: 'pages/StudentListPage',
                params: { 'PARAMS': this.xn + '_' + this.xq } as Record<string, Object>
              });
            })
            this.chartWeb(this.webMidController, this.chartUrlMid, (this.subjectCode + 1) * 72)
            this.chartWeb(this.webBottomController, this.chartUrlBottom, 320)
          }
        }
        .width('100%')
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.main_bg'))
  }
}
