import { router } from '@kit.ArkUI';
import { ApiService } from '../network/ApiService';
import { ApiResponse } from '../model/ResponseModel';
import { OaDepartment as OaDepartmentData, OaDepartmentBean } from '../model/ContactModel';
import { TitleBar } from '../components/TitleBar';
import { EmptyView } from '../components/EmptyView';
import { LoadingView } from '../components/LoadingView';

/**
 * 部门选择页 — 源码级翻译（oa/selector/view/DepartmentListActivity.java 逐行 → ArkTS）：
 *
 * 【入口】OA 待办/会议等选人选部门流程：{bmdm, mode, list}(list=已选部门 Parcelable 数组)；
 *   mode 缺省 "singleDeptPicker"（TextUtils.isEmpty 判断）→ ListView 单选，否则多选。
 *
 * 【请求】T2(bmdm 空→"-1") → SelectPImpl.j → SelectModel.T0：
 *   e.b(SelectFactory.g("getDepartment")) + {deptId}（oa/b/b.java api/select；
 *   实测 2026-11-17 {deptId:"-1"} code=0 → Department{title:"组织架构(907人)",
 *   departmentList:[{BMDM:"000",BMMC:"山东管理学院",BMLX:"2",PXH,TYPE,SJBMDM:"-1",count:907,isChildren:"1",XLH:"0"}]}）
 *   a.g()：adapter.setData(departmentList)；tvTitle=title；"已选择"=V2()（U2 count 求和）
 *   空 → q2 空态；-3010 → ERROR_NETWORK
 *
 * 【列表】TodoDepartmentSelectedAdapter（mobile_campus_oa_view_todo_department.xml）：
 *   白底 padL12 行48(px_to_dip_96) pr12：cb 20dip(px_to_dip_40 mobile_campus_oa_todo_cb
 *   选中 mobile_campus_oa_choose/未选 mobile_campus_oa_chose，HAP 无 chose 资源沿项目 Circle 等价)
 *   tvTitle 17sp(px_to_sp_34) common_color_1 ml12；tvNext 15sp(px_to_sp_30) #1B6BB7 "下级"
 *   （mobile_campus_oa_lowerlevel 图标 dp4 间距）—— isChildren=="0" 或该行已勾选时隐藏；
 *   tvNext 点击（e 类）→ 自身页{bmdm:BMDM, mode, list:U2()} 123
 *   行点击（d.onItemClick）：全选 cb 置 false；singleDeptPicker → 单选勾该行；否则多选 toggle；
 *   刷新"已选择：N人"
 * 【全选】c 类：所有行 setItemChecked(cb.isChecked)；刷新计数
 * 【底部】layoutBottom 49dip(px_to_dip_98) 白底 padL12：tvSelected 16sp(px_to_sp_32)
 *   mobile_campus_primary_color_default "已选择：N人"（V2 = 勾选+传入 list 的 count 求和）；
 *   tvSubmit 17sp 白字 primary bg 宽80(px_to_dip_160) → b 类 setResult(U2) finish
 * 【下级/搜索返回】onActivityResult 123 结果 → 透传 setResult(list) finish（逐级冒泡）；
 *   HAP 等价：结果写 AppStorage 'oa_dept_result' + router.back() 逐层透传，由发起方消费
 * 【toolbar】右侧 mobile_campus_oa_search 图标（f 类）→ 部门搜索页（base.e.a.I）123
 */
@Entry
@Component
struct DepartmentListPage {
  @State pageTitle: string = '组织架构';
  @State departments: OaDepartmentBean[] = [];
  /** 行勾选状态（源码 ListView choiceMode：单选/多选） */
  @State checkedKeys: string[] = [];
  @State allChecked: boolean = false;
  @State selectedCount: number = 0;
  @State isLoading: boolean = true;
  /** 源码 t：intent "bmdm"（空 → "-1"） */
  private bmdm: string = '';
  /** 源码 v：intent mode（缺省 singleDeptPicker 单选） */
  private mode: string = 'singleDeptPicker';
  /** 源码 u：传入已选部门（参与 U2 合并与 V2 计数，不预勾选） */
  private passedList: OaDepartmentBean[] = [];

  aboutToAppear(): void {
    const params: Record<string, Object> | undefined = router.getParams() as Record<string, Object> | undefined;
    if (params !== undefined && params !== null) {
      const bm: Object = params['bmdm'];
      if (typeof bm === 'string') {
        this.bmdm = bm as string;
      }
      const md: Object = params['mode'];
      if (typeof md === 'string' && (md as string) !== '') {
        this.mode = md as string;
      }
      const sel: Object = params['selList'];
      if (typeof sel === 'string') {
        this.restorePassed(sel as string);
      }
    }
    this.refreshCount();
  }

  /** 传入已选部门 JSON 解析（源码 intent.getParcelableArrayListExtra("list")） */
  private restorePassed(json: string): void {
    try {
      const parsed: Object = JSON.parse(json) as Object;
      if (Array.isArray(parsed)) {
        const list: OaDepartmentBean[] = [];
        for (const one of parsed as Object[]) {
          const rec: Record<string, Object> = one as Record<string, Object>;
          const bean: OaDepartmentBean = new OaDepartmentBean();
          bean.BMDM = ApiService.pick(rec, ['BMDM']);
          bean.BMMC = ApiService.pick(rec, ['BMMC']);
          bean.BMLX = ApiService.pick(rec, ['BMLX']);
          bean.count = ApiService.pickNumber(rec, ['count']);
          bean.isChildren = ApiService.pick(rec, ['isChildren']);
          list.push(bean);
        }
        this.passedList = list;
      }
    } catch {
      ApiService.logError('DepartmentListPage restorePassed fail');
    }
  }

  onPageShow(): void {
    // 源码 onActivityResult：下级/搜索页返回结果 → 透传 + finish（AppStorage 冒泡等价）
    const result: string | undefined = AppStorage.get<string>('oa_dept_result');
    if (result !== undefined && result !== '') {
      AppStorage.setOrCreate<string>('oa_dept_result', result);
      this.getUIContext().getRouter().back();
      return;
    }
    this.loadDepartment();
  }

  /** 源码 T2(bmdm 空→"-1")：请求 getDepartment{deptId} */
  private loadDepartment(): void {
    this.isLoading = true;
    ApiService.getOaDepartment(this.bmdm === '' ? '-1' : this.bmdm)
      .then((response: ApiResponse<OaDepartmentData>) => {
        if (response.code === 1000) {
          // 登录失效统一处理已在网络层触发（HttpClient.bizRequest 拦截：清会话+toast+跳登录）
          return;
        }
        if (response.code === 0) {
          this.departments = response.data.departmentList;
          this.pageTitle = response.data.title === '' ? '组织架构' : response.data.title;
        } else {
          ApiService.logError('DepartmentListPage load fail code=' + response.code + ' msg=' + response.message);
          this.departments = [];
          this.pageTitle = '组织架构';
        }
        this.isLoading = false;
        this.refreshCount();
      })
      .catch(() => {
        ApiService.logError('DepartmentListPage load error');
        this.departments = [];
        this.isLoading = false;
      });
  }

  private isChecked(bmdm: string): boolean {
    return this.checkedKeys.indexOf(bmdm) >= 0;
  }

  /** 源码 d.onItemClick：全选 cb 置 false；singleDeptPicker → setItemChecked(i, true)
   *  （q 先置 false，true^false 恒 true → 单选恒选中，不可点击取消）；多选 toggle；刷新计数 */
  private onRowClick(bean: OaDepartmentBean): void {
    this.allChecked = false;
    if (this.mode === 'singleDeptPicker') {
      this.checkedKeys = [bean.BMDM];
    } else if (this.isChecked(bean.BMDM)) {
      const rest: string[] = [];
      for (const k of this.checkedKeys) {
        if (k !== bean.BMDM) {
          rest.push(k);
        }
      }
      this.checkedKeys = rest;
    } else {
      this.checkedKeys = this.checkedKeys.concat([bean.BMDM]);
    }
    this.refreshCount();
  }

  /** 源码 c 类：全选 cb → 所有行 setItemChecked(cb.isChecked)；刷新计数 */
  private onAllChecked(value: boolean): void {
    this.allChecked = value;
    const keys: string[] = [];
    if (value) {
      for (const bean of this.departments) {
        keys.push(bean.BMDM);
      }
    }
    this.checkedKeys = keys;
    this.refreshCount();
  }

  /** 源码 U2()：勾选项 + 传入已选 list 合并 */
  private collectSelected(): OaDepartmentBean[] {
    const list: OaDepartmentBean[] = [];
    for (const bean of this.departments) {
      if (this.isChecked(bean.BMDM)) {
        list.push(bean);
      }
    }
    for (const bean of this.passedList) {
      list.push(bean);
    }
    return list;
  }

  /** 源码 V2()：U2 全部 count 求和 */
  private refreshCount(): void {
    let total: number = 0;
    for (const bean of this.collectSelected()) {
      total += bean.count;
    }
    this.selectedCount = total;
  }

  /** 源码 b 类 tvSubmit：setResult(U2) finish → AppStorage 'oa_dept_result' + back */
  private submit(): void {
    AppStorage.setOrCreate<string>('oa_dept_result', JSON.stringify(this.selectedPayload()));
    this.getUIContext().getRouter().back();
  }

  /** U2 序列化（BMDM/BMMC/BMLX/count/isChildren 与源码 Parcelable 字段一致） */
  private selectedPayload(): Record<string, Object>[] {
    const rows: Record<string, Object>[] = [];
    for (const bean of this.collectSelected()) {
      const row: Record<string, Object> = {
        'BMDM': bean.BMDM, 'BMMC': bean.BMMC, 'BMLX': bean.BMLX,
        'count': bean.count, 'isChildren': bean.isChildren
      };
      rows.push(row);
    }
    return rows;
  }

  /** 源码 e 类 tvNext：自身页{bmdm:BMDM, mode, list:U2()} */
  private gotoChildren(bean: OaDepartmentBean): void {
    const selJson: string = JSON.stringify(this.selectedPayload());
    router.pushUrl({ url: 'pages/DepartmentListPage',
      params: { 'bmdm': bean.BMDM, 'mode': this.mode, 'selList': selJson } as Record<string, string> });
  }

  /** 源码 f 类 toolbar 搜索图标 → 部门搜索页（base.e.a.I，HAP 现有 TodoSearchDepartmentPage） */
  private gotoSearch(): void {
    router.pushUrl({ url: 'pages/TodoSearchDepartmentPage' });
  }

  build() {
    Column() {
      TitleBar({ title: this.pageTitle, showBack: true })
      if (this.isLoading) {
        LoadingView()
      } else if (this.departments.length === 0) {
        Column() {
          EmptyView({ tipText: '暂无部门数据' })
        }
        .width('100%')
        .layoutWeight(1)
      } else {
        this.deptContent()
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F2F2F2')
  }

  /** MultiStateView content：全选行(mt12 mb12) + ListView + layoutBottom */
  @Builder
  deptContent() {
    Column() {
      // 全选行：白底 48dip padH12 cb20 + tvTitle 17sp ml12
      Row() {
        this.checkBox(this.allChecked)
        Text(this.pageTitle)
          .fontSize(17)
          .fontColor($r('app.color.common_color_1'))
          .height(48)
          .margin({ left: 12 })
          .layoutWeight(1)
          .maxLines(1)
          .textAlign(TextAlign.Start)
      }
      .width('100%')
      .height(48)
      .margin({ top: 12, bottom: 12 })
      .padding({ left: 12, right: 12 })
      .backgroundColor($r('app.color.white'))
      .alignItems(VerticalAlign.Center)
      .onClick(() => {
        this.onAllChecked(!this.allChecked);
      })

      List() {
        ForEach(this.departments, (bean: OaDepartmentBean) => {
          ListItem() {
            this.deptRow(bean)
          }
        }, (bean: OaDepartmentBean) => bean.BMDM + '_' + bean.XLH)
      }
      .width('100%')
      .layoutWeight(1)
      .scrollBar(BarState.Off)
      .backgroundColor($r('app.color.white'))

      // layoutBottom：49dip 白底 padL12 已选择 + 确定
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

  /** mobile_campus_oa_view_todo_department：行48 padL12 pr12 cb20 + tvTitle17 ml12 + tvNext15#1B6BB7 */
  @Builder
  deptRow(bean: OaDepartmentBean) {
    Column() {
      Row() {
        this.checkBox(this.isChecked(bean.BMDM))
        Text(bean.BMMC)
          .fontSize(17)
          .fontColor($r('app.color.common_color_1'))
          .margin({ left: 12 })
          .maxLines(1)
          .layoutWeight(1)
          .flexShrink(1)

        // tvNext "下级"：isChildren=="0" 或已勾选 → 隐藏（源码 setVisibility 分流）
        if (bean.isChildren !== '0' && !this.isChecked(bean.BMDM)) {
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
            this.gotoChildren(bean);
          })
        }
      }
      .width('100%')
      .height(48)
      .padding({ left: 12, right: 12 })
      .alignItems(VerticalAlign.Center)
      .backgroundColor($r('app.color.white'))
      .onClick(() => {
        this.onRowClick(bean);
      })

      Divider()
        .color($r('app.color.common_color_5'))
        .strokeWidth(0.8)
        .width('100%')
    }
    .width('100%')
    .backgroundColor($r('app.color.white'))
  }

  /** mobile_campus_oa_todo_cb 复选框20（选中 choose/未选 chose；HAP 沿项目 Circle 等价实现） */
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
