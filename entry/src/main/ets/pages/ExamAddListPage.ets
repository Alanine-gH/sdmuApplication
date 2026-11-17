import { router } from '@kit.ArkUI';
import { TitleBar } from '../components/TitleBar';

/**
 * 考试分段页 — 1:1 复刻 exam_activity_addexamlist.xml
 * 结构：
 *   - toolbar_normal
 *   - RadioGroup 45dip 白底：「期末考试」/「等级考试」两个RadioButton（12fp small_text_size，
 *     选中色 textcolor_blue_selector=ybg_blue #18B4ED，layout_weight=1 居中）
 *   - blueline：2dip 白底横线，选中侧显示85dip蓝色（#18B4ED）指示条
 *   - 15dip 灰隔条（common_color_6）
 *   - ViewPager：两段考试列表（examination_comingfragment 结构：MultiStateView+下拉刷新列表）
 * 添加考试入口（examination_my_addexamination「添加考试」）在toolbar右侧。
 */
class ExamEntry {
  subject: string;
  time: string;
  place: string;
  type: string;
  status: string;

  constructor(subject: string, time: string, place: string, type: string, status: string) {
    this.subject = subject;
    this.time = time;
    this.place = place;
    this.type = type;
    this.status = status;
  }
}

@Entry
@Component
struct ExamAddListPage {
  @State segIndex: number = 0;
  @State finalExams: ExamEntry[] = [
    new ExamEntry('数据结构', '2026-12-28 09:00-11:00', '博学楼A201', '期末考试', '待考'),
    new ExamEntry('软件建模与分析', '2026-12-30 14:00-16:00', '博学楼C304', '期末考试', '待考'),
    new ExamEntry('操作系统原理', '2027-01-03 09:00-11:00', '明理楼B102', '期末考试', '待考')
  ];
  @State levelExams: ExamEntry[] = [
    new ExamEntry('大学英语六级', '2026-12-13 09:00-11:25', '明理楼A区', '等级考试', '已考'),
    new ExamEntry('全国计算机二级', '2026-09-26 09:00-11:00', '实训楼机房', '等级考试', '已考'),
    new ExamEntry('普通话水平测试', '2026-11-08 14:00起', '文科楼三层', '等级考试', '已考')
  ];

  @Builder
  examRow(item: ExamEntry) {
    Column() {
      Row() {
        Text(item.subject)
          .fontSize(16)
          .fontColor($r('app.color.common_color_1'))
          .layoutWeight(1)
        Text(item.status)
          .fontSize(13)
          .fontColor(item.status === '待考' ? $r('app.color.ybg_blue') : $r('app.color.common_color_3'))
      }
      .width('100%')

      Text(item.time)
        .fontSize(13)
        .fontColor($r('app.color.common_color_3'))
        .margin({ top: 6 })

      Text(item.place)
        .fontSize(13)
        .fontColor($r('app.color.common_color_3'))
        .margin({ top: 4 })
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
    .padding({ left: 15, right: 15, top: 12, bottom: 12 })
    .backgroundColor($r('app.color.white'))
  }

  build() {
    Column() {
      // toolbar_normal：45dip白底，右侧「添加考试」入口
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
        Text('考试安排')
          .fontSize(16)
          .fontColor($r('app.color.common_color_1'))
          .layoutWeight(1)
          .textAlign(TextAlign.Center)
          .maxLines(1)
        Text('添加考试')
          .fontSize(13)
          .fontColor($r('app.color.ybg_blue'))
          .margin({ right: 15 })
          .onClick(() => {
            router.pushUrl({ url: 'pages/HandleExamCoursePage' });
          })
      }
      .width('100%')
      .height(44)
      .alignItems(VerticalAlign.Center)
      .backgroundColor($r('app.color.main_bg'))

      Divider()
        .color($r('app.color.common_color_5'))
        .strokeWidth(0.5)
        .width('100%')

      // RadioGroup：45dip 白底，两段RadioButton（12fp，选中#18B4ED）
      Row() {
        Text('期末考试')
          .fontSize(12)
          .fontColor(this.segIndex === 0 ? $r('app.color.ybg_blue') : $r('app.color.common_color_3'))
          .height(45)
          .textAlign(TextAlign.Center)
          .layoutWeight(1)
          .onClick(() => {
            this.segIndex = 0;
          })
        Text('等级考试')
          .fontSize(12)
          .fontColor(this.segIndex === 1 ? $r('app.color.ybg_blue') : $r('app.color.common_color_3'))
          .height(45)
          .textAlign(TextAlign.Center)
          .layoutWeight(1)
          .onClick(() => {
            this.segIndex = 1;
          })
      }
      .width('100%')
      .height(45)
      .backgroundColor($r('app.color.white'))

      // blueline：2dip白线+选中侧85dip蓝条
      Row() {
        Row()
          .width(85)
          .height(2)
          .backgroundColor(this.segIndex === 0 ? $r('app.color.ybg_blue') : Color.Transparent)
          .layoutWeight(1)
        Row()
          .width(85)
          .height(2)
          .backgroundColor(this.segIndex === 1 ? $r('app.color.ybg_blue') : Color.Transparent)
          .layoutWeight(1)
      }
      .width('100%')
      .height(2)
      .backgroundColor($r('app.color.white'))

      // 15dip 灰隔条（common_color_6 px_to_dip_30/2）
      Row()
        .width('100%')
        .height(15)
        .backgroundColor($r('app.color.common_color_6'))

      // ViewPager：考试列表（SwipeMenuListView条目）
      List() {
        ForEach(this.segIndex === 0 ? this.finalExams : this.levelExams, (item: ExamEntry) => {
          ListItem() {
            this.examRow(item)
          }
        }, (item: ExamEntry) => item.subject)
      }
      .width('100%')
      .layoutWeight(1)
      .divider({
        strokeWidth: 0.8,
        color: $r('app.color.common_color_5'),
        startMargin: 15,
        endMargin: 15
      })
      .backgroundColor($r('app.color.white'))
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.common_color_6'))
  }
}
