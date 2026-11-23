import { router } from '@kit.ArkUI';
import { common } from '@kit.AbilityKit';
import { userAuth } from '@kit.UserAuthenticationKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { ApiService } from '../network/ApiService';
import { ApiResponse } from '../model/ResponseModel';
import { BreakpointSystem } from '../common/BreakpointSystem';
import { BiometricAuthHelper } from '../common/BiometricAuthHelper';

/**
 * 指纹登录页 — 1:1 复刻 FingerLoginActivity（194 行）+ mobile_campus_activity_finger_login.xml
 * [W22 launch-chain] 源码级翻译：
 *   布局：LinearLayout(#common_color_6, paddingT 20dip=10vp)：ivClose 50x50(pad 18dip=9vp, mt 10dip=5vp)
 *     + 中部块(mt 132dip=66vp)：finger_login_icon_log(pad 10dip=5vp) + "电脑登录确认" 20fp bold(mt 10dip=5vp)
 *     + weight 空白 + tvLogin 180dip 宽 pad 12dip=6vp 圆角 1024dip bg #1790ff 17fp 白"登录"
 *     + tvCancel 17fp #4b749a pad 12dip mt 20dip=10vp mb 74dip=37vp"取消登录"。
 *   y(Intent)：q = extra "result"（PolymerizationActivity w.c 下发）→ Gson = PolymerizationResultBean。
 *   f1()：p = PolymerizationModel(domain)（域名为扫码下发）。
 *   tvLogin → FingerHelper.d()（指纹认证，FingerDialog 装载中）→ 成功 a(1)：
 *     loginType=="scan_qrcode_login" → T0 POST {domain}/lyuapServer/cam/v1/bindBrowser
 *       {browserId,buildTime,typeId:"1"} → g→L2 / f→toast"登录失败"；
 *     否则直接 L2 → X0 POST {domain}/lyuapServer/cam/v1/login {browserId,buildTime,typeId:"1"}
 *       → g→1s 后 toast"登录成功"+finish / f→toast(message)。
 *   tvCancel → X0 {browserId,buildTime,typeId:"0"}（取消登录）→ g/f 都 finish。
 *   ivClose → finish。
 * 入口链：PolymerizationPage（cam/v1/verify 已绑分支）→ 本页。
 */
interface PolyResultBean {
  browserId?: string;
  buildTime?: number;
  domain?: string;
  loginType?: string;
}

@Entry
@Component
struct FingerLoginPage {
  private resultJson: string = '';
  /** 源码 r：PolymerizationResultBean */
  private bean: PolyResultBean | null = null;
  /** 源码 q：raw（未用，保真字段） */
  private rawResult: string = '';
  private toastTimerId: number = -1;
  @StorageProp('currentBreakpoint') currentBreakpoint: string = 'sm';
  @StorageProp('avoidAreaTopVp') avoidAreaTopVp: number = 0;
  @StorageProp('avoidAreaBottomVp') avoidAreaBottomVp: number = 0;

  aboutToAppear(): void {
    const params: object | undefined = router.getParams() as object | undefined;
    if (params !== undefined && params !== null) {
      const rec = params as Record<string, Object>;
      const result: Object = rec['result'];
      if (typeof result === 'string') {
        this.rawResult = result as string;
        this.parseBean();
      }
    }
    // 源码 f1()：p = new f(this.r.getDomain()) —— HAP 将 domain 存入 bean 即等价
  }

  aboutToDisappear(): void {
    BiometricAuthHelper.cancelActiveAuth();
    if (this.toastTimerId !== -1) {
      clearTimeout(this.toastTimerId);
      this.toastTimerId = -1;
    }
  }

  private parseBean(): void {
    try {
      const rec: Record<string, Object> = JSON.parse(this.rawResult) as Record<string, Object>;
      const bean: PolyResultBean = {};
      const pick = (k: string): string => {
        const v: Object = rec[k];
        return typeof v === 'string' ? v as string : '';
      };
      bean.browserId = pick('browserId');
      bean.domain = pick('domain');
      bean.loginType = pick('loginType');
      const bt: Object = rec['buildTime'];
      bean.buildTime = typeof bt === 'number' ? bt as number : Number(bt);
      this.bean = bean;
    } catch (error) {
      this.bean = null;
    }
  }

  private toast(msg: string): void {
    this.getUIContext().getPromptAction().showToast({ message: msg });
  }

  /** 源码 tvLogin → FingerHelper.d()：指纹认证（通过 BiometricAuthHelper 封装探测与状态反馈） */
  private async startFingerprint(): Promise<void> {
    const cap = BiometricAuthHelper.checkCapability();
    const ctx = this.getUIContext().getHostContext() as common.UIAbilityContext;
    const outcome = await BiometricAuthHelper.authenticate({
      title: '电脑登录确认',
      authTypes: [userAuth.UserAuthType.FINGERPRINT],
      uiContext: ctx
    });
    if (outcome.success) {
      await this.onFingerStatus(1);
      return;
    }
    if (outcome.notEnrolled || outcome.locked || outcome.canceled ||
      outcome.code === userAuth.UserAuthResultCode.TYPE_NOT_SUPPORT || outcome.message !== '') {
      const msg: string = outcome.message !== '' ? outcome.message : cap.description;
      this.toast(msg);
    }
  }

  /** 源码 FingerLoginActivity$a.a(int i)：i==1 分流 bindBrowser/直接 L2 */
  private async onFingerStatus(status: number): Promise<void> {
    if (status !== 1) {
      return;
    }
    const bean: PolyResultBean | null = this.bean;
    if (bean === null || (bean.browserId ?? '') === '' || (bean.domain ?? '') === '') {
      // 源码 r 空指针等价防御（正常链路必有值）
      this.toast('登录失败');
      return;
    }
    const browserId: string = bean.browserId as string;
    const buildTime: string = String(bean.buildTime);
    const domain: string = bean.domain as string;
    if (bean.loginType === 'scan_qrcode_login') {
      // 源码 C0404a：p.T0(browserId, buildTime, "1") → g→L2 / f→toast"登录失败"
      try {
        const resp: ApiResponse<Object> = await ApiService.polyBindBrowser(domain, browserId, buildTime, '1');
        if (resp.code === 0) {
          await this.confirmLogin(browserId, buildTime, domain, '1');
        } else {
          this.toast('登录失败');
        }
      } catch (error) {
        const be = error as BusinessError;
        ApiService.logError('polyBindBrowser fail: ' + be.message);
        this.toast('登录失败');
      }
      return;
    }
    // 源码 a$a.a 直接分支：L2(browserId, buildTime+"", "1")
    await this.confirmLogin(browserId, buildTime, domain, '1');
  }

  /** 源码 L2 → p.X0：POST {domain}/lyuapServer/cam/v1/login；g→1s toast"登录成功"+finish；f→toast */
  private async confirmLogin(browserId: string, buildTime: string, domain: string, typeId: string): Promise<void> {
    try {
      const resp: ApiResponse<Object> = await ApiService.polyLogin(domain, browserId, buildTime, typeId);
      if (resp.code === 0) {
        // 源码 b.g：e2(new a(), 1000L) → 1s 后 m("登录成功") + finish()
        this.toastTimerId = setTimeout(() => {
          this.toast('登录成功');
          router.back();
        }, 1000);
      } else {
        // 源码 b.f：m(str2) toast 服务器 message
        this.toast(resp.message);
      }
    } catch (error) {
      const be = error as BusinessError;
      ApiService.logError('polyLogin fail: ' + be.message);
      this.toast('网络请求失败，请重试');
    }
  }

  /** 源码 tvCancel → X0(browserId, buildTime, "0")：c 回调 g/f 都 finish */
  private async cancelLogin(): Promise<void> {
    const bean: PolyResultBean | null = this.bean;
    if (bean === null || (bean.domain ?? '') === '') {
      router.back();
      return;
    }
    try {
      await ApiService.polyLogin(bean.domain as string, bean.browserId ?? '', String(bean.buildTime), '0');
    } catch (error) {
      const be = error as BusinessError;
      ApiService.logError('polyLogin cancel fail: ' + be.message);
    }
    // 源码 c 回调 g/f 两分支均 finish()
    router.back();
  }

  build() {
    Scroll() {
      Column() {
        Row() {
          Image($r('app.media.finger_login_close'))
            .width(50)
            .height(50)
            .padding(9)
            .margin({ top: 5 })
            .hoverEffect(HoverEffect.Highlight)
            .onClick(() => {
              // 源码 ivClose → finish()
              router.back();
            })
        }
        .width('100%')
        .justifyContent(FlexAlign.Start)

        Column() {
          Image($r('app.media.finger_login_icon_log'))
            .padding(5)

          Text('电脑登录确认')
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor($r('app.color.black'))
            .margin({ top: 5 })
        }
        .margin({ top: 48 })
        .alignItems(HorizontalAlign.Center)

        Blank()
          .layoutWeight(1)

        Text('登录')
          .fontSize(17)
          .fontColor($r('app.color.white'))
          .textAlign(TextAlign.Center)
          .width(180)
          .padding(6)
          .margin({ top: 24 })
          .borderRadius(512)
          .backgroundColor('#1790FF')
          .hoverEffect(HoverEffect.Highlight)
          .onClick(() => {
            // 源码 tvLogin → o.d()（指纹认证）
            this.startFingerprint();
          })

        Text('取消登录')
          .fontSize(17)
          .fontColor('#4B749A')
          .textAlign(TextAlign.Center)
          .padding(6)
          .margin({ top: 10, bottom: Math.max(24, this.avoidAreaBottomVp + 16) })
          .hoverEffect(HoverEffect.Highlight)
          .onClick(() => {
            // 源码 tvCancel → X0(browserId, buildTime, "0")
            this.cancelLogin();
          })
      }
      .width('100%')
      .constraintSize({
        minHeight: '100%',
        maxWidth: BreakpointSystem.getContentMaxWidth(this.currentBreakpoint)
      })
      .padding({ top: Math.max(10, this.avoidAreaTopVp + 6) })
      .alignItems(HorizontalAlign.Center)
    }
    .width('100%')
    .height('100%')
    .scrollBar(BarState.Off)
    .backgroundColor($r('app.color.common_color_6'))
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
  }
}
