import { router } from '@kit.ArkUI';
import { BusinessError } from '@kit.BasicServicesKit';
import { TitleBar } from '../components/TitleBar';
import { ApiService } from '../network/ApiService';
import { LoginSession } from '../network/LoginSession';
import { ApiResponse } from '../model/ResponseModel';
import { BreakpointSystem } from '../common/BreakpointSystem';

/**
 * 扫码登录页 — 1:1 复刻 ScanLoginActivity（180 行）+ mobile_campus_activity_scan_login.xml
 * [W22 launch-chain] 源码级翻译：
 *   布局：toolbar_normal（H0()=null → 标题空）+ MultiStateView(content)：LinearLayout
 *   center_vertical：ll_content（插图 mobile_campus_scan_login + "扫码登录" 16fp mt36dip=18vp
 *   + tv_account 16fp ybg_blue mt12dip=6vp）+ tvSubmit 184x40dip marginH/L px_to_dip_24=12vp
 *   marginTB 20dip=10vp，bg mobile_campus_schedule_selector_confirm，文案"确认登录"（px_to_sp_32=16fp）。
 *   y(Intent)：l = extra "result"（扫得的二维码内容，MainActivity L1523/MainFragment L444 分发：
 *     JSON 含 type 且不含 app_id → 本页）。
 *   f1()：tvSubmit/ll_content 先隐藏；l 空 → toast"扫描出错"（页留原状）；
 *     含 login.weixin.qq.com → 未装微信 toast"你暂未安装微信哦"（已装则拉起微信并 finish ——
 *     HAP 无跨应用拉起能力，等价固定走未安装分支，保真注释）；
 *     含 txz.qq.com → "你暂未安装QQ哦"；含 m.tb.cn → "你暂未安装淘宝哦"；
 *     否则：ll_content 可见 + tv_account = userName + "  " + userId + tvSubmit 可见。
 *   M2()：ScanLoginPImpl.k(cb).g(l) → ScanLoginModel.V0：GET /api/scan/index {url=l}
 *     （2026-11-18 探针实测假 url code=1"暂不支持"——端点/协议真实）；g → finish；f → toast message。
 *   onDestroy：dVar.f()（回调置空防泄漏，HAP 无需）。
 */
@Entry
@Component
struct ScanLoginPage {
  /** intent "result"（扫得内容） */
  @State scanResult: string = '';
  /** ll_content 显隐（源码 p.setVisibility(4)→(0)） */
  @State showContent: boolean = false;
  /** tvSubmit 显隐（源码 setVisibility(8)→(0)） */
  @State showSubmit: boolean = false;
  /** tv_account = userName + "  " + userId */
  @State accountText: string = '';
  /** 提交中防重复 */
  @State submitting: boolean = false;
  @StorageProp('currentBreakpoint') currentBreakpoint: string = 'sm';
  @StorageProp('avoidAreaBottomVp') avoidAreaBottomVp: number = 0;

  aboutToAppear(): void {
    // 源码 y(Intent)：l = intent.getStringExtra("result")
    const params: object | undefined = router.getParams() as object | undefined;
    if (params !== undefined && params !== null) {
      const rec = params as Record<string, Object>;
      const result: Object = rec['result'];
      if (typeof result === 'string') {
        this.scanResult = result as string;
      }
    }
    this.f1();
  }

  /** 源码 f1() 逐行还原 */
  private f1(): void {
    this.showSubmit = false;
    this.showContent = false;
    if (this.scanResult === '') {
      this.getUIContext().getPromptAction().showToast({ message: '扫描出错' });
      return;
    }
    // 微信/QQ/淘宝 URL 分支（HAP 无法查询安装列表/拉起外部应用 → 等价 L2()==false 未安装分支）
    if (this.scanResult.indexOf('login.weixin.qq.com') >= 0) {
      this.getUIContext().getPromptAction().showToast({ message: '你暂未安装微信哦' });
      return;
    }
    if (this.scanResult.indexOf('txz.qq.com') >= 0) {
      this.getUIContext().getPromptAction().showToast({ message: '你暂未安装QQ哦' });
      return;
    }
    if (this.scanResult.indexOf('m.tb.cn') >= 0) {
      this.getUIContext().getPromptAction().showToast({ message: '你暂未安装淘宝哦' });
      return;
    }
    // 源码：p.setVisibility(0) + tv_account = userName + "  " + userId + tvSubmit 可见
    this.showContent = true;
    this.accountText = LoginSession.sessionName + '  ' + LoginSession.userId;
    this.showSubmit = true;
  }

  /** 源码 M2()：ScanLoginModel.V0 GET /api/scan/index {url}；g → finish；f → toast message */
  private async submit(): Promise<void> {
    if (this.submitting) {
      return;
    }
    this.submitting = true;
    try {
      const resp: ApiResponse<Object> = await ApiService.scanLoginIndex(this.scanResult);
      if (resp.code === 1000) {
        // 统一拦截层已处理（清会话+跳登录），页内不再提示
        return;
      }
      if (resp.code !== 0) {
        // 源码 f 回调：m(str2) toast 服务器 message
        this.getUIContext().getPromptAction().showToast({ message: resp.message });
        return;
      }
      // 源码 g 回调：ScanLoginActivity.this.finish()
      router.back();
    } catch (error) {
      const be = error as BusinessError;
      ApiService.logError('scanLoginIndex fail: ' + be.message);
      this.getUIContext().getPromptAction().showToast({ message: '网络请求失败，请重试' });
    } finally {
      this.submitting = false;
    }
  }

  build() {
    Column() {
      // toolbar_normal：H0()=null → 标题空
      TitleBar({ title: '', showBack: true })

      // MultiStateView content 区：LinearLayout gravity=center_vertical
      Scroll() {
        Column() {
          // ll_content（初始 invisible，f1 校验通过后可见）
          Column() {
            Image($r('app.media.mobile_campus_scan_login'))
              .width(214)
              .height(144)

            Text('扫码登录')
              .fontSize(16)
              .fontColor($r('app.color.black'))
              .textAlign(TextAlign.Center)
              .margin({ top: 18 })

            Text(this.accountText)
              .fontSize(16)
              .fontColor($r('app.color.ybg_blue'))
              .textAlign(TextAlign.Center)
              .margin({ top: 6 })
          }
          .width('100%')
          .alignItems(HorizontalAlign.Center)
          .visibility(this.showContent ? Visibility.Visible : Visibility.Hidden)

          // tvSubmit（初始 gone，f1 校验通过后可见）
          Text('确认登录')
            .fontSize(16)
            .fontColor($r('app.color.white'))
            .textAlign(TextAlign.Center)
            .width(184)
            .height(40)
            .backgroundColor($r('app.color.mobile_campus_schedule_confirm_blue'))
            .margin({ left: 12, right: 12, top: 10, bottom: 10 })
            .visibility(this.showSubmit ? Visibility.Visible : Visibility.None)
            .onClick(() => {
              this.submit();
            })
        }
        .width('100%')
        .constraintSize({
          minHeight: '100%',
          maxWidth: BreakpointSystem.getContentMaxWidth(this.currentBreakpoint)
        })
        .padding({ bottom: Math.max(16, this.avoidAreaBottomVp) })
        .justifyContent(FlexAlign.Center)
      }
      .width('100%')
      .layoutWeight(1)
      .scrollBar(BarState.Off)
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.white'))
  }
}
