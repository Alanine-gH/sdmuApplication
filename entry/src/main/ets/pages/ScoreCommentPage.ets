import { router } from '@kit.ArkUI';
import { BusinessError } from '@kit.BasicServicesKit';
import { TitleBar } from '../components/TitleBar';
import { EmptyView } from '../components/EmptyView';
import { LoadingView } from '../components/LoadingView';
import { ApiService } from '../network/ApiService';
import { ApiResponse } from '../model/ResponseModel';
import { ScoreCommentInfo } from '../model/ScoreModel';
import { Constants } from '../data/Constants';

/**
 * 留言栏 — ScoreCommentListActivity + ScoreCommentListFragment + ScoreCommentListAdapter
 * 源码级翻译（student_score/view）。
 *
 * 【入口】ScoreDetailActivity（课程成绩详情）底部"查看留言"进入，intent {xn,xq,kcdm}；
 *   HAP 上游 StudentScoreDetailPage 为聚合页无课程上下文 → 路由参数缺省空串（真实请求）。
 * 【布局】student_score_comment_list：toolbar_normal（T1"留言栏"）+ MultiStateView（bg main_bg）
 *   + RelativeLayout：底部 score3_detail_button 高 60vp 居中 17fp #18B4ED + student_score_message
 *     图标 drawablePadding 10vp + 上方 divider_grey 分隔线；PullToRefresh + SwipeMenuListView。
 * 【行】student_score_detail_comment_item：头像 34vp（68dip，default_avatar）+ 内容列 marginLeft 15vp：
 *   姓名 17fp #333333 maxWidth 230dip + 时间 12fp #CECECE；正文 14fp #555555 lineSpacingExtra 3dip。
 * 【数据】ScoreModel.m：GET comments{xn,xq,kcdm,pageNum,pageSize=10} → CommentInfo[]
 *   （AVATAR/PLNR/PLSJ/XH/XLH/XM）；pageNum=1 清空；空数组/ null → "没有数据了" 停上拉；
 *   下拉刷新 pageNum=1。左滑删除 → ScoreModel.Z deleteComment{xlh} → data "true" 移除行。
 * 【返回】finish() setResult(-1,{change,comment_num})（HAP AppStorage score_comment_result）。
 */
@Entry
@Component
struct ScoreCommentPage {
  @State comments: ScoreCommentInfo[] = [];
  @State isLoading: boolean = true;
  @State errorText: string = '';
  @State noMore: boolean = false;
  private xn: string = '';
  private xq: string = '';
  private kcdm: string = '';
  private pageNum: number = 1;
  private pageSize: number = 10;
  private changed: boolean = false;

  aboutToAppear(): void {
    const params: Record<string, Object> | undefined = router.getParams() as Record<string, Object> | undefined;
    if (params !== undefined && params !== null) {
      const xn: Object = params['xn'];
      const xq: Object = params['xq'];
      const kcdm: Object = params['kcdm'];
      this.xn = typeof xn === 'string' ? xn as string : '';
      this.xq = typeof xq === 'string' ? xq as string : '';
      this.kcdm = typeof kcdm === 'string' ? kcdm as string : '';
    }
    this.loadPage(1);
  }

  /** 源码 s.b(xn,xq,kcdm,page,10) → ScoreCommenPresenter → ScoreModel.m GET */
  private loadPage(page: number): void {
    this.isLoading = true;
    this.errorText = '';
    ApiService.getScoreCommentList(this.xn, this.xq, this.kcdm, page, this.pageSize)
      .then((response: ApiResponse<ScoreCommentInfo[]>) => {
        if (response.code === 1000) {
          return;
        }
        if (response.code !== 0) {
          this.errorText = response.message;
          this.isLoading = false;
          return;
        }
        if (page === 1) {
          this.comments = response.data;
          this.noMore = false;
        } else {
          this.comments = this.comments.concat(response.data);
        }
        this.pageNum = page;
        this.noMore = response.data.length < this.pageSize;
        this.isLoading = false;
      })
      .catch((error: BusinessError) => {
        ApiService.logError('comments fail: ' + error.message);
        this.errorText = '网络异常，请稍后重试';
        this.isLoading = false;
      });
  }

  private loadMore(): void {
    if (this.isLoading || this.noMore) {
      return;
    }
    this.loadPage(this.pageNum + 1);
  }

  private avatarSrc(item: ScoreCommentInfo): ResourceStr {
    if (item.AVATAR === '') {
      return $r('app.media.default_avatar');
    }
    return item.AVATAR.startsWith('http') ? item.AVATAR : Constants.SOCKET_HOST + '/' + item.AVATAR;
  }

  private toast(message: string): void {
    this.getUIContext().getPromptAction().showToast({ message: message, duration: 2000 });
  }

  /** 源码 e 类 SwipeMenu 删除：deleteComment{xlh} data "true" → 移除 + changed */
  private deleteComment(item: ScoreCommentInfo): void {
    ApiService.deleteScoreComment(item.XLH)
      .then((response: ApiResponse<string>) => {
        if (response.code !== 0) {
          this.toast(response.message);
          return;
        }
        if (response.data === 'true') {
          this.comments = this.comments.filter((one: ScoreCommentInfo): boolean => one.XLH !== item.XLH);
          this.changed = true;
        }
      })
      .catch((error: BusinessError) => {
        ApiService.logError('deleteComment fail: ' + error.message);
        this.toast('删除失败');
      });
  }

  private openPostPage(): void {
    router.pushUrl({
      url: 'pages/ScoreCommentPostPage',
      params: { 'xn': this.xn, 'xq': this.xq, 'kcdm': this.kcdm } as Record<string, Object>
    });
  }

  /** 源码 finish()：setResult(-1,{change,comment_num})（HAP AppStorage 管道；系统返回时回写） */
  private leavePage(): void {
    const result: Record<string, Object> = {
      'change': this.changed, 'comment_num': String(this.comments.length)
    };
    AppStorage.setOrCreate<string>('score_comment_result', JSON.stringify(result));
  }

  onBackPress(): boolean {
    this.leavePage();
    return false;
  }

  @Builder
  commentRow(item: ScoreCommentInfo) {
    Row() {
      Image(this.avatarSrc(item))
        .width(34)
        .height(34)
        .borderRadius(17)
        .objectFit(ImageFit.Cover)
        .alt($r('app.media.default_avatar'))
      Column() {
        Row() {
          Text(item.XM)
            .fontSize(17)
            .fontColor($r('app.color.common_color_1'))
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .layoutWeight(1)
          Text(item.PLSJ)
            .fontSize(12)
            .fontColor($r('app.color.common_color_4'))
            .maxLines(1)
        }
        .width('100%')
        .alignItems(VerticalAlign.Center)
        Text(item.PLNR)
          .fontSize(14)
          .fontColor($r('app.color.common_color_2'))
          .lineHeight(21)
          .width('100%')
          .margin({ top: 3 })
      }
      .layoutWeight(1)
      .margin({ left: 15 })
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .padding(15)
    .backgroundColor($r('app.color.white'))
    .alignItems(VerticalAlign.Top)
    .gesture(LongPressGesture({ repeat: false }).onAction((): void => { this.deleteComment(item); }))
  }

  build() {
    Column() {
      TitleBar({ title: '留言栏', showBack: true })
      if (this.isLoading && this.comments.length === 0) {
        LoadingView()
      } else if (this.errorText !== '') {
        EmptyView({ tipText: this.errorText })
      } else if (this.comments.length === 0) {
        EmptyView({ tipText: '暂无留言' })
      } else {
        List() {
          ForEach(this.comments, (item: ScoreCommentInfo) => {
            ListItem() {
              this.commentRow(item)
            }
          }, (item: ScoreCommentInfo) => item.XLH)
        }
        .layoutWeight(1)
        .width('100%')
        .divider({ strokeWidth: 0.5, color: $r('app.color.common_color_5'), startMargin: 0, endMargin: 0 })
        .backgroundColor($r('app.color.common_color_6'))
        .onReachEnd((): void => { this.loadMore(); })
        .scrollBar(BarState.Off)
      }
      Divider().color($r('app.color.common_color_5')).strokeWidth(0.5).width('100%')
      Row() {
        Image($r('app.media.student_score_message'))
          .width(18)
          .height(18)
        Text('给同学留言')
          .fontSize(17)
          .fontColor($r('app.color.common_color_7'))
          .margin({ left: 10 })
      }
      .width('100%')
      .height(60)
      .justifyContent(FlexAlign.Center)
      .backgroundColor($r('app.color.main_bg'))
      .onClick((): void => { this.openPostPage(); })
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.main_bg'))
  }
}
