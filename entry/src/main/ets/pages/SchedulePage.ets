import { TitleBar } from '../components/TitleBar';
import { ApiService } from '../network/ApiService';
import { CourseItem } from '../model/CourseModel';

/**
 * 课表页 — 1:1 复刻 mobile_campus_timetable_activity_index.xml
 *
 * 结构（RelativeLayout 白底）：
 *   - toolbar_normal（TitleBar 复刻）
 *   - timetable_week_container（bg common_color_5 #E7E7E7）：
 *       timetable_tv_month "--月" TextSize3.Color7=16fp common_color_7(#18B4ED)、
 *       宽 timetable_month_width=25vp 居中（点击弹出周次选择）
 *       ll_date 高 px_to_dip_90=45vp：7 个 timetabledatetext（13dip=6.5fp common_color_3 居中）
 *       ll_underLine：7 个 timetabledateundeline 高 3dip=1.5vp（今日列 ybg_blue）
 *   - divider 高 0.3dip bg common_color_4
 *   - timetable_content_container：白底，左侧节次时间轴（week_view_section_item）+
 *     7 列课程网格（绝对定位课程格子，参照 mobile_campus_timetable_desk_course_box.xml）
 *   - timetable_iv_open_class_btn：右下 FAB(mipmap mobile_campus_timetable_course_iv_open)
 *     marginRight px_to_dip_20=10vp marginBottom px_to_dip_30=15vp
 *
 * 其他复刻布局：
 *   - timetable_choose_week_item.xml：周选择条目 TextSize2.Color3=17fp common_color_3、
 *     padding px_to_dip_30=15vp 居中 maxLines=1（当前周高亮 #97000C）
 *   - mobile_campus_view_timetable_empty.xml：空态（左右 14×1vp #8F9FAF 线 +
 *     16fp #8F9FAF "无课程安排"，paddingV px_to_dip_50=25vp）
 *   - mobile_campus_timetable_view_weekcourse.xml：点击日期列弹出的当日课程列表行
 *     （高 91dip=45.5vp bg #F2F2F2、底部 1dip 白线；tvCourseSection common_color_3、
 *     tvTitle 17fp common_color_1、地点/教师 12fp common_color_31 带小图标）
 *
 * 课程格子配色：布局 XML 无色值，按任务要求使用 #97000C 主色的深浅变体数组。
 */
class ScheduleDateCell {
  dateNum: string;
  weekChar: string;

  constructor(dateNum: string, weekChar: string) {
    this.dateNum = dateNum;
    this.weekChar = weekChar;
  }
}

@Entry
@Component
struct SchedulePage {
  @State courseList: CourseItem[] = [];
  @State weekNumber: number = 1;
  @State dateCells: ScheduleDateCell[] = [];
  @State monthLabel: string = '--月';
  @State showWeekPanel: boolean = false;
  @State showDayPanel: boolean = false;
  @State panelDay: number = 0;
  private todayCol: number = 0;
  private todayWeek: number = 1;
  private sectionTimes: string[] = ['08:00', '08:55', '10:00', '10:55', '14:00', '14:55',
    '16:00', '16:55', '19:00', '19:55', '20:50', '21:45'];
  // Android 端课程格子配色数组（XML 无色值，取 #97000C 主色深浅变体）
  private colorPool: string[] = ['#97000C', '#A8262F', '#B03A43', '#8C2A33',
    '#C05B63', '#7E1B23', '#93424B', '#D07E85'];

  aboutToAppear(): void {
    const now: Date = new Date();
    this.todayCol = now.getDay() === 0 ? 6 : now.getDay() - 1;
    // 学期起始周一 2026-09-07
    const semesterStart: Date = new Date(2026, 8, 7);
    let week: number = Math.floor((now.getTime() - semesterStart.getTime()) / (7 * 24 * 3600 * 1000)) + 1;
    if (week < 1) {
      week = 1;
    }
    this.todayWeek = week;
    this.applyWeek(week);
    ApiService.getScheduleList()
      .then((response) => {
        this.courseList = response.data;
      })
      .catch(() => {
        this.courseList = [];
      });
  }

  private applyWeek(week: number): void {
    this.weekNumber = week;
    // 该周周一 = 学期起始周一 + (week-1)*7
    const monday: Date = new Date(2026, 8, 7 + (week - 1) * 7);
    const weekChars: string[] = ['一', '二', '三', '四', '五', '六', '日'];
    const cells: ScheduleDateCell[] = [];
    for (let i = 0; i < 7; i++) {
      const date: Date = new Date(monday.getFullYear(), monday.getMonth(), monday.getDate() + i);
      cells.push(new ScheduleDateCell('' + date.getDate(), weekChars[i]));
    }
    this.dateCells = cells;
    this.monthLabel = (monday.getMonth() + 1) + '月';
  }

  private weekOptions(): number[] {
    const options: number[] = [];
    for (let i = 1; i <= 20; i++) {
      options.push(i);
    }
    return options;
  }

  private underlineIndex(): number {
    return this.weekNumber === this.todayWeek ? this.todayCol : 0;
  }

  private dayCourses(day: number): CourseItem[] {
    const list: CourseItem[] = [];
    for (const course of this.courseList) {
      if (course.dayOfWeek === day + 1) {
        list.push(course);
      }
    }
    return list;
  }

  private courseColor(course: CourseItem): string {
    let index: number = 0;
    for (let i = 0; i < this.courseList.length; i++) {
      if (this.courseList[i].id === course.id) {
        index = i;
        break;
      }
    }
    return this.colorPool[index % this.colorPool.length];
  }

  private sessionLabel(course: CourseItem): string {
    return '第' + course.sectionStart + '-' + course.sectionEnd + '节';
  }

  /**
   * 周选择面板 — timetable_choose_week_item.xml：
   * TextSize2.Color3=17fp common_color_3、padding px_to_dip_30=15vp、居中、maxLines=1（当前周 #97000C 加粗）
   */
  @Builder
  weekPanel() {
    Column() {
      ForEach(this.weekOptions(), (week: number) => {
        Text('第' + week + '周')
          .fontSize(17)
          .fontColor(week === this.weekNumber ?
            $r('app.color.mobile_campus_primary_color') : $r('app.color.common_color_3'))
          .fontWeight(week === this.weekNumber ? FontWeight.Bold : FontWeight.Normal)
          .padding(15)
          .width('100%')
          .textAlign(TextAlign.Center)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .onClick(() => {
            this.applyWeek(week);
            this.showWeekPanel = false;
          })
      }, (week: number) => 'weekoption' + week)
    }
    .width(120)
    .backgroundColor($r('app.color.white'))
    .borderRadius(6)
    .position({ x: 0, y: 47 })
  }

  /**
   * 顶部周/日期条 — activity_index.xml timetable_week_container（bg common_color_5）
   */
  @Builder
  weekHeader() {
    Row() {
      // timetable_tv_month："--月" 16fp common_color_7 宽 25vp 居中，点击弹出周次选择
      Text(this.monthLabel)
        .fontSize(16)
        .fontColor($r('app.color.common_color_7'))
        .width(25)
        .textAlign(TextAlign.Center)
        .onClick(() => {
          this.showWeekPanel = !this.showWeekPanel;
        })
      Column() {
        // ll_date：高 45vp，7 个 timetabledatetext（6.5fp common_color_3 居中，两行"日期\n周几"）
        Row() {
          ForEach(this.dateCells, (cell: ScheduleDateCell) => {
            Text(cell.dateNum + '\n' + cell.weekChar)
              .fontSize(6.5)
              .fontColor($r('app.color.common_color_3'))
              .layoutWeight(1)
              .height('100%')
              .textAlign(TextAlign.Center)
          }, (cell: ScheduleDateCell) => 'date' + cell.weekChar)
        }
        .width('100%')
        .height(45)
        // ll_underLine：7 个 timetabledateundeline（高 1.5vp，选中列 ybg_blue）
        Row() {
          ForEach(this.dateCells, (lineCell: ScheduleDateCell, index: number) => {
            Row()
              .layoutWeight(1)
              .height(1.5)
              .backgroundColor(index === this.underlineIndex() ?
                $r('app.color.ybg_blue') : Color.Transparent)
          }, (lineCell: ScheduleDateCell) => 'underline' + lineCell.weekChar)
        }
        .width('100%')
      }
      .layoutWeight(1)
    }
    .width('100%')
    .backgroundColor($r('app.color.common_color_5'))
    .alignItems(VerticalAlign.Center)
  }

  /**
   * 左侧节次时间轴条目 — mobile_campus_timetable_week_view_section_item.xml：
   * 高 timetable_section_height=27.5vp；内容 bg common_color_6 宽 timetable_month_width；
   * 开始时间 TextSize5.Color3=12fp common_color_3；节次号 TextSize3.Color2=16fp common_color_2
   * marginTop px_to_dip_8=4vp；底部分隔线 common_color_5 divider_thin_size
   */
  @Builder
  sectionAxisItem(time: string, section: number) {
    Column() {
      Column() {
        Text(time)
          .fontSize(12)
          .fontColor($r('app.color.common_color_3'))
          .width('100%')
          .textAlign(TextAlign.Center)
        Text(section + '')
          .fontSize(16)
          .fontColor($r('app.color.common_color_2'))
          .margin({ top: 4 })
          .width('100%')
          .textAlign(TextAlign.Center)
      }
      .layoutWeight(1)
      .width('100%')
      .backgroundColor($r('app.color.common_color_6'))
      .justifyContent(FlexAlign.Center)
      Divider()
        .color($r('app.color.common_color_5'))
        .strokeWidth(0.5)
        .width('100%')
    }
    .width('100%')
    .height(27.5)
  }

  /**
   * 课程格子 — 参照 mobile_campus_timetable_desk_course_box.xml：
   * 文字 11fp(px_to_dip_22/2) 白字、paddingLeft/Right px_to_dip_6=3vp、ellipsize；
   * 按节次绝对定位（Android 端绝对布局），显示课程名/教室
   */
  @Builder
  courseBlock(course: CourseItem) {
    Column() {
      Text(course.name)
        .fontSize(11)
        .fontColor($r('app.color.white'))
        .fontWeight(FontWeight.Bold)
        .maxLines(2)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .width('100%')
      Text('@' + course.location)
        .fontSize(9)
        .fontColor($r('app.color.white'))
        .opacity(0.9)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .width('100%')
        .margin({ top: 2 })
    }
    .width('100%')
    .height((course.sectionEnd - course.sectionStart + 1) * 27.5 - 2)
    .padding({ left: 3, right: 3, top: 2, bottom: 2 })
    .position({ x: 0, y: (course.sectionStart - 1) * 27.5 + 1 })
    .backgroundColor(this.courseColor(course))
    .borderRadius(3)
    .alignItems(HorizontalAlign.Start)
  }

  /**
   * 单日列：Stack 内绝对定位课程格子
   */
  @Builder
  dayColumn(day: number) {
    Stack() {
      ForEach(this.dayCourses(day), (course: CourseItem) => {
        this.courseBlock(course)
      }, (course: CourseItem) => 'cell' + course.id)
    }
    .layoutWeight(1)
    .height(330)
    .onClick(() => {
      this.panelDay = day;
      this.showDayPanel = true;
    })
  }

  /**
   * 空态 — mobile_campus_view_timetable_empty.xml：
   * 左右 14×1vp #8F9FAF 线 + 16fp #8F9FAF 文案，marginH px_to_dip_30=15vp，paddingV 25vp
   */
  @Builder
  emptyCourseView() {
    Column() {
      Row() {
        Row()
          .width(14)
          .height(1)
          .backgroundColor($r('app.color.timetable_empty_color'))
        Text($r('app.string.timetable_empty'))
          .fontSize(16)
          .fontColor($r('app.color.timetable_empty_color'))
          .margin({ left: 15, right: 15 })
        Row()
          .width(14)
          .height(1)
          .backgroundColor($r('app.color.timetable_empty_color'))
      }
    }
    .width('100%')
    .padding({ top: 25, bottom: 25 })
  }

  /**
   * 当日课程列表行 — mobile_campus_timetable_view_weekcourse.xml：
   * 高 91dip=45.5vp bg #F2F2F2、底部 1dip 白线；tvCourseSection(common_color_3 padding 4vp)、
   * tvTitle px_to_sp_34=17fp common_color_1；地点/教师 px_to_sp_24=12fp common_color_31
   * 带图标 drawablePadding 4vp；整行 padding 4.5vp
   */
  @Builder
  dayPanelRow(course: CourseItem) {
    Column() {
      Row() {
        // tvCourseSection：节次，默认字号 common_color_3
        Text(this.sessionLabel(course))
          .fontSize(14)
          .fontColor($r('app.color.common_color_3'))
          .padding(4)
        // layoutContainer：marginLeft 15dip=7.5vp padding 4vp
        Column() {
          // tvTitle：课程名 17fp common_color_1
          Text(course.name)
            .fontSize(17)
            .fontColor($r('app.color.common_color_1'))
            .width('100%')
          // 地点/教师行 marginTop 6vp
          Row() {
            Row() {
              Image($r('app.media.mobile_campus_timetable_widget_timetable_locale'))
                .width(14)
                .height(14)
              Text(course.location)
                .fontSize(12)
                .fontColor($r('app.color.common_color_31'))
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
                .margin({ left: 4 })
                .layoutWeight(1)
            }
            .layoutWeight(1)
            Row() {
              Image($r('app.media.mobile_campus_timetable_widget_timetable_time'))
                .width(14)
                .height(14)
              Text(course.teacher)
                .fontSize(12)
                .fontColor($r('app.color.common_color_31'))
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
                .margin({ left: 4 })
                .layoutWeight(1)
            }
            .layoutWeight(1)
          }
          .width('100%')
          .margin({ top: 6 })
        }
        .margin({ left: 7.5 })
        .padding(4)
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)
      }
      .width('100%')
      .layoutWeight(1)
      .padding(4.5)
      .alignItems(VerticalAlign.Center)
      // tvLine：底部 1dip 白线
      Divider()
        .color($r('app.color.white'))
        .strokeWidth(0.5)
        .width('100%')
    }
    .width('100%')
    .height(45.5)
    .backgroundColor($r('app.color.common_color_6'))
  }

  /**
   * 当日课程面板：点击课程网格日期列弹出，点击任意处关闭
   */
  @Builder
  dayPanel() {
    Column() {
      if (this.dayCourses(this.panelDay).length === 0) {
        this.emptyCourseView()
      } else {
        ForEach(this.dayCourses(this.panelDay), (course: CourseItem) => {
          this.dayPanelRow(course)
        }, (course: CourseItem) => 'panel' + course.id)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.white'))
    .onClick(() => {
      this.showDayPanel = false;
    })
  }

  build() {
    Stack({ alignContent: Alignment.TopStart }) {
      Column() {
        // include toolbar_normal
        TitleBar({ title: '我的课表', showBack: true })
        // timetable_week_container
        this.weekHeader()
        // divider：高 0.3dip bg common_color_4
        Row()
          .width('100%')
          .height(0.5)
          .backgroundColor($r('app.color.common_color_4'))
        // timetable_content_container：白底课表内容
        Stack({ alignContent: Alignment.BottomEnd }) {
          if (this.courseList.length === 0) {
            Column() {
              this.emptyCourseView()
            }
            .width('100%')
            .height('100%')
            .justifyContent(FlexAlign.Center)
          } else {
            Row() {
              // 左侧节次时间轴：宽 25vp
              Column() {
                ForEach(this.sectionTimes, (time: string, index: number) => {
                  this.sectionAxisItem(time, index + 1)
                }, (time: string) => 'axis' + time)
              }
              .width(25)
              // 7 列课程网格
              Row() {
                ForEach([0, 1, 2, 3, 4, 5, 6], (day: number) => {
                  this.dayColumn(day)
                }, (day: number) => 'daycol' + day)
              }
              .layoutWeight(1)
              .height(330)
            }
            .width('100%')
          }
          // 当日课程面板覆盖层
          if (this.showDayPanel) {
            this.dayPanel()
          }
          // timetable_iv_open_class_btn：右下角悬浮按钮
          // marginRight px_to_dip_20=10vp marginBottom px_to_dip_30=15vp
          Image($r('app.media.mobile_campus_timetable_course_iv_open'))
            .width(71.5)
            .height(71.5)
            .margin({ right: 10, bottom: 15 })
        }
        .width('100%')
        .layoutWeight(1)
        .backgroundColor($r('app.color.white'))
      }
      .width('100%')
      .height('100%')
      // 周次选择面板（timetable_choose_week_item）
      if (this.showWeekPanel) {
        this.weekPanel()
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.white'))
  }
}
