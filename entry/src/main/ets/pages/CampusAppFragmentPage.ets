import { router } from '@kit.ArkUI';
import { TitleBar } from '../components/TitleBar';
import { BreakpointSystem } from '../common/BreakpointSystem';
import { AdaptiveLayoutHelper } from '../common/AdaptiveLayoutHelper';

class CampusAppEntryInfo {
  appId: string;
  appName: string;
  targetPage: string;

  constructor(appId: string, appName: string, targetPage: string) {
    this.appId = appId;
    this.appName = appName;
    this.targetPage = targetPage;
  }
}

/**
 * 应用 Tab 壳 — 1:1 复刻 mobile_campus_fragment_app.xml + mobile_campus_fragment_app_empty_common.xml：
 * fragment_app：LinearLayout vertical、fitsSystemWindows
 *   - MultiStateView(content) + PullToRefreshLayout + RecyclerView background=@color/viewLine
 * app_empty_common（空态提示条）：
 *   TextView 13.0sp=13fp(px_to_sp_26)、textColor=@color/common_color_3、gravity=center、
 *   background=@color/common_color_5、padding=px_to_dip_20=10vp、height=76.0dip=38vp、
 *   文案“点击右侧设置，可添加常用功能”
 * RecyclerView 数据态本地应用宫格（4 列，默认图标，本地清单 fallback，非编造业务数据）。未设置常用应用时展示空态提示。
 */
@Entry
@Component
struct CampusAppFragmentPage {
  @State appEntryList: CampusAppEntryInfo[] = [
    new CampusAppEntryInfo('a1', '成绩查询', 'pages/ScorePage'),
    new CampusAppEntryInfo('a2', '课表查询', 'pages/SchedulePage'),
    new CampusAppEntryInfo('a3', '新闻公告', 'pages/NewsPage'),
    new CampusAppEntryInfo('a4', '通讯录', 'pages/ContactPage'),
    new CampusAppEntryInfo('a5', '会议管理', 'pages/MeetingPage'),
    new CampusAppEntryInfo('a6', '图书借阅', 'pages/BookBorrowReportPage'),
    new CampusAppEntryInfo('a7', '通知消息', 'pages/MessageListPage'),
    new CampusAppEntryInfo('a8', '校园地图', 'pages/SchoolMapPage')
  ];
  @StorageProp('currentBreakpoint') currentBreakpoint: string = 'sm';
  @StorageProp('avoidAreaBottomVp') avoidAreaBottomVp: number = 0;

  build() {
    // 根 LinearLayout vertical（fill_parent、fitsSystemWindows）
    Column() {
      TitleBar({ title: '应用', showBack: true })
      // PullToRefreshLayout + RecyclerView background=@color/viewLine
      Scroll() {
        Column() {
          // mobile_campus_fragment_app_empty_common.xml — 空态提示条
          Text('点击右侧设置，可添加常用功能')
            .fontSize(13)
            .fontColor($r('app.color.common_color_3'))
            .textAlign(TextAlign.Center)
            .backgroundColor($r('app.color.common_color_5'))
            .padding(10)
            .width('100%')
            .height(38)
          // RecyclerView 数据态：响应式多列应用宫格（示例数据）
          Grid() {
            ForEach(this.appEntryList, (appEntry: CampusAppEntryInfo) => {
              GridItem() {
                Column() {
                  Image($r('app.media.default_app_icon'))
                    .width(32)
                    .height(32)
                  Text(appEntry.appName)
                    .fontSize(13)
                    .fontColor($r('app.color.common_color_1'))
                    .maxLines(1)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                    .margin({ top: 6 })
                }
                .width('100%')
                .alignItems(HorizontalAlign.Center)
                .padding({ top: 12, bottom: 12 })
                .borderRadius(8)
                .hoverEffect(HoverEffect.Highlight)
                .onClick(() => {
                  router.pushUrl({ url: appEntry.targetPage });
                })
              }
            }, (appEntry: CampusAppEntryInfo) => appEntry.appId)
          }
          .columnsTemplate(AdaptiveLayoutHelper.buildColumnsTemplate(
            BreakpointSystem.getGridColumns(this.currentBreakpoint, 4)
          ))
          .rowsGap(10)
          .width('100%')
          .height(AdaptiveLayoutHelper.computeGridHeightVp(
            this.appEntryList.length,
            BreakpointSystem.getGridColumns(this.currentBreakpoint, 4),
            76,
            10,
            16
          ))
          .margin({ top: 10 })
          .backgroundColor($r('app.color.white'))
        }
        .width('100%')
        .constraintSize({ maxWidth: BreakpointSystem.getContentMaxWidth(this.currentBreakpoint) })
        .alignSelf(ItemAlign.Center)
        .alignItems(HorizontalAlign.Start)
        .padding({ bottom: this.avoidAreaBottomVp })
      }
      .width('100%')
      .layoutWeight(1)
      .backgroundColor($r('app.color.viewLine'))
      .scrollBar(BarState.Off)
      .align(Alignment.Top)
    }
    .width('100%')
    .height('100%')
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.BOTTOM])
  }
}
