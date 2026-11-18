import { TitleBar } from '../components/TitleBar';
import { EmptyView } from '../components/EmptyView';

/**
 * 早餐打卡排名页 — 统一空态（页面开发中）。
 * 数据源：无服务器接口支撑（ApiService 无早餐打卡端点），按零容忍原则不展示任何编造排名数据。
 */
@Entry
@Component
struct BreakfastRankPage {
  build() {
    Column() {
      TitleBar({ title: '早餐打卡排名', showBack: true })
      EmptyView({ tipText: '页面开发中' })
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.main_bg'))
  }
}
