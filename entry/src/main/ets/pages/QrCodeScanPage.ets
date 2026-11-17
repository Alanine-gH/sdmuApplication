import { router } from '@kit.ArkUI';

/**
 * 扫码页 — 1:1 复刻 activity_qr_code_scan.xml：
 * FrameLayout 黑底 + SurfaceView 全屏（相机预览，静态黑屏占位）+
 * 竖向覆盖层：返回图标 56×56 pad16 marginT60 + 中部扫描线区(weight1，icon_scan_line 全宽上下循环动画) +
 * 底部 100vp：居中闪光灯按钮(19×33 图标 + "扫二维码/条码" 14fp 白 marginT8) +
 * 黑色操作条 100vp：右侧"相册"按钮(23×23 图标 + 12fp 白 marginT8 marginR21，pad 20/15)
 */
class ScanNavParams {
  content: string = '';
}

@Entry
@Component
struct QrCodeScanPage {
  @State scanLineOffset: number = 0;
  private scanAreaHeight: number = 0;
  private timerId: number = -1;

  aboutToAppear(): void {
    this.timerId = setInterval(() => {
      this.scanLineOffset = this.scanLineOffset >= 1 ? 0 : this.scanLineOffset + 0.02;
    }, 30);
  }

  aboutToDisappear(): void {
    if (this.timerId >= 0) {
      clearInterval(this.timerId);
      this.timerId = -1;
    }
  }

  private goResult(): void {
    const navParams: ScanNavParams = new ScanNavParams();
    navParams.content = 'https://portal.sdmu.edu.cn/scan?ticket=8f3a2c';
    router.pushUrl({
      url: 'pages/QrCodeScanResultPage',
      params: navParams
    });
  }

  build() {
    Stack() {
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor(Color.Black)

      Column() {
        Row() {
          Image($r('app.media.icon_scan_back'))
            .width(24)
            .height(24)
            .padding(16)
            .objectFit(ImageFit.Contain)
            .onClick(() => {
              router.back();
            })
        }
        .width('100%')
        .height(56)
        .margin({ top: 60 })
        .justifyContent(FlexAlign.Start)
        .alignItems(VerticalAlign.Center)

        Stack() {
          Image($r('app.media.icon_scan_line'))
            .width('100%')
            .objectFit(ImageFit.Fill)
            .offset({ y: this.scanLineOffset * this.scanAreaHeight })
        }
        .width('100%')
        .layoutWeight(1)
        .clip(true)
        .onAreaChange((oldArea: Area, newArea: Area) => {
          this.scanAreaHeight = Number(newArea.height);
        })

        Column() {
          Column() {
            Image($r('app.media.icon_scan_light_close'))
              .width(19)
              .height(33)
              .objectFit(ImageFit.Contain)

            Text('扫二维码/条码')
              .fontSize(14)
              .fontColor($r('app.color.white'))
              .margin({ top: 8 })
          }
          .padding({ left: 20, right: 20 })
          .alignItems(HorizontalAlign.Center)
        }
        .width('100%')
        .height(100)
        .justifyContent(FlexAlign.Start)
        .alignItems(HorizontalAlign.Center)
      }
      .width('100%')
      .height('100%')

      Column() {
        Row() {
          Column() {
            Image($r('app.media.icon_scan_album'))
              .width(23)
              .height(23)
              .objectFit(ImageFit.Contain)

            Text('相册')
              .fontSize(12)
              .fontColor($r('app.color.white'))
              .margin({ top: 8 })
          }
          .padding({ left: 20, right: 20, top: 15, bottom: 15 })
          .margin({ right: 21 })
          .alignItems(HorizontalAlign.Center)
          .onClick(() => {
            this.goResult();
          })
        }
        .width('100%')
        .height(100)
        .backgroundColor(Color.Black)
        .justifyContent(FlexAlign.End)
        .alignItems(VerticalAlign.Center)
      }
      .width('100%')
      .height('100%')
      .justifyContent(FlexAlign.End)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(Color.Black)
  }
}
