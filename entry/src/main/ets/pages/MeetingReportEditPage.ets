import { router } from '@kit.ArkUI';
import { cameraPicker, camera } from '@kit.CameraKit';
import { photoAccessHelper } from '@kit.MediaLibraryKit';
import { Context } from '@kit.AbilityKit';
import { fileIo as fs } from '@kit.CoreFileKit';
import { TitleBar } from '../components/TitleBar';
import { ApiService } from '../network/ApiService';
import { ApiResponse } from '../model/ResponseModel';
import { BusinessError } from '@kit.BasicServicesKit';
import { Constants } from '../data/Constants';

/**
 * 会议报告编辑页 — MeetingReportEditActivity.java(420行) 源码级翻译
 * 【源码链路】MeetingReportShowActivity.d3()（底部"编辑会议报告"）→ bundle{HYID, MEETING_CONTENT,
 *   PIC, MEETING_XLH, STATE} → /meeting/edit（e.a.i0）。
 * 【布局】mobile_campus_meeting_activity_report_edit.xml：toolbar（右"完成" toolBar_text_but：
 *   mobile_campus_meeting_report_save 背景 61×26dip，enabled ybg_blue/disabled common_color_24=#CCCCCC
 *   圆角 px_to_dip_8=4，r1 白字#ffffff/黑字#000000）+ edit_content（白底 paddingTop/Bottom 20
 *   paddingLeft/Right 25，gravity center|left|top，layoutWeight 1）+ 底部 RelativeLayout 40dip
 *   （image_camera marginLeft 13 + image_album marginLeft 15）+ photoAdapter RecyclerView 横向
 *   （padding 4；photo item 75×75 margin 7.5 + delete_icon 右上 padL4 padB4）。
 * 【数据】y(intent)：MEETING_CONTENT/PIC/MEETING_XLH/STATE/HYID；PIC 非空 → s=oldPicXLH。
 *   g3 预填：MEETING_CONTENT + PIC 按逗号拆分图片列表（服务器图 ID → URL=host+/mobileapi_ydxy/open/image/+id，
 *   源码 MeetingReportPhotoAdapter.f11738d）。
 * 【交互】
 *   - TextWatcher：trim 空 → r1(false) 完成禁用。
 *   - 相机 d.onClick：图片数≥9 → "不能上传超过9张图片"；cameraPicker → onActivityResult(1) →
 *     data.add(0, 照片路径)（HAP：cameraPicker.launch → 沙箱 cache 拷贝）。
 *   - 相册 e.onClick：z2 权限后 → b(9-count) PhotoViewPicker → onActivityResult(59733) →
 *     SELECTED_PHOTOS 逐个加入（HAP：PhotoViewPicker maxSelect=9-count → cache 拷贝）。
 *   - imgDelete b.a：c0.g(e(i))（e(i) 是 http/https URL=服务器图）→ r(逗号拼接旧图 ID=detelePicXLH)
 *     后移除；本地新图直接移除。img 点击 → 大图预览（源码 BrowsePhotosActivity NONE 模式等价）。
 * 【提交】g.onClick：内容未变 && 无本地新图 && r 空 → "当前内容未作修改"；b3()（MEETING_CONTENT
 *   空=新建）→ d3 = p.Z(new i).N(u=HYID, content, 本地新图) → saveMeetingReport
 *   {meetingXLH=HYID, content, PIC[]}（MeetingModel.l1，实参实证 HYID）；否则 f3 = p.b0(new j).O
 *   (MEETING_XLH, content, 新图, s=oldPicXLH, r=detelePicXLH) → updateMeetingReport {detelePicXLH,
 *   meetingXLH, content, oldPicXLH, PIC[]}（MeetingModel.m1）。
 *   响应：data != "\"1\"" → "会议报告保存失败！"/"会议报告修改失败！"；否则 "会议报告保存成功~"/
 *   "会议报告修改成功~" + setResult+finish。
 * 【返回键】e3()：文本非空 || q 有图 → "放弃此次编辑？"确认弹窗。
 * 【接口实测】写端点会话内不真实提交（探针仅验证 delMeetingReport/openMeetingReport 连通性）；
 *   响应成功判定 meetingReportDataOk（bool/"1" 兼容）。
 */
@Entry
@Component
struct MeetingReportEditPage {
  @State reportText: string = '';
  @State pics: string[] = [];
  @State canSubmit: boolean = false;
  @State submitting: boolean = false;
  @State showDiscardDialog: boolean = false;
  @State previewIndex: number = -1;
  private hyid: string = '';
  private meetingXLH: string = '';
  private oldPicXLH: string = '';
  private deletePicXLH: string = '';
  private meetingContent: string = '';

  aboutToAppear(): void {
    // 源码 y(intent)：MEETING_CONTENT/PIC/MEETING_XLH/STATE/HYID；PIC 非空 → s=oldPicXLH
    const params: object | undefined = router.getParams() as object | undefined;
    if (params !== null && params !== undefined) {
      const record = params as Record<string, Object>;
      this.hyid = MeetingReportEditPage.pickStr(record, ['HYID']);
      this.meetingXLH = MeetingReportEditPage.pickStr(record, ['MEETING_XLH']);
      this.meetingContent = MeetingReportEditPage.pickStr(record, ['MEETING_CONTENT']);
      const stateVal: Object | undefined = record['STATE'];
      if (typeof stateVal === 'string') {
        // 源码 x.STATE 记录后未参与提交/渲染（HAP 同语义保留）
      }
      const picVal: Object | undefined = record['PIC'];
      if (typeof picVal === 'string' && (picVal as string) !== '') {
        this.oldPicXLH = picVal as string;
      }
    }
    this.presetFromReport();
  }

  /** 源码 Z2()→g3(report)：MEETING_CONTENT/PIC 任一非空 → 预填文本与图片列表 */
  private presetFromReport(): void {
    if (this.meetingContent === '' && this.oldPicXLH === '') {
      return;
    }
    this.reportText = this.meetingContent;
    // 源码 r1(true)：预填非空即启用完成按钮（Y0 判断 + TextWatcher）
    if (this.reportText.trim() !== '') {
      this.canSubmit = true;
    }
    if (this.oldPicXLH === '') {
      return;
    }
    // 源码 q.addAll(Arrays.asList(report.PIC.split(",")))：服务器图 ID 列表
    const ids: string[] = this.oldPicXLH.split(',');
    for (const id of ids) {
      if (id !== '') {
        this.pics.push(id);
      }
    }
  }

  /** 源码 w.e(i)：storage 本地路径原样；服务器图 → host+/mobileapi_ydxy/open/image/+id */
  private reportPicUrl(pic: string): string {
    if (pic.indexOf('/cache/') >= 0 || pic.indexOf('file://') >= 0) {
      return pic;
    }
    return Constants.SOCKET_HOST + '/mobileapi_ydxy/open/image/' + pic;
  }

  /** 源码 c0.g(e(i))：http/https URL = 服务器图（删除时记入 detelePicXLH） */
  private isServerPic(pic: string): boolean {
    return !(pic.indexOf('/cache/') >= 0 || pic.indexOf('file://') >= 0);
  }

  /** media uri → 沙箱 cache 文件（fs.statSync 需要真实路径，PhotoViewPicker/cameraPicker uri 均拷贝） */
  private copyUriToCache(uri: string): string {
    const ctx: Context = this.getUIContext().getHostContext() as Context;
    const fileName: string = 'meeting_report_' + Date.now() + '_' +
      String(Math.floor(Math.random() * 9000) + 1000) + '.jpg';
    const target: string = ctx.cacheDir + '/' + fileName;
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
  }

  /** 源码 d.onClick（image_camera）：≥9 拦截 → 拍照 → add(0, 路径) */
  private async pickFromCamera(): Promise<void> {
    if (this.pics.length >= 9) {
      this.toast('不能上传超过9张图片');
      return;
    }
    try {
      const profile: cameraPicker.PickerProfile = {
        cameraPosition: camera.CameraPosition.CAMERA_POSITION_BACK
      };
      const result: cameraPicker.PickerResult = await cameraPicker.pick(
        this.getUIContext().getHostContext() as Context,
        [cameraPicker.PickerMediaType.PHOTO], profile);
      // [W21 协作修复] SDK cameraPicker.PickerResult 为单结果 {resultCode, resultUri, mediaType}（无 result[]）
      const uri: string = result.resultUri;
      this.pics.splice(0, 0, this.copyUriToCache(uri));
    } catch (error) {
      const be = error as BusinessError;
      ApiService.logError('MeetingReportEditPage camera fail: ' + be.message);
    }
  }

  /** 源码 e.onClick（image_album）：z2 权限后 b(9-count) → SELECTED_PHOTOS 逐个加入 */
  private async pickFromAlbum(): Promise<void> {
    if (this.pics.length >= 9) {
      this.toast('不能上传超过9张图片');
      return;
    }
    try {
      const picker = new photoAccessHelper.PhotoViewPicker();
      const options: photoAccessHelper.PhotoSelectOptions = {
        MIMEType: photoAccessHelper.PhotoViewMIMETypes.IMAGE_TYPE,
        maxSelectNumber: 9 - this.pics.length
      };
      const result: photoAccessHelper.PhotoSelectResult = await picker.select(options);
      for (const uri of result.photoUris) {
        this.pics.push(this.copyUriToCache(uri));
      }
    } catch (error) {
      const be = error as BusinessError;
      ApiService.logError('MeetingReportEditPage album fail: ' + be.message);
    }
  }

  /** 源码 MeetingReportPhotoAdapter b.a（imgDelete）：服务器图 → detelePicXLH 追加；本地图直接移除 */
  private removePic(index: number): void {
    const pic: string = this.pics[index];
    if (this.isServerPic(pic)) {
      // 源码：r 为空直接赋值，否则 ACCEPT_TIME_SEPARATOR_SP（","）拼接
      this.deletePicXLH = this.deletePicXLH === '' ? pic : this.deletePicXLH + ',' + pic;
    }
    const next: string[] = [];
    for (let i = 0; i < this.pics.length; i++) {
      if (i !== index) {
        next.push(this.pics[i]);
      }
    }
    this.pics = next;
  }

  /** 源码 g.onClick（完成）：未修改拦截 → b3() 新建/更新分流 */
  private submit(): void {
    if (this.submitting || !this.canSubmit) {
      return;
    }
    const content: string = this.reportText;
    // 源码：q 中 contains("storage") 的条目=本地新图（HAP=cache 拷贝路径）
    const newPics: string[] = [];
    for (const pic of this.pics) {
      if (!this.isServerPic(pic)) {
        newPics.push(pic);
      }
    }
    if (content === this.meetingContent && newPics.length === 0 && this.deletePicXLH === '') {
      this.toast('当前内容未作修改');
      return;
    }
    // 源码 b3()：MEETING_CONTENT 空 = 新建（saveMeetingReport，meetingXLH 实参=HYID）
    if (this.meetingContent === '') {
      this.doSave(content, newPics);
    } else {
      this.doUpdate(content, newPics);
    }
  }

  /** 源码 d3 → MeetingModel.l1：POST_MULTIPART saveMeetingReport {meetingXLH=HYID, content, PIC[]} */
  private doSave(content: string, newPics: string[]): void {
    this.submitting = true;
    this.canSubmit = false;
    ApiService.saveMeetingReport(this.hyid, content, newPics)
      .then((response: ApiResponse<Object>) => {
        this.submitting = false;
        if (response.code === 1000) {
          return;
        }
        if (response.code === 0 && ApiService.meetingReportDataOk(response.data)) {
          this.toast('会议报告保存成功~');
          this.finishAfterSubmit();
        } else if (response.code === 0) {
          this.canSubmit = true;
          this.toast('会议报告保存失败！');
        } else {
          // 源码 i.f(str2)：m(str2) toast 服务器文案
          this.canSubmit = true;
          this.toast(response.message === '' ? '会议报告保存失败！' : response.message);
        }
      })
      .catch((error: BusinessError) => {
        this.submitting = false;
        this.canSubmit = true;
        ApiService.logError('MeetingReportEditPage save fail: ' + error.message);
        this.toast('会议报告保存失败！');
      });
  }

  /** 源码 f3 → MeetingModel.m1：POST_MULTIPART updateMeetingReport {detelePicXLH, meetingXLH, content, oldPicXLH, PIC[]} */
  private doUpdate(content: string, newPics: string[]): void {
    this.submitting = true;
    this.canSubmit = false;
    ApiService.updateMeetingReport(this.meetingXLH, content, this.oldPicXLH, this.deletePicXLH, newPics)
      .then((response: ApiResponse<Object>) => {
        this.submitting = false;
        if (response.code === 1000) {
          return;
        }
        if (response.code === 0 && ApiService.meetingReportDataOk(response.data)) {
          this.toast('会议报告修改成功~');
          this.finishAfterSubmit();
        } else if (response.code === 0) {
          this.canSubmit = true;
          this.toast('会议报告修改失败！');
        } else {
          this.canSubmit = true;
          this.toast(response.message === '' ? '会议报告修改失败！' : response.message);
        }
      })
      .catch((error: BusinessError) => {
        this.submitting = false;
        this.canSubmit = true;
        ApiService.logError('MeetingReportEditPage update fail: ' + error.message);
        this.toast('会议报告修改失败！');
      });
  }

  /** 源码 c3()：setResult(-1)+finish（详情页 onActivityResult(1) 刷新报告与 WebView） */
  private finishAfterSubmit(): void {
    AppStorage.setOrCreate('meeting_report_edited', true);
    router.back();
  }

  /** 源码 onBackPressed → e3()：文本非空 || 有图 → "放弃此次编辑？"确认 */
  private onBackClick(): void {
    const hasContent: boolean = this.reportText.trim() !== '' || this.pics.length > 0;
    if (hasContent) {
      this.showDiscardDialog = true;
      return;
    }
    router.back();
  }

  /** 物理返回键同源码 onBackPressed：有编辑内容 → 拦截弹确认；否则放行 */
  onBackPress(): boolean {
    const hasContent: boolean = this.reportText.trim() !== '' || this.pics.length > 0;
    if (hasContent) {
      this.showDiscardDialog = true;
      return true;
    }
    return false;
  }

  private toast(message: string): void {
    this.getUIContext().getPromptAction().showToast({ message: message });
  }

  private static pickStr(record: Record<string, Object>, keys: string[]): string {
    for (const key of keys) {
      const v: Object | undefined = record[key];
      if (typeof v === 'string') {
        return v as string;
      }
      if (typeof v === 'number') {
        return String(v as number);
      }
    }
    return '';
  }

  // ===== UI =====

  build() {
    Stack() {
      Column() {
        TitleBar({ title: '会议报告', showBack: true, onBack: (): void => {
          this.onBackClick();
        } })
        // toolbar 右"完成"（toolBar_text_but：61×26 pill，enabled ybg_blue 白字/disabled #CCCCCC 黑字）
        Text('完成')
          .fontSize(16)
          .fontColor(this.canSubmit ? Color.White : Color.Black)
          .textAlign(TextAlign.Center)
          .width(61)
          .height(26)
          .borderRadius(4)
          .backgroundColor(this.canSubmit ? $r('app.color.common_color_12') : '#CCCCCC')
          .position({ x: '88%', y: 9 })
          .onClick(() => {
            this.submit();
          })

        // edit_content：白底 padding 25/20 layoutWeight1
        TextArea({ text: this.reportText, placeholder: '' })
          .fontSize(16)
          .fontColor($r('app.color.common_color_1'))
          .placeholderColor($r('app.color.common_color_35'))
          .backgroundColor($r('app.color.white'))
          .padding({ left: 25, right: 25, top: 20, bottom: 20 })
          .width('100%')
          .layoutWeight(1)
          .onChange((value: string) => {
            // 源码 TextWatcher：trim 空 → 完成禁用
            this.reportText = value;
            this.canSubmit = value.trim() !== '';
          })

        // 底部相机/相册行 40dip（camera marginLeft 13 + album marginLeft 15）
        Row() {
          Image($r('app.media.mobile_campus_meeting_camera'))
            .width(22)
            .height(22)
            .margin({ left: 13 })
            .onClick(() => {
              this.pickFromCamera();
            })
          Image($r('app.media.mobile_campus_meeting_image'))
            .width(22)
            .height(22)
            .margin({ left: 15 })
            .onClick(() => {
              this.pickFromAlbum();
            })
        }
        .width('100%')
        .height(40)
        .alignItems(VerticalAlign.Center)
        .backgroundColor($r('app.color.white'))

        // photoAdapter RecyclerView 横向（padding 4）
        Scroll() {
          Row() {
            ForEach(this.pics, (pic: string, index: number) => {
              this.photoCell(pic, index)
            }, (pic: string, index: number) => 'pic_' + String(index) + '_' + pic.substring(0, 16))
          }
          .padding(4)
          .alignItems(VerticalAlign.Center)
        }
        .scrollable(ScrollDirection.Horizontal)
        .scrollBar(BarState.Off)
        .width('100%')
      }
      .width('100%')
      .height('100%')
      .alignItems(HorizontalAlign.Start)
      .backgroundColor($r('app.color.main_bg'))

      // 大图预览（源码 BrowsePhotosActivity NONE 模式等价）
      if (this.previewIndex >= 0 && this.previewIndex < this.pics.length) {
        this.previewOverlay()
      }

      // 返回键"放弃此次编辑？"（源码 dialog.g）
      if (this.showDiscardDialog) {
        this.discardDialog()
      }
    }
    .width('100%')
    .height('100%')
    .alignContent(Alignment.Center)
  }

  /** mobile_campus_meeting_item_photo：75×75 图（margin 7.5）+ delete_icon 右上（padL4 padB4） */
  @Builder
  photoCell(pic: string, index: number) {
    Stack({ alignContent: Alignment.TopEnd }) {
      Image(this.reportPicUrl(pic))
        .alt($r('app.media.ic_empty'))
        .width(75)
        .height(75)
        .objectFit(ImageFit.Cover)
      Image($r('app.media.delete_icon'))
        .width(16)
        .height(16)
        .padding({ left: 4, bottom: 4 })
        .onClick(() => {
          this.removePic(index);
        })
    }
    .margin(7.5)
    .onClick(() => {
      // 源码 img 点击 c.onItemClick：BrowsePhotosActivity(urls, index, NONE)
      this.previewIndex = index;
    })
  }

  /** 全屏大图预览层（点图外关闭；源码等价 BrowsePhotosActivity 简化） */
  @Builder
  previewOverlay() {
    Column() {
      Image(this.reportPicUrl(this.pics[this.previewIndex]))
        .alt($r('app.media.ic_empty'))
        .width('100%')
        .height('80%')
        .objectFit(ImageFit.Contain)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#CC000000')
    .justifyContent(FlexAlign.Center)
    .onClick(() => {
      this.previewIndex = -1;
    })
  }

  /** "放弃此次编辑？"确认（源码 framework dialog.g：a()=finish） */
  @Builder
  discardDialog() {
    Column() {
      Text('放弃此次编辑？')
        .fontSize(17)
        .fontColor($r('app.color.common_color_1'))
        .margin({ top: 16, bottom: 16 })
      Divider()
        .color($r('app.color.common_color_5'))
        .strokeWidth(0.5)
        .width('100%')
      Row() {
        Text('取消')
          .fontSize(17)
          .fontColor($r('app.color.common_color_3'))
          .textAlign(TextAlign.Center)
          .layoutWeight(1)
          .height(44)
          .onClick(() => {
            this.showDiscardDialog = false;
          })
        Divider()
          .vertical(true)
          .color($r('app.color.common_color_5'))
          .strokeWidth(0.5)
          .height(44)
        Text('确定')
          .fontSize(17)
          .fontColor($r('app.color.mobile_campus_primary_color_default'))
          .textAlign(TextAlign.Center)
          .layoutWeight(1)
          .height(44)
          .onClick(() => {
            // 源码 a.a()：finish()
            this.showDiscardDialog = false;
            router.back();
          })
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)
    }
    .width(270)
    .borderRadius(8)
    .backgroundColor($r('app.color.white'))
    .alignItems(HorizontalAlign.Center)
    .clip(true)
  }
}
