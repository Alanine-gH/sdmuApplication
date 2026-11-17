import { TitleBar } from '../components/TitleBar';

/** 发布页已选照片模型 — post_publish_chosen_photo_item.xml */
class PostPublishPhoto {
  id: string;
  res: string;

  constructor(id: string, res: string) {
    this.id = id;
    this.res = res;
  }
}

/**
 * 发布帖子 — 按反编译布局 1:1 复刻 social_post_publish.xml + social_post_publish_bottom_bar.xml：
 *   RelativeLayout（背景 ybg_white）
 *   - include toolbar_normal（标题“发布帖子”）
 *   - ScrollView：LinearLayout padding 15/14/15/12
 *     - EmojiconEditText 6行，hint色 common_color_4，margin px_to_dip_12=6vp
 *     - GridView 4列，间距 px_to_dip_10=5vp，padding 6
 *   - 底部栏：分隔线 + 图片(school_edit_pic)/表情(school_edit_emotion) 按钮行 padding 15/4 + 分隔线
 */
@Entry
@Component
struct PostPublishPage {
  @State content: string = '';
  @State photos: PostPublishPhoto[] = [
    new PostPublishPhoto('ph1', 'app.media.social_banner_default'),
    new PostPublishPhoto('ph2', 'app.media.social_banner_default')
  ];

  build() {
    Column() {
      TitleBar({ title: '发布帖子' })
      Scroll() {
        Column() {
          TextArea({ text: this.content, placeholder: '说点什么吧...' })
            .placeholderColor($r('app.color.common_color_4'))
            .fontSize(16)
            .fontColor($r('app.color.common_color_1'))
            .backgroundColor(Color.Transparent)
            .width('100%')
            .margin(6)
            .constraintSize({ minHeight: 120 })
          Grid() {
            ForEach(this.photos, (photo: PostPublishPhoto) => {
              GridItem() {
                Image($r(photo.res))
                  .width('100%')
                  .height(82)
                  .objectFit(ImageFit.Cover)
                  .borderRadius(3)
              }
            }, (photo: PostPublishPhoto) => photo.id)
            GridItem() {
              Column() {
                Text('+')
                  .fontSize(28)
                  .fontColor($r('app.color.common_color_4'))
              }
              .width('100%')
              .height(82)
              .justifyContent(FlexAlign.Center)
              .border({ width: 0.5, color: $r('app.color.common_color_5') })
              .borderRadius(3)
            }
          }
          .columnsTemplate('1fr 1fr 1fr 1fr')
          .columnsGap(5)
          .rowsGap(5)
          .width('100%')
          .padding(6)
          .height(this.photos.length < 4 ? 94 : 188)
        }
        .width('100%')
        .padding({ left: 15, right: 15, top: 14, bottom: 12 })
        .alignItems(HorizontalAlign.Start)
      }
      .scrollBar(BarState.Off)
      .layoutWeight(1)
      .backgroundColor($r('app.color.ybg_white'))

      Column() {
        Divider()
          .color($r('app.color.common_color_5'))
          .strokeWidth(0.5)
        Row() {
          Image($r('app.media.school_edit_pic'))
            .width(24)
            .height(24)
            .margin({ right: 20 })
          Image($r('app.media.school_edit_emotion'))
            .width(24)
            .height(24)
        }
        .width('100%')
        .padding({ left: 15, right: 15, top: 4, bottom: 4 })
        .alignItems(VerticalAlign.Center)
        .backgroundColor($r('app.color.ybg_white'))
        Divider()
          .color($r('app.color.common_color_5'))
          .strokeWidth(0.5)
      }
      .width('100%')
      .backgroundColor($r('app.color.ybg_white'))
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.ybg_white'))
  }
}
