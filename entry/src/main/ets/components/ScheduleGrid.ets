import { ApiService } from '../network/ApiService';
import { CourseItem } from '../model/CourseModel';

/**
 * 首页课表子Tab — 1:1 复刻 report_item_indextimetable.xml + report_item_indextimetable_item.xml
 *
 * report_item_indextimetable.xml：
 *   根 LinearLayout horizontal 高 px_to_dip_320=160vp
 *   - 左列 ll_timetable 宽 px_to_dip_200=100vp、bg_item_white(白底)：
 *       "课表" px_to_sp_30=15fp common_color_2 居中 weight=1
 *       divider_horizontal_grey_thin
 *       tv_week(第N周) 15fp ybg_blue / tv_date(日期) 12fp common_color_33 weight=1
 *       divider_horizontal_grey_thin
 *       tv_curweek 15fp common_color_2 居中 weight=1
 *   - 右侧 FrameLayout：横向 RecyclerView 课程卡片（无数据时 report_nodata 150dip×147dip）
 *
 * report_item_indextimetable_item.xml（课程卡片）：
 *   RelativeLayout 宽 px_to_dip_300=150vp 高 160vp、bg_item_blue(蓝底)
 *   - tv_session 节次 px_to_sp_28=14fp 白字 paddingTop px_to_dip_8=4vp
 *   - tv_coursename 课程名 px_to_sp_30=15fp 白字 maxLines=3 weight=1
 *   - 地点行：iv_place(loc2) px_to_dip_30=15vp + tv_place 14fp 白字 marginLeft px_to_dip_12=6vp
 *   - 教师行：iv_name(teacher2) 15vp + tv_name 14fp 白字 marginLeft 6vp、paddingV px_to_dip_8=4vp
 */
@Component
export struct ScheduleGrid {
  @State todayCourses: CourseItem[] = [];
  @State weekLabel: string = '';
  @State dateLabel: string = '';

  aboutToAppear(): void {
    ApiService.getScheduleList()
      .then((response) => {
        // 取今日课程（CourseItem.dayOfWeek：1=周一 … 7=周日）
        const today: Date = new Date();
        const dayOfWeek: number = today.getDay() === 0 ? 7 : today.getDay();
        const list: CourseItem[] = [];
        for (const course of response.data) {
          if (course.dayOfWeek === dayOfWeek) {
            list.push(course);
          }
        }
        list.sort((a: CourseItem, b: CourseItem): number => a.sectionStart - b.sectionStart);
        this.todayCourses = list;
      })
      .catch(() => {
        this.todayCourses = [];
      });
    // 学期起始周一 2026-09-07，计算当前周次与日期（tv_week/tv_date/tv_curweek）
    const semesterStart: Date = new Date(2026, 8, 7);
    const now: Date = new Date();
    let week: number = Math.floor((now.getTime() - semesterStart.getTime()) / (7 * 24 * 3600 * 1000)) + 1;
    if (week < 1) {
      week = 1;
    }
    this.weekLabel = '第' + week + '周';
    this.dateLabel = (now.getMonth() + 1) + '月' + now.getDate() + '日';
  }

  private sessionLabel(course: CourseItem): string {
    if (course.sectionStart === course.sectionEnd) {
      return '第' + course.sectionStart + '节';
    }
    return '第' + course.sectionStart + '-' + course.sectionEnd + '节';
  }

  @Builder
  courseCard(course: CourseItem) {
    // report_item_indextimetable_item.xml：150×160 蓝底课程卡片
    Column() {
      // tv_session：节次 14fp 白字 paddingTop 4vp
      Text(this.sessionLabel(course))
        .fontSize(14)
        .fontColor($r('app.color.white'))
        .padding({ top: 4 })
        .width('100%')
      // tv_coursename：课程名 15fp 白字 maxLines=3
      Text(course.name)
        .fontSize(15)
        .fontColor($r('app.color.white'))
        .maxLines(3)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .layoutWeight(1)
        .width('100%')
      // 地点行：loc2 图标 15vp + 地点 14fp 白字
      Row() {
        Image($r('app.media.loc2'))
          .width(15)
          .height(15)
        Text(course.location)
          .fontSize(14)
          .fontColor($r('app.color.white'))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .margin({ left: 6 })
          .layoutWeight(1)
      }
      .width('100%')
      .padding({ bottom: 2 })
      // 教师行：teacher2 图标 15vp + 教师 14fp 白字
      Row() {
        Image($r('app.media.teacher2'))
          .width(15)
          .height(15)
        Text(course.teacher)
          .fontSize(14)
          .fontColor($r('app.color.white'))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .margin({ left: 6 })
          .layoutWeight(1)
      }
      .width('100%')
      .padding({ top: 4, bottom: 4 })
    }
    .width(150)
    .height(160)
    .padding({ left: 8, right: 8 })
    .backgroundColor($r('app.color.ybg_blue'))
    .alignItems(HorizontalAlign.Start)
  }

  build() {
    // 根 LinearLayout 高 160vp（首页嵌入时随父容器拉伸）
    Row() {
      // 左列 ll_timetable：宽 100vp 白底
      Column() {
        // "课表" 15fp common_color_2
        Text($r('app.string.timetable'))
          .fontSize(15)
          .fontColor($r('app.color.common_color_2'))
          .layoutWeight(1)
          .width('100%')
          .textAlign(TextAlign.Center)
        // divider_horizontal_grey_thin
        Divider()
          .color($r('app.color.common_color_5'))
          .strokeWidth(0.5)
          .width('100%')
        Column() {
          // tv_week：第N周 15fp ybg_blue
          Text(this.weekLabel)
            .fontSize(15)
            .fontColor($r('app.color.ybg_blue'))
          // tv_date：日期 12fp common_color_33(#D0D0D0)
          Text(this.dateLabel)
            .fontSize(12)
            .fontColor($r('app.color.common_color_33'))
            .margin({ top: 2 })
        }
        .layoutWeight(1)
        .width('100%')
        .justifyContent(FlexAlign.Center)
        // divider_horizontal_grey_thin
        Divider()
          .color($r('app.color.common_color_5'))
          .strokeWidth(0.5)
          .width('100%')
        // tv_curweek 15fp common_color_2
        Text($r('app.string.schedule_current_week'))
          .fontSize(15)
          .fontColor($r('app.color.common_color_2'))
          .layoutWeight(1)
          .width('100%')
          .textAlign(TextAlign.Center)
      }
      .width(100)
      .height('100%')
      .backgroundColor($r('app.color.main_bg'))

      // 右侧：横向课程卡片列表 / 无数据态
      if (this.todayCourses.length === 0) {
        // fl_nodata：report_nodata 150dip×147dip 水平居中
        Column() {
          Image($r('app.media.report_nodata'))
            .width(75)
            .height(73.5)
        }
        .layoutWeight(1)
        .height('100%')
        .backgroundColor($r('app.color.main_bg'))
        .justifyContent(FlexAlign.Center)
      } else {
        // rv_recyclerview_horizontal
        Scroll() {
          Row() {
            ForEach(this.todayCourses, (course: CourseItem) => {
              this.courseCard(course)
            }, (course: CourseItem) => 'homecourse' + course.id)
          }
          .alignItems(VerticalAlign.Center)
        }
        .scrollable(ScrollDirection.Horizontal)
        .scrollBar(BarState.Off)
        .layoutWeight(1)
        .height('100%')
        .backgroundColor($r('app.color.main_bg'))
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.main_bg'))
  }
}
