import { router } from '@kit.ArkUI';
import { ApiService } from '../network/ApiService';
import { NewsItem } from '../model/NewsModel';
import { TitleBar } from '../components/TitleBar';
import { LoadingView } from '../components/LoadingView';
import { EmptyView } from '../components/EmptyView';

/**
 * 新闻详情页。
 */
@Entry
@Component
struct NewsDetailPage {
  @State news: NewsItem = new NewsItem('', '', '', '', '', '', '', '', '');
  @State isLoading: boolean = true;

  aboutToAppear(): void {
    const params: object = router.getParams();
    let newsId: string = '';
    if (params !== null && params !== undefined) {
      const record = params as Record<string, Object>;
      const idValue: Object = record['id'];
      if (typeof idValue === 'string') {
        newsId = idValue as string;
      }
    }
    ApiService.getNewsDetail(newsId)
      .then((response) => {
        this.news = response.data;
        this.isLoading = false;
      })
      .catch(() => {
        this.isLoading = false;
      });
  }

  build() {
    Column() {
      TitleBar({ title: '新闻详情', showBack: true })
      if (this.isLoading) {
        LoadingView()
      } else {
        if (this.news.id === '') {
          EmptyView({ tipText: '内容不存在' })
        } else {
          Scroll() {
            Column({ space: 12 }) {
              Text(this.news.title)
                .fontSize(20)
                .fontWeight(FontWeight.Bold)
                .fontColor($r('app.color.sdmu_text_primary'))
              Row() {
                Text(this.news.source)
                  .fontSize(12)
                  .fontColor($r('app.color.sdmu_text_hint'))
                Blank()
                Text(this.news.publishTime)
                  .fontSize(12)
                  .fontColor($r('app.color.sdmu_text_hint'))
              }
              .width('100%')
              Divider()
                .color($r('app.color.sdmu_divider'))
              Text(this.news.content)
                .fontSize(15)
                .lineHeight(26)
                .fontColor($r('app.color.sdmu_text_secondary'))
                .width('100%')
            }
            .alignItems(HorizontalAlign.Start)
            .padding(16)
          }
          .layoutWeight(1)
          .scrollBar(BarState.Off)
        }
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.sdmu_bg'))
  }
}
