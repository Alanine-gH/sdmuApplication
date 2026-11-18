import { router, promptAction } from '@kit.ArkUI';
import { pasteboard } from '@kit.BasicServicesKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { TitleBar } from '../components/TitleBar';
import { LoadingView } from '../components/LoadingView';
import { ApiService } from '../network/ApiService';
import { ApiResponse } from '../model/ResponseModel';
import { LoginSession } from '../network/LoginSession';
import { SocialPost, SocialComment, SocialSubComment } from '../model/SocialModels';
import { Constants } from '../data/Constants';

/**
 * 收藏/集市帖详情页 — 1:1 复刻 MarkDetailActivity（activity_mark_detail + MarketFloatButton）+ MarketPImpl。
 * 【通道实证 2026-11-18 probe_w20_social.py】
 *   读链 = 校内 circleOpen（hasSchoolCirclePhone=false 分支，源码 MarketModel.d1/b1/f1）：
 *     getMarketInfo/getMarketComments/getMarketLikes 实测 HTTP200 code=0001 系统异常
 *     → 真实错误态（message 透传），绝不编造商品/评论/点赞。
 *   写链 = push 域 yibaogao.com（likeOperator/sendComment/deleteComment/deleteCircle/hideCircle/
 *     stickCircle/alterClassify/reGrounding/turnover/addTop/getUserScores）实测不可达 → 真实错误 toast。
 * 【UI 保真】更多菜单（复制/举报/删除[本人]/重新上架·已成交[本人集市]）；MarketFloatButton 四键
 *   （竞价置顶 market_top/已成交 market_sold/再发一件 market_post/重新上架 market_resell，仅本人显示）；
 *   marketType 标签 0=想卖 1=想买、marketStatus 0=在售 1=已成交（源码 MarkDetailView.t()）。
 */
@Entry
@Component
struct MarkDetailPage {
  @State post: SocialPost | null = null;
  @State comments: SocialComment[] = [];
  @State likeNames: string = '';
  @State pageState: number = 0; // 0=loading 1=content 2=error 3=deleted
  @State errMsg: string = '';
  @State pageNum: number = 1;
  @State hasMore: boolean = false;
  @State showInput: boolean = false;
  @State commentText: string = '';
  @State replyTarget: SocialComment | null = null;
  @State avatarVersion: number = 0;
  private postId: string = '';
  private avatarMap: Map<string, string> = new Map();

  aboutToAppear(): void {
    const params: Record<string, Object> = (router.getParams() ?? {}) as Record<string, Object>;
    const pick = (k: string): string => {
      const v: Object | undefined = params[k];
      return typeof v === 'string' ? v as string : (typeof v === 'number' ? String(v as number) : '');
    };
    this.postId = pick('id');
    this.loadDetail();
  }

  /** 源码 y4()/v$k：getMarketInfo {id}（circleOpen，0001 → 真实错误态；2000 → 帖子已删除） */
  private async loadDetail(): Promise<void> {
    if (this.postId === '') {
      this.errMsg = '缺少帖子参数';
      this.pageState = 2;
      return;
    }
    this.pageState = 0;
    const result = await ApiService.getMarketInfo(this.postId);
    if (result.code !== 0) {
      this.errMsg = result.message;
      this.pageState = 2;
      return;
    }
    const rows: Object[] = ApiService.extractArray(result.data);
    if (rows.length <= 0) {
      this.errMsg = '商品不存在';
      this.pageState = 2;
      return;
    }
    this.post = SocialPost.fromRecord(rows[0] as Record<string, Object>);
    this.pageState = 1;
    this.loadComments(1);
    this.loadLikes();
  }

  /** 源码 E4/F4：评论分页 getMarketComments {circleId,pageNum,pageSize:10} */
  private async loadComments(page: number): Promise<void> {
    const result = await ApiService.getMarketComments(this.postId, page, 10);
    if (result.code !== 0) {
      if (page === 1) {
        this.comments = [];
      }
      ApiService.logError('market comments: ' + result.message);
      return;
    }
    const list: SocialComment[] = SocialComment.listFrom(ApiService.extractArray(result.data));
    this.pageNum = page;
    this.hasMore = list.length >= 10;
    this.comments = page === 1 ? list : this.comments.concat(list);
    const ids: string[] = [];
    for (const c of list) {
      ids.push(c.userId);
    }
    this.resolveAvatars(ids);
  }

  /** 源码 z4/A4：getMarketLikes {circleId} */
  private async loadLikes(): Promise<void> {
    const result = await ApiService.getMarketLikes(this.postId);
    if (result.code !== 0) {
      return;
    }
    const rows: Object[] = ApiService.extractArray(result.data);
    const names: string[] = [];
    for (const row of rows) {
      const r: Record<string, Object> = row as Record<string, Object>;
      let n: string = ApiService.pick(r, ['nickName', 'nickname']);
      if (n === '小奕的粉丝') {
        n = '';
      }
      if (n === '') {
        n = ApiService.pick(r, ['userName']);
      }
      if (n !== '') {
        names.push(n);
      }
    }
    // 源码分隔符 ad.t = " , "
    this.likeNames = names.join(' , ');
  }

  /** 源码 base.b.a.f：头像批量补链 */
  private resolveAvatars(userIds: string[]): void {
    const need: string[] = [];
    for (const uid of userIds) {
      if (uid !== '' && !this.avatarMap.has(uid)) {
        need.push(uid);
      }
    }
    if (need.length === 0) {
      return;
    }
    ApiService.getSocialAvatars(need.join(','))
      .then((response: ApiResponse<Object>) => {
        if (response.code !== 0) {
          return;
        }
        const raw: Object[] = Array.isArray(response.data) ? response.data as Object[] : [];
        for (const one of raw) {
          const rec: Record<string, Object> = one as Record<string, Object>;
          const uid: string = ApiService.pick(rec, ['USERID']);
          if (uid !== '') {
            this.avatarMap.set(uid, ApiService.pick(rec, ['TX']));
          }
        }
        this.avatarVersion++;
      })
      .catch((error: BusinessError) => ApiService.logError('avatar fail: ' + error.message));
  }

  private avatarSrc(uid: string): ResourceStr {
    if (this.avatarMap.has(uid)) {
      const cached: string | undefined = this.avatarMap.get(uid);
      if (cached !== undefined && cached !== '') {
        return cached.startsWith('http') ? cached : Constants.SOCKET_HOST + '/' + cached;
      }
    }
    return $r('app.media.default_avatar');
  }

  /** 源码 d0()/G4/l1：点赞乐观更新（±1 反转数学）+ likeOperator push（不可达→真实错误） */
  private toggleLike(): void {
    if (this.post === null) {
      return;
    }
    const p: SocialPost = this.post;
    const num: number = Number(p.likeNum === '' ? '0' : p.likeNum);
    if (p.isLike === '1') {
      p.likeNum = String(num + 1);
      p.isLike = '0';
    } else {
      p.likeNum = String(num - 1);
      p.isLike = '1';
    }
    this.post = p;
    ApiService.pushMarketLikeOperator(this.postId, p.isLike === '1' ? '1' : '0')
      .then((response: ApiResponse<Object>) => {
        // 源码 s.g()：data=="true" → z4/A4 重新拉点赞人名
        if (response.code === 0 && (response.data as string) === 'true') {
          this.loadLikes();
        } else if (response.code !== 0) {
          promptAction.showToast({ message: response.message });
        }
      })
      .catch((error: BusinessError) => promptAction.showToast({ message: error.message }));
  }

  /** 源码 t4/b$a：评论弹层 */
  private openCommentInput(reply: SocialComment | null): void {
    this.replyTarget = reply;
    this.commentText = '';
    this.showInput = true;
  }

  /** 源码 n1 sendComment：push 域（不可达→真实错误） */
  private submitComment(): void {
    const content: string = this.commentText.trim();
    if (content === '' || this.post === null) {
      promptAction.showToast({ message: '评论内容不能为空' });
      return;
    }
    const target: SocialComment | null = this.replyTarget;
    ApiService.pushMarketSendComment(content, this.postId,
      target === null ? '' : target.userId, target === null ? '' : target.userType,
      target === null ? '' : target.userSchool, target === null ? '' : target.id)
      .then((response: ApiResponse<Object>) => {
        if (response.code === 0) {
          this.showInput = false;
          this.loadComments(1);
          this.loadDetail();
        } else {
          promptAction.showToast({ message: response.message });
        }
      })
      .catch((error: BusinessError) => promptAction.showToast({ message: error.message }));
  }

  /** 源码 L4/g：删除评论确认 */
  private confirmDeleteComment(comment: SocialComment): void {
    AlertDialog.show({
      message: '将此条评论删除，将同时删除评论下的所有回复。',
      title: '删除评论',
      primaryButton: { value: '取消', action: (): void => { } },
      secondaryButton: {
        value: '删除',
        action: (): void => {
          ApiService.pushMarketDeleteComment(this.postId, comment.id)
            .then((response: ApiResponse<Object>) => {
              if (response.code === 0) {
                this.loadComments(1);
                this.loadDetail();
              } else {
                promptAction.showToast({ message: response.message });
              }
            })
            .catch((error: BusinessError) => promptAction.showToast({ message: error.message }));
        }
      }
    });
  }

  private onCommentTap(comment: SocialComment): void {
    if (comment.userId === LoginSession.userId) {
      this.confirmDeleteComment(comment);
    } else {
      this.openCommentInput(comment);
    }
  }

  private onSubTap(sub: SocialSubComment): void {
    const reply: SocialComment = new SocialComment();
    reply.id = sub.id;
    reply.userId = sub.userId;
    reply.userType = sub.userType;
    reply.userSchool = sub.userSchool;
    reply.nickName = sub.nickName;
    this.openCommentInput(reply);
  }

  /** 源码 b0$a：更多菜单（复制/举报/删除[本人]/重新上架·已成交[本人集市]） */
  private showMoreMenu(): void {
    if (this.post === null) {
      return;
    }
    // [W21 协作修复] showActionMenu.buttons 为定长元组类型 → 按分支内联字面量元组（语义不变）
    const own: boolean = this.post.userId === LoginSession.userId;
    if (own) {
      if (this.post.type === '2') {
        if ((this.post as SocialPost).marketStatus === '0') {
          promptAction.showActionMenu({ title: '更多', buttons: [
            { text: '复制', color: '#333333' }, { text: '举报', color: '#333333' },
            { text: '删除', color: '#333333' }, { text: '已成交', color: '#333333' }
          ] })
            .then((result: promptAction.ActionMenuSuccessResponse) => this.onMoreAction(result.index, 4))
            .catch((error: BusinessError) => ApiService.logError('actionMenu: ' + error.message));
        } else {
          promptAction.showActionMenu({ title: '更多', buttons: [
            { text: '复制', color: '#333333' }, { text: '举报', color: '#333333' },
            { text: '删除', color: '#333333' }, { text: '重新上架', color: '#333333' }
          ] })
            .then((result: promptAction.ActionMenuSuccessResponse) => this.onMoreAction(result.index, 4))
            .catch((error: BusinessError) => ApiService.logError('actionMenu: ' + error.message));
        }
        return;
      }
      promptAction.showActionMenu({ title: '更多', buttons: [
        { text: '复制', color: '#333333' }, { text: '举报', color: '#333333' },
        { text: '删除', color: '#333333' }
      ] })
        .then((result: promptAction.ActionMenuSuccessResponse) => this.onMoreAction(result.index, 3))
        .catch((error: BusinessError) => ApiService.logError('actionMenu: ' + error.message));
      return;
    }
    promptAction.showActionMenu({ title: '更多', buttons: [
      { text: '复制', color: '#333333' }, { text: '举报', color: '#333333' }
    ] })
      .then((result: promptAction.ActionMenuSuccessResponse) => this.onMoreAction(result.index, 2))
      .catch((error: BusinessError) => ApiService.logError('actionMenu: ' + error.message));
  }

  /** 源码 菜单分发：复制/举报/删除→deleteCircle/重新上架→reGrounding/已成交→turnover */
  private onMoreAction(index: number, total: number): void {
    if (index < 0 || index >= total) {
      return;
    }
    if (index === 0) {
      const data: pasteboard.PasteData =
        pasteboard.createData(pasteboard.MIMETYPE_TEXT_PLAIN, this.post === null ? '' : this.post.content);
      pasteboard.getSystemPasteboard().setData(data)
        .then((): void => promptAction.showToast({ message: '已复制' }))
        .catch((error: BusinessError) => ApiService.logError('copy fail: ' + error.message));
      return;
    }
    if (index === 1) {
      router.pushUrl({
        url: 'pages/SocialReportPage',
        params: { 'id': this.postId, 'fromMarket': true }
      });
      return;
    }
    const label: string = index === 2 ? '删除' : (index === 3 ? (this.post !== null && (this.post as SocialPost).marketStatus === '0' ? '已成交' : '重新上架') : '');
    if (label === '删除') {
      this.confirmPush('是否删除帖子', (): Promise<ApiResponse<Object>> => ApiService.pushMarketDeleteCircle(this.postId));
    } else if (label === '已成交') {
      this.confirmPush('是否设置状态为已成交', (): Promise<ApiResponse<Object>> => ApiService.pushMarketTurnover(this.postId));
    } else if (label === '重新上架') {
      this.confirmPush('是否设置状态为重新上架', (): Promise<ApiResponse<Object>> => ApiService.pushMarketReGrounding(this.postId));
    }
  }

  /** 源码 dialog.g 确认弹窗统一封装（push 域调用，不可达 → 真实错误 toast） */
  private confirmPush(message: string, call: () => Promise<ApiResponse<Object>>): void {
    AlertDialog.show({
      message: message,
      primaryButton: { value: '取消', action: (): void => { } },
      secondaryButton: {
        value: '确定',
        action: (): void => {
          call()
            .then((response: ApiResponse<Object>) => {
              if (response.code === 0) {
                promptAction.showToast({ message: '操作成功' });
                router.back();
              } else {
                promptAction.showToast({ message: response.message });
              }
            })
            .catch((error: BusinessError) => promptAction.showToast({ message: error.message }));
        }
      }
    });
  }

  /** 源码 B4/m$d：竞价置顶 —— getUserScores（push 域不可达 → 真实错误 toast） */
  private bidTop(): void {
    ApiService.pushGetUserScores()
      .then((response: ApiResponse<Object>) => {
        promptAction.showToast({ message: response.code === 0 ? '请求失败，请重试' : response.message });
      })
      .catch((error: BusinessError) => promptAction.showToast({ message: error.message }));
  }

  /** 源码 MarketFloatButton 四键（仅本人帖显示）：竞价置顶/已成交/再发一件/重新上架 */
  @Builder
  floatButtons(p: SocialPost) {
    Column({ space: 10 }) {
      Image($r('app.media.market_top'))
        .width(38)
        .height(38)
        .onClick(() => {
          this.bidTop();
        })
      if (p.marketStatus === '0') {
        Image($r('app.media.market_sold'))
          .width(38)
          .height(38)
          .onClick(() => {
            this.confirmPush('确认为已成交？',
              (): Promise<ApiResponse<Object>> => ApiService.pushMarketTurnover(this.postId));
          })
      } else {
        Image($r('app.media.market_resell'))
          .width(38)
          .height(38)
          .onClick(() => {
            this.confirmPush('是否设置状态为重新上架',
              (): Promise<ApiResponse<Object>> => ApiService.pushMarketReGrounding(this.postId));
          })
      }
      Image($r('app.media.market_post'))
        .width(38)
        .height(38)
        .onClick(() => {
          router.pushUrl({ url: 'pages/MarketPostPage' });
        })
    }
    .alignItems(HorizontalAlign.Center)
  }

  /** 源码 MarkDetailView.t()：market_tag —— 已成交(状态!=0)/想卖(marketType=0)/想买(marketType=1)，其余隐藏 */
  private marketTag(p: SocialPost): string {
    if (p.marketStatus !== '0') {
      return '已成交';
    }
    if (p.marketType === '0') {
      return '想卖';
    }
    if (p.marketType === '1') {
      return '想买';
    }
    return '';
  }

  /** 源码 market/widget/a 头部：头像+昵称/单位/时间（头像点击 → UserDetailActivity）+ market_tag
   *  +内容+九宫格+评论/点赞行+点赞人名 */
  @Builder
  detailHead(p: SocialPost) {
    Column() {
      Row() {
        Image(this.avatarSrc(p.userId))
          .width(40)
          .height(40)
          .borderRadius(20)
          .objectFit(ImageFit.Cover)
          .onClick(() => {
            // 源码 ViewOnClickListenerC0306a：targetId/targetSchoolId(当前用户校)/targetUserType
            router.pushUrl({
              url: 'pages/UserDetailPage',
              params: {
                'targetId': p.userId,
                'targetSchoolId': LoginSession.schoolId,
                'targetUserType': p.userType
              }
            });
          })
        Column() {
          Text(p.displayName())
            .fontSize(14)
            .fontColor($r('app.color.common_color_1'))
          Text(p.unit)
            .fontSize(12)
            .fontColor($r('app.color.common_color_3'))
            .margin({ top: 2 })
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
        .margin({ left: 10 })
        Text(this.formatTime(p.publishTime, p.serversTime))
          .fontSize(12)
          .fontColor($r('app.color.common_color_3'))
      }
      .width('100%')
      .alignItems(VerticalAlign.Top)

      Text(this.marketTag(p))
        .fontSize(11)
        .fontColor($r('app.color.common_color_3'))
        .border({ width: 0.5, color: $r('app.color.common_color_5') })
        .borderRadius(2)
        .padding({ left: 6, right: 6, top: 1, bottom: 1 })
        .margin({ top: 8 })
        .visibility(this.marketTag(p) === '' ? Visibility.None : Visibility.Visible)
      Text(p.content)
        .fontSize(15)
        .fontColor($r('app.color.common_color_1'))
        .width('100%')
        .margin({ top: 8 })
        .visibility(p.content === '' ? Visibility.None : Visibility.Visible)
      this.photoGrid(p)
      Row() {
        Text('评论   ' + p.commentNum)
          .fontSize(13)
          .fontColor($r('app.color.common_color_3'))
        Blank()
        Text(p.likeNum === '' || p.likeNum === '0' ? '' : '已有' + p.likeNum + '人点赞')
          .fontSize(13)
          .fontColor($r('app.color.common_color_3'))
      }
      .width('100%')
      .margin({ top: 10 })
      Text(this.likeNames)
        .fontSize(13)
        .fontColor('#507daf')
        .width('100%')
        .margin({ top: 4 })
        .visibility(this.likeNames === '' ? Visibility.None : Visibility.Visible)
    }
    .width('100%')
    .padding(15)
    .backgroundColor($r('app.color.white'))
  }

  @Builder
  photoGrid(p: SocialPost) {
    Column() {
      if (p.pictureList().length === 1) {
        Image(this.picSrc(p.pictureList()[0]))
          .width(100)
          .height(100)
          .objectFit(ImageFit.Cover)
          .borderRadius(2)
      } else if (p.pictureList().length > 1) {
        Grid() {
          ForEach(p.pictureList(), (pic: string) => {
            GridItem() {
              Image(this.picSrc(pic))
                .width('100%')
                .height('100%')
                .objectFit(ImageFit.Cover)
                .borderRadius(2)
            }
          }, (pic: string) => pic)
        }
        .columnsTemplate('1fr 1fr 1fr')
        .columnsGap(2.5)
        .rowsGap(2.5)
        .height(117.5)
        .width('100%')
      }
    }
    .width('100%')
    .visibility(p.pictureList().length > 0 ? Visibility.Visible : Visibility.None)
  }

  private picSrc(pic: string): ResourceStr {
    if (pic.startsWith('http')) {
      return pic;
    }
    return Constants.SOCKET_HOST + '/' + pic;
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
      const yesterday: boolean = ref.getFullYear() === date.getFullYear()
        && ref.getMonth() === date.getMonth() && ref.getDate() === date.getDate() + 1;
      if (yesterday) {
        return '昨天' + pad(date.getHours()) + ':' + pad(date.getMinutes());
      }
      return pad(date.getMonth() + 1) + '-' + pad(date.getDate()) + ' ' +
        pad(date.getHours()) + ':' + pad(date.getMinutes());
    } catch (error) {
      const be = error as BusinessError;
      ApiService.logError('formatTime fail: ' + be.message);
      return '';
    }
  }

  /** 源码 MarketCommentAdapter：主条 + 子回复 */
  @Builder
  commentItem(c: SocialComment) {
    Column() {
      Row() {
        Image(this.avatarSrc(c.userId))
          .width(34)
          .height(34)
          .borderRadius(17)
          .objectFit(ImageFit.Cover)
        Column() {
          Row() {
            Text(c.displayName())
              .fontSize(13)
              .fontColor($r('app.color.common_color_1'))
            Blank()
          }
          .width('100%')
          Text(c.content)
            .fontSize(14)
            .fontColor($r('app.color.common_color_1'))
            .width('100%')
            .margin({ top: 4 })
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
        .margin({ left: 10 })
      }
      .width('100%')
      .alignItems(VerticalAlign.Top)
      .onClick(() => {
        this.onCommentTap(c);
      })
      ForEach(c.subList, (sub: SocialSubComment) => {
        Column() {
          Row() {
            Blank().width(44)
            Column() {
              Text(sub.displayName() + (sub.targetNickName === '' ? '' : ' 回复 ' + sub.targetNickName))
                .fontSize(13)
                .fontColor($r('app.color.common_color_1'))
              Text(sub.content)
                .fontSize(14)
                .fontColor($r('app.color.common_color_1'))
                .width('100%')
                .margin({ top: 3 })
            }
            .alignItems(HorizontalAlign.Start)
            .layoutWeight(1)
          }
          .width('100%')
          .alignItems(VerticalAlign.Top)
        }
        .margin({ top: 8 })
        .onClick(() => {
          this.onSubTap(sub);
        })
      }, (sub: SocialSubComment) => sub.id)
    }
    .width('100%')
    .padding({ left: 15, right: 15, top: 10, bottom: 10 })
    .backgroundColor($r('app.color.white'))
    .margin({ top: 1 })
  }

  /** 源码 layoutBottom：评论 + 赞 */
  @Builder
  bottomBar(p: SocialPost) {
    Row() {
      Row() {
        Image($r('app.media.social_comment'))
          .width(18)
          .height(18)
        Text('评论')
          .fontSize(15)
          .fontColor($r('app.color.common_color_1'))
          .margin({ left: 6 })
      }
      .layoutWeight(1)
      .height(44)
      .justifyContent(FlexAlign.Center)
      .onClick(() => {
        this.openCommentInput(null);
      })
      Divider()
        .vertical(true)
        .height(20)
        .color($r('app.color.common_color_5'))
      Row() {
        Image(p.isLike === '1' ? $r('app.media.social_like') : $r('app.media.social_like_select'))
          .width(18)
          .height(18)
        Text('点赞')
          .fontSize(15)
          .fontColor($r('app.color.common_color_1'))
          .margin({ left: 6 })
      }
      .layoutWeight(1)
      .height(44)
      .justifyContent(FlexAlign.Center)
      .onClick(() => {
        this.toggleLike();
      })
    }
    .width('100%')
    .height(45)
    .backgroundColor($r('app.color.white'))
    .border({ width: { top: 0.5 }, color: $r('app.color.common_color_5') })
  }

  /** 源码 弹层：底部评论输入 */
  @Builder
  commentInputSheet() {
    Column()
      .width('100%')
      .height('100%')
      .backgroundColor('rgba(0,0,0,0.35)')
      .onClick(() => {
        this.showInput = false;
      })
    Column() {
      Text(this.replyTarget === null ? '发表评论' : '回复 ' + (this.replyTarget as SocialComment).displayName())
        .fontSize(14)
        .fontColor($r('app.color.common_color_3'))
        .width('100%')
      Row() {
        TextArea({ text: this.commentText, placeholder: '说点什么吧...' })
          .placeholderColor($r('app.color.common_color_4'))
          .fontSize(15)
          .fontColor($r('app.color.common_color_1'))
          .backgroundColor($r('app.color.common_color_6'))
          .borderRadius(6)
          .layoutWeight(1)
          .constraintSize({ minHeight: 40, maxHeight: 120 })
          .onChange((value: string) => {
            this.commentText = value;
          })
        Text('发送')
          .fontSize(15)
          .fontColor(Color.White)
          .backgroundColor($r('app.color.common_color_12'))
          .borderRadius(6)
          .padding({ left: 14, right: 14, top: 9, bottom: 9 })
          .margin({ left: 8 })
          .onClick(() => {
            this.submitComment();
          })
      }
      .width('100%')
      .alignItems(VerticalAlign.Bottom)
    }
    .width('100%')
    .padding(15)
    .backgroundColor($r('app.color.white'))
    .borderRadius({ topLeft: 8, topRight: 8 })
  }

  build() {
    Stack({ alignContent: Alignment.Bottom }) {
      Stack({ alignContent: Alignment.TopEnd }) {
        Column() {
          TitleBar({
            title: '详情',
            rightText: '更多',
            onRightClick: (): void => {
              this.showMoreMenu();
            }
          })
          if (this.pageState === 0) {
            LoadingView()
              .layoutWeight(1)
          } else if (this.pageState === 1 && this.post !== null) {
            List() {
              ListItem() {
                this.detailHead(this.post as SocialPost)
              }
              ForEach(this.comments, (c: SocialComment) => {
                ListItem() {
                  this.commentItem(c)
                }
              }, (c: SocialComment) => c.id)
              if (this.comments.length === 0) {
                ListItem() {
                Text('快来发表你的评论吧')
                    .fontSize(13)
                    .fontColor($r('app.color.common_color_4'))
                    .width('100%')
                    .textAlign(TextAlign.Center)
                    .padding(30)
                }
              }
              if (this.hasMore) {
                ListItem() {
                  Text('加载更多')
                    .fontSize(13)
                    .fontColor($r('app.color.common_color_12'))
                    .width('100%')
                    .textAlign(TextAlign.Center)
                    .padding(12)
                    .onClick(() => {
                      this.loadComments(this.pageNum + 1);
                    })
                }
              }
            }
            .width('100%')
            .layoutWeight(1)
            .backgroundColor($r('app.color.main_bg'))
          } else {
            Column({ space: 12 }) {
              Text('ⓘ')
                .fontSize(44)
                .fontColor($r('app.color.common_color_4'))
              Text(this.pageState === 3 ? '帖子已删除' : this.errMsg === '' ? '加载失败' : this.errMsg)
                .fontSize(14)
                .fontColor($r('app.color.common_color_3'))
                .textAlign(TextAlign.Center)
                .padding({ left: 30, right: 30 })
              Text('重试')
                .fontSize(14)
                .fontColor($r('app.color.common_color_12'))
                .onClick(() => {
                  this.loadDetail();
                })
            }
            .width('100%')
            .layoutWeight(1)
            .justifyContent(FlexAlign.Center)
          }
          if (this.pageState === 1 && this.post !== null) {
            this.bottomBar(this.post as SocialPost)
          }
        }
        .width('100%')
        .height('100%')
        .backgroundColor($r('app.color.main_bg'))

        if (this.pageState === 1 && this.post !== null
          && (this.post as SocialPost).userId === LoginSession.userId) {
          Column() {
            this.floatButtons(this.post as SocialPost)
          }
          .margin({ top: 60, right: 12 })
        }
      }
      .width('100%')
      .height('100%')

      if (this.showInput) {
        this.commentInputSheet()
      }
    }
    .width('100%')
    .height('100%')
  }
}
