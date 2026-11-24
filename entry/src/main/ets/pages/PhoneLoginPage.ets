import { router } from '@kit.ArkUI';
import { common } from '@kit.AbilityKit';
import { TitleBar } from '../components/TitleBar';
import { ApiService, CheckLoginPhoneResult } from '../network/ApiService';
import { LoginSession } from '../network/LoginSession';
import { Api } from '../network/Api';
import { ApiResponse } from '../model/ResponseModel';
import { UserInfo } from '../model/UserModel';
import { PreferencesUtil } from '../data/PreferencesUtil';
import { Constants } from '../data/Constants';
import { ImmersiveLightHelper } from '../common/ImmersiveLightHelper';
import { PrivacyWindowHelper } from '../common/PrivacyWindowHelper';
import { BreakpointSystem } from '../common/BreakpointSystem';

/**
 * 手机号登录页 — 1:1 复刻 APK 手机号登录链路（InputIdentifyCodeActivity 188 行 + IdentifyCodeModel）：
 *   阶段1：手机号输入（LoginPage 同款输入行）+ "获取验证码"胶囊 + 底部协议勾选
 *          点击 → ensureNegotiated（协商 key 就绪）→ checkLoginPhone → SendSms 真发短信 → 进阶段2
 *   阶段2：标题"输入验证码" + 插图 + "验证码已发送至 +86 手机号" + 4 位验证码格（VerifyCodeView）
 *          + "Xs后重发" 90s 倒计时（timeFrequency 服务器下发）+ 重发按钮
 *          满 4 位自动 loginBySms → UserEntity → LoginSession 全字段保存持久化 → 进主页
 * 校验（源码 InputIdentifyCodeActivity L436-439）：手机号空 → "请输入您的手机号"；
 *   格式不对 → "手机号格式不对"
 */
@Entry
@Component
struct PhoneLoginPage {
  /** 0=手机号输入 1=验证码输入（同页双阶段，APK 两 Activity 链路复刻） */
  @State stage: number = 0;
  @State phoneNum: string = '';
  @State privacyAgreed: boolean = false;
  @State sending: boolean = false;
  @State codeDigits: string = '';
  @State countDown: number = 0;
  @State logging: boolean = false;
  @StorageProp('currentBreakpoint') currentBreakpoint: string = 'sm';
  @StorageProp('avoidAreaBottomVp') avoidAreaBottomVp: number = 0;
  @StorageProp('keyboardHeightVp') keyboardHeightVp: number = 0;
  private timerId: number = -1;
  /** checkLoginPhone 服务器下发倒计时秒数（源码 InputIdentifyCodeActivity.q=timeSpace，重发沿用同值） */
  private timeFrequency: number = Api.SMS_TIME_FREQUENCY;

  onPageShow(): void {
    const ctx = this.getUIContext().getHostContext() as common.UIAbilityContext;
    PrivacyWindowHelper.enterSensitivePage('PhoneLoginPage', ctx);
  }

  onPageHide(): void {
    const ctx = this.getUIContext().getHostContext() as common.UIAbilityContext;
    PrivacyWindowHelper.leaveSensitivePage('PhoneLoginPage', ctx);
  }

  aboutToDisappear(): void {
    this.stopTimer();
    const ctx = this.getUIContext().getHostContext() as common.UIAbilityContext;
    PrivacyWindowHelper.leaveSensitivePage('PhoneLoginPage', ctx);
  }

  /** 系统返回键：验证码阶段返回手机号输入阶段（APK 返回键同款） */
  onBackPress(): boolean {
    if (this.stage === 1) {
      this.backToPhone();
      return true;
    }
    return false;
  }

  private toast(msg: string): void {
    this.getUIContext().getPromptAction().showToast({ message: msg });
  }

  private stopTimer(): void {
    if (this.timerId !== -1) {
      clearInterval(this.timerId);
      this.timerId = -1;
    }
  }

  /** 手机号格式校验：源码 c0.i = ^1[0-9]\d{9}$（11 位、1 开头、其余全数字；
   *  reviewer 修正：原实现将第二位限 3-9，比源码更严，按 L439 "手机号格式不对" 的实际校验放宽） */
  private isPhoneValid(): boolean {
    if (this.phoneNum.length !== 11) {
      return false;
    }
    if (this.phoneNum[0] !== '1') {
      return false;
    }
    for (let i = 1; i < 11; i++) {
      const c: string = this.phoneNum[i];
      if (c < '0' || c > '9') {
        return false;
      }
    }
    return true;
  }

  private startCountDown(seconds: number): void {
    this.stopTimer();
    this.countDown = seconds > 0 ? seconds : Api.SMS_TIME_FREQUENCY;
    this.timerId = setInterval(() => {
      this.countDown = this.countDown - 1;
      if (this.countDown <= 0) {
        this.stopTimer();
        this.countDown = 0;
      }
    }, 1000);
  }

  /** 阶段1 "获取验证码"：协议校验 → 手机号校验（L436-439）→ 协商 → checkLoginPhone → SendSms */
  private async getSmsCode(): Promise<void> {
    if (this.sending) {
      return;
    }
    if (!this.privacyAgreed) {
      this.toast('请先同意《隐私政策》和《服务协议》');
      return;
    }
    if (this.phoneNum === '') {
      this.toast('请输入您的手机号');
      return;
    }
    if (!this.isPhoneValid()) {
      this.toast('手机号格式不对');
      return;
    }
    this.sending = true;
    try {
      // APK GetKeyUtil 同款：加密请求前确保协商 key 就绪（UC/aesKey 复用或新协商）
      const negotiated: boolean = await LoginSession.ensureNegotiated();
      if (!negotiated) {
        this.toast('无法连接学校服务器，请稍后重试或检查网络');
        this.sending = false;
        return;
      }
      // 源码 f.T0：checkLoginPhone 校验手机号可登录性 + 频率 timeFrequency
      const check: ApiResponse<CheckLoginPhoneResult> = await ApiService.checkLoginPhone(this.phoneNum);
      if (check.code !== 0) {
        const msg: string = check.message.indexOf('网络请求失败') >= 0
          ? '无法连接学校服务器，请稍后重试或检查网络'
          : (check.message === '' ? '请求失败，请稍后重试' : check.message);
        this.toast(msg);
        this.sending = false;
        return;
      }
      if (!check.data.canSendSms) {
        this.toast('当前手机号暂不支持验证码登录');
        this.sending = false;
        return;
      }
      // 源码 f.V0：SendSms 真实下发短信
      const send: ApiResponse<Object> = await ApiService.sendSms(this.phoneNum);
      if (send.code !== 0) {
        this.toast(send.message === '' ? '验证码发送失败，请稍后重试' : send.message);
        this.sending = false;
        return;
      }
      this.timeFrequency = check.data.timeFrequency;
      this.startCountDown(check.data.timeFrequency);
      this.stage = 1;
    } catch (error) {
      this.toast('网络请求失败，请重试');
    }
    this.sending = false;
  }

  /** 阶段2 重发按钮：倒计时结束后可点，重调 SendSms 并沿用 checkLoginPhone 下发时长重启倒计时 */
  private async resendSms(): Promise<void> {
    if (this.countDown > 0 || this.sending) {
      return;
    }
    this.sending = true;
    try {
      const send: ApiResponse<Object> = await ApiService.sendSms(this.phoneNum);
      if (send.code === 0) {
        // 源码 InputIdentifyCodeActivity O2 重发沿用 this.q（首次 timeSpace），非固定 90
        this.startCountDown(this.timeFrequency);
      } else {
        this.toast(send.message === '' ? '验证码发送失败，请稍后重试' : send.message);
      }
    } catch (error) {
      this.toast('网络请求失败，请重试');
    }
    this.sending = false;
  }

  /** 验证码阶段返回手机号阶段（TitleBar 返回键 + 系统返回键共用） */
  private backToPhone(): void {
    this.stopTimer();
    this.countDown = 0;
    this.codeDigits = '';
    this.stage = 0;
  }

  /** 满 4 位自动登录：loginBySms → LoginSession 已在 ApiService 内填充并持久化，
   *  此处与 LoginPage 登录成功处理完全一致（全字段 Preferences 落盘 + 进主页）
   */
  private async doSmsLogin(): Promise<void> {
    if (this.logging) {
      return;
    }
    this.logging = true;
    try {
      const response: ApiResponse<UserInfo> = await ApiService.loginBySms(this.phoneNum, this.codeDigits);
      if (response.code === 0) {
        // 与 LoginPage.doLogin 成功分支逐字段一致
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
        this.toast('登录成功');
        router.replaceUrl({ url: 'pages/Index' });
      } else {
        this.toast('登录失败: ' + response.message);
        // 验证码错误/过期：清空重输
        this.codeDigits = '';
      }
    } catch (error) {
      this.toast('登录异常，请重试');
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

  build() {
    Column() {
      TitleBar({
        title: this.stage === 0 ? '手机号登录' : '输入验证码',
        showBack: true,
        onBack: this.stage === 1 ? (): void => {
          this.backToPhone();
        } : null
      })

      Scroll() {
        Column() {
          if (this.stage === 0) {
            // ===== 阶段1：手机号输入（LoginPage 同款输入行 + 主色胶囊按钮） =====
            Column() {
              Row() {
                Image($r('app.media.mobile_campus_login_phone'))
                  .width(24)
                  .height(24)
                TextInput({ placeholder: '请输入您的手机号', text: this.phoneNum })
                  .type(InputType.PhoneNumber)
                  .enterKeyType(EnterKeyType.Done)
                  .fontSize(17)
                  .fontColor($r('app.color.common_color_1'))
                  .placeholderColor($r('app.color.common_color_3'))
                  .placeholderFont({ size: 17 })
                  .height(42)
                  .padding({ left: 10, right: 0 })
                  .backgroundColor(Color.Transparent)
                  .caretColor($r('app.color.mobile_campus_primary_color'))
                  .layoutWeight(1)
                  .onSubmit(() => {
                    this.getSmsCode();
                  })
                  .onChange((value: string) => {
                    this.phoneNum = value;
                  })

                // 清除按钮：灰圆 ×（有手机号才显示，LoginPage 同款）
                if (this.phoneNum !== '') {
                  Stack({ alignContent: Alignment.Center }) {
                    Text('×')
                      .fontSize(14)
                      .fontColor($r('app.color.white'))
                  }
                  .width(16)
                  .height(16)
                  .borderRadius(8)
                  .backgroundColor($r('app.color.common_color_4'))
                  .hoverEffect(HoverEffect.Highlight)
                  .onClick(() => {
                    this.phoneNum = '';
                  })
                }
              }
              .width('100%')
              .height(46)
              .padding({ left: 24, right: 24 })
              .margin({ top: 30 })
              .alignItems(VerticalAlign.Center)

              Row() {
                Divider()
                  .color($r('app.color.login_divider'))
                  .strokeWidth(0.5)
                  .width('100%')
              }
              .width('100%')
              .padding({ left: 24 })

              // 获取验证码：深红胶囊（同 LoginPage 登录按钮样式，双层衬底防 SMOOTH 档位白底白字）
              Row() {
                Stack({ alignContent: Alignment.Center }) {
                  Text(this.sending ? '发送中...' : '获取验证码')
                    .fontSize(18)
                    .fontColor($r('app.color.white'))
                    .width('100%')
                    .height(46)
                    .textAlign(TextAlign.Center)
                    .backgroundColor($r('app.color.mobile_campus_primary_color'))
                    .borderRadius(23)
                    .systemMaterial(ImmersiveLightHelper.primaryButtonMaterial())
                }
                .width('100%')
                .height(46)
                .backgroundColor($r('app.color.mobile_campus_primary_color'))
                .borderRadius(23)
                .clickEffect({ level: ClickEffectLevel.LIGHT, scale: 0.97 })
                .hoverEffect(HoverEffect.Highlight)
                .onClick(() => {
                  this.getSmsCode();
                })
              }
              .width('100%')
              .constraintSize({ maxWidth: 480 })
              .padding({ left: 33, right: 33 })
              .margin({ top: 30 })
            }
            .width('100%')
            .alignItems(HorizontalAlign.Center)
          } else {
            // ===== 阶段2：输入验证码（InputIdentifyCodeActivity + VerifyCodeView 复刻） =====
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

                // 源码 InputIdentifyCodeActivity f1()：this.l.setText("+86 " + this.p) 原样手机号
                Text('+86 ' + this.phoneNum)
                  .fontSize(13)
                  .fontColor($r('app.color.mobile_campus_primary_color'))
                  .padding({ left: 10 })
              }
              .margin({ top: 4 })
              .alignItems(VerticalAlign.Center)

              // 4 位验证码格（单行方格 40vp，间距 3vp）+ 隐藏输入框叠加接收输入
              Stack() {
                Row({ space: 3 }) {
                  ForEach([0, 1, 2, 3, 4, 5], (idx: number) => {
                    Text(this.digitAt(idx))
                      .fontSize(20)
                      .fontColor($r('app.color.common_color_1'))
                      .textAlign(TextAlign.Center)
                      .width(40)
                      .height(40)
                      .backgroundColor($r('app.color.common_color_6'))
                      .borderRadius(1)
                  }, (idx: number) => `sms_code_box_${idx}`)
                }
                .alignItems(VerticalAlign.Center)

                TextInput({ text: this.codeDigits })
                  .type(InputType.Number)
                  .enterKeyType(EnterKeyType.Done)
                  .maxLength(6)
                  .opacity(0)
                  .width(255)
                  .height(40)
                  .caretColor(Color.Transparent)
                  .onSubmit(() => {
                    if (this.codeDigits.length >= 4 && !this.logging) {
                      this.doSmsLogin();
                    }
                  })
                  .onChange((value: string) => {
                    this.codeDigits = value;
                    // APK VerifyCodeView 同款：满 4 位自动 loginBySms
                    if (value.length === 4 && !this.logging) {
                      this.doSmsLogin();
                    }
                  })
              }
              .margin({ top: 9 })

              Text(this.logging ? '正在登录...' : '')
                .fontSize(13)
                .fontColor($r('app.color.common_color_2'))
                .margin({ top: 8 })

              // 重发按钮：倒计时中 "Xs后重发"（置灰不可点），归零后 "重新获取"
              Text(this.countDown > 0 ? `${this.countDown}s后重发` : '重新获取')
                .fontSize(15)
                .fontColor(this.countDown > 0 ?
                  $r('app.color.common_color_3') : $r('app.color.mobile_campus_primary_color'))
                .padding({ left: 10, right: 10, top: 12, bottom: 12 })
                .borderRadius(25)
                .border({
                  width: 1,
                  color: this.countDown > 0 ?
                    $r('app.color.common_color_3') : $r('app.color.mobile_campus_primary_color')
                })
                .backgroundColor($r('app.color.white'))
                .margin({ top: 24 })
                .hoverEffect(HoverEffect.Highlight)
                .onClick(() => {
                  this.resendSms();
                })
            }
            .width('100%')
            .alignItems(HorizontalAlign.Center)
          }

          Blank().layoutWeight(1)

          // ===== 底部圆形 radio 同意行（LoginPage 同款） =====
          Row() {
            Stack({ alignContent: Alignment.Center }) {
              Circle()
                .width(20)
                .height(20)
                .fill(Color.White)
                .stroke($r('app.color.mobile_campus_primary_color'))
                .strokeWidth(1.5)
              if (this.privacyAgreed) {
                Circle()
                  .width(11)
                  .height(11)
                  .fill($r('app.color.mobile_campus_primary_color'))
              }
            }
            .hoverEffect(HoverEffect.Highlight)
            .onClick(() => {
              this.privacyAgreed = !this.privacyAgreed;
            })

            Text('同意')
              .fontSize(15)
              .fontColor($r('app.color.common_color_1'))
              .margin({ left: 8 })

            Text('《隐私政策》')
              .fontSize(15)
              .fontColor($r('app.color.mobile_campus_primary_color'))
              .hoverEffect(HoverEffect.Highlight)
              .onClick(() => {
                router.pushUrl({
                  url: 'pages/PrivacyTextPage',
                  params: { type: 'privacy' }
                });
              })

            Text('和')
              .fontSize(15)
              .fontColor($r('app.color.common_color_1'))

            Text('《服务协议》')
              .fontSize(15)
              .fontColor($r('app.color.mobile_campus_primary_color'))
              .hoverEffect(HoverEffect.Highlight)
              .onClick(() => {
                router.pushUrl({
                  url: 'pages/PrivacyTextPage',
                  params: { type: 'service' }
                });
              })
          }
          .width('100%')
          .justifyContent(FlexAlign.Center)
          .margin({ top: 24, bottom: Math.max(24, this.avoidAreaBottomVp + this.keyboardHeightVp + 16) })
        }
        .width('100%')
        .constraintSize({ minHeight: '100%', maxWidth: BreakpointSystem.getContentMaxWidth(this.currentBreakpoint) })
        .alignItems(HorizontalAlign.Center)
      }
      .width('100%')
      .layoutWeight(1)
      .scrollBar(BarState.Off)
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.main_bg'))
  }
}
