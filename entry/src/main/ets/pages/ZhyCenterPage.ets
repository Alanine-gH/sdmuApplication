import { router } from '@kit.ArkUI';
import { TitleBar } from '../components/TitleBar';

class ZhyCenterEntryInfo {
  entryId: string;
  entryName: string;
  targetPage: string;

  constructor(entryId: string, entryName: string, targetPage: string) {
    this.entryId = entryId;
    this.entryName = entryName;
    this.targetPage = targetPage;
  }
}

/**
 * 迎新中心 — 1:1 复刻 mobile_campus_fragment_zhy.xml +
 * mobile_campus_view_main_zhy_center_button.xml + mobile_campus_view_main_zhy_center_button_item.xml：
 * fragment_zhy：PullToRefreshLayout + MultiStateView(content) + FrameLayout：
 *   RecyclerView background=@color/common_color_6 + 右下回顶按钮(mobile_campus_top, margin 8dip)
 * center_button：RecyclerView background=@color/white、paddingL/R 2.5dip、paddingT 7.5dip，
 *   四宫格条目（GridLayoutManager 双列 → 2×2）：
 *   - llRoot：LinearLayout center、paddingH 2.5dip
 *   - llLayout（BLLinearLayout）：gravity=center、paddingV 4dip、
 *     bl_corners_radius=15.0dip、bl_solid_color=#ff74acff
 *   - ivIcon：20.0dip=20vp 图标（icon_yellow_page_address）、marginR 8dip=8vp
 *   - tvContent：14.0sp=14fp、bold、white、maxLines=1
 * 内置示例数据（四入口）。
 */
@Entry
@Component
struct ZhyCenterPage {
  @State centerEntryList: ZhyCenterEntryInfo[] = [
    new ZhyCenterEntryInfo('z1', '迎新报到', 'pages/WebViewPage'),
    new ZhyCenterEntryInfo('z2', '宿舍查询', 'pages/WebViewPage'),
    new ZhyCenterEntryInfo('z3', '缴费指南', 'pages/WebViewPage'),
    new ZhyCenterEntryInfo('z4', '校园导览', 'pages/SchoolMapPage')
  ];

  /**
   * mobile_campus_view_main_zhy_center_button_item.xml — 四宫格胶囊入口单格。
   * llRoot paddingH 2.5vp；llLayout 圆角 30vp 实底 #74ACFF、paddingV 8vp、
   * ivIcon 20vp + marginR 8vp + tvContent 14fp 粗体白字。
   */
  @Builder
  centerEntryPill(entry: ZhyCenterEntryInfo) {
    Row() {
      Row() {
        Image($r('app.media.icon_yellow_page_address'))
          .width(20)
          .height(20)
          .fillColor($r('app.color.white'))
          .margin({ right: 8 })
        Text(entry.entryName)
          .fontSize(14)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.white'))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .width('100%')
      .padding({ top: 8, bottom: 8 })
      .borderRadius(30)
      .backgroundColor($r('app.color.zhy_center_pill_blue'))
      .justifyContent(FlexAlign.Center)
      .alignItems(VerticalAlign.Center)
    }
    .width('100%')
    .padding({ left: 2.5, right: 2.5 })
    .alignItems(VerticalAlign.Center)
    .onClick(() => {
      router.pushUrl({ url: entry.targetPage });
    })
  }

  build() {
    // fragment_zhy 根：PullToRefreshLayout + RecyclerView common_color_6 背景
    Column() {
      TitleBar({ title: '迎新中心', showBack: true })
      Scroll() {
        Column() {
          // mobile_campus_view_main_zhy_center_button.xml：RecyclerView 白底、
          // paddingL/R 2.5vp、paddingT 7.5vp，四宫格（2×2）
          Grid() {
            ForEach(this.centerEntryList, (entry: ZhyCenterEntryInfo) => {
              GridItem() {
                this.centerEntryPill(entry)
              }
            }, (entry: ZhyCenterEntryInfo) => entry.entryId)
          }
          .columnsTemplate('1fr 1fr')
          .rowsGap(5)
          .width('100%')
          .padding({ left: 2.5, right: 2.5, top: 7.5 })
          .backgroundColor($r('app.color.white'))
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)
      }
      .width('100%')
      .layoutWeight(1)
      .backgroundColor($r('app.color.common_color_6'))
      .scrollBar(BarState.Off)
      .align(Alignment.Top)
    }
    .width('100%')
    .height('100%')
  }
}

