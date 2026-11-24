import { router } from '@kit.ArkUI';
import { BusinessError } from '@kit.BasicServicesKit';
import { photoAccessHelper } from '@kit.MediaLibraryKit';
import { fileIo as fs } from '@kit.CoreFileKit';
import { TitleBar } from '../components/TitleBar';
import { EmptyView } from '../components/EmptyView';
import { LoadingView } from '../components/LoadingView';
import { ApiService } from '../network/ApiService';
import { ApiResponse } from '../model/ResponseModel';
import { SchoolSceneryItem } from '../model/ContactModel';
import { LoginSession } from '../network/LoginSession';
import { BreakpointSystem } from '../common/BreakpointSystem';
import { AdaptiveLayoutHelper } from '../common/AdaptiveLayoutHelper';
import { VisionEnhancementHelper, VisionCaptionCandidate } from '../common/VisionEnhancementHelper';

/**
 * 校园风光 — SchoolSceneryActivity + SchoolSceneryFragment + SchoolSceneryAdapter 源码级翻译。
 *
 * 【入口】APK ARouter `/school/scenery`（ARouter$$Group$$school L17）；宫格 yyid=schoolScenery。
 * 【结构】mobile_campus_school_activity_scenery：toolbar_normal（标题"校园风光"，T1 若会话有效
 *   gVar.k(mobile_campus_school_cam) 相机图标）+ TabLayout 高 36vp（px_to_dip_72，tabMaxWidth 72dip、
 *   marginH 32dip、选中/indicator mobile_campus_primary_color_default、未选中 common_color_3）+ ViewPager。
 *   页签={"最新"(newest),"最热"(hottest)}，lifemanager.d.b.b()（session_key 非空）时追加"我的"(my)。
 * 【列表】mobile_campus_school_fragment_scenery：PullToRefresh + RecyclerView StaggeredGrid 2 列，
 *   padding 7dip + SpacesItemDecoration 7dip；item 高 = HEIGHT*165dp/WIDTH（width 空→屏宽）。
 * 【条目】mobile_campus_school_view_scenery：centerCrop 图 + 底部 #4d000000 24dip 条：
 *   tvLikeNum 白字 drawableLeft mobile_campus_school_like drawablePadding 8dip / tvTitle 白字右对齐。
 *   署名：非"my"或 verifyState!="1" → XM；my+VERIFY 空/1 → 当前用户名；2→"审核中"；其他→"未通过"。
 * 【交互】ISLIKE==0 点击点赞 addLike{PICID}：data=="true"→ISLIKE=1/LIKE_COUNT++/toast"点赞成功"，
 *   否则"点赞失败"；条目点击 BrowsePhotosActivity（photoUrlList=[PIC_URL]，DELETE 仅 my）。
 *   上传：F0(131) 相册 → 弹窗"确认上传选中图片？" → addMyPIC keyName="imgs" →
 *   data=="1"→toast"上传成功 "并切到最后一页（我的）；否则"上传失败 "。
 */
const TAB_KEYS: string[] = ['newest', 'hottest', 'my'];
const TAB_LABELS: string[] = ['最新', '最热', '我的'];

/** 源码 f1()：lifemanager.d.b.b()（session_key 非空）才追加"我的"页签与相机图标 */
function tabKeysForSession(hasSession: boolean): string[] {
  return hasSession ? TAB_KEYS : TAB_KEYS.slice(0, 2);
}

@Entry
@Component
struct SchoolSceneryPage {
  @State photos: SchoolSceneryItem[] = [];
  @State activeTab: string = 'newest';
  @State isLoading: boolean = true;
  @State loadError: string = '';
  @State currentIndex: number = 0;
  @State searchKeyword: string = '';
  @State aiMatchedPaths: string[] = [];
  @StorageProp('currentBreakpoint') currentBreakpoint: string = 'sm';
  @StorageProp('windowWidthVp') windowWidthVp: number = 360;
  @StorageProp('avoidAreaBottomVp') avoidAreaBottomVp: number = 0;
  private canUpload: boolean = LoginSession.sessionKey !== '';
  private pendingPics: string[] = [];

  private getFlowCols(): number {
    return BreakpointSystem.getGridColumns(this.currentBreakpoint, 2);
  }

  aboutToAppear(): void {
    this.loadPhotos('newest');
  }

  onPageShow(): void {
    this.consumeBrowseResult();
  }

  /** 源码 Y1()：presenter.k(type) → SchoolModel.W0 明文 GET；空列表 EMPTY / 失败 ERROR */
  private loadPhotos(type: string): void {
    this.isLoading = true;
    this.loadError = '';
    ApiService.getSchoolSceneryList(type)
      .then((response: ApiResponse<SchoolSceneryItem[]>) => {
        if (response.code === 1000) {
          return;
        }
        if (response.code === 0) {
          this.photos = response.data;
        } else {
          this.photos = [];
          this.loadError = response.message;
        }
        this.isLoading = false;
      })
      .catch((error: BusinessError) => {
        ApiService.logError('SchoolScenery load fail: ' + error.message);
        this.photos = [];
        this.loadError = '网络异常，请稍后重试';
        this.isLoading = false;
      });
  }

  private switchTab(index: number): void {
    const next: string = TAB_KEYS[index];
    if (next === this.activeTab) {
      return;
    }
    this.activeTab = next;
    this.currentIndex = 0;
    this.loadPhotos(next);
  }

  /** 源码 onBindViewHolder：按当前瀑布流列宽与原始宽高比等比缩放条目高度 */
  private itemHeight(item: SchoolSceneryItem): number {
    const cols: number = this.getFlowCols();
    const maxWProp: number | string = BreakpointSystem.getContentMaxWidth(this.currentBreakpoint);
    const maxW: number = typeof maxWProp === 'number' ? maxWProp : this.windowWidthVp;
    const colW: number = AdaptiveLayoutHelper.computeWaterFlowColWidthVp(this.windowWidthVp, maxW, cols, 7);
    const rawW: number = item.WIDTH === '' ? 375 : Number(item.WIDTH);
    const rawH: number = item.HEIGHT === '' ? 0 : Number(item.HEIGHT);
    return AdaptiveLayoutHelper.computeAspectScaledHeightVp(rawW, rawH, colW, colW);
  }

  /** 源码署名分支：非 my 或 verifyState != "1" → XM；my+VERIFY 空/1 → 当前用户名；2 审核中；其他 未通过 */
  private titleText(item: SchoolSceneryItem): string {
    if (this.activeTab !== 'my' || item.verifyState !== '1') {
      return item.XM;
    }
    if (item.VERIFY === '' || item.VERIFY === '1') {
      return LoginSession.sessionName;
    }
    return item.VERIFY === '2' ? '审核中' : '未通过';
  }

  /** 源码 e 类：ISLIKE==1 点不动；成功 data=="true" → ISLIKE=1 + LIKE_COUNT++ + toast */
  private onLike(item: SchoolSceneryItem, index: number): void {
    if (item.ISLIKE === 1) {
      return;
    }
    ApiService.addCampusLike(item.PICID)
      .then((response: ApiResponse<string>) => {
        if (response.code !== 0) {
          this.toast(response.message === '' ? '点赞失败' : response.message);
          return;
        }
        if (response.data === 'true') {
          const next: SchoolSceneryItem[] = this.photos.slice();
          const one: SchoolSceneryItem = next[index];
          one.ISLIKE = 1;
          one.LIKE_COUNT = one.LIKE_COUNT + 1;
          this.photos = next;
          this.toast('点赞成功');
        } else {
          this.toast('点赞失败');
        }
      })
      .catch((error: BusinessError) => {
        ApiService.logError('addLike fail: ' + error.message);
        this.toast('点赞失败');
      });
  }

  private openPhoto(index: number): void {
    this.currentIndex = index;
    const urls: string[] = this.photos.map((p: SchoolSceneryItem): string => p.PIC_URL);
    AppStorage.setOrCreate<boolean>('school_scenery_browse_pending', true);
    router.pushUrl({
      url: 'pages/BrowsePhotosPage',
      params: {
        'photoUrlList': urls,
        'startPosition': index,
        'extraOperation': this.activeTab === 'my' ? 'delete' : 'none'
      } as Record<string, Object>
    });
  }

  /** 源码 onActivityResult(4818)：my 页返回空列表且 U1()（当前 PICID）非空 → delMyPic 刷新 */
  private consumeBrowseResult(): void {
    const pending: boolean | undefined = AppStorage.get<boolean>('school_scenery_browse_pending');
    if (pending !== true) {
      return;
    }
    AppStorage.setOrCreate<boolean>('school_scenery_browse_pending', false);
    const result: string[] | undefined = AppStorage.get<string[]>('browse_photos_result');
    if (result === undefined) {
      return;
    }
    AppStorage.setOrCreate<string[]>('browse_photos_result', []);
    if (this.activeTab !== 'my' || this.photos.length === 0) {
      return;
    }
    if (result.length === 0 && this.photos[this.currentIndex].PICID !== '') {
      this.deleteCurrentPic(this.photos[this.currentIndex].PICID);
    }
  }

  private deleteCurrentPic(picId: string): void {
    ApiService.deleteCampusPic(picId)
      .then((response: ApiResponse<Object>) => {
        if (response.code === 0) {
          this.loadPhotos(this.activeTab);
        }
      })
      .catch((error: BusinessError) => ApiService.logError('delMyPic fail: ' + error.message));
  }

  /** 源码 a 类 F0(131)：相册选择 → 弹窗"确认上传选中图片？" → addMyPIC */
  private pickAndUpload(): void {
    const picker: photoAccessHelper.PhotoViewPicker = new photoAccessHelper.PhotoViewPicker();
    const options: photoAccessHelper.PhotoSelectOptions = {
      MIMEType: photoAccessHelper.PhotoViewMIMETypes.IMAGE_TYPE,
      maxSelectNumber: 9
    };
    picker.select(options)
      .then((result: photoAccessHelper.PhotoSelectResult) => {
        if (result.photoUris.length === 0) {
          return;
        }
        this.pendingPics = result.photoUris.map((uri: string): string => this.copyUriToCache(uri));
        this.confirmUpload();
      })
      .catch((error: BusinessError) => ApiService.logError('scenery picker fail: ' + error.message));
  }

  private confirmUpload(): void {
    this.getUIContext().showAlertDialog({
      title: '',
      message: '确认上传选中图片？',
      primaryButton: { value: '取消', action: (): void => { this.pendingPics = []; } },
      secondaryButton: { value: '确认', action: (): void => { this.doUpload(); } }
    });
  }

  private doUpload(): void {
    if (this.pendingPics.length === 0) {
      return;
    }
    ApiService.uploadCampusPhotos(this.pendingPics)
      .then((response: ApiResponse<string>) => {
        this.pendingPics = [];
        if (response.code === 0 && response.data === '1') {
          this.toast('上传成功 ');
          this.activeTab = 'my';
          this.currentIndex = 0;
          this.loadPhotos('my');
        } else {
          this.toast('上传失败 ');
        }
      })
      .catch((error: BusinessError) => {
        this.pendingPics = [];
        ApiService.logError('addMyPIC fail: ' + error.message);
        this.toast('上传失败 ');
      });
  }

  /** media uri → 沙箱 cache 文件（multipart 上传需要真实路径） */
  private copyUriToCache(uri: string): string {
    try {
      const ctx: Context = this.getUIContext().getHostContext() as Context;
      const fileName: string = 'scenery_' + Date.now() + '_' + String(Math.floor(Math.random() * 9000) + 1000) + '.jpg';
      const target: string = ctx.cacheDir + '/' + fileName;
      const src: fs.File = fs.openSync(uri, fs.OpenMode.READ_ONLY);
      const dst: fs.File = fs.openSync(target, fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE | fs.OpenMode.TRUNC);
      try {
        fs.copyFileSync(src.fd, dst.fd);
      } finally {
        fs.closeSync(src);
        fs.closeSync(dst);
      }
      VisionEnhancementHelper.indexImageForTextSearch(target);
      return target;
    } catch (error) {
      const err = error as BusinessError;
      ApiService.logError('scenery cache copy fail: ' + err.message);
      return uri;
    }
  }

  private toast(message: string): void {
    this.getUIContext().getPromptAction().showToast({ message: message, duration: 2000 });
  }

  private displayedPhotos(): SchoolSceneryItem[] {
    const kw: string = VisionEnhancementHelper.sanitizeSearchQuery(this.searchKeyword);
    if (kw === '') {
      return this.photos;
    }
    const candidates: VisionCaptionCandidate[] =
      this.photos.map((p: SchoolSceneryItem): VisionCaptionCandidate => {
        const item: VisionCaptionCandidate = {
          id: p.PICID,
          title: this.titleText(p),
          imagePath: p.PIC_URL
        };
        return item;
      });
    const matchedIds: string[] = VisionEnhancementHelper.matchCaptionsFallback(kw, candidates);
    const idSet: Set<string> = new Set<string>(matchedIds);
    const pathSet: Set<string> = new Set<string>(this.aiMatchedPaths);
    return this.photos.filter((p: SchoolSceneryItem): boolean => {
      return idSet.has(p.PICID) || pathSet.has(p.PIC_URL);
    });
  }

  private async triggerVisionSearch(): Promise<void> {
    const kw: string = VisionEnhancementHelper.sanitizeSearchQuery(this.searchKeyword);
    if (kw === '') {
      this.aiMatchedPaths = [];
      return;
    }
    const res = await VisionEnhancementHelper.searchImagesByText(kw);
    if (res.supported && res.items.length > 0) {
      this.aiMatchedPaths = res.items.map((it) => it.imagePath);
    } else {
      this.aiMatchedPaths = [];
    }
  }

  @Builder
  sceneryItem(item: SchoolSceneryItem, index: number) {
    Stack({ alignContent: Alignment.Bottom }) {
      Image(item.PIC_URL)
        .width('100%')
        .height(this.itemHeight(item))
        .objectFit(ImageFit.Cover)
        .alt($r('app.media.default_avatar'))
      Row() {
        Row() {
          Image($r('app.media.mobile_campus_school_like'))
            .width(14)
            .height(14)
          Text(String(item.LIKE_COUNT))
            .fontSize(12)
            .fontColor($r('app.color.white'))
            .margin({ left: 4 })
        }
        .hoverEffect(HoverEffect.Highlight)
        .onClick((): void => { this.onLike(item, index); })
        Text(this.titleText(item))
          .fontSize(12)
          .fontColor($r('app.color.white'))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .margin({ left: 8 })
          .layoutWeight(1)
          .textAlign(TextAlign.End)
      }
      .width('100%')
      .height(24)
      .padding({ left: 16, right: 16 })
      .backgroundColor('#4D000000')
    }
    .width('100%')
    .borderRadius(2)
    .clip(true)
    .hoverEffect(HoverEffect.Highlight)
    .onClick((): void => { this.openPhoto(index); })
  }

  build() {
    Column() {
      TitleBar({
        title: '校园风光',
        showBack: true,
        rightIcon: this.canUpload ? $r('app.media.mobile_campus_school_cam') : null,
        onRightClick: (): void => { this.pickAndUpload(); }
      })
      Row() {
        Row() {
          ForEach(tabKeysForSession(this.canUpload), (key: string, index: number) => {
            Column() {
              Text(TAB_LABELS[index])
                .fontSize(15)
                .fontColor(this.activeTab === key ? $r('app.color.blue_default') : $r('app.color.common_color_3'))
                .height(34)
                .textAlign(TextAlign.Center)
              Divider()
                .color(this.activeTab === key ? $r('app.color.blue_default') : Color.Transparent)
                .strokeWidth(2)
                .width('60%')
            }
            .height(36)
            .layoutWeight(1)
            .hoverEffect(HoverEffect.Highlight)
            .onClick((): void => { this.switchTab(index); })
          }, (key: string) => key)
        }
        .width('100%')
        .height(36)
        .constraintSize({ maxWidth: BreakpointSystem.getContentMaxWidth(this.currentBreakpoint) })
      }
      .width('100%')
      .height(36)
      .justifyContent(FlexAlign.Center)
      .backgroundColor($r('app.color.white'))

      Row() {
        Row({ space: 8 }) {
          Search({ value: this.searchKeyword, placeholder: 'AI文搜图 / 作者关键词筛选' })
            .layoutWeight(1)
            .height(32)
            .textFont({ size: 13 })
            .placeholderFont({ size: 13 })
            .onChange((val: string) => {
              this.searchKeyword = val;
              if (val.trim() === '') {
                this.aiMatchedPaths = [];
              }
            })
            .onSubmit(() => {
              this.triggerVisionSearch();
            })
        }
        .width('100%')
        .padding({ left: 10, right: 10, top: 4, bottom: 4 })
        .constraintSize({ maxWidth: BreakpointSystem.getContentMaxWidth(this.currentBreakpoint) })
      }
      .width('100%')
      .justifyContent(FlexAlign.Center)
      .backgroundColor($r('app.color.white'))

      if (this.isLoading) {
        LoadingView()
      } else if (this.loadError !== '') {
        Scroll() {
          Column({ space: 12 }) {
            EmptyView({ tipText: this.loadError })
            Button('重试')
              .fontSize(14)
              .backgroundColor($r('app.color.ybg_blue'))
              .fontColor($r('app.color.white'))
              .hoverEffect(HoverEffect.Highlight)
              .onClick((): void => { this.loadPhotos(this.activeTab); })
          }
          .width('100%')
          .constraintSize({ minHeight: 320 })
          .justifyContent(FlexAlign.Center)
        }
        .width('100%')
        .layoutWeight(1)
      } else if (this.displayedPhotos().length === 0) {
        Scroll() {
          Column() {
            EmptyView({ tipText: this.searchKeyword.trim() !== '' ? '未找到匹配的校园风光' : (this.activeTab === 'my' ? '你还没上传过照片哦' : '暂无校园风光') })
          }
          .width('100%')
          .constraintSize({ minHeight: 320 })
          .justifyContent(FlexAlign.Center)
        }
        .width('100%')
        .layoutWeight(1)
      } else {
        Row() {
          WaterFlow() {
            ForEach(this.displayedPhotos(), (item: SchoolSceneryItem, index: number) => {
              FlowItem() {
                this.sceneryItem(item, index)
              }
            }, (item: SchoolSceneryItem) => item.PICID)
          }
          .columnsTemplate(AdaptiveLayoutHelper.buildColumnsTemplate(this.getFlowCols()))
          .columnsGap(7)
          .rowsGap(7)
          .padding({ left: 7, right: 7, top: 7, bottom: Math.max(7, this.avoidAreaBottomVp) })
          .width('100%')
          .height('100%')
          .constraintSize({ maxWidth: BreakpointSystem.getContentMaxWidth(this.currentBreakpoint) })
          .scrollBar(BarState.Off)
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.common_color_6'))
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.BOTTOM])
  }
}
