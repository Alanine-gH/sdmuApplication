import { TitleBar } from '../components/TitleBar';
import { EmptyView } from '../components/EmptyView';

/**
 * 好友列表页 — 统一空态（页面开发中）。
 * 数据源：无服务器接口支撑（ApiService 无社交好友端点），按零容忍原则不展示任何编造好友名单。
 */
@Entry
@Component
struct FriendUserListPage {
  build() {
    Column() {
      TitleBar({ title: '好友' })
      EmptyView({ tipText: '页面开发中' })
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.main_bg'))
  }
}
