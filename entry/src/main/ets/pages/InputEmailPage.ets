import { TitleBar } from '../components/TitleBar';

/**
 * 输入邮箱页 — 1:1 复刻 mobile_campus_activity_mobile_campus_bind_email.xml
 * 结构：LinearLayout(ybg_white) + toolbar_normal + thin divider + 居中纵向布局
 *   + 图标(默认 invisible) marginT px_to_dip_80=40vp
 *   + "电子邮箱" common_color_1 marginT px_to_dip_24=12vp
 *   + "请输入邮箱" px_to_sp_26/2=13fp marginT 8vp
 *   + 邮箱输入框 marginH px_to_dip_112=56vp marginT px_to_dip_36=18vp 居中
 *   + "完成" px_to_sp_30/2=15fp marginT px_to_dip_76=38vp padding 10vp
 *   + 底部温馨提醒 paddingH px_to_dip_100=50vp
 */
@Entry
@Component
struct InputEmailPage {
  @State email: string = '';

  private submit(): void {
    if (this.email.length === 0 || this.email.indexOf('@') < 0) {
      this.getUIContext().getPromptAction().showToast({ message: '请输入本人使用的邮箱地址' });
      return;
    }
    this.getUIContext().getPromptAction().showToast({ message: '提交成功' });
  }

  build() {
    Column() {
      TitleBar({ title: '输入邮箱', showBack: true })
      Divider()
        .color($r('app.color.divider_grey'))
        .strokeWidth(0.5)
        .width('100%')

      Column() {
        Image($r('app.media.mobile_campus_phone_nub'))
          .visibility(Visibility.None)
          .margin({ top: 40 })

        Text('电子邮箱')
          .fontSize(16)
          .fontColor($r('app.color.common_color_1'))
          .margin({ top: 12 })

        Text('请输入邮箱')
          .fontSize(13)
          .fontColor($r('app.color.common_color_2'))
          .margin({ top: 8 })

        TextInput({ text: this.email, placeholder: '' })
          .width('100%')
          .height(40)
          .textAlign(TextAlign.Center)
          .fontSize(16)
          .fontColor($r('app.color.common_color_1'))
          .backgroundColor($r('app.color.sdmu_bg'))
          .borderRadius(2)
          .type(InputType.Email)
          .margin({ left: 56, right: 56, top: 18 })
          .onChange((value: string) => {
            this.email = value;
          })

        Text('完成')
          .fontSize(15)
          .fontColor($r('app.color.mobile_campus_primary_color'))
          .padding(10)
          .margin({ top: 38 })
          .onClick(() => {
            this.submit();
          })
      }
      .width('100%')
      .alignItems(HorizontalAlign.Center)

      Column() {
        Text('温馨提醒:\n\n请输入本人使用的邮箱地址。')
          .fontSize(15)
          .fontColor($r('app.color.common_color_2'))
          .textAlign(TextAlign.Center)
      }
      .width('100%')
      .layoutWeight(1)
      .justifyContent(FlexAlign.Center)
      .padding({ left: 50, right: 50 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.ybg_white'))
  }
}
