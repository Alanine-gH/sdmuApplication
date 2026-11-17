import { TitleBar } from '../components/TitleBar';

class ReceiptField {
  key: string = '';
  value: string = '';

  constructor(key: string, value: string) {
    this.key = key;
    this.value = value;
  }
}

@Entry
@Component
struct ReceiptAssistPage {
  private receiptName: string = '北京山软信息技术有限公司';
  private fields: ReceiptField[] = [
    new ReceiptField('类型', '增值税专用发票'),
    new ReceiptField('税号', '91110108MA01XK8L2Q'),
    new ReceiptField('单位地址', '北京市海淀区中关村大街1号科技大厦A座808'),
    new ReceiptField('电话号码', '010-88886666'),
    new ReceiptField('开户银行', '中国工商银行北京中关村支行'),
    new ReceiptField('银行账号', '0200 0012 3456 7890 1234')
  ];

  @Builder
  fieldRow(field: ReceiptField) {
    Row() {
      Text(field.key)
        .fontSize(16)
        .fontColor($r('app.color.mobile_campus_schedule_color2'))
      Text(field.value)
        .fontSize(16)
        .fontColor($r('app.color.common_color_1'))
        .margin({ left: 24 })
        .layoutWeight(1)
    }
    .width('100%')
    .alignItems(VerticalAlign.Top)
    .margin({ top: 6 })
  }

  build() {
    Column() {
      TitleBar({ title: '发票抬头' })
      Scroll() {
        Column() {
          Column() {
            Text('以下为您的常用开票信息，商家扫描下方二维码可快速获取发票抬头，也可长按复制发送给商家。')
              .fontSize(14)
              .fontColor($r('app.color.common_color_1'))
              .width('100%')
              .padding({ top: 10, bottom: 10 })
              .lineHeight(20)

            Text(this.receiptName)
              .fontSize(20)
              .fontColor($r('app.color.blue_default'))
              .margin({ top: 20 })

            ForEach(this.fields, (field: ReceiptField, index: number) => {
              this.fieldRow(field)
            }, (field: ReceiptField, index: number) => 'f_' + index + '_' + field.key)

            Divider()
              .color($r('app.color.common_color_36'))
              .strokeWidth(0.5)
              .width('100%')
              .margin({ top: 14 })

            Image($r('app.media.icon_share'))
              .width(150)
              .height(150)
              .margin({ top: 25 })

            Text('商家扫描二维码快速获取抬头信息')
              .fontSize(14)
              .fontColor($r('app.color.common_color_35'))
              .width('100%')
              .textAlign(TextAlign.Center)
              .margin({ top: 14, bottom: 14 })

            Divider()
              .color($r('app.color.common_color_36'))
              .strokeWidth(0.5)
              .width('100%')

            Text('开票须知')
              .fontSize(17)
              .fontColor($r('app.color.common_color_35'))
              .margin({ top: 10, bottom: 12 })
          }
          .width('100%')
          .padding({ left: 15, right: 15, bottom: 12 })
          .backgroundColor($r('app.color.white'))
          .borderRadius(4)
        }
        .width('100%')
        .padding({ left: 20, right: 20, top: 15 })
      }
      .width('100%')
      .layoutWeight(1)
      .scrollBar(BarState.Off)
      .align(Alignment.Top)
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.common_color_5'))
  }
}
