import { router } from '@kit.ArkUI';
import { ApiService } from '../network/ApiService';
import { NewsItem } from '../model/NewsModel';
import { TitleBar } from '../components/TitleBar';
import { EmptyView } from '../components/EmptyView';
import { LoadingView } from '../components/LoadingView';

/**
 * 新闻列表页 — 按反编译布局 1:1 复刻 mobile_campus_activity_news.xml：
 *   LinearLayout vertical（fill_parent）
 *   - include toolbar_normal（标题由菜单名下发，取“新闻公告”）
 *   - mRecyclerView：fill_parent、LinearLayoutManager 纵向列表
 *   条目布局 mobile_campus_news_list_item.xml。该 XML 无 Banner，轮播见首页 HomeTab。
 */
@Entry
@Component
struct NewsPage {
  @State newsList: NewsItem[] = [];
  @State isLoading: boolean = true;

  aboutToAppear(): void {
    ApiService.getNewsList()
      .then((response) => {
        this.newsList = response.data;
        this.isLoading = false;
      })
      .catch(() => {
        this.newsList = [];
        this.isLoading = false;
      });
  }

  /**
   * mobile_campus_news_list_item.xml — 列表条目。
   * 外层 LinearLayout vertical：background=@color/white、padding=10.0dip=10vp。
   */
  @Builder
  newsListItem(item: NewsItem) {
    Column() {
      // tvTitle：textSize=16.0sp=16fp、textColor=#ff000000、ellipsize=end、maxLines=1
      Text(item.title)
        .fontSize(16)
        .fontColor($r('app.color.black'))
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .width('100%')
      // 信息行 LinearLayout horizontal：gravity=center_vertical、layout_marginTop=5.0dip=5vp
      Row() {
        // tvFrom：textSize=14.0sp=14fp、textColor=#ff999999、ellipsize=end、maxLines=1、
        // paddingRight=10.0dip=10vp、layout_width=0dip + layout_weight=1（占满剩余宽度）
        Text(item.source)
          .fontSize(14)
          .fontColor($r('app.color.common_color_3'))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .padding({ right: 10 })
          .layoutWeight(1)
        // tvTime：textSize=14.0sp=14fp、textColor=#ff999999、wrap_content
        Text(item.publishTime)
          .fontSize(14)
          .fontColor($r('app.color.common_color_3'))
      }
      .width('100%')
      .margin({ top: 5 })
      .alignItems(VerticalAlign.Center)
      // 分隔 View：background=#fff5f5f5、height=0.5dip=0.5vp、layout_marginTop=10.0dip=10vp
      Divider()
        .color($r('app.color.news_list_item_divider'))
        .strokeWidth(0.5)
        .margin({ top: 10 })
        .width('100%')
    }
    .width('100%')
    .padding(10)
    .backgroundColor($r('app.color.white'))
    .alignItems(HorizontalAlign.Start)
    .onClick(() => {
      router.pushUrl({ url: 'pages/NewsDetailPage', params: { id: item.id } });
    })
  }

  build() {
    // mobile_campus_activity_news.xml 根 LinearLayout vertical（fill_parent）
    Column() {
      // include toolbar_normal（45vp 白底 + 16fp 标题 + 0.5vp 分隔线）
      TitleBar({ title: '新闻公告', showBack: true })
      // mRecyclerView：fill_parent、LinearLayoutManager
      if (this.isLoading) {
        LoadingView()
      } else {
        if (this.newsList.length === 0) {
          EmptyView()
        } else {
          List() {
            ForEach(this.newsList, (item: NewsItem) => {
              ListItem() {
                this.newsListItem(item)
              }
            }, (item: NewsItem) => item.id)
          }
          .width('100%')
          .layoutWeight(1)
          .backgroundColor($r('app.color.white'))
          .scrollBar(BarState.Off)
        }
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.white'))
  }
}
