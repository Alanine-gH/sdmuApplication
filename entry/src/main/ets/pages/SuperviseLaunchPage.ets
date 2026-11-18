/**
 * 督导启动路由页 — 1:1 复刻 activity_supervise_launch.xml：
 * - 纯路由中转页：ConstraintLayout fill_parent、无任何子视图；
 * - 源码 f1()：g2(a.G0 supervise/main) + finish（无条件直达督导首页），本页停留时长为 0。
 */
import { router } from '@kit.ArkUI';

@Entry
@Component
struct SuperviseLaunchPage {
  aboutToAppear(): void {
    router.replaceUrl({ url: 'pages/SupervisePage' });
  }

  build() {
    Column()
      .width('100%')
      .height('100%')
      .backgroundColor(Color.Transparent)
  }
}
