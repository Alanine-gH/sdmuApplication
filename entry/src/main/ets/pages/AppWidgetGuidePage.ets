import { TitleBar } from '../components/TitleBar';
import { WidgetDataHelper } from '../common/WidgetDataHelper';

/**
 * 桌面小组件引导页 — HarmonyOS 原生桌面服务卡片添加引导页。
 * 使用华为 HarmonyOS 真机四步引导长图（mobile_campus_timetable_guide_huawei），
 * 并提供原生 formProvider.openFormManager 一键添加到桌面入口与安全降级提示。
 */
@Entry
@Component
struct AppWidgetGuidePage {
  /** HarmonyOS 桌面卡片引导图资源 */
  private guideRes(): Resource {
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
