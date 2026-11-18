import { router, promptAction } from '@kit.ArkUI';
import { pasteboard } from '@kit.BasicServicesKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { TitleBar } from '../components/TitleBar';
import { LoadingView } from '../components/LoadingView';
import { ApiService, BizJsonResult } from '../network/ApiService';
import { ApiResponse } from '../model/ResponseModel';
import { LoginSession } from '../network/LoginSession';
import { SocialPost, SocialComment, SocialLike, SocialSubComment } from '../model/SocialModels';
import { Constants } from '../data/Constants';

/**
 * 帖子详情页 — 1:1 复刻 PostDetailActivity（social_news_activity + social_post_detail_head）+ PostDetailPresenter。
 * 【通道实证 2026-11-18 probe_w20_social.py】
 *   读链 = 校内 circleOpen（hasSchoolCirclePhone=false 分支，源码 SocialModel.y0/o0/E）：
 *     getCircleInfo/getCircleComments/getCircleLikes 实测 HTTP200 code=0001 系统异常
 *     → 真实错误态（message 透传），绝不编造帖子/评论/点赞。
 *   写链 = push 域 yibaogao.com（likeOperator/sendComment/deleteComment/deleteCircle/hideCircle…）：
 *     实测 WinError 10054/SSL EOF 不可达 → 真实网络错误 toast。
 *   （浏览计数 addviewnum 源码调用方为 ReadDetailActivity，非本页 —— 详情页不发。）
 * 【路由】MyPostPage/SocialMessagePage 点条目 → {id,targetUserId,type:3}；头像/点赞人 → UserDetailPage。
 * 【本地行为保真】点赞乐观更新（源码 i/d0 同款 ±1 反转数学+图标切换）先于网络回调。
 */
@Entry
@Component
struct PostDetailPage {
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
  private targetUserId: string = '';
  private avatarMap: Map<string, string> = new Map();

  aboutToAppear(): void {
    const params: Record<string, Object> = (router.getParams() ?? {}) as Record<string, Object>;
    const pick = (k: string): string => {
      const v: Object | undefined = params[k];
      return typeof v === 'string' ? v as string : (typeof v === 'number' ? String(v as number) : '');
    };
    this.postId = pick('id');
    this.targetUserId = pick('targetUserId');
    this.loadDetail();
  }

  /** 源码 f2()/w.k|l：详情主接口 postInfo/getCircleInfo + 成功后评论/点赞/浏览计数 */
  private async loadDetail(): Promise<void> {
    if (this.postId === '') {
      this.errMsg = '缺少帖子参数';
      this.pageState = 2;
      return;
    }
    this.pageState = 0;
    const result: BizJsonResult = await ApiService.getCircleInfo(this.postId);
    if (result.code !== 0) {
      this.errMsg = result.message;
      // 源码 presenter a.f()：code=="2000" → CampusPage.POST_DELETED
      this.pageState = result.code === 2000 || result.message.indexOf('2000') >= 0
        || result.message.indexOf('删除') >= 0 ? 3 : 2;
      return;
    }
    const rows: Object[] = ApiService.extractArray(result.data);
    if (rows.length <= 0) {
      this.errMsg = '帖子不存在';
      this.pageState = 2;
      return;
    }
    this.post = SocialPost.fromRecord(rows[0] as Record<string, Object>);
    this.pageState = 1;
    this.resolveAvatars([this.post.userId]);
    this.loadComments(1);
    this.loadLikes();
  }

  /** 源码 m1()：评论分页（pageSize=10，页 size<10 停止上拉） */
  private async loadComments(page: number): Promise<void> {
    const result: BizJsonResult = await ApiService.getCircleComments(this.postId, page, 10);
    if (result.code !== 0) {
      if (page === 1) {
        this.comments = [];
      }
      ApiService.logError('circleOpen comments: ' + result.message);
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

  /** 源码 A()：点赞人名链 E3()；成功后刷新 likeNames */
  private async loadLikes(): Promise<void> {
    const result: BizJsonResult = await ApiService.getCircleLikes(this.postId);
    if (result.code !== 0) {
      return;
    }
    const list: SocialLike[] = SocialLike.listFrom(ApiService.extractArray(result.data));
    const names: string[] = [];
    for (const l of list) {
      const n: string = l.displayName();
      if (n !== '') {
        names.push(n);
      }
    }
    // 源码 E3() 分隔符 ad.t = " , "
    this.likeNames = names.join(' , ');
    const ids: string[] = [];
    for (const l of list) {
      ids.push(l.userId);
    }
    this.resolveAvatars(ids);
  }

  /** 源码 base.b.a.f：头像批量补链 getAvatarByUser（校内，实测 code=0 [{TX,USERID}]，无头像 TX=null） */
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

  /** 源码 e.h(publishTime, serversTime)：相对时间 */
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

  /** 源码 i()：点赞乐观更新（±1 反转数学保真）+ likeOperator push（不可达→真实错误 toast） */
  private toggleLike(): void {
    if (this.post === null) {
      return;
    }
    const num: number = Number(this.post.likeNum === '' ? '0' : this.post.likeNum);
    const p: SocialPost = this.post;
    if (p.isLike === '1') {
      p.likeNum = String(num + 1);
      p.isLike = '0';
    } else {
      p.likeNum = String(num - 1);
      p.isLike = '1';
    }
    this.post = p;
    ApiService.pushLikeOperator(this.postId, p.isLike === '1' ? '1' : '0')
      .then((response: ApiResponse<Object>) => {
        if (response.code === 0 && (response.data as string) === 'true') {
          this.loadLikes();
        } else if (response.code !== 0) {
          promptAction.showToast({ message: response.message });
        }
      })
      .catch((error: BusinessError) => promptAction.showToast({ message: error.message }));
  }

  /** 源码 D3()/J3()：评论弹层（回复带 commentId/target 三元组） */
  private openCommentInput(reply: SocialComment | null): void {
    this.replyTarget = reply;
    this.commentText = '';
    this.showInput = true;
  }

  /** 源码 U2 弹层发送 → w0 sendComment（push 域，不可达→真实错误） */
  private submitComment(): void {
    const content: string = this.commentText.trim();
    if (content === '' || this.post === null) {
      promptAction.showToast({ message: '评论内容不能为空' });
      return;
    }
    const target: SocialComment | null = this.replyTarget;
    const p: SocialPost = this.post;
    ApiService.pushSendComment(content, p.id, target === null ? '' : target.userId,
      target === null ? '' : target.userType, target === null ? '' : target.userSchool,
      target === null ? '' : target.id)
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

  /** 源码 K3/n()：删除评论确认（同时删除子回复） */
  private confirmDeleteComment(comment: SocialComment): void {
    AlertDialog.show({
      message: '将此条评论删除，将同时删除评论下的所有回复。',
      title: '删除评论',
      primaryButton: {
        value: '取消', action: (): void => {
        }
      },
      secondaryButton: {
        value: '删除', action: (): void => {
          ApiService.pushDeleteComment(this.postId, comment.id)
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

  /** 源码 k()：评论条目点击 —— 本人删/他人回复（管理员分支 HAP 会话无 isAdmin 字段按 false） */
  private onCommentTap(comment: SocialComment): void {
    if (comment.userId === LoginSession.userId) {
      this.confirmDeleteComment(comment);
    } else {
      this.openCommentInput(comment);
    }
  }

  /** 源码 b0$a：更多菜单（复制/举报/删除[本人]；屏蔽/分类为管理员项，HAP 无 isAdmin → 隐藏）
   *  [W21 协作修复] showActionMenu.buttons 为定长元组类型 → 按分支内联字面量元组（语义不变） */
  private showMoreMenu(): void {
    if (this.post === null) {
      return;
    }
    if (this.post.userId === LoginSession.userId) {
      promptAction.showActionMenu({ title: '更多', buttons: [
        { text: '复制', color: '#333333' },
        { text: '举报', color: '#333333' },
        { text: '删除', color: '#333333' }
      ] })
        .then((result: promptAction.ActionMenuSuccessResponse) => {
          this.onMoreAction(result.index, 3);
        })
        .catch((error: BusinessError) => ApiService.logError('actionMenu: ' + error.message));
    } else {
      promptAction.showActionMenu({ title: '更多', buttons: [
        { text: '复制', color: '#333333' },
        { text: '举报', color: '#333333' }
      ] })
        .then((result: promptAction.ActionMenuSuccessResponse) => {
          this.onMoreAction(result.index, 2);
        })
        .catch((error: BusinessError) => ApiService.logError('actionMenu: ' + error.message));
    }
  }

  /** 源码 菜单回调：复制/举报→SocialReportPage/删除→deleteCircle 确认 */
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
      router.pushUrl({ url: 'pages/SocialReportPage', params: { 'id': this.postId } });
      return;
    }
    this.confirmDeleteCircle();
  }

  /** 源码 e()/U()：删除帖子确认 → deleteCircle（push 域）→ 成功返回 m="1" finish */
  private confirmDeleteCircle(): void {
    AlertDialog.show({
      message: '是否删除帖子',
      primaryButton: {
        value: '取消', action: (): void => {
        }
      },
      secondaryButton: {
        value: '删除', action: (): void => {
          ApiService.pushDeleteCircle(this.postId)
            .then((response: ApiResponse<Object>) => {
              if (response.code === 0) {
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

  /** 源码 H3()：九宫格（1 图 100vp，多图 37.5vp 三列 2.5vp 缝），点击看图（isOldData 原图链） */
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

  /** 源码 G3() 头部：头像40 + 昵称/单位/时间 + 内容 + 九宫格 + 评论数/点赞行 + 点赞人名链 */
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
            router.pushUrl({
              url: 'pages/UserDetailPage',
              params: { 'targetId': p.userId, 'targetUserType': p.userType, 'targetSchoolId': p.userSchool }
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

  /** 源码 CommentAdapter：主条 + 子回复缩进列表 */
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
            Text(this.formatTime(c.commentTime, c.serversTime === '' ? c.commentTime : c.serversTime))
              .fontSize(12)
              .fontColor($r('app.color.common_color_3'))
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
          this.onSubTap(c, sub);
        })
      }, (sub: SocialSubComment) => sub.id)
    }
    .width('100%')
    .padding({ left: 15, right: 15, top: 10, bottom: 10 })
    .backgroundColor($r('app.color.white'))
    .margin({ top: 1 })
  }

  /** 源码 子回复点击 → 回复该子条 */
  private onSubTap(main: SocialComment, sub: SocialSubComment): void {
    const reply: SocialComment = new SocialComment();
    reply.id = sub.id;
    reply.userId = sub.userId;
    reply.userType = sub.userType;
    reply.userSchool = sub.userSchool;
    reply.nickName = sub.nickName;
    void main;
    this.openCommentInput(reply);
  }

  /** 源码 social_fragment_post_item_tv_commient/tv_like 底栏 */
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

  /** 源码 弹层：底部评论输入（回复态标题显示 回复@xx） */
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
            ListItem() {
              Column() {
                Text('全部评论')
                  .fontSize(13)
                  .fontColor($r('app.color.common_color_3'))
                  .width('100%')
                  .padding({ left: 15, top: 10, bottom: 6 })
              }
              .width('100%')
              .backgroundColor($r('app.color.main_bg'))
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

      if (this.showInput) {
        this.commentInputSheet()
      }
    }
    .width('100%')
    .height('100%')
  }
}
