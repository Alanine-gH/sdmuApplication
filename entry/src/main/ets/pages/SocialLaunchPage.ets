/**
 * 校圈启动页 — 1:1 复刻 MobileCampusSchoolCircleLaunchActivity（module.launch.view）
 * 原始 Activity 为壳工程 native 壳，视觉与通用启动页一致：
 *   - 全屏背景图 centerCrop
 *   - 中央校圈标识 schoolcircle + 名称（px_to_sp_40 → 20fp）
 *   - tvTimer 倒计时（px_to_sp_24 → 12fp）
 * 内置数据：倒计时 3 秒。
 */
@Entry
@Component
struct SocialLaunchPage {
  @State countDown: number = 3;
  @State circleName: string = '校圈';
  private timerId: number = -1;

  aboutToAppear(): void {
    this.timerId = setInterval(() => {
      this.countDown = this.countDown - 1;
      if (this.countDown <= 0) {
        clearInterval(this.timerId);
        this.timerId = -1;
        this.countDown = 0;
      }
    }, 1000);
  }

  aboutToDisappear(): void {
    if (this.timerId !== -1) {
      clearInterval(this.timerId);
      this.timerId = -1;
    }
  }

  build() {
    Stack({ alignContent: Alignment.Center }) {
      Image($r('app.media.mobile_campus_launch'))
        .width('100%')
        .height('100%')
        .objectFit(ImageFit.Cover)

      Column() {
        Image($r('app.media.schoolcircle'))
          .width(80)
          .height(80)

        Text(this.circleName)
          .fontSize(20)
          .fontColor($r('app.color.white'))
          .margin({ top: 15 })
      }
      .alignItems(HorizontalAlign.Center)

      Text(this.countDown > 0 ? `${this.countDown}s` : '进入')
        .fontSize(12)
        .fontColor($r('app.color.white'))
        .textAlign(TextAlign.Center)
        .padding({ left: 8, right: 8, top: 4, bottom: 4 })
        .borderRadius(12)
        .backgroundColor('#80FFFFFF')
        .position({ x: '85%', y: 12 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.black'))
  }
}
