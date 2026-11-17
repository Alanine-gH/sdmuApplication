import { router } from '@kit.ArkUI';

/**
 * 自定义课表页 — 1:1 复刻 activity_custom_timetable.xml
 * 结构：RelativeLayout白底 >
 *   - toolbar_normal
 *   - CustomTableSelector：学年第/学期/月三段选择条
 *   - 课表周条（common_color_5底）：「--月」月份块(TextSize3.Color7) +
 *     7列日期(90/2=45vp timetabledatetext) + 选中日ybg_blue下划线
 *   - divider 0.3dip #CECECE
 *   - 课表内容容器（课程网格）
 *   - CustomFloatButton（右下悬浮，默认gone）
 */
class CustomCourse {
  name: string;
  place: string;
  day: number;
  startNode: number;
  nodeCount: number;
  colorIdx: number;

  constructor(name: string, place: string, day: number, startNode: number, nodeCount: number, colorIdx: number) {
    this.name = name;
    this.place = place;
    this.day = day;
    this.startNode = startNode;
    this.nodeCount = nodeCount;
    this.colorIdx = colorIdx;
  }
}

@Entry
@Component
struct CustomTimetablePage {
  @State yearName: string = '2026-2027学年';
  @State termName: string = '第1学期';
  @State monthName: string = '11月';
  @State selectedDay: number = 0;
  private weekDays: string[] = ['一', '二', '三', '四', '五', '六', '日'];
  private dates: string[] = ['16', '17', '18', '19', '20', '21', '22'];
  private courseColors: string[] = ['#97000C', '#1B68B7', '#18B4ED', '#3267B1', '#52BEFF', '#FF9999', '#FF8900'];
  private courses: CustomCourse[] = [
    new CustomCourse('数据分析及可视化', '博学楼B202', 1, 2, 2, 0),
    new CustomCourse('软件建模与分析', '博学楼C304', 2, 0, 2, 1),
    new CustomCourse('Java程序设计', '实训楼402', 3, 4, 2, 2),
    new CustomCourse('操作系统原理', '明理楼B102', 4, 6, 2, 3),
    new CustomCourse('大学体育', '操场', 5, 2, 1, 5),
    new CustomCourse('大学英语', '文科楼A305', 5, 8, 2, 4)
  ];

  private colorOf(idx: number): string {
    return this.courseColors[idx % this.courseColors.length];
  }

  build() {
    Column() {
      // toolbar_normal
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
        Text('自定义课表')
          .fontSize(16)
          .fontColor($r('app.color.common_color_1'))
          .layoutWeight(1)
          .textAlign(TextAlign.Center)
          .maxLines(1)
        Blank()
          .width(40)
      }
      .width('100%')
      .height(44)
      .alignItems(VerticalAlign.Center)
      .backgroundColor($r('app.color.white'))

      Divider()
        .color($r('app.color.common_color_5'))
        .strokeWidth(0.5)
        .width('100%')

      // CustomTableSelector：学年第/学期/月 三段选择
      Row() {
        Text(this.yearName)
          .fontSize(14)
          .fontColor($r('app.color.common_color_1'))
          .height(40)
          .textAlign(TextAlign.Center)
          .layoutWeight(1.4)
          .onClick(() => {
            this.yearName = this.yearName === '2026-2027学年' ? '2025-2026学年' : '2026-2027学年';
          })
        Text(this.termName)
          .fontSize(14)
          .fontColor($r('app.color.common_color_1'))
          .height(40)
          .textAlign(TextAlign.Center)
          .layoutWeight(1)
          .onClick(() => {
            this.termName = this.termName === '第1学期' ? '第2学期' : '第1学期';
          })
        Text(this.monthName)
          .fontSize(14)
          .fontColor($r('app.color.common_color_1'))
          .height(40)
          .textAlign(TextAlign.Center)
          .layoutWeight(0.6)
          .onClick(() => {
            const m: number = Number(this.monthName.replace('月', ''));
            const next: number = m % 12 + 1;
            this.monthName = next.toString() + '月';
          })
      }
      .width('100%')
      .height(40)
      .backgroundColor($r('app.color.white'))

      // 课表周条（common_color_5底）：月份块 + 7列日期 + 蓝下划线
      Column() {
        Row() {
          Text(this.monthName.replace('月', '--月'))
            .fontSize(14)
            .fontColor($r('app.color.ybg_blue'))
            .width(44)
            .textAlign(TextAlign.Center)
            .height(45)
          Row() {
            ForEach(this.weekDays, (d: string, i: number) => {
              Column() {
                Text(this.dates[i])
                  .fontSize(12)
                  .fontColor(this.selectedDay === i ? $r('app.color.ybg_blue') : $r('app.color.common_color_3'))
                Text(d)
                  .fontSize(12)
                  .fontColor(this.selectedDay === i ? $r('app.color.ybg_blue') : $r('app.color.common_color_3'))
                  .margin({ top: 1 })
              }
              .layoutWeight(1)
              .onClick(() => {
                this.selectedDay = i;
              })
            }, (d: string) => 'wd_' + d)
          }
          .layoutWeight(1)
          .height(45)
          .alignItems(VerticalAlign.Center)
        }
        .width('100%')
        .height(45)

        // 下划线行（选中日ybg_blue）
        Row() {
          Row()
            .width('100%')
            .height(2)
            .backgroundColor($r('app.color.common_color_5'))
        }
        .width('100%')
        .height(2)
      }
      .width('100%')
      .backgroundColor($r('app.color.common_color_5'))

      // divider 0.3dip #CECECE
      Divider()
        .color($r('app.color.common_color_4'))
        .strokeWidth(0.3)
        .width('100%')

      // 课表内容：课程网格（左节次列+7列课程）
      Row() {
        // 左节次列
        Column() {
          ForEach([1, 2, 3, 4, 5, 6, 7, 8, 9, 10], (n: number) => {
            Column() {
              Text(n.toString())
                .fontSize(11)
                .fontColor($r('app.color.common_color_3'))
              Text(n.toString())
                .fontSize(9)
                .fontColor($r('app.color.common_color_4'))
                .margin({ top: 1 })
            }
            .width(24)
            .height(54)
            .justifyContent(FlexAlign.Center)
          }, (n: number) => 'node_' + n)
        }
        .width(24)
        .alignItems(HorizontalAlign.Center)

        // 7列课程
        Row() {
          ForEach(this.weekDays, (d: string, di: number) => {
            Column() {
              ForEach(this.courses, (c: CustomCourse) => {
                if (c.day === di) {
                  Column() {
                    Text(c.name)
                      .fontSize(11)
                      .fontColor(Color.White)
                      .maxLines(3)
                      .textOverflow({ overflow: TextOverflow.Ellipsis })
                    Text(c.place)
                      .fontSize(9)
                      .fontColor('#B2FFFFFF')
                      .margin({ top: 2 })
                      .maxLines(1)
                  }
                  .width('96%')
                  .height(c.nodeCount * 54 - 4)
                  .justifyContent(FlexAlign.Center)
                  .borderRadius(3)
                  .backgroundColor(this.colorOf(c.colorIdx))
                }
                if (c.day !== di && c.day < di && c.startNode <= 10) {
                  // 非当日课程留白由Blank填充
                }
              }, (c: CustomCourse) => 'ct_' + c.name)
            }
            .layoutWeight(1)
            .padding({ top: 2 })
            .alignItems(HorizontalAlign.Center)
          }, (d: string) => 'col_' + d)
        }
        .layoutWeight(1)
      }
      .width('100%')
      .layoutWeight(1)
      .backgroundColor($r('app.color.white'))
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.white'))
  }
}
