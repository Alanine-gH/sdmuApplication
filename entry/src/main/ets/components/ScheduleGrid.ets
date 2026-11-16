import { ApiService } from '../network/ApiService';
import { CourseItem } from '../model/CourseModel';

/**
 * 课表周视图：7天 × 12节 网格，课程色块展示。
 */
@Component
export struct ScheduleGrid {
  @State courseList: CourseItem[] = [];
  @State todayIndex: number = 0;
  private dayNames: string[] = ['一', '二', '三', '四', '五', '六', '日'];
  private colorPool: string[] = ['#1677FF', '#52C41A', '#FAAD14', '#FF4D4F', '#722ED1', '#13C2C2', '#EB2F96', '#FA8C16', '#2F54EB'];

  aboutToAppear(): void {
    ApiService.getScheduleList()
      .then((response) => {
        this.courseList = response.data;
      })
      .catch(() => {
        this.courseList = [];
      });
    const now: Date = new Date();
    this.todayIndex = now.getDay() === 0 ? 6 : now.getDay() - 1;
  }

  private courseAt(day: number, section: number): CourseItem | null {
    for (const course of this.courseList) {
      if (course.dayOfWeek === day && section >= course.sectionStart && section <= course.sectionEnd) {
        return course;
      }
    }
    return null;
  }

  private colorFor(course: CourseItem): string {
    let index: number = 0;
    for (let i = 0; i < this.courseList.length; i++) {
      if (this.courseList[i].id === course.id) {
        index = i;
        break;
      }
    }
    return this.colorPool[index % this.colorPool.length];
  }

  build() {
    Column() {
      // 表头：周一~周日
      Row() {
        Text('节')
          .fontSize(11)
          .fontColor($r('app.color.sdmu_text_hint'))
          .width(24)
          .textAlign(TextAlign.Center)
        ForEach(this.dayNames, (name: string, index: number) => {
          Text('周' + name)
            .fontSize(12)
            .fontColor(index === this.todayIndex ? Color.White : $r('app.color.sdmu_text_secondary'))
            .backgroundColor(index === this.todayIndex ? $r('app.color.sdmu_primary') : Color.Transparent)
            .borderRadius(8)
            .layoutWeight(1)
            .padding({ top: 4, bottom: 4 })
            .textAlign(TextAlign.Center)
        }, (name: string) => 'day' + name)
      }
      .width('100%')
      .padding({ left: 4, right: 4, top: 6, bottom: 6 })
      .backgroundColor($r('app.color.sdmu_card_bg'))

      // 课程网格
      Scroll() {
        Column() {
          ForEach([1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12], (section: number) => {
            Row() {
              Text(section + '')
                .fontSize(11)
                .fontColor($r('app.color.sdmu_text_hint'))
                .width(24)
                .textAlign(TextAlign.Center)
              ForEach([0, 1, 2, 3, 4, 5, 6], (day: number) => {
                Column({ space: 2 }) {
                  Text(this.courseAt(day, section)?.name ?? '')
                    .fontSize(10)
                    .fontColor(Color.White)
                    .maxLines(2)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                  Text('@' + (this.courseAt(day, section)?.location ?? ''))
                    .fontSize(9)
                    .fontColor(Color.White)
                    .maxLines(1)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                }
                .layoutWeight(1)
                .height(56)
                .margin(1)
                .borderRadius(4)
                .backgroundColor(this.courseAt(day, section) !== null ?
                  this.colorFor(this.courseAt(day, section) ?? this.courseList[0]) : $r('app.color.sdmu_bg'))
                .justifyContent(FlexAlign.Center)
                .alignItems(HorizontalAlign.Center)
                .padding(2)
              }, (day: number) => 'cell' + day + '-' + section)
            }
            .width('100%')
          }, (section: number) => 'row' + section)
        }
        .width('100%')
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.sdmu_card_bg'))
  }
}
