import { TitleBar } from '../components/TitleBar';

/**
 * 绩点排行页 — 复刻 GradeReportActvity（gradeReport，H5排行榜原生复刻）
 * 源入口：student_report/ReportFactory "rank/gradeReport"
 * 结构：toolbar（标题「绩点排行」）+ 排行榜列表：
 *   - 我的排名卡（高亮#1B68B7）
 *   - 排行列表（名次徽章/姓名/学院/绩点），前三名金银铜色
 *   - 隐藏真实姓名提示（hide_personal_info_tips）
 */
class RankEntry {
  rank: number;
  name: string;
  college: string;
  score: string;

  constructor(rank: number, name: string, college: string, score: string) {
    this.rank = rank;
    this.name = name;
    this.college = college;
    this.score = score;
  }
}

@Entry
@Component
struct GradeRankPage {
  @State myRank: RankEntry = new RankEntry(38, '孔硕', '信息工程学院', '3.42');
  @State ranks: RankEntry[] = [
    new RankEntry(1, '王同学', '信息工程学院', '4.35'),
    new RankRank2(),
    new RankRank3(),
    new RankEntry(4, '赵同学', '会计学院', '3.98'),
    new RankEntry(5, '刘同学', '工商管理学院', '3.95'),
    new RankEntry(6, '陈同学', '信息工程学院', '3.91'),
    new RankEntry(7, '杨同学', '人文学院', '3.87'),
    new RankEntry(8, '黄同学', '金融学院', '3.84'),
    new RankEntry(9, '周同学', '会计学院', '3.80'),
    new RankEntry(10, '吴同学', '信息工程学院', '3.76')
  ];

  @Builder
  rankRow(item: RankEntry, highlight: boolean) {
    Row() {
      Text(item.rank === 1 ? '1' : item.rank === 2 ? '2' : item.rank === 3 ? '3' : item.rank.toString())
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .fontColor(item.rank === 1 ? '#FFAA00' : item.rank === 2 ? '#C0C0C0' : item.rank === 3 ? '#CD7F32' :
          (highlight ? $r('app.color.ybg_blue') : $r('app.color.common_color_3')))
        .width(36)
        .textAlign(TextAlign.Center)
      Column() {
        Text(item.name)
          .fontSize(15)
          .fontColor(highlight ? $r('app.color.ybg_blue') : $r('app.color.common_color_1'))
          .fontWeight(highlight ? FontWeight.Bold : FontWeight.Normal)
        Text(item.college)
          .fontSize(12)
          .fontColor($r('app.color.common_color_3'))
          .margin({ top: 2 })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
      Text(item.score)
        .fontSize(17)
        .fontWeight(FontWeight.Bold)
        .fontColor(highlight ? $r('app.color.ybg_blue') : $r('app.color.common_color_1'))
    }
    .width('100%')
    .height(56)
    .padding({ left: 12, right: 15 })
    .alignItems(VerticalAlign.Center)
    .backgroundColor(highlight ? '#F0F8FF' : $r('app.color.white'))
  }

  build() {
    Column() {
      TitleBar({ title: '绩点排行', showBack: true })

      Scroll() {
        Column() {
          // 隐藏姓名提示（hide_personal_info_tips）
          Text('是否在排行榜中隐藏自己的真实姓名')
            .fontSize(12)
            .fontColor($r('app.color.common_color_3'))
            .padding({ left: 15, right: 15, top: 10, bottom: 10 })
            .width('100%')

          // 我的排名卡（高亮）
          this.rankRow(this.myRank, true)

          // 排行列表
          ForEach(this.ranks, (item: RankEntry) => {
            if (item.rank !== 38) {
              this.rankRow(item, false)
            }
          }, (item: RankEntry) => 'rank_' + item.rank)

          Blank()
            .height(20)
        }
        .width('100%')
      }
      .width('100%')
      .layoutWeight(1)
      .scrollBar(BarState.Off)
      .backgroundColor($r('app.color.common_color_6'))
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.common_color_6'))
  }
}

class RankRank2 extends RankEntry {
  constructor() {
    super(2, '李同学', '人文学院', '4.21');
  }
}

class RankRank3 extends RankEntry {
  constructor() {
    super(3, '张同学', '金融学院', '4.15');
  }
}
