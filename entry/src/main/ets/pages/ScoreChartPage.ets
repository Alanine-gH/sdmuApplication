// 数据源：无服务器接口，页面数据为内置示例数据（离线演示用），未接 ApiService。
import { TitleBar } from '../components/TitleBar';

/**
 * 成绩图表页 — 1:1 复刻 score_view_combined_chart.xml + score_fragment_combined_chart.xml +
 * score_view_bar_chart.xml + score_view_table*.xml（原生复刻 CombinedChart/BarChart/TableView）
 *
 * score_view_combined_chart.xml：LinearLayout 白底：TabLayout 48.0dip 高 + ViewPager
 * score_fragment_combined_chart.xml：FrameLayout + CombinedChart（填满）
 * score_view_bar_chart.xml：LinearLayout 白底 + BarChart（填满）
 *
 * TableView（score_view_table.xml）：column_header_height=48.0dip、row_header_width=200.0dip；
 *   底部 tvScore"查看学生具体成绩" #1B68B7 padding 12dip、右箭头 arrow_right_blue_desk_widget
 * score_view_table_cell.xml：tvPass/tvFail 上下两格（weight 各1）
 * score_view_table_row_header.xml：tvCourseName（weight 6）+ 右侧及格/不及格两行（weight 2）
 * score_view_table_coner / column_header：角部与列表头"课程"，mobile_campus_score_shape_table_bg
 *   （白底 0.5dip divider_grey 描边）
 */
class ScoreChartItem {
  year: string;
  avgScore: number;
  passRate: number;

  constructor(year: string, avgScore: number, passRate: number) {
    this.year = year;
    this.avgScore = avgScore;
    this.passRate = passRate;
  }
}

class ScoreChartTableRow {
  courseName: string;
  passCount: string;
  failCount: string;

  constructor(courseName: string, passCount: string, failCount: string) {
    this.courseName = courseName;
    this.passCount = passCount;
    this.failCount = failCount;
  }
}

function buildChartItems(): ScoreChartItem[] {
  const items: ScoreChartItem[] = [];
  items.push(new ScoreChartItem('21-1', 78, 90));
  items.push(new ScoreChartItem('21-2', 82, 94));
  items.push(new ScoreChartItem('22-1', 76, 88));
  items.push(new ScoreChartItem('22-2', 85, 96));
  items.push(new ScoreChartItem('23-1', 80, 92));
  items.push(new ScoreChartItem('23-2', 88, 98));
  return items;
}

function buildTableRows(): ScoreChartTableRow[] {
  const rows: ScoreChartTableRow[] = [];
  rows.push(new ScoreChartTableRow('高等数学（下）', '32', '3'));
  rows.push(new ScoreChartTableRow('大学英语（四）', '33', '2'));
  rows.push(new ScoreChartTableRow('数据结构与算法', '30', '5'));
  rows.push(new ScoreChartTableRow('操作系统原理', '31', '4'));
  rows.push(new ScoreChartTableRow('概率论与数理统计', '28', '7'));
  return rows;
}

@Component
struct ScoreChartBarView {
  @Prop items: ScoreChartItem[] = [];
  @Prop showLine: boolean = false;

  build() {
    Column() {
      // CombinedChart / BarChart 原生复刻：Y 轴刻度 + 柱状 + 折线
      Row() {
        Column() {
          Text('100').fontSize(9).fontColor($r('app.color.common_color_3'))
          Text('75').fontSize(9).fontColor($r('app.color.common_color_3'))
          Text('50').fontSize(9).fontColor($r('app.color.common_color_3'))
          Text('25').fontSize(9).fontColor($r('app.color.common_color_3'))
          Text('0').fontSize(9).fontColor($r('app.color.common_color_3'))
        }
        .height('100%')
        .justifyContent(FlexAlign.SpaceBetween)
        .padding({ bottom: 20 })
        .margin({ left: 6, right: 4 })

        Column() {
          Row() {
            ForEach(this.items, (item: ScoreChartItem, index: number) => {
              Column() {
                Row() {
                  // 及格率柱（浅蓝）
                  Column()
                    .width(14)
                    .height(item.passRate * 0.9)
                    .backgroundColor('#7FC0F0')
                  // 平均分柱（深蓝）
                  Column()
                    .width(14)
                    .height(item.avgScore * 0.9)
                    .backgroundColor($r('app.color.mobile_campus_primary_color_default'))
                }
                .height('100%')
                .alignItems(VerticalAlign.Bottom)
                .justifyContent(FlexAlign.Center)

                if (this.showLine) {
                  // 折线数据点（CombinedChart line 数据）
                  Text(item.avgScore.toString())
                    .fontSize(8)
                    .fontColor($r('app.color.score_rank_red'))
                }
                Text(item.year)
                  .fontSize(9)
                  .fontColor($r('app.color.common_color_3'))
                  .margin({ top: 4 })
              }
              .layoutWeight(1)
              .height('100%')
              .alignItems(HorizontalAlign.Center)
            }, (item: ScoreChartItem, index: number) => 'bar_' + index + '_' + item.year)
          }
          .width('100%')
          .layoutWeight(1)
          .alignItems(VerticalAlign.Bottom)

          Divider()
            .color($r('app.color.common_color_5'))
            .strokeWidth(0.5)
        }
        .layoutWeight(1)
        .height('100%')
        .border({ width: { top: 0.5 }, color: $r('app.color.common_color_5') })
      }
      .layoutWeight(1)
      .width('100%')
      .padding({ top: 12, bottom: 8, right: 12 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.white'))
  }
}

@Component
struct ScoreChartTableView {
  @Prop rows: ScoreChartTableRow[] = [];

  build() {
    Column() {
      // TableView：column_header_height=48.0dip=48vp、row_header_width=200.0dip=100vp
      Scroll() {
        Column() {
          // 列表头行（column_header + coner）
          Row() {
            Text('课程')
              .fontSize(12)
              .fontColor($r('app.color.black'))
              .textAlign(TextAlign.Center)
              .width(100) // row_header_width 200.0dip=100vp
              .height(48)
              .backgroundColor('#FFFFFF')
              .border({ width: 0.5, color: $r('app.color.divider_grey') })
            Text('及格')
              .fontSize(12)
              .fontColor($r('app.color.black'))
              .textAlign(TextAlign.Center)
              .layoutWeight(1)
              .height(48)
              .backgroundColor('#FFFFFF')
              .border({ width: 0.5, color: $r('app.color.divider_grey') })
            Text('不及格')
              .fontSize(12)
              .fontColor($r('app.color.black'))
              .textAlign(TextAlign.Center)
              .layoutWeight(1)
              .height(48)
              .backgroundColor('#FFFFFF')
              .border({ width: 0.5, color: $r('app.color.divider_grey') })
          }
          .width('100%')

          ForEach(this.rows, (row: ScoreChartTableRow, index: number) => {
            Row() {
              // row_header：tvCourseName weight 6
              Text(row.courseName)
                .fontSize(12)
                .fontColor($r('app.color.black'))
                .textAlign(TextAlign.Center)
                .width(100)
                .height(48)
                .padding({ left: 2, right: 2 })
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
                .backgroundColor('#FFFFFF')
                .border({ width: 0.5, color: $r('app.color.divider_grey') })
              // cell：tvPass / tvFail 上下两格（weight 各 1）
              Column() {
                Text(row.passCount)
                  .fontSize(12)
                  .fontColor($r('app.color.black'))
                  .textAlign(TextAlign.Center)
                  .layoutWeight(1)
                  .width('100%')
                  .backgroundColor('#FFFFFF')
                  .border({ width: 0.5, color: $r('app.color.divider_grey') })
                Text(row.failCount)
                  .fontSize(12)
                  .fontColor($r('app.color.black'))
                  .textAlign(TextAlign.Center)
                  .layoutWeight(1)
                  .width('100%')
                  .backgroundColor('#FFFFFF')
                  .border({ width: 0.5, color: $r('app.color.divider_grey') })
              }
              .layoutWeight(1)
              .height(48)
            }
            .width('100%')
          }, (row: ScoreChartTableRow, index: number) => 'row_' + index + '_' + row.courseName)
        }
        .width('100%')
      }
      .width('100%')
      .scrollable(ScrollDirection.Horizontal)

      // tvScore："查看学生具体成绩" #1B68B7、padding 12dip、右侧蓝色箭头
      Row() {
        Text('查看学生具体成绩')
          .fontSize(14)
          .fontColor('#1B68B7')
          .layoutWeight(1)
        Image($r('app.media.arrow_right_blue_desk_widget'))
          .width(14)
          .height(14)
          .objectFit(ImageFit.Contain)
      }
      .width('100%')
      .padding(12)
      .alignItems(VerticalAlign.Center)
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.white'))
  }
}

@Entry
@Component
struct ScoreChartPage {
  @State currentTabIndex: number = 0;
  private chartItems: ScoreChartItem[] = buildChartItems();
  private tableRows: ScoreChartTableRow[] = buildTableRows();

  build() {
    Column() {
      TitleBar({ title: '成绩图表' })
      Divider()
        .color($r('app.color.common_color_5'))
        .strokeWidth(0.5)
        .width('100%')
      // score_view_combined_chart.xml：TabLayout 48.0dip 高
      Row() {
        Text('柱状图')
          .fontSize(14)
          .fontColor(this.currentTabIndex === 0
            ? $r('app.color.mobile_campus_primary_color_default')
            : $r('app.color.common_color_1'))
          .layoutWeight(1)
          .height(48) // TabLayout 48.0dip
          .textAlign(TextAlign.Center)
          .onClick(() => {
            this.currentTabIndex = 0;
          })
        Text('组合图')
          .fontSize(14)
          .fontColor(this.currentTabIndex === 1
            ? $r('app.color.mobile_campus_primary_color_default')
            : $r('app.color.common_color_1'))
          .layoutWeight(1)
          .height(48)
          .textAlign(TextAlign.Center)
          .onClick(() => {
            this.currentTabIndex = 1;
          })
        Text('表格')
          .fontSize(14)
          .fontColor(this.currentTabIndex === 2
            ? $r('app.color.mobile_campus_primary_color_default')
            : $r('app.color.common_color_1'))
          .layoutWeight(1)
          .height(48)
          .textAlign(TextAlign.Center)
          .onClick(() => {
            this.currentTabIndex = 2;
          })
      }
      .width('100%')
      .backgroundColor($r('app.color.white'))

      // viewPager 内容
      Stack() {
        if (this.currentTabIndex === 0) {
          // score_view_bar_chart.xml：BarChart
          ScoreChartBarView({ items: this.chartItems, showLine: false })
        } else if (this.currentTabIndex === 1) {
          // score_fragment_combined_chart.xml：CombinedChart（柱状 + 折线）
          ScoreChartBarView({ items: this.chartItems, showLine: true })
        } else {
          // score_view_table.xml：TableView
          ScoreChartTableView({ rows: this.tableRows })
        }
      }
      .width('100%')
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.main_bg'))
  }
}
