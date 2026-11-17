import { TitleBar } from '../components/TitleBar';

/**
 * 历史记录条目模型 — 服务不可达时使用内置示例数据。
 */
export class SportHistoryItem {
  date: string;
  steps: number;
  schoolRank: number;
  deptRank: number;

  constructor(date: string, steps: number, schoolRank: number, deptRank: number) {
    this.date = date;
    this.steps = steps;
    this.schoolRank = schoolRank;
    this.deptRank = deptRank;
  }
}

/** 历史记录示例数据 */
function buildHistoryItems(): SportHistoryItem[] {
  const list: SportHistoryItem[] = [
    new SportHistoryItem('2022-09-25', 12680, 5, 2),
    new SportHistoryItem('2022-09-24', 9342, 12, 4),
    new SportHistoryItem('2022-09-23', 8765, 15, 5),
    new SportHistoryItem('2022-09-22', 15320, 3, 1),
    new SportHistoryItem('2022-09-21', 300, 3, 1),
    new SportHistoryItem('2022-09-20', 11208, 8, 3),
    new SportHistoryItem('2022-09-19', 6980, 22, 8),
    new SportHistoryItem('2022-09-18', 14012, 4, 2)
  ];
  return list;
}

/** 排行榜条目模型 */
export class SportDetailRankItem {
  rank: number;
  name: string;
  college: string;
  steps: number;

  constructor(rank: number, name: string, college: string, steps: number) {
    this.rank = rank;
    this.name = name;
    this.college = college;
    this.steps = steps;
  }
}

/** 某日排行榜示例数据 */
function buildDetailRanks(): SportDetailRankItem[] {
  const list: SportDetailRankItem[] = [
    new SportDetailRankItem(1, '张伟', '体育教学部', 18246),
    new SportDetailRankItem(2, '李娜', '外国语学院', 16733),
    new SportDetailRankItem(3, '王强', '计算机学院', 15210),
    new SportDetailRankItem(4, '刘洋', '机械工程学院', 14305),
    new SportDetailRankItem(5, '陈静', '经济管理学院', 13672),
    new SportDetailRankItem(6, '杨帆', '土木工程学院', 12890),
    new SportDetailRankItem(7, '赵敏', '医学院', 12118),
    new SportDetailRankItem(8, '孙丽', '文学院', 11436)
  ];
  return list;
}

/**
 * 步数历史页 — 按反编译布局 1:1 复刻 mobile_campus_activity_app_sport_steps_history.xml：
 *   LinearLayout vertical
 *   - MToolBar（标题“历史记录”）
 *   - SmartRefreshLayout + RecyclerView（paddingTop/Bottom=4vp）：
 *     item_sport_steps_history：白底圆角8vp #F8F8F8 卡片 margin 15/6，
 *     日期 16sp 黑色 padding 20/18、右侧“查看” 16sp explainColor marginRight=13、箭头 marginRight=24
 * 点击条目进入详情视图（SportStepsHistoryDetailActivity → mobile_campus_activity_app_sport_steps_detail.xml）：
 *   back3 头图 124vp + 三列统计（24sp 白色粗体 + 14sp 白色）+ 白底圆角16vp 列表头“2022年09月21日排行榜”
 */
@Entry
@Component
struct SportStepsHistoryPage {
  @State historyList: SportHistoryItem[] = buildHistoryItems();
  @State showDetail: boolean = false;
  @State currentTab: number = 0;
  @State detailRanks: SportDetailRankItem[] = buildDetailRanks();
  @State detailDate: string = '';

  /**
   * item_sport_steps_history.xml — 历史记录条目。
   */
  @Builder
  historyItem(item: SportHistoryItem) {
    Row() {
      Text(item.date)
        .fontSize(16)
        .fontColor($r('app.color.black'))
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .padding({ left: 20, right: 20, top: 18, bottom: 18 })
        .layoutWeight(1)
      Text('查看')
        .fontSize(16)
        .fontColor($r('app.color.explain_color'))
        .margin({ right: 13 })
      Image($r('app.media.icon_arrow_right_gray'))
        .width(16)
        .height(16)
        .margin({ right: 24 })
        .objectFit(ImageFit.Contain)
    }
    .width('100%')
    .backgroundColor($r('app.color.sport_history_item_bg'))
    .borderRadius(8)
    .alignItems(VerticalAlign.Center)
    .margin({ left: 15, right: 15, top: 6, bottom: 6 })
    .onClick(() => {
      this.detailDate = item.date;
      this.currentTab = 0;
      this.showDetail = true;
    })
  }

  /**
   * item_child_sport_steps_rankings.xml — 排行榜条目（详情页复用，无点赞列）。
   */
  @Builder
  rankItem(item: SportDetailRankItem) {
    Column() {
      Row() {
        Stack({ alignContent: Alignment.Center }) {
          if (item.rank <= 3) {
            Image(item.rank === 1 ? $r('app.media.sport_steps_rankings_gold') :
              (item.rank === 2 ? $r('app.media.sport_steps_rankings_silver') : $r('app.media.sport_steps_rankings_bronze')))
              .width(32)
              .height(32)
              .objectFit(ImageFit.Contain)
          } else {
            Text(item.rank.toString())
              .fontSize(18)
              .fontWeight(FontWeight.Bold)
              .fontColor($r('app.color.sport_rank_number'))
          }
        }
        .width(50)
        .height('100%')

        Divider()
          .vertical(true)
          .color($r('app.color.common_color_5'))
          .strokeWidth(0.5)
          .height('100%')
          .margin({ right: 20 })

        Column() {
          Text(item.name)
            .fontSize(16)
            .fontColor($r('app.color.black'))
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
          Text(item.college)
            .fontSize(14)
            .fontColor($r('app.color.explain_color'))
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .margin({ top: 4 })
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
        .padding({ right: 10 })

        Text(item.steps.toString())
          .fontSize(18)
          .fontColor($r('app.color.sport_steps_blue'))
      }
      .width('100%')
      .padding({ left: 15, top: 12, bottom: 12 })
      .alignItems(VerticalAlign.Center)

      Divider()
        .color($r('app.color.common_color_5'))
        .strokeWidth(0.5)
        .margin({ left: 15, right: 15 })
    }
    .width('100%')
  }

  /**
   * mobile_campus_activity_app_sport_steps_detail.xml — 历史详情视图。
   */
  @Builder
  detailView() {
    Column() {
      TitleBar({ title: '历史记录' })
      Stack({ alignContent: Alignment.TopStart }) {
        Column() {
          // back3 头图 height=124dip=124vp（AppBarLayout 背景 #BDEBED）
          Image($r('app.media.sport_steps_rankings_back3'))
            .width('100%')
            .height(124)
            .objectFit(ImageFit.Cover)
          // 白底顶部圆角16vp区域
          Column() {
            Row() {
              Text(this.detailDate.replace('-', '年').replace('-', '月') + '日排行榜')
                .fontSize(17)
                .fontWeight(FontWeight.Bold)
                .fontColor($r('app.color.black'))
                .layoutWeight(1)
              Text('*此数据仅供参考')
                .fontSize(12)
                .fontColor($r('app.color.explain_color'))
            }
            .width('100%')
            .padding({ left: 15, right: 15 })
            .margin({ top: 16 })

            // MagicIndicator Tab 45vp paddingBottom=12
            Row() {
              Text('全校排名')
                .fontSize(16)
                .fontColor(this.currentTab === 0 ? $r('app.color.sport_steps_blue') : $r('app.color.common_color_1'))
                .fontWeight(this.currentTab === 0 ? FontWeight.Bold : FontWeight.Normal)
                .layoutWeight(1)
                .textAlign(TextAlign.Center)
                .onClick(() => {
                  this.currentTab = 0;
                })
              Text('部门排名')
                .fontSize(16)
                .fontColor(this.currentTab === 1 ? $r('app.color.sport_steps_blue') : $r('app.color.common_color_1'))
                .fontWeight(this.currentTab === 1 ? FontWeight.Bold : FontWeight.Normal)
                .layoutWeight(1)
                .textAlign(TextAlign.Center)
                .onClick(() => {
                  this.currentTab = 1;
                })
            }
            .width('100%')
            .height(45)
            .padding({ bottom: 12 })
          }
          .width('100%')
          .layoutWeight(1)
          .backgroundColor($r('app.color.white'))
          .borderRadius({ topLeft: 16, topRight: 16 })
        }
        .width('100%')
        .height('100%')

        // 头图上的三列统计：24sp 白色粗体 + 14sp 白色 marginTop=5
        Row() {
          Column() {
            Text(this.historyList.find((h: SportHistoryItem): boolean => h.date === this.detailDate)?.steps.toString() ?? '0')
              .fontSize(24)
              .fontWeight(FontWeight.Bold)
              .fontColor($r('app.color.white'))
              .maxLines(1)
            Text('运动步数')
              .fontSize(14)
              .fontColor($r('app.color.white'))
              .maxLines(1)
              .margin({ top: 5 })
          }
          .justifyContent(FlexAlign.Center)
          .layoutWeight(1)
          .height('100%')

          Column() {
            Text(this.historyList.find((h: SportHistoryItem): boolean => h.date === this.detailDate)?.schoolRank.toString() ?? '0')
              .fontSize(24)
              .fontWeight(FontWeight.Bold)
              .fontColor($r('app.color.white'))
              .maxLines(1)
            Text('全校排名')
              .fontSize(14)
              .fontColor($r('app.color.white'))
              .maxLines(1)
              .margin({ top: 5 })
          }
          .justifyContent(FlexAlign.Center)
          .layoutWeight(1)
          .height('100%')

          Column() {
            Text(this.historyList.find((h: SportHistoryItem): boolean => h.date === this.detailDate)?.deptRank.toString() ?? '0')
              .fontSize(24)
              .fontWeight(FontWeight.Bold)
              .fontColor($r('app.color.white'))
              .maxLines(1)
            Text('部门排名')
              .fontSize(14)
              .fontColor($r('app.color.white'))
              .maxLines(1)
              .margin({ top: 5 })
          }
          .justifyContent(FlexAlign.Center)
          .layoutWeight(1)
          .height('100%')
        }
        .width('100%')
        .height(124)
      }
      .width('100%')
      .layoutWeight(1)

      // ViewPager2 内容
      List() {
        ForEach(this.detailRanks, (item: SportDetailRankItem) => {
          ListItem() {
            this.rankItem(item)
          }
        }, (item: SportDetailRankItem) => item.rank.toString() + '_' + item.name)
      }
      .width('100%')
      .layoutWeight(1)
      .scrollBar(BarState.Off)
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.sport_steps_header_blue'))
  }

  build() {
    Column() {
      if (this.showDetail) {
        this.detailView()
      } else {
        TitleBar({ title: '历史记录' })
        // SmartRefreshLayout + RecyclerView（paddingTop/Bottom=4）
        List() {
          ForEach(this.historyList, (item: SportHistoryItem) => {
            ListItem() {
              this.historyItem(item)
            }
          }, (item: SportHistoryItem) => item.date)
        }
        .width('100%')
        .layoutWeight(1)
        .padding({ top: 4, bottom: 4 })
        .scrollBar(BarState.Off)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.main_bg'))
  }
}
