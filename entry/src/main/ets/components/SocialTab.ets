import { router } from '@kit.ArkUI';
import { TitleBar } from './TitleBar';

/**
 * 校圈 Tab — 复刻 SocialMainActivity（social_main_activity.xml + social_fragment_head）
 * 结构：toolbar_normal「校圈」+ 模块流：
 *   - 头部入口卡（白色）：校园动态/我的帖子/跳蚤市场/好友 4入口
 *   - 帖子流预览（social_news_head 样式：头像40vp+昵称14fp+时间12fp+内容15fp+九宫格图）
 */
class CirclePost {
  author: string;
  time: string;
  content: string;

  constructor(author: string, time: string, content: string) {
    this.author = author;
    this.time = time;
    this.content = content;
  }
}

@Component
export struct SocialTab {
  @State posts: CirclePost[] = [
    new CirclePost('校园记者团', '2小时前', '第十一届社团文化节圆满落幕，快来看看精彩瞬间！'),
    new CirclePost('信息工程学院', '5小时前', '程序设计大赛报名开始，欢迎大家踊跃参加。'),
    new CirclePost('青春山管', '昨天 18:30', '秋日校园美图分享，一起来感受秋天的山管～')
  ];

  @Builder
  entryRow(icon: Resource, label: string, target: string) {
    Column() {
      Image(icon)
        .width(28)
        .height(28)
      Text(label)
        .fontSize(13)
        .fontColor($r('app.color.common_color_1'))
        .margin({ top: 6 })
    }
    .layoutWeight(1)
    .padding({ top: 14, bottom: 14 })
    .onClick(() => {
      router.pushUrl({ url: target });
    })
  }

  @Builder
  postRow(post: CirclePost) {
    Row() {
      Column() {
        Image($r('app.media.mobile_campus_school_logo'))
          .width(40)
          .height(40)
          .borderRadius(20)
        Blank()
          .layoutWeight(1)
      }
      .width(40)

      Column() {
        Text(post.author)
          .fontSize(14)
          .fontColor($r('app.color.common_color_1'))
        Text(post.content)
          .fontSize(15)
          .fontColor($r('app.color.common_color_1'))
          .margin({ top: 6 })
          .maxLines(3)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        Text(post.time)
          .fontSize(12)
          .fontColor($r('app.color.common_color_3'))
          .margin({ top: 8 })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
      .margin({ left: 12 })
    }
    .width('100%')
    .padding({ left: 15, right: 15, top: 12, bottom: 12 })
    .alignItems(VerticalAlign.Top)
    .backgroundColor($r('app.color.white'))
  }

  build() {
    Column() {
      TitleBar({ title: '校圈', showBack: false })

      Scroll() {
        Column() {
          // 头部入口卡（4入口）
          Row() {
            this.entryRow($r('app.media.icon_share'), '校园动态', 'pages/SocialNewsPage')
            this.entryRow($r('app.media.mobile_campus_school_like'), '我的帖子', 'pages/MyPostPage')
            this.entryRow($r('app.media.icon_all'), '跳蚤市场', 'pages/MarketPage')
            this.entryRow($r('app.media.teacher_icon'), '好友', 'pages/FriendUserListPage')
          }
          .width('100%')
          .backgroundColor($r('app.color.white'))
          .margin({ top: 8 })

          // 帖子流
          Column() {
            ForEach(this.posts, (post: CirclePost) => {
              this.postRow(post)
            }, (post: CirclePost) => post.author)
          }
          .width('100%')
          .margin({ top: 8 })

          Blank()
            .height(20)
        }
        .width('100%')
      }
      .width('100%')
      .layoutWeight(1)
      .scrollBar(BarState.Off)
      .backgroundColor($r('app.color.common_color_6'))
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.common_color_6'))
  }
}
