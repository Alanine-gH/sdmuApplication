import { router } from '@kit.ArkUI';
import { TitleBar } from '../components/TitleBar';

/** 社交帖子模型 — social_post_item.xml */
export class SocialPostInfo {
  id: string;
  name: string;
  school: string;
  time: string;
  content: string;
  photos: string[];
  commentNum: string;
  likeNum: string;

  constructor(id: string, name: string, school: string, time: string, content: string,
    photos: string[], commentNum: string, likeNum: string) {
    this.id = id;
    this.name = name;
    this.school = school;
    this.time = time;
    this.content = content;
    this.photos = photos;
    this.commentNum = commentNum;
    this.likeNum = likeNum;
  }
}

/** 社交阅读推荐模型 — social_read_item.xml */
export class SocialReadInfo {
  id: string;
  title: string;
  time: string;
  readNum: string;

  constructor(id: string, title: string, time: string, readNum: string) {
    this.id = id;
    this.title = title;
    this.time = time;
    this.readNum = readNum;
  }
}

function buildSocialReads(): SocialReadInfo[] {
  return [
    new SocialReadInfo('r1', '校园食堂新菜品上线，快来尝鲜', '2026-11-16', '3280'),
    new SocialReadInfo('r2', '图书馆开放时间调整公告', '2026-11-15', '1560')
  ];
}

function buildSocialPosts(): SocialPostInfo[] {
  return [
    new SocialPostInfo('p1', '小柚子', '数据科学与大数据技术', '10:25', '今天的银杏大道太美了，大家快去打卡拍照！',
      ['app.media.social_banner_default'], '12', '86'),
    new SocialPostInfo('p2', '阿树', '软件工程', '09:40', '求推荐几本机器学习入门书籍，最好有配套代码练习的～',
      [], '8', '23'),
    new SocialPostInfo('p3', '南方有雨', '汉语言文学', '昨天', '学校话剧社招新啦，喜欢表演的同学不要错过！',
      ['app.media.social_banner_default', 'app.media.social_banner_default'], '35', '128')
  ];
}

/**
 * 社交主页 — 按源布局 1:1 复刻 social_main_activity.xml + social_fragment.xml
 * (social_fragment_head.xml + social_news_head.xml + social_post_item.xml)：
 *   LinearLayout vertical
 *   - toolbar_normal（标题“校圈”）
 *   - 轮播图 RelativeLayout px_to_dip_260=130vp + 指示点
 *   - 入口行：最新动态 / 跳蚤市场（padding 15，图标+文字）
 *   - social_news_head：阅读 more 行 + social_read_item + 校园动态入口
 *   - 帖子列表 social_post_item
 */
@Entry
@Component
struct SocialHomePage {
  @State posts: SocialPostInfo[] = buildSocialPosts();
  @State reads: SocialReadInfo[] = buildSocialReads();
  @State bannerIndex: number = 0;

  build() {
    Column() {
      TitleBar({ title: '校圈' })
      Scroll() {
        Column() {
          Stack({ alignContent: Alignment.BottomStart }) {
            Swiper() {
              Image($r('app.media.social_banner_default'))
                .width('100%')
                .height('100%')
                .objectFit(ImageFit.Cover)
            }
            .width('100%')
            .height(130)
            .autoPlay(true)
            .indicator(false)

            Row() {
              Blank()
                .width(7.5)
                .height(3)
                .borderRadius(1.5)
                .backgroundColor(this.bannerIndex === 0 ? $r('app.color.white') : $r('app.color.common_color_24'))
              Blank()
                .width(5)
              Blank()
                .width(7.5)
                .height(3)
                .borderRadius(1.5)
                .backgroundColor(this.bannerIndex === 1 ? $r('app.color.white') : $r('app.color.common_color_24'))
            }
            .margin({ left: 5, bottom: 7.5 })
          }
          .width('100%')
          .height(130)

          Row() {
            Row() {
              Image($r('app.media.socialnew_news'))
                .width(34)
                .height(34)
              Text('最新动态')
                .fontSize(12)
                .fontColor($r('app.color.common_color_1'))
                .margin({ left: 14.5, right: 10 })
            }
            .layoutWeight(1)
            .justifyContent(FlexAlign.Center)
            .height('100%')

            Divider()
              .vertical(true)
              .strokeWidth(0.5)
              .height(28)
              .color($r('app.color.common_color_5'))

            Row() {
              Image($r('app.media.social_market'))
                .width(34)
                .height(34)
              Text('跳蚤市场')
                .fontSize(12)
                .fontColor($r('app.color.common_color_1'))
                .margin({ left: 14.5, right: 10 })
            }
            .layoutWeight(1)
            .justifyContent(FlexAlign.Center)
            .height('100%')
            .onClick(() => {
              router.pushUrl({ url: 'pages/MarketPage' });
            })
          }
          .width('100%')
          .height(48)
          .padding({ left: 15, right: 15 })
          .backgroundColor($r('app.color.main_bg'))

          Divider()
            .color($r('app.color.common_color_5'))
            .strokeWidth(0.5)
          Divider()
            .color($r('app.color.common_color_6'))
            .strokeWidth(2)
          Divider()
            .color($r('app.color.common_color_5'))
            .strokeWidth(0.5)

          Row() {
            Image($r('app.media.social_reading'))
              .width(24)
              .height(24)
              .margin({ top: 1 })
            Text('阅读')
              .fontSize(14)
              .fontColor($r('app.color.common_color_3'))
              .layoutWeight(1)
              .margin({ left: 5 })
            Text('更多')
              .fontSize(14)
              .fontColor($r('app.color.common_color_4'))
            Image($r('app.media.arrow_right2'))
              .width(12)
              .height(12)
              .margin({ top: 1, left: 2 })
          }
          .width('100%')
          .padding({ left: 15, right: 15, top: 10, bottom: 10 })

          Divider()
            .color($r('app.color.common_color_5'))
            .strokeWidth(0.5)

          ForEach(this.reads, (read: SocialReadInfo) => {
            Row() {
              Image($r('app.media.social_banner_default'))
                .width(110)
                .height(70)
                .objectFit(ImageFit.Fill)
                .borderRadius(4)
              Column() {
                Text(read.title)
                  .fontSize(16)
                  .fontColor($r('app.color.common_color_1'))
                  .maxLines(2)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
                  .padding({ left: 15 })
                Row() {
                  Text(read.time)
                    .fontSize(14)
                    .fontColor($r('app.color.common_color_3'))
                    .layoutWeight(1)
                    .padding({ left: 15 })
                  Text(read.readNum + ' 阅读')
                    .fontSize(14)
                    .fontColor($r('app.color.common_color_3'))
                    .textAlign(TextAlign.End)
                    .layoutWeight(1)
                }
                .width('100%')
                .padding({ top: 10 })
                .alignItems(VerticalAlign.Bottom)
              }
              .layoutWeight(1)
              .height(70)
            }
            .width('100%')
            .alignItems(VerticalAlign.Center)
            .padding({ left: 15, right: 15, top: 10, bottom: 10 })
            .backgroundColor($r('app.color.main_bg'))
          }, (read: SocialReadInfo) => read.id)

          Divider()
            .color($r('app.color.common_color_5'))
            .strokeWidth(0.5)

          Row() {
            Image($r('app.media.social_location'))
              .width(24)
              .height(24)
              .margin({ top: 1 })
            Text('校园动态')
              .fontSize(14)
              .fontColor($r('app.color.common_color_3'))
              .margin({ left: 5 })
          }
          .width('100%')
          .padding({ left: 15, right: 15, top: 10, bottom: 10 })
          .onClick(() => {
            router.pushUrl({ url: 'pages/SocialNewsPage' });
          })

          Divider()
            .color($r('app.color.common_color_5'))
            .strokeWidth(0.5)

          ForEach(this.posts, (post: SocialPostInfo) => {
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
                    }
                    .width('100%')
                    Row() {
                      Text(post.school)
                        .fontSize(12)
                        .fontColor($r('app.color.common_color_3'))
                        .layoutWeight(1)
                        .maxLines(1)
                        .textOverflow({ overflow: TextOverflow.Ellipsis })
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
                    }, (photo: string) => photo)
                  }
                  .width('100%')
                  .padding({ top: 9 })
                }
              }
              .width('100%')
              .padding({ left: 15, right: 15, top: 10, bottom: 7 })
              .backgroundColor($r('app.color.main_bg'))

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
              router.pushUrl({ url: 'pages/PostDetailPage' });
            })
          }, (post: SocialPostInfo) => post.id)
        }
      }
      .scrollBar(BarState.Off)
      .layoutWeight(1)
      .backgroundColor($r('app.color.common_color_6'))
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.main_bg'))
  }
}
