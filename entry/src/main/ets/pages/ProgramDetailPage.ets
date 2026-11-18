import { TitleBar } from '../components/TitleBar';
import { EmptyView } from '../components/EmptyView';

/**
 * 项目明细页 — 统一空态（页面开发中）。
 * 数据源：无服务器接口支撑（ApiService 无科研项目端点），按零容忍原则不展示任何编造项目明细。
 */
@Entry
@Component
struct ProgramDetailPage {
  build() {
    Column() {
      TitleBar({ title: '项目明细' })
      EmptyView({ tipText: '页面开发中' })
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.main_bg'))
  }
}
