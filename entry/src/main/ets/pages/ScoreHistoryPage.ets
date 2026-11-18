import { TitleBar } from '../components/TitleBar';
import { EmptyView } from '../components/EmptyView';

/**
 * 成绩历史（搜索记录）页 — 统一空态（页面开发中）。
 * 数据源：无服务器接口支撑（ApiService 无成绩搜索端点），按零容忍原则不展示任何编造搜索记录。
 */
@Entry
@Component
struct ScoreHistoryPage {
  build() {
    Column() {
      TitleBar({ title: '成绩查询', showBack: true })
      EmptyView({ tipText: '页面开发中' })
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.main_bg'))
  }
}
