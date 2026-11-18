import { router } from '@kit.ArkUI';
import { TitleBar } from '../components/TitleBar';
import { EmptyView } from '../components/EmptyView';
import { LoadingView } from '../components/LoadingView';
import { ApiService } from '../network/ApiService';
import { ApiResponse } from '../model/ResponseModel';
import { LoginSession } from '../network/LoginSession';
import { StudentScoreGroup, StudentScoreChild } from '../model/ScoreModel';
import { BusinessError } from '@kit.BasicServicesKit';

/**
 * 学生成绩单页 — 1:1 翻译原 APK StudentScoreActivity.java（score/view）+ ScoreAdapter（score/adapter/a.java）。
 *
 * 【源码结构】J1 = mobile_campus_score_activity_student_score：
 *   toolbar_normal（标题 String.format("%s成绩单", studentName)）+ divider + ExpandableListView。
 * 【入口链】y(Intent)：studentName/studentId ← StudentSearchActivity.Q2（score/studentList 路由，
 *   ScoreMainActivity 点击"查看学生具体成绩"→ Q0=StudentSearchActivity PARAMS=xn_xq → 点学生 → 本页）。
 *   HAP 搜索页未翻译（映射表 todo），本页 studentName/studentId 缺省时回退登录会话本人学号/姓名
 *   （真实存在值；实测 getStudentMsg 对测试学号 code=0001 → 真实空态，不编造数据）。
 * 【数据】K2() → StudentSearchModel.V0（score/c/b.java）：GET api/avgCheck/getStudentMsg {xh}
 *   → StudentMessage[{xn,xq,data:[{kcmc,xscj,bjpm}]}]；空 → MultiStateView 空态（q2）。
 * 【组行】mobile_campus_score_item_score_parent：96dip 高 padding 24/24、
 *   xn+"学年"（32sp mobile_campus_score_common_color1=#3267b1）+ "第"+xq+"学期"（marginLeft24 weight1）
 *   + 箭头（展开 arrow_down / 收起 arrow_up）。
 * 【子行】mobile_campus_score_item_score_child：padding 50/24/24/24、28sp、
 *   kcmc（common_color_1 weight6）+ xscj（common_color_2 weight4 居中，ScoreAdapter.c()：
 *   含数字 → xscj+"分"，否则原样——如"优"/"良"/"及格"）+ "排名"+bjpm（common_color_2）。
 */
@Entry
@Component
struct StudentScorePage {
  @State studentName: string = '';
  @State studentId: string = '';
  @State groupList: StudentScoreGroup[] = [];
  @State expandedFlags: boolean[] = [];
  @State isLoading: boolean = true;

  aboutToAppear(): void {
    // 源码 y(Intent)：studentName/studentId；HAP 无搜索页 → 缺省回退登录会话本人（真实学号）
    const params: Record<string, Object> | undefined =
      router.getParams() as Record<string, Object> | undefined;
    if (params) {
      const name: Object = params['studentName'];
      const id: Object = params['studentId'];
      if (typeof name === 'string' && name !== '') {
        this.studentName = name;
      }
      if (typeof id === 'string' && id !== '') {
        this.studentId = id;
      }
    }
    if (this.studentId === '') {
      this.studentId = LoginSession.userId;
    }
    if (this.studentName === '') {
      this.studentName = LoginSession.sessionName;
    }
    this.loadScoreMsg();
  }

  /** 源码 K2()：b.n(new a(StudentMessage.class)).j(studentId) → GET getStudentMsg {xh} */
  private loadScoreMsg(): void {
    ApiService.getStudentScoreMsg(this.studentId)
      .then((response: ApiResponse<StudentScoreGroup[]>) => {
        this.groupList = response.data;
        this.expandedFlags = this.groupList.map((): boolean => false);
        this.isLoading = false;
      })
      .catch((error: BusinessError) => {
        ApiService.logError('StudentScore getStudentMsg fail: ' + error.message);
        this.groupList = [];
        this.isLoading = false;
      });
  }

  /** 源码 ScoreAdapter.c()：正则 .*\d+.* 含数字 → "N分"，否则成绩原样（优/良/中等文字成绩） */
  private scoreText(xscj: string): string {
    if (/[0-9]/.test(xscj)) {
      return xscj + '分';
    }
    return xscj;
  }

  @Builder
  groupRow(index: number) {
    Row() {
      Text(this.groupList[index].xn + '学年')
        .fontSize(16)
        .fontColor($r('app.color.mobile_campus_score_common_color1'))
      Text('第' + this.groupList[index].xq + '学期')
        .fontSize(16)
        .fontColor($r('app.color.mobile_campus_score_common_color1'))
        .margin({ left: 12 })
        .layoutWeight(1)
      Image(this.expandedFlags[index] ? $r('app.media.arrow_down') : $r('app.media.arrow_up'))
        .width(16)
        .height(16)
    }
    .width('100%')
    .height(48)
    .padding({ left: 12, right: 12 })
    .alignItems(VerticalAlign.Center)
    .backgroundColor($r('app.color.white'))
    .onClick(() => {
      // ExpandableListView 组点击展开/收起
      const flags: boolean[] = this.expandedFlags.slice();
      flags[index] = !flags[index];
      this.expandedFlags = flags;
    })
  }

  @Builder
  childRow(groupIndex: number, childIndex: number) {
    Row() {
      Text(this.groupList[groupIndex].children[childIndex].kcmc)
        .fontSize(14)
        .fontColor($r('app.color.common_color_1'))
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .layoutWeight(6)
      Text(this.scoreText(this.groupList[groupIndex].children[childIndex].xscj))
        .fontSize(14)
        .fontColor($r('app.color.common_color_2'))
        .maxLines(1)
        .textAlign(TextAlign.Center)
        .layoutWeight(4)
      Text('排名' + this.groupList[groupIndex].children[childIndex].bjpm)
        .fontSize(14)
        .fontColor($r('app.color.common_color_2'))
        .maxLines(1)
    }
    .width('100%')
    .padding({ left: 25, right: 12, top: 12, bottom: 12 })
    .backgroundColor($r('app.color.white'))
  }

  build() {
    Column() {
      // 源码 T1：String.format("%s成绩单", studentName)
      TitleBar({ title: this.studentName + '成绩单', showBack: true })
      if (this.isLoading) {
        LoadingView()
      } else if (this.groupList.length === 0) {
        // 源码 a.g：arrayList 空 → q2(MultiStateView 空态)；实测测试学号 0001 → 真实空态
        EmptyView({ tipText: '暂无成绩数据' })
      } else {
        List() {
          ForEach(this.groupList, (group: StudentScoreGroup, groupIndex: number) => {
            ListItem() {
              Column() {
                this.groupRow(groupIndex)
                if (this.expandedFlags[groupIndex]) {
                  ForEach(group.children, (child: StudentScoreChild, childIndex: number) => {
                    this.childRow(groupIndex, childIndex)
                  }, (child: StudentScoreChild, cIdx: number) => groupIndex + '-' + child.kcmc + '-' + cIdx)
                }
              }
              .width('100%')
            }
          }, (group: StudentScoreGroup) => group.xn + '-' + group.xq)
        }
        .width('100%')
        .layoutWeight(1)
        .scrollBar(BarState.Off)
        .backgroundColor($r('app.color.main_bg'))
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.main_bg'))
  }
}
