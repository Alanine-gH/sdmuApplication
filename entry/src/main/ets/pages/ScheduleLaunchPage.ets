import { router } from '@kit.ArkUI';

/**
 * 日程启动页 — 1:1 复刻 mobile_campus_schedule_guide.xml（ScheduleLaunchActivity，action=sdgy_schedule）
 * 结构：LinearLayout gravity=center(竖向) + ImageView(mobile_campus_schedule_shader 720x452)
 * 外部协议入口页：展示日程引导图后跳转日程主页。
 *
 * 数据源：无服务器接口 — 纯引导展示，1.5s 后跳转 ScheduleMainActivity。
 */
@Entry
@Component
struct ScheduleLaunchPage {
  @State launched: boolean = false;

  private goScheduleMain(): void {
    if (this.launched) {
      return;
    }
    this.launched = true;
    router.replaceUrl({ url: 'pages/ScheduleMainActivity' });
  }

  aboutToAppear(): void {
    setTimeout(() => {
      this.goScheduleMain();
    }, 1500);
  }

  build() {
    Column() {
      Image($r('app.media.mobile_campus_schedule_shader'))
        .width(300)
        .height(188)
        .objectFit(ImageFit.Contain)
        .onClick(() => {
          this.goScheduleMain();
        })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .backgroundColor($r('app.color.main_bg'))
  }
}
