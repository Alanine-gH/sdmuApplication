/**
 * 旧版启动页 — 1:1 复刻旧版 mobile_campus 启动布局（grep: launch）
 * 结构：LinearLayout(vertical)
 *   - ivBg 全屏背景图 mobile_campus_launch.png centerCrop
 *   - tvVersion 版本号（px_to_sp_24 → 12fp，左下角）
 *   - tvTimer 倒计时（px_to_sp_24 → 12fp，右上角）
 * 内置数据：版本号与 3 秒倒计时。
 */
@Entry
@Component
struct MobileCampusLaunchPage {
  @State countDown: number = 3;
  @State versionText: string = '8.2.1';
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
    Stack() {
      Image($r('app.media.mobile_campus_launch'))
        .width('100%')
        .height('100%')
        .objectFit(ImageFit.Cover)

      Text(`V${this.versionText}`)
        .fontSize(12)
        .fontColor($r('app.color.white'))
        .position({ x: 15, y: '95%' })

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
