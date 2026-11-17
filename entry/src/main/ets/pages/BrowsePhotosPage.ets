import { router } from '@kit.ArkUI';

/**
 * 照片全屏浏览页 — 1:1 复刻源布局 browse_photos.xml + browse_photos_item.xml
 * 结构：黑色全屏 HackyViewPager + 顶部 alpha_20 半透明操作条（白色返回 + 右侧操作按钮）
 * + 底部 CirclePageIndicator 圆点页指示（半径 2vp，当前点 browse_photos_hover_dot，其余 browse_photos_normal_dot）
 */
interface BrowsePhotoItem {
  photoId: number;
}

@Entry
@Component
struct BrowsePhotosPage {
  @State photoList: BrowsePhotoItem[] = [];
  @State currentIndex: number = 0;

  aboutToAppear(): void {
    const seeds: number[] = [];
    for (let i = 1; i <= 6; i++) {
      seeds.push(i);
    }
    this.photoList = seeds.map((id: number): BrowsePhotoItem => {
      return { photoId: id };
    });
  }

  build() {
    Column() {
      Stack() {
        // 全屏滑动浏览（黑色底）
        Swiper() {
          ForEach(this.photoList, (item: BrowsePhotoItem) => {
            Image($r('app.media.up_photo_bg'))
              .objectFit(ImageFit.Contain)
              .width('100%')
              .height('100%')
          }, (item: BrowsePhotoItem) => `browse_${item.photoId}`)
        }
        .index(this.currentIndex)
        .indicator(false)
        .loop(false)
        .width('100%')
        .height('100%')
        .backgroundColor($r('app.color.black'))
        .onChange((index: number) => {
          this.currentIndex = index;
        })

        // 顶部半透明操作条（alpha_20）：白色返回 + 右侧操作按钮
        Row() {
          Image($r('app.media.nav_back_btn_white'))
            .objectFit(ImageFit.Contain)
            .width(24)
            .height(24)
            .onClick(() => {
              router.back();
            })

          Blank()

          Text('···')
            .fontSize(20)
            .fontColor('#FFFFFFFF')
            .textAlign(TextAlign.Center)
            .padding({ left: 6, right: 6 })
            .margin({ right: 10 })
        }
        .width('100%')
        .padding(12)
        .alignItems(VerticalAlign.Center)
        .backgroundColor($r('app.color.alpha_20'))
      }
      .width('100%')
      .layoutWeight(1)

      // 底部 CirclePageIndicator：圆点页指示（paddingTop 10 / marginBottom 10）
      Row() {
        ForEach(this.photoList, (item: BrowsePhotoItem) => {
          Circle()
            .width(4)
            .height(4)
            .fill(item.photoId - 1 === this.currentIndex ?
            $r('app.color.browse_photos_hover_dot') : $r('app.color.browse_photos_normal_dot'))
            .margin({ left: 4, right: 4 })
        }, (item: BrowsePhotoItem) => `dot_${item.photoId}`)
      }
      .justifyContent(FlexAlign.Center)
      .width('100%')
      .padding({ top: 10, bottom: 10 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.black'))
  }
}
