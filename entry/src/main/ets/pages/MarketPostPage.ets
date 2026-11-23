import { router, promptAction } from '@kit.ArkUI';
import { photoAccessHelper } from '@kit.MediaLibraryKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { TitleBar } from '../components/TitleBar';
import { ApiService } from '../network/ApiService';
import { ApiResponse } from '../model/ResponseModel';
import { BreakpointSystem } from '../common/BreakpointSystem';
import { AdaptiveLayoutHelper } from '../common/AdaptiveLayoutHelper';

/**
 * 集市发帖页 — 1:1 复刻 MarketPostActivity（activity_market_post）+ MarketPostView + MarketModel。
 * 【源码还原】
 *   - 标题 R.string.market_post_title"发帖"；意向 RadioGroup：rbBuy"想卖"→marketType 0、
 *     rbSale"想买"→marketType 1（view_market_post.xml 实文）；占领头条区：时长/费用/设置时长
 *     （getUserScores 积分数据 → 竞价弹窗；余额不足 toast"当前可用积分不够参与竞价"）；
 *     tvTipsexplain"让更多的同学看到你的帖子"；
 *   - 内容 500 字 + 图片 ≤9（market_post_publish_chosen_photo_item，含删除角标）；
 *   - 发布按钮 enable = MarketPostView.isSubmit()（意向已选恒 true）且（有内容或有图）；
 *   - 发布 = MarketModel.k1 → e.f multipart {content,type:"2",marketType,score,time} +
 *     pic1..picN @ push 域（2026-11-18 实测不可达 → 真实网络错误 toast）；
 *   - getUserScores = e.b GET @ push 域 → 不可达 → 积分区保持初始"2/10"占位不可用态
 *     （源码 getScore/getTime 在 !isScoreValid 时返回"0"）。
 */
@Entry
@Component
struct MarketPostPage {
  @State content: string = '';
  @State photos: string[] = [];
  @State marketType: number = 0; // 0=想卖 1=想买
  @State submitting: boolean = false;
  @State scoreReady: boolean = false;
  @StorageProp('currentBreakpoint') currentBreakpoint: string = 'sm';
  @StorageProp('avoidAreaBottomVp') avoidAreaBottomVp: number = 0;
  @StorageProp('keyboardHeightVp') keyboardHeightVp: number = 0;

  aboutToAppear(): void {
    // 源码 f1()：d0(getUserScores).G() —— push 域，实测不可达 → scoreReady 保持 false
    ApiService.pushGetUserScores()
      .then((response: ApiResponse<Object>) => {
        if (response.code === 0) {
          this.scoreReady = true;
        } else {
          promptAction.showToast({ message: response.message });
        }
      })
      .catch((error: BusinessError) => {
        promptAction.showToast({ message: error.message });
      });
  }

  /** 源码 b3() */
  private isEmpty(): boolean {
    return this.content.trim() === '' && this.photos.length <= 0;
  }

  /** 源码 MarketPostView.isSubmit(): marketType != -1（意向必选，默认想卖） */
  private canSubmit(): boolean {
    return !this.isEmpty() && !this.submitting;
  }

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

  /** 源码 b$a：presenter.J(content,"2",marketType,time,score,files) → MarketModel.k1 multipart */
  private publish(): void {
    if (this.isEmpty()) {
      promptAction.showToast({ message: '内容不能为空！' });
      return;
    }
    this.submitting = true;
    // 源码 getPerPrice()/getTime()：!isScoreValid → "0"
    const time: string = this.scoreReady ? '' : '0';
    const score: string = '0';
    ApiService.pushPublishMarket(this.content.trim(), String(this.marketType), time, score, this.photos)
      .then((response: ApiResponse<Object>) => {
        this.submitting = false;
        if (response.code === 0) {
          promptAction.showToast({ message: '发布成功' });
          router.back();
        } else {
          promptAction.showToast({ message: response.message });
        }
      })
      .catch((error: BusinessError) => {
        this.submitting = false;
        promptAction.showToast({ message: error.message });
      });
  }

  /** 源码 m adapter：九宫格（末格加号 + 已选图删除角标 imgRemove） */
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
              .hoverEffect(HoverEffect.Highlight)
              .onClick(() => {
                this.pickPhotos();
              })
          }
        }
      }
      .columnsTemplate(AdaptiveLayoutHelper.buildColumnsTemplate(
        BreakpointSystem.getGridColumns(this.currentBreakpoint, 3)
      ))
      .columnsGap(5)
      .rowsGap(5)
      .height(AdaptiveLayoutHelper.computeGridHeightVp(
        this.photos.length + (this.photos.length < 9 ? 1 : 0),
        BreakpointSystem.getGridColumns(this.currentBreakpoint, 3),
        90,
        5,
        5
      ))
      .width('100%')
  }

  /** 源码 view_market_post.xml：意向 RadioGroup（想卖/想买 selector_market_post） */
  @Builder
  marketTypeBar() {
    Row() {
      Text('意向')
        .fontSize(16)
        .fontColor($r('app.color.common_color_1'))
      Blank()
      Text('想卖')
        .fontSize(14)
        .fontColor(this.marketType === 0 ? Color.White : $r('app.color.common_color_1'))
        .backgroundColor(this.marketType === 0 ? $r('app.color.common_color_12') : $r('app.color.common_color_6'))
        .borderRadius(4)
        .padding({ left: 18, right: 18, top: 6, bottom: 6 })
        .hoverEffect(HoverEffect.Highlight)
        .onClick(() => {
          this.marketType = 0;
        })
      Text('想买')
        .fontSize(14)
        .fontColor(this.marketType === 1 ? Color.White : $r('app.color.common_color_1'))
        .backgroundColor(this.marketType === 1 ? $r('app.color.common_color_12') : $r('app.color.common_color_6'))
        .borderRadius(4)
        .padding({ left: 18, right: 18, top: 6, bottom: 6 })
        .margin({ left: 12 })
        .hoverEffect(HoverEffect.Highlight)
        .onClick(() => {
          this.marketType = 1;
        })
    }
    .width('100%')
    .height(44)
    .padding({ left: 15, right: 15 })
    .backgroundColor($r('app.color.white'))
  }

  /** 源码 占领头条区：时长/费用 + 设置时长（积分余额来自 getUserScores，push 域不可达 → 不可用态） */
  @Builder
  topBar() {
    Column() {
      Row() {
        Text('占领头条')
          .fontSize(16)
          .fontColor($r('app.color.common_color_1'))
        Blank()
        Text(this.scoreReady ? '设置时长' : '设置时长 >')
          .fontSize(16)
          .fontColor($r('app.color.common_color_3'))
          .hoverEffect(HoverEffect.Highlight)
          .onClick(() => {
            // 源码 e.click：!existTop 且 usableScores<minUnitprice → toast；push 域不可达无余额 → 同款提示
            promptAction.showToast({ message: '当前可用积分不够参与竞价' });
          })
      }
      .width('100%')
      .height(40)
      Row() {
        Text('时长')
          .fontSize(16)
          .fontColor($r('app.color.common_color_1'))
        Blank()
        Text('2 小时')
          .fontSize(16)
          .fontColor($r('app.color.common_color_7'))
        Text('费用')
          .fontSize(16)
          .fontColor($r('app.color.common_color_1'))
          .margin({ left: 16 })
        Text('10 积分')
          .fontSize(16)
          .fontColor($r('app.color.common_color_7'))
      }
      .width('100%')
      .height(36)
      Text('让更多的同学看到你的帖子')
        .fontSize(16)
        .fontColor($r('app.color.common_color_3'))
        .width('100%')
        .padding({ top: 8, bottom: 17 })
    }
    .width('100%')
    .padding({ left: 15, right: 15 })
    .backgroundColor($r('app.color.white'))
    .margin({ top: 1 })
  }

  build() {
    Column() {
      TitleBar({
        title: '发帖',
        rightText: '发布',
        rightButtonStyle: true,
        rightEnabled: this.canSubmit(),
        onRightClick: (): void => {
          this.publish();
        }
      })
      Scroll() {
        Column() {
          this.marketTypeBar()
          this.topBar()
          Column() {
            TextArea({ text: this.content, placeholder: '输入商品描述...' })
              .placeholderColor($r('app.color.common_color_4'))
              .fontSize(16)
              .fontColor($r('app.color.common_color_1'))
              .maxLength(500)
              .backgroundColor(Color.Transparent)
              .width('100%')
              .constraintSize({ minHeight: 110 })
              .onChange((value: string) => {
                this.content = value;
              })
            this.photoGrid()
          }
          .width('100%')
          .padding(12)
          .backgroundColor($r('app.color.white'))
          .margin({ top: 1 })
        }
        .width('100%')
        .constraintSize({ maxWidth: BreakpointSystem.getContentMaxWidth(this.currentBreakpoint) })
        .alignSelf(ItemAlign.Center)
        .padding({ bottom: this.avoidAreaBottomVp + this.keyboardHeightVp })
      }
      .width('100%')
      .layoutWeight(1)
      .scrollBar(BarState.Off)
      .backgroundColor($r('app.color.common_color_6'))
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.common_color_6'))
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.BOTTOM])
  }
}
