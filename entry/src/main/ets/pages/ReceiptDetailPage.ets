import { router } from '@kit.ArkUI';
import { TitleBar } from '../components/TitleBar';

class DetailField {
  key: string = '';
  value: string = '';

  constructor(key: string, value: string) {
    this.key = key;
    this.value = value;
  }
}

@Entry
@Component
struct ReceiptDetailPage {
  private title: string = 'BX20260512001';
  private fields1: DetailField[] = [
    new DetailField('预约单号', 'YY202605120001'),
    new DetailField('业务编号', 'YB20260512001'),
    new DetailField('业务类型', '日常报销'),
    new DetailField('报销金额', '¥1,250.00')
  ];
  private fields2: DetailField[] = [
    new DetailField('报销人员', '张老师'),
    new DetailField('报销日期', '2026-05-12'),
    new DetailField('报销状态', '已通过'),
    new DetailField('部门编号', 'D0010'),
    new DetailField('项目编号', 'XM2026A01')
  ];
  private summary: string = '横向科研项目差旅及材料费报销，含交通费、住宿费及会议注册费。';

  @Builder
  fieldRow(field: DetailField) {
    Row() {
      Text(field.key)
        .fontSize(14)
        .fontColor($r('app.color.common_color_1'))
      Text(field.value)
        .fontSize(14)
        .fontColor($r('app.color.common_color_3'))
        .margin({ left: 12 })
    }
    .width('100%')
    .alignItems(VerticalAlign.Center)
  }

  build() {
    Column() {
      TitleBar({ title: '报销单详情' })
      Scroll() {
        Column() {
          Column() {
            Text(this.title)
              .fontSize(18.5)
              .fontColor($r('app.color.blue_default'))
              .width('100%')
              .height(59)
              .textAlign(TextAlign.Center)

            Column() {
              ForEach(this.fields1, (field: DetailField, index: number) => {
                this.fieldRow(field)
              }, (field: DetailField, index: number) => 'f1_' + index + '_' + field.key)
            }
            .width('100%')
            .padding({ left: 18, right: 18, top: 21, bottom: 21 })

            Divider()
              .color($r('app.color.common_color_6'))
              .strokeWidth(0.5)
              .width('100%')

            Column() {
              ForEach(this.fields2, (field: DetailField, index: number) => {
                Row() {
                  Text(field.key)
                    .fontSize(14)
                    .fontColor($r('app.color.common_color_1'))
                  Text(field.value)
                    .fontSize(14)
                    .fontColor($r('app.color.common_color_3'))
                    .margin({ left: 12 })
                }
                .width('100%')
                .alignItems(VerticalAlign.Center)
                .margin({ top: index > 0 ? 12 : 0 })
              }, (field: DetailField, index: number) => 'f2_' + index + '_' + field.key)
            }
            .width('100%')
            .padding({ left: 18, right: 18, top: 21, bottom: 21 })

            Divider()
              .color($r('app.color.common_color_6'))
              .strokeWidth(0.5)
              .width('100%')

            Column() {
              Row() {
                Text('摘         要')
                  .fontSize(14)
                  .fontColor($r('app.color.common_color_1'))
                Text(this.summary)
                  .fontSize(14)
                  .fontColor($r('app.color.common_color_3'))
                  .margin({ left: 12 })
                  .layoutWeight(1)
              }
              .width('100%')
              .alignItems(VerticalAlign.Top)

              Text('确定')
                .fontSize(16)
                .fontColor($r('app.color.white'))
                .width(160)
                .height(40)
                .textAlign(TextAlign.Center)
                .backgroundColor($r('app.color.blue_default'))
                .margin({ top: 24 })
                .onClick(() => {
                  router.back();
                })
            }
            .width('100%')
            .padding({ left: 18, right: 18, top: 21, bottom: 21 })
          }
          .width('100%')
          .backgroundColor($r('app.color.white'))
          .borderRadius(4)
          .padding({ bottom: 4 })

          Image($r('app.media.mobile_campus_reimburse_ticketfoot'))
            .width('100%')
            .objectFit(ImageFit.Cover)
        }
        .width('100%')
      }
      .width('100%')
      .layoutWeight(1)
      .scrollBar(BarState.Off)
      .align(Alignment.Top)
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.main_bg'))
  }
}
