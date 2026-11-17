import { router } from '@kit.ArkUI';
import { TitleBar } from '../components/TitleBar';

/**
 * 新增记录 — 1:1 复刻自：
 *   new_inspection_activity_add_record.xml（标题 + 评语输入 + 照片九宫格 + 星级评分 + 提交）
 *   inspection_comment_starbar.xml（星级行：标题 + 5星 + 描述）
 */

class StarRatingItem {
  title: string;
  titleSize: number;
  rating: number;

  constructor(title: string, titleSize: number, rating: number) {
    this.title = title;
    this.titleSize = titleSize;
    this.rating = rating;
  }
}

class ChosenPhoto {
  name: string;

  constructor(name: string) {
    this.name = name;
  }
}

@Component
struct CommentStarRow {
  @Prop itemTitle: string = '';
  @Prop titleSize: number = 15;
  @Prop rating: number = 0;
  private onRate: (rating: number) => void = (rating: number): void => {};

  build() {
    Row() {
      Text(this.itemTitle)
        .fontSize(this.titleSize)
        .fontColor($r('app.color.common_color_1'))
        .width(40)
        .margin({ top: 12, bottom: 12 })
      Row() {
        ForEach([1, 2, 3, 4, 5], (star: number) => {
          Text('★')
            .fontSize(20)
            .fontColor(star <= this.rating ? $r('app.color.ybg_blue') : $r('app.color.common_color_5'))
            .margin({ left: 7.5, right: 7.5 })
            .onClick(() => {
              this.onRate(star);
            })
        }, (star: number) => star.toString())
      }
      .layoutWeight(1)
      .margin({ left: 4, right: 4 })
      .justifyContent(FlexAlign.Center)

      Text(this.rating > 0 ? `${this.rating}分` : '')
        .fontSize(14)
        .fontColor($r('app.color.inspection_desc_gray'))
        .width(30)
        .textAlign(TextAlign.Center)
    }
    .width('100%')
    .height(44)
    .padding({ left: 13, right: 13 })
    .alignItems(VerticalAlign.Center)
  }
}

@Entry
@Component
struct InspectionNewPage {
  @State pageTitle: string = '302室检查';
  @State comment: string = '';
  @State chosenPhotos: ChosenPhoto[] = [
    new ChosenPhoto('photo1'),
    new ChosenPhoto('photo2'),
    new ChosenPhoto('photo3')
  ];
  @State starItems: StarRatingItem[] = [
    new StarRatingItem('总体情况', 17, 0),
    new StarRatingItem('卫生情况', 15, 0),
    new StarRatingItem('垃圾分类', 15, 0),
    new StarRatingItem('节能减排', 15, 0)
  ];
  @State canSubmit: boolean = false;

  private updateStarRating(index: number, rating: number): void {
    this.starItems = this.starItems.map((item: StarRatingItem, i: number): StarRatingItem => {
      if (i === index) {
        return new StarRatingItem(item.title, item.titleSize, rating);
      }
      return item;
    });
    this.canSubmit = this.starItems.some((item: StarRatingItem): boolean => item.rating > 0);
  }

  build() {
    Column() {
      // toolbar_normal
      TitleBar({ title: '新增记录', showBack: true })

      Scroll() {
        Column() {
          // inspection_addrecord_title
          Text(this.pageTitle)
            .fontSize(24)
            .fontColor($r('app.color.common_color_1'))
            .width('100%')
            .padding({ left: 14.5, right: 14.5, top: 8, bottom: 8 })

          // inspection_addrecord_content 评语输入
          TextArea({ placeholder: '给该宿舍写写评语吧', text: this.comment })
            .fontSize(16)
            .fontColor($r('app.color.common_color_1'))
            .placeholderColor($r('app.color.common_color_3'))
            .backgroundColor($r('app.color.white'))
            .padding({ left: 14.5, right: 14.5, top: 12, bottom: 12 })
            .width('100%')
            .height(140)
            .onChange((value: string) => {
              this.comment = value;
            })

          // inspection_addrecord_gv_chosen_photo_container 照片九宫格
          Grid() {
            ForEach(this.chosenPhotos, (photo: ChosenPhoto) => {
              GridItem() {
                Image($r('app.media.inspection_pic'))
                  .width('100%')
                  .aspectRatio(1)
                  .objectFit(ImageFit.Cover)
                  .borderRadius(2)
              }
            }, (photo: ChosenPhoto) => photo.name)
            GridItem() {
              Image($r('app.media.inspection_photo'))
                .width(32)
                .height(32)
                .objectFit(ImageFit.Contain)
            }
            .onClick(() => {
              this.chosenPhotos = [...this.chosenPhotos, new ChosenPhoto(`photo${this.chosenPhotos.length + 1}`)];
            })
          }
          .columnsTemplate('1fr 1fr 1fr 1fr 1fr')
          .rowsGap(9)
          .columnsGap(9)
          .padding(15)
          .width('100%')
          .backgroundColor($r('app.color.white'))

          // inspection_addrecord_comment_container 星级评分
          Column() {
            ForEach(this.starItems, (item: StarRatingItem, index: number) => {
              Column() {
                CommentStarRow({
                  itemTitle: item.title,
                  titleSize: item.titleSize,
                  rating: item.rating,
                  onRate: (rating: number): void => {
                    this.updateStarRating(index, rating);
                  }
                })
                Divider()
                  .color($r('app.color.common_color_5'))
                  .strokeWidth(0.5)
                  .width('100%')
              }
              .width('100%')
            }, (item: StarRatingItem) => item.title)
          }
          .width('100%')
          .backgroundColor($r('app.color.white'))
          .margin({ top: 12 })

          // inspection_addrecord_submit 提交
          Text('提交')
            .fontSize(17)
            .fontColor(this.canSubmit ? $r('app.color.white') : $r('app.color.common_color_33'))
            .textAlign(TextAlign.Center)
            .width('100%')
            .padding({ top: 13, bottom: 13 })
            .backgroundColor(this.canSubmit ? $r('app.color.ybg_blue') : $r('app.color.common_color_5'))
            .borderRadius(4)
            .margin({ left: 20, right: 20, top: 60 })
            .onClick(() => {
              if (this.canSubmit) {
                router.back();
              }
            })
        }
        .width('100%')
        .padding({ bottom: 10 })
      }
      .width('100%')
      .layoutWeight(1)
      .align(Alignment.TopStart)
      .scrollBar(BarState.Off)
      .backgroundColor($r('app.color.common_color_6'))
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.common_color_6'))
  }
}
