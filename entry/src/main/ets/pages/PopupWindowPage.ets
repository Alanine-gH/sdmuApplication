import { TitleBar } from '../components/TitleBar';
import { EmptyView } from '../components/EmptyView';

/**
 * 弹窗复刻页 — 统一空态（页面开发中）。
 * 数据源：无服务器接口支撑（学校切换清单未实证），按零容忍原则不展示任何编造学校/菜单数据。
 */
@Entry
@Component
struct PopupWindowPage {
  build() {
    Column() {
      TitleBar({ title: '', showBack: true })
      EmptyView({ tipText: '页面开发中' })
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.main_bg'))
  }
}
