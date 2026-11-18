import { router } from '@kit.ArkUI';
import { BusinessError } from '@kit.BasicServicesKit';
import { TitleBar } from '../components/TitleBar';
import { EmptyView } from '../components/EmptyView';
import { LoadingView } from '../components/LoadingView';
import { ApiService } from '../network/ApiService';
import { ApiResponse } from '../model/ResponseModel';
import { ScoreStatEntry, ScoreDetailEntry, ScoreRankEntry, ScoreCommentEntry,
  ScoreDetailData } from '../model/ScoreModel';

class ScoreStatCell {
  label: string = '';
  statValue: string = '';
}

class ScoreDetailItem {
  courseName: string = '';
  totalScore: string = '';
  avgScore: string = '';
  maxScore: string = '';
  failRate: string = '';
  personalScore: string = '';
  statCells: ScoreStatCell[] = [];
}

class ScoreRankItem {
  rankNo: string = '';
  rankName: string = '';
  anonymous: boolean = false;
  rankPoint: string = '';
  likeNum: string = '';
}

class ScoreCommentItem {
  avatarText: string = '';
  commentName: string = '';
  commentTime: string = '';
  commentContent: string = '';
}

@Component
struct ScoreStatCellView {
  @Prop cell: ScoreStatCell = new ScoreStatCell();

  build() {
    Column({ space: 2 }) {
      Text(this.cell.statValue)
        .fontSize(15)
        .fontColor($r('app.color.common_color_1'))
        .maxLines(1)
      Text(this.cell.label)
        .fontSize(12)
        .fontColor($r('app.color.common_color_3'))
        .maxLines(1)
    }
    .layoutWeight(1)
    .padding({ top: 10, bottom: 10 })
    .justifyContent(FlexAlign.Center)
  }
}

@Component
struct ScoreRankRow {
  @Prop rankItem: ScoreRankItem = new ScoreRankItem();

  build() {
    Row() {
      Text(this.rankItem.rankNo)
        .fontSize(14)
        .fontColor($r('app.color.white'))
        .textAlign(TextAlign.Center)
        .width(24)
        .height(24)
        .borderRadius(8)
        .backgroundColor($r('app.color.score_rank_red'))
      Text(this.rankItem.anonymous ? '匿名' : this.rankItem.rankName)
        .fontSize(15)
        .fontColor($r('app.color.common_color_1'))
        .width(80)
        .padding({ left: 15, right: 15 })
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
      Text(this.rankItem.rankPoint)
        .fontSize(15)
        .fontColor($r('app.color.common_color_3'))
        .padding({ left: 15, right: 15 })
        .layoutWeight(1)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
      Row({ space: 2 }) {
        Text('赞')
          .fontSize(10)
          .fontColor($r('app.color.common_color_3'))
          .maxLines(1)
        Text(this.rankItem.likeNum)
          .fontSize(10)
          .fontColor($r('app.color.common_color_3'))
          .maxLines(1)
      }
      .width(35)
      .height(35)
      .alignItems(VerticalAlign.Center)
      .justifyContent(FlexAlign.End)
    }
    .width('100%')
    .padding(15)
    .backgroundColor($r('app.color.white'))
    .alignItems(VerticalAlign.Center)
  }
}

@Component
struct ScoreCommentRow {
  @Prop commentItem: ScoreCommentItem = new ScoreCommentItem();

  build() {
    Row() {
      Text(this.commentItem.avatarText)
        .fontSize(16)
        .fontColor($r('app.color.white'))
        .textAlign(TextAlign.Center)
        .width(34)
        .height(34)
        .borderRadius(17)
        .backgroundColor($r('app.color.ybg_blue'))
      Column() {
        Row() {
          Text(this.commentItem.commentName)
            .fontSize(17)
            .fontColor($r('app.color.common_color_1'))
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .layoutWeight(1)
          Text(this.commentItem.commentTime)
            .fontSize(12)
            .fontColor($r('app.color.common_color_4'))
            .maxLines(1)
        }
        .width('100%')
        .alignItems(VerticalAlign.Center)
        Text(this.commentItem.commentContent)
          .fontSize(14)
          .fontColor($r('app.color.common_color_2'))
          .lineHeight(21)
          .width('100%')
          .margin({ top: 3 })
      }
      .layoutWeight(1)
      .margin({ left: 15 })
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .padding(15)
    .backgroundColor($r('app.color.white'))
    .alignItems(VerticalAlign.Top)
  }
}

@Entry
@Component
struct StudentScoreDetailPage {
  @State detailList: ScoreDetailItem[] = [];
  @State rankList: ScoreRankItem[] = [];
  @State commentList: ScoreCommentItem[] = [];
  @State isLoading: boolean = true;

  aboutToAppear(): void {
    ApiService.getScoreDetail()
      .then((response: ApiResponse<ScoreDetailData>) => {
        if (response.code !== 0) {
          console.info('StudentScoreDetailPage degrade: code=' + response.code + ' msg=' + response.message);
        }
        const data: ScoreDetailData = response.data;
        this.detailList = data.detailList.map((entry: ScoreDetailEntry): ScoreDetailItem => {
          const cells: ScoreStatCell[] = entry.statCells.map((cell: ScoreStatEntry): ScoreStatCell => {
            const cellItem: ScoreStatCell = { label: cell.label, statValue: cell.statValue };
            return cellItem;
          });
          const item: ScoreDetailItem = {
            courseName: entry.courseName,
            totalScore: entry.totalScore,
            avgScore: entry.avgScore,
            maxScore: entry.maxScore,
            failRate: entry.failRate,
            personalScore: entry.personalScore,
            statCells: cells
          };
          return item;
        });
        this.rankList = data.rankList.map((entry: ScoreRankEntry): ScoreRankItem => {
          const rankItem: ScoreRankItem = {
            rankNo: entry.rankNo,
            rankName: entry.rankName,
            anonymous: entry.anonymous,
            rankPoint: entry.rankPoint,
            likeNum: entry.likeNum
          };
          return rankItem;
        });
        this.commentList = data.commentList.map((entry: ScoreCommentEntry): ScoreCommentItem => {
          const commentItem: ScoreCommentItem = {
            avatarText: entry.avatarText,
            commentName: entry.commentName,
            commentTime: entry.commentTime,
            commentContent: entry.commentContent
          };
          return commentItem;
        });
        this.isLoading = false;
      })
      .catch((error: BusinessError) => {
        console.info('StudentScoreDetailPage load fail: ' + error.message);
        this.isLoading = false;
      });
  }

  build() {
    Column() {
      TitleBar({ title: '成绩单详情', showBack: true })
      if (this.isLoading) {
        LoadingView()
      } else if (this.detailList.length === 0) {
        EmptyView()
      } else {
      Scroll() {
        Column() {
          ForEach(this.detailList, (item: ScoreDetailItem) => {
            Column() {
              Row() {
                Text('课程')
                  .fontSize(14)
                  .fontColor($r('app.color.white'))
                  .height(26)
                Text('总评成绩')
                  .fontSize(14)
                  .fontColor($r('app.color.white'))
                  .layoutWeight(1)
                  .textAlign(TextAlign.End)
                  .margin({ right: 20 })
              }
              .width('100%')
              .padding({ left: 15, top: 26, right: 15 })
              .backgroundColor($r('app.color.ybg_blue'))
              Row() {
                Text(item.courseName)
                  .fontSize(18)
                  .fontColor($r('app.color.white'))
                  .layoutWeight(1)
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
                Text(item.totalScore)
                  .fontSize(49)
                  .fontColor($r('app.color.white'))
                  .padding({ left: 20, right: 20 })
              }
              .width('100%')
              .padding({ left: 15, right: 15, bottom: 15 })
              .backgroundColor($r('app.color.ybg_blue'))
              Column()
                .width('100%')
                .height(15)
                .backgroundColor($r('app.color.main_bg'))
              Row() {
                ForEach(item.statCells, (cell: ScoreStatCell) => {
                  ScoreStatCellView({ cell: cell })
                }, (cell: ScoreStatCell) => cell.label)
              }
              .width('100%')
              .backgroundColor($r('app.color.main_bg'))
              Divider()
                .color($r('app.color.common_color_5'))
                .strokeWidth(0.5)
                .width('100%')
              Divider()
                .color($r('app.color.common_color_6'))
                .strokeWidth(0.5)
                .width('100%')
              Divider()
                .color($r('app.color.common_color_5'))
                .strokeWidth(0.5)
                .width('100%')
              Text('成绩统计')
                .fontSize(14)
                .fontColor($r('app.color.common_color_1'))
                .width('100%')
                .padding(15)
              Divider()
                .color($r('app.color.common_color_5'))
                .strokeWidth(0.5)
                .width('100%')
              Column() {
                Row() {
                  Row() {
                    Text('平均成绩')
                      .fontSize(15)
                      .fontColor($r('app.color.common_color_3'))
                    Text(item.avgScore)
                      .fontSize(15)
                      .fontColor($r('app.color.common_color_7'))
                      .margin({ left: 20 })
                  }
                  .layoutWeight(1)
                  Row() {
                    Text('最高成绩')
                      .fontSize(15)
                      .fontColor($r('app.color.common_color_3'))
                    Text(item.maxScore)
                      .fontSize(15)
                      .fontColor($r('app.color.common_color_7'))
                      .margin({ left: 20 })
                  }
                  .layoutWeight(1)
                }
                .width('100%')
                .padding({ top: 15, bottom: 15 })
                Divider()
                  .color($r('app.color.common_color_5'))
                  .strokeWidth(0.5)
                  .width('100%')
                Row() {
                  Row() {
                    Text('挂科率')
                      .fontSize(15)
                      .fontColor($r('app.color.common_color_3'))
                    Text(item.failRate)
                      .fontSize(15)
                      .fontColor($r('app.color.common_color_7'))
                      .margin({ left: 20 })
                  }
                  .layoutWeight(1)
                  Row() {
                    Text('个人成绩')
                      .fontSize(15)
                      .fontColor($r('app.color.common_color_3'))
                    Text(item.personalScore)
                      .fontSize(15)
                      .fontColor($r('app.color.common_color_7'))
                      .margin({ left: 20 })
                  }
                  .layoutWeight(1)
                }
                .width('100%')
                .padding({ top: 15, bottom: 15 })
              }
              .width('100%')
              .padding({ left: 15, right: 15 })
              .backgroundColor($r('app.color.white'))
            }
            .width('100%')
            .backgroundColor($r('app.color.main_bg'))
          }, (item: ScoreDetailItem) => item.courseName)

          Divider()
            .color($r('app.color.common_color_5'))
            .strokeWidth(1)
            .width('100%')
          Divider()
            .color($r('app.color.common_color_5'))
            .strokeWidth(0.5)
            .width('100%')
          Row() {
            Text('班级成绩排名')
              .fontSize(14)
              .fontColor($r('app.color.common_color_1'))
              .padding(15)
              .layoutWeight(1)
          }
          .width('100%')
          .backgroundColor($r('app.color.main_bg'))
          ForEach(this.rankList, (rankItem: ScoreRankItem) => {
            ScoreRankRow({ rankItem: rankItem })
          }, (rankItem: ScoreRankItem) => rankItem.rankNo)

          Divider()
            .color($r('app.color.common_color_5'))
            .strokeWidth(1)
            .width('100%')
          Divider()
            .color($r('app.color.common_color_5'))
            .strokeWidth(0.5)
            .width('100%')
          Row() {
            Text('考后课评')
              .fontSize(14)
              .fontColor($r('app.color.common_color_1'))
              .padding(15)
              .layoutWeight(1)
            Row() {
              Text('更多')
                .fontSize(14)
                .fontColor($r('app.color.common_color_3'))
              Text('＞')
                .fontSize(14)
                .fontColor($r('app.color.common_color_3'))
                .margin({ left: 5 })
            }
            .padding({ right: 15 })
            .onClick(() => {
              router.pushUrl({ url: 'pages/ScoreCommentPage' });
            })
          }
          .width('100%')
          .backgroundColor($r('app.color.main_bg'))
          ForEach(this.commentList, (commentItem: ScoreCommentItem) => {
            Column() {
              ScoreCommentRow({ commentItem: commentItem })
              Divider()
                .color($r('app.color.common_color_5'))
                .strokeWidth(0.4)
                .width('100%')
            }
          }, (commentItem: ScoreCommentItem) => commentItem.commentName)

          Column() {
            Text('给同学留言')
              .fontSize(17)
              .fontColor($r('app.color.common_color_7'))
              .height(60)
              .textAlign(TextAlign.Center)
          }
          .width('100%')
          .justifyContent(FlexAlign.Center)
          .onClick(() => {
            router.pushUrl({ url: 'pages/ScoreCommentPostPage' });
          })
        }
        .width('100%')
      }
      .layoutWeight(1)
      .backgroundColor($r('app.color.common_color_6'))
      }
    }
    .width('100%')
    .height('100%')
  }
}
