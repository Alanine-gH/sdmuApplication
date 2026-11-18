import { router } from '@kit.ArkUI';
import { BusinessError } from '@kit.BasicServicesKit';
import { TitleBar } from '../components/TitleBar';
import { LoadingView } from '../components/LoadingView';
import { ApiService, BizJsonResult } from '../network/ApiService';
import { SocialPost } from '../model/SocialModels';
import { Constants } from '../data/Constants';

/**
 * 最新动态页 — 源码级翻译 NewNewsActivityEx（[P-B placeholder]）：
 * 【入口】PostPublishPage 发帖成功 replaceUrl('pages/SocialNewNewsPage')（源码 PostPublish K()
 *   postType=="1"→NewNewsActivity）；标题 R.string.scoial_new_news="新鲜事"；右上 nav_plus_btn。
 * 【数据 f1()】列表 q.f("-1")→NewActivityPresenter.f→SocialModel.v→LIANYI freshNewList
 *   {lastId}（e.b GET + xxdm 头 @push 域，实测 SSL EOF 不可达 → 真实错误态，绝不编造动态）；
 *   上拉 W2()=末条 id 追加，下拉 a() lastId="-1" 重置。
 *   头条 q.h(1,1)→freshpapers（push 不可达→i() 空→read_container GONE）。
 *   Ex 特有 G1()=statecontroller.a(null)，i() 里 f12860a(xxdm) 非空→head GONE（测试账号 sdmu 非空）。
 * 【列表项 NewsAdapter/social_post_item】头像40+昵称+单位+相对时间+内容+九宫格+评论/点赞；
 *   点击 X2(i,false)→PostDetailActivity{id,targetUserId,type:2}；发布→PostPublishPage post_type="1"。
 */
interface ExNewsHead {
  cover: string;
  title: string;
  viewNum: string;
}

@Entry
@Component
struct SocialNewNewsPage {
  @State posts: SocialPost[] = [];
  @State viewState: string = 'loading';
  @State head: ExNewsHead | null = null;
  @State refreshing: boolean = false;
  @State loadingMore: boolean = false;
  private page: number = 1;

  aboutToAppear(): void {
    this.load(true);
    this.loadHead();
  }

  /** 源码 c()/a()：首屏与下拉 lastId="-1"（LIANYI freshNewList） */
  private load(isRefresh: boolean): void {
    if (isRefresh) {
      this.page = 1;
    } else {
      this.loadingMore = true;
    }
    this.refreshing = isRefresh;
    const lastId: string = isRefresh ? '-1' : this.lastId();
    ApiService.pushGetFreshNewList(lastId)
      .then((result: BizJsonResult) => {
        this.refreshing = false;
        this.loadingMore = false;
        if (result.code !== 0) {
          if (isRefresh) {
            this.viewState = 'error';
          }
          ApiService.logError('freshNewList code=' + result.code + ' msg=' + result.message);
          return;
        }
        const list: SocialPost[] = SocialPost.listFrom(ApiService.extractArray(result.data));
        this.posts = isRefresh ? list : this.posts.concat(list);
        this.viewState = this.posts.length > 0 ? 'content' : 'empty';
        if (list.length > 0) {
          this.page = this.page + 1;
        }
      })
      .catch((error: BusinessError) => {
        this.refreshing = false;
        this.loadingMore = false;
        if (isRefresh) {
          this.viewState = 'error';
        }
        ApiService.logError('freshNewList fail: ' + error.message);
      });
  }

  private lastId(): string {
    return this.posts.length === 0 ? '-1' : (this.posts[this.posts.length - 1].id || '-1');
  }

  /** 源码 q.h(1,1)→freshpapers；Ex i() f12860a 非空→head GONE（实测 sdmu 非空），静默 */
  private loadHead(): void {
    ApiService.pushGetFreshPapers(1, 1)
      .then((result: BizJsonResult) => {
        if (result.code !== 0) {
          this.head = null;
          return;
        }
        const rows: Object[] = ApiService.extractArray(result.data);
        if (rows.length === 0) {
          this.head = null;
          return;
        }
        const rec: Record<string, Object> = ApiService.asRecord(rows[0]);
        const pick = (key: string): string => ApiService.pick(rec, [key]);
        this.head = { cover: pick('COVER'), title: pick('TITLE'), viewNum: pick('VIEWNUM') };
      })
      .catch((error: BusinessError) => { this.head = null; ApiService.logError('freshpapers fail: ' + error.message); });
  }

  /** 源码 e.h(publishTime, serversTime)：相对时间（与 PostDetailPage 同款） */
  private formatTime(publishTime: string, serversTime: string): string {
    if (publishTime === '') {
      return '';
    }
    try {
      const ref: Date = serversTime === '' ? new Date() : new Date(serversTime.replace(/-/g, '/'));
      const date: Date = new Date(publishTime.replace(/-/g, '/'));
      const diffSec: number = Math.floor((ref.getTime() - date.getTime()) / 1000);
      if (diffSec < 60) {
        return diffSec + '秒前';
      }
      const diffMin: number = Math.floor(diffSec / 60);
      if (diffMin < 60) {
        return diffMin + '分钟前';
      }
      if (diffMin <= 120) {
        return '1小时前';
      }
      const pad = (v: number): string => v < 10 ? '0' + String(v) : String(v);
      const sameDay: boolean = ref.getFullYear() === date.getFullYear()
        && ref.getMonth() === date.getMonth() && ref.getDate() === date.getDate();
      if (sameDay) {
        return pad(date.getHours()) + ':' + pad(date.getMinutes());
      }
      return pad(date.getMonth() + 1) + '-' + pad(date.getDate()) + ' ' +
        pad(date.getHours()) + ':' + pad(date.getMinutes());
    } catch (error) {
      const be = error as BusinessError;
      ApiService.logError('formatTime fail: ' + be.message);
      return '';
    }
  }

  private toPublish(): void {
    router.pushUrl({ url: 'pages/PostPublishPage', params: { 'post_type': '1' } });
  }

  private onPostTap(post: SocialPost): void {
    router.pushUrl({ url: 'pages/PostDetailPage',
      params: { 'id': post.id, 'targetUserId': post.userId, 'type': 2 } });
  }

  @Builder
  newsHeadView() {
    if (this.head !== null) {
      Column() {
        Text('悦读 更多 >').fontSize(14).fontColor($r('app.color.common_color_3'))
          .width('100%').padding({ left: 15, right: 15, top: 10, bottom: 10 })
        Row() {
          if (this.head!.cover !== '') {
            Image(this.head!.cover).width(70).height(52).objectFit(ImageFit.Cover).margin({ right: 10 })
          }
          Column() {
            Text(this.head!.title).fontSize(15).fontColor($r('app.color.common_color_1')).maxLines(2)
            Text(this.head!.viewNum + '   阅读')
              .fontSize(12).fontColor($r('app.color.common_color_3')).margin({ top: 4 })
          }
          .alignItems(HorizontalAlign.Start).layoutWeight(1)
        }
        .width('100%').padding({ left: 15, right: 15, bottom: 10 })
      }
      .width('100%').backgroundColor($r('app.color.main_bg'))
    }
  }

  private picSrc(pic: string): ResourceStr {
    return pic.startsWith('http') ? pic : Constants.SOCKET_HOST + '/' + pic;
  }

  /** 源码 social_post_item 九宫格容器：最多 9 图，每行 3 张 */
  private photoRows(post: SocialPost): string[][] {
    const pics: string[] = post.pictureList().slice(0, 9);
    const rows: string[][] = [];
    for (let i: number = 0; i < pics.length; i += 3) {
      rows.push(pics.slice(i, i + 3));
    }
    return rows;
  }

  @Builder
  postPhotos(post: SocialPost) {
    Column() {
      ForEach(this.photoRows(post), (row: string[], rowIndex: number) => {
        Row() {
          ForEach(row, (pic: string) => {
            Image(this.picSrc(pic))
              .width('32%').aspectRatio(1).objectFit(ImageFit.Cover).borderRadius(2)
          }, (pic: string) => pic)
        }
        .width('100%').margin({ top: 6 })
      }, (row: string[], rowIndex: number) => String(rowIndex))
    }
    .width('100%')
    .visibility(post.pictureList().length > 0 ? Visibility.Visible : Visibility.None)
  }

  @Builder
  postItem(post: SocialPost) {
    Column() {
      Row() {
        Image(post.avatar === '' ? $r('app.media.default_avatar') : post.avatar)
          .width(40).height(40).borderRadius(20).objectFit(ImageFit.Cover)
        Column() {
          Row() {
            Text(post.displayName()).fontSize(14).fontColor($r('app.color.common_color_1'))
            Blank()
            Text(this.formatTime(post.publishTime, post.serversTime))
              .fontSize(12).fontColor($r('app.color.common_color_3'))
          }
          .width('100%')
          Text(post.unit).fontSize(12).fontColor($r('app.color.common_color_3')).margin({ top: 2 })
        }
        .alignItems(HorizontalAlign.Start).layoutWeight(1).margin({ left: 10 })
      }
      .width('100%')
      Text(post.content).fontSize(15).fontColor($r('app.color.common_color_1'))
        .width('100%').margin({ top: 8 }).maxLines(4)
        .visibility(post.content === '' ? Visibility.None : Visibility.Visible)
      this.postPhotos(post)
      Row() {
        Text('评论  ' + post.commentNum).fontSize(13).fontColor($r('app.color.common_color_3'))
        Blank()
        Text(post.likeNum === '' || post.likeNum === '0' ? '' : '已有' + post.likeNum + '人点赞')
          .fontSize(13).fontColor($r('app.color.common_color_3'))
      }
      .width('100%').margin({ top: 10 })
    }
    .width('100%').padding(15).backgroundColor($r('app.color.white'))
    .onClick(() => { this.onPostTap(post); })
  }

  build() {
    Column() {
      TitleBar({ title: '新鲜事', showBack: true, rightIcon: $r('app.media.nav_plus_btn'),
        onRightClick: (): void => { this.toPublish(); } })
      if (this.viewState === 'loading') {
        LoadingView()
      } else if (this.viewState === 'empty') {
        Column() {
          Image($r('app.media.mobile_campus_page_develop')).width(160).objectFit(ImageFit.Contain)
          Text('暂无动态').fontSize(14).fontColor($r('app.color.sdmu_text_hint')).margin({ top: 16 })
        }
        .width('100%').layoutWeight(1).justifyContent(FlexAlign.Center)
      } else if (this.viewState === 'error') {
        Column() {
          Image($r('app.media.mobile_campus_page_internet')).width(120).objectFit(ImageFit.Contain)
          Text('网络好像有点问题，过一会再试吧').fontSize(14)
            .fontColor($r('app.color.sdmu_text_hint')).margin({ top: 16 })
          Text('重试').fontSize(15).fontColor($r('app.color.white'))
            .padding({ left: 17, right: 17, top: 4, bottom: 4 })
            .backgroundColor($r('app.color.blue_default')).margin({ top: 16 })
            .onClick(() => { this.viewState = 'loading'; this.load(true); })
        }
        .width('100%').layoutWeight(1).justifyContent(FlexAlign.Center)
      } else {
        List() {
          ListItem() { this.newsHeadView() }
          ForEach(this.posts, (post: SocialPost) => { ListItem() { this.postItem(post); } },
            (post: SocialPost) => post.id)
          if (this.loadingMore) {
            ListItem() { LoadingView() }
          }
        }
        .width('100%').layoutWeight(1)
        .onReachEnd(() => { if (!this.loadingMore && !this.refreshing) { this.load(false); } })
      }
    }
    .width('100%').height('100%').backgroundColor($r('app.color.main_bg'))
  }
}
