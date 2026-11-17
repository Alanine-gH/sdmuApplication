import { router } from '@kit.ArkUI';
import { TitleBar } from '../components/TitleBar';

/** 用户详情帖子模型 — social_post_item.xml */
class UserDetailPost {
  id: string;
  time: string;
  content: string;
  photos: string[];
  commentNum: string;
  likeNum: string;

  constructor(id: string, time: string, content: string, photos: string[], commentNum: string, likeNum: string) {
    this.id = id;
    this.time = time;
    this.content = content;
    this.photos = photos;
    this.commentNum = commentNum;
    this.likeNum = likeNum;
  }
}

function buildUserPosts(): UserDetailPost[] {
  return [
    new UserDetailPost('up1', '10:25', '今天的银杏大道太美了，大家快去打卡拍照！',
      ['app.media.social_banner_default'], '12', '86'),
    new UserDetailPost('up2', '昨天', '求推荐几本机器学习入门书籍，最好有配套代码练习的～', [], '8', '23'),
    new UserDetailPost('up3', '前天', '学校话剧社招新啦，喜欢表演的同学不要错过！', [], '35', '128')
  ];
}

/**
 * 用户详情 — 按源布局 1:1 复刻 social_fragment_page.xml + social_post_item.xml：
 *   LinearLayout vertical
 *   - include toolbar_normal（标题“个人主页”）
 *   - 头部：头像 px_to_dip_100=50vp 居中 + 昵称16fp + 院系/学校12fp common_color_3 + 加好友按钮
 *   - 三层分隔线
 *   - TA 的帖子列表 social_post_item + 评论/点赞行
 */
@Entry
@Component
struct UserDetailPage {
  @State userName: string = '小柚子';
  @State userSex: string = '女';
  @State userSchool: string = '信息科学与技术学院 · 数据科学与大数据技术';
  @State isFriend: boolean = false;
  @State posts: UserDetailPost[] = buildUserPosts();

  build() {
    Column() {
      TitleBar({ title: '个人主页' })
      Scroll() {
        Column() {
          Column() {
            Image($r('app.media.default_avatar'))
              .width(50)
              .height(50)
              .borderRadius(25)
              .margin({ top: 20 })
            Row() {
              Text(this.userName)
                .fontSize(16)
                .fontColor($r('app.color.common_color_1'))
              Text(this.userSex)
                .fontSize(12)
                .fontColor(this.userSex === '女' ? '#FF6C6C' : '#18B4ED')
                .margin({ left: 4 })
            }
            .margin({ top: 8 })

            Text(this.userSchool)
              .fontSize(12)
              .fontColor($r('app.color.common_color_3'))
              .margin({ top: 4 })

            Text(this.isFriend ? '已添加' : '+ 加好友')
              .fontSize(13)
              .fontColor(this.isFriend ? $r('app.color.common_color_3') : $r('app.color.white'))
              .padding({ left: 14, right: 14, top: 5, bottom: 5 })
              .borderRadius(14)
              .backgroundColor(this.isFriend ? $r('app.color.main_bg') : $r('app.color.ybg_blue'))
              .border({ width: 0.5, color: this.isFriend ? $r('app.color.common_color_5') : Color.Transparent })
              .margin({ top: 12, bottom: 20 })
              .onClick(() => {
                this.isFriend = !this.isFriend;
              })
          }
          .width('100%')
          .alignItems(HorizontalAlign.Center)
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

          ForEach(this.posts, (post: UserDetailPost) => {
            Column() {
              Column() {
                Row() {
                  Image($r('app.media.default_avatar'))
                    .width(40)
                    .height(40)
                    .borderRadius(20)
                  Column() {
                    Text(this.userName)
                      .fontSize(16)
                      .fontColor($r('app.color.common_color_1'))
                      .width('100%')
                    Row() {
                      Text(this.userSchool)
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
              .onClick(() => {
                router.pushUrl({ url: 'pages/PostDetailPage' });
              })

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
          }, (post: UserDetailPost) => post.id)
        }
      }
      .scrollBar(BarState.Off)
      .layoutWeight(1)
      .backgroundColor($r('app.color.common_color_6'))
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.common_color_6'))
  }
}
