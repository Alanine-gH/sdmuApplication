import { router } from '@kit.ArkUI';
import { BusinessError } from '@kit.BasicServicesKit';
import { TitleBar } from '../components/TitleBar';
import { EmptyView } from '../components/EmptyView';
import { LoadingView } from '../components/LoadingView';
import { ApiService } from '../network/ApiService';
import { ApiResponse } from '../model/ResponseModel';
import { ComingExamEntity } from '../model/ScoreModel';

/**
 * 考试添加/调整 — AddExamListActivity + AddExamListFragment + AddExamListAdapter 源码级翻译。
 *
 * 【入口】ExamListActivity.T1 右键 nav_plus_btn → AddExamListActivity（HAP ExamPage 同路由）。
 * 【布局】exam_activity_addexamlist：toolbar_normal（标题"考试信息"）+ RadioGroup 高 45vp
 *   （"期末考试"/"等级考试"，textcolor_blue_selector）+ examination_view_blueline + 15vp 灰条
 *   + ViewPager（每 tab = AddExamListFragment）。
 * 【列表】common_refresh_lv_rl_exam：ListView + footerView examinationaddexam_list_itemfooter
 *   （"自定义添加" examnation_addcustomexam 图标）；行 examinationaddexam_list_item：
 *   KMMC 16fp + 时间行；LX=="3" → 课程名 #333333、"待添加" #18B4ED+右箭头；其他 → 灰字
 *   common_color_4、时间 "yyyy/MM/dd(周X) HH:mm"、"已添加"。
 * 【数据】AddExamListFragmentModel.p0 → GET editExamList{kslx:"0"/"1"} → AddExamEntity[]
 *   （2026-11-18 实测 kslx=0 真实 6 行软工综合设计等）。
 * 【点击】LX=="3" 行 → HandleExamCourseActivity edit；footer"自定义添加" → HandleExamCourseActivity
 *   custom add（handleExamData=当前列表+类型）。
 */
@Entry
@Component
struct ExamAddListPage {
  @State activeTab: number = 0;
  @State list: ComingExamEntity[] = [];
  @State isLoading: boolean = true;
  @State errorText: string = '';
  private loaded: boolean[] = [false, false];

  aboutToAppear(): void {
    this.loadList('0');
  }

  /** 源码 P1：AddExamListFragmentPresenter.b(f.getAddExamTypeType(), multiStateView) */
  private loadList(kslx: string): void {
    this.isLoading = true;
    this.errorText = '';
    ApiService.getAddExamList(kslx)
      .then((response: ApiResponse<ComingExamEntity[]>) => {
        if (response.code === 1000) {
          return;
        }
        if (response.code === 0) {
          this.list = response.data;
          this.loaded[this.activeTab] = true;
        } else {
          this.list = [];
          this.errorText = response.message;
        }
        this.isLoading = false;
      })
      .catch((error: BusinessError) => {
        ApiService.logError('editExamList fail: ' + error.message);
        this.list = [];
        this.errorText = '网络异常，请稍后重试';
        this.isLoading = false;
      });
  }

  private switchTab(index: number): void {
    if (this.activeTab === index) {
      return;
    }
    this.activeTab = index;
    this.loadList(index === 0 ? '0' : '1');
  }

  /** 源码 AddExamListFragment.b：footer 自定义添加 → HandleExamCourseActivity(custom add) */
  private openCustomAdd(): void {
    const data: Object[] = this.list.map((item: ComingExamEntity): Object => {
      const rec: Record<string, Object> = {
        'KMMC': item.KMMC, 'KSSJ': item.KSSJ, 'KSLX': item.KSLX, 'LX': item.LX, 'ZWH': item.ZWH
      };
      return rec as Object;
    });
    router.pushUrl({
      url: 'pages/HandleExamCoursePage',
      params: {
        'handleExamType': 'add',
        'handleExamTitle': this.activeTab === 0 ? '期末考试' : '等级考试',
        'handleExamData': data
      } as Record<string, Object>
    });
  }

  /** 源码 AddExamListFragment.a：LX=="3" 行 → edit */
  private openEdit(item: ComingExamEntity): void {
    if (item.LX !== '3') {
      return;
    }
    router.pushUrl({
      url: 'pages/HandleExamCoursePage',
      params: {
        'handleExamType': 'edit',
        'handleExamTitle': this.activeTab === 0 ? '期末考试' : '等级考试',
        'examCourseInfo': {
          'KMMC': item.KMMC, 'KSSJ': item.KSSJ, 'KSLX': item.KSLX, 'LX': item.LX, 'ZWH': item.ZWH
        } as Record<string, Object>
      } as Record<string, Object>
    });
  }

  private formatTime(text: string): string {
    if (text === '') {
      return '';
    }
    const t: string = text.replace(/\//g, '-');
    const m: RegExpMatchArray | null = t.match(/^(\d{4})-(\d{2})-(\d{2})[ T](\d{2}):(\d{2})/);
    if (m === null) {
      return text;
    }
    const d: Date = new Date(Number(m[1]), Number(m[2]) - 1, Number(m[3]), Number(m[4]), Number(m[5]));
    const weeks: string[] = ['日', '一', '二', '三', '四', '五', '六'];
    return d.getFullYear() + '/' + m[2] + '/' + m[3] + '(周' + weeks[d.getDay()] + ') ' + m[4] + ':' + m[5];
  }

  @Builder
  row(item: ComingExamEntity) {
    Row() {
      Column() {
        Text(item.KMMC)
          .fontSize(16)
          .fontColor(item.LX === '3' ? '#333333' : '#CECECE')
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        if (item.LX !== '3') {
          Row() {
            Image($r('app.media.examination_time')).width(15).height(15)
            Text(this.formatTime(item.KSSJ))
              .fontSize(16)
              .fontColor('#CECECE')
              .margin({ left: 8 })
              .layoutWeight(1)
          }
          .width('100%')
          .margin({ top: 8 })
          .alignItems(VerticalAlign.Center)
        }
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
      Text(item.LX === '3' ? '待添加' : '已添加')
        .fontSize(16)
        .fontColor(item.LX === '3' ? '#18B4ED' : '#CECECE')
        .margin({ left: 15, right: item.LX === '3' ? 15 : 40 })
      if (item.LX === '3') {
        Image($r('app.media.arrow_right_blue_desk_widget')).width(8).height(8).margin({ left: 5 })
      }
    }
    .width('100%')
    .padding({ left: 12, right: 12, top: 15, bottom: 12 })
    .backgroundColor($r('app.color.white'))
    .alignItems(VerticalAlign.Center)
    .onClick((): void => { this.openEdit(item); })
  }

  build() {
    Column() {
      TitleBar({ title: '考试信息', showBack: true })
      Row() {
        ForEach(['期末考试', '等级考试'], (label: string, index: number) => {
          Column() {
            Text(label)
              .fontSize(14)
              .fontColor(this.activeTab === index ? '#18B4ED' : '#747474')
              .height(43)
              .textAlign(TextAlign.Center)
              .width('100%')
            Divider()
              .color(this.activeTab === index ? '#18B4ED' : Color.Transparent)
              .strokeWidth(2)
              .width(85)
          }
          .layoutWeight(1)
          .height(45)
          .onClick((): void => { this.switchTab(index); })
        }, (label: string) => label)
      }
      .width('100%')
      .height(45)
      .backgroundColor($r('app.color.white'))
      Divider().color('#F2F2F2').strokeWidth(15).width('100%')
      if (this.isLoading) {
        LoadingView()
      } else if (this.errorText !== '') {
        EmptyView({ tipText: this.errorText })
      } else if (this.list.length === 0) {
        EmptyView({ tipText: '暂无考试' })
      } else {
        List() {
          ForEach(this.list, (item: ComingExamEntity) => {
            ListItem() {
              this.row(item)
            }
          }, (item: ComingExamEntity) => item.KMMC + item.KSLX)
        }
        .layoutWeight(1)
        .width('100%')
        .divider({ strokeWidth: 0.5, color: '#E7E7E7', startMargin: 12, endMargin: 12 })
        .scrollBar(BarState.Off)
      }
      Row() {
        Image($r('app.media.examnation_addcustomexam')).width(16).height(16)
        Text('自定义添加')
          .fontSize(16)
          .fontColor('#747474')
          .margin({ left: 8 })
      }
      .width('100%')
      .height(48)
      .padding({ left: 12 })
      .backgroundColor($r('app.color.white'))
      .onClick((): void => { this.openCustomAdd(); })
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.white'))
  }
}
