import { ApiService } from '../network/ApiService';
import { ScoreItem } from '../model/ScoreModel';
import { TitleBar } from '../components/TitleBar';
import { EmptyView } from '../components/EmptyView';
import { LoadingView } from '../components/LoadingView';

/**
 * 成绩列表页：右侧大号分数按分数段着色。
 */
@Entry
@Component
struct ScorePage {
  @State scoreList: ScoreItem[] = [];
  @State isLoading: boolean = true;

  aboutToAppear(): void {
    ApiService.getScoreList()
      .then((response) => {
        this.scoreList = response.data;
        this.isLoading = false;
      })
      .catch(() => {
        this.scoreList = [];
        this.isLoading = false;
      });
  }

  private scoreColor(score: number): Resource {
    if (score >= 90) {
      return $r('app.color.sdmu_success');
    }
    if (score >= 60) {
      return $r('app.color.sdmu_primary');
    }
    return $r('app.color.sdmu_danger');
  }

  build() {
    Column() {
      TitleBar({ title: '我的成绩', showBack: true })
      if (this.isLoading) {
        LoadingView()
      } else {
        if (this.scoreList.length === 0) {
          EmptyView()
        } else {
          List() {
            ForEach(this.scoreList, (item: ScoreItem) => {
              ListItem() {
                Row({ space: 12 }) {
                  Column({ space: 6 }) {
                    Text(item.courseName)
                      .fontSize(16)
                      .fontWeight(FontWeight.Medium)
                      .fontColor($r('app.color.sdmu_text_primary'))
                      .maxLines(1)
                      .textOverflow({ overflow: TextOverflow.Ellipsis })
                    Text(item.semester + ' · ' + item.credit + '学分 · ' + item.type)
                      .fontSize(12)
                      .fontColor($r('app.color.sdmu_text_hint'))
                  }
                  .alignItems(HorizontalAlign.Start)
                  .layoutWeight(1)
                  Column({ space: 2 }) {
                    Text(item.score + '')
                      .fontSize(26)
                      .fontWeight(FontWeight.Bold)
                      .fontColor(this.scoreColor(item.score))
                    Text('绩点 ' + item.gpa)
                      .fontSize(11)
                      .fontColor($r('app.color.sdmu_text_hint'))
                  }
                  .alignItems(HorizontalAlign.Center)
                }
                .width('100%')
                .padding(14)
                .borderRadius(10)
                .backgroundColor($r('app.color.sdmu_card_bg'))
                .margin({ left: 12, right: 12, top: 10 })
              }
            }, (item: ScoreItem) => item.id)
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
