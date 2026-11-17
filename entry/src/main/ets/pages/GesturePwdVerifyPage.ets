import { router } from '@kit.ArkUI';
import { GesturePwdGrid } from '../components/GesturePwdGrid';

/**
 * 手势密码校验页 — 1:1 复刻 dialog_gesture_password.xml
 * 结构：LinearLayout(white) 全屏
 *   - 顶栏 44vp：左侧关闭按钮 icon_gesture_close 44x44(padding 15) + 居中标题
 *     "身份验证" 17fp black(paddingTB 10)
 *   - 头像 72x72 default_avatar（centerCrop）、marginT 20vp(40÷2)
 *   - 手机号 18fp black、marginT 8vp(16÷2)
 *   - "请输入手势密码" 14fp #999999、marginT 8vp
 *   - 错误提示 14fp colorCheckedErr(#EB5757)、marginT 4vp
 *   - 大手势九宫格 marginT 12.5vp(25÷2)、paddingH 6vp
 */
@Entry
@Component
struct GesturePwdVerifyPage {
  @State phoneText: string = '138****5678';
  @State errorTip: string = '';
  @State resetToken: number = 0;
  private validSeq: number[] = [0, 3, 6, 7, 8];

  private onGridFinish(seq: number[]): void {
    if (seq.length === this.validSeq.length && seq.every((v: number, i: number): boolean => v === this.validSeq[i])) {
      this.errorTip = '';
      this.getUIContext().getPromptAction().showToast({ message: '验证成功' });
      router.back();
    } else {
      this.errorTip = '手势密码错误，请重新输入';
      this.resetToken = this.resetToken + 1;
    }
  }

  build() {
    Column() {
      // 顶栏 44vp
      Stack() {
        Text('身份验证')
          .fontSize(17)
          .fontColor($r('app.color.black'))
          .textAlign(TextAlign.Center)
          .width('100%')
          .padding({ top: 10, bottom: 10 })

        Image($r('app.media.icon_gesture_close'))
          .width(44)
          .height(44)
          .padding(15)
          .onClick(() => {
            router.back();
          })
      }
      .width('100%')
      .height(44)
      .alignContent(Alignment.BottomStart)

      Column() {
        Image($r('app.media.default_avatar'))
          .width(72)
          .height(72)
          .objectFit(ImageFit.Cover)
          .borderRadius(36)
          .margin({ top: 20 })

        Text(this.phoneText)
          .fontSize(18)
          .fontColor($r('app.color.black'))
          .textAlign(TextAlign.Center)
          .width('100%')
          .margin({ top: 8 })

        Text('请输入手势密码')
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
            this.onGridFinish(seq);
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
