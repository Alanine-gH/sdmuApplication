import { TitleBar } from '../components/TitleBar';
import { GesturePwdGrid } from '../components/GesturePwdGrid';

/**
 * 手势密码设置页 — 1:1 复刻 mobile_campus_activity_gesture_pwd_setting.xml
 * 结构：LinearLayout(垂直) + toolbar_normal
 *   - "设置您的新手势密码" 17fp black 居中、marginT 20vp(40÷2)
 *   - 小手势九宫格 72x72vp、marginT 8vp(16÷2)、不可交互（预览）
 *   - "绘制解锁图案" 14fp #999999、marginT 8vp
 *   - 错误提示 14fp colorCheckedErr(#EB5757)、marginT 4vp
 *   - 大手势九宫格 marginT 12.5vp(25÷2)、paddingH 6vp
 */
@Entry
@Component
struct GesturePwdSettingPage {
  @State firstSeq: number[] = [];
  @State tipText: string = '绘制解锁图案';
  @State errorTip: string = '';
  @State resetToken: number = 0;
  private titleText: string = '设置您的新手势密码';

  private onBigFinish(seq: number[]): void {
    if (this.firstSeq.length === 0) {
      // 第一次绘制：记录并显示到小九宫格
      this.firstSeq = seq;
      this.tipText = '再次绘制确认';
      this.errorTip = '';
      this.resetToken = this.resetToken + 1;
    } else {
      // 第二次绘制：比对两次图案
      if (seq.length === this.firstSeq.length && seq.every((v: number, i: number): boolean => v === this.firstSeq[i])) {
        this.errorTip = '';
        this.tipText = '设置成功';
        this.getUIContext().getPromptAction().showToast({ message: '手势密码设置成功' });
      } else {
        this.errorTip = '两次绘制不一致，请重新绘制';
        this.firstSeq = [];
        this.tipText = '绘制解锁图案';
        this.resetToken = this.resetToken + 1;
      }
    }
  }

  build() {
    Column() {
      TitleBar({ title: '设置手势密码', showBack: true })

      Column() {
        Text(this.titleText)
          .fontSize(17)
          .fontColor($r('app.color.black'))
          .textAlign(TextAlign.Center)
          .width('100%')
          .margin({ top: 20 })

        GesturePwdGrid({
          gridWidth: 72,
          allowInteract: false,
          displaySeq: this.firstSeq,
          resetToken: this.resetToken,
          onFinish: (seq: number[]) => {
            this.onBigFinish(seq);
          }
        })
          .margin({ top: 8 })

        Text(this.tipText)
          .fontSize(14)
          .fontColor($r('app.color.common_color_3'))
          .textAlign(TextAlign.Center)
          .width('100%')
          .margin({ top: 8 })

        Text(this.errorTip)
          .fontSize(14)
          .fontColor($r('app.color.color_checked_err'))
          .textAlign(TextAlign.Center)
          .width('100%')
          .margin({ top: 4 })

        GesturePwdGrid({
          gridWidth: 336,
          allowInteract: true,
          resetToken: this.resetToken,
          onFinish: (seq: number[]) => {
            this.onBigFinish(seq);
          }
        })
          .margin({ top: 12 })
          .padding({ left: 6, right: 6 })
      }
      .width('100%')
      .height('100%')
      .alignItems(HorizontalAlign.Center)
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.white'))
  }
}
