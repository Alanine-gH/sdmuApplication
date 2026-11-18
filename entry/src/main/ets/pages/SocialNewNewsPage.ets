import { TitleBar } from '../components/TitleBar';
import { EmptyView } from '../components/EmptyView';

/**
 * 最新动态页 — 统一空态（页面开发中）。
 * 数据源：无服务器接口支撑（ApiService 无校园资讯端点），按零容忍原则不展示任何编造资讯。
 */
@Entry
@Component
struct SocialNewNewsPage {
  build() {
    Column() {
      TitleBar({ title: '最新动态' })
      EmptyView({ tipText: '页面开发中' })
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.main_bg'))
  }
}
