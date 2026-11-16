import { router } from '@kit.ArkUI';
import { ApiService } from '../network/ApiService';
import { NewsItem } from '../model/NewsModel';

/**
 * 首页 Tab：聚合功能入口 + 新闻列表。
 */
@Component
export struct HomeTab {
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

  @Builder
  entryCard(icon: string, label: string, target: string) {
    Column({ space: 6 }) {
      Text(icon)
        .fontSize(26)
      Text(label)
        .fontSize(12)
        .fontColor($r('app.color.sdmu_text_secondary'))
    }
    .width('22%')
    .padding({ top: 12, bottom: 12 })
    .borderRadius(10)
    .backgroundColor($r('app.color.sdmu_card_bg'))
    .onClick(() => {
      router.pushUrl({ url: target });
    })
  }

  @Builder
  newsCard(item: NewsItem) {
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
    .onClick(() => {
      router.pushUrl({ url: 'pages/NewsDetailPage', params: { id: item.id } });
    })
  }

  build() {
    Column() {
      Text('山东管理学院')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor(Color.White)
        .width('100%')
        .height(56)
        .textAlign(TextAlign.Center)
        .backgroundColor($r('app.color.sdmu_primary'))

      List({ space: 0 }) {
        ListItem() {
          Row({ space: 8 }) {
            this.entryCard('📖', '新闻公告', 'pages/NewsPage')
            this.entryCard('📅', '我的课表', 'pages/SchedulePage')
            this.entryCard('📝', '待办事项', 'pages/TodoPage')
            this.entryCard('📊', '我的成绩', 'pages/ScorePage')
          }
          .width('100%')
          .justifyContent(FlexAlign.SpaceBetween)
          .padding({ left: 12, right: 12, top: 12 })
        }

        ListItem() {
          Row({ space: 8 }) {
            this.entryCard('🏛', '会议', 'pages/MeetingPage')
            this.entryCard('👥', '通讯录', 'pages/ContactPage')
            this.entryCard('🕐', '考试安排', 'pages/ExamPage')
            this.entryCard('✅', '考勤记录', 'pages/AttendancePage')
          }
          .width('100%')
          .justifyContent(FlexAlign.SpaceBetween)
          .padding({ left: 12, right: 12, top: 8, bottom: 4 })
        }

        ForEach(this.newsList, (item: NewsItem) => {
          ListItem() {
            this.newsCard(item)
          }
        }, (item: NewsItem) => item.id)
      }
      .width('100%')
      .layoutWeight(1)
      .backgroundColor($r('app.color.sdmu_bg'))
    }
    .width('100%')
    .height('100%')
  }
}
