import { LoginSession } from '../network/LoginSession';
import { HttpClient } from '../network/HttpClient';
import { ApiService } from '../network/ApiService';
import { ApiResponse } from '../model/ResponseModel';
import { router } from '@kit.ArkUI';
import { PreferencesUtil } from '../data/PreferencesUtil';
import { Constants } from '../data/Constants';
import { WMHTab } from '../components/WMHTab';
import { ICampusTab } from '../components/ICampusTab';
import { IOfficeTab } from '../components/IOfficeTab';
import { MineTab } from '../components/MineTab';
import { BreakpointSystem } from '../common/BreakpointSystem';
import { ImmersiveLightHelper } from '../common/ImmersiveLightHelper';
import {
  PerformanceSchedulerHelper,
  FAST_SCENE_PAGE_TRANSITION,
  FAST_DURATION_SHORT
} from '../common/PerformanceSchedulerHelper';

/** APK 应用宫格项（服务端下发 7 组，本清单为 2026-11-17 实拍结果） */
class AppGridItem {
  name: string;
  icon: Resource;
  target: string;
  /** 轻应用 YYID（服务端下发字段；原生页为空串） */
  yyid: string;
  /** 轻应用 H5 地址（服务端下发 LX=2 时的 URL；LX=1 为空串） */
  url: string;

  constructor(name: string, icon: Resource, target: string, yyid: string, url: string = '') {
    this.name = name;
    this.icon = icon;
    this.target = target;
    this.yyid = yyid;
    this.url = url;
  }
}

/** 服务端下发分组（/api/app/list 响应同构：YYFL 组名 + DATA 应用数组） */
class ServerAppItem {
  yyid: string = '';
  yymc: string = '';
  lx: string = '';
  url: string = '';
  yytb: string = '';
  pxh: string = '';
}

class ServerAppGroup {
  name: string;
  apps: ServerAppItem[];

  constructor(name: string) {
    this.name = name;
    this.apps = [];
  }
}

/**
 * 服务端应用图标（APK CommonFactory.a：ServiceBaseUrl.d() + "/mobileapi_ydxy/open/image/" + YYTB；
 * d.d() = 服务器 serverUrl，即 Constants.SOCKET_HOST）。
 * 加载失败回落本地占位图，与 APK Glide placeholder/error 行为一致。
 */
@Component
struct ServerIcon {
  /** 图标网络地址；空串时直接显示本地占位 */
  @Prop url: string = '';
  @State private iconFailed: boolean = false;

  build() {
    if (this.url === '' || this.iconFailed) {
      Image($r('app.media.default_app_icon'))
        .width(34)
        .height(34)
        .objectFit(ImageFit.Contain)
    } else {
      Image(this.url)
        .width(34)
        .height(34)
        .objectFit(ImageFit.Contain)
        // 加载过程中显示占位（Glide placeholder 同款体验）
        .alt($r('app.media.default_app_icon'))
        .onError(() => {
          this.iconFailed = true;
        })
    }
  }
}

/** LX=1 原生 YYID → HAP 原生页映射（原 APK ARouter 同口径，小写） */
const YYID_ROUTES: Map<string, string> = new Map([
  ['timetable', 'pages/SchedulePage'],
  ['score', 'pages/ScorePage'],
  ['mylibrary', 'pages/BookBorrowReportPage'],
  ['campusview', 'pages/SchoolSceneryPage'],
  // [W26 partial-finish] 路由考证修正：APK 无 SchoolIntroActivity——宫格 yyid=schoolIntro
  //   （manifest action sdgy_schoolIntro L448-453）→ SchoolSituationLaunchActivity（f1() g2(a.b1
  //   =/school/situation，base/e/a.java L121-122 + strings L643-644 + ARouter$$Group$$school
  //   L18 /school/situation→SchoolSituationActivity）→ SchoolSituationPage（W25 源码级实现，
  //   /open/schoolIntro/index 实测 200 真实数据）。原 SchoolIntroPage 占位页无 APK 对应物已移除。
  ['schoolintro', 'pages/SchoolSituationPage'],
  ['address_book', 'pages/ContactPage'],
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
  ['market', 'pages/MarketPage'],
  ['inspection', 'pages/InspectionRecordPage'],
  ['dormitorycheck', 'pages/InspectionRecordPage']
]);

@Component
struct AppsTab {
  /** 服务端下发分组（/api/app/list 成功时置非空，渲染走数据驱动分支） */
  @State serverGroups: ServerAppGroup[] = [];
  /** 数据源标记：server=服务端下发 / local=本地清单 */
  @State dataSource: string = 'local';
  /** onActivityResult(5467) 返回刷新等价：编辑常用应用页 toggle 成功后置时间戳，本页监听重拉 */
  @StorageLink('common_app_changed') @Watch('onCommonAppChanged') commonAppChanged: number = 0;
  @StorageProp('currentBreakpoint') currentBreakpoint: string = 'sm';
  @StorageProp('heightBreakpoint') heightBreakpoint: string = 'lg';
  @StorageProp('isLandscape') isLandscape: boolean = false;
  @State searchTrigger: number = -1;

  private useSideRail(): boolean {
    return BreakpointSystem.shouldUseSideRail(
      this.currentBreakpoint,
      this.heightBreakpoint,
      this.isLandscape
    );
  }

  private gridTemplate(): string {
    const cols: number = BreakpointSystem.getAppGridColumns(this.currentBreakpoint);
    let tpl: string = '1fr';
    for (let i = 1; i < cols; i++) {
      tpl += ' 1fr';
    }
    return tpl;
  }

  aboutToAppear(): void {
    this.loadApps();
  }

  /** AppFragmentV2.onActivityResult：i3==-1 && i2==5467 → clear + c2() + b2(true) 重拉 */
  onCommonAppChanged(propName: string): void {
    if (this.commonAppChanged > 0) {
      this.loadApps();
    }
  }

  /** 复刻原 APK YDXYAppModel.V0：GET /api/app/list?data=enc({zdlx,khdbb,type}) */
  private loadApps(): void {
    const params: Record<string, Object> = {
      'zdlx': '3',
      'khdbb': Constants.CLIENT_VERSION,
      'type': '1'
    };
    HttpClient.getWithEncParams('/mobileapi_ydxy/api/app/list', params)
      .then((response: ApiResponse<Object>) => {
        if (ApiService.isSuccess(response) && typeof response.data === 'string') {
          try {
            const raw: Object[] = JSON.parse(response.data as string) as Object[];
            const groups: ServerAppGroup[] = [];
            for (const one of raw) {
              const rec = one as Record<string, Object>;
              const groupName: string = typeof rec['YYFL'] === 'string' ? rec['YYFL'] as string : '';
              const dataArr: Object[] = Array.isArray(rec['DATA']) ? rec['DATA'] as Object[] : [];
              if (groupName === '' || dataArr.length === 0) {
                continue;
              }
              const group = new ServerAppGroup(groupName);
              for (const d of dataArr) {
                const dr = d as Record<string, Object>;
                const item = new ServerAppItem();
                const pick = (k: string): string => {
                  const v: Object = dr[k];
                  return typeof v === 'string' ? v as string : '';
                };
                item.yyid = pick('YYID');
                item.yymc = pick('YYMC');
                item.lx = pick('LX');
                item.url = pick('URL');
                item.yytb = pick('YYTB');
                item.pxh = pick('PXH');
                if (item.yymc.includes('付款码') || item.yyid === 'ewm') {
                  AppStorage.setOrCreate<string>('ecard_pay_yyid', item.yyid);
                  AppStorage.setOrCreate<string>('ecard_pay_lx', item.lx);
                  AppStorage.setOrCreate<string>('ecard_pay_url', item.url);
                }
                group.apps.push(item);
              }
              if (group.apps.length > 0) {
                groups.push(group);
              }
            }
            if (groups.length > 0) {
              this.serverGroups = groups;
              this.dataSource = 'server';
            }
          } catch (err) {
            // 解析失败保留本地清单
          }
        }
      })
      .catch(() => {
        // 静默保留本地清单
      });
  }

  /** 点击分发（复刻 APK module/app/util/a.java + X5LightActivity.I2() 分支）：
   *  1) YYID 原生映射命中 → HAP 原生页（课表/成绩/通讯录/督评等已翻译页）；
   *  2) 其余全部走 LightAppPage——APK 所有非原生应用都是 LightActivity，
   *     LX=2/4/8 及缺省由 LightAppPage 的 I2() 矩阵拼 springboard/单点/直载，
   *     服务端 YYID 一律可用 springboard?yyid=<YYID> 免登打开，绝无“功能对接中”死路。 */
  private dispatchApp(name: string, yyid: string, lx: string, url: string): void {
    const target: string | undefined = YYID_ROUTES.get(yyid.toLowerCase());
    if (target !== undefined) {
      router.pushUrl({ url: target });
      return;
    }
    // 有 yyid：走 LightAppPage，由其 I2() 矩阵加工（LX=2/4/8 或缺省 springboard）
    if (yyid !== '') {
      router.pushUrl({ url: 'pages/LightAppPage', params: { title: name, url: url, yyid: yyid, lx: lx } });
      return;
    }
    // 无 yyid 但有直载 URL（少数本地清单项）：LightAppPage 直载
    if (url !== '') {
      router.pushUrl({ url: 'pages/LightAppPage', params: { title: name, url: url, yyid: '', lx: lx === '' ? '2' : lx } });
      return;
    }
    this.getUIContext().getPromptAction().showToast({ message: name + ' 暂无访问地址' });
  }

  private myApps: AppGridItem[] = [
    new AppGridItem('网上办事大厅', $r('app.media.icon_work_search'), 'pages/LightAppPage', 'affairHall'),
    new AppGridItem('我的课表', $r('app.media.mobile_campus_icon_calendar'), 'pages/SchedulePage', ''),
    new AppGridItem('空闲教室', $r('app.media.mobile_campus_base_search'), 'pages/LightAppPage', 'freeClassroom'),
    new AppGridItem('我的成绩', $r('app.media.average_score'), 'pages/ScorePage', ''),
    new AppGridItem('报修服务', $r('app.media.mobile_campus_oa_repair'), 'pages/LightAppPage', 'repairService'),
    new AppGridItem('邮箱', $r('app.media.mobile_campus_email_b'), 'pages/LightAppPage', 'mail'),
    new AppGridItem('学历查询', $r('app.media.examination_term'), 'pages/LightAppPage', 'educationQuery'),
    new AppGridItem('教务系统', $r('app.media.examination_table'), 'pages/LightAppPage', 'academicSystem'),
    new AppGridItem('督导系统', $r('app.media.mobile_campus_supervise_screen'), 'pages/SupervisePage', ''),
    new AppGridItem('公寓系统', $r('app.media.mobile_campus_school_end'), 'pages/LightAppPage', 'dormitory'),
    new AppGridItem('学校查询', $r('app.media.mobile_campus_base_search'), 'pages/LightAppPage', 'schoolQuery')
  ];
  private officeApps: AppGridItem[] = [
    new AppGridItem('今日日程', $r('app.media.mobile_campus_main_message_weekplan'), 'pages/ScheduleMainActivity', ''),
    new AppGridItem('问卷课堂', $r('app.media.mobile_campus_main_message_remind'), 'pages/LightAppPage', 'YiClassroom')
  ];
  private cardApps: AppGridItem[] = [
    new AppGridItem('一卡通付款码', $r('app.media.default_app_icon'), 'pages/LightAppPage', 'ewm'),
    new AppGridItem('一卡通首页', $r('app.media.app_icon'), 'pages/LightAppPage', 'cardHome'),
    new AppGridItem('我的余额', $r('app.media.my_account'), 'pages/LightAppPage', 'cardBalance'),
    new AppGridItem('我的账单', $r('app.media.my_password'), 'pages/LightAppPage', 'cardBill'),
    new AppGridItem('挂失解挂', $r('app.media.attendance_icon'), 'pages/LightAppPage', 'cardLoss')
  ];
  private reportApps: AppGridItem[] = [
    new AppGridItem('学习报告', $r('app.media.report_blue'), 'pages/StudyReportDetailPage', ''),
    new AppGridItem('消费报告', $r('app.media.report_new'), 'pages/LightAppPage', ''),
    new AppGridItem('借阅排行', $r('app.media.report_select'), 'pages/BookBorrowReportPage', ''),
    new AppGridItem('情报报告', $r('app.media.report_uncheck'), 'pages/LightAppPage', '')
  ];
  private lightApps: AppGridItem[] = [
    new AppGridItem('校园新闻', $r('app.media.socialnew_news'), 'pages/NewsPage', 'bodaNews'),
    new AppGridItem('校园风光', $r('app.media.mobile_campus_school_way'), 'pages/SchoolSceneryPage', 'schoolScenery'),
    new AppGridItem('校园场馆', $r('app.media.mobile_campus_school_cam'), 'pages/LightAppPage', 'schoolVenue'),
    new AppGridItem('失物招领', $r('app.media.mobile_campus_page_empty'), 'pages/LightAppPage', 'lostFound'),
    new AppGridItem('校历', $r('app.media.examination_time'), 'pages/LightAppPage', 'schoolCalendar'),
    new AppGridItem('课表桌', $r('app.media.mobile_campus_timetable_ic_widget_timetable'), 'pages/SchedulePage', 'timetableDesk')
  ];

  /** 分组标题行：红色左边条 + 组名 + 收起箭头（APK 同款） */
  @Builder
  groupHeader(title: string) {
    Row() {
      Row()
        .width(3)
        .height(14)
        .backgroundColor($r('app.color.sdmu_primary'))
        .margin({ right: 8 })
      Text(title)
        .fontSize(15)
        .fontColor($r('app.color.common_color_1'))
        .layoutWeight(1)
      Image($r('app.media.arrow_up_grey_desk_widget'))
        .width(14)
        .height(14)
    }
    .width('100%')
    .height(38)
    .padding({ left: 12, right: 12 })
    .alignItems(VerticalAlign.Center)
    .backgroundColor($r('app.color.white'))
  }

  /** 4 列宫格 */
  @Builder
  gridGroup(items: AppGridItem[]) {
    Column() {
      Column() {
        Grid() {
          ForEach(items, (item: AppGridItem) => {
            GridItem() {
              Column() {
                Image(item.icon)
                  .width(34)
                  .height(34)
                  .objectFit(ImageFit.Contain)
                Text(item.name)
                  .fontSize(12)
                  .fontColor($r('app.color.common_color_1'))
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
                  .margin({ top: 8 })
              }
              .width('100%')
              .padding({ top: 14, bottom: 14 })
              .borderRadius(12)
              .alignItems(HorizontalAlign.Center)
              .clickEffect({ level: ClickEffectLevel.LIGHT, scale: 0.95 })
              .hoverEffect(HoverEffect.Highlight)
              .onClick(() => {
                if (item.url !== '') {
                  // LX=2 轻应用：直接加载服务端下发的 H5 地址
                  this.dispatchApp(item.name, item.yyid, '2', item.url);
                } else if (item.yyid !== '') {
                  // LX=1 原生：YYID 映射分发
                  this.dispatchApp(item.name, item.yyid, '1', '');
                } else {
                  router.pushUrl({ url: item.target });
                }
              })
            }
          }, (item: AppGridItem) => 'app_' + item.name)
        }
        .columnsTemplate(this.gridTemplate())
        .rowsGap(0)
        .width('100%')
        .height(Math.ceil(items.length / BreakpointSystem.getAppGridColumns(this.currentBreakpoint)) * 90)
      }
      .width('100%')
      .borderRadius(14)
      .backgroundColor(ImmersiveLightHelper.fallbackBg($r('app.color.white')))
      .systemMaterial(ImmersiveLightHelper.cardMaterial())
    }
    .width('100%')
    .padding({ left: 12, right: 12, bottom: 10 })
  }

  build() {
    Column() {
      // 标题栏：白底「应用」17fp + 红下划线 + 右上放大镜（APK 同款）
      Stack({ alignContent: Alignment.TopEnd }) {
        Column() {
          Text($r('app.string.app_label'))
            .fontSize(17)
            .fontColor($r('app.color.common_color_1'))
            .textAlign(TextAlign.Center)
          Row()
            .width(this.currentBreakpoint === 'xs' ? 120 : 210)
            .height(2)
            .backgroundColor($r('app.color.sdmu_primary'))
            .margin({ top: 6 })
        }
        .width('100%')
        .padding({ top: 14, bottom: 12 })
        .alignItems(HorizontalAlign.Center)

        SymbolGlyph($r('sys.symbol.magnifyingglass'))
          .fontSize(22)
          .fontColor([$r('app.color.common_color_1')])
          .symbolEffect(new BounceSymbolEffect(EffectScope.WHOLE, EffectDirection.UP), this.searchTrigger)
          .margin({ right: 20, top: 14 })
          .hoverEffect(HoverEffect.Highlight)
          .onClick(() => {
            this.searchTrigger = this.searchTrigger < 0 ? 1 : this.searchTrigger + 1;
            // WorkFragment$e：搜索图标 → e.a.z=/app/AppSearchActivity（HAP AppSearchPage）
            router.pushUrl({ url: 'pages/AppSearchPage' });
          })
      }
      .width('100%')
      .backgroundColor($r('app.color.white'))

      Scroll() {
        Column() {
          // 服务端下发宫格（/api/app/list 数据驱动，与 APK 行为一致）
          if (this.dataSource === 'server') {
            ForEach(this.serverGroups, (group: ServerAppGroup) => {
              Column() {
                Column() {
                  this.groupHeader(group.name)
                  Grid() {
                    ForEach(group.apps, (item: ServerAppItem) => {
                      GridItem() {
                        Column() {
                          // APK 同款：YYTB UUID 拼服务端图标 URL，失败回落本地占位
                          ServerIcon({ url: item.yytb === '' ? '' :
                            Constants.SOCKET_HOST + '/mobileapi_ydxy/open/image/' + item.yytb })
                          Text(item.yymc)
                            .fontSize(12)
                            .fontColor($r('app.color.common_color_1'))
                            .maxLines(1)
                            .textOverflow({ overflow: TextOverflow.Ellipsis })
                            .margin({ top: 8 })
                        }
                        .width('100%')
                        .padding({ top: 14, bottom: 14 })
                        .borderRadius(12)
                        .alignItems(HorizontalAlign.Center)
                        .clickEffect({ level: ClickEffectLevel.LIGHT, scale: 0.95 })
                        .hoverEffect(HoverEffect.Highlight)
                        .onClick(() => {
                          this.dispatchApp(item.yymc, item.yyid, item.lx, item.url);
                        })
                      }
                    }, (item: ServerAppItem) => 'sv_' + item.yyid)
                  }
                  .columnsTemplate(this.gridTemplate())
                  .width('100%')
                  .height(Math.ceil(group.apps.length / BreakpointSystem.getAppGridColumns(this.currentBreakpoint)) * 90)
                }
                .width('100%')
                .borderRadius(14)
                .backgroundColor(ImmersiveLightHelper.fallbackBg($r('app.color.white')))
                .systemMaterial(ImmersiveLightHelper.cardMaterial())
              }
              .width('100%')
              .padding({ left: 12, right: 12, bottom: 10 })
            }, (group: ServerAppGroup) => 'grp_' + group.name)
          }

          // 本地清单宫格（服务端未返回时展示）
          if (this.dataSource === 'local') {
          // Banner：校园风景横图（APK 同位置，校园实景照）
          Image($r('app.media.choose_school'))
            .width('100%')
            .height(120)
            .objectFit(ImageFit.Cover)

          // 常用应用（该账号未添加，仅标题行 + 点击添加）
          Column() {
            Row() {
              Row()
                .width(3)
                .height(14)
                .backgroundColor($r('app.color.sdmu_primary'))
                .margin({ right: 8 })
              Text('常用应用')
                .fontSize(15)
                .fontColor($r('app.color.common_color_1'))
                .layoutWeight(1)
              Text('点击添加 >')
                .fontSize(13)
                .fontColor($r('app.color.common_color_3'))
                .hoverEffect(HoverEffect.Highlight)
                .onClick(() => {
                  // AppTitleAdapter.d 回调（AppFragmentV2$e）→ a1(getActivity(), e.a.x, bundle, 5467)：
                  // e.a.x = R$string.mobile_campus_router_edit_common_app = "/app/EditCommonAppActivity"
                  // → ARouter$$Group$$app 映射 newUI 包 EditCommonAppActivity（标题"添加常用应用"，
                  //   MToolBar 右图标再进 EditCommonAppSearchPage）；HAP 等价 EditCommonAppPage，
                  //   onActivityResult(5467) 返回刷新由 @StorageLink('common_app_changed') 等价）
                  router.pushUrl({ url: 'pages/EditCommonAppPage' });
                })
            }
            .width('100%')
            .height(38)
            .padding({ left: 12, right: 12 })
            .alignItems(VerticalAlign.Center)
          }
          .width('100%')
          .margin({ top: 8 })
          .backgroundColor($r('app.color.white'))

          this.groupHeader('我的应用')
          this.gridGroup(this.myApps)
          this.groupHeader('办公应用')
          this.gridGroup(this.officeApps)
          this.groupHeader('一卡通')
          this.gridGroup(this.cardApps)
          this.groupHeader('数据报表')
          this.gridGroup(this.reportApps)
          this.groupHeader('轻校园')
          this.gridGroup(this.lightApps)
          }
        }
        .width('100%')
        .padding({ bottom: this.useSideRail() ? 16 : 88 })
      }
      .scrollable(ScrollDirection.Vertical)
      .width('100%')
      .layoutWeight(1)
      .align(Alignment.Top)
      .backgroundColor($r('app.color.common_color_6'))
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.common_color_6'))
  }
}

/**
 * 报告 Tab — 复刻 mobile_campus_fragment_main_v3.xml：
 *   - 顶部 44vp 白底校名横幅图（fitXY）
 *   - SlidingTabLayout：高 44vp、指示器 #97000C 宽 28vp 高 3vp 圆角 1.5、
 *     文字选中 #333333 加粗 14fp / 未选中 #808080 14fp、tab padding 15vp
 *   - ViewPager 内容（微门户/I校园/I办公，Tab 数据源与 Android 端一致由服务端菜单下发）
 */
@Component
struct ReportTab {
  @State subTabIndex: number = 0;
  @StorageProp('isCompactHeight') isCompactHeight: boolean = false;

  @Builder
  subTabLabel(label: string | Resource, index: number) {
    Column() {
      Text(label)
        .fontSize(14)
        .fontColor($r('app.color.common_color_1'))
        .fontWeight(FontWeight.Bold)
        .padding({ left: 15, right: 15 })
      // 指示器：px_to_dip_56/2=28vp 宽、px_to_dip_6/2=3vp 高、圆角 1.5vp
      Row()
        .width(28)
        .height(3)
        .borderRadius(1.5)
        .backgroundColor($r('app.color.mobile_campus_primary_color'))
        .margin({ top: 4 })
    }
    .height(this.isCompactHeight ? 36 : 44)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .hoverEffect(HoverEffect.Highlight)
    .onClick(() => {
      this.subTabIndex = index;
    })
  }

  @Builder
  subTabLabelUnselected(label: string | Resource, index: number) {
    Column() {
      Text(label)
        .fontSize(14)
        .fontColor($r('app.color.tab_unselected'))
        .fontWeight(FontWeight.Normal)
        .padding({ left: 15, right: 15 })
      // 占位保持高度一致
      Row()
        .width(28)
        .height(3)
        .margin({ top: 4 })
    }
    .height(this.isCompactHeight ? 36 : 44)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .hoverEffect(HoverEffect.Highlight)
    .onClick(() => {
      this.subTabIndex = index;
    })
  }

  build() {
    Column() {
      // 顶部校名横幅：固定比例居中，紧凑高屏自动收紧高度
      Row() {
        Image($r('app.media.mobile_campus_main_head_logo'))
          .height(this.isCompactHeight ? 24 : 34)
          .constraintSize({ maxWidth: 320 })
          .objectFit(ImageFit.Contain)
      }
      .width('100%')
      .height(this.isCompactHeight ? 32 : 44)
      .justifyContent(FlexAlign.Center)
      .backgroundColor($r('app.color.main_bg'))

      // SlidingTabLayout：微门户 / I校园 / I办公
      Row() {
        if (this.subTabIndex === 0) {
          this.subTabLabel('微门户', 0)
        } else {
          this.subTabLabelUnselected('微门户', 0)
        }
        if (this.subTabIndex === 1) {
          this.subTabLabel('I校园', 1)
        } else {
          this.subTabLabelUnselected('I校园', 1)
        }
        if (this.subTabIndex === 2) {
          this.subTabLabel('I办公', 2)
        } else {
          this.subTabLabelUnselected('I办公', 2)
        }
      }
      .width('100%')
      .height(this.isCompactHeight ? 36 : 44)
      .justifyContent(FlexAlign.Center)

      // ViewPager 内容
      if (this.subTabIndex === 0) {
        WMHTab()
          .width('100%')
          .layoutWeight(1)
      } else if (this.subTabIndex === 1) {
        ICampusTab()
          .width('100%')
          .layoutWeight(1)
      } else {
        IOfficeTab()
          .width('100%')
          .layoutWeight(1)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.main_bg'))
  }
}

/**
 * 主页 — 复刻 mobile_campus_activity_main.xml + main_bottom_bar_rgroup.xml：
 * NoScrollViewPager + BadgeLayout(底部 RadioGroup)：
 *   报告 / 应用 / 校圈 / 我的，RadioButton 文字 12fp(px_to_sp_24)、
 *   选中色 ybg_blue #18B4ED、未选中 common_color_3 #999999、bg main_bg、paddingBottom 2vp(px4/2)。
 */
@Entry
@Component
struct Index {
  @State isReady: boolean = false;
  @State isLogged: boolean = false;
  @State currentTabIndex: number = 0;
  /** [tablet-adapt] 多形态断点：xs/sm / md / lg / xl + 高度断点 */
  @StorageProp('isWideScreen') isWideScreen: boolean = false;
  @StorageProp('currentBreakpoint') currentBreakpoint: string = 'sm';
  @StorageProp('heightBreakpoint') heightBreakpoint: string = 'lg';
  @StorageProp('isLandscape') isLandscape: boolean = false;
  @StorageProp('avoidAreaLeftVp') avoidAreaLeftVp: number = 0;
  @StorageProp('avoidAreaRightVp') avoidAreaRightVp: number = 0;
  @StorageProp('avoidAreaBottomVp') avoidAreaBottomVp: number = 0;
  @State tabTriggers: number[] = [-1, -1, -1];

  private useSideRail(): boolean {
    return BreakpointSystem.shouldUseSideRail(
      this.currentBreakpoint,
      this.heightBreakpoint,
      this.isLandscape
    );
  }

  aboutToAppear(): void {
    // 启动即恢复持久化会话（UC/aesKey/sessionKey），业务请求免重新协商
    LoginSession.restoreSession();
    PreferencesUtil.getBoolean(Constants.KEY_IS_LOGIN, false)
      .then((logged: boolean) => {
        this.isLogged = logged;
        this.isReady = true;
        if (!logged) {
          router.replaceUrl({ url: 'pages/LoginPage' });
        } else {
          this.consumePendingWidgetRoute();
        }
      })
      .catch(() => {
        this.isReady = true;
        this.isLogged = false;
        router.replaceUrl({ url: 'pages/LoginPage' });
      });
  }

  onPageShow(): void {
    if (this.isReady && this.isLogged) {
      this.consumePendingWidgetRoute();
    }
  }

  private consumePendingWidgetRoute(): void {
    const targetPage: string | undefined = AppStorage.get<string>('pendingWidgetPage');
    if (targetPage && targetPage !== '') {
      const yyid: string = AppStorage.get<string>('pendingWidgetYyid') || '';
      const title: string = AppStorage.get<string>('pendingWidgetTitle') || '';
      AppStorage.setOrCreate<string>('pendingWidgetPage', '');
      AppStorage.setOrCreate<string>('pendingWidgetYyid', '');
      AppStorage.setOrCreate<string>('pendingWidgetTitle', '');
      router.pushUrl({
        url: targetPage,
        params: { yyid: yyid, title: title }
      }).catch(() => {
        // 路由异常忽略
      });
    }
  }

  @Builder
  bottomTab(glyphNormal: Resource, glyphSelected: Resource, label: string | Resource, index: number) {
    // APK 实拍：选中色为主题红 #97000C（main_bottom_bar 红色选中态）
    if (this.currentTabIndex === index) {
      Column() {
        SymbolGlyph(glyphSelected)
          .fontSize(24)
          .fontColor([$r('app.color.sdmu_primary')])
          .symbolEffect(
            new BounceSymbolEffect(EffectScope.LAYER, EffectDirection.UP),
            this.tabTriggers[index]
          )
        Text(label)
          .fontSize(12)
          .fontColor($r('app.color.sdmu_primary'))
          .margin({ top: 2 })
      }
      .width(this.useSideRail() ? 60 : '100%')
      .height(52)
      .borderRadius(this.useSideRail() ? 14 : 0)
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
      .backgroundColor(this.useSideRail() ?
        ImmersiveLightHelper.fallbackBg('#FFF0F0') : Color.Transparent)
      .systemMaterial(this.useSideRail() ? ImmersiveLightHelper.pillMaterial() : undefined)
      .clickEffect({ level: ClickEffectLevel.LIGHT, scale: 0.94 })
      .hoverEffect(HoverEffect.Highlight)
    } else {
      Column() {
        SymbolGlyph(glyphNormal)
          .fontSize(24)
          .fontColor([$r('app.color.common_color_2')])
          .symbolEffect(
            new BounceSymbolEffect(EffectScope.LAYER, EffectDirection.UP),
            this.tabTriggers[index]
          )
        Text(label)
          .fontSize(12)
          .fontColor($r('app.color.common_color_2'))
          .margin({ top: 2 })
      }
      .width(this.useSideRail() ? 60 : '100%')
      .height(52)
      .borderRadius(this.useSideRail() ? 14 : 0)
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
      .backgroundColor(this.useSideRail() ? $r('app.color.main_bg') : Color.Transparent)
      .clickEffect({ level: ClickEffectLevel.LIGHT, scale: 0.94 })
      .hoverEffect(HoverEffect.Highlight)
    }
  }

  build() {
    Column() {
      if (this.isReady && this.isLogged) {
        // APK 实拍：学生端底栏 3 个按钮（首页/应用/我的）
        Tabs({ barPosition: this.useSideRail() ? BarPosition.Start : BarPosition.End }) {
          // [tablet-adapt] xs/sm:100% / md:720vp / lg:1080vp / xl:1200vp + 侧边导航栏
          TabContent() {
            Row() {
              ReportTab()
                .width('100%')
                .constraintSize({ maxWidth: BreakpointSystem.getContentMaxWidth(this.currentBreakpoint) })
            }
            .width('100%')
            .height('100%')
            .justifyContent(FlexAlign.Center)
          }
          .tabBar(this.bottomTab($r('sys.symbol.house'), $r('sys.symbol.house_fill'),
            '首页', 0))
          TabContent() {
            Row() {
              AppsTab()
                .width('100%')
                .constraintSize({ maxWidth: BreakpointSystem.getContentMaxWidth(this.currentBreakpoint) })
            }
            .width('100%')
            .height('100%')
            .justifyContent(FlexAlign.Center)
          }
          .tabBar(this.bottomTab($r('sys.symbol.square_grid_2x2'), $r('sys.symbol.square_grid_2x2'),
            '应用', 1))
          TabContent() {
            Row() {
              MineTab()
                .width('100%')
                .constraintSize({ maxWidth: BreakpointSystem.getContentMaxWidth(this.currentBreakpoint) })
            }
            .width('100%')
            .height('100%')
            .justifyContent(FlexAlign.Center)
          }
          .tabBar(this.bottomTab($r('sys.symbol.person'), $r('sys.symbol.person_fill'),
            '我的', 2))
        }
        .vertical(this.useSideRail())
        .barWidth(this.useSideRail() ? 76 : '100%')
        .barHeight(this.useSideRail() ? '100%' : 62)
        .barOverlap(!this.useSideRail())
        .barBackgroundColor(!this.useSideRail() ? Color.Transparent : $r('app.color.main_bg'))
        .barFloatingStyle(!this.useSideRail() && ImmersiveLightHelper.isSupported() ? {
          barSideMargin: 16,
          barBottomMargin: Math.max(10, this.avoidAreaBottomVp > 0 ? Math.round(this.avoidAreaBottomVp * 0.5) : 10),
          systemMaterial: ImmersiveLightHelper.tabBarMaterial()
        } : undefined)
        .scrollable(!this.useSideRail())
        .barMode(BarMode.Fixed)
        .onChange((index: number) => {
          PerformanceSchedulerHelper.reportSceneBegin(FAST_SCENE_PAGE_TRANSITION, FAST_DURATION_SHORT);
          this.currentTabIndex = index;
          const next: number[] = this.tabTriggers.slice();
          if (index >= 0 && index < next.length) {
            next[index] = next[index] < 0 ? 1 : next[index] + 1;
            this.tabTriggers = next;
          }
          PerformanceSchedulerHelper.reportSceneEnd(FAST_SCENE_PAGE_TRANSITION, FAST_DURATION_SHORT);
        })
      }
    }
    .width('100%')
    .height('100%')
    .padding({
      left: this.avoidAreaLeftVp > 0 ? this.avoidAreaLeftVp : 0,
      right: this.avoidAreaRightVp > 0 ? this.avoidAreaRightVp : 0
    })
    .backgroundColor($r('app.color.main_bg'))
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
  }
}





