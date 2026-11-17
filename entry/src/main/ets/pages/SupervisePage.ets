import { router } from '@kit.ArkUI';
import { BusinessError } from '@kit.BasicServicesKit';
import { ApiService } from '../network/ApiService';
import { ApiResponse } from '../model/ResponseModel';
import { SuperviseCourseItem } from '../model/SuperviseModel';

/**
 * 督导主页 — 1:1 复刻自：
 *   mobile_campus_supervise_activity_superv...activity_supervise_main.xml
 *   mobile_campus_supervise_view_main.xml（课程列表项）
 *   mobile_campus_supervise_weekview.xml / weekview_item.xml（周视图）
 *   mobile_campus_supervise_toolbar_normal.xml（标题栏：标题 ybg_blue + 搜索/筛选图标）
 */

class SuperviseWeekDay {
  dayLabel: string;
  dateNumber: string;
  checked: boolean;

  constructor(dayLabel: string, dateNumber: string, checked: boolean) {
    this.dayLabel = dayLabel;
    this.dateNumber = dateNumber;
    this.checked = checked;
  }
}

class SuperviseItem {
  section: string;
  courseTitle: string;
  majorInfo: string;

  constructor(section: string, courseTitle: string, majorInfo: string) {
    this.section = section;
    this.courseTitle = courseTitle;
    this.majorInfo = majorInfo;
  }
}

@Entry
@Component
struct SupervisePage {
  @State weekDays: SuperviseWeekDay[] = [
    new SuperviseWeekDay('一', '16', true),
    new SuperviseWeekDay('二', '17', false),
    new SuperviseWeekDay('三', '18', false),
    new SuperviseWeekDay('四', '19', false),
    new SuperviseWeekDay('五', '20', false),
    new SuperviseWeekDay('六', '21', false),
    new SuperviseWeekDay('日', '22', false)
  ];
  @State superviseList: SuperviseItem[] = [
    new SuperviseItem('1-2节', '高等数学（下）', '数学与统计学院 · 2024级数学与应用数学'),
    new SuperviseItem('3-4节', '大学英语（四）', '外国语学院 · 2023级英语专业'),
    new SuperviseItem('6-7节', '数据结构', '计算机学院 · 2024级软件工程'),
    new SuperviseItem('8-9节', '毛泽东思想和中国特色社会主义理论体系概论', '马克思主义学院 · 2023级思想政治教育'),
    new SuperviseItem('10-11节', '大学物理（下）', '物理与电子工程学院 · 2024级应用物理学')
  ];
  @State showTips: boolean = false;

  aboutToAppear(): void {
    ApiService.getSuperviseList()
      .then((response: ApiResponse<SuperviseCourseItem[]>) => {
        if (response.code !== 0) {
          console.info('SupervisePage degrade: code=' + response.code + ' msg=' + response.message);
        }
        if (response.data.length > 0) {
          this.superviseList = response.data.map((entry: SuperviseCourseItem): SuperviseItem => {
            return new SuperviseItem(entry.section, entry.courseTitle, entry.majorInfo);
          });
        }
      })
      .catch((error: BusinessError) => {
        console.info('SupervisePage load fail: ' + error.message);
      });
  }

  private toggleWeekDay(target: SuperviseWeekDay): void {
    this.weekDays = this.weekDays.map((day: SuperviseWeekDay): SuperviseWeekDay => {
      return new SuperviseWeekDay(day.dayLabel, day.dateNumber, day.dateNumber === target.dateNumber);
    });
  }

  build() {
    Column() {
      // mobile_campus_supervise_toolbar_normal.xml：45vp 白底 + 44vp 工具栏 + 细分隔线
      Column() {
        Row() {
          Text('＜')
            .fontSize(16)
            .fontColor($r('app.color.common_color_1'))
            .width(40)
            .height('100%')
            .textAlign(TextAlign.Center)
            .margin({ left: 15 })
            .onClick(() => {
              router.back();
            })
          Text('督导听课')
            .fontSize(17)
            .fontColor($r('app.color.ybg_blue'))
            .layoutWeight(1)
            .textAlign(TextAlign.Center)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
          Row() {
            Image($r('app.media.mobile_campus_supervise_search'))
              .width(24)
              .height(24)
              .margin({ right: 15 })
              .onClick(() => {
                this.showTips = !this.showTips;
              })
            Image($r('app.media.mobile_campus_supervise_screen'))
              .width(24)
              .height(24)
              .margin({ right: 15 })
          }
          .alignItems(VerticalAlign.Center)
        }
        .width('100%')
        .height(44)
        .alignItems(VerticalAlign.Center)

        Divider()
          .color($r('app.color.common_color_5'))
          .strokeWidth(0.5)
          .width('100%')
      }
      .width('100%')
      .backgroundColor($r('app.color.main_bg'))

      // layoutTips：蓝底提示条（默认 gone，点筛选图标切换）
      if (this.showTips) {
        Row() {
          Image($r('app.media.mobile_campus_supervise_teacher'))
            .width(18)
            .height(18)
            .margin({ right: 8 })
          Text('已选择：第12周（11-16 ~ 11-22），点击日期可切换')
            .fontColor(Color.White)
            .fontSize(14)
            .height(32)
            .textAlign(TextAlign.Start)
            .layoutWeight(1)
        }
        .width('100%')
        .alignItems(VerticalAlign.Center)
        .padding({ left: 12, right: 12 })
        .backgroundColor($r('app.color.blue_default'))
      }

      // weekview.xml / weekview_item.xml：7 列周视图
      Row() {
        ForEach(this.weekDays, (day: SuperviseWeekDay) => {
          Column() {
            Text(day.dayLabel)
              .fontSize(14)
              .fontColor($r('app.color.common_color_1'))
            Text(day.dateNumber)
              .fontSize(14)
              .fontColor(day.checked ? Color.White : $r('app.color.common_color_1'))
              .width(32)
              .height(32)
              .borderRadius(16)
              .textAlign(TextAlign.Center)
              .backgroundColor(day.checked ? '#1B68B7' : Color.Transparent)
              .margin({ top: 8 })
              .onClick(() => {
                this.toggleWeekDay(day);
              })
          }
          .layoutWeight(1)
          .padding(12)
          .alignItems(HorizontalAlign.Center)
        }, (day: SuperviseWeekDay) => day.dateNumber)
      }
      .width('100%')
      .backgroundColor($r('app.color.main_bg'))

      // FrameLayout：paddingTop 12，列表 + 右下角悬浮督导图标
      Stack({ alignContent: Alignment.BottomEnd }) {
        List({ space: 0 }) {
          ForEach(this.superviseList, (item: SuperviseItem) => {
            ListItem() {
              Row() {
                Text(item.section)
                  .fontSize(17)
                  .fontColor('#1B6BB7')
                  .padding({ left: 12, right: 15 })
                  .height('100%')
                  .textAlign(TextAlign.Start)
                Column() {
                  Text(item.courseTitle)
                    .fontSize(15)
                    .fontColor($r('app.color.common_color_1'))
                    .maxLines(1)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                    .padding({ top: 2 })
                    .layoutWeight(1)
                  Text(item.majorInfo)
                    .fontSize(14)
                    .fontColor($r('app.color.common_color_3'))
                    .maxLines(1)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                    .padding({ top: 2 })
                    .layoutWeight(1)
                }
                .width(59)
                .height(59)
                .alignItems(HorizontalAlign.Start)
                .justifyContent(FlexAlign.Center)

                Divider()
                  .color($r('app.color.common_color_4'))
                  .strokeWidth(0.5)
                  .width('100%')
              }
              .width('100%')
              .height(60)
              .alignItems(VerticalAlign.Center)
              .backgroundColor($r('app.color.main_bg'))
            }
          }, (item: SuperviseItem) => item.section + '_' + item.courseTitle)
        }
        .width('100%')
        .height('100%')
        .backgroundColor($r('app.color.common_color_6'))

        Image($r('app.media.mobile_campus_supervise_supervisor'))
          .width(52)
          .height(52)
          .margin({ right: 12, bottom: 12 })
          .onClick(() => {
            router.pushUrl({ url: 'pages/SuperviseMinePage' });
          })
      }
      .layoutWeight(1)
      .width('100%')
      .padding({ top: 12 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.common_color_6'))
  }
}
