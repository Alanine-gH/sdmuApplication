import { TitleBar } from '../components/TitleBar';
import { EmptyView } from '../components/EmptyView';

/**
 * OA事项页 — 统一空态（页面开发中）。
 * 数据源：无服务器接口支撑（ApiService 无 OA 议题端点），按零容忍原则不展示任何编造会议议题。
 */
@Entry
@Component
struct OaIssuePage {
  build() {
    Column() {
      TitleBar({ title: 'OA事项', showBack: true })
      EmptyView({ tipText: '页面开发中' })
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.main_bg'))
  }
}
