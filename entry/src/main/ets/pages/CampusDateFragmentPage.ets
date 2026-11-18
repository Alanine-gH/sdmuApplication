import { TitleBar } from '../components/TitleBar';
import { EmptyView } from '../components/EmptyView';

/**
 * 日期选择页 — 统一空态（页面开发中）。
 * 数据源：无服务器接口支撑，且无本地农历计算能力，按零容忍原则不展示任何编造日期/农历数据。
 */
@Entry
@Component
struct CampusDateFragmentPage {
  build() {
    Column() {
      TitleBar({ title: '日期选择', showBack: true })
      EmptyView({ tipText: '页面开发中' })
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.main_bg'))
  }
}
