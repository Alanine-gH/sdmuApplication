import { router } from '@kit.ArkUI';

/**
 * 照片浏览页 — 1:1 复刻源布局 activity_photo_pager.xml + fragment_image_pager.xml + item_pager.xml
 * 结构：navigation_bar_normal(顶部导航) + 全屏 ViewPager（pager_bg 深色底）+ 页码指示（n/total）
 * + 底部 #99000000 半透明选择条（右侧"选择"勾选项，drawableLeft social_rb_selector 勾选框）
 */
interface PagerPhotoItem {
  photoId: number;
  selected: boolean;
}

@Entry
@Component
struct PhotoPagerPage {
  @State photoList: PagerPhotoItem[] = [];
  @State currentIndex: number = 0;
  private readonly totalCount: number = 9;

  aboutToAppear(): void {
    const seeds: number[] = [];
    for (let i = 1; i <= this.totalCount; i++) {
      seeds.push(i);
    }
    this.photoList = seeds.map((id: number): PagerPhotoItem => {
      return { photoId: id, selected: false };
    });
  }

  private toggleCurrentSelected(): void {
    const item: PagerPhotoItem | undefined = this.photoList[this.currentIndex];
    if (item === undefined) {
      return;
    }
    const next: PagerPhotoItem[] = this.photoList.map((it: PagerPhotoItem): PagerPhotoItem => {
      if (it.photoId === item.photoId) {
        return { photoId: it.photoId, selected: !it.selected };
      }
      return it;
    });
    this.photoList = next;
  }

  private isCurrentSelected(): boolean {
    const item: PagerPhotoItem | undefined = this.photoList[this.currentIndex];
    if (item === undefined) {
      return false;
    }
    return item.selected;
  }

  build() {
    Column() {
      // navigation_bar_normal：返回 + 居中标题
      Row() {
        Image($r('app.media.nav_back_btn'))
          .objectFit(ImageFit.Contain)
          .width(24)
          .height(24)
          .padding({ left: 15, right: 10 })
          .onClick(() => {
            router.back();
          })

        Text('图片预览')
          .fontSize(16)
          .fontColor($r('app.color.common_color_1'))
          .margin({ left: 12 })
      }
      .width('100%')
      .height(48)
      .alignItems(VerticalAlign.Center)
      .backgroundColor($r('app.color.white'))

      // 全屏滑动浏览（fragment_image_pager：ViewPager + pager_bg）
      Stack({ alignContent: Alignment.TopEnd }) {
        Swiper() {
          ForEach(this.photoList, (item: PagerPhotoItem) => {
            Image($r('app.media.up_photo_bg'))
              .objectFit(ImageFit.Contain)
              .width('100%')
              .height('100%')
          }, (item: PagerPhotoItem) => `pager_${item.photoId}`)
        }
        .index(this.currentIndex)
        .indicator(false)
        .loop(false)
        .width('100%')
        .layoutWeight(1)
        .backgroundColor($r('app.color.pager_bg'))
        .onChange((index: number) => {
          this.currentIndex = index;
        })

        // 页码指示（pager_navigator_layout：n / total）
        Text(`${this.currentIndex + 1}/${this.totalCount}`)
          .fontSize(13)
          .fontColor('#FFFFFFFF')
          .padding({ left: 8, right: 8, top: 3, bottom: 3 })
          .borderRadius(10)
          .backgroundColor('#66000000')
          .margin({ top: 12, right: 12 })
      }
      .width('100%')
      .layoutWeight(1)

      // 底部选择条：#99000000 半透明，右侧"选择"勾选项
      Row() {
        Blank()

        Row() {
          Stack() {
            if (this.isCurrentSelected()) {
              Text('✓')
                .fontSize(10)
                .fontColor('#FFFFFFFF')
                .textAlign(TextAlign.Center)
            }
          }
          .width(16)
          .height(16)
          .borderRadius(8)
          .backgroundColor(this.isCurrentSelected() ? $r('app.color.mobile_campus_primary_color') : '#00000000')
          .border({ width: 1.5, color: '#FFFFFFFF' })
          .margin({ right: 8 })

          Text(this.isCurrentSelected() ? '已选择' : '选择')
            .fontSize(14)
            .fontColor('#FFFFFFFF')
        }
        .padding(10)
        .onClick(() => {
          this.toggleCurrentSelected();
        })
      }
      .width('100%')
      .padding({ right: 10, left: 10 })
      .alignItems(VerticalAlign.Center)
      .backgroundColor('#99000000')
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.black'))
  }
}
