import { router } from '@kit.ArkUI';
import { TitleBar } from '../components/TitleBar';

/**
 * 巡检记录 — 1:1 复刻自：
 *   inspection_activity_record.xml（添加记录按钮 + 记录列表）
 *   inspection_item_record.xml（记录行：第x周）
 */

class InspectionRecordItem {
  week: string;

  constructor(week: string) {
    this.week = week;
  }
}

@Entry
@Component
struct InspectionRecordPage {
  @State recordList: InspectionRecordItem[] = [
    new InspectionRecordItem('第16周'),
    new InspectionRecordItem('第15周'),
    new InspectionRecordItem('第14周'),
    new InspectionRecordItem('第13周')
  ];

  build() {
    Column() {
      // toolbar_normal
      TitleBar({ title: '巡检记录', showBack: true })

      // common_color_6 分隔条
      Divider()
        .color($r('app.color.common_color_6'))
        .strokeWidth(10)
        .width('100%')

      // 添加记录 inspection_shape_add
      Row() {
        Image($r('app.media.inspection_add'))
          .width(24)
          .height(24)
          .objectFit(ImageFit.Contain)
        Text('添加记录')
          .fontSize(14)
          .fontColor($r('app.color.common_color_3'))
          .margin({ left: 13 })
      }
      .width('100%')
      .height(62)
      .padding(12)
      .alignItems(VerticalAlign.Center)
      .backgroundColor($r('app.color.common_color_5'))
      .borderRadius(4)
      .margin({ left: 15, right: 15, top: 15 })
      .onClick(() => {
        router.pushUrl({ url: 'pages/InspectionNewPage' });
      })

      // MultiStateView content：lvRecord 记录列表
      Scroll() {
        Column() {
          ForEach(this.recordList, (record: InspectionRecordItem) => {
            Row() {
              Text(record.week)
                .fontSize(14)
                .fontColor($r('app.color.black'))
                .height('100%')
                .textAlign(TextAlign.Center)
            }
            .width('100%')
            .height(62)
            .padding({ top: 8, bottom: 8, left: 12, right: 15 })
            .alignItems(VerticalAlign.Center)
            .backgroundColor($r('app.color.white'))
            .borderRadius(4)
            .onClick(() => {
              router.pushUrl({ url: 'pages/InspectionPage' });
            })
          }, (record: InspectionRecordItem) => record.week)
        }
        .width('100%')
      }
      .width('100%')
      .layoutWeight(1)
      .align(Alignment.TopStart)
      .scrollBar(BarState.Off)
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.common_color_6'))
  }
}
