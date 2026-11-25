import { router } from '@kit.ArkUI';
import { common } from '@kit.AbilityKit';
import { preferences } from '@kit.ArkData';
import { TitleBar } from '../components/TitleBar';
import { GesturePwdGrid } from '../components/GesturePwdGrid';
import { GestureManager, GesturePwdBean } from '../model/GestureManager';
import { LoginSession } from '../network/LoginSession';
import { PreferencesUtil } from '../data/PreferencesUtil';
import { PrivacyWindowHelper } from '../common/PrivacyWindowHelper';
import { BreakpointSystem } from '../common/BreakpointSystem';
import { BiometricAuthHelper, BiometricCapability } from '../common/BiometricAuthHelper';

/**
 * 手势密码校验页 — 1:1 复刻 GesturePwdVerifyActivity（229 行）
 * + mobile_campus_activity_gesture_pwd_verify.xml + GesturePwdLayout check 模式
 * [W22 launch-chain] 源码级翻译：
 *   布局：toolbar_normal（T1 标题"身份验证"）+ RelativeLayout(mt 40dip=20vp)：ivAvatar 72x72
 *   default_avatar centerCrop / tvAvatar 72x72 圆角 bg primary 白 20sp（gone 切换）
 *   + tvPhone 18sp(mt 16sp≈8vp) + tvTip"请输入手势密码" 14sp #999999(mt 16dip=8vp)
 *   + tvErrorTip 14sp #EB5757(mt 8dip=4vp) + gplBig(paddingH 12dip=6vp, mt 25dip=12.5vp)。
 *   y(Intent)：l = Gson(extra "jsonStr") = GesturePwdBean{userId, gesturePwds}。
 *   f1()：CDJS → setCount(4)（SDGY → 3）；N2() 头像分流（SystemSwitch.touxiang==null 分支：
 *     avatar 空 → userName 空 → 默认头像图，否则 BLTextView 首字；HAP 会话无 avatar 字段 →
 *     等价走 avatar 空分支）；手机号掩码 K2(str)：11 位 → 前3+"*****"+7..9（源码 substring 保真）。
 *   check 模式（switchToCheckMode(gesturePwds, 5)）：
 *     a() onToast i2==5 → tvErrorTip"手势密码不正确，剩余尝试次数%s次"（错误笔画红，组件 errorToken）；
 *     c(true) → M2()：tvErrorTip"校验成功" → g2(e.a.j=/my/GesturePwdSettingActivity) + finish
 *       （源码链：校验通过 → 重设手势密码页）；c(false) → L2() 冻结 60s（CountDownTimer：
 *       onTick"冻结"+(秒+1)+"s"，onFinish 复位重挂 check 模式），冻结期 finish() 被抑制。
 * 入口链（APK SettingActivity h()）：已存手势 → g2(e.a.k=/my/GesturePwdVerifyActivity, {jsonStr})。
 */
@Entry
@Component
struct GesturePwdVerifyPage {
  /** 源码 l：GesturePwdBean */
  @State private bean: GesturePwdBean | null = null;
  /** 验证模式：'reset' 重设手势 | 'disable' 关闭手势 | 'unlock' 启动解锁 */
  @State private mode: string = 'reset';
  @State private gridInteracting: boolean = false;
  private autoTriggeredBiometric: boolean = false;
  /** 源码 n(tvErrorTip) */
  @State errorTip: string = '';
  /** 源码 o/tvAvatar / q/tvPhone */
  @State showNameAvatar: boolean = false;
  @State nameChar: string = '';
  @State phoneText: string = '';
  /** 源码 m：check 模式错误态（错误笔画红） */
  @State errorToken: number = 0;
  /** 源码 r：CountDownTimer；t：冻结中 */
  @State frozen: boolean = false;
  @State biometricEnabled: boolean = false;
  @State biometricCap: BiometricCapability | null = null;
  @State biometricBusy: boolean = false;
  private countdownTimerId: number = -1;
  /** 源码 s：冻结秒数 */
  private readonly freezeSeconds: number = 60;
  /** 源码 maxAttemptTimes=5 / currentAttemptTime=1 */
  private currentAttemptTime: number = 1;
  private readonly maxAttemptTimes: number = 5;
  /** 源码 mCount：CDJS=4，其余=3 */
  private gridCount: number = 3;
  @StorageProp('currentBreakpoint') currentBreakpoint: string = 'sm';
  @StorageProp('windowWidthVp') windowWidthVp: number = 360;
  @StorageProp('windowHeightVp') windowHeightVp: number = 780;
  @StorageProp('avoidAreaBottomVp') avoidAreaBottomVp: number = 0;

  aboutToAppear(): void {
    // 源码 y(Intent)：l = Gson(intent.getStringExtra("jsonStr"))
    const params: object | undefined = router.getParams() as object | undefined;
    if (params !== undefined && params !== null) {
      const rec = params as Record<string, Object>;
      const modeVal: Object = rec['mode'];
      if (typeof modeVal === 'string' && modeVal !== '') {
        this.mode = modeVal as string;
      }
      const json: Object = rec['jsonStr'];
      if (typeof json === 'string' && json !== '') {
        try {
          const parsed = JSON.parse(json as string) as Record<string, Object>;
          const b = new GesturePwdBean();
          b.userId = typeof parsed['userId'] === 'string' ? parsed['userId'] as string : '';
          const pwdRaw: Object = parsed['gesturePwds'];
          if (Array.isArray(pwdRaw)) {
            for (const p of pwdRaw as Object[]) {
              if (typeof p === 'number') {
                b.gesturePwds.push(p as number);
              }
            }
          }
          if (b.gesturePwds.length > 0) {
            this.bean = b;
          }
        } catch (error) {
          this.bean = null;
        }
      }
    }
    if (this.bean === null && this.mode !== 'unlock') {
      GestureManager.find(GestureManager.resolveUserId()).then((saved: GesturePwdBean | null) => {
        if (saved !== null && saved.gesturePwds.length > 0) {
          this.bean = saved;
        }
      });
    }
    if (LoginSession.schoolId === 'CDJS') {
      this.gridCount = 4;
    }
    this.N2();
    // 源码 f1()：gesturePwdBean != null → switchToCheckMode(gesturePwds, 5)
    this.currentAttemptTime = 1;
    this.restoreLockoutState();
    this.biometricCap = BiometricAuthHelper.checkCapability();
    try {
      const ctx = this.getUIContext().getHostContext() as common.UIAbilityContext;
      BiometricAuthHelper.isBiometricUnlockEnabled(ctx).then((enabled: boolean) => {
        this.biometricEnabled = enabled;
        if (this.mode === 'unlock' && !this.autoTriggeredBiometric && this.hasBiometricVerifyAvailable()) {
          this.autoTriggeredBiometric = true;
          setTimeout(() => {
            this.startBiometricVerify();
          }, 250);
        }
      });
    } catch {
      this.biometricEnabled = false;
    }
  }

  onPageShow(): void {
    const ctx = this.getUIContext().getHostContext() as common.UIAbilityContext;
    PrivacyWindowHelper.enterSensitivePage('GesturePwdVerifyPage', ctx);
  }

  onPageHide(): void {
    const ctx = this.getUIContext().getHostContext() as common.UIAbilityContext;
    PrivacyWindowHelper.leaveSensitivePage('GesturePwdVerifyPage', ctx);
  }

  aboutToDisappear(): void {
    BiometricAuthHelper.cancelActiveAuth();
    // 源码 onDestroy：CountDownTimer.cancel()
    if (this.countdownTimerId !== -1) {
      clearTimeout(this.countdownTimerId);
      this.countdownTimerId = -1;
    }
    const ctx = this.getUIContext().getHostContext() as common.UIAbilityContext;
    PrivacyWindowHelper.leaveSensitivePage('GesturePwdVerifyPage', ctx);
  }

  /** 源码 N2()：头像 + 掩码手机号（touxiang 开关分支：HAP 未持久化 SystemSwitch → null 分支） */
  private N2(): void {
    const userName: string = LoginSession.sessionName;
    // SystemSwitch.touxiang == null → 等价 getAvatar() 空分支
    if (userName === '') {
      this.showNameAvatar = false;
    } else {
      this.showNameAvatar = true;
      this.nameChar = userName.charAt(0);
    }
    // 源码：bindMobile 优先，空取 mobileNo → K2 掩码
    const phone: string = LoginSession.sessionPhone;
    this.phoneText = this.maskPhone(phone);
  }

  /** 源码 K2(str)：空或长度≠11 → ""；否则 substring(0,3) + "*****" + substring(7,10)（11 位取 8-10 位） */
  private maskPhone(phone: string): string {
    if (phone === '' || phone.length !== 11) {
      return '';
    }
    return phone.substring(0, 3) + '*****' + phone.substring(7, 10);
  }

  private toast(msg: string): void {
    this.getUIContext().getPromptAction().showToast({ message: msg });
  }

  private hasBiometricVerifyAvailable(): boolean {
    return this.biometricEnabled &&
      this.biometricCap !== null &&
      BiometricAuthHelper.shouldOfferBiometricToggle(this.biometricCap);
  }

  private async startBiometricVerify(): Promise<void> {
    if (this.frozen || this.biometricBusy || this.biometricCap === null) {
      return;
    }
    const canVerify: boolean = this.biometricEnabled || this.bean === null;
    if (!BiometricAuthHelper.shouldShowBiometricVerify(canVerify, this.biometricCap, this.frozen)) {
      this.toast(this.biometricCap.description);
      return;
    }
    this.biometricBusy = true;
    try {
      const bioTypes = this.biometricCap.anyBiometric
        ? BiometricAuthHelper.getBiometricOnlyTypes(this.biometricCap)
        : this.biometricCap.authTypes;
      const outcome = await BiometricAuthHelper.authenticate({
        title: '生物识别快捷验证',
        navigationButtonText: this.bean !== null && this.bean.gesturePwds.length > 0 ? '使用手势密码' : undefined,
        authTypes: bioTypes
      });
      if (outcome.success) {
        this.currentAttemptTime = 1;
        await this.M2();
        return;
      }
      if (!outcome.canceled && outcome.message !== '') {
        this.toast(outcome.message);
      }
    } finally {
      this.biometricBusy = false;
    }
  }

  private sameSeq(a: number[], b: number[]): boolean {
    if (a.length !== b.length) {
      return false;
    }
    for (let i = 0; i < a.length; i++) {
      if (a[i] !== b[i]) {
        return false;
      }
    }
    return true;
  }

  /** 源码 onCheck 逐行还原（组件 onFinish 入口） */
  private onCheck(seq: number[]): void {
    if (seq.length < 4) {
      this.errorTip = '请最少连接4个点';
      this.errorToken = this.errorToken + 1;
      return;
    }
    const pwd: number[] | null = this.bean !== null ? this.bean.gesturePwds : null;
    if (pwd === null || pwd.length === 0) {
      return;
    }
    const match: boolean = this.sameSeq(pwd, seq);
    if (this.currentAttemptTime > this.maxAttemptTimes) {
      // 源码：currentAttemptTime > max → 直接回调（冻结态，交互已被禁用）
      if (match) {
        this.M2();
      } else {
        this.L2();
      }
      this.currentAttemptTime = 1;
      return;
    }
    if (match) {
      // 源码：zCompare → c(true)
      this.currentAttemptTime = 1;
      this.saveLockoutState(1, 0);
      this.M2();
      return;
    }
    const remaining: number = this.maxAttemptTimes - this.currentAttemptTime;
    if (remaining > 0) {
      // 源码 onToast(String.format("手势密码不正确，剩余尝试次数%s次", i3), red, 5) → tvErrorTip
      this.errorTip = '手势密码不正确，剩余尝试次数' + remaining + '次';
      this.errorToken = this.errorToken + 1;
      this.currentAttemptTime++;
      this.saveLockoutState(this.currentAttemptTime, 0);
    } else {
      // 源码：剩余 0 → c(false) → L2() 冻结
      this.currentAttemptTime++;
      this.L2();
    }
  }

  /** 源码 M2()：校验通过后按模式分发（disable / unlock / reset） */
  private async M2(): Promise<void> {
    this.errorTip = '校验成功';
    if (this.mode === 'disable') {
      await GestureManager.remove(GestureManager.resolveUserId());
      this.toast('已关闭手势密码');
      router.back();
      return;
    }
    if (this.mode === 'unlock') {
      router.replaceUrl({ url: 'pages/Index', params: { 'jpushExtra': '' } });
      return;
    }
    router.replaceUrl({ url: 'pages/GesturePwdSettingPage' });
  }

  /** 持久化手势失败次数与锁定截止时间，防止强杀重启绕过冻结 */
  private saveLockoutState(attempt: number, lockUntilMs: number): void {
    try {
      const ctx = this.getUIContext().getHostContext() as common.UIAbilityContext;
      const store = preferences.getPreferencesSync(ctx, { name: 'sdmu_security_prefs' });
      store.putSync('gesture_attempt_count', attempt);
      store.putSync('gesture_lock_until_ms', lockUntilMs);
      store.flushSync();
    } catch {
      // 忽略持久化异常
    }
  }

  /** 启动时恢复手势冻结状态与剩余尝试次数 */
  private restoreLockoutState(): void {
    try {
      const ctx = this.getUIContext().getHostContext() as common.UIAbilityContext;
      const store = preferences.getPreferencesSync(ctx, { name: 'sdmu_security_prefs' });
      const savedAttempt = store.getSync('gesture_attempt_count', 1) as number;
      const lockUntilMs = store.getSync('gesture_lock_until_ms', 0) as number;
      const now: number = Date.now();
      if (typeof lockUntilMs === 'number' && lockUntilMs > now) {
        this.startFreezeCountdown(lockUntilMs - now);
        return;
      }
      if (typeof savedAttempt === 'number' && savedAttempt >= 1 && savedAttempt <= this.maxAttemptTimes) {
        this.currentAttemptTime = savedAttempt;
      }
    } catch {
      // 忽略读取异常
    }
  }

  private startFreezeCountdown(durationMs: number): void {
    if (this.countdownTimerId !== -1) {
      clearInterval(this.countdownTimerId);
      this.countdownTimerId = -1;
    }
    this.frozen = true;
    let remainingMs: number = durationMs;
    this.errorTip = '冻结' + Math.max(1, Math.ceil(remainingMs / 1000)) + 's';
    this.countdownTimerId = setInterval(() => {
      remainingMs -= 1000;
      if (remainingMs <= 0) {
        if (this.countdownTimerId !== -1) {
          clearInterval(this.countdownTimerId);
          this.countdownTimerId = -1;
        }
        this.frozen = false;
        this.errorTip = '';
        this.currentAttemptTime = 1;
        this.saveLockoutState(1, 0);
        return;
      }
      this.errorTip = '冻结' + (Math.floor(remainingMs / 1000) + 1) + 's';
    }, 1000);
  }

  /** 源码 L2()：setIfAllowInteract(false) + "冻结60s" + 持久化锁定截止时间 */
  private L2(): void {
    const durationMs: number = this.freezeSeconds * 1000;
    this.saveLockoutState(1, Date.now() + durationMs);
    this.startFreezeCountdown(durationMs);
  }

  /** 源码 finish() 覆盖：冻结中或启动解锁态抑制返回 */
  onBackPress(): boolean {
    return this.frozen || this.mode === 'unlock';
  }

  private async switchOtherAccount(): Promise<void> {
    await PreferencesUtil.clear();
    router.replaceUrl({ url: 'pages/LoginPage' });
  }

  build() {
    Column() {
      TitleBar({ title: '身份验证', showBack: this.mode !== 'unlock' })

      Scroll() {
        Column() {
          // RelativeLayout：ivAvatar / tvAvatar 互斥
          Stack() {
            Image($r('app.media.default_avatar'))
              .width(72)
              .height(72)
              .objectFit(ImageFit.Cover)
              .visibility(this.showNameAvatar ? Visibility.None : Visibility.Visible)

            Text(this.nameChar)
              .fontSize(20)
              .fontColor($r('app.color.white'))
              .textAlign(TextAlign.Center)
              .width(72)
              .height(72)
              .borderRadius(36)
              .backgroundColor($r('app.color.mobile_campus_primary_color'))
              .visibility(this.showNameAvatar ? Visibility.Visible : Visibility.None)
          }
          .margin({ top: 20 })

          Text(this.phoneText)
            .fontSize(18)
            .fontColor($r('app.color.black'))
            .textAlign(TextAlign.Center)
            .width('100%')
            .margin({ top: 8 })

          Text(this.bean !== null && this.bean.gesturePwds.length > 0
            ? '请输入手势密码'
            : '请使用人脸或指纹完成身份验证')
            .fontSize(14)
            .fontColor('#999999')
            .textAlign(TextAlign.Center)
            .width('100%')
            .margin({ top: 8 })

          Text(this.errorTip)
            .fontSize(14)
            .fontColor($r('app.color.color_checked_err'))
            .textAlign(TextAlign.Center)
            .width('100%')
            .margin({ top: 4 })

          if (this.bean !== null && this.bean.gesturePwds.length > 0) {
            GesturePwdGrid({
              gridWidth: BreakpointSystem.computeGestureGridSize(this.windowWidthVp, this.windowHeightVp),
              allowInteract: !this.frozen,
              count: this.gridCount,
              errorToken: this.errorToken,
              onInteractChange: (interacting: boolean): void => {
                this.gridInteracting = interacting;
              },
              onSwipeFinish: (seq: number[]): void => {
                // 源码 e()：onSwipeFinish 校验页无动作
              },
              onFinish: (seq: number[]): void => {
                this.onCheck(seq);
              }
            })
              .margin({ top: 12.5 })
              .padding({ left: 6, right: 6 })
          }

          if (this.hasBiometricVerifyAvailable() || (this.bean === null && this.biometricCap !== null &&
            BiometricAuthHelper.shouldOfferBiometricToggle(this.biometricCap))) {
            Button(this.biometricBusy ? '正在验证...' : (this.bean !== null && this.bean.gesturePwds.length > 0
              ? '指纹/人脸快捷验证'
              : '使用指纹/人脸验证'))
              .fontSize(15)
              .fontColor(this.bean !== null && this.bean.gesturePwds.length > 0 ? '#1B68B7' : $r('app.color.white'))
              .backgroundColor(this.bean !== null && this.bean.gesturePwds.length > 0 ? '#EBF4FF' : '#1B68B7')
              .borderRadius(20)
              .padding({ left: 24, right: 24, top: 10, bottom: 10 })
              .margin({ top: 20 })
              .enabled(!this.frozen && !this.biometricBusy)
              .opacity(this.frozen ? 0.45 : 1)
              .hoverEffect(HoverEffect.Highlight)
              .onClick(() => {
                this.startBiometricVerify();
              })
          }

          if (this.mode === 'unlock') {
            Text('切换其他账号登录')
              .fontSize(14)
              .fontColor('#1B68B7')
              .padding({ top: 18, bottom: 8, left: 16, right: 16 })
              .hoverEffect(HoverEffect.Highlight)
              .onClick(() => {
                this.switchOtherAccount();
              })
          }
        }
        .width('100%')
        .constraintSize({ maxWidth: BreakpointSystem.getContentMaxWidth(this.currentBreakpoint) })
        .padding({ bottom: Math.max(16, this.avoidAreaBottomVp + 12) })
        .alignItems(HorizontalAlign.Center)
      }
      .width('100%')
      .layoutWeight(1)
      .scrollBar(BarState.Off)
      .enableScrollInteraction(!this.gridInteracting)
      .align(Alignment.Top)
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.white'))
  }
}
