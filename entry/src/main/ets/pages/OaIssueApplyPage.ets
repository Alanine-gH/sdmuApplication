import { TitleBar } from '../components/TitleBar';
import { EmptyView } from '../components/EmptyView';

/**
 * OA事项申请页 — 统一空态（页面开发中）。
 * 数据源：无服务器接口支撑（ApiService 无 OA 申请端点），按零容忍原则不展示任何编造预填数据。
 */
@Entry
@Component
struct OaIssueApplyPage {
  build() {
    Column() {
      TitleBar({ title: '事项申请', showBack: true })
      EmptyView({ tipText: '页面开发中' })
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.main_bg'))
  }
}
