/**
 * 服务启用提示页 — 1:1 复刻 activity_endisable_service.xml：
 * - RelativeLayout 竖向、padH 16dip(=16vp)、wrap 高；
 * - enable_service_text 13sp(=13fp)、marginTop 16dip(=16vp)、marginR 8dip(=8vp)，
 *   文案 "Please enable the HMS service in settings tag"（来自源码字符串）。
 */
@Entry
@Component
struct EndisableServicePage {
  build() {
    Column() {
      Text('Please enable the HMS service in settings tag')
        .fontSize(13)
        .fontColor('#333333')
        .width('100%')
        .margin({ top: 16, right: 8 })
    }
    .width('100%')
    .height('100%')
    .padding({ left: 16, right: 16 })
    .backgroundColor($r('app.color.white'))
  }
}
