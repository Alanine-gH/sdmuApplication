import { TitleBar } from '../components/TitleBar';
import { EmptyView } from '../components/EmptyView';

/**
 * 日程周详情页 — 统一空态（页面开发中）。
 * 数据源：无服务器接口支撑（ApiService 无 OA 日程端点），按零容忍原则不展示任何编造课程/今日课程数据。
 */
@Entry
@Component
struct ScheduleWeekDetailPage {
  build() {
    Column() {
      TitleBar({ title: '本周课表', showBack: true })
      EmptyView({ tipText: '页面开发中' })
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.main_bg'))
  }
}
