import { router } from '@kit.ArkUI';
import { ApiService } from '../network/ApiService';
import { ApiResponse } from '../model/ResponseModel';
import { OaFormField, OaWorkApplyDetail } from '../model/OaTodoModel';
import { BusinessError } from '@kit.BasicServicesKit';
import { picker } from '@kit.CoreFileKit';
import { cameraPicker, camera } from '@kit.CameraKit';
import { Context } from '@kit.AbilityKit';
import { LoadingView } from '../components/LoadingView';
import { EmptyView } from '../components/EmptyView';

/**
 * 业务申请表单填写页 — 1:1 翻译原 APK WorkApplyFormConfigActivity.java(804行)：
 *
 * 【布局】mobile_campus_oa_activity_workapply_formconfig.xml：toolbar_normal(title||"业务申请") +
 *   MultiStateView(loading/empty/error/content)[RelativeLayout[ScrollView(bg common_color_6)
 *   [edit_container 白底 + 头部 12vp 灰条] + apply_submit("提交" 17fp primary 白底 padV10)]]。
 *
 * 【数据流源码还原】
 *   1. y(Intent)：s=processid、t=title（空→toolbar "业务申请"）。
 *   2. e3(s)：ApplyModel.V0 → GET formConfig {processid} → WorkApplyDetail{formFieldConfigList,
 *      itemBasicInfoMap.bpmRequestRuleUrl}；g→m3 渲染+v(content)；f→s2 空态（-3010→error）；
 *      e→u2 loading。
 *   3. m3()：fieldName 为 map key，fieldType 分支渲染：input(p)/select(o)/checkbox(d)/
 *      radio(RadioBox)/date(f+B 回调)/textarea(q)/single·multi User·DeptPicker(j)/
 *      file(FileUploadLayout)/meetingPicker(i)；docNumberPicker 亦走 j（c 回调 U 路由）；
 *      isTop(radio)+top(input) 关联（p.o(RadioBox)：置顶选中必填天数）；尾部灰条。
 *   4. apply_submit f → W2()：数据集空→"数据集为空"；逐字段 g() 必填文案 hVar.b() +
 *      Y2(fieldCheck 正则)→"输入的{fieldScreenName}格式错误"；X2() 时间先后（noticeTime/
 *      loseefficacyTime 或 START_TIME/END_TIME，f.z：前者>后者 toast"{A}不能晚于{B}"）。
 *   5. b3()：formatData（本地联动）；c3()：SUBJECT(subject)/picker relevance 键(fileRule)/
 *      file→SubmitFileBean{filePath,fileName,keyName:"selectfile"}→AllSubmitFileBean{fdName}/
 *      MEETING fieldName 拆"," + 各"_show"/select fieldName+"_show"/read 跳过；bundle{data map,
 *      processid, bmpurl, allSubmitFiles} → h2(a.L 流程处理页) 5348 → 返回 -1 → setResult+finish。
 *
 * 【HAP 等价】控件矩阵复用 EditTodoDetailPage 模式；提交 bundle 经 AppStorage
 *   'workapply_submit_bundle' → TodoProcedureOtherPage（a.L 路由等价，处理页其它 worker 负责）；
 *   meeting 字段 chips + 点击 → MeetingSelectorPage（源码 a.V 路由等价）。
 */

interface WorkApplyNavParams {
  processid: string;
  title: string;
}

/** select fieldRule [{id,text}] 单项 */
class KVOption {
  id: string = '';
  text: string = '';
}

/** user/dept/docNumber picker 已选条目（Entry.java key=编码 value=名称） */
class ChipEntry {
  key: string = '';
  value: string = '';
}

/** 表单控件 VM（widget p/o/d/RadioBox/f/q/j/FileUpload/i 的可渲染状态包） */
class FormFieldVM {
  field: OaFormField = new OaFormField();
  options: KVOption[] = [];
  checks: boolean[] = [];
  radioPicked: string = '';
  chips: ChipEntry[] = [];
  files: string[] = [];
  /** date 显示值（datePicker 格式化后） */
  dateDisplay: string = '';
  dateOutFmt: string = '';
  /** isTop(radio) ↔ top(input) 关联：置顶选中时天数必填 */
  linkTopRequired: boolean = false;
}

/** AllSubmitFileBean/SubmitFileBean（c3 文件提交结构） */
class SubmitFileGroup {
  fdName: string = '';
  filePaths: string[] = [];
}

const CHECK_COLORS: string[] = ['#FF6C6C', '#FFCC31', '#82DC4B', '#31B4FF', '#1B68B7', '#9261C4'];

@Entry
@Component
struct WorkApplyFormConfigPage {
  @State vms: FormFieldVM[] = [];
  @State pageTitle: string = '业务申请';
  @State loading: boolean = true;
  @State failed: boolean = false;
  @State loadErrMsg: string = '';
  @State showSelectDialog: boolean = false;
  @State selectVmIdx: number = -1;
  private navParams: WorkApplyNavParams = { processid: '', title: '' };
  private bmpurl: string = '';
  private topRadioIdx: number = -1;
  /** 源码 5348 返回 -1 → setResult+finish 标记 */
  private submitted: boolean = false;

  aboutToAppear(): void {
    const params: Object | undefined = router.getParams() as Object | undefined;
    if (params !== undefined && params !== null) {
      const rec: Record<string, Object> = params as Record<string, Object>;
      this.navParams.processid = this.strOf(rec, 'processid');
      this.navParams.title = this.strOf(rec, 'title');
    }
    if (this.navParams.title !== '') {
      this.pageTitle = this.navParams.title;
    }
    this.fetchConfig();
  }

  /** 源码 5348 返回 -1（流程处理页完成）→ setResult+finish */
  onPageShow(): void {
    if (this.submitted) {
      router.back();
    }
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

  /** 源码 e3：GET formConfig {processid} → WorkApplyDetail */
  private fetchConfig(): void {
    ApiService.getWorkApplyFormConfig(this.navParams.processid)
      .then((response: ApiResponse<OaWorkApplyDetail>) => {
        if (response.code === 1000) {
          return;
        }
        if (response.code === 0) {
          this.bmpurl = response.data.bpmRequestRuleUrl;
          this.buildForm(response.data.formFieldConfigList);
          this.loading = false;
          this.failed = false;
        } else {
          this.loading = false;
          this.failed = true;
          this.loadErrMsg = response.message === '' ? '获取表单配置失败' : response.message;
        }
      })
      .catch((error: BusinessError) => {
        ApiService.logError('WorkApplyFormConfig fetch fail: ' + error.message);
        this.loading = false;
        this.failed = true;
        this.loadErrMsg = '网络异常，请稍后重试';
      });
  }

  /** 源码 m3：按 fieldType 建控件（fieldName 为键；isTop/top 关联；未处理类型 log 跳过） */
  private buildForm(fields: OaFormField[]): void {
    const list: FormFieldVM[] = [];
    let topRadioIdx: number = -1;
    let topInputIdx: number = -1;
    for (const field of fields) {
      const vm: FormFieldVM | null = this.makeVm(field, fields);
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
    // 源码 m3 尾段：isTop(radio)+top(input) 关联（p.o(RadioBoxLayout)）
    if (topRadioIdx >= 0 && topInputIdx >= 0) {
      list[topInputIdx].linkTopRequired = true;
      this.topRadioIdx = topRadioIdx;
    }
    this.vms = list;
  }

  /** 源码 m3 if 链：仅 9 类渲染，其余 Log.e 跳过；picker 类 relevance 预填（i3） */
  private makeVm(field: OaFormField, fields: OaFormField[]): FormFieldVM | null {
    const t: string = field.fieldType;
    if (t !== 'input' && t !== 'file' && t !== 'select' && t !== 'checkbox' && t !== 'radio' &&
      t !== 'date' && t !== 'textarea' && t !== 'meetingPicker' &&
      t !== 'singleUserPicker' && t !== 'multiUserPicker' && t !== 'singleDeptPicker' &&
      t !== 'multiDeptPicker' && t !== 'docNumberPicker') {
      ApiService.logError('WorkApplyFormConfig skip fieldType: ' + t);
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
      t === 'multiDeptPicker' || t === 'docNumberPicker') {
      this.fillRelevance(field, fields);
      vm.chips = this.splitChips(field.fieldValue, field.fieldAnotherValue);
    } else if (t === 'meetingPicker') {
      this.fillRelevance(field, fields);
      // 源码 widget i.e：Entry.key=fieldValue 配 Entry.value=fieldAnotherValue（逗号配对）
      vm.chips = this.splitChips(field.fieldValue, field.fieldAnotherValue);
    } else if (t === 'file') {
      vm.files = field.fieldValue === '' ? [] : field.fieldValue.split(',');
    }
    return vm;
  }

  /** 源码 i3：fieldRule.relevance → 从同表单取对应字段值入 fieldAnotherValue */
  private fillRelevance(field: OaFormField, fields: OaFormField[]): void {
    if (field.fieldRule === '') {
      return;
    }
    let relevance: string = '';
    try {
      const rec: Record<string, Object> = JSON.parse(field.fieldRule) as Record<string, Object>;
      const v: Object = rec['relevance'];
      if (typeof v === 'string') {
        relevance = v as string;
      }
    } catch (error) {
      const err = error as BusinessError;
      ApiService.logError('WorkApplyFormConfig relevance parse fail: ' + err.message);
    }
    if (relevance === '') {
      return;
    }
    for (const other of fields) {
      if (other.fieldName === relevance) {
        field.fieldAnotherValue = other.fieldValue;
        return;
      }
    }
  }

  /** 源码 o.e：fieldRule=[{id,text}]，fieldValue 逗号多值初始化已选集合 */
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
      ApiService.logError('WorkApplyFormConfig select rule parse fail: ' + err.message);
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
      ApiService.logError('WorkApplyFormConfig map rule parse fail: ' + err.message);
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
      ApiService.logError('WorkApplyFormConfig date rule parse fail: ' + err.message);
    }
    vm.dateDisplay = this.formatDate(vm.field.fieldValue, vm.dateOutFmt);
  }

  /** 简易日期解析 + 模式化输出；失败原样返回（源码 ParseException 分支） */
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

  // ===== 源码 W2()：必填 + 正则 + 时间先后校验 =====
  private validateAll(): boolean {
    if (this.vms.length === 0) {
      this.toast('数据集为空');
      return false;
    }
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
    return this.validateTimeOrder();
  }

  /** 控件 g() 失败文案（p/o/d/RadioBox/f/q/j/FileUpload/i.b） */
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
      t === 'singleDeptPicker' || t === 'multiDeptPicker' || t === 'docNumberPicker' ||
      t === 'meetingPicker') {
      // 源码 o/j/i.b：fieldScreenName+"不能为空"（i.g() 同 j.g()：fieldValue 空即失败）
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
    if (t === 'file') {
      return vm.files.length === 0 ? '请上传附件' : '';
    }
    return '';
  }

  /** 源码 Y2：fieldCheck 正则（String.matches 全串匹配） */
  private matchCheck(value: string, check: string): boolean {
    try {
      const re: RegExp = new RegExp('^(?:' + check + ')$');
      return re.test(value);
    } catch (error) {
      const err = error as BusinessError;
      ApiService.logError('WorkApplyFormConfig fieldCheck invalid: ' + err.message);
      return true;
    }
  }

  /** 源码 X2：noticeTime/loseefficacyTime 或 START_TIME/END_TIME（f.z：前者不能晚于后者） */
  private validateTimeOrder(): boolean {
    const early: number = this.vmIdxByName('noticeTime');
    const late: number = this.vmIdxByName('loseefficacyTime');
    if (early >= 0 && late >= 0) {
      return this.checkDateOrder(early, late);
    }
    const start: number = this.vmIdxByName('START_TIME');
    const end: number = this.vmIdxByName('END_TIME');
    if (start >= 0 && end >= 0) {
      return this.checkDateOrder(start, end);
    }
    return true;
  }

  private vmIdxByName(name: string): number {
    for (let i = 0; i < this.vms.length; i++) {
      if (this.vms[i].field.fieldName === name) {
        return i;
      }
    }
    return -1;
  }

  /** 源码 f.z：this 显示时间 > other → toast"{A}不能晚于{B}" 返回 false */
  private checkDateOrder(earlyIdx: number, lateIdx: number): boolean {
    const early: string = this.vms[earlyIdx].dateDisplay;
    const late: string = this.vms[lateIdx].dateDisplay;
    if (early === '' || late === '' || early === '---' || late === '---') {
      return true;
    }
    const earlyMs: number = Date.parse(early.replace(' ', 'T'));
    const lateMs: number = Date.parse(late.replace(' ', 'T'));
    if (Number.isNaN(earlyMs) || Number.isNaN(lateMs)) {
      return true;
    }
    if (earlyMs > lateMs) {
      this.toast(this.vms[earlyIdx].field.fieldScreenName + '不能晚于' + this.vms[lateIdx].field.fieldScreenName);
      return false;
    }
    return true;
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
      t === 'multiDeptPicker' || t === 'docNumberPicker' || t === 'meetingPicker') {
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

  /** 源码 f.onClick：W2 → b3(formatData) → c3(bundle) → a.L 流程处理页 5348 */
  private onSubmitClick(): void {
    if (!this.validateAll()) {
      return;
    }
    for (const vm of this.vms) {
      this.readVmValue(vm);
    }
    this.pushProcedure();
  }

  /** 源码 c3()：SUBJECT/picker relevance/file→selectfile/MEETING 拆分/select _show → a.L */
  private pushProcedure(): void {
    const map: Record<string, string> = {};
    const fileGroups: SubmitFileGroup[] = [];
    for (const vm of this.vms) {
      const f: OaFormField = vm.field;
      const t: string = f.fieldType;
      if ('subject'.toLowerCase() === f.fieldName.toLowerCase()) {
        map['SUBJECT'] = f.fieldValue;
      } else if (t === 'singleUserPicker' || t === 'multiUserPicker' || t === 'singleDeptPicker' ||
        t === 'multiDeptPicker' || t === 'docNumberPicker') {
        map[f.fieldName] = f.fieldValue;
        const rel: string = this.relevanceOf(f);
        if (rel !== '') {
          map[rel] = f.fieldAnotherValue;
        }
      } else if (t === 'file') {
        this.collectFileGroup(f, fileGroups);
      } else if (t.toLowerCase() === 'read') {
        // 源码 READ 类型跳过
      } else if (t === 'meetingPicker') {
        this.collectMeetingMap(f, map);
      } else if (t === 'select') {
        map[f.fieldName] = f.fieldValue;
        map[f.fieldName + '_show'] = f.fieldAnotherValue;
      } else {
        map[f.fieldName] = f.fieldValue;
      }
    }
    const bundle: Record<string, Object> = {
      'data': map as Object,
      'processid': this.navParams.processid,
      'bmpurl': this.bmpurl,
      'allSubmitFiles': fileGroups as Object
    };
    AppStorage.setOrCreate<string>('workapply_submit_bundle', JSON.stringify(bundle));
    this.submitted = true;
    router.pushUrl({ url: 'pages/TodoProcedureOtherPage' });
  }

  /** 源码 f3：fieldRule.relevance 键名 */
  private relevanceOf(field: OaFormField): string {
    if (field.fieldRule === '') {
      return '';
    }
    try {
      const rec: Record<string, Object> = JSON.parse(field.fieldRule) as Record<string, Object>;
      const v: Object = rec['relevance'];
      return typeof v === 'string' ? (v as string) : '';
    } catch (error) {
      const err = error as BusinessError;
      ApiService.logError('WorkApplyFormConfig relevanceOf fail: ' + err.message);
      return '';
    }
  }

  /** 源码 FILE 分支：filePath 拆"," → SubmitFileBean{filePath,fileName,keyName:"selectfile"} */
  private collectFileGroup(field: OaFormField, groups: SubmitFileGroup[]): void {
    if (field.fieldValue === '') {
      return;
    }
    const paths: string[] = field.fieldValue.split(',');
    const group: SubmitFileGroup = new SubmitFileGroup();
    group.fdName = field.fieldName;
    for (const p of paths) {
      if (p !== '') {
        group.filePaths.push(p);
      }
    }
    if (group.filePaths.length > 0) {
      groups.push(group);
    }
  }

  /** 源码 MEETING 分支：fieldName/fieldValue/fieldAnotherValue 按","拆 → key + key_show */
  private collectMeetingMap(field: OaFormField, map: Record<string, string>): void {
    const names: string[] = field.fieldName.split(',');
    const values: string[] = field.fieldValue.split(',');
    const shows: string[] = field.fieldAnotherValue.split(',');
    for (let i = 0; i < names.length; i++) {
      map[names[i].trim()] = i < values.length ? values[i] : '';
      map[names[i].trim() + '_show'] = i < shows.length ? shows[i] : '';
    }
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

  /** 源码 c 回调：选择器路由（e.a.G/D/U） */
  private openPicker(vm: FormFieldVM): void {
    const t: string = vm.field.fieldType;
    if (t === 'singleUserPicker' || t === 'multiUserPicker') {
      router.pushUrl({ url: 'pages/CarbonCopyListPage' });
    } else if (t === 'singleDeptPicker' || t === 'multiDeptPicker') {
      router.pushUrl({ url: 'pages/TodoSearchDepartmentPage' });
    } else if (t === 'docNumberPicker') {
      router.pushUrl({ url: 'pages/DocNumberPage' });
    } else if (t === 'meetingPicker') {
      // 源码 e 回调：a.V 会议室选择 1570（i.r(entries) 回填管道待 MeetingSelectorPage 接线）
      router.pushUrl({ url: 'pages/MeetingSelectorPage' });
    }
  }

  /** 源码 a(FileUploadLayout.f)+a3：btn_upload → ACTION_GET_CONTENT 等价 DocumentViewPicker */
  private async pickFile(vm: FormFieldVM): Promise<void> {
    if (vm.files.length >= 10) {
      return;
    }
    try {
      const docPicker: picker.DocumentViewPicker = new picker.DocumentViewPicker();
      const opts: picker.DocumentSelectOptions = new picker.DocumentSelectOptions();
      const uris: string[] = await docPicker.select(opts);
      const copy: FormFieldVM[] = this.vms.slice();
      copy[this.vmIndexOf(vm)].files = copy[this.vmIndexOf(vm)].files.concat(uris);
      this.vms = copy;
    } catch (error) {
      const err = error as BusinessError;
      ApiService.logError('WorkApplyFormConfig pickFile fail: ' + err.message);
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
      ApiService.logError('WorkApplyFormConfig camera fail: ' + err.message);
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
          this.fetchConfig();
        })
      } else {
        Scroll() {
          Column() {
            // edit_container：头部 12vp 灰条 + 动态表单 + 尾部灰条
            Row()
              .width('100%')
              .height(12)
              .backgroundColor($r('app.color.common_color_6'))
            Column() {
              if (this.vms.length === 0) {
                Column() {
                  EmptyView({ tipText: '该流程暂无可填写的表单项' })
                }
                .width('100%')
                .padding({ top: 40, bottom: 40 })
              }
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
        // apply_submit："提交" 17fp primary 白底 padV10
        Text('提交')
          .fontSize(17)
          .fontColor($r('app.color.mobile_campus_primary_color_default'))
          .textAlign(TextAlign.Center)
          .width('100%')
          .padding({ top: 10, bottom: 10 })
          .backgroundColor($r('app.color.white'))
          .onClick(() => {
            this.onSubmitClick();
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

  /** toolbar_normal：title（空→"业务申请"） */
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
          router.back();
        })
      Text(this.pageTitle)
        .fontSize(17)
        .fontColor($r('app.color.common_color_1'))
        .layoutWeight(1)
        .textAlign(TextAlign.Center)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
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
    } else if (vm.field.fieldType === 'file') {
      this.fileContent(vm)
    } else {
      this.pickerContent(vm)
    }
  }

  /** p(SingleTextLayout)：EditText 16fp；subject maxLength20；"置顶天数"数字键盘 */
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

  /** o(SelectBoxLayout)：当前选项文案 + arrow_right2 + SocialDialog 选项弹层 */
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

  /** d(CheckBoxLayout)：FlowLayout 六色复选 chips */
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

  /** f(DatePickLayout)：显示值 + arrow；DatePickerDialog 365 天窗 */
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

  /** j(IntentTextLayout)/i(MeetingLayout)：chips + 删除 + arrow → 选择器路由 */
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

  /** FileUploadLayout：附件行 + 添加附件 + 相机钮（满 10 隐藏添加区） */
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
        Image($r('app.media.mobile_campus_oa_camera'))
          .width(24)
          .height(24)
          .onClick(() => {
            this.takePhoto(vm);
          })
      }
      .width('100%')
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
