import { router } from '@kit.ArkUI';
import { TitleBar } from '../components/TitleBar';
import { ApiService } from '../network/ApiService';
import { ApiResponse } from '../model/ResponseModel';
import { YiBanBannerEntry, YiBanAppGroup, YiBanAppItem, YiBanNewsEntry,
  YiBanArticleEntry } from '../model/ContactModel';
import { Constants } from '../data/Constants';
import { EmptyView } from '../components/EmptyView';
import { LoadingView } from '../components/LoadingView';

/**
 * 易班聚合页 — 源码级翻译（YiBanFragment.java + YiBanPImpl + YiBanModel + 4 adapter 逐行 → ArkTS，
 * [W25 misc-b]）：
 *
 * 【布局】mobile_campus_fragment_yiban：toolbar"易班"（A0：toolBarView gone → TitleBar 标题保留等价）
 *   + PullToRefreshLayout + RecyclerView(VLayout 聚合列表)
 * 【数据】X1()：4 个请求并行（banner=YiBanModel.X0 showData{Ad} / 应用=U0 application /
 *   头条=T0 showData{Toutiao}（>3 条截前 3）/ 易瞄瞄=Z0 GetArticleList{page:"1",pagesize:"15"}）；
 *   e2() 计数 4 次回调齐 → 全 null → EMPTY 态；否则聚合渲染：banner(AppBannerAdapterV22) +
 *   应用分组（YiBanAppTitleAdapter 组头+YiBanAppAdapter 宫格）/ 头条（组头"头条"+YiBanNewsAdapter）/
 *   易瞄瞄（组头"易瞄瞄"+YiBanArticleAdapter）
 * 【组头】mobile_campus_item_yiban_title.xml：38dip(px_to_dip_76) pl12：竖条 4dip(primary)+标题 14fp
 *   common_color_3 ml8（px_to_dip_8=4/px_to_sp_28=14/px_to_dip_16=8）
 * 【宫格】AppAdapterV2 item（unread_item 小图版）：60×48 图标(padH14 padV8) + 13fp #555555 名 maxLines2；
 *   点击 g 类 → a2(AppBean) → LightAppPage{yyid:YYID, lx:LX, url:URL}（util.a.f 轻应用链）
 * 【头条行】mobile_campus_item_app_unread_item_big.xml：容器 76dip(px_to_dip_152) 居中：ivImage 59×59
 *   (px_to_dip_118) mt13 fitXY + tvTitle 12fp(px_to_sp_24) 居中 mt4 mb12 maxLines2（角标 XML gone）；
 *   点击 f 类 → AppBean{URL, LX(空或"3"→"4"), YYID:"yibannews"} → LightAppPage
 * 【易瞄瞄行】YiBanArticleAdapter：头像40+昵称14fp+单位+正文(Html.fromHtml)+"查看全部/收起"（c/d 类
 *   折叠）；点击 e 类 → /yiban/ymmDetail{newsId}（YiMiaoMiaoDetailPage）
 * 【下拉】h 类 a() → X1() 重拉；上拉禁用
 */
interface YiBanListRow {
  kind: string;
  group?: YiBanAppGroup;
  app?: YiBanAppItem;
  news?: YiBanNewsEntry;
  article?: YiBanArticleEntry;
}

@Entry
@Component
struct YiBanPage {
  @State banners: YiBanBannerEntry[] = [];
  @State groups: YiBanAppGroup[] = [];
  @State newsList: YiBanNewsEntry[] = [];
  @State articleList: YiBanArticleEntry[] = [];
  @State isLoading: boolean = true;
  @State rows: YiBanListRow[] = [];
  @State isRefreshing: boolean = false;
  /** 源码 k：回调计数（4 次齐 → 渲染） */
  private callbackCount: number = 0;
  private bannerGot: boolean = false;
  private appGot: boolean = false;
  private newsGot: boolean = false;
  private articleGot: boolean = false;

  onPageShow(): void {
    // 源码 U0()（onHiddenChanged/false 显示）→ X1()；HAP onPageShow 重拉
    this.reload();
  }

  aboutToAppear(): void {
    this.reload();
  }

  /** 源码 X1()：k=0 + 4 请求 */
  private reload(): void {
    this.isLoading = true;
    this.callbackCount = 0;
    this.bannerGot = false;
    this.appGot = false;
    this.newsGot = false;
    this.articleGot = false;
    ApiService.getYiBanBanners().then((r: ApiResponse<YiBanBannerEntry[]>) => {
      if (r.code === 0 && r.data.length > 0) {
        this.banners = r.data;
        this.bannerGot = true;
      }
      this.onPartDone();
    }).catch(() => {
      this.onPartDone();
    });
    ApiService.getYiBanApplications().then((r: ApiResponse<YiBanAppGroup[]>) => {
      if (r.code === 0 && r.data.length > 0) {
        this.groups = r.data;
        this.appGot = true;
      }
      this.onPartDone();
    }).catch(() => {
      this.onPartDone();
    });
    ApiService.getYiBanNews().then((r: ApiResponse<YiBanNewsEntry[]>) => {
      if (r.code === 0 && r.data.length > 0) {
        // 源码 b 类：>3 条截前 3
        this.newsList = r.data.length > 3 ? r.data.slice(0, 3) : r.data;
        this.newsGot = true;
      }
      this.onPartDone();
    }).catch(() => {
      this.onPartDone();
    });
    ApiService.getYiBanArticles('1').then((r: ApiResponse<YiBanArticleEntry[]>) => {
      if (r.code === 0 && r.data.length > 0) {
        this.articleList = r.data;
        this.articleGot = true;
      }
      this.onPartDone();
    }).catch(() => {
      this.onPartDone();
    });
  }

  /** 源码 e2()：计数齐 → 全空 EMPTY / 渲染聚合 */
  private onPartDone(): void {
    this.callbackCount = this.callbackCount + 1;
    if (this.callbackCount < 4) {
      return;
    }
    this.isLoading = false;
    this.isRefreshing = false;
    if (!this.bannerGot && !this.appGot && !this.newsGot && !this.articleGot) {
      // 源码 t0(EMPTY)
      this.rows = [];
      return;
    }
    const list: YiBanListRow[] = [];
    if (this.bannerGot) {
      // banner 区由 Swiper 直接渲染，不进行列表
    }
    for (const group of this.groups) {
      if (group.DATA.length === 0) {
        continue;
      }
      // 源码 R1：组头 + 宫格
      list.push({ kind: 'title', group: group });
      for (const app of group.DATA) {
        list.push({ kind: 'app', app: app });
      }
    }
    if (this.newsGot) {
      const head: YiBanAppGroup = new YiBanAppGroup();
      head.YYFL = '头条';
      list.push({ kind: 'title', group: head });
      for (const news of this.newsList) {
        list.push({ kind: 'news', news: news });
      }
    }
    if (this.articleGot) {
      const head: YiBanAppGroup = new YiBanAppGroup();
      head.YYFL = '易瞄瞄';
      list.push({ kind: 'title', group: head });
      for (const article of this.articleList) {
        list.push({ kind: 'article', article: article });
      }
    }
    this.rows = list;
  }

  /** 源码 f 类：新闻点击 → AppBean{URL, LX(空或3→4), YYID:"yibannews"} → 轻应用链 */
  private openNews(news: YiBanNewsEntry): void {
    const lx: string = news.LX === '' || news.LX === '3' ? '4' : news.LX;
    router.pushUrl({ url: 'pages/LightAppPage',
      params: { 'yyid': 'yibannews', 'lx': lx, 'url': news.URL } as Record<string, string> });
  }

  /** 源码 g 类：应用点击 → a2(AppBean) → 轻应用链 */
  private openApp(app: YiBanAppItem): void {
    const params: Record<string, string> = {
      'yyid': app.YYID,
      'lx': app.LX === '' ? '4' : app.LX,
      'url': app.URL
    };
    router.pushUrl({ url: 'pages/LightAppPage', params: params });
  }

  /** 源码 e 类：文章点击 → /yiban/ymmDetail{newsId} */
  private openArticle(article: YiBanArticleEntry): void {
    router.pushUrl({ url: 'pages/YiMiaoMiaoDetailPage',
      params: { 'newsId': article.news_id } as Record<string, string> });
  }

  private coverUrlOf(tp: string): string {
    return tp === '' ? '' : Constants.SOCKET_HOST + tp;
  }

  build() {
    Column() {
      TitleBar({ title: '易班', showBack: true })

      if (this.isLoading) {
        LoadingView()
      } else if (this.rows.length === 0 && this.banners.length === 0) {
        // 源码 e2：全 null → EMPTY
        Column() {
          EmptyView({ tipText: '暂无数据' })
        }
        .width('100%')
        .layoutWeight(1)
      } else {
        Refresh({ refreshing: this.isRefreshing }) {
          List() {
            // banner（AppBannerAdapterV22 等价：轮播图）
            if (this.banners.length > 0) {
              ListItem() {
                Swiper() {
                  ForEach(this.banners, (banner: YiBanBannerEntry) => {
                    Image(this.coverUrlOf(banner.TP))
                      .width('100%')
                      .height(110)
                      .objectFit(ImageFit.Fill)
                  }, (banner: YiBanBannerEntry) => banner.XLH)
                }
                .width('100%')
                .height(110)
                .autoPlay(true)
                .indicator(true)
              }
            }
            ForEach(this.rows, (row: YiBanListRow, idx: number) => {
              ListItem() {
                if (row.kind === 'title') {
                  this.groupTitle(row.group!.YYFL)
                } else if (row.kind === 'app') {
                  this.appRow(row.app!)
                } else if (row.kind === 'news') {
                  this.newsRow(row.news!)
                } else {
                  this.articleRow(row.article!)
                }
              }
            }, (row: YiBanListRow, idx: number) => row.kind + '_' + idx)
          }
          .width('100%')
          .layoutWeight(1)
          .scrollBar(BarState.Off)
          .backgroundColor($r('app.color.white'))
        }
        .width('100%')
        .layoutWeight(1)
        .onRefreshing(() => {
          // 源码 h 类 a()：下拉 → X1() 重拉
          this.isRefreshing = true;
          this.reload();
        })
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.white'))
  }

  // mobile_campus_item_yiban_title.xml：竖条 4dip primary + 标题 14fp common_color_3 ml8（高38 pl12）
  @Builder
  groupTitle(title: string) {
    Row() {
      Column()
        .width(4)
        .height('100%')
        .backgroundColor($r('app.color.mobile_campus_primary_color'))
      Text(title)
        .fontSize(14)
        .fontColor($r('app.color.common_color_3'))
        .margin({ left: 8 })
    }
    .width('100%')
    .height(38)
    .padding({ left: 12, right: 12 })
    .alignItems(VerticalAlign.Center)
  }

  // AppAdapterV2 unread_item：60×48 图标(padH14 padV8) + 13fp #555555 名
  @Builder
  appRow(app: YiBanAppItem) {
    Column() {
      Image(this.coverUrlOf(app.ICON) === '' ? $r('app.media.icon_share') : this.coverUrlOf(app.ICON))
        .width(60)
        .height(48)
        .objectFit(ImageFit.Contain)
      Text(app.NAME)
        .fontSize(13)
        .fontColor('#555555')
        .maxLines(2)
        .textAlign(TextAlign.Center)
    }
    .width('25%')
    .padding({ left: 15, right: 15, top: 5, bottom: 5 })
    .alignItems(HorizontalAlign.Center)
    .onClick(() => {
      this.openApp(app);
    })
  }

  // mobile_campus_item_app_unread_item_big.xml：59×59 图 mt13 + 标题 12fp 居中 mt4 mb12
  @Builder
  newsRow(news: YiBanNewsEntry) {
    Column() {
      Image(this.coverUrlOf(news.TP) === '' && this.coverUrlOf(news.image) === ''
        ? $r('app.media.icon_share')
        : (this.coverUrlOf(news.TP) !== '' ? this.coverUrlOf(news.TP) : this.coverUrlOf(news.image)))
        .width(59)
        .height(59)
        .objectFit(ImageFit.Fill)
      Text(news.TITLE === '' ? news.title : news.TITLE)
        .fontSize(12)
        .fontColor($r('app.color.common_color_1'))
        .margin({ top: 4, bottom: 12 })
        .maxLines(2)
        .textAlign(TextAlign.Center)
    }
    .width(76)
    .alignItems(HorizontalAlign.Center)
    .margin({ left: 12, right: 12 })
    .onClick(() => {
      this.openNews(news);
    })
  }

  // YiBanArticleAdapter 行：头像40 + 昵称14fp + 单位12fp + 正文（Html）+ "查看全部/收起"
  @Builder
  articleRow(article: YiBanArticleEntry) {
    Column() {
      Row() {
        Image(this.coverUrlOf(article.yb_userhead) === '' ? $r('app.media.ybg_tx_default_man')
          : this.coverUrlOf(article.yb_userhead))
          .width(40)
          .height(40)
          .borderRadius(20)
        Column() {
          Text(article.yb_usernick)
            .fontSize(14)
            .fontColor($r('app.color.common_color_1'))
            .maxLines(1)
          Text(article.yb_schoolname)
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
      .padding({ left: 12, right: 12, top: 10 })
      .alignItems(VerticalAlign.Center)

      Text(article.news_content === '' ? article.content : article.news_content)
        .fontSize(15)
        .fontColor($r('app.color.common_color_1'))
        .width('100%')
        .padding({ left: 12, right: 12, top: 8, bottom: 8 })
        .maxLines(6)
        .textOverflow({ overflow: TextOverflow.Ellipsis })

      Text('查看全部')
        .fontSize(13)
        .fontColor($r('app.color.ybg_blue'))
        .width('100%')
        .textAlign(TextAlign.End)
        .padding({ left: 12, right: 12, bottom: 10 })
    }
    .width('100%')
    .backgroundColor($r('app.color.white'))
    .onClick(() => {
      this.openArticle(article);
    })
  }
}
