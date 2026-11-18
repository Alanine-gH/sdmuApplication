import { router, promptAction } from '@kit.ArkUI';
import { BusinessError } from '@kit.BasicServicesKit';
import { TitleBar } from '../components/TitleBar';
import { LoadingView } from '../components/LoadingView';
import { ApiService } from '../network/ApiService';
import { ApiResponse } from '../model/ResponseModel';
import { LoginSession } from '../network/LoginSession';
import { SocialPost } from '../model/SocialModels';
import { Constants } from '../data/Constants';

/**
 * 我的帖子页 — 1:1 复刻 MyPostActivity（common_refresh_lv_rl_toolbar）+ MyPostPresenter。
 * 【源码还原】
 *   - 入参 user_id/user_name/user_type/school_id（SocialMainActivity 菜单"我的帖子"/
 *     UserDetailActivity.f3"TA的帖子"入口）；标题：本人→R.string.my_post"我的贴子"、
 *     他人→R.string.my_posted"发过的帖子"；
 *   - 列表 = MyPostPresenter.b(lastId,user,userType,schoolId) → SocialModel.H0 →
 *     LIANYI getSomeoneCircleList {lastId,userId,userType,schoolId}（e.b GET + xxdm 头）；
 *   - 2026-11-18 实测 push 域校园网不可达（WinError 10054/SSL EOF）→ 真实错误态 + 重试，
 *     空数据文案 empty_my_post"你还没发过帖子哦"；绝无编造帖子；
 *   - 条目点击：type=="2" → MarkDetailActivity，否则 PostDetailActivity {id,targetUserId,type:3}；
 *   - 下拉刷新（lastId="-1"）/上拉加载（lastId=末条 id）。
 */
@Entry
@Component
struct MyPostPage {
  @State posts: SocialPost[] = [];
  @State pageState: number = 0; // 0=loading 1=content 2=error 3=empty
  @State errMsg: string = '';
  @State isRefreshing: boolean = false;
  @State isLoadingMore: boolean = false;
  private userId: string = '';
  private userName: string = '';
  private userType: string = '';
  private schoolId: string = '';

  aboutToAppear(): void {
    const params: Record<string, Object> = (router.getParams() ?? {}) as Record<string, Object>;
    const pick = (k: string): string => {
      const v: Object | undefined = params[k];
      return typeof v === 'string' ? v as string : '';
    };
    this.userId = pick('user_id') === '' ? LoginSession.userId : pick('user_id');
    this.userName = pick('user_name');
    this.userType = pick('user_type') === '' ? LoginSession.userType : pick('user_type');
    this.schoolId = pick('school_id') === '' ? LoginSession.schoolId : pick('school_id');
    this.refresh();
  }

  /** 源码 Q2()：末条 id 作为加载 more 的 lastId */
  private lastId(): string {
    if (this.posts.length === 0) {
      return '-1';
    }
    const last: SocialPost = this.posts[this.posts.length - 1];
    return last.id === '' ? '-1' : last.id;
  }

  /** 源码 P2()：列表请求（push 域不可达 → 真实错误态） */
  private load(lastId: string, isRefresh: boolean): void {
    ApiService.pushGetSomeoneCircleList(lastId, this.userId, this.userType, this.schoolId)
      .then((response: ApiResponse<Object>) => {
        this.isRefreshing = false;
        this.isLoadingMore = false;
        if (response.code !== 0) {
          this.errMsg = response.message;
          if (isRefresh) {
            this.pageState = 2;
          }
          promptAction.showToast({ message: response.message });
          return;
        }
        const raw: Object[] = Array.isArray(response.data) ? response.data as Object[] : [];
        const list: SocialPost[] = SocialPost.listFrom(raw);
        if (isRefresh) {
          this.posts = list;
        } else {
          this.posts = this.posts.concat(list);
        }
        this.pageState = this.posts.length === 0 ? 3 : 1;
      })
      .catch((error: BusinessError) => {
        this.isRefreshing = false;
        this.isLoadingMore = false;
        this.errMsg = error.message;
        if (isRefresh) {
          this.pageState = 2;
        }
        promptAction.showToast({ message: error.message });
      });
  }

  /** 源码 b.a()：下拉刷新 lastId="-1" */
  private refresh(): void {
    this.isRefreshing = true;
    this.load('-1', true);
  }

  /** 源码 b.b()：上拉加载 lastId=末条 id */
  private loadMore(): void {
    if (this.isLoadingMore || this.pageState !== 1) {
      return;
    }
    this.isLoadingMore = true;
    this.load(this.lastId(), false);
  }

  /** 源码 c()：条目点击 type=="2" → MarkDetail，否则 PostDetail {type:3} */
  private onItemTap(post: SocialPost): void {
    const params: Record<string, Object> = {
      'id': post.id, 'targetUserId': post.userId, 'type': 3
    };
    if (post.type === '2') {
      router.pushUrl({ url: 'pages/MarkDetailPage', params: params });
    } else {
      router.pushUrl({ url: 'pages/PostDetailPage', params: params });
    }
  }

  /** 源码 MyPostAdapter.setMarketTag：type=="2" 时 已成交(状态!=0)/想卖(marketType=0)/想买(marketType=1)，其余隐藏 */
  private marketTag(post: SocialPost): string {
    if (post.type !== '2') {
      return '';
    }
    if (post.marketStatus !== '0') {
      return '已成交';
    }
    if (post.marketType === '0') {
      return '想卖';
    }
    if (post.marketType === '1') {
      return '想买';
    }
    return '';
  }

  private avatarSrc(post: SocialPost): ResourceStr {
    if (post.avatar !== '') {
      return post.avatar.startsWith('http') ? post.avatar : Constants.SOCKET_HOST + '/' + post.avatar;
    }
    return $r('app.media.default_avatar');
  }

  /** 源码 MyPostAdapter：头像+昵称+时间+内容+评论数（操作弹层沿用详情页入口，此处直跳详情） */
  @Builder
  postRow(post: SocialPost) {
    Row() {
      Image(this.avatarSrc(post))
        .width(40)
        .height(40)
        .borderRadius(20)
        .objectFit(ImageFit.Cover)
      Column() {
        Row() {
          Text(post.displayName())
            .fontSize(14)
            .fontColor($r('app.color.common_color_1'))
          Blank()
          Text(this.marketTag(post))
            .fontSize(11)
            .fontColor($r('app.color.common_color_3'))
            .border({ width: 0.5, color: $r('app.color.common_color_5') })
            .borderRadius(2)
            .padding({ left: 5, right: 5, top: 1, bottom: 1 })
            .visibility(this.marketTag(post) === '' ? Visibility.None : Visibility.Visible)
        }
        .width('100%')
        Text(post.content)
          .fontSize(15)
          .fontColor($r('app.color.common_color_1'))
          .width('100%')
          .margin({ top: 6 })
          .maxLines(3)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        Text('评论 ' + post.commentNum)
          .fontSize(12)
          .fontColor($r('app.color.common_color_3'))
          .width('100%')
          .margin({ top: 8 })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
      .margin({ left: 12 })
    }
    .width('100%')
    .padding({ left: 15, right: 15, top: 12, bottom: 12 })
    .alignItems(VerticalAlign.Top)
    .backgroundColor($r('app.color.white'))
    .margin({ top: 1 })
    .onClick(() => {
      this.onItemTap(post);
    })
  }

  build() {
    Column() {
      TitleBar({
        title: this.userId === LoginSession.userId ? '我的贴子' : '发过的帖子',
        onBack: (): void => {
          router.back();
        }
      })
      Refresh({ refreshing: this.isRefreshing }) {
        if (this.pageState === 0) {
          LoadingView()
            .width('100%')
            .height('100%')
        } else if (this.pageState === 2) {
          Column({ space: 12 }) {
            Text('ⓘ')
              .fontSize(44)
              .fontColor($r('app.color.common_color_4'))
            Text(this.errMsg === '' ? '加载失败' : this.errMsg)
              .fontSize(14)
              .fontColor($r('app.color.common_color_3'))
              .textAlign(TextAlign.Center)
              .padding({ left: 30, right: 30 })
            Text('重试')
              .fontSize(14)
              .fontColor($r('app.color.common_color_12'))
              .onClick(() => {
                this.refresh();
              })
          }
          .width('100%')
          .height('100%')
          .justifyContent(FlexAlign.Center)
        } else if (this.pageState === 3) {
          Column() {
            Text('你还没发过帖子哦')
              .fontSize(14)
              .fontColor($r('app.color.common_color_4'))
          }
          .width('100%')
          .height('100%')
          .justifyContent(FlexAlign.Center)
        } else {
          List() {
            ForEach(this.posts, (post: SocialPost) => {
              ListItem() {
                this.postRow(post)
              }
            }, (post: SocialPost) => post.id)
            ListItem() {
              Text(this.posts.length >= 10 ? '上拉加载更多' : '没有更多了')
                .fontSize(12)
                .fontColor($r('app.color.common_color_4'))
                .width('100%')
                .textAlign(TextAlign.Center)
                .padding(14)
            }
          }
          .width('100%')
          .height('100%')
          .backgroundColor($r('app.color.main_bg'))
          .onReachEnd(() => {
            this.loadMore();
          })
        }
      }
      .width('100%')
      .layoutWeight(1)
      .onRefreshing(() => {
        this.refresh();
      })
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.main_bg'))
  }
}
