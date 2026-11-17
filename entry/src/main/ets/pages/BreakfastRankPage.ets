import { TitleBar } from '../components/TitleBar';

/**
 * 早餐打卡全校排名 — 复刻 student_report_layout_main.xml（breakfastReport/TotalRankActivity）
 * WebView 壳按 H5 结构原生复刻：周期切换（周/月/学期）+ 我的排名卡 + 全校排名列表
 */
interface RankRow {
  rankNum: number;
  name: string;
  dept: string;
  checkCount: number;
}

@Entry
@Component
struct BreakfastRankPage {
  @State currentPeriod: string = '本月';
  @State periods: string[] = ['本周', '本月', '本学期'];
  @State rankRows: RankRow[] = [
    new BreakfastRankData(1, '张明宇', '计算机学院', 22),
    new BreakfastRankData(2, '李思涵', '外国语学院', 21),
    new BreakfastRankData(3, '王志强', '机械工程学院', 20),
    new BreakfastRankData(4, '刘雨桐', '经济管理学院', 19),
    new BreakfastRankData(5, '陈嘉豪', '土木工程学院', 19),
    new BreakfastRankData(6, '赵欣怡', '艺术学院', 18),
    new BreakfastRankData(7, '孙博文', '理学院', 18),
    new BreakfastRankData(8, '周子墨', '计算机学院', 17),
    new BreakfastRankData(9, '吴雅婷', '文学院', 16),
    new BreakfastRankData(10, '郑凯文', '法学院', 15)
  ] as RankRow[];
  @State myRank: number = 6;
  @State myCount: number = 18;

  build() {
    Column() {
      TitleBar({ title: '早餐打卡排名', showBack: true })

      Column() {
        // 周期切换
        Row() {
          ForEach(this.periods, (period: string) => {
            Text(period)
              .fontSize(14)
              .fontColor(period === this.currentPeriod ?
                $r('app.color.white') : $r('app.color.common_color_2'))
              .backgroundColor(period === this.currentPeriod ?
                $r('app.color.mobile_campus_primary_color') : $r('app.color.white'))
              .borderRadius(14)
              .padding({ left: 16, right: 16, top: 6, bottom: 6 })
              .onClick(() => {
                this.currentPeriod = period;
              })
          }, (period: string) => 'rankperiod' + period)
        }
        .width('100%')
        .height(44)
        .padding({ left: 15 })
        .alignItems(VerticalAlign.Center)

        // 我的排名卡
        Row() {
          Column() {
            Text(this.myRank + '')
              .fontSize(24)
              .fontWeight(FontWeight.Bold)
              .fontColor($r('app.color.mobile_campus_primary_color'))
            Text('我的排名')
              .fontSize(12)
              .fontColor($r('app.color.common_color_3'))
              .margin({ top: 4 })
          }
          .layoutWeight(1)
          .alignItems(HorizontalAlign.Center)

          Column() {
            Text(this.myCount + '次')
              .fontSize(24)
              .fontWeight(FontWeight.Bold)
              .fontColor($r('app.color.mobile_campus_primary_color'))
            Text('打卡次数')
              .fontSize(12)
              .fontColor($r('app.color.common_color_3'))
              .margin({ top: 4 })
          }
          .layoutWeight(1)
          .alignItems(HorizontalAlign.Center)
        }
        .width('100%')
        .padding({ top: 16, bottom: 16 })
        .backgroundColor($r('app.color.white'))
        .borderRadius(8)

        // 全校排名列表
        Column() {
          ForEach(this.rankRows, (row: RankRow, index: number) => {
            Row() {
              Text(this.rankBadge(row.rankNum))
                .fontSize(14)
                .fontWeight(FontWeight.Bold)
                .fontColor(this.rankColor(row.rankNum))
                .width(30)
                .textAlign(TextAlign.Center)
              Text(row.name)
                .fontSize(15)
                .fontColor($r('app.color.common_color_1'))
                .margin({ left: 10 })
              Text(row.dept)
                .fontSize(13)
                .fontColor($r('app.color.common_color_3'))
                .margin({ left: 10 })
                .layoutWeight(1)
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
              Text(row.checkCount + '次')
                .fontSize(14)
                .fontColor($r('app.color.common_color_2'))
            }
            .width('100%')
            .height(50)
            .padding({ left: 15, right: 15 })
            .alignItems(VerticalAlign.Center)
            .onClick(() => {
              this.myRank = row.rankNum;
              this.myCount = row.checkCount;
            })

            Divider()
              .color($r('app.color.common_color_5'))
              .strokeWidth(0.5)
              .width('100%')
              .margin({ left: 55 })
          }, (row: RankRow) => 'rankrow' + row.rankNum)
        }
        .width('100%')
        .backgroundColor($r('app.color.white'))
        .borderRadius(8)
        .margin({ top: 12 })
      }
      .width('100%')
      .padding(12)
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.common_color_6'))
  }

  private rankBadge(rankNum: number): string {
    return rankNum <= 3 ? 'Top' + rankNum : '' + rankNum;
  }

  private rankColor(rankNum: number): ResourceColor {
    if (rankNum === 1) {
      return $r('app.color.report_rank_gold');
    }
    if (rankNum === 2) {
      return $r('app.color.report_rank_silver');
    }
    if (rankNum === 3) {
      return $r('app.color.report_rank_bronze');
    }
    return $r('app.color.common_color_3');
  }
}

class BreakfastRankData implements RankRow {
  rankNum: number;
  name: string;
  dept: string;
  checkCount: number;

  constructor(rankNum: number, name: string, dept: string, checkCount: number) {
    this.rankNum = rankNum;
    this.name = name;
    this.dept = dept;
    this.checkCount = checkCount;
  }
}
