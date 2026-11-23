import { router } from '@kit.ArkUI';
import { TitleBar } from '../components/TitleBar';
import { ApiService } from '../network/ApiService';
import { ApiResponse } from '../model/ResponseModel';
import { ScheduleTermParams, CourseSectionsEntry, parseYmdMs, apkTotalWeeks } from '../model/CourseModel';
import { PreferencesUtil } from '../data/PreferencesUtil';

/**
 * 编辑课程页 — 1:1 复刻 schedule/view/EditCourseActivity.java（ARouter /message/editcourse，
 * R.string.mobile_campus_schedule_edit_course 唯一注册的编辑课程路由）
 *
 * 源码考证（W16 清占位依据）：
 *   - timetable/view/EditCourseActivity（edit_course.xml，reuseflag=1/2 双模 savePersonalCourse/
 *     saveCustomCourse）全工程无 reuseflag 调用方（grep "reuseflag" 仅其自身）→ 死代码，不复刻；
 *     "timetable_dao 本地库"在反编译源码/smali 中均不存在（蹭课链无本地 SQLite，仅 Hawk 缓存）。
 *   - 本页取 schedule 包 EditCourseActivity：J1=mobile_campus_schedule_activity_add_course.xml
 *     （与 AddCoursePage 同款表单），T1 标题 course_custom"自定义课程"。
 * 源码还原的 UI 与行为：
 *   1. y(Intent)：xlh + bean(CourseDetail) 必填 → HAP 路由参数 xlh/kcmc/skdd/djj/xqj/qsjsz
 *      （bean 字段拍平）；缺失 → toast"课程信息出错，请重试"+finish
 *   2. W2() 回填：l=KCMC、n=SKDD；DJJ 非空 → day=XQJ、start/end=DJJ 拆分 → 节数文案
 *      "周X s-e"；QSJSZ 非空 → ","拆分（"a-b"展开区间）→ TreeSet 周集 → 周文案 f()
 *   3. x.o()/x.h()：termInfo 学期（maxWeek=GetTimeTableUtil.r，异常回退 25）+ courseSections
 *      （节数滚轮上限；GetTimeTableUtil.l() 本地缓存语义 = PreferencesUtil timetable_course_sections）
 *   4. 周数弹窗 weiget.b（单双全周互斥 + 5 列周格，选中 #88D9FF 连周胶囊）；节数弹窗 weiget.a
 *      四滚轮（周X|第X节|到|第X节，start<=end 联动）；文案 U2/V2 = "周"+h[day]+" "+start+"-"+end
 *   5. 提交 T2()：三段校验（请输入课程名称/请输入课程周数/请输入课程节数）→
 *      ScheduleModel.c.a.d1 POST updateCourse {xlh,kcmc,qsjsz(周集","),djj(s-e),xqj,skdd}，
 *      响应 data=="true"(STATUS_TRUE) → setResult(-1)+finish（无成功 toast，源码即静默），
 *      失败 f → toast message
 *   6. 返回键 S2()/X2()：任一字段非空 → 确认弹窗"是否取消编辑课程？"
 */
const WEEK_NUM_FALLBACK: number = 25;
const SECTION_COUNT_FALLBACK: number = 12;
const WHEEL_ITEM_HEIGHT: number = 53;
const WHEEL_VISIBLE_ITEMS: number = 7;
const WHEEL_EDGE_ITEMS: number = 3;
const WEEK_GRID_COLUMNS: number = 5;
const PREF_COURSE_SECTIONS: string = 'timetable_course_sections';
/** e.h = {'日','一','二','三','四','五','六'}（baselibrary util/e.java:29） */
const WEEK_CHARS: string[] = ['日', '一', '二', '三', '四', '五', '六'];

/** 周几字符（U2/V2：day 1..6 → 一..六，其余（含 7=周日）→ 日） */
function dayChar(day: number): string {
  return day >= 1 && day <= 6 ? WEEK_CHARS[day] : WEEK_CHARS[0];
}

/** 中文数字（baselibrary NumberUtil.q.a 1:1） */
function cnNumber(value: number): string {
  const digits: string[] = ['零', '一', '二', '三', '四', '五', '六', '七', '八', '九'];
  const units: string[] = ['', '十', '百', '千', '万', '十万', '百万', '千万', '亿'];
  const text: string = '' + value;
  let out: string = '';
  for (let i = 0; i < text.length; i++) {
    const digit: number = Number(text[i]);
    if (digit !== 0) {
      out += digits[digit] + units[text.length - 1 - i];
    }
  }
  return out;
}

/** "第X节" 滚轮文案（ChooseCourseSectionDialog.u() 非 HNDS 分支） */
function sectionLabel(section: number): string {
  let label: string = cnNumber(section);
  if (section > 9 && section < 20) {
    label = label.substring(1);
  }
  return '第' + label + '节';
}

@Entry
@Component
struct EditCoursePage {
  @State courseName: string = '';
  @State place: string = '';
  @State weekText: string = '';
  @State sectionText: string = '';
  @State weekSet: number[] = [];
  @State day: number = 1;
  @State startSection: number = 1;
  @State endSection: number = 1;
  @State maxWeek: number = WEEK_NUM_FALLBACK;
  @State sectionCount: number = SECTION_COUNT_FALLBACK;
  @State showWeekDialog: boolean = false;
  @State showSectionDialog: boolean = false;
  @State weekChosen: boolean[] = [];
  @State oddChecked: boolean = false;
  @State evenChecked: boolean = false;
  @State allChecked: boolean = false;
  @State submitting: boolean = false;
  private xlh: string = '';
  private startScroller: Scroller = new Scroller();
  private endScroller: Scroller = new Scroller();
  private dayScroller: Scroller = new Scroller();

  aboutToAppear(): void {
    // y(Intent)：xlh+bean 必填，缺失 → "课程信息出错，请重试"+finish
    const params: Record<string, Object> | undefined =
      router.getParams() as Record<string, Object> | undefined;
    if (params === undefined || params === null) {
      this.invalidParams();
      return;
    }
    this.xlh = this.strParam(params, 'xlh');
    const kcmc: string = this.strParam(params, 'kcmc');
    if (this.xlh === '' || kcmc === '') {
      this.invalidParams();
      return;
    }
    this.fillFromBean(params, kcmc);
    this.loadTermAndSections();
  }

  private strParam(params: Record<string, Object>, key: string): string {
    const v: Object = params[key];
    return typeof v === 'string' ? v as string : '';
  }

  private invalidParams(): void {
    this.getUIContext().getPromptAction().showToast({ message: '课程信息出错，请重试' });
    router.back();
  }

  /** W2()：bean 回填表单（KCMC/SKDD/DJJ+XQJ/QSJSZ） */
  private fillFromBean(params: Record<string, Object>, kcmc: string): void {
    this.courseName = kcmc;
    this.place = this.strParam(params, 'skdd');
    const djj: string = this.strParam(params, 'djj');
    const xqj: string = this.strParam(params, 'xqj');
    if (djj !== '') {
      // XQJ → day（非数字回退 1）；DJJ "s-e" → start/end
      const dayNum: number = Number(xqj);
      this.day = !Number.isNaN(dayNum) && dayNum >= 1 ? dayNum : 1;
      const parts: string[] = djj.split('-');
      if (parts.length === 2) {
        const s: number = Number(parts[0]);
        const e: number = Number(parts[1]);
        if (!Number.isNaN(s) && !Number.isNaN(e)) {
          this.startSection = s;
          this.endSection = e;
          this.sectionText = '周' + dayChar(this.day) + ' ' + s + '-' + e;
        }
      }
    }
    const qsjsz: string = this.strParam(params, 'qsjsz');
    if (qsjsz !== '') {
      // QSJSZ ","拆分 → "a-b"展开 → TreeSet 升序去重 → f() 文案
      const set: Set<number> = new Set<number>();
      const tokens: string[] = qsjsz.split(',');
      for (const token of tokens) {
        if (token.indexOf('-') >= 0) {
          const range: string[] = token.split('-');
          const from: number = Number(range[0]);
          const to: number = Number(range[1]);
          if (!Number.isNaN(from) && !Number.isNaN(to)) {
            for (let w = from; w <= to; w++) {
              set.add(w);
            }
          }
        } else {
          const single: number = Number(token);
          if (!Number.isNaN(single)) {
            set.add(single);
          }
        }
      }
      const sorted: number[] = Array.from(set).sort((a: number, b: number) => a - b);
      this.weekSet = sorted;
      this.weekText = this.weekDisplay(sorted);
    }
  }

  /** f1 的 x.o()/x.h()：学期 maxWeek + courseSections 节数上限（本地缓存优先） */
  private async loadTermAndSections(): Promise<void> {
    ApiService.getScheduleTermParams()
      .then((resp: ApiResponse<ScheduleTermParams>) => {
        const term: ScheduleTermParams = resp.data;
        const weeks: number = apkTotalWeeks(parseYmdMs(term.ksrq), parseYmdMs(term.jsrq));
        if (weeks > 0) {
          this.maxWeek = weeks;
        }
      })
      .catch(() => {
        // GetTimeTableUtil 异常回退 25
      });
    const cached: string = await PreferencesUtil.getString(PREF_COURSE_SECTIONS, '');
    if (cached !== '') {
      try {
        const raw: Object = JSON.parse(cached) as Object;
        if (Array.isArray(raw) && (raw as Object[]).length > 0) {
          this.sectionCount = (raw as Object[]).length;
        }
      } catch {
        // 缓存损坏 → 走网络
      }
    }
    ApiService.getCourseSections()
      .then((resp: ApiResponse<CourseSectionsEntry[]>) => {
        if (resp.code === 0 && resp.data.length > 0) {
          this.sectionCount = resp.data.length;
        }
      })
      .catch(() => {
        // 节数上限沿用回退值
      });
  }

  private toast(msg: string): void {
    this.getUIContext().getPromptAction().showToast({ message: msg });
  }

  /** 返回键 S2()/X2()：任一字段非空 → "是否取消编辑课程？"确认弹窗 */
  onBackPress(): boolean {
    if (this.courseName === '' && this.place === '' && this.weekText === '' && this.sectionText === '') {
      return false;
    }
    this.getUIContext().showAlertDialog({
      message: '是否取消编辑课程？',
      autoCancel: true,
      alignment: DialogAlignment.Center,
      primaryButton: {
        value: '确定',
        action: () => {
          router.back();
        }
      },
      secondaryButton: {
        value: '取消',
        action: () => {
        }
      }
    });
    return true;
  }

  // ===== 周数弹窗（ChooseCourseWeekAdapter 逻辑 1:1） =====

  private oddEvenState(): number {
    // getOddEvenState()：0=全单 1=全双 2=全周 3=杂
    let oddCount: number = 0;
    let evenCount: number = 0;
    for (let i = 0; i < this.weekChosen.length; i++) {
      if (this.weekChosen[i]) {
        if ((i + 1) % 2 === 0) {
          evenCount++;
        } else {
          oddCount++;
        }
      }
    }
    const max: number = this.weekChosen.length;
    if (oddCount > 0 && evenCount > 0) {
      return oddCount + evenCount === max ? 2 : 3;
    }
    if (evenCount === Math.floor(max / 2)) {
      return 1;
    }
    if (oddCount === Math.floor(max / 2) + (max % 2)) {
      return 0;
    }
    return 3;
  }

  private refreshWeekChecks(): void {
    const state: number = this.oddEvenState();
    this.oddChecked = state === 0;
    this.evenChecked = state === 1;
    this.allChecked = state === 2;
  }

  private setAllWeeks(value: boolean): void {
    const arr: boolean[] = this.weekChosen;
    for (let i = 0; i < arr.length; i++) {
      arr[i] = value;
    }
    this.weekChosen = arr;
  }

  private selectOddWeeks(): void {
    const arr: boolean[] = this.weekChosen;
    for (let i = 0; i < arr.length; i++) {
      arr[i] = i % 2 === 0;
    }
    this.weekChosen = arr;
  }

  private selectEvenWeeks(): void {
    const arr: boolean[] = this.weekChosen;
    for (let i = 0; i < arr.length; i++) {
      arr[i] = i % 2 === 1;
    }
    this.weekChosen = arr;
  }

  private onWeekItemClick(index: number): void {
    const arr: boolean[] = this.weekChosen;
    arr[index] = !arr[index];
    this.weekChosen = arr;
    this.refreshWeekChecks();
  }

  /** f()：连续周 "first-last"/"first"，否则 d() 单双周段混排 */
  private weekDisplay(sorted: number[]): string {
    if (sorted.length === 0) {
      return '';
    }
    let contiguous: boolean = true;
    for (let i = 1; i < sorted.length; i++) {
      if (sorted[i] !== sorted[i - 1] + 1) {
        contiguous = false;
        break;
      }
    }
    if (contiguous) {
      return sorted[0] === sorted[sorted.length - 1] ? '' + sorted[0] :
        sorted[0] + '-' + sorted[sorted.length - 1];
    }
    return this.weekSegmentText(sorted);
  }

  /** d() 1:1：连段 "a-b（单周）/（双周）"、孤周 "n,"，尾部去分隔符 */
  private weekSegmentText(sorted: number[]): string {
    let sb: string = '';
    let oddStart: number = -1;
    let oddEnd: number = -1;
    let evenStart: number = -1;
    let evenEnd: number = -1;
    for (const w of sorted) {
      if (w % 2 === 1) {
        if (oddStart >= 0) {
          if (oddEnd + 2 === w) {
            oddEnd = w;
          } else {
            sb += this.flushWeekSegment(oddStart, oddEnd, '单周');
            oddStart = w;
            oddEnd = w;
          }
        } else {
          oddStart = w;
          oddEnd = w;
        }
      } else {
        if (evenStart >= 0) {
          if (evenEnd + 2 === w) {
            evenEnd = w;
          } else {
            sb += this.flushWeekSegment(evenStart, evenEnd, '双周');
            evenStart = w;
            evenEnd = w;
          }
        } else {
          evenStart = w;
          evenEnd = w;
        }
      }
    }
    if (oddStart > 0) {
      sb += this.flushWeekSegment(oddStart, oddEnd, '单周');
    }
    if (evenEnd > 0) {
      sb += this.flushWeekSegment(evenStart, evenEnd, '双周');
    }
    return sb.length > 0 ? sb.substring(0, sb.length - 1) : '';
  }

  private flushWeekSegment(start: number, end: number, tag: string): string {
    if (start === end) {
      return start + ',';
    }
    return start + '-' + end + '（' + tag + '）,';
  }

  private openWeekDialog(): void {
    // 构造器入参 w.h() 副本（取消即丢弃）
    const arr: boolean[] = [];
    for (let i = 0; i < this.maxWeek; i++) {
      arr.push(this.weekSet.indexOf(i + 1) >= 0);
    }
    this.weekChosen = arr;
    this.refreshWeekChecks();
    this.showWeekDialog = true;
  }

  private confirmWeekDialog(): void {
    // g.a(chosenWeeks)：空集回显"点击修改上课周数"，否则 o(set)+f() 文案
    const chosen: number[] = [];
    for (let i = 0; i < this.weekChosen.length; i++) {
      if (this.weekChosen[i]) {
        chosen.push(i + 1);
      }
    }
    this.weekSet = chosen;
    this.weekText = chosen.length === 0 ? '' : this.weekDisplay(chosen);
    this.showWeekDialog = false;
  }

  // ===== 节数弹窗（ChooseCourseSectionDialog 滚轮 1:1） =====

  private dayOptions(): string[] {
    const out: string[] = [];
    for (let i = 1; i <= 6; i++) {
      out.push('周' + WEEK_CHARS[i]);
    }
    out.push('周' + WEEK_CHARS[0]);
    return out;
  }

  private sectionOptions(): string[] {
    const out: string[] = [];
    for (let i = 1; i <= this.sectionCount; i++) {
      out.push(sectionLabel(i));
    }
    return out;
  }

  private openSectionDialog(): void {
    this.showSectionDialog = true;
    setTimeout(() => {
      this.dayScroller.scrollToIndex(WHEEL_EDGE_ITEMS + this.day - 1, false);
      this.startScroller.scrollToIndex(WHEEL_EDGE_ITEMS + this.startSection - 1, false);
      this.endScroller.scrollToIndex(WHEEL_EDGE_ITEMS + this.endSection - 1, false);
    }, 60);
  }

  private onStartWheelChange(dataIdx: number): void {
    if (dataIdx >= 0 && dataIdx < this.sectionCount) {
      this.startSection = dataIdx + 1;
      if (this.endSection < this.startSection) {
        this.endSection = this.startSection;
        this.endScroller.scrollToIndex(WHEEL_EDGE_ITEMS + this.endSection - 1, true);
      }
    }
  }

  private onEndWheelChange(dataIdx: number): void {
    if (dataIdx >= 0 && dataIdx < this.sectionCount) {
      this.endSection = dataIdx + 1;
      if (this.endSection < this.startSection) {
        this.startSection = this.endSection;
        this.startScroller.scrollToIndex(WHEEL_EDGE_ITEMS + this.startSection - 1, true);
      }
    }
  }

  private confirmSectionDialog(): void {
    // a.a(day,start,end) → q.setText(U2(...))："周X s-e"
    this.sectionText = '周' + dayChar(this.day) + ' ' + this.startSection + '-' + this.endSection;
    this.showSectionDialog = false;
  }

  // ===== 提交（e.onClick 校验 + ScheduleModel.d1 updateCourse POST 1:1） =====

  private submit(): void {
    if (this.courseName === '') {
      this.toast('请输入课程名称');
      return;
    }
    if (this.weekText === '') {
      this.toast('请输入课程周数');
      return;
    }
    if (this.sectionText === '') {
      this.toast('请输入课程节数');
      return;
    }
    if (this.submitting) {
      return;
    }
    this.submitting = true;
    // T2()：qsjsz=周集升序","拼接；djj=g()+"-"+c()；xqj=b()；skdd=e()
    let qsjsz: string = '';
    for (let i = 0; i < this.weekSet.length; i++) {
      qsjsz += (i > 0 ? ',' : '') + this.weekSet[i];
    }
    ApiService.updateCourse(this.xlh, this.courseName, qsjsz,
      this.startSection + '-' + this.endSection, String(this.day), this.place)
      .then((resp: ApiResponse<Object>) => {
        this.submitting = false;
        if (resp.code === 0 && ('' + resp.data) === 'true') {
          // b.g：setResult(-1)+finish（源码无成功 toast）
          router.back();
        } else if (resp.code === 0) {
          // g 非 true：源码静默（无 f 回调）；HAP 保持静默等待重试
        } else {
          this.toast(resp.message === '' ? '连接不到网络，请稍后再试' : resp.message);
        }
      })
      .catch(() => {
        this.submitting = false;
        this.toast('连接不到网络，请稍后再试');
      });
  }

  // ===== UI（mobile_campus_schedule_activity_add_course.xml，与 AddCoursePage 同款表单） =====

  @Builder
  wheelEdges(edgeKey: string) {
    ForEach([0, 1, 2], (item: number) => {
      ListItem() {
        Column()
          .width('100%')
          .height(WHEEL_ITEM_HEIGHT)
      }
    }, (item: number) => edgeKey + item)
  }

  @Builder
  wheelList(scroller: Scroller, options: string[], selectedIndex: number, keyPrefix: string,
    onSelect: (idx: number) => void) {
    List({ scroller: scroller, space: 0 }) {
      this.wheelEdges('eTop' + keyPrefix)
      ForEach(options, (label: string, dataIndex: number) => {
        ListItem() {
          Text(label)
            .fontSize(dataIndex === selectedIndex ? 17 : 15)
            .fontColor(dataIndex === selectedIndex ? $r('app.color.mobile_campus_primary_color') :
              $r('app.color.common_color_2'))
            .width('100%')
            .height(WHEEL_ITEM_HEIGHT)
            .textAlign(TextAlign.Center)
            .onClick(() => {
              onSelect(dataIndex);
            })
        }
      }, (label: string) => keyPrefix + label)
      this.wheelEdges('eEnd' + keyPrefix)
    }
    .scrollSnapAlign(ScrollSnapAlign.CENTER)
    .onScrollIndex((start: number, end: number) => {
      const dataIdx: number = end - WHEEL_EDGE_ITEMS;
      if (dataIdx >= 0 && dataIdx < options.length) {
        onSelect(dataIdx);
      }
    })
    .scrollBar(BarState.Off)
    .width('100%')
    .height(WHEEL_ITEM_HEIGHT * WHEEL_VISIBLE_ITEMS)
  }

  @Builder
  formRow(icon: Resource, label: string, slot: string) {
    Row() {
      Image(icon)
        .width(23)
        .height(23)
      Text(label)
        .fontSize(16)
        .fontColor($r('app.color.common_color_1'))
        .margin({ left: 12, right: 12 })
      if (slot === 'name') {
        TextInput({ text: this.courseName, placeholder: '请输入课程名称' })
          .fontSize(16)
          .fontColor($r('app.color.common_color_1'))
          .placeholderColor('#B8C0C9')
          .placeholderFont({ size: 16 })
          .maxLength(20)
          .height(48)
          .backgroundColor(Color.Transparent)
          .padding(0)
          .layoutWeight(1)
          .onChange((value: string) => {
            this.courseName = value;
          })
      } else if (slot === 'place') {
        // 源码 edit_course_iv_delete_place_btn 绑定后无显隐代码（visibility 恒 gone），
        // 与 AddCoursePage 同款表单口径一致：不渲染删除按钮
        TextInput({ text: this.place, placeholder: '请输入上课地点' })
          .fontSize(16)
          .fontColor($r('app.color.common_color_1'))
          .placeholderColor('#B8C0C9')
          .placeholderFont({ size: 16 })
          .maxLength(20)
          .height(48)
          .backgroundColor(Color.Transparent)
          .padding(0)
          .layoutWeight(1)
          .onChange((value: string) => {
            this.place = value;
          })
      } else if (slot === 'week') {
        Text(this.weekText === '' ? '点击修改上课周数' : this.weekText)
          .fontSize(16)
          .fontColor(this.weekText === '' ? '#B8C0C9' : $r('app.color.common_color_1'))
          .layoutWeight(1)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      } else {
        Text(this.sectionText === '' ? '点击修改上课时间' : this.sectionText)
          .fontSize(16)
          .fontColor(this.sectionText === '' ? '#B8C0C9' : $r('app.color.common_color_1'))
          .layoutWeight(1)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
    }
    .width('100%')
    .height(48)
    .alignItems(VerticalAlign.Center)
    .padding({ left: 12, right: 12 })
    .backgroundColor($r('app.color.white'))
  }

  /** ChooseCourseWeeksDialog：标题+完成+单双全周勾选+5 列周格 */
  @Builder
  weekDialog() {
    Column() {
      Blank()
        .onClick(() => {
          this.showWeekDialog = false;
        })
      Column() {
        Row() {
          Text('选择上课周数')
            .fontSize(19)
            .fontColor($r('app.color.common_color_7'))
            .layoutWeight(1)
            .textAlign(TextAlign.Center)
            .padding(12)
          Text('完成')
            .fontSize(17)
            .fontColor($r('app.color.common_color_7'))
            .padding(10)
            .backgroundColor($r('app.color.hover_grey'))
            .onClick(() => {
              this.confirmWeekDialog();
            })
        }
        .width('100%')
        .alignItems(VerticalAlign.Center)
        Divider()
          .color($r('app.color.common_color_5'))
          .strokeWidth(0.5)
          .width('100%')
        Row() {
          Text('单周')
            .fontSize(17)
            .fontColor($r('app.color.common_color_1'))
            .layoutWeight(1)
            .textAlign(TextAlign.Center)
            .padding({ top: 10, bottom: 10 })
            .onClick(() => {
              if (this.oddChecked) {
                this.setAllWeeks(false);
              } else {
                this.selectOddWeeks();
              }
              this.refreshWeekChecks();
            })
          Row()
            .width(1)
            .height(20)
            .backgroundColor($r('app.color.common_color_5'))
          Text('双周')
            .fontSize(17)
            .fontColor($r('app.color.common_color_1'))
            .layoutWeight(1)
            .textAlign(TextAlign.Center)
            .padding({ top: 10, bottom: 10 })
            .onClick(() => {
              if (this.evenChecked) {
                this.setAllWeeks(false);
              } else {
                this.selectEvenWeeks();
              }
              this.refreshWeekChecks();
            })
          Row()
            .width(1)
            .height(20)
            .backgroundColor($r('app.color.common_color_5'))
          Text('全周')
            .fontSize(17)
            .fontColor($r('app.color.common_color_1'))
            .layoutWeight(1)
            .textAlign(TextAlign.Center)
            .padding({ top: 10, bottom: 10 })
            .onClick(() => {
              if (this.allChecked) {
                this.setAllWeeks(false);
              } else {
                this.setAllWeeks(true);
              }
              this.refreshWeekChecks();
            })
        }
        .width('100%')
        .alignItems(VerticalAlign.Center)
        Divider()
          .color($r('app.color.common_color_5'))
          .strokeWidth(0.5)
          .width('100%')
        Grid() {
          ForEach(this.weekChosen, (chosen: boolean, index: number) => {
            GridItem() {
              Text('' + (index + 1))
                .fontSize(16)
                .fontColor(chosen ? $r('app.color.white') : $r('app.color.black'))
                .width('100%')
                .height('100%')
                .textAlign(TextAlign.Center)
                .backgroundColor(chosen ? $r('app.color.common_color_12') : Color.Transparent)
                .borderRadius({
                  topLeft: chosen && (index % WEEK_GRID_COLUMNS === 0 || index === 0 ||
                    !this.weekChosen[index - 1]) ? 14 : 0,
                  topRight: chosen && ((index + 1) % WEEK_GRID_COLUMNS === 0 ||
                    index === this.weekChosen.length - 1 || !this.weekChosen[index + 1]) ? 14 : 0,
                  bottomLeft: chosen && (index % WEEK_GRID_COLUMNS === 0 || index === 0 ||
                    !this.weekChosen[index - 1]) ? 14 : 0,
                  bottomRight: chosen && ((index + 1) % WEEK_GRID_COLUMNS === 0 ||
                    index === this.weekChosen.length - 1 || !this.weekChosen[index + 1]) ? 14 : 0
                })
                .padding({ top: 3, bottom: 3 })
            }
            .height(40)
            .onClick(() => {
              this.onWeekItemClick(index);
            })
          }, (chosen: boolean, index: number) => 'wk' + index + '_' + (chosen ? '1' : '0'))
        }
        .columnsTemplate('1fr 1fr 1fr 1fr 1fr')
        .width('100%')
        .padding({ left: 12, right: 12, top: 10, bottom: 19 })
      }
      .width('100%')
      .backgroundColor($r('app.color.white'))
      .onClick(() => {
        // 拦截面板内点击
      })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#77000000')
    .alignItems(HorizontalAlign.Start)
    .justifyContent(FlexAlign.End)
  }

  /** ChooseCourseSectionDialog：标题+完成+周X|第X节|到|第X节 四段滚轮 */
  @Builder
  sectionDialog() {
    Column() {
      Blank()
        .onClick(() => {
          this.showSectionDialog = false;
        })
      Column() {
        Row() {
          Text('选择上课节数')
            .fontSize(19)
            .fontColor($r('app.color.common_color_7'))
            .layoutWeight(1)
            .textAlign(TextAlign.Center)
            .padding(12)
          Text('完成')
            .fontSize(17)
            .fontColor($r('app.color.common_color_7'))
            .padding(10)
            .backgroundColor($r('app.color.hover_grey'))
            .onClick(() => {
              this.confirmSectionDialog();
            })
        }
        .width('100%')
        .alignItems(VerticalAlign.Center)
        Row() {
          Column() {
            this.wheelList(this.dayScroller, this.dayOptions(), this.day - 1, 'day',
              (idx: number) => {
                this.day = idx + 1;
              })
          }
          .layoutWeight(3)
          Column() {
            this.wheelList(this.startScroller, this.sectionOptions(), this.startSection - 1, 'st',
              (idx: number) => {
                this.onStartWheelChange(idx);
              })
          }
          .layoutWeight(4)
          Text('到')
            .fontSize(17)
            .fontColor($r('app.color.common_color_2'))
            .margin({ left: 6, right: 6 })
          Column() {
            this.wheelList(this.endScroller, this.sectionOptions(), this.endSection - 1, 'ed',
              (idx: number) => {
                this.onEndWheelChange(idx);
              })
          }
          .layoutWeight(4)
        }
        .width('100%')
        .alignItems(VerticalAlign.Center)
        .padding({ bottom: 19 })
      }
      .width('100%')
      .backgroundColor($r('app.color.white'))
      .onClick(() => {
        // 拦截面板内点击
      })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#77000000')
    .alignItems(HorizontalAlign.Start)
    .justifyContent(FlexAlign.End)
  }

  build() {
    Stack({ alignContent: Alignment.Bottom }) {
      Column() {
        TitleBar({ title: '自定义课程', showBack: true })
        Scroll() {
          Column() {
            Column() {
              this.formRow($r('app.media.mobile_campus_schedule_title'), '课程名称', 'name')
            }
            .width('100%')
            .margin({ top: 12 })
            Divider()
              .color($r('app.color.common_color_5'))
              .strokeWidth(0.5)
              .width('100%')
            this.formRow($r('app.media.mobile_campus_schedule_local'), '上课地点', 'place')
            Divider()
              .color($r('app.color.common_color_5'))
              .strokeWidth(0.5)
              .width('100%')
            Column() {
              this.formRow($r('app.media.mobile_campus_schedule_class_b'), '课程周数', 'week')
            }
            .width('100%')
            .margin({ top: 15 })
            .onClick(() => {
              this.openWeekDialog();
            })
            Divider()
              .color($r('app.color.common_color_5'))
              .strokeWidth(0.5)
              .width('100%')
            this.formRow($r('app.media.mobile_campus_schedule_class_b'), '课程节数', 'section')
            Divider()
              .color($r('app.color.common_color_5'))
              .strokeWidth(0.5)
              .width('100%')
          }
          .width('100%')
        }
        .width('100%')
        .layoutWeight(1)
        .scrollBar(BarState.Off)

        // edit_course_tv_confirm_btn：mobile_campus_schedule_selector_confirm（恒 enabled）
        Column() {
          Text('提交')
            .fontSize(16)
            .fontColor($r('app.color.white'))
            .width('100%')
            .height(40)
            .textAlign(TextAlign.Center)
            .borderRadius(4)
            .backgroundColor($r('app.color.mobile_campus_schedule_confirm_blue'))
            .onClick(() => {
              this.submit();
            })
        }
        .width('100%')
        .padding({ left: 12, right: 12, top: 48, bottom: 27 })
      }
      .width('100%')
      .height('100%')
      .backgroundColor($r('app.color.common_color_6'))

      if (this.showWeekDialog) {
        this.weekDialog()
      }
      if (this.showSectionDialog) {
        this.sectionDialog()
      }
    }
    .width('100%')
    .height('100%')
  }
}
