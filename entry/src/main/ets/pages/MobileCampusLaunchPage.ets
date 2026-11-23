import { BreakpointSystem } from '../common/BreakpointSystem';

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
  @StorageProp('currentBreakpoint') currentBreakpoint: string = 'sm';
  @StorageProp('avoidAreaTopVp') avoidAreaTopVp: number = 0;
  @StorageProp('avoidAreaBottomVp') avoidAreaBottomVp: number = 0;
  @StorageProp('avoidAreaLeftVp') avoidAreaLeftVp: number = 0;
  @StorageProp('avoidAreaRightVp') avoidAreaRightVp: number = 0;
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
        .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])

      Scroll() {
        Column() {
          Row() {
            Blank()
            Text(this.countDown > 0 ? `${this.countDown}s` : '进入')
              .fontSize(12)
              .fontColor($r('app.color.white'))
              .textAlign(TextAlign.Center)
              .padding({ left: 8, right: 8, top: 4, bottom: 4 })
              .borderRadius(12)
              .backgroundColor('#80FFFFFF')
          }
          .width('100%')

          Blank()

          Row() {
            Text(`V${this.versionText}`)
              .fontSize(12)
              .fontColor($r('app.color.white'))
          }
          .width('100%')
        }
        .width('100%')
        .constraintSize({
          minHeight: '100%',
          maxWidth: BreakpointSystem.getContentMaxWidth(this.currentBreakpoint)
        })
        .padding({
          top: Math.max(12, this.avoidAreaTopVp + 12),
          bottom: Math.max(16, this.avoidAreaBottomVp + 12),
          left: Math.max(15, this.avoidAreaLeftVp + 15),
          right: Math.max(15, this.avoidAreaRightVp + 15)
        })
      }
      .width('100%')
      .height('100%')
      .scrollBar(BarState.Off)
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.black'))
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
  }
}
