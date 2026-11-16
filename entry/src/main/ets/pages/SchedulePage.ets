import { TitleBar } from '../components/TitleBar';
import { ScheduleGrid } from '../components/ScheduleGrid';

/**
 * 课表页：周视图。
 */
@Entry
@Component
struct SchedulePage {
  build() {
    Column() {
      TitleBar({ title: '我的课表', showBack: true })
      ScheduleGrid()
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.sdmu_card_bg'))
  }
}
