import { TitleBar } from '../components/TitleBar';
import { EmptyView } from '../components/EmptyView';

/**
 * 统一通知页 — 统一空态（页面开发中）。
 * 数据源：无服务器接口支撑（ApiService 无统一通知端点），按零容忍原则不展示任何编造通知。
 */
@Entry
@Component
struct UnifyNotificationPage {
  build() {
    Column() {
      TitleBar({ title: '统一通知', showBack: true })
      EmptyView({ tipText: '页面开发中' })
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.main_bg'))
  }
}
