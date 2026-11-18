import { TitleBar } from '../components/TitleBar';
import { EmptyView } from '../components/EmptyView';

/**
 * 请假名单页 — 统一空态（页面开发中）。
 * 数据源：无服务器接口支撑（ApiService 无请假学生列表端点），按零容忍原则不展示任何编造请假记录。
 */
@Entry
@Component
struct TimetableLeaveDetailPage {
  build() {
    Column() {
      TitleBar({ title: '请假名单', showBack: true })
      EmptyView({ tipText: '页面开发中' })
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.main_bg'))
  }
}
