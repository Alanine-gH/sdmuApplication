import { router } from '@kit.ArkUI';

/**
 * 课表桌面小部件登录跳转页 — 1:1 复刻 TimeTableLoginActivity（lyyd/timetable/view，32 行）
 * [W22 launch-chain] 源码级翻译：J1()=0 无布局透明壳，f1() 唯一动作：
 *   g2(e.a.u = R$string.mobile_campus_launch_login = "/launch/newlogin"
 *   → MobileCampusLoginNewActivity)，随即 finish()。
 * HAP 等价：replaceUrl pages/LoginPage（/launch/newlogin 既有翻译页）。
 * 独立账号体系考证：timetable 包无自有登录接口（d/b|c|f.java 全部走校内 /mobileapi_ydxy
 * 加密通道，复用主登录会话）——桌面小部件（WidgetProvider/WeekCourseWidgetProvider/
 * DayCourseWidgetProvider setOnClickPendingIntent → TimeTableLoginActivity）在未登录时
 * 统一分发到主登录页，不是独立账号体系。
 * 入口链：timetable 三个桌面小部件（HAP 桌面卡片未实现，链路保留）。
 */
@Entry
@Component
struct TimeTableLoginPage {
  aboutToAppear(): void {
    // 源码 f1()：g2(e.a.u, null) + finish()
    router.replaceUrl({ url: 'pages/LoginPage' });
  }

  build() {
    // J1()=0：无 setContentView，透明空壳页
    Stack()
      .width('100%')
      .height('100%')
      .backgroundColor(Color.Transparent)
  }
}
