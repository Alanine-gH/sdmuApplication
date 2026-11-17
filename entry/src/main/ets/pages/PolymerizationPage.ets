import { TitleBar } from '../components/TitleBar';

/**
 * 聚合页 — 1:1 复刻 mobile_campus_polymerization.xml：
 * 白底竖向 Column 居中水平 + toolbar_normal（原页仅工具栏，用于设备登录跳转中转）。
 * 示例数据：中转状态文本区（原页面加载后立即 finish，此处静态展示）。
 */
@Entry
@Component
struct PolymerizationPage {
  @State transferResult: string = '扫码聚合中转：正在校验设备指纹...';

  build() {
    Column() {
      TitleBar({ title: '', showBack: true })

      Column() {
        Text(this.transferResult)
          .fontSize(14)
          .fontColor('#999999')
      }
      .width('100%')
      .padding({ top: 40 })
      .alignItems(HorizontalAlign.Center)
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.white'))
    .alignItems(HorizontalAlign.Center)
  }
}
