import { router } from '@kit.ArkUI';

/**
 * 社交消息页 — 1:1 复刻 message_social_item.xml：
 * 头像 40x40 + 昵称(14fp common_color_1) + 类型(14fp common_color_28) + 时间(12fp common_color_3 右侧)
 * 下一行消息内容(15fp common_color_1, paddingTop 3.5)
 */
interface SocialMessageItem {
  id: number;
  name: string;
  type: string;
  time: string;
  content: string;
  avatar: Resource;
}

@Entry
@Component
struct SocialMessagePage {
  @State messageList: SocialMessageItem[] = [
    {
      id: 1,
      name: '张小明',
      type: '评论了你的帖子',
      time: '昨天 18:20',
      content: '同学，你这个课程表分享做得真不错！',
      avatar: $r('app.media.default_avatar')
    },
    {
      id: 2,
      name: '李华',
      type: '赞了你的帖子',
      time: '11-15 20:35',
      content: '',
      avatar: $r('app.media.default_avatar')
    },
    {
      id: 3,
      name: '王芳',
      type: '回复了你的评论',
      time: '11-14 12:00',
      content: '集市那件吉他还在吗？我想买~',
      avatar: $r('app.media.default_avatar')
    },
    {
      id: 4,
      name: '陈强',
      type: '关注了你',
      time: '11-12 08:15',
      content: '',
      avatar: $r('app.media.default_avatar')
    }
  ];

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
        Text('消息')
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

      Scroll() {
        Column() {
          ForEach(this.messageList, (item: SocialMessageItem) => {
            Row() {
              Image(item.avatar)
                .width(40)
                .height(40)
                .borderRadius(20)
                .objectFit(ImageFit.Cover)
                .margin({ right: 15 })

              Column() {
                Row() {
                  Text(item.name)
                    .fontSize(14)
                    .fontColor($r('app.color.common_color_1'))
                    .maxLines(1)
                    .margin({ right: 10 })
                  Text(item.type)
                    .fontSize(14)
                    .fontColor($r('app.color.common_color_28'))
                    .maxLines(1)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                    .layoutWeight(1)
                  Text(item.time)
                    .fontSize(12)
                    .fontColor($r('app.color.common_color_3'))
                }
                .width('100%')
                .alignItems(VerticalAlign.Center)

                if (item.content.length > 0) {
                  Text(item.content)
                    .fontSize(15)
                    .fontColor($r('app.color.common_color_1'))
                    .maxLines(1)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                    .width('100%')
                    .padding({ top: 3.5 })
                }
              }
              .layoutWeight(1)
              .alignItems(HorizontalAlign.Start)
            }
            .width('100%')
            .padding({ left: 15, right: 15, top: 10, bottom: 10 })
            .alignItems(VerticalAlign.Center)
            .backgroundColor($r('app.color.main_bg'))

            Divider()
              .color($r('app.color.common_color_5'))
              .strokeWidth(0.5)
              .width('100%')
          }, (item: SocialMessageItem) => item.id.toString())
        }
        .width('100%')
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)
      .align(Alignment.Top)
      .backgroundColor($r('app.color.common_color_6'))
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.common_color_6'))
  }
}
