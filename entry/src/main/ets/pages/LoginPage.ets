import { router } from '@kit.ArkUI';
import { ApiService } from '../network/ApiService';
import { PreferencesUtil } from '../data/PreferencesUtil';
import { Constants } from '../data/Constants';

/**
 * 登录页 — 1:1 复刻 mobile_campus_activity_login_new.xml
 * 结构：RelativeLayout(main_bg白)
 *   1. layoutTop 243vp：ivBg 登录背景图(paddingBottom 50vp) + ivIcon 校徽 100vp 底部居中
 *   2. 输入区：paddingH 32vp、marginTop 32vp；tiAccount/tiPwd 18fp(common_color_1)，
 *      分隔线 #E5E5E5 0.5vp；ivEyes 50vp 宽(paddingH 15vp)
 *   3. tvLogin：胶囊按钮 radius 1024dip、solid #97000C、白字 18fp、paddingV 9vp
 *   4. 底部隐私行：勾选框 + 同意《隐私政策》和《服务协议》，marginBottom 31vp
 */
@Entry
@Component
struct LoginPage {
  @State account: string = '';
  @State password: string = '';
  @State passwordVisible: boolean = false;
  @State privacyAgreed: boolean = false;
  @State isLogging: boolean = false;

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
    Column() {
      // layoutTop：px_to_dip_486 / 2 = 243vp
      Stack({ alignContent: Alignment.Bottom }) {
        // ivBg：fill_parent + paddingBottom 50dip → 内容区 193vp，centerCrop
        Image($r('app.media.mobile_campus_login_bg'))
          .width('100%')
          .height(243)
          .padding({ bottom: 50 })
          .objectFit(ImageFit.Cover)
        // ivIcon：100dip x 100dip，gravity bottom|center
        Image($r('app.media.mobile_campus_school_logo'))
          .width(100)
          .height(100)
      }
      .width('100%')
      .height(243)

      // 输入区：marginTop 32vp、paddingLeft/Right 32vp（layoutContainer 内 LinearLayout）
      Column() {
        // tiAccount 账号输入：18fp、#333333、paddingTop/Bottom 10vp
        TextInput({ placeholder: $r('app.string.school_account'), text: this.account })
          .type(InputType.USER_NAME)
          .fontSize(18)
          .fontColor($r('app.color.common_color_1'))
          .placeholderColor($r('app.color.common_color_3'))
          .placeholderFont({ size: 18 })
          .height(45)
          .padding({ top: 10, bottom: 10, left: 0, right: 40 })
          .backgroundColor(Color.Transparent)
          .caretColor($r('app.color.mobile_campus_primary_color'))
          .onChange((value: string) => {
            this.account = value;
          })

        // 分隔线：#ffe5e5e5、0.5dip
        Divider()
          .color($r('app.color.login_divider'))
          .strokeWidth(0.5)
          .width('100%')

        // 密码行：tiPwd + ivEyes(50dip 宽、paddingH 15dip)
        Row() {
          TextInput({ placeholder: $r('app.string.password'), text: this.password })
            .type(InputType.Password)
            .showPasswordIcon(false)
            .fontSize(18)
            .fontColor($r('app.color.common_color_1'))
            .placeholderColor($r('app.color.common_color_3'))
            .placeholderFont({ size: 18 })
            .height(45)
            .padding({ top: 10, bottom: 10, left: 0, right: 0 })
            .backgroundColor(Color.Transparent)
            .caretColor($r('app.color.mobile_campus_primary_color'))
            .layoutWeight(1)
            .onChange((value: string) => {
              this.password = value;
            })

          // ivEyes：eyes_status_close / eyes_status_open
          Image(this.passwordVisible ? $r('app.media.eyes_status_open') : $r('app.media.eyes_status_close'))
            .width(20)
            .height(20)
            .margin({ left: 15, right: 15 })
            .onClick(() => {
              this.passwordVisible = !this.passwordVisible;
            })
        }
        .width('100%')
        .height(45)

        // 分隔线：#ffe5e5e5、0.5dip
        Divider()
          .color($r('app.color.login_divider'))
          .strokeWidth(0.5)
          .width('100%')
      }
      .width('100%')
      .padding({ left: 32, right: 32 })
      .margin({ top: 32 })

      // tvLogin：BLTextView 胶囊按钮，bl_solid #97000C、radius 1024dip、白字 18fp、paddingV 9vp
      Text(this.isLogging ? '登录中...' : $r('app.string.login_label'))
        .fontSize(18)
        .fontColor($r('app.color.white'))
        .width('100%')
        .height(44)
        .textAlign(TextAlign.Center)
        .padding({ top: 9, bottom: 9 })
        .backgroundColor($r('app.color.mobile_campus_primary_color'))
        .borderRadius(22)
        .margin({ top: 32 })
        .onClick(() => {
          this.doLogin();
        })

      Blank()

      // 底部隐私行：alignParentBottom、centerHorizontal、marginBottom 31vp(px62/2)
      Row() {
        // cb_privacy_policy_agree：mobile_campus_privacy_cb 选择器
        Image(this.privacyAgreed ? $r('app.media.mobile_campus_privacy_selected') :
          $r('app.media.mobile_campus_privacy_not_selected'))
          .width(20)
          .height(20)
          .margin({ right: 12 })
          .onClick(() => {
            this.privacyAgreed = !this.privacyAgreed;
          })

        Text($r('app.string.privacy_agree'))
          .fontSize(14)
          .fontColor($r('app.color.common_color_1'))

        Text($r('app.string.privacy_policy'))
          .fontSize(14)
          .fontColor($r('app.color.mobile_campus_primary_color'))
          .onClick(() => {
            router.pushUrl({
              url: 'pages/WebViewPage',
              params: { url: 'https://www.sdgu.edu.cn/', title: '隐私政策' }
            });
          })

        Text($r('app.string.privacy_and'))
          .fontSize(14)
          .fontColor($r('app.color.common_color_1'))

        Text($r('app.string.service_policy'))
          .fontSize(14)
          .fontColor($r('app.color.mobile_campus_primary_color'))
          .onClick(() => {
            router.pushUrl({
              url: 'pages/WebViewPage',
              params: { url: 'https://www.sdgu.edu.cn/', title: '服务协议' }
            });
          })
      }
      .width('100%')
      .margin({ bottom: 31 })
      .justifyContent(FlexAlign.Center)
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.main_bg'))
  }
}
