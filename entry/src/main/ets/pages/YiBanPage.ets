import { router } from '@kit.ArkUI';
import { TitleBar } from '../components/TitleBar';

class YiBanNewsInfo {
  newsId: string;
  title: string;
  subTitle: string;

  constructor(newsId: string, title: string, subTitle: string) {
    this.newsId = newsId;
    this.title = title;
    this.subTitle = subTitle;
  }
}

class YiBanSectionInfo {
  sectionTitle: string;
  sectionId: string;
  newsList: YiBanNewsInfo[];

  constructor(sectionId: string, sectionTitle: string, newsList: YiBanNewsInfo[]) {
    this.sectionId = sectionId;
    this.sectionTitle = sectionTitle;
    this.newsList = newsList;
  }
}

/**
 * 易班 Tab — 1:1 复刻 mobile_campus_fragment_yiban.xml（VLayout 模块流）：
 * LinearLayout vertical fill_parent
 *   - include toolbar_normal（45vp 白底 + 16fp 标题 + 0.5vp 分隔线）
 *   - MultiStateView(content) + PullToRefreshLayout + RecyclerView（fill_parent）
 * 模块流条目：
 *   - mobile_campus_item_yiban_title.xml：分组标题条，height=px_to_dip_76=38vp、
 *     paddingH 12vp(px24/2)，左侧 primary 色 4vp 竖条 + 14fp(px_to_sp_28) common_color_3 标题
 *   - mobile_campus_view_yiban_news.xml：易班新闻条目，minHeight=px_to_dip_88=44vp、
 *     imgNews 72vp(px144/2) centerCrop、tvTitle 14fp common_color_1、tvSubTitle 13fp(px_to_sp_26)
 *     common_color_3、底部分隔线 common_color_6
 * 详情页复用 YiMiaoMiaoDetailPage。内置示例数据。
 */
@Entry
@Component
struct YiBanPage {
  @State sectionList: YiBanSectionInfo[] = [
    new YiBanSectionInfo('s1', '易班头条', [
      new YiBanNewsInfo('y1', '易班新生开学季活动精彩回顾', '易班工作站 · 2026-11-16'),
      new YiBanNewsInfo('y2', '第十四届校园网络文化节启动', '校团委 · 2026-11-15'),
      new YiBanNewsInfo('y3', '易班优课大学生党史学习专题上线', '易班发展中心 · 2026-11-14')
    ]),
    new YiBanSectionInfo('s2', '校园快讯', [
      new YiBanNewsInfo('y4', '学校召开学风建设专题工作会议', '学生工作处 · 2026-11-13'),
      new YiBanNewsInfo('y5', '冬季长跑锻炼活动本周开始', '体育教学部 · 2026-11-12')
    ]),
    new YiBanSectionInfo('s3', '通知公告', [
      new YiBanNewsInfo('y6', '关于评选2026年度易班先进班级的通知', '易班发展中心 · 2026-11-11'),
      new YiBanNewsInfo('y7', '宿舍安全用电检查工作安排', '学生公寓中心 · 2026-11-10')
    ])
  ];

  /**
   * mobile_campus_item_yiban_title.xml — 分组标题条。
   * RelativeLayout：paddingH 12vp(px24/2)、height 38vp(px_to_dip_76/2)；
   * 左侧竖条 View 4vp primary 色 + 标题 14fp(px_to_sp_28) common_color_3、marginLeft 8vp(px16/2)。
   */
  @Builder
  yibanSectionTitle(section: YiBanSectionInfo) {
    Row() {
      Column()
        .width(4)
        .height(20)
        .backgroundColor($r('app.color.mobile_campus_primary_color'))
      Text(section.sectionTitle)
        .fontSize(14)
        .fontColor($r('app.color.common_color_3'))
        .margin({ left: 8 })
    }
    .width('100%')
    .height(38)
    .padding({ left: 12, right: 12 })
    .alignItems(VerticalAlign.Center)
  }

  /**
   * mobile_campus_view_yiban_news.xml — 易班新闻条目。
   * 白底 LinearLayout vertical、RelativeLayout minHeight 44vp；
   * imgNews 72vp、marginV 8dip=8vp、marginH 12vp(px24/2)、centerCrop；
   * tvTitle 14fp common_color_1 maxLines 1、tvSubTitle 13fp common_color_3 maxLines 1；
   * 底部分隔 View 1.0dip=0.5vp common_color_6。
   */
  @Builder
  yibanNewsRow(newsItem: YiBanNewsInfo) {
    Column() {
      Row() {
        Image($r('app.media.mobile_campus_main_new_default'))
          .width(72)
          .height(72)
          .objectFit(ImageFit.Cover)
          .margin({
            top: 8,
            bottom: 8,
            left: 12,
            right: 12
          })
        // 右侧信息列：gravity=center_vertical、tvTitle marginV 8vp、tvSubTitle marginBottom 8vp
        Column() {
          Text(newsItem.title)
            .fontSize(14)
            .fontColor($r('app.color.common_color_1'))
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .margin({ top: 8, bottom: 8, left: 12, right: 48 })
            .width('100%')
          Text(newsItem.subTitle)
            .fontSize(13)
            .fontColor($r('app.color.common_color_3'))
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .margin({ bottom: 8, left: 12, right: 48 })
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)
        .justifyContent(FlexAlign.Center)
        .height('100%')
      }
      .width('100%')
      .constraintSize({ minHeight: 44 })
      .alignItems(VerticalAlign.Center)
      .backgroundColor($r('app.color.white'))
      // 底部分隔 View：height=1.0dip=0.5vp、background=@color/common_color_6
      Divider()
        .color($r('app.color.common_color_6'))
        .strokeWidth(0.5)
        .width('100%')
    }
    .width('100%')
    .onClick(() => {
      router.pushUrl({ url: 'pages/YiMiaoMiaoDetailPage', params: { id: newsItem.newsId } });
    })
  }

  build() {
    // 根 LinearLayout vertical（fill_parent）
    Column() {
      // include toolbar_normal
      TitleBar({ title: '易班', showBack: true })
      // MultiStateView(content) + PullToRefreshLayout + RecyclerView
      List() {
        ForEach(this.sectionList, (section: YiBanSectionInfo) => {
          ListItem() {
            Column() {
              // 分组标题条
              this.yibanSectionTitle(section)
              // 分组内新闻条目流
              ForEach(section.newsList, (newsItem: YiBanNewsInfo) => {
                this.yibanNewsRow(newsItem)
              }, (newsItem: YiBanNewsInfo) => newsItem.newsId)
            }
            .width('100%')
          }
        }, (section: YiBanSectionInfo) => section.sectionId)
      }
      .width('100%')
      .layoutWeight(1)
      .backgroundColor($r('app.color.white'))
      .scrollBar(BarState.Off)
    }
    .width('100%')
    .height('100%')
  }
}

