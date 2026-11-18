import { router } from '@kit.ArkUI';
import { TitleBar } from '../components/TitleBar';
import { ApiService } from '../network/ApiService';
import { ApiResponse } from '../model/ResponseModel';
import { YiBanArticleEntry } from '../model/ContactModel';
import { Constants } from '../data/Constants';
import { EmptyView } from '../components/EmptyView';
import { LoadingView } from '../components/LoadingView';

/**
 * 易瞄瞄详情页 — 源码级翻译（YiMiaoMiaoDetailActivity.java 逐行 → ArkTS，[W25 misc-b]）：
 *
 * 【布局】mobile_campus_activity_yiban_ymm.xml：toolbar("详情"，T1) + MultiStateView(ScrollView)：
 *   social_post_item 头（social_fragment_post_item_iv_avatar 40dip 圆 + tv_name 16fp + tv_school）+
 *   post_list_item_tv_substance 正文（EmojiconTextView，Html.fromHtml 富文本）+ 2dip 灰条 +
 *   评论/点赞操作行（XML gone，M2 无显示操作 → 保真省略）
 * 【数据】y(Intent)：newsId → YiBanPImpl.l → YiBanModel.V0 POST getDetailByArticleId {news_id}
 *   → YiBanArticle；code!="0"||null → EMPTY；M2()：yb_usernick/头像(yb_userhead 网络图，
 *   默认 ybg_tx_default_man)/yb_schoolname/news_content(Html)；
 *   image_list 拼接串在源码 M2 未用于 photo container（p 容器代码未填充 → 不显示，保真）
 * 【f2()】下拉刷新 → K2() 重拉
 */
@Entry
@Component
struct YiMiaoMiaoDetailPage {
  @State article: YiBanArticleEntry = new YiBanArticleEntry();
  @State isLoading: boolean = true;
  @State showError: boolean = false;
  @State showEmpty: boolean = false;
  private newsId: string = '';

  aboutToAppear(): void {
    const params = router.getParams() as Record<string, string>;
    if (params !== null && params !== undefined) {
      this.newsId = params['newsId'] !== undefined && params['newsId'] !== null ? params['newsId'] : '';
    }
    this.loadDetail();
  }

  /** 源码 K2()：YiBanModel.V0 POST getDetailByArticleId {news_id} */
  private loadDetail(): void {
    this.isLoading = true;
    this.showError = false;
    this.showEmpty = false;
    ApiService.getYiBanArticleDetail(this.newsId)
      .then((response: ApiResponse<YiBanArticleEntry>) => {
        this.isLoading = false;
        if (response.code === 1000) {
          return;
        }
        if (response.code !== 0 || response.data.news_id === '') {
          // 源码 a 类 g()：code!="0"||null → EMPTY
          this.showEmpty = true;
          return;
        }
        // 源码 f() 业务失败 → s2 + toast（非 -3010 折中空态同 W9 先例）
        this.article = response.data;
      })
      .catch(() => {
        ApiService.logError('YiMiaoMiaoDetailPage load error');
        this.isLoading = false;
        this.showError = true;
      });
  }

  /** 源码 M2 头像：yb_userhead 网络图 / ybg_tx_default_man 默认 */
  private avatarUrl(): string {
    if (this.article.yb_userhead === '') {
      return '';
    }
    return Constants.SOCKET_HOST + this.article.yb_userhead;
  }

  build() {
    Column() {
      TitleBar({ title: '详情', showBack: true })

      if (this.isLoading) {
        LoadingView()
      } else if (this.showError || this.showEmpty) {
        Column() {
          EmptyView({ tipText: this.showError ? '加载失败，请检查网络后重试' : '暂无数据' })
        }
        .width('100%')
        .layoutWeight(1)
      } else {
        Scroll() {
          Column() {
            // social_post_item 头：头像 40dip 圆 + 昵称 + 学校
            Row() {
              Image(this.avatarUrl() === '' ? $r('app.media.ybg_tx_default_man') : this.avatarUrl())
                .width(40)
                .height(40)
                .borderRadius(20)
              Column() {
                Text(this.article.yb_usernick)
                  .fontSize(16)
                  .fontColor($r('app.color.common_color_1'))
                  .maxLines(1)
                Text(this.article.yb_schoolname)
                  .fontSize(12)
                  .fontColor($r('app.color.common_color_3'))
                  .margin({ top: 3 })
                  .maxLines(1)
              }
              .alignItems(HorizontalAlign.Start)
              .margin({ left: 10 })
              .layoutWeight(1)
            }
            .width('100%')
            .padding({ left: 15, right: 15, top: 10, bottom: 7 })
            .alignItems(VerticalAlign.Center)

            // 正文：Html.fromHtml → RichText（空 → gone，源码 M2 97-99）
            if (this.article.news_content === '') {
              Column()
                .height(0)
            } else {
              RichText(this.article.news_content)
                .width('100%')
                .padding({ left: 15, right: 15, top: 8, bottom: 8 })
            }

            // 2dip(px_to_dip_4) 灰条
            Divider()
              .color($r('app.color.common_color_5'))
              .strokeWidth(0.5)
              .width('100%')
          }
          .width('100%')
        }
        .width('100%')
        .layoutWeight(1)
        .scrollBar(BarState.Off)
        .align(Alignment.Top)
        .backgroundColor($r('app.color.main_bg'))
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.main_bg'))
  }
}
