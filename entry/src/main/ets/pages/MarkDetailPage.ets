import { TitleBar } from '../components/TitleBar';

/** 市场详情评论模型 — social_comment_item.xml */
class MarketDetailComment {
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

function buildMarketComments(): MarketDetailComment[] {
  return [
    new MarketDetailComment('c1', '阿树', '软件工程', '10:25', '还在吗？可以便宜一点吗？'),
    new MarketDetailComment('c2', '南方有雨', '汉语言文学', '11:02', '求发票和充电器照片～'),
    new MarketDetailComment('c3', '晚风', '机械设计制造及其自动化', '11:30', '想要，明天可以面交吗？'),
    new MarketDetailComment('c4', '柚子茶', '会计学', '12:10', '已经私信你了，请查收。')
  ];
}

/**
 * 市场商品详情 — 按源布局 1:1 复刻 market_activity_item.xml + social_post_item.xml + social_comment_item.xml：
 *   LinearLayout vertical
 *   - include toolbar_normal（标题“商品详情”）
 *   - 商品内容 social_post_item（头像40vp、昵称16fp、“想卖”标签、正文15fp、九图）
 *   - 评论/点赞行 px_to_sp_30=15fp common_color_3，padding 15/10，右侧更多
 *   - 评论列表 social_comment_item
 */
@Entry
@Component
struct MarkDetailPage {
  @State postName: string = '小柚子';
  @State postSchool: string = '数据科学与大数据技术';
  @State postTime: string = '10:25';
  @State postTag: string = '想卖';
  @State postContent: string = '九成新iPad 2022，64G，带原装保护壳，考试周用完出，有意私聊。电池健康95%，无划痕，可当面验机。';
  @State postPhotos: string[] = ['app.media.social_banner_default', 'app.media.social_banner_default',
    'app.media.social_banner_default'];
  @State commentNum: string = '5';
  @State likeNum: string = '32';
  @State comments: MarketDetailComment[] = buildMarketComments();

  build() {
    Column() {
      TitleBar({ title: '商品详情' })
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
                  Row() {
                    Text(this.postName)
                      .fontSize(16)
                      .fontColor($r('app.color.common_color_1'))
                      .maxLines(1)
                      .textOverflow({ overflow: TextOverflow.Ellipsis })
                      .layoutWeight(1)
                    Text(this.postTag)
                      .fontSize(13)
                      .fontColor($r('app.color.white'))
                      .padding({ left: 5, right: 5, top: 1, bottom: 1 })
                      .borderRadius(4)
                      .backgroundColor($r('app.color.market_sale_color'))
                  }
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

              Text(this.postContent)
                .fontSize(15)
                .fontColor($r('app.color.common_color_1'))
                .padding({ top: 5, bottom: 4 })
                .width('100%')

              Flex({ wrap: FlexWrap.Wrap }) {
                ForEach(this.postPhotos, (photo: string, idx: number) => {
                  Image($r(photo))
                    .width(105)
                    .height(105)
                    .objectFit(ImageFit.Cover)
                    .borderRadius(3)
                    .margin({ right: 5, bottom: 5 })
                }, (photo: string, idx: number) => this.postName + idx)
              }
              .width('100%')
              .padding({ top: 9 })
            }
            .width('100%')
            .padding({ left: 15, right: 15, top: 10, bottom: 7 })
            .backgroundColor($r('app.color.main_bg'))
            .onClick(() => {
              this.getUIContext().getPromptAction().showToast({ message: '商品信息已刷新' });
            })

            Row() {
              Image($r('app.media.social_comment'))
                .width(18)
                .height(18)
              Text(this.commentNum)
                .fontSize(15)
                .fontColor($r('app.color.common_color_3'))
                .margin({ left: 7, right: 40 })
              Image($r('app.media.social_like'))
                .width(18)
                .height(18)
              Text(this.likeNum)
                .fontSize(15)
                .fontColor($r('app.color.common_color_3'))
                .margin({ left: 7 })
              Blank()
              Image($r('app.media.social_more'))
                .width(18)
                .height(18)
            }
            .width('100%')
            .padding({ left: 15, right: 15, top: 10, bottom: 10 })
            .backgroundColor($r('app.color.main_bg'))

            Divider()
              .color($r('app.color.common_color_5'))
              .strokeWidth(0.5)

            Text('全部评论 (' + this.comments.length + ')')
              .fontSize(13)
              .fontColor($r('app.color.common_color_32'))
              .padding({ left: 15, right: 15, top: 12, bottom: 12 })
              .width('100%')
              .backgroundColor($r('app.color.main_bg'))
          }
          .backgroundColor($r('app.color.main_bg'))
        }

        ForEach(this.comments, (comment: MarketDetailComment) => {
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
        }, (comment: MarketDetailComment) => comment.id)
      }
      .width('100%')
      .layoutWeight(1)
      .backgroundColor($r('app.color.common_color_6'))
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.common_color_6'))
  }
}
