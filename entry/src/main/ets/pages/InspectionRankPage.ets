import { TitleBar } from '../components/TitleBar';

/**
 * 巡检排名 — 1:1 复刻自：
 *   new_inspection_activity_recordlist.xml（toolbar + common_color_6 分隔条 + 列表）
 *   排名行参照 inspection_item_record.xml 样式（白色卡片 + 左标题）
 *   注：源工程 NewInspectionRankListActivity 未保留专属布局 xml，
 *       按 recordlist 通用列表结构 + 星级评分视觉复刻。
 */

class InspectionRankItem {
  rank: number;
  dormName: string;
  score: string;

  constructor(rank: number, dormName: string, score: string) {
    this.rank = rank;
    this.dormName = dormName;
    this.score = score;
  }
}

@Entry
@Component
struct InspectionRankPage {
  @State rankList: InspectionRankItem[] = [
    new InspectionRankItem(1, '302室', '五星'),
    new InspectionRankItem(2, '305室', '四星'),
    new InspectionRankItem(3, '303室', '四星'),
    new InspectionRankItem(4, '301室', '三星'),
    new InspectionRankItem(5, '304室', '三星'),
    new InspectionRankItem(6, '306室', '二星')
  ];

  build() {
    Column() {
      // toolbar_normal
      TitleBar({ title: '巡检排名', showBack: true })

      // common_color_6 分隔条
      Divider()
        .color($r('app.color.common_color_6'))
        .strokeWidth(10)
        .width('100%')

      // 列表
      Scroll() {
        Column() {
          ForEach(this.rankList, (item: InspectionRankItem) => {
            Row() {
              Text(`${item.rank}`)
                .fontSize(14)
                .fontColor(item.rank <= 3 ? $r('app.color.mobile_campus_meeting_must_attend_text') : $r('app.color.common_color_3'))
                .width(24)
                .textAlign(TextAlign.Center)
              Text(item.dormName)
                .fontSize(14)
                .fontColor($r('app.color.black'))
                .layoutWeight(1)
                .margin({ left: 8 })
              Text(item.score)
                .fontSize(14)
                .fontColor($r('app.color.common_color_7'))
            }
            .width('100%')
            .height(62)
            .padding({ top: 8, bottom: 8, left: 12, right: 15 })
            .alignItems(VerticalAlign.Center)
            .backgroundColor($r('app.color.white'))
            .borderRadius(4)
          }, (item: InspectionRankItem) => `${item.rank}_${item.dormName}`)
        }
        .width('100%')
      }
      .width('100%')
      .layoutWeight(1)
      .align(Alignment.TopStart)
      .scrollBar(BarState.Off)
      .backgroundColor($r('app.color.common_color_6'))
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.common_color_6'))
  }
}
