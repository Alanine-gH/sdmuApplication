import { TitleBar } from '../components/TitleBar';

/**
 * 修改昵称页 — 1:1 复刻 mobile_campus_activity_personal_change_nickname.xml
 * 结构：LinearLayout(common_color_6) + toolbar_normal
 *   + EditText(白底 padding 15, marginTop 20, hint 请设置您的昵称, maxLength 15)
 *   + 提示文字 14fp padding 15/12
 *   + 提交按钮 17fp 圆角8 左右margin 15 上margin 20 上下padding 13
 *     可用: #1B68B7/白字  不可用: #DFE4EA/#999999
 */
@Entry
@Component
struct ChangeNickNamePage {
  @State nickName: string = '张小明';

  private canSubmit(): boolean {
    return this.nickName.length >= 2;
  }

  private submit(): void {
    if (!this.canSubmit()) {
      this.getUIContext().getPromptAction().showToast({ message: '请输入2-15个字符' });
      return;
    }
    this.getUIContext().getPromptAction().showToast({ message: '昵称设置成功' });
  }

  build() {
    Column() {
      TitleBar({ title: '修改昵称', showBack: true })

      TextInput({ text: this.nickName, placeholder: '请设置您的昵称' })
        .width('100%')
        .height(52)
        .backgroundColor($r('app.color.white'))
        .fontSize(16)
        .fontColor($r('app.color.common_color_1'))
        .placeholderColor($r('app.color.common_color_3'))
        .maxLength(15)
        .padding(15)
        .margin({ top: 20 })
        .onChange((value: string) => {
          this.nickName = value;
        })

      Text('支持2-15个字符哦~(*^▽^*)')
        .fontSize(14)
        .fontColor($r('app.color.common_color_1'))
        .width('100%')
        .padding({ left: 15, right: 15, top: 12, bottom: 12 })

      Text('确定设置')
        .fontSize(17)
        .fontColor(this.canSubmit() ? $r('app.color.white') : '#999999')
        .textAlign(TextAlign.Center)
        .width('100%')
        .padding({ top: 13, bottom: 13 })
        .margin({ left: 15, right: 15, top: 20 })
        .backgroundColor(this.canSubmit() ? '#1B68B7' : '#DFE4EA')
        .borderRadius(8)
        .onClick(() => {
          this.submit();
        })
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.common_color_6'))
  }
}
