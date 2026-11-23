/**
 * 服务启用提示页 — 1:1 复刻 activity_endisable_service.xml：
 * - RelativeLayout 竖向、padH 16dip(=16vp)、wrap 高；
 * - enable_service_text 13sp(=13fp)、marginTop 16dip(=16vp)、marginR 8dip(=8vp)，
 *   文案 "Please enable the HMS service in settings tag"（来自源码字符串）。
 */
@Entry
@Component
struct EndisableServicePage {
  @StorageProp('avoidAreaTopVp') avoidAreaTopVp: number = 0;
  @StorageProp('avoidAreaBottomVp') avoidAreaBottomVp: number = 0;
  @StorageProp('avoidAreaLeftVp') avoidAreaLeftVp: number = 0;
  @StorageProp('avoidAreaRightVp') avoidAreaRightVp: number = 0;

  build() {
    Column() {
      Text('Please enable the HMS service in settings tag')
        .fontSize(13)
        .fontColor('#333333')
        .width('100%')
        .padding({ top: 16, right: 8 })
    }
    .width('100%')
    .height('100%')
    .padding({
      left: Math.max(16, this.avoidAreaLeftVp),
      right: Math.max(16, this.avoidAreaRightVp),
      top: this.avoidAreaTopVp,
      bottom: this.avoidAreaBottomVp
    })
    .backgroundColor($r('app.color.white'))
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
  }
}
