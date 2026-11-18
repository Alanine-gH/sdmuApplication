import { router, promptAction } from '@kit.ArkUI';
import { pasteboard, BusinessError } from '@kit.BasicServicesKit';
import { TitleBar } from '../components/TitleBar';
import { LoadingView } from '../components/LoadingView';
import { EmptyView } from '../components/EmptyView';
import { ApiService, BizJsonResult } from '../network/ApiService';
import { ApiResponse } from '../model/ResponseModel';
import { LoginSession } from '../network/LoginSession';
import { SocialPost } from '../model/SocialModels';
import { Constants } from '../data/Constants';

/**
 * 集市列表页 — 源码级翻译（MarketActivity + MarketItemAdapter + MarketPImpl，[W28 final-b]）。
 * 【布局】activity_market = toolbar_normal("集市") + header_market(100dip：搜索行 44dip
 *   {EditText 32dip 圆角8 #f2f2f2 描边1px #dadbdf hint"输入你想搜索的内容..." 14sp #b5b5b5 + search 图标
 *   drawablePadding 9 + 右"搜索" 50dip #1b68b6} + 12dip #f2f2f2 + MSelectTab×4
 *   {全部 icon_all #1b68b6 / 想买 icon_buy1 #18b4ed / 想卖 icon_sale1 #eb5d2a / 已成交 icon_closed1 #5ec78f，
 *   12sp+icon 8dip+底部 23×2dip 圆角指示条 mt5，padding 10} + 1dip #f5f5f5)
 *   + common_refresh_lv_rl（MultiStateView+ListView）+ 右下 market_post 浮动按钮（margin 15）。
 * 【数据链】hasSchoolCirclePhone 分支（GlobalParamInfo.getPhoneStatus()）：
 *   false：ALL+空关键词 → GET circleOpen/getMarketList {lastId}；筛选/搜索 → POST circleOpen/serchMarketList
 *          {lastId,marketType,marketStatus,keyWord}（MarketModel.h1/Y0，e.b/e.d）。
 *   true ：ALL+空关键词 → GET market/freshNewList {lastId}；筛选/搜索 → GET market/serchFreshNewList
 *          {lastId,marketType,marketStatus,keyWord}（MarketModel.g1/X0 @push 域）。
 *   分页 lastId=上页末条 id（空→"-1"）；下拉 i() 重置；上拉 h.b() 追加。
 * 【行】market_activity_item = social_post_item + 4dip 间隔 + 评论/点赞行（15sp common_color_3，
 *   drawablePadding 7；分享 gone；more 30dip）+ 双层分隔线。
 *   social_post_item：avatar 40 + 徽标 logo_techer(用户类型2)/logo_organization(3) + 昵称16sp +
 *   头条 market_top(13sp 白字 #18b4ed 圆角2，marketTop>0)/market_tag(已成交 colorOver#5ec78f+
 *   icon_closed2、想卖 colorSale#eb5d2a+icon_sale2、想买 colorBuy#18b4ed+icon_buy2)/置顶(freshTop!=0，
 *   icon_top) + unit 12sp + 时间 12sp（源码 setVisibility(8) 恒隐藏保真）+ 内容15sp maxLines4
 *   （超4行"查看全部"/"收起"）+ 九宫格图（单图 100×100，多图按 3 列 37.5 间距2.5）。
 * 【操作】更多菜单 = 复制/举报/[删除 本人]/[屏蔽·分类 管理员(会话无 isAdmin 隐藏)]/
 *   [参与竞价·已成交·重新上架 本人 type=="2" 集市帖]；复制→粘贴板"已复制"；举报→SocialReportPage；
 *   删除/已成交/重新上架 → push 域真实调用（实测 yibaogao.com 不可达 → 真实错误 toast）。
 * 【点击】头像→UserDetailPage{targetId,targetSchoolId,targetUserType}；行→MarkDetailPage{id,targetUserId,type:2}；
 *   评论图标→MarkDetailPage is_commetn=true；点赞→likeOperator 乐观更新（±1 反转数学）。
 * 【探针】temp/probe_w28_final_b.py 锚点 [W28 final-b]。
 */
@Entry
@Component
struct MarketPage {
  @State tab: number = 0;
  @State keyword: string = '';
  @State list: SocialPost[] = [];
  @State pageState: string = 'loading';
  @State errMsg: string = '';
  @State hasMore: boolean = false;
  @State avatarVersion: number = 0;
  @State contentExpanded: boolean = false;
  private lastId: string = '-1';
  private hasSchoolCirclePhone: boolean = false;
  private channelReady: boolean = false;
  private firstShow: boolean = true;
  private avatarMap: Map<string, string> = new Map();

  aboutToAppear(): void {
    this.resolveChannel();
  }

  onPageShow(): void {
    // 源码 f2() onResume：重置 ALL + 重拉（首次进入由 resolveChannel 触发，避免重复）
    if (this.firstShow) {
      this.firstShow = false;
      return;
    }
    this.tab = 0;
    this.loadList(true);
  }

  /** 源码 GlobalParamInfo.PhoneStatus.hasSchoolCirclePhone：查询失败按 false（校内 circleOpen 分支） */
  private resolveChannel(): void {
    ApiService.queryBindPhoneStatus()
      .then((response: ApiResponse<Object>) => {
        if (response.code === 0) {
          const rec: Record<string, Object> = ApiService.asRecord(response.data);
          this.hasSchoolCirclePhone = ApiService.pick(rec, ['hasSchoolCirclePhone']) === '1' ||
            ApiService.pick(rec, ['hasSchoolCirclePhone']) === 'true';
        }
        this.channelReady = true;
        this.loadList(true);
      })
      .catch((error: BusinessError) => {
        ApiService.logError('market phoneStatus fail: ' + error.message);
        this.channelReady = true;
        this.loadList(true);
      });
  }

  /** 源码 m3()：切换页签重置 lastId=-1 并重拉 */
  private switchTab(index: number): void {
    this.tab = index;
    this.loadList(true);
  }

  /** 源码 i() 搜索：trim 后以当前 tab 重拉 */
  private search(): void {
    this.loadList(true);
  }

  /** marketType：ALL 空 / BUY "1" / SELL "0" / DEAL 空；marketStatus：DEAL "1" 否则空 */
  private marketTypeOf(): string {
    if (this.tab === 1) {
      return '1';
    }
    if (this.tab === 2) {
      return '0';
    }
    return '';
  }

  private marketStatusOf(): string {
    return this.tab === 3 ? '1' : '';
  }

  /** 源码 m3()/h.b()：加载列表（reset=true 覆盖，false 追加） */
  private loadList(reset: boolean): void {
    if (!this.channelReady) {
      return;
    }
    const lastId: string = reset ? '-1' : this.lastId;
    if (reset) {
      this.pageState = 'loading';
      this.lastId = '-1';
    }
    const keyWord: string = this.keyword.trim();
    const type: string = this.marketTypeOf();
    const status: string = this.marketStatusOf();
    const isPlainList: boolean = keyWord === '' && this.tab === 0;
    let task: Promise<BizJsonResult>;
    if (this.hasSchoolCirclePhone) {
      task = isPlainList ? ApiService.pushGetMarketFreshList(lastId)
        : ApiService.pushSearchMarketFreshList(lastId, type, status, keyWord);
    } else {
      task = isPlainList ? ApiService.getMarketList(lastId)
        : ApiService.searchMarketList(lastId, type, status, keyWord);
    }
    task.then((result: BizJsonResult) => {
      if (result.code !== 0) {
        if (reset) {
          this.list = [];
          this.errMsg = result.message;
          this.pageState = 'error';
        } else {
          this.hasMore = false;
        }
        return;
      }
      const rows: SocialPost[] = SocialPost.listFrom(ApiService.extractArray(result.data));
      if (reset) {
        this.list = rows;
      } else {
        this.list = this.list.concat(rows);
      }
      if (rows.length > 0) {
        this.lastId = rows[rows.length - 1].id;
      }
      this.hasMore = rows.length > 0;
      this.pageState = this.list.length > 0 ? 'content' : 'empty';
      this.resolveAvatars(rows);
    }).catch((error: BusinessError) => {
      ApiService.logError('market list fail: ' + error.message);
      if (reset) {
        this.list = [];
        this.errMsg = '网络请求失败';
        this.pageState = 'error';
      }
    });
  }

  /** 源码 base.b.a.f：头像批量补链 */
  private resolveAvatars(rows: SocialPost[]): void {
    const need: string[] = [];
    for (const row of rows) {
      if (row.userId !== '' && !this.avatarMap.has(row.userId)) {
        need.push(row.userId);
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
        for (const one of ApiService.extractArray(response.data)) {
          const rec: Record<string, Object> = ApiService.asRecord(one);
          const uid: string = ApiService.pick(rec, ['USERID']);
          if (uid !== '') {
            this.avatarMap.set(uid, ApiService.pick(rec, ['TX']));
          }
        }
        this.avatarVersion++;
      })
      .catch((error: BusinessError) => ApiService.logError('market avatar fail: ' + error.message));
  }

  private avatarSrc(post: SocialPost): ResourceStr {
    if (post.avatar !== '') {
      return post.avatar.startsWith('http') ? post.avatar : Constants.SOCKET_HOST + '/' + post.avatar;
    }
    const cached: string | undefined = this.avatarMap.get(post.userId);
    if (cached !== undefined && cached !== '') {
      return cached.startsWith('http') ? cached : Constants.SOCKET_HOST + '/' + cached;
    }
    return $r('app.media.default_circle');
  }

  private picSrc(pic: string): ResourceStr {
    return pic.startsWith('http') ? pic : Constants.SOCKET_HOST + '/' + pic;
  }

  /** 源码 e.h(publishTime, serversTime) 相对时间 */
  private formatTime(post: SocialPost): string {
    if (post.publishTime === '') {
      return '';
    }
    try {
      const ref: Date = post.serversTime === '' ? new Date() : new Date(post.serversTime.replace(/-/g, '/'));
      const date: Date = new Date(post.publishTime.replace(/-/g, '/'));
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
      const sameDay: boolean = ref.getFullYear() === date.getFullYear() &&
        ref.getMonth() === date.getMonth() && ref.getDate() === date.getDate();
      if (sameDay) {
        return pad(date.getHours()) + ':' + pad(date.getMinutes());
      }
      return pad(date.getMonth() + 1) + '-' + pad(date.getDate()) + ' ' +
        pad(date.getHours()) + ':' + pad(date.getMinutes());
    } catch (error) {
      const be = error as BusinessError;
      ApiService.logError('market time fail: ' + be.message);
      return '';
    }
  }

  /** 源码 MarketItemAdapter.setMarketTag：已成交/想卖/想买（颜色+图标） */
  private marketTagOf(post: SocialPost): string {
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

  private marketTagColor(post: SocialPost): string {
    if (post.marketStatus !== '0') {
      return '#5EC78F';
    }
    if (post.marketType === '0') {
      return '#EB5D2A';
    }
    if (post.marketType === '1') {
      return '#18B4ED';
    }
    return '#00000000';
  }

  private marketTagIcon(post: SocialPost): Resource | null {
    if (post.marketStatus !== '0') {
      return $r('app.media.icon_closed2');
    }
    if (post.marketType === '0') {
      return $r('app.media.icon_sale2');
    }
    if (post.marketType === '1') {
      return $r('app.media.icon_buy2');
    }
    return null;
  }

  /** 源码 e 类：点赞乐观更新（isLike=="1"→取消：likeNum+1；否则点赞：likeNum-1） */
  private toggleLike(post: SocialPost): void {
    const num: number = Number(post.likeNum === '' ? '0' : post.likeNum);
    if (post.isLike === '1') {
      post.likeNum = String(num + 1);
      post.isLike = '0';
    } else {
      post.likeNum = String(num > 0 ? num - 1 : 0);
      post.isLike = '1';
    }
    const copied: SocialPost[] = this.list.slice();
    this.list = copied;
    ApiService.pushMarketLikeOperator(post.id, post.isLike === '1' ? '1' : '0')
      .then((response: ApiResponse<Object>) => {
        if (response.code !== 0) {
          promptAction.showToast({ message: response.message });
        }
      })
      .catch((error: BusinessError) => promptAction.showToast({ message: error.message }));
  }

  /** 源码 j3：行点击 → MarkDetailActivity{id,targetUserId,is_commetn,type:2} */
  private openDetail(post: SocialPost, commentMode: boolean): void {
    router.pushUrl({
      url: 'pages/MarkDetailPage',
      params: {
        'id': post.id, 'targetUserId': post.userId, 'type': 2, 'is_commetn': commentMode
      } as Record<string, Object>
    });
  }

  private openUser(post: SocialPost): void {
    router.pushUrl({
      url: 'pages/UserDetailPage',
      params: {
        'targetId': post.userId,
        'targetSchoolId': LoginSession.schoolId,
        'targetUserType': post.userType
      } as Record<string, Object>
    });
  }

  /** 源码 MarketItemAdapter.f$a：更多菜单操作列表构造（管理员项 HAP 无 isAdmin 隐藏） */
  private opsOf(post: SocialPost): string[] {
    const ops: string[] = ['复制', '举报'];
    if (post.userId === LoginSession.userId) {
      ops.push('删除');
    }
    if (post.userId === LoginSession.userId && post.type === '2') {
      if (post.marketStatus === '0') {
        if (post.marketTop !== '' && post.marketTop === '0') {
          ops.push('参与竞价');
        }
        ops.push('已成交');
      } else {
        ops.push('重新上架');
      }
    }
    return ops;
  }

  /** 动态按钮元组按分支内联（ArkTS showActionMenu 定长元组限制） */
  private showMoreMenu(post: SocialPost): void {
    const ops: string[] = this.opsOf(post);
    if (ops.length === 2) {
      promptAction.showActionMenu({ title: '更多', buttons: [
        { text: '复制', color: '#333333' }, { text: '举报', color: '#333333' }
      ] }).then((r: promptAction.ActionMenuSuccessResponse) => this.onMoreAction(post, r.index))
        .catch((e: BusinessError) => ApiService.logError('market menu: ' + e.message));
    } else if (ops.length === 3) {
      const third: string = ops[2];
      promptAction.showActionMenu({ title: '更多', buttons: [
        { text: '复制', color: '#333333' }, { text: '举报', color: '#333333' },
        { text: third, color: '#333333' }
      ] }).then((r: promptAction.ActionMenuSuccessResponse) => this.onMoreAction(post, r.index))
        .catch((e: BusinessError) => ApiService.logError('market menu: ' + e.message));
    } else if (ops.length === 4) {
      promptAction.showActionMenu({ title: '更多', buttons: [
        { text: '复制', color: '#333333' }, { text: '举报', color: '#333333' },
        { text: ops[2], color: '#333333' }, { text: ops[3], color: '#333333' }
      ] }).then((r: promptAction.ActionMenuSuccessResponse) => this.onMoreAction(post, r.index))
        .catch((e: BusinessError) => ApiService.logError('market menu: ' + e.message));
    } else {
      promptAction.showActionMenu({ title: '更多', buttons: [
        { text: '复制', color: '#333333' }, { text: '举报', color: '#333333' },
        { text: ops[2], color: '#333333' }, { text: ops[3], color: '#333333' },
        { text: ops[4], color: '#333333' }
      ] }).then((r: promptAction.ActionMenuSuccessResponse) => this.onMoreAction(post, r.index))
        .catch((e: BusinessError) => ApiService.logError('market menu: ' + e.message));
    }
  }

  /** 菜单分发：index 对应 opsOf 顺序 */
  private onMoreAction(post: SocialPost, index: number): void {
    const ops: string[] = this.opsOf(post);
    if (index < 0 || index >= ops.length) {
      return;
    }
    const op: string = ops[index];
    if (op === '复制') {
      const data: pasteboard.PasteData =
        pasteboard.createData(pasteboard.MIMETYPE_TEXT_PLAIN, post.content);
      pasteboard.getSystemPasteboard().setData(data)
        .then((): void => promptAction.showToast({ message: '已复制' }))
        .catch((e: BusinessError) => ApiService.logError('market copy: ' + e.message));
    } else if (op === '举报') {
      router.pushUrl({ url: 'pages/SocialReportPage', params: { 'id': post.id, 'fromMarket': true } });
    } else if (op === '删除') {
      this.confirmAction('是否删除帖子', (): Promise<ApiResponse<Object>> => ApiService.pushMarketDeleteCircle(post.id), post, 'delete');
    } else if (op === '已成交') {
      this.confirmAction('是否设置状态为已成交', (): Promise<ApiResponse<Object>> => ApiService.pushMarketTurnover(post.id), post, 'sold');
    } else if (op === '重新上架') {
      this.confirmAction('是否设置状态为重新上架', (): Promise<ApiResponse<Object>> => ApiService.pushMarketReGrounding(post.id), post, 'reopen');
    } else if (op === '参与竞价') {
      this.bidMarket(post);
    }
  }

  /** push 域写操作确认框（真实调用；成功按源码 S() 更新/移除行） */
  private confirmAction(title: string, call: () => Promise<ApiResponse<Object>>,
    post: SocialPost, mode: string): void {
    AlertDialog.show({
      message: title,
      primaryButton: { value: '取消', action: (): void => { } },
      secondaryButton: {
        value: '确定',
        action: (): void => {
          call().then((response: ApiResponse<Object>) => {
            if (response.code !== 0) {
              promptAction.showToast({ message: response.message });
              return;
            }
            if (mode === 'delete') {
              this.list = this.list.filter((it: SocialPost): boolean => it.id !== post.id);
            } else if (mode === 'sold') {
              post.marketStatus = '1';
              this.refreshRows();
            } else if (mode === 'reopen') {
              post.marketStatus = '0';
              this.refreshRows();
            }
          }).catch((error: BusinessError) => promptAction.showToast({ message: error.message }));
        }
      }
    });
  }

  private refreshRows(): void {
    this.list = this.list.slice();
  }

  /** 源码 i1 → TopDialog 前置：getUserScores；existTop=1 保护期提示 */
  private bidMarket(post: SocialPost): void {
    ApiService.pushGetUserScores()
      .then((response: ApiResponse<Object>) => {
        if (response.code !== 0) {
          promptAction.showToast({ message: response.message });
          return;
        }
        const rec: Record<string, Object> = ApiService.asRecord(response.data);
        if (ApiService.pick(rec, ['existTop']) === '1') {
          AlertDialog.show({ message: '当前小伙伴的头条贴正处于半小时保护期，半小时内我们将会对所有参与竞价的帖子进行筛选并通知您' });
        } else {
          promptAction.showToast({ message: '参与竞价：' + post.id });
        }
      })
      .catch((error: BusinessError) => promptAction.showToast({ message: error.message }));
  }

  @Builder
  marketTabItem(label: string, icon: Resource, color: string, index: number) {
    Column() {
      Row() {
        Image(icon).width(12).height(12).margin({ right: 4 })
        Text(label).fontSize(12).fontColor(color)
      }
      .alignItems(VerticalAlign.Center)
      Column()
        .width(11.5)
        .height(1)
        .borderRadius(1)
        .backgroundColor(color)
        .margin({ top: 2.5 })
        .visibility(this.tab === index ? Visibility.Visible : Visibility.Hidden)
    }
    .layoutWeight(1)
    .padding({ top: 5, bottom: 5 })
    .alignItems(HorizontalAlign.Center)
    .onClick(() => {
      this.switchTab(index);
    })
  }

  /** header_market：搜索行 44 + 12 灰条 + 四页签 + 1 分隔 */
  @Builder
  headerMarket() {
    Column() {
      Row() {
        Row() {
          Image($r('app.media.search'))
            .width(14)
            .height(14)
            .margin({ left: 8, right: 4.5 })
          TextInput({ text: this.keyword, placeholder: '输入你想搜索的内容...' })
            .placeholderColor('#B5B5B5')
            .fontSize(14)
            .fontColor($r('app.color.common_color_1'))
            .backgroundColor(Color.Transparent)
            .layoutWeight(1)
            .height(32)
            .padding(0)
            .onChange((value: string) => {
              this.keyword = value;
            })
            .onSubmit(() => {
              this.search();
            })
        }
        .layoutWeight(1)
        .height(32)
        .backgroundColor('#F2F2F2')
        .borderRadius(8)
        .border({ width: 0.5, color: '#DADBDF' })
        .margin({ left: 15 })

        Text('搜索')
          .fontSize(16)
          .fontColor('#1B68B6')
          .width(25)
          .height(25)
          .textAlign(TextAlign.Center)
          .margin({ left: 4, right: 5 })
          .onClick(() => {
            this.search();
          })
      }
      .width('100%')
      .height(44)
      .alignItems(VerticalAlign.Center)

      Row().width('100%').height(6).backgroundColor('#F2F2F2')

      Row() {
        this.marketTabItem('全部', $r('app.media.icon_all'), '#1B68B6', 0)
        this.marketTabItem('想买', $r('app.media.icon_buy1'), '#18B4ED', 1)
        this.marketTabItem('想卖', $r('app.media.icon_sale1'), '#EB5D2A', 2)
        this.marketTabItem('已成交', $r('app.media.icon_closed1'), '#5EC78F', 3)
      }
      .width('100%')
      .height(32)

      Divider().color('#F5F5F5').strokeWidth(0.5)
    }
    .width('100%')
    .height(100)
    .backgroundColor(Color.White)
  }

  @Builder
  avatarBlock(post: SocialPost) {
    Stack({ alignContent: Alignment.BottomEnd }) {
      Image(this.avatarSrc(post))
        .width(40)
        .height(40)
        .borderRadius(20)
        .objectFit(ImageFit.Cover)
        .onClick(() => {
          this.openUser(post);
        })
      if (post.userType === '2') {
        Image($r('app.media.logo_techer')).width(14).height(14)
      } else if (post.userType === '3') {
        Image($r('app.media.logo_organization')).width(14).height(14)
      }
    }
    .width(40)
    .height(40)
  }

  @Builder
  tagRow(post: SocialPost) {
    Row() {
      if (post.marketTop !== '' && Number(post.marketTop) > 0) {
        Text('头条')
          .fontSize(13)
          .fontColor(Color.White)
          .backgroundColor('#18B4ED')
          .borderRadius(2)
          .padding({ left: 5, right: 5, top: 1, bottom: 1 })
          .margin({ left: 10 })
      }
      if (this.marketTagOf(post) !== '') {
        Row() {
          if (this.marketTagIcon(post) !== null) {
            Image(this.marketTagIcon(post) as Resource).width(12).height(12).margin({ right: 3 })
          }
          Text(this.marketTagOf(post))
            .fontSize(13)
            .fontColor(this.marketTagColor(post))
        }
        .margin({ left: 10 })
      }
      if (post.freshTop !== '0' && post.freshTop !== '') {
        Row() {
          Image($r('app.media.icon_top')).width(12).height(12).margin({ right: 3 })
          Text('置顶').fontSize(13).fontColor('#1B68B6')
        }
        .margin({ left: 10 })
      }
    }
    .alignItems(VerticalAlign.Center)
  }

  /** social_post_item 头部 + 正文 */
  @Builder
  postHead(post: SocialPost) {
    Column() {
      Row() {
        this.avatarBlock(post)
        Column() {
          Row() {
            Text(post.displayName())
              .fontSize(16)
              .fontColor($r('app.color.common_color_1'))
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
              .layoutWeight(1)
            this.tagRow(post)
          }
          .width('100%')
          .alignItems(VerticalAlign.Center)

          Row() {
            Text(post.unit)
              .fontSize(12)
              .fontColor($r('app.color.common_color_3'))
              .layoutWeight(1)
              .maxLines(1)
            Text(this.formatTime(post))
              .fontSize(12)
              .fontColor($r('app.color.common_color_3'))
              .visibility(Visibility.Hidden)
          }
          .width('100%')
          .margin({ top: 2 })
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)
        .margin({ left: 5 })
      }
      .width('100%')
      .alignItems(VerticalAlign.Top)

      Text(post.content)
        .fontSize(15)
        .fontColor($r('app.color.common_color_1'))
        .width('100%')
        .padding({ top: 5, bottom: 4 })
        .maxLines(4)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .visibility(post.content === '' ? Visibility.None : Visibility.Visible)

      this.photoGrid(post)
    }
    .width('100%')
    .padding({ left: 15, right: 15, top: 10, bottom: 7 })
  }

  @Builder
  photoGrid(post: SocialPost) {
    Column() {
      if (post.pictureList().length === 1) {
        Image(this.picSrc(post.pictureList()[0]))
          .width(100)
          .height(100)
          .objectFit(ImageFit.Cover)
          .borderRadius(2)
      } else if (post.pictureList().length > 1) {
        Grid() {
          ForEach(post.pictureList(), (pic: string) => {
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
        .height(115)
        .width('100%')
      }
    }
    .width('100%')
    .padding({ top: 4 })
    .visibility(post.pictureList().length > 0 ? Visibility.Visible : Visibility.None)
  }

  /** 评论/点赞行（market_activity_item 底部 RelativeLayout） */
  @Builder
  postBottomBar(post: SocialPost) {
    Column() {
      Row() {
        Row() {
          Image($r('app.media.social_comment')).width(15).height(15).margin({ right: 7 })
          Text(post.commentNum === '0' || post.commentNum === '' ? '评论' : post.commentNum)
            .fontSize(15)
            .fontColor($r('app.color.common_color_3'))
        }
        .padding({ top: 10, bottom: 10, right: 40 })
        .onClick(() => {
          this.openDetail(post, true);
        })
        Row() {
          Image(post.isLike === '1' ? $r('app.media.social_like') : $r('app.media.social_like_select'))
            .width(15)
            .height(15)
            .margin({ right: 7 })
          Text(post.likeNum === '0' || post.likeNum === '' ? '点赞' : post.likeNum)
            .fontSize(15)
            .fontColor($r('app.color.common_color_3'))
        }
        .padding({ top: 10, bottom: 10, right: 40 })
        .onClick(() => {
          this.toggleLike(post);
        })
        Blank()
        Image($r('app.media.social_more'))
          .width(15)
          .height(15)
          .objectFit(ImageFit.Contain)
          .onClick(() => {
            this.showMoreMenu(post);
          })
      }
      .width('100%')
      .padding({ left: 15, right: 15 })
      .alignItems(VerticalAlign.Center)
      .backgroundColor($r('app.color.main_bg'))
    }
    .width('100%')
    .border({ width: { bottom: 0.5 }, color: $r('app.color.common_color_5') })
  }

  @Builder
  marketItem(post: SocialPost) {
    Column() {
      this.postHead(post)
      Row().width('100%').height(2).backgroundColor($r('app.color.main_bg'))
      Divider().color($r('app.color.common_color_5')).strokeWidth(0.5)
      this.postBottomBar(post)
    }
    .width('100%')
    .backgroundColor($r('app.color.main_bg'))
    .onClick(() => {
      this.openDetail(post, false);
    })
  }

  @Builder
  listState() {
    if (this.pageState === 'loading') {
      Column() {
        LoadingView()
      }
      .width('100%')
      .layoutWeight(1)
    } else if (this.pageState === 'error') {
      Column() {
        EmptyView({ tipText: this.errMsg === '' ? '加载失败' : this.errMsg })
        Text('重试')
          .fontSize(14)
          .fontColor($r('app.color.common_color_12'))
          .onClick(() => {
            this.loadList(true);
          })
      }
      .width('100%')
      .layoutWeight(1)
      .justifyContent(FlexAlign.Center)
    } else if (this.pageState === 'empty') {
      Column() {
        EmptyView({ tipText: '暂无帖子' })
      }
      .width('100%')
      .layoutWeight(1)
    } else {
      List() {
        ForEach(this.list, (post: SocialPost) => {
          ListItem() {
            this.marketItem(post)
          }
        }, (post: SocialPost) => post.id)
        if (this.hasMore) {
          ListItem() {
            Text('加载更多')
              .fontSize(13)
              .fontColor($r('app.color.common_color_12'))
              .width('100%')
              .textAlign(TextAlign.Center)
              .padding(12)
              .onClick(() => {
                this.loadList(false);
              })
          }
        }
      }
      .width('100%')
      .layoutWeight(1)
      .divider({ strokeWidth: 0.5, color: '#F2F2F2' })
      .onReachEnd(() => {
        if (this.hasMore && this.pageState === 'content') {
          this.loadList(false);
        }
      })
      .backgroundColor($r('app.color.main_bg'))
    }
  }

  build() {
    Stack({ alignContent: Alignment.BottomEnd }) {
      Column() {
        TitleBar({ title: '集市', showBack: true })
        this.headerMarket()
        this.listState()
      }
      .width('100%')
      .height('100%')
      .backgroundColor($r('app.color.main_bg'))

      Image($r('app.media.market_post'))
        .width(50)
        .height(50)
        .margin({ right: 15, bottom: 15 })
        .onClick(() => {
          router.pushUrl({ url: 'pages/MarketPostPage' });
        })
    }
    .width('100%')
    .height('100%')
  }
}
