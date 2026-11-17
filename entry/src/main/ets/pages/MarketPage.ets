import { router } from '@kit.ArkUI';
import { TitleBar } from '../components/TitleBar';

/** 跳蚤市场商品模型 — market_activity_item.xml */
class MarketPostInfo {
  id: string;
  name: string;
  school: string;
  time: string;
  tag: string;
  tagColor: string;
  content: string;
  photos: string[];
  commentNum: string;
  likeNum: string;

  constructor(id: string, name: string, school: string, time: string, tag: string, tagColor: string,
    content: string, photos: string[], commentNum: string, likeNum: string) {
    this.id = id;
    this.name = name;
    this.school = school;
    this.time = time;
    this.tag = tag;
    this.tagColor = tagColor;
    this.content = content;
    this.photos = photos;
    this.commentNum = commentNum;
    this.likeNum = likeNum;
  }
}

function buildMarketPosts(): MarketPostInfo[] {
  return [
    new MarketPostInfo('m1', '小柚子', '数据科学与大数据技术', '10:25', '想卖', '#EB5D2A',
      '九成新iPad 2022，64G，带原装保护壳，考试周用完出，有意私聊。',
      ['app.media.social_banner_default'], '5', '32'),
    new MarketPostInfo('m2', '阿树', '软件工程', '09:40', '想买', '#18B4ED',
      '求购二手高等数学教材（同济第七版上下册），价格合理即可。',
      [], '2', '8'),
    new MarketPostInfo('m3', '南方有雨', '汉语言文学', '昨天', '已成交', '#5EC78F',
      '台灯已出，感谢大家，本帖关闭。',
      [], '12', '45'),
    new MarketPostInfo('m4', '晚风', '机械设计制造及其自动化', '昨天', '想卖', '#EB5D2A',
      '出一辆九成新山地自行车，毕业搬不走，校内自提价好商量。',
      ['app.media.social_banner_default'], '9', '21')
  ];
}

/**
 * 跳蚤市场列表 — 按反编译布局 1:1 复刻 activity_market.xml + header_market.xml + market_activity_item.xml：
 *   LinearLayout vertical
 *   - include toolbar_normal（标题“跳蚤市场”）
 *   - header_market：搜索行（EditText 高32vp + “搜索” #1B68B6）+ 12vp 灰条 +
 *     四个分类 Tab（全部#1B68B6 / 想买#18B4ED / 想卖#EB5D2A / 已成交#5EC78F）
 *   - 商品列表 market_activity_item（帖子 social_post_item + 评论/点赞行 + 头条标签）
 *   - 右下角悬浮发布按钮 market_post，边距 15
 */
@Entry
@Component
struct MarketPage {
  @State posts: MarketPostInfo[] = buildMarketPosts();
  @State searchContent: string = '';
  @State selectedIndex: number = 0;
  private tabTitles: string[] = ['全部', '想买', '想卖', '已成交'];
  private tabColors: string[] = ['#1B68B6', '#18B4ED', '#EB5D2A', '#5EC78F'];
  private tabIcons: Resource[] = [$r('app.media.icon_all'), $r('app.media.icon_buy1'),
    $r('app.media.icon_sale1'), $r('app.media.icon_closed1')];

  build() {
    Stack({ alignContent: Alignment.BottomEnd }) {
      Column() {
        TitleBar({ title: '跳蚤市场' })
        Column() {
          Row() {
            Row() {
              Image($r('app.media.search'))
                .width(16)
                .height(16)
                .margin({ left: 8 })
              TextInput({ text: this.searchContent, placeholder: '输入你想搜索的内容...' })
                .placeholderColor($r('app.color.market_search_hint'))
                .fontSize(14)
                .fontColor($r('app.color.common_color_1'))
                .backgroundColor(Color.Transparent)
                .layoutWeight(1)
                .height(30)
                .padding({ left: 9, right: 8 })
                .onChange((value: string) => {
                  this.searchContent = value;
                })
            }
            .layoutWeight(1)
            .height(32)
            .borderRadius(16)
            .backgroundColor($r('app.color.common_color_6'))
            .alignItems(VerticalAlign.Center)

            Text('搜索')
              .fontSize(14)
              .fontColor($r('app.color.color_all'))
              .width(25)
              .textAlign(TextAlign.Center)
              .margin({ left: 8 })
          }
          .width('100%')
          .height(44)
          .padding({ left: 15, right: 10 })
          .alignItems(VerticalAlign.Center)
          .backgroundColor($r('app.color.white'))

          Blank()
            .width('100%')
            .height(12)
            .backgroundColor($r('app.color.common_color_6'))

          Row() {
            ForEach(this.tabTitles, (tab: string, index: number) => {
              Column() {
                Image(this.tabIcons[index])
                  .width(24)
                  .height(24)
                Text(tab)
                  .fontSize(12)
                  .fontColor(index === this.selectedIndex ? this.tabColors[index] : $r('app.color.common_color_3'))
                  .margin({ top: 3 })
              }
              .layoutWeight(1)
              .padding({ top: 8, bottom: 8 })
              .onClick(() => {
                this.selectedIndex = index;
              })
            }, (tab: string, index: number) => tab + index)
          }
          .width('100%')
          .backgroundColor($r('app.color.white'))

          Divider()
            .strokeWidth(1)
            .color($r('app.color.common_color_6'))
        }
        .width('100%')
        .backgroundColor($r('app.color.main_bg'))

        List({ space: 5 }) {
          ForEach(this.posts, (post: MarketPostInfo) => {
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
                        Text(post.name)
                          .fontSize(16)
                          .fontColor($r('app.color.common_color_1'))
                          .maxLines(1)
                          .textOverflow({ overflow: TextOverflow.Ellipsis })
                          .layoutWeight(1)
                        Text(post.tag)
                          .fontSize(13)
                          .fontColor($r('app.color.white'))
                          .padding({ left: 5, right: 5, top: 1, bottom: 1 })
                          .borderRadius(4)
                          .backgroundColor(post.tagColor)
                      }
                      .width('100%')
                      Row() {
                        Text(post.school)
                          .fontSize(12)
                          .fontColor($r('app.color.common_color_3'))
                          .layoutWeight(1)
                        Text(post.time)
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

                  Text(post.content)
                    .fontSize(15)
                    .fontColor($r('app.color.common_color_1'))
                    .padding({ top: 5, bottom: 4 })
                    .width('100%')

                  if (post.photos.length > 0) {
                    Flex({ wrap: FlexWrap.Wrap }) {
                      ForEach(post.photos, (photo: string) => {
                        Image($r(photo))
                          .width(105)
                          .height(105)
                          .objectFit(ImageFit.Cover)
                          .borderRadius(3)
                          .margin({ right: 5, bottom: 5 })
                      }, (photo: string) => post.id + photo)
                    }
                    .width('100%')
                    .padding({ top: 9 })
                  }
                }
                .width('100%')
                .padding({ left: 15, right: 15, top: 10, bottom: 7 })
                .backgroundColor($r('app.color.main_bg'))

                Blank()
                  .width('100%')
                  .height(2)
                Divider()
                  .color($r('app.color.common_color_5'))
                  .strokeWidth(0.5)

                Row() {
                  Image($r('app.media.social_comment'))
                    .width(18)
                    .height(18)
                  Text(post.commentNum)
                    .fontSize(15)
                    .fontColor($r('app.color.common_color_3'))
                    .margin({ left: 7, right: 40 })
                  Image($r('app.media.social_like'))
                    .width(18)
                    .height(18)
                  Text(post.likeNum)
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
              }
              .onClick(() => {
                router.pushUrl({ url: 'pages/MarkDetailPage' });
              })
            }
          }, (post: MarketPostInfo) => post.id)
        }
        .width('100%')
        .layoutWeight(1)
        .backgroundColor($r('app.color.common_color_6'))
      }
      .width('100%')
      .height('100%')

      Image($r('app.media.market_post'))
        .width(56)
        .height(56)
        .margin({ right: 15, bottom: 15 })
        .onClick(() => {
          router.pushUrl({ url: 'pages/MarketPostPage' });
        })
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.main_bg'))
  }
}
