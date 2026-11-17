import { router } from '@kit.ArkUI';

/**
 * 后台更新进度页 — 1:1 复刻源布局 activity_update_background.xml（后台更新承载页）
 * 并还原 hms_download_progress.xml（下载提示文本 + 半透明百分比 + 7vp 进度条）
 * 与 upsdk_ota_update_view.xml（应用名/版本/大小/更新详情滚动区，字色 upsdk_color_gray_10）
 */
const OTA_DETAIL: string = '1. 新增短视频首页，聚合校园热门内容；\n' +
  '2. 校园风光支持高清大图浏览与图片保存；\n' +
  '3. 修复部分机型课表显示异常的问题；\n' +
  '4. 提升应用启动速度与整体稳定性。';

@Entry
@Component
struct UpdateBackgroundPage {
  @State progressValue: number = 0;
  private timerId: number = -1;

  aboutToAppear(): void {
    this.timerId = setInterval(() => {
      if (this.progressValue >= 100) {
        clearInterval(this.timerId);
        this.timerId = -1;
        return;
      }
      this.progressValue = this.progressValue + 2;
    }, 120);
  }

  aboutToDisappear(): void {
    if (this.timerId !== -1) {
      clearInterval(this.timerId);
      this.timerId = -1;
    }
  }

  build() {
    Stack() {
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor('#FF101010')

      Scroll() {
        Column() {
          // hms_download_progress：下载提示 + 百分比 + 7vp 线性进度条
          Column() {
            Row() {
              Text('正在下载，请稍候…')
                .fontSize(13)
                .fontColor('#FFFFFFFF')
                .layoutWeight(1)
                .margin({ right: 8 })

              Text(`${this.progressValue}%`)
                .fontSize(13)
                .fontColor('#FFFFFFFF')
                .opacity(0.5)
            }
            .width('100%')
            .margin({ top: 16 })

            Progress({ value: this.progressValue, total: 100, type: ProgressType.Linear })
              .value(this.progressValue)
              .style({ strokeWidth: 7 })
              .color($r('app.color.mobile_campus_primary_color'))
              .backgroundColor('#33FFFFFF')
              .width('100%')
              .margin({ top: 10, bottom: 16 })
          }
          .padding({ left: 16, right: 16 })
          .width('100%')
          .borderRadius(12)
          .backgroundColor('#FF232323')
          .margin({ top: 24 })

          // upsdk_ota_update_view：应用名 / 版本 / 大小 / 更新详情
          Column() {
            Row() {
              Text('应用名称:')
                .fontSize(16)
                .fontColor($r('app.color.upsdk_color_gray_10'))

              Text('移动校园')
                .fontSize(16)
                .fontWeight(FontWeight.Medium)
                .fontColor($r('app.color.upsdk_color_gray_10'))
                .margin({ left: 16 })
            }
            .width('100%')
            .margin({ bottom: 8 })

            Row() {
              Text('应用版本:')
                .fontSize(16)
                .fontColor($r('app.color.upsdk_color_gray_10'))

              Text('V6.2.0')
                .fontSize(16)
                .fontWeight(FontWeight.Medium)
                .fontColor($r('app.color.upsdk_color_gray_10'))
                .margin({ left: 16 })
            }
            .width('100%')
            .margin({ bottom: 8 })

            Row() {
              Text('安装包大小:')
                .fontSize(16)
                .fontColor($r('app.color.upsdk_color_gray_10'))

              Text('28.6MB')
                .fontSize(16)
                .fontWeight(FontWeight.Medium)
                .fontColor($r('app.color.upsdk_color_gray_10'))
                .margin({ left: 16 })

              Text('（已下载 ${(this.progressValue * 0.286).toFixed(1)}MB）')
                .fontSize(16)
                .fontWeight(FontWeight.Medium)
                .fontColor($r('app.color.upsdk_color_gray_10'))
                .margin({ left: 16 })
            }
            .width('100%')

            Text('更新详情:')
              .fontSize(16)
              .fontColor($r('app.color.upsdk_color_gray_10'))
              .width('100%')
              .margin({ top: 24 })

            Text(OTA_DETAIL)
              .fontSize(14)
              .fontColor($r('app.color.upsdk_color_gray_10'))
              .lineHeight(22)
              .width('100%')
              .margin({ top: 16 })
          }
          .padding({ left: 24, right: 24 })
          .width('100%')
          .borderRadius(12)
          .backgroundColor('#FF232323')
          .margin({ top: 16, bottom: 32 })
        }
        .width('100%')
      }
      .width('100%')
      .height('100%')
      .scrollBar(BarState.Off)
      .align(Alignment.Top)
    }
    .width('100%')
    .height('100%')
    .onClick(() => {
      router.back();
    })
  }
}
