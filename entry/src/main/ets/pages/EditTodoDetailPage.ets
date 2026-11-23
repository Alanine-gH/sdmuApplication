import { router } from '@kit.ArkUI';
import { ApiService } from '../network/ApiService';
import { ApiResponse } from '../model/ResponseModel';
import { OaFormField, OaTodoDetail } from '../model/OaTodoModel';
import { BusinessError } from '@kit.BasicServicesKit';
import { picker } from '@kit.CoreFileKit';
import { cameraPicker, camera } from '@kit.CameraKit';
import { Context, common } from '@kit.AbilityKit';
import { PdfView, pdfService, pdfViewManager } from '@kit.PDFKit';
import { LoadingView } from '../components/LoadingView';
import { EmptyView } from '../components/EmptyView';
import { FilePreviewHelper } from '../common/FilePreviewHelper';
import { BreakpointSystem } from '../common/BreakpointSystem';
import { AdaptiveLayoutHelper } from '../common/AdaptiveLayoutHelper';

/**
 * 待办编辑页 — 1:1 翻译原 APK EditTodoDetailActivity.java(746行)：
 *
 * 【页面结构】mobile_campus_oa_activity_edit_todoitem.xml：
 *   自定义头部 44vp：ivBack(nav_back_btn pad5) + tvTitle"编辑"(px_to_sp_37=18.5fp #333 居中)
 *   + 隐形占位图标；ScrollView：todoitem_detail_header（d3() 只显示 header_title，其余容器 gone）
 *   + divider(12vp) + edit_container 动态表单 + 底部 btn_sure（bg common_color_7=#18B4ED，
 *   白 17fp padT/B15vp"确定"）。
 *
 * 【数据流源码还原】
 *   1. y(Intent)：bean(RowsBean) → C=subject/D=nodeName/E=startTime/F=hj；data=TodoDetail
 *      （APK 原链 TodoDetailActivity(/todo/detail) j.onClick → /todo/edit 带
 *      bundle{bean, mainBean, data(TodoDetail)}；[W14] HAP 入口=TodoPage/TodoReadPage 条目点击，
 *      TodoDetail 改由 transactionDetails 管道拉取：GET {xlh, todo_type, currentnodeid} 同 E3 参数）
 *   2. c3(TodoDetail)：formFieldConfigList 按 fieldType 建控件（TodoViewType）：
 *      input(p)/file(FileUploadLayout)/select(o)/checkbox(d)/radio(RadioBoxLayout)/date(f)/
 *      textarea(q)/single·multi·User·DeptPicker(j)/docNumberPicker；fieldReadOnly=="true" 的字段
 *      不加入视图；"isTop"(radio)与"top"(input) 关联（p.o(RadioBoxLayout)：置顶选中必填天数）
 *   3. btn_sure(d.onClick)：R2() 必填校验（空 → 控件 b() 文案；正则 fieldCheck →
 *      "输入的{fieldScreenName}格式错误"）→ V2() formatData → setResult(-1, {data}) finish
 *      （[W14] HAP 等价 router.back 携参，消费方=处理页 TodoProcedurePage 待翻译）
 *   4. onBackPressed → e3()：确认框"是否取消修改待办？" → finish
 *   5. 选择器路由（b 回调）：single/multiUserPicker → e.a.G(CarbonCopyListActivity)；
 *      single/multiDeptPicker → e.a.D(TodoSearchDepartmentActivity)；docNumberPicker → e.a.U
 *      （HAP 对应占位页已路由，选中回填待各自翻译后接线）
 */
interface TodoNavParams {
  type: string;
  docUnid: string;
  processId: string;
  subject: string;
  hj: string;
  startTime: string;
  addName: string;
  nodeName: string;
  currentnodeid: string;
  authorCn: string;
}

/** select fieldRule [{id,text}] 单项（Entity.java） */
class KVOption {
  id: string = '';
  text: string = '';
}

/** user/dept/docNumber picker 已选条目（Entry.java key=编码 value=名称） */
class ChipEntry {
  key: string = '';
  value: string = '';
}

/** 表单控件 VM（widget p/o/d/RadioBox/f/q/j/FileUpload 的可渲染状态包） */
class FormFieldVM {
  field: OaFormField = new OaFormField();
  options: KVOption[] = [];
  checks: boolean[] = [];
  radioPicked: string = '';
  chips: ChipEntry[] = [];
  files: string[] = [];
  /** date 显示值（datePicker 格式化后） */
  dateDisplay: string = '';
  /** dataType/datePicker（date 字段 rule） */
  dateInFmt: string = '';
  dateOutFmt: string = '';
  /** isTop(radio) ↔ top(input) 关联：置顶选中时天数必填 */
  linkTopRequired: boolean = false;
  /** 源码 c3：readonly 字段同样 new 控件并 z.put（仅跳过 addView），R2 校验/V2 回传仍覆盖 */
  readonly: boolean = false;
}

const CHECK_COLORS: string[] = ['#FF6C6C', '#FFCC31', '#82DC4B', '#31B4FF', '#1B68B7', '#9261C4'];

@Entry
@Component
struct EditTodoDetailPage {
  @State vms: FormFieldVM[] = [];
  @State headerTitle: string = '';
  @State loading: boolean = true;
  @State failed: boolean = false;
  @State loadErrMsg: string = '';
  /** select 选项弹窗 */
  @State showSelectDialog: boolean = false;
  @State selectVmIdx: number = -1;
  @State showPdfModal: boolean = false;
  @State pdfTitle: string = '';
  @State pendingPdfPath: string = '';
  @StorageProp('currentBreakpoint') currentBreakpoint: string = 'sm';
  @StorageProp('windowWidthVp') windowWidthVp: number = 360;
  @StorageProp('windowHeightVp') windowHeightVp: number = 780;
  @StorageProp('avoidAreaBottomVp') avoidAreaBottomVp: number = 0;
  private navParams: TodoNavParams | null = null;
  /** [W23 oa-remain] C3 bmpurl（itemBasicInfoMap.bpmRequestRuleUrl），提交时入 edited_todo_nav */
  private bpmurl: string = '';
  /** isTop(radio) 在 vms 中的下标（top input 关联必填） */
  private topRadioIdx: number = -1;
  private pdfController: pdfViewManager.PdfController = new pdfViewManager.PdfController();

  aboutToDisappear(): void {
    this.closePdfModal();
  }

  private closePdfModal(): void {
    this.pendingPdfPath = '';
    if (this.showPdfModal) {
      this.showPdfModal = false;
      try {
        this.pdfController.releaseDocument();
      } catch {
        // 忽略释放异常
      }
    }
  }

  private async loadPendingPdf(): Promise<void> {
    const path: string = this.pendingPdfPath;
    if (path === '') {
      return;
    }
    try {
      const parseRes = await this.pdfController.loadDocument(path);
      if (parseRes !== pdfService.ParseResult.PARSE_SUCCESS) {
        this.toast('PDF 文档解析失败');
      }
    } catch {
      this.toast('PDF 文档加载失败');
    }
  }

  private async previewAttachedFile(filePathOrUri: string): Promise<void> {
    const trimmed: string = (filePathOrUri || '').trim();
    if (trimmed === '') {
      this.toast('附件路径为空');
      return;
    }
    const ctx = this.getUIContext().getHostContext() as common.UIAbilityContext;
    const title: string = this.fileNameOf(trimmed);
    const res = await FilePreviewHelper.openUriPreview(ctx, trimmed, title);
    if (res.success) {
      return;
    }
    if (res.method === 'pdfView' && res.localPath !== '') {
      this.pendingPdfPath = res.localPath;
      this.pdfTitle = title;
      this.showPdfModal = true;
      return;
    }
    this.toast(res.message !== '' ? res.message : '暂不支持打开该附件');
  }

  aboutToAppear(): void {
    const params: Object | undefined = router.getParams() as Object | undefined;
    if (params !== undefined && params !== null) {
      const rec: Record<string, Object> = params as Record<string, Object>;
      const p: TodoNavParams = {
        type: this.strOf(rec, 'type'),
        docUnid: this.strOf(rec, 'docUnid'),
        processId: this.strOf(rec, 'processId'),
        subject: this.strOf(rec, 'subject'),
        hj: this.strOf(rec, 'hj'),
        startTime: this.strOf(rec, 'startTime'),
        addName: this.strOf(rec, 'addName'),
        nodeName: this.strOf(rec, 'nodeName'),
        currentnodeid: this.strOf(rec, 'currentnodeid'),
        authorCn: this.strOf(rec, 'authorCn')
      };
      this.navParams = p;
      this.headerTitle = p.subject;
    }
    this.fetchDetail();
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

  /** 源码 TodoDetailActivity.E3 同款参数：GET transactionDetails {xlh, todo_type, currentnodeid} */
  private fetchDetail(): void {
    const p: TodoNavParams | null = this.navParams;
    if (p === null) {
      this.loading = false;
      this.failed = true;
      this.loadErrMsg = '缺少待办参数';
      return;
    }
    ApiService.getOaTodoDetail(p.docUnid, p.type, p.currentnodeid)
      .then((response: ApiResponse<OaTodoDetail>) => {
        if (response.code === 1000) {
          // 网络层统一拦截，页面仅 return
          return;
        }
        if (response.code === 0) {
          // [W23 oa-remain] C3 bmpurl 参数（itemBasicInfoMap.bpmRequestRuleUrl）
          this.bpmurl = response.data.itemBasicInfoMap.bpmRequestRuleUrl;
          this.buildForm(response.data);
          this.loading = false;
          this.failed = false;
        } else {
          this.loading = false;
          this.failed = true;
          this.loadErrMsg = response.message === '' ? '获取待办详情失败' : response.message;
        }
      })
      .catch((error: BusinessError) => {
        ApiService.logError('EditTodoDetail fetch fail: ' + error.message);
        this.loading = false;
        this.failed = true;
        this.loadErrMsg = '网络异常，请稍后重试';
      });
  }

  /** 源码 c3：按 fieldType 建控件（readonly 不渲染；未处理类型 log 跳过） */
  private buildForm(detail: OaTodoDetail): void {
    const list: FormFieldVM[] = [];
    let topRadioIdx: number = -1;
    let topInputIdx: number = -1;
    for (const field of detail.formFieldConfigList) {
      const vm: FormFieldVM | null = this.makeVm(field);
      if (vm === null) {
        continue;
      }
      // 源码 c3：readonly 字段只跳过 addView，控件仍入 z（R2 校验+getData 回传包含它）
      if (field.fieldReadOnly === 'true') {
        vm.readonly = true;
      }
      if (field.fieldName === 'isTop' && field.fieldType === 'radio') {
        topRadioIdx = list.length;
      }
      if (field.fieldName === 'top' && field.fieldType === 'input') {
        topInputIdx = list.length;
      }
      list.push(vm);
    }
    // 源码 c3 尾段：isTop(radio)+top(input) 关联（p.o(RadioBoxLayout)）
    if (topRadioIdx >= 0 && topInputIdx >= 0) {
      list[topInputIdx].linkTopRequired = true;
      this.topRadioIdx = topRadioIdx;
    }
    this.vms = list;
  }

  private makeVm(field: OaFormField): FormFieldVM | null {
    const t: string = field.fieldType;
    // 源码 c3 if 链仅含 4 个 picker 类型：docNumberPicker 落 else → Log.e 跳过（不渲染）
    if (t !== 'input' && t !== 'file' && t !== 'select' && t !== 'checkbox' && t !== 'radio' && t !== 'date' &&
      t !== 'textarea' && t !== 'singleUserPicker' && t !== 'multiUserPicker' && t !== 'singleDeptPicker' &&
      t !== 'multiDeptPicker') {
      // 源码 else 分支：Log.e("输出不处理的数据", ...)
      ApiService.logError('EditTodoDetail skip fieldType: ' + t);
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
    } else if (t === 'singleUserPicker' || t === 'multiUserPicker' || t === 'singleDeptPicker' ||
      t === 'multiDeptPicker') {
      vm.chips = this.splitChips(field.fieldValue, field.fieldAnotherValue);
    } else if (t === 'file') {
      vm.files = field.fieldValue === '' ? [] : field.fieldValue.split(',');
    }
    return vm;
  }

  /** 源码 o.e：fieldRule=[{id,text}]，当前显示=text(fieldValue 对应 id) */
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
      ApiService.logError('EditTodoDetail select rule parse fail: ' + err.message);
    }
    // 源码 o.e：fieldValue（可逗号多值）初始化已选集合 l，提交 getData 才不丢预填
    const selected: string[] = vm.field.fieldValue === '' ? [] : vm.field.fieldValue.split(',');
    const checks: boolean[] = [];
    for (const opt of options) {
      checks.push(selected.indexOf(opt.id) >= 0);
    }
    vm.checks = checks;
    vm.options = options;
  }

  /** 源码 d.e/radio.e：fieldRule={id:text} Map；checkbox 初始化勾选、radio 初始化选中文案 */
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
      ApiService.logError('EditTodoDetail map rule parse fail: ' + err.message);
    }
    vm.options = options;
    vm.checks = checks;
    vm.radioPicked = radioPicked;
  }

  /** 源码 f.e：fieldRule={dataType,datePicker,...}；显示=datePicker 格式（解析失败原样） */
  private fillDateVm(vm: FormFieldVM): void {
    try {
      const rec: Record<string, Object> = JSON.parse(vm.field.fieldRule) as Record<string, Object>;
      vm.dateInFmt = this.strOf(rec, 'dataType');
      vm.dateOutFmt = this.strOf(rec, 'datePicker');
    } catch (error) {
      const err = error as BusinessError;
      ApiService.logError('EditTodoDetail date rule parse fail: ' + err.message);
    }
    vm.dateDisplay = this.formatDate(vm.field.fieldValue, vm.dateOutFmt);
  }

  /** 简易日期解析（yyyy-MM-dd [HH:mm[:ss]]）+ 模式化输出；失败原样返回（源码 ParseException 分支） */
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

  /** 源码 j.e：fieldValue/fieldAnotherValue 逗号配对 → Entry[]（去重） */
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

  // ===== 源码 R2()/S2：必填 + 正则校验 =====
  private validateAll(): boolean {
    for (let i = 0; i < this.vms.length; i++) {
      const vm: FormFieldVM = this.vms[i];
      const msg: string = this.validateVm(vm);
      if (msg !== '') {
        this.toast(msg);
        return false;
      }
      const value: string = this.readVmValue(vm);
      if (vm.field.fieldCheck !== '' && value !== '' && !this.matchCheck(value, vm.field.fieldCheck)) {
        this.toast('输入的' + vm.field.fieldScreenName + '格式错误');
        return false;
      }
    }
    return true;
  }

  /** 控件 g() 失败文案（p/o/d/RadioBox/f/q/j/FileUpload.b） */
  private validateVm(vm: FormFieldVM): string {
    const f: OaFormField = vm.field;
    // 各控件 g() 的 l() 分支：readonly 必过（R2 仍会对 getData 跑 S2 正则）
    if (f.fieldReadOnly === 'true') {
      return '';
    }
    // 源码 p.g()：isTop 关联检查在 fieldNullable 之前（可空的"置顶天数"在选中置顶时也必填）
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
    if (t === 'select' || t === 'singleUserPicker' || t === 'multiUserPicker' || t === 'singleDeptPicker' ||
      t === 'multiDeptPicker' || t === 'docNumberPicker') {
      if (f.fieldValue === '') {
        return f.fieldScreenName + '不能为空';
      }
      return '';
    }
    if (t === 'checkbox') {
      if (this.countChecks(vm) === 0) {
        return '需要填写' + f.fieldScreenName;
      }
      return '';
    }
    if (t === 'radio') {
      if (vm.radioPicked === '') {
        return '需要填写' + f.fieldScreenName;
      }
      return '';
    }
    if (t === 'date') {
      if (vm.dateDisplay === '' || vm.dateDisplay === '---') {
        return '请填写' + f.fieldScreenName;
      }
      return '';
    }
    if (t === 'file') {
      if (vm.files.length === 0) {
        return '请上传附件';
      }
      return '';
    }
    return '';
  }

  private matchCheck(value: string, check: string): boolean {
    try {
      // 源码 S2 用 String.matches()：全串匹配；JS RegExp.test 为部分匹配，补锚点等价
      const re: RegExp = new RegExp('^(?:' + check + ')$');
      return re.test(value);
    } catch (error) {
      const err = error as BusinessError;
      ApiService.logError('EditTodoDetail fieldCheck invalid: ' + err.message);
      return true;
    }
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
    if (t === 'singleUserPicker' || t === 'multiUserPicker' || t === 'singleDeptPicker' ||
      t === 'multiDeptPicker' || t === 'docNumberPicker') {
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
    if (t === 'file') {
      f.fieldValue = vm.files.join(',');
      return f.fieldValue;
    }
    return f.fieldValue;
  }

  /** 源码 d.onClick：校验 → 写回 → 返回编辑结果（APK setResult 等价；HAP 消费方经 AppStorage 取参） */
  private onSureClick(): void {
    if (!this.validateAll()) {
      return;
    }
    // 源码 V2()：formatData 事件仅本地埋点/联动，无 UI 影响
    for (const vm of this.vms) {
      this.readVmValue(vm);
    }
    // router.back 无 params 形参（DepartmentListPage 'oa_dept_result' 同款 AppStorage 管道）
    AppStorage.setOrCreate('edited_todo_form', JSON.stringify(this.vms));
    // [W23 oa-remain] 处理页（TodoProcedureActivity）消费管道：C3 bundle 的 processid/unid/bmpurl
    // （源码 TodoDetailActivity.C3 → /todo/procedure；HAP 处理页 parseEditedTodo 读取）
    if (this.navParams !== null) {
      const nav: Record<string, string> = {
        'processid': this.navParams.processId,
        'unid': this.navParams.docUnid,
        'bmpurl': this.detailBpmUrl()
      };
      AppStorage.setOrCreate('edited_todo_nav', JSON.stringify(nav));
    }
    router.back();
  }

  /** TodoDetail.itemBasicInfoMap.bpmRequestRuleUrl（C3 bmpurl 参数） */
  private detailBpmUrl(): string {
    return this.bpmurl;
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

  /** 可编辑字段数（readonly 只入数据不渲染，空态判断用可编辑数） */
  private editableCount(): number {
    let count: number = 0;
    for (const vm of this.vms) {
      if (!vm.readonly) {
        count++;
      }
    }
    return count;
  }

  /** 源码 e3()：返回确认框 */
  private confirmExit(): void {
    AlertDialog.show({
      message: '是否取消修改待办？',
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
          // 源码 g.a() → finish()
          router.back();
        }
      }
    });
  }

  private toast(message: string): void {
    this.getUIContext().getPromptAction().showToast({ message: message });
  }

  /** 源码 b 回调：选择器路由（e.a.G/D/U） */
  private openPicker(vm: FormFieldVM): void {
    const t: string = vm.field.fieldType;
    if (t === 'singleUserPicker' || t === 'multiUserPicker') {
      router.pushUrl({ url: 'pages/CarbonCopyListPage' });
    } else if (t === 'singleDeptPicker' || t === 'multiDeptPicker') {
      router.pushUrl({ url: 'pages/TodoSearchDepartmentPage' });
    } else if (t === 'docNumberPicker') {
      router.pushUrl({ url: 'pages/DocNumberPage' });
    }
  }

  /** 源码 a(FileUploadLayout.f)+U2：btn_upload → ACTION_GET_CONTENT 等价 DocumentViewPicker */
  private async pickFile(vm: FormFieldVM): Promise<void> {
    if (vm.files.length >= 10) {
      return;
    }
    try {
      const docPicker: picker.DocumentViewPicker = new picker.DocumentViewPicker();
      const opts: picker.DocumentSelectOptions = new picker.DocumentSelectOptions();
      const uris: string[] = await docPicker.select(opts);
      const copy: FormFieldVM[] = this.vms.slice();
      for (const uri of uris) {
        copy[this.vmIndexOf(vm)].files.push(uri);
      }
      this.vms = copy;
    } catch (error) {
      const err = error as BusinessError;
      ApiService.logError('EditTodoDetail pickFile fail: ' + err.message);
    }
  }

  /** 源码 btn_camera → PictureSelector 拍照；HAP 等价 cameraPicker */
  private async takePhoto(vm: FormFieldVM): Promise<void> {
    if (vm.files.length >= 10) {
      return;
    }
    const ctx: Context | undefined = this.getUIContext().getHostContext();
    if (ctx === undefined) {
      this.toast('相机启动失败，请用"添加附件"选择文件');
      return;
    }
    try {
      const profile: cameraPicker.PickerProfile = new cameraPicker.PickerProfile();
      profile.cameraPosition = camera.CameraPosition.CAMERA_POSITION_BACK;
      const result: cameraPicker.PickerResult =
        await cameraPicker.pick(ctx, [cameraPicker.PickerMediaType.PHOTO], profile);
      if (result.resultUri !== '') {
        const copy: FormFieldVM[] = this.vms.slice();
        copy[this.vmIndexOf(vm)].files.push(result.resultUri);
        this.vms = copy;
      }
    } catch (error) {
      const err = error as BusinessError;
      ApiService.logError('EditTodoDetail camera fail: ' + err.message);
      this.toast('相机启动失败，请用"添加附件"选择文件');
    }
  }

  private vmIndexOf(vm: FormFieldVM): number {
    for (let i = 0; i < this.vms.length; i++) {
      if (this.vms[i] === vm) {
        return i;
      }
    }
    return 0;
  }

  build() {
    Stack() {
      Column() {
        this.topBar()
        if (this.loading) {
          LoadingView()
        } else if (this.failed) {
          Column() {
            EmptyView({ tipText: this.loadErrMsg === '' ? '加载失败，点击重试' : this.loadErrMsg })
          }
          .width('100%')
          .layoutWeight(1)
          .onClick(() => {
            this.loading = true;
            this.failed = false;
            this.fetchDetail();
          })
        } else {
          Scroll() {
            Column() {
              this.detailHeader()
              Row()
                .width('100%')
                .height(12)
                .backgroundColor($r('app.color.common_color_6'))
              this.formContainer()
            }
            .width('100%')
            .constraintSize({ maxWidth: BreakpointSystem.getContentMaxWidth(this.currentBreakpoint) })
          }
          .layoutWeight(1)
          .scrollBar(BarState.Off)
          Text('确定')
            .fontSize(17)
            .fontColor($r('app.color.white'))
            .textAlign(TextAlign.Center)
            .width('100%')
            .padding({ top: 15, bottom: Math.max(15, this.avoidAreaBottomVp + 10) })
            .backgroundColor($r('app.color.common_color_7'))
            .onClick(() => {
              this.onSureClick();
            })
        }
      }
      .width('100%')
      .height('100%')
      .backgroundColor($r('app.color.white'))

      if (this.showSelectDialog) {
        this.selectDialogOverlay()
      }
      if (this.showPdfModal) {
        this.pdfPreviewOverlay()
      }
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  pdfPreviewOverlay() {
    Column() {
      Column() {
        Row() {
          Text(this.pdfTitle)
            .fontSize(15)
            .fontWeight(FontWeight.Medium)
            .fontColor($r('app.color.common_color_1'))
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .layoutWeight(1)
          Text('关闭')
            .fontSize(14)
            .fontColor('#3A92ED')
            .padding({ left: 10, right: 4, top: 4, bottom: 4 })
            .onClick(() => {
              this.closePdfModal();
            })
        }
        .width('100%')
        .padding({ left: 14, right: 14, top: 10, bottom: 10 })
        .backgroundColor($r('app.color.white'))

        Divider().color($r('app.color.common_color_5')).strokeWidth(0.5).width('100%')

        PdfView({
          controller: this.pdfController,
          pageLayout: pdfService.PageLayout.LAYOUT_SINGLE,
          isContinuous: true,
          showScroll: true
        })
          .width('100%')
          .layoutWeight(1)
          .onAppear(() => {
            this.loadPendingPdf();
          })
      }
      .width(AdaptiveLayoutHelper.getDialogMaxWidth(this.currentBreakpoint, this.windowWidthVp))
      .height(AdaptiveLayoutHelper.getDialogMaxHeight(this.windowHeightVp))
      .backgroundColor($r('app.color.white'))
      .borderRadius(10)
      .clip(true)
      .onClick(() => {
        // 拦截点击
      })
    }
    .width('100%')
    .height('100%')
    .padding({ left: 16, right: 16 })
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .backgroundColor('#66000000')
    .onClick(() => {
      this.closePdfModal();
    })
  }

  /** 自定义头部 44vp：ivBack(nav_back_btn) + "编辑"18.5fp 居中 + 隐形占位 */
  @Builder
  topBar() {
    Row() {
      Image($r('app.media.nav_back_btn'))
        .width(28)
        .height(28)
        .padding(5)
        .margin({ left: 10 })
        .onClick(() => {
          // 源码 e.onClick/f.onClick/onBackPressed → e3() 确认框
          this.confirmExit();
        })
      Text('编辑')
        .fontSize(18.5)
        .fontColor($r('app.color.common_color_1'))
        .textAlign(TextAlign.Center)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .margin({ left: 10, right: 10 })
        .layoutWeight(1)
      Image($r('app.media.nav_back_btn'))
        .width(28)
        .height(28)
        .padding(5)
        .margin({ right: 10 })
        .opacity(0)
    }
    .width('100%')
    .height(44)
    .alignItems(VerticalAlign.Center)
    .backgroundColor($r('app.color.main_bg'))
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP])
  }

  /** todoitem_detail_header（d3()：仅 header_title 可见） */
  @Builder
  detailHeader() {
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
  }

  /** edit_container：非 readonly 字段按类型渲染 + 收尾分隔线 */
  @Builder
  formContainer() {
    Column() {
      if (this.editableCount() === 0) {
        Column() {
          EmptyView({ tipText: '该待办无可编辑表单' })
        }
        .width('100%')
        .padding({ top: 40, bottom: 40 })
      }
      ForEach(this.vms, (vm: FormFieldVM, idx: number) => {
        // 源码 c3：readonly 只建控件不 addView
        if (!vm.readonly) {
          this.fieldRow(vm, idx)
        }
      }, (vm: FormFieldVM, idx: number) => idx.toString() + '-' + vm.field.fieldNumber.toString())
      Divider()
        .color($r('app.color.common_color_5'))
        .strokeWidth(0.5)
        .width('100%')
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }

  /** 控件行骨架（各 widget layout 共形）：label 列 80vp + 内容 + 底分隔线 */
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
    } else if (vm.field.fieldType === 'file') {
      this.fileContent(vm)
    } else {
      this.pickerContent(vm)
    }
  }

  /** p(SingleTextLayout)：EditText 16fp #333；subject maxLength20；hint=remark 或 "请输入...” */
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
      .maxLength(this.inputMaxLength(vm))
      // 源码 p.e()：置顶天数 setInputType(2)=数字键盘（Normal=默认文本态）
      .type(vm.field.fieldScreenName === '置顶天数' ? InputType.Number : InputType.Normal)
      .onChange((value: string) => {
        this.vms[idx].field.fieldValue = value;
      })
  }

  /** 源码 p.e()：subject maxLength20；"置顶天数"数字键盘+最多 2 位 */
  private inputMaxLength(vm: FormFieldVM): number {
    if (vm.field.fieldName.toLowerCase() === 'subject') {
      return 20;
    }
    return vm.field.fieldScreenName === '置顶天数' ? 2 : -1;
  }

  /** q(TextAreaLayout)：minLines 4 多行输入 */
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

  /** o(SelectBoxLayout)：当前选项文案 + arrow_right2；点击弹 SocialDialog 选项 */
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

  /** d(CheckBoxLayout)：FlowLayout 六色复选 chips（选中实底白字，未选中描边彩字） */
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

  /** RadioBoxLayout：2 列单选（ToggleRadioButton 预选 fieldValue 对应文案） */
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
    // 源码 RadioHolder.enableToggle(itemCount==1)：仅单选项 radio 可再点取消
    if (vm.radioPicked === text && vm.options.length > 1) {
      return;
    }
    const copy: FormFieldVM[] = this.vms.slice();
    copy[vmIdx].radioPicked = copy[vmIdx].radioPicked === text ? '' : text;
    this.vms = copy;
  }

  /** f(DatePickLayout)：显示值 + arrow；DatePickerDialog 365 天窗（源码 e(ctx,365,...)） */
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
        this.vms = copy;
      }
    });
  }

  /** j(IntentTextLayout)：chips（编码=名称）+ 删除 + arrow → 选择器路由 */
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
          Text(chip.key === chip.value ? chip.value : chip.key + ' ' + chip.value)
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

  /** FileUploadLayout：附件行(delete_icon + 名称 16fp #1B68B7) + 添加附件 + 相机钮 */
  @Builder
  fileContent(vm: FormFieldVM) {
    Column() {
      ForEach(vm.files, (file: string, fi: number) => {
        Row() {
          Text(this.fileNameOf(file))
            .fontSize(16)
            .fontColor($r('app.color.mobile_campus_primary_color_default'))
            .layoutWeight(1)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .onClick(() => {
              this.previewAttachedFile(file);
            })
          Image($r('app.media.delete_icon'))
            .width(14)
            .height(14)
            .onClick(() => {
              this.removeFile(this.vmIndexOf(vm), fi);
            })
        }
        .width('100%')
        .padding({ bottom: 8 })
      }, (file: string, fi: number) => fi.toString() + file)
      Row() {
        Text('添加附件')
          .fontSize(16)
          .fontColor($r('app.color.mobile_campus_primary_color_default'))
          .layoutWeight(1)
          .onClick(() => {
            this.pickFile(vm);
          })
        // btn_camera（mobile_campus_oa_camera，拍照 59733 管线）
        Image($r('app.media.mobile_campus_oa_camera'))
          .width(24)
          .height(24)
          .onClick(() => {
            this.takePhoto(vm);
          })
      }
      .width('100%')
      // 源码 FileUploadLayout.z：满 10 个 → btn_upload GONE、btn_camera INVISIBLE
      .visibility(vm.files.length >= 10 ? Visibility.None : Visibility.Visible)
    }
    .width('100%')
  }

  private fileNameOf(path: string): string {
    const idx: number = path.lastIndexOf('/');
    return idx >= 0 ? path.substring(idx + 1) : path;
  }

  private removeFile(vmIdx: number, fileIdx: number): void {
    const copy: FormFieldVM[] = this.vms.slice();
    const rest: string[] = [];
    for (let i = 0; i < copy[vmIdx].files.length; i++) {
      if (i !== fileIdx) {
        rest.push(copy[vmIdx].files[i]);
      }
    }
    copy[vmIdx].files = rest;
    this.vms = copy;
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
                .padding({ top: 12, bottom: 12, left: 12, right: 12 })
                .textAlign(TextAlign.Center)
                .border({ width: { bottom: 0.5 }, color: $r('app.color.common_color_5') })
                .hoverEffect(HoverEffect.Highlight)
                .onClick(() => {
                  this.pickSelect(this.selectVmIdx, oi);
                })
            }, (opt: KVOption, oi: number) => oi.toString() + opt.id)
          }
          .width('100%')
        }
        .constraintSize({ maxHeight: Math.max(160, BreakpointSystem.getDialogMaxHeight(this.windowHeightVp) - 52) })
        .scrollBar(BarState.Off)
        Text('取消')
          .fontSize(15)
          .fontColor($r('app.color.common_color_3'))
          .width('100%')
          .textAlign(TextAlign.Center)
          .padding({ top: 12, bottom: 12 })
          .hoverEffect(HoverEffect.Highlight)
          .onClick(() => {
            this.showSelectDialog = false;
          })
      }
      .width(BreakpointSystem.getDialogMaxWidth(this.currentBreakpoint, this.windowWidthVp))
      .constraintSize({ maxHeight: BreakpointSystem.getDialogMaxHeight(this.windowHeightVp) })
      .backgroundColor($r('app.color.white'))
      .borderRadius(8)
      .clip(true)
      .onClick(() => {
        // 拦截弹窗卡片点击事件
      })
    }
    .width('100%')
    .height('100%')
    .padding({ left: 16, right: 16 })
    .backgroundColor('#66000000')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .onClick(() => {
      this.showSelectDialog = false;
    })
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
