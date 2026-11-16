import { ApiService } from '../network/ApiService';
import { ExamItem } from '../model/ScoreModel';
import { TitleBar } from '../components/TitleBar';
import { EmptyView } from '../components/EmptyView';
import { LoadingView } from '../components/LoadingView';

/**
 * 考试安排页 — 1:1 复刻 examination_list_item.xml + examination_tag.xml
 *
 * examination_list_item.xml（白底条目）：
 *   padding L px_to_dip_24=12vp R 12vp T px_to_dip_30=15vp B px_to_dip_24=12vp
 *   - flowlayout_coursename：课程名(MediumText.Black=16fp #000000) + 考试标签(examination_tag)
 *   - 时间行 marginTop 12vp：examination_time 图标 15vp + 时间(MediumText.Grey=16fp #747474)
 *     marginLeft 8vp weight=1 + "剩余 N 天"（剩余/天 16fp #747474，N 蓝色加粗）
 *   - 地点行 marginTop 6vp：examination_place 图标 15vp + 地点(SmallText.Grey=14fp #747474)
 *   - 座位/方式行 marginTop 6vp：examination_table 图标 + 14fp #747474
 *   - 学期行 marginTop 6vp：examination_term 图标 + 14fp #747474
 *
 * examination_tag.xml：px_to_sp_20=10fp 白字、蓝底圆角(round_shape_normal_round_coner_blue_bg,
 *   corners coner_radius_normal=6dip=3vp)、padding L6 R6 T3 B3(vp)、marginTop 1vp
 *
 * 注：mobile_campus_view_exam_item.xml（#F5F7FA 圆角条目）为首页"移动校园"考试模块卡片布局，
 * 不属于本页（考试列表页）结构，故未在此使用。
 */
@Entry
@Component
struct ExamPage {
  @State examList: ExamItem[] = [];
  @State isLoading: boolean = true;

  aboutToAppear(): void {
    ApiService.getExamList()
      .then((response) => {
        this.examList = response.data;
        this.isLoading = false;
      })
      .catch(() => {
        this.examList = [];
        this.isLoading = false;
      });
  }

  private remainingDays(time: string): number {
    // time 形如 "2026-12-20 09:00-11:00"，取日期部分计算距今天数
    const parts: string[] = time.split(' ');
    if (parts.length < 1) {
      return -1;
    }
    const dateParts: string[] = parts[0].split('-');
    if (dateParts.length < 3) {
      return -1;
    }
    const examDate: Date = new Date(Number(dateParts[0]), Number(dateParts[1]) - 1, Number(dateParts[2]));
    if (isNaN(examDate.getTime())) {
      return -1;
    }
    const now: Date = new Date();
    const todayStart: Date = new Date(now.getFullYear(), now.getMonth(), now.getDate());
    return Math.ceil((examDate.getTime() - todayStart.getTime()) / (24 * 3600 * 1000));
  }

  private termLabel(time: string): string {
    const dateParts: string[] = time.split(' ')[0].split('-');
    if (dateParts.length < 3) {
      return '';
    }
    const year: number = Number(dateParts[0]);
    const month: number = Number(dateParts[1]);
    if (isNaN(year) || isNaN(month)) {
      return '';
    }
    // 8月及以后为新学年第一学期
    if (month >= 8) {
      return year + '-' + (year + 1) + '学年 第1学期';
    }
    if (month <= 1) {
      return (year - 1) + '-' + year + '学年 第1学期';
    }
    return (year - 1) + '-' + year + '学年 第2学期';
  }

  build() {
    Column() {
      // include toolbar_normal
      TitleBar({ title: '考试安排', showBack: true })
      if (this.isLoading) {
        LoadingView()
      } else {
        if (this.examList.length === 0) {
          EmptyView()
        } else {
          Scroll() {
            Column() {
              ForEach(this.examList, (item: ExamItem, index: number) => {
                // examination_list_item.xml：白底考试条目
                Column() {
                  // flowlayout_coursename：课程名 + 考试标签（流式布局）
                  Flex({ wrap: FlexWrap.Wrap, alignItems: ItemAlign.Center }) {
                    // tv_course_examination_list：MediumText.Black 16fp #000000
                    Text(item.courseName)
                      .fontSize(16)
                      .fontColor($r('app.color.black'))
                      .maxLines(2)
                      .textOverflow({ overflow: TextOverflow.Ellipsis })
                    // examination_tag.xml：教务提供标签 10fp 白字蓝底圆角 3vp
                    Text($r('app.string.examination_my_exam_tag'))
                      .fontSize(10)
                      .fontColor($r('app.color.white'))
                      .backgroundColor($r('app.color.ybg_blue'))
                      .borderRadius(3)
                      .padding({ left: 6, right: 6, top: 3, bottom: 3 })
                      .margin({ left: 3, top: 1 })
                      .maxLines(1)
                  }
                  .width('100%')
                  // 时间行：examination_time 图标 15vp + 时间 + 剩余天数
                  Row() {
                    Image($r('app.media.examination_time'))
                      .width(15)
                      .height(15)
                    // tv_time_examination_list：MediumText.Grey 16fp #747474
                    Text(item.time)
                      .fontSize(16)
                      .fontColor($r('app.color.ybg_grey'))
                      .margin({ left: 8 })
                      .layoutWeight(1)
                      .maxLines(1)
                      .textOverflow({ overflow: TextOverflow.Ellipsis })
                    // examination_list_whole_rest_day_layout：剩余 N 天
                    if (this.remainingDays(item.time) > 0) {
                      // tv_shengyustr："剩余" 16fp #747474
                      Text($r('app.string.remain'))
                        .fontSize(16)
                        .fontColor($r('app.color.ybg_grey'))
                        .margin({ right: 1 })
                      // 距考天数（蓝色加粗）
                      Text(this.remainingDays(item.time) + '')
                        .fontSize(16)
                        .fontColor($r('app.color.blue_default'))
                        .fontWeight(FontWeight.Bold)
                      // tv_tianstr："天" 16fp #747474
                      Text($r('app.string.day'))
                        .fontSize(16)
                        .fontColor($r('app.color.ybg_grey'))
                        .margin({ left: 1 })
                    }
                  }
                  .width('100%')
                  .margin({ top: 12 })
                  .alignItems(VerticalAlign.Center)
                  // 地点行：examination_place 图标 + 考场
                  Row() {
                    Image($r('app.media.examination_place'))
                      .width(15)
                      .height(15)
                    // tv_place_examination_list：SmallText.Grey 14fp #747474
                    Text(item.location)
                      .fontSize(14)
                      .fontColor($r('app.color.ybg_grey'))
                      .margin({ left: 8 })
                      .layoutWeight(1)
                      .maxLines(1)
                      .textOverflow({ overflow: TextOverflow.Ellipsis })
                  }
                  .width('100%')
                  .margin({ top: 6 })
                  .alignItems(VerticalAlign.Center)
                  // 方式行：examination_table 图标 + 考试方式
                  Row() {
                    Image($r('app.media.examination_table'))
                      .width(15)
                      .height(15)
                    // tvTable：SmallText.Grey 14fp #747474
                    Text(item.type)
                      .fontSize(14)
                      .fontColor($r('app.color.ybg_grey'))
                      .margin({ left: 8 })
                      .layoutWeight(1)
                      .maxLines(1)
                      .textOverflow({ overflow: TextOverflow.Ellipsis })
                  }
                  .width('100%')
                  .margin({ top: 6 })
                  .alignItems(VerticalAlign.Center)
                  // 学期行：examination_term 图标 + 学期
                  Row() {
                    Image($r('app.media.examination_term'))
                      .width(15)
                      .height(15)
                    // tv_term_examination_list：SmallText.Grey 14fp #747474
                    Text(this.termLabel(item.time))
                      .fontSize(14)
                      .fontColor($r('app.color.ybg_grey'))
                      .margin({ left: 8 })
                      .layoutWeight(1)
                      .maxLines(1)
                      .textOverflow({ overflow: TextOverflow.Ellipsis })
                  }
                  .width('100%')
                  .margin({ top: 6 })
                  .alignItems(VerticalAlign.Center)
                }
                .width('100%')
                .padding({ left: 12, right: 12, top: 15, bottom: 12 })
                .backgroundColor($r('app.color.white'))
                .alignItems(HorizontalAlign.Start)
                // 条目间分隔线
                if (index < this.examList.length - 1) {
                  Divider()
                    .color($r('app.color.common_color_5'))
                    .strokeWidth(0.5)
                    .width('100%')
                }
              }, (item: ExamItem) => 'exam' + item.id)
            }
            .width('100%')
          }
          .width('100%')
          .layoutWeight(1)
          .backgroundColor($r('app.color.white'))
          .scrollBar(BarState.Off)
        }
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.white'))
  }
}
