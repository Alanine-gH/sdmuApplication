import { router, promptAction } from '@kit.ArkUI';
import { photoAccessHelper } from '@kit.MediaLibraryKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { TitleBar } from '../components/TitleBar';
import { ApiService } from '../network/ApiService';
import { ApiResponse } from '../model/ResponseModel';

/**
 * 发布帖子页 — 1:1 复刻 PostPublishActivity（social_post_publish.xml）+ PostPublicPresenter。
 * 【源码还原】
 *   - 输入框 500 字上限（InputFilter.LengthFilter(500)）、hint="说说身边新鲜事"；
 *   - 图片九宫格 ≤9（post_publish_chosen_photo_item，up_photo_bg 加号格，超选 toast
 *     "您已经选择了足够多图片了，赶快去发布吧"）；
 *   - 表情面板（EmoticonsKeyBoardLayout）→ HAP 等价表情条插入文本；
 *   - 发布按钮初始禁用，onTextChanged b3()（内容空且无图）→ 禁用；
 *   - 发布 = PostPublicPresenter.b(content,"1",files) → SocialModel.f → e.f multipart
 *     {content,type:"1"} + pic1..picN @ push 域 yibaogao.com（2026-11-18 实测不可达 →
 *     真实网络错误 toast，绝不编造发布成功）；
 *   - 成功回调 K()：post_type=="2"（校圈浮动按钮入口）→ 跳 NewNewsActivity，否则返回；
 *   - 返回键有内容 → 确认弹窗"放弃此次编辑？"。
 */
@Entry
@Component
struct PostPublishPage {
  @State content: string = '';
  @State photos: string[] = [];
  @State showEmoji: boolean = false;
  @State submitting: boolean = false;
  private postType: string = '1';

  aboutToAppear(): void {
    const params: Record<string, Object> = (router.getParams() ?? {}) as Record<string, Object>;
    const pt: Object | undefined = params['postType'];
    if (typeof pt === 'string' && (pt as string) !== '') {
      this.postType = pt as string;
    }
  }

  /** 源码 b3()：内容空且无图 */
  private isEmpty(): boolean {
    return this.content.trim() === '' && this.photos.length <= 0;
  }

  /** 源码 e3()：F0(131) 图库选图（剩余额度 = 9 - 已选） */
  private pickPhotos(): void {
    const remain: number = 9 - this.photos.length;
    if (remain <= 0) {
      promptAction.showToast({ message: '您已经选择了足够多图片了，赶快去发布吧' });
      return;
    }
    const picker = new photoAccessHelper.PhotoViewPicker();
    const options: photoAccessHelper.PhotoSelectOptions = new photoAccessHelper.PhotoSelectOptions();
    options.MIMEType = photoAccessHelper.PhotoViewMIMETypes.IMAGE_TYPE;
    options.maxSelectNumber = remain;
    picker.select(options)
      .then((result: photoAccessHelper.PhotoSelectResult) => {
        for (const uri of result.photoUris) {
          if (this.photos.length < 9) {
            this.photos.push(uri);
          }
        }
      })
      .catch((error: BusinessError) => ApiService.logError('photo pick fail: ' + error.message));
  }

  /** 源码 g$a：压缩+组包后 presenter.b(content,"1",files) —— push 域 multipart 真实尝试 */
  private publish(): void {
    if (this.isEmpty()) {
      promptAction.showToast({ message: '内容不能为空！' });
      return;
    }
    this.submitting = true;
    ApiService.pushPublishPost(this.content.trim(), this.photos)
      .then((response: ApiResponse<Object>) => {
        this.submitting = false;
        if (response.code === 0) {
          this.publishSuccess();
        } else {
          promptAction.showToast({ message: response.message });
        }
      })
      .catch((error: BusinessError) => {
        this.submitting = false;
        promptAction.showToast({ message: error.message });
      });
  }

  /** 源码 K()：发布成功 —— postType=="2" → NewNewsActivity，否则返回上一页（源码无成功 toast） */
  private publishSuccess(): void {
    if (this.postType === '2') {
      router.replaceUrl({ url: 'pages/SocialNewNewsPage' });
    } else {
      router.back();
    }
  }

  /** 源码 d3()：返回有内容 → "放弃此次编辑？" */
  private backWithConfirm(): void {
    if (this.isEmpty()) {
      router.back();
      return;
    }
    AlertDialog.show({
      message: '放弃此次编辑？',
      primaryButton: {
        value: '取消', action: (): void => {
        }
      },
      secondaryButton: {
        value: '确定', action: (): void => {
          router.back();
        }
      }
    });
  }

  /** 源码 k adapter：九宫格（末格加号 up_photo_bg；已选图右上删除） */
  @Builder
  photoGrid() {
    Grid() {
      ForEach(this.photos, (uri: string, idx: number) => {
        GridItem() {
          Stack({ alignContent: Alignment.TopEnd }) {
            Image(uri)
              .width('100%')
              .height('100%')
              .objectFit(ImageFit.Cover)
              .borderRadius(3)
            Image($r('app.media.market_close'))
              .width(16)
              .height(16)
              .margin(3)
              .onClick(() => {
                this.photos.splice(idx, 1);
                this.photos = this.photos.slice();
              })
          }
          .width('100%')
          .height('100%')
        }
      }, (uri: string) => uri)
      if (this.photos.length < 9) {
        GridItem() {
          Image($r('app.media.up_photo_bg'))
            .width('100%')
            .height('100%')
            .objectFit(ImageFit.Cover)
            .borderRadius(3)
            .onClick(() => {
              this.pickPhotos();
            })
        }
      }
    }
    .columnsTemplate('1fr 1fr 1fr')
    .columnsGap(5)
    .rowsGap(5)
    .height(this.photos.length === 0 ? 90 : (Math.floor((this.photos.length - 1) / 3) + 1) * 95 + 5)
    .width('100%')
  }

  /** 源码 EmoticonsKeyBoardLayout：表情条插入文本（HAP 等价实现） */
  @Builder
  emojiBar() {
    Row({ space: 12 }) {
      ForEach(['😀', '😁', '😂', '🤣', '😊', '😍', '🤔', '👍', '🙏', '🎉', '❤️', '🌹'],
        (emoji: string) => {
          Text(emoji)
            .fontSize(24)
            .onClick(() => {
              this.content += emoji;
            })
        }, (emoji: string) => emoji)
    }
    .width('100%')
    .padding({ left: 15, right: 15, top: 8, bottom: 8 })
    .backgroundColor($r('app.color.common_color_6'))
  }

  build() {
    Column() {
      TitleBar({
        title: '发贴',
        rightText: '发布',
        rightButtonStyle: true,
        rightEnabled: !this.isEmpty() && !this.submitting,
        onRightClick: (): void => {
          this.publish();
        },
        onBack: (): void => {
          this.backWithConfirm();
        }
      })
      Scroll() {
        Column() {
          TextArea({ text: this.content, placeholder: '说说身边新鲜事' })
            .placeholderColor($r('app.color.common_color_4'))
            .fontSize(16)
            .fontColor($r('app.color.common_color_1'))
            .maxLength(500)
            .backgroundColor(Color.Transparent)
            .width('100%')
            .constraintSize({ minHeight: 120 })
            .onChange((value: string) => {
              this.content = value;
            })
          Text(String(this.content.length) + '/500')
            .fontSize(12)
            .fontColor($r('app.color.common_color_4'))
            .width('100%')
            .textAlign(TextAlign.End)
            .padding({ right: 15 })
          this.photoGrid()
          Row() {
            Image($r('app.media.social_comment'))
              .width(22)
              .height(22)
              .onClick(() => {
                this.showEmoji = !this.showEmoji;
              })
            Blank()
          }
          .width('100%')
          .padding({ left: 15, right: 15, top: 10 })
        }
        .width('100%')
      }
      .width('100%')
      .layoutWeight(1)
      .scrollBar(BarState.Off)
      if (this.showEmoji) {
        this.emojiBar()
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.white'))
  }
}
