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

/** LX=1 原生 YYID → HAP 原生页映射（原 APK ARouter 同口径，小写） */
const YYID_ROUTES: Map<string, string> = new Map([
  ['timetable', 'pages/SchedulePage'],
  ['score', 'pages/ScorePage'],
  ['mylibrary', 'pages/BookBorrowReportPage'],
  ['campusview', 'pages/SchoolSceneryPage'],
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

@Component
struct AppsTab {
  /** 服务端下发分组（/api/app/list 成功时置非空，渲染走数据驱动分支） */
  @State serverGroups: ServerAppGroup[] = [];
  /** 数据源标记：server=服务端下发 / local=本地清单 */
  @State dataSource: string = 'local';

  aboutToAppear(): void {
    // 复刻原 APK YDXYAppModel.V0：GET /api/app/list?data=enc({zdlx,khdbb,type})
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

  /** 点击分发（复刻原 APK module/app/util/a.java switch）：
   *  LX=1 原生 → YYID 映射表 → HAP 原生页（无映射 toast）；
   *  LX=2 H5 → LightAppPage 加载服务端下发 URL（CAS 免登/第三方认证地址） */
  private dispatchApp(name: string, yyid: string, lx: string, url: string): void {
    if (lx === '2' || lx === '4' || lx === '8') {
      if (url === '') {
        this.getUIContext().getPromptAction().showToast({ message: name + ' 暂无访问地址' });
        return;
      }
      router.pushUrl({ url: 'pages/LightAppPage', params: { title: name, url: url } });
      return;
    }
    const target: string | undefined = YYID_ROUTES.get(yyid.toLowerCase());
    if (target !== undefined) {
      router.pushUrl({ url: target });
    } else {
      this.getUIContext().getPromptAction().showToast({ message: name + ' 功能对接中' });
    }
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
    new AppGridItem('一卡通付款码', $r('app.media.default_app_icon'), 'pages/LightAppPage', 'cardPayment'),
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
            .alignItems(HorizontalAlign.Center)
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
      .columnsTemplate('1fr 1fr 1fr 1fr')
      .rowsGap(0)
      .width('100%')
      .height(items.length > 8 ? (items.length + 3) / 4 * 90 : Math.ceil(items.length / 4) * 90)
    }
    .width('100%')
    .backgroundColor($r('app.color.white'))
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
            .width(210)
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
          .margin({ right: 20, top: 14 })
      }
      .width('100%')
      .backgroundColor($r('app.color.white'))

      Scroll() {
        Column() {
          // 服务端下发宫格（/api/app/list 数据驱动，与 APK 行为一致）
          if (this.dataSource === 'server') {
            ForEach(this.serverGroups, (group: ServerAppGroup) => {
              Column() {
                this.groupHeader(group.name)
                Grid() {
                  ForEach(group.apps, (item: ServerAppItem) => {
                    GridItem() {
                      Column() {
                        Image($r('app.media.default_app_icon'))
                          .width(34)
                          .height(34)
                          .objectFit(ImageFit.Contain)
                        Text(item.yymc)
                          .fontSize(12)
                          .fontColor($r('app.color.common_color_1'))
                          .maxLines(1)
                          .textOverflow({ overflow: TextOverflow.Ellipsis })
                          .margin({ top: 8 })
                      }
                      .width('100%')
                      .padding({ top: 14, bottom: 14 })
                      .alignItems(HorizontalAlign.Center)
                      .onClick(() => {
                        this.dispatchApp(item.yymc, item.yyid, item.lx, item.url);
                      })
                    }
                  }, (item: ServerAppItem) => 'sv_' + item.yyid)
                }
                .columnsTemplate('1fr 1fr 1fr 1fr')
                .width('100%')
                .height(Math.ceil(group.apps.length / 4) * 90)
              }
              .width('100%')
              .margin({ bottom: 8 })
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
    .height(44)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
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
    .height(44)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .onClick(() => {
      this.subTabIndex = index;
    })
  }

  build() {
    Column() {
      // 顶部校名横幅：44vp 白底、fitXY
      Row() {
        Image($r('app.media.mobile_campus_main_head_logo'))
          .width('100%')
          .height(44)
          .objectFit(ImageFit.Fill)
      }
      .width('100%')
      .height(44)
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
      .height(44)
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

  aboutToAppear(): void {
    // 启动即恢复持久化会话（UC/aesKey/sessionKey），业务请求免重新协商
    LoginSession.restoreSession();
    PreferencesUtil.getBoolean(Constants.KEY_IS_LOGIN, false)
      .then((logged: boolean) => {
        this.isLogged = logged;
        this.isReady = true;
        if (!logged) {
          router.replaceUrl({ url: 'pages/LoginPage' });
        }
      })
      .catch(() => {
        this.isReady = true;
        this.isLogged = false;
        router.replaceUrl({ url: 'pages/LoginPage' });
      });
  }

  /** APK BadgeLayout.setCheckedDrawable 用 DrawableCompat.tint：选中染主题红、未选染灰。
   *  png 无法用 fillColor，改用 4x5 colorFilter 全量替换 RGB、保留 alpha。 */
  private static readonly TINT_RED: number[] =
    [0, 0, 0, 0, 0.59, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0.05, 0, 0, 0, 1, 0];
  private static readonly TINT_GREY: number[] =
    [0, 0, 0, 0, 0.49, 0, 0, 0, 0, 0.49, 0, 0, 0, 0, 0.49, 0, 0, 0, 1, 0];

  @Builder
  bottomTab(iconNormal: Resource, iconChecked: Resource, label: string | Resource, index: number) {
    // APK 实拍：选中色为主题红 #97000C（main_bottom_bar 红色选中态），非蓝色
    if (this.currentTabIndex === index) {
      Column() {
        Image(iconChecked)
          .width(26)
          .height(26)
          .colorFilter(Index.TINT_RED)
        Text(label)
          .fontSize(12)
          .fontColor($r('app.color.sdmu_primary'))
          .margin({ top: 2 })
      }
      .height(52)
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
      .backgroundColor($r('app.color.main_bg'))
    } else {
      Column() {
        Image(iconNormal)
          .width(26)
          .height(26)
          .colorFilter(Index.TINT_GREY)
        Text(label)
          .fontSize(12)
          .fontColor($r('app.color.common_color_2'))
          .margin({ top: 2 })
      }
      .height(52)
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
      .backgroundColor($r('app.color.main_bg'))
    }
  }

  build() {
    Column() {
      if (this.isReady && this.isLogged) {
        // APK 实拍：学生端底栏 3 个按钮（首页/应用/我的）——BadgeLayout 中
        // cbNews 仅教师(userType=2)可见、cbContact 由 isHideContactTab 隐藏、
        // cbYiban 由 mobile_campus_yiban_visibility=false 隐藏、cbDaiBan/cbXueGong 未启用。
        Tabs({ barPosition: BarPosition.End }) {
          TabContent() {
            ReportTab()
          }
          .tabBar(this.bottomTab($r('app.media.mobile_campus_home'), $r('app.media.mobile_campus_home_select'),
            '首页', 0))
          TabContent() {
            AppsTab()
          }
          .tabBar(this.bottomTab($r('app.media.mobile_campus_work'), $r('app.media.mobile_campus_work_select'),
            '应用', 1))
          TabContent() {
            MineTab()
          }
          .tabBar(this.bottomTab($r('app.media.mobile_campus_my'), $r('app.media.mobile_campus_my_select'),
            '我的', 2))
        }
        .scrollable(true)
        .barMode(BarMode.Fixed)
        .onChange((index: number) => {
          this.currentTabIndex = index;
        })
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.main_bg'))
  }
}




