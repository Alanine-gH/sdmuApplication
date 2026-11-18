import { router } from '@kit.ArkUI';
import { ApiService } from '../network/ApiService';
import { ApiResponse } from '../model/ResponseModel';
import { OaSubDeptResult, OaSubDeptUser } from '../model/OaTodoModel';
import { TitleBar } from '../components/TitleBar';
import { EmptyView } from '../components/EmptyView';
import { LoadingView } from '../components/LoadingView';
import { BusinessError } from '@kit.BasicServicesKit';

/**
 * 抄送/人员选择页 — 源码级翻译（W23，原 mock 复刻版清除重写）：
 * APK CarbonCopyListActivity（oa/selector/view，路由 /selector/carboncopy = base.e.a.G）。
 *
 * 【入口】处理页/传阅页/编辑表单 picker（singleUserPicker/multiUserPicker）：
 *   入参 {processId, userFilterNodeId, bmdm, jsid, groupId, mode, currentSize, list, isOpeanSubPeopleList}
 *   mode 缺省 "multiUserPicker"（TextUtils.isEmpty 分流）。
 * 【布局】mobile_campus_oa_activity_carbon_copy.xml：
 *   toolbar_normal（右搜索图标 mobile_campus_oa_search → e.a.H /selector/searchperson，
 *   HAP 无对应页保留入口无跳转）+ MultiStateView（RadioGroup 页签 + 标题行 + common_lv +
 *   layoutBottom 49dip）。
 * 【数据流源码还原】
 *   RadioGroup（rGroup 白底 pad8）三页签：rbGroup"按组织架构选择"（默认选中）/rbRole"按角色选择"
 *   /rbPeople"人员分组"；bmdm/jsid/groupId 全空时显示（f1），isOpeanSubPeopleList=false 隐藏
 *   rbPeople（且 z 清空）。
 *   g3(bmdm) → SelectPImpl.o → SelectModel.Y0：GET getSubDeptList {deptId=bmdm,processId,
 *   userFilterNodeId} → SubDepartment{title,resultData}（实测空参 code=0 title"组织架构(0人)"）；
 *   i3(jsid) → a1：GET getSubRoleList {deptId=jsid}（实测 1145 rows）；h3(groupId) → Z0：
 *   GET getSubUserGroupList {groupId}（实测 0 rows）。
 *   g 回调：u.setData(resultData)；q(tvTitle)=title；o(tvSelected)="已选择：N人"（f3：TYPE=0
 *   +count/TYPE=1 +1）；行含 TYPE=="1" → cb 全选钮显示；空 → q2 空态；-3010 → ERROR_NETWORK；
 *   mode=="singleUserPicker" → cb 隐藏。
 * 【列表】TodoSubDeptSelectAdapter 双视图：
 *   TYPE 空/0（mobile_campus_oa_view_todo_department）：cb INVISIBLE(4)+tvTitle=BMMC+
 *   tvNext"下级"（count==0 隐藏，点击 → f 回调自身页{bmdm|jsid|groupId, mode, list, currentSize,
 *   processId, userFilterNodeId}）；
 *   TYPE 1（mobile_campus_oa_view_sub_dept_person）：行 60dip、组间 topMargin 12（前一项 TYPE
 *   不同）、icon 36dip 四色圆 i%4 green/pink/yellow/blue_circle + XM 首字 + tvName 17fp + tvSub
 *   =SJHM 14fp（空隐藏）+ cb。
 *   行点击（e 类）：cb 置 false；singleUserPicker → 单选；多选 toggle；TYPE=0 行强制不勾选。
 * 【全选】d 类：cb 勾选 → 所有行 checked（TYPE=0 行强制 false）；单选模式切多选。
 * 【提交】c 类 tvSubmit：D+e3().size() > 200 → toast "选择人员不能大于200人,已经超出N人"
 *   （Math.abs 差值）；否则 setResult(list=e3() 勾选+传入 list 合并 HashSet 去重) finish。
 * 【下级返回】onActivityResult 任意 -1 → 透传 list + setResult + finish（逐级冒泡）；
 *   HAP 等价：下级页结果写 'oa_copy_result' → 本页 onPageShow 读到即透传 back；
 *   本页提交也写 'oa_copy_result' + back，由发起方（处理页/编辑表单）onPageShow 消费。
 * 【禁 mock】原 6 条假部门全清；接口实测真实数据/真实空态。
 */
interface CarbonNavParams {
  processId: string;
  userFilterNodeId: string;
  bmdm: string;
  jsid: string;
  groupId: string;
  mode: string;
  currentSize: number;
  isOpeanSubPeopleList: boolean;
}

const PERSON_COLORS: ResourceColor[] = ['#92D860', '#FF8080', '#FFD11F', '#97D0F2'];

@Entry
@Component
struct CarbonCopyListPage {
  @State pageTitle: string = '组织架构';
  @State users: OaSubDeptUser[] = [];
  @State checkedKeys: string[] = [];
  @State selectedCount: number = 0;
  @State isLoading: boolean = true;
  @State showAllCheck: boolean = false;
  @State allChecked: boolean = false;
  @State pageTab: number = 0;
  @State showTabs: boolean = false;
  @State failed: boolean = false;
  @State failMsg: string = '';
  private nav: CarbonNavParams = {
    processId: '', userFilterNodeId: '', bmdm: '', jsid: '', groupId: '',
    mode: 'multiUserPicker', currentSize: 0, isOpeanSubPeopleList: true
  };
  /** 传入已选人员（源码 A list：参与 e3 合并与 f3 计数） */
  private passedList: OaSubDeptUser[] = [];

  aboutToAppear(): void {
    const params: Record<string, Object> | undefined = router.getParams() as Record<string, Object> | undefined;
    if (params !== undefined && params !== null) {
      this.nav.processId = this.strOf(params, 'processId');
      this.nav.userFilterNodeId = this.strOf(params, 'userFilterNodeId');
      this.nav.bmdm = this.strOf(params, 'bmdm');
      this.nav.jsid = this.strOf(params, 'jsid');
      this.nav.groupId = this.strOf(params, 'groupId');
      const mode: Object = params['mode'];
      if (typeof mode === 'string' && (mode as string) !== '') {
        this.nav.mode = mode as string;
      }
      const size: Object = params['currentSize'];
      if (typeof size === 'number') {
        this.nav.currentSize = size as number;
      } else if (typeof size === 'string') {
        const n: number = Number(size as string);
        this.nav.currentSize = Number.isNaN(n) ? 0 : n;
      }
      const openSub: Object = params['isOpeanSubPeopleList'];
      if (typeof openSub === 'boolean') {
        this.nav.isOpeanSubPeopleList = openSub as boolean;
      }
      const listJson: Object = params['list'];
      if (typeof listJson === 'string' && (listJson as string) !== '') {
        this.restorePassed(listJson as string);
      }
    }
    // 源码 y()：isOpeanSubPeopleList=false → z 清空（人员分组入口关闭）
    if (!this.nav.isOpeanSubPeopleList) {
      this.nav.groupId = '';
    }
    // 源码 f1：bmdm/jsid/groupId 全空 → 显示 RadioGroup 页签
    this.showTabs = this.nav.bmdm === '' && this.nav.jsid === '' && this.nav.groupId === '';
    if (this.nav.jsid !== '') {
      this.pageTab = 1;
    } else if (this.nav.groupId !== '') {
      this.pageTab = 2;
    }
    this.loadTabData();
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

  /** 传入已选人员 JSON 解析（源码 intent.getParcelableArrayListExtra("list")） */
  private restorePassed(json: string): void {
    try {
      const parsed: Object = JSON.parse(json) as Object;
      for (const one of ApiService.extractArray(parsed)) {
        this.passedList.push(OaSubDeptUser.fromRecord(ApiService.asRecord(one)));
      }
    } catch (error) {
      const err = error as BusinessError;
      ApiService.logError('CarbonCopyList restorePassed fail: ' + err.message);
    }
  }

  onPageShow(): void {
    // 源码 onActivityResult：下级页返回 → 透传 + finish（AppStorage 冒泡等价）
    const result: string | undefined = AppStorage.get<string>('oa_copy_result');
    if (result !== undefined && result !== '') {
      AppStorage.setOrCreate<string>('oa_copy_result', result);
      this.getUIContext().getRouter().back();
      return;
    }
  }

  /** 源码 g3/i3/h3 分流：页签 → 三接口 */
  private loadTabData(): void {
    this.isLoading = true;
    this.failed = false;
    let call: Promise<ApiResponse<OaSubDeptResult>>;
    if (this.pageTab === 1) {
      call = ApiService.getOaSubRoleList(this.nav.jsid);
    } else if (this.pageTab === 2) {
      call = ApiService.getOaSubUserGroupList(this.nav.groupId);
    } else {
      call = ApiService.getOaSubDeptList(this.nav.bmdm, this.nav.processId, this.nav.userFilterNodeId);
    }
    call
      .then((response: ApiResponse<OaSubDeptResult>) => {
        if (response.code === 1000) {
          return;
        }
        if (response.code === 0) {
          this.users = response.data.resultData;
          this.pageTitle = response.data.title === '' ? '组织架构' : response.data.title;
          this.errorOrEmpty(false);
        } else if (response.code === -3010) {
          this.errorOrEmpty(true);
        } else {
          this.failMsg = response.message;
          this.failed = true;
          this.users = [];
        }
        this.isLoading = false;
        this.refreshCount();
      })
      .catch((error: BusinessError) => {
        ApiService.logError('loadTabData fail: ' + error.message);
        this.failed = true;
        this.failMsg = '网络异常，请稍后重试';
        this.users = [];
        this.isLoading = false;
      });
  }

  /** 源码 a/f/h 类 f(str)：有数据 v(content) / -3010 无数据 ERROR_NETWORK / 无数据 s2 空态 */
  private errorOrEmpty(isNetwork: boolean): void {
    if (this.users.length > 0) {
      this.failed = false;
      return;
    }
    this.failed = isNetwork;
    this.failMsg = isNetwork ? '网络异常，请稍后重试' : '暂无数据';
  }

  /** 源码 g 回调：行含 TYPE=="1" → 全选 cb 显示；singleUserPicker → cb 隐藏 */
  private isPersonRow(row: OaSubDeptUser): boolean {
    return row.TYPE === '1';
  }

  private isChecked(key: string): boolean {
    return this.checkedKeys.indexOf(key) >= 0;
  }

  /** 行勾选键：TYPE=0 用 BMDM，TYPE=1 用 GH（PersonRow 勾选状态） */
  private rowKey(row: OaSubDeptUser): string {
    return row.TYPE === '1' ? row.GH : row.BMDM;
  }

  /** 源码 e 类 onItemClicked：cb 置 false；单选/多选；TYPE=0 行强制不勾选 */
  private onRowClick(row: OaSubDeptUser): void {
    this.allChecked = false;
    const key: string = this.rowKey(row);
    if (row.TYPE !== '1') {
      // 源码 e：TYPE=0 行 setItemChecked(i, false)
      this.refreshCount();
      return;
    }
    if (this.nav.mode === 'singleUserPicker') {
      this.checkedKeys = [key];
    } else if (this.isChecked(key)) {
      const rest: string[] = [];
      for (const k of this.checkedKeys) {
        if (k !== key) {
          rest.push(k);
        }
      }
      this.checkedKeys = rest;
    } else {
      this.checkedKeys = this.checkedKeys.concat([key]);
    }
    this.refreshCount();
  }

  /** 源码 d 类：全选 cb → 所有行 checked（TYPE=0 行强制 false；多选模式） */
  private onAllChecked(value: boolean): void {
    this.allChecked = value;
    const keys: string[] = [];
    for (const row of this.users) {
      if (row.TYPE === '1' && value) {
        keys.push(this.rowKey(row));
      }
    }
    this.checkedKeys = keys;
    this.refreshCount();
  }

  /** 源码 e3()/f3()：勾选 + 传入 list 合并；count：TYPE=0 +count / TYPE=1 +1 */
  private refreshCount(): void {
    let total: number = 0;
    for (const row of this.collectSelected()) {
      total += row.TYPE === '0' ? row.count : 1;
    }
    this.selectedCount = total;
  }

  private collectSelected(): OaSubDeptUser[] {
    const list: OaSubDeptUser[] = [];
    for (const row of this.users) {
      if (this.isChecked(this.rowKey(row))) {
        list.push(row);
      }
    }
    for (const row of this.passedList) {
      list.push(row);
    }
    return list;
  }

  /** 源码 c 类 tvSubmit：200 人上限校验 + setResult + finish */
  private submit(): void {
    const selected: OaSubDeptUser[] = this.collectSelected();
    if (this.nav.currentSize + selected.length > 200) {
      const over: number = Math.abs(this.nav.currentSize + selected.length - 200);
      this.toast('选择人员不能大于200人,已经超出' + over + '人');
      return;
    }
    const rows: Record<string, Object>[] = [];
    for (const row of selected) {
      rows.push({
        'BMDM': row.BMDM, 'BMMC': row.BMMC, 'GH': row.GH, 'XM': row.XM,
        'SJHM': row.SJHM, 'TYPE': row.TYPE, 'count': row.count
      });
    }
    AppStorage.setOrCreate<string>('oa_copy_result', JSON.stringify(rows));
    this.getUIContext().getRouter().back();
  }

  /** 源码 f 回调（tvNext"下级"）：自身页 {bmdm|jsid|groupId, mode, list, currentSize, processId, userFilterNodeId} */
  private gotoChildren(row: OaSubDeptUser): void {
    const selJson: string = JSON.stringify(this.selectedPayload());
    const params: Record<string, Object> = {
      'mode': this.nav.mode,
      'list': selJson,
      'currentSize': this.nav.currentSize,
      'processId': this.nav.processId,
      'userFilterNodeId': this.nav.userFilterNodeId
    };
    if (row.BMDM !== '') {
      params['bmdm'] = row.BMDM;
    } else if (row.JSID !== '') {
      params['jsid'] = row.JSID;
    } else if (row.GROUPID !== '') {
      params['groupId'] = row.GROUPID;
    }
    router.pushUrl({ url: 'pages/CarbonCopyListPage', params: params });
  }

  /** 勾选+传入集合序列化（Parcelable 字段等价） */
  private selectedPayload(): Record<string, Object>[] {
    const rows: Record<string, Object>[] = [];
    for (const row of this.collectSelected()) {
      rows.push({
        'BMDM': row.BMDM, 'BMMC': row.BMMC, 'GH': row.GH, 'XM': row.XM,
        'SJHM': row.SJHM, 'TYPE': row.TYPE, 'count': row.count
      });
    }
    return rows;
  }

  private toast(message: string): void {
    this.getUIContext().getPromptAction().showToast({ message: message });
  }

  build() {
    Column() {
      TitleBar({ title: this.pageTitle, showBack: true })
      if (this.isLoading) {
        Column() {
          LoadingView()
        }
        .width('100%')
        .layoutWeight(1)
      } else if (this.failed) {
        Column() {
          EmptyView({ tipText: this.failMsg === '' ? '暂无数据' : this.failMsg })
        }
        .width('100%')
        .layoutWeight(1)
      } else {
        this.content()
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F2F2F2')
  }

  /** MultiStateView content：页签 + 标题行（cb+tvTitle） + 列表 + layoutBottom */
  @Builder
  content() {
    Column() {
      if (this.showTabs) {
        Row() {
          this.tabItem('按组织架构选择', 0)
          this.tabItem('按角色选择', 1)
          if (this.nav.isOpeanSubPeopleList) {
            this.tabItem('人员分组', 2)
          }
        }
        .width('100%')
        .padding(8)
        .backgroundColor($r('app.color.white'))
      }

      Row() {
        if (this.showAllCheck && this.nav.mode !== 'singleUserPicker') {
          // [W23 修复] @Builder 返回 void 不能链 .onClick（原 381:14）→ Stack 包裹承载点击
          Stack() {
            this.checkBox(this.allChecked)
          }
          .onClick(() => {
            this.onAllChecked(!this.allChecked);
          })
        }
        Text(this.pageTitle)
          .fontSize(17)
          .fontColor($r('app.color.common_color_1'))
          .margin({ left: 12 })
          .layoutWeight(1)
          .maxLines(1)
          .textAlign(TextAlign.Start)
      }
      .width('100%')
      .height(48)
      .margin({ top: 12 })
      .padding({ left: 12, right: 12 })
      .backgroundColor($r('app.color.white'))
      .alignItems(VerticalAlign.Center)

      List() {
        ForEach(this.users, (row: OaSubDeptUser, index: number) => {
          ListItem() {
            this.userRow(row, index)
          }
        }, (row: OaSubDeptUser, index: number) => index + '_' + this.rowKey(row) + '_' + String(this.isChecked(this.rowKey(row))))
      }
      .width('100%')
      .layoutWeight(1)
      .scrollBar(BarState.Off)
      .margin({ top: 12 })

      Row() {
        Text('已选择：' + this.selectedCount + '人')
          .fontSize(16)
          .fontColor($r('app.color.mobile_campus_primary_color_default'))
        Blank()
        Text('确定')
          .fontSize(17)
          .fontColor($r('app.color.white'))
          .backgroundColor($r('app.color.mobile_campus_primary_color_default'))
          .width(80)
          .height('100%')
          .textAlign(TextAlign.Center)
          .onClick(() => {
            this.submit();
          })
      }
      .width('100%')
      .height(49)
      .padding({ left: 12 })
      .alignItems(VerticalAlign.Center)
      .backgroundColor($r('app.color.white'))
    }
    .width('100%')
    .layoutWeight(1)
  }

  @Builder
  tabItem(label: string, index: number) {
    Text(label)
      .fontSize(15)
      .fontColor(this.pageTab === index ? $r('app.color.mobile_campus_primary_color_default')
        : $r('app.color.common_color_1'))
      .margin({ right: 16 })
      .onClick(() => {
        // 源码 g 类：页签切换清空 bmdm/jsid/groupId 对应位并重拉
        this.switchTab(index);
      })
  }

  /** 源码 g 类 onCheckedChanged：rbGroup→v="-1" / rbRole→y="-1" / rbPeople→z="-1" */
  private switchTab(index: number): void {
    if (index === this.pageTab) {
      return;
    }
    this.pageTab = index;
    if (index === 0) {
      this.nav.jsid = '';
      this.nav.groupId = '';
      this.nav.bmdm = '-1';
    } else if (index === 1) {
      this.nav.jsid = '-1';
      this.nav.bmdm = '';
      this.nav.groupId = '';
    } else {
      this.nav.groupId = '-1';
      this.nav.bmdm = '';
      this.nav.jsid = '';
    }
    this.checkedKeys = [];
    this.allChecked = false;
    this.loadTabData();
  }

  /** TodoSubDeptSelectAdapter 双视图行 */
  @Builder
  userRow(row: OaSubDeptUser, index: number) {
    Column() {
      if (row.TYPE !== '1') {
        this.deptRowInner(row)
      } else {
        this.personRowInner(row, index)
      }
    }
    .width('100%')
    .margin({ top: index > 0 && this.prevTypeDiffers(index) ? 12 : 0 })
  }

  /** 源码 getView 行距：i>0 且前一项 TYPE 不同 → topMargin 12 */
  private prevTypeDiffers(index: number): boolean {
    if (index <= 0) {
      return false;
    }
    return this.users[index - 1].TYPE !== this.users[index].TYPE;
  }

  /** TYPE 空/0 部门行：cb INVISIBLE + tvTitle=BMMC + tvNext"下级"（count==0 隐藏） */
  @Builder
  deptRowInner(row: OaSubDeptUser) {
    Column() {
      Row() {
        Circle()
          .width(20)
          .height(20)
          .fill(Color.Transparent)
          .stroke(Color.Transparent)
          .strokeWidth(0)
          .opacity(0)
        Text(row.BMMC)
          .fontSize(17)
          .fontColor($r('app.color.common_color_1'))
          .margin({ left: 12 })
          .maxLines(1)
          .layoutWeight(1)
        if (row.count !== 0) {
          Row() {
            Image($r('app.media.mobile_campus_oa_lowerlevel'))
              .width(14)
              .height(14)
              .margin({ right: 4 })
            Text('下级')
              .fontSize(15)
              .fontColor('#1B6BB7')
          }
          .alignItems(VerticalAlign.Center)
          .onClick(() => {
            this.gotoChildren(row);
          })
        }
      }
      .width('100%')
      .height(48)
      .padding({ left: 12, right: 12 })
      .alignItems(VerticalAlign.Center)
      .backgroundColor($r('app.color.white'))
      .onClick(() => {
        this.onRowClick(row);
      })

      Divider().color($r('app.color.common_color_5')).strokeWidth(0.5)
    }
    .width('100%')
    .backgroundColor($r('app.color.white'))
  }

  /** TYPE 1 人员行：cb20 + 四色圆36 XM 首字 + tvName 17fp + tvSub=SJHM 14fp */
  @Builder
  personRowInner(row: OaSubDeptUser, index: number) {
    Column() {
      Row() {
        this.checkBox(this.isChecked(this.rowKey(row)))
        Text(row.XM.length > 0 ? row.XM.substring(0, 1) : '')
          .fontSize(18.5)
          .fontColor($r('app.color.white'))
          .width(36)
          .height(36)
          .textAlign(TextAlign.Center)
          .borderRadius(18)
          .backgroundColor(PERSON_COLORS[index % 4])
          .margin({ left: 12 })
        Column() {
          Text(row.XM)
            .fontSize(17)
            .fontColor($r('app.color.common_color_1'))
            .maxLines(1)
          if (row.SJHM !== '') {
            Text(row.SJHM)
              .fontSize(14)
              .fontColor($r('app.color.mobile_campus_oa_meeting'))
              .margin({ top: 4 })
              .maxLines(1)
          }
        }
        .alignItems(HorizontalAlign.Start)
        .margin({ left: 12 })
        .layoutWeight(1)
      }
      .width('100%')
      .height(60)
      .padding({ left: 12, right: 12 })
      .alignItems(VerticalAlign.Center)
      .backgroundColor($r('app.color.white'))
      .onClick(() => {
        this.onRowClick(row);
      })

      Divider().color($r('app.color.common_color_5')).strokeWidth(0.5)
    }
    .width('100%')
    .backgroundColor($r('app.color.white'))
  }

  /** mobile_campus_oa_todo_cb 复选框20（HAP Circle 等价实现，沿 W9 DepartmentListPage） */
  @Builder
  checkBox(checked: boolean) {
    Stack() {
      Circle()
        .width(20)
        .height(20)
        .fill(Color.Transparent)
        .stroke(checked ? $r('app.color.mobile_campus_primary_color_default') : $r('app.color.common_color_3'))
        .strokeWidth(1)
      if (checked) {
        Text('✓')
          .fontSize(12)
          .fontColor($r('app.color.white'))
          .backgroundColor($r('app.color.mobile_campus_primary_color_default'))
          .width(20)
          .height(20)
          .textAlign(TextAlign.Center)
          .borderRadius(10)
      }
    }
    .width(20)
    .height(20)
  }
}
