/** 模型层本地取值工具（零外部依赖：ApiService 与本模型互相 import 会成环） */
function pickStr(rec: Record<string, Object>, key: string): string {
  const v: Object = rec[key];
  if (typeof v === 'string') {
    return v as string;
  }
  if (typeof v === 'number') {
    return String(v as number);
  }
  return '';
}

function pickNum(rec: Record<string, Object>, key: string): number {
  const v: Object = rec[key];
  if (typeof v === 'number') {
    return v as number;
  }
  if (typeof v === 'string') {
    const n: number = Number(v as string);
    if (!Number.isNaN(n)) {
      return n;
    }
  }
  return 0;
}
/**
 * OA 待办模块模型 — 逐行翻译原生实体（TodoFragment/TodoMainActivity 数据流）：
 *   - TodoTabOA  ← com.lysoft.android.lyyd.oa.todo.entity.TodoTab.java
 *     {BPM_GZ, PORT, TAB_NAME, TOTALNUM, TYPE}（tab/newTab 接口返回数组）
 *   - OaTodoRow  ← com.lysoft.android.lyyd.oa.todo.entity.RowsBean.java（TodoListBean.rows 单行）
 *   - OaTodoList ← com.lysoft.android.lyyd.oa.todo.entity.TodoListBean.java {rows, total}
 *   - OaChannel  ← framework.widget.dialog.MessageChannelBean.java {isSelect, terminalId, terminalName}
 * 请求参数实证（TodoModel.f1 + BaseRemoteXUtils3Impl case GET）：
 *   GET /mobileapi_ydxy/api/java/todoitem/list?pageSize=10&pageNum=N&rule=<BPM_GZ>
 *   参数名 rule ← com.heytap.mcssdk.constant.b.p（TodoModel.f1 第三个 put 的 key）
 *   pageSize ← AgooConstants.ACK_REMOVE_PACKAGE = "10"
 * [W23 oa-remain] 模型层零外部依赖：fromRecord 全部使用本文件 pickStr/pickNum
 * （ApiService 亦 import 本模型，互相 import 有环风险；原 W22 补的 ApiService import 已移除）。
 */

export class TodoTabOA {
  BPM_GZ: string = '';
  PORT: string = '';
  TAB_NAME: string = '';
  TOTALNUM: number = 0;
  TYPE: string = '';

  static fromRecord(rec: Record<string, Object>): TodoTabOA {
    const tab: TodoTabOA = new TodoTabOA();
    const vGz: Object = rec['BPM_GZ'];
    if (typeof vGz === 'string') {
      tab.BPM_GZ = vGz as string;
    }
    const vPort: Object = rec['PORT'];
    if (typeof vPort === 'string') {
      tab.PORT = vPort as string;
    }
    const vName: Object = rec['TAB_NAME'];
    if (typeof vName === 'string') {
      tab.TAB_NAME = vName as string;
    }
    const vNum: Object = rec['TOTALNUM'];
    if (typeof vNum === 'number') {
      tab.TOTALNUM = vNum as number;
    } else if (typeof vNum === 'string') {
      tab.TOTALNUM = Number(vNum as string);
    }
    const vType: Object = rec['TYPE'];
    if (typeof vType === 'string') {
      tab.TYPE = vType as string;
    }
    return tab;
  }
}

export class OaTodoRow {
  addName_cn: string = '';
  appid: string = '';
  author: string = '';
  author_cn: string = '';
  bpmRequestRuleUrl: string = '';
  content: string = '';
  currentnodeid: string = '';
  currentnodename: string = '';
  docCreated: string = '';
  docNumber: string = '';
  draftDep_cn: string = '';
  followStatus: string = '';
  hj: string = '';
  loseEfficacyTime: string = '';
  mj: string = '';
  nodeName: string = '';
  orUnid: string = '';
  processId: string = '';
  processName: string = '';
  startTime: string = '';
  subject: string = '';
  totalTime: string = '';
  type: string = '';
  url: string = '';

  static fromRecord(rec: Record<string, Object>): OaTodoRow {
    const row: OaTodoRow = new OaTodoRow();
    const keys: string[] = ['addName_cn', 'appid', 'author', 'author_cn', 'bpmRequestRuleUrl', 'content',
      'currentnodeid', 'currentnodename', 'docCreated', 'docNumber', 'draftDep_cn', 'followStatus', 'hj',
      'loseEfficacyTime', 'mj', 'nodeName', 'orUnid', 'processId', 'processName', 'startTime', 'subject',
      'totalTime', 'type', 'url'];
    for (const key of keys) {
      const v: Object = rec[key];
      if (typeof v === 'string') {
        row.setField(key, v as string);
      } else if (typeof v === 'number') {
        row.setField(key, String(v as number));
      }
    }
    return row;
  }

  // ArkTS 禁止 class→Record 强转：按 key 显式读写（替代 as Record 强转）
  setField(key: string, value: string): void {
    if (key === 'addName_cn') { this.addName_cn = value; } else if (key === 'appid') { this.appid = value; }
    else if (key === 'author') { this.author = value; } else if (key === 'author_cn') { this.author_cn = value; }
    else if (key === 'bpmRequestRuleUrl') { this.bpmRequestRuleUrl = value; } else if (key === 'content') { this.content = value; }
    else if (key === 'currentnodeid') { this.currentnodeid = value; } else if (key === 'currentnodename') { this.currentnodename = value; }
    else if (key === 'docCreated') { this.docCreated = value; } else if (key === 'docNumber') { this.docNumber = value; }
    else if (key === 'draftDep_cn') { this.draftDep_cn = value; } else if (key === 'followStatus') { this.followStatus = value; }
    else if (key === 'hj') { this.hj = value; } else if (key === 'loseEfficacyTime') { this.loseEfficacyTime = value; }
    else if (key === 'mj') { this.mj = value; } else if (key === 'nodeName') { this.nodeName = value; }
    else if (key === 'orUnid') { this.orUnid = value; } else if (key === 'processId') { this.processId = value; }
    else if (key === 'processName') { this.processName = value; } else if (key === 'startTime') { this.startTime = value; }
    else if (key === 'subject') { this.subject = value; } else if (key === 'totalTime') { this.totalTime = value; }
    else if (key === 'type') { this.type = value; } else if (key === 'url') { this.url = value; }
  }

  getField(key: string): string {
    if (key === 'addName_cn') { return this.addName_cn; } else if (key === 'appid') { return this.appid; }
    else if (key === 'author') { return this.author; } else if (key === 'author_cn') { return this.author_cn; }
    else if (key === 'bpmRequestRuleUrl') { return this.bpmRequestRuleUrl; } else if (key === 'content') { return this.content; }
    else if (key === 'currentnodeid') { return this.currentnodeid; } else if (key === 'currentnodename') { return this.currentnodename; }
    else if (key === 'docCreated') { return this.docCreated; } else if (key === 'docNumber') { return this.docNumber; }
    else if (key === 'draftDep_cn') { return this.draftDep_cn; } else if (key === 'followStatus') { return this.followStatus; }
    else if (key === 'hj') { return this.hj; } else if (key === 'loseEfficacyTime') { return this.loseEfficacyTime; }
    else if (key === 'mj') { return this.mj; } else if (key === 'nodeName') { return this.nodeName; }
    else if (key === 'orUnid') { return this.orUnid; } else if (key === 'processId') { return this.processId; }
    else if (key === 'processName') { return this.processName; } else if (key === 'startTime') { return this.startTime; }
    else if (key === 'subject') { return this.subject; } else if (key === 'totalTime') { return this.totalTime; }
    else if (key === 'type') { return this.type; } else if (key === 'url') { return this.url; }
    return '';
  }
}

export class OaTodoList {
  rows: OaTodoRow[] = [];
  total: string = '';
}

export class OaChannel {
  isSelect: boolean = false;
  terminalId: string = '';
  terminalName: string = '';
}

// ===== [W14 todo-series] 搜索分组 + 表单实体（源码级 1:1） =====
/** TodoSearch.java {name, rows: RowsBean[], type} — search 接口返回的分组（name=分组名） */
export class OaTodoSearchGroup {
  name: string = '';
  type: string = '';
  rows: OaTodoRow[] = [];
}

/**
 * FormEntity.java（TodoDetail.formFieldConfigList 单项）逐字段：
 * fieldNumber(表单序号/键) fieldNullable("true"=可空) fieldReadOnly("true"=只读不渲染编辑态)
 * fieldRule(JSON：select=[{id,text}] checkbox/radio={id:text} date={dataType,datePicker,KSRQ,JSRQ})
 */
export class OaFormField {
  fieldAnotherValue: string = '';
  fieldCheck: string = '';
  fieldDataDetail: string = '';
  fieldName: string = '';
  fieldNullable: string = '';
  fieldNumber: number = 0;
  fieldReadOnly: string = '';
  fieldRemark: string = '';
  fieldRule: string = '';
  fieldScreenName: string = '';
  fieldTextColor: string = '';
  fieldType: string = '';
  fieldValue: string = '';
  sortKey: string = '';
  wfOrUnid: string = '';

  static fromRecord(rec: Record<string, Object>): OaFormField {
    const f: OaFormField = new OaFormField();
    const strs: string[] = ['fieldAnotherValue', 'fieldCheck', 'fieldDataDetail', 'fieldName', 'fieldNullable',
      'fieldReadOnly', 'fieldRemark', 'fieldRule', 'fieldScreenName', 'fieldTextColor', 'fieldType',
      'fieldValue', 'sortKey', 'wfOrUnid'];
    for (const key of strs) {
      const v: Object = rec[key];
      if (typeof v === 'string') {
        f.setStr(key, v as string);
      } else if (typeof v === 'number') {
        f.setStr(key, String(v as number));
      }
    }
    const vNum: Object = rec['fieldNumber'];
    if (typeof vNum === 'number') {
      f.fieldNumber = vNum as number;
    } else if (typeof vNum === 'string') {
      const n: number = Number(vNum as string);
      f.fieldNumber = Number.isNaN(n) ? 0 : n;
    }
    return f;
  }

  setStr(key: string, value: string): void {
    if (key === 'fieldAnotherValue') { this.fieldAnotherValue = value; } else if (key === 'fieldCheck') { this.fieldCheck = value; }
    else if (key === 'fieldDataDetail') { this.fieldDataDetail = value; } else if (key === 'fieldName') { this.fieldName = value; }
    else if (key === 'fieldNullable') { this.fieldNullable = value; } else if (key === 'fieldReadOnly') { this.fieldReadOnly = value; }
    else if (key === 'fieldRemark') { this.fieldRemark = value; } else if (key === 'fieldRule') { this.fieldRule = value; }
    else if (key === 'fieldScreenName') { this.fieldScreenName = value; } else if (key === 'fieldTextColor') { this.fieldTextColor = value; }
    else if (key === 'fieldType') { this.fieldType = value; } else if (key === 'fieldValue') { this.fieldValue = value; }
    else if (key === 'sortKey') { this.sortKey = value; } else if (key === 'wfOrUnid') { this.wfOrUnid = value; }
  }
}

/** TodoDetail.java {bpmAttachList, formFieldConfigList, itemBasicInfoMap, processFlowDocList} — 编辑页只消费 formFieldConfigList + itemBasicInfoMap */
export class OaTodoDetail {
  formFieldConfigList: OaFormField[] = [];
  itemBasicInfoMap: OaTodoRow = new OaTodoRow();
  /** [W19 workapply] 详情页消费：processFlowDocList（ProcedureLayout FLOWING 时间线）+ bpmAttachList（附件） */
  processFlowDocList: OaWorkApplyFlowNode[] = [];
  bpmAttachList: OaWorkApplyAttach[] = [];
}

// ===== [W19 workapply] 业务申请链实体（workapply/entity/* + todo/entity/base/* 源码 1:1） =====

/**
 * ProcessFlowEntity.java（TimelineLayout 节点行）核心渲染字段 1:1：
 *   nodeName/nextNodeName/userName/userId/deptName/actionName/remark/startTime/endTime/difTime
 *   （career=process_career 行取 deptName；首行 BOTTOM/NONE 类型固定"发出申请"）
 */
export class OaWorkApplyFlowNode {
  actionName: string = '';
  deptName: string = '';
  difTime: string = '';
  endTime: string = '';
  nextNodeName: string = '';
  nextUserList: string = '';
  nodeName: string = '';
  remark: string = '';
  startTime: string = '';
  userId: string = '';
  userName: string = '';

  static fromRecord(rec: Record<string, Object>): OaWorkApplyFlowNode {
    const n: OaWorkApplyFlowNode = new OaWorkApplyFlowNode();
    const keys: string[] = ['actionName', 'deptName', 'difTime', 'endTime', 'nextNodeName', 'nextUserList',
      'nodeName', 'remark', 'startTime', 'userId', 'userName'];
    for (const key of keys) {
      const v: Object = rec[key];
      let value: string = '';
      if (typeof v === 'string') {
        value = v as string;
      } else if (typeof v === 'number') {
        value = String(v as number);
      }
      if (key === 'actionName') { n.actionName = value; } else if (key === 'deptName') { n.deptName = value; }
      else if (key === 'difTime') { n.difTime = value; }
      else if (key === 'endTime') { n.endTime = value; } else if (key === 'nextNodeName') { n.nextNodeName = value; }
      else if (key === 'nextUserList') { n.nextUserList = value; } else if (key === 'nodeName') { n.nodeName = value; }
      else if (key === 'remark') { n.remark = value; } else if (key === 'startTime') { n.startTime = value; }
      else if (key === 'userId') { n.userId = value; } else if (key === 'userName') { n.userName = value; }
    }
    return n;
  }
}

/** AttachmentEntity.java {downloadUrl, fileSize, realFileName, wfOrUnid}（TodoDetail.BpmAttachListBean 基类） */
export class OaWorkApplyAttach {
  downloadUrl: string = '';
  fileSize: string = '';
  realFileName: string = '';
  wfOrUnid: string = '';

  static fromRecord(rec: Record<string, Object>): OaWorkApplyAttach {
    const a: OaWorkApplyAttach = new OaWorkApplyAttach();
    const keys: string[] = ['downloadUrl', 'fileSize', 'realFileName', 'wfOrUnid'];
    for (const key of keys) {
      const v: Object = rec[key];
      let value: string = '';
      if (typeof v === 'string') {
        value = v as string;
      } else if (typeof v === 'number') {
        value = String(v as number);
      }
      if (key === 'downloadUrl') { a.downloadUrl = value; } else if (key === 'fileSize') { a.fileSize = value; }
      else if (key === 'realFileName') { a.realFileName = value; } else if (key === 'wfOrUnid') { a.wfOrUnid = value; }
    }
    return a;
  }
}

/** WorkApply.java {folderId, folderName, processId, processName}（processList 单行/宫格项） */
export class WorkApplyEntry {
  folderId: string = '';
  folderName: string = '';
  processId: string = '';
  processName: string = '';

  static fromRecord(rec: Record<string, Object>): WorkApplyEntry {
    const w: WorkApplyEntry = new WorkApplyEntry();
    const keys: string[] = ['folderId', 'folderName', 'processId', 'processName'];
    for (const key of keys) {
      const v: Object = rec[key];
      let value: string = '';
      if (typeof v === 'string') {
        value = v as string;
      } else if (typeof v === 'number') {
        value = String(v as number);
      }
      if (key === 'folderId') { w.folderId = value; } else if (key === 'folderName') { w.folderName = value; }
      else if (key === 'processId') { w.processId = value; } else if (key === 'processName') { w.processName = value; }
    }
    return w;
  }
}

/** MyApplyList.RowsBean.java（我的申请单行，12 字段 Gson 1:1；appid=="ydbg" 才可移动端办理） */
export class OaWorkApplyRow {
  addname_cn: string = '';
  appid: string = '';
  author_cn: string = '';
  bussStatus: string = '';
  currentNodeName: string = '';
  currentnodeid: string = '';
  docCreated: string = '';
  docNumber: string = '';
  orUnid: string = '';
  processName: string = '';
  processid: string = '';
  subject: string = '';

  static fromRecord(rec: Record<string, Object>): OaWorkApplyRow {
    const r: OaWorkApplyRow = new OaWorkApplyRow();
    const keys: string[] = ['addname_cn', 'appid', 'author_cn', 'bussStatus', 'currentNodeName',
      'currentnodeid', 'docCreated', 'docNumber', 'orUnid', 'processName', 'processid', 'subject'];
    for (const key of keys) {
      const v: Object = rec[key];
      if (typeof v === 'string') {
        r.setField(key, v as string);
      } else if (typeof v === 'number') {
        r.setField(key, String(v as number));
      }
    }
    return r;
  }

  setField(key: string, value: string): void {
    if (key === 'addname_cn') { this.addname_cn = value; } else if (key === 'appid') { this.appid = value; }
    else if (key === 'author_cn') { this.author_cn = value; } else if (key === 'bussStatus') { this.bussStatus = value; }
    else if (key === 'currentNodeName') { this.currentNodeName = value; } else if (key === 'currentnodeid') { this.currentnodeid = value; }
    else if (key === 'docCreated') { this.docCreated = value; } else if (key === 'docNumber') { this.docNumber = value; }
    else if (key === 'orUnid') { this.orUnid = value; } else if (key === 'processName') { this.processName = value; }
    else if (key === 'processid') { this.processid = value; } else if (key === 'subject') { this.subject = value; }
  }
}

/** MyApplyList.java {rows, total} */
export class OaWorkApplyList {
  rows: OaWorkApplyRow[] = [];
  total: string = '';
}

/**
 * WorkApplyDetail.java {formFieldConfigList(FormFieldConfigListBean=FormEntity), itemBasicInfoMap
 * {bpmRequestRuleUrl}} — formConfig 接口返回的动态表单配置。
 */
export class OaWorkApplyDetail {
  formFieldConfigList: OaFormField[] = [];
  bpmRequestRuleUrl: string = '';
}

// ===== [W23 oa-remain] OA 待办链剩余 8 页实体（源码 1:1） =====

/** SubDepartment.ResultDataBean（base/bean/SubDepartment.java）— 人员选择器/处理页头像格子共用行 */
export class OaSubDeptUser {
  BMDM: string = '';
  BMMC: string = '';
  GH: string = '';
  XM: string = '';
  SJHM: string = '';
  JSID: string = '';
  GROUPID: string = '';
  TYPE: string = '';
  count: number = 0;
  /** TodoProcedureAdapter.isSelected（仅处理页头像格子用；Gson 不序列化该字段） */
  isSelected: boolean = false;

  static fromRecord(rec: Record<string, Object>): OaSubDeptUser {
    const u: OaSubDeptUser = new OaSubDeptUser();
    const strs: string[] = ['BMDM', 'BMMC', 'GH', 'XM', 'SJHM', 'JSID', 'GROUPID', 'TYPE'];
    for (const key of strs) {
      const v: Object = rec[key];
      if (typeof v === 'string') {
        u.setStr(key, v as string);
      } else if (typeof v === 'number') {
        u.setStr(key, String(v as number));
      }
    }
    u.count = 0;
    const cv: Object = rec['count'];
    if (typeof cv === 'number') {
      u.count = cv as number;
    } else if (typeof cv === 'string') {
      const n: number = Number(cv as string);
      if (!Number.isNaN(n)) {
        u.count = n;
      }
    }
    return u;
  }

  setStr(key: string, value: string): void {
    if (key === 'BMDM') { this.BMDM = value; } else if (key === 'BMMC') { this.BMMC = value; }
    else if (key === 'GH') { this.GH = value; } else if (key === 'XM') { this.XM = value; }
    else if (key === 'SJHM') { this.SJHM = value; } else if (key === 'JSID') { this.JSID = value; }
    else if (key === 'GROUPID') { this.GROUPID = value; } else if (key === 'TYPE') { this.TYPE = value; }
  }
}

/** SubDepartment.java {title, resultData}（getSubDeptList/getSubRoleList/getSubUserGroupList 响应） */
export class OaSubDeptResult {
  title: string = '';
  resultData: OaSubDeptUser[] = [];
}

/** ReturnToAnyNode.java {NODEID, NODENAME}（getReturnToAnyNode 响应，回退环节单行） */
export class OaReturnToAnyNode {
  NODEID: string = '';
  NODENAME: string = '';

  static fromRecord(rec: Record<string, Object>): OaReturnToAnyNode {
    const n: OaReturnToAnyNode = new OaReturnToAnyNode();
    n.NODEID = pickStr(rec, 'NODEID');
    n.NODENAME = pickStr(rec, 'NODENAME');
    return n;
  }
}

/** TodoOpenProcess.ButtonMapListBean（处理页底部按钮单项） */
export class OaProcessButton {
  actionId: string = '';
  actionName: string = '';
  buttonId: string = '';
  buttonName: string = '';
  clickable: boolean = true;

  static fromRecord(rec: Record<string, Object>): OaProcessButton {
    const b: OaProcessButton = new OaProcessButton();
    b.actionId = pickStr(rec, 'actionId');
    b.actionName = pickStr(rec, 'actionName');
    b.buttonId = pickStr(rec, 'buttonId');
    b.buttonName = pickStr(rec, 'buttonName');
    b.clickable = pickStr(rec, 'clickable') !== 'false';
    return b;
  }
}

/** TodoOpenProcess.CurrentNodeConfigBean（处理页当前节点配置；HAP 消费子集逐字段对齐） */
export class OaCurrentNodeConfig {
  actionId: string = '';
  noReassFlag: string = '';
  buttonIdList: string = '';
  buttonMapList: OaProcessButton[] = [];
  copyToOwner: string = '';
  copyToOwner_show: string = '';
  defaultRemark: string = '';
  nodeId: string = '';
  nodeName: string = '';
  noCopyToFlag: string = '';
  noCopyToSelectFlag: string = '';
  processId: string = '';
  remarkNullFlag: string = '';

  static fromRecord(rec: Record<string, Object>): OaCurrentNodeConfig {
    const c: OaCurrentNodeConfig = new OaCurrentNodeConfig();
    const strs: string[] = ['actionId', 'buttonIdList', 'noReassFlag', 'copyToOwner', 'copyToOwner_show', 'defaultRemark',
      'nodeId', 'nodeName', 'noCopyToFlag', 'noCopyToSelectFlag', 'processId', 'remarkNullFlag'];
    for (const key of strs) {
      const v: Object = rec[key];
      if (typeof v === 'string') {
        c.setStr(key, v as string);
      }
    }
    return c;
  }

  setStr(key: string, value: string): void {
    if (key === 'actionId') { this.actionId = value; }
    else if (key === 'noReassFlag') { this.noReassFlag = value; }
    else if (key === 'buttonIdList') { this.buttonIdList = value; }
    else if (key === 'copyToOwner') { this.copyToOwner = value; }
    else if (key === 'copyToOwner_show') { this.copyToOwner_show = value; }
    else if (key === 'defaultRemark') { this.defaultRemark = value; }
    else if (key === 'nodeId') { this.nodeId = value; }
    else if (key === 'nodeName') { this.nodeName = value; }
    else if (key === 'noCopyToFlag') { this.noCopyToFlag = value; }
    else if (key === 'noCopyToSelectFlag') { this.noCopyToSelectFlag = value; }
    else if (key === 'processId') { this.processId = value; }
    else if (key === 'remarkNullFlag') { this.remarkNullFlag = value; }
  }
}

/** TodoOpenProcess.NextNodeConfigBean.SelectUserMapListBean {userId, userName} */
export class OaNextNodeUser {
  userId: string = '';
  userName: string = '';
}

/** TodoOpenProcess.NextNodeConfigBean（下一环节配置；HAP 消费子集） */
export class OaNextNodeConfig {
  gatewayType: string = '';
  gatewayType_defaultChecked: string = '';
  gatewayType_disabled: string = '';
  maxSelectSize: number = 2147483647;
  minSelectSize: number = 0;
  nodeId: string = '';
  nodeName: string = '';
  ownerMaxUserNum: string = '';
  ownerMinUserNum: string = '';
  ownerSelectFlag: string = '';
  ownerSelectType: string = '';
  processId: string = '';
  selectUserMapList: OaNextNodeUser[] = [];

  static fromRecord(rec: Record<string, Object>): OaNextNodeConfig {
    const n: OaNextNodeConfig = new OaNextNodeConfig();
    const strs: string[] = ['gatewayType', 'gatewayType_defaultChecked', 'gatewayType_disabled',
      'nodeId', 'nodeName', 'ownerMaxUserNum', 'ownerMinUserNum', 'ownerSelectFlag',
      'ownerSelectType', 'processId'];
    for (const key of strs) {
      const v: Object = rec[key];
      if (typeof v === 'string') {
        n.setStr(key, v as string);
      }
    }
    return n;
  }

  setStr(key: string, value: string): void {
    if (key === 'gatewayType') { this.gatewayType = value; }
    else if (key === 'gatewayType_defaultChecked') { this.gatewayType_defaultChecked = value; }
    else if (key === 'gatewayType_disabled') { this.gatewayType_disabled = value; }
    else if (key === 'nodeId') { this.nodeId = value; }
    else if (key === 'nodeName') { this.nodeName = value; }
    else if (key === 'ownerMaxUserNum') { this.ownerMaxUserNum = value; }
    else if (key === 'ownerMinUserNum') { this.ownerMinUserNum = value; }
    else if (key === 'ownerSelectFlag') { this.ownerSelectFlag = value; }
    else if (key === 'ownerSelectType') { this.ownerSelectType = value; }
    else if (key === 'processId') { this.processId = value; }
  }
}

/** TodoOpenProcess.java（openProcess 响应；HAP 消费 currentNodeConfig/nextNodeConfig/currentNodeId） */
export class OaTodoOpenProcess {
  currentNodeId: string = '';
  currentNodeConfig: OaCurrentNodeConfig[] = [];
  nextNodeConfig: OaNextNodeConfig[] = [];
}

/** RunProcess.java（runProcess 响应；处理页成功回调只消费 msg/orUnid） */
export class OaRunProcessResult {
  msg: string = '';
  orUnid: string = '';
}

/** DocNumCategory.Entity/DocNumWord.Entity/DocNumSerialNo.Entity {id, text}
 *  （DocNumberActivity 四列联动共用行；响应 data={content:"[{id,text}]"} 内嵌 JSON 串） */
export class OaDocNumEntity {
  id: string = '';
  text: string = '';
}

/** CheckRecord.java {XLH, JCJLMC}（getCheckRecordsList 单行，巡检记录列表） */
export class OaInspectionRecord {
  XLH: string = '';
  JCJLMC: string = '';

  static fromRecord(rec: Record<string, Object>): OaInspectionRecord {
    const r: OaInspectionRecord = new OaInspectionRecord();
    r.XLH = pickStr(rec, 'XLH');
    r.JCJLMC = pickStr(rec, 'JCJLMC');
    return r;
  }
}

/** Ldmc.java {LDMC}（getLdmcList 单行，楼层名） */
export class OaLdmc {
  LDMC: string = '';

  static fromRecord(rec: Record<string, Object>): OaLdmc {
    const l: OaLdmc = new OaLdmc();
    l.LDMC = pickStr(rec, 'LDMC');
    return l;
  }
}

/** DormitoryCheckRecords.java {recordXlh}（addDormitoryCheckRecords 响应） */
export class OaDormitoryRecord {
  recordXlh: string = '';
}

/** RecordsDetail.DatalistBean.DataBean {QSH, RECORDDETAILXLH, TYPE}（寝室行） */
export class OaInspectionDorm {
  QSH: string = '';
  RECORDDETAILXLH: string = '';
  TYPE: string = '';

  static fromRecord(rec: Record<string, Object>): OaInspectionDorm {
    const d: OaInspectionDorm = new OaInspectionDorm();
    d.QSH = pickStr(rec, 'QSH');
    d.RECORDDETAILXLH = pickStr(rec, 'RECORDDETAILXLH');
    d.TYPE = pickStr(rec, 'TYPE');
    return d;
  }
}

/** RecordsDetail.DatalistBean {name, data}（楼层分组：name=="notCheckList"→"待检查寝室"） */
export class OaInspectionGroup {
  name: string = '';
  data: OaInspectionDorm[] = [];
}

/** RecordsDetail.java {hadScoreSize, datalist}（getRecordsDetail 响应） */
export class OaRecordsDetail {
  hadScoreSize: number = 0;
  datalist: OaInspectionGroup[] = [];
}

/** Reimbursed.java（project/reimbursed|unreimbursed 单行；Gson 字段全 1:1） */
export class OaReimbursed {
  AMOUNT: number = 0;
  BUSINESS_NUMBER: string = '';
  BUSINESS_TYPE: string = '';
  DEPT_NUMBER: string = '';
  DESC: string = '';
  PROJECT_NAME: string = '';
  PROJECT_NUMBER: string = '';
  REIMBURSE_AMOUNT: string = '';
  REIMBURSE_DATE: number = 0;
  REIMBURSE_PEOPLE: string = '';
  REIMBURSE_TYPE: string = '';
  STATUS: string = '';
  SUB_NUMBER: string = '';
  USABLE_AMOUNT: string = '';

  static fromRecord(rec: Record<string, Object>): OaReimbursed {
    const r: OaReimbursed = new OaReimbursed();
    const strs: string[] = ['BUSINESS_NUMBER', 'BUSINESS_TYPE', 'DEPT_NUMBER', 'DESC', 'PROJECT_NAME',
      'PROJECT_NUMBER', 'REIMBURSE_AMOUNT', 'REIMBURSE_PEOPLE', 'REIMBURSE_TYPE', 'STATUS',
      'SUB_NUMBER', 'USABLE_AMOUNT'];
    for (const key of strs) {
      const v: Object = rec[key];
      if (typeof v === 'string') {
        r.setStr(key, v as string);
      } else if (typeof v === 'number') {
        r.setStr(key, String(v as number));
      }
    }
    r.AMOUNT = pickNum(rec, 'AMOUNT');
    const rd: Object = rec['REIMBURSE_DATE'];
    if (typeof rd === 'number') {
      r.REIMBURSE_DATE = rd as number;
    } else if (typeof rd === 'string') {
      const n: number = Number(rd as string);
      r.REIMBURSE_DATE = Number.isNaN(n) ? 0 : n;
    }
    return r;
  }

  setStr(key: string, value: string): void {
    if (key === 'BUSINESS_NUMBER') { this.BUSINESS_NUMBER = value; }
    else if (key === 'BUSINESS_TYPE') { this.BUSINESS_TYPE = value; }
    else if (key === 'DEPT_NUMBER') { this.DEPT_NUMBER = value; }
    else if (key === 'DESC') { this.DESC = value; }
    else if (key === 'PROJECT_NAME') { this.PROJECT_NAME = value; }
    else if (key === 'PROJECT_NUMBER') { this.PROJECT_NUMBER = value; }
    else if (key === 'REIMBURSE_AMOUNT') { this.REIMBURSE_AMOUNT = value; }
    else if (key === 'REIMBURSE_PEOPLE') { this.REIMBURSE_PEOPLE = value; }
    else if (key === 'REIMBURSE_TYPE') { this.REIMBURSE_TYPE = value; }
    else if (key === 'STATUS') { this.STATUS = value; }
    else if (key === 'SUB_NUMBER') { this.SUB_NUMBER = value; }
    else if (key === 'USABLE_AMOUNT') { this.USABLE_AMOUNT = value; }
  }
}
