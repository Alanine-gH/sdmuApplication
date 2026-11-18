import { TitleBar } from '../components/TitleBar';
import { EmptyView } from '../components/EmptyView';

/**
 * 校圈举报页 — 统一空态（页面开发中）。
 * 数据源：无服务器接口支撑（举报理由/提交端点未实证），按零容忍原则不展示任何编造理由清单。
 */
@Entry
@Component
struct SocialReportPage {
  build() {
    Column() {
      TitleBar({ title: '举报' })
      EmptyView({ tipText: '页面开发中' })
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.main_bg'))
  }
}
