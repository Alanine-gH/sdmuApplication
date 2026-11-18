import { TitleBar } from '../components/TitleBar';
import { EmptyView } from '../components/EmptyView';

/**
 * 校园动态列表页 — 统一空态（页面开发中）。
 * 数据源：无服务器接口支撑（ApiService 无社交动态端点），按零容忍原则不展示任何编造帖子。
 */
@Entry
@Component
struct SocialNewsPage {
  build() {
    Column() {
      TitleBar({ title: '校园动态' })
      EmptyView({ tipText: '页面开发中' })
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.main_bg'))
  }
}
