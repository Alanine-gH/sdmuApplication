import { TitleBar } from '../components/TitleBar';
import { EmptyView } from '../components/EmptyView';

/**
 * 一卡通消费报表页 — 统一空态（页面开发中）。
 * 数据源：无服务器接口支撑（ApiService 无一卡通消费端点），按零容忍原则不展示任何编造消费数据。
 */
@Entry
@Component
struct CardConsumeReportPage {
  build() {
    Column() {
      TitleBar({ title: '一卡通消费', showBack: true })
      EmptyView({ tipText: '页面开发中' })
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.main_bg'))
  }
}
