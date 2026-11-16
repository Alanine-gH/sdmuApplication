import { router } from '@kit.ArkUI';
import { ApiService } from '../network/ApiService';
import { NewsItem } from '../model/NewsModel';
import { TitleBar } from '../components/TitleBar';
import { EmptyView } from '../components/EmptyView';
import { LoadingView } from '../components/LoadingView';

/**
 * 新闻列表页。
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

  build() {
    Column() {
      TitleBar({ title: '新闻公告', showBack: true })
      if (this.isLoading) {
        LoadingView()
      } else {
        if (this.newsList.length === 0) {
          EmptyView()
        } else {
          List({ space: 0 }) {
            ForEach(this.newsList, (item: NewsItem) => {
              ListItem() {
                Column({ space: 6 }) {
                  Text(item.title)
                    .fontSize(16)
                    .fontWeight(FontWeight.Bold)
                    .fontColor($r('app.color.sdmu_text_primary'))
                    .maxLines(2)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                  Text(item.summary)
                    .fontSize(13)
                    .fontColor($r('app.color.sdmu_text_secondary'))
                    .maxLines(3)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                  Row() {
                    Text(item.source)
                      .fontSize(12)
                      .fontColor($r('app.color.sdmu_primary'))
                    Blank()
                    Text(item.publishTime)
                      .fontSize(12)
                      .fontColor($r('app.color.sdmu_text_hint'))
                  }
                  .width('100%')
                }
                .alignItems(HorizontalAlign.Start)
                .padding(14)
                .borderRadius(10)
                .backgroundColor($r('app.color.sdmu_card_bg'))
                .margin({ left: 12, right: 12, top: 10 })
                .shadow({ radius: 4, color: '#11000000', offsetX: 0, offsetY: 2 })
                .onClick(() => {
                  router.pushUrl({ url: 'pages/NewsDetailPage', params: { id: item.id } });
                })
              }
            }, (item: NewsItem) => item.id)
          }
          .width('100%')
          .layoutWeight(1)
          .backgroundColor($r('app.color.sdmu_bg'))
          .scrollBar(BarState.Off)
        }
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.sdmu_bg'))
  }
}
