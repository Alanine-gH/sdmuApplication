import { router } from '@kit.ArkUI';
import { ApiService } from '../network/ApiService';
import { ApiResponse } from '../model/ResponseModel';
import { MainNotificationV2, MessageExtAppBean, MessageSystemSwitch } from '../model/MessageModel';
import { BusinessError } from '@kit.BasicServicesKit';
import { LoadingView } from '../components/LoadingView';
import { EmptyView } from '../components/EmptyView';
import { BreakpointSystem } from '../common/BreakpointSystem';
import { AdaptiveLayoutHelper, SplitPaneConfig } from '../common/AdaptiveLayoutHelper';

/**
 * 消息列表页 — 1:1 翻译原 APK MessageListActivity.java(494行) + MessageFragment.java(426行)
 * + MessageAdapter + MessagePopupDialog + RefreshFragment（分页基类）：
 *
 * 【页面结构】mobile_campus_activity_message_list2.xml：
 *   LinearLayout vertical 白底（mRootView）
 *   - MToolBar（m_toolbar.xml）：FrameLayout 45vp（tvTitle 17fp 居中 mL/mR105、ivLeftIcon 35w mL5
 *     返回、tvRightText 16fp #333 pr15 maxLength4、ivRightIcon 40w mR5 编辑）+ vLine 0.5 #E7E7E7
 *   - MagicIndicator 40vp（mTabLayout）：ColorTransitionPagerTitleView 14fp（未选 explainColor
 *     #999999 / 选中 #1B68B7，点击切页）+ LinePagerIndicator #1B68B7 32×3 r2 + title 间隔
 *     simple_splitter 1×0.5 #E7E7E7 dividerPadding 8 + 容器 paddingBottom 4
 *   - ViewPager2（mViewPager，weight1 bg #fff2f2f2）→ 每 tab 一个 MessageFragment
 *   - tvDelete 底栏：16fp read_dot_bg(#FF0000) 居中 paddingT/B15 默认 gone，"删除（0）"
 *
 * 【tab 结构】Q2()：SystemSwitch.messages_page_tabs=="2" → [未读消息(type1), 已读消息(type2)]；
 *   否则（含 systemSwitch==null）→ [全部消息(type3)] 且 mTabLayout 隐藏。
 * 【数据流】MessageModel.X0：POST getDateMessage {stateCode:m, page:g}（h=15/页）；
 *   a.g 成功 → P1（g==1 替换 / 否则追加；size<15 无更多）；a.f 失败 → 有数据 toast / 空则错误视图。
 * 【交互】点击：编辑模式 toggle isSelected+计数(EventBus45)；浏览模式 未读tab或STATE=='1'
 *   先 updateState 标记已读，isEmc==1 → EmcMessageDetailActivity（无CONTENT）；EXT 无 LX →
 *   详情页（带 CONTENT/SENDBY）；有 LX → AppRouterUtils.f 按 LX 分流。
 *   长按（非编辑、非EMC）→ 确认删除单条；编辑模式底栏 → 批量删除 M2（batchdelete xlhs）。
 * 【工具菜单】MessagePopupDialog（R2：SystemSwitch 三开关 all_messages_read/all_messages_delete/
 *   batch_messages_delete 全 "1" 才显示编辑入口）：全部已读 allUpdateState / 全部删除 alldelete
 *   {stateCode: 单页签=3, t==0=1, t!=0=2} / 批量删除 → N2 进编辑模式。
 * 【SystemSwitch 现状】HAP 未持久化（ContactPage 同款结论）→ 等价源码 systemSwitch==null 分支：
 *   单"全部消息"页签、无编辑入口；全部编辑/删除链路代码保留，开关下发后自动点亮。
 * 【跳转映射】LX 1/7 → 原生路由/小程序（HAP 无原生 AppRouter → 等价 ActivityNotFound 分支
 *   toast"程序猿正在加班加点赶功能"）；2/4/6/8/15 → H5（WebViewPage 等价 e.a.v）；5 → 三方 App
 *   （等价"请先安装应用"）；16 → 消息详情 EmcMessageDetailPage。
 */

/** C0 路由参数 — EmcMessageDetailActivity.y(Intent) 读的 bundle key */
interface MessageNavParams {
  channelCode: string;
  xlh: string;
  title: string;
  sendTime: string;
  content: string;
  sendBy: string;
}

/** WebViewPage 路由参数（AppRouterUtils.f H5 分流 e.a.v 等价） */
interface WebNavParams {
  url: string;
  title: string;
}

/** 页签定义 — MessageListActivity.r（标题）+ MessageFragment.d2(type) */
class MessageTabDef {
  title: string = '';
  type: number = 3;
}

/** RefreshFragment 分页状态：g=page（初值1）、h=15（MessageFragment.f1 设定） */
class MessageTabState {
  rows: MainNotificationV2[] = [];
  page: number = 1;
  loading: boolean = false;
  loaded: boolean = false;
  refreshing: boolean = false;
  hasMore: boolean = true;
  errMsg: string = '';
}

/** MessagePopupDialog.show(t) 计算出的菜单可见性（vLine1/vLine2 源码绑定 all_read/all_delete 开关） */
class PopupMenuFlags {
  showAllRead: boolean = false;
  showAllDelete: boolean = false;
  showBatchDelete: boolean = false;
  showLine1: boolean = false;
  showLine2: boolean = false;
  showTriangle: boolean = false;
}

const PAGE_SIZE: number = 15;

@Entry
@Component
struct MessageListPage {
  @State tabs: MessageTabDef[] = [];
  @State states: MessageTabState[] = [];
  @State currentTab: number = 0;
  /** MessageListActivity.s：0=浏览 1=编辑（N2 切换） */
  @State editMode: number = 0;
  /** tvDelete 文案计数（EventBus45/批量删除回调） */
  @State deleteCount: number = 0;
  @State showPopup: boolean = false;
  /** R2 三开关（systemSwitch==null → 全部空 → 菜单项全隐藏） */
  @State swAllRead: string = '';
  @State swAllDelete: string = '';
  @State swBatchDelete: string = '';
  @State selectedMsg: MainNotificationV2 | null = null;
  @State selectedMsgContent: string = '';
  @State detailLoading: boolean = false;
  @State detailError: string = '';
  @StorageProp('currentBreakpoint') currentBreakpoint: string = 'sm';
  @StorageProp('windowWidthVp') windowWidthVp: number = 360;
  @StorageProp('windowHeightVp') windowHeightVp: number = 780;
  @StorageProp('avoidAreaLeftVp') avoidAreaLeftVp: number = 0;
  @StorageProp('avoidAreaRightVp') avoidAreaRightVp: number = 0;
  @StorageProp('avoidAreaBottomVp') avoidAreaBottomVp: number = 0;

  aboutToAppear(): void {
    // 源码 MessageListActivity.f1 → Q2()（页签）+ R2()（SystemSwitch 三开关）
    this.initTabs();
  }

  // ===== Q2：messages_page_tabs=="2" 双页签，否则单"全部消息" =====
  private initTabs(): void {
    const defs: MessageTabDef[] = [];
    const states: MessageTabState[] = [];
    const sw: MessageSystemSwitch | null = MessageSystemSwitch.current();
    if (sw !== null && sw.messagesPageTabs === '2') {
      const unread: MessageTabDef = new MessageTabDef();
      unread.title = '未读消息';
      unread.type = 1;
      defs.push(unread);
      const read: MessageTabDef = new MessageTabDef();
      read.title = '已读消息';
      read.type = 2;
      defs.push(read);
    } else {
      const all: MessageTabDef = new MessageTabDef();
      all.title = '全部消息';
      all.type = 3;
      defs.push(all);
    }
    this.swAllRead = sw !== null ? sw.allMessagesRead : '';
    this.swAllDelete = sw !== null ? sw.allMessagesDelete : '';
    this.swBatchDelete = sw !== null ? sw.batchMessagesDelete : '';
    for (const def of defs) {
      states.push(new MessageTabState());
    }
    this.states = states;
    this.tabs = defs;
    // ViewPager2 offscreenPageLimit=2：所有 Fragment 创建即 f1() → Z1() 首次加载
    for (let i = 0; i < defs.length; i++) {
      this.fetchList(i, 1, false);
    }
  }

  /** 源码 MessageFragment.Z1 → k.m(...).j(m+"", g+"")：getDateMessage POST {stateCode, page} */
  private fetchList(idx: number, pageNum: number, isLoadMore: boolean): void {
    if (idx < 0 || idx >= this.tabs.length) {
      return;
    }
    ApiService.getMessageList(String(this.tabs[idx].type), pageNum)
      .then((response: ApiResponse<MainNotificationV2[]>) => {
        if (response.code === 1000) {
          // 登录失效统一处理已在网络层触发（HttpClient.bizRequest 拦截：清会话+toast+跳登录）
          this.patchState(idx, this.idleState(idx));
          return;
        }
        if (response.code === 0) {
          this.handleListOk(idx, pageNum, isLoadMore, response.data);
        } else {
          this.handleListFail(idx, response.message);
        }
      })
      .catch((error: BusinessError) => {
        ApiService.logError('Message fetchList fail: ' + error.message);
        this.handleListFail(idx, '网络请求失败');
      });
  }

  /** 源码 RefreshFragment.P1 + MessageFragment a.g：首页替换/追加，<15 停止加载更多 */
  private handleListOk(idx: number, pageNum: number, isLoadMore: boolean, rows: MainNotificationV2[]): void {
    const prev: MessageTabState = this.states[idx];
    const st: MessageTabState = new MessageTabState();
    st.page = pageNum;
    st.loaded = true;
    st.loading = false;
    st.refreshing = false;
    st.errMsg = '';
    st.rows = isLoadMore ? prev.rows.concat(rows) : rows;
    st.hasMore = rows.length >= PAGE_SIZE;
    this.patchState(idx, st);
  }

  /** 源码 MessageFragment a.f：有数据 toast 保持内容；空列表 → 错误视图（tvReload 重试） */
  private handleListFail(idx: number, message: string): void {
    const prev: MessageTabState = this.states[idx];
    const st: MessageTabState = new MessageTabState();
    st.rows = prev.rows;
    st.page = prev.page;
    st.hasMore = prev.hasMore;
    st.loaded = prev.loaded || prev.rows.length === 0;
    st.loading = false;
    st.refreshing = false;
    st.errMsg = message === '' ? '请求失败' : message;
    this.patchState(idx, st);
    // 源码 a.f：仅有数据时 toast；空列表走错误视图（不重复 toast）
    if (st.rows.length > 0) {
      this.toast(st.errMsg);
    }
  }

  /** 源码 RefreshFragment a.f(fVar)（下拉）：g=1 → Z1 */
  private refreshTab(idx: number): void {
    if (idx < 0 || idx >= this.tabs.length) {
      return;
    }
    const prev: MessageTabState = this.states[idx];
    const st: MessageTabState = new MessageTabState();
    st.rows = prev.rows;
    st.page = 1;
    st.loaded = prev.loaded;
    st.hasMore = true;
    st.refreshing = true;
    st.loading = true;
    this.patchState(idx, st);
    this.fetchList(idx, 1, false);
  }

  /** 源码 RefreshFragment a.i(fVar)（上拉）：g++ → Z1 */
  private loadMoreTab(idx: number): void {
    if (idx < 0 || idx >= this.tabs.length) {
      return;
    }
    const prev: MessageTabState = this.states[idx];
    if (!prev.hasMore || prev.loading || !prev.loaded) {
      return;
    }
    const st: MessageTabState = new MessageTabState();
    st.rows = prev.rows;
    st.page = prev.page + 1;
    st.loaded = prev.loaded;
    st.hasMore = prev.hasMore;
    st.loading = true;
    this.patchState(idx, st);
    this.fetchList(idx, st.page, true);
  }

  /** 源码 MessageFragment.b(tvReload)/T0 code46·52 已读分支：g=1 → Z1 重载 */
  private reloadTab(idx: number): void {
    const prev: MessageTabState = this.states[idx];
    const st: MessageTabState = new MessageTabState();
    st.rows = prev.rows;
    st.page = 1;
    st.loaded = prev.loaded;
    st.hasMore = true;
    st.loading = true;
    this.patchState(idx, st);
    this.fetchList(idx, 1, false);
  }

  private idleState(idx: number): MessageTabState {
    const prev: MessageTabState = this.states[idx];
    const st: MessageTabState = new MessageTabState();
    st.rows = prev.rows;
    st.page = prev.page;
    st.hasMore = prev.hasMore;
    st.loaded = prev.loaded;
    st.errMsg = prev.errMsg;
    return st;
  }

  private patchState(idx: number, st: MessageTabState): void {
    const copy: MessageTabState[] = this.states.slice();
    copy[idx] = st;
    this.states = copy;
  }

  // ===== 源码 MessageAdapter.d(int)：编辑模式标记 + T0 code44：清除全部选中 =====
  private onEditModeChanged(): void {
    for (let i = 0; i < this.states.length; i++) {
      const prev: MessageTabState = this.states[i];
      const rows: MainNotificationV2[] = prev.rows;
      for (const row of rows) {
        row.isSelected = false;
      }
      const st: MessageTabState = new MessageTabState();
      st.rows = rows;
      st.page = prev.page;
      st.hasMore = prev.hasMore;
      st.loaded = prev.loaded;
      st.errMsg = prev.errMsg;
      this.patchState(i, st);
    }
    this.deleteCount = 0;
  }

  /** 源码 N2()：s 0↔1（tvDelete/tvRightText/ivRightIcon 可见性）+ EventBus44 */
  private toggleEditMode(): void {
    if (this.editMode === 1) {
      this.editMode = 0;
    } else {
      this.editMode = 1;
      this.deleteCount = 0;
    }
    this.showPopup = false;
    this.onEditModeChanged();
  }

  /** 源码 MessageFragment.a2()：统计选中数 + EventBus45 → tvDelete 文案 */
  private refreshDeleteCount(): void {
    let count: number = 0;
    const st: MessageTabState = this.states[this.currentTab];
    for (const row of st.rows) {
      if (row.isSelected) {
        count++;
      }
    }
    this.deleteCount = count;
  }

  /** 源码 MessageFragment.d.onItemClick（编辑模式分支）：toggle + 计数 */
  private onItemTap(item: MainNotificationV2, idx: number, pos: number): void {
    if (this.editMode !== 0) {
      item.isSelected = !item.isSelected;
      this.refreshDeleteCount();
      const prev: MessageTabState = this.states[idx];
      this.patchState(idx, this.idleState(idx));
      return;
    }
    // 浏览模式：未读 tab(m==1) 或 全部tab且未读(STATE=='1') → 先 updateState 标记已读
    const type: number = this.tabs[idx].type;
    if (type === 1 || (type === 3 && item.STATE === '1')) {
      this.doMarkRead(item, idx, pos);
    }
    this.jumpByMessage(item, idx);
  }

  /** 源码 e2 → h.d.q(a1)：GET updateState {xlh, batchId, isEmc?}；f.g：m==1 移除行+EventBus52，m==3 STATE='2' */
  private doMarkRead(item: MainNotificationV2, idx: number, pos: number): void {
    ApiService.updateMessageState(item.XLH, item.BATCHID, item.isEmc)
      .then((response: ApiResponse<Object>) => {
        if (response.code === 1000) {
          // 登录失效统一处理已在网络层触发（HttpClient.bizRequest 拦截：清会话+toast+跳登录）
          return;
        }
        if (response.code !== 0) {
          return;
        }
        const type: number = this.tabs[idx].type;
        const prev: MessageTabState = this.states[idx];
        const st: MessageTabState = new MessageTabState();
        st.page = prev.page;
        st.hasMore = prev.hasMore;
        st.loaded = prev.loaded;
        if (type === 1) {
          const rows: MainNotificationV2[] = prev.rows.slice();
          rows.splice(pos, 1);
          st.rows = rows;
          this.patchState(idx, st);
          this.onOneDeletedFromUnread();
        } else {
          item.STATE = '2';
          st.rows = prev.rows;
          this.patchState(idx, st);
        }
      })
      .catch((error: BusinessError) => {
        ApiService.logError('Message updateState fail: ' + error.message);
      });
  }

  /** 源码 T0 code52：单条删除（未读tab）→ 已读 tab g=1 重载 */
  private onOneDeletedFromUnread(): void {
    for (let i = 0; i < this.tabs.length; i++) {
      if (this.tabs[i].type === 2) {
        this.reloadTab(i);
        return;
      }
    }
  }

  /** 源码 d.onItemClick 跳转段：isEmc → 详情(无CONTENT)；EXT 无 LX → 详情(带CONTENT/SENDBY)；有 LX → AppRouterUtils.f */
  private jumpByMessage(item: MainNotificationV2, idx: number): void {
    const splitCfg: SplitPaneConfig =
      AdaptiveLayoutHelper.getSplitPaneConfig(this.currentBreakpoint, this.windowWidthVp);
    if (!splitCfg.useTwoPane) {
      this.openMessageFullPage(item);
      return;
    }
    this.selectMessageForPreview(item);
  }

  private openMessageFullPage(item: MainNotificationV2): void {
    if (item.isEmc === 1) {
      this.openDetail(item, false);
      return;
    }
    const ext: MessageExtAppBean | null = item.EXT;
    if (ext === null || ext.LX === '') {
      this.openDetail(item, true);
      return;
    }
    ext.xxTitle = item.TITLE;
    ext.xxContent = item.CONTENT;
    this.jumpByLx(ext);
  }

  private selectMessageForPreview(item: MainNotificationV2): void {
    this.selectedMsg = item;
    this.detailError = '';
    this.selectedMsgContent = item.CONTENT;
    if (item.CONTENT !== '') {
      this.detailLoading = false;
      return;
    }
    this.detailLoading = true;
    const xlh: string = item.XLH;
    ApiService.getEmcMessageContent(item.XLH, item.channelCode)
      .then((response: ApiResponse<Object>) => {
        if (response.code === 1000) {
          this.detailLoading = false;
          return;
        }
        if (this.selectedMsg === null || this.selectedMsg.XLH !== xlh) {
          return;
        }
        this.detailLoading = false;
        if (response.code === 0) {
          this.selectedMsgContent = typeof response.data === 'string' ? response.data as string : '';
        } else {
          this.detailError = response.message === '' ? '获取消息详情失败' : response.message;
        }
      })
      .catch((error: BusinessError) => {
        ApiService.logError('MessageListPage inline detail fail: ' + error.message);
        if (this.selectedMsg !== null && this.selectedMsg.XLH === xlh) {
          this.detailLoading = false;
          this.detailError = '网络异常，请稍后重试';
        }
      });
  }

  /** 源码 U1/c2 → g2(activity, e.a.C0, bundle) = EmcMessageDetailActivity（/main/notification_detail） */
  private openDetail(item: MainNotificationV2, withContent: boolean): void {
    const params: MessageNavParams = {
      channelCode: item.channelCode,
      xlh: item.XLH,
      title: item.TITLE,
      sendTime: item.SENDTIME,
      content: withContent ? item.CONTENT : '',
      sendBy: withContent ? item.SENDBY : ''
    };
    router.pushUrl({ url: 'pages/EmcMessageDetailPage', params: params });
  }

  /** 源码 AppRouterUtils.f(context, appBean)：LX 分流（HAP 无原生 AppRouter，按等价分支落地） */
  private jumpByLx(ext: MessageExtAppBean): void {
    if (ext.LX === '16') {
      const params: MessageNavParams = {
        channelCode: '',
        xlh: '',
        title: ext.xxTitle,
        sendTime: ext.xxTime,
        content: ext.xxContent,
        sendBy: ext.xxSender
      };
      router.pushUrl({ url: 'pages/EmcMessageDetailPage', params: params });
      return;
    }
    if (ext.LX === '2' || ext.LX === '4' || ext.LX === '6' || ext.LX === '8' || ext.LX === '15') {
      const params: WebNavParams = { url: ext.URL, title: ext.YYMC };
      router.pushUrl({ url: 'pages/WebViewPage', params: params });
      return;
    }
    if (ext.LX === '5') {
      // 源码 h()：三方 App 拉起失败分支 toast"请先安装应用"
      this.toast('请先安装应用');
      return;
    }
    // LX 1/7：原生路由/小程序（g()/b.f）→ HAP 无该路由，等价 ActivityNotFound → toast
    this.toast('程序猿正在加班加点赶功能');
  }

  /** 源码 c.onItemLongClick（P2()==0 且 isEmc!=1）：确认删除单条 → Y1 → delete */
  private onItemLongPress(item: MainNotificationV2, pos: number, idx: number): void {
    if (this.editMode !== 0 || item.isEmc === 1) {
      return;
    }
    AlertDialog.show({
      title: '删除消息',
      message: '确认要将这条消息删除吗？',
      autoCancel: true,
      alignment: DialogAlignment.Center,
      primaryButton: {
        value: '取消',
        action: (): void => {
        }
      },
      secondaryButton: {
        value: '确认',
        action: (): void => {
          this.doDeleteOne(item, pos, idx);
        }
      }
    });
  }

  /** 源码 Y1 → h.d.f(U0)：GET delete {xlh, isEmc?}；e.g 移除行+toast；e.b 余量<15 → g++ 追拉一页 */
  private doDeleteOne(item: MainNotificationV2, pos: number, idx: number): void {
    ApiService.deleteMessage(item.XLH, item.isEmc)
      .then((response: ApiResponse<Object>) => {
        if (response.code === 1000) {
          // 登录失效统一处理已在网络层触发（HttpClient.bizRequest 拦截：清会话+toast+跳登录）
          return;
        }
        if (response.code !== 0) {
          this.toast(response.message);
          return;
        }
        const prev: MessageTabState = this.states[idx];
        const st: MessageTabState = new MessageTabState();
        st.page = prev.page;
        st.hasMore = prev.hasMore;
        st.loaded = prev.loaded;
        const rows: MainNotificationV2[] = prev.rows.slice();
        rows.splice(pos, 1);
        st.rows = rows;
        st.loaded = true;
        st.loading = false;
        this.patchState(idx, st);
        this.toast('删除成功');
        if (rows.length < PAGE_SIZE) {
          this.loadMoreTab(idx);
        }
      })
      .catch((error: BusinessError) => {
        ApiService.logError('Message delete fail: ' + error.message);
        this.toast('网络请求失败');
      });
  }

  /** 源码 MToolBar.c(ivRightIcon)：popup.show(t)（开关全空时菜单不可达） */
  private onEditIconClick(): void {
    this.showPopup = true;
  }

  /** 源码 MessagePopupDialog.show(t)：已读 tab 隐藏"全部已读"，三项全无 → 隐藏三角 */
  private popupFlags(): PopupMenuFlags {
    const flags: PopupMenuFlags = new PopupMenuFlags();
    flags.showAllRead = this.swAllRead === '1';
    flags.showAllDelete = this.swAllDelete === '1';
    flags.showBatchDelete = this.swBatchDelete === '1';
    if (this.currentTab === 1 && flags.showAllRead) {
      flags.showAllRead = false;
    }
    // 源码 handleViewsVisible：vLine1 随 all_messages_read、vLine2 随 all_messages_delete（相邻项隐藏也保留）
    flags.showLine1 = flags.showAllRead;
    flags.showLine2 = flags.showAllDelete;
    flags.showTriangle = this.swAllRead === '1' || flags.showAllDelete || flags.showBatchDelete;
    return flags;
  }

  /** 源码 MessagePopupDialog → a.a()（批量删除）：dismiss + N2 */
  private onPopupBatchDelete(): void {
    this.showPopup = false;
    this.toggleEditMode();
  }

  /** 源码 a.b()（全部删除）：按页签拼确认文案 → O2 */
  private onPopupAllDelete(): void {
    this.showPopup = false;
    let title: string = '删除全部消息';
    let text: string = '确认要将全部消息删除吗？';
    if (this.tabs.length !== 1) {
      if (this.currentTab === 0) {
        title = '删除全部未读消息';
        text = '确认要将全部未读消息删除吗？';
      } else {
        title = '删除全部已读消息';
        text = '确认要将全部已读消息删除吗？';
      }
    }
    AlertDialog.show({
      title: title,
      message: text,
      autoCancel: true,
      alignment: DialogAlignment.Center,
      primaryButton: {
        value: '取消',
        action: (): void => {
        }
      },
      secondaryButton: {
        value: '确认',
        action: (): void => {
          this.doAllDelete();
        }
      }
    });
  }

  /** 源码 O2：stateCode = 单页签3 / t==0 → 1 / t!=0 → 2；f.g → EventBus48 + toast 删除成功 */
  private doAllDelete(): void {
    let stateCode: number = 3;
    if (this.tabs.length !== 1) {
      stateCode = this.currentTab !== 0 ? 2 : 1;
    }
    ApiService.allDeleteMessages(String(stateCode))
      .then((response: ApiResponse<Object>) => {
        if (response.code === 1000) {
          // 登录失效统一处理已在网络层触发（HttpClient.bizRequest 拦截：清会话+toast+跳登录）
          return;
        }
        if (response.code !== 0) {
          this.toast(response.message);
          return;
        }
        this.onAllDeleteDone(this.currentTab);
        this.toast('删除成功');
      })
      .catch((error: BusinessError) => {
        ApiService.logError('Message allDelete fail: ' + error.message);
        this.toast('网络请求失败');
      });
  }

  /** 源码 T0 code48：m==3 清空；被删页签（t+1==m）清空 */
  private onAllDeleteDone(deletedIdx: number): void {
    for (let i = 0; i < this.states.length; i++) {
      const type: number = this.tabs[i].type;
      if (type === 3 || type === deletedIdx + 1) {
        const prev: MessageTabState = this.states[i];
        const st: MessageTabState = new MessageTabState();
        st.rows = [];
        st.page = prev.page;
        st.loaded = prev.loaded;
        this.patchState(i, st);
      }
    }
  }

  /** 源码 a.c()（全部标记已读）：确认 → C0389a allUpdateState → EventBus46 + toast"全部消息标记为已读" */
  private onPopupAllRead(): void {
    this.showPopup = false;
    AlertDialog.show({
      title: '全部标记为已读',
      message: '确认要将全部消息状态设置为\n已读吗？',
      autoCancel: true,
      alignment: DialogAlignment.Center,
      primaryButton: {
        value: '取消',
        action: (): void => {
        }
      },
      secondaryButton: {
        value: '确认',
        action: (): void => {
          this.doAllRead();
        }
      }
    });
  }

  private doAllRead(): void {
    ApiService.allUpdateMessageState()
      .then((response: ApiResponse<Object>) => {
        if (response.code === 1000) {
          // 登录失效统一处理已在网络层触发（HttpClient.bizRequest 拦截：清会话+toast+跳登录）
          return;
        }
        if (response.code !== 0) {
          this.toast(response.message);
          return;
        }
        this.onAllReadDone();
        this.toast('全部消息标记为已读');
      })
      .catch((error: BusinessError) => {
        ApiService.logError('Message allUpdateState fail: ' + error.message);
        this.toast('网络请求失败');
      });
  }

  /** 源码 T0 code46：未读 tab 清空列表；其余 tab g=1 重载 */
  private onAllReadDone(): void {
    for (let i = 0; i < this.states.length; i++) {
      if (this.tabs[i].type === 1) {
        const prev: MessageTabState = this.states[i];
        const st: MessageTabState = new MessageTabState();
        st.rows = [];
        st.page = prev.page;
        st.loaded = prev.loaded;
        this.patchState(i, st);
      } else {
        this.reloadTab(i);
      }
    }
  }

  /** 源码 e.onClick(tvDelete)：u.b2() 选中项；空 → toast；确认 → M2 batchdelete */
  private onTvDeleteClick(): void {
    const selected: MainNotificationV2[] = [];
    const st: MessageTabState = this.states[this.currentTab];
    if (this.editMode === 1) {
      for (const row of st.rows) {
        if (row.isSelected) {
          selected.push(row);
        }
      }
    }
    if (selected.length <= 0) {
      this.toast('请选择删除项');
      return;
    }
    AlertDialog.show({
      title: '删除消息',
      message: '确认要将这' + selected.length + '条消息删除吗？',
      autoCancel: true,
      alignment: DialogAlignment.Center,
      primaryButton: {
        value: '取消',
        action: (): void => {
        }
      },
      secondaryButton: {
        value: '确认',
        action: (): void => {
          this.doBatchDelete(selected);
        }
      }
    });
  }

  /** 源码 M2：xlhs JSON 数组 → batchdelete；g 回调：toast 删除成功 + 计数清零 + u.X1() */
  private doBatchDelete(selected: MainNotificationV2[]): void {
    const ids: string[] = [];
    for (const row of selected) {
      ids.push(row.XLH);
    }
    ApiService.batchDeleteMessages(ids)
      .then((response: ApiResponse<Object>) => {
        if (response.code === 1000) {
          // 登录失效统一处理已在网络层触发（HttpClient.bizRequest 拦截：清会话+toast+跳登录）
          return;
        }
        if (response.code !== 0) {
          this.toast(response.message);
          return;
        }
        this.toast('删除成功');
        this.deleteCount = 0;
        this.removeSelectedAndPull();
      })
      .catch((error: BusinessError) => {
        ApiService.logError('Message batchDelete fail: ' + error.message);
        this.toast('网络请求失败');
      });
  }

  /** 源码 MessageFragment.X1：移除选中行；余量<15 → g++ 追拉一页 */
  private removeSelectedAndPull(): void {
    const idx: number = this.currentTab;
    const prev: MessageTabState = this.states[idx];
    const rows: MainNotificationV2[] = [];
    for (const row of prev.rows) {
      if (!row.isSelected) {
        rows.push(row);
      }
    }
    const st: MessageTabState = new MessageTabState();
    st.rows = rows;
    st.page = prev.page;
    st.hasMore = prev.hasMore;
    st.loaded = prev.loaded;
    st.loading = false;
    this.patchState(idx, st);
    if (rows.length < PAGE_SIZE) {
      this.loadMoreTab(idx);
    }
  }

  private toast(message: string): void {
    if (message === '') {
      return;
    }
    this.getUIContext().getPromptAction().showToast({ message: message });
  }

  // 登录失效统一处理已下沉网络层（HttpClient.bizRequest code=1000 拦截：清会话+toast+跳登录），
  // 页面 1000 分支只负责 return，不再持有本地 onSessionExpired 实现

  build() {
    Stack() {
      Column() {
        this.topBar()
        if (AdaptiveLayoutHelper.getSplitPaneConfig(this.currentBreakpoint, this.windowWidthVp).useTwoPane) {
          Row() {
            Column() {
              this.tabBar()
              this.swiperArea()
              if (this.editMode === 1) {
                Text('删除（' + this.deleteCount + '）')
                  .fontSize(16)
                  .fontColor($r('app.color.read_dot_bg'))
                  .textAlign(TextAlign.Center)
                  .width('100%')
                  .padding({ top: 15, bottom: 15 })
                  .backgroundColor($r('app.color.white'))
                  .hoverEffect(HoverEffect.Highlight)
                  .onClick(() => {
                    this.onTvDeleteClick();
                  })
              }
            }
            .layoutWeight(AdaptiveLayoutHelper.getSplitPaneConfig(
              this.currentBreakpoint, this.windowWidthVp).masterRatio)
            .height('100%')

            Divider()
              .vertical(true)
              .width(0.5)
              .height('100%')
              .color($r('app.color.common_color_5'))

            Column() {
              this.messageDetailPane()
            }
            .layoutWeight(AdaptiveLayoutHelper.getSplitPaneConfig(
              this.currentBreakpoint, this.windowWidthVp).detailRatio)
            .height('100%')
          }
          .width('100%')
          .layoutWeight(1)
          .padding({ left: this.avoidAreaLeftVp, right: this.avoidAreaRightVp })
        } else {
          this.tabBar()
          this.swiperArea()
          if (this.editMode === 1) {
            Text('删除（' + this.deleteCount + '）')
              .fontSize(16)
              .fontColor($r('app.color.read_dot_bg'))
              .textAlign(TextAlign.Center)
              .width('100%')
              .padding({ top: 15, bottom: 15 })
              .backgroundColor($r('app.color.white'))
              .hoverEffect(HoverEffect.Highlight)
              .onClick(() => {
                this.onTvDeleteClick();
              })
          }
        }
      }
      .width('100%')
      .height('100%')
      .backgroundColor($r('app.color.white'))
      if (this.showPopup) {
        this.popupOverlay()
      }
    }
    .width('100%')
    .height('100%')
  }

  /** m_toolbar.xml：FrameLayout 45vp + tvTitle 17fp 居中 + 返回/右文/右图标 + vLine 0.5 #E7E7E7 */
  @Builder
  topBar() {
    Column() {
      Stack() {
        Text('消息')
          .fontSize(17)
          .fontColor($r('app.color.common_color_1'))
          .textAlign(TextAlign.Center)
          .maxLines(1)
          .width('100%')
          .padding({ left: 105, right: 105 })
        Row() {
          Image($r('app.media.nav_back_btn'))
            .width(35)
            .height(35)
            .objectFit(ImageFit.Contain)
            .margin({ left: 5 })
            .hoverEffect(HoverEffect.Highlight)
            .onClick(() => {
              router.back();
            })
          Blank().layoutWeight(1)
          if (this.editMode === 1) {
            Text('取消')
              .fontSize(16)
              .fontColor('#333333')
              .maxLines(1)
              .padding({ right: 15 })
              .hoverEffect(HoverEffect.Highlight)
              .onClick(() => {
                this.toggleEditMode();
              })
          } else if (this.editIconVisible()) {
            Image($r('app.media.icon_message_list_edit'))
              .width(40)
              .height(35)
              .objectFit(ImageFit.Contain)
              .padding(2.5)
              .margin({ right: 5 })
              .hoverEffect(HoverEffect.Highlight)
              .onClick(() => {
                this.onEditIconClick();
              })
          } else {
            Blank().width(40)
          }
        }
        .width('100%')
        .height('100%')
        .alignItems(VerticalAlign.Center)
      }
      .width('100%')
      .height(44)
      Divider()
        .color('#E7E7E7')
        .strokeWidth(0.5)
        .width('100%')
    }
    .width('100%')
    .height(45)
    .backgroundColor($r('app.color.white'))
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP])
  }

  /** 源码 R2：三开关任一 "1" 才显示 ivRightIcon（systemSwitch==null → 隐藏） */
  private editIconVisible(): boolean {
    return this.swAllRead === '1' || this.swAllDelete === '1' || this.swBatchDelete === '1';
  }

  /** MagicIndicator(mTabLayout 40vp)：单页签隐藏；标题14fp + 指示条 32×3 r2 #1B68B7 + 中缝 1×0.5 */
  @Builder
  tabBar() {
    if (this.tabs.length > 1) {
      Row() {
        ForEach(this.tabs, (tab: MessageTabDef, idx: number) => {
          if (idx > 0) {
            // 源码 S2：titleContainer SHOW_DIVIDER_MIDDLE + simple_splitter（页签之间，非行尾）
            Divider()
              .vertical(true)
              .color('#E7E7E7')
              .strokeWidth(1)
              .height(16)
              .margin({ top: 8, bottom: 8 })
          }
          Column() {
            Text(tab.title)
              .fontSize(14)
              .fontColor(this.currentTab === idx ? '#1B68B7' : $r('app.color.explain_color'))
              .maxLines(1)
            Row()
              .width(32)
              .height(3)
              .borderRadius(2)
              .backgroundColor(this.currentTab === idx ? '#1B68B7' : Color.Transparent)
              .margin({ top: 4 })
          }
          .alignItems(HorizontalAlign.Center)
          .justifyContent(FlexAlign.Center)
          .layoutWeight(1)
          .hoverEffect(HoverEffect.Highlight)
          .onClick(() => {
            this.currentTab = idx;
          })
        }, (tab: MessageTabDef, idx: number) => idx.toString() + tab.title)
      }
      .width('100%')
      .height(36)
      .padding({ bottom: 4 })
      .backgroundColor($r('app.color.white'))
    }
  }

  /** ViewPager2(mViewPager bg #f2f2f2) → Swiper，每页 = MessageFragment */
  @Builder
  swiperArea() {
    Swiper() {
      ForEach(this.tabs, (tab: MessageTabDef, idx: number) => {
        Column() {
          if (this.states.length === this.tabs.length) {
            this.tabListPage(idx)
          }
        }
        .width('100%')
        .height('100%')
      }, (tab: MessageTabDef, idx: number) => idx.toString() + tab.title)
    }
    .index(this.currentTab)
    .loop(false)
    .indicator(false)
    .backgroundColor('#F2F2F2')
    .onChange((idx: number) => {
      // 源码 c.onPageSelected：t=idx + EventBus47 + 编辑模式中切页 → N2 退出编辑
      this.currentTab = idx;
      if (this.editMode === 1) {
        this.toggleEditMode();
      }
    })
    .layoutWeight(1)
  }

  /** fragment_message.xml：SmartRefreshLayout + RecyclerView（空态/错误态/分页加载） */
  @Builder
  tabListPage(idx: number) {
    Refresh({
      refreshing: this.states[idx].refreshing
    }) {
      if (!this.states[idx].loaded && this.states[idx].loading) {
        LoadingView()
      } else if (this.states[idx].errMsg !== '' && this.states[idx].rows.length === 0) {
        // layout_message_error.xml：icon_message_error + 文案 + tvReload 重试（描边 #1B68B7 r4）
        Column() {
          Image($r('app.media.icon_message_error'))
            .width(96)
            .height(96)
            .objectFit(ImageFit.Contain)
          Text('请求失败，请点击重试')
            .fontSize(16)
            .fontColor('#CECECE')
            .textAlign(TextAlign.Center)
            .margin({ top: 24 })
          Text('重试')
            .fontSize(14)
            .fontColor('#1B68B7')
            .padding({ left: 30, right: 30, top: 7, bottom: 7 })
            .borderRadius(4)
            .border({ width: 1, color: '#1B68B7' })
            .margin({ top: 24 })
            .hoverEffect(HoverEffect.Highlight)
            .onClick(() => {
              this.reloadTab(idx);
            })
        }
        .width('100%')
        .height('100%')
        .backgroundColor('#F2F2F2')
        .justifyContent(FlexAlign.Center)
      } else if (this.states[idx].rows.length === 0) {
        // layout_message_empty.xml：icon_message_empty + "暂无消息"
        Column() {
          Image($r('app.media.icon_message_empty'))
            .width(96)
            .height(96)
            .objectFit(ImageFit.Contain)
          Text('暂无消息')
            .fontSize(16)
            .fontColor('#CECECE')
            .textAlign(TextAlign.Center)
            .margin({ top: 24 })
        }
        .width('100%')
        .height('100%')
        .backgroundColor('#F2F2F2')
        .justifyContent(FlexAlign.Center)
      } else {
        List({ space: 0 }) {
          ForEach(this.states[idx].rows, (row: MainNotificationV2, pos: number) => {
            ListItem() {
              this.messageItem(row, pos, idx)
            }
          }, (row: MainNotificationV2, pos: number) => idx.toString() + '-' + pos.toString() +
            '-' + row.XLH + '-' + row.STATE + '-' + row.isSelected.toString())
        }
        .width('100%')
        .height('100%')
        .backgroundColor('#F2F2F2')
        .scrollBar(BarState.Off)
        .edgeEffect(EdgeEffect.Spring)
        .onReachEnd(() => {
          this.loadMoreTab(idx);
        })
      }
    }
    .width('100%')
    .height('100%')
    .onRefreshing(() => {
      this.refreshTab(idx);
    })
  }

  /** item_message.xml：vLine 12vp(仅首行) + 白底行(padL10/T12/R15/B12)
   *  左列 30vp（bell 16×16 mT3.5 / 红点 5×5 / 勾选 16×16）+ tvTitle 16fp#333 + tvTime 13fp#999
   *  + 底分隔线 0.5 #E7E7E7。normal：bell可见+未读红点；edit：仅勾选图标 */
  @Builder
  messageItem(row: MainNotificationV2, pos: number, idx: number) {
    Column() {
      if (pos === 0) {
        Column()
          .width('100%')
          .height(12)
          .backgroundColor('#F2F2F2')
      }
      Row() {
        // 左列 30vp：RelativeLayout 16×16 居中（bell 填充 + 红点 5×5 右上角）/ 编辑模式勾选图标
        if (this.editMode === 0) {
          Stack({ alignContent: Alignment.TopStart }) {
            Image($r('app.media.icon_unify_notification_notification'))
              .width(16)
              .height(16)
              .objectFit(ImageFit.Contain)
              .margin({ left: 7, top: 3.5 })
            Circle()
              .width(5)
              .height(5)
              .fill($r('app.color.read_dot_bg'))
              .visibility(row.STATE === '1' ? Visibility.Visible : Visibility.None)
              .margin({ left: 18, top: 3.5 })
          }
          .width(30)
          .height(16)
          .alignSelf(ItemAlign.Start)
        } else {
          Column() {
            Image(row.isSelected ? $r('app.media.icon_message_list_select') :
              $r('app.media.icon_message_list_un_select'))
              .width(16)
              .height(16)
              .objectFit(ImageFit.Contain)
          }
          .width(30)
          .height(16)
          .alignItems(HorizontalAlign.Center)
          .justifyContent(FlexAlign.Center)
          .alignSelf(ItemAlign.Center)
        }

        Column() {
          Text(row.TITLE)
            .fontSize(16)
            .fontColor('#333333')
            .lineHeight(21)
            .width('100%')
          Text('发布日期：' + row.SENDTIME)
            .fontSize(13)
            .fontColor('#999999')
            .lineHeight(18)
            .width('100%')
            .margin({ top: 8 })
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
        .padding({ left: 10 })
      }
      .width('100%')
      .backgroundColor(this.selectedMsg !== null && this.selectedMsg.XLH === row.XLH
        ? '#EEF5FC' : $r('app.color.white'))
      .padding({ left: 10, top: 12, right: 15, bottom: 12 })
      .alignItems(VerticalAlign.Top)
      .hoverEffect(HoverEffect.Highlight)
      .onClick(() => {
        this.onItemTap(row, idx, pos);
      })
      .gesture(LongPressGesture({ duration: 500 }).onAction(() => {
        this.onItemLongPress(row, pos, idx);
      }))

      Divider()
        .color('#E7E7E7')
        .strokeWidth(0.5)
    }
    .width('100%')
  }

  /** 双栏右侧消息详情预览面板 */
  @Builder
  messageDetailPane() {
    Column() {
      if (this.selectedMsg === null) {
        Column() {
          EmptyView({ tipText: '请选择左侧消息查看详情' })
        }
        .width('100%')
        .height('100%')
      } else {
        Scroll() {
          Column({ space: 12 }) {
            Column({ space: 8 }) {
              Text(this.selectedMsg.TITLE)
                .fontSize(18)
                .fontWeight(FontWeight.Medium)
                .fontColor('#333333')
                .width('100%')
              if (this.selectedMsg.SENDBY !== '') {
                Text('发布人员：' + this.selectedMsg.SENDBY)
                  .fontSize(13)
                  .fontColor('#999999')
              }
              if (this.selectedMsg.SENDTIME !== '') {
                Text('发布日期：' + this.selectedMsg.SENDTIME)
                  .fontSize(13)
                  .fontColor('#999999')
              }
              Row() {
                Text('打开完整页面')
                  .fontSize(14)
                  .fontColor($r('app.color.white'))
                  .padding({ left: 18, right: 18, top: 9, bottom: 9 })
                  .borderRadius(6)
                  .backgroundColor('#1B68B7')
                  .hoverEffect(HoverEffect.Highlight)
                  .onClick(() => {
                    if (this.selectedMsg !== null) {
                      this.openMessageFullPage(this.selectedMsg);
                    }
                  })
              }
              .width('100%')
              .justifyContent(FlexAlign.End)
              .margin({ top: 4 })
            }
            .width('100%')
            .padding(16)
            .borderRadius(8)
            .backgroundColor($r('app.color.white'))
            .alignItems(HorizontalAlign.Start)

            if (this.detailLoading) {
              Column() {
                LoadingView()
              }
              .width('100%')
              .height(160)
              .backgroundColor($r('app.color.white'))
              .borderRadius(8)
            } else if (this.detailError !== '') {
              Column() {
                Text(this.detailError)
                  .fontSize(14)
                  .fontColor('#999999')
              }
              .width('100%')
              .padding(16)
              .backgroundColor($r('app.color.white'))
              .borderRadius(8)
              .alignItems(HorizontalAlign.Center)
            } else {
              Column() {
                Text(this.selectedMsgContent === '' ? '暂无正文内容，请点击上方按钮查看完整页面' : this.selectedMsgContent)
                  .fontSize(16)
                  .fontColor('#333333')
                  .lineHeight(24)
                  .width('100%')
              }
              .width('100%')
              .padding(16)
              .borderRadius(8)
              .backgroundColor($r('app.color.white'))
              .alignItems(HorizontalAlign.Start)
            }
          }
          .width('100%')
          .padding({ left: 16, right: 16, top: 16, bottom: Math.max(16, this.avoidAreaBottomVp) })
        }
        .width('100%')
        .height('100%')
        .scrollBar(BarState.Off)
        .align(Alignment.Top)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F2F2F2')
  }

  /** layout_message_popup_dialog.xml：三角(sanjiaoxing #434343) + 深灰菜单(#434343 r8) */
  @Builder
  popupOverlay() {
    Stack({ alignContent: Alignment.TopStart }) {
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor('#66000000')
        .onClick(() => {
          this.showPopup = false;
        })
      Column() {
        Row() {
          Blank().layoutWeight(1)
          if (this.popupFlags().showTriangle) {
            Column()
              .width(18)
              .height(18)
              .backgroundColor('#434343')
              .rotate({ angle: 45 })
              .margin({ right: 20 })
          }
        }
        .width(150)
        .height(18)
        Scroll() {
          Column() {
            if (this.popupFlags().showAllRead) {
              Text('全部已读')
                .fontSize(14)
                .fontColor($r('app.color.white'))
                .padding({ left: 16, right: 16, top: 10, bottom: 10 })
                .hoverEffect(HoverEffect.Highlight)
                .onClick(() => {
                  this.onPopupAllRead();
                })
            }
            if (this.popupFlags().showLine1) {
              Divider()
                .color($r('app.color.white'))
                .strokeWidth(0.5)
            }
            if (this.popupFlags().showAllDelete) {
              Text('全部删除')
                .fontSize(14)
                .fontColor($r('app.color.white'))
                .padding({ left: 16, right: 16, top: 10, bottom: 10 })
                .hoverEffect(HoverEffect.Highlight)
                .onClick(() => {
                  this.onPopupAllDelete();
                })
            }
            if (this.popupFlags().showLine2) {
              Divider()
                .color($r('app.color.white'))
                .strokeWidth(0.5)
            }
            if (this.popupFlags().showBatchDelete) {
              Text('批量删除')
                .fontSize(14)
                .fontColor($r('app.color.white'))
                .padding({ left: 16, right: 16, top: 10, bottom: 10 })
                .hoverEffect(HoverEffect.Highlight)
                .onClick(() => {
                  this.onPopupBatchDelete();
                })
            }
          }
          .backgroundColor('#434343')
          .borderRadius(8)
          .alignItems(HorizontalAlign.Start)
        }
        .scrollBar(BarState.Off)
        .constraintSize({
          maxWidth: BreakpointSystem.getDialogMaxWidth(this.currentBreakpoint, this.windowWidthVp),
          maxHeight: BreakpointSystem.getDialogMaxHeight(this.windowHeightVp)
        })
        .onClick(() => {
          // 拦截弹窗内点击
        })
      }
      .width('100%')
      .margin({ top: 45 })
      .padding({ right: Math.max(8, this.avoidAreaRightVp + 8) })
      .alignItems(HorizontalAlign.End)
    }
    .width('100%')
    .height('100%')
    .alignContent(Alignment.TopStart)
  }
}
