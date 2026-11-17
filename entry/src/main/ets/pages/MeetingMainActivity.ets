import { router } from '@kit.ArkUI';
import { TitleBar } from '../components/TitleBar';

/**
 * 会议主页 — 1:1 复刻（px_to_dip_N = N/2 vp, px_to_sp_N = N/2 fp）：
 * mobile_campus_meeting_activity.xml：竖向 LinearLayout bg #F2F2F2 + toolbar_normal + 白底 TabLayout 48vp
 *   (tabIndicator 2vp primary) + ViewPager
 * mobile_campus_meeting_view_main_group.xml：分组头 marginTop 12，白底 40vp tvTitle + 右侧 ivIcon(open)
 *   + tvTips "展开" 12fp #1B68B7 marginEnd 12/12 + 细分隔线
 * mobile_campus_meeting_view_main_child.xml：白底 paddingLeft 8，tvDay 20fp 宽 44 居左居中，
 *   imgTimeline，右侧 imgCancel/imgState，内容 marginLeft 10 marginTop 14：
 *   报告 tag 24x16 白字 9fp 圆角蓝底 + tvTitle 17fp #333 + 必须参加 11fp #C80D28 边框；
 *   tvLocation/tvTime 12fp 图标 drawablePadding 6 marginTop 6
 */

interface MeetingMainItem {
  id: string;
  day: string;
  title: string;
  hasReport: boolean;
  mustAttend: boolean;
  location: string;
  time: string;
}

interface MeetingMainGroup {
  groupId: string;
  label: string;
  expanded: boolean;
  items: MeetingMainItem[];
}

interface MeetingMainTab {
  tabName: string;
  groups: MeetingMainGroup[];
}

function buildMainSample(): MeetingMainTab[] {
  const item1: MeetingMainItem = {
    id: 'm1', day: '17', title: '2026年秋季学期教学工作推进会', hasReport: true, mustAttend: false,
    location: '行政楼三楼会议室', time: '11-17 09:00'
  };
  const item2: MeetingMainItem = {
    id: 'm2', day: '17', title: '学生工作例会', hasReport: false, mustAttend: true,
    location: '学生活动中心201', time: '11-17 14:30'
  };
  const item3: MeetingMainItem = {
    id: 'm3', day: '18', title: '期末考试安排协调会', hasReport: true, mustAttend: false,
    location: '教务处会议室', time: '11-18 10:00'
  };
  const g1: MeetingMainGroup = { groupId: 'g0', label: '今天', expanded: true, items: [item1, item2] };
  const g2: MeetingMainGroup = { groupId: 'g1', label: '明天', expanded: false, items: [item3] };
  const tabAll: MeetingMainTab = { tabName: '全部会议', groups: [g1, g2] };
  const tabHost: MeetingMainTab = { tabName: '我主持', groups: [g1] };
  const tabJoin: MeetingMainTab = { tabName: '我参与', groups: [g1, g2] };
  return [tabAll, tabHost, tabJoin];
}

@Component
struct MeetingMainChildItem {
  item: MeetingMainItem = {
    id: '', day: '', title: '', hasReport: false, mustAttend: false, location: '', time: ''
  };

  build() {
    Row() {
      Text(this.item.day)
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
          if (this.item.hasReport) {
            Text('报告')
              .fontSize(9)
              .fontColor($r('app.color.ybg_white'))
              .textAlign(TextAlign.Center)
              .width(24)
              .height(16)
              .backgroundColor($r('app.color.mobile_campus_primary_color_default'))
              .borderRadius(3)
              .margin({ right: 4 })
          }
          Text(this.item.title)
            .fontSize(17)
            .fontColor($r('app.color.common_color_1'))
            .layoutWeight(1)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
          if (this.item.mustAttend) {
            Text('必须参加')
              .fontSize(11)
              .fontColor($r('app.color.mobile_campus_meeting_must_attend_text'))
              .padding({ left: 8, right: 8, top: 2, bottom: 2 })
              .border({
                width: 1,
                color: $r('app.color.mobile_campus_meeting_must_attend_border'),
                radius: 3
              })
              .margin({ left: 4, right: 4 })
          }
        }
        .width('100%')
        .alignItems(VerticalAlign.Center)

        Row() {
          Image($r('app.media.mobile_campus_meeting_location_s'))
            .width(12)
            .height(12)
            .margin({ right: 6 })
          Text(this.item.location)
            .fontSize(12)
            .fontColor($r('app.color.common_color_3'))
            .maxLines(1)
        }
        .width('100%')
        .margin({ top: 6 })
        .alignItems(VerticalAlign.Center)

        Row() {
          Image($r('app.media.mobile_campus_meeting_time_s'))
            .width(12)
            .height(12)
            .margin({ right: 6 })
          Text(this.item.time)
            .fontSize(12)
            .fontColor($r('app.color.common_color_3'))
            .maxLines(1)
        }
        .width('100%')
        .margin({ top: 6 })
        .alignItems(VerticalAlign.Center)
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
      .margin({ left: 10, top: 14, bottom: 14 })
    }
    .width('100%')
    .backgroundColor($r('app.color.white'))
    .padding({ left: 8 })
    .alignItems(VerticalAlign.Top)
    .onClick(() => {
      router.pushUrl({ url: 'pages/MeetingDetailPage', params: { id: this.item.id } });
    })
  }
}

@Component
struct MeetingMainGroupView {
  group: MeetingMainGroup = { groupId: '', label: '', expanded: true, items: [] };
  onToggle: (groupId: string) => void = (groupId: string) => {
    console.info('toggle ' + groupId);
  };

  build() {
    Column() {
      Row() {
        Text(this.group.label)
          .fontSize(14)
          .fontColor($r('app.color.common_color_1'))
          .height(40)
          .padding({ left: 12, right: 12 })
          .layoutWeight(1)
          .maxLines(1)

        Image($r('app.media.mobile_campus_meeting_open'))
          .width(16)
          .height(16)
          .margin({ right: 6 })
          .rotate({ angle: this.group.expanded ? 0 : 180 })

        Text(this.group.expanded ? '收起' : '展开')
          .fontSize(12)
          .fontColor('#1B68B7')
          .margin({ right: 12 })
          .onClick(() => {
            this.onToggle(this.group.groupId);
          })
      }
      .width('100%')
      .backgroundColor($r('app.color.white'))
      .alignItems(VerticalAlign.Center)

      Divider()
        .color($r('app.color.common_color_5'))
        .strokeWidth(0.5)
        .width('100%')

      if (this.group.expanded) {
        ForEach(this.group.items, (item: MeetingMainItem) => {
          MeetingMainChildItem({ item: item })
        }, (item: MeetingMainItem) => item.id)
      }
    }
    .width('100%')
    .margin({ top: 12 })
  }
}

@Component
struct MeetingMainTabPage {
  @State localGroups: MeetingMainGroup[] = [];
  tabGroups: MeetingMainGroup[] = [];

  aboutToAppear(): void {
    this.localGroups = this.tabGroups;
  }

  build() {
    Scroll() {
      Column() {
        ForEach(this.localGroups, (group: MeetingMainGroup) => {
          MeetingMainGroupView({
            group: group,
            onToggle: (groupId: string) => {
              const updated: MeetingMainGroup[] = [];
              for (const g of this.localGroups) {
                if (g.groupId === groupId) {
                  const toggled: MeetingMainGroup = {
                    groupId: g.groupId, label: g.label, expanded: !g.expanded, items: g.items
                  };
                  updated.push(toggled);
                } else {
                  updated.push(g);
                }
              }
              this.localGroups = updated;
            }
          })
        }, (group: MeetingMainGroup) => group.groupId + (group.expanded ? '_open' : '_close'))

        Text('— 暂无更多会议 —')
          .fontSize(12)
          .fontColor($r('app.color.common_color_3'))
          .margin({ top: 24, bottom: 24 })
      }
      .width('100%')
    }
    .width('100%')
    .height('100%')
    .align(Alignment.Top)
    .scrollBar(BarState.Off)
    .backgroundColor($r('app.color.mobile_campus_bg_color'))
  }
}

@Entry
@Component
struct MeetingMainActivity {
  @State currentTabIndex: number = 0;
  private sampleTabs: MeetingMainTab[] = buildMainSample();

  @Builder
  tabBarItem(index: number, name: string) {
    Text(name)
      .fontSize(16)
      .fontColor(index === this.currentTabIndex
        ? $r('app.color.mobile_campus_primary_color_default')
        : $r('app.color.common_color_3'))
      .height(48)
      .padding({ left: 24, right: 24 })
  }

  build() {
    Column() {
      TitleBar({ title: '会议', showBack: true })

      Row() {
        ForEach(this.sampleTabs, (tab: MeetingMainTab, index: number) => {
          Column() {
            this.tabBarItem(index, tab.tabName)
            Divider()
              .color(index === this.currentTabIndex
                ? $r('app.color.mobile_campus_primary_color_default')
                : Color.Transparent)
              .strokeWidth(2)
              .width(index === this.currentTabIndex ? 40 : 0)
          }
          .onClick(() => {
            this.currentTabIndex = index;
          })
        }, (tab: MeetingMainTab) => tab.tabName)
      }
      .width('100%')
      .height(48)
      .backgroundColor($r('app.color.white'))
      .justifyContent(FlexAlign.Center)

      Column() {
        ForEach(this.sampleTabs, (tab: MeetingMainTab, index: number) => {
          if (index === this.currentTabIndex) {
            MeetingMainTabPage({ tabGroups: tab.groups })
          }
        }, (tab: MeetingMainTab) => 'content_' + tab.tabName)
      }
      .width('100%')
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.mobile_campus_bg_color'))
  }
}
