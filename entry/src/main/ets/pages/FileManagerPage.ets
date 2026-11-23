import { common } from '@kit.AbilityKit';
import { fileIo as fs } from '@kit.CoreFileKit';
import { PdfView, pdfService, pdfViewManager } from '@kit.PDFKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { TitleBar } from '../components/TitleBar';
import { ApiService } from '../network/ApiService';
import { FilePreviewHelper } from '../common/FilePreviewHelper';
import { BreakpointSystem } from '../common/BreakpointSystem';
import { AdaptiveLayoutHelper } from '../common/AdaptiveLayoutHelper';

/**
 * 下载文件管理页 — 源码级翻译（FileManagerActivity.java + FileListAdapter 逐行 → ArkTS，
 * [W26 partial-finish]；原静态空列表替换为真实下载目录扫描与文件操作）：
 *
 * 【目录】源码 baseapp/a/a/b/d.java 静态块 i = {Downloads/<app_name>, externalCacheDir/todo,
 *   externalCacheDir/meeting}。HAP 沙箱无公共 Download 共享目录 → 等价映射：
 *   filesDir/download（APK 公共下载目录/山东管理学院 的应用私有下载根）、cacheDir/todo（OA 待办附件）、
 *   cacheDir/meeting（会议附件）。
 * 【扫描】S2()：遍历目录 T2(str)：list() 非目录文件 → FileEntity{isFile:true, filePath, fileName,
 *   stamp=lastModified, createTime="yyyy-MM-dd HH:mm:ss"}；Collections.sort 按 stamp 降序；
 *   空 → MultiStateView 空态。z2(SwipeRefresh)（HAP 等价 onShow 重扫）。
 * 【交互】FileListAdapter.d.a(i, cb) 长按：非选择模式 → 进入选择模式（p 清空 + 选中本项 + U2(true)
 *   显"删除"）；d.b(i, cb) 单击：选择模式 → toggle 勾选 + 全选框同步；非选择模式 → r.n(filePath)
 *   打开（HAP startAbility ohos.want.action.viewData，失败 → toast "不支持打开"）。
 * 【删除】"删除" → p.size()==0 → toast "当前无选定文件！"；否则对话框 "确定删除选定文件？"
 *   → 逐个 File.delete() → 清空重扫 → U2(false)。
 * 【全选】cb_select_all：已全选 → 清空；否则全选。
 * 【返回】onBackPressed：选择模式 → 退出选择模式（e(false)+p.clear+U2(false)）；否则默认。
 * 【工具栏】T1：标题 mobile_campus_file_manage + "删除"（初始 setVisibility(8)）。
 */
/** 源码 FileEntity（fileName/stamp/createTime/filePath/isFile） */
class DownloadFile {
  name: string = '';
  createTime: string = '';
  filePath: string = '';
  stamp: number = 0;

  constructor(name: string, createTime: string, filePath: string, stamp: number) {
    this.name = name;
    this.createTime = createTime;
    this.filePath = filePath;
    this.stamp = stamp;
  }
}

/** 源码 SimpleDateFormat("yyyy-MM-dd HH:mm:ss").format(lastModified) 逐字段等价 */
function formatStamp(stamp: number): string {
  const d: Date = new Date(stamp);
  const pad = (n: number): string => (n < 10 ? '0' + String(n) : String(n));
  return String(d.getFullYear()) + '-' + pad(d.getMonth() + 1) + '-' + pad(d.getDate()) +
    ' ' + pad(d.getHours()) + ':' + pad(d.getMinutes()) + ':' + pad(d.getSeconds());
}

@Entry
@Component
struct FileManagerPage {
  @State files: DownloadFile[] = [];
  /** 源码 n.d()：选择模式开关 */
  @State selectMode: boolean = false;
  /** 源码 p：SparseArray<Boolean> → 选中文件路径集合 */
  @State selected: Set<string> = new Set<string>();
  /** 源码 s.setChecked：全选框状态 */
  @State allSelected: boolean = false;
  /** 源码 U2(z)：删除按钮 + 全选框显隐 */
  /** 源码 U2：删除按钮 + 全选框显隐 */
  @State showToolbar: boolean = false;
  @State showPdfModal: boolean = false;
  @State pdfTitle: string = '';
  @State pendingPdfPath: string = '';
  @StorageProp('currentBreakpoint') currentBreakpoint: string = 'sm';
  @StorageProp('windowWidthVp') windowWidthVp: number = 360;
  @StorageProp('windowHeightVp') windowHeightVp: number = 780;
  @StorageProp('avoidAreaBottomVp') avoidAreaBottomVp: number = 0;
  private pdfController: pdfViewManager.PdfController = new pdfViewManager.PdfController();

  aboutToAppear(): void {
    this.rescan();
  }

  aboutToDisappear(): void {
    this.closePdfModal();
  }

  private closePdfModal(): void {
    this.pendingPdfPath = '';
    if (this.showPdfModal) {
      this.showPdfModal = false;
      try {
        this.pdfController.releaseDocument();
      } catch {
        // 忽略释放异常
      }
    }
  }

  private async loadPendingPdf(): Promise<void> {
    const path: string = this.pendingPdfPath;
    if (path === '') {
      return;
    }
    try {
      const parseRes = await this.pdfController.loadDocument(path);
      if (parseRes !== pdfService.ParseResult.PARSE_SUCCESS) {
        this.getUIContext().getPromptAction().showToast({ message: 'PDF 文档解析失败' });
      }
    } catch {
      this.getUIContext().getPromptAction().showToast({ message: 'PDF 文档加载失败' });
    }
  }

  /** 源码 S2()：三目录收集 + stamp 降序 + 空态判定 */
  private rescan(): void {
    const context = this.getUIContext().getHostContext() as common.UIAbilityContext;
    // 源码 d.i：{Downloads/<app_name>, externalCacheDir/todo, externalCacheDir/meeting} 沙箱等价
    const dirs: string[] = [
      context.filesDir + '/download',
      context.cacheDir + '/todo',
      context.cacheDir + '/meeting'
    ];
    const out: DownloadFile[] = [];
    for (const dir of dirs) {
      this.collectDir(dir, out);
    }
    // 源码 Collections.sort(o, b)：stamp 降序（fileEntity2.stamp - fileEntity.stamp > 0 ? 1 : -1）
    out.sort((a: DownloadFile, b2: DownloadFile): number => b2.stamp - a.stamp);
    this.files = out;
    this.selected = new Set<string>();
    this.allSelected = false;
  }

  /** 源码 T2(str)：list() 非目录文件 → FileEntity（目录不存在/空 → return） */
  private collectDir(dir: string, out: DownloadFile[]): void {
    let names: string[] = [];
    try {
      names = fs.listFileSync(dir);
    } catch (error) {
      const be = error as BusinessError;
      // 目录不存在（尚未产生附件下载）→ 与 APK File.list()==null 分支一致：静默跳过
      ApiService.logError('FileManagerPage list fail dir=' + dir + ' code=' + be.code);
      return;
    }
    if (names.length <= 0) {
      return;
    }
    for (const name of names) {
      const filePath: string = dir + '/' + name;
      try {
        const stat: fs.Stat = fs.statSync(filePath);
        if (stat.isDirectory()) {
          continue;
        }
        const stamp: number = stat.mtime;
        out.push(new DownloadFile(name, formatStamp(stamp), filePath, stamp));
      } catch (error) {
        const be = error as BusinessError;
        ApiService.logError('FileManagerPage stat fail ' + filePath + ' code=' + be.code);
      }
    }
  }

  /** 源码 d.a(i, cb) 长按：进入选择模式并选中本项 */
  private onItemLongPress(file: DownloadFile): void {
    if (this.selectMode) {
      return;
    }
    this.selected = new Set<string>([file.filePath]);
    this.selectMode = true;
    this.showToolbar = true;
    this.allSelected = this.selected.size >= this.files.length && this.files.length > 0;
  }

  /** 源码 d.b(i, cb) 单击：选择模式 toggle / 非选择模式打开 */
  private onItemClick(file: DownloadFile): void {
    if (this.selectMode) {
      const next: Set<string> = new Set<string>(this.selected);
      if (next.has(file.filePath)) {
        next.delete(file.filePath);
      } else {
        next.add(file.filePath);
      }
      this.selected = next;
      this.allSelected = next.size >= this.files.length && this.files.length > 0;
      return;
    }
    this.openFile(file);
  }

  /** 源码 r.n(filePath)：PreviewKit / PdfView / Want 打开；失败 → toast */
  private async openFile(file: DownloadFile): Promise<void> {
    const context = this.getUIContext().getHostContext() as common.UIAbilityContext;
    const res = await FilePreviewHelper.openLocalFilePreview(context, file.filePath, file.name);
    if (res.success) {
      return;
    }
    if (res.method === 'pdfView') {
      this.pendingPdfPath = file.filePath;
      this.pdfTitle = file.name;
      this.showPdfModal = true;
      return;
    }
    this.getUIContext().getPromptAction().showToast({ message: res.message !== '' ? res.message : '不支持打开' });
  }

  /** 源码 e.onClick 全选：已全选 → 清空；否则全选 */
  private toggleSelectAll(): void {
    if (this.selected.size >= this.files.length && this.files.length > 0) {
      this.selected = new Set<string>();
      this.allSelected = false;
      return;
    }
    const next: Set<string> = new Set<string>();
    for (const f of this.files) {
      next.add(f.filePath);
    }
    this.selected = next;
    this.allSelected = true;
  }

  /** 源码 d.onClick "删除"：无选中 → toast；有选中 → 确认对话框 */
  private onDeleteClick(): void {
    if (this.selected.size === 0) {
      this.getUIContext().getPromptAction().showToast({ message: '当前无选定文件！' });
      return;
    }
    this.getUIContext().showAlertDialog({
      title: '',
      message: '确定删除选定文件？',
      primaryButton: {
        value: '取消',
        action: () => {
        }
      },
      secondaryButton: {
        value: '确定',
        action: () => {
          this.deleteSelected();
        }
      }
    });
  }

  /** 源码 d.a.a()：逐个 File.delete() → 清空重扫 → U2(false) */
  private deleteSelected(): void {
    for (const path of this.selected) {
      try {
        fs.unlinkSync(path);
      } catch (error) {
        const be = error as BusinessError;
        ApiService.logError('FileManagerPage delete fail ' + path + ' code=' + be.code);
      }
    }
    this.selectMode = false;
    this.showToolbar = false;
    this.rescan();
  }

  /** 源码 onBackPressed：选择模式 → 退出选择模式 */
  private exitSelectMode(): void {
    this.selectMode = false;
    this.selected = new Set<string>();
    this.showToolbar = false;
    this.allSelected = false;
  }

  build() {
    Stack() {
      Column() {
        TitleBar({ title: '下载文件管理', showBack: true })

        // 源码 U2：删除按钮（工具栏右侧 m("删除")）+ 全选框（cb_select_all）
        Row() {
          if (this.showToolbar) {
            Row() {
              Text('全选')
                .fontSize(14)
                .fontColor($r('app.color.common_color_1'))
                .padding({ left: 15, right: 8 })
                .hoverEffect(HoverEffect.Highlight)
                .onClick(() => {
                  this.toggleSelectAll();
                })
              Text('删除')
                .fontSize(14)
                .fontColor($r('app.color.ybg_red'))
                .padding({ left: 8, right: 15 })
                .hoverEffect(HoverEffect.Highlight)
                .onClick(() => {
                  this.onDeleteClick();
                })
            }
            .width('100%')
            .height(44)
            .justifyContent(FlexAlign.End)
            .alignItems(VerticalAlign.Center)
            .backgroundColor($r('app.color.white'))
            .constraintSize({ maxWidth: BreakpointSystem.getContentMaxWidth(this.currentBreakpoint) })
          }
        }
        .width('100%')
        .justifyContent(FlexAlign.Center)

        if (this.files.length === 0) {
          // 源码 q2(this.r)：MultiStateView 空态（empty_view 12fp #CECECE padding 15）
          Column() {
            Text('暂无下载文件')
              .fontSize(12)
              .fontColor($r('app.color.common_color_4'))
              .padding(15)
          }
          .width('100%')
          .layoutWeight(1)
          .justifyContent(FlexAlign.Center)
          .backgroundColor($r('app.color.main_bg'))
        } else {
          List() {
            ForEach(this.files, (file: DownloadFile) => {
              ListItem() {
                Row() {
                  // rb_select：选择模式下显示 CheckBox
                  if (this.selectMode) {
                    Checkbox({ name: file.filePath })
                      .select(this.selected.has(file.filePath))
                      .selectedColor($r('app.color.sdmu_primary'))
                      .width(20)
                      .height(20)
                      .margin({ left: 15 })
                  } else {
                    Row()
                      .width(20)
                      .height(20)
                      .margin({ left: 15 })
                  }

                  // 文件类型图标（FileListAdapter 固定 word 图标）
                  Image($r('app.media.mobile_campus_oa_word'))
                    .width(32)
                    .height(32)
                    .margin({ left: 20, right: 24 })

                  Column() {
                    Text(file.name)
                      .fontSize(17.5)
                      .fontColor($r('app.color.common_color_1'))
                      .maxLines(1)
                      .textOverflow({ overflow: TextOverflow.Ellipsis })
                    Text(file.createTime)
                      .fontSize(11.5)
                      .fontColor($r('app.color.common_color_1'))
                      .margin({ top: 2 })
                  }
                  .alignItems(HorizontalAlign.Start)
                  .layoutWeight(1)
                }
                .width('100%')
                .padding({ top: 10, bottom: 10, right: 12 })
                .alignItems(VerticalAlign.Center)
                .backgroundColor($r('app.color.white'))
                .hoverEffect(HoverEffect.Highlight)
                .onClick(() => {
                  this.onItemClick(file);
                })
                // Row 无 onLongClick 属性（首轮构建 10505001 实证）→ LongPressGesture 等价
                .gesture(LongPressGesture({ repeat: false, duration: 500 })
                  .onAction(() => {
                    this.onItemLongPress(file);
                  }))
              }
            }, (file: DownloadFile) => file.filePath + '_' + String(file.stamp))
          }
          .width('100%')
          .constraintSize({ maxWidth: BreakpointSystem.getContentMaxWidth(this.currentBreakpoint) })
          .padding({ bottom: this.avoidAreaBottomVp })
          .layoutWeight(1)
          .backgroundColor($r('app.color.main_bg'))
        }
      }
      .width('100%')
      .height('100%')
      .alignItems(HorizontalAlign.Center)
      .backgroundColor($r('app.color.main_bg'))

      if (this.showPdfModal) {
        this.pdfPreviewOverlay()
      }
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  pdfPreviewOverlay() {
    Column() {
      Column() {
        Row() {
          Text(this.pdfTitle)
            .fontSize(15)
            .fontWeight(FontWeight.Medium)
            .fontColor($r('app.color.common_color_1'))
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .layoutWeight(1)
          Text('关闭')
            .fontSize(14)
            .fontColor('#3A92ED')
            .padding({ left: 10, right: 4, top: 4, bottom: 4 })
            .hoverEffect(HoverEffect.Highlight)
            .onClick(() => {
              this.closePdfModal();
            })
        }
        .width('100%')
        .padding({ left: 14, right: 14, top: 10, bottom: 10 })
        .backgroundColor($r('app.color.white'))

        Divider().color($r('app.color.common_color_5')).strokeWidth(0.5).width('100%')

        PdfView({
          controller: this.pdfController,
          pageLayout: pdfService.PageLayout.LAYOUT_SINGLE,
          isContinuous: true,
          showScroll: true
        })
          .width('100%')
          .layoutWeight(1)
          .onAppear(() => {
            this.loadPendingPdf();
          })
      }
      .width(AdaptiveLayoutHelper.getDialogMaxWidth(this.currentBreakpoint, this.windowWidthVp))
      .height(AdaptiveLayoutHelper.getDialogMaxHeight(this.windowHeightVp))
      .backgroundColor($r('app.color.white'))
      .borderRadius(10)
      .clip(true)
      .onClick(() => {
        // 拦截点击
      })
    }
    .width('100%')
    .height('100%')
    .padding({ left: 16, right: 16 })
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .backgroundColor('#66000000')
    .onClick(() => {
      this.closePdfModal();
    })
  }

  /** 源码 onBackPressed：选择模式 → 退出选择模式；否则默认返回 */
  onBackPress(): boolean {
    if (this.showPdfModal) {
      this.closePdfModal();
      return true;
    }
    if (!this.selectMode) {
      return false;
    }
    this.exitSelectMode();
    return true;
  }
}
