import { router } from '@kit.ArkUI';
import { TitleBar } from '../components/TitleBar';

/**
 * 排行榜条目模型 — 服务不可达时使用内置示例数据。
 */
export class SportRankItem {
  rank: number;
  name: string;
  college: string;
  steps: number;
  praiseNum: number;
  praised: boolean;

  constructor(rank: number, name: string, college: string, steps: number, praiseNum: number, praised: boolean) {
    this.rank = rank;
    this.name = name;
    this.college = college;
    this.steps = steps;
    this.praiseNum = praiseNum;
    this.praised = praised;
  }
}

/** 全校排行榜示例数据 */
function buildSchoolRanks(): SportRankItem[] {
  const list: SportRankItem[] = [
    new SportRankItem(1, '张伟', '体育教学部', 18246, 32, true),
    new SportRankItem(2, '李娜', '外国语学院', 16733, 28, false),
    new SportRankItem(3, '王强', '计算机学院', 15210, 24, true),
    new SportRankItem(4, '刘洋', '机械工程学院', 14305, 18, false),
    new SportRankItem(5, '陈静', '经济管理学院', 13672, 15, false),
    new SportRankItem(6, '杨帆', '土木工程学院', 12890, 12, true),
    new SportRankItem(7, '赵敏', '医学院', 12118, 9, false),
    new SportRankItem(8, '孙丽', '文学院', 11436, 8, false)
  ];
  return list;
}

/** 部门排行榜示例数据 */
function buildDeptRanks(): SportRankItem[] {
  const list: SportRankItem[] = [
    new SportRankItem(1, '王强', '计算机学院', 15210, 24, true),
    new SportRankItem(2, '刘洋', '计算机学院', 14305, 18, false),
    new SportRankItem(3, '张伟', '计算机学院', 11840, 16, false),
    new SportRankItem(4, '周杰', '计算机学院', 10422, 11, false),
    new SportRankItem(5, '吴磊', '计算机学院', 9876, 7, true),
    new SportRankItem(6, '郑爽', '计算机学院', 9210, 5, false),
    new SportRankItem(7, '冯超', '计算机学院', 8654, 4, false),
    new SportRankItem(8, '褚燕', '计算机学院', 7980, 3, false)
  ];
  return list;
}

/**
 * 教师运动步数排名页 — 按反编译布局 1:1 复刻 mobile_campus_activity_app_sport_steps_rankings.xml：
 *   LinearLayout vertical
 *   - MToolBar（标题“教师运动步数”）
 *   - CoordinatorLayout：
 *     - AppBarLayout（背景 #7FC573）：
 *       - CollapsingToolbarLayout：
 *         - back1 图片 height=280dip=280vp centerCrop
 *         - RelativeLayout：
 *           - rlLayout1 168x168vp 居中 marginTop=16vp：bubble 气泡图 + 今日步数（32sp→16fp 粗体 #3A7DF0、16sp→8fp）
 *           - 右上 setting/history 两个 44x44vp 按钮
 *           - rlLayout2 height=96vp：back2 拉伸图 + 两张白底圆角8vp卡片（全校排名/部门排名，24sp→12fp 粗体）
 *       - 白底顶部圆角16vp区域：标题“今日排行榜”17sp 粗体 + “*此数据仅供参考”12sp + MagicIndicator 45vp
 *     - ViewPager2：全校/部门两个排行榜列表（item_child_sport_steps_rankings）
 */
@Entry
@Component
struct SportStepsRankPage {
  @State currentTab: number = 0;
  @State schoolRanks: SportRankItem[] = buildSchoolRanks();
  @State deptRanks: SportRankItem[] = buildDeptRanks();

  /**
   * item_child_sport_steps_rankings.xml — 排行榜条目。
   * 行 padding left=15/top=12/bottom=12；排名列 50vp；分隔线 0.5vp marginRight=20vp。
   */
  @Builder
  rankItem(item: SportRankItem) {
    Column() {
      Row() {
        // 排名列 RelativeLayout width=50dip：奖牌图 32x32 或排名数字 18sp 粗体 #D5DDE5
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

        // 姓名/学院列
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

        // 步数 18sp #3A7DF0
        Text(item.steps.toString())
          .fontSize(18)
          .fontColor($r('app.color.sport_steps_blue'))

        // 点赞列 paddingLeft/Right=15
        Column() {
          Text(item.praiseNum.toString())
            .fontSize(12)
            .fontColor($r('app.color.sport_steps_blue'))
          Image(item.praised ? $r('app.media.sport_steps_rankings_praise') : $r('app.media.sport_steps_rankings_un_praise'))
            .width(15)
            .height(15)
            .margin({ top: 1 })
            .objectFit(ImageFit.Contain)
        }
        .justifyContent(FlexAlign.Center)
        .padding({ left: 15, right: 15 })
        .height('100%')
        .onClick(() => {
          item.praised = !item.praised;
          item.praiseNum = item.praised ? item.praiseNum + 1 : item.praiseNum - 1;
        })
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
   * 排行榜列表 — ViewPager2 页内容。
   */
  @Builder
  rankListPage(ranks: SportRankItem[]) {
    List() {
      ForEach(ranks, (item: SportRankItem) => {
        ListItem() {
          this.rankItem(item)
        }
      }, (item: SportRankItem) => item.rank.toString() + '_' + item.name)
    }
    .width('100%')
    .height('100%')
    .scrollBar(BarState.Off)
  }

  build() {
    Column() {
      TitleBar({ title: '教师运动步数' })
      // CoordinatorLayout / AppBarLayout（背景 #7FC573）
      Stack({ alignContent: Alignment.TopStart }) {
        Column() {
          // back1 顶部背景图 height=280dip=280vp
          Image($r('app.media.sport_steps_rankings_back1'))
            .width('100%')
            .height(280)
            .objectFit(ImageFit.Cover)
          // 白底顶部圆角16vp区域：rlLayout2 下半部分为列表头
          Column() {
            Row() {
              Text('今日排行榜')
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

        // 顶部悬浮内容（rlLayout1 气泡 + 右上按钮 + rlLayout2 排名卡片）
        Column() {
          Row() {
            Blank()
            // 右上 setting/history 44x44vp
            Row() {
              Image($r('app.media.sport_steps_rankings_setting'))
                .width(44)
                .height(44)
                .objectFit(ImageFit.Cover)
                .margin({ right: 5 })
                .onClick(() => {
                  router.pushUrl({ url: 'pages/SportStepsSettingPage' });
                })
              Image($r('app.media.sport_steps_rankings_history'))
                .width(44)
                .height(44)
                .objectFit(ImageFit.Cover)
                .onClick(() => {
                  router.pushUrl({ url: 'pages/SportStepsHistoryPage' });
                })
            }
            .alignItems(VerticalAlign.Center)
            .padding({ left: 8, right: 8, top: 15 })
          }
          .width('100%')

          // rlLayout1 168x168vp 居中 marginTop=16：bubble + 今日步数
          Stack({ alignContent: Alignment.Center }) {
            Image($r('app.media.sport_steps_rankings_bubble'))
              .width(168)
              .height(168)
              .objectFit(ImageFit.Cover)
            Column() {
              Text('300')
                .fontSize(32)
                .fontWeight(FontWeight.Bold)
                .fontColor($r('app.color.sport_steps_blue'))
                .maxLines(1)
              Text('今日步数')
                .fontSize(16)
                .fontColor($r('app.color.sport_steps_blue'))
                .maxLines(1)
            }
          }
          .width(168)
          .height(168)
          .margin({ top: 16 })

          // rlLayout2 height=96vp：back2 拉伸 + 两张白底圆角8vp卡片（marginLeft/Right=15 marginTop=18 height=60）
          Stack({ alignContent: Alignment.TopStart }) {
            Image($r('app.media.sport_steps_rankings_back2'))
              .width('100%')
              .height(96)
              .objectFit(ImageFit.Fill)
            Row() {
              Row() {
                Text('全校排名')
                  .fontSize(14)
                  .fontColor($r('app.color.black'))
                  .maxLines(1)
                Text('3')
                  .fontSize(24)
                  .fontWeight(FontWeight.Bold)
                  .fontColor($r('app.color.sport_steps_blue'))
                  .textAlign(TextAlign.End)
                  .maxLines(1)
                  .layoutWeight(1)
              }
              .alignItems(VerticalAlign.Center)
              .backgroundColor($r('app.color.white'))
              .borderRadius(8)
              .padding({ left: 15, right: 15 })
              .height(60)
              .layoutWeight(1)

              Blank().width(15)

              Row() {
                Text('部门排名')
                  .fontSize(14)
                  .fontColor($r('app.color.black'))
                  .maxLines(1)
                Text('1')
                  .fontSize(24)
                  .fontWeight(FontWeight.Bold)
                  .fontColor($r('app.color.sport_steps_blue'))
                  .textAlign(TextAlign.End)
                  .maxLines(1)
                  .layoutWeight(1)
              }
              .alignItems(VerticalAlign.Center)
              .backgroundColor($r('app.color.white'))
              .borderRadius(8)
              .padding({ left: 15, right: 15 })
              .height(60)
              .layoutWeight(1)
            }
            .width('100%')
            .height(60)
            .margin({ left: 15, right: 15, top: 18 })
          }
          .width('100%')
          .height(96)
        }
        .width('100%')
        .padding({ top: 0 })
      }
      .width('100%')
      .layoutWeight(1)

      // ViewPager2 内容
      if (this.currentTab === 0) {
        Column() {
          this.rankListPage(this.schoolRanks)
        }
        .width('100%')
        .layoutWeight(1)
      } else {
        Column() {
          this.rankListPage(this.deptRanks)
        }
        .width('100%')
        .layoutWeight(1)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.sport_steps_header_green'))
  }
}
