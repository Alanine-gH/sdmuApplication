import { TitleBar } from '../components/TitleBar';
import { EmptyView } from '../components/EmptyView';

/**
 * 演示页 — 统一空态（页面开发中）。
 * 无业务数据源，按零容忍原则不展示任何编造演示数据。
 */
@Entry
@Component
struct DemoPage {
  build() {
    Column() {
      TitleBar({ title: '演示', showBack: true })
      EmptyView({ tipText: '页面开发中' })
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.main_bg'))
  }
}
