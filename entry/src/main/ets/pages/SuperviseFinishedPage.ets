import { TitleBar } from '../components/TitleBar';
import { EmptyView } from '../components/EmptyView';

/**
 * 已督导详情页 — 统一空态（页面开发中）。
 * 数据源：无服务器接口支撑（督导记录端点未实证），按零容忍原则不展示任何编造督导记录。
 */
@Entry
@Component
struct SuperviseFinishedPage {
  build() {
    Column() {
      TitleBar({ title: '已督导', showBack: true })
      EmptyView({ tipText: '页面开发中' })
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.main_bg'))
  }
}
