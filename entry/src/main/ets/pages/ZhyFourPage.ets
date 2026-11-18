import { TitleBar } from '../components/TitleBar';
import { EmptyView } from '../components/EmptyView';

/**
 * 迎新四准则页 — 统一空态（页面开发中）。
 * 数据源：无服务器接口支撑，按零容忍原则不展示任何编造准则内容。
 */
@Entry
@Component
struct ZhyFourPage {
  build() {
    Column() {
      TitleBar({ title: '迎新四准则', showBack: true })
      EmptyView({ tipText: '页面开发中' })
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.main_bg'))
  }
}
