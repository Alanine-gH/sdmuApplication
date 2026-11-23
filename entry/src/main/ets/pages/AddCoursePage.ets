import { router } from '@kit.ArkUI';
import { TitleBar } from '../components/TitleBar';
import { ApiService } from '../network/ApiService';
import { ApiResponse } from '../model/ResponseModel';
import { ScheduleTermParams, CourseSectionsEntry, parseYmdMs, apkTotalWeeks } from '../model/CourseModel';
import { BreakpointSystem } from '../common/BreakpointSystem';
import { AdaptiveLayoutHelper } from '../common/AdaptiveLayoutHelper';

/**
 * 自定义课程添加页 — 1:1 复刻 schedule/view/AddCourseActivity.java
 * （路由 /message/addcourse，TimetableActivity FAB custom 入口）
 *
 * 源码还原的 UI 与行为：
 *   1. 布局 mobile_campus_schedule_activity_add_course.xml：课程名称/上课地点输入行
 *      （icon 23vp+label 16fp marginH12+EditText maxLength20 hint #B8C0C9）+
 *      课程周数/课程节数选择行（hint 文案 setting_week_num_info/setting_section_num_info）+
 *      底部提交按钮（高40vp 圆角4vp，enable #1B68B6 / disable #B8C0C9）
 *   2. 周数弹窗 ChooseCourseWeeksDialog(weiget/b.java)+ChooseCourseWeekAdapter：
 *      标题"选择上课周数"19fp #18B4ED + 右上"完成"；单周/双周/全周 互斥 CheckBox；
 *      5 列周格 1..maxWeek（GetTimeTableUtil.r(jsrq-ksrq) 取整周数，异常回退 25），
 *      选中 common_color_12(#88D9FF) 圆角胶囊、连周中段方角、文字选中变白
 *   3. 节数弹窗 ChooseCourseSectionDialog(weiget/a.java)：4 滚轮 周X|第X节|到|第X节，
 *      周序 一..六、日（e.h 数组），节序文案"第X节"（maxWeek 段=courseSections.size），
 *      滚动联动 start<=end（e()），完成回调 a(day,start,end)
 *   4. 节数文案 U2()/V2()：SDMU 非HNDS 分支 = "周"+h[day]+" "+start+"-"+end（SERVER="-"）
 *   5. 提交 d.onClick：五段校验文案源码原文；qsjsz=周集","拼接（SP），djj=start+"-"+end（SERVER），
 *      xqj=day，skdd=地点 → POST addPersonalCourse（ScheduleModel.T0），响应 "1"=成功
 *      （g: STATUS_TRUE）→"添加成功"+finish，否则"添加失败"
 *   6. 返回键 S2()：课程名 trim 非空 → 确认弹窗"是否取消自定义课程？"（W2）
 *   7. 周数显示文本 f()/d()：连续周 "1-16"，否则单周段 "1,3-15（单周）" 与双周段混排
 */
const WEEK_NUM_FALLBACK: number = 25;
const SECTION_COUNT_FALLBACK: number = 12;
const WHEEL_ITEM_HEIGHT: number = 53;
const WHEEL_VISIBLE_ITEMS: number = 7;
const WHEEL_EDGE_ITEMS: number = 3;
/** e.h = {'日','一','二','三','四','五','六'}（baselibrary util/e.java:29） */
const WEEK_CHARS: string[] = ['日', '一', '二', '三', '四', '五', '六'];

/** 周几字符（U2/V2：day 1..6 → 一..六，其余（含 7=周日）→ 日） */
function dayChar(day: number): string {
  return day >= 1 && day <= 6 ? WEEK_CHARS[day] : WEEK_CHARS[0];
}

/** 中文数字（baselibrary NumberUtil.q.a 1:1：1→一、10→一十、11→一十一、20→二十） */
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

/** "第X节" 滚轮文案（ChooseCourseSectionDialog.u() 非 HNDS 分支：q.a 中文数字，11..19 去首字） */
function sectionLabel(section: number): string {
  let label: string = cnNumber(section);
  if (section > 9 && section < 20) {
    label = label.substring(1);
  }
  return '第' + label + '节';
}

@Entry
@Component
struct AddCoursePage {
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
  @StorageProp('currentBreakpoint') currentBreakpoint: string = 'sm';
  @StorageProp('windowWidthVp') windowWidthVp: number = 360;
  @StorageProp('windowHeightVp') windowHeightVp: number = 640;
  @StorageProp('isCompactHeight') isCompactHeight: boolean = false;
  @StorageProp('avoidAreaBottomVp') avoidAreaBottomVp: number = 0;
  private startScroller: Scroller = new Scroller();
  private endScroller: Scroller = new Scroller();
  private dayScroller: Scroller = new Scroller();

  private getWeekGridCols(): number {
    return BreakpointSystem.getGridColumns(this.currentBreakpoint, 5);
  }

  aboutToAppear(): void {
    // f1：x.o() 学期信息（maxWeek）+ x.h() courseSections（节数滚轮上限）
    ApiService.getScheduleTermParams()
      .then((resp: ApiResponse<ScheduleTermParams>) => {
        const term: ScheduleTermParams = resp.data;
        const startMs: number = parseYmdMs(term.ksrq);
        const endMs: number = parseYmdMs(term.jsrq);
        const weeks: number = apkTotalWeeks(startMs, endMs);
        if (weeks > 0) {
          this.maxWeek = weeks;
        }
      })
      .catch(() => {
        // 源码 weiget/b.u() catch → iR=25
      });
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

  /** 返回键 S2()/W2()：课程名 trim 非空 → "是否取消自定义课程？"确认弹窗 */
  onBackPress(): boolean {
    if (this.courseName.trim() === '') {
      return false;
    }
    this.getUIContext().showAlertDialog({
      message: '是否取消自定义课程？',
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

  private selectAllWeeks(): void {
    const arr: boolean[] = this.weekChosen;
    for (let i = 0; i < arr.length; i++) {
      arr[i] = true;
    }
    this.weekChosen = arr;
  }

  private selectNoneWeek(): void {
    const arr: boolean[] = this.weekChosen;
    for (let i = 0; i < arr.length; i++) {
      arr[i] = false;
    }
    this.weekChosen = arr;
  }

  private selectOddWeeks(): void {
    // selectAllOddWeeks()：偶位（周数 1,3,5..）true
    const arr: boolean[] = this.weekChosen;
    for (let i = 0; i < arr.length; i++) {
      arr[i] = i % 2 === 0;
    }
    this.weekChosen = arr;
  }

  private selectEvenWeeks(): void {
    // selectAllEvenWeeks()：偶数周（0-based 奇位）true
    const arr: boolean[] = this.weekChosen;
    for (let i = 0; i < arr.length; i++) {
      arr[i] = i % 2 === 1;
    }
    this.weekChosen = arr;
  }

  private onWeekItemClick(index: number): void {
    // reverseWeekChosenState()：翻转 + 刷新胶囊角标
    const arr: boolean[] = this.weekChosen;
    arr[index] = !arr[index];
    this.weekChosen = arr;
    this.refreshWeekChecks();
  }

  /** f()：连续周 "first-last"/"first"，否则 d() 单双周段混排 */
  private weekDisplay(): string {
    const chosen: number[] = [];
    for (let i = 0; i < this.weekChosen.length; i++) {
      if (this.weekChosen[i]) {
        chosen.push(i + 1);
      }
    }
    if (chosen.length === 0) {
      return '';
    }
    let contiguous: boolean = true;
    for (let i = 1; i < chosen.length; i++) {
      if (chosen[i] !== chosen[i - 1] + 1) {
        contiguous = false;
        break;
      }
    }
    if (contiguous) {
      return chosen[0] === chosen[chosen.length - 1] ? '' + chosen[0] :
        chosen[0] + '-' + chosen[chosen.length - 1];
    }
    return this.weekSegmentText(chosen);
  }

  /** d() 1:1：连段 "a-b（单周）/（双周）"、孤周 "n,"，尾部去一个分隔符（"1,3-15（单周）"） */
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
    // deleteCharAt(length-1)：去掉尾部分隔符
    return sb.length > 0 ? sb.substring(0, sb.length - 1) : '';
  }

  /** 段落拼接：单周 "i,"（SP=","），连段 "i-e（单周）,"（SERVER="-"），尾部 deleteCharAt */
  private flushWeekSegment(start: number, end: number, tag: string): string {
    if (start === end) {
      return start + ',';
    }
    return start + '-' + end + '（' + tag + '）,';
  }

  private openWeekDialog(): void {
    // 每次打开按已提交集合 weekSet 初始化（源码构造器入参 w.h() 副本，取消即丢弃）
    const arr: boolean[] = [];
    for (let i = 0; i < this.maxWeek; i++) {
      arr.push(this.weekSet.indexOf(i + 1) >= 0);
    }
    this.weekChosen = arr;
    this.refreshWeekChecks();
    this.showWeekDialog = true;
  }

  private confirmWeekDialog(): void {
    // 完成 → g.a(chosenWeeks)：TreeSet 升序提交（取消路径不回写，源码 dismiss 无回调）
    const chosen: number[] = [];
    for (let i = 0; i < this.weekChosen.length; i++) {
      if (this.weekChosen[i]) {
        chosen.push(i + 1);
      }
    }
    this.weekSet = chosen;
    // e.a()：空集 → 回显"点击修改上课周数"
    this.weekText = chosen.length === 0 ? '' : this.weekDisplay();
    this.showWeekDialog = false;
  }

  // ===== 节数弹窗（ChooseCourseSectionDialog 滚轮 1:1） =====

  private dayOptions(): string[] {
    // u()：周一..周六 + 周日（末位）
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
    // e()：start 滚动 → end < start 时 end 跟随
    if (dataIdx >= 0 && dataIdx < this.sectionCount) {
      this.startSection = dataIdx + 1;
      if (this.endSection < this.startSection) {
        this.endSection = this.startSection;
        this.endScroller.scrollToIndex(WHEEL_EDGE_ITEMS + this.endSection - 1, true);
      }
    }
  }

  private onEndWheelChange(dataIdx: number): void {
    // e()：end 滚动 → end < start 时 start 跟随
    if (dataIdx >= 0 && dataIdx < this.sectionCount) {
      this.endSection = dataIdx + 1;
      if (this.endSection < this.startSection) {
        this.startSection = this.endSection;
        this.startScroller.scrollToIndex(WHEEL_EDGE_ITEMS + this.startSection - 1, true);
      }
    }
  }

  private confirmSectionDialog(): void {
    // a.a(day,start,end) → q.setText(U2(...))：非HNDS = i2 + SERVER("-") + i3 → "周X 1-2"
    this.sectionText = '周' + dayChar(this.day) + ' ' + this.startSection + '-' + this.endSection;
    this.showSectionDialog = false;
  }

  // ===== 提交（d.onClick 五段校验 + ScheduleModel.T0 POST 1:1） =====

  private submit(): void {
    if (this.courseName === '') {
      this.toast('请输入课程名称');
      return;
    }
    if (this.courseName.trim() === '') {
      this.toast('请输入除空格以外的课程名称');
      return;
    }
    if (this.place === '') {
      this.toast('请输入上课地点');
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
    // qsjsz = 周集升序","拼接（TreeSet/SP）；djj = start-SERVER("start-end")；xqj = day；skdd = 地点
    let qsjsz: string = '';
    for (let i = 0; i < this.weekSet.length; i++) {
      qsjsz += (i > 0 ? ',' : '') + this.weekSet[i];
    }
    ApiService.addPersonalCourse(this.courseName, qsjsz,
      this.startSection + '-' + this.endSection, String(this.day), this.place)
      .then((resp: ApiResponse<Object>) => {
        this.submitting = false;
        if (resp.code === 0 && ('' + resp.data) === '1') {
          this.toast('添加成功');
          router.back();
        } else if (resp.code === 0) {
          this.toast('添加失败');
        } else {
          // f 回调：网络/服务错误 toast（b1：空文案回退"连接不到网络，请稍后再试"）
          this.toast(resp.message === '' ? '连接不到网络，请稍后再试' : resp.message);
        }
      })
      .catch(() => {
        this.submitting = false;
        this.toast('连接不到网络，请稍后再试');
      });
  }

  // ===== UI =====

  /** 滚轮前后空白填充（setVisibleItems(7) 首尾可居中） */
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
        TextInput({ placeholder: '请输入课程名称', text: this.courseName })
          .fontSize(16)
          .fontColor($r('app.color.common_color_1'))
          .placeholderColor($r('app.color.edit_hint_color'))
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
        TextInput({ placeholder: '请输入上课地点', text: this.place })
          .fontSize(16)
          .fontColor($r('app.color.common_color_1'))
          .placeholderColor($r('app.color.edit_hint_color'))
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
          .fontColor(this.weekText === '' ? $r('app.color.edit_hint_color') : $r('app.color.common_color_1'))
          .layoutWeight(1)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      } else {
        Text(this.sectionText === '' ? '点击修改上课时间' : this.sectionText)
          .fontSize(16)
          .fontColor(this.sectionText === '' ? $r('app.color.edit_hint_color') : $r('app.color.common_color_1'))
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

  /** ChooseCourseWeeksDialog：标题+完成+单双全周勾选+自适应列周格（平板/横屏居中，手机底滑） */
  @Builder
  weekDialog() {
    Column() {
      Scroll() {
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
              .borderRadius(6)
              .backgroundColor($r('app.color.hover_grey'))
              .hoverEffect(HoverEffect.Highlight)
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
              .hoverEffect(HoverEffect.Highlight)
              .onClick(() => {
                if (this.oddChecked) {
                  this.selectNoneWeek();
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
              .hoverEffect(HoverEffect.Highlight)
              .onClick(() => {
                if (this.evenChecked) {
                  this.selectNoneWeek();
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
              .hoverEffect(HoverEffect.Highlight)
              .onClick(() => {
                if (this.allChecked) {
                  this.selectNoneWeek();
                } else {
                  this.selectAllWeeks();
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
                    topLeft: chosen && (index % this.getWeekGridCols() === 0 || index === 0 ||
                      !this.weekChosen[index - 1]) ? 14 : 0,
                    topRight: chosen && ((index + 1) % this.getWeekGridCols() === 0 ||
                      index === this.weekChosen.length - 1 || !this.weekChosen[index + 1]) ? 14 : 0,
                    bottomLeft: chosen && (index % this.getWeekGridCols() === 0 || index === 0 ||
                      !this.weekChosen[index - 1]) ? 14 : 0,
                    bottomRight: chosen && ((index + 1) % this.getWeekGridCols() === 0 ||
                      index === this.weekChosen.length - 1 || !this.weekChosen[index + 1]) ? 14 : 0
                  })
                  .padding({ top: 3, bottom: 3 })
              }
              .height(40)
              .hoverEffect(HoverEffect.Highlight)
              .onClick(() => {
                this.onWeekItemClick(index);
              })
            }, (chosen: boolean, index: number) => 'wk' + index + '_' + (chosen ? '1' : '0') + '_' + this.currentBreakpoint)
          }
          .columnsTemplate(AdaptiveLayoutHelper.buildColumnsTemplate(this.getWeekGridCols()))
          .width('100%')
          .height(AdaptiveLayoutHelper.computeGridHeightVp(this.weekChosen.length, this.getWeekGridCols(), 40, 0, 29))
          .padding({ left: 12, right: 12, top: 10, bottom: 19 })
        }
        .width('100%')
      }
      .width('100%')
      .constraintSize({
        maxWidth: AdaptiveLayoutHelper.getSheetMaxWidth(this.currentBreakpoint, this.windowWidthVp),
        maxHeight: BreakpointSystem.getDialogMaxHeight(this.windowHeightVp)
      })
      .backgroundColor($r('app.color.white'))
      .borderRadius(AdaptiveLayoutHelper.shouldUseCenterSheet(this.currentBreakpoint, this.isCompactHeight) ?
        12 : { topLeft: 12, topRight: 12 })
      .clip(true)
      .padding({
        bottom: AdaptiveLayoutHelper.shouldUseCenterSheet(this.currentBreakpoint, this.isCompactHeight) ?
          0 : this.avoidAreaBottomVp
      })
      .onClick(() => {
        // 拦截面板内点击
      })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#66000000')
    .alignItems(HorizontalAlign.Center)
    .justifyContent(AdaptiveLayoutHelper.shouldUseCenterSheet(this.currentBreakpoint, this.isCompactHeight) ?
      FlexAlign.Center : FlexAlign.End)
    .onClick(() => {
      this.showWeekDialog = false;
    })
  }

  /** ChooseCourseSectionDialog：标题+完成+周X|第X节|到|第X节 四段滚轮 */
  @Builder
  sectionDialog() {
    Column() {
      Scroll() {
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
              .borderRadius(6)
              .backgroundColor($r('app.color.hover_grey'))
              .hoverEffect(HoverEffect.Highlight)
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
      }
      .width('100%')
      .constraintSize({
        maxWidth: AdaptiveLayoutHelper.getSheetMaxWidth(this.currentBreakpoint, this.windowWidthVp),
        maxHeight: BreakpointSystem.getDialogMaxHeight(this.windowHeightVp)
      })
      .backgroundColor($r('app.color.white'))
      .borderRadius(AdaptiveLayoutHelper.shouldUseCenterSheet(this.currentBreakpoint, this.isCompactHeight) ?
        12 : { topLeft: 12, topRight: 12 })
      .clip(true)
      .padding({
        bottom: AdaptiveLayoutHelper.shouldUseCenterSheet(this.currentBreakpoint, this.isCompactHeight) ?
          0 : this.avoidAreaBottomVp
      })
      .onClick(() => {
        // 拦截面板内点击
      })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#66000000')
    .alignItems(HorizontalAlign.Center)
    .justifyContent(AdaptiveLayoutHelper.shouldUseCenterSheet(this.currentBreakpoint, this.isCompactHeight) ?
      FlexAlign.Center : FlexAlign.End)
    .onClick(() => {
      this.showSectionDialog = false;
    })
  }

  build() {
    Stack({ alignContent: Alignment.Bottom }) {
      Column() {
        TitleBar({ title: '自定义课程', showBack: true })
        Scroll() {
          Column() {
            // linear_course_ll_input_coursename：marginTop 12vp
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
            // edit_course_week_num_container：marginTop 15vp（px30/2）
            Column() {
              this.formRow($r('app.media.mobile_campus_schedule_class_b'), '课程周数', 'week')
            }
            .width('100%')
            .margin({ top: 15 })
            .hoverEffect(HoverEffect.Highlight)
            .onClick(() => {
              this.openWeekDialog();
            })
            Divider()
              .color($r('app.color.common_color_5'))
              .strokeWidth(0.5)
              .width('100%')
            Column() {
              this.formRow($r('app.media.mobile_campus_schedule_class_b'), '课程节数', 'section')
            }
            .width('100%')
            .hoverEffect(HoverEffect.Highlight)
            .onClick(() => {
              this.openSectionDialog();
            })
            Divider()
              .color($r('app.color.common_color_5'))
              .strokeWidth(0.5)
              .width('100%')
          }
          .width('100%')
          .constraintSize({ maxWidth: BreakpointSystem.getContentMaxWidth(this.currentBreakpoint) })
          .alignSelf(ItemAlign.Center)
        }
        .width('100%')
        .layoutWeight(1)
        .scrollBar(BarState.Off)

        // edit_course_tv_confirm_btn：selector enable #1B68B6（源码恒 enabled）
        Column() {
          Text('提交')
            .fontSize(16)
            .fontColor($r('app.color.white'))
            .width('100%')
            .height(40)
            .textAlign(TextAlign.Center)
            .borderRadius(4)
            .backgroundColor($r('app.color.mobile_campus_schedule_confirm_blue'))
            .hoverEffect(HoverEffect.Highlight)
            .onClick(() => {
              this.submit();
            })
        }
        .width('100%')
        .constraintSize({ maxWidth: BreakpointSystem.getContentMaxWidth(this.currentBreakpoint) })
        .alignSelf(ItemAlign.Center)
        .padding({ left: 12, right: 12, top: this.isCompactHeight ? 16 : 48, bottom: Math.max(27, this.avoidAreaBottomVp + 12) })
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
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.BOTTOM])
  }
}
