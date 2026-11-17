/**
 * 已登录启动页 — 1:1 复刻 mobile_campus_logined_launch.xml
 * 结构：FrameLayout
 *   - ivBg 底部背景图 mobile_campus_logined_launch.png centerCrop
 *   - llLayout(vertical，加载完成后显示)：姓名 20fp、日期行1 14fp、日期行2 15fp，common_color_1
 *     nameView: ml 15vp(mt 37.5)  dateView1: ml 15 mt 40 mb 5  dateView2: ml 15
 */
@Entry
@Component
struct LoginedLaunchPage {
  @State userName: string = '张明';
  @State dateText1: string = '2026年11月17日 星期二';
  @State dateText2: string = '农历十月初八';
  @State showLayout: boolean = true;

  build() {
    Stack({ alignContent: Alignment.Bottom }) {
      Image($r('app.media.mobile_campus_logined_launch'))
        .width('100%')
        .height('100%')
        .objectFit(ImageFit.Cover)

      Column() {
        Text(this.userName)
          .fontSize(20)
          .fontColor($r('app.color.common_color_1'))
          .margin({ left: 15, top: 37.5 })

        Text(this.dateText1)
          .fontSize(14)
          .fontColor($r('app.color.common_color_1'))
          .margin({ left: 15, top: 40, bottom: 5 })

        Text(this.dateText2)
          .fontSize(15)
          .fontColor($r('app.color.common_color_1'))
          .margin({ left: 15 })
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)
      .visibility(this.showLayout ? Visibility.Visible : Visibility.None)
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.white'))
  }
}
