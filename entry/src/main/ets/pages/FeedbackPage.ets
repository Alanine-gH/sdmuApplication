import { router } from '@kit.ArkUI';
import { photoAccessHelper } from '@kit.MediaLibraryKit';
import { TitleBar } from '../components/TitleBar';
import { ApiService, FeedbackTypeEntry } from '../network/ApiService';
import { LoginSession } from '../network/LoginSession';

/**
 * 意见反馈页 — 1:1 复刻 FeedbackActivity.java + mobile_campus_feedback_activity.xml(v22)
 * 结构：toolbar_normal + divider + NestedScrollView(#F2F2F2)
 *   tvQuestion "选择问题模块，迅速定位问题"：源码 XML visibility=gone 且 Activity 全程
 *     无 setVisibility(VISIBLE)（layout 与 layout-v22 一致）→ 保持隐藏不渲染；
 *     types 接口仍按 f1() 照常调用，提交 typeId 恒为 ""（v==null 分支）。
 *   白卡1 padding16：edContent 高58(px116/2) maxLines3 maxLength300
 *     hint"请您输入APP使用过程中遇到的问题或意见" + 计数器 n/300（feedback_text 16fp #999 右对齐）
 *   分隔线 common_color_6 1dip
 *   白卡2 padding16："添加相关问题截图" + tvNum "n/6"（16fp 黑）；
 *     gv 九宫格 3列（GridLayoutManager 3）marginTop16；SpaceItemDecoration(y.a(16))：
 *     列间视觉 16dp、行间 10dp；照片项 75dip(px150/2) centerCrop + 右上角删除 icon_close(18dp)；
 *     添加项 75dip feedback_add 图
 *   divider / 白卡3 paddingH16 paddingV14(px28/2)：edContact 17fp(px34/2)
 *     hint"请输入您的手机号/QQ" 单行（inputType=number+digits 白名单，实际数字字母可输）
 *   divider / tvMessage 公告条：12fp(px24/2) #666666 bg #FBF5C0 paddingH16 paddingV10
 *     announcement 接口返回非空显示（默认 gone）
 *   tvSubmit 提交：18fp(px36/2) 白 高44(px88/2) margin30(px60/2) 圆角10
 *     enabled primary_color / disabled common_color_24
 * 行为（源码逐行）：
 *   f1()：e3() types + d3() announcement（photoAdapter 初始 [""] 占位、tvNum 0/6）
 *   f3()：content.trim 与 contact.trim 均非空才启用提交
 *   g onClick：content 空 →"请您输入APP使用过程中遇到的问题或意见"；
 *     contact 空 →"请输入您的手机号/QQ"；photos 去占位 → c3() 提交
 *   c3 → POST_MULTIPART submit/ciphertext（data=固定key密文原样，j=false 无外层加密 + imgs 文件，FeedbackPImpl）
 *   成功 data==true → toast"提交成功" + finish(router.back)
 */
@Entry
@Component
struct FeedbackPage {
  /** edContent 内容 */
  @State content: string = '';
  /** edContact 内容 */
  @State contact: string = '';
  /** 照片 uri 列表（源码 adapter data："" 占位追加在末尾，此处用 photos.length 表达） */
  @State photos: string[] = [];
  /** tvMessage 公告文本（announcement 接口；空则不显示） */
  @State announcement: string = '';
  /** 问题类型缓存（e3 拉取；tvQuestion 源码恒隐藏，提交 typeId=""） */
  private feedbackTypes: FeedbackTypeEntry[] = [];
  /** 提交中防重复（源码 loading g0.i / a.e dismiss） */
  @State submitting: boolean = false;

  aboutToAppear(): void {
    // 源码 f1()：tvNum 初始 0/6、adapter 单占位；e3() + d3()
    this.photos = [];
    this.loadTypes();
    this.loadAnnouncement();
  }

  /** 源码 e3()：x.p(...).k() → types 接口 */
  private async loadTypes(): Promise<void> {
    const resp = await ApiService.getFeedbackTypes();
    if (resp.code === 0) {
      this.feedbackTypes = resp.data;
    }
  }

  /** 源码 d3()：x.q(...).h() → announcement 接口（c 回调：非空 setText+VISIBLE，空 GONE） */
  private async loadAnnouncement(): Promise<void> {
    const resp = await ApiService.getFeedbackAnnouncement();
    if (resp.code === 0 && resp.data !== '') {
      this.announcement = resp.data;
    } else {
      this.announcement = '';
    }
  }

  /** 源码 f3()：两个输入 trim 均非空才启用提交 */
  private submitEnabled(): boolean {
    return this.content.trim() !== '' && this.contact.trim() !== '';
  }

  /** 源码 d 点击添加项：z2 权限后 photo picker（最多 6 张，余量 = 6-已有数+0） */
  private async pickPhotos(): Promise<void> {
    try {
      const picker = new photoAccessHelper.PhotoViewPicker();
      const options: photoAccessHelper.PhotoSelectOptions = {
        MIMEType: photoAccessHelper.PhotoViewMIMETypes.IMAGE_TYPE,
        maxSelectNumber: 6 - this.photos.length
      };
      const result: photoAccessHelper.PhotoSelectResult = await picker.select(options);
      for (const uri of result.photoUris) {
        this.photos.push(uri);
      }
    } catch {
      // 用户取消选择不处理（Android onActivityResult RESULT_CANCEL 同）
    }
  }

  /** 源码 imgDelete 点击 e.a：移除该图并刷新计数 */
  private removePhoto(index: number): void {
    const next: string[] = [];
    for (let i = 0; i < this.photos.length; i++) {
      if (i !== index) {
        next.push(this.photos[i]);
      }
    }
    this.photos = next;
  }

  /** 源码 g onClick + c3()：校验 → 提交（typeId 恒 ""，tvQuestion 源码隐藏） */
  private async submit(): Promise<void> {
    if (this.submitting) {
      return;
    }
    if (this.content === '') {
      this.getUIContext().getPromptAction().showToast({ message: '请您输入APP使用过程中遇到的问题或意见' });
      return;
    }
    if (this.contact === '') {
      this.getUIContext().getPromptAction().showToast({ message: '请输入您的手机号/QQ' });
      return;
    }
    this.submitting = true;
    try {
      const resp = await ApiService.submitFeedback(this.content, this.contact, '', this.photos);
      const dataOk: boolean = typeof resp.data === 'boolean' ? (resp.data as boolean) :
        (typeof resp.data === 'string' && (resp.data as string) === 'true');
      if (resp.code === 0 && dataOk) {
        // 源码 a.g(Boolean true)：m("提交成功") + finish()
        this.getUIContext().getPromptAction().showToast({ message: '提交成功' });
        router.back();
      } else {
        // 源码 a.f：toast(msg)
        this.getUIContext().getPromptAction().showToast({ message: resp.message });
      }
    } finally {
      this.submitting = false;
    }
  }

  /** 源码 i onClick：标题栏"反馈记录" → FeedbackRecordActivity（E0 路由同族） */
  private openRecord(): void {
    router.pushUrl({ url: 'pages/FeedbackRecordPage' });
  }

  @Builder
  photoGridItem(uri: string, index: number) {
    // mobile_campus_feedback_item_photo.xml：FrameLayout 75dip；img centerCrop；
    // imgDelete 右上角（icon_close 36px@xhdpi=18dp，flush 右上，XML paddingB 8 为框内空隙不影响可见图）
    Stack({ alignContent: Alignment.TopEnd }) {
      Image(uri)
        .width(75)
        .height(75)
        .objectFit(ImageFit.Cover)
      Image($r('app.media.mobile_campus_feedback_icon_close'))
        .width(18)
        .height(18)
        .onClick(() => {
          this.removePhoto(index);
        })
    }
    .width(75)
    .height(75)
  }

  build() {
    Column() {
      // toolbar_normal：标题（mySetup.feedbackTitle 服务端可覆盖，默认"意见反馈"）
      // + toolBar_text_but"反馈记录"（黑色，i onClick → 反馈记录页）
      TitleBar({
        title: '意见反馈',
        showBack: true,
        rightText: '反馈记录',
        onRightClick: (): void => {
          this.openRecord();
        }
      })

      // divider_horizontal_grey_normal
      Divider()
        .color($r('app.color.common_color_5'))
        .strokeWidth(0.5)
        .width('100%')

      Scroll() {
        Column() {
          // tvQuestion：源码 XML visibility=gone 且无显示代码 → 不渲染（源码忠实行为）

          // 白卡1：edContent + 计数器
          Column() {
            TextArea({ placeholder: '请您输入APP使用过程中遇到的问题或意见', text: this.content })
              .fontSize(16)
              .fontColor($r('app.color.black'))
              .placeholderColor($r('app.color.common_color_3'))
              .placeholderFont({ size: 16 })
              .height(58)
              .maxLines(3)
              .maxLength(300)
              .backgroundColor(Color.Transparent)
              .padding(0)
              .onChange((value: string) => {
                this.content = value;
              })

            // TextInputLayout counter：n/300（feedback_text 16fp common_color_3 右对齐）
            Text(this.content.length + '/300')
              .fontSize(16)
              .fontColor($r('app.color.common_color_3'))
              .width('100%')
              .textAlign(TextAlign.End)
          }
          .width('100%')
          .padding(16)
          .backgroundColor($r('app.color.white'))
          .alignItems(HorizontalAlign.Start)

          // View common_color_6 1dip
          Divider()
            .color($r('app.color.common_color_6'))
            .strokeWidth(1)
            .width('100%')

          // 白卡2：截图区
          Column() {
            Row() {
              Text('添加相关问题截图')
                .fontSize(16)
                .fontColor($r('app.color.black'))
                .layoutWeight(1)
              Text(this.photos.length + '/6')
                .fontSize(16)
                .fontColor($r('app.color.black'))
            }
            .width('100%')

            // gv：GridLayoutManager 3 列、marginTop 16(px32/2)；
            // SpaceItemDecoration(y.a(16))：列间视觉 16dp（col1 左偏移16、col2 左偏移32）、行间 10dp
            Grid() {
              ForEach(this.photos, (uri: string, index: number) => {
                GridItem() {
                  this.photoGridItem(uri, index)
                }
              }, (uri: string, index: number) => uri + '_' + index)
              if (this.photos.length < 6) {
                GridItem() {
                  // 添加项：feedback_add 图 75dip
                  Image($r('app.media.mobile_campus_feedback_add'))
                    .width(75)
                    .height(75)
                }
                .onClick(() => {
                  this.pickPhotos();
                })
              }
            }
            .columnsTemplate('1fr 1fr 1fr')
            .columnsGap(16)
            .rowsGap(10)
            .margin({ top: 16 })
            .width('100%')
          }
          .width('100%')
          .padding(16)
          .backgroundColor($r('app.color.white'))
          .alignItems(HorizontalAlign.Start)

          // divider_horizontal_grey_normal
          Divider()
            .color($r('app.color.common_color_5'))
            .strokeWidth(0.5)
            .width('100%')

          // 白卡3：edContact（paddingH 16 paddingV 14）
          Row() {
            TextInput({ placeholder: '请输入您的手机号/QQ', text: this.contact })
              .fontSize(17)
              .fontColor($r('app.color.black'))
              .placeholderColor($r('app.color.common_color_3'))
              .placeholderFont({ size: 17 })
              .maxLines(1)
              .backgroundColor(Color.Transparent)
              .padding(0)
              .layoutWeight(1)
              .onChange((value: string) => {
                this.contact = value;
              })
          }
          .width('100%')
          .padding({ left: 16, right: 16, top: 14, bottom: 14 })
          .backgroundColor($r('app.color.white'))

          // divider_horizontal_grey_normal
          Divider()
            .color($r('app.color.common_color_5'))
            .strokeWidth(0.5)
            .width('100%')

          // tvMessage 公告条（announcement 非空显示）
          if (this.announcement !== '') {
            Text(this.announcement)
              .fontSize(12)
              .fontColor('#666666')
              .backgroundColor('#FBF5C0')
              .width('100%')
              .padding({ left: 16, right: 16, top: 10, bottom: 10 })
          }

          // tvSubmit 提交
          Text('提交')
            .fontSize(18)
            .fontColor($r('app.color.white'))
            .width('100%')
            .height(44)
            .textAlign(TextAlign.Center)
            .margin(30)
            .borderRadius(10)
            .backgroundColor(this.submitEnabled() ?
              $r('app.color.mobile_campus_primary_color') : $r('app.color.common_color_24'))
            .onClick(() => {
              this.submit();
            })
        }
        .width('100%')
      }
      .width('100%')
      .layoutWeight(1)
      .scrollBar(BarState.Off)
      .align(Alignment.Top)
      .backgroundColor($r('app.color.common_color_6'))
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.white'))
  }
}
