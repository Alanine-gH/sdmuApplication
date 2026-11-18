import { TitleBar } from '../components/TitleBar';
import { EmptyView } from '../components/EmptyView';

/**
 * 议题详情页 — 统一空态（页面开发中）。
 * 数据源：无服务器接口支撑（ApiService 无 OA 议题详情端点），按零容忍原则不展示任何编造议题/流程数据。
 */
@Entry
@Component
struct OaIssueDetailPage {
  build() {
    Column() {
      TitleBar({ title: '议题详情', showBack: true })
      EmptyView({ tipText: '页面开发中' })
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.main_bg'))
  }
}
