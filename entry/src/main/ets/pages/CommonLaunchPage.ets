/**
 * 通用启动页 — 1:1 复刻 mobile_campus_common_launch.xml
 * 结构：LinearLayout(vertical)
 *   - ivBg 全屏背景图 centerCrop（mobile_campus_launch.png）
 *   - tvVersion 版本号（px_to_sp_24 → 12fp，默认 gone）
 *   - tvTimer 倒计时（px_to_sp_24 → 12fp，默认 gone，倒计时结束后显示"跳过"）
 */
@Entry
@Component
struct CommonLaunchPage {
  @State countDown: number = 3;
  @State versionText: string = 'V8.2.1';
  @State showLayout: boolean = false;
  private timerId: number = -1;

  aboutToAppear(): void {
    this.timerId = setInterval(() => {
      this.countDown = this.countDown - 1;
      if (this.countDown <= 0) {
        clearInterval(this.timerId);
        this.timerId = -1;
        this.showLayout = true;
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

      Text(`V${this.versionText.replace('V', '')}`)
        .fontSize(12)
        .fontColor($r('app.color.white'))
        .visibility(Visibility.None)

      Text(this.countDown > 0 ? `${this.countDown}s` : '跳过')
        .fontSize(12)
        .fontColor($r('app.color.white'))
        .visibility(Visibility.None)
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.black'))
  }
}
