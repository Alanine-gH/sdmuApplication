import { TitleBar } from '../components/TitleBar';
import { EmptyView } from '../components/EmptyView';

/**
 * OA部门待办页 — 统一空态（页面开发中）。
 * 数据源：无服务器接口支撑（ApiService 无组织架构部门端点），按零容忍原则不展示任何编造部门清单。
 */
@Entry
@Component
struct TodoDepartmentPage {
  build() {
    Column() {
      TitleBar({ title: '部门待办' })
      EmptyView({ tipText: '页面开发中' })
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.main_bg'))
  }
}
