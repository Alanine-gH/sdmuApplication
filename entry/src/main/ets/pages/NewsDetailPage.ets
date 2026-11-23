import { router } from '@kit.ArkUI';
import { common } from '@kit.AbilityKit';
import { BreakpointSystem } from '../common/BreakpointSystem';
import { ApiService } from '../network/ApiService';
import { NewsItem } from '../model/NewsModel';
import { EmptyView } from '../components/EmptyView';
import { ShareHelper } from '../common/ShareHelper';

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
  @StorageProp('currentBreakpoint') currentBreakpoint: string = 'sm';
  @StorageProp('isCompactHeight') isCompactHeight: boolean = false;
  @StorageProp('avoidAreaLeftVp') avoidAreaLeftVp: number = 0;
  @StorageProp('avoidAreaRightVp') avoidAreaRightVp: number = 0;
  @StorageProp('avoidAreaBottomVp') avoidAreaBottomVp: number = 0;
  private newsId: string = '';

  aboutToAppear(): void {
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

  loadDetail(): void {
    this.isLoading = true;
    ApiService.getNewsDetail(this.newsId)
      .then((response) => {
        this.news = response.data;
        this.isLoading = false;
      })
      .catch(() => {
        this.isLoading = false;
      });
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
}
