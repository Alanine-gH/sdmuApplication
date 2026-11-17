import { router } from '@kit.ArkUI';
import { BusinessError } from '@kit.BasicServicesKit';
import { ApiService } from '../network/ApiService';
import { ApiResponse } from '../model/ResponseModel';
import { CourseItem, sectionTimeLabel } from '../model/CourseModel';
import { ExamItem } from '../model/ScoreModel';

/**
 * I校园 Tab — 复刻 mobile_campus_fragment_icampus.xml：
 * 白底容器 paddingTop 9vp(px_to_dip_18) + 滚动区 #F2F2F2 + 右下角回顶按钮(mobile_campus_top, margin 8dip)。
 * 内容模块：
 *   - mobile_campus_view_main_schedule.xml（今日课表卡）
 *   - mobile_campus_view_main_group_title.xml（分组标题）
 *   - mobile_campus_view_main_app.xml（应用条目：icon 32dip、名称15fp粗体#333333）
 *   - examination_tag.xml（"教务提供"标签：10fp白字蓝底圆角）
 */

class ICampusCourseInfo {
  num: string;
  title: string;
  location: string;

  constructor(num: string, title: string, location: string) {
    this.num = num;
    this.title = title;
    this.location = location;
  }
}

class ICampusAppInfo {
  name: string;
  icon: Resource;
  url: string;

  constructor(name: string, icon: Resource, url: string) {
    this.name = name;
    this.icon = icon;
    this.url = url;
  }
}

class ICampusExamInfo {
  subject: string;
  time: string;
  place: string;

  constructor(subject: string, time: string, place: string) {
    this.subject = subject;
    this.time = time;
    this.place = place;
  }
}

@Component
export struct ICampusTab {
  // 离线降级内置数据：课表接口（getScheduleList）失败时展示的示例课程
  @State courseList: ICampusCourseInfo[] = [
    new ICampusCourseInfo('01', '高等数学（下）', '教学楼A301  08:00-09:40'),
    new ICampusCourseInfo('02', '大学英语（四）', '外语楼B203  10:00-11:40'),
    new ICampusCourseInfo('03', '数据结构', '实验楼C105  14:00-15:40')
  ];
  @State appList: ICampusAppInfo[] = [
    new ICampusAppInfo('课表', $r('app.media.mobile_campus_icon_calendar'), 'pages/SchedulePage'),
    new ICampusAppInfo('成绩', $r('app.media.average_score'), 'pages/ScorePage'),
    new ICampusAppInfo('考试', $r('app.media.examination_table'), 'pages/ExamPage'),
    new ICampusAppInfo('考勤', $r('app.media.attendance_time'), 'pages/AttendancePage')
  ];
  // 离线降级内置数据：考试接口（getExamList）失败时展示的示例考试
  @State examList: ICampusExamInfo[] = [
    new ICampusExamInfo('高等数学（下）', '2026-01-08 09:00-11:00', '第一教学楼A201'),
    new ICampusExamInfo('数据结构', '2026-01-10 14:00-16:00', '第二教学楼B105')
  ];
  @State showBackTop: boolean = false;
  scroller: Scroller = new Scroller();

  aboutToAppear(): void {
    ApiService.getScheduleList()
      .then((response: ApiResponse<CourseItem[]>) => {
        if (response.data.length > 0) {
          let index: number = 0;
          this.courseList = response.data.map((course: CourseItem): ICampusCourseInfo => {
            index = index + 1;
            const numText: string = index < 10 ? '0' + index.toString() : index.toString();
            const timeText: string = sectionTimeLabel(course.sectionStart, course.sectionEnd);
            const locationText: string = timeText !== '' ?
              course.location + '  ' + timeText : course.location;
            return new ICampusCourseInfo(numText, course.name, locationText);
          });
        }
        if (!ApiService.isSuccess(response)) {
          this.getUIContext().getPromptAction().showToast({ message: '课表加载失败，已展示离线数据：' + response.message });
        }
      })
      .catch((error: BusinessError) => {
        this.getUIContext().getPromptAction().showToast({ message: '课表加载失败，已展示离线数据：' + (error as BusinessError).message });
      });
    ApiService.getExamList()
      .then((response: ApiResponse<ExamItem[]>) => {
        if (response.data.length > 0) {
          this.examList = response.data.map((exam: ExamItem): ICampusExamInfo => {
            return new ICampusExamInfo(exam.courseName, exam.time, exam.location);
          });
        }
        if (!ApiService.isSuccess(response)) {
          this.getUIContext().getPromptAction().showToast({ message: '考试安排加载失败，已展示离线数据：' + response.message });
        }
      })
      .catch((error: BusinessError) => {
        this.getUIContext().getPromptAction().showToast({ message: '考试安排加载失败，已展示离线数据：' + (error as BusinessError).message });
      });
  }

  /**
   * mobile_campus_view_main_group_title.xml — 分组标题。
   * 高 px_to_dip_80=40vp、padding 左右 px_to_dip_24=12vp、
   * 标题 px_to_sp_30=15fp @color/mobile_campus_primary_color、drawableLeft + drawablePadding px_to_dip_16=8vp。
   */
  @Builder
  groupTitleCell(title: string, icon: Resource) {
    Column() {
      Row() {
        Image(icon)
          .width(20)
          .height(20)
        Text(title)
          .fontSize(15)
          .fontColor($r('app.color.mobile_campus_primary_color'))
          .margin({ left: 8 })
      }
      .height(40)
      .width('100%')
      .padding({ left: 12, right: 12 })
      .alignItems(VerticalAlign.Center)
      .alignSelf(ItemAlign.Stretch)

      Divider()
        .color($r('app.color.common_color_6'))
        .strokeWidth(1)
    }
    .width('100%')
    .backgroundColor($r('app.color.white'))
  }

  /**
   * mobile_campus_view_main_schedule.xml — 今日课表单节课。
   * tvNum：宽 px_to_dip_90=45vp、px_to_sp_42=21fp、#DFE4EA、居中；
   * 内容列 padding px_to_dip_24=12vp，课程名 px_to_sp_34=17fp #333333，
   * 教室/时间 px_to_dip_28=14fp #999999、marginTop px_to_dip_16=8vp。
   */
  @Builder
  scheduleCourseCell(course: ICampusCourseInfo) {
    Column() {
      Row() {
        Text(course.num)
          .fontSize(21)
          .fontColor($r('app.color.menu_divider'))
          .textAlign(TextAlign.Center)
          .width(45)
        Column() {
          Text(course.title)
            .fontSize(17)
            .fontColor($r('app.color.common_color_1'))
          Text(course.location)
            .fontSize(14)
            .fontColor($r('app.color.common_color_3'))
            .margin({ top: 8 })
        }
        .padding(12)
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)
    }
    .width('100%')
    .backgroundColor($r('app.color.white'))
  }

  /**
   * mobile_campus_view_main_app.xml — 应用条目。
   * padding 左右 px_to_dip_32=16vp、上下 px_to_dip_20=10vp；
   * icon 32dip + margin 8dip；名称 px_to_sp_30=15fp 粗体 #333333，右侧箭头。
   */
  @Builder
  appEntryCell(app: ICampusAppInfo) {
    Row() {
      Image(app.icon)
        .width(32)
        .height(32)
        .margin(8)
        .objectFit(ImageFit.Cover)
      Text(app.name)
        .fontSize(15)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.common_color_1'))
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .margin({ left: 12 })
        .layoutWeight(1)
      Image($r('app.media.arrow_right'))
        .width(16)
        .height(16)
        .opacity(0.6)
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 10, bottom: 10 })
    .alignItems(VerticalAlign.Center)
    .onClick(() => {
      router.pushUrl({ url: app.url });
    })
  }

  /**
   * 考试安排条目 — 科目 + examination_tag"教务提供"标签（10fp白字蓝底圆角，
   * padding 左右 px_to_dip_12=6vp、上下 px_to_dip_6=3vp）+ 时间/考场行。
   */
  @Builder
  examEntryCell(exam: ICampusExamInfo) {
    Column() {
      Row() {
        Text(exam.subject)
          .fontSize(15)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.common_color_1'))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .layoutWeight(1)
        Text('教务提供')
          .fontSize(10)
          .fontColor($r('app.color.white'))
          .backgroundColor($r('app.color.blue_default'))
          .borderRadius(4)
          .padding({ left: 6, right: 6, top: 3, bottom: 3 })
          .margin({ left: 8 })
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)

      Row() {
        Image($r('app.media.examination_time'))
          .width(14)
          .height(14)
        Text(exam.time)
          .fontSize(14)
          .fontColor($r('app.color.common_color_3'))
          .margin({ left: 6 })
      }
      .width('100%')
      .margin({ top: 8 })
      .alignItems(VerticalAlign.Center)

      Row() {
        Image($r('app.media.examination_place'))
          .width(14)
          .height(14)
        Text(exam.place)
          .fontSize(14)
          .fontColor($r('app.color.common_color_3'))
          .margin({ left: 6 })
      }
      .width('100%')
      .margin({ top: 8 })
      .alignItems(VerticalAlign.Center)
    }
    .width('100%')
    .padding(12)
    .backgroundColor($r('app.color.white'))
  }

  build() {
    Column() {
      Stack({ alignContent: Alignment.BottomEnd }) {
        // RecyclerView：#F2F2F2
        Scroll(this.scroller) {
          Column() {
            this.groupTitleCell('今日课表', $r('app.media.mobile_campus_main_schedule'))
            ForEach(this.courseList, (course: ICampusCourseInfo) => {
              this.scheduleCourseCell(course)
              Divider()
                .color($r('app.color.common_color_6'))
                .strokeWidth(1)
            }, (course: ICampusCourseInfo) => 'campus_course_' + course.num + '_' + course.title)

            this.groupTitleCell('校园应用', $r('app.media.mobile_campus_icon_course'))
            ForEach(this.appList, (app: ICampusAppInfo) => {
              this.appEntryCell(app)
              Divider()
                .color($r('app.color.common_color_6'))
                .strokeWidth(1)
            }, (app: ICampusAppInfo) => 'campus_app_' + app.name)

            this.groupTitleCell('考试安排', $r('app.media.examination_term'))
            ForEach(this.examList, (exam: ICampusExamInfo) => {
              this.examEntryCell(exam)
              Divider()
                .color($r('app.color.common_color_6'))
                .strokeWidth(1)
            }, (exam: ICampusExamInfo) => 'campus_exam_' + exam.subject + '_' + exam.time)
          }
          .width('100%')
          .padding({ bottom: 12 })
          .backgroundColor($r('app.color.common_color_6'))
        }
        .scrollable(ScrollDirection.Vertical)
        .width('100%')
        .height('100%')
        .onScroll((xOffset: number, yOffset: number) => {
          this.showBackTop = this.scroller.currentOffset().yOffset > 200;
        })

        // imgTop：右下回顶按钮，layout_margin=8dip
        if (this.showBackTop) {
          Image($r('app.media.mobile_campus_top'))
            .width(40)
            .height(40)
            .margin(8)
            .objectFit(ImageFit.Contain)
            .onClick(() => {
              this.scroller.scrollTo({ xOffset: 0, yOffset: 0 });
              this.showBackTop = false;
            })
        }
      }
      .width('100%')
      .height('100%')
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.white'))
    .padding({ top: 9 })
  }
}
