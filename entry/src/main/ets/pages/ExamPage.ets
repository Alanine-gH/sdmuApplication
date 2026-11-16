import { ApiService } from '../network/ApiService';
import { ExamItem } from '../model/ScoreModel';
import { TitleBar } from '../components/TitleBar';
import { EmptyView } from '../components/EmptyView';
import { LoadingView } from '../components/LoadingView';

/**
 * 考试安排页。
 */
@Entry
@Component
struct ExamPage {
  @State examList: ExamItem[] = [];
  @State isLoading: boolean = true;

  aboutToAppear(): void {
    ApiService.getExamList()
      .then((response) => {
        this.examList = response.data;
        this.isLoading = false;
      })
      .catch(() => {
        this.examList = [];
        this.isLoading = false;
      });
  }

  build() {
    Column() {
      TitleBar({ title: '考试安排', showBack: true })
      if (this.isLoading) {
        LoadingView()
      } else {
        if (this.examList.length === 0) {
          EmptyView()
        } else {
          List() {
            ForEach(this.examList, (item: ExamItem) => {
              ListItem() {
                Column({ space: 8 }) {
                  Row() {
                    Text(item.courseName)
                      .fontSize(16)
                      .fontWeight(FontWeight.Bold)
                      .fontColor($r('app.color.sdmu_text_primary'))
                      .layoutWeight(1)
                      .maxLines(1)
                      .textOverflow({ overflow: TextOverflow.Ellipsis })
                    Text(item.type)
                      .fontSize(11)
                      .fontColor($r('app.color.sdmu_primary'))
                      .padding({ left: 8, right: 8, top: 3, bottom: 3 })
                      .borderRadius(10)
                      .backgroundColor('#141677FF')
                  }
                  .width('100%')
                  Row() {
                    Text('🕐 ' + item.time)
                      .fontSize(13)
                      .fontColor($r('app.color.sdmu_text_secondary'))
                  }
                  .width('100%')
                  Row() {
                    Text('📍 ' + item.location)
                      .fontSize(13)
                      .fontColor($r('app.color.sdmu_text_secondary'))
                  }
                  .width('100%')
                }
                .alignItems(HorizontalAlign.Start)
                .padding(14)
                .borderRadius(10)
                .backgroundColor($r('app.color.sdmu_card_bg'))
                .margin({ left: 12, right: 12, top: 10 })
              }
            }, (item: ExamItem) => item.id)
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
