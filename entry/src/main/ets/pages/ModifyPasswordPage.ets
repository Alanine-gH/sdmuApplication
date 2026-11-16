import { TitleBar } from '../components/TitleBar';

/**
 * 修改密码页 — 1:1 复刻 my_activity_modifypassword.xml
 * 结构：LinearLayout(白底 ybg_white) + toolbar_normal
 *   1. 新密码输入：paddingH 15vp(px30÷2)、marginTop 15vp、
 *      hint "输入新密码" #CECECE(common_color_4)、文字 16fp(px32÷2) #555555(TextSize3.Color2)、
 *      下分隔线 0.8dip、marginTop 15vp
 *   2. 再次输入新密码：同上
 *   3. 验证码行：输入 "输入验证码" 16fp #555555 + 右侧"获取验证码"按钮：
 *      16fp #F2F2F2(TextSize3.Color6)、padding 10vp(px20÷2)、bg #18B4ED 圆角 6dip
 *   4. 确定按钮：17fp(px34÷2) #F2F2F2(TextSize2.Color6)、padding 10vp、
 *      bg #18B4ED 圆角 6dip、marginH 15vp、marginTop 37dip
 *   5. tips 文本：12fp(px24÷2) #999999(TextSize5.Color3)
 */
@Entry
@Component
struct ModifyPasswordPage {
  @State newPassword: string = '';
  @State confirmPassword: string = '';
  @State verifyCode: string = '';

  private submit(): void {
    if (this.newPassword === '') {
      this.getUIContext().getPromptAction().showToast({ message: '请输入新密码' });
      return;
    }
    if (this.confirmPassword === '') {
      this.getUIContext().getPromptAction().showToast({ message: '请再次输入新密码' });
      return;
    }
    if (this.confirmPassword !== this.newPassword) {
      this.getUIContext().getPromptAction().showToast({ message: '两次输入的密码不一致' });
      return;
    }
    // Android 端提示：学校未开通修改密码功能
    this.getUIContext().getPromptAction().showToast({ message: '学校未开通修改密码功能' });
  }

  build() {
    Column() {
      TitleBar({ title: '修改密码', showBack: true })

      // 新密码输入
      Column() {
        TextInput({ placeholder: '输入新密码', text: this.newPassword })
          .type(InputType.Password)
          .fontSize(16)
          .fontColor($r('app.color.common_color_2'))
          .placeholderColor($r('app.color.hint_color_4'))
          .placeholderFont({ size: 16 })
          .height(44)
          .backgroundColor(Color.Transparent)
          .padding(0)
          .onChange((value: string) => {
            this.newPassword = value;
          })
        Divider()
          .color($r('app.color.common_color_5'))
          .strokeWidth(0.8)
          .width('100%')
          .margin({ top: 15 })
      }
      .width('100%')
      .padding({ left: 15, right: 15 })
      .margin({ top: 15 })

      // 再次输入新密码
      Column() {
        TextInput({ placeholder: '再次输入新密码', text: this.confirmPassword })
          .type(InputType.Password)
          .fontSize(16)
          .fontColor($r('app.color.common_color_2'))
          .placeholderColor($r('app.color.hint_color_4'))
          .placeholderFont({ size: 16 })
          .height(44)
          .backgroundColor(Color.Transparent)
          .padding(0)
          .onChange((value: string) => {
            this.confirmPassword = value;
          })
        Divider()
          .color($r('app.color.common_color_5'))
          .strokeWidth(0.8)
          .width('100%')
          .margin({ top: 15 })
      }
      .width('100%')
      .padding({ left: 15, right: 15 })
      .margin({ top: 15 })

      // 验证码行
      Column() {
        Row() {
          TextInput({ placeholder: '输入验证码', text: this.verifyCode })
            .type(InputType.Number)
            .fontSize(16)
            .fontColor($r('app.color.common_color_2'))
            .placeholderColor($r('app.color.hint_color_4'))
            .placeholderFont({ size: 16 })
            .height(44)
            .backgroundColor(Color.Transparent)
            .padding(0)
            .layoutWeight(1)
            .onChange((value: string) => {
              this.verifyCode = value;
            })

          // 获取验证码按钮：#18B4ED 圆角 6vp、16fp #F2F2F2、padding 10vp
          Text('获取验证码')
            .fontSize(16)
            .fontColor($r('app.color.common_color_6'))
            .padding(10)
            .borderRadius(6)
            .backgroundColor($r('app.color.ybg_blue'))
            .margin({ left: 10 })
        }
        .width('100%')
        .alignItems(VerticalAlign.Center)

        Divider()
          .color($r('app.color.common_color_5'))
          .strokeWidth(0.8)
          .width('100%')
          .margin({ top: 10 })
      }
      .width('100%')
      .padding({ left: 15, right: 15 })
      .margin({ top: 15 })

      // 确定按钮：#18B4ED 圆角 6vp、17fp #F2F2F2、marginH 15vp、marginTop 37dip
      Text('确定')
        .fontSize(17)
        .fontColor($r('app.color.common_color_6'))
        .width('100%')
        .padding(10)
        .textAlign(TextAlign.Center)
        .borderRadius(6)
        .backgroundColor($r('app.color.ybg_blue'))
        .margin({ left: 15, right: 15, top: 37 })
        .onClick(() => {
          this.submit();
        })

      // tips 文本：12fp #999999
      Text('为了您的账号安全，修改密码后需重新登录')
        .fontSize(12)
        .fontColor($r('app.color.common_color_3'))
        .width('100%')
        .margin({ left: 15, right: 15, top: 6 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.white'))
  }
}
