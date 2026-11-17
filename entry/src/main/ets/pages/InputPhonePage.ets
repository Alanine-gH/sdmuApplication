import { TitleBar } from '../components/TitleBar';

/**
 * 输入手机号页 — 1:1 复刻 mobile_campus_activity_bind_phone.xml 居中表单样式
 * 结构：LinearLayout(ybg_white) + toolbar_normal + 居中纵向布局
 *   + 图标 mobile_campus_phone_nub marginT px_to_dip_80=40vp
 *   + "手机号" common_color_1 marginT px_to_dip_24=12vp
 *   + "请输入手机号" px_to_sp_26/2=13fp marginT 8vp
 *   + 输入框 marginH px_to_dip_112=56vp marginT px_to_dip_36=18vp 居中
 *   + "完成" px_to_sp_30/2=15fp marginT px_to_dip_76=38vp padding 10vp
 *   + 底部温馨提醒 paddingH px_to_dip_100=50vp
 */
@Entry
@Component
struct InputPhonePage {
  @State phone: string = '';

  private submit(): void {
    if (this.phone.length !== 11) {
      this.getUIContext().getPromptAction().showToast({ message: '请输入本人使用的手机号' });
      return;
    }
    this.getUIContext().getPromptAction().showToast({ message: '提交成功' });
  }

  build() {
    Column() {
      TitleBar({ title: '输入手机号', showBack: true })

      Column() {
        Image($r('app.media.mobile_campus_phone_nub'))
          .margin({ top: 40 })

        Text('手机号')
          .fontSize(16)
          .fontColor($r('app.color.common_color_1'))
          .margin({ top: 12 })

        Text('请输入手机号')
          .fontSize(13)
          .fontColor($r('app.color.common_color_2'))
          .margin({ top: 8 })

        TextInput({ text: this.phone, placeholder: '' })
          .width('100%')
          .height(40)
          .textAlign(TextAlign.Center)
          .fontSize(16)
          .fontColor($r('app.color.common_color_1'))
          .backgroundColor($r('app.color.sdmu_bg'))
          .borderRadius(2)
          .type(InputType.PhoneNumber)
          .margin({ left: 56, right: 56, top: 18 })
          .onChange((value: string) => {
            this.phone = value;
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
        Text('温馨提醒:\n\n请输入本人使用的手机号。')
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
