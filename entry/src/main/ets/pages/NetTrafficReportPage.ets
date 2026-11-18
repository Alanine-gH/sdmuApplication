import { TitleBar } from '../components/TitleBar';
import { EmptyView } from '../components/EmptyView';

/**
 * 上网流量报表页 — 统一空态（页面开发中）。
 * 数据源：无服务器接口支撑（ApiService 无上网流量端点），按零容忍原则不展示任何编造流量数据。
 */
@Entry
@Component
struct NetTrafficReportPage {
  build() {
    Column() {
      TitleBar({ title: '上网流量', showBack: true })
      EmptyView({ tipText: '页面开发中' })
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.main_bg'))
  }
}
