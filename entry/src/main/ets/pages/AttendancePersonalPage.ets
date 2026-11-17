import { TitleBar } from '../components/TitleBar';

/**
 * 个人考勤分段页 — 1:1 复刻 attendance_activity_personal.xml + attendance_fragment_personal.xml
 * 结构（#F2F2F2底）：
 *   - toolbar_normal「个人考勤」
 *   - 顶部统计卡（白卡 marginTop 44vp）：头像40vp+姓名16fp#333+部门12fp#999 |
 *     右侧「正常打卡N天/月需打卡N天」16fp#333；日期15fp#50B3FE+下拉箭头
 *   - fragment_personal：双蓝卡统计（#388CFC蓝卡24vp#24B3FE底边：月需打卡天数24fp/正常打卡天数24fp）
 *     + 三态视图（缺勤/未签/请假 AttendanceStateView）
 *   - 日历（CalendarView 40dip周条#388CFC选中白字+「假」标记#128C4B）+ 考勤记录列表
 */
class AttendanceRecord {
  date: string;
  signIn: string;
  signOut: string;
  state: string;

  constructor(date: string, signIn: string, signOut: string, state: string) {
    this.date = date;
    this.signIn = signIn;
    this.signOut = signOut;
    this.state = state;
  }
}

@Entry
@Component
struct AttendancePersonalPage {
  @State monthStr: string = '2026年11月';
  @State records: AttendanceRecord[] = [
    new AttendanceRecord('11-17', '07:58', '17:32', '正常'),
    new AttendanceRecord('11-16', '07:55', '17:28', '正常'),
    new AttendanceRecord('11-15', '08:12', '17:30', '迟到'),
    new AttendanceRecord('11-14', '—', '—', '请假')
  ];

  @Builder
  stateCell(label: string, count: string, colorStr: string) {
    Column() {
      Text(count)
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .fontColor(Color.White)
      Text(label)
        .fontSize(12)
        .fontColor(Color.White)
        .margin({ top: 4 })
    }
    .layoutWeight(1)
    .padding({ top: 12, bottom: 12 })
    .borderRadius(4)
    .backgroundColor(colorStr)
    .alignItems(HorizontalAlign.Center)
  }

  build() {
    Column() {
      TitleBar({ title: '个人考勤', showBack: true })

      Scroll() {
        Column() {
          // 顶部白卡（头像+姓名+部门 | 右侧打卡天数）
          Column() {
            // 日期行（15fp #50B3FE + 下拉箭头）
            Row() {
              Blank().layoutWeight(1)
              Text(this.monthStr)
                .fontSize(15)
                .fontColor('#50B3FE')
                .padding({ left: 16, right: 4 })
              Image($r('app.media.arrow_down_blue_desk_widget'))
                .width(12)
                .height(12)
            }
            .width('100%')
            .margin({ top: 20, bottom: 12 })

            // 头像+姓名+部门 | 右侧统计
            Row() {
              Row() {
                Image($r('app.media.mobile_campus_school_logo'))
                  .width(40)
                  .height(40)
                  .borderRadius(20)
                Column() {
                  Text('孔硕')
                    .fontSize(16)
                    .fontColor($r('app.color.common_color_1'))
                  Text('信息工程学院')
                    .fontSize(12)
                    .fontColor($r('app.color.common_color_3'))
                    .margin({ top: 8 })
                }
                .alignItems(HorizontalAlign.Start)
                .margin({ left: 12 })
              }
              .alignItems(VerticalAlign.Center)

              Column() {
                Text('正常打卡16天')
                  .fontSize(16)
                  .fontColor($r('app.color.common_color_1'))
                Text('月需打卡20天')
                  .fontSize(16)
                  .fontColor($r('app.color.common_color_1'))
                  .margin({ top: 8 })
              }
              .alignItems(HorizontalAlign.End)
            }
            .width('100%')
            .padding({ left: 16, right: 16 })
            .justifyContent(FlexAlign.SpaceBetween)

            // 分隔线
            Divider()
              .color($r('app.color.common_color_5'))
              .strokeWidth(0.5)
              .width('100%')
              .margin({ top: 16, bottom: 8 })
          }
          .width('92%')
          .padding({ left: 16, right: 16, bottom: 12 })
          .borderRadius(8)
          .backgroundColor($r('app.color.white'))
          .margin({ top: 16 })

          // 双蓝卡统计（#388CFC 24fp白字）
          Row() {
            this.stateCell('月需打卡天数', '20', '#388CFC')
            Blank().width(13)
            this.stateCell('正常打卡天数', '16', '#388CFC')
          }
          .width('92%')
          .padding({ left: 12, right: 12, top: 8 })
          .alignItems(VerticalAlign.Center)

          // 三态视图（缺勤/未签/请假）
          Row() {
            this.stateCell('缺勤', '2', '#E96161')
            this.stateCell('未签', '1', '#FF8900')
            this.stateCell('请假', '1', '#128C4B')
          }
          .width('92%')
          .padding({ left: 12, right: 12, top: 13 })
          .alignItems(VerticalAlign.Center)

          // 考勤记录列表（透明divider 12vp间隔）
          Column() {
            ForEach(this.records, (r: AttendanceRecord) => {
              Row() {
                Column() {
                  Text(r.date)
                    .fontSize(15)
                    .fontColor($r('app.color.common_color_1'))
                  Text('上班 ' + r.signIn + ' | 下班 ' + r.signOut)
                    .fontSize(12)
                    .fontColor($r('app.color.common_color_3'))
                    .margin({ top: 4 })
                }
                .alignItems(HorizontalAlign.Start)
                .layoutWeight(1)

                Text(r.state)
                  .fontSize(13)
                  .fontColor(r.state === '正常' ? '#128C4B' : r.state === '迟到' ? '#FF8900' :
                    r.state === '请假' ? '#388CFC' : '#E96161')
              }
              .width('100%')
              .padding({ left: 16, right: 16, top: 12, bottom: 12 })
              .borderRadius(6)
              .backgroundColor($r('app.color.white'))
              .alignItems(VerticalAlign.Center)
              .margin({ top: 6 })
            }, (r: AttendanceRecord) => 'att_' + r.date)

            Blank()
              .height(20)
          }
          .width('92%')
          .margin({ top: 12 })
        }
        .width('100%')
      }
      .width('100%')
      .layoutWeight(1)
      .scrollBar(BarState.Off)
      .align(Alignment.Top)
      .backgroundColor($r('app.color.common_color_6'))
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.common_color_6'))
  }
}
