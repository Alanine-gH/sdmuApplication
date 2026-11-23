import { router } from '@kit.ArkUI';
import { ApiService } from '../network/ApiService';
import { ApiResponse } from '../model/ResponseModel';
import { TodoTabOA, OaTodoRow, OaTodoList, OaChannel } from '../model/OaTodoModel';
import { BusinessError } from '@kit.BasicServicesKit';
import { LoadingView } from '../components/LoadingView';
import { EmptyView } from '../components/EmptyView';
import { LoginSession } from '../network/LoginSession';
import { BreakpointSystem } from '../common/BreakpointSystem';

/**
 * 待阅事宜页 — 1:1 翻译原 APK TodoReadActivity.java(215行)：
 *
 * 【页面结构】与 TodoMainActivity 同布局 mobile_campus_oa_activity_todo_main.xml：
 *   toolbar 标题"待阅事宜"(T1 gVar.n) + 右搜索图标(mobile_campus_oa_search → e.a.C=TodoSearchActivity)
 *   + SlidingTabLayout(48vp) + ViewPager(TodoFragment.V1(tab.TYPE, tab.BPM_GZ))。
 *
 * 【数据流源码还原】
 *   1. onResume → N2() → P.V(...).A() → GET newTab → TodoTab[]（h1="newTab"，区别待办页的 tab）
 *   2. 首次 getTabCount()==0：TAB_NAME 建页签 + TodoFragment.V1(TYPE, BPM_GZ)；此后仅刷 TOTALNUM 角标
 *      （a.g → O2(i, TOTALNUM)：>0 showMsg，<=0 hideMsg）
 *   3. 每 tab = TodoFragment：GET list data={pageSize:"10", pageNum, rule:<tab.BPM_GZ>}
 *   4. 点击（TodoFragment.d）：appid!="ydbg" → toast"移动端暂不支持该流程，请移动到电脑端进行操作"；
 *      ydbg → 详情/编辑页（e.a.J）带 bundle{type, bean}（[W14] HAP 路由 → EditTodoDetailPage，
 *      APK 原链为 TodoDetailActivity(/todo/detail) → 编辑子页 EditTodoDetailActivity(/todo/edit)）
 *   5. 关注按钮/弹窗与 TodoPage 同源 TodoMainItemAdapter（schoolId==QNZY 且 type!=gz 才显示）
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
  currentnodeid: string;
  authorCn: string;
}

/** TodoFragment 每实例状态（m=pageNum、adapter datas、刷新状态） */
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
struct TodoReadPage {
  @State tabs: TodoTabOA[] = [];
  @State listStates: TabListState[] = [];
  @State currentTab: number = 0;
  @State tabsLoading: boolean = true;
  @State tabsFailed: boolean = false;
  @State channels: OaChannel[] = [];
  @State showChannelDialog: boolean = false;
  @StorageProp('currentBreakpoint') currentBreakpoint: string = 'sm';
  @StorageProp('windowWidthVp') windowWidthVp: number = 360;
  @StorageProp('windowHeightVp') windowHeightVp: number = 780;
  /** 关注弹窗待操作 docUnid（TodoFragment$a C0205a.f12352b） */
  private pendingDocUnid: string = '';

  onPageShow(): void {
    // 源码 TodoReadActivity.onResume → N2()（tab+角标）+ TodoFragment.U0()（m=1 重载列表）
    this.loadTabs();
  }

  // ===== TodoReadActivity.N2：GET newTab → 首次建页签 + 更新 TOTALNUM 角标 =====
  private loadTabs(): void {
    ApiService.getOaTodoNewTabs()
      .then((response: ApiResponse<TodoTabOA[]>) => {
        if (response.code === 1000) {
          // 网络层统一拦截（toast+清会话+跳登录），页面仅 return
          return;
        }
        if (response.code === 0 && response.data.length > 0) {
          this.applyTabs(response.data);
          this.reloadList(this.currentTab);
        } else {
          this.tabsFailed = response.code !== 0;
          if (response.code !== 0) {
            this.toast(response.message === '' ? '获取待阅分类失败' : response.message);
          }
          this.tabsLoading = false;
        }
      })
      .catch((error: BusinessError) => {
        ApiService.logError('TodoRead loadTabs fail: ' + error.message);
        this.tabsFailed = true;
        this.tabsLoading = false;
      });
  }

  /** 源码 a.g 回调：getTabCount()==0 时只建一次页签，此后仅刷 TOTALNUM */
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

  // ===== TodoFragment.U0：m=1 重载当前页列表 =====
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

  // ===== TodoFragment.c.a()：下拉刷新（m=1）=====
  private refreshList(idx: number): void {
    if (idx < 0 || idx >= this.tabs.length) {
      return;
    }
    const st: TabListState = new TabListState();
    st.rows = this.listStates[idx].rows;
    st.pageNum = 1;
    st.loaded = this.listStates[idx].loaded;
    st.hasMore = true;
    st.refreshing = true;
    st.loading = true;
    this.patchState(idx, st);
    this.fetchList(idx, 1, false);
  }

  // ===== TodoFragment.c.b()：上拉加载（m+1，rows>=10 才允许）=====
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
          // 网络层统一拦截，页面仅 return
          return;
        }
        if (response.code === 0) {
          this.handleListOk(idx, pageNum, isLoadMore, response.data);
        } else {
          this.handleListFail(idx, response.message);
        }
      })
      .catch((error: BusinessError) => {
        ApiService.logError('TodoRead fetchList fail: ' + error.message);
        this.handleListFail(idx, '网络异常，请稍后重试');
      });
  }

  /** 源码 b.g 成功回调：rows<10 停加载，>=10 允许下一页；空→空态 */
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

  /** 源码 b.f 失败回调：toast；有内容保持内容，无内容进错误态 */
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

  /** 源码 TodoFragment.U0：切到相邻 tab 触发重载（Swiper onChange 等价 Fragment onResume） */
  private ensureTabLoaded(idx: number): void {
    if (idx < 0 || idx >= this.tabs.length) {
      return;
    }
    const st: TabListState = this.listStates[idx];
    if (!st.loaded && !st.loading) {
      this.reloadList(idx);
    }
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

  // ===== 源码 d.onItemClick：appid!="ydbg" toast；否则详情页带 bundle{type, bean} =====
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
      nodeName: row.currentnodename,
      currentnodeid: row.currentnodeid,
      authorCn: row.author_cn
    };
    router.pushUrl({ url: 'pages/EditTodoDetailPage', params: params });
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
          if (response.code === 0) {
            // 源码 C0206a.g → f.a(14,null) EventBus → m=1 重载
            this.reloadList(this.currentTab);
          }
        })
        .catch((error: BusinessError) => {
          ApiService.logError('TodoRead deleteFollows fail: ' + error.message);
        });
      return;
    }
    ApiService.getOaTodoChannels()
      .then((response: ApiResponse<OaChannel[]>) => {
        if (response.code === 0 && response.data.length > 0) {
          this.pendingDocUnid = row.orUnid;
          this.channels = response.data;
          this.showChannelDialog = true;
        }
      })
      .catch((error: BusinessError) => {
        ApiService.logError('TodoRead messagesChannel fail: ' + error.message);
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
        if (response.code === 0) {
          this.toast('关注成功');
          this.reloadList(this.currentTab);
        } else {
          this.toast(response.message);
        }
      })
      .catch((error: BusinessError) => {
        ApiService.logError('TodoRead addFollows fail: ' + error.message);
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

  /** toolbar_normal：45vp 白底 + 44vp Toolbar（标题17fp 居中）+ 右搜索 marginR15 */
  @Builder
  topBar() {
    Column() {
      Row() {
        Blank().width(40)
        Text('待阅事宜')
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

  /** SlidingTabLayout：48vp 等分，14fp 选中#1B68B7 未选#999999，TOTALNUM 角标（O2 showMsg/hideMsg） */
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
      Scroll() {
        Column({ space: 12 }) {
          Text('请选择关注渠道')
            .fontSize(16)
            .fontColor($r('app.color.common_color_1'))
            .fontWeight(FontWeight.Bold)
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
              .hoverEffect(HoverEffect.Highlight)
              .onClick(() => {
                this.toggleChannel(idx);
              })
            }, (ch: OaChannel, idx: number) => idx.toString() + ch.terminalId)
          }
          .width('100%')
          Row({ space: 12 }) {
            Text('取消')
              .fontSize(15)
              .fontColor($r('app.color.common_color_3'))
              .textAlign(TextAlign.Center)
              .layoutWeight(1)
              .padding({ top: 10, bottom: 10 })
              .borderRadius(4)
              .backgroundColor($r('app.color.common_color_6'))
              .hoverEffect(HoverEffect.Highlight)
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
              .hoverEffect(HoverEffect.Highlight)
              .onClick(() => {
                this.onChannelsConfirmed();
              })
          }
          .width('100%')
        }
        .padding(16)
        .width('100%')
      }
      .scrollBar(BarState.Off)
      .backgroundColor($r('app.color.white'))
      .borderRadius(8)
      .width(BreakpointSystem.getDialogMaxWidth(this.currentBreakpoint, this.windowWidthVp))
      .constraintSize({ maxHeight: BreakpointSystem.getDialogMaxHeight(this.windowHeightVp) })
      .onClick(() => {
        // 拦截弹窗内点击
      })
    }
    .width('100%')
    .height('100%')
    .padding({ left: 16, right: 16 })
    .backgroundColor('#66000000')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .onClick(() => {
      this.showChannelDialog = false;
    })
  }
}
