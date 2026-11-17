/**
 * 主页 Banner 弹窗页 — 1:1 复刻 mobile_campus_dialog_main_banner.xml（px_to_dip_N = N/2 vp）：
 * - main_head_banner RelativeLayout 背景 mobile_campus_primary_color_default(#1B68B7)、wrap 高；
 * - main_head_viewpager AutoScrollViewPager fill（自动轮播）；
 * - tvTitle：bold、singleLine、ellipsize end、背景 #B2FFFFFF、alignParentBottom、marginL 8dip(=8vp)；
 * - main_head_indicator PageIndicatorView：alignParentBottom 居中、marginB px_to_dip_15(=7.5vp)、
 *   圆点半径 px_to_dip_7(=3.5vp)、无切换动画。
 */
import { router } from '@kit.ArkUI';

class BannerEntry {
  bannerId: string = '';
  bannerTitle: string = '';
  bannerImage: Resource = $r('app.media.social_banner_default');

  constructor(bannerId: string, bannerTitle: string, bannerImage: Resource) {
    this.bannerId = bannerId;
    this.bannerTitle = bannerTitle;
    this.bannerImage = bannerImage;
  }
}

@Entry
@Component
struct BannerDialogPage {
  @State currentIndex: number = 0;
  private banners: BannerEntry[] = [
    new BannerEntry('b1', '关于开展2026年度消防安全专项检查的通知', $r('app.media.social_banner_default')),
    new BannerEntry('b2', '图书馆近期开放时间调整公告', $r('app.media.social_banner_default')),
    new BannerEntry('b3', '2026年秋季运动会报名通道开启', $r('app.media.social_banner_default'))
  ];

  private currentTitle(): string {
    if (this.currentIndex >= 0 && this.currentIndex < this.banners.length) {
      return this.banners[this.currentIndex].bannerTitle;
    }
    return '';
  }

  build() {
    Column() {
      // main_head_banner：主色底轮播容器（fill 宽、wrap 高）
      Stack({ alignContent: Alignment.BottomStart }) {
        // main_head_viewpager：自动轮播
        Swiper() {
          ForEach(this.banners, (banner: BannerEntry) => {
            Image(banner.bannerImage)
              .width('100%')
              .height('100%')
              .objectFit(ImageFit.Fill)
          }, (banner: BannerEntry) => banner.bannerId)
        }
        .width('100%')
        .height('100%')
        .autoPlay(true)
        .interval(3000)
        .loop(true)
        .indicator(false)
        .onChange((index: number) => {
          this.currentIndex = index;
        })

        // tvTitle：bold 半透明白底标题条、底部左侧、marginL 8vp
        Text(this.currentTitle())
          .fontSize(14)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333333')
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .backgroundColor('#B2FFFFFF')
          .padding({ left: 6, right: 6, top: 3, bottom: 3 })
          .margin({ left: 8 })
          .onClick(() => {
            router.back();
          })

        // main_head_indicator：底部居中圆点、marginB 7.5vp、半径 3.5vp
        Row() {
          ForEach(this.banners, (banner: BannerEntry, index: number) => {
            Circle()
              .width(7)
              .height(7)
              .fill(index === this.currentIndex ? '#FFFFFF' : '#80FFFFFF')
              .margin({ right: 7 })
          }, (banner: BannerEntry) => `dot_${banner.bannerId}`)
        }
        .justifyContent(FlexAlign.Center)
        .width('100%')
        .margin({ bottom: 7.5 })
      }
      .width('100%')
      .height(180)
      .backgroundColor($r('app.color.mobile_campus_primary_color_default'))
      .borderRadius(8)
    }
    .width('100%')
    .height('100%')
    .padding({ left: 24, right: 24 })
    .backgroundColor('#99000000')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }
}
