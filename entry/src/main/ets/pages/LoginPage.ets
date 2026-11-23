import { router } from '@kit.ArkUI';
import { common } from '@kit.AbilityKit';
import { ApiService } from '../network/ApiService';
import { LoginSession } from '../network/LoginSession';
import { PreferencesUtil } from '../data/PreferencesUtil';
import { Constants } from '../data/Constants';
import { ImmersiveLightHelper } from '../common/ImmersiveLightHelper';
import { BreakpointSystem } from '../common/BreakpointSystem';
import { PrivacyWindowHelper } from '../common/PrivacyWindowHelper';

/**
 * 登录页 — 按 APK 实拍（900x1600/240dpi 逐像素映射 600dp 宽）重构：
 *   1. 顶部 310dp 航拍背景 + 白色椭圆弧过渡 + 中央圆校徽（白边 5dp）
 *   2. 账号行：红色人形图标 + TextInput + 清除按钮（灰圆×）
 *   3. 密码行：红色锁图标 + TextInput + 眼睛（开/闭）
 *   4. 忘记密码 / 登录帮助 行
 *   5. 登录：深红胶囊（左右 33dp、高 46dp、radius 23）
 *   6. 手机号登录：白底红描边胶囊
 *   7. 底部圆形 radio（红圈红点）+ 同意《隐私政策》和《服务协议》
 */
@Entry
@Component
struct LoginPage {
  @State account: string = '';
  @State password: string = '';
  @State passwordVisible: boolean = false;
  @State privacyAgreed: boolean = false;
  @State isLogging: boolean = false;
  @StorageProp('currentBreakpoint') currentBreakpoint: string = 'sm';

  onPageShow(): void {
    const ctx = this.getUIContext().getHostContext() as common.UIAbilityContext;
    PrivacyWindowHelper.enterSensitivePage('LoginPage', ctx);
  }

  onPageHide(): void {
    const ctx = this.getUIContext().getHostContext() as common.UIAbilityContext;
    PrivacyWindowHelper.leaveSensitivePage('LoginPage', ctx);
  }

  aboutToDisappear(): void {
    const ctx = this.getUIContext().getHostContext() as common.UIAbilityContext;
    PrivacyWindowHelper.leaveSensitivePage('LoginPage', ctx);
  }

  private async doLogin(): Promise<void> {
    if (!this.privacyAgreed) {
      this.getUIContext().getPromptAction().showToast({ message: '请先同意《隐私政策》和《服务协议》' });
      return;
    }
    if (this.account === '') {
      this.getUIContext().getPromptAction().showToast({ message: '请输入您的账号' });
      return;
    }
    if (this.password === '') {
      this.getUIContext().getPromptAction().showToast({ message: '请输入您的密码' });
      return;
    }
    this.isLogging = true;
    try {
      const response = await ApiService.login(this.account, this.password);
      if (response.code === 0) {
        await PreferencesUtil.putBoolean(Constants.KEY_IS_LOGIN, true);
        await PreferencesUtil.putString(Constants.KEY_USER_ID, response.data.userId);
        await PreferencesUtil.putString(Constants.KEY_USER_NAME, response.data.name);
        await PreferencesUtil.putString(Constants.KEY_USER_DEPARTMENT, response.data.college);
        await PreferencesUtil.putString(Constants.KEY_USER_MAJOR, response.data.major);
        await PreferencesUtil.putString(Constants.KEY_USER_CLASS, response.data.className);
        await PreferencesUtil.putString(Constants.KEY_USER_GRADE, response.data.grade);
        await PreferencesUtil.putString(Constants.KEY_USER_PHONE, response.data.phone);
        await PreferencesUtil.putString(Constants.KEY_USER_TYPE, LoginSession.userType === '' ? '1' : LoginSession.userType);
        await PreferencesUtil.putString(Constants.KEY_TOKEN, response.data.token);
        this.getUIContext().getPromptAction().showToast({ message: '登录成功' });
        router.replaceUrl({ url: 'pages/Index' });
      } else {
        this.getUIContext().getPromptAction().showToast({ message: '登录失败: ' + response.message });
      }
    } catch (error) {
      this.getUIContext().getPromptAction().showToast({ message: '登录异常，请重试' });
    }
    this.isLogging = false;
  }

  build() {
    Stack({ alignContent: Alignment.TopStart }) {
      Column() {
        // ===== 1. 顶部航拍背景 + 白椭圆弧 + 圆校徽 =====
        Stack({ alignContent: Alignment.Bottom }) {
          // ivBg：航拍图 310dp 高 centerCrop
          Image($r('app.media.mobile_campus_login_bg'))
            .width('100%')
            .height(310)
            .objectFit(ImageFit.Cover)

          // 白色椭圆弧：宽超屏、横跨图底，形成 APK 同款下弧过渡
          Column()
            .width('170%')
            .height(120)
            .borderRadius(60)
            .backgroundColor($r('app.color.main_bg'))
            .margin({ bottom: -84 })
            .alignSelf(ItemAlign.Center)

          // 校徽圆章：直径 97dp 白边 5dp，完整骑在弧线上（APK 位置：图案中心约在弧上方）
          Image($r('app.media.mobile_campus_school_logo'))
            .width(97)
            .height(97)
            .borderRadius(48.5)
            .border({ width: 5, color: $r('app.color.main_bg') })
            .margin({ bottom: 2 })
        }
        .width('100%')
        .height(310)

        // ===== 2. 账号行 =====
        Row() {
          Image($r('app.media.mobile_campus_login_username'))
            .width(24)
            .height(24)
          TextInput({ placeholder: '请输入您的账号', text: this.account })
            .type(InputType.USER_NAME)
            .fontSize(17)
            .fontColor($r('app.color.common_color_1'))
            .placeholderColor($r('app.color.common_color_3'))
            .placeholderFont({ size: 17 })
            .height(42)
            .padding({ left: 10, right: 0 })
            .backgroundColor(Color.Transparent)
            .caretColor($r('app.color.mobile_campus_primary_color'))
            .layoutWeight(1)
            .onChange((value: string) => {
              this.account = value;
            })

          // 清除按钮：灰圆 ×（有账号才显示）
          if (this.account !== '') {
            Stack({ alignContent: Alignment.Center }) {
              Text('×')
                .fontSize(14)
                .fontColor($r('app.color.white'))
            }
            .width(16)
            .height(16)
            .borderRadius(8)
            .backgroundColor($r('app.color.common_color_4'))
            .onClick(() => {
              this.account = '';
            })
          }
        }
        .width('100%')
        .height(46)
        .padding({ left: 24, right: 24 })
        .alignItems(VerticalAlign.Center)

        Divider()
          .color($r('app.color.login_divider'))
          .strokeWidth(0.5)
          .width('100%')
          .margin({ left: 24 })
          .strokeWidth(0.5)

        // ===== 3. 密码行 =====
        Row() {
          Image($r('app.media.mobile_campus_login_password'))
            .width(24)
            .height(24)
          TextInput({ placeholder: '请输入您的密码', text: this.password })
            .type(this.passwordVisible ? InputType.Normal : InputType.Password)
            .showPasswordIcon(false)
            .fontSize(17)
            .fontColor($r('app.color.common_color_1'))
            .placeholderColor($r('app.color.common_color_3'))
            .placeholderFont({ size: 17 })
            .height(42)
            .padding({ left: 10, right: 0 })
            .backgroundColor(Color.Transparent)
            .caretColor($r('app.color.mobile_campus_primary_color'))
            .layoutWeight(1)
            .onChange((value: string) => {
              this.password = value;
            })

          // 眼睛：开/闭
          Image(this.passwordVisible ? $r('app.media.eyes_status_open') : $r('app.media.eyes_status_close'))
            .width(20)
            .height(20)
            .margin({ left: 12 })
            .onClick(() => {
              this.passwordVisible = !this.passwordVisible;
            })
        }
        .width('100%')
        .height(46)
        .padding({ left: 24, right: 24 })
        .margin({ top: 8 })
        .alignItems(VerticalAlign.Center)

        Divider()
          .color($r('app.color.login_divider'))
          .strokeWidth(0.5)
          .width('100%')

        // ===== 4. 忘记密码 / 登录帮助 =====
        Row() {
          Text('忘记密码')
            .fontSize(15)
            .fontColor($r('app.color.common_color_2'))
          Blank()
          Text('登录帮助')
            .fontSize(15)
            .fontColor($r('app.color.common_color_2'))
        }
        .width('100%')
        .padding({ left: 24, right: 24, top: 14, bottom: 6 })

        // ===== 5. 登录胶囊按钮（外层 padding 控制左右 33dp，APK 同款） =====
        Row() {
          Text(this.isLogging ? '登录中...' : '登录')
            .fontSize(18)
            .fontColor($r('app.color.white'))
            .width('100%')
            .height(46)
            .textAlign(TextAlign.Center)
            .backgroundColor(ImmersiveLightHelper.fallbackBg($r('app.color.mobile_campus_primary_color')))
            .borderRadius(23)
            .systemMaterial(ImmersiveLightHelper.primaryButtonMaterial())
            .clickEffect({ level: ClickEffectLevel.LIGHT, scale: 0.97 })
            .onClick(() => {
              this.doLogin();
            })
        }
        .width('100%')
        .constraintSize({ maxWidth: BreakpointSystem.isCompactWidth(this.currentBreakpoint) ? '100%' : 480 })
        .padding({ left: 33, right: 33 })
        .margin({ top: 14 })

        // ===== 6. 手机号登录描边胶囊 =====
        Row() {
          Text('手机号登录')
            .fontSize(18)
            .fontColor($r('app.color.mobile_campus_primary_color'))
            .width('100%')
            .height(46)
            .textAlign(TextAlign.Center)
            .backgroundColor(ImmersiveLightHelper.fallbackBg($r('app.color.white')))
            .borderRadius(23)
            .border(ImmersiveLightHelper.isSupported() ? undefined : {
              width: 1,
              color: $r('app.color.mobile_campus_primary_color')
            })
            .systemMaterial(ImmersiveLightHelper.secondaryButtonMaterial())
            .clickEffect({ level: ClickEffectLevel.LIGHT, scale: 0.97 })
            .onClick(() => {
              // [W4 sms-login] 跳转手机号登录页（InputIdentifyCodeActivity 链路复刻）
              router.pushUrl({ url: 'pages/PhoneLoginPage' });
            })
        }
        .width('100%')
        .constraintSize({ maxWidth: BreakpointSystem.isCompactWidth(this.currentBreakpoint) ? '100%' : 480 })
        .padding({ left: 33, right: 33 })
        .margin({ top: 14 })

        Blank()

        // ===== 7. 底部圆形 radio 同意行 =====
        Row() {
          // 圆形 radio：未选红圈空心 / 已选红圈+红点
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
            .onClick(() => {
              router.pushUrl({
                url: 'pages/WebViewPage',
                params: { url: 'https://www.sdmu.edu.cn/', title: '隐私政策' }
              });
            })

          Text('和')
            .fontSize(15)
            .fontColor($r('app.color.common_color_1'))

          Text('《服务协议》')
            .fontSize(15)
            .fontColor($r('app.color.mobile_campus_primary_color'))
            .onClick(() => {
              router.pushUrl({
                url: 'pages/WebViewPage',
                params: { url: 'https://www.sdmu.edu.cn/', title: '服务协议' }
              });
            })
        }
        .width('100%')
        .justifyContent(FlexAlign.Center)
        .margin({ bottom: 46 })
      }
      .width('100%')
      .height('100%')
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.main_bg'))
  }
}
