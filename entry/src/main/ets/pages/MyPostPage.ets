import { router } from '@kit.ArkUI';

/**
 * 我的贴子页 — 1:1 复刻 social_fragment_post_item.xml：
 * social_post_item（头像40x40+昵称16fp+学校/时间12fp+正文15fp）
 * + 点赞评论行 + 2vp间隔 + 分隔线组(thin/normal/thin)
 * 空态文案：你还没发过帖子哦
 */
interface MyPostItem {
  id: number;
  content: string;
  school: string;
  time: string;
  commentCount: number;
  likeCount: number;
}

@Entry
@Component
struct MyPostPage {
  @State postList: MyPostItem[] = [
    {
      id: 1,
      content: '今天在图书馆三楼捡到一张校园卡，请失主联系我~',
      school: '山东管理学院',
      time: '11-15 14:30',
      commentCount: 12,
      likeCount: 34
    },
    {
      id: 2,
      content: '求推荐几门好过的选修课，学弟学妹们快冲！',
      school: '山东管理学院',
      time: '11-13 20:10',
      commentCount: 56,
      likeCount: 89
    },
    {
      id: 3,
      content: '周末社团招新，摄影协会期待你的加入！',
      school: '山东管理学院',
      time: '11-11 09:45',
      commentCount: 8,
      likeCount: 21
    }
  ];

  @Builder
  postItemBuilder(item: MyPostItem) {
    Column() {
      Column() {
        Row() {
          Image($r('app.media.default_avatar'))
            .width(40)
            .height(40)
            .borderRadius(20)
            .objectFit(ImageFit.Cover)
          Column() {
            Text('我')
              .fontSize(16)
              .fontColor($r('app.color.common_color_1'))
              .maxLines(1)
              .width('100%')
              .padding({ left: 5 })
            Row() {
              Text(item.school)
                .fontSize(12)
                .fontColor($r('app.color.common_color_3'))
                .layoutWeight(1)
              Text(item.time)
                .fontSize(12)
                .fontColor($r('app.color.common_color_3'))
            }
            .width('100%')
            .padding({ left: 5 })
          }
          .layoutWeight(1)
          .alignItems(HorizontalAlign.Start)
        }
        .width('100%')
        .margin({ bottom: 5 })
        .alignItems(VerticalAlign.Center)

        Text(item.content)
          .fontSize(15)
          .fontColor($r('app.color.common_color_1'))
          .width('100%')
          .padding({ top: 5, bottom: 4 })
      }
      .width('100%')
      .padding({ left: 15, right: 15, top: 10, bottom: 7 })

      Row() {
        Row() {
          Image($r('app.media.social_comment'))
            .width(15)
            .height(15)
            .objectFit(ImageFit.Contain)
          Text(item.commentCount.toString())
            .fontSize(15)
            .fontColor($r('app.color.common_color_3'))
            .margin({ left: 7 })
        }
        .padding({ top: 10, right: 40, bottom: 10 })
        .alignItems(VerticalAlign.Center)

        Row() {
          Image($r('app.media.social_like'))
            .width(15)
            .height(15)
            .objectFit(ImageFit.Contain)
          Text(item.likeCount.toString())
            .fontSize(15)
            .fontColor($r('app.color.common_color_3'))
            .margin({ left: 7 })
        }
        .padding({ top: 10, right: 40, bottom: 10 })
        .alignItems(VerticalAlign.Center)

        Blank()

        Image($r('app.media.social_more'))
          .width(15)
          .height(15)
          .objectFit(ImageFit.Contain)
      }
      .width('100%')
      .padding({ left: 15, right: 15 })
      .alignItems(VerticalAlign.Center)

      Divider()
        .color($r('app.color.common_color_5'))
        .strokeWidth(0.5)
        .width('100%')
      Divider()
        .color($r('app.color.common_color_6'))
        .strokeWidth(4)
        .width('100%')
      Divider()
        .color($r('app.color.common_color_5'))
        .strokeWidth(0.5)
        .width('100%')
    }
    .width('100%')
    .backgroundColor($r('app.color.main_bg'))
    .onClick(() => {
      router.pushUrl({ url: 'pages/PostDetailPage', params: { postId: item.id } });
    })
  }

  build() {
    Column() {
      Row() {
        Text('＜')
          .fontSize(16)
          .fontColor($r('app.color.common_color_1'))
          .width(40)
          .height('100%')
          .textAlign(TextAlign.Center)
          .margin({ left: 15 })
          .onClick(() => {
            router.back();
          })
        Text('我的贴子')
          .fontSize(16)
          .fontColor($r('app.color.common_color_1'))
          .layoutWeight(1)
          .textAlign(TextAlign.Center)
          .maxLines(1)
        Blank()
          .width(40)
      }
      .width('100%')
      .height(44)
      .alignItems(VerticalAlign.Center)
      .backgroundColor($r('app.color.main_bg'))
      Divider()
        .color($r('app.color.common_color_5'))
        .strokeWidth(0.5)
        .width('100%')

      if (this.postList.length > 0) {
        List() {
          ForEach(this.postList, (item: MyPostItem) => {
            ListItem() {
              this.postItemBuilder(item)
            }
          }, (item: MyPostItem) => item.id.toString())
        }
        .width('100%')
        .layoutWeight(1)
        .scrollBar(BarState.Off)
      } else {
        Column() {
          Text('你还没发过帖子哦')
            .fontSize(14)
            .fontColor($r('app.color.common_color_3'))
            .margin({ top: 120 })
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Start)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.common_color_6'))
  }
}
