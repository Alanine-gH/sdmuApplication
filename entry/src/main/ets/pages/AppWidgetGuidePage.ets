import { deviceInfo } from '@kit.BasicServicesKit';
import { TitleBar } from '../components/TitleBar';
import { WidgetDataHelper } from '../common/WidgetDataHelper';

/**
 * 桌面小组件引导页 — 源码级复刻 AppWidgetGuideActivity（lyyd/timetable/view）。
 * 源码：mobile_campus_timetable_activity_guide 布局（toolbar"添加小组件" + mWebView）+
 * J2()：WebView settings（SupportZoom false/BuiltInZoom true(隐藏控件)/WideViewPort/
 * SINGLE_COLUMN/LoadWithOverviewMode）→ loadUrl(file:///android_asset/<机型引导图>)。
 * I2() 机型分支：v.c()=华为(默认 huawei) / v.d()=mi / v.e()=oppo / v.f()=vivo；
 * onBackPressed：finish + overridePendingTransition(none, push_bottom_from_top)。
 * HAP 等价：deviceInfo.marketName/productModel 判机型 → Image 全宽加载本地 PNG
 * （rawfile→media 已随 APK assets 拷入 4 张引导图），Scroll 等价 WebView 滚动。
 * M1 增强：提供原生 formProvider.openFormManager 一键添加到桌面入口与安全降级提示。
 */
@Entry
@Component
struct AppWidgetGuidePage {
  /** I2() 机型分支结果对应的引导图资源（build 中 $r 需字面量 → switch 静态映射） */
  private guideRes(): Resource {
    // deviceInfo.marketName：HUAWEI/MAGIC → huawei；Xiaomi/REDMI → mi；OPPO/realme → oppo；vivo/iQOO → vivo
    const market: string = deviceInfo.marketName.toUpperCase();
    const brand: string = deviceInfo.brand.toUpperCase();
    if (market.indexOf('XIAOMI') >= 0 || brand.indexOf('XIAOMI') >= 0 || market.indexOf('REDMI') >= 0) {
      return $r('app.media.mobile_campus_timetable_guide_mi');
    }
    if (market.indexOf('OPPO') >= 0 || brand.indexOf('OPPO') >= 0 || market.indexOf('REALME') >= 0) {
      return $r('app.media.mobile_campus_timetable_guide_oppo');
    }
    if (market.indexOf('VIVO') >= 0 || brand.indexOf('VIVO') >= 0 || market.indexOf('IQOO') >= 0) {
      return $r('app.media.mobile_campus_timetable_guide_vivo');
    }
    // v.c()（华为/其余设备）→ 默认 huawei 引导图
    return $r('app.media.mobile_campus_timetable_guide_huawei');
  }

  private pinWidget(formName: string, dimension: number): void {
    const res = WidgetDataHelper.openPinWidgetManager(formName, dimension);
    this.getUIContext().getPromptAction().showToast({ message: res.message, duration: 2500 });
  }

  build() {
    Column() {
      TitleBar({ title: '添加小组件', showBack: true })

      Column({ space: 10 }) {
        Text('一键添加服务卡片到桌面')
          .fontSize(15)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.common_color_1'))
          .width('100%')

        Row({ space: 10 }) {
          Text('一键添加课表小组件')
            .fontSize(14)
            .fontColor($r('app.color.white'))
            .backgroundColor($r('app.color.sdmu_primary'))
            .borderRadius(20)
            .height(38)
            .textAlign(TextAlign.Center)
            .layoutWeight(1)
            .onClick(() => {
              this.pinWidget(WidgetDataHelper.FORM_SCHEDULE_WIDGET, WidgetDataHelper.DIMENSION_4_4);
            })

          Text('添加快捷入口卡片')
            .fontSize(14)
            .fontColor($r('app.color.sdmu_primary'))
            .backgroundColor('#FDECEE')
            .borderRadius(20)
            .height(38)
            .textAlign(TextAlign.Center)
            .layoutWeight(1)
            .onClick(() => {
              this.pinWidget(WidgetDataHelper.FORM_QUICK_ENTRY_WIDGET, WidgetDataHelper.DIMENSION_2_2);
            })
        }
        .width('100%')
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 12, bottom: 12 })
      .backgroundColor('#F8F9FB')

      // WebView SINGLE_COLUMN/WideViewPort 等价：图片全宽 + 可滚动
      Scroll() {
        Image(this.guideRes())
          .width('100%')
          .objectFit(ImageFit.Contain)
          .autoResize(true)
      }
      .scrollBar(BarState.Off)
      .width('100%')
      .layoutWeight(1)
      .align(Alignment.Top)
      .backgroundColor($r('app.color.white'))
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.white'))
  }
}
