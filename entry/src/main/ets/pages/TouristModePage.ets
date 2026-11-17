import { router } from '@kit.ArkUI';

class TouristNewsInfo {
  newsId: string;
  title: string;
  subTitle: string;
  publishTime: string;

  constructor(newsId: string, title: string, subTitle: string, publishTime: string) {
    this.newsId = newsId;
    this.title = title;
    this.subTitle = subTitle;
    this.publishTime = publishTime;
  }
}

/**
 * 游客模式主页 — 1:1 复刻 mobile_campus_fragment_tourist.xml（只读浏览版首页）：
 * LinearLayout vertical
 *   - RelativeLayout：background=@color/mobile_campus_primary_color、
 *     paddingLeft=px_to_dip_20=10vp、paddingRight=px_to_dip_32=16vp、height=px_to_dip_88=44vp
 *     - img_logo1：mobile_campus_main_head_logo，父左、垂直居中
 *     - cbMsn：消息开关（selector 背景），父右、垂直居中、默认选中
 *   - PullToRefreshLayout + MultiStateView(content)
 *     - FrameLayout：RecyclerView background=@color/common_color_6 + 右下回顶按钮(mobile_campus_top, margin 8dip)
 * 条目复刻 mobile_campus_view_main_news.xml：
 *   imgNews 72vp(px144/2) marginV 4dip marginH 12vp(px24/2)、
 *   tvTitle 14fp(px_to_sp_28) common_color_1、tvSubTitle/tvTime 13fp(px_to_sp_26) common_color_3、
 *   底部分隔线 0.5dip common_color_6。内置示例数据，游客只读浏览。
 */
@Entry
@Component
struct TouristModePage {
  @State msnChecked: boolean = true;
  @State touristNewsList: TouristNewsInfo[] = [
    new TouristNewsInfo('t1', '山东中医药大学2026年招生简章正式发布', '学校简介 · 招生计划', '2026-11-16'),
    new TouristNewsInfo('t2', '校园秋季运动会圆满落幕', '体育部 · 校园动态', '2026-11-15'),
    new TouristNewsInfo('t3', '图书馆开放时间调整通知', '图书馆 · 通知公告', '2026-11-14'),
    new TouristNewsInfo('t4', '大学生创新创业大赛报名开始', '教务处 · 竞赛信息', '2026-11-13'),
    new TouristNewsInfo('t5', '中医药文化科普周活动预告', '团委 · 校园文化', '2026-11-12')
  ];

  /**
   * mobile_campus_view_main_news.xml — 游客模式新闻条目（只读）。
   * 外层白底、分隔线贴底（1.0dip=0.5vp，common_color_6）。
   */
  @Builder
  touristNewsRow(item: TouristNewsInfo) {
    Row() {
      // imgNews：72vp(px_to_dip_144/2)、scaleType=centerCrop、marginV 8dip=8vp、marginH 12vp(px24/2)
      Image($r('app.media.mobile_campus_main_new_default'))
        .width(72)
        .height(72)
        .objectFit(ImageFit.Cover)
        .margin({ top: 8, bottom: 8,
          left: 12,
          right: 12
        })
      // 右侧信息列：LinearLayout vertical、gravity=center_vertical
      Column() {
        // tvTitle：14fp(px_to_sp_28)、common_color_1、maxLines=1、marginV 8vp(px16/2)、marginH 48vp(px96/2)
        Text(item.title)
          .fontSize(14)
          .fontColor($r('app.color.common_color_1'))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .margin({ top: 8, bottom: 8, left: 12, right: 48 })
          .width('100%')
        // tvSubTitle：13fp(px_to_sp_26)、common_color_3、maxLines=1、marginBottom 8vp
        Text(item.subTitle)
          .fontSize(13)
          .fontColor($r('app.color.common_color_3'))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .margin({ bottom: 8, left: 12, right: 48 })
          .width('100%')
        // tvTime：13fp(px_to_sp_26)、common_color_3、maxLines=1、marginBottom 8vp
        Text(item.publishTime)
          .fontSize(13)
          .fontColor($r('app.color.common_color_3'))
          .maxLines(1)
          .margin({ bottom: 8, left: 12, right: 48 })
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
      .justifyContent(FlexAlign.Center)
      .height(88)
    }
    .width('100%')
    .alignItems(VerticalAlign.Center)
    .backgroundColor($r('app.color.white'))
    .onClick(() => {
      router.pushUrl({ url: 'pages/NewsDetailPage', params: { id: item.newsId } });
    })
  }

  build() {
    // 根 LinearLayout vertical
    Column() {
      // RelativeLayout：primary 色、height 44vp、paddingL 10vp、paddingR 16vp
      Row() {
        // img_logo1：父左、垂直居中
        Image($r('app.media.mobile_campus_main_head_logo'))
          .height(26)
          .objectFit(ImageFit.Contain)
          .alignSelf(ItemAlign.Center)
        Blank()
          .layoutWeight(1)
        // cbMsn：父右、垂直居中、默认选中（selector 背景 → 圆角描边开关胶囊）
        Text('消息')
          .fontSize(12)
          .fontColor(this.msnChecked ? $r('app.color.mobile_campus_primary_color') : $r('app.color.white'))
          .padding({ left: 8, right: 8, top: 3, bottom: 3 })
          .borderRadius(13)
          .border({
            width: 1,
            color: $r('app.color.white')
          })
          .backgroundColor(this.msnChecked ? $r('app.color.white') : Color.Transparent)
          .onClick(() => {
            this.msnChecked = !this.msnChecked;
          })
      }
      .width('100%')
      .height(44)
      .padding({ left: 10, right: 16 })
      .backgroundColor($r('app.color.mobile_campus_primary_color'))

      // PullToRefreshLayout + MultiStateView(content) → RecyclerView common_color_6 背景
      List() {
        ForEach(this.touristNewsList, (item: TouristNewsInfo) => {
          ListItem() {
            Column() {
              this.touristNewsRow(item)
              // 条目底部分隔 View：1.0dip=0.5vp、common_color_6
              Divider()
                .color($r('app.color.common_color_6'))
                .strokeWidth(0.5)
                .width('100%')
            }
            .width('100%')
          }
        }, (item: TouristNewsInfo) => item.newsId)
      }
      .width('100%')
      .layoutWeight(1)
      .backgroundColor($r('app.color.common_color_6'))
      .scrollBar(BarState.Off)
    }
    .width('100%')
    .height('100%')
  }
}

