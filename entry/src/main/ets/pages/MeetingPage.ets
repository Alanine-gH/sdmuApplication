import { router } from '@kit.ArkUI';
import { ApiService } from '../network/ApiService';
import { ApiResponse } from '../model/ResponseModel';
import { MeetingItem } from '../model/MeetingModel';
import { BusinessError } from '@kit.BasicServicesKit';
import { TitleBar } from '../components/TitleBar';
import { EmptyView } from '../components/EmptyView';
import { LoadingView } from '../components/LoadingView';

interface MeetingGroup {
  groupId: string;
  label: string;
  dayNum: string;
  items: MeetingItem[];
}

@Entry
@Component
struct MeetingPage {
  @State allGroups: MeetingGroup[] = [];
  @State isLoading: boolean = true;
  @State expandedId: string = '';

  aboutToAppear(): void {
    ApiService.getMeetingList()
      .then((response: ApiResponse<MeetingItem[]>) => {
        const data: MeetingItem[] = response.data;
        if (data.length > 0) {
          this.allGroups = MeetingPage.buildGroups(data);
          if (this.allGroups.length > 0) {
            this.expandedId = this.allGroups[0].groupId;
          }
        } else if (response.code !== 0) {
          console.info('MeetingPage degrade: code=' + response.code + ' msg=' + response.message);
        }
        this.isLoading = false;
      })
      .catch((error: BusinessError) => {
        console.info('MeetingPage load fail: ' + error.message);
        this.allGroups = [];
        this.isLoading = false;
      });
  }

  private static buildGroups(meetings: MeetingItem[]): MeetingGroup[] {
    const groups: MeetingGroup[] = [];
    for (const meeting of meetings) {
      let datePart: string = '';
      let dayNum: string = '';
      if (meeting.time !== null && meeting.time !== undefined && meeting.time.length >= 10) {
        datePart = meeting.time.substring(0, 10);
        dayNum = meeting.time.substring(8, 10);
      }
      let matched: MeetingGroup | null = null;
      for (const group of groups) {
        if (group.groupId === datePart) {
          matched = group;
          break;
        }
      }
      if (matched === null) {
        const items: MeetingItem[] = [meeting];
        groups.push({ groupId: datePart, label: MeetingPage.formatLabel(datePart), dayNum: dayNum, items: items });
      } else {
        matched.items.push(meeting);
      }
    }
    return groups;
  }

  private static formatLabel(datePart: string): string {
    if (datePart.length < 10) {
      return datePart;
    }
    const year: string = datePart.substring(0, 4);
    const month: string = datePart.substring(5, 7);
    const day: string = datePart.substring(8, 10);
    return year + '年' + month + '月' + day + '日';
  }

  private stateIcon(status: string): Resource {
    if (status === '1') {
      return $r('app.media.mobile_campus_meeting_success');
    }
    if (status === '2') {
      return $r('app.media.mobile_campus_meeting_cancel');
    }
    return $r('app.media.mobile_campus_meeting');
  }

  private toggleGroup(groupId: string): void {
    if (this.expandedId === groupId) {
      this.expandedId = '';
    } else {
      this.expandedId = groupId;
    }
  }

  private statusText(status: string): string {
    if (status === '1') {
      return '进行中';
    }
    if (status === '2') {
      return '已结束';
    }
    return '未开始';
  }

  build() {
    Column() {
      TitleBar({ title: '会议安排', showBack: true })

      if (this.isLoading) {
        LoadingView()
      } else {
        if (this.allGroups.length === 0) {
          EmptyView({ tipText: '暂无会议安排' })
        } else {
          List() {
            ForEach(this.allGroups, (group: MeetingGroup) => {
              ListItem() {
                this.meetingGroupHeader(group)
              }

              if (this.expandedId === group.groupId) {
                ForEach(group.items, (meeting: MeetingItem) => {
                  ListItem() {
                    this.meetingChildRow(meeting, group.dayNum)
                  }
                }, (meeting: MeetingItem) => meeting.id)
              }
            }, (group: MeetingGroup) => group.groupId)
          }
          .width('100%')
          .layoutWeight(1)
          .backgroundColor($r('app.color.mobile_campus_bg_color'))
          .scrollBar(BarState.Off)
        }
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.mobile_campus_bg_color'))
  }

  // mobile_campus_meeting_view_main_group.xml：组头 40vp 白底 padH12 + meeting_open + 展开提示 12fp #1B68B7 + 0.5 分隔线×2
  @Builder
  meetingGroupHeader(group: MeetingGroup) {
    Column() {
      Row() {
        Text(group.label)
          .fontSize(16)
          .fontColor($r('app.color.common_color_1'))
          .layoutWeight(1)
          .maxLines(1)
        Image($r('app.media.mobile_campus_meeting_open'))
          .width(16)
          .height(16)
          .margin({ right: 6 })
        Text(this.expandedId === group.groupId ? '收起' : '展开')
          .fontSize(12)
          .fontColor($r('app.color.mobile_campus_primary_color_default'))
          .margin({ right: 12 })
      }
      .width('100%')
      .height(40)
      .padding({ left: 12, right: 12 })
      .alignItems(VerticalAlign.Center)
      .backgroundColor($r('app.color.white'))
      .margin({ top: 12 })
      .onClick(() => {
        this.toggleGroup(group.groupId);
      })

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
    .backgroundColor($r('app.color.white'))
  }

  // mobile_campus_meeting_view_main_child.xml
  @Builder
  meetingChildRow(meeting: MeetingItem, dayNum: string) {
    Stack({ alignContent: Alignment.TopEnd }) {
      Row() {
        // tvDay: px_to_sp_40=20fp 宽 44dip
        Text(dayNum)
          .fontSize(20)
          .fontColor($r('app.color.common_color_1'))
          .width(44)
          .textAlign(TextAlign.Center)

        // imgTimeline
        Image($r('app.media.mobile_campus_meeting_timeline'))
          .width(16)
          .height(40)

        // 内容: marginLeft 10dip marginTop 14dip
        Column() {
          Row() {
            // tvReport: 24×16vp bg #1B68B7 圆角2 文本 9fp 白 marginEnd px_to_dip_8=4vp
            Text('报告')
              .fontSize(9)
              .fontColor($r('app.color.white'))
              .width(24)
              .height(16)
              .textAlign(TextAlign.Center)
              .borderRadius(2)
              .backgroundColor($r('app.color.mobile_campus_primary_color_default'))
              .margin({ right: 4 })
            // tvTitle: px_to_sp_34=17fp #333
            Text(meeting.title)
              .fontSize(17)
              .fontColor($r('app.color.common_color_1'))
              .layoutWeight(1)
              .maxLines(2)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
          }
          .width('100%')
          .alignItems(VerticalAlign.Center)

          // tvLocation: px_to_sp_24=12fp 图标 drawablePadding 6 marginTop 6
          Row() {
            Image($r('app.media.mobile_campus_meeting_location_s'))
              .width(12)
              .height(12)
              .margin({ right: 6 })
            Text(meeting.location)
              .fontSize(12)
              .fontColor($r('app.color.common_color_3'))
              .maxLines(1)
          }
          .margin({ top: 6 })
          .alignItems(VerticalAlign.Center)

          // tvTime
          Row() {
            Image($r('app.media.mobile_campus_meeting_time_s'))
              .width(12)
              .height(12)
              .margin({ right: 6 })
            Text(meeting.time)
              .fontSize(12)
              .fontColor($r('app.color.common_color_3'))
              .maxLines(1)
          }
          .margin({ top: 6 })
          .alignItems(VerticalAlign.Center)
        }
        .alignItems(HorizontalAlign.Start)
        .margin({ left: 10, right: 12 })
        .layoutWeight(1)
      }
      .width('100%')
      .padding({ left: 8, top: 14, bottom: 14 })
      .alignItems(VerticalAlign.Center)
      .backgroundColor($r('app.color.white'))
      .onClick(() => {
        router.pushUrl({ url: 'pages/MeetingDetailPage', params: { id: meeting.id } });
      })

      // imgState: marginTop/-marginRight -12dip 超出右上角
      Image(this.stateIcon(meeting.status))
        .width(20)
        .height(20)
        .offset({ x: -12, y: -12 })
    }
    .width('100%')
    .backgroundColor($r('app.color.white'))
  }
}
