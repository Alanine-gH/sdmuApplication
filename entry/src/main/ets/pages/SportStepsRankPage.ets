import { router } from '@kit.ArkUI';
import { TitleBar } from '../components/TitleBar';

/**
 * 教师运动步数排行榜 — 源码级翻译（SportStepsRankingsActivity + SportStepsRankingsFragment +
 * SportStepsRankingsAdapter + item_child_sport_steps_rankings，[W28 final-b]）。
 *
 * 【布局】mobile_campus_activity_app_sport_steps_rankings：MToolBar("教师运动步数") +
 *   CoordinatorLayout/AppBarLayout(#7fc573)：
 *   - 280dip sport_steps_rankings_back1 头图；居中 168dip bubble 气泡，内"300"32sp bold #3a7df0 +
 *     "今日步数"16sp #3a7df0（XML 字面值，源码无赋值语句——开发期占位字面保真）；
 *     右上 ivSetting/ivHistory 44dip（settings→e.a.w0=/app/SportStepsSettingActivity，
 *     history→e.a.x0=/app/SportStepsHistoryActivity）；
 *   - rlLayout2 96dip back2 fitXY：两白块圆角8（16dip margin）"全校排名"14sp+"3"24sp bold #3a7df0 /
 *     "部门排名"14sp+"1"24sp bold #3a7df0（同为 XML 字面值）；
 *   - 白面板圆角上16："今日排行榜"17sp bold + "*此数据仅供参考"12sp #999 + MagicIndicator 45dip
 *     （tab 14sp 选中 #3a7df0/未选 #999，indicator 2dip 圆角 #3a7df0）；
 *   - ViewPager2 两个 Fragment：全校排行TOP10(type=1)/部门排行TOP10(type=2)。
 * 【数据】SportStepsRankingsFragment.K1() 源码字面硬编码（APK 开发期占位数据，非运行时接口）：
 *   type1 = 10 条×重复 4 组（常贝贝/贺婷/任秀丽/母久宁/董祥宾/胡晓琴/武俊梅/张学海/贺拥军/周银萍）；
 *   type2 = 网络信息技术中心 8 条（周银萍/陈蓉/龚啸/何东琴/罗思源/拉巴多吉/王跟成/张国梁）。
 *   保真复刻，非编造。
 * 【行】item_child_sport_steps_rankings：首行 vLine1 gone；行 paddingH15 padV12：
 *   50dip 排名列（前3 ivMedal gold/silver/bronze 32dip；>3 tvRankings 18sp bold #d5dde5）+
 *   0.5dip 竖线 mr20 + 名称16sp 黑 + 学院14sp #999 mt4 + 步数"N步"18sp #3a7df0 +
 *   llPraise（tvPraiseNum 12sp #3a7df0 + 15dip 赞/未赞图标 mt1）+ vLine2（末行 mb15）。
 *   点赞切换：isPraise 反转，praiseNum +(赞)/-1(取消，0 不下减)。
 */
class RankRow {
  name: string;
  college: string;
  steps: number;
  praiseNum: number;
  praised: boolean;

  constructor(name: string, college: string, steps: number, praiseNum: number, praised: boolean) {
    this.name = name;
    this.college = college;
    this.steps = steps;
    this.praiseNum = praiseNum;
    this.praised = praised;
  }
}

@Entry
@Component
struct SportStepsRankPage {
  @State tab: number = 0;
  @State schoolRows: RankRow[] = [];
  @State deptRows: RankRow[] = [];

  aboutToAppear(): void {
    this.schoolRows = SportStepsRankPage.buildSchoolRows();
    this.deptRows = SportStepsRankPage.buildDeptRows();
  }

  /** 源码 K1() type=1：10 条×4 组字面量（40 行） */
  private static buildSchoolRows(): RankRow[] {
    const base: RankRow[] = [
      new RankRow('常贝贝', '民族研究院', 24530, 6, false),
      new RankRow('贺婷', '民族研究院', 22286, 3, false),
      new RankRow('任秀丽', '文学院', 20822, 5, false),
      new RankRow('母久宁', '医学院（附属医院）', 20325, 0, false),
      new RankRow('董祥宾', '财经学院', 20265, 1, false),
      new RankRow('胡晓琴', '法学院', 18622, 3, false),
      new RankRow('武俊梅', '马克思主义学院', 18605, 1, false),
      new RankRow('张学海', '文学院', 17440, 1, false),
      new RankRow('贺拥军', '科研处', 16875, 4, false),
      new RankRow('周银萍', '网络信息技术中心', 15552, 2, false)
    ];
    const rows: RankRow[] = [];
    for (let i = 0; i < 4; i++) {
      for (const one of base) {
        rows.push(new RankRow(one.name, one.college, one.steps, one.praiseNum, false));
      }
    }
    return rows;
  }

  /** 源码 K1() type=2：8 条字面量 */
  private static buildDeptRows(): RankRow[] {
    return [
      new RankRow('周银萍', '网络信息技术中心', 15552, 2, false),
      new RankRow('陈蓉', '网络信息技术中心', 15104, 2, false),
      new RankRow('龚啸', '网络信息技术中心', 14822, 1, false),
      new RankRow('何东琴', '网络信息技术中心', 14710, 2, false),
      new RankRow('罗思源', '网络信息技术中心', 14636, 1, false),
      new RankRow('拉巴多吉', '网络信息技术中心', 14384, 0, false),
      new RankRow('王跟成', '网络信息技术中心', 14370, 0, false),
      new RankRow('张国梁', '网络信息技术中心', 14180, 1, false)
    ];
  }

  private currentRows(): RankRow[] {
    return this.tab === 0 ? this.schoolRows : this.deptRows;
  }

  /** 源码 a 类 OnItemChildClick：点赞切换（isPraise 反转，praiseNum ±1，0 不下减） */
  private togglePraise(row: RankRow): void {
    if (row.praised) {
      row.praised = false;
      row.praiseNum = row.praiseNum !== 0 ? row.praiseNum - 1 : 0;
    } else {
      row.praised = true;
      row.praiseNum = row.praiseNum + 1;
    }
    this.schoolRows = this.schoolRows.slice();
    this.deptRows = this.deptRows.slice();
  }

  private medalOf(index: number): Resource | null {
    if (index === 0) {
      return $r('app.media.sport_steps_rankings_gold');
    }
    if (index === 1) {
      return $r('app.media.sport_steps_rankings_silver');
    }
    if (index === 2) {
      return $r('app.media.sport_steps_rankings_bronze');
    }
    return null;
  }

  @Builder
  headerBlock() {
    Column() {
      Stack({ alignContent: Alignment.TopStart }) {
        Image($r('app.media.sport_steps_rankings_back1'))
          .width('100%')
          .height(280)
          .objectFit(ImageFit.Cover)

        Row() {
          Blank()
          Stack({ alignContent: Alignment.Center }) {
            Image($r('app.media.sport_steps_rankings_bubble'))
              .width(84)
              .height(84)
              .objectFit(ImageFit.Cover)
            Column() {
              Text('300').fontSize(32).fontWeight(FontWeight.Bold).fontColor('#3A7DF0').maxLines(1)
              Text('今日步数').fontSize(16).fontColor('#3A7DF0').maxLines(1)
            }
            .alignItems(HorizontalAlign.Center)
          }
          .width(84)
          .height(84)
          Blank()
        }
        .width('100%')
        .margin({ top: 8 })

        Row() {
          Blank()
          Image($r('app.media.sport_steps_rankings_setting'))
            .width(22)
            .height(22)
            .objectFit(ImageFit.Cover)
            .margin({ right: 2.5 })
            .onClick(() => {
              router.pushUrl({ url: 'pages/SportStepsSettingPage' });
            })
          Image($r('app.media.sport_steps_rankings_history'))
            .width(22)
            .height(22)
            .objectFit(ImageFit.Cover)
            .onClick(() => {
              router.pushUrl({ url: 'pages/SportStepsHistoryPage' });
            })
        }
        .width('100%')
        .padding({ left: 4, top: 7.5, right: 4 })

        Column() {
          Blank()
          Stack() {
            Image($r('app.media.sport_steps_rankings_back2'))
              .width('100%')
              .height('100%')
              .objectFit(ImageFit.Fill)
            Row() {
              this.rankCard('全校排名', '3')
              Row().width(7.5)
              this.rankCard('部门排名', '1')
            }
            .width('100%')
            .height(30)
            .padding({ left: 7.5, right: 7.5 })
            .margin({ top: 9 })
          }
          .width('100%')
          .height(48)
        }
        .width('100%')
        .height(280)
      }
      .width('100%')
      .height(280)

      Column() {
        Row() {
          Text('今日排行榜').fontSize(17).fontWeight(FontWeight.Bold).fontColor(Color.Black)
          Blank()
          Text('*此数据仅供参考').fontSize(12).fontColor($r('app.color.common_color_3'))
        }
        .width('100%')
        .padding({ left: 7.5, right: 7.5 })
        .margin({ top: 8 })

        Row() {
          this.tabItem('全校排行TOP10', 0)
          this.tabItem('部门排行TOP10', 1)
        }
        .width('100%')
        .height(22.5)
        .justifyContent(FlexAlign.Center)
        .padding({ bottom: 6 })
      }
      .width('100%')
      .backgroundColor(Color.White)
      .borderRadius({ topLeft: 8, topRight: 8 })
    }
    .width('100%')
    .backgroundColor('#7FC573')
  }

  @Builder
  rankCard(label: string, value: string) {
    Row() {
      Text(label).fontSize(14).fontColor(Color.Black).maxLines(1)
      Text(value)
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .fontColor('#3A7DF0')
        .textAlign(TextAlign.End)
        .layoutWeight(1)
        .maxLines(1)
    }
    .layoutWeight(1)
    .height('100%')
    .padding({ left: 7.5, right: 7.5 })
    .backgroundColor(Color.White)
    .borderRadius(8)
  }

  @Builder
  tabItem(label: string, index: number) {
    Column() {
      Text(label)
        .fontSize(14)
        .fontColor(this.tab === index ? '#3A7DF0' : '#999999')
        .padding({ left: 12, right: 12 })
      Column()
        .width(20)
        .height(2)
        .borderRadius(2)
        .backgroundColor('#3A7DF0')
        .margin({ top: 2 })
        .visibility(this.tab === index ? Visibility.Visible : Visibility.Hidden)
    }
    .onClick(() => {
      this.tab = index;
    })
  }

  @Builder
  rankRow(row: RankRow, index: number) {
    Column() {
      if (index === 0) {
        Divider().color($r('app.color.common_color_5')).strokeWidth(0.25)
          .margin({ left: 7.5, right: 7.5 })
          .visibility(Visibility.Hidden)
      }
      Row() {
        Stack({ alignContent: Alignment.Center }) {
          if (index < 3) {
            Image(this.medalOf(index) as Resource).width(16).height(16)
          } else {
            Text(String(index + 1))
              .fontSize(18)
              .fontWeight(FontWeight.Bold)
              .fontColor('#D5DDE5')
          }
        }
        .width(25)

        Divider().vertical(true).height(24).strokeWidth(0.25).color($r('app.color.common_color_5'))
          .margin({ right: 10 })

        Column() {
          Text(row.name).fontSize(16).fontColor(Color.Black).maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
          Text(row.college).fontSize(14).fontColor($r('app.color.common_color_3')).maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .margin({ top: 2 })
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)
        .padding({ right: 5 })

        Text(String(row.steps) + '步').fontSize(18).fontColor('#3A7DF0')

        Column() {
          Text(String(row.praiseNum)).fontSize(12).fontColor('#3A7DF0')
          Image(row.praised ? $r('app.media.sport_steps_rankings_praise')
            : $r('app.media.sport_steps_rankings_un_praise'))
            .width(7.5)
            .height(7.5)
            .margin({ top: 0.5 })
        }
        .padding({ left: 7.5, right: 7.5 })
        .justifyContent(FlexAlign.Center)
        .onClick(() => {
          this.togglePraise(row);
        })
      }
      .width('100%')
      .padding({ left: 7.5, top: 6, bottom: 6 })
      .alignItems(VerticalAlign.Center)

      Divider()
        .color($r('app.color.common_color_5'))
        .strokeWidth(0.25)
        .margin({ left: 7.5, right: 7.5, bottom: index === this.currentRows().length - 1 ? 7.5 : 0 })
    }
    .width('100%')
  }

  build() {
    Column() {
      TitleBar({ title: '教师运动步数', showBack: true })
      List() {
        ListItem() {
          this.headerBlock()
        }
        ForEach(this.currentRows(), (row: RankRow, index: number) => {
          ListItem() {
            this.rankRow(row, index)
          }
        }, (row: RankRow, index: number) => 'rank_' + String(this.tab) + '_' + String(index))
      }
      .width('100%')
      .layoutWeight(1)
      .scrollBar(BarState.Off)
      .backgroundColor(Color.White)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(Color.White)
  }
}
