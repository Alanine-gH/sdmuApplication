import { TitleBar } from '../components/TitleBar';
import { EmptyView } from '../components/EmptyView';

/**
 * 校园地图页 — 统一空态（页面开发中）。
 * 数据源：无服务器接口支撑（ApiService 无地图/地点检索端点），按零容忍原则不展示任何编造地点数据。
 */
@Entry
@Component
struct SchoolMapPage {
  build() {
    Column() {
      TitleBar({ title: '校园地图' })
      EmptyView({ tipText: '页面开发中' })
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.main_bg'))
  }
}
