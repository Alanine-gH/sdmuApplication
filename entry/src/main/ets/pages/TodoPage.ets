import { router } from '@kit.ArkUI';
import { ApiService } from '../network/ApiService';
import { ApiResponse } from '../model/ResponseModel';
import { TodoTabOA, OaTodoRow, OaTodoList, OaChannel } from '../model/OaTodoModel';
import { BusinessError } from '@kit.BasicServicesKit';
import { LoadingView } from '../components/LoadingView';
import { EmptyView } from '../components/EmptyView';
import { LoginSession } from '../network/LoginSession';

/**
 * OA 待办页 — 1:1 翻译原 APK TodoMainActivity.java(233行) + TodoFragment.java(391行)：
 *
 * 【页面结构】mobile_campus_oa_activity_todo_main.xml：
 *   toolbar_normal(45vp: 标题"待办事项"17fp + 右搜索图标 marginR15 → TodoSearchActivity)
 *   + 灰条 px_to_dip_23=11.5vp #F2F2F2 + SlidingTabLayout(48vp 等分/字14fp
 *     选中#1B68B7 未选#999999/indicator 高2vp 宽=标题字宽) + ViewPager(=Swiper)
 *   每个 tab = TodoFragment：mobile_campus_oa_fragment_todo.xml → common_refresh_lv_rl
 *   （PullToRefreshLayout + ListView），列表项 mobile_campus_oa_view_todo_item.xml：
 *   padL 11.5vp 高72vp（内 69.5vp padT8 padR12）+ 标题 17fp #333 + 关注钮 12fp #FF6C6C 描边
 *   （schoolId==QNZY 且 type!=gz 才显示）+ 第二行 mT12：申请人 13fp #999 maxLength10
 *   + 缓级徽标 12fp 白底色块 32×16vp + 时间 13fp #999 + 底分隔线 0.5。
 *
 * 【数据流源码还原】（TodoModel.java/TodoPImpl.java/TodoFactory.java）
 *   1. onResume → O2() → P.V(...).z() → GET tab → TodoTab[]：TAB_NAME 建页签
 *      （getTabCount()==0 只建一次），TOTALNUM>0 显示角标（Q2 showMsg/hideMsg）
 *   2. TodoFragment.V1(TYPE, BPM_GZ)：k=BPM_GZ(请求 rule 参数) l=TYPE(点击分流)
 *   3. U1(loadMore) → P.S(...).B(k, pageNum) → GET list
 *      data={pageSize:"10"(AgooConstants.ACK_REMOVE_PACKAGE), pageNum, rule:<BPM_GZ>}
 *      ← com.heytap.mcssdk.constant.b.p="rule"；rows<10 停止加载更多，>=10 下一页
 *   4. rows 全字段 TodoUtils.o 反射 unescapeHtml3（ApiService.parseOaTodoRow 已实现）
 *   5. 点击：appid!="ydbg" → toast"移动端暂不支持该流程，请移动到电脑端进行操作"；
 *      ydbg → 详情页(bundle type+bean)；db 类型返回后刷新（onActivityResult 1568）
 *   6. 关注：followStatus=1 → deleteFollows{docUnids}；否则 GET messagesChannel
 *      → 渠道选择弹窗 → 选中 terminalId 逗号拼接 → addFollows{docUnids,channels}
 *      → toast"关注成功" + EventBus 14 → 刷新本页
 */
interface TodoNavParams {
  type: string;
  docUnid: string;
  processId: string;
  subject: string;
  hj: string;
  startTime: string;
  addName: string;
  nodeName: string;
}

/** TodoFragment 每实例状态（m=pageNum、j=adapter datas、PullToRefresh 状态） */
class TabListState {
  rows: OaTodoRow[] = [];
  pageNum: number = 1;
  hasMore: boolean = true;
  loading: boolean = false;
  loaded: boolean = false;
  refreshing: boolean = false;
  errMsg: string = '';
}

@Entry
@Component
struct TodoPage {
  @State tabs: TodoTabOA[] = [];
  @State listStates: TabListState[] = [];
  @State currentTab: number = 0;
  @State tabsLoading: boolean = true;
  @State tabsFailed: boolean = false;
  @State channels: OaChannel[] = [];
  @State showChannelDialog: boolean = false;
  /** 关注弹窗待操作 docUnid（C0205a.f12352b） */
  private pendingDocUnid: string = '';

  onPageShow(): void {
    // 源码 TodoMainActivity.onResume→O2()（tab+角标）+ TodoFragment.U0()（m=1 重载列表）
    this.loadTabs();
  }

  // ===== TodoMainActivity.O2：GET tab → 建页签（首次）+ 更新 TOTALNUM 角标 =====
  private loadTabs(): void {
    ApiService.getOaTodoTabs()
      .then((response: ApiResponse<TodoTabOA[]>) => {
        if (response.code === 1000) {
          this.onSessionExpired();
          return;
        }
        if (response.code === 0 && response.data.length > 0) {
          this.applyTabs(response.data);
          this.reloadList(this.currentTab);
        } else {
          this.tabsFailed = response.code !== 0;
          if (response.code !== 0) {
            this.toast(response.message === '' ? '获取待办分类失败' : response.message);
          }
          this.tabsLoading = false;
        }
      })
      .catch((error: BusinessError) => {
        ApiService.logError('Todo loadTabs fail: ' + error.message);
        this.tabsFailed = true;
        this.tabsLoading = false;
      });
  }

  /** 源码 g 回调：getTabCount()==0 时只建一次页签，此后仅刷 TOTALNUM */
  private applyTabs(data: TodoTabOA[]): void {
    if (this.tabs.length === 0) {
      const states: TabListState[] = [];
      for (const tab of data) {
        states.push(new TabListState());
      }
      this.listStates = states;
      this.tabs = data;
      this.tabsLoading = false;
      this.tabsFailed = false;
      return;
    }
    const merged: TodoTabOA[] = this.tabs.slice();
    for (let i = 0; i < merged.length && i < data.length; i++) {
      merged[i].TOTALNUM = data[i].TOTALNUM;
    }
    this.tabs = merged;
  }

  // ===== TodoFragment.U0/onActivityResult：m=1 重载当前页列表 =====
  private reloadList(idx: number): void {
    if (idx < 0 || idx >= this.tabs.length) {
      return;
    }
    const st: TabListState = new TabListState();
    st.loading = true;
    st.loaded = false;
    st.hasMore = true;
    this.patchState(idx, st);
    this.fetchList(idx, 1, false);
  }

  // ===== TodoFragment.c.b()：下拉刷新（m=1，可上拉）=====
  private refreshList(idx: number): void {
    if (idx < 0 || idx >= this.tabs.length) {
      return;
    }
    const prev: TabListState = this.listStates[idx];
    const st: TabListState = new TabListState();
    st.rows = prev.rows;
    st.pageNum = 1;
    st.loaded = prev.loaded;
    st.hasMore = true;
    st.refreshing = true;
    st.loading = true;
    this.patchState(idx, st);
    this.fetchList(idx, 1, false);
  }

  // ===== TodoFragment.c.a() + f.setPullUpToLoadEnable：上拉加载（m+1）=====
  private loadMoreList(idx: number): void {
    if (idx < 0 || idx >= this.tabs.length) {
      return;
    }
    const prev: TabListState = this.listStates[idx];
    if (!prev.hasMore || prev.loading || !prev.loaded) {
      return;
    }
    const st: TabListState = new TabListState();
    st.rows = prev.rows;
    st.pageNum = prev.pageNum;
    st.loaded = prev.loaded;
    st.hasMore = prev.hasMore;
    st.loading = true;
    this.patchState(idx, st);
    this.fetchList(idx, prev.pageNum + 1, true);
  }

  /** TodoFragment.U1 → P.S(cb).B(rule, pageNum) → GET list（加密 data= 参数） */
  private fetchList(idx: number, pageNum: number, isLoadMore: boolean): void {
    const rule: string = this.tabs[idx].BPM_GZ;
    ApiService.getOaTodoList(rule, pageNum)
      .then((response: ApiResponse<OaTodoList>) => {
        if (response.code === 1000) {
          this.patchState(idx, this.idleState(this.listStates[idx]));
          this.onSessionExpired();
          return;
        }
        if (response.code === 0) {
          this.handleListOk(idx, pageNum, isLoadMore, response.data);
        } else {
          this.handleListFail(idx, response.message);
        }
      })
      .catch((error: BusinessError) => {
        ApiService.logError('Todo fetchList fail: ' + error.message);
        this.handleListFail(idx, '网络异常，请稍后重试');
      });
  }

  /** 源码 b.g() 成功回调：rows<10 停加载，>=10 允许下一页；空→空态 */
  private handleListOk(idx: number, pageNum: number, isLoadMore: boolean, data: OaTodoList): void {
    const prev: TabListState = this.listStates[idx];
    const st: TabListState = new TabListState();
    st.pageNum = pageNum;
    st.loaded = true;
    st.loading = false;
    st.refreshing = false;
    const fresh: OaTodoRow[] = data.rows;
    st.rows = isLoadMore ? prev.rows.concat(fresh) : fresh;
    st.hasMore = fresh.length >= 10;
    st.errMsg = '';
    this.patchState(idx, st);
  }

  /** 源码 b.f() 失败回调：toast；有内容保持内容，无内容进错误/空态 */
  private handleListFail(idx: number, message: string): void {
    const prev: TabListState = this.listStates[idx];
    const st: TabListState = new TabListState();
    st.rows = prev.rows;
    st.pageNum = prev.pageNum;
    st.hasMore = prev.hasMore && prev.rows.length > 0;
    st.loaded = prev.loaded || prev.rows.length === 0;
    st.loading = false;
    st.refreshing = false;
    st.errMsg = message === '' ? '加载失败' : message;
    this.patchState(idx, st);
    this.toast(st.errMsg);
  }

  /** 源码 TodoFragment.U0：m=1 重载列表（原版 ViewPager offscreenPageLimit=1，切到相邻 tab
   *  时 Fragment 自动 onResume 触发；Swiper 需在 onChange 里补齐同等行为） */
  private ensureTabLoaded(idx: number): void {
    if (idx < 0 || idx >= this.tabs.length) {
      return;
    }
    const st: TabListState = this.listStates[idx];
    if (!st.loaded && !st.loading) {
      this.reloadList(idx);
    }
  }

  private idleState(prev: TabListState): TabListState {
    const st: TabListState = new TabListState();
    st.rows = prev.rows;
    st.pageNum = prev.pageNum;
    st.hasMore = prev.hasMore;
    st.loaded = prev.loaded;
    st.errMsg = prev.errMsg;
    return st;
  }

  private patchState(idx: number, st: TabListState): void {
    const copy: TabListState[] = this.listStates.slice();
    copy[idx] = st;
    this.listStates = copy;
  }

  // ===== 源码 m(str)：Toast =====
  private toast(message: string): void {
    if (message === '') {
      return;
    }
    this.getUIContext().getPromptAction().showToast({ message: message });
  }

  /** 源码 code=1000 →"登录已失效，请重新登录" + 跳登录页（PersonalDetailPage 同款） */
  private onSessionExpired(): void {
    this.getUIContext().getPromptAction().showToast({ message: '登录已失效，请重新登录' });
    router.replaceUrl({ url: 'pages/LoginPage' });
  }

  // ===== 源码 d.onItemClick：appid!="ydbg" toast；否则详情页（db 带返回刷新）=====
  private onRowClick(row: OaTodoRow, type: string): void {
    if (row.appid === '' || row.appid !== 'ydbg') {
      this.toast('移动端暂不支持该流程，请移动到电脑端进行操作');
      return;
    }
    const params: TodoNavParams = {
      type: type,
      docUnid: row.orUnid,
      processId: row.processId,
      subject: row.subject,
      hj: row.hj,
      startTime: row.startTime,
      addName: row.addName_cn,
      nodeName: row.currentnodename
    };
    router.pushUrl({ url: 'pages/TodoReadPage', params: params });
  }

  // ===== 源码 a.a(int)→g 确认框："是否取消关注？/是否添加关注？" =====
  private onAttentionClick(row: OaTodoRow): void {
    const confirmText: string = row.followStatus === '1' ? '是否取消关注？' : '是否添加关注？';
    AlertDialog.show({
      message: confirmText,
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
          this.onFollowConfirmed(row);
        }
      }
    });
  }

  /** 源码 C0205a.a()：followStatus=1 → deleteFollows；否则 messagesChannel 弹窗 */
  private onFollowConfirmed(row: OaTodoRow): void {
    if (row.followStatus === '1') {
      ApiService.deleteOaFollows(row.orUnid)
        .then((response: ApiResponse<Object>) => {
          if (response.code === 1000) {
            this.onSessionExpired();
            return;
          }
          if (response.code === 0) {
            // 源码 C0206a.g → f.a(14,null) EventBus → m=1 重载
            this.reloadList(this.currentTab);
          }
        })
        .catch((error: BusinessError) => {
          ApiService.logError('Todo deleteFollows fail: ' + error.message);
        });
      return;
    }
    ApiService.getOaTodoChannels()
      .then((response: ApiResponse<OaChannel[]>) => {
        if (response.code === 1000) {
          this.onSessionExpired();
          return;
        }
        if (response.code === 0 && response.data.length > 0) {
          this.pendingDocUnid = row.orUnid;
          this.channels = response.data;
          this.showChannelDialog = true;
        }
      })
      .catch((error: BusinessError) => {
        ApiService.logError('Todo messagesChannel fail: ' + error.message);
      });
  }

  /** 源码 C0207a.a(list)：选中 terminalId 逗号拼接 → addFollows → "关注成功"+刷新 */
  private onChannelsConfirmed(): void {
    let joined: string = '';
    for (const ch of this.channels) {
      if (ch.isSelect) {
        joined = joined + ch.terminalId + ',';
      }
    }
    if (joined.length > 0) {
      joined = joined.substring(0, joined.length - 1);
    }
    this.showChannelDialog = false;
    if (joined === '') {
      return;
    }
    ApiService.addOaFollows(this.pendingDocUnid, joined)
      .then((response: ApiResponse<Object>) => {
        if (response.code === 1000) {
          this.onSessionExpired();
          return;
        }
        if (response.code === 0) {
          this.toast('关注成功');
          this.reloadList(this.currentTab);
        } else {
          this.toast(response.message);
        }
      })
      .catch((error: BusinessError) => {
        ApiService.logError('Todo addFollows fail: ' + error.message);
      });
  }

  private toggleChannel(idx: number): void {
    const copy: OaChannel[] = this.channels.slice();
    const one: OaChannel = new OaChannel();
    one.terminalId = copy[idx].terminalId;
    one.terminalName = copy[idx].terminalName;
    one.isSelect = !copy[idx].isSelect;
    copy[idx] = one;
    this.channels = copy;
  }

  build() {
    Stack() {
      Column() {
        this.topBar()
        // 灰条 px_to_dip_23=11.5vp #fff2f2f2（activity_todo_main line5）
        Row()
          .width('100%')
          .height(11.5)
          .backgroundColor($r('app.color.common_color_6'))
        if (this.tabsLoading) {
          LoadingView()
        } else if (this.tabsFailed && this.tabs.length === 0) {
          // MultiStateView 错误态（a.e → t0 ERROR_NETWORK）→ 点击重试
          Column() {
            EmptyView({ tipText: '加载失败，点击重试' })
          }
          .width('100%')
          .layoutWeight(1)
          .onClick(() => {
            this.tabsLoading = true;
            this.tabsFailed = false;
            this.loadTabs();
          })
        } else {
          Column() {
            this.tabBar()
            this.swiperArea()
          }
          .width('100%')
          .layoutWeight(1)
        }
      }
      .width('100%')
      .height('100%')
      .backgroundColor($r('app.color.white'))
      if (this.showChannelDialog) {
        this.channelDialogOverlay()
      }
    }
    .width('100%')
    .height('100%')
  }

  /** toolbar_normal：45vp 白底 + 44vp Toolbar（标题17fp 居中 maxLength18）+ 右搜索 marginR15 */
  @Builder
  topBar() {
    Column() {
      Row() {
        Blank().width(40)
        Text('待办事项')
          .fontSize(17)
          .fontColor($r('app.color.common_color_1'))
          .textAlign(TextAlign.Center)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .margin({ left: 5, right: 5 })
          .layoutWeight(1)
        Image($r('app.media.mobile_campus_oa_search'))
          .width(25)
          .height(25)
          .margin({ right: 15 })
          .onClick(() => {
            // 源码 c.onClick → g2(activity, e.a.C) = TodoSearchActivity
            router.pushUrl({ url: 'pages/TodoSearchPage' });
          })
      }
      .width('100%')
      .height(44)
      .alignItems(VerticalAlign.Center)
      .backgroundColor($r('app.color.main_bg'))
      Divider()
        .color($r('app.color.common_color_5'))
        .strokeWidth(0.5)
        .width('100%')
    }
    .width('100%')
    .height(45)
    .backgroundColor($r('app.color.main_bg'))
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP])
  }

  /** SlidingTabLayout：48vp 等分 tab，14fp 选中#1B68B7 未选#999999，indicator 2vp 宽=字宽，TOTALNUM 角标 */
  @Builder
  tabBar() {
    Row() {
      ForEach(this.tabs, (tab: TodoTabOA, idx: number) => {
        Column() {
          Stack({ alignContent: Alignment.TopEnd }) {
            Text(tab.TAB_NAME)
              .fontSize(14)
              .fontColor(this.currentTab === idx ? $r('app.color.mobile_campus_primary_color_default') :
                $r('app.color.common_color_3'))
              .maxLines(1)
            if (tab.TOTALNUM > 0) {
              Text(tab.TOTALNUM > 99 ? '99+' : tab.TOTALNUM.toString())
                .fontSize(10)
                .fontColor($r('app.color.white'))
                .backgroundColor('#FF2D2D')
                .borderRadius(8)
                .padding({ left: 4, right: 4, top: 1, bottom: 1 })
                .margin({ left: -6, top: -6 })
            }
          }
          // tl_indicator_width_equal_title=true：指示条宽度=标题文字宽度（wrap 容器 100%）
          Row()
            .width('100%')
            .height(2)
            .borderRadius(1)
            .backgroundColor(this.currentTab === idx ? $r('app.color.mobile_campus_primary_color_default') :
              Color.Transparent)
            .margin({ top: 4 })
        }
        .alignItems(HorizontalAlign.Center)
        .justifyContent(FlexAlign.Center)
        .layoutWeight(1)
        .onClick(() => {
          this.currentTab = idx;
        })
      }, (tab: TodoTabOA, idx: number) => idx.toString() + tab.TAB_NAME)
    }
    .width('100%')
    .height(48)
    .backgroundColor($r('app.color.white'))
  }

  /** ViewPager → Swiper，每页 = TodoFragment 列表 */
  @Builder
  swiperArea() {
    Swiper() {
      ForEach(this.tabs, (tab: TodoTabOA, idx: number) => {
        Column() {
          if (this.listStates.length === this.tabs.length) {
            this.tabListPage(idx)
          }
        }
        .width('100%')
        .height('100%')
      }, (tab: TodoTabOA, idx: number) => idx.toString() + tab.TAB_NAME)
    }
    .index(this.currentTab)
    .loop(false)
    .indicator(false)
    .onChange((idx: number) => {
      this.currentTab = idx;
      this.ensureTabLoaded(idx);
    })
    .layoutWeight(1)
  }

  /** TodoFragment 视图：PullToRefreshLayout + ListView（空态/错误态/加载更多） */
  @Builder
  tabListPage(idx: number) {
    Refresh({
      refreshing: this.listStates[idx].refreshing
    }) {
      if (!this.listStates[idx].loaded && this.listStates[idx].loading) {
        LoadingView()
      } else if (this.listStates[idx].rows.length === 0) {
        // MultiStateView 空态（b.g 空列表 → B1）/ 失败态（b.f → -3010 网络错误/D1）
        Column() {
          EmptyView({ tipText: this.listStates[idx].errMsg === '' ? '暂无数据' : this.listStates[idx].errMsg })
        }
        .width('100%')
        .height('100%')
        .onClick(() => {
          this.reloadList(idx);
        })
      } else {
        List({ space: 0 }) {
          ForEach(this.listStates[idx].rows, (row: OaTodoRow) => {
            ListItem() {
              this.todoItem(row, this.tabs[idx].TYPE)
            }
          }, (row: OaTodoRow, inner: number) => idx.toString() + '-' + inner.toString() + '-' + row.orUnid)
        }
        .width('100%')
        .height('100%')
        .backgroundColor($r('app.color.white'))
        .scrollBar(BarState.Off)
        .edgeEffect(EdgeEffect.Spring)
        .onReachEnd(() => {
          this.loadMoreList(idx);
        })
      }
    }
    .width('100%')
    .height('100%')
    .onRefreshing(() => {
      this.refreshList(idx);
    })
  }

  /** mobile_campus_oa_view_todo_item.xml 逐行：padL11.5 高72（内69.5 padT8 padR12） */
  @Builder
  todoItem(row: OaTodoRow, type: string) {
    Column() {
      Column() {
        Row() {
          Text(row.subject)
            .fontSize(17)
            .fontColor($r('app.color.common_color_1'))
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .layoutWeight(1)
          // tvAttention：schoolId=QNZY 且 type!=gz 才显示（TodoMainItemAdapter.getView）
          if (LoginSession.schoolId === 'QNZY' && type !== 'gz') {
            Text(row.followStatus === '1' ? '取消关注' : '关注')
              .fontSize(12)
              .fontColor('#FF6C6C')
              .border({ width: 1, color: '#FF6C6C' })
              .borderRadius(3)
              .padding({ left: 5, right: 5, top: 3, bottom: 3 })
              .margin({ left: 10 })
              .onClick(() => {
                this.onAttentionClick(row);
              })
          }
        }
        .width('100%')
        .alignItems(VerticalAlign.Center)
        Row() {
          Text(this.applyText(row))
            .fontSize(13)
            .fontColor($r('app.color.common_color_3'))
            .maxLines(1)
            .flexShrink(0)
          Blank().layoutWeight(1)
          this.hjBadge(row.hj)
          Text(row.startTime)
            .fontSize(13)
            .fontColor($r('app.color.common_color_3'))
            .maxLines(1)
            .margin({ left: 5 })
            .flexShrink(0)
        }
        .width('100%')
        .margin({ top: 12 })
        .alignItems(VerticalAlign.Center)
      }
      .width('100%')
      .height(69.5)
      .padding({ top: 8, right: 12 })
      Divider()
        .color($r('app.color.common_color_5'))
        .strokeWidth(0.5)
        .width('100%')
    }
    .width('100%')
    .height(72)
    .padding({ left: 11.5 })
    .backgroundColor($r('app.color.white'))
    .onClick(() => {
      this.onRowClick(row, type);
    })
  }

  /** tvApply："申请人："+addName_cn，android:maxLength=10 截断 */
  private applyText(row: OaTodoRow): string {
    const full: string = '申请人：' + row.addName_cn;
    return full.length > 10 ? full.substring(0, 10) : full;
  }

  /** setHJ：一般/空 → gone；加急#FFC231 平急#82DC4B 急件#1B68B7 特急#ED874A 特提#FF6C6C（64×32px） */
  @Builder
  hjBadge(hj: string) {
    if (hj === '加急' || hj === '平急' || hj === '急件' || hj === '特急' || hj === '特提') {
      Text(hj)
        .fontSize(12)
        .fontColor($r('app.color.white'))
        .textAlign(TextAlign.Center)
        .width(32)
        .height(16)
        .backgroundColor(this.hjColor(hj))
        .margin({ right: 5 })
        .flexShrink(0)
    }
  }

  private hjColor(hj: string): string {
    if (hj === '加急') {
      return '#FFC231';
    }
    if (hj === '平急') {
      return '#82DC4B';
    }
    if (hj === '急件') {
      return '#1B68B7';
    }
    if (hj === '特急') {
      return '#ED874A';
    }
    return '#FF6C6C';
  }

  /** MessageChannelSelectDialog 复刻（全屏遮罩 + 白色面板 + 渠道复选 + 取消/确认） */
  @Builder
  channelDialogOverlay() {
    Column() {
      Column({ space: 12 }) {
        Text('请选择关注渠道')
          .fontSize(16)
          .fontColor($r('app.color.common_color_1'))
          .fontWeight(FontWeight.Bold)
        Scroll() {
          Column({ space: 8 }) {
            ForEach(this.channels, (ch: OaChannel, idx: number) => {
              Row() {
                Image(ch.isSelect ? $r('app.media.mobile_campus_oa_selected') :
                  $r('app.media.mobile_campus_oa_uncheck'))
                  .width(18)
                  .height(18)
                Text(ch.terminalName)
                  .fontSize(14)
                  .fontColor($r('app.color.common_color_1'))
                  .margin({ left: 8 })
                  .layoutWeight(1)
              }
              .width('100%')
              .padding({ top: 6, bottom: 6 })
              .onClick(() => {
                this.toggleChannel(idx);
              })
            }, (ch: OaChannel, idx: number) => idx.toString() + ch.terminalId)
          }
          .width('100%')
        }
        .layoutWeight(1)
        .align(Alignment.Top)
        Row({ space: 12 }) {
          Text('取消')
            .fontSize(15)
            .fontColor($r('app.color.common_color_3'))
            .textAlign(TextAlign.Center)
            .layoutWeight(1)
            .padding({ top: 10, bottom: 10 })
            .borderRadius(4)
            .backgroundColor($r('app.color.common_color_6'))
            .onClick(() => {
              this.showChannelDialog = false;
            })
          Text('确定')
            .fontSize(15)
            .fontColor($r('app.color.white'))
            .textAlign(TextAlign.Center)
            .layoutWeight(1)
            .padding({ top: 10, bottom: 10 })
            .borderRadius(4)
            .backgroundColor($r('app.color.mobile_campus_primary_color_default'))
            .onClick(() => {
              this.onChannelsConfirmed();
            })
        }
        .width('100%')
      }
      .padding(16)
      .backgroundColor($r('app.color.white'))
      .borderRadius(8)
      .width('80%')
      .height(320)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#80000000')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }
}
