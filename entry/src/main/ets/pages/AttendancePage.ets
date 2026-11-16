import { ApiService } from '../network/ApiService';
import { AttendanceItem } from '../model/AttendanceModel';
import { TitleBar } from '../components/TitleBar';
import { EmptyView } from '../components/EmptyView';
import { LoadingView } from '../components/LoadingView';

/**
 * 考勤页 — 1:1 复刻 attendance_activity_main.xml + attendance_view_date.xml +
 * attendance_view_state.xml + attendance_view_record.xml + attendance_view_child.xml
 *
 * attendance_activity_main.xml：toolbar_normal + TabLayout(高 px_to_dip_80=40vp、tabGravity=center、
 *   指示条高 0、选中色 mobile_campus_primary_color_default(#1B68B7)、未选中 #333333、
 *   textSize px_to_dip_28=14fp) + ViewPager 内容
 *
 * attendance_view_date.xml（日期头）：tvDate 16fp(dip32/2) #333333 高 40vp paddingLeft 12vp、
 *   左侧 attendance_time 图标 drawablePadding 8vp；分隔线 #E7E7E7 高 0.5dip
 * attendance_view_state.xml（考勤时间轴）：paddingT px_to_dip_54=27vp paddingB px_to_dip_48=24vp
 *   开始：tvStartTime 18.5fp 加粗 #333333 宽 56dip=28vp + 蓝点(16dip=8vp,
 *   attendance_shape_blue #388CFC) + 灰线(2dip×48dip=1×24vp #E7E7E7) +
 *   tvStart 14fp #333333 / tvStartDesc 12fp #388CFC 蓝底(#DDECFF)圆角标签 padding 2/1vp
 *   结束：tvEndTime 18.5fp 加粗 + 线 + 蓝点 + tvEnd 14fp
 *   tvEndDesc：marginLeft px_to_dip_225=112.5vp、marginTop 12vp 蓝底标签
 * attendance_view_record.xml（统计行）：tvRecordName 16fp #999999 左、
 *   tvRecordTimes 17fp(dip34/2) #333333 右、marginTop px_to_dip_22=11vp
 * attendance_view_child.xml（课程行）：高 px_to_dip_128=64vp、padding L12 R20、
 *   img 40vp marginLeft 8vp、tvName 16fp #333333、tvDepartment 12fp #999999 marginTop 8vp、
 *   tvCount 16fp #333333 右侧
 */
class AttDateGroup {
  date: string;
  startTime: string;
  startLabel: string;
  startDesc: string;
  endTime: string;
  endLabel: string;
  endDesc: string;

  constructor(date: string, startTime: string, startLabel: string, startDesc: string,
    endTime: string, endLabel: string, endDesc: string) {
    this.date = date;
    this.startTime = startTime;
    this.startLabel = startLabel;
    this.startDesc = startDesc;
    this.endTime = endTime;
    this.endLabel = endLabel;
    this.endDesc = endDesc;
  }
}

class AttStatEntry {
  name: string;
  times: number;

  constructor(name: string, times: number) {
    this.name = name;
    this.times = times;
  }
}

class AttCourseEntry {
  name: string;
  department: string;
  count: number;

  constructor(name: string, department: string, count: number) {
    this.name = name;
    this.department = department;
    this.count = count;
  }
}

@Entry
@Component
struct AttendancePage {
  @State records: AttendanceItem[] = [];
  @State groups: AttDateGroup[] = [];
  @State statEntries: AttStatEntry[] = [];
  @State courseEntries: AttCourseEntry[] = [];
  @State isLoading: boolean = true;
  @State attTabIndex: number = 0;

  aboutToAppear(): void {
    ApiService.getAttendanceList()
      .then((response) => {
        this.records = response.data;
        this.buildGroups();
        this.buildStats();
        this.isLoading = false;
      })
      .catch(() => {
        this.records = [];
        this.groups = [];
        this.statEntries = [];
        this.courseEntries = [];
        this.isLoading = false;
      });
  }

  private dateOf(time: string): string {
    const parts: string[] = time.split(' ');
    return parts.length > 0 ? parts[0] : time;
  }

  private timeOf(time: string): string {
    const parts: string[] = time.split(' ');
    if (parts.length < 2) {
      return '00:00';
    }
    return parts[1];
  }

  private buildGroups(): void {
    // 按日期分组，取每日首/末条考勤作为时间轴上下签
    const dates: string[] = [];
    const buckets: AttendanceItem[][] = [];
    for (const record of this.records) {
      const dateStr: string = this.dateOf(record.time);
      let index: number = -1;
      for (let i = 0; i < dates.length; i++) {
        if (dates[i] === dateStr) {
          index = i;
          break;
        }
      }
      if (index < 0) {
        dates.push(dateStr);
        buckets.push([]);
        index = buckets.length - 1;
      }
      buckets[index].push(record);
    }
    const result: AttDateGroup[] = [];
    for (let i = 0; i < buckets.length; i++) {
      const list: AttendanceItem[] = buckets[i].slice();
      list.sort((a: AttendanceItem, b: AttendanceItem): number => a.time < b.time ? -1 : 1);
      const first: AttendanceItem = list[0];
      const last: AttendanceItem = list[list.length - 1];
      result.push(new AttDateGroup(dates[i], this.timeOf(first.time), first.courseName, first.status,
        this.timeOf(last.time), last.courseName, last.status));
    }
    this.groups = result;
  }

  private buildStats(): void {
    // 考勤状态统计（attendance_view_record）
    const names: string[] = ['正常', '迟到', '缺勤'];
    const counts: number[] = [0, 0, 0];
    for (const record of this.records) {
      for (let i = 0; i < names.length; i++) {
        if (record.status === names[i]) {
          counts[i] += 1;
        }
      }
    }
    const entries: AttStatEntry[] = [];
    for (let i = 0; i < names.length; i++) {
      entries.push(new AttStatEntry(names[i], counts[i]));
    }
    this.statEntries = entries;
    // 课程考勤统计（attendance_view_child）
    const courseNames: string[] = [];
    const courseTypes: string[] = [];
    const courseCounts: number[] = [];
    for (const record of this.records) {
      let index: number = courseNames.indexOf(record.courseName);
      if (index < 0) {
        courseNames.push(record.courseName);
        courseTypes.push(record.type);
        courseCounts.push(0);
        index = courseCounts.length - 1;
      }
      courseCounts[index] += 1;
    }
    const courseList: AttCourseEntry[] = [];
    for (let i = 0; i < courseNames.length; i++) {
      courseList.push(new AttCourseEntry(courseNames[i], courseTypes[i], courseCounts[i]));
    }
    this.courseEntries = courseList;
  }

  /**
   * 考勤状态标签：tvStartDesc/tvEndDesc — 12fp #388CFC 蓝底(#DDECFF)圆角标签
   */
  @Builder
  stateTag(desc: string) {
    Text(desc)
      .fontSize(12)
      .fontColor($r('app.color.attendance_enable_color'))
      .backgroundColor($r('app.color.attendance_tag_bg'))
      .borderRadius(999)
      .padding({ left: 2, right: 2, top: 1, bottom: 1 })
      .maxLines(1)
  }

  /**
   * attendance_view_state.xml：单日考勤时间轴
   */
  @Builder
  dateStateView(group: AttDateGroup) {
    Column() {
      // 开始行：tvStartTime + 蓝点/灰线 + tvStart/tvStartDesc
      Row() {
        // tvStartTime：18.5fp 加粗 #333333 宽 28vp
        Text(group.startTime)
          .fontSize(18.5)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.common_color_1'))
          .width(28)
        // viewStart 蓝点 8vp + 24vp 灰线
        Column() {
          Row()
            .width(8)
            .height(8)
            .borderRadius(4)
            .backgroundColor($r('app.color.attendance_enable_color'))
            .margin({ top: 4 })
          Row()
            .width(1)
            .height(24)
            .backgroundColor($r('app.color.common_color_5'))
        }
        .alignItems(HorizontalAlign.Center)
        // tvStart / tvStartDesc
        Column() {
          Text(group.startLabel)
            .fontSize(14)
            .fontColor($r('app.color.common_color_1'))
          Column() {
            this.stateTag(group.startDesc)
          }
          .margin({ top: 12 })
          .alignItems(HorizontalAlign.Start)
        }
        .margin({ left: 12 })
        .alignItems(HorizontalAlign.Start)
      }
      .width('100%')
      .padding({ left: 12 })
      .alignItems(VerticalAlign.Center)
      // 结束行：tvEndTime + 灰线/蓝点 + tvEnd
      Row() {
        // tvEndTime：18.5fp 加粗 #333333 宽 28vp
        Text(group.endTime)
          .fontSize(18.5)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.common_color_1'))
          .width(28)
        // 灰线 + viewEnd 蓝点 8vp
        Column() {
          Row()
            .width(1)
            .height(24)
            .backgroundColor($r('app.color.common_color_5'))
          Row()
            .width(8)
            .height(8)
            .borderRadius(4)
            .backgroundColor($r('app.color.attendance_enable_color'))
            .margin({ bottom: 4 })
        }
        .alignItems(HorizontalAlign.Center)
        // tvEnd
        Column() {
          Text(group.endLabel)
            .fontSize(14)
            .fontColor($r('app.color.common_color_1'))
        }
        .margin({ left: 12 })
        .alignItems(HorizontalAlign.Start)
      }
      .width('100%')
      .margin({ top: 2 })
      .padding({ left: 12 })
      .alignItems(VerticalAlign.Center)
      // tvEndDesc：marginLeft 112.5vp 蓝底标签
      Row() {
        Row()
          .width(112.5)
        this.stateTag(group.endDesc)
      }
      .width('100%')
      .margin({ top: 12 })
    }
    .width('100%')
    .padding({ top: 27, bottom: 24 })
    .backgroundColor($r('app.color.white'))
  }

  /**
   * attendance_view_date.xml：日期头（40vp 高 + attendance_time 图标 + 分隔线）
   */
  @Builder
  dateHeaderView(group: AttDateGroup) {
    Column() {
      Row() {
        Image($r('app.media.attendance_time'))
          .width(14)
          .height(14)
        // tvDate：16fp #333333 drawablePadding 8vp paddingLeft 12vp
        Text(group.date)
          .fontSize(16)
          .fontColor($r('app.color.common_color_1'))
          .margin({ left: 8 })
      }
      .width('100%')
      .height(40)
      .padding({ left: 12 })
      .alignItems(VerticalAlign.Center)
      // 分隔线：#E7E7E7 高 0.5dip
      Divider()
        .color($r('app.color.common_color_5'))
        .strokeWidth(0.5)
        .width('100%')
    }
    .width('100%')
    .backgroundColor($r('app.color.white'))
  }

  build() {
    // attendance_activity_main.xml：LinearLayout
    Column() {
      // include toolbar_normal
      TitleBar({ title: '考勤记录', showBack: true })
      if (this.isLoading) {
        LoadingView()
      } else {
        if (this.records.length === 0) {
          EmptyView()
        } else {
          // TabLayout：高 40vp 居中、无指示条、选中 #1B68B7 / 未选中 #333333、14fp
          Row() {
            ForEach([$r('app.string.attendance_tab_detail'), $r('app.string.attendance_tab_stats')],
              (label: Resource, index: number) => {
                Text(label)
                  .fontSize(14)
                  .fontColor(index === this.attTabIndex ?
                    $r('app.color.blue_default') : $r('app.color.common_color_1'))
                  .padding({ left: 15, right: 15 })
                  .height(40)
                  .onClick(() => {
                    this.attTabIndex = index;
                  })
              }, (label: Resource) => 'atttab' + label)
          }
          .width('100%')
          .height(40)
          .justifyContent(FlexAlign.Center)
          .backgroundColor($r('app.color.white'))

          if (this.attTabIndex === 0) {
            // 考勤详情：attendance_view_date + attendance_view_state
            Scroll() {
              Column() {
                ForEach(this.groups, (group: AttDateGroup) => {
                  Column() {
                    this.dateHeaderView(group)
                    this.dateStateView(group)
                  }
                  .width('100%')
                  .backgroundColor($r('app.color.white'))
                }, (group: AttDateGroup) => 'attdate' + group.date)
              }
              .width('100%')
            }
            .width('100%')
            .layoutWeight(1)
            .backgroundColor($r('app.color.white'))
            .scrollBar(BarState.Off)
          } else {
            // 考勤统计：attendance_view_record + attendance_view_child
            Scroll() {
              Column() {
                // 状态统计行：tvRecordName 16fp #999 / tvRecordTimes 17fp #333
                ForEach(this.statEntries, (entry: AttStatEntry) => {
                  Row() {
                    Text(entry.name)
                      .fontSize(16)
                      .fontColor($r('app.color.common_color_3'))
                    Text(entry.times + '')
                      .fontSize(17)
                      .fontColor($r('app.color.common_color_1'))
                  }
                  .width('100%')
                  .margin({ top: 11 })
                  .padding({ left: 12, right: 12 })
                  .justifyContent(FlexAlign.SpaceBetween)
                }, (entry: AttStatEntry) => 'attstat' + entry.name)
                Divider()
                  .color($r('app.color.common_color_5'))
                  .strokeWidth(0.5)
                  .width('100%')
                  .margin({ top: 11 })
                // 课程考勤行：attendance_view_child.xml
                ForEach(this.courseEntries, (entry: AttCourseEntry) => {
                  Row() {
                    // img：40vp（运行时占位图标）marginLeft 8vp
                    Image($r('app.media.report'))
                      .width(40)
                      .height(40)
                      .margin({ left: 8 })
                      .borderRadius(20)
                    // tvName 16fp #333 / tvDepartment 12fp #999 marginTop 8vp
                    Column() {
                      Text(entry.name)
                        .fontSize(16)
                        .fontColor($r('app.color.common_color_1'))
                      Text(entry.department)
                        .fontSize(12)
                        .fontColor($r('app.color.common_color_3'))
                        .margin({ top: 8 })
                    }
                    .margin({ left: 12 })
                    .layoutWeight(1)
                    .alignItems(HorizontalAlign.Start)
                    // tvCount 16fp #333 右侧
                    Text(entry.count + '')
                      .fontSize(16)
                      .fontColor($r('app.color.common_color_1'))
                  }
                  .width('100%')
                  .height(64)
                  .padding({ left: 12, right: 20 })
                  .alignItems(VerticalAlign.Center)
                }, (entry: AttCourseEntry) => 'attcourse' + entry.name)
              }
              .width('100%')
              .backgroundColor($r('app.color.white'))
            }
            .width('100%')
            .layoutWeight(1)
            .backgroundColor($r('app.color.white'))
            .scrollBar(BarState.Off)
          }
        }
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.white'))
  }
}
