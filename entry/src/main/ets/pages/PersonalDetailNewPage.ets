import { TitleBar } from '../components/TitleBar';

/**
 * 个人详情新版页 — 1:1 复刻 my_user_detail.xml + my_user_detail_info.xml + my_user_detail_scoial.xml
 * 结构：上部 RelativeLayout(divider_grey 背景, weight 1)
 *   + 滚动区：头部图 px_to_dip_220=110vp(my_person 底图 + ly_logo 头像 px_to_dip_128=64vp marginL 15)
 *   + 信息卡(main_bg)：姓名行(px_to_sp_36/2=18fp + 性别图标) + 姓名/学院行(px_to_sp_30/2=15fp, label宽 px_to_dip_150=75vp)
 *   + 社交卡：个人社交 + my_user_more(px_to_dip_60=30vp)
 * 底部按钮栏(main_bg padding 15vp)：关注(my_user_add + common_color_1 文字)
 */
interface DetailInfoItem {
  key: string;
  label: string;
  value: string;
}

@Entry
@Component
struct PersonalDetailNewPage {
  @State userName: string = '张小明';
  @State isFollowed: boolean = false;
  @State infoItems: DetailInfoItem[] = [
    { key: 'true_name', label: '姓名', value: '张小明' },
    { key: 'academy', label: '学院', value: '信息工程学院' }
  ];

  private toggleFollow(): void {
    this.isFollowed = !this.isFollowed;
    this.getUIContext().getPromptAction().showToast({ message: this.isFollowed ? '关注成功' : '已取消关注' });
  }

  @Builder
  greyThinDivider() {
    Divider()
      .color($r('app.color.divider_grey'))
      .strokeWidth(0.5)
      .width('100%')
  }

  @Builder
  infoRow(label: string, value: string) {
    Row() {
      Text(label)
        .fontSize(15)
        .fontColor($r('app.color.common_color_2'))
        .width(75)
      Text(value)
        .fontSize(15)
        .fontColor($r('app.color.common_color_1'))
        .margin({ right: 13 })
    }
    .width('100%')
    .padding({ left: 15, right: 15, top: 10, bottom: 10 })
    .alignItems(VerticalAlign.Center)
  }

  build() {
    Column() {
      TitleBar({ title: '个人详情', showBack: true })

      Scroll() {
        Column() {
          // 头部背景区 110vp
          Stack({ alignContent: Alignment.BottomStart }) {
            Image($r('app.media.my_person'))
              .width('100%')
              .height(110)
              .objectFit(ImageFit.Cover)
            Image($r('app.media.ly_logo'))
              .width(64)
              .height(64)
              .margin({ left: 15 })
              .offset({ y: 32 })
          }
          .width('100%')
          .height(110)

          // 占位，避免头像偏移重叠
          Row()
            .height(20)

          // 信息卡 my_user_detail_info
          Column() {
            Row() {
              Row()
                .width(75)
              Text(this.userName)
                .fontSize(18)
                .fontColor($r('app.color.common_color_1'))
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
              Image($r('app.media.my_user_boy'))
                .width(16)
                .height(16)
                .margin({ left: 6 })
            }
            .width('100%')
            .padding({ left: 15, right: 15, top: 10, bottom: 10 })
            .alignItems(VerticalAlign.Center)

            this.greyThinDivider()

            ForEach(this.infoItems, (item: DetailInfoItem, index: number) => {
              this.infoRow(item.label, item.value)
              if (index < this.infoItems.length - 1) {
                this.greyThinDivider()
              }
            }, (item: DetailInfoItem): string => item.key)
          }
          .width('100%')
          .backgroundColor($r('app.color.main_bg'))

          // 社交卡 my_user_detail_scoial
          Column() {
            this.greyThinDivider()

            Row() {
              Text('个人社交')
                .fontSize(15)
                .fontColor($r('app.color.common_color_2'))
                .alignSelf(ItemAlign.Start)
                .width(75)
              Row()
                .layoutWeight(1)
              Image($r('app.media.my_user_more'))
                .width(30)
                .height(30)
                .objectFit(ImageFit.Contain)
                .padding({ left: 10 })
            }
            .width('100%')
            .padding({ left: 15, right: 15, top: 10, bottom: 10 })
            .alignItems(VerticalAlign.Center)
          }
          .width('100%')
          .backgroundColor($r('app.color.main_bg'))
        }
      }
      .scrollBar(BarState.Off)
      .width('100%')
      .layoutWeight(1)
      .backgroundColor($r('app.color.divider_grey'))

      // 底部按钮栏
      Row() {
        Row() {
          Image($r('app.media.my_user_add'))
            .height(22)
            .objectFit(ImageFit.Contain)
          Text(this.isFollowed ? '取消关注' : '关注')
            .fontSize(16)
            .fontColor($r('app.color.common_color_1'))
            .margin({ left: 15 })
        }
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
        .alignItems(VerticalAlign.Center)
        .onClick(() => {
          this.toggleFollow();
        })
      }
      .width('100%')
      .padding(15)
      .backgroundColor($r('app.color.main_bg'))
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.divider_grey'))
  }
}
