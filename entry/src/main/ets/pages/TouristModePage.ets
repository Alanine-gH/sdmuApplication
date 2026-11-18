import { TitleBar } from '../components/TitleBar';
import { EmptyView } from '../components/EmptyView';

/**
 * 游客模式页 — 统一空态（页面开发中）。
 * 数据源：无服务器接口支撑（游客资讯端点未实证），按零容忍原则不展示任何编造资讯。
 */
@Entry
@Component
struct TouristModePage {
  build() {
    Column() {
      TitleBar({ title: '游客模式' })
      EmptyView({ tipText: '页面开发中' })
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.main_bg'))
  }
}
