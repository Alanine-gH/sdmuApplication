import { TitleBar } from '../components/TitleBar';

/**
 * 学业报告详情 — 复刻 student_report_layout_main.xml（studyReport/DetailActivity）
 * 原生为 WebView 壳，按 H5 报表结构原生复刻：
 *   学年学期选择 + 概况卡（加权平均分 / 平均绩点 / 班级排名）
 *   + 学期课程成绩列表（课程名 / 学分 / 成绩 / 绩点）
 */
interface StudyCourseRow {
  courseName: string;
  credit: string;
  score: number;
  gpa: string;
}

interface StudySummary {
  avgScore: string;
  avgGpa: string;
  classRank: string;
  totalStudents: string;
}

@Entry
@Component
struct StudyReportDetailPage {
  @State currentTerm: string = '2025-2026 第1学期';
  @State terms: string[] = ['2025-2026 第1学期', '2024-2025 第2学期', '2024-2025 第1学期'];
  @State summary: StudySummary = new StudySummaryItem('86.5', '3.42', '8', '42');
  @State courseRows: StudyCourseRow[] = [
    new StudyCourseRowItem('高等数学(下)', '5.0', 92, '4.5'),
    new StudyCourseRowItem('大学英语(四)', '3.0', 85, '3.7'),
    new StudyCourseRowItem('数据结构', '4.0', 88, '4.0'),
    new StudyCourseRowItem('Java程序设计', '4.5', 90, '4.2'),
    new StudyCourseRowItem('大学物理', '3.5', 79, '3.0'),
    new StudyCourseRowItem('体育(四)', '1.0', 86, '3.6')
  ] as StudyCourseRow[];

  build() {
    Column() {
      TitleBar({ title: '学业报告', showBack: true })

      Scroll() {
        Column() {
          // 学年学期选择
          Row() {
            ForEach(this.terms, (term: string) => {
              Text(term)
                .fontSize(13)
                .fontColor(term === this.currentTerm ?
                  $r('app.color.white') : $r('app.color.common_color_2'))
                .backgroundColor(term === this.currentTerm ?
                  $r('app.color.mobile_campus_primary_color') : $r('app.color.white'))
                .borderRadius(14)
                .padding({ left: 12, right: 12, top: 6, bottom: 6 })
                .maxLines(1)
                .onClick(() => {
                  this.currentTerm = term;
                })
            }, (term: string) => 'studycapsule' + term)
          }
          .width('100%')
          .padding({ left: 15, right: 15, top: 12, bottom: 12 })
          .alignItems(VerticalAlign.Center)

          // 概况卡
          Row() {
            this.summaryCell('加权平均分', this.summary.avgScore)
            this.summaryCell('平均绩点', this.summary.avgGpa)
            this.summaryCell('班级排名', this.summary.classRank + '/' + this.summary.totalStudents)
          }
          .width('100%')
          .padding({ top: 20, bottom: 20 })
          .backgroundColor($r('app.color.white'))
          .borderRadius(8)

          // 课程成绩列表头
          Row() {
            Text('课程')
              .fontSize(14)
              .fontColor($r('app.color.common_color_3'))
              .layoutWeight(4)
            Text('学分')
              .fontSize(14)
              .fontColor($r('app.color.common_color_3'))
              .layoutWeight(2)
              .textAlign(TextAlign.Center)
            Text('成绩')
              .fontSize(14)
              .fontColor($r('app.color.common_color_3'))
              .layoutWeight(2)
              .textAlign(TextAlign.Center)
            Text('绩点')
              .fontSize(14)
              .fontColor($r('app.color.common_color_3'))
              .layoutWeight(2)
              .textAlign(TextAlign.Center)
          }
          .width('100%')
          .height(40)
          .padding({ left: 15, right: 15 })
          .backgroundColor($r('app.color.white'))
          .alignItems(VerticalAlign.Center)

          Divider()
            .color($r('app.color.common_color_5'))
            .strokeWidth(0.5)
            .width('100%')

          // 课程成绩行
          Column() {
            ForEach(this.courseRows, (row: StudyCourseRow) => {
              Row() {
                Text(row.courseName)
                  .fontSize(14)
                  .fontColor($r('app.color.common_color_1'))
                  .layoutWeight(4)
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
                Text(row.credit)
                  .fontSize(14)
                  .fontColor($r('app.color.common_color_2'))
                  .layoutWeight(2)
                  .textAlign(TextAlign.Center)
                Text(row.score + '')
                  .fontSize(14)
                  .fontColor(row.score >= 80 ? $r('app.color.mobile_campus_schedule_color8') :
                    $r('app.color.ybg_orange'))
                  .layoutWeight(2)
                  .textAlign(TextAlign.Center)
                Text(row.gpa)
                  .fontSize(14)
                  .fontColor($r('app.color.common_color_2'))
                  .layoutWeight(2)
                  .textAlign(TextAlign.Center)
              }
              .width('100%')
              .height(48)
              .padding({ left: 15, right: 15 })
              .alignItems(VerticalAlign.Center)

              Divider()
                .color($r('app.color.common_color_5'))
                .strokeWidth(0.5)
                .width('100%')
            }, (row: StudyCourseRow) => 'studycourse' + row.courseName)
          }
          .width('100%')
          .backgroundColor($r('app.color.white'))
        }
        .width('100%')
      }
      .width('100%')
      .layoutWeight(1)
      .backgroundColor($r('app.color.common_color_6'))
      .scrollBar(BarState.Off)
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.common_color_6'))
  }

  @Builder
  summaryCell(labelText: string, valueText: string) {
    Column() {
      Text(valueText)
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.mobile_campus_primary_color'))
      Text(labelText)
        .fontSize(12)
        .fontColor($r('app.color.common_color_3'))
        .margin({ top: 6 })
    }
    .layoutWeight(1)
    .alignItems(HorizontalAlign.Center)
  }
}

class StudySummaryItem implements StudySummary {
  avgScore: string;
  avgGpa: string;
  classRank: string;
  totalStudents: string;

  constructor(avgScore: string, avgGpa: string, classRank: string, totalStudents: string) {
    this.avgScore = avgScore;
    this.avgGpa = avgGpa;
    this.classRank = classRank;
    this.totalStudents = totalStudents;
  }
}

class StudyCourseRowItem implements StudyCourseRow {
  courseName: string;
  credit: string;
  score: number;
  gpa: string;

  constructor(courseName: string, credit: string, score: number, gpa: string) {
    this.courseName = courseName;
    this.credit = credit;
    this.score = score;
    this.gpa = gpa;
  }
}

