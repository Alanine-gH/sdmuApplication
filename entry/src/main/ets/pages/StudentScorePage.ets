// 数据源：无服务器接口，页面数据为内置示例数据（离线演示用），未接 ApiService。
import { TitleBar } from '../components/TitleBar';

/**
 * 学生成绩查看页 — 1:1 复刻 mobile_campus_score_activity_student_score.xml +
 * common_expandlv_rl.xml + score_fragment_webview.xml（原生复刻成绩表）
 *
 * activity_student_score.xml：LinearLayout vertical + toolbar_normal +
 *   divider_horizontal_grey_normal + common_expandlv_rl（MultiStateView content +
 *   ExpandableListView：groupIndicator=null、divider=divider_grey 0.8dip）
 *
 * score_fragment_webview.xml 原为 WebView 成绩报表 → 原生复刻成绩表：
 *   表头行（课程/学分/总评成绩/绩点）+ 各课程成绩行，字号 12fp、
 *   mobile_campus_score_shape_table_bg：#FFFFFF 底 0.5dip divider_grey 描边
 */
class StudentCourseScore {
  courseName: string;
  credit: string;
  totalScore: string;
  gpa: string;

  constructor(courseName: string, credit: string, totalScore: string, gpa: string) {
    this.courseName = courseName;
    this.credit = credit;
    this.totalScore = totalScore;
    this.gpa = gpa;
  }
}

class StudentScoreTermGroup {
  termName: string;
  courses: StudentCourseScore[];

  constructor(termName: string, courses: StudentCourseScore[]) {
    this.termName = termName;
    this.courses = courses;
  }
}

function buildStudentScoreGroups(): StudentScoreTermGroup[] {
  const groups: StudentScoreTermGroup[] = [];
  groups.push(new StudentScoreTermGroup('2025-2026学年 第一学期', [
    new StudentCourseScore('高等数学（下）', '5.0', '88', '3.7'),
    new StudentCourseScore('大学英语（四）', '3.0', '92', '4.0'),
    new StudentCourseScore('数据结构与算法', '4.0', '85', '3.5'),
    new StudentCourseScore('操作系统原理', '3.5', '79', '3.0'),
    new StudentCourseScore('概率论与数理统计', '3.0', '81', '3.2')
  ]));
  groups.push(new StudentScoreTermGroup('2025-2026学年 第二学期', [
    new StudentCourseScore('计算机网络', '3.5', '90', '3.9'),
    new StudentCourseScore('数据库系统概论', '3.0', '86', '3.6'),
    new StudentCourseScore('软件工程导论', '2.5', '77', '2.8'),
    new StudentCourseScore('马克思主义基本原理', '3.0', '83', '3.3')
  ]));
  groups.push(new StudentScoreTermGroup('2024-2025学年 第二学期', [
    new StudentCourseScore('高等数学（上）', '5.0', '76', '2.6'),
    new StudentCourseScore('线性代数', '3.0', '84', '3.4'),
    new StudentCourseScore('大学物理', '4.0', '71', '2.1'),
    new StudentCourseScore('C语言程序设计', '3.5', '95', '4.3')
  ]));
  return groups;
}

@Component
struct StudentScoreTermRow {
  @Prop group: StudentScoreTermGroup = new StudentScoreTermGroup('', []);
  @State expanded: boolean = false;

  build() {
    Column() {
      // 分组头（ExpandableListView group 行）
      Row() {
        Text(this.group.termName)
          .fontSize(15)
          .fontColor($r('app.color.mobile_campus_score_common_color1'))
          .layoutWeight(1)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        Image(this.expanded ? $r('app.media.arrow_up') : $r('app.media.arrow_down'))
          .width(14)
          .height(14)
          .objectFit(ImageFit.Contain)
      }
      .width('100%')
      .height(48)
      .padding({ left: 12, right: 12 })
      .alignItems(VerticalAlign.Center)
      .onClick(() => {
        this.expanded = !this.expanded;
      })

      // 展开：原生复刻成绩表（score_fragment_webview）
      if (this.expanded) {
        Column() {
          // 表头行
          Row() {
            Text('课程').fontSize(12).fontColor($r('app.color.black')).textAlign(TextAlign.Center)
              .layoutWeight(6).height('100%')
              .backgroundColor('#FFFFFF')
              .border({ width: 0.5, color: $r('app.color.divider_grey') })
            Text('学分').fontSize(12).fontColor($r('app.color.black')).textAlign(TextAlign.Center)
              .layoutWeight(2).height('100%')
              .backgroundColor('#FFFFFF')
              .border({ width: 0.5, color: $r('app.color.divider_grey') })
            Text('总评成绩').fontSize(12).fontColor($r('app.color.black')).textAlign(TextAlign.Center)
              .layoutWeight(2).height('100%')
              .backgroundColor('#FFFFFF')
              .border({ width: 0.5, color: $r('app.color.divider_grey') })
            Text('绩点').fontSize(12).fontColor($r('app.color.black')).textAlign(TextAlign.Center)
              .layoutWeight(2).height('100%')
              .backgroundColor('#FFFFFF')
              .border({ width: 0.5, color: $r('app.color.divider_grey') })
          }
          .width('100%')
          .height(36)

          ForEach(this.group.courses, (course: StudentCourseScore, index: number) => {
            Row() {
              Text(course.courseName).fontSize(12).fontColor($r('app.color.black')).textAlign(TextAlign.Center)
                .layoutWeight(6).height('100%').padding({ left: 2, right: 2 })
                .backgroundColor('#FFFFFF')
                .border({ width: 0.5, color: $r('app.color.divider_grey') })
                .maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
              Text(course.credit).fontSize(12).fontColor($r('app.color.black')).textAlign(TextAlign.Center)
                .layoutWeight(2).height('100%')
                .backgroundColor('#FFFFFF')
                .border({ width: 0.5, color: $r('app.color.divider_grey') })
              Text(course.totalScore).fontSize(12).fontColor($r('app.color.black')).textAlign(TextAlign.Center)
                .layoutWeight(2).height('100%')
                .backgroundColor('#FFFFFF')
                .border({ width: 0.5, color: $r('app.color.divider_grey') })
              Text(course.gpa).fontSize(12).fontColor($r('app.color.black')).textAlign(TextAlign.Center)
                .layoutWeight(2).height('100%')
                .backgroundColor('#FFFFFF')
                .border({ width: 0.5, color: $r('app.color.divider_grey') })
            }
            .width('100%')
            .height(36)
          }, (course: StudentCourseScore, index: number) => this.group.termName + '_' + index + '_' + course.courseName)
        }
        .width('100%')
        .padding({ left: 12, right: 12, bottom: 8 })
      }

      // ExpandableListView divider：divider_grey 0.8dip
      Divider()
        .color($r('app.color.divider_grey'))
        .strokeWidth(0.8)
    }
    .width('100%')
  }
}

@Entry
@Component
struct StudentScorePage {
  @State groups: StudentScoreTermGroup[] = buildStudentScoreGroups();

  build() {
    Column() {
      TitleBar({ title: '学生成绩' })
      // divider_horizontal_grey_normal
      Divider()
        .color($r('app.color.common_color_5'))
        .strokeWidth(0.5)
        .width('100%')
      // common_expandlv_rl：ExpandableListView（白底列表）
      Scroll() {
        Column() {
          ForEach(this.groups, (group: StudentScoreTermGroup, index: number) => {
            StudentScoreTermRow({ group: group })
          }, (group: StudentScoreTermGroup) => group.termName)
        }
        .width('100%')
      }
      .width('100%')
      .layoutWeight(1)
      .backgroundColor($r('app.color.main_bg'))
      .align(Alignment.Top)
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.main_bg'))
  }
}
