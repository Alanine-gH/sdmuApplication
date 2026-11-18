import { TitleBar } from '../components/TitleBar';
import { EmptyView } from '../components/EmptyView';

/**
 * 校圈主页 — 统一空态（页面开发中）。
 * 数据源：无服务器接口支撑（ApiService 无社交帖子端点），按零容忍原则不展示任何编造帖子/阅读数据。
 */
@Entry
@Component
struct SocialHomePage {
  build() {
    Column() {
      TitleBar({ title: '校圈' })
      EmptyView({ tipText: '页面开发中' })
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.main_bg'))
  }
}
