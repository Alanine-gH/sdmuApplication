import { router } from '@kit.ArkUI';

/**
 * 指纹登录页 — 1:1 复刻 mobile_campus_activity_finger_login.xml
 * 结构：LinearLayout(垂直、bg common_color_6、paddingT 10vp)
 *   - 关闭按钮 finger_login_close 50x50(padding 9)、marginT 5vp
 *   - 中部：指纹插图 finger_login_icon_log(padding 5) + "电脑登录确认" 20fp bold black(marginT 5)
 *     marginT 66vp(132÷2)
 *   - 弹性空白（weight 1）
 *   - "登录" 按钮 90vp 宽、padding 6vp、圆角 512vp(1024÷2)、bg #1790FF、17fp 白色
 *   - "取消登录" 17fp #4B749A、padding 6vp、marginT 10vp、marginB 37vp(74÷2)
 */
@Entry
@Component
struct FingerLoginPage {
  build() {
    Column() {
      Image($r('app.media.finger_login_close'))
        .width(50)
        .height(50)
        .padding(9)
        .margin({ top: 5 })
        .onClick(() => {
          router.back();
        })

      Column() {
        Image($r('app.media.finger_login_icon_log'))
          .width(116)
          .height(86)
          .padding(5)

        Text('电脑登录确认')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.black'))
          .margin({ top: 5 })
      }
      .margin({ top: 66 })
      .alignItems(HorizontalAlign.Center)

      Blank()
        .layoutWeight(1)

      Text('登录')
        .fontSize(17)
        .fontColor($r('app.color.white'))
        .textAlign(TextAlign.Center)
        .width(90)
        .padding(6)
        .borderRadius(25)
        .backgroundColor($r('app.color.finger_blue'))
        .onClick(() => {
          this.getUIContext().getPromptAction().showToast({ message: '指纹验证通过，登录成功' });
        })

      Text('取消登录')
        .fontSize(17)
        .fontColor($r('app.color.finger_cancel_blue'))
        .textAlign(TextAlign.Center)
        .padding(6)
        .margin({ top: 10, bottom: 37 })
        .onClick(() => {
          router.back();
        })
    }
    .width('100%')
    .height('100%')
    .padding({ top: 10 })
    .backgroundColor($r('app.color.common_color_6'))
  }
}
