import { router } from '@kit.ArkUI';
import { common, Want } from '@kit.AbilityKit';
import { BusinessError, pasteboard } from '@kit.BasicServicesKit';
import { call } from '@kit.TelephonyKit';
import { BreakpointSystem } from '../common/BreakpointSystem';
import { ApiService } from '../network/ApiService';
import { NewsItem } from '../model/NewsModel';
import { EmptyView } from '../components/EmptyView';
import { ShareHelper } from '../common/ShareHelper';
import { NluEntityHelper, NluEntityChip } from '../common/NluEntityHelper';
import { TtsReaderController, TtsStateSnapshot } from '../common/TtsReaderHelper';
import { ReminderCalendarHelper } from '../common/ReminderCalendarHelper';

/**
 * 新闻详情页 — 按源布局 1:1 复刻 mobile_campus_fragment_news.xml（资讯页）：
 *   根 LinearLayout vertical：background=@color/mobile_campus_bg_color、fill_parent
 *   - 顶部 RelativeLayout 45.0dip=45vp 白底：ivBack / 居中标题“资讯” / ivRefresh
 *   - ProgressBar：3.0dip=3vp 横向进度条（progressDrawable=mobile_campus_progress：白底 + 主色进度）
 *   - mWebView：layout_weight=1、白底 —— 以本地文本渲染新闻正文（后续接真实 URL 时替换为 Web 组件）
 */
@Entry
@Component
struct NewsDetailPage {
  @State news: NewsItem = new NewsItem('', '', '', '', '', '', '', '', '');
  @State isLoading: boolean = true;
  @State nluEntities: NluEntityChip[] = [];
  @State ttsSnapshot: TtsStateSnapshot = {
    state: 'idle',
    currentIndex: 0,
    totalChunks: 0,
    errorMessage: ''
  };
  @StorageProp('currentBreakpoint') currentBreakpoint: string = 'sm';
  @StorageProp('isCompactHeight') isCompactHeight: boolean = false;
  @StorageProp('avoidAreaLeftVp') avoidAreaLeftVp: number = 0;
  @StorageProp('avoidAreaRightVp') avoidAreaRightVp: number = 0;
  @StorageProp('avoidAreaBottomVp') avoidAreaBottomVp: number = 0;
  private newsId: string = '';
  private nluRequestToken: number = 0;
  private ttsController: TtsReaderController = new TtsReaderController();

  aboutToAppear(): void {
    this.ttsController.setOnStateChange((snapshot: TtsStateSnapshot) => {
      this.ttsSnapshot = snapshot;
    });
    const params: object = router.getParams();
    if (params !== null && params !== undefined) {
      const record = params as Record<string, Object>;
      const idValue: Object = record['id'];
      if (typeof idValue === 'string') {
        this.newsId = idValue as string;
      }
    }
    this.loadDetail();
  }

  onPageHide(): void {
    this.ttsController.shutdown();
  }

  aboutToDisappear(): void {
    this.ttsController.shutdown();
  }

  loadDetail(): void {
    this.isLoading = true;
    this.nluEntities = [];
    this.ttsController.stop();
    ApiService.getNewsDetail(this.newsId)
      .then((response) => {
        this.news = response.data;
        this.isLoading = false;
        if (this.news.id !== '') {
          this.extractNewsEntities(this.news.title + '\n' + this.news.content);
        }
      })
      .catch(() => {
        this.isLoading = false;
      });
  }

  private async extractNewsEntities(sourceText: string): Promise<void> {
    this.nluRequestToken += 1;
    const token: number = this.nluRequestToken;
    const result = await NluEntityHelper.extractEntities(sourceText);
    if (token !== this.nluRequestToken) {
      return;
    }
    this.nluEntities = result.entities;
  }

  private toast(msg: string): void {
    if (msg !== '') {
      this.getUIContext().getPromptAction().showToast({ message: msg });
    }
  }

  private async onEntityChipTap(chip: NluEntityChip): Promise<void> {
    if (chip.action === 'calendar') {
      const ctx = this.getUIContext().getHostContext() as common.UIAbilityContext;
      const startMs: number = chip.timestampMs !== null ? chip.timestampMs : Date.now() + 3600000;
      const endMs: number = startMs + 3600000;
      const calRes = await ReminderCalendarHelper.addCalendarEventWithResult(
        ctx,
        this.news.title !== '' ? this.news.title : '校园资讯日程',
        chip.text,
        startMs,
        endMs
      );
      if (calRes.success) {
        this.toast(calRes.message);
        return;
      }
      if (startMs > Date.now()) {
        const remRes = await ReminderCalendarHelper.publishCalendarReminderWithResult(
          this.news.title !== '' ? this.news.title : '校园资讯提醒',
          chip.text,
          new Date(startMs),
          ctx
        );
        this.toast(remRes.success ? remRes.message : (remRes.message || calRes.message));
        return;
      }
      this.toast(calRes.message);
      return;
    }
    if (chip.action === 'dial') {
      try {
        call.makeCall(chip.text, () => {
        });
      } catch {
        this.toast('无法拉起拨号');
      }
      return;
    }
    if (chip.action === 'email') {
      const ctx = this.getUIContext().getHostContext() as common.UIAbilityContext;
      try {
        ctx.startAbility({
          action: 'mailto:' + chip.text,
          entities: ['entity.system.default'],
          parameters: { 'email': [chip.text] }
        } as Want).catch(() => {
          this.toast('请安装邮箱应用');
        });
      } catch {
        this.toast('请安装邮箱应用');
      }
      return;
    }
    if (chip.action === 'url') {
      const lower: string = chip.text.toLowerCase();
      const targetUrl: string = (lower.startsWith('http://') || lower.startsWith('https://'))
        ? chip.text
        : 'https://' + chip.text;
      router.pushUrl({
        url: 'pages/WebViewPage',
        params: { url: targetUrl, title: '网页详情' }
      });
      return;
    }
    if (chip.action === 'location') {
      try {
        const data: pasteboard.PasteData = pasteboard.createData(pasteboard.MIMETYPE_TEXT_PLAIN, chip.text);
        await pasteboard.getSystemPasteboard().setData(data);
        this.toast('已复制地点：' + chip.text);
      } catch {
        this.toast('复制地点失败');
      }
    }
  }

  private async startTtsRead(): Promise<void> {
    const text: string = this.news.title + '。' + this.news.content;
    const ok: boolean = await this.ttsController.speak(text);
    if (!ok) {
      const msg: string = this.ttsSnapshot.errorMessage !== ''
        ? this.ttsSnapshot.errorMessage
        : '当前设备暂不支持语音朗读';
      this.toast(msg);
    }
  }

  private async resumeTtsRead(): Promise<void> {
    const ok: boolean = await this.ttsController.resume();
    if (!ok && this.ttsSnapshot.errorMessage !== '') {
      this.toast(this.ttsSnapshot.errorMessage);
    }
  }

  private ttsStatusLabel(): string {
    const total: number = Math.max(1, this.ttsSnapshot.totalChunks);
    const cur: number = Math.min(total, this.ttsSnapshot.currentIndex + 1);
    if (this.ttsSnapshot.state === 'playing') {
      return `朗读中 · 第 ${cur}/${total} 段`;
    }
    if (this.ttsSnapshot.state === 'paused') {
      return `已暂停 · 第 ${cur}/${total} 段`;
    }
    if (this.ttsSnapshot.state === 'error') {
      return this.ttsSnapshot.errorMessage !== '' ? this.ttsSnapshot.errorMessage : '语音朗读暂不可用';
    }
    return '资讯语音朗读';
  }

  /**
   * mobile_campus_fragment_news.xml 顶部 RelativeLayout：
   * background=@color/white、layout_height=45.0dip=45vp。
   */
  @Builder
  detailToolbar() {
    Column() {
      Row() {
        // ivBack：layout_width=70.0dip=70vp、layout_height=45vp、paddingTop/Bottom=12.0dip=12vp、
        // src=@mipmap/icon_back_black、layout_alignParentLeft=true
        // （XML 中 visibility=invisible 为 Tab 内场景；详情页需要返回，此处显示并响应点击）
        Row() {
          Image($r('app.media.icon_back_black'))
            .height(21)
            .objectFit(ImageFit.Contain)
        }
        .width(70)
        .height(this.isCompactHeight ? 38 : 45)
        .padding({ top: 12, bottom: 12 })
        .alignItems(VerticalAlign.Center)
        .hoverEffect(HoverEffect.Highlight)
        .onClick(() => {
          router.back();
        })
        // 标题 TextView：textSize=18.0sp=18fp、textColor=@color/common_color_1、
        // gravity=center、fill_parent、text="资讯"
        Text($r('app.string.news_detail_title'))
          .fontSize(18)
          .fontColor($r('app.color.common_color_1'))
          .textAlign(TextAlign.Center)
          .layoutWeight(1)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        Row() {
          Text('分享')
            .fontSize(14)
            .fontColor($r('app.color.common_color_1'))
        }
        .height(this.isCompactHeight ? 38 : 45)
        .padding({ left: 10, right: 8 })
        .alignItems(VerticalAlign.Center)
        .hoverEffect(HoverEffect.Highlight)
        .onClick(() => {
          const ctx = this.getUIContext().getHostContext() as common.UIAbilityContext;
          ShareHelper.shareText(ctx, this.news.title || '校园资讯', this.news.summary || this.news.content || '山东管理学院资讯', this.news.url || undefined);
        })
        // ivRefresh：paddingLeft/Right=15.0dip=15vp、paddingTop/Bottom=12.0dip=12vp、
        // src=@mipmap/icon_refresh_black、layout_alignParentRight=true
        Row() {
          Image($r('app.media.icon_refresh_black'))
            .height(21)
            .objectFit(ImageFit.Contain)
        }
        .height(this.isCompactHeight ? 38 : 45)
        .padding({ left: 15, right: 15, top: 12, bottom: 12 })
        .alignItems(VerticalAlign.Center)
        .hoverEffect(HoverEffect.Highlight)
        .onClick(() => {
          this.loadDetail();
        })
      }
      .width('100%')
      .height(this.isCompactHeight ? 38 : 45)
      .padding({ left: this.avoidAreaLeftVp, right: this.avoidAreaRightVp })
      .constraintSize({ maxWidth: BreakpointSystem.getContentMaxWidth(this.currentBreakpoint) })
    }
    .width('100%')
    .alignItems(HorizontalAlign.Center)
    .backgroundColor($r('app.color.white'))
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP])
  }

  build() {
    // 根 LinearLayout vertical：background=@color/mobile_campus_bg_color、fill_parent
    Column() {
      this.detailToolbar()
      if (this.isLoading) {
        // progressBar：layout_height=3.0dip=3vp、style=progressBarStyleHorizontal、max=100、
        // progressDrawable=@drawable/mobile_campus_progress（#ffffffff 背景 + @color/mobile_campus_primary_color 进度）
        Progress({ value: 60, total: 100, type: ProgressType.Linear })
          .width('100%')
          .height(3)
          .color($r('app.color.mobile_campus_primary_color'))
          .backgroundColor($r('app.color.white'))
          .borderRadius(0)
        // mWebView：background=@color/white、layout_weight=1（加载中为空白页）
        Column() {
        }
        .width('100%')
        .layoutWeight(1)
        .backgroundColor($r('app.color.white'))
      } else {
        if (this.news.id === '') {
          // MultiStateView msv_emptyView=empty_view
          Column() {
            EmptyView({ tipText: '内容不存在' })
          }
          .width('100%')
          .layoutWeight(1)
          .backgroundColor($r('app.color.white'))
        } else {
          // mWebView：background=@color/white、layout_weight=1 —— 正文以本地文本渲染
          // （下方文章排版无对应 XML 属性，对应 WebView 内 HTML 正文样式）
          Scroll() {
            Column() {
              Text(this.news.title)
                .fontSize(18)
                .fontWeight(FontWeight.Bold)
                .fontColor($r('app.color.common_color_1'))
                .lineHeight(30)
                .width('100%')
              Row() {
                Text(this.news.source)
                  .fontSize(12)
                  .fontColor($r('app.color.common_color_3'))
                Blank()
                Text(this.news.publishTime)
                  .fontSize(12)
                  .fontColor($r('app.color.common_color_3'))
              }
              .width('100%')
              .margin({ top: 10, bottom: 10 })

              this.ttsControlBar()

              if (this.nluEntities.length > 0) {
                this.nluEntitySection()
              }

              Divider()
                .color($r('app.color.common_color_6'))
                .strokeWidth(1)
                .width('100%')
              Text(this.news.content)
                .fontSize(15)
                .lineHeight(28)
                .fontColor($r('app.color.common_color_2'))
                .width('100%')
                .margin({ top: 12 })
            }
            .alignItems(HorizontalAlign.Start)
            .width('100%')
            .constraintSize({ maxWidth: BreakpointSystem.getContentMaxWidth(this.currentBreakpoint) })
            .padding({
              left: Math.max(16, this.avoidAreaLeftVp),
              right: Math.max(16, this.avoidAreaRightVp),
              top: 16,
              bottom: Math.max(16, this.avoidAreaBottomVp)
            })
          }
          .width('100%')
          .layoutWeight(1)
          .backgroundColor($r('app.color.white'))
          .scrollBar(BarState.Off)
          .align(Alignment.Top)
        }
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.mobile_campus_bg_color'))
  }

  @Builder
  ttsControlBar() {
    Row({ space: 8 }) {
      Text(this.ttsStatusLabel())
        .fontSize(13)
        .fontColor(this.ttsSnapshot.state === 'error' ? '#E5484D' : $r('app.color.common_color_2'))
        .layoutWeight(1)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })

      if (this.ttsSnapshot.state === 'playing') {
        Text('暂停')
          .fontSize(12)
          .fontColor('#1B68B7')
          .padding({ left: 10, right: 10, top: 5, bottom: 5 })
          .borderRadius(14)
          .backgroundColor('#EBF4FF')
          .hoverEffect(HoverEffect.Highlight)
          .onClick(() => {
            this.ttsController.pause();
          })
        Text('停止')
          .fontSize(12)
          .fontColor($r('app.color.common_color_2'))
          .padding({ left: 10, right: 10, top: 5, bottom: 5 })
          .borderRadius(14)
          .backgroundColor('#F2F4F7')
          .hoverEffect(HoverEffect.Highlight)
          .onClick(() => {
            this.ttsController.stop();
          })
      } else if (this.ttsSnapshot.state === 'paused') {
        Text('继续')
          .fontSize(12)
          .fontColor($r('app.color.white'))
          .padding({ left: 10, right: 10, top: 5, bottom: 5 })
          .borderRadius(14)
          .backgroundColor('#1B68B7')
          .hoverEffect(HoverEffect.Highlight)
          .onClick(() => {
            this.resumeTtsRead();
          })
        Text('停止')
          .fontSize(12)
          .fontColor($r('app.color.common_color_2'))
          .padding({ left: 10, right: 10, top: 5, bottom: 5 })
          .borderRadius(14)
          .backgroundColor('#F2F4F7')
          .hoverEffect(HoverEffect.Highlight)
          .onClick(() => {
            this.ttsController.stop();
          })
      } else {
        Text('语音朗读')
          .fontSize(12)
          .fontColor($r('app.color.white'))
          .padding({ left: 12, right: 12, top: 5, bottom: 5 })
          .borderRadius(14)
          .backgroundColor('#1B68B7')
          .hoverEffect(HoverEffect.Highlight)
          .onClick(() => {
            this.startTtsRead();
          })
      }
    }
    .width('100%')
    .padding({ left: 12, right: 12, top: 8, bottom: 8 })
    .margin({ bottom: 10 })
    .borderRadius(8)
    .backgroundColor('#F7F9FC')
    .alignItems(VerticalAlign.Center)
  }

  @Builder
  nluEntitySection() {
    Column() {
      Text('智能识别与快捷操作')
        .fontSize(12)
        .fontColor($r('app.color.common_color_3'))
        .margin({ bottom: 6 })
      Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.Start }) {
        ForEach(this.nluEntities, (chip: NluEntityChip, idx: number) => {
          Row({ space: 4 }) {
            Text(chip.typeLabel)
              .fontSize(11)
              .fontColor('#1B68B7')
              .padding({ left: 5, right: 5, top: 1, bottom: 1 })
              .borderRadius(4)
              .backgroundColor('#EBF4FF')
            Text(chip.text)
              .fontSize(12)
              .fontColor($r('app.color.common_color_1'))
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
              .constraintSize({ maxWidth: 180 })
            Text(chip.actionLabel)
              .fontSize(11)
              .fontColor('#1B68B7')
          }
          .padding({ left: 8, right: 8, top: 5, bottom: 5 })
          .margin({ right: 8, bottom: 8 })
          .borderRadius(14)
          .backgroundColor('#F7F9FC')
          .border({ width: 0.5, color: '#D6E4F5' })
          .alignItems(VerticalAlign.Center)
          .hoverEffect(HoverEffect.Highlight)
          .onClick(() => {
            this.onEntityChipTap(chip);
          })
        }, (chip: NluEntityChip, idx: number) => `${idx}_${chip.type}_${chip.text}`)
      }
      .width('100%')
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
    .margin({ bottom: 8 })
  }
}
