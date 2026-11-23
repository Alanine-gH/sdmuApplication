import { router } from '@kit.ArkUI';
import { promptAction } from '@kit.ArkUI';
import { photoAccessHelper } from '@kit.MediaLibraryKit';
import { http } from '@kit.NetworkKit';
import { BusinessError } from '@kit.BasicServicesKit';
import fs from '@ohos.file.fs';
import { CreaseRegionVp } from '../common/BreakpointSystem';
import { AdaptiveLayoutHelper } from '../common/AdaptiveLayoutHelper';

/**
 * 照片全屏浏览页 — 源码级复刻 BrowsePhotosActivity（baseapp weiget 包，PhotoView+ViewPager）。
 * 源码：browse_photos.xml（黑底 + 顶部 alpha_20 操作条：browse_photos_iv_back_btn 白返回 +
 * browse_photos_iv_extra_operation_btn（DELETE→rubbish_icon / SHARE→post_detail_share_btn_selector /
 * NONE→无图）+ 底部 CirclePageIndicator（radius 2vp、fillColor #bbbbbb / pageColor #454545、
 * 间距 7vp、>1 张显示））+ browse_photos_item（PhotoView 全屏 + ProgressBar loading_torus_grey）；
 * e PagerAdapter.instantiateItem：数字串 → 本地资源图，否则 i.h(0/4, str) 网络图（default_circle
 * 占位 + LoadingDialog + 失败 no_pic）；photoView.setOnViewTapListener → L2()（单击退出）；
 * 长按（非 DELETE）→ 弹"is_save_photo=是否保存图片"→ c.b.d.a.a 保存相册；
 * b（右上 DELETE）→ 移除当前 → 空表 L2() / 剩 1 张 → indicator 隐 → notifyDataSetChanged；
 * L2()：DELETE 模式 setResult(photoUrlList 剩余) + finish。
 * HAP 等价：Swiper + Image(pinch 缩放 PhotoView 语义) + 长按保存 photoAccessHelper。
 */
class BrowsePhotoItem {
  url: string = '';
}

@Entry
@Component
struct BrowsePhotosPage {
  @State photos: BrowsePhotoItem[] = [];
  @State currentIndex: number = 0;
  /** extraOperation：none/delete/share */
  private extraOperation: string = 'none';
  /** PhotoView 缩放态（pinch 手势） */
  @State scaleValue: number = 1;
  @StorageProp('avoidAreaTopVp') avoidAreaTopVp: number = 0;
  @StorageProp('avoidAreaBottomVp') avoidAreaBottomVp: number = 0;
  @StorageProp('avoidAreaLeftVp') avoidAreaLeftVp: number = 0;
  @StorageProp('avoidAreaRightVp') avoidAreaRightVp: number = 0;
  @StorageProp('foldStatus') foldStatus: number = 0;
  @StorageProp('creaseRegionVp') creaseRegionVp: CreaseRegionVp | null = null;
  private filePathCache: string = '';

  aboutToAppear(): void {
    const params: object | undefined = router.getParams() as object | undefined;
    if (params !== null && params !== undefined) {
      const record = params as Record<string, Object>;
      const list: Object = record['photoUrlList'];
      if (Array.isArray(list)) {
        const arr: string[] = list as string[];
        this.photos = arr.map((u: string): BrowsePhotoItem => {
          const item = new BrowsePhotoItem();
          item.url = u;
          return item;
        });
      }
      const start: Object = record['startPosition'];
      if (typeof start === 'number') {
        this.currentIndex = start as number;
      }
      const op: Object = record['extraOperation'];
      if (typeof op === 'string') {
        this.extraOperation = op as string;
      }
    }
  }

  /** L2()：DELETE 模式回传剩余列表（onActivityResult 等价 AppStorage 管道）→ finish */
  private closePage(): void {
    if (this.extraOperation === 'delete') {
      AppStorage.setOrCreate('browse_photos_result', this.photos.map((p: BrowsePhotoItem): string => p.url));
    }
    router.back();
  }

  /** b（右上 DELETE）：移除当前 → 空表 L2() / 剩 1 张 → 隐圆点 */
  private deleteCurrent(): void {
    if (this.extraOperation !== 'delete' || this.photos.length === 0) {
      return;
    }
    const next: BrowsePhotoItem[] = this.photos.slice();
    next.splice(this.currentIndex, 1);
    this.photos = next;
    if (this.photos.length === 0) {
      this.closePage();
      return;
    }
    if (this.currentIndex >= this.photos.length) {
      this.currentIndex = this.photos.length - 1;
    }
  }

  /** 长按保存（非 DELETE 模式）：c.b.d.a.a(context,url) 保存相册等价 */
  private async saveToGallery(url: string): Promise<void> {
    if (url === '' || (!url.startsWith('http://') && !url.startsWith('https://'))) {
      return;
    }
    const client: http.HttpRequest = http.createHttp();
    try {
      const response: http.HttpResponse = await client.request(url, {
        method: http.RequestMethod.GET,
        expectDataType: http.HttpDataType.ARRAY_BUFFER,
        connectTimeout: 15000,
        readTimeout: 30000
      });
      if (response.responseCode !== 200) {
        promptAction.showToast({ message: '保存失败' });
        return;
      }
      const helper: photoAccessHelper.PhotoAccessHelper =
        photoAccessHelper.getPhotoAccessHelper(this.getUIContext().getHostContext());
      const uri: string = await helper.createAsset(photoAccessHelper.PhotoType.IMAGE, 'jpg');
      const file: fs.File = fs.openSync(uri, fs.OpenMode.READ_WRITE | fs.OpenMode.TRUNC);
      try {
        await fs.write(file.fd, response.result as ArrayBuffer);
      } finally {
        fs.closeSync(file);
      }
      promptAction.showToast({ message: '已保存到相册' });
    } catch (error) {
      const be = error as BusinessError;
      promptAction.showToast({ message: '保存失败' });
    } finally {
      client.destroy();
    }
  }

  /** 右上角操作按钮资源（DELETE→rubbish_icon / SHARE→school_share_and / NONE→无） */
  private opRes(): Resource | null {
    if (this.extraOperation === 'delete') {
      return $r('app.media.rubbish_icon');
    }
    if (this.extraOperation === 'share') {
      return $r('app.media.school_share_and');
    }
    return null;
  }

  @Builder
  photoPage(item: BrowsePhotoItem) {
    Image(item.url)
      .width('100%')
      .height('100%')
      .objectFit(ImageFit.Contain)
      .alt($r('app.media.no_pic'))
      .scale({ x: this.scaleValue, y: this.scaleValue })
      .gesture(
        PinchGesture({ fingers: 2 })
          .onActionUpdate((event: GestureEvent) => {
            // PhotoView 双指缩放语义
            const s: number = event.scale;
            this.scaleValue = s < 1 ? 1 : (s > 4 ? 4 : s);
          })
          .onActionEnd(() => {
            this.scaleValue = 1;
          })
      )
      .onClick(() => {
        // b onViewTap → L2()
        this.closePage();
      })
      .gesture(
        LongPressGesture({ repeat: false })
          .onAction(() => {
            if (this.extraOperation !== 'delete') {
              // e$a onLongClick：弹"是否保存图片"
              this.getUIContext().showAlertDialog({
                title: '',
                message: '是否保存图片',
                primaryButton: {
                  value: '取消',
                  action: () => {
                  }
                },
                secondaryButton: {
                  value: '确认',
                  action: () => {
                    this.saveToGallery(item.url);
                  }
                }
              });
            }
          })
      )
  }

  build() {
    FolderStack({ upperItems: ['browse_photos_stage'] }) {
      Stack({ alignContent: Alignment.TopStart }) {
        // HackyViewPager：全屏翻页（PhotoView 单击/长按绑定）
        if (this.photos.length > 0) {
          Swiper() {
            ForEach(this.photos, (item: BrowsePhotoItem) => {
              this.photoPage(item)
            }, (item: BrowsePhotoItem) => 'bp_' + item.url)
          }
          .index(this.currentIndex)
          .indicator(false)
          .loop(false)
          .width('100%')
          .height('100%')
          .onChange((index: number) => {
            this.currentIndex = index;
            this.scaleValue = 1;
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

        // 顶部 alpha_20 操作条（padding 12）：白返回 + 右上操作按钮
        Row() {
          Image($r('app.media.nav_back_btn_white'))
            .objectFit(ImageFit.Contain)
            .width(24)
            .height(24)
            .hoverEffect(HoverEffect.Highlight)
            .onClick(() => {
              this.closePage();
            })

          Blank()

          if (this.extraOperation !== 'delete' && this.photos.length > 0) {
            Row() {
              SaveButton({
                icon: SaveIconStyle.FULL_FILLED,
                text: SaveDescription.SAVE,
                buttonType: ButtonType.Capsule
              })
                .height(28)
                .fontSize(12)
                .fontColor($r('app.color.white'))
                .iconColor($r('app.color.white'))
                .backgroundColor('#4D000000')
                .onClick((_event: ClickEvent, result: SaveButtonOnClickResult) => {
                  if (result === SaveButtonOnClickResult.SUCCESS &&
                    this.currentIndex >= 0 && this.currentIndex < this.photos.length) {
                    this.saveToGallery(this.photos[this.currentIndex].url);
                  } else {
                    promptAction.showToast({ message: '未获得保存授权' });
                  }
                })
            }
            .margin({ right: 8 })
          }

          if (this.opRes() !== null) {
            Image(this.opRes() as Resource)
              .objectFit(ImageFit.Contain)
              .width(24)
              .height(24)
              .padding(3)
              .margin({ right: 10 })
              .hoverEffect(HoverEffect.Highlight)
              .onClick(() => {
                // b（DELETE）：移除当前
                this.deleteCurrent();
              })
          }
        }
        .width('100%')
        .padding({
          top: Math.max(6, this.avoidAreaTopVp + 6),
          bottom: 6,
          left: Math.max(12, this.avoidAreaLeftVp + 12),
          right: Math.max(12, this.avoidAreaRightVp + 12)
        })
        .alignItems(VerticalAlign.Center)
        .backgroundColor($r('app.color.alpha_20'))
        .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP])
      }
      .id('browse_photos_stage')
      .width('100%')
      .height('100%')

      // 下半屏指示器与折痕避让区（位于 upperItems 之外，半折叠悬停时保持在下半屏）
      Column() {
        if (this.photos.length > 1) {
          Row() {
            ForEach(this.photos, (item: BrowsePhotoItem, index: number) => {
              Circle()
                .width(4)
                .height(4)
                .fill(index === this.currentIndex
                  ? $r('app.color.browse_photos_hover_dot') : $r('app.color.browse_photos_normal_dot'))
                .margin({ left: 3.5, right: 3.5 })
            }, (item: BrowsePhotoItem) => 'dot_' + item.url)
          }
          .justifyContent(FlexAlign.Center)
          .width('100%')
          .padding({
            top: 10 + AdaptiveLayoutHelper.getCreaseAvoidHeightVp(this.creaseRegionVp, this.foldStatus),
            bottom: Math.max(10, this.avoidAreaBottomVp + 10),
            left: this.avoidAreaLeftVp,
            right: this.avoidAreaRightVp
          })
          .backgroundColor('#66000000')
        }
      }
      .width('100%')
      .height('100%')
      .justifyContent(FlexAlign.End)
      .hitTestBehavior(HitTestMode.Transparent)
    }
    .enableAnimation(true)
    .autoHalfFold(true)
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.black'))
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
  }
}
