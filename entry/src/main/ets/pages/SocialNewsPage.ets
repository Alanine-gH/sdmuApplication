import { router } from '@kit.ArkUI';
import { TitleBar } from '../components/TitleBar';

/** 校园动态帖子模型 — social_post_item.xml */
class SocialNewsPost {
  id: string;
  name: string;
  school: string;
  time: string;
  content: string;
  photos: string[];

  constructor(id: string, name: string, school: string, time: string, content: string, photos: string[]) {
    this.id = id;
    this.name = name;
    this.school = school;
    this.time = time;
    this.content = content;
    this.photos = photos;
  }
}

function buildSocialNewsPosts(): SocialNewsPost[] {
  return [
    new SocialNewsPost('n1', '小柚子', '数据科学与大数据技术', '10:25', '今天的银杏大道太美了，大家快去打卡拍照！',
      ['app.media.social_banner_default']),
    new SocialNewsPost('n2', '阿树', '软件工程', '09:40', '求推荐几本机器学习入门书籍，最好有配套代码练习的～', []),
    new SocialNewsPost('n3', '南方有雨', '汉语言文学', '昨天', '学校话剧社招新啦，喜欢表演的同学不要错过！',
      ['app.media.social_banner_default', 'app.media.social_banner_default']),
    new SocialNewsPost('n4', '柚子茶', '会计学', '昨天', '校园歌手大赛报名通道已开启，欢迎热爱唱歌的同学报名参加。',
      []),
    new SocialNewsPost('n5', '晚风', '机械设计制造及其自动化', '前天', '考研自习室占座太严重了，希望学校能加强管理。',
      [])
  ];
}

/**
 * 校园动态列表 — 按源布局 1:1 复刻 social_news_activity.xml：
 *   RelativeLayout（背景 common_color_6）
 *   - include toolbar_normal（标题“校园动态”）
 *   - common_refresh_lv_rl：帖子列表 social_post_item
 *   - 底部操作栏：评论(social_post) / 点赞(social_like)，px_to_sp_24=12fp common_color_31，
 *     padding 40/12/40/12，中间竖分隔线 common_color_6
 */
@Entry
@Component
struct SocialNewsPage {
  @State posts: SocialNewsPost[] = buildSocialNewsPosts();

  build() {
    Column() {
      TitleBar({ title: '校园动态' })
      List({ space: 5 }) {
        ForEach(this.posts, (post: SocialNewsPost) => {
          ListItem() {
            Column() {
              Column() {
                Row() {
                  Image($r('app.media.default_avatar'))
                    .width(40)
                    .height(40)
                    .borderRadius(20)
                  Column() {
                    Text(post.name)
                      .fontSize(16)
                      .fontColor($r('app.color.common_color_1'))
                      .maxLines(1)
                      .textOverflow({ overflow: TextOverflow.Ellipsis })
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
                    }, (photo: string) => post.id + photo)
                  }
                  .width('100%')
                  .padding({ top: 9 })
                }
              }
              .width('100%')
              .padding({ left: 15, right: 15, top: 10, bottom: 7 })
              .backgroundColor($r('app.color.main_bg'))
              .onClick(() => {
                router.pushUrl({ url: 'pages/PostDetailPage' });
              })
            }
          }
        }, (post: SocialNewsPost) => post.id)
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
