import { TitleBar } from '../components/TitleBar';
import { EmptyView } from '../components/EmptyView';

/**
 * 票据预览页 — 统一空态（页面开发中）。
 * 数据源：无服务器接口支撑（ApiService 无票据端点），按零容忍原则不展示任何编造票据。
 */
@Entry
@Component
struct ReceiptImagePage {
  build() {
    Column() {
      TitleBar({ title: '票据预览' })
      EmptyView({ tipText: '页面开发中' })
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.main_bg'))
  }
}
