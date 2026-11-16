import { router } from '@kit.ArkUI';
import { ApiService } from '../network/ApiService';
import { PreferencesUtil } from '../data/PreferencesUtil';
import { Constants } from '../data/Constants';

/**
 * 登录页：账号密码登录，成功后保存登录状态并进入主页。
 */
@Entry
@Component
struct LoginPage {
  @State account: string = '';
  @State password: string = '';
  @State isLogging: boolean = false;

  private async doLogin(): Promise<void> {
    if (this.account === '') {
      this.getUIContext().getPromptAction().showToast({ message: '请输入学号/工号' });
      return;
    }
    if (this.password === '') {
      this.getUIContext().getPromptAction().showToast({ message: '请输入密码' });
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
      // 顶部 Logo 区
      Column({ space: 10 }) {
        Text('山')
          .fontSize(40)
          .fontColor(Color.White)
          .width(80)
          .height(80)
          .textAlign(TextAlign.Center)
          .backgroundColor($r('app.color.sdmu_primary'))
          .borderRadius(40)
        Text('山东管理学院')
          .fontSize(26)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.sdmu_text_primary'))
        Text('移动校园')
          .fontSize(14)
          .fontColor($r('app.color.sdmu_text_secondary'))
      }
      .width('100%')
      .margin({ top: 80, bottom: 50 })
      .alignItems(HorizontalAlign.Center)

      // 账号输入
      TextInput({ placeholder: '学号/工号', text: this.account })
        .type(InputType.USER_NAME)
        .onChange((value: string) => {
          this.account = value;
        })
        .height(48)
        .fontSize(16)
        .placeholderColor($r('app.color.sdmu_text_hint'))
        .backgroundColor($r('app.color.sdmu_card_bg'))
        .borderRadius(8)
        .margin({ left: 32, right: 32, bottom: 16 })
        .padding({ left: 16, right: 16 })

      // 密码输入
      TextInput({ placeholder: '密码', text: this.password })
        .type(InputType.Password)
        .onChange((value: string) => {
          this.password = value;
        })
        .height(48)
        .fontSize(16)
        .placeholderColor($r('app.color.sdmu_text_hint'))
        .backgroundColor($r('app.color.sdmu_card_bg'))
        .borderRadius(8)
        .margin({ left: 32, right: 32 })
        .padding({ left: 16, right: 16 })

      // 登录按钮
      Button(this.isLogging ? '登录中...' : '登 录')
        .width('80%')
        .height(48)
        .fontSize(18)
        .fontColor(Color.White)
        .backgroundColor($r('app.color.sdmu_primary'))
        .borderRadius(24)
        .margin({ top: 40 })
        .enabled(!this.isLogging)
        .onClick(() => {
          this.doLogin();
        })

      Blank()

      // 底部隐私政策
      Row() {
        Text('登录即代表同意')
          .fontSize(12)
          .fontColor($r('app.color.sdmu_text_hint'))
        Text('《隐私政策》')
          .fontSize(12)
          .fontColor($r('app.color.sdmu_primary'))
          .onClick(() => {
            router.pushUrl({
              url: 'pages/WebViewPage',
              params: { url: 'https://www.sdgu.edu.cn/', title: '隐私政策' }
            });
          })
      }
      .margin({ bottom: 40 })
      .justifyContent(FlexAlign.Center)
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.sdmu_bg'))
  }
}
