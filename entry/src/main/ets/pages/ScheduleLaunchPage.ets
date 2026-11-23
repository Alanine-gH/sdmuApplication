import { router } from '@kit.ArkUI';

/**
 * 课表模块启动跳转页 — 1:1 复刻 ScheduleLaunchActivity（lyyd/schedule/view，33 行）
 * [W22 launch-chain] 源码级翻译：J1()=0 无布局透明壳，f1() 唯一动作：
 *   g2(e.a.u0 = R$string.mobile_campus_schedule_message_schedule = "/schedule/main"
 *   → ScheduleMainActivity)，随即 finish()。
 * HAP 等价：replaceUrl pages/ScheduleMainActivity（/schedule/main 既有翻译页）。
 * 旧占位的"引导图 + 1.5s 延时"为编造（源码 J1()=0 无 mobile_campus_schedule_guide 布局、
 * 无任何延时）——本次按源码清除。
 * 入口链：全源码（含 dex2/3 smali）无显式调用方 —— 外部显式 Intent 入口，应用内无导航；
 * 本页为源码壳页忠实翻译。
 */
@Entry
@Component
struct ScheduleLaunchPage {
  aboutToAppear(): void {
    // 源码 f1()：g2(a.u0, null) + finish()
    router.replaceUrl({ url: 'pages/ScheduleMainActivity' });
  }

  build() {
    // J1()=0：无 setContentView，透明空壳页
    Stack()
      .width('100%')
      .height('100%')
      .backgroundColor(Color.Transparent)
      .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
  }
}
