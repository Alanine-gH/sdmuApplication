import { router } from '@kit.ArkUI';
import { BusinessError } from '@kit.BasicServicesKit';
import { TitleBar } from '../components/TitleBar';
import { EmptyView } from '../components/EmptyView';
import { LoadingView } from '../components/LoadingView';
import { ApiService } from '../network/ApiService';
import { ApiResponse } from '../model/ResponseModel';
import { ClassAndId, StudentEntity } from '../model/ScoreModel';

/**
 * 学生成绩单 — StudentListActivity + StudentListFragment + StudentAdapter 源码级翻译。
 *
 * 【入口】ScoreMainFragment"查看学生具体成绩"→ g2(/score/studentList) bundle{PARAMS}；
 *   PARAMS = ScoreMainActivity.a 拼接串（"xn_xq,xn_xq"，上学期+本学期）。
 * 【布局】mobile_campus_score_activity_student_list：toolbar_normal（T1"学生成绩单"）
 *   + student_list_search TextView 高 32vp 圆角灰底（hint"输入学生姓名信息搜索..."+search_b 图标）
 *     点击 → StudentSearchActivity{PARAMS}（HAP 未翻译，保留入口样式）
 *   + divider_horizontal_grey_normal + TabLayout（scrollable，tabPadding 5vp，indicator 高 0，
 *     item=mobile_campus_score_item_tab_view CheckedTextView 14fp 圆角 pill）
 *   + ViewPager（每班 StudentListFragment）。
 * 【数据】StudentSearchModel.T0：POST getClazz {params} → ClassAndId[]{clazz,code}
 *   （实测测试账号 0001 系统异常 → 真实错误态）；每班 W0 POST getStudents {bjid} → StudentEntity[]{xh,xm}
 *   （实测 code=0 空表）。
 * 【行】mobile_campus_score_item_student_list：姓名 16fp #333333 高 44vp padding 12vp + 右箭头
 *   + 底部 0.5vp common_color_6 分隔线；点击 → StudentScoreActivity {studentName,studentId}
 *   （HAP StudentScorePage）。
 */
@Entry
@Component
struct StudentListPage {
  @State classes: ClassAndId[] = [];
  @State activeIndex: number = 0;
  @State students: StudentEntity[] = [];
  @State isLoading: boolean = true;
  @State errorText: string = '';
  @State paramsValue: string = '';
  private loadedCodes: string[] = [];

  aboutToAppear(): void {
    const params: Record<string, Object> | undefined = router.getParams() as Record<string, Object> | undefined;
    if (params !== undefined && params !== null) {
      const value: Object = params['PARAMS'];
      if (typeof value === 'string') {
        this.paramsValue = value as string;
      }
    }
    this.loadClasses();
  }

  /** 源码 K2：StudentSearchPImpl.g(q) → StudentSearchModel.T0 POST getClazz {params} */
  private loadClasses(): void {
    this.isLoading = true;
    this.errorText = '';
    ApiService.getStudentClassList(this.paramsValue)
      .then((response: ApiResponse<ClassAndId[]>) => {
        if (response.code === 1000) {
          return;
        }
        if (response.code === 0) {
          this.classes = response.data;
          if (this.classes.length > 0) {
            this.selectTab(0);
          } else {
            this.isLoading = false;
          }
        } else {
          this.classes = [];
          this.errorText = response.message;
          this.isLoading = false;
        }
      })
      .catch((error: BusinessError) => {
        ApiService.logError('getClazz fail: ' + error.message);
        this.classes = [];
        this.errorText = '网络异常，请稍后重试';
        this.isLoading = false;
      });
  }

  private selectTab(index: number): void {
    if (index < 0 || index >= this.classes.length) {
      return;
    }
    this.activeIndex = index;
    const code: string = this.classes[index].code;
    if (this.loadedCodes.indexOf(code) >= 0) {
      return;
    }
    this.loadStudents(code);
  }

  /** 源码 StudentListFragment.N1：StudentSearchPImpl.o(...).k(bjid) → W0 getStudents */
  private loadStudents(bjid: string): void {
    this.isLoading = true;
    this.errorText = '';
    ApiService.getStudentsByClass(bjid)
      .then((response: ApiResponse<StudentEntity[]>) => {
        if (response.code === 1000) {
          return;
        }
        if (response.code === 0) {
          this.students = response.data;
          this.loadedCodes.push(bjid);
        } else {
          this.students = [];
          this.errorText = response.message;
        }
        this.isLoading = false;
      })
      .catch((error: BusinessError) => {
        ApiService.logError('getStudents fail: ' + error.message);
        this.students = [];
        this.errorText = '网络异常，请稍后重试';
        this.isLoading = false;
      });
  }

  private openStudent(item: StudentEntity): void {
    router.pushUrl({
      url: 'pages/StudentScorePage',
      params: { 'studentName': item.xm, 'studentId': item.xh } as Record<string, Object>
    });
  }

  build() {
    Column() {
      TitleBar({ title: '学生成绩单', showBack: true })
      Row() {
        Image($r('app.media.search_b'))
          .width(16)
          .height(16)
        Text('输入学生姓名信息搜索...')
          .fontSize(14)
          .fontColor('#B5B5B5')
          .margin({ left: 9 })
      }
      .width('auto')
      .height(32)
      .padding({ left: 8, right: 8 })
      .borderRadius(16)
      .backgroundColor('#F2F2F2')
      .margin({ left: 12, right: 12, top: 8, bottom: 8 })
      .onClick((): void => {
        this.getUIContext().getPromptAction().showToast({ message: '搜索页未在本批范围', duration: 1500 });
      })
      Divider().color($r('app.color.common_color_5')).strokeWidth(0.5).width('100%')
      if (this.classes.length > 0) {
        Scroll() {
          Row() {
            ForEach(this.classes, (item: ClassAndId, index: number) => {
              Text(item.clazz)
                .fontSize(14)
                .fontColor(this.activeIndex === index ? $r('app.color.white') : '#B2BDC9')
                .backgroundColor(this.activeIndex === index ? '#18B4ED' : '#F2F2F2')
                .borderRadius(14)
                .padding({ left: 12, right: 12, top: 6, bottom: 6 })
                .margin({ left: 5, right: 5, top: 8, bottom: 8 })
                .maxLines(1)
                .onClick((): void => { this.selectTab(index); })
            }, (item: ClassAndId) => item.code)
          }
        }
        .scrollable(ScrollDirection.Horizontal)
        .scrollBar(BarState.Off)
        .width('100%')
      }
      if (this.isLoading) {
        LoadingView()
      } else if (this.errorText !== '') {
        EmptyView({ tipText: this.errorText })
      } else if (this.students.length === 0) {
        EmptyView({ tipText: '暂无学生' })
      } else {
        List() {
          ForEach(this.students, (item: StudentEntity) => {
            ListItem() {
              Row() {
                Text(item.xm)
                  .fontSize(16)
                  .fontColor($r('app.color.common_color_1'))
                  .layoutWeight(1)
                Image($r('app.media.arrow_right2'))
                  .width(12)
                  .height(12)
              }
              .width('100%')
              .height(44)
              .padding({ left: 12, right: 12 })
              .backgroundColor($r('app.color.white'))
              .onClick((): void => { this.openStudent(item); })
            }
          }, (item: StudentEntity) => item.xh)
        }
        .layoutWeight(1)
        .width('100%')
        .divider({ strokeWidth: 0.5, color: $r('app.color.common_color_6'), startMargin: 12, endMargin: 0 })
        .scrollBar(BarState.Off)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.main_bg'))
  }
}
