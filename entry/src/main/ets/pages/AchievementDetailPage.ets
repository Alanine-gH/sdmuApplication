import { TitleBar } from '../components/TitleBar';
import { EmptyView } from '../components/EmptyView';

/**
 * 成果成员页 — 统一空态（页面开发中）。
 * 数据源：无服务器接口支撑，按零容忍原则不展示任何编造成员名单。
 */
@Entry
@Component
struct AchievementDetailPage {
  build() {
    Column() {
      TitleBar({ title: '成果成员' })
      EmptyView({ tipText: '页面开发中' })
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.main_bg'))
  }
}
