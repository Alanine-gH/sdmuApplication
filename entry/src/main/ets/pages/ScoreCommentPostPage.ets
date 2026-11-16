import { TitleBar } from '../components/TitleBar';

@Entry
@Component
struct ScoreCommentPostPage {
  @State inputContent: string = '';

  build() {
    Column() {
      TitleBar({ title: '发表课评', showBack: true })
      Scroll() {
        Column() {
          TextArea({
            placeholder: '说说这门课的学习心得，帮助学弟学妹选课...',
            text: this.inputContent
          })
            .placeholderColor($r('app.color.common_color_4'))
            .fontSize(14)
            .fontColor($r('app.color.common_color_1'))
            .constraintSize({ minHeight: 126 })
            .maxLength(500)
            .margin(6)
            .backgroundColor($r('app.color.white'))
            .onChange((value: string) => {
              this.inputContent = value;
            })
        }
        .width('100%')
      }
      .layoutWeight(1)
      .backgroundColor($r('app.color.white'))
      .align(Alignment.Top)

      Divider()
        .color($r('app.color.common_color_5'))
        .strokeWidth(1)
        .width('100%')
      Row() {
        Text('😊')
          .fontSize(24)
          .margin({ right: 20 })
          .onClick(() => {
            this.inputContent = this.inputContent + '😊';
          })
        Blank()
        Text(this.inputContent.length + '/500')
          .fontSize(12)
          .fontColor($r('app.color.common_color_4'))
          .margin({ right: 10 })
        Text('发布')
          .fontSize(14)
          .fontColor($r('app.color.common_color_7'))
          .padding({ left: 12, right: 12, top: 6, bottom: 6 })
          .borderRadius(4)
          .border({ width: 1, color: $r('app.color.ybg_blue') })
          .onClick(() => {
            if (this.inputContent.trim().length === 0) {
              this.getUIContext().getPromptAction().showToast({ message: '请先输入课评内容' });
              return;
            }
            this.getUIContext().getPromptAction().showToast({ message: '发布成功' });
            this.inputContent = '';
          })
      }
      .width('100%')
      .padding({ left: 15, top: 4, right: 15, bottom: 4 })
      .height(48)
      .alignItems(VerticalAlign.Center)
      .backgroundColor($r('app.color.white'))
      Divider()
        .color($r('app.color.common_color_5'))
        .strokeWidth(1)
        .width('100%')
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.white'))
  }
}
