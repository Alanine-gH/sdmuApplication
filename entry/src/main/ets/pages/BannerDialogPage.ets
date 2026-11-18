import { TitleBar } from '../components/TitleBar';
import { EmptyView } from '../components/EmptyView';

/**
 * 主页 Banner 弹窗页 — 统一空态（页面开发中）。
 * 数据源：无服务器接口支撑（ApiService 无 banner 端点），按零容忍原则不展示任何编造 banner 数据。
 */
@Entry
@Component
struct BannerDialogPage {
  build() {
    Column() {
      TitleBar({ title: '' })
      EmptyView({ tipText: '页面开发中' })
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.main_bg'))
  }
}
