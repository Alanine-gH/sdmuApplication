import { TitleBar } from '../components/TitleBar';

/** 评论模型 — social_comment_item.xml */
class SocialDetailComment {
  id: string;
  name: string;
  school: string;
  time: string;
  content: string;

  constructor(id: string, name: string, school: string, time: string, content: string) {
    this.id = id;
    this.name = name;
    this.school = school;
    this.time = time;
    this.content = content;
  }
}

function buildDetailComments(): SocialDetailComment[] {
  return [
    new SocialDetailComment('c1', '小柚子', '数据科学与大数据技术', '10:25', '太美了，我也去过，拍照真的出片！'),
    new SocialDetailComment('c2', '阿树', '软件工程', '11:02', '在哪里呀？求定位～'),
    new SocialDetailComment('c3', '南方有雨', '汉语言文学', '11:30', '收藏了，周末就去！'),
    new SocialDetailComment('c4', '晚风', '机械设计制造及其自动化', '12:10', '这条银杏大道是我们学校最美的风景线。')
  ];
}

/**
 * 帖子详情 — 按源布局 1:1 复刻 social_post_detail_head.xml + social_comment_item.xml：
 *   LinearLayout vertical（背景 main_bg）
 *   - 帖子内容 social_post_item（头像40vp、昵称16fp、时间/学校12fp、正文15fp、九图）
 *   - 点赞数行：social_like_select + px_to_sp_27=13.5fp，左边距15
 *   - 正文 EmojiconTextView px_to_sp_26=13fp common_color_1 padding 15/5
 *   - 间隔 px_to_dip_20=10vp + 三层分隔线
 *   - 评论数 px_to_sp_26=13fp common_color_32 padding 15/12
 *   - 评论列表 social_comment_item（头像40vp，昵称14fp，学校/时间12fp，内容15fp）
 */
@Entry
@Component
struct PostDetailPage {
  @State postName: string = '小柚子';
  @State postSchool: string = '数据科学与大数据技术';
  @State postTime: string = '10:25';
  @State postTitle: string = '今天的银杏大道太美了，大家快去打卡拍照！金黄的树叶铺满整条路，随手一拍都是大片，强烈推荐大家周末去走走，记得带上相机和好朋友～';
  @State postPhotos: string[] = ['app.media.social_banner_default', 'app.media.social_banner_default',
    'app.media.social_banner_default'];
  @State likeNum: string = '86';
  @State comments: SocialDetailComment[] = buildDetailComments();

  build() {
    Column() {
      TitleBar({ title: '帖子详情' })
      List({ space: 0 }) {
        ListItem() {
          Column() {
            Column() {
              Row() {
                Image($r('app.media.default_avatar'))
                  .width(40)
                  .height(40)
                  .borderRadius(20)
                Column() {
                  Text(this.postName)
                    .fontSize(16)
                    .fontColor($r('app.color.common_color_1'))
                    .maxLines(1)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                    .width('100%')
                  Row() {
                    Text(this.postSchool)
                      .fontSize(12)
                      .fontColor($r('app.color.common_color_3'))
                      .layoutWeight(1)
                    Text(this.postTime)
                      .fontSize(12)
                      .fontColor($r('app.color.common_color_3'))
                  }
                  .width('100%')
                  .margin({ top: 2 })
                }
                .layoutWeight(1)
                .height(40)
                .padding({ left: 5 })
                .justifyContent(FlexAlign.Center)
              }
              .width('100%')
              .margin({ bottom: 5 })

              Text(this.postTitle)
                .fontSize(15)
                .fontColor($r('app.color.common_color_1'))
                .padding({ top: 5, bottom: 4 })
                .width('100%')

              Flex({ wrap: FlexWrap.Wrap }) {
                ForEach(this.postPhotos, (photo: string) => {
                  Image($r(photo))
                    .width(105)
                    .height(105)
                    .objectFit(ImageFit.Cover)
                    .borderRadius(3)
                    .margin({ right: 5, bottom: 5 })
                    .onClick(() => {
                      this.getUIContext().getPromptAction().showToast({ message: '查看大图' });
                    })
                }, (photo: string, idx: number) => this.postName + idx)
              }
              .width('100%')
              .padding({ top: 9 })
            }
            .width('100%')
            .padding({ left: 15, right: 15, top: 10, bottom: 7 })
            .backgroundColor($r('app.color.main_bg'))

            Row() {
              Image($r('app.media.social_like_select'))
                .width(16)
                .height(16)
              Text(this.likeNum)
                .fontSize(13.5)
                .fontColor($r('app.color.common_color_1'))
                .margin({ left: 10 })
            }
            .width('100%')
            .padding({ left: 15, top: 8, bottom: 8 })

            Text(this.postTitle)
              .fontSize(13)
              .fontColor($r('app.color.common_color_1'))
              .padding({ left: 15, right: 15, top: 5 })
              .width('100%')

            Blank()
              .height(10)
            Divider()
              .color($r('app.color.common_color_5'))
              .strokeWidth(0.5)
            Divider()
              .color($r('app.color.common_color_6'))
              .strokeWidth(2)
            Divider()
              .color($r('app.color.common_color_5'))
              .strokeWidth(0.5)

            Text('全部评论 (' + this.comments.length + ')')
              .fontSize(13)
              .fontColor($r('app.color.common_color_32'))
              .padding({ left: 15, right: 15, top: 12, bottom: 12 })
              .width('100%')
          }
          .backgroundColor($r('app.color.main_bg'))
        }

        ForEach(this.comments, (comment: SocialDetailComment) => {
          ListItem() {
            Row() {
              Image($r('app.media.default_avatar'))
                .width(40)
                .height(40)
                .borderRadius(20)
              Column() {
                Text(comment.name)
                  .fontSize(14)
                  .fontColor($r('app.color.common_color_2'))
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
                  .width('100%')
                Row() {
                  Text(comment.school)
                    .fontSize(12)
                    .fontColor($r('app.color.common_color_3'))
                  Blank()
                  Text(comment.time)
                    .fontSize(12)
                    .fontColor($r('app.color.common_color_3'))
                    .padding({ left: 5 })
                }
                .width('100%')
                Text(comment.content)
                  .fontSize(15)
                  .fontColor($r('app.color.common_color_1'))
                  .width('100%')
                  .margin({ top: 8 })
              }
              .layoutWeight(1)
              .padding({ left: 5 })
            }
            .width('100%')
            .padding({ left: 15, right: 15, top: 10, bottom: 10 })
            .backgroundColor($r('app.color.main_bg'))
            .onClick(() => {
              this.getUIContext().getPromptAction().showToast({ message: '回复功能' });
            })
          }
        }, (comment: SocialDetailComment) => comment.id)
      }
      .width('100%')
      .layoutWeight(1)
      .backgroundColor($r('app.color.common_color_6'))

      Column() {
        Divider()
          .color($r('app.color.common_color_5'))
          .strokeWidth(0.5)
        Row() {
          Row() {
            Image($r('app.media.social_post'))
              .width(18)
              .height(18)
            Text('评论')
              .fontSize(12)
              .fontColor($r('app.color.common_color_31'))
              .margin({ left: 12 })
          }
          .layoutWeight(1)
          .justifyContent(FlexAlign.Center)
          .padding({ top: 12, bottom: 12 })

          Divider()
            .vertical(true)
            .strokeWidth(0.5)
            .height(30)
            .color($r('app.color.common_color_6'))
            .margin({ top: 5, bottom: 5 })

          Row() {
            Image($r('app.media.social_like'))
              .width(18)
              .height(18)
            Text('点赞')
              .fontSize(12)
              .fontColor($r('app.color.common_color_31'))
              .margin({ left: 12 })
          }
          .layoutWeight(1)
          .justifyContent(FlexAlign.Center)
          .padding({ top: 12, bottom: 12 })
        }
        .width('100%')
        .alignItems(VerticalAlign.Center)
        .backgroundColor($r('app.color.main_bg'))
      }
      .width('100%')
      .backgroundColor($r('app.color.main_bg'))
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.common_color_6'))
  }
}
