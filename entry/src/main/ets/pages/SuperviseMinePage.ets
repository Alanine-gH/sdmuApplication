import { router } from '@kit.ArkUI';
import { BusinessError } from '@kit.BasicServicesKit';
import { TitleBar } from '../components/TitleBar';
import { ApiService } from '../network/ApiService';
import { ApiResponse } from '../model/ResponseModel';
import { SuperviseRecordItem, SuperviseMineData } from '../model/SuperviseModel';

/**
 * 我的督导 — 1:1 复刻自：
 *   mobile_campus_supervise_activity_supervise_mine.xml（TabLayout 48vp + ViewPager）
 *   mobile_campus_supervise_view_mine.xml（未督导列表项）
 *   mobile_campus_supervise_view_mine_past.xml（已督导列表项，右侧"评课"按钮）
 *   mobile_campus_supervise_layout_evaluate_show.xml（教学评价展示面板）
 *   mobile_campus_supervise_activity_supervise_evaluate.xml（评课表单：应到/实到、星级、评语、提交）
 */

class LectureRecord {
  dateLabel: string;
  weekLabel: string;
  title: string;
  teacher: string;
  location: string;
  time: string;
  evaluated: boolean;
  attendanceExpect: string;
  attendanceActual: string;
  score: number;
  comment: string;

  constructor(dateLabel: string, weekLabel: string, title: string, teacher: string, location: string, time: string,
    evaluated: boolean, attendanceExpect: string, attendanceActual: string, score: number, comment: string) {
    this.dateLabel = dateLabel;
    this.weekLabel = weekLabel;
    this.title = title;
    this.teacher = teacher;
    this.location = location;
    this.time = time;
    this.evaluated = evaluated;
    this.attendanceExpect = attendanceExpect;
    this.attendanceActual = attendanceActual;
    this.score = score;
    this.comment = comment;
  }
}

@Entry
@Component
struct SuperviseMinePage {
  @State selectedTabIndex: number = 0;
  @State pastRecords: LectureRecord[] = [
    new LectureRecord('11-09', '周一', '高等数学（下）', '张建国', '明理楼B302', '08:30-10:00', true, '56', '54', 4,
      '教学目标明确，重点突出；板书规范，推导过程完整。课堂互动稍显不足，建议增加随堂提问环节。'),
    new LectureRecord('11-05', '周四', '数据结构', '李慧敏', '计算机楼A215', '14:00-15:40', true, '48', '47', 5,
      '案例驱动教学，思路清晰，代码演示到位，学生参与度高，整体效果优秀。'),
    new LectureRecord('11-02', '周一', '大学英语（四）', '王雪梅', '外语楼208', '10:00-11:40', true, '50', '46', 3,
      '语音语调标准，课堂氛围活跃；部分学生注意力不集中，建议加强课堂管理。')
  ];
  @State futureRecords: LectureRecord[] = [
    new LectureRecord('11-16', '周一', '大学物理（下）', '赵国强', '实验楼C105', '16:00-17:40', false, '', '', 0, ''),
    new LectureRecord('11-18', '周三', '线性代数', '陈立群', '明理楼B410', '08:00-09:40', false, '', '', 0, ''),
    new LectureRecord('11-20', '周五', '教育学原理', '孙美玲', '文科楼302', '14:00-15:40', false, '', '', 0, '')
  ];
  @State sheetVisible: boolean = false;
  @State sheetMode: string = 'show';
  @State sheetTitle: string = '';
  @State sheetTeacher: string = '';
  @State sheetExpect: string = '';
  @State sheetActual: string = '';
  @State sheetScore: number = 0;
  @State sheetComment: string = '';

  aboutToAppear(): void {
    ApiService.getSuperviseMine()
      .then((response: ApiResponse<SuperviseMineData>) => {
        if (response.code !== 0) {
          console.info('SuperviseMinePage degrade: code=' + response.code + ' msg=' + response.message);
        }
        const data: SuperviseMineData = response.data;
        if (data.pastRecords.length > 0) {
          this.pastRecords = data.pastRecords.map((entry: SuperviseRecordItem): LectureRecord => {
            return new LectureRecord(entry.dateLabel, entry.weekLabel, entry.title, entry.teacher, entry.location,
              entry.time, entry.evaluated, entry.attendanceExpect, entry.attendanceActual, entry.score,
              entry.comment);
          });
        }
        if (data.futureRecords.length > 0) {
          this.futureRecords = data.futureRecords.map((entry: SuperviseRecordItem): LectureRecord => {
            return new LectureRecord(entry.dateLabel, entry.weekLabel, entry.title, entry.teacher, entry.location,
              entry.time, entry.evaluated, entry.attendanceExpect, entry.attendanceActual, entry.score,
              entry.comment);
          });
        }
      })
      .catch((error: BusinessError) => {
        console.info('SuperviseMinePage load fail: ' + error.message);
      });
  }

  private openShowSheet(record: LectureRecord): void {
    this.sheetMode = 'show';
    this.sheetTitle = record.title;
    this.sheetTeacher = record.teacher;
    this.sheetExpect = record.attendanceExpect;
    this.sheetActual = record.attendanceActual;
    this.sheetScore = record.score;
    this.sheetComment = record.comment;
    this.sheetVisible = true;
  }

  private openEditSheet(record: LectureRecord): void {
    this.sheetMode = 'edit';
    this.sheetTitle = record.title;
    this.sheetTeacher = record.teacher;
    this.sheetExpect = record.attendanceExpect;
    this.sheetActual = record.attendanceActual;
    this.sheetScore = record.score;
    this.sheetComment = record.comment;
    this.sheetVisible = true;
  }

  private submitEvaluate(): void {
    this.sheetVisible = false;
  }

  // layout_evaluate_show.xml / activity_supervise_evaluate.xml
  @Builder
  superviseEvaluateSheetBuilder() {
    Column() {
      Text(this.sheetTitle)
        .fontSize(15)
        .fontColor($r('app.color.common_color_1'))
        .width('100%')
        .textAlign(TextAlign.Center)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .padding({ top: 12, bottom: 4 })
      Text(this.sheetTeacher)
        .fontSize(13)
        .fontColor($r('app.color.common_color_3'))
        .width('100%')
        .textAlign(TextAlign.Center)
        .padding({ bottom: 8 })

      Divider()
        .color($r('app.color.common_color_5'))
        .strokeWidth(0.5)
        .width('100%')

      // 应到人数 / 实到人数
      Row() {
        Column() {
          Text('应到人数')
            .fontSize(13)
            .fontColor($r('app.color.common_color_1'))
          Text(this.sheetExpect !== '' ? this.sheetExpect : '--')
            .fontSize(17)
            .fontColor($r('app.color.blue_default'))
            .margin({ top: 4 })
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)

        Column() {
          Text('实到人数')
            .fontSize(13)
            .fontColor($r('app.color.common_color_1'))
          Text(this.sheetActual !== '' ? this.sheetActual : '--')
            .fontSize(17)
            .fontColor($r('app.color.blue_default'))
            .margin({ top: 4 })
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)
      .margin({ top: 24, bottom: 21 })

      // 课程评价（评分星级）
      Text('课程评价')
        .fontSize(17)
        .fontColor($r('app.color.common_color_1'))
        .width('100%')
        .textAlign(TextAlign.Center)
        .margin({ top: 12 })

      Row() {
        ForEach([1, 2, 3, 4, 5], (starNum: number) => {
          Image(starNum <= this.sheetScore ?
            $r('app.media.mobile_campus_supervise_star_light') :
            $r('app.media.mobile_campus_supervise_star_grey'))
            .width(20)
            .height(20)
            .margin({ left: 4, right: 4 })
            .onClick(() => {
              if (this.sheetMode === 'edit') {
                this.sheetScore = starNum;
              }
            })
        }, (starNum: number) => starNum.toString())
      }
      .margin({ top: 21, bottom: 17 })
      .justifyContent(FlexAlign.Center)

      // 评课内容 / 展示评语
      Text(this.sheetComment !== '' ? this.sheetComment : (this.sheetMode === 'edit' ?
        '本次课程整体效果如何呢？' : '暂无评课内容'))
        .fontSize(13)
        .fontColor($r('app.color.common_color_1'))
        .width('100%')
        .textAlign(TextAlign.Start)
        .padding(7)
        .margin({ top: 15 })
        .minLines(5)
        .maxLines(8)
      Blank()
        .layoutWeight(1)

      // 提交评价（编辑模式）
      if (this.sheetMode === 'edit') {
        Text('提交评价')
          .fontSize(17)
          .fontColor(Color.White)
          .width('100%')
          .textAlign(TextAlign.Center)
          .padding({ top: 10, bottom: 10 })
          .backgroundColor('#1B68B7')
          .margin({ bottom: 12 })
          .onClick(() => {
            this.submitEvaluate();
          })
      }
    }
    .width('100%')
    .height('100%')
    .padding({ left: 12, right: 12 })
    .backgroundColor($r('app.color.white'))
  }

  build() {
    Column() {
      // toolbar_normal.xml
      TitleBar({ title: '我的督导', showBack: true })

      // TabLayout：48vp，指示条 2vp #1B68B7，选中 #1B68B7 / 未选中 #999999
      Column() {
        Row() {
          Column() {
            Text('已督导')
              .fontSize(15)
              .fontColor(this.selectedTabIndex === 0 ? '#1B68B7' : $r('app.color.common_color_3'))
              .layoutWeight(1)
              .textAlign(TextAlign.Center)
            Divider()
              .color(this.selectedTabIndex === 0 ? '#1B68B7' : Color.Transparent)
              .strokeWidth(2)
              .width('100%')
          }
          .layoutWeight(1)
          .height(46)
          .justifyContent(FlexAlign.Center)
          .onClick(() => {
            this.selectedTabIndex = 0;
          })

          Column() {
            Text('未督导')
              .fontSize(15)
              .fontColor(this.selectedTabIndex === 1 ? '#1B68B7' : $r('app.color.common_color_3'))
              .layoutWeight(1)
              .textAlign(TextAlign.Center)
            Divider()
              .color(this.selectedTabIndex === 1 ? '#1B68B7' : Color.Transparent)
              .strokeWidth(2)
              .width('100%')
          }
          .layoutWeight(1)
          .height(46)
          .justifyContent(FlexAlign.Center)
          .onClick(() => {
            this.selectedTabIndex = 1;
          })
        }
        .width('100%')
        .height(48)
        .alignItems(VerticalAlign.Center)
        .backgroundColor($r('app.color.white'))

        Divider()
          .color($r('app.color.common_color_5'))
          .strokeWidth(0.5)
          .width('100%')
      }
      .width('100%')
      .backgroundColor($r('app.color.white'))

      // ViewPager：已督导 / 未督导
      if (this.selectedTabIndex === 0) {
        List({ space: 0 }) {
          ForEach(this.pastRecords, (record: LectureRecord) => {
            ListItem() {
              Row() {
                Text(record.dateLabel + '\n' + record.weekLabel)
                  .fontSize(17)
                  .fontColor('#1B6BB7')
                  .width(106)
                  .padding({ left: 12 })
                  .textAlign(TextAlign.Start)
                  .lineHeight(24)
                Column() {
                  Row() {
                    Column() {
                      Text(record.title)
                        .fontSize(17)
                        .fontColor($r('app.color.common_color_1'))
                        .maxLines(1)
                        .textOverflow({ overflow: TextOverflow.Ellipsis })
                      Row() {
                        Image($r('app.media.mobile_campus_supervise_teacher'))
                          .width(12)
                          .height(12)
                          .margin({ right: 8 })
                        Text(record.teacher)
                          .fontSize(13)
                          .fontColor($r('app.color.common_color_3'))
                      }
                      .margin({ top: 15 })

                      Row() {
                        Image($r('app.media.mobile_campus_supervise_location'))
                          .width(12)
                          .height(12)
                          .margin({ right: 8 })
                        Text(record.location)
                          .fontSize(13)
                          .fontColor($r('app.color.common_color_3'))
                      }
                      .margin({ top: 8 })

                      Row() {
                        Image($r('app.media.mobile_campus_supervise_time'))
                          .width(16)
                          .height(16)
                          .margin({ right: 8 })
                        Text(record.time)
                          .fontSize(13)
                          .fontColor($r('app.color.common_color_3'))
                      }
                      .margin({ top: 8 })
                    }
                    .height(111)
                    .layoutWeight(1)
                    .alignItems(HorizontalAlign.Start)
                    .justifyContent(FlexAlign.Center)

                    Text(record.evaluated ? '查看' : '评课')
                      .fontSize(14)
                      .fontColor('#1B68B7')
                      .width(80)
                      .height(32)
                      .textAlign(TextAlign.Center)
                      .borderRadius(4)
                      .border({ width: 1, color: '#1B68B7' })
                      .margin({ right: 12 })
                      .onClick(() => {
                        if (record.evaluated) {
                          this.openShowSheet(record);
                        } else {
                          this.openEditSheet(record);
                        }
                      })
                  }
                  .alignItems(VerticalAlign.Center)
                  .height(112)

                  Divider()
                    .color($r('app.color.common_color_5'))
                    .strokeWidth(0.5)
                    .width('100%')
                }
                .layoutWeight(1)
                .height(112)
                .alignItems(HorizontalAlign.Start)
              }
              .width('100%')
              .height(112)
              .alignItems(VerticalAlign.Center)
              .backgroundColor($r('app.color.white'))
              .onClick(() => {
                this.openShowSheet(record);
              })
            }
          }, (record: LectureRecord) => record.dateLabel + record.title)
        }
        .width('100%')
        .layoutWeight(1)
        .backgroundColor($r('app.color.common_color_6'))
      } else {
        List({ space: 0 }) {
          ForEach(this.futureRecords, (record: LectureRecord) => {
            ListItem() {
              Row() {
                Text(record.dateLabel + '\n' + record.weekLabel)
                  .fontSize(17)
                  .fontColor('#1B6BB7')
                  .width(106)
                  .padding({ left: 12 })
                  .textAlign(TextAlign.Start)
                  .lineHeight(24)
                Column() {
                  Column() {
                    Text(record.title)
                      .fontSize(17)
                      .fontColor($r('app.color.common_color_1'))
                      .maxLines(1)
                      .textOverflow({ overflow: TextOverflow.Ellipsis })
                    Row() {
                      Image($r('app.media.mobile_campus_supervise_teacher'))
                        .width(12)
                        .height(12)
                        .margin({ right: 8 })
                      Text(record.teacher)
                        .fontSize(13)
                        .fontColor($r('app.color.common_color_3'))
                    }
                    .margin({ top: 15 })

                    Row() {
                      Image($r('app.media.mobile_campus_supervise_location'))
                        .width(12)
                        .height(12)
                        .margin({ right: 8 })
                      Text(record.location)
                        .fontSize(13)
                        .fontColor($r('app.color.common_color_3'))
                    }
                    .margin({ top: 8 })

                    Row() {
                      Image($r('app.media.mobile_campus_supervise_time'))
                        .width(16)
                        .height(16)
                        .margin({ right: 8 })
                      Text(record.time)
                        .fontSize(13)
                        .fontColor($r('app.color.common_color_3'))
                    }
                    .margin({ top: 8 })
                  }
                  .height(111)
                  .layoutWeight(1)
                  .alignItems(HorizontalAlign.Start)
                  .justifyContent(FlexAlign.Center)

                  Divider()
                    .color($r('app.color.common_color_5'))
                    .strokeWidth(0.5)
                    .width('100%')
                }
                .layoutWeight(1)
                .height(112)
                .alignItems(HorizontalAlign.Start)
              }
              .width('100%')
              .height(112)
              .padding({ top: 8, bottom: 8 })
              .alignItems(VerticalAlign.Center)
              .backgroundColor($r('app.color.white'))
              .onClick(() => {
                this.openEditSheet(record);
              })
            }
          }, (record: LectureRecord) => record.dateLabel + record.title)
        }
        .width('100%')
        .layoutWeight(1)
        .backgroundColor($r('app.color.common_color_6'))
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.common_color_6'))
    .bindSheet($$this.sheetVisible, this.superviseEvaluateSheetBuilder(), {
      height: 480,
      dragBar: true,
      showClose: true,
      backgroundColor: $r('app.color.white')
    } as SheetOptions)
  }
}
