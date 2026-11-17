import { TitleBar } from '../components/TitleBar';

/** 市场发布已选照片模型 — market_post_publish_chosen_photo_item.xml */
class MarketPublishPhoto {
  id: string;
  res: string;

  constructor(id: string, res: string) {
    this.id = id;
    this.res = res;
  }
}

/**
 * 市场发布 — 按反编译布局 1:1 复刻 activity_market_post.xml + social_post_publish_bottom_bar.xml：
 *   RelativeLayout（背景 #F0F0F0）
 *   - include toolbar_normal（标题“发布商品”）
 *   - ScrollView：白色卡片（minHeight 179vp，padding 15/14/15/12）
 *     - EmojiconEditText 6行 hint“输入商品描述...” maxLength 500
 *     - GridView 4列，间距 px_to_dip_16=8vp
 *   - 底部栏：图片/表情按钮行
 *   - 发布按钮：高 px_to_dip_88=44vp，margin 15/25/15/12.5，白字17fp
 */
@Entry
@Component
struct MarketPostPage {
  @State content: string = '';
  @State photos: MarketPublishPhoto[] = [
    new MarketPublishPhoto('ph1', 'app.media.social_banner_default'),
    new MarketPublishPhoto('ph2', 'app.media.social_banner_default')
  ];

  build() {
    Column() {
      TitleBar({ title: '发布商品' })
      Scroll() {
        Column() {
          Column() {
            TextArea({ text: this.content, placeholder: '输入商品描述...' })
              .placeholderColor($r('app.color.common_color_4'))
              .fontSize(16)
              .fontColor($r('app.color.common_color_1'))
              .maxLength(500)
              .backgroundColor(Color.Transparent)
              .width('100%')
              .constraintSize({ minHeight: 120 })
            Grid() {
              ForEach(this.photos, (photo: MarketPublishPhoto) => {
                GridItem() {
                  Image($r(photo.res))
                    .width('100%')
                    .height(80)
                    .objectFit(ImageFit.Cover)
                    .borderRadius(3)
                }
              }, (photo: MarketPublishPhoto) => photo.id)
              GridItem() {
                Column() {
                  Text('+')
                    .fontSize(28)
                    .fontColor($r('app.color.common_color_4'))
                }
                .width('100%')
                .height(80)
                .justifyContent(FlexAlign.Center)
                .border({ width: 0.5, color: $r('app.color.common_color_5') })
                .borderRadius(3)
              }
            }
            .columnsTemplate('1fr 1fr 1fr 1fr')
            .columnsGap(8)
            .rowsGap(8)
            .width('100%')
            .margin({ top: 10 })
          }
          .width('100%')
          .backgroundColor($r('app.color.white'))
          .padding({ left: 15, right: 15, top: 14, bottom: 12 })
          .constraintSize({ minHeight: 179 })

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
            Divider()
              .color($r('app.color.common_color_5'))
              .strokeWidth(0.5)
          }
          .width('100%')
          .margin({ top: 12 })
          .backgroundColor($r('app.color.ybg_white'))

          Text('发布')
            .fontSize(17)
            .fontColor($r('app.color.white'))
            .textAlign(TextAlign.Center)
            .width('100%')
            .height(44)
            .borderRadius(6)
            .backgroundColor($r('app.color.ybg_blue'))
            .margin({ left: 15, right: 15, top: 25, bottom: 12.5 })
        }
        .width('100%')
      }
      .scrollBar(BarState.Off)
      .layoutWeight(1)
      .backgroundColor('#F0F0F0')
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F0F0F0')
  }
}
