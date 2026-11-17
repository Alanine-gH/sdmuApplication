import { TitleBar } from '../components/TitleBar';

/**
 * 输入验证码页 — 1:1 复刻 mobile_campus_activity_input_identify_code.xml
 * 结构：LinearLayout(ybg_white) + toolbar_normal + divider
 *   - 验证码插图 mobile_campus_code 57x96.5vp(xhdpi 114x193÷2)、marginTop 40vp(px80÷2)
 *   - "输入验证码" 18fp common_color_1、marginTop 12vp(px24÷2)
 *   - "验证码已发送至" 13fp(px26÷2) + 手机号 13fp primary paddingLeft 10vp
 *   - 验证码输入框 4 格（singleBox 方格、fill #F2F2F2、圆角 1vp、间距 3vp、20fp）、marginTop 9vp
 *   - "完成" 15fp(px30÷2) marginT 48vp(px96÷2)、enabled #1B68B7/disabled #CECECE
 *   - "重新获取" 15fp padding 10vp 圆角描边圆角 1024÷2、enabled primary/disabled #999999
 */
@Entry
@Component
struct InputIdentifyCodePage {
  @State codeDigits: string = '';
  @State phoneText: string = '138****5678';
  @State countDown: number = 0;
  private timerId: number = -1;

  aboutToDisappear(): void {
    if (this.timerId !== -1) {
      clearInterval(this.timerId);
      this.timerId = -1;
    }
  }

  private requestCode(): void {
    if (this.countDown > 0) {
      return;
    }
    this.countDown = 60;
    this.getUIContext().getPromptAction().showToast({ message: '验证码已重新发送' });
    this.timerId = setInterval(() => {
      this.countDown = this.countDown - 1;
      if (this.countDown <= 0) {
        clearInterval(this.timerId);
        this.timerId = -1;
        this.countDown = 0;
      }
    }, 1000);
  }

  private nextStep(): void {
    if (this.codeDigits.length < 4) {
      return;
    }
    this.getUIContext().getPromptAction().showToast({ message: '验证成功' });
  }

  private digitAt(idx: number): string {
    if (idx < this.codeDigits.length) {
      return this.codeDigits[idx];
    }
    return '';
  }

  build() {
    Column() {
      TitleBar({ title: '输入验证码', showBack: true })

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

          Text(this.phoneText)
            .fontSize(13)
            .fontColor($r('app.color.mobile_campus_primary_color'))
            .padding({ left: 10 })
        }
        .margin({ top: 4 })
        .alignItems(VerticalAlign.Center)

        // 4 格验证码输入（叠加透明输入框接收输入）
        Stack() {
          Row({ space: 3 }) {
            ForEach([0, 1, 2, 3], (idx: number) => {
              Text(this.digitAt(idx))
                .fontSize(20)
                .fontColor($r('app.color.common_color_1'))
                .textAlign(TextAlign.Center)
                .width(40)
                .height(40)
                .backgroundColor($r('app.color.common_color_6'))
                .borderRadius(1)
            }, (idx: number) => `code_box_${idx}`)
          }
          .alignItems(VerticalAlign.Center)

          TextInput({ text: this.codeDigits })
            .type(InputType.Number)
            .maxLength(4)
            .opacity(0)
            .width(169)
            .height(40)
            .caretColor(Color.Transparent)
            .onChange((value: string) => {
              this.codeDigits = value;
            })
        }
        .margin({ top: 9 })

        Text('完成')
          .fontSize(15)
          .fontColor(this.codeDigits.length >= 4 ? $r('app.color.blue_default') : $r('app.color.common_color_24'))
          .margin({ top: 48 })
          .visibility(this.codeDigits.length >= 4 ? Visibility.Visible : Visibility.None)
          .onClick(() => {
            this.nextStep();
          })

        Text(this.countDown > 0 ? `重新获取(${this.countDown}s)` : '重新获取')
          .fontSize(15)
          .fontColor(this.countDown > 0 ? $r('app.color.common_color_3') : $r('app.color.blue_default'))
          .padding({ left: 10, right: 10, top: 12, bottom: 12 })
          .borderRadius(25)
          .border({
            width: 1,
            color: this.countDown > 0 ? $r('app.color.common_color_3') : $r('app.color.blue_default')
          })
          .backgroundColor($r('app.color.white'))
          .margin({ top: 48 })
          .onClick(() => {
            this.requestCode();
          })
      }
      .width('100%')
      .height('100%')
      .alignItems(HorizontalAlign.Center)
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.ybg_white'))
  }
}
