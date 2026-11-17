import { TitleBar } from '../components/TitleBar';

/**
 * 绑定手机页 — 1:1 复刻 mobile_campus_login_activity_bindcellphone.xml
 * 结构：LinearLayout(ybg_white) + toolbar_normal + thin divider
 *   + 手机号行(+86 TextSize2.Color7 16fp #18B4ED + 输入框 marginL 10) 下分隔线 marginT 15
 *   + 验证码行(输入 + 获取验证码按钮 bg primary #1B68B7 padding 10) 下分隔线 marginT 10
 *   + 下一步按钮 marginH 15 marginT 37 bg #1B68B7 padding 10 白字居中
 * 基准间距：px_to_dip_30=15vp / px_to_dip_60=30vp / px_to_dip_20=10vp / px_to_dip_74=37vp
 */
@Entry
@Component
struct BindPhonePage {
  @State phone: string = '';
  @State verifyCode: string = '';

  private getCode(): void {
    if (this.phone.length !== 11) {
      this.getUIContext().getPromptAction().showToast({ message: '请输入正确的手机号' });
      return;
    }
    this.getUIContext().getPromptAction().showToast({ message: '验证码已发送' });
  }

  private nextStep(): void {
    if (this.phone.length !== 11 || this.verifyCode.length < 4) {
      this.getUIContext().getPromptAction().showToast({ message: '请填写手机号和验证码' });
      return;
    }
    this.getUIContext().getPromptAction().showToast({ message: '绑定成功' });
  }

  @Builder
  greyThinDivider() {
    Divider()
      .color($r('app.color.divider_grey'))
      .strokeWidth(0.5)
      .width('100%')
  }

  build() {
    Column() {
      TitleBar({ title: '绑定手机', showBack: true })
      this.greyThinDivider()

      // 手机号输入行
      Column() {
        Row() {
          Text('+86')
            .fontSize(16)
            .fontColor($r('app.color.common_color_7'))
          TextInput({ text: this.phone, placeholder: '请输入手机号' })
            .layoutWeight(1)
            .height(40)
            .backgroundColor(Color.Transparent)
            .padding({ left: 10 })
            .fontSize(16)
            .fontColor($r('app.color.common_color_1'))
            .placeholderColor($r('app.color.common_color_4'))
            .type(InputType.PhoneNumber)
            .onChange((value: string) => {
              this.phone = value;
            })
        }
        .width('100%')
        .padding({ left: 15, right: 15 })
        .alignItems(VerticalAlign.Center)
        .margin({ top: 30 })

        Divider()
          .color($r('app.color.menu_divider'))
          .strokeWidth(0.5)
          .width('100%')
          .margin({ top: 15 })
      }
      .width('100%')

      // 验证码输入行
      Column() {
        Row() {
          TextInput({ text: this.verifyCode, placeholder: '请输入验证码' })
            .layoutWeight(1)
            .height(40)
            .backgroundColor(Color.Transparent)
            .padding({ left: 15 })
            .fontSize(16)
            .fontColor($r('app.color.common_color_1'))
            .placeholderColor($r('app.color.common_color_4'))
            .type(InputType.Number)
            .onChange((value: string) => {
              this.verifyCode = value;
            })

          Text('获取验证码')
            .fontSize(16)
            .fontColor($r('app.color.white'))
            .backgroundColor($r('app.color.mobile_campus_primary_color_default'))
            .padding(10)
            .margin({ left: 10 })
            .onClick(() => {
              this.getCode();
            })
        }
        .width('100%')
        .padding({ left: 15, right: 15 })
        .alignItems(VerticalAlign.Center)
        .margin({ top: 15 })

        Divider()
          .color($r('app.color.menu_divider'))
          .strokeWidth(0.5)
          .width('100%')
          .margin({ top: 10 })
      }
      .width('100%')

      // 下一步
      Text('确定')
        .fontSize(16)
        .fontColor($r('app.color.white'))
        .textAlign(TextAlign.Center)
        .width('100%')
        .backgroundColor($r('app.color.mobile_campus_primary_color_default'))
        .padding(10)
        .margin({ left: 15, right: 15, top: 37 })
        .onClick(() => {
          this.nextStep();
        })
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.ybg_white'))
  }
}
