import { router } from '@kit.ArkUI';
import { HttpClient } from '../network/HttpClient';
import { LoginSession } from '../network/LoginSession';
import { ApiResponse } from '../model/ResponseModel';
import { PreferencesUtil } from '../data/PreferencesUtil';
import { Constants } from '../data/Constants';
import { PasteHelper } from '../common/PasteHelper';
import { BreakpointSystem } from '../common/BreakpointSystem';

/**
 * 应用搜索页 — 源码级复刻 AppSearchActivity（newUI 包，/app/AppSearchActivity，
 * 主页工作台 WorkFragment 搜索图标 → e.a.z 进入）。
 * 源码：mobile_campus_activity_app_search 布局 + EventBus 数据链（36→宿主回 37=应用分组）
 * 的 HAP 等价 = 自拉宿主同源接口 /api/app/list（YDXYAppModel.V0，type="1"）+ /api/app/getUnreadNum
 * （AppFragmentV2.i() 宿主未读链，AppSearchAdapter.convert 渲染 unReadTip/unReadNum）。
 * 交互全链：IME 搜索（actionSearch=3）→ 空 toast"请输入搜索内容" → g3 历史去重插头 10 条
 * （x.f("appSearchHistory")）→ b3 chips 刷新 → 隐藏历史区显示列表 → 本地过滤 YYMC.contains →
 * 空态 layout_edit_common_app_search_empty；点击应用：已登录（d.b.b()=session_key 非空）→
 * 跳应用（EventBus 38→39→module/app/util/a.f 分流等价）；未登录 LX!=1 → WebView
 * （navigationBarTitle/url/isZoom）；ivDelete 清历史确认弹窗"确认删除全部历史记录？取消/确认"。
 */
/** /api/app/list 服务端下发应用项（AppBean 下发字段 + AppSearchAdapter 渲染字段） */
class SearchAppBean {
  yyid: string = '';
  yymc: string = '';
  lx: string = '';
  url: string = '';
  yytb: string = '';
  /** AppSearchAdapter.convert：unReadTip 非空优先显示，否则 unReadNum（>99→"99+"） */
  unReadNum: number = 0;
  unReadTip: string = '';
}

const HISTORY_KEY: string = 'appSearchHistory';
const HISTORY_MAX: number = 10;

@Entry
@Component
struct AppSearchPage {
  @State searchText: string = '';
  @State historyList: string[] = [];
  /** 历史区/列表区互斥显隐（源码 llSearchHistory / mRecyclerView visibility） */
  @State showHistory: boolean = true;
  @State resultList: SearchAppBean[] = [];
  @State searched: boolean = false;
  @StorageProp('currentBreakpoint') currentBreakpoint: string = 'sm';
  @StorageProp('avoidAreaBottomVp') avoidAreaBottomVp: number = 0;
  @StorageProp('avoidAreaLeftVp') avoidAreaLeftVp: number = 0;
  @StorageProp('avoidAreaRightVp') avoidAreaRightVp: number = 0;
  @StorageProp('keyboardHeightVp') keyboardHeightVp: number = 0;
  /** 全量应用池（37 数据等价：/api/app/list 全部 DATA 扁平 + getUnreadNum 合并） */
  private allApps: SearchAppBean[] = [];

  aboutToAppear(): void {
    this.loadHistory();
    this.loadApps();
  }

  /** X2()：gson 解析 appSearchHistory（缺省 "[]"） */
  private async loadHistory(): Promise<void> {
    const raw: string = await PreferencesUtil.getString(HISTORY_KEY, '[]');
    try {
      const list: string[] = JSON.parse(raw) as string[];
      this.historyList = list;
    } catch (error) {
      this.historyList = [];
    }
    if (this.searchText === '') {
      this.showHistory = this.historyList.length > 0;
    }
  }

  /** b3()：历史 chips 刷新（空历史 → llSearchHistory gone） */
  private async refreshHistory(): Promise<void> {
    await this.loadHistory();
  }

  /**
   * g3(str)：历史保存 — Y2 命中先移除 → add(0) → 超过 10 条截断 → x.f 持久化
   */
  private async saveHistory(keyword: string): Promise<void> {
    const list: string[] = this.historyList.slice();
    const idx: number = list.indexOf(keyword);
    if (idx >= 0) {
      list.splice(idx, 1);
    }
    list.unshift(keyword);
    const trimmed: string[] = list.length > HISTORY_MAX ? list.slice(0, HISTORY_MAX) : list;
    this.historyList = trimmed;
    await PreferencesUtil.putString(HISTORY_KEY, JSON.stringify(trimmed));
  }

  /** T2()：确认后清空历史 → x.f(key,"[]") + b3() */
  private async clearHistory(): Promise<void> {
    await PreferencesUtil.putString(HISTORY_KEY, '[]');
    this.historyList = [];
  }

  /**
   * V0 宿主数据链等价：GET /api/app/list {zdlx:'3',khdbb,type:'1'}（YDXYAppModel.V0 实参）
   * + GET /api/app/getUnreadNum {zdlx,khdbb}（X0）→ YYID 匹配填 unReadNum/unReadTip（e3）
   */
  private loadApps(): void {
    const params: Record<string, Object> = {
      'zdlx': '3',
      'khdbb': Constants.CLIENT_VERSION,
      'type': '1'
    };
    HttpClient.getWithEncParams('/mobileapi_ydxy/api/app/list', params)
      .then(async (response: ApiResponse<Object>) => {
        const apps: SearchAppBean[] = [];
        if (HttpClient.normalizeCode(response.code) === 0 && typeof response.data === 'string') {
          try {
            const raw: Object[] = JSON.parse(response.data as string) as Object[];
            for (const one of raw) {
              const rec = one as Record<string, Object>;
              const dataArr: Object[] = Array.isArray(rec['DATA']) ? rec['DATA'] as Object[] : [];
              for (const d of dataArr) {
                const dr = d as Record<string, Object>;
                const bean = new SearchAppBean();
                const pick = (k: string): string => {
                  const v: Object = dr[k];
                  return typeof v === 'string' ? v as string : '';
                };
                bean.yyid = pick('YYID');
                bean.yymc = pick('YYMC');
                bean.lx = pick('LX');
                bean.url = pick('URL');
                bean.yytb = pick('YYTB');
                apps.push(bean);
              }
            }
          } catch (err) {
            // 解析失败保持空池（禁 mock：无数据即空态）
          }
        }
        await this.mergeUnread(apps);
        this.allApps = apps;
        if (this.searchText !== '') {
          this.filterResult();
        }
      })
      .catch(() => {
        // 网络失败保持空池（禁 mock）
      });
  }

  /** e3(list)：getUnreadNum 响应按 YYID 匹配 — READ_NUM 纯数字→unReadNum，否则 unReadTip */
  private async mergeUnread(apps: SearchAppBean[]): Promise<void> {
    const params: Record<string, Object> = {
      'zdlx': '3',
      'khdbb': Constants.CLIENT_VERSION
    };
    const response: ApiResponse<Object> = await HttpClient.getWithEncParams('/mobileapi_ydxy/api/app/getUnreadNum', params);
    if (HttpClient.normalizeCode(response.code) !== 0 || typeof response.data !== 'string') {
      return;
    }
    try {
      const unread: Object[] = JSON.parse(response.data as string) as Object[];
      for (const one of unread) {
        const rec = one as Record<string, Object>;
        const yyid: string = typeof rec['YYID'] === 'string' ? rec['YYID'] as string : '';
        const readNum: string = typeof rec['READ_NUM'] === 'string' ? rec['READ_NUM'] as string : '';
        for (const app of apps) {
          if (app.yyid === yyid) {
            if (/^[0-9]+$/.test(readNum)) {
              app.unReadNum = Number(readNum);
              app.unReadTip = '';
            } else {
              app.unReadTip = readNum;
              app.unReadNum = 0;
            }
          }
        }
      }
    } catch (err) {
      // 未读解析失败不影响列表主体
    }
  }

  /** U2(list)：本地过滤 YYMC.contains(trim) */
  private filterResult(): void {
    const keyword: string = this.searchText.trim();
    this.resultList = this.allApps.filter((app: SearchAppBean): boolean =>
      app.yymc !== '' && app.yymc.includes(keyword));
  }

  /** f3()：搜索动作（IME actionSearch / chip 点击） */
  private doSearch(): void {
    const keyword: string = this.searchText.trim();
    if (keyword === '') {
      this.getUIContext().getPromptAction().showToast({ message: '请输入搜索内容' });
      return;
    }
    this.saveHistory(keyword);
    this.filterResult();
    this.searched = true;
    // r.setVisibility(8); s.setVisibility(0)：历史区隐藏、列表区显示
    this.showHistory = false;
  }

  /** m()（列表项点击）：d.b.b()=已登录 → 跳应用（util/a.f 分流等价）；未登录 LX!=1 → WebView */
  private openApp(app: SearchAppBean): void {
    const logined: boolean = LoginSession.sessionKey !== '';
    if (logined || app.lx === '1') {
      this.dispatchApp(app);
      return;
    }
    // bundle{navigationBarTitle=YYMC, url=URL, isZoom=j.e.a(YYID)} → /app/web
    router.pushUrl({
      url: 'pages/WebViewPage',
      params: { navigationBarTitle: app.yymc, url: app.url, isZoom: false }
    });
  }

  /**
   * module/app/util/a.f(context, appBean) 分流（Index.dispatchApp 同口径）：
   * 1) YYID 原生映射命中 → 原生页；2) 其余全部走 LightAppPage（APK 非原生即 LightActivity），
   * 由 I2() 矩阵拼 springboard/单点/直载，服务端 YYID 一律可免登打开，绝无“功能对接中”死路。
   */
  private dispatchApp(app: SearchAppBean): void {
    const target: string | undefined = this.nativeMap().get(app.yyid.toLowerCase());
    if (target !== undefined) {
      router.pushUrl({ url: target });
      return;
    }
    // 任何未映射的 YYID（含 LX=1）都交给 LightAppPage 的 springboard 跳板打开
    router.pushUrl({
      url: 'pages/LightAppPage',
      params: { title: app.yymc, url: app.url, yyid: app.yyid, lx: app.lx === '' ? '2' : app.lx }
    });
  }

  /** LX=1 原生 YYID → HAP 原生页映射（Index.YYID_ROUTES 同口径，页面间不互相依赖） */
  private nativeMap(): Map<string, string> {
    return new Map([
      ['timetable', 'pages/SchedulePage'],
      ['score', 'pages/ScorePage'],
      ['mylibrary', 'pages/BookBorrowReportPage'],
      ['campusview', 'pages/SchoolSceneryPage'],
      // [W26 partial-finish] 同 Index.YYID_ROUTES 考证修正：sdgy_schoolIntro → SchoolSituationLaunch
      //   → /school/situation → SchoolSituationActivity（W25 SchoolSituationPage）
      ['schoolintro', 'pages/SchoolSituationPage'],
      ['studyreport', 'pages/StudyReportPage'],
      ['schedule', 'pages/ScheduleMainActivity'],
      ['news', 'pages/NewsPage'],
      ['contact', 'pages/ContactPage'],
      ['meeting', 'pages/MeetingPage'],
      ['exam', 'pages/ExamPage'],
      ['attendance', 'pages/AttendancePage'],
      ['supervise', 'pages/SupervisePage'],
      ['workapply', 'pages/WorkApplyPage'],
      ['receipt', 'pages/ReceiptListPage'],
      ['market', 'pages/MarketPage']
    ]);
  }

  /** AppSearchAdapter.convert 图标：YYTB UUID → 服务端图标 URL（CommonFactory.a 公式） */
  private iconUrl(app: SearchAppBean): string {
    if (app.yyid === 'yibaogao' || app.yytb === '') {
      return '';
    }
    return Constants.SOCKET_HOST + '/mobileapi_ydxy/open/image/' + app.yytb;
  }

  /** tvUnreadNum 文案：unReadTip 优先 → unReadNum>99→"99+" → 数字 → ≤0 无 */
  private unreadText(app: SearchAppBean): string {
    if (app.unReadTip !== '') {
      return app.unReadTip;
    }
    if (app.unReadNum > 99) {
      return '99+';
    }
    if (app.unReadNum > 0) {
      return String(app.unReadNum);
    }
    return '';
  }

  /** R2(str)：chip 文案 ≤7 字原样，否则前 7 字+"..." */
  private chipText(raw: string): string {
    return raw.length <= 7 ? raw : raw.substring(0, 7) + '...';
  }

  @Builder
  historyChip(keyword: string) {
    Text(this.chipText(keyword))
      .fontSize(16)
      .fontColor('#333333')
      .maxLines(1)
      .textOverflow({ overflow: TextOverflow.Ellipsis })
      .padding({ left: 16, right: 16, top: 7, bottom: 7 })
      .borderRadius(8)
      .backgroundColor('#f2f2f2')
      .margin({ left: 0, right: 16, top: 8, bottom: 8 })
      .hoverEffect(HoverEffect.Highlight)
      .onClick(() => {
        // o(str)：回填 + 光标末位 + f3()
        this.searchText = keyword;
        this.doSearch();
      })
  }

  @Builder
  appRow(app: SearchAppBean) {
    Column() {
      Row() {
        Stack({ alignContent: Alignment.TopEnd }) {
          if (this.iconUrl(app) === '') {
            Image($r('app.media.default_app_icon'))
              .width(40)
              .height(40)
              .objectFit(ImageFit.Cover)
              .alignSelf(ItemAlign.End)
              .margin({ top: 5 })
          } else {
            Image(this.iconUrl(app))
              .width(40)
              .height(40)
              .objectFit(ImageFit.Cover)
              .alt($r('app.media.default_app_icon'))
              .alignSelf(ItemAlign.End)
              .margin({ top: 5 })
          }
          if (this.unreadText(app) !== '') {
            Text(this.unreadText(app))
              .fontSize(10)
              .fontColor(Color.White)
              .textAlign(TextAlign.Center)
              .minFontScale(1)
              .maxLines(1)
              .padding({ left: 3.5, right: 3.5 })
              .constraintSize({ minWidth: 18 })
              .height(18)
              .borderRadius(8)
              .backgroundColor($r('app.color.read_dot_bg'))
          }
        }
        .width(50)
        .height(45)

        Text(app.yymc)
          .fontSize(16)
          .fontColor('#000000')
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .padding({ left: 12, right: 12 })
          .layoutWeight(1)

        Image($r('app.media.icon_arrow_gray_right'))
          .width(16)
          .height(16)
          .objectFit(ImageFit.Contain)
      }
      .width('100%')
      .padding(12)
      .borderRadius(8)
      .backgroundColor('#F8F8F8')
      .alignItems(VerticalAlign.Center)
      .hoverEffect(HoverEffect.Highlight)
      .onClick(() => {
        this.openApp(app);
      })
    }
    .width('100%')
    .padding({ left: 8, right: 8, top: 6, bottom: 6 })
  }

  /** layout_edit_common_app_search_empty 空态 */
  @Builder
  searchEmpty() {
    Column() {
      Image($r('app.media.icon_empty_common_app_search'))
        .objectFit(ImageFit.Contain)
        .alignSelf(ItemAlign.Center)
      Text('没有找到相关内容')
        .fontSize(14)
        .fontColor($r('app.color.common_color_1'))
        .textAlign(TextAlign.Center)
        .margin({ top: 4 })
      Text('换个关键词试试吧~')
        .fontSize(12)
        .fontColor($r('app.color.explain_color'))
        .textAlign(TextAlign.Center)
        .margin({ top: 4 })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .backgroundColor($r('app.color.white'))
  }

  build() {
    Column() {
      // 搜索行：actionBarSize 白底 + BL 搜索框(圆角8 #f2f2f2 14sp icon_search_gray) + 取消
      Column() {
        Row() {
          Stack({ alignContent: Alignment.End }) {
            Row() {
              Image(this.searchText === '' ? $r('app.media.icon_search_gray') : $r('app.media.icon_search_black'))
                .width(16)
                .height(16)
                .objectFit(ImageFit.Contain)
                .margin({ left: 10 })

              TextInput({ text: this.searchText, placeholder: '请输入应用名称搜索...' })
                .fontSize(14)
                .fontColor($r('app.color.common_color_1'))
                .placeholderColor($r('app.color.explain_color'))
                .placeholderFont({ size: 14 })
                .backgroundColor(Color.Transparent)
                .border({ width: 0 })
                .padding({ left: 8, right: 40 })
                .layoutWeight(1)
                .height(34)
                .enterKeyType(EnterKeyType.Search)
                .defaultFocus(true)
                .onChange((value: string) => {
                  // l TextWatcher：空 → 历史区显/列表隐 + ivClear 隐；非空 → ivClear 显
                  this.searchText = value;
                  if (value === '') {
                    this.showHistory = this.historyList.length > 0;
                    this.searched = false;
                  }
                })
                .onSubmit(() => {
                  this.doSearch();
                })
            }
            .width('100%')
            .height(34)
            .borderRadius(8)
            .backgroundColor('#f2f2f2')
            .alignItems(VerticalAlign.Center)

            if (this.searchText !== '') {
              Image($r('app.media.icon_search_history_clear'))
                .width(40)
                .height(40)
                .objectFit(ImageFit.None)
                .hoverEffect(HoverEffect.Highlight)
                .onClick(() => {
                  // q()：清空输入 + ivClear 隐
                  this.searchText = '';
                  this.searched = false;
                  this.showHistory = this.historyList.length > 0;
                })
            }
          }
          .layoutWeight(1)
          .margin({ left: 16 })

          Row() {
            PasteButton({
              icon: PasteIconStyle.LINES,
              text: PasteDescription.PASTE,
              buttonType: ButtonType.Capsule
            })
              .height(30)
              .fontSize(12)
              .iconSize(12)
              .fontColor($r('app.color.white'))
              .iconColor($r('app.color.white'))
              .backgroundColor($r('app.color.sdmu_primary'))
              .padding({ left: 10, right: 10, top: 4, bottom: 4 })
              .onClick(async (_event: ClickEvent, result: PasteButtonOnClickResult) => {
                if (result !== PasteButtonOnClickResult.SUCCESS) {
                  this.getUIContext().getPromptAction().showToast({ message: '未获得剪贴板授权' });
                  return;
                }
                const res = await PasteHelper.readPlainTextFromSystemPasteboard();
                if (!res.success) {
                  this.getUIContext().getPromptAction().showToast({ message: res.message });
                  return;
                }
                const keyword: string = PasteHelper.normalizeSingleLine(res.text, 40);
                if (keyword === '') {
                  this.getUIContext().getPromptAction().showToast({ message: '剪贴板暂无文本内容' });
                  return;
                }
                this.searchText = keyword;
                this.doSearch();
              })
          }
          .margin({ left: 8 })

          Text('取消')
            .fontSize(14)
            .fontColor($r('app.color.sdmu_primary'))
            .padding({ left: 16, right: 20 })
            .height('100%')
            .hoverEffect(HoverEffect.Highlight)
            .onClick(() => {
              // p()：finish
              router.back();
            })
        }
        .width('100%')
        .height(45)
        .padding({ left: this.avoidAreaLeftVp, right: this.avoidAreaRightVp })
        .constraintSize({ maxWidth: BreakpointSystem.getContentMaxWidth(this.currentBreakpoint) })
        .alignSelf(ItemAlign.Center)
        .alignItems(VerticalAlign.Center)
      }
      .width('100%')
      .backgroundColor($r('app.color.white'))
      .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP])

      if (!this.searched && this.showHistory) {
        // llSearchHistory：paddingTop16 + 头行（"历史搜索" 14sp #555555 + ivDelete）+ FlowLayout chips
        Scroll() {
          Column() {
            Row() {
              Text('历史搜索')
                .fontSize(14)
                .fontColor('#555555')
                .padding({ left: 16, right: 16, top: 8, bottom: 8 })
                .layoutWeight(1)
              Image($r('app.media.icon_delete'))
                .width(20)
                .height(20)
                .objectFit(ImageFit.Contain)
                .padding({ left: 16, right: 16 })
                .hoverEffect(HoverEffect.Highlight)
                .onClick(() => {
                  // r()：确认弹窗 → T2() 清空
                  this.getUIContext().showAlertDialog({
                    title: '',
                    message: '确认删除全部历史记录？',
                    primaryButton: {
                      value: '取消',
                      action: () => {
                      }
                    },
                    secondaryButton: {
                      value: '确认',
                      action: () => {
                        this.clearHistory();
                      }
                    }
                  });
                })
            }
            .width('100%')
            .alignItems(VerticalAlign.Center)

            Flex({
              direction: FlexDirection.Row,
              wrap: FlexWrap.Wrap,
              justifyContent: FlexAlign.Start,
              alignItems: ItemAlign.Center
            }) {
              ForEach(this.historyList, (keyword: string) => {
                this.historyChip(keyword)
              }, (keyword: string) => 'chip_' + keyword)
            }
            .width('100%')
            .padding({ left: 16, right: 16, top: 8, bottom: 8 })
          }
          .width('100%')
          .constraintSize({ maxWidth: BreakpointSystem.getContentMaxWidth(this.currentBreakpoint) })
          .alignSelf(ItemAlign.Center)
          .padding({
            top: 16,
            left: this.avoidAreaLeftVp,
            right: this.avoidAreaRightVp,
            bottom: this.keyboardHeightVp + this.avoidAreaBottomVp
          })
          .backgroundColor($r('app.color.white'))
        }
        .width('100%')
        .layoutWeight(1)
        .scrollBar(BarState.Off)
        .align(Alignment.Top)
      } else {
        // mRecyclerView：结果列表（空态 = layout_edit_common_app_search_empty）
        Column() {
          if (this.resultList.length === 0) {
            this.searchEmpty()
          } else {
            List() {
              ForEach(this.resultList, (app: SearchAppBean) => {
                ListItem() {
                  this.appRow(app)
                }
              }, (app: SearchAppBean) => 'app_' + app.yyid + '_' + app.yymc)
            }
            .width('100%')
            .height('100%')
            .contentEndOffset(this.keyboardHeightVp + this.avoidAreaBottomVp)
            .scrollBar(BarState.Off)
            .backgroundColor($r('app.color.white'))
          }
        }
        .width('100%')
        .constraintSize({ maxWidth: BreakpointSystem.getContentMaxWidth(this.currentBreakpoint) })
        .alignSelf(ItemAlign.Center)
        .padding({ left: this.avoidAreaLeftVp, right: this.avoidAreaRightVp })
        .layoutWeight(1)
        .backgroundColor($r('app.color.white'))
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.white'))
  }
}
