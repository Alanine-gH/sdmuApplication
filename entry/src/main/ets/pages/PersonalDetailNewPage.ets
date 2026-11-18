import { TitleBar } from '../components/TitleBar';
import { EmptyView } from '../components/EmptyView';

/**
 * 个人详情旧复刻页 — 统一空态（页面开发中）。
 * 已被源码级 PersonalDetailPage（getUserInfo 真接口）取代；本页按零容忍原则不展示任何编造用户数据。
 */
@Entry
@Component
struct PersonalDetailNewPage {
  build() {
    Column() {
      TitleBar({ title: '个人详情', showBack: true })
      EmptyView({ tipText: '页面开发中' })
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.main_bg'))
  }
}
