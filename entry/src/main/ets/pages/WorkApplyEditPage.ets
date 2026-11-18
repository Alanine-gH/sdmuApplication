import { router } from '@kit.ArkUI';
import { ApiService } from '../network/ApiService';
import { OaFormField } from '../model/OaTodoModel';
import { BusinessError } from '@kit.BasicServicesKit';
import { EmptyView } from '../components/EmptyView';

/**
 * 业务申请编辑页 — 1:1 翻译原 APK WorkApplyEditActivity.java(392行)：
 *
 * 【布局】mobile_campus_oa_activity_workapply_edit.xml：toolbar_normal("业务申请") +
 *   ScrollView[edit_container：detail_header(标题=bean.subject) + divider(12vp) + 动态表单] +
 *   btn_sure("提交" 17fp 白字 primary 底 padV12)。
 *
 * 【数据流源码还原】
 *   1. y(Intent)：u=bean(RowsBean)、x=data(WorkApplyDetail 形态，详情页 g 回调传入)；v=subject。
 *      【APK 原链】WorkApplyDetailActivity.todo_detail_edit(m) 按钮（f1 双分支 setVisibility(8)
 *      恒隐藏）→ a.T{applybean,data}；HAP 入参经 AppStorage 'workapply_edit_payload'。
 *   2. Q2()：p=标题（w 紧急程度源码无赋值 → 空 → 标签隐藏）；O2(x)：fieldType 分支渲染
 *      （a(bean) 空白带值）：INPUT(p)/SELECT(o)/CHECKBOX(d)/Radio(RadioBox)/DATE(f)/
 *      TEXTAREA(q)/single·multiUser·DeptPicker(j)；【O2 无 FILE/MEETING 分支 → 落 Log.e 跳过】；
 *      isTop(radio)+top(input) 关联（p.o(RadioBox)）；尾部灰条。
 *   3. btn_sure b → M2()：数据集空→"数据集为空"；逐字段 g() 失败 → hVar.b() 文案 toast；
 *      通过 → N2()（formatData 本地联动）→ setResult(-1){data:x} finish。
 *   4. onBackPressed → R2()：确认框"是否取消修改业务申请？" → g.a() finish。
 *   5. onActivityResult：1564 人员（a.G CarbonCopyListActivity）、1565 部门（a.D）、
 *      1569 文号（a.U）→ j.z(编码[], 名称[]) 回填。
 *
 * 【HAP 等价】入参 AppStorage 'workapply_edit_payload'{bean, form}；出参 AppStorage
 *   'workapply_edit_result'（formFieldConfigList JSON）+ router.back（消费方=处理页待翻译）。
 */

interface WorkApplyEditPayload {
  bean: object;
  form: OaFormField[];
}

/** select fieldRule [{id,text}] 单项 */
class KVOption {
  id: string = '';
  text: string = '';
}

/** picker 已选条目（Entry.java key=编码 value=名称） */
class ChipEntry {
  key: string = '';
  value: string = '';
}

/** 表单控件 VM（widget p/o/d/RadioBox/f/q/j 的可渲染状态包） */
class FormFieldVM {
  field: OaFormField = new OaFormField();
  options: KVOption[] = [];
  checks: boolean[] = [];
  radioPicked: string = '';
  chips: ChipEntry[] = [];
  dateDisplay: string = '';
  dateOutFmt: string = '';
  /** isTop(radio) ↔ top(input) 关联：置顶选中时天数必填 */
  linkTopRequired: boolean = false;
}

const CHECK_COLORS: string[] = ['#FF6C6C', '#FFCC31', '#82DC4B', '#31B4FF', '#1B68B7', '#9261C4'];

@Entry
@Component
struct WorkApplyEditPage {
  @State vms: FormFieldVM[] = [];
  @State headerTitle: string = '';
  @State showSelectDialog: boolean = false;
  @State selectVmIdx: number = -1;
  private payload: WorkApplyEditPayload | null = null;
  private topRadioIdx: number = -1;

  aboutToAppear(): void {
    const raw: string | undefined = AppStorage.get<string>('workapply_edit_payload');
    if (raw !== undefined && raw !== '') {
      this.consumePayload(raw);
    }
  }

  /** 源码 y(Intent)：bean/data 拆包 → Q2 标题 + O2 渲染 */
  private consumePayload(raw: string): void {
    try {
      const payload: WorkApplyEditPayload = JSON.parse(raw) as WorkApplyEditPayload;
      this.payload = payload;
      const beanRec: Record<string, Object> = payload.bean as Record<string, Object>;
      const subject: Object = beanRec['subject'];
      this.headerTitle = typeof subject === 'string' ? (subject as string) : '';
      this.buildForm(payload.form);
    } catch (error) {
      const err = error as BusinessError;
      ApiService.logError('WorkApplyEdit payload parse fail: ' + err.message);
    }
  }

  /** 源码 O2：7 类控件（FILE/MEETING 落 Log.e 跳过）+ isTop/top 关联 + 尾部灰条 */
  private buildForm(fields: OaFormField[]): void {
    const list: FormFieldVM[] = [];
    let topRadioIdx: number = -1;
    let topInputIdx: number = -1;
    for (const field of fields) {
      const vm: FormFieldVM | null = this.makeVm(field);
      if (vm === null) {
        continue;
      }
      if (field.fieldName === 'isTop' && field.fieldType === 'radio') {
        topRadioIdx = list.length;
      }
      if (field.fieldName === 'top' && field.fieldType === 'input') {
        topInputIdx = list.length;
      }
      list.push(vm);
    }
    if (topRadioIdx >= 0 && topInputIdx >= 0) {
      list[topInputIdx].linkTopRequired = true;
      this.topRadioIdx = topRadioIdx;
    }
    this.vms = list;
  }

  /** 源码 O2 if 链：input/select/checkbox/radio/date/textarea/picker，其余跳过 */
  private makeVm(field: OaFormField): FormFieldVM | null {
    const t: string = field.fieldType;
    if (t !== 'input' && t !== 'select' && t !== 'checkbox' && t !== 'radio' && t !== 'date' &&
      t !== 'textarea' && t !== 'singleUserPicker' && t !== 'multiUserPicker' &&
      t !== 'singleDeptPicker' && t !== 'multiDeptPicker') {
      ApiService.logError('WorkApplyEdit skip fieldType: ' + t);
      return null;
    }
    const vm: FormFieldVM = new FormFieldVM();
    vm.field = field;
    if (t === 'select') {
      this.fillSelectVm(vm);
    } else if (t === 'checkbox' || t === 'radio') {
      this.fillMapVm(vm);
    } else if (t === 'date') {
      this.fillDateVm(vm);
    } else {
      vm.chips = this.splitChips(field.fieldValue, field.fieldAnotherValue);
    }
    return vm;
  }

  /** 源码 o.e：fieldRule=[{id,text}] */
  private fillSelectVm(vm: FormFieldVM): void {
    const options: KVOption[] = [];
    try {
      const arr: Object = JSON.parse(vm.field.fieldRule) as Object;
      if (Array.isArray(arr)) {
        const rawArr: Object[] = arr as Object[];
        for (const one of rawArr) {
          const rec: Record<string, Object> = one as Record<string, Object>;
          const opt: KVOption = new KVOption();
          opt.id = this.strOf(rec, 'id');
          opt.text = this.strOf(rec, 'text');
          options.push(opt);
        }
      }
    } catch (error) {
      const err = error as BusinessError;
      ApiService.logError('WorkApplyEdit select rule parse fail: ' + err.message);
    }
    const selected: string[] = vm.field.fieldValue === '' ? [] : vm.field.fieldValue.split(',');
    const checks: boolean[] = [];
    for (const opt of options) {
      checks.push(selected.indexOf(opt.id) >= 0);
    }
    vm.checks = checks;
    vm.options = options;
  }

  /** 源码 d.e/radio.e：fieldRule={id:text} Map */
  private fillMapVm(vm: FormFieldVM): void {
    const options: KVOption[] = [];
    const checks: boolean[] = [];
    let radioPicked: string = '';
    try {
      const rec: Record<string, Object> = JSON.parse(vm.field.fieldRule) as Record<string, Object>;
      const selected: string[] = vm.field.fieldValue === '' ? [] : vm.field.fieldValue.split(',');
      for (const key of Object.keys(rec)) {
        const v: Object = rec[key];
        const text: string = typeof v === 'string' ? (v as string) : (typeof v === 'number' ? String(v as number) : '');
        const opt: KVOption = new KVOption();
        opt.id = key;
        opt.text = text;
        options.push(opt);
        checks.push(selected.indexOf(key) >= 0);
        if (vm.field.fieldType === 'radio' && key === vm.field.fieldValue) {
          radioPicked = text;
        }
      }
    } catch (error) {
      const err = error as BusinessError;
      ApiService.logError('WorkApplyEdit map rule parse fail: ' + err.message);
    }
    vm.options = options;
    vm.checks = checks;
    vm.radioPicked = radioPicked;
  }

  /** 源码 f.e：fieldRule={dataType,datePicker} */
  private fillDateVm(vm: FormFieldVM): void {
    try {
      const rec: Record<string, Object> = JSON.parse(vm.field.fieldRule) as Record<string, Object>;
      vm.dateOutFmt = this.strOf(rec, 'datePicker');
    } catch (error) {
      const err = error as BusinessError;
      ApiService.logError('WorkApplyEdit date rule parse fail: ' + err.message);
    }
    vm.dateDisplay = this.formatDate(vm.field.fieldValue, vm.dateOutFmt);
  }

  private formatDate(value: string, pattern: string): string {
    if (value === '') {
      return '---';
    }
    const m: RegExpMatchArray | null = value.trim()
      .match(/^(\d{4})[-/](\d{1,2})[-/](\d{1,2})(?:[ T](\d{1,2}):(\d{1,2})(?::(\d{1,2}))?)?$/);
    if (m === null || pattern === '') {
      return value;
    }
    let out: string = pattern;
    out = out.replace('yyyy', m[1]);
    out = out.replace('MM', this.pad2(m[2]));
    out = out.replace('dd', this.pad2(m[3]));
    out = out.replace('HH', m[4] === undefined ? '00' : this.pad2(m[4]));
    out = out.replace('mm', m[5] === undefined ? '00' : this.pad2(m[5]));
    out = out.replace('ss', m[6] === undefined ? '00' : this.pad2(m[6]));
    return out;
  }

  private pad2(v: string): string {
    const n: number = Number(v);
    return n < 10 ? '0' + String(n) : String(n);
  }

  private splitChips(ids: string, names: string): ChipEntry[] {
    const chips: ChipEntry[] = [];
    const idArr: string[] = ids === '' ? [] : ids.split(',');
    const nameArr: string[] = names === '' ? [] : names.split(',');
    const seen: string[] = [];
    for (let i = 0; i < idArr.length; i++) {
      if (seen.indexOf(idArr[i]) >= 0) {
        continue;
      }
      seen.push(idArr[i]);
      const chip: ChipEntry = new ChipEntry();
      chip.key = idArr[i];
      chip.value = i < nameArr.length ? nameArr[i] : '';
      chips.push(chip);
    }
    return chips;
  }

  private strOf(rec: Record<string, Object>, key: string): string {
    const v: Object = rec[key];
    if (typeof v === 'string') {
      return v as string;
    }
    if (typeof v === 'number') {
      return String(v as number);
    }
    return '';
  }

  // ===== 源码 M2()：必填校验（g() 失败 → hVar.b() 文案） =====
  private validateAll(): boolean {
    if (this.vms.length === 0) {
      this.toast('数据集为空');
      return false;
    }
    for (let i = 0; i < this.vms.length; i++) {
      const msg: string = this.validateVm(this.vms[i]);
      if (msg !== '') {
        this.toast(msg);
        return false;
      }
      this.readVmValue(this.vms[i]);
    }
    return true;
  }

  /** 控件 g() 失败文案（p/o/d/RadioBox/f/q/j.b） */
  private validateVm(vm: FormFieldVM): string {
    const f: OaFormField = vm.field;
    if (f.fieldType === 'input' && vm.linkTopRequired && this.topRadioIdx >= 0 &&
      this.vms[this.topRadioIdx].radioPicked !== '' && f.fieldValue.trim() === '') {
      return f.fieldValue === '' ? '请填写' + f.fieldScreenName : '请填写除空格以外的有效内容';
    }
    if (f.fieldNullable === 'true') {
      return '';
    }
    const t: string = f.fieldType;
    if (t === 'input' || t === 'textarea') {
      const v: string = f.fieldValue;
      if (v !== '' && v.trim() === '') {
        return '请填写除空格以外的有效内容';
      }
      if (v.trim() === '') {
        return '请填写' + f.fieldScreenName;
      }
      return '';
    }
    if (t === 'select' || t === 'singleUserPicker' || t === 'multiUserPicker' ||
      t === 'singleDeptPicker' || t === 'multiDeptPicker') {
      return f.fieldValue === '' ? f.fieldScreenName + '不能为空' : '';
    }
    if (t === 'checkbox') {
      return this.countChecks(vm) === 0 ? '需要填写' + f.fieldScreenName : '';
    }
    if (t === 'radio') {
      return vm.radioPicked === '' ? '需要填写' + f.fieldScreenName : '';
    }
    if (t === 'date') {
      return vm.dateDisplay === '' || vm.dateDisplay === '---' ? '请填写' + f.fieldScreenName : '';
    }
    return '';
  }

  /** 源码 getData()：UI 值写回 fieldValue/fieldAnotherValue */
  private readVmValue(vm: FormFieldVM): string {
    const f: OaFormField = vm.field;
    const t: string = f.fieldType;
    if (t === 'select') {
      let id: string = '';
      let text: string = '';
      for (let i = 0; i < vm.options.length; i++) {
        if (vm.checks[i]) {
          id = vm.options[i].id;
          text = vm.options[i].text;
        }
      }
      f.fieldValue = id;
      f.fieldAnotherValue = text;
      return id;
    }
    if (t === 'checkbox') {
      const ids: string[] = [];
      for (let i = 0; i < vm.options.length; i++) {
        if (vm.checks[i]) {
          ids.push(vm.options[i].id);
        }
      }
      f.fieldValue = ids.join(',');
      return f.fieldValue;
    }
    if (t === 'radio') {
      let id: string = '';
      for (const opt of vm.options) {
        if (opt.text === vm.radioPicked) {
          id = opt.id;
        }
      }
      f.fieldValue = id;
      return id;
    }
    if (t === 'date') {
      f.fieldValue = vm.dateDisplay === '---' ? '' : vm.dateDisplay;
      return f.fieldValue;
    }
    const keys: string[] = [];
    const vals: string[] = [];
    for (const chip of vm.chips) {
      keys.push(chip.key);
      vals.push(chip.value);
    }
    f.fieldValue = keys.join(',');
    f.fieldAnotherValue = vals.join(',');
    return f.fieldValue;
  }

  /** 源码 b.onClick：M2 → N2 → setResult{data} finish（AppStorage 管道等价） */
  private onSureClick(): void {
    if (!this.validateAll()) {
      return;
    }
    if (this.payload === null) {
      this.toast('数据集为空');
      return;
    }
    AppStorage.setOrCreate<string>('workapply_edit_result', JSON.stringify(this.payload.form));
    router.back();
  }

  /** 源码 R2()/d：返回确认框"是否取消修改业务申请？" */
  private confirmExit(): void {
    AlertDialog.show({
      message: '是否取消修改业务申请？',
      autoCancel: true,
      alignment: DialogAlignment.Center,
      primaryButton: {
        value: '取消',
        action: (): void => {
        }
      },
      secondaryButton: {
        value: '确定',
        action: (): void => {
          // 源码 d.a() → finish()
          router.back();
        }
      }
    });
  }

  private countChecks(vm: FormFieldVM): number {
    let count: number = 0;
    for (const c of vm.checks) {
      if (c) {
        count++;
      }
    }
    return count;
  }

  private toast(message: string): void {
    this.getUIContext().getPromptAction().showToast({ message: message });
  }

  /** 源码 a 回调：SINGLE/MULTI_USER → a.G 人员选择；SINGLE/MULTI_DEPT → a.D 部门选择 */
  private openPicker(vm: FormFieldVM): void {
    const t: string = vm.field.fieldType;
    if (t === 'singleDeptPicker' || t === 'multiDeptPicker') {
      router.pushUrl({ url: 'pages/TodoSearchDepartmentPage' });
      return;
    }
    router.pushUrl({ url: 'pages/CarbonCopyListPage' });
  }

  build() {
    Column() {
      this.topBar()
      if (this.vms.length === 0) {
        Column() {
          EmptyView({ tipText: '该流程无可编辑表单' })
        }
        .width('100%')
        .layoutWeight(1)
      } else {
        Scroll() {
          Column() {
            // detail_header：标题（紧急程度源码无赋值 → 标签区隐藏）
            Column() {
              Text(this.headerTitle === '' ? '-' : this.headerTitle)
                .fontSize(18.5)
                .fontWeight(FontWeight.Bold)
                .fontColor($r('app.color.common_color_1'))
                .maxLines(2)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
                .width('100%')
                .margin({ top: 12, bottom: 16 })
            }
            .width('100%')
            .padding({ left: 12, right: 12, top: 12 })
            Row()
              .width('100%')
              .height(12)
              .backgroundColor($r('app.color.common_color_6'))
            // edit_container 动态表单
            Column() {
              ForEach(this.vms, (vm: FormFieldVM, idx: number) => {
                this.fieldRow(vm, idx)
              }, (vm: FormFieldVM, idx: number) => idx.toString() + '-' + vm.field.fieldNumber.toString())
              Row()
                .width('100%')
                .height(12)
                .backgroundColor($r('app.color.common_color_6'))
            }
            .width('100%')
            .alignItems(HorizontalAlign.Start)
          }
          .width('100%')
        }
        .layoutWeight(1)
        .scrollBar(BarState.Off)
        .backgroundColor($r('app.color.common_color_6'))
        // btn_sure："提交" 17fp 白字 primary 底 padV12
        Text('提交')
          .fontSize(17)
          .fontColor($r('app.color.white'))
          .textAlign(TextAlign.Center)
          .width('100%')
          .padding({ top: 12, bottom: 12 })
          .backgroundColor($r('app.color.mobile_campus_primary_color_default'))
          .onClick(() => {
            this.onSureClick();
          })
      }
      if (this.showSelectDialog) {
        this.selectDialogOverlay()
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.white'))
  }

  /** toolbar_normal："业务申请"；返回键 → 确认框（源码 setNavigationOnClickListener → c → R2） */
  @Builder
  topBar() {
    Row() {
      Text('＜')
        .fontSize(17)
        .fontColor($r('app.color.common_color_1'))
        .width(40)
        .height('100%')
        .textAlign(TextAlign.Center)
        .margin({ left: 15 })
        .onClick(() => {
          this.confirmExit();
        })
      Text('业务申请')
        .fontSize(17)
        .fontColor($r('app.color.common_color_1'))
        .layoutWeight(1)
        .textAlign(TextAlign.Center)
        .maxLines(1)
      Blank().width(40)
    }
    .width('100%')
    .height(44)
    .alignItems(VerticalAlign.Center)
    .backgroundColor($r('app.color.main_bg'))
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP])
    Divider().color($r('app.color.common_color_5')).strokeWidth(0.5).width('100%')
  }

  /** 控件行骨架：label 列 80vp + 内容 + 底分隔线 */
  @Builder
  fieldRow(vm: FormFieldVM, idx: number) {
    Row() {
      Column() {
        Text('*')
          .fontSize(17)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.ybg_red'))
          .margin({ right: 4 })
          .visibility(vm.field.fieldNullable === 'true' ? Visibility.None : Visibility.Visible)
        Text(vm.field.fieldScreenName)
          .fontSize(16)
          .fontColor($r('app.color.common_color_3'))
      }
      .width(80)
      .alignItems(HorizontalAlign.Start)
      .margin({ right: 12 })
      Column() {
        this.fieldContent(vm, idx)
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .alignItems(VerticalAlign.Top)
    .padding({ left: 12, top: 15, right: 12 })
    Divider()
      .color($r('app.color.common_color_5'))
      .strokeWidth(0.5)
      .width('100%')
      .margin({ top: 16 })
  }

  @Builder
  fieldContent(vm: FormFieldVM, idx: number) {
    if (vm.field.fieldType === 'input') {
      this.inputContent(vm, idx)
    } else if (vm.field.fieldType === 'textarea') {
      this.textareaContent(vm, idx)
    } else if (vm.field.fieldType === 'select') {
      this.selectContent(vm)
    } else if (vm.field.fieldType === 'checkbox') {
      this.checkContent(vm)
    } else if (vm.field.fieldType === 'radio') {
      this.radioContent(vm)
    } else if (vm.field.fieldType === 'date') {
      this.dateContent(vm)
    } else {
      this.pickerContent(vm)
    }
  }

  /** p(SingleTextLayout)：subject maxLength20；"置顶天数"数字键盘 */
  @Builder
  inputContent(vm: FormFieldVM, idx: number) {
    TextInput({
      text: vm.field.fieldValue,
      placeholder: vm.field.fieldRemark === '' ? '请输入' + vm.field.fieldScreenName + '...' : vm.field.fieldRemark
    })
      .fontSize(16)
      .fontColor($r('app.color.common_color_1'))
      .placeholderColor('#B5B5B5')
      .placeholderFont({ size: 16 })
      .backgroundColor(Color.Transparent)
      .padding(0)
      .width('100%')
      .maxLength(vm.field.fieldName.toLowerCase() === 'subject' ? 20 : -1)
      .type(vm.field.fieldScreenName === '置顶天数' ? InputType.Number : InputType.Normal)
      .onChange((value: string) => {
        this.vms[idx].field.fieldValue = value;
      })
  }

  /** q(TextAreaLayout)：多行输入 */
  @Builder
  textareaContent(vm: FormFieldVM, idx: number) {
    TextArea({
      text: vm.field.fieldValue,
      placeholder: vm.field.fieldRemark === '' ? '请输入' + vm.field.fieldScreenName + '...' : vm.field.fieldRemark
    })
      .fontSize(16)
      .fontColor($r('app.color.common_color_1'))
      .placeholderColor('#B5B5B5')
      .placeholderFont({ size: 16 })
      .backgroundColor(Color.Transparent)
      .padding(0)
      .width('100%')
      .height(96)
      .onChange((value: string) => {
        this.vms[idx].field.fieldValue = value;
      })
  }

  /** o(SelectBoxLayout)：当前选项 + arrow + 弹层 */
  @Builder
  selectContent(vm: FormFieldVM) {
    Row() {
      Text(this.selectDisplay(vm))
        .fontSize(16)
        .fontColor($r('app.color.common_color_1'))
        .layoutWeight(1)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
      Image($r('app.media.arrow_right2'))
        .width(16)
        .height(16)
        .margin({ left: 8 })
    }
    .width('100%')
    .alignItems(VerticalAlign.Center)
    .onClick(() => {
      this.selectVmIdx = this.vmIndexOf(vm);
      this.showSelectDialog = true;
    })
  }

  private selectDisplay(vm: FormFieldVM): string {
    for (const opt of vm.options) {
      if (opt.id === vm.field.fieldValue) {
        return opt.text;
      }
    }
    return '';
  }

  /** d(CheckBoxLayout)：六色复选 chips */
  @Builder
  checkContent(vm: FormFieldVM) {
    Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.Start }) {
      ForEach(vm.options, (opt: KVOption, ci: number) => {
        Text(opt.text)
          .fontSize(15)
          .fontColor(vm.checks[ci] ? $r('app.color.white') : CHECK_COLORS[ci % 6])
          .backgroundColor(vm.checks[ci] ? CHECK_COLORS[ci % 6] : Color.Transparent)
          .border({
            width: vm.checks[ci] ? 0 : 0.5,
            color: CHECK_COLORS[ci % 6]
          })
          .padding({ left: 5, right: 5, top: 1.5, bottom: 1.5 })
          .margin({ right: 8, bottom: 8 })
          .onClick(() => {
            this.toggleCheck(this.vmIndexOf(vm), ci);
          })
      }, (opt: KVOption, ci: number) => ci.toString() + opt.id)
    }
    .width('100%')
  }

  private toggleCheck(vmIdx: number, optionIdx: number): void {
    const copy: FormFieldVM[] = this.vms.slice();
    copy[vmIdx].checks[optionIdx] = !copy[vmIdx].checks[optionIdx];
    this.vms = copy;
  }

  /** RadioBoxLayout：2 列单选 */
  @Builder
  radioContent(vm: FormFieldVM) {
    Column() {
      ForEach(vm.options, (opt: KVOption, ri: number) => {
        Row() {
          Circle({ width: 14, height: 14 })
            .fill(vm.radioPicked === opt.text ? $r('app.color.mobile_campus_primary_color_default') :
              Color.Transparent)
            .stroke(vm.radioPicked === opt.text ? $r('app.color.mobile_campus_primary_color_default') :
              $r('app.color.common_color_24'))
            .strokeWidth(1)
          Text(opt.text)
            .fontSize(15)
            .fontColor($r('app.color.common_color_1'))
            .margin({ left: 8 })
        }
        .width('50%')
        .padding({ top: 6, bottom: 6 })
        .alignItems(VerticalAlign.Center)
        .onClick(() => {
          this.pickRadio(this.vmIndexOf(vm), opt.text);
        })
      }, (opt: KVOption, ri: number) => ri.toString() + opt.id)
    }
    .width('100%')
  }

  private pickRadio(vmIdx: number, text: string): void {
    const vm: FormFieldVM = this.vms[vmIdx];
    if (vm.radioPicked === text && vm.options.length > 1) {
      return;
    }
    const copy: FormFieldVM[] = this.vms.slice();
    copy[vmIdx].radioPicked = copy[vmIdx].radioPicked === text ? '' : text;
    this.vms = copy;
  }

  /** f(DatePickLayout)：DatePickerDialog 365 天窗 */
  @Builder
  dateContent(vm: FormFieldVM) {
    Row() {
      Text(vm.dateDisplay)
        .fontSize(16)
        .fontColor($r('app.color.common_color_1'))
        .layoutWeight(1)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
      Image($r('app.media.arrow_right2'))
        .width(16)
        .height(16)
        .margin({ left: 8 })
    }
    .width('100%')
    .alignItems(VerticalAlign.Center)
    .onClick(() => {
      this.showDatePicker(this.vmIndexOf(vm));
    })
  }

  private showDatePicker(vmIdx: number): void {
    const vm: FormFieldVM = this.vms[vmIdx];
    const base: Date = new Date();
    const m: RegExpMatchArray | null = vm.dateDisplay.match(/^(\d{4})-(\d{2})-(\d{2})/);
    if (m !== null) {
      base.setFullYear(Number(m[1]));
      base.setMonth(Number(m[2]) - 1);
      base.setDate(Number(m[3]));
    }
    const minTime: Date = new Date(base.getTime() - 365 * 24 * 60 * 60 * 1000);
    const maxTime: Date = new Date(base.getTime() + 365 * 24 * 60 * 60 * 1000);
    DatePickerDialog.show({
      start: minTime,
      end: maxTime,
      selected: base,
      onDateAccept: (value: Date) => {
        const display: string = this.formatDate(
          value.getFullYear() + '-' + this.pad2(String(value.getMonth() + 1)) + '-' + this.pad2(String(value.getDate())),
          vm.dateOutFmt === '' ? 'yyyy-MM-dd' : vm.dateOutFmt);
        const copy: FormFieldVM[] = this.vms.slice();
        copy[vmIdx].dateDisplay = display;
        copy[vmIdx].field.fieldValue = display === '---' ? '' : display;
        this.vms = copy;
      }
    });
  }

  /** j(IntentTextLayout)：chips + 删除 + arrow → 选择器路由 */
  @Builder
  pickerContent(vm: FormFieldVM) {
    Column() {
      if (vm.chips.length === 0) {
        Text('请选择')
          .fontSize(16)
          .fontColor('#B5B5B5')
      }
      ForEach(vm.chips, (chip: ChipEntry, pi: number) => {
        Row() {
          Text(chip.value === '' ? chip.key : chip.value)
            .fontSize(16)
            .fontColor($r('app.color.common_color_1'))
            .layoutWeight(1)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
          Image($r('app.media.delete_icon'))
            .width(14)
            .height(14)
            .onClick(() => {
              this.removeChip(this.vmIndexOf(vm), pi);
            })
        }
        .width('100%')
        .padding({ top: 4, bottom: 4 })
      }, (chip: ChipEntry, pi: number) => pi.toString() + chip.key)
      Row() {
        Text('添加')
          .fontSize(16)
          .fontColor($r('app.color.mobile_campus_primary_color_default'))
        Image($r('app.media.arrow_right2'))
          .width(16)
          .height(16)
          .margin({ left: 8 })
      }
      .width('100%')
      .padding({ top: 4, bottom: 4 })
      .onClick(() => {
        this.openPicker(vm);
      })
    }
    .width('100%')
  }

  private removeChip(vmIdx: number, chipIdx: number): void {
    const copy: FormFieldVM[] = this.vms.slice();
    const rest: ChipEntry[] = [];
    for (let i = 0; i < copy[vmIdx].chips.length; i++) {
      if (i !== chipIdx) {
        rest.push(copy[vmIdx].chips[i]);
      }
    }
    copy[vmIdx].chips = rest;
    this.vms = copy;
  }

  private vmIndexOf(vm: FormFieldVM): number {
    for (let i = 0; i < this.vms.length; i++) {
      if (this.vms[i] === vm) {
        return i;
      }
    }
    return 0;
  }

  /** o → SocialDialog：fieldRule 选项列表，单选回填 */
  @Builder
  selectDialogOverlay() {
    Column() {
      Column() {
        Scroll() {
          Column() {
            ForEach(this.vms[this.selectVmIdx].options, (opt: KVOption, oi: number) => {
              Text(opt.text)
                .fontSize(16)
                .fontColor($r('app.color.common_color_1'))
                .width('100%')
                .padding({ top: 12, bottom: 12 })
                .textAlign(TextAlign.Center)
                .border({ width: { bottom: 0.5 }, color: $r('app.color.common_color_5') })
                .onClick(() => {
                  this.pickSelect(this.selectVmIdx, oi);
                })
            }, (opt: KVOption, oi: number) => oi.toString() + opt.id)
          }
          .width('100%')
        }
        .constraintSize({ maxHeight: 360 })
        Text('取消')
          .fontSize(15)
          .fontColor($r('app.color.common_color_3'))
          .width('100%')
          .textAlign(TextAlign.Center)
          .padding({ top: 12, bottom: 12 })
          .onClick(() => {
            this.showSelectDialog = false;
          })
      }
      .width('80%')
      .backgroundColor($r('app.color.white'))
      .borderRadius(8)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#80000000')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }

  private pickSelect(vmIdx: number, optionIdx: number): void {
    const copy: FormFieldVM[] = this.vms.slice();
    const opt: KVOption = copy[vmIdx].options[optionIdx];
    const checks: boolean[] = [];
    for (let i = 0; i < copy[vmIdx].options.length; i++) {
      checks.push(i === optionIdx);
    }
    copy[vmIdx].checks = checks;
    copy[vmIdx].field.fieldValue = opt.id;
    copy[vmIdx].field.fieldAnotherValue = opt.text;
    this.vms = copy;
    this.showSelectDialog = false;
  }
}
