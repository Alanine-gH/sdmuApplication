import { TitleBar } from '../components/TitleBar';

class ReceiptImage {
  name: string = '';
  desc: string = '';

  constructor(name: string, desc: string) {
    this.name = name;
    this.desc = desc;
  }
}

@Entry
@Component
struct ReceiptImagePage {
  @State currentIndex: number = 0;
  private images: ReceiptImage[] = [
    new ReceiptImage('发票-交通费', '2026-05-12 增值税普通发票'),
    new ReceiptImage('发票-住宿费', '2026-05-12 增值税专用发票'),
    new ReceiptImage('发票-会议注册费', '2026-05-13 电子发票')
  ];

  @Builder
  imageCard(item: ReceiptImage) {
    Column() {
      Column() {
        Image($r('app.media.mobile_campus_reimburse_ticketfoot'))
          .width(200)
          .height(120)
          .objectFit(ImageFit.Contain)
        Text(item.name)
          .fontSize(16)
          .fontColor($r('app.color.common_color_1'))
          .margin({ top: 16 })
        Text(item.desc)
          .fontSize(13)
          .fontColor($r('app.color.common_color_3'))
          .margin({ top: 8 })
      }
      .width('100%')
      .padding(20)
      .backgroundColor($r('app.color.white'))
      .borderRadius(8)
      .alignItems(HorizontalAlign.Center)
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
  }

  build() {
    Column() {
      TitleBar({ title: '票据预览' })
      Stack() {
        Swiper() {
          ForEach(this.images, (item: ReceiptImage, index: number) => {
            this.imageCard(item)
          }, (item: ReceiptImage, index: number) => 'img_' + index + '_' + item.name)
        }
        .width('100%')
        .layoutWeight(1)
        .onChange((index: number) => {
          this.currentIndex = index;
        })

        Row() {
          ForEach(this.images, (item: ReceiptImage, index: number) => {
            Circle()
              .width(6)
              .height(6)
              .fill(this.currentIndex === index ? $r('app.color.blue_default') : $r('app.color.common_color_24'))
              .margin({ left: index > 0 ? 6 : 0 })
          }, (item: ReceiptImage, index: number) => 'dot_' + index)
        }
        .margin({ bottom: 7.5 })
      }
      .width('100%')
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.common_color_5'))
  }
}
