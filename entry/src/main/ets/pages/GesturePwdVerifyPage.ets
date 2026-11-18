import { router } from '@kit.ArkUI';
import { TitleBar } from '../components/TitleBar';
import { GesturePwdGrid } from '../components/GesturePwdGrid';
import { GesturePwdBean } from '../model/GestureManager';
import { LoginSession } from '../network/LoginSession';

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
  private bean: GesturePwdBean | null = null;
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
  private countdownTimerId: number = -1;
  /** 源码 s：冻结秒数 */
  private readonly freezeSeconds: number = 60;
  /** 源码 maxAttemptTimes=5 / currentAttemptTime=1 */
  private currentAttemptTime: number = 1;
  private readonly maxAttemptTimes: number = 5;
  /** 源码 mCount：CDJS=4，其余=3 */
  private gridCount: number = 3;

  aboutToAppear(): void {
    // 源码 y(Intent)：l = Gson(intent.getStringExtra("jsonStr"))
    const params: object | undefined = router.getParams() as object | undefined;
    if (params !== undefined && params !== null) {
      const rec = params as Record<string, Object>;
      const json: Object = rec['jsonStr'];
      if (typeof json === 'string') {
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
          this.bean = b;
        } catch (error) {
          this.bean = null;
        }
      }
    }
    if (LoginSession.schoolId === 'CDJS') {
      this.gridCount = 4;
    }
    this.N2();
    // 源码 f1()：gesturePwdBean != null → switchToCheckMode(gesturePwds, 5)
    this.currentAttemptTime = 1;
  }

  aboutToDisappear(): void {
    // 源码 onDestroy：CountDownTimer.cancel()
    if (this.countdownTimerId !== -1) {
      clearTimeout(this.countdownTimerId);
      this.countdownTimerId = -1;
    }
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

  /** 源码 onCheck 逐行还原（组件 onFinish = seq>=4 的 check 入口） */
  private onCheck(seq: number[]): void {
    const pwd: number[] | null = this.bean !== null ? this.bean.gesturePwds : null;
    if (pwd === null || pwd.length === 0) {
      // 源码 switchToCheckMode 参数错误（pwd 空）仅 Log，不回调
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
      this.M2();
      return;
    }
    const remaining: number = this.maxAttemptTimes - this.currentAttemptTime;
    if (remaining > 0) {
      // 源码 onToast(String.format("手势密码不正确，剩余尝试次数%s次", i3), red, 5) → tvErrorTip
      this.errorTip = '手势密码不正确，剩余尝试次数' + remaining + '次';
      this.errorToken = this.errorToken + 1;
    } else {
      // 源码：剩余 0 → c(false) → L2() 冻结
      this.L2();
    }
    this.currentAttemptTime++;
  }

  /** 源码 M2()：tvErrorTip"校验成功" → g2(e.a.j) + finish */
  private M2(): void {
    this.errorTip = '校验成功';
    router.replaceUrl({ url: 'pages/GesturePwdSettingPage' });
  }

  /** 源码 L2()：setIfAllowInteract(false) + "冻结60s" + CountDownTimer(s*1000, 1000) */
  private L2(): void {
    this.frozen = true;
    this.errorTip = '冻结' + this.freezeSeconds + 's';
    let remainingMs: number = this.freezeSeconds * 1000;
    this.countdownTimerId = setInterval(() => {
      remainingMs -= 1000;
      if (remainingMs <= 0) {
        // 源码 onFinish：t=false + 允许交互 + tip 清空 + 重新挂 check 模式（尝试次数复位）
        if (this.countdownTimerId !== -1) {
          clearInterval(this.countdownTimerId);
          this.countdownTimerId = -1;
        }
        this.frozen = false;
        this.errorTip = '';
        this.currentAttemptTime = 1;
        return;
      }
      // 源码 onTick："冻结" + (j / 1000 + 1) + "s"
      this.errorTip = '冻结' + (Math.floor(remainingMs / 1000) + 1) + 's';
    }, 1000);
  }

  /** 源码 finish() 覆盖：冻结中抑制返回（系统返回键同走 finish） */
  onBackPress(): boolean {
    return this.frozen;
  }

  build() {
    Column() {
      TitleBar({ title: '身份验证', showBack: true })

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

        Text('请输入手势密码')
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

        GesturePwdGrid({
          gridWidth: 336,
          allowInteract: !this.frozen,
          count: this.gridCount,
          errorToken: this.errorToken,
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
      .width('100%')
      .height('100%')
      .alignItems(HorizontalAlign.Center)
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.white'))
  }
}
