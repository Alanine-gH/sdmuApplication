import { TitleBar } from '../components/TitleBar';
import { EmptyView } from '../components/EmptyView';

/**
 * OA通知设置页 — 统一空态（页面开发中）。
 * 数据源：无服务器接口支撑（ApiService 无 OA 议题端点），按零容忍原则不展示任何编造会议通知。
 */
@Entry
@Component
struct OaIssueNotificationPage {
  build() {
    Column() {
      TitleBar({ title: '通知设置', showBack: true })
      EmptyView({ tipText: '页面开发中' })
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.main_bg'))
  }
}
