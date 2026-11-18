import { TitleBar } from '../components/TitleBar';
import { EmptyView } from '../components/EmptyView';

/**
 * 成绩图表页 — 统一空态（页面开发中）。
 * 数据源：无服务器接口支撑（ApiService 无成绩图表端点），按零容忍原则不展示任何编造图表/表格数据。
 */
@Entry
@Component
struct ScoreChartPage {
  build() {
    Column() {
      TitleBar({ title: '成绩图表' })
      EmptyView({ tipText: '页面开发中' })
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.main_bg'))
  }
}
