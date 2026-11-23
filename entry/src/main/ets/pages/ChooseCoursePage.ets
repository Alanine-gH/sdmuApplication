import { router } from '@kit.ArkUI';
import { BusinessError } from '@kit.BasicServicesKit';
import { TitleBar } from '../components/TitleBar';
import { ApiService } from '../network/ApiService';
import { ApiResponse } from '../model/ResponseModel';
import { AuditCourseNameEntry, AuditGradeEntry, AuditMajorEntry } from '../model/CourseModel';
import { PreferencesUtil } from '../data/PreferencesUtil';
import { BreakpointSystem } from '../common/BreakpointSystem';
import { AdaptiveLayoutHelper } from '../common/AdaptiveLayoutHelper';

/**
 * 蹭课课程名列表页 — 1:1 复刻 timetable/view/ChooseCourseActivity.java（ChooseAcademyActivity
 * 气泡点击入口，标题=学院名）
 *
 * 源码还原的 UI 与数据链：
 *   1. 布局 choose_course.xml = toolbar_normal + common_refresh_lv_with_search_box：
 *      搜索框（同 ChooseAcademyPage search_box：圆角 6vp #E7E7E7 + search_grey + drawablePadding10）
 *      + divider thin 0.5 + PullToRefreshLayout(ListView divider #E7E7E7 0.8vp)；
 *      toolbar 右侧"筛选"（ybg_blue，仅 f.c.d().isSupportSearchFilter 即 ckControl 持久化开时）
 *   2. 数据 f1：m.e() searchSchedule → hint="请输入"+data（f.c.g 持久化）；m.b(xydm,y,1) →
 *      getCollegeCourseNames {pageSize:"20",pageNum,xydm[,zydm,nj]}（d 回调仅取 kcmc）；
 *      m.c() getGradeList → 年级；m.d(xydm) getCkMajors → 专业（2026-11-18 探针：9 学院课程名
 *      全空数组 → 页面呈现 Page.EMPTY 空态）
 *   3. 筛选弹窗 widget.c ChooseCourseFilterPopup（popup_choose_course_filter）：全屏半透明 +
 *      白面板 marginBottom 60vp；年级 3 列圆角选择（17fp #999/白选中 color5→ybg_blue）+ 首项"全部"；
 *      专业行（label + 已选文案 + arrow_down/up_blue 切换）→ 1 列专业列表（16fp #999→#18B4ED）
 *      + 首项"全部"；触透明区 dismiss 回调 a(grade,major)（0 位=全部→null）：与当前过滤不同才
 *      x=1 重载+回顶；弹窗打开时 toolbar 文案 sure_normal"确认"（a.onClick gVar.m），关闭还原"筛选"
 *   4. 下拉刷新 x=1 重拉；上拉 x++ 追加；空列表页=Page.EMPTY，翻页无数据 toast"没有数据了"；
 *      失败 E：x>1 回退一页，列表空→Page.ERROR，否则 toast message||network_or_service_error
 *   5. 搜索 IME actionSearch（c 类）→ setSearchKey(true)+e3(true)；列表项点击（d 类）→
 *      setSearchKey(kcmc)+e3(false) —— 二者均跳 timetable AddCourseActivity（审核课程列表，
 *      映射表标注范围外未翻译）：HAP 保留源码状态语义，路由待该页落地补全
 *   6. f2() onResume 重拉：HAP 由 aboutToAppear 统一拉取（等价数据行为，避免双请求闪烁）
 */
const PAGE_SIZE: number = 20;
const PREF_AUDIT_SUPPORT_SEARCH: string = 'audit_is_support_search_filter';
const PREF_AUDIT_SEARCH_KEY_TYPE: string = 'audit_search_course_key_type';

@Entry
@Component
struct ChooseCoursePage {
  @State rows: AuditCourseNameEntry[] = [];
  @State loadState: number = 1; // 0=content 1=loading 2=empty 3=error
  @State errorTips: string = '';
  @State hint: string = '请输入课程名称';
  @State searchKey: string = '';
  @State grades: AuditGradeEntry[] = [];
  @State majors: AuditMajorEntry[] = [];
  @State gradeOptions: AuditGradeEntry[] = [];
  @State majorOptions: AuditMajorEntry[] = [];
  @State gradeIdx: number = 0;
  @State majorIdx: number = 0;
  @State appliedNj: string = '';
  @State appliedZydm: string = '';
  @State chosenMajorText: string = '全部';
  @State showFilter: boolean = false;
  @State showMajors: boolean = false;
  @State filterOpen: boolean = false;
  @State supportFilter: boolean = false;
  @State listTitle: string = '';
  @StorageProp('currentBreakpoint') currentBreakpoint: string = 'sm';
  @StorageProp('windowWidthVp') windowWidthVp: number = 360;
  @StorageProp('windowHeightVp') windowHeightVp: number = 640;
  @StorageProp('avoidAreaBottomVp') avoidAreaBottomVp: number = 0;
  private xydm: string = '';
  private pageNum: number = 1;
  private noMore: boolean = false;
  private loadingNames: boolean = false;

  aboutToAppear(): void {
    this.readParams();
    this.loadInit();
  }

  /** y(Intent)/T1：academy 路由参数（xydm 请求键、xymc 标题） */
  private readParams(): void {
    const params: Record<string, Object> | undefined =
      router.getParams() as Record<string, Object> | undefined;
    if (params === undefined || params === null) {
      return;
    }
    const xydm: Object = params['xydm'];
    if (typeof xydm === 'string') {
      this.xydm = xydm as string;
    }
    const xymc: Object = params['xymc'];
    this.listTitle = typeof xymc === 'string' ? xymc as string : '';
  }

  /** f1：searchSchedule hint + 课程名第 1 页 + 年级 + 专业 + 筛选开关（f.c.d 持久化键） */
  private async loadInit(): Promise<void> {
    try {
      const support: boolean = await PreferencesUtil.getBoolean(PREF_AUDIT_SUPPORT_SEARCH, false);
      this.supportFilter = support;
      const keyType: string = await PreferencesUtil.getString(PREF_AUDIT_SEARCH_KEY_TYPE, '');
      if (keyType !== '') {
        this.hint = '请输入' + keyType;
      }
    } catch (error) {
      const be = error as BusinessError;
      ApiService.logError('CC readPrefs fail: ' + be.message);
    }
    this.loadNames(true);
    this.loadGrades();
    this.loadMajors();
    this.loadHint();
  }

  /** m.e()：searchSchedule → hint="请输入"+data（f.c.g 同键再持久化） */
  private async loadHint(): Promise<void> {
    const resp: ApiResponse<string> = await ApiService.getAuditSearchHint();
    if (resp.code === 0 && resp.data !== '') {
      this.hint = '请输入' + resp.data;
      try {
        await PreferencesUtil.putString(PREF_AUDIT_SEARCH_KEY_TYPE, resp.data);
      } catch (error) {
        const be = error as BusinessError;
        ApiService.logError('CC saveHint fail: ' + be.message);
      }
    }
  }

  /** m.c()：getGradeList → 年级（弹窗构建时补"全部"首项） */
  private async loadGrades(): Promise<void> {
    const resp: ApiResponse<AuditGradeEntry[]> = await ApiService.getAuditGradeList();
    if (resp.code === 0) {
      this.grades = resp.data;
    }
  }

  /** m.d(xydm)：getCkMajors → 专业 */
  private async loadMajors(): Promise<void> {
    const resp: ApiResponse<AuditMajorEntry[]> = await ApiService.getCkMajors(this.xydm);
    if (resp.code === 0) {
      this.majors = resp.data;
    }
  }

  /** m.b(xydm,y,page)：getCollegeCourseNames；refresh=true 时 x=1 且清列表 */
  private async loadNames(refresh: boolean): Promise<void> {
    if (this.loadingNames) {
      return;
    }
    this.loadingNames = true;
    const page: number = refresh ? 1 : this.pageNum;
    if (refresh) {
      this.pageNum = 1;
      this.noMore = false;
    }
    const resp: ApiResponse<AuditCourseNameEntry[]> = await ApiService.getCollegeCourseNames(
      page, this.xydm, this.appliedZydm, this.appliedNj);
    this.loadingNames = false;
    if (resp.code === 0) {
      if (resp.data.length > 0) {
        if (refresh) {
          this.rows = resp.data;
        } else {
          this.rows = this.rows.concat(resp.data);
        }
        this.loadState = 0;
      } else if (refresh || this.rows.length <= 0) {
        this.loadState = 2;
      } else {
        // L()：x>1 空表 → hasNoMoreData + toast"没有数据了"
        this.noMore = true;
        this.toast('没有数据了');
      }
      return;
    }
    this.onNamesError(resp);
  }

  /** E(str,str2)：x>1 回退一页；列表空→Page.ERROR；否则 toast message||网络错误文案 */
  private onNamesError(resp: ApiResponse<AuditCourseNameEntry[]>): void {
    if (this.pageNum > 1) {
      this.pageNum = this.pageNum - 1;
    }
    if (this.rows.length <= 0) {
      this.errorTips = resp.message === '' ? '连接不到网络，请稍后再试' : resp.message;
      this.loadState = 3;
      return;
    }
    this.toast(resp.message === '' ? '连接不到网络，请稍后再试' : resp.message);
  }

  private toast(msg: string): void {
    this.getUIContext().getPromptAction().showToast({ message: msg });
  }

  /** 下拉刷新（PullToRefreshLayout.a）：x=1 重拉 */
  private refreshList(): void {
    this.loadNames(true);
  }

  /** 上拉加载（PullToRefreshLayout.b → a3）：x++ 追加 */
  private loadMore(): void {
    if (this.noMore || this.loadingNames) {
      return;
    }
    this.pageNum = this.pageNum + 1;
    this.loadNames(false);
  }

  /** 筛选弹窗首次打开（a.onClick：t==null 时构建）：补"全部"首项 + 应用已选回显 */
  private openFilterPopup(): void {
    if (this.gradeOptions.length === 0) {
      const allGrade: AuditGradeEntry = new AuditGradeEntry();
      this.gradeOptions = [allGrade].concat(this.grades);
    }
    if (this.majorOptions.length === 0) {
      const allMajor: AuditMajorEntry = new AuditMajorEntry();
      this.majorOptions = [allMajor].concat(this.majors);
    }
    // 回显已应用过滤（identity 语义等价为 nj/zydm 匹配）
    this.gradeIdx = 0;
    for (let i = 1; i < this.gradeOptions.length; i++) {
      if (this.gradeOptions[i].nj === this.appliedNj && this.appliedNj !== '') {
        this.gradeIdx = i;
      }
    }
    this.majorIdx = 0;
    for (let i = 1; i < this.majorOptions.length; i++) {
      if (this.majorOptions[i].zydm === this.appliedZydm && this.appliedZydm !== '') {
        this.majorIdx = i;
      }
    }
    this.chosenMajorText = this.majorIdx === 0 ? '全部' : this.majorOptions[this.majorIdx].zymc;
    this.showFilter = true;
    this.filterOpen = true;
  }

  /** dismiss 回调 a(grade,major)：0 位=全部(null)；过滤变化才 x=1 重载+smoothScrollToPosition(0) */
  private applyFilter(): void {
    this.showFilter = false;
    this.filterOpen = false;
    const nj: string = this.gradeIdx === 0 ? '' : this.gradeOptions[this.gradeIdx].nj;
    const zydm: string = this.majorIdx === 0 ? '' : this.majorOptions[this.majorIdx].zydm;
    if (nj === this.appliedNj && zydm === this.appliedZydm) {
      return;
    }
    this.appliedNj = nj;
    this.appliedZydm = zydm;
    this.refreshList();
  }

  /** 搜索 IME actionSearch（c 类）：setSearchKey(true) → e3(true) 跳审核课程列表（范围外） */
  private submitSearch(): void {
    // 源码 e3(true)：Intent(AddCourseActivity){academy,courseFilter(searchKey/isCustomSearchKey),
    // from_search=true} —— timetable AddCourseActivity（searchCollegeCourses 列表）未翻译，
    // HAP 保留源码状态语义，路由待该页落地补全。
  }

  /** 列表项点击（d 类）：setSearchKey(kcmc,false) → e3(false) 跳审核课程列表（范围外） */
  private onRowClick(index: number): void {
    // 源码 e3(false)：Intent(AddCourseActivity){courseFilter.searchKey=kcmc} —— timetable
    // AddCourseActivity（searchCollegeCourses 列表）未翻译（映射表范围外），HAP 保留源码
    // 状态语义，路由待该页落地补全。
    if (index < 0 || index >= this.rows.length) {
      return;
    }
  }

  // ===== UI =====

  /** search_box.xml：圆角 6vp #E7E7E7、search_grey 前置、drawablePadding 10、16fp hint */
  @Builder
  searchBox() {
    Row() {
      Image($r('app.media.search_grey'))
        .width(16)
        .height(16)
        .margin({ right: 10 })
      TextInput({ text: this.searchKey, placeholder: this.hint })
        .fontSize(16)
        .fontColor($r('app.color.common_color_2'))
        .placeholderColor($r('app.color.common_color_3'))
        .placeholderFont({ size: 16 })
        .backgroundColor(Color.Transparent)
        .padding(0)
        .layoutWeight(1)
        .height(36)
        .maxLines(1)
        .enterKeyType(EnterKeyType.Search)
        .onChange((value: string) => {
          this.searchKey = value;
        })
        .onSubmit(() => {
          this.submitSearch();
        })
    }
    .width('100%')
    .padding({ left: 15, right: 15, top: 6, bottom: 6 })
    .backgroundColor($r('app.color.common_color_5'))
    .borderRadius(6)
  }

  /** audit_course_academy_item：17fp Color1、padH12 padV15、白底 hover 灰、arrow_right 右缀 */
  @Builder
  courseRow(item: AuditCourseNameEntry, index: number) {
    Column() {
      Row() {
        Text(item.kcmc)
          .fontSize(17)
          .fontColor($r('app.color.common_color_1'))
          .layoutWeight(1)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        Image($r('app.media.arrow_right'))
          .width(16)
          .height(16)
      }
      .width('100%')
      .padding({ left: 12, right: 12, top: 15, bottom: 15 })
      .alignItems(VerticalAlign.Center)
      .backgroundColor($r('app.color.white'))
      .hoverEffect(HoverEffect.Highlight)
      .onClick(() => {
        this.onRowClick(index);
      })
      // ListView divider #E7E7E7 0.8vp
      Divider()
        .color($r('app.color.divider_grey'))
        .strokeWidth(0.8)
        .width('100%')
    }
    .width('100%')
  }

  /** popup_choose_course_filter 年级 3 列圆角选择（17fp #999，选中白字 ybg_blue 底） */
  @Builder
  gradeItem(item: AuditGradeEntry, index: number) {
    Text(item.njmc)
      .fontSize(17)
      .fontColor(index === this.gradeIdx ? $r('app.color.ybg_white') : $r('app.color.common_color_3'))
      .textAlign(TextAlign.Center)
      .maxLines(1)
      .width('100%')
      .padding({ top: 6, bottom: 6 })
      .borderRadius(6)
      .backgroundColor(index === this.gradeIdx ? $r('app.color.ybg_blue') : $r('app.color.common_color_5'))
      .hoverEffect(HoverEffect.Highlight)
      .onClick(() => {
        this.gradeIdx = index;
      })
  }

  /** audit_course_choose_major_item：白底 16fp #999 → 选中 #18B4ED，padH10 padV10 */
  @Builder
  majorItem(item: AuditMajorEntry, index: number) {
    Text(item.zymc)
      .fontSize(16)
      .fontColor(index === this.majorIdx ? $r('app.color.ybg_blue') : $r('app.color.common_color_3'))
      .maxLines(1)
      .textOverflow({ overflow: TextOverflow.Ellipsis })
      .width('100%')
      .padding({ top: 10, right: 10, bottom: 10 })
      .backgroundColor($r('app.color.white'))
      .hoverEffect(HoverEffect.Highlight)
      .onClick(() => {
        this.majorIdx = index;
        this.chosenMajorText = index === 0 ? '全部' : item.zymc;
      })
  }

  /** ChooseCourseFilterPopup：全屏半透明遮罩 + 自适应宽/高 Scroll 面板 + 自适应列数年级网格 */
  @Builder
  filterPopup() {
    Column() {
      Scroll() {
        Column() {
          Row()
            .width('100%')
            .height(8)
            .backgroundColor($r('app.color.common_color_6'))
          Row() {
            Text('年级')
              .fontSize(17)
              .fontColor($r('app.color.common_color_1'))
              .margin({ right: 27 })
            Grid() {
              ForEach(this.gradeOptions, (item: AuditGradeEntry, index: number) => {
                GridItem() {
                  this.gradeItem(item, index)
                }
              }, (item: AuditGradeEntry) => 'gr' + item.nj + '_' + item.njmc)
            }
            .columnsTemplate(AdaptiveLayoutHelper.buildColumnsTemplate(
              BreakpointSystem.getGridColumns(this.currentBreakpoint, 3)
            ))
            .columnsGap(22)
            .rowsGap(10)
            .layoutWeight(1)
            .height(AdaptiveLayoutHelper.computeGridHeightVp(
              this.gradeOptions.length,
              BreakpointSystem.getGridColumns(this.currentBreakpoint, 3),
              34,
              10,
              0
            ))
            .margin({ right: 12 })
          }
          .width('100%')
          .padding({ left: 12, right: 0, top: 12, bottom: 15 })
          .alignItems(VerticalAlign.Center)
          Row()
            .width('100%')
            .height(8)
            .backgroundColor($r('app.color.common_color_6'))
          Column() {
            Row() {
              Text('专业')
                .fontSize(17)
                .fontColor($r('app.color.common_color_1'))
                .margin({ top: 20, bottom: 20 })
              Text(this.chosenMajorText)
                .fontSize(17)
                .fontColor($r('app.color.common_color_1'))
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
                .margin({ left: 60 })
                .layoutWeight(1)
              Image(this.showMajors ? $r('app.media.arrow_up_blue_desk_widget') :
                $r('app.media.arrow_down_blue_desk_widget'))
                .width(39)
                .height(32.5)
                .padding(12)
                .hoverEffect(HoverEffect.Highlight)
                .onClick(() => {
                  this.showMajors = !this.showMajors;
                })
            }
            .width('100%')
            .padding({ left: 12 })
            .alignItems(VerticalAlign.Center)
            if (this.showMajors) {
              Divider()
                .color($r('app.color.common_color_5'))
                .strokeWidth(0.5)
                .width('100%')
              Column() {
                ForEach(this.majorOptions, (item: AuditMajorEntry, index: number) => {
                  this.majorItem(item, index)
                }, (item: AuditMajorEntry) => 'mj' + item.zydm + '_' + item.zymc)
              }
              .width('100%')
              .padding({ left: 60 })
              .backgroundColor($r('app.color.divider_grey'))
              .alignItems(HorizontalAlign.Start)
            }
          }
          .width('100%')
          .alignItems(HorizontalAlign.Start)
        }
        .width('100%')
      }
      .width('100%')
      .constraintSize({
        maxWidth: AdaptiveLayoutHelper.getSheetMaxWidth(this.currentBreakpoint, this.windowWidthVp),
        maxHeight: BreakpointSystem.getDialogMaxHeight(this.windowHeightVp)
      })
      .backgroundColor($r('app.color.ybg_white'))
      .borderRadius(this.currentBreakpoint === 'xs' || this.currentBreakpoint === 'sm' ?
        0 : { bottomLeft: 12, bottomRight: 12 })
      .clip(true)
      .onClick(() => {
        // 拦截面板内点击
      })
      // 面板以下透明区触摸 dismiss → applyFilter 回调
      Column()
        .width('100%')
        .layoutWeight(1)
        .onClick(() => {
          this.applyFilter();
        })
    }
    .width('100%')
    .height('100%')
    .alignItems(HorizontalAlign.Center)
    .justifyContent(FlexAlign.Start)
    .backgroundColor('#66000000')
  }

  build() {
    Stack() {
      Column() {
        TitleBar({
          title: this.listTitle,
          showBack: true,
          rightText: this.supportFilter ? (this.filterOpen ? '确认' : '筛选') : '',
          onRightClick: (): void => {
            if (this.showFilter) {
              this.applyFilter();
            } else {
              this.openFilterPopup();
            }
          }
        })
        // common_refresh_lv_with_search_box：搜索框 FrameLayout(ybg_white pad T/B 10, marginH 10)
        Column() {
          Column() {
            this.searchBox()
          }
          .width('100%')
          .constraintSize({ maxWidth: BreakpointSystem.getContentMaxWidth(this.currentBreakpoint) })
          .alignSelf(ItemAlign.Center)
          .padding({ left: 10, right: 10 })
        }
        .width('100%')
        .padding({ top: 10, bottom: 10 })
        .backgroundColor($r('app.color.ybg_white'))
        // divider_horizontal_grey_thin
        Divider()
          .color($r('app.color.common_color_5'))
          .strokeWidth(0.5)
          .width('100%')
        // MultiStateView：loading/empty/error/content(List)
        Stack() {
          if (this.loadState === 1) {
            LoadingProgress()
              .width(72)
              .height(72)
              .color($r('app.color.ybg_blue'))
          } else if (this.loadState === 2) {
            Scroll() {
              Column() {
                Image($r('app.media.no_report'))
                  .width(220)
                  .height(150)
                  .objectFit(ImageFit.Contain)
                  .margin({ left: 25, right: 25 })
              }
              .width('100%')
              .constraintSize({ minHeight: 280 })
              .justifyContent(FlexAlign.Center)
            }
            .width('100%')
            .height('100%')
          } else if (this.loadState === 3) {
            Scroll() {
              Column() {
                Image($r('app.media.empty_error'))
                  .width(220)
                  .height(150)
                  .objectFit(ImageFit.Contain)
                  .margin({ left: 25, right: 25 })
                Text(this.errorTips)
                  .fontSize(12)
                  .fontColor('#CECECE')
                  .textAlign(TextAlign.Center)
                  .padding(15)
              }
              .width('100%')
              .constraintSize({ minHeight: 280 })
              .justifyContent(FlexAlign.Center)
            }
            .width('100%')
            .height('100%')
          } else {
            Row() {
              List() {
                ForEach(this.rows, (item: AuditCourseNameEntry, index: number) => {
                  ListItem() {
                    this.courseRow(item, index)
                  }
                }, (item: AuditCourseNameEntry, index: number) => 'row' + item.kcmc + '_' + index)
              }
              .width('100%')
              .height('100%')
              .constraintSize({ maxWidth: BreakpointSystem.getContentMaxWidth(this.currentBreakpoint) })
              .contentEndOffset(this.avoidAreaBottomVp > 0 ? this.avoidAreaBottomVp : 0)
              .scrollBar(BarState.Off)
              .onReachEnd(() => {
                this.loadMore();
              })
            }
            .width('100%')
            .height('100%')
            .justifyContent(FlexAlign.Center)
          }
        }
        .width('100%')
        .layoutWeight(1)
        .backgroundColor($r('app.color.main_bg'))
      }
      .width('100%')
      .height('100%')
      if (this.showFilter) {
        this.filterPopup()
      }
    }
    .width('100%')
    .height('100%')
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.BOTTOM])
  }
}
