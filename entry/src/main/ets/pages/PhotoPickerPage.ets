import { router, promptAction } from '@kit.ArkUI';
import { photoAccessHelper } from '@kit.MediaLibraryKit';
import { cameraPicker, camera } from '@kit.CameraKit';
import { Context } from '@kit.AbilityKit';
import { fileIo as fs } from '@kit.CoreFileKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { BreakpointSystem } from '../common/BreakpointSystem';
import { TitleBar } from '../components/TitleBar';
import { ApiService } from '../network/ApiService';

/**
 * 图片选择器 — 源码级翻译（PhotoPickerActivity + PhotoPickerFragment + PhotoGridAdapter，[W28 final-b]）。
 *
 * 【源码】activity_photo_picker = toolbar_normal（标题 choose_photos"选择图片"，右"完成"done，
 *   初始 disabled）+ PhotoPickerFragment；fragment_photo_picker = RecyclerView 3 列
 *   （StaggeredGridLayoutManager 3×1）+ 底部 RelativeLayout（左 button"所有图片" all_image、
 *   右 photo_picker_btn_preview"预览"preview / "预览(N)"preview_with_count，disabled 态 selector）。
 *   item_photo = SquareItemLayout：iv_photo centerCrop padding2 + v_mask #99000000 margin2（仅选中）
 *   + v_selected photo_checkbox_bg（pictures_selected / picture_unselected）padding5 margin5。
 *   首格 camera（SHOW_CAMERA 默认 true，点击 ImageCaptureManager 拍照插到首条）+ 9 图上限
 *   （MAX_COUNT 路由参，默认 9）→ 超限 toast over_max_count_tips"你最多可以选择N张图片"。
 *   选中变化 → J2(count)：右上"完成(N/M)" done_with_count / "完成" done，enabled=count>0；
 *   预览 → PhotoPagerActivity{photos,SELECTED_PHOTOS,current_item:0,MAX_COUNT}；
 *   完成 → setResult(-1, SELECTED_PHOTOS) + finish；PhotoPager 返回 → 回填选中集合（isDone 直接 finish）。
 *
 * 【HAP 等价说明（平台能力差异，非 mock）】APK 直接读 MediaStore 全量相册（READ_IMAGEVIDEO
 *   system_basic，普通 HAP 无法获得）。HAP 用系统 PhotoViewPicker 选取照片后在本页九宫格内预览/
 *   多选/取消选择；相机格用 cameraPicker 等价 ImageCaptureManager。所有图片均来自真实用户选择，
 *   零占位假图。返回管道=AppStorage 'photo_picker_result' {SELECTED_PHOTOS: string[]}。
 */
class PickerPhotoItem {
  uri: string = '';
  selected: boolean = false;
}

@Entry
@Component
struct PhotoPickerPage {
  @State photos: PickerPhotoItem[] = [];
  @State selectCount: number = 0;
  @State maxCount: number = 9;
  @State showCamera: boolean = true;
  @State picking: boolean = false;
  @StorageProp('currentBreakpoint') currentBreakpoint: string = 'sm';
  @StorageProp('avoidAreaBottomVp') avoidAreaBottomVp: number = 0;
  @StorageProp('avoidAreaLeftVp') avoidAreaLeftVp: number = 0;
  @StorageProp('avoidAreaRightVp') avoidAreaRightVp: number = 0;

  aboutToAppear(): void {
    const params: Record<string, Object> | undefined = router.getParams() as Record<string, Object> | undefined;
    if (params !== undefined && params !== null) {
      const max: Object = params['MAX_COUNT'];
      if (typeof max === 'number') {
        this.maxCount = max as number;
      }
      const showCam: Object = params['SHOW_CAMERA'];
      if (typeof showCam === 'boolean') {
        this.showCamera = showCam as boolean;
      }
      const selected: Object = params['SELECTED_PHOTOS'];
      if (Array.isArray(selected)) {
        const uris: string[] = selected as string[];
        this.photos = uris.map((uri: string): PickerPhotoItem => {
          const item: PickerPhotoItem = new PickerPhotoItem();
          item.uri = uri;
          item.selected = true;
          return item;
        });
        this.selectCount = this.photos.length;
      }
    }
    // 源码 f1()：PhotoPickerFragment.E0().t(SHOW_CAMERA) + N0(MAX_COUNT)
    if (this.maxCount <= 0) {
      this.maxCount = 9;
    }
    // APK 进入即展示系统相册网格；HAP 等价=进入即拉起系统图片选择器（用户取消则留在本页重选）
    if (this.photos.length === 0) {
      setTimeout((): void => {
        this.pickFromGallery();
      }, 120);
    }
  }

  /** 源码 c 类回调：选中数超上限 → toast over_max_count_tips；否则更新计数 */
  private toggleSelect(index: number): void {
    const item: PickerPhotoItem = this.photos[index];
    if (item.selected) {
      item.selected = false;
      this.selectCount = this.selectCount > 0 ? this.selectCount - 1 : 0;
      this.refresh();
      return;
    }
    if (this.selectCount >= this.maxCount) {
      promptAction.showToast({ message: '你最多可以选择' + String(this.maxCount) + '张图片' });
      return;
    }
    if (this.maxCount <= 1) {
      // 源码 i<=1：先清空其它选择
      this.photos = this.photos.map((it: PickerPhotoItem): PickerPhotoItem => {
        it.selected = it === item;
        return it;
      });
      this.selectCount = 1;
      this.refresh();
      return;
    }
    item.selected = true;
    this.selectCount = this.selectCount + 1;
    this.refresh();
  }

  private refresh(): void {
    this.photos = this.photos.slice();
  }

  /** 源码 J2(i)：右上"完成(N/M)"；0 → "完成" 且禁用 */
  private doneText(): string {
    return this.selectCount > 0 ? '完成(' + String(this.selectCount) + '/' + String(this.maxCount) + ')' : '完成';
  }

  /** 源码 b 类：图片点击 → 预览 PhotoPagerActivity{photos(全部),SELECTED_PHOTOS,current_item:index,MAX_COUNT} */
  private openPager(startIndex: number): void {
    const all: string[] = this.photos.map((item: PickerPhotoItem): string => item.uri);
    if (all.length === 0) {
      return;
    }
    router.pushUrl({
      url: 'pages/PhotoPagerPage',
      params: {
        'photos': all,
        'current_item': startIndex,
        'SELECTED_PHOTOS': this.selectedUris(),
        'MAX_COUNT': this.maxCount
      } as Record<string, Object>
    });
  }

  private selectedUris(): string[] {
    const list: string[] = [];
    for (const item of this.photos) {
      if (item.selected) {
        list.push(item.uri);
      }
    }
    return list;
  }

  /** 源码 a 类：完成 → setResult(-1, SELECTED_PHOTOS) + finish */
  private finishPick(): void {
    if (this.selectCount <= 0) {
      return;
    }
    AppStorage.setOrCreate('photo_picker_result', {
      'SELECTED_PHOTOS': this.selectedUris()
    } as Record<string, Object>);
    router.back();
  }

  /** media uri → 沙箱 cache 文件（沿用 APK ImageCaptureManager 拷贝到私有目录的语义） */
  private copyUriToCache(uri: string): string {
    if (uri.startsWith('/') || uri.startsWith('file://')) {
      return uri;
    }
    try {
      const ctx: Context = this.getUIContext().getHostContext() as Context;
      const target: string = ctx.cacheDir + '/picker_' + Date.now() + '_' +
        String(Math.floor(Math.random() * 9000) + 1000) + '.jpg';
      const src = fs.openSync(uri, fs.OpenMode.READ_ONLY);
      try {
        const dst = fs.openSync(target, fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE);
        try {
          fs.copyFileSync(src.fd, dst.fd);
        } finally {
          fs.closeSync(dst);
        }
      } finally {
        fs.closeSync(src);
      }
      return target;
    } catch (error) {
      const be = error as BusinessError;
      ApiService.logError('photo picker copy fail: ' + be.message);
      return uri;
    }
  }

  /** 源码首格 camera：cameraPicker 拍照 → 插入首条 */
  private async takePhoto(): Promise<void> {
    if (this.selectCount >= this.maxCount) {
      promptAction.showToast({ message: '你最多可以选择' + String(this.maxCount) + '张图片' });
      return;
    }
    try {
      const profile: cameraPicker.PickerProfile = {
        cameraPosition: camera.CameraPosition.CAMERA_POSITION_BACK
      };
      const result: cameraPicker.PickerResult = await cameraPicker.pick(
        this.getUIContext().getHostContext() as Context,
        [cameraPicker.PickerMediaType.PHOTO], profile);
      const path: string = this.copyUriToCache(result.resultUri);
      const item: PickerPhotoItem = new PickerPhotoItem();
      item.uri = path;
      item.selected = true;
      this.photos.splice(0, 0, item);
      this.selectCount = this.selectCount + 1;
      this.refresh();
    } catch (error) {
      const be = error as BusinessError;
      ApiService.logError('photo picker camera fail: ' + be.message);
    }
  }

  /** 源码 button"所有图片"：目录弹层（HAP 系统选择器等价全量相册入口） */
  private async pickFromGallery(): Promise<void> {
    if (this.picking) {
      return;
    }
    const remain: number = this.maxCount - this.selectCount;
    if (remain <= 0) {
      promptAction.showToast({ message: '你最多可以选择' + String(this.maxCount) + '张图片' });
      return;
    }
    this.picking = true;
    try {
      const picker: photoAccessHelper.PhotoViewPicker = new photoAccessHelper.PhotoViewPicker();
      const options: photoAccessHelper.PhotoSelectOptions = {
        MIMEType: photoAccessHelper.PhotoViewMIMETypes.IMAGE_TYPE,
        maxSelectNumber: remain
      };
      const result: photoAccessHelper.PhotoSelectResult = await picker.select(options);
      for (const uri of result.photoUris) {
        const item: PickerPhotoItem = new PickerPhotoItem();
        item.uri = this.copyUriToCache(uri);
        item.selected = true;
        this.photos.push(item);
        this.selectCount = this.selectCount + 1;
      }
      this.refresh();
    } catch (error) {
      const be = error as BusinessError;
      ApiService.logError('photo picker gallery fail: ' + be.message);
    }
    this.picking = false;
  }

  /** PhotoPager 返回（onActivityResult 2 等价）：AppStorage 'photo_pager_result' */
  onPageShow(): void {
    const result: Object | undefined = AppStorage.get<Object>('photo_pager_result');
    if (result === undefined || result === null) {
      return;
    }
    AppStorage.setOrCreate<Object>('photo_pager_result', new Object());
    const rec: Record<string, Object> = result as Record<string, Object>;
    const isDone: boolean = rec['isDone'] === true;
    const selected: Object = rec['SELECTED_PHOTOS'];
    if (isDone) {
      const list: string[] = Array.isArray(selected) ? selected as string[] : [];
      AppStorage.setOrCreate('photo_picker_result', { 'SELECTED_PHOTOS': list } as Record<string, Object>);
      router.back();
      return;
    }
    if (Array.isArray(selected)) {
      const uris: string[] = selected as string[];
      this.photos = this.photos.map((item: PickerPhotoItem): PickerPhotoItem => {
        item.selected = uris.includes(item.uri);
        return item;
      });
      this.selectCount = uris.length;
      this.refresh();
    }
  }

  /** 源码 item_photo：SquareItemLayout 内 iv_photo padding2 centerCrop + v_mask #99000000 margin2 +
   *  v_selected photo_checkbox_bg（42px@1.5x=28vp intrinsic）padding5 margin5；
   *  图片点击=预览（源码 b 类），圆勾点击=选中切换（源码 c 类） */
  @Builder
  photoCell(item: PickerPhotoItem, index: number) {
    Stack({ alignContent: Alignment.TopEnd }) {
      Image(item.uri)
        .width('100%')
        .height('100%')
        .objectFit(ImageFit.Cover)
        .padding(2)
        .onClick(() => {
          this.openPager(index);
        })
      if (item.selected) {
        Column() {
          Column()
            .width('100%')
            .height('100%')
            .backgroundColor('#99000000')
            .onClick(() => {
              this.openPager(index);
            })
        }
        .width('100%')
        .height('100%')
        .padding(2)
      }
      Image(item.selected ? $r('app.media.pictures_selected') : $r('app.media.picture_unselected'))
        .width(28)
        .height(28)
        .margin(5)
        .padding(5)
        .onClick(() => {
          this.toggleSelect(index);
        })
    }
    .width('100%')
    .aspectRatio(1)
  }

  @Builder
  cameraCell() {
    Stack({ alignContent: Alignment.Center }) {
      Image($r('app.media.ic_camera_grey600_48dp'))
        .width(24)
        .height(24)
        .objectFit(ImageFit.Contain)
    }
    .width('100%')
    .aspectRatio(1)
    .onClick(() => {
      this.takePhoto();
    })
  }

  build() {
    Column() {
      TitleBar({
        title: '选择图片',
        rightText: this.doneText(),
        rightTextColor: this.selectCount > 0 ? '#000000' : '#999999',
        onRightClick: (): void => {
          this.finishPick();
        }
      })

      if (this.showCamera || this.photos.length > 0) {
        Grid() {
          if (this.showCamera) {
            GridItem() {
              this.cameraCell()
            }
          }
          ForEach(this.photos, (item: PickerPhotoItem, index: number) => {
            GridItem() {
              this.photoCell(item, index)
            }
          }, (item: PickerPhotoItem, index: number) => item.uri + '_' + String(index))
        }
        .columnsTemplate('1fr 1fr 1fr')
        .columnsGap(1)
        .rowsGap(1)
        .width('100%')
        .constraintSize({ maxWidth: BreakpointSystem.getContentMaxWidth(this.currentBreakpoint) })
        .layoutWeight(1)
        .backgroundColor($r('app.color.ybg_white'))
      } else {
        Scroll() {
          Column() {
            Text('点击下方“所有图片”选择照片')
              .fontSize(14)
              .fontColor($r('app.color.common_color_3'))
          }
          .width('100%')
          .padding({ top: 80, bottom: 24 })
          .alignItems(HorizontalAlign.Center)
        }
        .width('100%')
        .constraintSize({ maxWidth: BreakpointSystem.getContentMaxWidth(this.currentBreakpoint) })
        .layoutWeight(1)
        .scrollBar(BarState.Off)
      }

      Row() {
        Text('所有图片')
          .fontSize(14)
          .fontColor($r('app.color.common_color_1'))
          .padding(10)
          .onClick(() => {
            this.pickFromGallery();
          })
        Blank()
        Text(this.selectCount > 0 ? '预览(' + String(this.selectCount) + ')' : '预览')
          .fontSize(14)
          .fontColor(this.selectCount > 0 ? $r('app.color.common_color_1') : $r('app.color.common_color_3'))
          .padding(10)
          .enabled(this.selectCount > 0)
          .onClick(() => {
            this.openPager(0);
          })
      }
      .width('100%')
      .constraintSize({ maxWidth: BreakpointSystem.getContentMaxWidth(this.currentBreakpoint) })
      .padding({
        left: Math.max(5, this.avoidAreaLeftVp),
        right: Math.max(5, this.avoidAreaRightVp),
        top: 5,
        bottom: Math.max(5, this.avoidAreaBottomVp)
      })
      .alignItems(VerticalAlign.Center)
      .backgroundColor($r('app.color.ybg_white'))
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.ybg_white'))
  }
}
