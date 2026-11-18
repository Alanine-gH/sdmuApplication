import { TitleBar } from '../components/TitleBar';
import { EmptyView } from '../components/EmptyView';

/**
 * 图书借阅报表页 — 统一空态（页面开发中）。
 * 数据源：无服务器接口支撑（ApiService 无图书借阅端点），按零容忍原则不展示任何编造借阅数据。
 */
@Entry
@Component
struct BookBorrowReportPage {
  build() {
    Column() {
      TitleBar({ title: '图书借阅', showBack: true })
      EmptyView({ tipText: '页面开发中' })
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.main_bg'))
  }
}
