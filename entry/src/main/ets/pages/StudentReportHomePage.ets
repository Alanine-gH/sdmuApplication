import { router } from '@kit.ArkUI';
import { TitleBar } from '../components/TitleBar';

/**
 * 学生报表主页 — 1:1 复刻 fragment_indexreport.xml
 * 结构：FrameLayout（common_color_6 底 ReportScrollView）
 *   - toolbar_normal_alpha 标题栏
 *   - 报表卡片列表（ReportScrollView 内容）：
 *     学业报告 / 早餐打卡 / 一卡通消费 / 图书借阅 / 绩点排行
 */
interface ReportEntry {
  name: string;
  desc: string;
  iconColor: string;
  pagePath: string;
}

@Entry
@Component
struct StudentReportHomePage {
  @State reportEntries: ReportEntry[] = [
    new ReportEntryItem('学业报告', '查看学业成绩与绩点分析', '#3267B1', 'pages/StudyReportDetailPage'),
    new ReportEntryItem('早餐打卡', '个人打卡记录与全校排名', '#57C06B', 'pages/BreakfastPersonalPage'),
    new ReportEntryItem('一卡通消费', '校园卡消费流水统计', '#FF8900', 'pages/CardConsumeReportPage'),
    new ReportEntryItem('图书借阅', '图书馆借阅历史统计', '#1B68B7', 'pages/BookBorrowReportPage'),
    new ReportEntryItem('绩点排行', '全校绩点排行榜单', '#18B4ED', 'pages/GradeRankPage')
  ] as ReportEntry[];

  build() {
    Column() {
      // include toolbar_normal_alpha
      TitleBar({ title: '学生报表', showBack: true })

      // ReportScrollView：报表卡片列表
      Scroll() {
        Column() {
          ForEach(this.reportEntries, (entry: ReportEntry) => {
            Row() {
              // 报表图标块
              Text(entry.name.substring(0, 1))
                .fontSize(18)
                .fontWeight(FontWeight.Bold)
                .fontColor($r('app.color.white'))
                .width(44)
                .height(44)
                .borderRadius(22)
                .backgroundColor(entry.iconColor)
                .textAlign(TextAlign.Center)
              Column() {
                Text(entry.name)
                  .fontSize(16)
                  .fontColor($r('app.color.common_color_1'))
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
                Text(entry.desc)
                  .fontSize(13)
                  .fontColor($r('app.color.common_color_3'))
                  .margin({ top: 4 })
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
              }
              .layoutWeight(1)
              .margin({ left: 12 })
              .alignItems(HorizontalAlign.Start)

              Image($r('app.media.arrow_right2'))
                .width(8)
                .height(14)
            }
            .width('100%')
            .padding({ left: 15, right: 15 })
            .height(76)
            .alignItems(VerticalAlign.Center)
            .backgroundColor($r('app.color.white'))
            .onClick(() => {
              // pagePath 已含 'pages/' 前缀（见 reportEntries 定义），不可再拼 'pages/'
              router.pushUrl({ url: this.pagePathOf(entry) });
            })

            Divider()
              .color($r('app.color.common_color_5'))
              .strokeWidth(0.5)
              .width('100%')
          }, (entry: ReportEntry) => 'reportentry' + entry.name)
        }
        .width('100%')
      }
      .width('100%')
      .layoutWeight(1)
      .backgroundColor($r('app.color.common_color_6'))
      .scrollBar(BarState.Off)
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.common_color_6'))
  }

  private pagePathOf(entry: ReportEntry): string {
    return entry.pagePath;
  }
}

class ReportEntryItem implements ReportEntry {
  name: string;
  desc: string;
  iconColor: string;
  pagePath: string;

  constructor(name: string, desc: string, iconColor: string, pagePath: string) {
    this.name = name;
    this.desc = desc;
    this.iconColor = iconColor;
    this.pagePath = pagePath;
  }
}

