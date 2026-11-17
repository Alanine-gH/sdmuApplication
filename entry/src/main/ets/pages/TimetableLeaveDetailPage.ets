import { TitleBar } from '../components/TitleBar';

/**
 * 请假学生详情页 — 1:1 复刻 mobile_campus_timetable_leave_student_detail.xml
 *   + leave_student_header.xml + leave_student_item.xml
 * 结构：LinearLayout + toolbar_normal("请假名单")
 *   + header：白底 padding 12vp "请假名单" 17fp(px_to_sp_34) common_color_1
 *   + item：白底 padding 12vp，头像 24vp(px_to_dip_48)，姓名 17fp 宽60vp(px_to_dip_120)，
 *     学号 14fp(px_to_sp_28) common_color_3 宽110vp(px_to_dip_220)，班级 14fp common_color_1
 *   + detail 弹层(leave_student_detail)：paddingH 12vp，标题行 marginV 12vp
 *     "请假详情" 18fp(px_to_sp_36) 居中 + 关闭钮(padding 6vp)；分隔线 common_color_6 0.5vp(px_to_dip_1)；
 *     姓名 18fp 粗体 ybg_blue；信息行 标签 18fp common_color_3 宽100vp + 值 18fp common_color_1
 *
 * 数据源：无服务器接口 — ApiService 未提供请假学生列表端点，页面为内置示例数据。
 */
class LeaveStudent {
  name: string;
  number: string;
  className: string;
  profession: string;
  startDate: string;
  endDate: string;
  startSection: string;
  endSection: string;
  reason: string;

  constructor(name: string, number: string, className: string, profession: string,
    startDate: string, endDate: string, startSection: string, endSection: string, reason: string) {
    this.name = name;
    this.number = number;
    this.className = className;
    this.profession = profession;
    this.startDate = startDate;
    this.endDate = endDate;
    this.startSection = startSection;
    this.endSection = endSection;
    this.reason = reason;
  }
}

class DetailRow {
  label: string;
  value: string;

  constructor(label: string, value: string) {
    this.label = label;
    this.value = value;
  }
}

@Entry
@Component
struct TimetableLeaveDetailPage {
  @State selected: LeaveStudent = new LeaveStudent('', '', '', '', '', '', '', '', '');
  @State showDetail: boolean = false;
  private detailRows: DetailRow[] = [];
  private students: LeaveStudent[] = [
    new LeaveStudent('张三', '20230001', '2023级软件工程1班', '软件工程', '2026-11-17 08:00', '2026-11-17 10:00', '第1节', '第2节', '身体不适，前往校医院就诊'),
    new LeaveStudent('李四', '20230002', '2023级软件工程1班', '软件工程', '2026-11-18 14:00', '2026-11-18 16:00', '第5节', '第6节', '家中有事，请假回家'),
    new LeaveStudent('王五', '20230003', '2023级软件工程2班', '软件工程', '2026-11-19 08:00', '2026-11-19 12:00', '第1节', '第4节', '参加省级比赛')
  ];

  private openDetail(student: LeaveStudent): void {
    this.selected = student;
    this.detailRows = [
      new DetailRow('学号:', student.number),
      new DetailRow('专业:', student.profession),
      new DetailRow('班级:', student.className),
      new DetailRow('开始时间:', student.startDate),
      new DetailRow('结束时间:', student.endDate),
      new DetailRow('开始节次:', student.startSection),
      new DetailRow('结束节次:', student.endSection),
      new DetailRow('请假事由:', student.reason)
    ];
    this.showDetail = true;
  }

  build() {
    Stack() {
      Column() {
        TitleBar({ title: '请假名单', showBack: true })

        // leave_student_header：白底 padding 12vp
        Row() {
          Text('请假名单')
            .fontSize(17)
            .fontColor($r('app.color.common_color_1'))
        }
        .width('100%')
        .padding(12)
        .backgroundColor($r('app.color.ybg_white'))

        List() {
          ForEach(this.students, (student: LeaveStudent) => {
            ListItem() {
              // leave_student_item：白底 padding 12vp
              Row() {
                Image($r('app.media.mobile_campus_timetable_leave_student_avatar'))
                  .width(24)
                  .height(24)
                Text(student.name)
                  .fontSize(17)
                  .fontColor($r('app.color.common_color_1'))
                  .width(60)
                  .margin({ left: 12 })
                Text(student.number)
                  .fontSize(14)
                  .fontColor($r('app.color.common_color_3'))
                  .width(110)
                  .margin({ left: 12 })
                Text(student.className)
                  .fontSize(14)
                  .fontColor($r('app.color.common_color_1'))
                  .margin({ left: 12 })
                  .layoutWeight(1)
              }
              .width('100%')
              .alignItems(VerticalAlign.Center)
              .padding(12)
              .backgroundColor($r('app.color.ybg_white'))
              .onClick(() => {
                this.openDetail(student);
              })
            }
          }, (student: LeaveStudent) => student.number)
        }
        .width('100%')
        .layoutWeight(1)
        .backgroundColor($r('app.color.common_color_6'))
        .divider({ strokeWidth: 0.5, color: $r('app.color.common_color_5') })
      }
      .width('100%')
      .height('100%')

      // leave_student_detail 弹层
      if (this.showDetail) {
        Column() {
          // 标题行 marginV 12vp："请假详情" 18fp 居中 + 关闭钮
          Stack() {
            Text('请假详情')
              .fontSize(18)
              .fontColor($r('app.color.common_color_1'))
            Row() {
              Image($r('app.media.mobile_campus_base_close_g'))
                .width(24)
                .height(24)
                .objectFit(ImageFit.Contain)
                .onClick(() => {
                  this.showDetail = false;
                })
            }
            .width('100%')
            .justifyContent(FlexAlign.End)
          }
          .width('100%')
          .height(36)
          .margin({ top: 12, bottom: 12 })

          // 分隔线 common_color_6 0.5vp
          Divider()
            .color($r('app.color.common_color_6'))
            .strokeWidth(0.5)
            .width('100%')

          // 姓名 18fp 粗体 ybg_blue marginTop 12vp
          Text(this.selected.name)
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor($r('app.color.ybg_blue'))
            .margin({ top: 12 })

          // 信息行：标签 18fp common_color_3 宽100vp + 值 18fp common_color_1
          ForEach(this.detailRows, (row: DetailRow, index: number) => {
            Row() {
              Text(row.label)
                .fontSize(18)
                .fontColor($r('app.color.common_color_3'))
                .width(100)
              Text(row.value)
                .fontSize(18)
                .fontColor($r('app.color.common_color_1'))
                .margin({ left: 6 })
                .layoutWeight(1)
            }
            .width('100%')
            .alignItems(VerticalAlign.Top)
            .margin({ bottom: index === this.detailRows.length - 1 ? 24 : 12 })
          }, (row: DetailRow) => row.label)
        }
        .width('100%')
        .height('100%')
        .padding({ left: 12, right: 12 })
        .backgroundColor($r('app.color.main_bg'))
      }
    }
    .width('100%')
    .height('100%')
  }
}
