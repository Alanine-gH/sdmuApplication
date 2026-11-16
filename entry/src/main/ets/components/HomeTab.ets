import { router } from '@kit.ArkUI';
import { ApiService } from '../network/ApiService';
import { NewsItem } from '../model/NewsModel';

/**
 * 首页新闻区块 — 按反编译布局 1:1 复刻：
 *   - mobile_campus_main_banner.xml（顶部 Banner 轮播，AutoScrollViewPager → Swiper）
 *   - mobile_campus_view_main_center_news.xml + mobile_campus_view_main_news_item.xml（“动态”模块）
 *   - mobile_campus_view_main_news.xml（首页新闻条目）
 * 滚动容器背景对应 mobile_campus_fragment_main.xml ExpandableListView 的 @color/mobile_campus_bg_color。
 */
@Component
export struct HomeTab {
  @State newsList: NewsItem[] = [];

  aboutToAppear(): void {
    ApiService.getNewsList()
      .then((response) => {
        this.newsList = response.data;
      })
      .catch(() => {
        this.newsList = [];
      });
  }

  /**
   * mobile_campus_main_banner.xml — Banner 单页。
   * tvTitle：textStyle=bold、background=#b2ffffff、marginLeft=8.0dip=8vp、singleLine、alignParentBottom
   * （XML 未指定 textSize/textColor，取默认黑 14fp 近似）。
   */
  @Builder
  bannerCell(item: NewsItem) {
    Stack({ alignContent: Alignment.BottomStart }) {
      // AutoScrollViewPager 页面图片：fill_parent / fill_parent，scaleType=centerCrop
      Image($r('app.media.mobile_campus_main_new_default'))
        .width('100%')
        .height('100%')
        .objectFit(ImageFit.Cover)
      Text(item.title)
        .fontSize(14)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.black'))
        .backgroundColor($r('app.color.mobile_campus_banner_title_bg'))
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .margin({ left: 8 })
    }
    .width('100%')
    .height('100%')
    .onClick(() => {
      router.pushUrl({ url: 'pages/NewsDetailPage', params: { id: item.id } });
    })
  }

  /**
   * mobile_campus_view_main_center_news.xml — “动态”模块。
   * 外层 LinearLayout 无背景，实际位于首页红色头部区，取 @color/mobile_campus_primary_color。
   */
  @Builder
  centerNewsSection() {
    Column() {
      // 标题行 LinearLayout horizontal：paddingLeft/Right=12.0dip=12vp，layout_marginTop=20.0dip=20vp
      Row() {
        // BLView：宽 3.0dip=3vp、高 fill_parent(随标题行拉伸)、margin top/bottom=2.0dip=2vp、
        // bl_corners_radius=30.0dip=30vp、bl_solid_color=@color/white
        Column()
          .width(3)
          .alignSelf(ItemAlign.Stretch)
          .margin({ top: 2, bottom: 2 })
          .borderRadius(30)
          .backgroundColor($r('app.color.white'))
        // tvName：textSize=20.0sp=20fp、@color/white、ellipsize=end、maxLines=1、
        // paddingLeft/Right=8.0dip=8vp、text="动态"
        Text($r('app.string.news_center_title'))
          .fontSize(20)
          .fontColor($r('app.color.white'))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .padding({ left: 8, right: 8 })
      }
      .width('100%')
      .padding({ left: 12, right: 12 })
      .margin({ top: 20 })
      .alignItems(VerticalAlign.Center)

      // BLLinearLayout：orientation=vertical、margin left/right=12.0dip=12vp、top=10.0dip=10vp、
      // bl_corners_radius=8.0dip=8vp、bl_solid_color=@color/white
      Column() {
        // mRecyclerView：paddingLeft/Right=5.0dip=5vp、layout_marginTop=5.0dip=5vp，LinearLayoutManager 纵向列表
        Column() {
          ForEach(this.newsList, (item: NewsItem) => {
            // mobile_campus_view_main_news_item.xml — 单条文字条目
            Column() {
              // tvContent：textSize=15.0sp=15fp、@color/black、ellipsize=end、maxLines=1、
              // padding 左右=12.0dip=12vp、上下=10.0dip=10vp
              Text(item.title)
                .fontSize(15)
                .fontColor($r('app.color.black'))
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
                .padding({ left: 12, right: 12, top: 10, bottom: 10 })
                .width('100%')
                .onClick(() => {
                  router.pushUrl({ url: 'pages/NewsDetailPage', params: { id: item.id } });
                })
              // vLine：background=#ff7deeae、height=0.5dip=0.5vp、margin 左右=10.0dip=10vp
              Divider()
                .color($r('app.color.mobile_campus_center_news_green'))
                .strokeWidth(0.5)
                .margin({ left: 10, right: 10 })
            }
            .width('100%')
          }, (item: NewsItem) => 'center_' + item.id)
        }
        .width('100%')
        .padding({ left: 5, right: 5 })
        .margin({ top: 5 })

        // tvMore：textSize=14.0sp=14fp、textColor=#ff7deeae、gravity=center、
        // padding 上下=10.0dip=10vp、text="查看更多"
        Text($r('app.string.view_more'))
          .fontSize(14)
          .fontColor($r('app.color.mobile_campus_center_news_green'))
          .textAlign(TextAlign.Center)
          .padding({ top: 10, bottom: 10 })
          .width('100%')
          .onClick(() => {
            router.pushUrl({ url: 'pages/NewsPage' });
          })
      }
      .width('100%')
      .borderRadius(8)
      .backgroundColor($r('app.color.white'))
      .margin({ left: 12, right: 12, top: 10 })
    }
    .width('100%')
    .backgroundColor($r('app.color.mobile_campus_primary_color'))
  }

  /**
   * mobile_campus_view_main_news.xml — 首页新闻条目。
   * 外层 LinearLayout vertical、background=@color/white。
   */
  @Builder
  newsRow(item: NewsItem) {
    Column() {
      // RelativeLayout：imgNews 左、文字区右（toEndOf=imgNews、alignParentEnd=true）
      Row() {
        // imgNews：144px/2=72vp 见方、margin top/bottom=8.0dip=8vp、
        // marginStart/End=px_to_dip_24/2=12vp、src=@mipmap/mobile_campus_main_new_default、scaleType=centerCrop
        Image($r('app.media.mobile_campus_main_new_default'))
          .width(72)
          .height(72)
          .margin({ top: 8, bottom: 8, left: 12, right: 12 })
          .objectFit(ImageFit.Cover)
        // 右侧 RelativeLayout 内 LinearLayout vertical
        Column() {
          // tvTitle：px_to_sp_28/2=14fp、@color/common_color_1、ellipsize=end、maxLines=1、
          // margin top/bottom=px_to_dip_16/2=8vp、marginStart=12vp、marginEnd=px_to_dip_96/2=48vp
          Text(item.title)
            .fontSize(14)
            .fontColor($r('app.color.common_color_1'))
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .margin({ top: 8, bottom: 8, left: 12, right: 48 })
          // tvSubTitle：px_to_sp_26/2=13fp、@color/common_color_3、maxLines=1、marginBottom=8vp
          Text(item.summary)
            .fontSize(13)
            .fontColor($r('app.color.common_color_3'))
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .margin({ bottom: 8, left: 12, right: 48 })
          // tvTime：px_to_sp_26/2=13fp、@color/common_color_3、maxLines=1、marginBottom=8vp
          Text(item.publishTime)
            .fontSize(13)
            .fontColor($r('app.color.common_color_3'))
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .margin({ bottom: 8, left: 12, right: 48 })
          // 分隔 View：alignParentBottom、background=@color/common_color_6、height=1.0dip=1vp、fill_parent
          Divider()
            .color($r('app.color.common_color_6'))
            .strokeWidth(1)
            .width('100%')
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)
    }
    .width('100%')
    .backgroundColor($r('app.color.white'))
    .onClick(() => {
      router.pushUrl({ url: 'pages/NewsDetailPage', params: { id: item.id } });
    })
  }

  build() {
    // 首页滚动容器（ExpandableListView：background=@color/mobile_campus_bg_color）
    List() {
      // Banner 区块：RelativeLayout main_head_banner、height=px_to_dip_260/2=130vp、
      // background=@color/mobile_campus_primary_color
      ListItem() {
        Stack({ alignContent: Alignment.BottomStart }) {
          if (this.newsList.length > 0) {
            // AutoScrollViewPager → Swiper 自动轮播（indicator visibility=gone，不显示指示器）
            Swiper() {
              ForEach(this.newsList, (item: NewsItem) => {
                this.bannerCell(item)
              }, (item: NewsItem) => 'banner_' + item.id)
            }
            .width('100%')
            .height('100%')
            .autoPlay(true)
            .interval(4000)
            .indicator(false)
          } else {
            // 数据未加载时显示默认图（main_head_image：scaleType=centerCrop）
            Image($r('app.media.mobile_campus_main_new_default'))
              .width('100%')
              .height('100%')
              .objectFit(ImageFit.Cover)
          }
        }
        .width('100%')
        .height(130)
        .backgroundColor($r('app.color.mobile_campus_primary_color'))
      }

      // “动态”中部模块（mobile_campus_view_main_center_news.xml）
      ListItem() {
        this.centerNewsSection()
      }

      // 首页新闻列表（mobile_campus_view_main_news.xml 条目）
      ForEach(this.newsList, (item: NewsItem) => {
        ListItem() {
          this.newsRow(item)
        }
      }, (item: NewsItem) => item.id)
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.mobile_campus_bg_color'))
    .scrollBar(BarState.Off)
  }
}
