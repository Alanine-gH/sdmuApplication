import { router } from '@kit.ArkUI';
import { TitleBar } from '../components/TitleBar';
import { ApiService } from '../network/ApiService';
import { ApiResponse } from '../model/ResponseModel';
import { BusinessError } from '@kit.BasicServicesKit';

/**
 * 考试科目处理页 — 1:1 翻译原 APK HandleExamCourseActivity.java（examination/view）
 * + examination_handleexamcourse.xml + ChooseTimeDialog（work/multimodule/weiget/c.java，MMDDWheelAdapter）。
 *
 * 【入口链】ExamPage/AddExamListActivity：Intent{handleExamData:List, handleExamType:HandleExamCourseType,
 *   examCourseInfo:ExamCourseInfo}。HandleExamCourseType 枚举四态：
 *   CUSTOM_ADD_TERMEND(add,期末考试)/CUSTOM_ADD_LEVEL(add,等级考试)/EDIT_TERMEND/EDIT_LEVEL。
 *   HAP 上游 ExamPage（todo）无调用 → 路由参数缺省 CUSTOM_ADD_TERMEND_EXAM_TYPE（源码主入口语义）。
 * 【UI 保真】examination_handleexamcourse.xml 可见性实证：
 *   科目/考试时间/考试地点/座位号行恒显；准考证号行 XML gone → 仅"等级考试"标题时 X2 显示；
 *   提醒时间行 XML gone 且代码无显示操作 → 不渲染；注意事项行 gone → edit+ComingExam+TGRXH空 显示；
 *   "同考试人"区 gone + i0 空实现 → 永不渲染。文案 1:1：考试科目/请输入考试科目、
 *   点击选择时间、请输入考试地点、请输入座位号、准考证号/输入准考证号（选填）、
 *   此考试已刷新，请确定是否需要更改详细信息。
 * 【时间弹窗】ChooseTimeDialog：三滚轮（日期列今天起 MMDDWheelAdapter"今天/MM-dd 周X"、
 *   时"0..23时"循环、分"0..59分"循环），标题实时"yyyy-MM-dd 周X HH:mm"（u()），确定回调
 *   a(str显示,str2提交) → q.setText/q.setTag；非 add 模式直接 enabled，add 按科目联动。
 * 【校验 c3】科目空→"请输入考试科目"；科目 enabled 且>30字→"科目名称不能超过30个字"；
 *   时间空→"请输入开始时间"；b.onClick 前置重复→"已存在相同的考试科目"（B=handleExamData）。
 * 【提交】HandleExamCourseModel.u：POST api/exam/operatorExam {zwh,zkzh,txlx,kssj,kslx,ksdd,kmmc,jssj}
 *   （txlx=A.indexOf(提醒文本)，A=["无","提前1小时","提前2小时","提前1天","提前3天"]；
 *   kslx="期末考试"?"0":"1"；kssj 用 tag 原始值）。成功 h1() → setResult(dataischange)+finish
 *   （无 toast）；失败 m(msg) toast。（2026-11-18 实测空 kmmc 0001——必填语义。）
 */
@Entry
@Component
struct HandleExamCoursePage {
  @State pageTitle: string = '期末考试';
  @State rightBtnText: string = '添加';
  @State btnEnabled: boolean = false;
  @State subject: string = '';
  @State subjectEnabled: boolean = true;
  /** 源码 XML edit_course_tv_time 默认 text=examination_my_examtimehint"点击选择时间" */
  @State examTimeText: string = '点击选择时间';
  @State examTimeTag: string = '';
  @State place: string = '';
  @State seatNo: string = '';
  @State examNo: string = '';
  @State alarmTimeText: string = '提前1小时';
  @State showExamNoRow: boolean = false;
  @State showAttentionRow: boolean = false;
  @State showTimeDialog: boolean = false;
  // 时间弹窗三滚轮（ChooseTimeDialog 等价）
  @State dayLabels: string[] = [];
  @State hourLabels: string[] = [];
  @State minuteLabels: string[] = [];
  @State pickDay: number = 0;
  @State pickHour: number = 0;
  @State pickMinute: number = 0;
  /** 源码 l=HandleExamCourseType{type,title}；m=ExamCourseInfo；B=handleExamData */
  private handleExamType: string = 'add';
  private handleExamTitle: string = '期末考试';
  private examCourseInfo: Record<string, Object> | null = null;
  private existingSubjects: string[] = [];
  /** 源码 A=C.d()：提醒时间五档（index 即 txlx） */
  private readonly alarmTimeList: string[] = ['无', '提前1小时', '提前2小时', '提前1天', '提前3天'];

  aboutToAppear(): void {
    this.readRouteParams();
    // 源码 Y2：A = C.d() 五档
    this.buildTimeWheelLabels();
    this.applyTypeDefaults();
    this.prefillWhenEdit();
  }

  /** 源码 y(Intent)：handleExamData/handleExamType/examCourseInfo → HAP 路由参数 */
  private readRouteParams(): void {
    const params: Record<string, Object> | undefined =
      router.getParams() as Record<string, Object> | undefined;
    if (!params) {
      return;
    }
    const type: Object = params['handleExamType'];
    const title: Object = params['handleExamTitle'];
    const info: Object = params['examCourseInfo'];
    if (typeof type === 'string' && type !== '') {
      this.handleExamType = type;
    }
    if (typeof title === 'string' && title !== '') {
      this.handleExamTitle = title;
    }
    if (info !== null && info !== undefined && typeof info === 'object') {
      this.examCourseInfo = info as Record<string, Object>;
    }
    const dataArr: Object = params['handleExamData'];
    if (Array.isArray(dataArr)) {
      for (const one of dataArr as Object[]) {
        const rec: Record<string, Object> = one as Record<string, Object>;
        const kmmc: Object = rec['KMMC'];
        if (typeof kmmc === 'string' && kmmc !== '') {
          this.existingSubjects.push(kmmc);
        }
      }
    }
  }

  /** ChooseTimeDialog 构造：日期列今天起（MMDDWheelAdapter 第0项"今天"），时/分循环 */
  private buildTimeWheelLabels(): void {
    const days: string[] = [];
    const weekChars: string[] = ['日', '一', '二', '三', '四', '五', '六'];
    const now: Date = new Date();
    for (let i = 0; i < 730; i++) {
      const d: Date = new Date(now.getFullYear(), now.getMonth(), now.getDate() + i);
      if (i === 0) {
        days.push('今天');
        continue;
      }
      const mm: string = (d.getMonth() + 1) < 10 ? '0' + (d.getMonth() + 1) : '' + (d.getMonth() + 1);
      const dd: string = d.getDate() < 10 ? '0' + d.getDate() : '' + d.getDate();
      days.push(mm + '-' + dd + ' 周' + weekChars[d.getDay()]);
    }
    this.dayLabels = days;
    const hours: string[] = [];
    const minutes: string[] = [];
    for (let h = 0; h < 24; h++) {
      hours.push(h + '时');
    }
    for (let m = 0; m < 60; m++) {
      minutes.push(m + '分');
    }
    this.hourLabels = hours;
    this.minuteLabels = minutes;
  }

  /** 源码 applyTypeDefaults：add2/save 按钮文案 + 等级考试考号行 + 初始 enabled 状态 */
  private applyTypeDefaults(): void {
    this.rightBtnText = this.handleExamType === 'add' ? '添加' : '保存';
    // 源码 X2："等级考试".equals(title) → 考号行显示
    this.showExamNoRow = this.handleExamTitle === '等级考试';
    this.btnEnabled = false;
    if (this.handleExamType === 'edit') {
      // 源码 T1：edit+ComingExamEntity → enabled，edit+AddExamEntity → disabled
      this.btnEnabled = this.examCourseInfo !== null && this.examCourseInfo['KSDD'] !== undefined;
    }
  }

  /** 源码 X2：edit 模式预填（AddExamEntity{KMMC} / ComingExamEntity 全字段） */
  private prefillWhenEdit(): void {
    if (this.handleExamType !== 'edit' || this.examCourseInfo === null) {
      return;
    }
    const info: Record<string, Object> = this.examCourseInfo;
    this.subject = this.strOf(info['KMMC']);
    this.subjectEnabled = false;
    const ksdd: string = this.strOf(info['KSDD']);
    if (ksdd !== '') {
      // ComingExamEntity 分支：时间/地点/座位/考号/提醒全预填
      const kssj: string = this.strOf(info['KSSJ']);
      this.examTimeText = this.formatExamTime(kssj);
      this.examTimeTag = kssj;
      this.place = ksdd;
      this.seatNo = this.strOf(info['ZWH']);
      this.examNo = this.strOf(info['ZKZH']);
      const txlx: string = this.strOf(info['TXLX']);
      const idx: number = Number(txlx);
      this.alarmTimeText = !Number.isNaN(idx) && idx >= 0 && idx < this.alarmTimeList.length ?
        this.alarmTimeList[idx] : this.alarmTimeList[1];
      // TGRXH 空 → 注意事项显示
      this.showAttentionRow = this.strOf(info['TGRXH']) === '';
    }
  }

  private strOf(v: Object): string {
    if (typeof v === 'string') {
      return v as string;
    }
    return '';
  }

  /** 源码 HandleExamCoursePresenter.c(KSSJ)："yyyy-MM-dd 周X HH:mm"（解析失败回退原文） */
  private formatExamTime(kssj: string): string {
    const parsed: Date = new Date(kssj.replace(' ', 'T'));
    if (Number.isNaN(parsed.getTime())) {
      return kssj;
    }
    return this.timeDisplay(parsed) ;
  }

  /** 弹窗标题/回显共用："yyyy-MM-dd 周X HH:mm"（u()：j.format="yyyy-MM-dd"+" 周"+周字+" "+HH:mm） */
  private timeDisplay(d: Date): string {
    const weekChars: string[] = ['日', '一', '二', '三', '四', '五', '六'];
    const yyyy: string = '' + d.getFullYear();
    const mm: string = (d.getMonth() + 1) < 10 ? '0' + (d.getMonth() + 1) : '' + (d.getMonth() + 1);
    const dd: string = d.getDate() < 10 ? '0' + d.getDate() : '' + d.getDate();
    const hh: string = d.getHours() < 10 ? '0' + d.getHours() : '' + d.getHours();
    const mi: string = d.getMinutes() < 10 ? '0' + d.getMinutes() : '' + d.getMinutes();
    return yyyy + '-' + mm + '-' + dd + ' 周' + weekChars[d.getDay()] + ' ' + hh + ':' + mi;
  }

  /** 源码 d.a(str,str2) 确定回调：q.setText(str)/q.setTag(str2) + enabled 联动 */
  private onTimePicked(dayIdx: number, hourIdx: number, minuteIdx: number): void {
    const base: Date = new Date();
    const picked: Date = new Date(base.getFullYear(), base.getMonth(), base.getDate() + dayIdx,
      hourIdx, minuteIdx);
    const mm: string = (picked.getMonth() + 1) < 10 ? '0' + (picked.getMonth() + 1) :
      '' + (picked.getMonth() + 1);
    const dd: string = picked.getDate() < 10 ? '0' + picked.getDate() : '' + picked.getDate();
    this.examTimeTag = picked.getFullYear() + '-' + mm + '-' + dd + ' ' +
      (hourIdx < 10 ? '0' + hourIdx : '' + hourIdx) + ':' + (minuteIdx < 10 ? '0' + minuteIdx : '' + minuteIdx);
    this.examTimeText = this.timeDisplay(picked);
    // 源码 d 回调：非 add 直接 enabled；add 按科目文本联动
    if (this.handleExamType !== 'add') {
      this.btnEnabled = true;
    } else {
      this.btnEnabled = this.subject.trim() !== '';
    }
  }

  /** 源码 b.onClick + c3()：重复科目 → 校验链 → operatorExam 提交 */
  private submitExam(): void {
    const trimSubject: string = this.subject.trim();
    if (this.existingSubjects.length > 0) {
      for (const one of this.existingSubjects) {
        if (one === trimSubject) {
          this.getUIContext().getPromptAction().showToast({ message: '已存在相同的考试科目' });
          return;
        }
      }
    }
    if (trimSubject === '') {
      this.getUIContext().getPromptAction().showToast({ message: '请输入考试科目' });
      return;
    }
    if (this.subjectEnabled && trimSubject.length > 30) {
      this.getUIContext().getPromptAction().showToast({ message: '科目名称不能超过30个字' });
      return;
    }
    if (this.examTimeText.trim() === '' || this.examTimeTag === '') {
      this.getUIContext().getPromptAction().showToast({ message: '请输入开始时间' });
      return;
    }
    this.doSubmit(trimSubject);
  }

  /** 源码 c3 尾段：构建 SumbitHandleExamEntity → C.g → 成功 U2+z1 finish / 失败 toast */
  private doSubmit(kmmc: string): void {
    const txlx: number = this.alarmTimeList.indexOf(this.alarmTimeText);
    const kslx: string = this.handleExamTitle === '期末考试' ? '0' : '1';
    ApiService.submitOperatorExam(kmmc, this.examTimeTag, this.place.trim(), this.seatNo.trim(),
      this.examNo.trim(), (txlx >= 0 ? txlx : 0) + '', kslx)
      .then((response: ApiResponse<string>) => {
        if (response.code === 1000) {
          return;
        }
        if (response.code === 0) {
          // 源码 h1()：setResult(dataischange=true) + z1(true) finish（无 toast）
          router.back();
        } else if (response.message !== '') {
          this.getUIContext().getPromptAction().showToast({ message: response.message });
        }
      })
      .catch((error: BusinessError) => {
        ApiService.logError('HandleExamCourse operatorExam fail: ' + error.message);
      });
  }

  @Builder
  inputRow(label: string, hint: string, text: string, maxLength: number, indent: boolean,
    editable: boolean, onInput: (v: string) => void) {
    Row() {
      Text(label)
        .fontSize(17)
        .fontColor($r('app.color.common_color_1'))
        .margin({ right: 13 })
      TextInput({ placeholder: hint, text: text })
        .fontSize(17)
        .fontColor($r('app.color.common_color_1'))
        .placeholderColor($r('app.color.common_color_4'))
        .placeholderFont({ size: 17 })
        .maxLength(maxLength)
        .height(44)
        .backgroundColor(Color.Transparent)
        .padding({ left: indent ? 15 : 0, right: 0 })
        .layoutWeight(1)
        .enabled(editable)
        .onChange((v: string) => {
          onInput(v);
        })
    }
    .width('100%')
    .padding({ left: 10, right: 10, top: 15, bottom: 15 })
    .alignItems(VerticalAlign.Center)
    .backgroundColor($r('app.color.white'))
  }

  @Builder
  timeRow() {
    Row() {
      Text('考试时间')
        .fontSize(17)
        .fontColor($r('app.color.common_color_1'))
        .margin({ right: 13 })
      Text(this.examTimeText)
        .fontSize(17)
        .fontColor($r('app.color.common_color_1'))
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .layoutWeight(1)
      Image($r('app.media.arrow_right2'))
        .width(14)
        .height(14)
    }
    .width('100%')
    .padding({ left: 10, right: 10, top: 15, bottom: 15 })
    .alignItems(VerticalAlign.Center)
    .backgroundColor($r('app.color.white'))
    .onClick(() => {
      // 源码 V2()：ChooseTimeDialog 初值 = q.getTag()（已选时间）否则当前时间
      const base: Date = new Date();
      this.pickDay = 0;
      this.pickHour = base.getHours();
      this.pickMinute = base.getMinutes();
      if (this.examTimeTag !== '') {
        const tagged: Date = new Date(this.examTimeTag.replace(' ', 'T'));
        if (!Number.isNaN(tagged.getTime())) {
          const today: Date = new Date(base.getFullYear(), base.getMonth(), base.getDate());
          const dayDiff: number =
            Math.round((tagged.getTime() - today.getTime()) / 86400000);
          this.pickDay = dayDiff < 0 ? 0 : dayDiff;
          this.pickHour = tagged.getHours();
          this.pickMinute = tagged.getMinutes();
        }
      }
      this.showTimeDialog = true;
    })
  }

  @Builder
  thinDivider() {
    Divider()
      .color($r('app.color.common_color_5'))
      .strokeWidth(0.5)
      .width('100%')
  }

  @Builder
  normalDivider() {
    Divider()
      .color($r('app.color.common_color_5'))
      .strokeWidth(1)
      .width('100%')
  }

  @Builder
  timeDialog() {
    // 遮罩 + ChooseTimeDialog 等价面板（三滚轮 + 标题 + 确定）
    Column() {
      Column() {
        // 源码 tv_setexamtimetitle：u() 实时 "yyyy-MM-dd 周X HH:mm"
        Text(this.timeDisplay(new Date(new Date().getFullYear(), new Date().getMonth(),
          new Date().getDate() + this.pickDay, this.pickHour, this.pickMinute)))
          .fontSize(17)
          .fontColor($r('app.color.common_color_1'))
          .height(44)
          .textAlign(TextAlign.Center)
          .width('100%')
        Row() {
          TextPicker({ range: this.dayLabels, selected: this.pickDay })
            .layoutWeight(3)
            .onChange((value: string | string[], index: number | number[]) => {
              this.pickDay = Array.isArray(index) ? Number((index as number[])[0]) : Number(index);
            })
          TextPicker({ range: this.hourLabels, selected: this.pickHour })
            .layoutWeight(1)
            .onChange((value: string | string[], index: number | number[]) => {
              this.pickHour = Array.isArray(index) ? Number((index as number[])[0]) : Number(index);
            })
          TextPicker({ range: this.minuteLabels, selected: this.pickMinute })
            .layoutWeight(1)
            .onChange((value: string | string[], index: number | number[]) => {
              this.pickMinute = Array.isArray(index) ? Number((index as number[])[0]) : Number(index);
            })
        }
        .width('100%')
        .height(200)
        Text('确定')
          .fontSize(17)
          .fontColor($r('app.color.white'))
          .width('80%')
          .height(44)
          .textAlign(TextAlign.Center)
          .borderRadius(4)
          .backgroundColor($r('app.color.common_color_7'))
          .margin({ top: 12, bottom: 16 })
          .onClick(() => {
            this.showTimeDialog = false;
            this.onTimePicked(this.pickDay, this.pickHour, this.pickMinute);
          })
      }
      .width('86%')
      .borderRadius(8)
      .backgroundColor($r('app.color.white'))
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .backgroundColor('rgba(0,0,0,0.4)')
    .onClick(() => {
      this.showTimeDialog = false;
    })
  }

  build() {
    Stack() {
      Column() {
        TitleBar({ title: this.pageTitle, showBack: true, rightText: this.rightBtnText,
          rightButtonStyle: true,
          rightEnabled: this.btnEnabled,
          onRightClick: (): void => {
            // 源码 z.setEnabled 联动 + b.onClick → c3()
            this.submitExam();
          } })
        Scroll() {
          Column() {
            // 1. 科目行（XML：考试科目/请输入考试科目；edit 预填 disabled）
            this.inputRow('考试科目', '请输入考试科目', this.subject, 50, false, this.subjectEnabled,
              (v: string) => {
                this.subject = v;
                // 源码 TextWatcher a：q.tag==null 或科目空 → disabled，否则 enabled
                this.btnEnabled = this.examTimeTag !== '' && v.trim() !== '';
              })
            this.thinDivider()
            // 2. 考试时间行（V2 时间弹窗）
            this.timeRow()
            this.thinDivider()
            // 3. 考试地点行（XML hint=请输入考试地点，maxLength 30）
            this.inputRow('考试地点', '请输入考试地点', this.place, 30, false, true, (v: string) => {
              this.place = v;
            })
            this.thinDivider()
            // 4. 座位号行（XML hint=请输入座位号；marginLeft 30 缩进 + maxLength 10）
            this.inputRow('座位号', '请输入座位号', this.seatNo, 10, true, true, (v: string) => {
              this.seatNo = v;
            })
            this.normalDivider()
            // 5. 准考证号行：XML gone → 仅"等级考试"标题显示（X2 w.setVisibility(0)）
            if (this.showExamNoRow) {
              this.inputRow('准考证号', '输入准考证号（选填）', this.examNo, 30, false, true,
                (v: string) => {
                  this.examNo = v;
                })
              this.normalDivider()
            }
            // 6. 注意事项行：XML gone → edit+ComingExam+TGRXH空 显示
            //    （examination_my_examtimeattention="此考试已刷新…"，TextSize4.Color7=14fp#18B4ED，
            //     图标 16dip=8vp，padding 30/24=15/12vp，marginLeft 8dip=4vp）
            if (this.showAttentionRow) {
              Row() {
                Image($r('app.media.examnation_attention'))
                  .width(8)
                  .height(8)
                Text('此考试已刷新，请确定是否需要更改详细信息')
                  .fontSize(14)
                  .fontColor($r('app.color.common_color_7'))
                  .margin({ left: 4 })
                  .layoutWeight(1)
              }
              .width('100%')
              .padding({ left: 15, right: 15, top: 12, bottom: 12 })
              .alignItems(VerticalAlign.Center)
            }
            // 提醒时间行/同考试人区：源码 XML gone 恒不渲染（保真省略）
          }
          .width('100%')
        }
        .width('100%')
        .layoutWeight(1)
        .backgroundColor($r('app.color.common_color_6'))
        .align(Alignment.Top)
      }
      .width('100%')
      .height('100%')
      .backgroundColor($r('app.color.common_color_6'))

      if (this.showTimeDialog) {
        this.timeDialog()
      }
    }
    .width('100%')
    .height('100%')
  }
}
