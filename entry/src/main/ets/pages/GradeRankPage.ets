import { TitleBar } from '../components/TitleBar';
import { EmptyView } from '../components/EmptyView';

/**
 * 绩点排行页 — 统一空态（页面开发中）。
 * 数据源：无服务器接口支撑（ApiService 无绩点排行端点），按零容忍原则不展示任何编造排行数据。
 */
@Entry
@Component
struct GradeRankPage {
  build() {
    Column() {
      TitleBar({ title: '绩点排行', showBack: true })
      EmptyView({ tipText: '页面开发中' })
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.main_bg'))
  }
}
