import { router } from '@kit.ArkUI';
import { webview } from '@kit.ArkWeb';
import { ApiService } from '../network/ApiService';
import { ApiResponse } from '../model/ResponseModel';
import { TitleBar } from '../components/TitleBar';
import { LoadingView } from '../components/LoadingView';
import { LoginSession } from '../network/LoginSession';
import { BusinessError } from '@kit.BasicServicesKit';

/**
 * 成绩页 — 1:1 翻译原 APK ScoreMainActivity.java + ScoreMainFragment.java：
 *
 * 【源码结构】成绩页主体 = 3 个 WebView（ECharts H5 图表），按 hasSubject.code 分流：
 *   - chartOne（score_view_top，j）   = SCHOOL + /mobileapi_ydxy/api/avgCheck/chartOne?xn=..&xq=..
 *   - chartTh（score_view_mid，l）   = .../avgCheck/chartTh?xn=..&xq=..（有科目时高度 (code+1)*72vp）
 *   - chartTwo（score_view_bottom，k）= .../avgCheck/chartTwo?xn=..&xq=..
 *   hasSubject.code == 0 → 隐藏 top/mid，chartTwo 全屏（源码 g() 回调 setLayoutParams(-1,-1)）
 *   code > 0 → 三段显示，mid 高度 = (code+1)*72vp
 *
 * 【数据接口】（ScoreModel.java，全部走加密管道）
 *   GET  /mobileapi_ydxy/api/avgCheck/getSemester  → {nowSemester:{XN,XQ}, lastSemester:{XN,XQ}}
 *   POST /mobileapi_ydxy/api/avgCheck/hasSubject {xn,xq} → {code:int}
 *   POST /mobileapi_ydxy/api/avgCheck/getSubScore {subName}
 *
 * 【WebView 认证头】同 LightActivity：Unique-Code=会话UC + AppType=ydxy
 * 【学年学期默认】SDGY 实测 getSemester 返回空对象 → 回退当前学年（源码 TextUtils.isEmpty 分支）
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

  aboutToAppear(): void {
    const uc: string = LoginSession.deviceCode !== '' ? LoginSession.deviceCode : LoginSession.onlyCode;
    this.headers = [
      { headerKey: 'Unique-Code', headerValue: uc },
      { headerKey: 'AppType', headerValue: 'ydxy' }
    ];
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
        this.loadHasSubject();
      })
      .catch((error: BusinessError) => {
        ApiService.logError('Score getSemester fail: ' + error.message);
        this.loadHasSubject();
      });
  }

  /** 源码 ScoreModel.V0：POST hasSubject {xn,xq} → code 分流 */
  private loadHasSubject(): void {
    ApiService.hasSubject(this.xn, this.xq)
      .then((response: ApiResponse<Record<string, Object>>) => {
        if (response.code === 1000) {
          this.getUIContext().getPromptAction().showToast({ message: '登录已失效，请重新登录' });
          router.replaceUrl({ url: 'pages/LoginPage' });
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

  private chartUrl(name: string): string {
    return this.baseUrl + '/' + name + '?xn=' + this.xn + '&xq=' + this.xq;
  }

  @Builder
  chartWeb(controller: webview.WebviewController, url: string, heightVp: number) {
    Web({ src: url, controller: controller })
      .width('100%')
      .height(heightVp)
      .onControllerAttached(() => {
        controller.loadUrl(url, this.headers);
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
          if (this.subjectCode === 0) {
            // 源码：code==0 → chartTwo 全屏
            this.chartWeb(this.webBottomController, this.chartUrl('chartTwo'), 100)
          } else {
            // 源码：三段——top chartOne / mid chartTh（高 (code+1)*72vp）/ bottom chartTwo
            this.chartWeb(this.webTopController, this.chartUrl('chartOne'), 260)
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
              router.pushUrl({ url: 'pages/StudentScorePage', params: { xn: this.xn, xq: this.xq } });
            })
            this.chartWeb(this.webMidController, this.chartUrl('chartTh'), (this.subjectCode + 1) * 72)
            this.chartWeb(this.webBottomController, this.chartUrl('chartTwo'), 320)
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
