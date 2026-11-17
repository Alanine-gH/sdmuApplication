import { TitleBar } from '../components/TitleBar';

interface MeetingOption {
  id: string;
  name: string;
  time: string;
  room: string;
}

/**
 * 会议选择页 — 1:1 复刻 mobile_campus_oa_widget_meeting_select_layout.xml：
 * 行 padL12 padT15：左侧标签容器宽80 mr12 "*"红标(17fp粗体) + 标签16fp common_color_3
 * 内容16fp common_color_1 右侧arrow_right2 mr10
 * 分隔线 mt16 高0.5 common_color_5（位于标签右侧之下）
 */
@Entry
@Component
struct MeetingSelectorPage {
  @State meetings: MeetingOption[] = [];
  @State selectedId: string = '';

  aboutToAppear(): void {
    this.meetings = [
      { id: 'm1', name: '2026年秋季学期教学工作部署会', time: '2026-11-20 14:30', room: '第一会议室' },
      { id: 'm2', name: '党委理论学习中心组会议', time: '2026-11-18 09:00', room: '党委会议室' },
      { id: 'm3', name: '学生工作例会', time: '2026-11-17 16:00', room: '行政楼308' },
      { id: 'm4', name: '招生工作专题会', time: '2026-11-15 10:00', room: '第二会议室' },
      { id: 'm5', name: '后勤保障协调会', time: '2026-11-14 15:00', room: '第三会议室' }
    ];
  }

  private select(meeting: MeetingOption): void {
    this.selectedId = meeting.id;
    this.getUIContext().getPromptAction().showToast({ message: '已选择: ' + meeting.name });
  }

  build() {
    Column() {
      TitleBar({ title: '会议选择', showBack: true })

      List() {
        ForEach(this.meetings, (meeting: MeetingOption) => {
          ListItem() {
            this.selectRow('会议', meeting.name, this.selectedId === meeting.id)
          }
          .onClick(() => {
            this.select(meeting);
          })

          ListItem() {
            this.selectRow('时间', meeting.time, this.selectedId === meeting.id)
          }
          .onClick(() => {
            this.select(meeting);
          })

          ListItem() {
            this.selectRow('地点', meeting.room, this.selectedId === meeting.id)
          }
          .onClick(() => {
            this.select(meeting);
          })
        }, (meeting: MeetingOption) => meeting.id)
      }
      .width('100%')
      .layoutWeight(1)
      .scrollBar(BarState.Off)
      .backgroundColor($r('app.color.white'))
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.white'))
  }

  // mobile_campus_oa_widget_meeting_select_layout.xml
  @Builder
  selectRow(label: string, content: string, selected: boolean) {
    Column() {
      Row() {
        // tv_container 宽80 mr12
        Row() {
          Text(label)
            .fontSize(16)
            .fontColor($r('app.color.common_color_3'))
        }
        .width(80)
        .margin({ right: 12 })
        .alignItems(VerticalAlign.Center)

        // intent_content 16fp common_color_1
        Text(content)
          .fontSize(16)
          .fontColor(selected ? $r('app.color.mobile_campus_primary_color_default') : $r('app.color.common_color_1'))
          .layoutWeight(1)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        // intent_arrow arrow_right2 mr10
        Image($r('app.media.arrow_right2'))
          .width(16)
          .height(16)
          .margin({ right: 10 })
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)

      // 分隔线 mt16 h0.5 位于标签右侧之下
      Divider()
        .color($r('app.color.common_color_5'))
        .strokeWidth(0.5)
        .margin({ top: 16, left: 92 })
    }
    .width('100%')
    .padding({ left: 12, top: 15 })
    .backgroundColor($r('app.color.white'))
  }
}
