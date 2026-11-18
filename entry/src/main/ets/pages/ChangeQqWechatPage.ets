import { TitleBar } from '../components/TitleBar';
import { EmptyView } from '../components/EmptyView';

/**
 * 账号绑定页 — 统一空态（页面开发中）。
 * 数据源：无服务器接口支撑（绑定状态/账号端点未实证），按零容忍原则不展示任何编造账号数据。
 */
@Entry
@Component
struct ChangeQqWechatPage {
  build() {
    Column() {
      TitleBar({ title: '账号绑定', showBack: true })
      EmptyView({ tipText: '页面开发中' })
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.main_bg'))
  }
}
