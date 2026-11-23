import { router } from '@kit.ArkUI';
import { BreakpointSystem } from '../common/BreakpointSystem';

/**
 * 图片翻页选择页 — 源码级复刻 PhotoPagerActivity（baselibrary PhotoPicker 包）。
 * 源码：activity_photo_pager 布局 = ImagePagerFragment（全屏 ViewPager PhotoView）+
 * navigation_bar_normal（背景 -1728053248=#99000000：nav_back_btn_white 返回 + 左标题
 * image_index"%1$d/%2$d" common_color_6 + 右"完成"done/done_with_count"完成(%1$d/%2$d)"）+
 * photo_pager_bottom_bar（#99000000：photo_pager_tv_selected_state"选择" select 圆点
 * drawablePadding 4vp padding 10vp 靠右）；f1()：photos/current_item/MAX_COUNT=9/SELECTED_PHOTOS；
 * onPageScrolled → J2() 页码刷新 + 当前页在已选集合 → 圆点选中态；
 * PhotoPicker 点击回调 a：切换工具栏显隐（500ms 透明动画 + systemUiVisibility）；
 * d（圆点点击）：已选移除/未选加入（超 MAX_COUNT → over_max_count_tips"你最多可以选择N张图片"）
 * → 右上文案刷新"完成(N/M)"/"完成"；
 * b（返回）/c（完成）→ H2(z)：z 且未选 → 加入当前页 → setResult(SELECTED_PHOTOS, isDone)；
 * onBackPressed → H2(false)。
 * HAP 等价管道：AppStorage 'photo_pager_result'{selected, isDone}（setResult 等价）。
 */
class PagerPhotoItem {
  url: string = '';
  selected: boolean = false;
}

@Entry
@Component
struct PhotoPagerPage {
  @State photos: PagerPhotoItem[] = [];
  @State selectedUrls: string[] = [];
  @State currentIndex: number = 0;
  @State barsVisible: boolean = true;
  @StorageProp('avoidAreaTopVp') avoidAreaTopVp: number = 0;
  @StorageProp('avoidAreaBottomVp') avoidAreaBottomVp: number = 0;
  @StorageProp('avoidAreaLeftVp') avoidAreaLeftVp: number = 0;
  @StorageProp('avoidAreaRightVp') avoidAreaRightVp: number = 0;
  private maxCount: number = 9;
  private barsAnim: number = 0;

  aboutToAppear(): void {
    const params: object | undefined = router.getParams() as object | undefined;
    if (params !== null && params !== undefined) {
      const record = params as Record<string, Object>;
      const list: Object = record['photos'];
      if (Array.isArray(list)) {
        this.photos = (list as string[]).map((u: string): PagerPhotoItem => {
          const item = new PagerPhotoItem();
          item.url = u;
          return item;
        });
      }
      const start: Object = record['current_item'];
      if (typeof start === 'number') {
        this.currentIndex = start as number;
      }
      const max: Object = record['MAX_COUNT'];
      if (typeof max === 'number') {
        this.maxCount = max as number;
      }
      const sel: Object = record['SELECTED_PHOTOS'];
      if (Array.isArray(sel)) {
        this.selectedUrls = (sel as string[]).slice();
      }
    }
    // 初始已选态回填
    this.photos = this.photos.map((p: PagerPhotoItem): PagerPhotoItem => {
      return { url: p.url, selected: this.selectedUrls.includes(p.url) };
    });
  }

  /** J2()：页码 text（image_index = "N/total"） */
  private indexText(): string {
    return String(this.currentIndex + 1) + '/' + String(this.photos.length);
  }

  /** 右上文案：size>0 → "完成(N/M)"，否则"完成"（done_with_count/done） */
  private doneText(): string {
    if (this.selectedUrls.length > 0) {
      return '完成(' + String(this.selectedUrls.length) + '/' + String(this.maxCount) + ')';
    }
    return '完成';
  }

  /** d（圆点点击）：toggle 当前页选中；超上限 toast over_max_count_tips */
  private toggleSelected(): void {
    const current: PagerPhotoItem | undefined = this.photos[this.currentIndex];
    if (current === undefined) {
      return;
    }
    if (this.selectedUrls.includes(current.url)) {
      this.selectedUrls = this.selectedUrls.filter((u: string): boolean => u !== current.url);
    } else {
      if (this.selectedUrls.length >= this.maxCount) {
        this.getUIContext().getPromptAction()
          .showToast({ message: '你最多可以选择' + String(this.maxCount) + '张图片' });
        return;
      }
      this.selectedUrls = this.selectedUrls.concat([current.url]);
    }
    this.photos = this.photos.map((p: PagerPhotoItem): PagerPhotoItem => {
      return { url: p.url, selected: this.selectedUrls.includes(p.url) };
    });
  }

  /** H2(z)：z 且未选 → 加入当前页 → AppStorage 管道（setResult(SELECTED_PHOTOS,isDone)）→ finish */
  private finishPage(isDone: boolean): void {
    const selected: string[] = this.selectedUrls.slice();
    if (isDone && selected.length === 0) {
      const current: PagerPhotoItem | undefined = this.photos[this.currentIndex];
      if (current !== undefined) {
        selected.push(current.url);
      }
    }
    AppStorage.setOrCreate('photo_pager_result', {
      'SELECTED_PHOTOS': selected,
      'isDone': isDone
    } as Record<string, Object>);
    router.back();
  }

  /** a：点击图片 → 工具栏显隐切换（AlphaAnimation 500ms） */
  private toggleBars(): void {
    this.barsVisible = !this.barsVisible;
    this.barsAnim = this.barsVisible ? 1 : 0;
  }

  build() {
    Stack() {
      // ImagePagerFragment：全屏 PhotoView 翻页
      if (this.photos.length > 0) {
        Swiper() {
          ForEach(this.photos, (item: PagerPhotoItem) => {
            Image(item.url)
              .width('100%')
              .height('100%')
              .objectFit(ImageFit.Contain)
              .alt($r('app.media.no_pic'))
              .onClick(() => {
                this.toggleBars();
              })
          }, (item: PagerPhotoItem) => 'pp_' + item.url)
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
      } else {
        Scroll() {
          Column() {
            Text('暂无图片')
              .fontSize(14)
              .fontColor($r('app.color.white'))
          }
          .width('100%')
          .padding({ top: 120, bottom: 24 })
          .alignItems(HorizontalAlign.Center)
        }
        .width('100%')
        .height('100%')
        .scrollBar(BarState.Off)
      }

      // photo_pager_navigation_bar：#99000000 + 白返回 + N/total + 完成(N/M)
      Row() {
        Image($r('app.media.nav_back_btn_white'))
          .objectFit(ImageFit.Contain)
          .width(24)
          .height(24)
          .padding({ left: 10, right: 5 })
          .onClick(() => {
            // b：H2(false)
            this.finishPage(false);
          })

        Text(this.indexText())
          .fontSize(15)
          .fontColor($r('app.color.common_color_6'))
          .margin({ left: 5 })

        Blank()

        Text(this.doneText())
          .fontSize(15)
          .fontColor($r('app.color.common_color_6'))
          .padding({ left: 10, right: 10 })
          .onClick(() => {
            // c：H2(true)
            this.finishPage(true);
          })
      }
      .width('100%')
      .height(48 + this.avoidAreaTopVp)
      .padding({
        top: this.avoidAreaTopVp,
        left: this.avoidAreaLeftVp,
        right: this.avoidAreaRightVp
      })
      .alignItems(VerticalAlign.Center)
      .backgroundColor('#99000000')
      .margin({ top: 0 })
      .opacity(this.barsAnim)
      .visibility(this.barsVisible ? Visibility.Visible : Visibility.Hidden)
      .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP])

      // photo_pager_bottom_bar：#99000000 + 右"选择"圆点
      Row() {
        Blank()

        Row() {
          Stack({ alignContent: Alignment.Center }) {
            Circle()
              .width(16)
              .height(16)
              .fill(Color.Transparent)
              .stroke(Color.White)
              .strokeWidth(1.5)
            if (this.photos[this.currentIndex] !== undefined && this.photos[this.currentIndex].selected) {
              Circle()
                .width(9)
                .height(9)
                .fill(Color.White)
            }
          }
          .width(16)
          .height(16)
          .margin({ right: 4 })

          Text('选择')
            .fontSize(15)
            .fontColor($r('app.color.common_color_6'))
        }
        .padding(10)
        .onClick(() => {
          this.toggleSelected();
        })
      }
      .width('100%')
      .padding({
        left: this.avoidAreaLeftVp,
        right: this.avoidAreaRightVp,
        bottom: this.avoidAreaBottomVp
      })
      .alignItems(VerticalAlign.Center)
      .backgroundColor('#99000000')
      .opacity(this.barsAnim)
      .visibility(this.barsVisible ? Visibility.Visible : Visibility.Hidden)
      .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.BOTTOM])
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.black'))
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
  }
}
