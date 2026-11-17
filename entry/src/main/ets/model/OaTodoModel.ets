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
