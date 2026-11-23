import { router } from '@kit.ArkUI';
import { BusinessError } from '@kit.BasicServicesKit';
import { ApiService } from '../network/ApiService';
import { ApiResponse } from '../model/ResponseModel';
import { SuperviseCourseDetail } from '../model/SuperviseModel';
import { TitleBar } from '../components/TitleBar';
import { EmptyView } from '../components/EmptyView';
import { LoadingView } from '../components/LoadingView';

/**
 * 新增督导/课程详情页 — 源码级翻译 [P-C placeholder]（SuperviseLectureAddActivity.java 逐行 → ArkTS）：
 *
 * 【考证】manifest L402 SuperviseLectureAddActivity；入口 SupervisePage:342"新增督导"按钮
 *   → H0 /supervise/add。标题源码 T1=gVar.n("课程详情")（非入口按钮文案"新增督导"）。
 * 【布局】mobile_campus_supervise_activity_supervise_add.xml：
 *   toolbar_normal + LectureDetailView(supervise_add_detail) + LectureNotifyView(supervise_add_notify，
 *   marginL/R=24px→12vp、marginTop=64px→32vp、app:buttonType="add"→0→"添加听课"分支)。
 * 【LectureDetailView】mobile_campus_supervise_layout_lecture_detail.xml（白底 padH12 padV20）：
 *   课程名 KCMC 16sp #1B68B7 mb22；任课教师=SKLSXM / 工号=GH / 开课院系=SKBJ /
 *   开课周数=QSJSZ+"周" / 上课节数="周"+XQJ+" 第"+DJJ+"节次" / 上课地点=SKDD；
 *   TextStyle1 标签 14sp #999999(maxLength4)、TextStyle2 值 14sp #333333；
 *   分割线 mt/mb17vp；听课时间行 XML gone 且本页不调 setSuperviseData → 保真不渲染。
 * 【LectureNotifyView】mobile_campus_supervise_layout_lecture_notify.xml（CardView 白卡圆角）：
 *   听课时间行 h48vp（图标+"听课时间"标签 marginR21vp + 时间文本 hint"请选择听课时间" + 右箭头）
 *   → SuperviseDateDialog 滚轮（数据源=DetailsCourse.itemList，visibleItems7）；
 *   日程提醒行（"不提醒"checked / "指定时间提醒"）→ ChooseTimeDialog 三滚轮 → setText+setTag；
 *   提交钮"添加听课"白字蓝底，XML enabled=false，notifyType==0 时按听课时间非空启用。
 * 【数据】W0 detailsCourse{xlh} → DetailsCourse（b.g 回调填 7 字段 + itemList）；
 *   提交 Q2 → T0 addListenCourse{courseId=p.XLH, listenTime, remind, remindtime}；
 *   a.g：data=="true"→toast"添加成功" 否则 toast(message)，均 finish。
 * 【探针】probe_p_c_placeholder.py：detailsCourse 假 xlh code=0001、addListenCourse 假参 code=0001
 *   （端点存活，业务校验在服务端）；测试账号无真实课程 → 真实空态，不展示任何编造课程/日期。
 */

const WEEK_CN: string[] = ['日', '一', '二', '三', '四', '五', '六'];

/** 源码 ChooseTimeDialog 三滚轮：日标签（MM-dd 周X，从今天起 30 天） */
function makeDayLabels(): string[] {
  const labels: string[] = [];
  const base: Date = new Date();
  for (let i = 0; i < 30; i++) {
    const d: Date = new Date(base.getFullYear(), base.getMonth(), base.getDate() + i);
    const mm: string = (d.getMonth() + 1).toString().padStart(2, '0');
    const dd: string = d.getDate().toString().padStart(2, '0');
    labels.push(mm + '-' + dd + ' 周' + WEEK_CN[d.getDay()]);
  }
  return labels;
}

function makeHourLabels(): string[] {
  const labels: string[] = [];
  for (let i = 0; i < 24; i++) { labels.push(i.toString().padStart(2, '0') + '时'); }
  return labels;
}

function makeMinuteLabels(): string[] {
  const labels: string[] = [];
  for (let i = 0; i < 60; i++) { labels.push(i.toString().padStart(2, '0') + '分'); }
  return labels;
}

@Entry
@Component
struct SuperviseAddPage {
  private readonly dayLabels: string[] = makeDayLabels();
  private readonly hourLabels: string[] = makeHourLabels();
  private readonly minuteLabels: string[] = makeMinuteLabels();

  @State detail: SuperviseCourseDetail | null = null;
  @State isLoading: boolean = true;
  @State showError: boolean = false;
  @State xlh: string = '';
  /** 源码 LectureNotifyView.supervise_attendance_time / notifyType */
  @State attendanceTime: string = '';
  @State notifyType: number = 0;
  /** 源码 supervise_notify_specific_time text + tag（tag=提交的 remindtime） */
  @State specificTime: string = '';
  @State submitEnabled: boolean = false;
  @State dateWheelVisible: boolean = false;
  @State dateIndex: number = 0;
  @State timeWheelVisible: boolean = false;
  @State pickDay: number = 0;
  @State pickHour: number = 8;
  @State pickMinute: number = 0;

  aboutToAppear(): void {
    const params: object | undefined = router.getParams() as object | undefined;
    if (params !== undefined && params !== null) {
      const rec: Record<string, Object> = params as Record<string, Object>;
      const v: Object = rec['xlh'];
      if (typeof v === 'string') { this.xlh = v as string; }
    }
    this.loadDetail();
  }

  /** 源码 f1()→R2()：n.t(b).l(xlh) → W0 detailsCourse */
  private loadDetail(): void {
    this.isLoading = true;
    this.showError = false;
    ApiService.getSuperviseCourseDetail(this.xlh)
      .then((response: ApiResponse<SuperviseCourseDetail>) => {
        this.isLoading = false;
        if (response.code !== 0 || response.data.KCMC === '') {
          this.showError = true;
          return;
        }
        this.detail = response.data;
      })
      .catch((error: BusinessError) => {
        this.isLoading = false;
        this.showError = true;
        ApiService.logError('SuperviseAddPage detail fail: ' + error.message);
      });
  }

  /** 源码 LectureNotifyView.setSubmitButtonEnable：notifyType0 看 attendance；notifyType1 两者都要 */
  private refreshSubmit(): void {
    if (this.notifyType === 0) {
      this.submitEnabled = this.attendanceTime !== '';
    } else {
      this.submitEnabled = this.attendanceTime !== '' && this.specificTime !== '';
    }
  }

  /** 源码 c.onClick → Q2：courseId=p.XLH、remind=notifyType、remindtime=getSpecificTime() */
  private submit(): void {
    if (this.detail === null || !this.submitEnabled) { return; }
    const courseId: string = this.detail.XLH;
    const remindtime: string = this.notifyType === 1 ? this.specificTime : '';
    ApiService.addSuperviseListen(courseId, this.attendanceTime.trim(),
      String(this.notifyType), remindtime)
      .then((response: ApiResponse<string>) => {
        if (response.code === 0 && response.data === 'true') {
          this.getUIContext().getPromptAction().showToast({ message: '添加成功' });
          router.back();
        } else {
          this.getUIContext().getPromptAction().showToast({
            message: response.message === '' ? '添加失败' : response.message
          });
          if (response.code === 0) { router.back(); }
        }
      })
      .catch((error: BusinessError) => {
        ApiService.logError('SuperviseAddPage submit fail: ' + error.message);
        this.getUIContext().getPromptAction().showToast({ message: '添加失败' });
      });
  }

  /** 源码 f.a(str)：SuperviseDateDialog 完成 → 时间文本 setText（itemList 选项） */
  private onDatePicked(): void {
    if (this.detail === null || this.detail.itemList.length === 0) { return; }
    const idx: number = this.dateIndex < this.detail.itemList.length ? this.dateIndex : 0;
    this.attendanceTime = this.detail.itemList[idx];
    this.dateWheelVisible = false;
    this.refreshSubmit();
  }

  /** 源码 g.a(str,str2)：ChooseTimeDialog 完成 → setText(str2)+setTag(str2)，str2="yyyy-MM-dd HH:mm" */
  private onTimePicked(): void {
    const base: Date = new Date();
    const d: Date = new Date(base.getFullYear(), base.getMonth(), base.getDate() + this.pickDay,
      this.pickHour, this.pickMinute);
    const yyyy: string = d.getFullYear().toString();
    const mm: string = (d.getMonth() + 1).toString().padStart(2, '0');
    const dd: string = d.getDate().toString().padStart(2, '0');
    const hh: string = d.getHours().toString().padStart(2, '0');
    const mi: string = d.getMinutes().toString().padStart(2, '0');
    this.specificTime = yyyy + '-' + mm + '-' + dd + ' ' + hh + ':' + mi;
    this.timeWheelVisible = false;
    this.refreshSubmit();
  }

  /** 源码 LectureDetailView.setLectureData 七字段（本页不显示听课时间行） */
  @Builder
  detailCard(d: SuperviseCourseDetail) {
    Column() {
      Text(d.KCMC)
        .fontSize(16).fontColor('#1B68B7').margin({ bottom: 22 }).maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
      // 源码 lecture_detail.xml 首行：任课教师/工号同一水平行各 weight=1
      Row() {
        Row() {
          Text('任课教师')
            .fontSize(14).fontColor($r('app.color.common_color_3'))
            .maxLines(1).margin({ right: 12 })
          Text(d.SKLSXM)
            .fontSize(14).fontColor($r('app.color.common_color_1'))
            .layoutWeight(1).maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
        }
        .layoutWeight(1).alignItems(VerticalAlign.Center)

        Row() {
          Text('工号')
            .fontSize(14).fontColor($r('app.color.common_color_3'))
            .maxLines(1).margin({ right: 12 })
          Text(d.GH)
            .fontSize(14).fontColor($r('app.color.common_color_1'))
            .layoutWeight(1).maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
        }
        .layoutWeight(1).alignItems(VerticalAlign.Center)
      }
      .width('100%')

      this.detailRow('开课院系', d.SKBJ, 12)
      Divider().color($r('app.color.common_color_5')).strokeWidth(0.5).margin({ top: 17, bottom: 17 })
      this.detailRow('开课周数', d.QSJSZ + '周')
      this.detailRow('上课节数', '周' + d.XQJ + ' 第' + d.DJJ + '节次', 12)
      this.detailRow('上课地点', d.SKDD, 12)
    }
    .width('100%')
    .padding({ left: 12, right: 12, top: 20, bottom: 20 })
    .backgroundColor($r('app.color.white'))
  }

  @Builder
  detailRow(label: string, value: string, top: number = 0) {
    Row() {
      Text(label)
        .fontSize(14).fontColor($r('app.color.common_color_3'))
        .maxLines(1).margin({ right: 12 })
      Text(value)
        .fontSize(14).fontColor($r('app.color.common_color_1'))
        .layoutWeight(1).maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
    }
    .width('100%')
    .margin({ top: top })
    .alignItems(VerticalAlign.Center)
  }

  /** 源码 LectureNotifyView：听课时间行 + 日程提醒单选项 + 添加听课按钮 */
  @Builder
  notifyCard() {
    Column() {
      Row() {
        Image($r('app.media.mobile_campus_supervise_time')).width(16).height(16).margin({ right: 8 })
        Text('听课时间').fontSize(14).fontColor($r('app.color.common_color_1')).margin({ right: 21 })
        Text(this.attendanceTime === '' ? '请选择听课时间' : this.attendanceTime)
          .fontSize(14).fontColor($r('app.color.common_color_1')).layoutWeight(1)
        Image($r('app.media.mobile_campus_supervise_arrow')).width(14).height(14)
      }
      .width('100%').height(48).alignItems(VerticalAlign.Center)
      .onClick(() => {
        if (this.detail !== null && this.detail.itemList.length > 0) { this.dateWheelVisible = true; }
      })

      Divider().color($r('app.color.common_color_5')).strokeWidth(0.5)

      Row() {
        Image($r('app.media.mobile_campus_supervise_notice')).width(16).height(16).margin({ right: 8 })
        Text('日程提醒').fontSize(14).fontColor($r('app.color.common_color_1')).margin({ right: 21 })
        Column() {
          this.radioRow('不提醒', 0)
          this.radioRow('指定时间提醒', 1)
          if (this.notifyType === 1) {
            Row() {
              Text(this.specificTime === '' ? '请选择提醒时间' : this.specificTime)
                .fontSize(14).fontColor($r('app.color.common_color_1')).margin({ left: 8 })
            }
            .width('100%').onClick(() => { this.timeWheelVisible = true; })
          }
        }
        .layoutWeight(1)
      }
      .width('100%').alignItems(VerticalAlign.Top).padding({ top: 12 })

      Column() {
        Text('添加听课')
          .fontSize(14).fontColor($r('app.color.white')).textAlign(TextAlign.Center)
          .width('100%').padding({ top: 10, bottom: 10 })
          .borderRadius(4)
          .backgroundColor(this.submitEnabled ? $r('app.color.mobile_campus_primary_color_default') :
            $r('app.color.common_color_24'))
          .onClick(() => { this.submit(); })
      }
      .width('100%')
      .padding({ left: 9, right: 9, top: 30 })
    }
    .width('100%')
    .padding({ left: 12, right: 12, bottom: 18 })
    .backgroundColor($r('app.color.white'))
    .borderRadius(4)
  }

  @Builder
  radioRow(text: string, type: number) {
    Row() {
      Image(this.notifyType === type ? $r('app.media.mobile_campus_supervise_choosed') :
        $r('app.media.mobile_campus_supervise_choose'))
        .width(16).height(16).margin({ right: 8 })
      Text(text).fontSize(14).fontColor($r('app.color.common_color_1'))
    }
    .width('100%').height(32).alignItems(VerticalAlign.Center)
    .onClick(() => {
      this.notifyType = type;
      this.refreshSubmit();
    })
  }

  /** 源码 SuperviseDateDialog：WheelView visibleItems7 + tvFinish"完成"（itemList 选项） */
  @Builder
  dateWheelBuilder() {
    Column() {
      Row() {
        Blank()
        Text('完成').fontSize(15).fontColor($r('app.color.common_color_1'))
          .padding(10).onClick(() => { this.onDatePicked(); })
      }
      .width('100%')
      if (this.detail !== null && this.detail.itemList.length > 0) {
        TextPicker({ range: this.detail.itemList, selected: this.dateIndex })
          .width('100%').layoutWeight(1).canLoop(false)
          .onChange((value: string | string[], index: number | number[]) => {
            this.dateIndex = Array.isArray(index) ? Number((index as number[])[0]) : Number(index);
          })
      } else {
        Text('暂无可选听课时间').fontSize(15).fontColor($r('app.color.common_color_3')).layoutWeight(1)
      }
    }
    .width('100%').height('100%')
  }

  /** 源码 ChooseTimeDialog：day/hour/minute 三滚轮 + tv_setexamtimetitle + 确定 */
  @Builder
  timeWheelBuilder() {
    Column() {
      Text(this.specificTime === '' ? 'yyyy-MM-dd HH:mm' : this.specificTime)
        .fontSize(17).fontColor($r('app.color.common_color_1')).height(44)
        .textAlign(TextAlign.Center).width('100%')
      Row() {
        TextPicker({ range: this.dayLabels, selected: this.pickDay }).layoutWeight(3)
          .onChange((value: string | string[], index: number | number[]) => {
            this.pickDay = Array.isArray(index) ? Number((index as number[])[0]) : Number(index);
          })
        TextPicker({ range: this.hourLabels, selected: this.pickHour }).layoutWeight(1)
          .onChange((value: string | string[], index: number | number[]) => {
            this.pickHour = Array.isArray(index) ? Number((index as number[])[0]) : Number(index);
          })
        TextPicker({ range: this.minuteLabels, selected: this.pickMinute }).layoutWeight(1)
          .onChange((value: string | string[], index: number | number[]) => {
            this.pickMinute = Array.isArray(index) ? Number((index as number[])[0]) : Number(index);
          })
      }
      .width('100%').height(200)
      Text('确定').fontSize(17).fontColor($r('app.color.white')).textAlign(TextAlign.Center)
        .width('80%').height(44).borderRadius(4)
        .backgroundColor($r('app.color.mobile_campus_primary_color_default'))
        .margin({ top: 12, bottom: 16 }).onClick(() => { this.onTimePicked(); })
    }
    .width('100%')
  }

  build() {
    Column() {
      // T1：课程详情（源码 gVar.n，非入口按钮文案"新增督导"）
      TitleBar({ title: '课程详情', showBack: true })

      if (this.isLoading) {
        LoadingView()
      } else if (this.showError || this.detail === null) {
        EmptyView({ tipText: '暂无课程详情' })
      } else {
        Scroll() {
          Column() {
            this.detailCard(this.detail as SuperviseCourseDetail)
            Column() { this.notifyCard() }
              .width('100%').padding({ left: 12, right: 12, top: 32 })
          }
          .width('100%')
        }
        .scrollBar(BarState.Off)
        .layoutWeight(1)
      }
    }
    .width('100%').height('100%')
    .backgroundColor($r('app.color.common_color_6'))
    .bindSheet($$this.dateWheelVisible, this.dateWheelBuilder(), {
      height: 280, dragBar: false, showClose: false, backgroundColor: $r('app.color.ybg_white')
    } as SheetOptions)
    .bindSheet($$this.timeWheelVisible, this.timeWheelBuilder(), {
      height: 380, dragBar: false, showClose: false, backgroundColor: $r('app.color.ybg_white')
    } as SheetOptions)
  }
}
