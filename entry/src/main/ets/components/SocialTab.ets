import { router } from '@kit.ArkUI';
import { TitleBar } from './TitleBar';
import { BreakpointSystem } from '../common/BreakpointSystem';

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
  @StorageProp('currentBreakpoint') currentBreakpoint: string = 'sm';
  @StorageProp('isCompactHeight') isCompactHeight: boolean = false;
  @StorageProp('avoidAreaBottomVp') avoidAreaBottomVp: number = 0;

  private getPostLanes(): number {
    if (this.currentBreakpoint === 'md' || this.currentBreakpoint === 'lg' || this.currentBreakpoint === 'xl') {
      return 2;
    }
    return 1;
  }

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
    .width('100%')
    .padding({ top: 14, bottom: 14 })
    .borderRadius(8)
    .hoverEffect(HoverEffect.Highlight)
    .onClick(() => {
      router.pushUrl({ url: target });
    })
  }

  @Builder
  shortcutHeader() {
    Column() {
      GridRow({ columns: { xs: 2, sm: 4, md: 4, lg: 4, xl: 4 }, gutter: { x: 8, y: 8 } }) {
        GridCol({ span: 1 }) {
          this.entryRow($r('app.media.icon_share'), '校园动态', 'pages/SocialNewsPage')
        }
        GridCol({ span: 1 }) {
          this.entryRow($r('app.media.mobile_campus_school_like'), '我的帖子', 'pages/MyPostPage')
        }
        GridCol({ span: 1 }) {
          this.entryRow($r('app.media.icon_all'), '跳蚤市场', 'pages/MarketPage')
        }
        GridCol({ span: 1 }) {
          this.entryRow($r('app.media.teacher_icon'), '好友', 'pages/FriendUserListPage')
        }
      }
      .width('100%')
      .backgroundColor($r('app.color.white'))
      .borderRadius(8)
    }
    .width('100%')
    .padding({ top: 8, bottom: 8 })
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
    .borderRadius(this.getPostLanes() > 1 ? 10 : 0)
    .hoverEffect(HoverEffect.Highlight)
  }

  build() {
    Column() {
      TitleBar({ title: '校圈', showBack: false })

      Row() {
        List({ space: 8 }) {
          ListItemGroup({ header: this.shortcutHeader() })
          ListItemGroup() {
            ForEach(this.posts, (post: CirclePost) => {
              ListItem() {
                this.postRow(post)
              }
            }, (post: CirclePost) => post.author)
          }
        }
        .lanes(this.getPostLanes(), this.getPostLanes() > 1 ? 10 : 0)
        .width('100%')
        .height('100%')
        .constraintSize({ maxWidth: BreakpointSystem.getContentMaxWidth(this.currentBreakpoint) })
        .padding({ left: this.getPostLanes() > 1 ? 12 : 0, right: this.getPostLanes() > 1 ? 12 : 0 })
        .contentEndOffset(Math.max(20, this.avoidAreaBottomVp + 16))
        .scrollBar(BarState.Off)
      }
      .width('100%')
      .layoutWeight(1)
      .justifyContent(FlexAlign.Center)
      .backgroundColor($r('app.color.common_color_6'))
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.common_color_6'))
  }
}
