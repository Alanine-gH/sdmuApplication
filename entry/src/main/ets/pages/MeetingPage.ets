import { router } from '@kit.ArkUI';
import { ApiService } from '../network/ApiService';
import { ApiResponse } from '../model/ResponseModel';
import { BusinessError } from '@kit.BasicServicesKit';
import { TitleBar } from '../components/TitleBar';
import { EmptyView } from '../components/EmptyView';
import { LoadingView } from '../components/LoadingView';
import { LoginSession } from '../network/LoginSession';
import { MeetingTabEntity, JoinListEntity, JoinListItem, WeekPlanEntity,
  CurrentDayEntity, TermParamsEntity, CalendarItemEntity, MeetingObjEntity,
  MeetingWeekDetailEntity } from '../model/MeetingApiModel';
import { AdaptiveLayoutHelper, SplitPaneConfig } from '../common/AdaptiveLayoutHelper';

/**
 * 会议页 — 源码逐行翻译（禁止看图猜；每个 UI 结构标注来源 XML）
 *
 * 【源码链路】MeetingActivity.java(33行) f1() → g2(this, a.Z, null) → RouteConstant.Z =
 *   R.string.mobile_campus_meeting_main = "/meeting/main" → MeetingMainActivity（会议主页，TabLayout+ViewPager）
 *   ├─ MeetingArrangementFragment（"我的会议"页签）
 *   └─ MeetingWeekPlanFragment（"周程会议"页签）
 * 本页 = MeetingActivity 转发目标 + MeetingMainActivity + 两 Fragment 的完整翻译。
 *
 * 【布局】mobile_campus_meeting_activity.xml：竖向 LinearLayout bg #F2F2F2 + toolbar_normal
 *   （标题 R.string.mobile_campus_meeting_main_title="会议安排"）+ 白底 TabLayout 48dip
 *   （tabGravity center / tabIndicator 2dip primary / 选中 primary / 未选 common_color_3）
 *   + ViewPager。页签文案 FragmentPagerAdapter.f11906a = {"我的会议","周程会议"}（标题 margins 37dp）。
 *
 * 【我的会议】MeetingArrangementFragment.java(263行) + adapter/a.java(MeetingArrangementAdapter 268行)
 *   - onResume → V1() → MeetingPImpl.C() → MeetingModel.b1：GET getJoinList（无参）→ JoinList[]
 *     组头 = JoinList{NAME,TYPE,DATA[]}；TYPE="past" 的组可折叠（adapter.f11777b 初始 true=收起，
 *     组头"展开"+open 图标；展开后"收起"+close 图标）。
 *   - 上拉 = W1() → MeetingPImpl.G(page) → MeetingModel.f1：GET getPastList {currentPage,pageSize:"20"}
 *     → JoinList.DATABean[]，追加到第 2 组（adapter.a(list)：getGroup(1).DATA.addAll）；
 *     每页满 20 条 → k++ 继续，否则 l=false 停用上拉（X1() 要求未收起且 l）。
 *   - 空态判定（b.b）：所有组孩子数=0 → CampusPage.EMPTY_MEETING；否则内容。
 *   - 子项布局 mobile_campus_meeting_view_main_child.xml / 组头 mobile_campus_meeting_view_main_group.xml。
 *   - 子项点击（d.onChildClick）：TASK_TYPE!="weekPlan" → 详情(b0=meeting_detail)；
 *     ="weekPlan" → 周程详情(a0=meeting_weekdetail)，bundle {xlh,TASK_TYPE[,IS_JOIN]}。
 *   - 右下 imgAdd → c0=meeting_create（AddMeetingActivity）。
 *
 * 【周程会议】MeetingWeekPlanFragment.java(234行) + widget/g.java(MeetingWeekLayout 111行)
 *   - f1：k.k(当日)（header 日期/星期）+ 列表 adapter。
 *   - a2() → SchedulePImpl.e → ScheduleModel.T0：POST getCurrentOrWeek {} → CurrentDay{date,week,xqj}；
 *     回调：o=week, p=date → k.k(p) + k.p(o="第N周") → b2()。
 *   - b2() → SchedulePImpl.f → ScheduleModel.U0：GET termInfoForTeacher → TermParamsEntity；
 *     回调：l=e(term,今日) 当前周；o=l；n=0；k.p(o)；c2("0")；k.n(l-1)（周翻页定位）。
 *   - c2(n) → MeetingPImpl.J → MeetingModel.h1：GET getWeekPlan {week:n} → WeekPlan[]；
 *     空 → EMPTY_MEETING，否则 setData。
 *   - 周翻页 onPageSelected(i)：l=i+1，若变化 → n=l-o，c2(String(n)) 重新拉该周。
 *   - 周视图 mobile_campus_meeting_weekdate_layout.xml：schedule_date_tv "yyyy年M月d日"（16fp #B2BDC9）
 *     + schedule_today_tv "星期X"（16fp #B2BDC9 marginLeft 20）+ schedule_week_tv "第N周"（16fp 主色）；
 *     星期表头 13fp（首尾 #B2BDC9、其余 #333）；MeetingWeekPager 44dip：7 个 DateView（30dip 圆，
 *     首尾 commonColor=#B2BDC9、其余 #5F5F5F；选中红圆 #E96161 白字）。SDGY 学校周一开头（一~日）。
 *
 * 【数据规则】禁止 mock；失败空态；UI 不直接发 HTTP（全部走 ApiService.bizJson 管道）。
 */

/** 页签条目（源码 FragmentPagerAdapter：{id 虚拟序号, name}） */
interface MeetingTabEntry {
  id: number;
  name: string;
}

/** 源码 MeetingPImpl.G：f1(str, "20", cb) —— 每页条数硬编码 20 */
const MEETING_PAGE_SIZE: string = '20';
const DAY_MS: number = 86400000;
const WEEK_MS: number = 604800000;

@Entry
@Component
struct MeetingPage {
  // ===== 页签（MeetingMainActivity：L2 getMeetTab → M2 建 Fragment）=====
  @State meetTabLoading: boolean = true;
  @State tabEntries: MeetingTabEntry[] = [];
  @State activeTab: number = 0;
  @State showMyTab: boolean = false;
  @State showWeekTab: boolean = false;
  private hasShownOnce: boolean = false;

  // ===== 我的会议（MeetingArrangementFragment + MeetingArrangementAdapter）=====
  @State myLoading: boolean = true;
  @State myGroups: JoinListEntity[] = [];
  @State myPastCollapsed: boolean = true; // adapter.f11777b 初始 true（past 组收起）
  @State myLoadingMore: boolean = false;
  private myPage: number = 2;        // 源码 k 初始 2（第一页数据随 getJoinList 返回）
  private myHasMore: boolean = true; // 源码 l 初始 true

  // ===== 周程会议（MeetingWeekPlanFragment + MeetingWeekLayout）=====
  @State weekLoading: boolean = true;
  @State weekPlans: WeekPlanEntity[] = [];
  @State weekDateText: string = '';   // schedule_date_tv
  @State weekDayText: string = '';    // schedule_today_tv
  @State weekNumText: string = '';    // schedule_week_tv
  @State weekWeekLabels: string[] = ['日', '一', '二', '三', '四', '五', '六'];
  @State weekPages: CalendarItemEntity[][] = [];
  @State weekPagerIndex: number = 0;
  @State weekSelectedDate: string = ''; // WeekPagerAdapter.f（选中日期，仅视觉）
  @State selectedMeetingItem: JoinListItem | null = null;
  @State selectedWeekPlan: WeekPlanEntity | null = null;
  @State selectedMeetingObj: MeetingObjEntity | null = null;
  @State selectedWeekDetail: MeetingWeekDetailEntity | null = null;
  @State detailLoading: boolean = false;
  @State detailError: string = '';
  @StorageProp('currentBreakpoint') currentBreakpoint: string = 'sm';
  @StorageProp('windowWidthVp') windowWidthVp: number = 360;
  @StorageProp('avoidAreaLeftVp') avoidAreaLeftVp: number = 0;
  @StorageProp('avoidAreaRightVp') avoidAreaRightVp: number = 0;
  @StorageProp('avoidAreaBottomVp') avoidAreaBottomVp: number = 0;
  private weekDisplayWeek: number = 0;  // 源码 l（当前展示周）
  private weekCurrentWeek: number = 0;  // 源码 o（当前周）

  aboutToAppear(): void {
    // 源码 MeetingWeekPlanFragment.f1：gVar.k(f.b.f(new Date(), "")) 先以今日初始化日期头
    const todayText: string = MeetingPage.ymdOf(new Date());
    this.weekSelectedDate = todayText;
    this.applyHeaderDate(todayText);
    this.loadMeetTab();
  }

  /** 源码 MeetingArrangementFragment.onResume → V1()：每次回到页面重拉 getJoinList（首次由 meetTab 回调触发） */
  onPageShow(): void {
    if (!this.hasShownOnce) {
      this.hasShownOnce = true;
      return;
    }
    if (!this.meetTabLoading && this.showMyTab) {
      this.loadJoinList();
    }
  }

  /** 源码 MeetingMainActivity.L2 → MeetingPImpl.F → MeetingModel.d1：GET getMeetTab */
  private loadMeetTab(): void {
    ApiService.getMeetingTab()
      .then((response: ApiResponse<MeetingTabEntity>) => {
        if (response.code === 1000) {
          // 登录失效统一处理已在网络层触发（HttpClient.bizRequest 拦截：清会话+toast+跳登录）
          this.meetTabLoading = false;
          return;
        }
        if (response.code === 0) {
          // 源码成功回调 g()：仅按 myMeeting/weekplan=="on" 建 Fragment（两个都 off 时保持空）
          this.showMyTab = response.data.myMeeting === 'on';
          this.showWeekTab = response.data.weekplan === 'on';
        } else {
          // 源码错误回调 b()：getTabCount()==0 时兜底加入两个 Fragment
          this.showMyTab = true;
          this.showWeekTab = true;
        }
        this.buildTabs();
        this.meetTabLoading = false;
        if (this.showMyTab) {
          this.loadJoinList();
        }
        if (this.showWeekTab) {
          this.loadCurrentDay();
        }
      })
      .catch((error: BusinessError) => {
        ApiService.logError('MeetingPage loadMeetTab fail: ' + error.message);
        this.showMyTab = true;
        this.showWeekTab = true;
        this.buildTabs();
        this.meetTabLoading = false;
        this.loadJoinList();
        this.loadCurrentDay();
      });
  }

  /** 源码 M2 + FragmentPagerAdapter.getPageTitle：按开关建页签 */
  private buildTabs(): void {
    const tabs: MeetingTabEntry[] = [];
    if (this.showMyTab) {
      tabs.push({ id: 0, name: '我的会议' });
    }
    if (this.showWeekTab) {
      tabs.push({ id: 1, name: '周程会议' });
    }
    this.tabEntries = tabs;
    this.activeTab = tabs.length > 0 ? tabs[0].id : 0;
  }

  /** 源码 MeetingArrangementFragment.onResume → V1 → MeetingPImpl.C → MeetingModel.b1 */
  private loadJoinList(): void {
    this.myLoading = true;
    ApiService.getMeetingJoinList()
      .then((response: ApiResponse<JoinListEntity[]>) => {
        if (response.code === 1000) {
          // 登录失效统一处理已在网络层触发（HttpClient.bizRequest 拦截：清会话+toast+跳登录）
          this.myLoading = false;
          return;
        }
        if (response.code === 0) {
          this.myGroups = response.data;
          // 源码 b.b()：k=2 重置分页；组数>1 时 l = 第2组孩子数 >= 20
          this.myPage = 2;
          if (this.myGroups.length > 1) {
            this.myHasMore = this.myGroups[1].DATA.length >= 20;
          }
        } else {
          this.myGroups = [];
          this.toast(response.message === '' ? '获取会议列表失败' : response.message);
        }
        this.myLoading = false;
      })
      .catch((error: BusinessError) => {
        ApiService.logError('MeetingPage loadJoinList fail: ' + error.message);
        this.myGroups = [];
        this.myLoading = false;
      });
  }

  /** 源码 W1 → MeetingPImpl.G → MeetingModel.f1：GET getPastList（currentPage, pageSize=20） */
  private loadMorePast(): void {
    if (this.myLoadingMore || !this.canLoadMorePast()) {
      return;
    }
    this.myLoadingMore = true;
    ApiService.getMeetingPastList(String(this.myPage))
      .then((response: ApiResponse<JoinListItem[]>) => {
        if (response.code === 1000) {
          // 登录失效统一处理已在网络层触发（HttpClient.bizRequest 拦截：清会话+toast+跳登录）
          this.myLoadingMore = false;
          return;
        }
        if (response.code === 0) {
          this.appendPastPage(response.data);
          // 源码 a.g()：满 20 条继续下一页，否则 l=false 停用上拉
          if (response.data.length >= 20) {
            this.myPage = this.myPage + 1;
          } else {
            this.myHasMore = false;
          }
        } else {
          this.toast(response.message === '' ? '加载更多失败' : response.message);
        }
        this.myLoadingMore = false;
      })
      .catch((error: BusinessError) => {
        ApiService.logError('MeetingPage loadMorePast fail: ' + error.message);
        this.myLoadingMore = false;
      });
  }

  /** 源码 MeetingArrangementAdapter.a(list)：getGroup(1).DATA.addAll(list)（仅 past 组） */
  private appendPastPage(list: JoinListItem[]): void {
    if (this.myGroups.length <= 1) {
      return;
    }
    const groups: JoinListEntity[] = this.myGroups.slice();
    const past: JoinListEntity = groups[1];
    const merged: JoinListEntity = new JoinListEntity();
    merged.NAME = past.NAME;
    merged.TYPE = past.TYPE;
    merged.DATA = past.DATA.concat(list);
    groups[1] = merged;
    this.myGroups = groups;
  }

  /** 源码 X1()：adapter!=null && !adapter.d()（未收起）&& l（还有更多） */
  private canLoadMorePast(): boolean {
    return this.myGroups.length > 1 && !this.myPastCollapsed && this.myHasMore;
  }

  /** 源码 f.onGroupClick：仅 TYPE="past" 组可展开/收起（全局 f11777b 翻转） */
  private togglePastGroup(): void {
    this.myPastCollapsed = !this.myPastCollapsed;
  }

  /** 源码 b.b() 空态判定：所有组孩子数为 0 → EMPTY_MEETING */
  private isJoinListEmpty(): boolean {
    for (const group of this.myGroups) {
      if (group.DATA.length > 0) {
        return false;
      }
    }
    return true;
  }

  /** 源码 groupView：past 组按 f11777b 收起/展开，其余组恒展开 */
  private isGroupCollapsed(group: JoinListEntity): boolean {
    return group.TYPE === 'past' ? this.myPastCollapsed : false;
  }

  /** 源码 d.onChildClick：weekPlan → 周程详情 a0；否则会议详情 b0（bundle 携带 xlh/TASK_TYPE） */
  private openMeetingDetail(item: JoinListItem): void {
    const splitCfg: SplitPaneConfig =
      AdaptiveLayoutHelper.getSplitPaneConfig(this.currentBreakpoint, this.windowWidthVp);
    if (!splitCfg.useTwoPane) {
      this.openMeetingFullPage(item);
      return;
    }
    this.selectMeetingForPreview(item);
  }

  private openMeetingFullPage(item: JoinListItem): void {
    const params: Record<string, Object> = {
      'xlh': item.XLH, 'TASK_TYPE': item.TASK_TYPE, 'id': item.XLH
    };
    if (item.TASK_TYPE === 'weekPlan') {
      params['IS_JOIN'] = item.IS_JOIN;
      // [W18 meeting-remain] 周程详情实体 = MeetingWeekDetailActivity（/meeting/weekdetail）→
      // pages/MeetingWeekPlanPage（原 'pages/MeetingWeekDetailPage' 未注册，坏路由已修正）
      this.pushRoute('pages/MeetingWeekPlanPage', params);
    } else {
      this.pushRoute('pages/MeetingDetailPage', params);
    }
  }

  private selectMeetingForPreview(item: JoinListItem): void {
    this.selectedMeetingItem = item;
    this.selectedWeekPlan = null;
    this.selectedMeetingObj = null;
    this.selectedWeekDetail = null;
    this.detailError = '';
    this.detailLoading = true;
    const xlh: string = item.XLH;
    if (item.TASK_TYPE === 'weekPlan') {
      ApiService.getMeetingWeekPlanDetails(xlh)
        .then((response: ApiResponse<MeetingWeekDetailEntity>) => {
          if (response.code === 1000) {
            this.detailLoading = false;
            return;
          }
          if (this.selectedMeetingItem === null || this.selectedMeetingItem.XLH !== xlh) {
            return;
          }
          this.detailLoading = false;
          if (response.code === 0 && response.data.ZT !== '') {
            this.selectedWeekDetail = response.data;
          } else {
            this.detailError = response.message === '' ? '获取周程详情失败' : response.message;
          }
        })
        .catch((error: BusinessError) => {
          ApiService.logError('MeetingPage inline weekDetail fail: ' + error.message);
          if (this.selectedMeetingItem !== null && this.selectedMeetingItem.XLH === xlh) {
            this.detailLoading = false;
            this.detailError = '网络异常，请稍后重试';
          }
        });
      return;
    }
    ApiService.getMeetingObj(xlh)
      .then((response: ApiResponse<MeetingObjEntity>) => {
        if (response.code === 1000) {
          this.detailLoading = false;
          return;
        }
        if (this.selectedMeetingItem === null || this.selectedMeetingItem.XLH !== xlh) {
          return;
        }
        this.detailLoading = false;
        if (response.code === 0 && response.data.TITLE !== '') {
          this.selectedMeetingObj = response.data;
        } else {
          this.detailError = response.message === '' ? '获取会议详情失败' : response.message;
        }
      })
      .catch((error: BusinessError) => {
        ApiService.logError('MeetingPage inline detail fail: ' + error.message);
        if (this.selectedMeetingItem !== null && this.selectedMeetingItem.XLH === xlh) {
          this.detailLoading = false;
          this.detailError = '网络异常，请稍后重试';
        }
      });
  }

  /** 源码 e.onClick（imgAdd）→ RouteConstant.c0 = mobile_campus_meeting_create */
  private openCreateMeeting(): void {
    this.pushRoute('pages/MeetingAddPage', {});
  }

  /** 源码 d.onItemClick（周计划列表）：bundle xlh → a0 = mobile_campus_meeting_weekdetail */
  private openWeekPlanDetail(xlh: string): void {
    // [W18 meeting-remain] 路由目标修正：MeetingWeekDetailActivity 实体 = pages/MeetingWeekPlanPage
    this.pushRoute('pages/MeetingWeekPlanPage', { 'xlh': xlh, 'id': xlh });
  }

  private onWeekPlanRowTap(plan: WeekPlanEntity): void {
    const splitCfg: SplitPaneConfig =
      AdaptiveLayoutHelper.getSplitPaneConfig(this.currentBreakpoint, this.windowWidthVp);
    if (!splitCfg.useTwoPane) {
      this.openWeekPlanDetail(plan.XLH);
      return;
    }
    this.selectedWeekPlan = plan;
    this.selectedMeetingItem = null;
    this.selectedMeetingObj = null;
    this.selectedWeekDetail = null;
    this.detailError = '';
    this.detailLoading = true;
    ApiService.getMeetingWeekPlanDetails(plan.XLH)
      .then((response: ApiResponse<MeetingWeekDetailEntity>) => {
        if (response.code === 1000) {
          this.detailLoading = false;
          return;
        }
        if (this.selectedWeekPlan === null || this.selectedWeekPlan.XLH !== plan.XLH) {
          return;
        }
        this.detailLoading = false;
        if (response.code === 0 && response.data.ZT !== '') {
          this.selectedWeekDetail = response.data;
        } else {
          this.detailError = response.message === '' ? '获取周程详情失败' : response.message;
        }
      })
      .catch((error: BusinessError) => {
        ApiService.logError('MeetingPage inline weekPlan fail: ' + error.message);
        if (this.selectedWeekPlan !== null && this.selectedWeekPlan.XLH === plan.XLH) {
          this.detailLoading = false;
          this.detailError = '网络异常，请稍后重试';
        }
      });
  }

  /** 路由跳转（未注册页面仅记录日志，不阻断页面） */
  private pushRoute(url: string, params: Record<string, Object>): void {
    try {
      router.pushUrl({ url: url, params: params }).catch((error: BusinessError) => {
        ApiService.logError('MeetingPage route fail @' + url + ': ' + error.message);
      });
    } catch (error) {
      const err = error as BusinessError;
      ApiService.logError('MeetingPage route throw @' + url + ': ' + err.message);
    }
  }

  /** 源码 MeetingWeekPlanFragment.a2 → ScheduleModel.T0：POST getCurrentOrWeek {} */
  private loadCurrentDay(): void {
    ApiService.getMeetingCurrentOrWeek()
      .then((response: ApiResponse<CurrentDayEntity>) => {
        if (response.code === 1000) {
          // 登录失效统一处理已在网络层触发（HttpClient.bizRequest 拦截：清会话+toast+跳登录）
          this.weekLoading = false;
          return;
        }
        if (response.code === 0) {
          // 源码 b.g()：m=currentDay；o=m.week；p=m.date；k.k(p)；k.p(o)
          const day: CurrentDayEntity = response.data;
          if (day !== null && day !== undefined) {
            this.weekCurrentWeek = day.week;
            this.weekNumText = '第' + String(day.week) + '周';
            const headerDate: string = day.date === '' ? MeetingPage.ymdOf(new Date()) : day.date;
            this.weekSelectedDate = headerDate;
            this.applyHeaderDate(headerDate);
          }
          // 源码 b.g() 回调末尾调用 b2()（失败回调只 toast，不再拉学期信息）
          this.loadTermInfo();
        } else {
          this.weekLoading = false;
          this.toast(response.message === '' ? '获取当前周失败' : response.message);
        }
      })
      .catch((error: BusinessError) => {
        ApiService.logError('MeetingPage loadCurrentDay fail: ' + error.message);
        this.weekLoading = false;
      });
  }

  /** 源码 b2 → ScheduleModel.U0：GET termInfoForTeacher → TermParamsEntity，随后算周并拉周计划 */
  private loadTermInfo(): void {
    ApiService.getMeetingTermInfoForTeacher()
      .then((response: ApiResponse<TermParamsEntity>) => {
        if (response.code === 1000) {
          // 登录失效统一处理已在网络层触发（HttpClient.bizRequest 拦截：清会话+toast+跳登录）
          this.weekLoading = false;
          return;
        }
        // 源码 a.g()：解析失败（termParamsEntity==null）直接 return
        if (response.code !== 0) {
          this.weekLoading = false;
          this.toast(response.message === '' ? '获取学期信息失败' : response.message);
          return;
        }
        const term: TermParamsEntity = response.data;
        // 源码：l=计算当前周；o=l；n=0；k.p(o)；c2("0")；k.n(l-1)
        const current: number = MeetingPage.computeCurrentWeek(term, Date.now());
        this.weekCurrentWeek = current;
        // l<=0（学期区间外）时 pager 停在 0 页，标记展示周=1 避免 onChange 重复拉取
        this.weekDisplayWeek = current > 0 ? current : 1;
        this.weekNumText = '第' + String(current) + '周';
        this.rebuildWeekPages(term);
        this.weekPagerIndex = current > 0 ? current - 1 : 0;
        this.loadWeekPlan('0');
      })
      .catch((error: BusinessError) => {
        ApiService.logError('MeetingPage loadTermInfo fail: ' + error.message);
        this.weekLoading = false;
      });
  }

  /** 源码 c2 → MeetingPImpl.J → MeetingModel.h1：GET getWeekPlan {week} */
  private loadWeekPlan(week: string): void {
    ApiService.getMeetingWeekPlan(week)
      .then((response: ApiResponse<WeekPlanEntity[]>) => {
        if (response.code === 1000) {
          // 登录失效统一处理已在网络层触发（HttpClient.bizRequest 拦截：清会话+toast+跳登录）
          this.weekLoading = false;
          return;
        }
        if (response.code === 0) {
          // 源码 q.setData(arrayList)；空数组 → EMPTY_MEETING 空态
          this.weekPlans = response.data;
        } else {
          this.weekPlans = [];
          this.toast(response.message === '' ? '获取周程会议失败' : response.message);
        }
        this.weekLoading = false;
      })
      .catch((error: BusinessError) => {
        ApiService.logError('MeetingPage loadWeekPlan fail: ' + error.message);
        this.weekPlans = [];
        this.weekLoading = false;
      });
  }

  /** 源码 e.onPageSelected：l=i+1；若变化 → n=l-o，c2(String(n)) */
  private onWeekPageChange(index: number): void {
    this.weekPagerIndex = index;
    const display: number = index + 1;
    if (this.weekDisplayWeek === display) {
      return;
    }
    this.weekDisplayWeek = display;
    this.loadWeekPlan(String(display - this.weekCurrentWeek));
  }

  /** 源码 k.k(str)→l(date)：schedule_date_tv="yyyy年M月d日"，schedule_today_tv="星期X" */
  private applyHeaderDate(dateText: string): void {
    let dt: Date = new Date();
    const ms: number = MeetingPage.parseYmdMs(dateText);
    if (ms !== 0) {
      dt = new Date(ms);
    }
    this.weekDateText = dt.getFullYear() + '年' + (dt.getMonth() + 1) + '月' + dt.getDate() + '日';
    this.weekDayText = '星期' + MeetingPage.weekdayChar(dt);
  }

  /** 源码 k.m(termParams,date) → WeekPagerAdapter.g → f.b.c：生成周页（SDGY 周一开头） */
  private rebuildWeekPages(term: TermParamsEntity): void {
    const mondayFirst: boolean = this.isMondayFirst();
    this.weekWeekLabels = mondayFirst
      ? ['一', '二', '三', '四', '五', '六', '日']
      : ['日', '一', '二', '三', '四', '五', '六'];
    this.weekPages = MeetingPage.buildWeekPages(term, mondayFirst ? 2 : 1);
  }

  /** 源码 widget/g.java + WeekPagerAdapter.g："SDGY".equals(schoolId) → 周一开头 */
  private isMondayFirst(): boolean {
    const schoolId: string = LoginSession.schoolId === '' ? 'SDGY' : LoginSession.schoolId;
    return schoolId === 'SDGY';
  }

  // ===== 时间/日期工具（源码 meeting/f/a.java MeetingUtil + f/b.java ScheduleUtil）=====

  /** f.a.a 的毫秒解析（yyyy-MM-dd HH:mm，失败 0） */
  private static parseMs(text: string): number {
    if (text === '') {
      return 0;
    }
    const ms: number = Date.parse(text.replace(' ', 'T'));
    return Number.isNaN(ms) ? 0 : ms;
  }

  /** f.a.a：会议时间文案（同日今天→HH:mm-HH:mm；同日同年→MM月dd日 HH:mm-HH:mm；跨年→yyyy/MM/dd ...） */
  private static meetingTimeText(start: string, end: string): string {
    const t1: number = MeetingPage.parseMs(start);
    const t2: number = MeetingPage.parseMs(end);
    if (t1 === 0 || t2 === 0) {
      return 'null';
    }
    const d1: Date = new Date(t1);
    const d2: Date = new Date(t2);
    const now: Date = new Date();
    if (MeetingPage.ymdOf(d1) === MeetingPage.ymdOf(d2)) {
      if (MeetingPage.ymdOf(now) === MeetingPage.ymdOf(d1)) {
        return MeetingPage.hmOf(d1) + '-' + MeetingPage.hmOf(d2);
      }
      if (d1.getFullYear() === now.getFullYear()) {
        // 源码 SimpleDateFormat("MM月dd日 HH:mm")
        return (d1.getMonth() + 1) + '月' + d1.getDate() + '日 ' +
          MeetingPage.hmOf(d1) + '-' + MeetingPage.hmOf(d2);
      }
      return MeetingPage.ymdSlashOf(d1) + ' ' + MeetingPage.hmOf(d1) + '-' + MeetingPage.hmOf(d2);
    }
    if (d1.getFullYear() === d2.getFullYear() && d1.getFullYear() === now.getFullYear()) {
      return MeetingPage.mdOf(d1) + ' ' + MeetingPage.hmOf(d1) + '-' +
        MeetingPage.mdOf(d2) + ' ' + MeetingPage.hmOf(d2);
    }
    return MeetingPage.ymdSlashOf(d1) + ' ' + MeetingPage.hmOf(d1) + '-' +
      MeetingPage.ymdSlashOf(d2) + ' ' + MeetingPage.hmOf(d2);
  }

  private static two(n: number): string {
    return n < 10 ? '0' + String(n) : String(n);
  }

  private static ymdOf(d: Date): string {
    return d.getFullYear() + '-' + MeetingPage.two(d.getMonth() + 1) + '-' + MeetingPage.two(d.getDate());
  }

  private static mdOf(d: Date): string {
    return MeetingPage.two(d.getMonth() + 1) + '/' + MeetingPage.two(d.getDate());
  }

  private static ymdSlashOf(d: Date): string {
    return d.getFullYear() + '/' + MeetingPage.two(d.getMonth() + 1) + '/' + MeetingPage.two(d.getDate());
  }

  private static hmOf(d: Date): string {
    return MeetingPage.two(d.getHours()) + ':' + MeetingPage.two(d.getMinutes());
  }

  private static weekdayChar(d: Date): string {
    const chars: string[] = ['日', '一', '二', '三', '四', '五', '六'];
    return chars[d.getDay()];
  }

  /** yyyy-MM-dd → 当日 0 点毫秒（失败 0） */
  private static parseYmdMs(text: string): number {
    if (text === '') {
      return 0;
    }
    const parts: string[] = text.split('-');
    if (parts.length !== 3) {
      return 0;
    }
    const y: number = Number(parts[0]);
    const m: number = Number(parts[1]);
    const d: number = Number(parts[2]);
    if (Number.isNaN(y) || Number.isNaN(m) || Number.isNaN(d)) {
      return 0;
    }
    return new Date(y, m - 1, d).getTime();
  }

  /** 源码 f.b.e(TermParamsEntity)：学期总周数（jsrq+1 - ksrq + 起始周内偏移，7 天向上取整） */
  private static termWeekCount(term: TermParamsEntity): number {
    const start: number = MeetingPage.parseYmdMs(term.ksrq);
    const end: number = MeetingPage.parseYmdMs(term.jsrq);
    if (start === 0 || end === 0) {
      return -1;
    }
    const days: number = Math.floor((end + DAY_MS - start) / DAY_MS);
    const dow: number = new Date(start).getDay() + 1; // Calendar.get(7)：1=周日
    const offset: number = dow === 1 ? 0 : dow - 1;
    const total: number = days + offset;
    return total % 7 === 0 ? Math.floor(total / 7) : Math.floor(total / 7) + 1;
  }

  /** 源码 c/b/b/a/d/a.e(term, date)：当前周（不在学期区间 → -1） */
  private static computeCurrentWeek(term: TermParamsEntity, nowMs: number): number {
    const start: number = MeetingPage.parseYmdMs(term.ksrq);
    const end: number = MeetingPage.parseYmdMs(term.jsrq);
    if (start === 0 || end === 0) {
      return -1;
    }
    if (nowMs < start || nowMs > end + DAY_MS - 1) {
      return -1;
    }
    const diff: number = nowMs - start;
    let week: number = Math.floor(diff / WEEK_MS);
    if (week >= 0) {
      week = week + 1;
    }
    return week;
  }

  /** 源码 f.b.c：按学期起止生成周页（firstDay：1=周日 2=周一；每页 7 个日期格） */
  private static buildWeekPages(term: TermParamsEntity, firstDay: number): CalendarItemEntity[][] {
    const pages: CalendarItemEntity[][] = [];
    const weeks: number = MeetingPage.termWeekCount(term);
    const start: number = MeetingPage.parseYmdMs(term.ksrq);
    if (weeks <= 0 || start === 0) {
      return pages;
    }
    const dow: number = new Date(start).getDay() + 1;
    const aligned: number = start + (firstDay - dow) * DAY_MS;
    const todayText: string = MeetingPage.ymdOf(new Date());
    for (let w = 0; w < weeks; w++) {
      const page: CalendarItemEntity[] = [];
      for (let d = 0; d < 7; d++) {
        const cellDate: Date = new Date(aligned + (w * 7 + d) * DAY_MS);
        const cell: CalendarItemEntity = new CalendarItemEntity();
        cell.dateText = MeetingPage.ymdOf(cellDate);
        cell.dayNum = String(cellDate.getDate());
        cell.isToday = cell.dateText === todayText;
        page.push(cell);
      }
      pages.push(page);
    }
    return pages;
  }

  // ===== 我的会议子项状态（MeetingArrangementAdapter.getChildView 逐行）=====

  /** 源码 tvDay 颜色覆写顺序：IS_JOIN(0灰/1主色) → STATUS=0 灰 → join 组按 IS_CURRENT_USER_PLAN */
  private meetingDayColor(item: JoinListItem, groupType: string): Resource {
    let color: Resource = $r('app.color.common_color_3');
    if (item.IS_JOIN === 1) {
      color = $r('app.color.mobile_campus_primary_color_default');
    }
    if (item.STATUS === '0') {
      color = $r('app.color.common_color_3');
    }
    if (groupType === 'join') {
      color = item.IS_CURRENT_USER_PLAN === '0'
        ? $r('app.color.mobile_campus_primary_color_default') : $r('app.color.common_color_3');
    }
    return color;
  }

  /** 源码 imgState 图标编码：0=无 1=no_attend 2=attend 3=my（IS_CURRENT_USER_PLAN=1 覆盖；STATUS=0 清空） */
  private meetingStateCode(item: JoinListItem): number {
    let code: number = 0;
    if (item.IS_JOIN === 0) {
      code = 1;
    } else if (item.IS_JOIN === 1) {
      code = 2;
    }
    if (item.IS_CURRENT_USER_PLAN === '1') {
      code = 3;
    }
    if (item.STATUS === '0' && item.IS_CURRENT_USER_PLAN !== '1') {
      code = 0;
    }
    return code;
  }

  private toast(message: string): void {
    this.getUIContext().getPromptAction().showToast({ message: message });
  }

  // 登录失效统一处理已下沉网络层（HttpClient.bizRequest code=1000 拦截：清会话+toast+跳登录），
  // 本地 onSessionExpired（仅 toast 无跳转的残缺实现）已删除，页面 1000 分支只负责 return

  // ===== UI =====

  build() {
    Column() {
      TitleBar({ title: '会议安排', showBack: true })

      if (this.meetTabLoading) {
        LoadingView()
      } else if (this.tabEntries.length === 0) {
        EmptyView({ tipText: '暂无会议' })
      } else {
        if (AdaptiveLayoutHelper.getSplitPaneConfig(this.currentBreakpoint, this.windowWidthVp).useTwoPane) {
          Row() {
            Column() {
              this.tabBar()
              if (this.activeTab === 0 && this.showMyTab) {
                this.arrangementView()
              }
              if (this.activeTab === 1 && this.showWeekTab) {
                this.weekPlanView()
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
              this.meetingDetailPane()
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
          if (this.activeTab === 0 && this.showMyTab) {
            this.arrangementView()
          }
          if (this.activeTab === 1 && this.showWeekTab) {
            this.weekPlanView()
          }
        }
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.mobile_campus_bg_color'))
  }

  /** mobile_campus_meeting_activity.xml TabLayout：48dip 白底、2dip 指示器、选中主色 */
  @Builder
  tabBar() {
    Row() {
      ForEach(this.tabEntries, (tab: MeetingTabEntry) => {
        Column() {
          Text(tab.name)
            .fontSize(14)
            .fontColor(this.activeTab === tab.id
              ? $r('app.color.mobile_campus_primary_color_default') : $r('app.color.common_color_3'))
            .layoutWeight(1)
            .textAlign(TextAlign.Center)
          Divider()
            .strokeWidth(2)
            .color(this.activeTab === tab.id
              ? $r('app.color.mobile_campus_primary_color_default') : Color.Transparent)
            .width('100%')
        }
        .layoutWeight(1)
        .height(48)
        .justifyContent(FlexAlign.End)
        .hoverEffect(HoverEffect.Highlight)
        .onClick(() => {
          this.activeTab = tab.id;
        })
      }, (tab: MeetingTabEntry) => 'meeting_tab_' + tab.id)
    }
    .width('100%')
    .height(48)
    .backgroundColor($r('app.color.white'))
  }

  /** mobile_campus_meeting_fragment_arrangement.xml：MultiStateView + 列表 + 右下 imgAdd */
  @Builder
  arrangementView() {
    Stack({ alignContent: Alignment.BottomEnd }) {
      if (this.myLoading) {
        LoadingView()
      } else if (this.isJoinListEmpty()) {
        EmptyView({ tipText: '暂无会议安排' })
      } else {
        List() {
          ForEach(this.myGroups, (group: JoinListEntity, index: number) => {
            ListItem() {
              this.meetingGroupHeader(group)
            }
            if (!this.isGroupCollapsed(group)) {
              ForEach(group.DATA, (item: JoinListItem) => {
                ListItem() {
                  this.meetingChildRow(item, group.TYPE)
                }
              }, (item: JoinListItem) => group.TYPE + '_' + item.XLH)
            }
          }, (group: JoinListEntity, index: number) => group.TYPE + '_g' + index)
        }
        .width('100%')
        .height('100%')
        .scrollBar(BarState.Off)
        .onReachEnd(() => {
          this.loadMorePast();
        })
      }
      // 源码 imgAdd：layout_gravity bottom|center|right，margin 16dip（mipmap 102px@xhdpi≈51vp）
      Image($r('app.media.mobile_campus_meeting_add'))
        .width(51)
        .height(51)
        .margin(16)
        .hoverEffect(HoverEffect.Highlight)
        .onClick(() => {
          this.openCreateMeeting();
        })
    }
    .width('100%')
    .layoutWeight(1)
  }

  /** mobile_campus_meeting_view_main_group.xml：40dip 白底组头 + ivIcon/tvTips（仅 past）+ 双分隔线 */
  @Builder
  meetingGroupHeader(group: JoinListEntity) {
    Column() {
      if (group.DATA.length > 0) {
        Row() {
          Text(group.NAME)
            .fontSize(14)
            .fontColor($r('app.color.common_color_1'))
            .layoutWeight(1)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
          if (group.TYPE === 'past') {
            Image(this.myPastCollapsed ? $r('app.media.mobile_campus_meeting_open')
              : $r('app.media.mobile_campus_meeting_close'))
              .width(16)
              .height(16)
              .margin({ right: 6 })
            Text(this.myPastCollapsed ? '展开' : '收起')
              .fontSize(12)
              .fontColor($r('app.color.mobile_campus_primary_color_default'))
              .margin({ right: 12 })
          }
        }
        .width('100%')
        .height(40)
        .padding({ left: 12, right: 12 })
        .backgroundColor($r('app.color.white'))
        .alignItems(VerticalAlign.Center)
        .hoverEffect(HoverEffect.Highlight)
        .onClick(() => {
          if (group.TYPE === 'past') {
            this.togglePastGroup();
          }
        })
      }
      Divider()
        .color($r('app.color.common_color_5'))
        .strokeWidth(0.5)
        .width('100%')
      Divider()
        .color($r('app.color.common_color_5'))
        .strokeWidth(0.5)
        .width('100%')
    }
    .width('100%')
    .margin({ top: 12 })
    .backgroundColor($r('app.color.white'))
  }

  /** mobile_campus_meeting_view_main_child.xml：tvDay 44dip + timeline + 标题/地点/时间 + 右上状态角标 */
  @Builder
  meetingChildRow(item: JoinListItem, groupType: string) {
    Stack({ alignContent: Alignment.TopEnd }) {
      Row() {
        Text('周' + item.WEEK)
          .fontSize(20)
          .fontColor(this.meetingDayColor(item, groupType))
          .width(44)
          .textAlign(TextAlign.Center)
        Image($r('app.media.mobile_campus_meeting_timeline'))
          .width(16)
          .height(44)
          .objectFit(ImageFit.Contain)
        Column() {
          this.meetingTitleRow(item)
          this.meetingInfoRow($r('app.media.mobile_campus_meeting_location_s'), item.ADDRESS)
          this.meetingInfoRow($r('app.media.mobile_campus_meeting_time_s'),
            MeetingPage.meetingTimeText(item.KSSJ, item.JSSJ))
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)
        .margin({ left: 10, top: 14 })
      }
      .width('100%')
      .padding({ left: 8 })
      .alignItems(VerticalAlign.Center)
      .backgroundColor(this.selectedMeetingItem !== null && this.selectedMeetingItem.XLH === item.XLH
        ? '#EEF5FC' : $r('app.color.white'))
      .hoverEffect(HoverEffect.Highlight)
      .onClick(() => {
        this.openMeetingDetail(item);
      })

      // 源码 child 右上：imgCancel + imgState 同一横向 LinearLayout（imgState marginTop/Right -12）
      Row() {
        if (item.STATUS === '0') {
          Image($r('app.media.mobile_campus_meeting_cancel'))
            .width(20)
            .height(20)
        }
        this.meetingCornerStateIcon(item)
      }
      .alignItems(VerticalAlign.Top)
    }
    .width('100%')
    .backgroundColor($r('app.color.white'))
  }

  /** child 右上 imgState（源码：IS_JOIN 0/1 → no_attend/attend；IS_CURRENT_USER_PLAN=1 → my；STATUS=0 且非本人→清空） */
  @Builder
  meetingCornerStateIcon(item: JoinListItem) {
    if (this.meetingStateCode(item) === 1) {
      Image($r('app.media.mobile_campus_meeting_no_attend'))
        .width(20)
        .height(20)
        .offset({ x: -12, y: -12 })
    } else if (this.meetingStateCode(item) === 2) {
      Image($r('app.media.mobile_campus_meeting_attend'))
        .width(20)
        .height(20)
        .offset({ x: -12, y: -12 })
    } else if (this.meetingStateCode(item) === 3) {
      Image($r('app.media.mobile_campus_meeting_my'))
        .width(20)
        .height(20)
        .offset({ x: -12, y: -12 })
    }
  }

  /** child 标题行：报告 tag（24×16 蓝底白字 9fp）+ tvTitle 17fp + 必须参加 11fp #C80D28 描边 */
  @Builder
  meetingTitleRow(item: JoinListItem) {
    Row() {
      if (item.IS_EXIST_MEETING_REPORT === '1') {
        Text('报告')
          .fontSize(9)
          .fontColor($r('app.color.ybg_white'))
          .width(24)
          .height(16)
          .textAlign(TextAlign.Center)
          .borderRadius(2)
          .backgroundColor($r('app.color.mobile_campus_primary_color_default'))
          .margin({ right: 4 })
      }
      Text(item.TITLE)
        .fontSize(17)
        .fontColor($r('app.color.common_color_1'))
        .layoutWeight(1)
        .maxLines(2)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
      if (item.IS_MUST_JOIN === '1') {
        Text('必须参加')
          .fontSize(11)
          .fontColor($r('app.color.mobile_campus_meeting_must_attend_text'))
          .padding({ left: 16, right: 16, top: 4, bottom: 4 })
          .border({
            width: 0.5,
            color: $r('app.color.mobile_campus_meeting_must_attend_border'),
            radius: 2
          })
          .margin({ left: 4 })
      }
    }
    .width('100%')
    .alignItems(VerticalAlign.Center)
  }

  /** child 图标信息行（tvLocation/tvTime：12fp + drawablePadding 6 + marginTop 6） */
  @Builder
  meetingInfoRow(icon: Resource, text: string) {
    Row() {
      Image(icon)
        .width(12)
        .height(12)
        .margin({ right: 6 })
      Text(text)
        .fontSize(12)
        .fontColor($r('app.color.common_color_3'))
        .maxLines(1)
    }
    .width('100%')
    .margin({ top: 6 })
    .alignItems(VerticalAlign.Center)
  }

  /** mobile_campus_meeting_fragment_week_plan.xml：weekView + 周计划列表 */
  @Builder
  weekPlanView() {
    Column() {
      Column() {
        this.weekDateHeader()
        this.weekPager()
      }
      .width('100%')
      .margin({ top: 8 })

      if (this.weekLoading) {
        LoadingView()
      } else if (this.weekPlans.length === 0) {
        EmptyView({ tipText: '暂无会议安排' })
      } else {
        List() {
          ForEach(this.weekPlans, (plan: WeekPlanEntity) => {
            ListItem() {
              this.weekPlanRow(plan)
            }
          }, (plan: WeekPlanEntity) => 'meeting_plan_' + plan.XLH)
        }
        .width('100%')
        .layoutWeight(1)
        .scrollBar(BarState.Off)
      }
    }
    .width('100%')
    .layoutWeight(1)
  }

  /** mobile_campus_meeting_weekdate_layout.xml 顶部日期行：16fp #B2BDC9 / #B2BDC9 / 主色 */
  @Builder
  weekDateHeader() {
    Row() {
      Text(this.weekDateText)
        .fontSize(16)
        .fontColor($r('app.color.mobile_campus_schedule_color2'))
      Text(this.weekDayText)
        .fontSize(16)
        .fontColor($r('app.color.mobile_campus_schedule_color2'))
        .layoutWeight(1)
        .margin({ left: 20 })
      Text(this.weekNumText)
        .fontSize(16)
        .fontColor($r('app.color.mobile_campus_primary_color_default'))
    }
    .width('100%')
    .padding(10)
    .alignItems(VerticalAlign.Center)
  }

  /** 星期表头（13fp 首尾灰）+ MeetingWeekPager 44dip（7 日期格，可周翻页） */
  @Builder
  weekPager() {
    Column() {
      Row() {
        ForEach(this.weekWeekLabels, (label: string, index: number) => {
          Text(label)
            .fontSize(13)
            .fontColor(index === 0 || index === 6
              ? $r('app.color.mobile_campus_schedule_color2') : $r('app.color.common_color_1'))
            .textAlign(TextAlign.Center)
            .layoutWeight(1)
        }, (label: string, index: number) => 'week_label_' + index)
      }
      .width('100%')
      .padding({ top: 5, bottom: 5 })

      Swiper() {
        ForEach(this.weekPages, (page: CalendarItemEntity[], pageIndex: number) => {
          Row() {
            ForEach(page, (cell: CalendarItemEntity, cellIndex: number) => {
              this.weekDateCell(cell, cellIndex)
            }, (cell: CalendarItemEntity) => 'date_' + cell.dateText)
          }
          .width('100%')
          .height(44)
          .alignItems(VerticalAlign.Center)
        }, (page: CalendarItemEntity[], pageIndex: number) => 'week_page_' + pageIndex)
      }
      .index(this.weekPagerIndex)
      .height(44)
      .indicator(false)
      .loop(false)
      .onChange((index: number) => {
        this.onWeekPageChange(index);
      })
    }
    .width('100%')
  }

  /** mobile_campus_meeting_date_view.xml：30dip DateView（选中红圆白字；首尾灰字；hasData 点本页不启用） */
  @Builder
  weekDateCell(cell: CalendarItemEntity, cellIndex: number) {
    Column() {
      Column() {
        Text(cell.dayNum)
          .fontSize(14)
          .fontColor(this.weekSelectedDate === cell.dateText
            ? $r('app.color.ybg_white')
            : (cellIndex === 0 || cellIndex === 6
              ? $r('app.color.mobile_campus_schedule_color2')
              : $r('app.color.mobile_campus_schedule_color5')))
      }
      .width(30)
      .height(30)
      .borderRadius(15)
      .backgroundColor(this.weekSelectedDate === cell.dateText
        ? $r('app.color.mobile_campus_schedule_color4') : Color.Transparent)
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
    }
    .layoutWeight(1)
    .height(44)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .onClick(() => {
      // 源码 a.a(dateView,calendarItem)：仅视觉选中（Fragment 未设置日期回调，不触发列表刷新）
      this.weekSelectedDate = cell.dateText;
    })
  }

  /** 周计划行：MeetingWeekPlanAdapter.getView（tvTitle=ZT / tvLocation=DD / tvTime / tvDay="周"+WEEK） */
  @Builder
  weekPlanRow(plan: WeekPlanEntity) {
    Row() {
      Text('周' + plan.WEEK)
        .fontSize(20)
        .fontColor($r('app.color.common_color_1'))
        .width(44)
        .textAlign(TextAlign.Center)
      Image($r('app.media.mobile_campus_meeting_timeline'))
        .width(16)
        .height(44)
        .objectFit(ImageFit.Contain)
      Column() {
        Row() {
          // 源码 MeetingWeekPlanAdapter.getView 未调用 tvReport.setVisibility → 布局默认 visible（恒显示"报告"）
          Text('报告')
            .fontSize(9)
            .fontColor($r('app.color.ybg_white'))
            .width(24)
            .height(16)
            .textAlign(TextAlign.Center)
            .borderRadius(2)
            .backgroundColor($r('app.color.mobile_campus_primary_color_default'))
            .margin({ right: 4 })
          Text(plan.ZT)
            .fontSize(17)
            .fontColor($r('app.color.common_color_1'))
            .layoutWeight(1)
            .maxLines(2)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
        .width('100%')
        .alignItems(VerticalAlign.Center)
        this.meetingInfoRow($r('app.media.mobile_campus_meeting_location_s'), plan.DD)
        this.meetingInfoRow($r('app.media.mobile_campus_meeting_time_s'),
          MeetingPage.meetingTimeText(plan.KSSJ, plan.JSSJ))
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
      .margin({ left: 10, top: 14 })
    }
    .width('100%')
    .padding({ left: 8 })
    .alignItems(VerticalAlign.Center)
    .backgroundColor(this.selectedWeekPlan !== null && this.selectedWeekPlan.XLH === plan.XLH
      ? '#EEF5FC' : $r('app.color.white'))
    .hoverEffect(HoverEffect.Highlight)
    .onClick(() => {
      this.onWeekPlanRowTap(plan);
    })
  }

  /** 双栏右侧会议详情预览面板 */
  @Builder
  meetingDetailPane() {
    Column() {
      if (this.selectedMeetingItem === null && this.selectedWeekPlan === null) {
        Column() {
          EmptyView({ tipText: '请选择左侧会议查看详情' })
        }
        .width('100%')
        .height('100%')
      } else {
        Scroll() {
          Column({ space: 12 }) {
            Column({ space: 8 }) {
              Text(this.selectedMeetingItem !== null
                ? this.selectedMeetingItem.TITLE
                : (this.selectedWeekPlan !== null ? this.selectedWeekPlan.ZT : ''))
                .fontSize(18)
                .fontWeight(FontWeight.Medium)
                .fontColor($r('app.color.common_color_1'))
                .width('100%')

              if (this.selectedMeetingItem !== null) {
                this.meetingMetaRow('地点', this.selectedMeetingItem.ADDRESS)
                this.meetingMetaRow('时间',
                  MeetingPage.meetingTimeText(this.selectedMeetingItem.KSSJ, this.selectedMeetingItem.JSSJ))
                this.meetingMetaRow('状态', this.selectedMeetingItem.STATUS === '0' ? '已取消' : '正常')
              } else if (this.selectedWeekPlan !== null) {
                this.meetingMetaRow('地点', this.selectedWeekPlan.DD)
                this.meetingMetaRow('时间',
                  MeetingPage.meetingTimeText(this.selectedWeekPlan.KSSJ, this.selectedWeekPlan.JSSJ))
                this.meetingMetaRow('举办单位', this.selectedWeekPlan.ZBDW)
                this.meetingMetaRow('主持人', this.selectedWeekPlan.ZCR)
              }
            }
            .width('100%')
            .padding(16)
            .borderRadius(8)
            .backgroundColor($r('app.color.white'))
            .alignItems(HorizontalAlign.Start)

            Row() {
              Text('查看完整详情')
                .fontSize(15)
                .fontColor($r('app.color.white'))
                .fontWeight(FontWeight.Medium)
                .textAlign(TextAlign.Center)
                .padding({ left: 20, right: 20, top: 10, bottom: 10 })
                .borderRadius(6)
                .backgroundColor($r('app.color.mobile_campus_primary_color_default'))
                .hoverEffect(HoverEffect.Highlight)
                .onClick(() => {
                  if (this.selectedMeetingItem !== null) {
                    this.openMeetingFullPage(this.selectedMeetingItem);
                  } else if (this.selectedWeekPlan !== null) {
                    this.openWeekPlanDetail(this.selectedWeekPlan.XLH);
                  }
                })
            }
            .width('100%')
            .justifyContent(FlexAlign.End)

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
                  .fontColor($r('app.color.common_color_3'))
              }
              .width('100%')
              .padding(16)
              .backgroundColor($r('app.color.white'))
              .borderRadius(8)
              .alignItems(HorizontalAlign.Center)
            } else if (this.selectedMeetingObj !== null) {
              Column({ space: 8 }) {
                Text('会议详细信息')
                  .fontSize(15)
                  .fontWeight(FontWeight.Medium)
                  .fontColor($r('app.color.common_color_1'))
                this.meetingMetaRow('举办单位', this.selectedMeetingObj.JBDW)
                this.meetingMetaRow('主持人', this.selectedMeetingObj.ZCR)
                this.meetingMetaRow('联系人', this.selectedMeetingObj.LXR)
                this.meetingMetaRow('联系电话', this.selectedMeetingObj.LXRDH)
                this.meetingMetaRow('参会领导', this.selectedMeetingObj.CHLD)
                this.meetingMetaRow('参会人员', this.selectedMeetingObj.CHRY)
                this.meetingMetaRow('参会人数', this.selectedMeetingObj.CHRS > 0
                  ? String(this.selectedMeetingObj.CHRS) + '人' : '--')
                this.meetingMetaRow('附件数量', String(this.selectedMeetingObj.ATTACHMENT_LIST.length))
              }
              .width('100%')
              .padding(16)
              .borderRadius(8)
              .backgroundColor($r('app.color.white'))
              .alignItems(HorizontalAlign.Start)
            } else if (this.selectedWeekDetail !== null) {
              Column({ space: 8 }) {
                Text('周程详细信息')
                  .fontSize(15)
                  .fontWeight(FontWeight.Medium)
                  .fontColor($r('app.color.common_color_1'))
                this.meetingMetaRow('举办单位', this.selectedWeekDetail.ZBDW)
                this.meetingMetaRow('主持人', this.selectedWeekDetail.ZCR)
                this.meetingMetaRow('联系电话', this.selectedWeekDetail.LXDH)
                this.meetingMetaRow('参会人员', this.selectedWeekDetail.CYRY)
                this.meetingMetaRow('备注', this.selectedWeekDetail.BZ)
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
    .backgroundColor($r('app.color.mobile_campus_bg_color'))
  }

  @Builder
  meetingMetaRow(label: string, value: string) {
    Row() {
      Text(label)
        .fontSize(13)
        .fontColor($r('app.color.common_color_3'))
        .width(84)
        .flexShrink(0)
      Text(value === '' ? '--' : value)
        .fontSize(13)
        .fontColor($r('app.color.common_color_1'))
        .layoutWeight(1)
    }
    .width('100%')
    .alignItems(VerticalAlign.Top)
  }
}
