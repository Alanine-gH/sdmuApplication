import { router } from '@kit.ArkUI';
import { BusinessError } from '@kit.BasicServicesKit';
import { TitleBar } from '../components/TitleBar';
import { ApiService } from '../network/ApiService';
import { LoginSession } from '../network/LoginSession';
import { ApiResponse } from '../model/ResponseModel';
import { UserInfo } from '../model/UserModel';
import { PreferencesUtil } from '../data/PreferencesUtil';
import { Constants } from '../data/Constants';

/**
 * 输入验证码页 — 1:1 复刻 InputIdentifyCodeActivity（188 行）
 * + mobile_campus_activity_input_identify_code.xml + VerifyCodeView(singleBox)
 * [W22 launch-chain] 源码级翻译：
 *   布局：ybg_white + toolbar_normal（H0()="" → 标题空）+ divider + 居中列：
 *     插图 mobile_campus_code(mt 80dip=40vp) + "输入验证码" 18sp(mt 24dip=12vp)
 *     + "验证码已发送至" 13sp + tvPhone 13sp primary(padL 20dip=10vp)（mt 8dip=4vp）
 *     + VerifyCodeView mt 18dip=9vp（contentNumber=4/GXMD 6，singleBox onlyFill fill #f2f2f2
 *       corner 2dip=1vp space 6dip=3vp 20sp；P2 margins：4 位左右 90dip=45vp / 6 位 40dip=20vp）
 *     + tvNext"完成"（XML gone 且源码无显示逻辑 → 保真省略渲染）
 *     + tvCode"重新获取" 15sp(padL/R 20dip=10vp padTB 12dip=6vp mt 96dip=48vp 圆角 1024dip
 *       白底描边，enabled primary/disabled #999999)。
 *   y(Intent)：p=phone、q=timeSpace(缺省 90)、r=isSendSms(缺省 true)
 *     （来源 MobileCampusLoginNewActivity m 回调：checkLoginPhone 的 timeFrequency/canSendSms）。
 *   f1()：P2(GXMD?6:4)；tvPhone = "+86 " + phone；r=true → O2() 自动发码；否则 tvCode 禁用。
 *   O2() → IdentifyCodeModel.W0：POST /open/auth/SendSms {phoneNum}（GXMD 另加 codeNum=6）
 *     → g：toast"验证码发送成功"+tvCode 禁用+q 秒倒计时（框架 util f.a(3,q) → EventBus 1/2：
 *     "Ns后重发"/"重新获取"恢复）；f：toast(message)。
 *   满 4 位自动登录（VerifyCodeView b 回调）→ U0：POST /open/auth/loginBySms
 *     body=AES(LoginSumbitEntity{userId:""passw:"",schoolId,phoneNum,checkCode,…})
 *     → g：存会话+initAtLogin+finishAllActivities+g2(e.a.r=/launch/logined)；f：toast(message)。
 * 入口链（APK MobileCampusLoginNewActivity L549）：手机号登录 checkLoginPhone 通过 →
 *   g2(e.a.m1=/launch/inputIdentifyCode)。HAP 由 PhoneLoginPage（W4 已验收同页双阶段等价实现）
 *   承载同链路，本页为该 Activity 的源码级 1:1 独立实现。
 */
@Entry
@Component
struct InputIdentifyCodePage {
  /** 源码 p：手机号（intent extra "phone"） */
  @State phoneText: string = '';
  /** 源码 o：VerifyCodeView 已输内容 */
  @State codeDigits: string = '';
  /** 源码 tvCode 文案与可用态（f.a(3,q) 倒计时等价） */
  @State codeBtnText: string = '重新获取';
  @State codeBtnEnabled: boolean = false;
  /** 源码 q：timeSpace（intent extra，缺省 90） */
  private timeSpace: number = 90;
  /** 源码 r：isSendSms（intent extra，缺省 true） */
  private isSendSms: boolean = true;
  /** 源码 P2 内容位数：GXMD → 6，其余 4 */
  private contentNumber: number = 4;
  private countdownTimerId: number = -1;
  /** 登录中防重复 */
  @State logging: boolean = false;
  /** 发码中防重复 */
  @State sending: boolean = false;

  aboutToAppear(): void {
    // 源码 y(Intent)：phone/timeSpace/isSendSms
    const params: object | undefined = router.getParams() as object | undefined;
    if (params !== undefined && params !== null) {
      const rec = params as Record<string, Object>;
      const phone: Object = rec['phone'];
      if (typeof phone === 'string') {
        this.phoneText = phone as string;
      }
      const ts: Object = rec['timeSpace'];
      if (typeof ts === 'number') {
        this.timeSpace = ts as number;
      }
      const sms: Object = rec['isSendSms'];
      if (typeof sms === 'boolean') {
        this.isSendSms = sms as boolean;
      }
    }
    // 源码 f1()：P2(GXMD?6:4)（schoolId 校验保真，SDMU 走 4）
    this.contentNumber = LoginSession.schoolId === 'GXMD' ? 6 : 4;
    // 源码：tvPhone = "+86 " + p
    if (this.isSendSms) {
      this.O2();
    } else {
      this.codeBtnEnabled = false;
    }
  }

  aboutToDisappear(): void {
    if (this.countdownTimerId !== -1) {
      clearInterval(this.countdownTimerId);
      this.countdownTimerId = -1;
    }
  }

  private toast(msg: string): void {
    this.getUIContext().getPromptAction().showToast({ message: msg });
  }

  /** 源码 O2()：W0(phone) → SendSms */
  private async O2(): Promise<void> {
    if (this.sending) {
      return;
    }
    this.sending = true;
    try {
      const resp: ApiResponse<Object> = await ApiService.sendSms(this.phoneText);
      if (resp.code === 1000) {
        return;
      }
      if (resp.code !== 0) {
        // 源码 c.f：m(str2)
        this.toast(resp.message);
        return;
      }
      // 源码 c.g：m("验证码发送成功") + m.setEnabled(false) + f.a(3, q)
      this.toast('验证码发送成功');
      this.codeBtnEnabled = false;
      this.startCountdown(this.timeSpace);
    } catch (error) {
      const be = error as BusinessError;
      ApiService.logError('sendSms fail: ' + be.message);
      this.toast('网络请求失败，请重试');
    } finally {
      this.sending = false;
    }
  }

  /** 源码 framework util f.a(3, q)：q 秒倒计时 → EventBus 1(data=剩余秒)/2(结束) */
  private startCountdown(seconds: number): void {
    if (this.countdownTimerId !== -1) {
      clearInterval(this.countdownTimerId);
      this.countdownTimerId = -1;
    }
    let remain: number = seconds > 0 ? seconds : 90;
    this.codeBtnText = remain + 's后重发';
    this.countdownTimerId = setInterval(() => {
      remain--;
      if (remain <= 0) {
        // EventBus code 2：tvCode = get_again("重新获取") + enabled=true
        if (this.countdownTimerId !== -1) {
          clearInterval(this.countdownTimerId);
          this.countdownTimerId = -1;
        }
        this.codeBtnText = '重新获取';
        this.codeBtnEnabled = true;
        return;
      }
      // EventBus code 1：tvCode = jLongValue + "s后重发"
      this.codeBtnText = remain + 's后重发';
    }, 1000);
  }

  /** 源码 a.b(str)：满 4/6 位自动 loginBySms */
  private async onCodeComplete(code: string): Promise<void> {
    if (this.logging) {
      return;
    }
    this.logging = true;
    try {
      const response: ApiResponse<UserInfo> = await ApiService.loginBySms(this.phoneText, code);
      if (response.code === 1000) {
        return;
      }
      if (response.code !== 0) {
        // 源码 C0375a.f：m(str2)
        this.toast(response.message);
        this.codeDigits = '';
        return;
      }
      // 源码 C0375a.g：d.a.f(userEntity) + b.g/b.f + initAtLogin + finishAllActivities + g2(e.a.r)
      await PreferencesUtil.putBoolean(Constants.KEY_IS_LOGIN, true);
      await PreferencesUtil.putString(Constants.KEY_USER_ID, response.data.userId);
      await PreferencesUtil.putString(Constants.KEY_USER_NAME, response.data.name);
      await PreferencesUtil.putString(Constants.KEY_USER_DEPARTMENT, response.data.college);
      await PreferencesUtil.putString(Constants.KEY_USER_MAJOR, response.data.major);
      await PreferencesUtil.putString(Constants.KEY_USER_CLASS, response.data.className);
      await PreferencesUtil.putString(Constants.KEY_USER_GRADE, response.data.grade);
      await PreferencesUtil.putString(Constants.KEY_USER_PHONE, response.data.phone);
      await PreferencesUtil.putString(Constants.KEY_USER_TYPE,
        LoginSession.userType === '' ? '1' : LoginSession.userType);
      await PreferencesUtil.putString(Constants.KEY_TOKEN, response.data.token);
      // 源码 g2(e.a.r = /launch/logined → LoginedLaunchActivity)
      router.replaceUrl({ url: 'pages/LoginedLaunchPage', params: { 'jpushExtra': '' } });
    } catch (error) {
      const be = error as BusinessError;
      ApiService.logError('loginBySms fail: ' + be.message);
      this.toast('网络请求失败，请重试');
      this.codeDigits = '';
    }
    this.logging = false;
  }

  private digitAt(idx: number): string {
    if (idx < this.codeDigits.length) {
      return this.codeDigits[idx];
    }
    return '';
  }

  /** tvCode 点击（源码 Y0 → O2，仅倒计时结束后可点） */
  private onResend(): void {
    if (!this.codeBtnEnabled) {
      return;
    }
    this.O2();
  }

  build() {
    Column() {
      // toolbar_normal：H0()="" → 标题空
      TitleBar({ title: '', showBack: true })
      // divider_horizontal_grey_thin
      Divider()
        .color($r('app.color.divider_grey'))
        .strokeWidth(0.5)
        .width('100%')

      Column() {
        Image($r('app.media.mobile_campus_code'))
          .width(57)
          .height(97)
          .margin({ top: 40 })

        Text('输入验证码')
          .fontSize(18)
          .fontColor($r('app.color.common_color_1'))
          .margin({ top: 12 })

        Row() {
          Text('验证码已发送至')
            .fontSize(13)
            .fontColor($r('app.color.black'))

          Text('+86 ' + this.phoneText)
            .fontSize(13)
            .fontColor($r('app.color.mobile_campus_primary_color'))
            .padding({ left: 10 })
        }
        .margin({ top: 4 })
        .alignItems(VerticalAlign.Center)

        // VerifyCodeView（singleBox 方格 + 叠加透明输入框；P2 margins：4 位左右 45vp）
        Stack() {
          Row({ space: 3 }) {
            ForEach(Array.from({ length: this.contentNumber }, (v: Object, i: number) => i), (idx: number) => {
              Text(this.digitAt(idx))
                .fontSize(20)
                .fontColor($r('app.color.textColor'))
                .textAlign(TextAlign.Center)
                .width(40)
                .height(40)
                .backgroundColor('#F2F2F2')
                .borderRadius(1)
            }, (idx: number) => `code_box_${idx}`)
          }
          .alignItems(VerticalAlign.Center)

          TextInput({ text: this.codeDigits })
            .type(InputType.Number)
            .maxLength(this.contentNumber)
            .opacity(0)
            .width(this.contentNumber * 40 + (this.contentNumber - 1) * 3)
            .height(40)
            .caretColor(Color.Transparent)
            .onChange((value: string) => {
              this.codeDigits = value;
              // 源码 VerifyCodeView：输入满 contentNumber 位 → b(str) 自动提交
              if (value.length >= this.contentNumber) {
                this.onCodeComplete(value);
              }
            })
        }
        .margin({ top: 9, left: 45, right: 45 })

        // tvNext"完成"：XML visibility=gone 且源码无显示逻辑 → 保真省略渲染

        // tvCode BLTextView"重新获取"
        Text(this.codeBtnText)
          .fontSize(15)
          .fontColor(this.codeBtnEnabled ? $r('app.color.mobile_campus_primary_color') : '#999999')
          .padding({ left: 10, right: 10, top: 6, bottom: 6 })
          .borderRadius(512)
          .border({
            width: 1,
            color: this.codeBtnEnabled ? $r('app.color.mobile_campus_primary_color') : '#999999'
          })
          .backgroundColor($r('app.color.white'))
          .margin({ top: 48 })
          .onClick(() => {
            this.onResend();
          })
      }
      .width('100%')
      .height('100%')
      .alignItems(HorizontalAlign.Center)
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.ybg_white'))
  }
}
