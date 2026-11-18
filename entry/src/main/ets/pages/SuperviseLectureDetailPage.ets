import { TitleBar } from '../components/TitleBar';
import { EmptyView } from '../components/EmptyView';

/**
 * 听课详情页 — 统一空态（页面开发中）。
 * 数据源：无服务器接口支撑（督导听课端点未实证），按零容忍原则不展示任何编造课程/教师数据。
 */
@Entry
@Component
struct SuperviseLectureDetailPage {
  build() {
    Column() {
      TitleBar({ title: '听课详情', showBack: true })
      EmptyView({ tipText: '页面开发中' })
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.main_bg'))
  }
}
