import { router } from '@kit.ArkUI';
import { ApiService } from '../network/ApiService';
import { ApiResponse } from '../model/ResponseModel';
import { TodoFormExtract, ProcFileGroupPlain } from '../network/ApiService';
import { HttpClient } from '../network/HttpClient';
import { LoginSession } from '../network/LoginSession';
import { OaSubDeptUser, OaReturnToAnyNode, OaTodoOpenProcess, OaCurrentNodeConfig,
  OaNextNodeConfig, OaNextNodeUser, OaProcessButton, OaRunProcessResult } from '../model/OaTodoModel';
import { TitleBar } from '../components/TitleBar';
import { LoadingView } from '../components/LoadingView';
import { EmptyView } from '../components/EmptyView';
import { BusinessError } from '@kit.BasicServicesKit';
import { BreakpointSystem } from '../common/BreakpointSystem';
import { AdaptiveLayoutHelper } from '../common/AdaptiveLayoutHelper';

/**
 * 流程处理页 — 源码级翻译（W23）：
 *   主处理页 = APK TodoProcedureActivity（/todo/procedure，路由 mobile_campus_oa_todo_procedure）
 *   转交/回退弹层 = APK TodoProcedureOtherActivity（/todo/procedure_other，e.a.N）页内等价
 *   （HAP 单页承接：弹层用页内覆盖层复刻，提交参数与 APK 122/123 onActivityResult 组装一致）。
 *
 * 【入口管道】
 *   A. WorkApplyFormConfigPage（源码 5348 c3 bundle）→ AppStorage 'workapply_submit_bundle'
 *      = JSON {data: map, processid, bmpurl, allSubmitFiles:[{fdName, filePaths[]}]}
 *   B. EditTodoDetailPage（源码 TodoDetailActivity 1563 C3 等价）→ AppStorage 'edited_todo_form'
 *      （W14 vms JSON）+ 'edited_todo_nav' = JSON {processid, unid, bmpurl}
 *      （vms→map 转换按 TodoDetailActivity.C3 同款规则：SUBJECT/picker relevance/file→selectfile/
 *        meeting 拆分/select _show/read 跳过）
 *
 * 【数据流源码还原（TodoPImpl/TodoModel）】
 *   B3 → openProcess（POST e.d {processid, docUnid}）→ TodoOpenProcess
 *   t3 → remark（GET）→ String[] 快捷意见 chips（s3：15fp pill 圆角12 描边0.5 margin10，
 *        选中主色底白字；点击填入 procedure_content）
 *   J3 渲染：
 *     - noCopyToFlag=="1" → 抄送区隐藏；否则 CopyViewLayout（XML 默认标题"抄送人员"）+
 *       setDefaultCopyUserList(copyToOwner, copyToOwner_show, noCopyToSelectFlag)：
 *       "1"→t("")+s(list,"2")（默认必带只读）；否则 t("1")+s(list,"3")（默认全选）
 *     - nextNodeConfig：每节点 TodoProcedureNextLayout（radio+nodeName+Grid5 头像格子+展开/收回+
 *       清空）；size==1 强制 disabled+defaultChecked；ownerSelectType=="2"→默认必带只读，
 *       否则 t("1")+s(list,"3")；checkbox 单/多选（gatewayType）；行点击未选中→"请先选择该节点
 *       再进行操作"；勾选格子超 maxSelectSize→"当前下一节点最多选择N人"
 *     - remarkNullFlag "1"/"2" → 意见区显示（"2" 必填）；defaultRemark 预填
 *     - buttonIdList 含 BU1032 → 电子签章区（qiyuesuo getSignUrl→WebView→EventBus15→
 *       qiyuesuo/detail→seal/image base64；HAP 等价 WebViewPage+AppStorage 管道）
 *   底部 ProcessBtnLayout：buttonId=="BU1001" → 主按钮（226dip primary/灰禁用双态，确认弹窗
 *     "确定办理这条流程吗？"→提交）；无 buttonMapList 且 actionId=="EndUserTask" → 自动
 *     "办理完成"；次按钮（BU1002 保存图标/BU1004·BU1008 回退图标/BU1006 退回图标）→ actionId 分流：
 *     GoToOthers/ReturnToAnyNode → 弹层；passRead → HAP 无 base.i 选择器页保留语义无跳转；
 *     GoToNextParallelUser → 直接提交（签章校验）；GoToFirstNode/GoToPrevNode → 确认弹窗→提交；
 *     其他 → toast "暂不支持该操作"
 *   提交 runProcess（POST e.d {docXml:JSON(map+WF_CopyUserList[+WF_ReassignmentFlag|isBackFlag]),
 *     nextNodeid(选中节点","), nextUserList(GH","；多节点"GH$nodeId,"), actionid, remark,
 *     processid, docUnid[, contractSignId, contractSignImage]}）→ RunProcess{msg}：
 *     成功 → msg toast + 附件上传（allSubmitFiles 非空：每个 fdName POST bmpurl+"R_S017_B066"
 *     明文 multipart {DocUnid,Processid,NodeName,FdName} + selectfile 文件）→ setResult+finish
 *     （HAP：AppStorage 'procedure_result'='1' + back）
 *   弹层（TodoProcedureOtherActivity 1:1）：
 *     GoToOthers：标题=actionName；CopyViewLayout"转交其他用户"；OARadioGroupLayout"选项"
 *       （转发后不需要返回/转发后需要返回，默认 y="1"）；remarkNullFlag 空或"3"→意见区隐藏；
 *       快捷 tag（ChooseTagLayout：单行放得下的 RadioButton 15fp tag_choosed 底 marginR10）+
 *       tvAddCommon"添加常用意见"（空→"内容不能为空"→addOpinion→"添加成功"）+ 更多→快捷回复页；
 *       确定：格子选中数 0→"请选择回退用户"；remarkNullFlag=="2" 且意见空→"请填写处理意见"→提交
 *     ReturnToAnyNode：标题=actionName；CopyViewLayout"回退用户"；getReturnToAnyNode {docUnid,
 *       currentNodeid} →"回退环节" radio（NODENAME，选中 r=NODEID）+"选项" radio（需要用户再次
 *       提交审批/用户修改后直接提交给我，默认 z="1"）；确定：r 空→"请选择回退环节"；人数 0→
 *       "请选择回退用户"→提交
 * 【禁 mock】openProcess/remark/getReturnToAnyNode 全真实接口；空数据走真实空态。
 */

/** 弹层/主页面通用人员格子（TodoProcedureAdapter 复刻） */
@Component
struct ProcedureUserGrid {
  @Prop users: OaSubDeptUser[] = [];
  @Prop showAdd: boolean = false;
  @Prop collapsed: boolean = false;
  @Prop gridType: string = '1';
  /** ownerSelectType=="2" 只读基座行数（TodoProcedureAdapter.f：i<baseSize 隐藏 checkbox 不可点） */
  @Prop readonlyBase: number = 0;
  @StorageProp('currentBreakpoint') currentBreakpoint: string = 'sm';
  onAdd?: () => void;
  onToggle?: (index: number) => void;

  private nameOf(u: OaSubDeptUser): string {
    return u.TYPE === '0' ? u.BMMC : u.XM;
  }

  private initialOf(u: OaSubDeptUser): string {
    const name: string = this.nameOf(u);
    return name.length > 0 ? name.substring(0, 1) : '';
  }

  build() {
    Grid() {
      ForEach(this.users, (u: OaSubDeptUser, index: number) => {
        GridItem() {
          Column() {
            Stack() {
              Text(this.initialOf(u))
                .fontSize(18.5)
                .fontColor($r('app.color.white'))
                .width(38)
                .height(38)
                .textAlign(TextAlign.Center)
                .borderRadius(19)
                .backgroundColor($r('app.color.mobile_campus_primary_color_default'))
              if (u.isSelected) {
                Text('✓')
                  .fontSize(10)
                  .fontColor($r('app.color.white'))
                  .width(16)
                  .height(16)
                  .textAlign(TextAlign.Center)
                  .borderRadius(8)
                  .backgroundColor('#4CD964')
                  .margin({ top: 2, left: 26 })
              }
            }
            .width(48)
            .height(48)
            .alignContent(Alignment.TopStart)

            Text(this.nameOf(u))
              .fontSize(12)
              .fontColor($r('app.color.common_color_1'))
              .margin({ top: 8 })
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
              .width(56)
              .textAlign(TextAlign.Center)
          }
          .alignItems(HorizontalAlign.Center)
          .onClick(() => {
            // 源码 OnBindViewHolder：i<f.size() 且 ownerSelectType=="2" → checkbox GONE+无监听（只读必带）
            if (this.gridType === '2' && index < this.readonlyBase) {
              return;
            }
            if (this.onToggle !== undefined) {
              this.onToggle(index);
            }
          })
        }
      }, (u: OaSubDeptUser, index: number) => index + '_' + u.GH + '_' + u.XM + '_' + String(u.isSelected))
      if (this.showAdd) {
        GridItem() {
          Column() {
            Image($r('app.media.mobile_campus_oa_addto_white'))
              .width(38)
              .height(38)
              .borderRadius(19)
              .backgroundColor($r('app.color.mobile_campus_primary_color_default'))
              .objectFit(ImageFit.Contain)
            Text('添加')
              .fontSize(12)
              .fontColor('#B2BDC9')
              .margin({ top: 8 })
          }
          .alignItems(HorizontalAlign.Center)
          .onClick(() => {
            if (this.onAdd !== undefined) {
              this.onAdd();
            }
          })
        }
      }
    }
    .columnsTemplate(AdaptiveLayoutHelper.buildColumnsTemplate(
      BreakpointSystem.getGridColumns(this.currentBreakpoint, 5)
    ))
    .rowsGap(8)
    .height(this.gridHeight(this.users.length, this.collapsed))
    .width('100%')
    .padding(12)
  }

  private gridHeight(size: number, collapsed: boolean): number {
    let shown: number = size;
    if (collapsed && shown > 4) {
      shown = 4;
    }
    if (this.showAdd) {
      shown = shown + 1;
    }
    const cols: number = BreakpointSystem.getGridColumns(this.currentBreakpoint, 5);
    return Math.max(98, AdaptiveLayoutHelper.computeGridHeightVp(shown, cols, 66, 8, 24));
  }
}

/** 处理页弹层 radio 行（OARadioGroupLayout/d3/e3/f3 复刻：17fp pad12 procedure_bg 单选） */
@Component
struct ProcedureRadioRow {
  @Prop label: string = '';
  @Prop picked: boolean = false;
  onPick?: () => void;

  build() {
    Row() {
      Circle()
        .width(18)
        .height(18)
        .fill(Color.Transparent)
        .stroke(this.picked ? $r('app.color.mobile_campus_primary_color_default') : $r('app.color.common_color_3'))
        .strokeWidth(this.picked ? 6 : 1)
      Text(this.label)
        .fontSize(17)
        .fontColor($r('app.color.common_color_1'))
        .margin({ left: 12 })
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .layoutWeight(1)
    }
    .width('100%')
    .padding(12)
    .alignItems(VerticalAlign.Center)
    .onClick(() => {
      if (this.onPick !== undefined) {
        this.onPick();
      }
    })
  }
}

/** 弹层单选组块（OARadioGroupLayout：标题+细线+radio 列+24 灰条） */
@Component
struct ProcedureRadioGroup {
  @Prop groupTitle: string = '';
  @Prop labels: string[] = [];
  @Prop pickedIndex: number = 0;
  onPick?: (index: number) => void;

  build() {
    Column() {
      Row() {
        Image($r('app.media.mobile_campus_oa_nextapprover'))
          .width(16)
          .height(16)
          .margin({ right: 12 })
        Text(this.groupTitle)
          .fontSize(15)
          .fontColor($r('app.color.mobile_campus_schedule_color11'))
      }
      .width('100%')
      .padding({ left: 13, right: 13, top: 10, bottom: 10 })
      .alignItems(VerticalAlign.Center)

      Divider().color($r('app.color.common_color_5')).strokeWidth(0.5)

      ForEach(this.labels, (label: string, index: number) => {
        ProcedureRadioRow({
          label: label,
          picked: this.pickedIndex === index,
          onPick: (): void => {
            if (this.onPick !== undefined) {
              this.onPick(index);
            }
          }
        })
      }, (label: string) => label)

      Column()
        .width('100%')
        .height(12)
        .backgroundColor('#F2F2F2')
    }
    .width('100%')
    .backgroundColor($r('app.color.white'))
  }
}

/** 下一环节行 VM（TodoProcedureNextLayout/view.b 状态包） */
class NextNodeVM {
  config: OaNextNodeConfig = new OaNextNodeConfig();
  users: OaSubDeptUser[] = [];
  /** h.n() 选中项（.isSelected）之外的基础列表（adapter.f），"收回"态只展示前 4 */
  baseSize: number = 0;
  checked: boolean = false;
  expanded: boolean = false;
  /** 收回标记（view.b.o） */
  collapsedNow: boolean = false;
  /** 添加格允许（adapter f12278d=="1"） */
  canAdd: boolean = true;
  maxSelect: number = 2147483647;
  minSelect: number = 0;
  /** selectUserMapList 快照（添加返回 g(max, list) 用） */
  seedUsers: OaNextNodeUser[] = [];

  static build(config: OaNextNodeConfig): NextNodeVM {
    const vm: NextNodeVM = new NextNodeVM();
    vm.config = config;
    let max: number = -1;
    try {
      max = Number(config.ownerMaxUserNum === '' ? '0' : config.ownerMaxUserNum);
    } catch (error) {
      const err = error as BusinessError;
      ApiService.logError('NextNodeVM max parse fail: ' + err.message);
      max = -1;
    }
    let min: number = -1;
    try {
      min = Number(config.ownerMinUserNum === '' ? '0' : config.ownerMinUserNum);
    } catch (error) {
      const err = error as BusinessError;
      ApiService.logError('NextNodeVM min parse fail: ' + err.message);
      min = -1;
    }
    if (max > 0) {
      vm.maxSelect = max;
    }
    if (min >= 0) {
      vm.minSelect = min;
    }
    if (config.ownerSelectType === '2') {
      const listSize: number = config.selectUserMapList.length;
      vm.maxSelect = Math.max(listSize, vm.maxSelect);
    }
    config.maxSelectSize = vm.maxSelect;
    config.minSelectSize = vm.minSelect;
    vm.seedUsers = config.selectUserMapList;
    return vm;
  }
}

/** workapply_submit_bundle 附件组（SubmitFileBean keyName=selectfile 分组） */
class ProcFileGroup {
  fdName: string = '';
  filePaths: string[] = [];
}

const OPINION_SEPARATOR: string = '[!_!]';

@Entry
@Component
struct TodoProcedureOtherPage {
  @State loading: boolean = true;
  @State failed: boolean = false;
  @State loadErrMsg: string = '';
  /** openProcess 响应 */
  private op: OaTodoOpenProcess = new OaTodoOpenProcess();
  private currentNode: OaCurrentNodeConfig | null = null;
  @State nextNodeVMs: NextNodeVM[] = [];
  /** 主页状态（J3） */
  @State copyUsers: OaSubDeptUser[] = [];
  @State copyCanAdd: boolean = true;
  @State copyReadOnlyMode: string = '3';
  @State remarkText: string = '';
  @State quickReplies: string[] = [];
  /** 源码 a TextWatcher/c 类：chips 选中位（意见清空 → 全部取消选中） */
  @State selectedChipIdx: number = -1;
  @State showElectronicSign: boolean = false;
  @State signBase64: string = '';
  @State signBizId: string = '';
  @State signSealId: string = '';
  /** 源码 H3→u.a(z)：校验通过才可点提交（buttonMapList 全体 c(z)） */
  @State actionButtonsEnabled: boolean = true;
  @StorageProp('currentBreakpoint') currentBreakpoint: string = 'sm';
  @StorageProp('windowWidthVp') windowWidthVp: number = 360;
  @StorageProp('windowHeightVp') windowHeightVp: number = 640;
  @StorageProp('isCompactHeight') isCompactHeight: boolean = false;
  @StorageProp('avoidAreaBottomVp') avoidAreaBottomVp: number = 0;
  @StorageProp('keyboardHeightVp') keyboardHeightVp: number = 0;
  /** 入参管道 */
  private processid: string = '';
  private unid: string = '';
  private bmpurl: string = '';
  private dataMap: Record<string, string> = {};
  private fileGroups: ProcFileGroup[] = [];
  private multiNextSelect: boolean = true;
  /** 已选下一环节 map（y：nodeId → users；null=仅勾选无人员） */
  private pickedNodeUsers: Map<string, OaSubDeptUser[] | null> = new Map();
  private firstNodePicked: string = '';
  /** 源码 K3 附件上传：x.put("docUnid", orUnid)（bmpurl 非空时）+ H 标记（GoToOthers→取 "unid"=null） */
  private orUnid: string = '';
  private gotoOthersFlag: boolean = false;
  /** 源码 q.e/q.b：提交飞行中按钮禁用 */
  private submitting: boolean = false;
  /** 弹层（TodoProcedureOtherActivity） */
  @State showOtherLayer: boolean = false;
  @State otherMode: string = '';
  @State otherActionName: string = '';
  @State otherRemarkNullFlag: string = '';
  @State otherUsers: OaSubDeptUser[] = [];
  @State otherRadio1: number = 0;
  @State otherRadio2: number = 0;
  @State otherRemark: string = '';
  @State otherRemarkTags: string[] = [];
  @State returnNodes: OaReturnToAnyNode[] = [];
  @State showAddOpinion: boolean = false;
  @State addOpinionText: string = '';
  private addOpinionTarget: string = 'main';

  aboutToAppear(): void {
    if (!this.parseSubmitBundle()) {
      this.parseEditedTodo();
    }
    this.fetchOpenProcess();
    this.fetchQuickReplies();
  }

  /** 管道 A：workapply_submit_bundle（源码 5348 c3 bundle；FormConfig push 进入） */
  private parseSubmitBundle(): boolean {
    const json: string | undefined = AppStorage.get<string>('workapply_submit_bundle');
    if (json === undefined || json === '') {
      return false;
    }
    try {
      const rec: Record<string, Object> = JSON.parse(json) as Record<string, Object>;
      this.processid = ApiService.pick(rec, ['processid']);
      this.bmpurl = ApiService.pick(rec, ['bmpurl']);
      this.unid = ApiService.pick(rec, ['unid']);
      const dataRec: Record<string, Object> = ApiService.asRecord(rec['data']);
      for (const key of Object.keys(dataRec)) {
        const v: Object = dataRec[key];
        if (typeof v === 'string') {
          this.dataMap[key] = v as string;
        } else if (typeof v === 'number') {
          this.dataMap[key] = String(v as number);
        }
      }
      for (const one of ApiService.extractArray(rec['allSubmitFiles'])) {
        const frec: Record<string, Object> = ApiService.asRecord(one);
        const group: ProcFileGroup = new ProcFileGroup();
        group.fdName = ApiService.pick(frec, ['fdName']);
        for (const p of ApiService.extractArray(frec['filePaths'])) {
          if (typeof p === 'string') {
            group.filePaths.push(p as string);
          }
        }
        if (group.fdName !== '' && group.filePaths.length > 0) {
          this.fileGroups.push(group);
        }
      }
      AppStorage.setOrCreate<string>('workapply_submit_bundle', '');
      return this.processid !== '';
    } catch (error) {
      const err = error as BusinessError;
      ApiService.logError('ProcedureOther parseSubmitBundle fail: ' + err.message);
      return false;
    }
  }

  /** 管道 B：edited_todo_form（W14 vms）+ edited_todo_nav（W23 补写）→ C3 同款 map */
  private parseEditedTodo(): boolean {
    const formJson: string | undefined = AppStorage.get<string>('edited_todo_form');
    const navJson: string | undefined = AppStorage.get<string>('edited_todo_nav');
    if (navJson !== undefined && navJson !== '') {
      try {
        const rec: Record<string, Object> = JSON.parse(navJson) as Record<string, Object>;
        this.processid = ApiService.pick(rec, ['processid']);
        this.unid = ApiService.pick(rec, ['unid']);
        this.bmpurl = ApiService.pick(rec, ['bmpurl']);
      } catch (error) {
        const err = error as BusinessError;
        ApiService.logError('ProcedureOther parseEditedTodo nav fail: ' + err.message);
      }
    }
    if (formJson === undefined || formJson === '' || this.processid === '') {
      return false;
    }
    const extract: TodoFormExtract = ApiService.buildTodoFormMap(formJson);
    this.dataMap = extract.map;
    for (const group of extract.fileGroups) {
      const g: ProcFileGroup = new ProcFileGroup();
      g.fdName = group.fdName;
      g.filePaths = group.filePaths;
      this.fileGroups.push(g);
    }
    AppStorage.setOrCreate<string>('edited_todo_form', '');
    AppStorage.setOrCreate<string>('edited_todo_nav', '');
    return this.processid !== '';
  }

  /** 源码 B3：openProcess（POST e.d {processid, docUnid}）→ J3 渲染 */
  private fetchOpenProcess(): void {
    this.loading = true;
    ApiService.openOaProcess(this.processid, this.unid)
      .then((response: ApiResponse<OaTodoOpenProcess>) => {
        if (response.code === 1000) {
          return;
        }
        if (response.code === 0) {
          this.op = response.data;
          this.failed = false;
          this.renderOpenProcess();
        } else {
          this.failed = true;
          this.loadErrMsg = response.message === '' ? '流程数据获取失败' : response.message;
          ApiService.logError('openProcess fail code=' + response.code + ' msg=' + response.message);
        }
        this.loading = false;
      })
      .catch((error: BusinessError) => {
        ApiService.logError('openProcess error: ' + error.message);
        this.failed = true;
        this.loadErrMsg = '网络异常，请稍后重试';
        this.loading = false;
      });
  }

  /** 源码 t3：remark 快捷意见（P.x → d1 GET） */
  private fetchQuickReplies(): void {
    ApiService.getOaFastReplies()
      .then((response: ApiResponse<string[]>) => {
        if (response.code === 0) {
          this.quickReplies = response.data;
        }
      })
      .catch((error: BusinessError) => {
        ApiService.logError('fetchQuickReplies fail: ' + error.message);
      });
  }

  /** 源码 J3（TodoProcedureActivity）渲染主线 */
  private renderOpenProcess(): void {
    const currentList: OaCurrentNodeConfig[] = this.op.currentNodeConfig;
    if (currentList.length > 0) {
      this.currentNode = currentList[0];
    }
    this.renderCopyArea();
    this.renderNextNodes();
    this.renderRemarkArea();
    this.renderSignArea();
    // defaultRemark 预填后重算按钮可用态（源码 setText 触发 a TextWatcher → u.a 重估）
    this.refreshButtonsEnabled(false);
  }

  /** 源码 J3 抄送分支：noCopyToFlag → CopyViewLayout + 默认抄送 */
  private renderCopyArea(): void {
    const node: OaCurrentNodeConfig | null = this.currentNode;
    if (node === null || node.noCopyToFlag === '1') {
      this.copyUsers = [];
      return;
    }
    const users: OaSubDeptUser[] = this.parseCopyDefault(node.copyToOwner, node.copyToOwner_show);
    if (node.noCopyToSelectFlag === '1') {
      this.copyCanAdd = false;
      this.copyReadOnlyMode = '2';
    } else {
      this.copyCanAdd = true;
      this.copyReadOnlyMode = '3';
    }
    for (const u of users) {
      u.isSelected = true;
    }
    this.copyUsers = users;
  }

  /** CopyViewLayout.setDefaultCopyUserList：GH/XM "," 配对拆分（长度不一致仅日志丢弃） */
  private parseCopyDefault(ghs: string, xms: string): OaSubDeptUser[] {
    const out: OaSubDeptUser[] = [];
    if (ghs === '' || xms === '') {
      return out;
    }
    if (ghs.indexOf(',') >= 0 && xms.indexOf(',') >= 0) {
      const ghList: string[] = ghs.split(',');
      const xmList: string[] = xms.split(',');
      if (ghList.length === xmList.length) {
        for (let i = 0; i < ghList.length; i++) {
          const u: OaSubDeptUser = new OaSubDeptUser();
          u.GH = ghList[i];
          u.XM = xmList[i];
          u.TYPE = '1';
          out.push(u);
        }
      } else {
        ApiService.logError('业务申请默认抄送人员id和姓名数量不一致');
      }
    } else {
      const u: OaSubDeptUser = new OaSubDeptUser();
      u.GH = ghs;
      u.XM = xms;
      u.TYPE = '1';
      out.push(u);
    }
    return out;
  }

  /** 源码 J3 下一环节分支：view.b 逐节点构建（size==1 强制 disabled+defaultChecked） */
  private renderNextNodes(): void {
    const list: OaNextNodeConfig[] = this.op.nextNodeConfig;
    const vms: NextNodeVM[] = [];
    if (list.length === 0) {
      this.nextNodeVMs = vms;
      this.pickedNodeUsers = new Map();
      return;
    }
    if (list.length === 1) {
      list[0].gatewayType_disabled = 'true';
      list[0].gatewayType_defaultChecked = 'true';
    }
    for (const config of list) {
      const vm: NextNodeVM = NextNodeVM.build(config);
      this.seedNodeUsers(vm);
      vms.push(vm);
    }
    this.nextNodeVMs = vms;
    // 源码尾段：未勾选 v()（隐藏）；勾选 ≤4 v()（显示无钮）；勾选 >4 w()（全部显示+"收回"，o=true）
    for (const vm of vms) {
      if (!vm.checked) {
        vm.expanded = false;
      } else {
        vm.expanded = true;
        vm.collapsedNow = vm.users.length > 4;
      }
      if (vm.checked) {
        this.pickedNodeUsers.set(vm.config.nodeId, null);
        this.firstNodePicked = vm.config.nodeId;
      }
    }
    this.refreshButtonsEnabled(false);
  }

  /** view.b.H(ownerSelectType, selectUserMapList)：s(list, mode) + t(flag) 等价 */
  private seedNodeUsers(vm: NextNodeVM): void {
    const users: OaSubDeptUser[] = [];
    for (const seed of vm.config.selectUserMapList) {
      const u: OaSubDeptUser = new OaSubDeptUser();
      u.GH = seed.userId;
      u.XM = seed.userName;
      u.TYPE = '1';
      // 源码 TodoProcedureAdapter.s(list, type)：仅 "3" 全选置位；"2" 固定基座不置位
      // （n() 对 "2" 无条件带上基座，见 refreshPicked）
      u.isSelected = vm.config.ownerSelectType !== '2';
      users.push(u);
    }
    // 源码 adapter.t(ownerSelectFlag)："添加"格仅 ownerSelectFlag=="1"（size<200 由 UI 判定）
    if (vm.config.ownerSelectFlag === '1') {
      vm.canAdd = true;
    } else {
      vm.canAdd = false;
    }
    vm.baseSize = users.length;
    vm.users = users;
    vm.checked = vm.config.gatewayType_defaultChecked === 'true';
  }

  /** 源码 J3 意见区分支 + defaultRemark 预填 */
  private renderRemarkArea(): void {
    const node: OaCurrentNodeConfig | null = this.currentNode;
    if (node !== null && node.defaultRemark !== '') {
      this.remarkText = node.defaultRemark;
    }
  }

  /** 源码 J3 电子签章分支：buttonIdList 含 BU1032 显示区 */
  private renderSignArea(): void {
    const node: OaCurrentNodeConfig | null = this.currentNode;
    this.showElectronicSign = node !== null && node.buttonIdList.indexOf('BU1032') >= 0;
  }

  onPageShow(): void {
    // 源码 onActivityResult(121)：抄送/格子人员添加返回 → addData
    const copyResult: string | undefined = AppStorage.get<string>('oa_copy_result');
    if (copyResult !== undefined && copyResult !== '') {
      AppStorage.setOrCreate<string>('oa_copy_result', '');
      this.consumeCopyResult(copyResult);
    }
    // 源码 onActivityResult(120)：快捷回复返回 fastReply → 输入框
    const fastReply: string | undefined = AppStorage.get<string>('fast_reply_result');
    if (fastReply !== undefined && fastReply !== '') {
      AppStorage.setOrCreate<string>('fast_reply_result', '');
      if (this.showOtherLayer) {
        this.otherRemark = fastReply;
        this.otherRemarkTags = [];
      } else {
        this.remarkText = fastReply;
      }
    }
    // 源码 c2(EventBus 15)：签章 WebView 返回后 → qiyuesuo/detail → seal/image base64
    // （APK onResume 分支为不可达死代码；事件由签章页完成时发出。HAP 以 onPageShow 回页触发等价）
    if (this.signBizId !== '' && this.signBase64 === '') {
      this.fetchSignDetail();
    }
  }

  /** 源码 onActivityResult 100/默认分支：添加返回 list → 当前弹层或格子 */
  private consumeCopyResult(json: string): void {
    try {
      const parsed: Object = JSON.parse(json) as Object;
      const list: OaSubDeptUser[] = [];
      for (const one of ApiService.extractArray(parsed)) {
        list.push(OaSubDeptUser.fromRecord(ApiService.asRecord(one)));
      }
      if (this.showOtherLayer) {
        this.otherUsers = this.otherUsers.concat(list);
        return;
      }
      if (this.copyTargetNodeIdx >= 0 && this.copyTargetNodeIdx < this.nextNodeVMs.length) {
        const vm: NextNodeVM = this.nextNodeVMs[this.copyTargetNodeIdx];
        vm.users = vm.users.concat(list);
        this.applyGridMax(vm, list);
        this.refreshPicked(vm);
      } else {
        this.copyUsers = this.copyUsers.concat(list);
      }
    } catch (error) {
      const err = error as BusinessError;
      ApiService.logError('consumeCopyResult fail: ' + err.message);
    }
  }

  /** TodoProcedureAdapter.g(max, list)：超 max 自动选中截断 + "最多选择N人" toast 一次 */
  private applyGridMax(vm: NextNodeVM, list: OaSubDeptUser[]): void {
    let selected: number = this.selectedCount(vm.users);
    let warned: boolean = false;
    for (const u of list) {
      if (selected < vm.maxSelect) {
        u.isSelected = true;
        selected++;
      } else if (!warned) {
        this.toast('当前下一节点最多选择' + vm.maxSelect + '人');
        warned = true;
      }
    }
  }

  private selectedCount(users: OaSubDeptUser[]): number {
    let count: number = 0;
    for (const u of users) {
      if (u.isSelected) {
        count++;
      }
    }
    return count;
  }

  /** 源码 v 类：节点勾选变化（gatewayType=="checkbox" 多选，否则单选清其它） */
  private onNodeChecked(vm: NextNodeVM, checked: boolean): void {
    // 源码 B()：gatewayType_disabled=="true" → checkbox.setEnabled(false)（点击无效）
    if (vm.config.gatewayType_disabled === 'true') {
      return;
    }
    if (vm.config.gatewayType === 'checkbox') {
      this.multiNextSelect = false;
      vm.checked = checked;
      if (!checked) {
        this.pickedNodeUsers.delete(vm.config.nodeId);
      } else {
        this.pickedNodeUsers.set(vm.config.nodeId, null);
      }
      this.refreshNodeState();
      return;
    }
    // 非 checkbox（radio）：源码 I3(i2) 回写本行 checked=true，且 y.clear()+put——radio 不可反选
    this.multiNextSelect = true;
    vm.checked = true;
    for (const other of this.nextNodeVMs) {
      if (other !== vm) {
        other.checked = false;
      }
    }
    this.pickedNodeUsers = new Map();
    this.pickedNodeUsers.set(vm.config.nodeId, null);
    this.firstNodePicked = vm.config.nodeId;
    this.refreshNodeState();
  }

  /** 状态引用替换（驱动 @State nextNodeVMs 刷新） */
  private refreshNodeState(): void {
    const copy: NextNodeVM[] = this.nextNodeVMs.slice();
    this.nextNodeVMs = copy;
  }

  /** 源码 w 类：行区域点击（未选中 toast；选中→其它 v() 复位、本行 A()?v():w() 展开/收回切换） */
  private onNodeRowClick(vm: NextNodeVM): void {
    if (!vm.checked) {
      this.toast('请先选择该节点再进行操作');
      return;
    }
    for (const other of this.nextNodeVMs) {
      if (other === vm) {
        // w.a：A()（o=true 已全展开）→ v() 收起；否则 w() 展开
        other.expanded = true;
        other.collapsedNow = !other.collapsedNow;
      } else {
        // v()：未勾选隐藏；勾选 → 显示收回态（前 4）
        other.expanded = other.checked;
        other.collapsedNow = false;
      }
    }
    this.refreshNodeState();
  }

  /** 源码 C0211b：格子勾选（超 max toast"当前下一节点最多选择N人"） */
  private onNodeUserToggle(vm: NextNodeVM, index: number): void {
    if (!vm.checked) {
      return;
    }
    const u: OaSubDeptUser | undefined = vm.users[index];
    if (u === undefined) {
      return;
    }
    if (u.isSelected) {
      u.isSelected = false;
    } else if (this.selectedCount(vm.users) < vm.maxSelect) {
      u.isSelected = true;
    } else {
      this.toast('当前下一节点最多选择' + vm.maxSelect + '人');
    }
    this.refreshPicked(vm);
  }

  /** 选中集合写回 pickedNodeUsers（y map；n() 等价："2" 基座无条件计入） */
  private refreshPicked(vm: NextNodeVM): void {
    const picked: OaSubDeptUser[] = [];
    if (vm.config.ownerSelectType === '2') {
      // 源码 TodoProcedureAdapter.n()：g=="2" → addAll(f)（固定基座必带）+ 基座之后勾选项
      for (let i = 0; i < vm.baseSize && i < vm.users.length; i++) {
        picked.push(vm.users[i]);
      }
      for (let i = vm.baseSize; i < vm.users.length; i++) {
        if (vm.users[i].isSelected) {
          picked.push(vm.users[i]);
        }
      }
    } else {
      for (const u of vm.users) {
        if (u.isSelected) {
          picked.push(u);
        }
      }
    }
    this.pickedNodeUsers.set(vm.config.nodeId, picked);
    this.refreshNodeState();
    this.refreshButtonsEnabled(true);
  }

  /** 源码 x 类：格子"添加" → CarbonCopyListPage multiUserPicker（rc=index+1 等价）
   *  注意源码 x.a：processId/userFilterNodeId 均取 F.nextNodeConfig.get(0)（非本行节点）——保真 */
  private openNodeUserPicker(vm: NextNodeVM, nodeIdx: number): void {
    if (!this.pickedNodeUsers.has(vm.config.nodeId)) {
      return;
    }
    this.copyTargetNodeIdx = nodeIdx;
    router.pushUrl({ url: 'pages/CarbonCopyListPage',
      params: {
        'mode': 'multiUserPicker',
        'processId': this.op.nextNodeConfig.length > 0 ? this.op.nextNodeConfig[0].processId : '',
        'userFilterNodeId': this.op.nextNodeConfig.length > 0 ? this.op.nextNodeConfig[0].nodeId : '',
        'currentSize': String(vm.users.length),
        'bmdm': ''
      } as Record<string, string> });
  }

  private copyTargetNodeIdx: number = -1;

  /** 源码 t 类：主页抄送区"添加" → CarbonCopyListPage（无 processId 过滤） */
  private openCopyUserPicker(): void {
    this.copyTargetNodeIdx = -1;
    router.pushUrl({ url: 'pages/CarbonCopyListPage',
      params: {
        'mode': 'multiUserPicker',
        'bmdm': '',
        'currentSize': String(this.copyUsers.length)
      } as Record<string, string> });
  }

  /** 源码 b 类：格子勾选回调（仅主抄送区：isSelected 反转；"2" 只读基座不可点） */
  private onCopyUserToggle(index: number): void {
    if (this.copyReadOnlyMode === '2' && index < this.copyBaseSize()) {
      return;
    }
    const u: OaSubDeptUser | undefined = this.copyUsers[index];
    if (u === undefined) {
      return;
    }
    u.isSelected = !u.isSelected;
    this.copyUsers = this.copyUsers.slice();
  }

  /** 源码 CopyViewLayout.getCopyUserList：adapter.n() 选中 GH ","（"2" 模式基座无条件计入） */
  private copyUserList(): string {
    const parts: string[] = [];
    if (this.copyReadOnlyMode === '2') {
      const base: number = this.copyBaseSize();
      for (let i = 0; i < this.copyUsers.length; i++) {
        if (i < base || this.copyUsers[i].isSelected) {
          parts.push(this.copyUsers[i].GH);
        }
      }
    } else {
      for (const u of this.copyUsers) {
        if (u.isSelected) {
          parts.push(u.GH);
        }
      }
    }
    return parts.join(',');
  }

  /** 源码 w3()：选中下一环节 nodeId "," 拼接 */
  private nextNodeIdList(): string {
    const ids: string[] = [];
    this.pickedNodeUsers.forEach((_users: OaSubDeptUser[] | null, nodeId: string) => {
      ids.push(nodeId);
    });
    return ids.join(',');
  }

  /** 源码 x3()：单节点 GH ","；多节点组内 "GH$nodeId,"（组内最后一个不尾随）+ 组尾 ","，整串去尾 1 字符 */
  private nextUserList(): string {
    if (this.pickedNodeUsers.size === 1) {
      const parts: string[] = [];
      this.pickedNodeUsers.forEach((users: OaSubDeptUser[] | null, _nodeId: string) => {
        if (users !== null) {
          for (const u of users) {
            parts.push(u.GH);
          }
        }
      });
      return parts.join(',');
    }
    let out: string = '';
    this.pickedNodeUsers.forEach((users: OaSubDeptUser[] | null, nodeId: string) => {
      if (users !== null && users.length > 0) {
        for (let i = 0; i < users.length; i++) {
          out = out + users[i].GH + '$' + nodeId;
          if (i !== users.length - 1) {
            out = out + ',';
          }
        }
        out = out + ',';
      }
    });
    return out.length > 0 ? out.substring(0, out.length - 1) : '';
  }

  /** 源码 j.b 普通按钮提交参数组装（docXml=gson(map)+WF_CopyUserList） */
  private buildRunParams(actionId: string, remark: string, nextNodeid: string,
    nextUserList: string): Record<string, Object> {
    const map: Record<string, string> = {};
    for (const key of Object.keys(this.dataMap)) {
      map[key] = this.dataMap[key];
    }
    map['WF_CopyUserList'] = this.copyUserList();
    const params: Record<string, Object> = {
      'docXml': Object.keys(map).length === 0 ? '' : JSON.stringify(map),
      'nextNodeid': nextNodeid,
      'actionid': actionId,
      'processid': this.processid,
      'docUnid': this.unid
    };
    params['nextUserList'] = nextUserList;
    params['remark'] = remark;
    if (this.signSealId !== '' && this.signBase64 !== '') {
      params['contractSignId'] = this.signBizId;
      params['contractSignImage'] = 'data:image/png;base64,' + this.signBase64;
    }
    return params;
  }

  /** 源码 C3 → q 回调：runProcess 提交（q.e 禁用→q.b 恢复；成功 msg toast + 附件上传 + back） */
  private submitRunProcess(params: Record<string, Object>): void {
    if (this.submitting) {
      return;
    }
    this.submitting = true;
    ApiService.runOaProcess(params)
      .then((response: ApiResponse<OaRunProcessResult>) => {
        if (response.code === 1000) {
          this.submitting = false;
          return;
        }
        if (response.code === 0) {
          // 源码 q.g：bmpurl 非空 → x.put("docUnid", orUnid)（后续附件上传取新 unid）
          if (this.bmpurl !== '') {
            this.orUnid = response.data.orUnid;
            this.dataMap['docUnid'] = response.data.orUnid;
          }
          this.uploadAttachFiles(params);
          // 源码 x2(runProcess.msg)：服务器 msg 原样 toast（无兜底文案）
          this.toast(response.data.msg);
          AppStorage.setOrCreate<string>('procedure_result', '1');
          this.getUIContext().getRouter().back();
        } else {
          // 源码 q.f：m(str2) toast 服务器 message
          this.toast(response.message);
        }
        this.submitting = false;
      })
      .catch((error: BusinessError) => {
        // 源码 q.e（异常回调）：仅 v.setEnable(false)+日志，无 toast
        ApiService.logError('runProcess fail: ' + error.message);
        this.submitting = false;
      });
  }

  /** 源码 K3：附件上传（allSubmitFiles 非空 → o1 每 fdName POST bmpurl+"R_S017_B066"；
   *  DocUnid 取 x.get(H?"unid":"docUnid")：GoToOthers→null、bmpurl 非空→orUnid、否则原 unid；
   *  n.g 上传成功回调 → p1 GET bmpurl+"R_S017_B065" {fdName, DocUnid}（j=false 明文，结果忽略） */
  private uploadAttachFiles(params: Record<string, Object>): void {
    if (this.fileGroups.length === 0) {
      return;
    }
    const url: string = this.bmpurl + 'R_S017_B066';
    let docUnid: string = this.unid;
    if (this.gotoOthersFlag) {
      docUnid = '';
    } else if (this.bmpurl !== '') {
      docUnid = this.orUnid;
    }
    const nodeName: string = params['nextNodeid'] !== undefined ? params['nextNodeid'] as string : '';
    for (const group of this.fileGroups) {
      const fields: Record<string, string> = {
        'DocUnid': docUnid,
        'Processid': this.processid,
        'NodeName': nodeName,
        'FdName': group.fdName
      };
      HttpClient.plainMultipartPost(url, fields, group.filePaths, 'selectfile')
        .then((uploadResult: ApiResponse<Object>) => {
          if (uploadResult.code === 0) {
            // 源码 n.g：上传成功 → p1 明文 GET bmpurl+"R_S017_B065"（结果回调 a 类空实现，忽略）
            HttpClient.feedbackGet(this.bmpurl + 'R_S017_B065',
              { 'fdName': group.fdName, 'DocUnid': docUnid })
              .then((_cleanup: ApiResponse<Object>): void => {
              })
              .catch((cleanupError: BusinessError): void => {
                ApiService.logError('R_S017_B065 cleanup fail: ' + cleanupError.message);
              });
          }
        })
        .catch((error: BusinessError) => {
          ApiService.logError('uploadAttachFiles fail: ' + error.message);
        });
    }
  }

  /** 源码 j.a 普通按钮（BU1001）：签章校验 + 非 GXMD 确认弹窗 → 提交 */
  private onPrimaryButton(button: OaProcessButton): void {
    const node: OaCurrentNodeConfig | null = this.currentNode;
    if (node !== null && node.buttonIdList.indexOf('BU1032') >= 0 && this.signBase64 === '') {
      this.toast('请添加电子签章');
      return;
    }
    if (LoginSessionSchool() !== 'GXMD') {
      this.confirmDialog('确定办理这条流程吗？', (): void => {
        this.submitPrimary(button);
      });
      return;
    }
    this.submitPrimary(button);
  }

  /** 确认弹窗确定后的组装提交（j.a 内层/a 类） */
  private submitPrimary(button: OaProcessButton): void {
    const nextNodeid: string = this.nextNodeIdList();
    const nextUsers: string = this.nextUserList();
    if (!this.validateNextSelect()) {
      return;
    }
    const params: Record<string, Object> =
      this.buildRunParams(button.actionId, this.remarkText.trim() === '' ? '' : this.remarkText,
        nextNodeid, nextUsers);
    this.submitRunProcess(params);
  }

  /** 源码 H3：remarkNullFlag=="2" 意见必填 + min/maxSelectSize 校验（提交前兜底，主链靠按钮禁用） */
  private validateNextSelect(): boolean {
    const node: OaCurrentNodeConfig | null = this.currentNode;
    if (node !== null && node.remarkNullFlag === '2' && this.remarkText.trim() === '') {
      this.toast('请输入处理意见');
      return false;
    }
    let checkedNodes: OaNextNodeConfig[] = [];
    if (this.multiNextSelect) {
      for (const vm of this.nextNodeVMs) {
        if (vm.checked) {
          checkedNodes.push(vm.config);
        }
      }
    } else {
      const keys: string[] = [];
      this.pickedNodeUsers.forEach((_users: OaSubDeptUser[] | null, nodeId: string) => {
        keys.push(nodeId);
      });
      for (const config of this.op.nextNodeConfig) {
        if (keys.indexOf(config.nodeId) >= 0) {
          checkedNodes.push(config);
        }
      }
    }
    for (const config of checkedNodes) {
      const users: OaSubDeptUser[] | null | undefined = this.pickedNodeUsers.get(config.nodeId);
      const hasSeed: boolean = config.selectUserMapList.length > 0;
      if ((hasSeed || config.ownerSelectFlag === '1') && (users === null || users === undefined || users.length === 0)) {
        return false;
      }
      if (users !== null && users !== undefined && users.length > config.maxSelectSize) {
        this.toast('当前下一节点最多选择' + config.maxSelectSize + '人');
        return false;
      }
      if (users !== null && users !== undefined && users.length > 0 && users.length < config.minSelectSize) {
        this.toast('当前下一节点至少选择' + config.minSelectSize + '人,还差' +
          (config.minSelectSize - users.length) + '人');
        return false;
      }
    }
    return true;
  }

  /**
   * 源码 H3 → z 回调（ProcessBtnLayout d 类 a(z) → 全部按钮 c(z)）等价：
   * remarkNullFlag=="2" 意见空 → 禁用；逐勾选节点校验 selectUserMapList/ownerSelectFlag 必填、
   * max/minSelectSize（违例 toast 一次）；无勾选节点（初始 H3 按节点评估）→ 可用。
   */
  private refreshButtonsEnabled(showToastOnFail: boolean): void {
    const node: OaCurrentNodeConfig | null = this.currentNode;
    if (node === null) {
      this.actionButtonsEnabled = true;
      return;
    }
    if (node.remarkNullFlag === '2' && this.remarkText.trim() === '') {
      this.actionButtonsEnabled = false;
      return;
    }
    const nodes: OaNextNodeConfig[] = [];
    if (this.multiNextSelect) {
      for (const vm of this.nextNodeVMs) {
        if (vm.checked) {
          nodes.push(vm.config);
        }
      }
    } else {
      const keys: string[] = [];
      this.pickedNodeUsers.forEach((_users: OaSubDeptUser[] | null, nodeId: string) => {
        keys.push(nodeId);
      });
      for (const config of this.op.nextNodeConfig) {
        if (keys.indexOf(config.nodeId) >= 0) {
          nodes.push(config);
        }
      }
    }
    if (nodes.length === 0) {
      // 初始渲染按各节点自身评估（源码 H3 单选恒取 [vm]），无勾选不构成禁用
      this.actionButtonsEnabled = true;
      return;
    }
    let enabled: boolean = true;
    for (const config of nodes) {
      const users: OaSubDeptUser[] | null | undefined = this.pickedNodeUsers.get(config.nodeId);
      const empty: boolean = users === null || users === undefined || users.length === 0;
      if ((config.selectUserMapList.length > 0 || config.ownerSelectFlag === '1') && empty) {
        enabled = false;
        break;
      }
      const size: number = empty ? 0 : (users as OaSubDeptUser[]).length;
      if (size > config.maxSelectSize) {
        if (showToastOnFail) {
          this.toast('当前下一节点最多选择' + config.maxSelectSize + '人');
        }
        enabled = false;
        break;
      }
      if (size > 0 && size < config.minSelectSize) {
        if (showToastOnFail) {
          this.toast('当前下一节点至少选择' + config.minSelectSize + '人,还差' +
            (config.minSelectSize - size) + '人');
        }
        enabled = false;
        break;
      }
    }
    this.actionButtonsEnabled = enabled;
  }

  /** 源码 j.a：次按钮 actionId 分流 */
  private onSecondaryButton(button: OaProcessButton): void {
    const actionId: string = button.actionId;
    if (actionId === 'GoToOthers') {
      this.openOtherLayer('GoToOthers', button);
      return;
    }
    if (actionId === 'ReturnToAnyNode') {
      this.openOtherLayer('ReturnToAnyNode', button);
      return;
    }
    if (actionId === 'passRead') {
      // 源码 base.i.e.a.n（人员选择器）HAP 无对应页：入口语义保留，无跳转
      this.toast('暂不支持该操作');
      return;
    }
    if (actionId === 'GoToNextParallelUser') {
      this.onPrimaryButton(button);
      return;
    }
    if (actionId === 'GoToFirstNode') {
      this.confirmDialog('确定回退首环节吗？', (): void => {
        this.submitDirect();
      });
      return;
    }
    if (actionId === 'GoToPrevNode') {
      this.confirmDialog('确定回退上一环节吗？', (): void => {
        this.submitDirect();
      });
      return;
    }
    this.toast('暂不支持该操作');
  }

  /** 源码 y3/z3：util.m.b 仅日志不组装；确认后 C3(x)——x 仅含 y() 初始 put 的 {processid, docUnid}
   *  （docXml/nextNodeid/actionid 等只在 j.a/j.b/122/123 分支写入，GoToFirstNode/GoToPrevNode 直提
   *  不经组装——按源码原样两参提交） */
  private submitDirect(): void {
    const params: Record<string, Object> = { 'processid': this.processid, 'docUnid': this.unid };
    this.submitRunProcess(params);
  }

  /** 弹层打开（TodoProcedureOtherActivity y() 入参等价） */
  private openOtherLayer(mode: string, button: OaProcessButton): void {
    if (mode === 'GoToOthers') {
      // 源码 j.a：GoToOthers 点击即 H=true（此后附件上传取 x.get("unid")=null）
      this.gotoOthersFlag = true;
    }
    this.otherMode = mode;
    this.otherActionName = button.actionName;
    const node: OaCurrentNodeConfig | null = this.currentNode;
    this.otherRemarkNullFlag = node !== null ? node.remarkNullFlag : '';
    this.otherUsers = [];
    this.otherRadio1 = 0;
    this.otherRadio2 = 0;
    this.otherRemark = '';
    this.otherRemarkTags = [];
    this.showOtherLayer = true;
    if (mode === 'ReturnToAnyNode') {
      this.fetchReturnNodes();
    } else {
      this.fetchOtherTags();
    }
  }

  /** 弹层 h3：getReturnToAnyNode {docUnid, currentNodeid} →"回退环节" radio */
  private fetchReturnNodes(): void {
    ApiService.getOaReturnToAnyNodes(this.unid, this.op.currentNodeId)
      .then((response: ApiResponse<OaReturnToAnyNode[]>) => {
        if (response.code === 0) {
          this.returnNodes = response.data;
        } else {
          this.returnNodes = [];
          ApiService.logError('getReturnToAnyNode fail code=' + response.code);
        }
      })
      .catch((error: BusinessError) => {
        ApiService.logError('getReturnToAnyNode error: ' + error.message);
        this.returnNodes = [];
      });
  }

  /** 弹层 g3：remark 快捷意见 → ChooseTagLayout */
  private fetchOtherTags(): void {
    ApiService.getOaFastReplies()
      .then((response: ApiResponse<string[]>) => {
        if (response.code === 0) {
          this.otherRemarkTags = response.data;
        }
      })
      .catch((error: BusinessError) => {
        ApiService.logError('fetchOtherTags fail: ' + error.message);
      });
  }

  /** 弹层 a 类：添加人员 → CarbonCopyListPage multiUserPicker rc100 */
  private openOtherUserPicker(): void {
    const node: OaCurrentNodeConfig | null = this.currentNode;
    router.pushUrl({ url: 'pages/CarbonCopyListPage',
      params: {
        'processId': node !== null ? node.processId : '',
        'userFilterNodeId': node !== null ? node.nodeId : '',
        'bmdm': '',
        'mode': 'multiUserPicker',
        'currentSize': String(this.otherUsers.length)
      } as Record<string, string> });
  }

  /** 弹层 tvAddCommon：添加常用意见弹窗（空→"内容不能为空"→addOpinion→"添加成功"） */
  private openAddOpinion(target: string): void {
    this.addOpinionTarget = target;
    this.addOpinionText = target === 'main' ? this.remarkText : this.otherRemark;
    this.showAddOpinion = true;
  }

  /** 源码 j$a$a：addOpinion 提交（成功 EventBus17 等价刷新快捷意见） */
  private submitAddOpinion(): void {
    const text: string = this.addOpinionText.trim();
    if (text === '') {
      this.toast('内容不能为空');
      return;
    }
    ApiService.addOaOpinion(text)
      .then((response: ApiResponse<Object>) => {
        if (response.code === 0) {
          this.showAddOpinion = false;
          this.toast('添加成功');
          this.fetchQuickReplies();
          this.fetchOtherTags();
        } else {
          this.toast(response.message);
        }
      })
      .catch((error: BusinessError) => {
        ApiService.logError('addOpinion fail: ' + error.message);
        this.toast('网络请求失败，请稍后再试');
      });
  }

  /** 弹层"更多" → TodoFastReplyPage（rc120 等价：返回 fast_reply_result onPageShow 消费） */
  private gotoFastReply(): void {
    router.pushUrl({ url: 'pages/TodoFastReplyPage' });
  }

  /** 弹层 tvConfirm（TodoProcedureOtherActivity k 类）：校验 → 组装提交 */
  private confirmOtherLayer(): void {
    if (this.otherMode === 'GoToOthers') {
      if (this.selectedCount(this.otherUsers) === 0) {
        this.toast('请选择回退用户');
        return;
      }
      if (this.otherRemarkNullFlag === '2' && this.otherRemark.trim() === '') {
        this.toast('请填写处理意见');
        return;
      }
      this.submitGoToOthers();
      return;
    }
    if (this.otherMode === 'ReturnToAnyNode') {
      if (this.otherRadio1 < 0 || this.otherRadio1 >= this.returnNodes.length) {
        this.toast('请选择回退环节');
        return;
      }
      if (this.selectedCount(this.otherUsers) === 0) {
        this.toast('请选择回退用户');
        return;
      }
      this.submitReturnToAnyNode();
    }
  }

  /** 源码 122 返回分支组装：WF_ReassignmentFlag→map + docXml + nextNodeid="" + GoToOthers */
  private submitGoToOthers(): void {
    const users: string[] = [];
    for (const u of this.otherUsers) {
      if (u.isSelected) {
        users.push(u.GH);
      }
    }
    const map: Record<string, string> = {};
    for (const key of Object.keys(this.dataMap)) {
      map[key] = this.dataMap[key];
    }
    map['WF_CopyUserList'] = this.copyUserList();
    map['WF_ReassignmentFlag'] = String(this.otherRadio1 + 1);
    const params: Record<string, Object> = {
      'docXml': Object.keys(map).length === 0 ? '' : JSON.stringify(map),
      'nextNodeid': '',
      'actionid': 'GoToOthers',
      'processid': this.processid,
      'docUnid': this.unid,
      'nextUserList': users.join(',')
    };
    // 源码 122：remark 仅非空时 put（空则不携带该字段）
    if (this.otherRemark !== '') {
      params['remark'] = this.otherRemark;
    }
    this.showOtherLayer = false;
    this.submitRunProcess(params);
  }

  /** 源码 123 返回分支组装：nextNodeid/isBackFlag→map + docXml + ReturnToAnyNode */
  private submitReturnToAnyNode(): void {
    const node: OaReturnToAnyNode = this.returnNodes[this.otherRadio1];
    const users: string[] = [];
    for (const u of this.otherUsers) {
      if (u.isSelected) {
        users.push(u.GH);
      }
    }
    const map: Record<string, string> = {};
    for (const key of Object.keys(this.dataMap)) {
      map[key] = this.dataMap[key];
    }
    map['WF_CopyUserList'] = this.copyUserList();
    map['isBackFlag'] = String(this.otherRadio2 + 1);
    const params: Record<string, Object> = {
      'docXml': Object.keys(map).length === 0 ? '' : JSON.stringify(map),
      'nextNodeid': node.NODEID,
      'actionid': 'ReturnToAnyNode',
      'processid': this.processid,
      'docUnid': this.unid,
      'nextUserList': users.join(',')
    };
    // 源码 123：不回传 remark（弹层意见区只在 GoToOthers 模式显示，123 分支也不组装 remark）
    this.showOtherLayer = false;
    this.submitRunProcess(params);
  }

  /** 源码 e 类：qiyuesuo getSignUrl → WebViewPage 免登（HAP WebViewPage 管道） */
  private openElectronicSign(): void {
    HttpClient.bizRequest('/mobileapi_ydxy/api/java/todoitem/qiyuesuo/getSignUrl', 'GET', {})
      .then((response: ApiResponse<Object>) => {
        if (response.code !== 0) {
          this.toast(response.message);
          return;
        }
        try {
          const rec: Record<string, Object> = JSON.parse(response.data as string) as Record<string, Object>;
          const bizId: string = ApiService.pick(rec, ['bizId']);
          const signUrl: string = ApiService.pick(rec, ['signUrl']);
          if (bizId === '' || signUrl === '') {
            return;
          }
          this.signBizId = bizId;
          router.pushUrl({ url: 'pages/WebViewPage',
            params: { 'url': signUrl, 'title': '电子签章' } as Record<string, string> });
        } catch (error) {
          const err = error as BusinessError;
          ApiService.logError('getSignUrl parse fail: ' + err.message);
        }
      })
      .catch((error: BusinessError) => {
        ApiService.logError('getSignUrl fail: ' + error.message);
        this.toast('网络请求失败，请稍后再试');
      });
  }

  /** 源码 onResume/c2(15)：WebView 返回后 bizId 有值且未取章 → qiyuesuo/detail → seal/image */
  private fetchSignDetail(): void {
    HttpClient.bizRequest('/mobileapi_ydxy/api/java/todoitem/qiyuesuo/detail?bizId=' + this.signBizId,
      'GET', {})
      .then((response: ApiResponse<Object>) => {
        if (response.code !== 0) {
          return;
        }
        try {
          const rec: Record<string, Object> = JSON.parse(response.data as string) as Record<string, Object>;
          const resultRec: Record<string, Object> = ApiService.asRecord(rec['result']);
          this.signBizId = ApiService.pick(resultRec, ['bizId']) === '' ? this.signBizId
            : ApiService.pick(resultRec, ['bizId']);
          const sealRec: Record<string, Object> = ApiService.asRecord(resultRec['seal']);
          const sealId: string = ApiService.pick(sealRec, ['id']);
          if (sealId !== '') {
            this.signSealId = sealId;
            this.fetchSealImage(sealId);
          }
        } catch (error) {
          const err = error as BusinessError;
          ApiService.logError('signDetail parse fail: ' + err.message);
        }
      })
      .catch((error: BusinessError) => {
        ApiService.logError('signDetail fail: ' + error.message);
      });
  }

  /** 源码 seal/image 回调：base64 图显示 + 更换按钮 */
  private fetchSealImage(sealId: string): void {
    HttpClient.bizRequest('/mobileapi_ydxy/api/java/todoitem/qiyuesuo/seal/image?sealId=' + sealId,
      'GET', {})
      .then((response: ApiResponse<Object>) => {
        if (response.code === 0 && typeof response.data === 'string' && (response.data as string) !== '') {
          this.signBase64 = response.data as string;
        }
      })
      .catch((error: BusinessError) => {
        ApiService.logError('sealImage fail: ' + error.message);
      });
  }

  private toast(message: string): void {
    this.getUIContext().getPromptAction().showToast({ message: message });
  }

  /** 源码 dialog.h（"确定办理这条流程吗？/确定回退首环节吗？/确定回退上一环节吗？"） */
  private confirmDialog(message: string, onSure: () => void): void {
    this.getUIContext().showAlertDialog({
      title: '',
      message: message,
      primaryButton: {
        value: '取消',
        action: (): void => {
        }
      },
      secondaryButton: {
        value: '确定',
        action: (): void => {
          onSure();
        }
      }
    });
  }

  /** 源码 a 类（添加常用意见弹窗） */
  private addOpinionDialog(): void {
    this.showAddOpinion = true;
  }

  build() {
    Column() {
      TitleBar({ title: '流程处理', showBack: true })
      Divider().color($r('app.color.common_color_5')).strokeWidth(0.5)
      if (this.loading) {
        Column() {
          LoadingView()
        }
        .width('100%')
        .layoutWeight(1)
      } else if (this.failed) {
        Scroll() {
          Column() {
            EmptyView({ tipText: this.loadErrMsg === '' ? '流程数据获取失败' : this.loadErrMsg })
          }
          .width('100%')
          .constraintSize({ minHeight: 320 })
          .justifyContent(FlexAlign.Center)
        }
        .width('100%')
        .layoutWeight(1)
      } else {
        Stack() {
          this.mainContent()
          if (this.showOtherLayer) {
            this.otherLayer()
          }
        }
        .width('100%')
        .layoutWeight(1)
        .alignContent(Alignment.Bottom)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.main_bg'))
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.BOTTOM])
  }

  /** 主内容：下一环节区 + 抄送区 + 意见区 + 电子签章区 + 底部按钮列 */
  @Builder
  mainContent() {
    Column() {
      Scroll() {
        Column() {
          if (this.nextNodeVMs.length > 0) {
            this.nextNodeArea()
          }
          if (this.currentNode !== null && this.currentNode.noCopyToFlag !== '1') {
            this.copyArea()
          }
          this.remarkArea()
          if (this.showElectronicSign) {
            this.signArea()
          }
        }
        .width('100%')
        .constraintSize({ maxWidth: BreakpointSystem.getContentMaxWidth(this.currentBreakpoint) })
        .alignSelf(ItemAlign.Center)
        .padding({ bottom: this.keyboardHeightVp })
      }
      .scrollBar(BarState.Off)
      .width('100%')
      .layoutWeight(1)

      Row() {
        Column() {
          this.processBtnBar()
        }
        .width('100%')
        .constraintSize({ maxWidth: BreakpointSystem.getContentMaxWidth(this.currentBreakpoint) })
      }
      .width('100%')
      .justifyContent(FlexAlign.Center)
      .padding({ bottom: this.avoidAreaBottomVp })
      .backgroundColor($r('app.color.white'))
    }
    .width('100%')
    .height('100%')
  }

  /** layoutNext：标题"下一级审批人" + 节点行列表 + 24 灰条 */
  @Builder
  nextNodeArea() {
    Column() {
      Row() {
        Image($r('app.media.mobile_campus_oa_nextapprover'))
          .width(16)
          .height(16)
          .margin({ right: 12 })
        Text('下一级审批人')
          .fontSize(15)
          .fontColor($r('app.color.mobile_campus_schedule_color11'))
      }
      .width('100%')
      .padding({ left: 13, right: 13, top: 10, bottom: 10 })
      .alignItems(VerticalAlign.Center)

      Divider().color($r('app.color.common_color_5')).strokeWidth(0.5)

      ForEach(this.nextNodeVMs, (vm: NextNodeVM, index: number) => {
        this.nextNodeRow(vm, index)
      }, (vm: NextNodeVM) => vm.config.nodeId + '_' + String(vm.checked) + '_' + String(vm.expanded))

      Column()
        .width('100%')
        .height(12)
        .backgroundColor('#F2F2F2')
    }
    .width('100%')
    .backgroundColor($r('app.color.white'))
  }

  /** mobile_campus_oa_view_procedure_next：checkbox+nodeName+展开/收回+清空+格子 */
  @Builder
  nextNodeRow(vm: NextNodeVM, index: number) {
    Column() {
      Row() {
        Circle()
          .width(20)
          .height(20)
          .fill(vm.checked ? $r('app.color.mobile_campus_primary_color_default') : Color.Transparent)
          .stroke(vm.checked ? $r('app.color.mobile_campus_primary_color_default') : $r('app.color.common_color_3'))
          .strokeWidth(vm.checked ? 7 : 1)
          .margin({ left: 13 })
          .onClick(() => {
            this.onNodeChecked(vm, !vm.checked);
          })
        Text(vm.config.nodeName)
          .fontSize(17)
          .fontColor($r('app.color.common_color_1'))
          .margin({ left: 13 })
          .layoutWeight(1)
          .maxLines(1)
          .onClick(() => {
            this.onNodeRowClick(vm);
          })
        if (vm.checked && vm.users.length > 4) {
          // 源码 tvExpend 仅作展示标签（b.j 未设监听，切换由行点击 w.a 承载）——保真不加点击
          Text(vm.collapsedNow ? '收回' : '展开')
            .fontSize(14)
            .fontColor($r('app.color.mobile_campus_primary_color_default'))
            .margin({ left: 16 })
        }
        if (vm.checked && (vm.users.length - vm.baseSize) > 3) {
          // 源码 imgDelete：h.l()>3（新加人数 > 3）可见
          Image($r('app.media.mobile_campus_oa_issue_clean'))
            .width(18)
            .height(18)
            .padding(4)
            .margin({ left: 8 })
            .onClick(() => {
              this.clearNodeUsers(vm);
            })
        }
      }
      .width('100%')
      .padding({ top: 16, bottom: 16 })
      .alignItems(VerticalAlign.Center)

      if (vm.checked && vm.expanded && vm.users.length > 0) {
        ProcedureUserGrid({
          users: vm.users,
          showAdd: vm.canAdd && vm.users.length < 200,
          collapsed: vm.users.length > 4 && !vm.collapsedNow,
          gridType: vm.config.ownerSelectType,
          readonlyBase: vm.config.ownerSelectType === '2' ? vm.baseSize : 0,
          onAdd: (): void => {
            this.openNodeUserPicker(vm, index);
          },
          onToggle: (idx: number): void => {
            this.onNodeUserToggle(vm, idx);
          }
        })
      }

      Divider().color($r('app.color.common_color_5')).strokeWidth(0.5)
    }
    .width('100%')
  }

  /** 源码 c 类（imgDelete）：h.i() 复位到固定基座列表（种子保留、全部取消选中） */
  private clearNodeUsers(vm: NextNodeVM): void {
    const reset: OaSubDeptUser[] = [];
    for (const seed of vm.config.selectUserMapList) {
      const u: OaSubDeptUser = new OaSubDeptUser();
      u.GH = seed.userId;
      u.XM = seed.userName;
      u.TYPE = '1';
      u.isSelected = false;
      reset.push(u);
    }
    vm.users = reset;
    this.refreshPicked(vm);
  }

  /** CopyViewLayout 抄送区（标题默认"抄送人员" + 格子 + 清空） */
  @Builder
  copyArea() {
    Column() {
      Row() {
        Image($r('app.media.mobile_campus_oa_nextapprover'))
          .width(16)
          .height(16)
          .margin({ right: 12 })
        Text('抄送人员')
          .fontSize(15)
          .fontColor($r('app.color.mobile_campus_schedule_color11'))
          .layoutWeight(1)
        if ((this.copyUsers.length - this.copyBaseSize()) > 3) {
          // 源码 CopyViewLayout.setDeleteVisibile：adapter.l()>3（新加人数 > 3）显示
          Image($r('app.media.mobile_campus_oa_issue_clean'))
            .width(18)
            .height(18)
            .padding(4)
            .margin({ right: 16 })
            .onClick(() => {
              // 源码 a 类：adapter.i() 复位到默认抄送（f 列表）且全部取消选中
              const base: number = this.copyBaseSize();
              const reset: OaSubDeptUser[] = [];
              for (let i = 0; i < this.copyUsers.length && i < base; i++) {
                const u: OaSubDeptUser = this.copyUsers[i];
                u.isSelected = false;
                reset.push(u);
              }
              this.copyUsers = reset;
            })
        }
      }
      .width('100%')
      .padding({ left: 13, right: 13, top: 10, bottom: 10 })
      .alignItems(VerticalAlign.Center)

      Divider().color($r('app.color.common_color_5')).strokeWidth(0.5)

      if (this.copyUsers.length > 0 || this.copyCanAdd) {
        ProcedureUserGrid({
          users: this.copyUsers,
          showAdd: this.copyCanAdd && this.copyUsers.length < 200,
          collapsed: false,
          gridType: this.copyReadOnlyMode,
          readonlyBase: this.copyReadOnlyMode === '2' ? this.copyBaseSize() : 0,
          onAdd: (): void => {
            this.openCopyUserPicker();
          },
          onToggle: (idx: number): void => {
            this.onCopyUserToggle(idx);
          }
        })
      }

      Column()
        .width('100%')
        .height(12)
        .backgroundColor('#F2F2F2')
    }
    .width('100%')
    .backgroundColor($r('app.color.white'))
  }

  /** TodoProcedureAdapter.f 快照长度（默认抄送数） */
  private copyBaseSize(): number {
    const node: OaCurrentNodeConfig | null = this.currentNode;
    if (node === null || node.copyToOwner === '') {
      return 0;
    }
    if (node.copyToOwner.indexOf(',') >= 0) {
      const ghs: string[] = node.copyToOwner.split(',');
      const xms: string[] = node.copyToOwner_show.split(',');
      return ghs.length === xms.length ? ghs.length : 0;
    }
    return 1;
  }

  /** layoutContentContainer：填写处理意见 + 输入框 + 快捷意见 chips + 更多 */
  @Builder
  remarkArea() {
    Column() {
      Row() {
        Image($r('app.media.mobile_campus_oa_opinon'))
          .width(16)
          .height(16)
          .margin({ right: 12 })
        Text('填写处理意见')
          .fontSize(15)
          .fontColor($r('app.color.mobile_campus_schedule_color11'))
          .layoutWeight(1)
        Text('添加常用意见')
          .fontSize(15)
          .fontColor('#1B68B7')
          .padding({ left: 15, right: 15, top: 10, bottom: 10 })
          .onClick(() => {
            this.openAddOpinion('main');
          })
      }
      .width('100%')
      .padding({ left: 13 })
      .alignItems(VerticalAlign.Center)

      Divider().color($r('app.color.common_color_5')).strokeWidth(0.5)

      TextArea({ text: this.remarkText, placeholder: '请输入处理意见或者选择常用意见' })
        .fontSize(17)
        .fontColor($r('app.color.common_color_1'))
        .placeholderColor($r('app.color.mobile_campus_schedule_color12'))
        .backgroundColor(Color.Transparent)
        .maxLines(6)
        .padding({ left: 44, right: 10, top: 15 })
        .width('100%')
        .onChange((value: string) => {
          this.remarkText = value;
          // 源码 a TextWatcher：意见清空 → 全部 chips 取消选中；H3 重估按钮可用态
          if (value.trim() === '') {
            this.selectedChipIdx = -1;
          }
          this.refreshButtonsEnabled(false);
        })

      Row() {
        Scroll() {
          Row() {
            ForEach(this.quickReplies, (item: string, index: number) => {
              Text(item)
                .fontSize(15)
                .fontColor(this.selectedChipIdx === index ? $r('app.color.white')
                  : $r('app.color.mobile_campus_primary_color_default'))
                .backgroundColor(this.selectedChipIdx === index
                  ? $r('app.color.mobile_campus_primary_color_default') : Color.Transparent)
                .border({ width: 0.5, color: $r('app.color.mobile_campus_primary_color_default'),
                  radius: 12 })
                .padding({ left: 6, right: 6, top: 3, bottom: 3 })
                .margin({ right: 10 })
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
                .onClick(() => {
                  // 源码 c 类：点选 chip → 选中态 + 填入意见框
                  this.selectedChipIdx = index;
                  this.remarkText = item;
                })
            }, (item: string, index: number) => index + '_' + item)
          }
          .alignItems(VerticalAlign.Center)
        }
        .scrollable(ScrollDirection.Horizontal)
        .scrollBar(BarState.Off)
        .layoutWeight(1)

        Row() {
          Text('更多')
            .fontSize(15)
            .fontColor($r('app.color.mobile_campus_schedule_color12'))
          Image($r('app.media.arrow_right2'))
            .width(12)
            .height(12)
            .margin({ left: 6 })
        }
        .padding({ right: 13 })
        .alignItems(VerticalAlign.Center)
        .onClick(() => {
          this.gotoFastReply();
        })
      }
      .width('100%')
      .height(36)
      .alignItems(VerticalAlign.Center)
    }
    .width('100%')
    .backgroundColor($r('app.color.white'))
  }

  /** llElectronicSign：添加电子签章区（BU1032） */
  @Builder
  signArea() {
    Column() {
      Column()
        .width('100%')
        .height(12)
        .backgroundColor('#F2F2F2')

      Row() {
        Text('添加电子签章')
          .fontSize(15)
          .fontColor($r('app.color.mobile_campus_schedule_color11'))
          .layoutWeight(1)
          .margin({ left: 13 })
        if (this.signBase64 !== '') {
          Text('更换')
            .fontSize(15)
            .fontColor('#1B68B7')
            .padding({ left: 15, right: 15, top: 10, bottom: 10 })
            .onClick(() => {
              // 源码 L(tvElectronicSignChange) 点击 → u3() getSignUrl 重走签章
              this.openElectronicSign();
            })
        }
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)

      Divider().color($r('app.color.common_color_5')).strokeWidth(0.5)

      Column() {
        if (this.signBase64 !== '') {
          Image('data:image/png;base64,' + this.signBase64)
            .width('90%')
            .height(100)
            .objectFit(ImageFit.Contain)
        } else {
          Text('添加电子签章')
            .fontSize(14)
            .fontColor('#1B68B7')
            .border({ width: 0.5, color: '#1B68B7', radius: 512 })
            .padding({ left: 10, right: 10, top: 4, bottom: 4 })
            .onClick(() => {
              this.openElectronicSign();
            })
        }
      }
      .width('100%')
      .height(100)
      .justifyContent(FlexAlign.Center)
    }
    .width('100%')
    .backgroundColor($r('app.color.white'))
  }

  /** ProcessBtnLayout：BU1001 主按钮 226dip + 次按钮列（H3 校验失败全体禁用：d 类 c(z) 等价） */
  @Builder
  processBtnBar() {
    Row() {
      Scroll() {
        Row() {
          ForEach(this.currentButtons(), (button: OaProcessButton) => {
            if (button.buttonId !== 'BU1001') {
              Row() {
                this.btnIcon(button.buttonId)
                Text(button.buttonName)
                  .fontSize(15)
                  .fontColor($r('app.color.mobile_campus_primary_color_default'))
                  .margin({ left: 8 })
              }
              .height('100%')
              .padding({ left: 20, right: 20 })
              .alignItems(VerticalAlign.Center)
              .onClick(() => {
                if (this.actionButtonsEnabled && !this.submitting) {
                  this.onSecondaryButton(button);
                }
              })
            }
          }, (button: OaProcessButton) => button.actionId + '_' + button.buttonId)
        }
        .alignItems(VerticalAlign.Center)
      }
      .scrollable(ScrollDirection.Horizontal)
      .scrollBar(BarState.Off)
      .layoutWeight(1)
      .height('100%')

      Text(this.primaryButtonName())
        .fontSize(17)
        .fontColor($r('app.color.white'))
        .backgroundColor($r('app.color.mobile_campus_primary_color_default'))
        .width(113)
        .height('100%')
        .textAlign(TextAlign.Center)
        .opacity(this.actionButtonsEnabled ? 1 : 0.5)
        .onClick(() => {
          if (!this.actionButtonsEnabled || this.submitting) {
            return;
          }
          const primary: OaProcessButton | null = this.primaryButton();
          if (primary !== null) {
            this.onPrimaryButton(primary);
          }
        })
    }
    .width('100%')
    .height(44)
    .backgroundColor($r('app.color.white'))
    .alignItems(VerticalAlign.Center)
  }

  /** 次按钮图标映射（k.k：BU1002 save / BU1004·BU1008 fallback / BU1006 backtob） */
  @Builder
  btnIcon(buttonId: string) {
    if (buttonId === 'BU1002') {
      Image($r('app.media.mobile_campus_oa_save')).width(16).height(16)
    } else if (buttonId === 'BU1004' || buttonId === 'BU1008') {
      Image($r('app.media.mobile_campus_oa_fallback')).width(16).height(16)
    } else if (buttonId === 'BU1006') {
      Image($r('app.media.mobile_campus_oa_backtob')).width(16).height(16)
    }
  }

  /** ProcessBtnLayout.setData 等价：buttonMapList 过滤（noReassFlag=="1" 隐藏 GoToOthers） */
  private currentButtons(): OaProcessButton[] {
    const node: OaCurrentNodeConfig | null = this.currentNode;
    if (node === null) {
      return [];
    }
    const out: OaProcessButton[] = [];
    for (const button of node.buttonMapList) {
      if (button.buttonId === 'BU1001') {
        continue;
      }
      if (node.noReassFlag === '1' && button.actionId === 'GoToOthers') {
        continue;
      }
      out.push(button);
    }
    return out;
  }

  /** 主按钮（BU1001；无 buttonMapList 且 actionId=="EndUserTask" → "办理完成"） */
  private primaryButton(): OaProcessButton | null {
    const node: OaCurrentNodeConfig | null = this.currentNode;
    if (node === null) {
      return null;
    }
    for (const button of node.buttonMapList) {
      if (button.buttonId === 'BU1001') {
        return button;
      }
    }
    if (node.buttonMapList.length === 0 && node.actionId === 'EndUserTask') {
      const b: OaProcessButton = new OaProcessButton();
      b.actionId = 'EndUserTask';
      b.buttonId = 'BU1001';
      b.buttonName = '办理完成';
      b.actionName = '办理完成';
      return b;
    }
    return null;
  }

  private primaryButtonName(): string {
    const primary: OaProcessButton | null = this.primaryButton();
    return primary !== null ? primary.buttonName : '';
  }

  /** 弹层覆盖层（TodoProcedureOtherActivity mobile_campus_oa_activity_procedure_other 等价） */
  @Builder
  otherLayer() {
    Column() {
      Column() {
        Row() {
          Text(this.otherActionName)
            .fontSize(18.5)
            .fontWeight(FontWeight.Bold)
            .fontColor($r('app.color.common_color_1'))
            .layoutWeight(1)
            .textAlign(TextAlign.Center)
          Text('取消')
            .fontSize(15)
            .fontColor($r('app.color.common_color_1'))
            .padding({ left: 8, right: 8 })
            .hoverEffect(HoverEffect.Highlight)
            .onClick(() => {
              this.showOtherLayer = false;
            })
        }
        .width('100%')
        .height(44)
        .padding({ left: 12, right: 12 })
        .alignItems(VerticalAlign.Center)

        Divider().color($r('app.color.common_color_5')).strokeWidth(0.5)

        Scroll() {
          Column() {
            if (this.otherMode === 'ReturnToAnyNode') {
              ProcedureRadioGroup({
                groupTitle: '回退环节',
                labels: this.returnNodeLabels(),
                pickedIndex: this.otherRadio1,
                onPick: (index: number): void => {
                  this.otherRadio1 = index;
                }
              })
            }
            if (this.otherMode === 'GoToOthers') {
              ProcedureRadioGroup({
                groupTitle: '选项',
                labels: ['转发后不需要返回', '转发后需要返回'],
                pickedIndex: this.otherRadio1,
                onPick: (index: number): void => {
                  this.otherRadio1 = index;
                }
              })
            }

            this.otherCopyArea()

            if (this.otherMode === 'ReturnToAnyNode') {
              ProcedureRadioGroup({
                groupTitle: '选项',
                labels: ['需要用户再次提交审批', '用户修改后直接提交给我'],
                pickedIndex: this.otherRadio2,
                onPick: (index: number): void => {
                  this.otherRadio2 = index;
                }
              })
            }

            if (this.otherMode === 'GoToOthers' && this.otherRemarkNullFlag !== '' &&
              this.otherRemarkNullFlag !== '3') {
              this.otherRemarkArea()
            }
          }
          .width('100%')
        }
        .scrollBar(BarState.Off)
        .width('100%')
        .layoutWeight(1)

        Row() {
          Text('取消')
            .fontSize(17)
            .fontColor($r('app.color.common_color_3'))
            .layoutWeight(1)
            .textAlign(TextAlign.Center)
            .height('100%')
            .hoverEffect(HoverEffect.Highlight)
            .onClick(() => {
              this.showOtherLayer = false;
            })
          Text('确定')
            .fontSize(17)
            .fontColor($r('app.color.white'))
            .backgroundColor($r('app.color.mobile_campus_primary_color_default'))
            .layoutWeight(1)
            .textAlign(TextAlign.Center)
            .height('100%')
            .hoverEffect(HoverEffect.Highlight)
            .onClick(() => {
              this.confirmOtherLayer();
            })
        }
        .width('100%')
        .height(48)
      }
      .width('100%')
      .constraintSize({
        maxWidth: AdaptiveLayoutHelper.getSheetMaxWidth(this.currentBreakpoint, this.windowWidthVp),
        maxHeight: BreakpointSystem.getDialogMaxHeight(this.windowHeightVp)
      })
      .height(BreakpointSystem.getDialogMaxHeight(this.windowHeightVp))
      .backgroundColor($r('app.color.white'))
      .borderRadius(AdaptiveLayoutHelper.shouldUseCenterSheet(this.currentBreakpoint, this.isCompactHeight) ?
        12 : { topLeft: 12, topRight: 12 })
      .clip(true)
      .padding({
        bottom: AdaptiveLayoutHelper.shouldUseCenterSheet(this.currentBreakpoint, this.isCompactHeight) ?
          0 : this.avoidAreaBottomVp
      })
      .onClick(() => {
        // 拦截弹窗内点击
      })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#66000000')
    .alignItems(HorizontalAlign.Center)
    .justifyContent(AdaptiveLayoutHelper.shouldUseCenterSheet(this.currentBreakpoint, this.isCompactHeight) ?
      FlexAlign.Center : FlexAlign.End)
    .onClick(() => {
      this.showOtherLayer = false;
    })
  }

  private returnNodeLabels(): string[] {
    const labels: string[] = [];
    for (const node of this.returnNodes) {
      labels.push(node.NODENAME);
    }
    return labels;
  }

  /** 弹层 CopyViewLayout（"转交其他用户"/"回退用户"） */
  @Builder
  otherCopyArea() {
    Column() {
      Row() {
        Image($r('app.media.mobile_campus_oa_nextapprover'))
          .width(16)
          .height(16)
          .margin({ right: 12 })
        Text(this.otherMode === 'GoToOthers' ? '转交其他用户' : '回退用户')
          .fontSize(15)
          .fontColor($r('app.color.mobile_campus_schedule_color11'))
          .layoutWeight(1)
        if (this.otherUsers.length > 3) {
          Image($r('app.media.mobile_campus_oa_issue_clean'))
            .width(18)
            .height(18)
            .padding(4)
            .margin({ right: 16 })
            .onClick(() => {
              this.otherUsers = [];
            })
        }
      }
      .width('100%')
      .padding({ left: 13, right: 13, top: 10, bottom: 10 })
      .alignItems(VerticalAlign.Center)

      Divider().color($r('app.color.common_color_5')).strokeWidth(0.5)

      ProcedureUserGrid({
        users: this.otherUsers,
        showAdd: true,
        collapsed: false,
        gridType: '1',
        onAdd: (): void => {
          this.openOtherUserPicker();
        },
        onToggle: (idx: number): void => {
          const u: OaSubDeptUser | undefined = this.otherUsers[idx];
          if (u !== undefined) {
            u.isSelected = !u.isSelected;
            this.otherUsers = this.otherUsers.slice();
          }
        }
      })

      Column()
        .width('100%')
        .height(12)
        .backgroundColor('#F2F2F2')
    }
    .width('100%')
    .backgroundColor($r('app.color.white'))
  }

  /** 弹层意见区（layoutContentContainer + ChooseTagLayout + tvAddCommon + 更多） */
  @Builder
  otherRemarkArea() {
    Column() {
      Row() {
        Image($r('app.media.mobile_campus_oa_opinon'))
          .width(16)
          .height(16)
          .margin({ right: 12 })
        Text('填写处理意见')
          .fontSize(15)
          .fontColor($r('app.color.mobile_campus_schedule_color11'))
          .layoutWeight(1)
        Text('添加常用意见')
          .fontSize(15)
          .fontColor('#1B68B7')
          .padding({ left: 15, right: 15, top: 10, bottom: 10 })
          .onClick(() => {
            this.openAddOpinion('other');
          })
      }
      .width('100%')
      .padding({ left: 13 })
      .alignItems(VerticalAlign.Center)

      Divider().color($r('app.color.common_color_5')).strokeWidth(0.5)

      TextArea({ text: this.otherRemark, placeholder: '请输入处理意见或者选择常用意见' })
        .fontSize(17)
        .fontColor($r('app.color.common_color_1'))
        .placeholderColor($r('app.color.mobile_campus_schedule_color12'))
        .backgroundColor(Color.Transparent)
        .maxLines(4)
        .padding({ left: 44, right: 10, top: 15 })
        .width('100%')
        .onChange((value: string) => {
          this.otherRemark = value;
        })

      Row() {
        Scroll() {
          Row() {
            ForEach(this.otherRemarkTags, (item: string) => {
              Text(item)
                .fontSize(15)
                .fontColor($r('app.color.mobile_campus_primary_color_default'))
                .border({ width: 0.5, color: $r('app.color.mobile_campus_primary_color_default'),
                  radius: 12 })
                .padding({ left: 6, right: 6, top: 3, bottom: 3 })
                .margin({ right: 10 })
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
                .onClick(() => {
                  this.otherRemark = item;
                })
            }, (item: string, index: number) => index + '_' + item)
          }
          .alignItems(VerticalAlign.Center)
        }
        .scrollable(ScrollDirection.Horizontal)
        .scrollBar(BarState.Off)
        .layoutWeight(1)

        Row() {
          Text('更多')
            .fontSize(15)
            .fontColor($r('app.color.mobile_campus_schedule_color12'))
          Image($r('app.media.arrow_right2'))
            .width(12)
            .height(12)
            .margin({ left: 6 })
        }
        .padding({ right: 13 })
        .alignItems(VerticalAlign.Center)
        .onClick(() => {
          this.gotoFastReply();
        })
      }
      .width('100%')
      .height(36)
      .alignItems(VerticalAlign.Center)
    }
    .width('100%')
    .backgroundColor($r('app.color.white'))
  }
}

/** 源码 GXMD 判定（b.b.c.c.c.e().getSchoolId()）——HAP 取登录会话 schoolId */
function LoginSessionSchool(): string {
  return LoginSession.schoolId;
}
