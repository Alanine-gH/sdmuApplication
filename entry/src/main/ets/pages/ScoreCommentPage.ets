import { router } from '@kit.ArkUI';
import { BusinessError } from '@kit.BasicServicesKit';
import { TitleBar } from '../components/TitleBar';
import { ApiService } from '../network/ApiService';
import { ApiResponse } from '../model/ResponseModel';
import { ScoreCommentEntry } from '../model/ScoreModel';

class ScoreCommentItem {
  avatarText: string = '';
  commentName: string = '';
  commentTime: string = '';
  commentContent: string = '';
}

@Component
struct CommentListItem {
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
struct ScoreCommentPage {
  @State commentList: ScoreCommentItem[] = [
    {
      avatarText: '张',
      commentName: '张同学',
      commentTime: '2026-06-28',
      commentContent: '老师讲课很细致，例题覆盖全面，考前把错题过了一遍基本就稳了。'
    },
    {
      avatarText: '匿',
      commentName: '匿名同学',
      commentTime: '2026-06-30',
      commentContent: '平时作业量适中，期末难度比往年低一些，认真复习拿高分不难。'
    },
    {
      avatarText: '刘',
      commentName: '刘同学',
      commentTime: '2026-07-02',
      commentContent: '签到要求比较严，别缺勤；作业按时交，占总评不少。'
    },
    {
      avatarText: '陈',
      commentName: '陈同学',
      commentTime: '2026-07-05',
      commentContent: '课程内容偏理论，建议课前预习一遍课件，上课会轻松很多。'
    }
  ];

  aboutToAppear(): void {
    ApiService.getScoreComments()
      .then((response: ApiResponse<ScoreCommentEntry[]>) => {
        if (response.data.length > 0) {
          this.commentList = response.data.map((entry: ScoreCommentEntry): ScoreCommentItem => {
            const commentItem: ScoreCommentItem = {
              avatarText: entry.avatarText,
              commentName: entry.commentName,
              commentTime: entry.commentTime,
              commentContent: entry.commentContent
            };
            return commentItem;
          });
        }
      })
      .catch((error: BusinessError) => {
      });
  }

  build() {
    Column() {
      TitleBar({ title: '课评', showBack: true })
      List() {
        ForEach(this.commentList, (commentItem: ScoreCommentItem) => {
          ListItem() {
            CommentListItem({ commentItem: commentItem })
          }
        }, (commentItem: ScoreCommentItem) => commentItem.commentName)
      }
      .layoutWeight(1)
      .width('100%')
      .divider({
        strokeWidth: 0.4,
        color: $r('app.color.common_color_5'),
        startMargin: 0,
        endMargin: 0
      })
      .backgroundColor($r('app.color.common_color_6'))
      .scrollBar(BarState.Off)

      Divider()
        .color($r('app.color.common_color_5'))
        .strokeWidth(0.4)
        .width('100%')
      Column() {
        Text('给同学留言')
          .fontSize(17)
          .fontColor($r('app.color.common_color_7'))
          .height(60)
          .textAlign(TextAlign.Center)
      }
      .width('100%')
      .backgroundColor($r('app.color.main_bg'))
      .justifyContent(FlexAlign.Center)
      .onClick(() => {
        router.pushUrl({ url: 'pages/ScoreCommentPostPage' });
      })
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.main_bg'))
  }
}
