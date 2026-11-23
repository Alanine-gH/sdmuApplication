import { router } from '@kit.ArkUI';
import { BreakpointSystem } from '../common/BreakpointSystem';

/**
 * 下载进度弹窗页 — 1:1 复刻源布局 dialog_download.xml 与 new_download_dialog.xml
 * style=classic: dialog_download（16vp 圆角白卡 + 标题 + 说明 + 5vp 进度条 + 百分比 + 暂停/取消按钮）
 * style=new: new_download_dialog（dialog_bg 背景图 + 发现新版本/版本号 + 关闭 + 环形下载进度 + 说明 + 55vp 底部双按钮）
 * download_dialog_super.xml 的卡片结构已并入 AppUpdatePage（variant=2 同族单按钮样式）
 */
const DOWNLOAD_MSG: string = '【新增】短视频首页增加今日热门\n【优化】修复部分已知问题，提升稳定性\n' +
  '【优化】优化课表刷新体验，加载更流畅';

@Entry
@Component
struct DownloadDialogPage {
  @State dialogStyle: string = 'classic';
  @State progressValue: number = 0;
  @State paused: boolean = false;
  @StorageProp('currentBreakpoint') currentBreakpoint: string = 'sm';
  @StorageProp('windowWidthVp') windowWidthVp: number = 360;
  @StorageProp('windowHeightVp') windowHeightVp: number = 640;
  @StorageProp('avoidAreaTopVp') avoidAreaTopVp: number = 0;
  @StorageProp('avoidAreaBottomVp') avoidAreaBottomVp: number = 0;
  @StorageProp('avoidAreaLeftVp') avoidAreaLeftVp: number = 0;
  @StorageProp('avoidAreaRightVp') avoidAreaRightVp: number = 0;
  private timerId: number = -1;

  aboutToAppear(): void {
    const params: object = router.getParams();
    if (params !== null && params !== undefined) {
      const record = params as Record<string, Object>;
      const s: Object = record['style'];
      if (typeof s === 'string') {
        this.dialogStyle = s;
      }
    }
    this.timerId = setInterval(() => {
      if (this.paused) {
        return;
      }
      if (this.progressValue >= 100) {
        clearInterval(this.timerId);
        this.timerId = -1;
        return;
      }
      this.progressValue = this.progressValue + 3;
    }, 150);
  }

  aboutToDisappear(): void {
    if (this.timerId !== -1) {
      clearInterval(this.timerId);
      this.timerId = -1;
    }
  }

  private togglePause(): void {
    this.paused = !this.paused;
  }

  private closeDialog(): void {
    if (this.timerId !== -1) {
      clearInterval(this.timerId);
      this.timerId = -1;
    }
    router.back();
  }

  @Builder
  /** dialog_download.xml：16vp 圆角白卡样式 */
  classicCard() {
    Column() {
      Text('发现新版本')
        .fontSize(17)
        .fontWeight(FontWeight.Bold)
        .fontColor('#FF000000')
        .textAlign(TextAlign.Center)
        .maxLines(1)
        .width('100%')
        .padding({ top: 24 })

      Scroll() {
        Column() {
          Text(DOWNLOAD_MSG)
            .fontSize(16)
            .fontColor($r('app.color.textColor'))
            .textAlign(TextAlign.Center)
            .lineHeight(24)
            .padding({ left: 20, right: 20, top: 24 })
            .width('100%')

          // 下载进度行：5vp 线性进度条 + 百分比
          Row() {
            Progress({ value: this.progressValue, total: 100, type: ProgressType.Linear })
              .value(this.progressValue)
              .style({ strokeWidth: 5 })
              .color($r('app.color.mobile_campus_primary_color'))
              .backgroundColor('#FFE0E0E0')
              .layoutWeight(1)
              .margin({ right: 20 })

            Text(`${this.progressValue}%`)
              .fontSize(14)
              .fontColor($r('app.color.textColor'))
          }
          .width('100%')
          .padding({ left: 20, right: 20, top: 15, bottom: 24 })
        }
        .width('100%')
      }
      .width('100%')
      .constraintSize({ maxHeight: Math.max(100, BreakpointSystem.getDialogMaxHeight(this.windowHeightVp) - 130) })
      .scrollBar(BarState.Off)

      Divider()
        .color($r('app.color.update_dialog_divider'))
        .strokeWidth(0.5)
        .width('100%')

      Row() {
        Text(this.paused ? '继续下载' : '暂停下载')
          .fontSize(17)
          .fontColor('#FF999999')
          .textAlign(TextAlign.Center)
          .maxLines(1)
          .layoutWeight(1)
          .padding({ left: 20, right: 20, top: 11.5, bottom: 11.5 })
          .onClick(() => {
            this.togglePause();
          })

        Divider()
          .vertical(true)
          .color($r('app.color.update_dialog_divider'))
          .strokeWidth(0.5)
          .height('100%')

        Text('取消')
          .fontSize(17)
          .fontColor($r('app.color.mobile_campus_primary_color'))
          .textAlign(TextAlign.Center)
          .maxLines(1)
          .layoutWeight(1)
          .padding({ left: 20, right: 20, top: 11.5, bottom: 11.5 })
          .onClick(() => {
            this.closeDialog();
          })
      }
      .width('100%')
    }
    .width('100%')
    .borderRadius(16)
    .backgroundColor($r('app.color.white'))
  }

  @Builder
  /** new_download_dialog.xml：dialog_bg 背景图样式 */
  newCard() {
    Column() {
      // 顶部区：标题 + 版本号 + 右上角关闭
      Stack({ alignContent: Alignment.TopEnd }) {
        Column() {
          Text('发现新版本')
            .fontSize(17)
            .fontColor('#FFFFFFFF')
            .padding({ left: 22, top: 20 })

          Text('V6.2.0')
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .fontColor('#FFFFFFFF')
            .margin({ left: 22, top: 4 })
        }
        .alignItems(HorizontalAlign.Start)
        .width('100%')

        Image($r('app.media.update_close'))
          .objectFit(ImageFit.Contain)
          .width(20)
          .height(20)
          .padding(12)
          .margin({ top: 8, right: 8 })
          .onClick(() => {
            this.closeDialog();
          })
      }
      .width('100%')
      .layoutWeight(5)

      // 环形下载进度（对应源 ProgressView）
      Column() {
        Stack() {
          Progress({ value: this.progressValue, total: 100, type: ProgressType.Eclipse })
            .value(this.progressValue)
            .style({ strokeWidth: 6 })
            .color($r('app.color.white'))
            .backgroundColor('#33FFFFFF')
            .width(56)
            .height(56)

          Text(`${this.progressValue}%`)
            .fontSize(12)
            .fontColor('#FFFFFFFF')
        }
        .width(56)
        .height(56)
        .alignContent(Alignment.Center)
      }
      .width('100%')
      .justifyContent(FlexAlign.Center)
      .layoutWeight(4)

      Scroll() {
        Text(DOWNLOAD_MSG)
          .fontSize(12)
          .fontColor($r('app.color.download_msg_gray'))
          .lineHeight(18)
          .padding({ left: 22, right: 22, top: 12, bottom: 12 })
          .width('100%')
      }
      .width('100%')
      .layoutWeight(4)
      .scrollBar(BarState.Off)

      Divider()
        .color($r('app.color.download_divider'))
        .strokeWidth(1.5)
        .width('100%')

      // 底部 55vp 双按钮：暂不更新 / 立即更新
      Row() {
        Text('暂不更新')
          .fontSize(16)
          .fontColor($r('app.color.download_btn_green'))
          .textAlign(TextAlign.Center)
          .layoutWeight(1)
          .height('100%')
          .onClick(() => {
            this.closeDialog();
          })

        Divider()
          .vertical(true)
          .color($r('app.color.download_divider'))
          .strokeWidth(1.5)
          .height('100%')

        Text('立即更新')
          .fontSize(16)
          .fontColor($r('app.color.download_btn_green'))
          .textAlign(TextAlign.Center)
          .layoutWeight(1)
          .height('100%')
          .onClick(() => {
            this.closeDialog();
          })
      }
      .width('100%')
      .height(55)
    }
    .width('100%')
    .height('100%')
    .borderRadius(16)
    .clip(true)
  }

  build() {
    if (this.dialogStyle === 'new') {
      // new_download_dialog：背景图卡片 + 半透明遮罩居中
      Stack() {
        Column()
          .width('100%')
          .height('100%')
          .backgroundColor($r('app.color.alpha_20'))

        Column() {
          Stack() {
            Image($r('app.media.dialog_bg'))
              .objectFit(ImageFit.Fill)
              .width('100%')
              .height('100%')

            this.newCard()
          }
          .width('82%')
          .height(Math.min(420, BreakpointSystem.getDialogMaxHeight(this.windowHeightVp)))
          .constraintSize({
            maxWidth: BreakpointSystem.getDialogMaxWidth(this.currentBreakpoint, this.windowWidthVp),
            maxHeight: BreakpointSystem.getDialogMaxHeight(this.windowHeightVp)
          })
        }
        .width('100%')
        .height('100%')
        .padding({
          top: this.avoidAreaTopVp,
          bottom: this.avoidAreaBottomVp,
          left: this.avoidAreaLeftVp,
          right: this.avoidAreaRightVp
        })
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#FF1A1A1A')
      .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
    } else {
      // dialog_download：白卡居中
      Stack() {
        Column()
          .width('100%')
          .height('100%')
          .backgroundColor($r('app.color.alpha_20'))

        Column() {
          Column() {
            this.classicCard()
          }
          .width('86%')
          .constraintSize({
            maxWidth: BreakpointSystem.getDialogMaxWidth(this.currentBreakpoint, this.windowWidthVp),
            maxHeight: BreakpointSystem.getDialogMaxHeight(this.windowHeightVp)
          })
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)
        }
        .width('100%')
        .height('100%')
        .padding({
          top: this.avoidAreaTopVp,
          bottom: this.avoidAreaBottomVp,
          left: this.avoidAreaLeftVp,
          right: this.avoidAreaRightVp
        })
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#FF1A1A1A')
      .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
    }
  }
}
