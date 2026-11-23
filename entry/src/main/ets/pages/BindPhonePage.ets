import { router } from '@kit.ArkUI';
import { BusinessError } from '@kit.BasicServicesKit';
import { TitleBar } from '../components/TitleBar';
import { ApiService } from '../network/ApiService';
import { LoginSession } from '../network/LoginSession';
import { BreakpointSystem } from '../common/BreakpointSystem';

/**
 * 绑定手机验证码页 — 1:1 翻译 MobileCampusBindPhoneActivity.java +
 *   mobile_campus_activity_bind_phone.xml
 *
 * 【源码依据】ARouter /my/bindphone（RouteConstant e.a.o）。入口 =
 *   MobileCampusInputPhoneActivity.V2（needSmsVertify 分支，bundle
 *   {phone, validation, justBindPhone:true, isCircle, userInfoJson?}）及 y() 换设备验证直转
 *   {validation, phone}。
 *
 * 【布局】ybg_white + toolbar（validation 空 → "绑定手机号"，否则"设备验证"）+ 细分隔线
 *   + 居中纵向：图标 mobile_campus_code(marginTop px_to_dip_80=40dip) + "输入验证码" +
 *     Row{ tvPhone "+86 "+phone(px_to_dip_26=13dip) + tvCode "获取验证码"
 *       (TextSize5.Color5=12sp #E7E7E7、schedule_selector_confirm enabled #1B68B6/禁用 #B8C0C9
 *        圆角 px_to_dip_8=4dip、padding px_to_dip_12=6dip、marginL px_to_dip_20=10dip；
 *        倒计时"已发送(Ns)"，结束→get_again"重新获取") } +
 *     VerifyCodeView（contentNumber 4（GXMD 才 6，k3 margin 4格90dip/6格40dip）、
 *       singleBox onlyFill 填充 #F2F2F2 圆角 2dip、space 6dip、字 20sp #333333、
 *       光标 cursorColor=@color/colorPrimary→#97000C 2dip 500ms 闪烁）+
 *     tvNext "完成"(px_to_sp_30=15sp selector_bind_phone, marginTop px_to_dip_96=48dip, 默认禁用)
 *
 * 【行为】f1() → i3() 页面出现即发送验证码：VerifyCodeModel.M0 POST getVercode
 *   {schoolId, userId, mobile, type:validation非空?"4":"1", [SchoolCircle]}；
 *   成功 g → tvCode 禁用 + 120s 倒计时"已发送(Ns)"→"重新获取"恢复；失败 f → toast(message)。
 *   tvCode 点击 → i3() 重发。VerifyCodeView 满 4 位 → tvNext 启用（e.b），否则禁用（e.a）。
 *   tvNext 点击（d）→ VerifyCodeModel.F POST verifyVercode {schoolId,userId,mobile,vercode,[SchoolCircle]}
 *   → 成功 h3()：
 *     justBindPhone(x) → j3() BindPhoneModel.U0 savePhone {code:userId,type:userType,phone}
 *       → code=="0" → toast"绑定手机成功！"；!isCircle → setResult+finish（HAP router.back）；
 *       isCircle（校圈）→ 社交昵称同步（lyyd.social 独立模块，SDMU 个人资料链路不触达，留空）；
 *     否则（设备验证）→ BindModel.G POST bindMobile {mobile} → 成功 g3()
 *       BindDeviceModel.T0 POST bindDevice/add {IMEI, sbmc}
 *       → 失败 toast"绑定设备失败"；成功且 validation 非空 → 跳主页清栈。
 *   code=1000 登录失效网络层统一拦截。
 */
interface BindRouteParams {
  phone?: string;
  validation?: string;
  justBindPhone?: boolean;
  isCircle?: boolean;
  userInfoJson?: string;
}

@Entry
@Component
struct BindPhonePage {
  /** 源码 q：手机号 */
  @State phone: string = '';
  /** 源码 v：validation（非空 = 设备验证模式） */
  private validation: string = '';
  /** 源码 x：justBindPhone */
  private justBindPhone: boolean = false;
  /** 源码 y：isCircle */
  private isCircle: boolean = false;
  /** 源码 f1/k3：GXMD 学校 6 格，其余 4 格（k3(4/6)） */
  private cells: number = LoginSession.schoolId === 'GXMD' ? 6 : 4;
  /** 源码 k3：VerifyCodeView 左右 margin，4 格 = y.a(90)=90dip，6 格 = y.a(40)=40dip */
  private sideMargin: number = LoginSession.schoolId === 'GXMD' ? 40 : 90;
  /** 源码 r：验证码输入 */
  @State verifyCode: string = '';
  /** tvCode 倒计时秒（0 = 可点击，源码 CountDownTimer 120000/1000） */
  @State countdown: number = 0;
  /** 是否已成功发码过：倒计时结束后文案为"重新获取"（源码 a.onFinish → R$string.get_again），
   *  首次进页未发码时保持 XML 默认"获取验证码" */
  @State codeSentOnce: boolean = false;
  private countdownTimer: number = -1;
  /** 提交中防重复（源码 g0.i loading 对） */
  @State submitting: boolean = false;
  /** VerifyCodeView 光标闪烁（源码 cursorDuration 500ms） */
  @State cursorOn: boolean = true;
  private cursorTimer: number = -1;
  @StorageProp('currentBreakpoint') currentBreakpoint: string = 'sm';
  @StorageProp('avoidAreaBottomVp') avoidAreaBottomVp: number = 0;
  @StorageProp('keyboardHeightVp') keyboardHeightVp: number = 0;

  aboutToAppear(): void {
    // 源码 y(Intent)：phone/validation/justBindPhone/isCircle/userInfoJson
    const params: object | undefined = router.getParams() as object | undefined;
    if (params !== undefined && params !== null) {
      const rec: BindRouteParams = params as BindRouteParams;
      this.phone = typeof rec.phone === 'string' ? rec.phone : '';
      this.validation = typeof rec.validation === 'string' ? rec.validation : '';
      this.justBindPhone = rec.justBindPhone === true;
      this.isCircle = rec.isCircle === true;
    }
    // 源码 f1()：i3() 页面出现即自动发送验证码
    this.sendCode();
    // 源码 VerifyCodeView 光标 500ms 闪烁
    this.cursorTimer = setInterval(() => {
      this.cursorOn = !this.cursorOn;
    }, 500);
  }

  aboutToDisappear(): void {
    // 源码 onDestroy：this.s.cancel()
    if (this.countdownTimer >= 0) {
      clearInterval(this.countdownTimer);
      this.countdownTimer = -1;
    }
    if (this.cursorTimer >= 0) {
      clearInterval(this.cursorTimer);
      this.cursorTimer = -1;
    }
  }

  /** 源码 i3()：MobileCampusVerifyCodePresenter.b → VerifyCodeModel.M0 getVercode */
  private async sendCode(): Promise<void> {
    try {
      const type: string = this.validation === '' ? '1' : '4';
      const resp = await ApiService.getVerifyCode(this.phone, type, this.isCircle);
      if (resp.code === 1000) {
        return;
      }
      if (resp.code === 0) {
        // 源码 b.g：tvCode.setEnabled(false) + s.start() 120s 倒计时
        this.codeSentOnce = true;
        this.startCountdown();
      } else {
        // 源码 b.f：m(str2) + tvCode.setEnabled(true)
        this.getUIContext().getPromptAction().showToast({ message: resp.message });
      }
    } catch (error) {
      const be = error as BusinessError;
      ApiService.logError('getVercode fail: ' + be.message);
    }
  }

  /** 源码 CountDownTimer a：onTick "已发送(Ns)"，onFinish "重新获取" + 恢复点击 */
  private startCountdown(): void {
    this.countdown = 120;
    if (this.countdownTimer >= 0) {
      clearInterval(this.countdownTimer);
    }
    this.countdownTimer = setInterval(() => {
      this.countdown = this.countdown - 1;
      if (this.countdown <= 0) {
        clearInterval(this.countdownTimer);
        this.countdownTimer = -1;
      }
    }, 1000);
  }

  /** 源码 VerifyCodeView 监听 e：未满位 a → tvNext 禁用；满位 b → tvNext 启用 + r=str */
  private onCodeChange(value: string): void {
    this.verifyCode = value;
  }

  /** 源码 k3(4)/k3(6)：格子序号数组（SDMU=4，GXMD=6） */
  private cellIndexes(): number[] {
    return this.cells === 6 ? [0, 1, 2, 3, 4, 5] : [0, 1, 2, 3];
  }

  /** 源码 h3()：justBindPhone → savePhone；否则设备验证 → bindMobile → bindDevice/add */
  private async afterVerified(): Promise<void> {
    if (this.justBindPhone) {
      await this.savePhoneBind();
    } else {
      await this.bindMobileThenDevice();
    }
  }

  /** 源码 j3() → BindPhoneModel.U0 savePhone（module/c/j/c.new g 回调）：
   *  code=="0"（g 回调，f.java 仅 code=0 进 g）→ toast"绑定手机成功！"；
   *  code!="0" → f 回调 f0.c(context, str2) toast 服务器 message
   *  （源码 g 内的 !"0".equals(code)→"手机号码格式错误" 为不可达防御分支）。
   */
  private async savePhoneBind(): Promise<void> {
    const resp = await ApiService.savePhone(this.phone);
    if (resp.code === 1000) {
      return;
    }
    if (resp.code !== 0) {
      // 源码 g.f：f0.c(context, str2) — toast 服务器返回 message
      this.getUIContext().getPromptAction().showToast({ message: resp.message });
      return;
    }
    this.getUIContext().getPromptAction().showToast({ message: '绑定手机成功！' });
    // 源码 g：!isCircle → setResult(-1)+finish（z=userInfoJson 非空才跳主页，HAP 链路为空）；
    // isCircle（校圈）→ hasSchoolCirclePhone + lyyd.social 昵称同步（独立模块不触达）
    router.back();
  }

  /** 源码 f.g → g3() 设备验证链：bindMobile → bindDevice/add → 跳主页清栈 */
  private async bindMobileThenDevice(): Promise<void> {
    const bindResp = await ApiService.bindMobileLianyi(this.phone);
    if (bindResp.code === 1000) {
      return;
    }
    if (bindResp.code !== 0) {
      // 源码 f.f：m(str2)
      this.getUIContext().getPromptAction().showToast({ message: bindResp.message });
      return;
    }
    // 源码 g3()：BindDevicePImpl.b(s.g(), s.m()) → BindDeviceModel.T0 add {IMEI, sbmc}
    const deviceResp = await ApiService.bindDeviceAdd();
    if (deviceResp.code !== 0) {
      // 源码 h.g：!bool → m("绑定设备失败")
      this.getUIContext().getPromptAction().showToast({ message: '绑定设备失败' });
      return;
    }
    // 源码 h.g：v(validation)非空 → b.d.a.d(true) 设备标记 + g2(e.a.r=主页)清栈；finish
    if (this.validation !== '') {
      router.replaceUrl({ url: 'pages/Index' });
    } else {
      router.back();
    }
  }

  /** 源码 d.onClick：g0.i(true) → MobileCampusVerifyCodePresenter.d → VerifyCodeModel.F verifyVercode */
  private async submitCode(): Promise<void> {
    if (this.submitting || this.verifyCode.length < this.cells) {
      return;
    }
    this.submitting = true;
    try {
      const resp = await ApiService.verifyVerifyCode(this.phone, this.verifyCode, this.isCircle);
      if (resp.code === 1000) {
        return;
      }
      if (resp.code === 0) {
        await this.afterVerified();
      } else {
        // 源码 d$f.f：m(str2)
        this.getUIContext().getPromptAction().showToast({ message: resp.message });
      }
    } catch (error) {
      const be = error as BusinessError;
      ApiService.logError('verifyVercode fail: ' + be.message);
    } finally {
      this.submitting = false;
    }
  }

  /** VerifyCodeView 复刻（module/launch/widget/VerifyCodeView.java singleBox）：
   *  onlyFill 填充 #F2F2F2、corner_size 2dip、spaceSize 6dip、字 20sp @color/textColor=#333333、
   *  光标 cursorColor=@color/colorPrimary→mobile_campus_primary_color=#97000C、cursorWidth 2dip、
   *  高度=getHeight()/2（≈20dip 参考屏）、cursorDuration 500ms 闪烁；
   *  inputBoxSquare=true → 盒宽高相等（盒宽=(可用宽-(n-1)*6)/n，layoutWeight+aspectRatio 等价） */
  @Builder
  codeBox(index: number) {
    Stack({ alignContent: Alignment.Center }) {
      Text(index < this.verifyCode.length ? this.verifyCode.charAt(index) : '')
        .fontSize(20)
        .fontColor('#333333')
      if (index === this.verifyCode.length && this.cursorOn) {
        Rect()
          .width(2)
          .height(20)
          .fill('#97000C')
      }
    }
    .layoutWeight(1)
    .aspectRatio(1)
    .backgroundColor('#F2F2F2')
    .borderRadius(2)
  }

  build() {
    Column() {
      TitleBar({ title: this.validation === '' ? '绑定手机号' : '设备验证', showBack: true })
      Divider()
        .color($r('app.color.divider_grey'))
        .strokeWidth(0.5)
        .width('100%')

      Scroll() {
        Column() {
          Image($r('app.media.mobile_campus_code'))
            .margin({ top: 40 })

          Text('输入验证码')
            .fontSize(16)
            .fontColor($r('app.color.common_color_1'))
            .margin({ top: 12 })

          Row() {
            Text('+86 ' + this.phone)
              .fontSize(13)
              .fontColor($r('app.color.common_color_1'))

            Text(this.countdown > 0 ? '已发送(' + this.countdown + 's)' :
              (this.codeSentOnce ? '重新获取' : '获取验证码'))
              .fontSize(12)
              .fontColor($r('app.color.common_color_5'))
              .backgroundColor(this.countdown > 0 ? '#B8C0C9' : '#1B68B6')
              .borderRadius(4)
              .padding(6)
              .margin({ left: 10 })
              .hoverEffect(HoverEffect.Highlight)
              .onClick(() => {
                if (this.countdown <= 0) {
                  this.sendCode();
                }
              })
          }
          .alignItems(VerticalAlign.Center)
          .margin({ top: 8 })

          // VerifyCodeView 复刻：透明 TextInput 承接输入，上方格子回显。
          Stack({ alignContent: Alignment.TopStart }) {
            Row({ space: 6 }) {
              ForEach(this.cellIndexes(), (idx: number) => {
                this.codeBox(idx)
              }, (idx: number) => 'box_' + idx)
            }
            .width('100%')
            .justifyContent(FlexAlign.Center)

            TextInput({ text: this.verifyCode })
              .type(InputType.Number)
              .enterKeyType(EnterKeyType.Done)
              .maxLength(this.cells)
              .fontSize(20)
              .fontColor(Color.Transparent)
              .caretColor(Color.Transparent)
              .backgroundColor(Color.Transparent)
              .width('100%')
              .height(42)
              .defaultFocus(true)
              .onSubmit(() => {
                this.submitCode();
              })
              .onChange((value: string) => {
                this.onCodeChange(value);
              })
          }
          .width('100%')
          .constraintSize({ maxWidth: 360 })
          .margin({ top: 18 })
          .padding({
            left: this.currentBreakpoint === 'xs' ? 24 : this.sideMargin,
            right: this.currentBreakpoint === 'xs' ? 24 : this.sideMargin
          })

          Text('完成')
            .fontSize(15)
            .fontColor(this.verifyCode.length >= this.cells && !this.submitting ? '#1B68B7' : '#CECECE')
            .padding(10)
            .margin({ top: 48 })
            .hoverEffect(HoverEffect.Highlight)
            .onClick(() => {
              this.submitCode();
            })
        }
        .width('100%')
        .constraintSize({ maxWidth: BreakpointSystem.getContentMaxWidth(this.currentBreakpoint) })
        .padding({ bottom: Math.max(24, this.avoidAreaBottomVp + this.keyboardHeightVp + 16) })
        .alignItems(HorizontalAlign.Center)
      }
      .width('100%')
      .layoutWeight(1)
      .scrollBar(BarState.Off)
      .align(Alignment.Top)
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.ybg_white'))
  }
}
