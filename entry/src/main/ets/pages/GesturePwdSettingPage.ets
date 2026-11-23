import { router } from '@kit.ArkUI';
import { common } from '@kit.AbilityKit';
import { TitleBar } from '../components/TitleBar';
import { GesturePwdGrid } from '../components/GesturePwdGrid';
import { GestureManager } from '../model/GestureManager';
import { LoginSession } from '../network/LoginSession';
import { PrivacyWindowHelper } from '../common/PrivacyWindowHelper';

/**
 * 手势密码设置页 — 1:1 复刻 GesturePwdSettingActivity（100 行）
 * + mobile_campus_activity_gesture_pwd_setting.xml + GesturePwdLayout reset 模式
 * [W22 launch-chain] 源码级翻译：
 *   布局：toolbar_normal（T1 标题"设置手势密码"）+ tvTitle"设置您的新手势密码" 17sp mt 40dip=20vp
 *     + gplSmall 72x72(mt 16dip=8vp, count=3=3x3 九点, ifAllowInteract=false 预览)
 *     + tvTip"绘制解锁图案" 14sp #999999(mt 16dip=8vp) + tvErrorTip 14sp #EB5757(mt 8dip=4vp)
 *     + gplBig(fill, paddingH 12dip=6vp, mt 25dip=12.5vp, interact=true)。
 *   f1()：CDJS → setCount(4)（4x4 十六点；本包 schoolId=SDGY → 3）；m.switchToResetMode()。
 *   回调映射（GesturePwdLayout.a onToast(str,color,i2)）：
 *     i2==2 → tvTip"再次绘制解锁图案"；i2==6 → tvErrorTip"绘制成功"（源码怪癖：成功提示落错误行）；
 *     i2==4 → tvErrorTip"与上次绘制不一致，请重新绘制"；i2==3 → tvErrorTip"请最少连接4个点"；
 *     e()（每笔抬手）→ l.refreshPwdKeyboard(list)（小九宫格回显笔画）。
 *   b()（onResetFinish）：toast"设置成功" + GestureManager.c(userId, list)
 *     （Hawk "allGesturePwdDatas" JSON 数组，HAP=Preferences 同键）+ finish。
 * 入口链（APK SettingActivity h()）：无已存手势 → "校验密码"弹窗 → POST /api/juherenzheng/checkPass
 *   成功 → g2(e.a.j=/my/GesturePwdSettingActivity)；或 GesturePwdVerifyActivity 校验成功 → 同路由。
 */
@Entry
@Component
struct GesturePwdSettingPage {
  /** 源码 o(tvTip) / p(tvErrorTip) 文本 */
  @State tipText: string = '绘制解锁图案';
  @State errorTip: string = '';
  /** 小九宫格回显笔画（源码 l.refreshPwdKeyboard(list)） */
  @State smallSeq: number[] = [];
  /** 源码 onReset：resetCurrentTime（0=首笔，1=确认笔） */
  private resetCurrentTime: number = 0;
  /** 源码 tempPwd：首笔序列 */
  private tempPwd: number[] = [];
  /** 源码 mCount：CDJS=4，其余=3 */
  private gridCount: number = 3;

  aboutToAppear(): void {
    // 源码 f1()：if ("CDJS".equals(c.b())) l/m.setCount(4)
    if (LoginSession.schoolId === 'CDJS') {
      this.gridCount = 4;
    }
    // 源码 m.switchToResetMode()
    this.resetCurrentTime = 0;
    this.tempPwd = [];
  }

  onPageShow(): void {
    const ctx = this.getUIContext().getHostContext() as common.UIAbilityContext;
    PrivacyWindowHelper.enterSensitivePage('GesturePwdSettingPage', ctx);
  }

  onPageHide(): void {
    const ctx = this.getUIContext().getHostContext() as common.UIAbilityContext;
    PrivacyWindowHelper.leaveSensitivePage('GesturePwdSettingPage', ctx);
  }

  aboutToDisappear(): void {
    const ctx = this.getUIContext().getHostContext() as common.UIAbilityContext;
    PrivacyWindowHelper.leaveSensitivePage('GesturePwdSettingPage', ctx);
  }

  private toast(msg: string): void {
    this.getUIContext().getPromptAction().showToast({ message: msg });
  }

  /** 源码 compare：等长逐位相等 */
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

  /** 源码 e()（onSwipeFinish）：小九宫格 refreshPwdKeyboard 回显 */
  private onSmallMirror(seq: number[]): void {
    this.smallSeq = seq;
  }

  /** 源码 onTouchEvent UP → onReset()（seq>=4 才触发，由组件 onFinish 保证） */
  private onBigFinish(seq: number[]): void {
    // 源码 onToast 回调 a(str,i,i2) 文案路由
    if (seq.length < 4) {
      // i2==3（组件未达 minLength 不回 onFinish；此分支保留等价防御）
      this.errorTip = '请最少连接4个点';
      return;
    }
    if (this.resetCurrentTime === 0) {
      // 源码 onReset 首笔：tempPwd = copy；onToast("再次绘制解锁图案", grey, 2) → tvTip
      this.tempPwd = seq;
      this.resetCurrentTime++;
      this.tipText = '再次绘制解锁图案';
      return;
    }
    if (this.sameSeq(this.tempPwd, seq)) {
      // 源码 onToast("绘制成功", grey, 6) → tvErrorTip（错误行）
      this.errorTip = '绘制成功';
      this.onResetFinish(seq);
    } else {
      // 源码 onToast("与上次绘制不一致，请重新绘制", red, 4) → tvErrorTip（tempPwd 不清空）
      this.errorTip = '与上次绘制不一致，请重新绘制';
    }
  }

  /** 源码 b()（onResetFinish）：toast"设置成功" + GestureManager.c + finish */
  private async onResetFinish(list: number[]): Promise<void> {
    this.toast('设置成功');
    // 源码 b.c(d.a.c().getUserId(), list)：Hawk allGesturePwdDatas upsert
    await GestureManager.save(LoginSession.userId, list);
    router.back();
  }

  build() {
    Column() {
      TitleBar({ title: '设置手势密码', showBack: true })

      Column() {
        // tvTitle
        Text('设置您的新手势密码')
          .fontSize(17)
          .fontColor($r('app.color.black'))
          .textAlign(TextAlign.Center)
          .width('100%')
          .margin({ top: 20 })

        // gplSmall 72x72（count=3 预览，refreshPwdKeyboard 回显）
        GesturePwdGrid({
          gridWidth: 72,
          allowInteract: false,
          count: this.gridCount,
          displaySeq: this.smallSeq,
          onSwipeFinish: (seq: number[]): void => {
            this.onSmallMirror(seq);
          }
        })
          .margin({ top: 8 })

        // tvTip（i2==1||2 文案）
        Text(this.tipText)
          .fontSize(14)
          .fontColor('#999999')
          .textAlign(TextAlign.Center)
          .width('100%')
          .margin({ top: 8 })

        // tvErrorTip（i2==3/4/6 文案，色 colorCheckedErr）
        Text(this.errorTip)
          .fontSize(14)
          .fontColor($r('app.color.color_checked_err'))
          .textAlign(TextAlign.Center)
          .width('100%')
          .margin({ top: 4 })

        // gplBig（reset 模式）
        GesturePwdGrid({
          gridWidth: 336,
          allowInteract: true,
          count: this.gridCount,
          onSwipeFinish: (seq: number[]): void => {
            this.onSmallMirror(seq);
          },
          onFinish: (seq: number[]): void => {
            this.onBigFinish(seq);
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
