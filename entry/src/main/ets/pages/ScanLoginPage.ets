import { TitleBar } from '../components/TitleBar';

/**
 * 扫码登录页 — 1:1 复刻 mobile_campus_activity_scan_login.xml
 * 结构：LinearLayout(垂直) + toolbar_normal + MultiStateView(content)
 *   - 扫码插图 mobile_campus_scan_login 214x144vp(xhdpi 428x288÷2)
 *   - "扫码登录" 16fp black、marginTop 18vp(36÷2)
 *   - 账号文本 16fp ybg_blue、marginTop 6vp(12÷2)
 *   - 确认登录按钮 184x40vp、marginH/V 10vp(px24÷2/20÷2)、bg #1B68B6 圆角 2vp(px8÷2)、
 *     16fp(px32÷2) 白色居中
 */
@Entry
@Component
struct ScanLoginPage {
  @State accountText: string = '张三（138****5678）';

  private submit(): void {
    this.getUIContext().getPromptAction().showToast({ message: '已确认扫码登录' });
  }

  build() {
    Column() {
      TitleBar({ title: '扫码登录', showBack: true })

      Column() {
        Column() {
          Image($r('app.media.mobile_campus_scan_login'))
            .width(214)
            .height(144)

          Text('扫码登录')
            .fontSize(16)
            .fontColor($r('app.color.black'))
            .textAlign(TextAlign.Center)
            .margin({ top: 18 })

          Text(this.accountText)
            .fontSize(16)
            .fontColor($r('app.color.ybg_blue'))
            .textAlign(TextAlign.Center)
            .margin({ top: 6 })
        }
        .width('100%')

        Text('确认登录')
          .fontSize(16)
          .fontColor($r('app.color.white'))
          .textAlign(TextAlign.Center)
          .width(184)
          .height(40)
          .borderRadius(2)
          .backgroundColor($r('app.color.mobile_campus_schedule_confirm_blue'))
          .margin({ left: 10, right: 10, top: 10, bottom: 10 })
          .onClick(() => {
            this.submit();
          })
      }
      .width('100%')
      .height('100%')
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.white'))
  }
}
