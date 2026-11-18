import { router } from '@kit.ArkUI';
import { ApiService } from '../network/ApiService';
import { ApiResponse } from '../model/ResponseModel';
import { OaTodoDetail, OaWorkApplyRow, OaWorkApplyFlowNode, OaWorkApplyAttach,
  OaFormField } from '../model/OaTodoModel';
import { LoginSession } from '../network/LoginSession';
import { BusinessError } from '@kit.BasicServicesKit';
import { LoadingView } from '../components/LoadingView';
import { EmptyView } from '../components/EmptyView';

/**
 * 业务申请详情页 — 1:1 翻译原 APK WorkApplyDetailActivity.java(712行)：
 *
 * 【布局】mobile_campus_oa_activity_workapply_detail.xml：MultiStateView[自定义头 44vp
 *   (back_icon + toolBar_title 18.5fp bold[invisible 初始，w3 只 setText 不改可见态] +
 *   tool_layout[撤回/编辑 均 gone]) + NestedScrollView(bg common_color_6)[edit_container 白底：
 *   detail_header + divider(12vp) + name2 "当前节点" 16fp 高36vp + 细线] +
 *   mobile_campus_handle_process("处理流程" gone)]。
 *   detail_header（mobile_campus_oa_workapply_detail_header.xml）：header_tag_container
 *   [emergency(蓝底白字)/wei(green)/cuiban(blue)] + header_title 18.5fp bold + btn_cuiban
 *   （16fp primary shape_border_darkblue 描边 padV10 白底）。
 *
 * 【数据流源码还原】
 *   1. y(Intent)：A=applybean(RowsBean)、H=type("apply")；B=subject、D=processid、E=orUnid。
 *   2. f1：w3()：l/q 标题；C（紧急程度）源码无赋值 → TextUtils.isEmpty(C) → tag 容器恒隐藏；
 *      A.bussStatus=="1" → btn_cuiban"已催办"禁用；m/s 按钮双分支均 setVisibility(8) 恒隐藏。
 *   3. o3：TodoPImpl.C(E,H,currentnodeid) → TodoModel.j1 → GET transactionDetails
 *      {xlh:orUnid, todo_type:"db", currentnodeid} → TodoDetail；a.g：formFieldConfigList 空时
 *      隐藏编辑钮（本就隐藏）；I=u3(detail){LX:"1",processId,YYID:"todoitem_detail",yhid:author,
 *      XLH:orUnid,nodeName}；J=t3(){title,content}=subject。
 *   4. q3(detail)：processFlowDocList → ProcedureLayout(FLOWING)（TimelineLayout 节点行：
 *      圆点 grey/green + process_tag 白字 greybox/greenbox（nodeName 空回退"审核/确认"）+
 *      处理人 15fp + career 15fp（首行 BOTTOM"发出申请"，其余 deptName）+ 意见 15fp primary +
 *      日期右上 12fp（commonSetting：endTime，空 INVISIBLE）；q3 末节点 nextNodeName 空→"审核"；
 *      p() 单节点 → BOTTOM+伪 TOP/CURRENT 行（userName=nextUserList||当前用户），多节点末行
 *      nextNodeName 非空 → TOP+CURRENT）+ 灰条；formFieldConfigList → 控件 d(bean) 带值渲染 + 灰条；
 *      bpmAttachList → 附件条（realFileName/downloadUrl/fileSize）+ 灰条。
 *   5. btn_cuiban d → s3(I,J)：ApplyModel.Y0 → POST sendBuss {property:I, message:J} →
 *      成功：x2("")、t="已催办"禁用、setResult(-1)；失败 f → m(str2) toast。
 *   6. 附件 i 回调：downloadUrl 含 "wf_num=R_convertPDF_B011" → WebView(a.w){url,title}；
 *      否则下载到缓存目录后系统预览（HAP 无本地文件预览基建：非 PDF 转换链展示文件名 toast）。
 *
 * 【HAP 等价】入参 AppStorage 'workapply_detail_row'；表单区以只读展示行呈现（控件矩阵
 *   外观复用 WorkApplyFormConfigPage；详情页无提交出口且测试账号无 OA 数据真实不可达）。
 */

interface UrgeProperty {
  LX: string;
  processId: string;
  YYID: string;
  yhid: string;
  XLH: string;
  nodeName: string;
}

interface UrgeMessage {
  title: string;
  content: string;
}

/**
 * TimelineLayout 节点行 VM（ProcedureLayout FLOWING + TimelineLayout.parseData 1:1）：
 *   tag=process_tag（nodeName 空回退"审核/确认"，白字 greybox/greenbox 底）、
 *   userName=process_handler、career=process_career（BOTTOM/NONE 固定"发出申请"，其余 deptName）、
 *   remark=process_comment（primary 色）、date=process_date（commonSetting：endTime，空 INVISIBLE）、
 *   current=FLOW_STATE.CURRENT（绿点+greenbox）
 */
class FlowRowVM {
  nodeName: string = '';
  userName: string = '';
  career: string = '';
  remark: string = '';
  date: string = '';
  current: boolean = false;
}

@Entry
@Component
struct WorkApplyDetailPage {
  @State row: OaWorkApplyRow = new OaWorkApplyRow();
  @State detail: OaTodoDetail = new OaTodoDetail();
  /** 源码 ProcedureLayout.p(FLOWING) 渲染出的时间线行（q3 修补 nextNodeName 后构建） */
  @State flowRows: FlowRowVM[] = [];
  @State loading: boolean = true;
  @State failed: boolean = false;
  @State loadErrMsg: string = '';
  /** 源码 btn_cuiban：bussStatus=="1" 或催办成功后 → "已催办"禁用 */
  @State urged: boolean = false;
  @State urging: boolean = false;
  /** 源码 u3/t3：催办 property/message JSON（详情回调后生成） */
  private urgeProperty: string = '';
  private urgeMessage: string = '';

  aboutToAppear(): void {
    const raw: string | undefined = AppStorage.get<string>('workapply_detail_row');
    if (raw !== undefined && raw !== '') {
      try {
        this.row = JSON.parse(raw) as OaWorkApplyRow;
      } catch (error) {
        const err = error as BusinessError;
        ApiService.logError('WorkApplyDetail row parse fail: ' + err.message);
      }
    }
    if (this.row.bussStatus === '1') {
      this.urged = true;
    }
    this.fetchDetail();
  }

  /** 源码 o3 → TodoModel.j1：GET transactionDetails {xlh, todo_type:"db", currentnodeid} */
  private fetchDetail(): void {
    ApiService.getOaTodoDetail(this.row.orUnid, 'db', this.row.currentnodeid)
      .then((response: ApiResponse<OaTodoDetail>) => {
        if (response.code === 1000) {
          return;
        }
        if (response.code === 0) {
          this.detail = response.data;
          this.buildFlowRows();
          this.buildUrgePayload(response.data);
          this.loading = false;
          this.failed = false;
        } else {
          this.loading = false;
          this.failed = true;
          this.loadErrMsg = response.message === '' ? '获取详情失败' : response.message;
        }
      })
      .catch((error: BusinessError) => {
        ApiService.logError('WorkApplyDetail fetch fail: ' + error.message);
        this.loading = false;
        this.failed = true;
        this.loadErrMsg = '网络异常，请稍后重试';
      });
  }

  /** 源码 a.g：I=u3(detail){LX,processId,YYID,yhid,XLH,nodeName}；J=t3(){title,content} */
  private buildUrgePayload(detail: OaTodoDetail): void {
    const property: UrgeProperty = {
      LX: '1',
      processId: this.row.processid,
      YYID: 'todoitem_detail',
      yhid: detail.itemBasicInfoMap.author,
      XLH: this.row.orUnid,
      nodeName: detail.itemBasicInfoMap.nodeName
    };
    const message: UrgeMessage = {
      title: this.row.subject,
      content: this.row.subject
    };
    this.urgeProperty = JSON.stringify(property);
    this.urgeMessage = JSON.stringify(message);
  }

  /** 源码 s3(I,J)：POST sendBuss {property, message}；成功 → "已催办"禁用 + setResult(-1) */
  private urgeClick(): void {
    if (this.urged || this.urging) {
      return;
    }
    this.urging = true;
    ApiService.sendWorkApplyUrge(this.urgeProperty, this.urgeMessage)
      .then((response: ApiResponse<Object>) => {
        this.urging = false;
        if (response.code === 0) {
          this.urged = true;
        } else {
          this.getUIContext().getPromptAction().showToast({
            message: response.message === '' ? '催办失败' : response.message
          });
        }
      })
      .catch((error: BusinessError) => {
        this.urging = false;
        ApiService.logError('WorkApplyDetail urge fail: ' + error.message);
        this.getUIContext().getPromptAction().showToast({ message: '网络异常，请稍后重试' });
      });
  }

  /** 源码 i 回调：R_convertPDF_B011 → WebView；其余条目展示（本地预览基建未建） */
  private openAttach(attach: OaWorkApplyAttach): void {
    if (attach.realFileName === '' || attach.downloadUrl === '') {
      this.getUIContext().getPromptAction().showToast({ message: '文件名或下载地址为空~' });
      return;
    }
    if (attach.downloadUrl.includes('wf_num=R_convertPDF_B011')) {
      router.pushUrl({
        url: 'pages/WebViewPage',
        params: {
          'navigationBarTitle': attach.realFileName,
          'url': attach.downloadUrl
        } as Record<string, string>
      });
      return;
    }
    this.getUIContext().getPromptAction().showToast({ message: attach.realFileName });
  }

  private toast(message: string): void {
    this.getUIContext().getPromptAction().showToast({ message: message });
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
            // name2："当前节点"（源码未赋值内容，16fp common_color_3 高36vp px12）
            Text('当前节点')
              .fontSize(16)
              .fontColor($r('app.color.common_color_3'))
              .width('100%')
              .height(36)
              .padding({ left: 12, right: 12 })
            Divider().color($r('app.color.common_color_5')).strokeWidth(0.5).width('100%')
            this.dynamicBody()
          }
          .width('100%')
        }
        .layoutWeight(1)
        .scrollBar(BarState.Off)
        .backgroundColor($r('app.color.common_color_6'))
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.white'))
  }

  /** 自定义头 44vp：back + toolBar_title（源码 invisible，保真透明占位） */
  @Builder
  topBar() {
    Row() {
      Image($r('app.media.nav_back_btn'))
        .width(28)
        .height(28)
        .padding(5)
        .margin({ left: 10 })
        .onClick(() => {
          router.back();
        })
      Text(this.row.subject)
        .fontSize(18.5)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.common_color_1'))
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .margin({ left: 10, right: 10 })
        .layoutWeight(1)
        .opacity(0)
      Blank().width(38)
    }
    .width('100%')
    .height(44)
    .alignItems(VerticalAlign.Center)
    .backgroundColor($r('app.color.white'))
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP])
  }

  /** detail_header：tag 容器（C 恒空隐藏）+ 标题 + 催办钮 */
  @Builder
  detailHeader() {
    Column() {
      Text(this.row.subject === '' ? '-' : this.row.subject)
        .fontSize(18.5)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.common_color_1'))
        .maxLines(2)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .width('100%')
        .margin({ top: 12, bottom: 16 })
      // btn_cuiban：shape_border_darkblue 描边 16fp primary 白底 padV10
      Text(this.urged ? '已催办' : '催办')
        .fontSize(16)
        .fontColor($r('app.color.mobile_campus_primary_color_default'))
        .textAlign(TextAlign.Center)
        .width('100%')
        .padding({ top: 10, bottom: 10 })
        .border({ width: 0.5, color: $r('app.color.mobile_campus_primary_color_default') })
        .opacity(this.urged ? 0.5 : 1)
        .onClick(() => {
          this.urgeClick();
        })
    }
    .width('100%')
    .padding({ left: 12, right: 12, top: 12, bottom: 16 })
  }

  /** q3 动态体：流程时间线 + 表单展示 + 附件 */
  @Builder
  dynamicBody() {
    Column() {
      if (this.flowRows.length > 0) {
        ForEach(this.flowRows, (row: FlowRowVM, ni: number) => {
          this.flowRow(row)
        }, (row: FlowRowVM, ni: number) => ni.toString() + row.nodeName + row.userName)
        Row()
          .width('100%')
          .height(12)
          .backgroundColor($r('app.color.common_color_6'))
      }
      if (this.detail.formFieldConfigList.length > 0) {
        ForEach(this.detail.formFieldConfigList, (field: OaFormField, fi: number) => {
          this.formShowRow(field)
        }, (field: OaFormField, fi: number) => fi.toString() + field.fieldNumber.toString())
        Row()
          .width('100%')
          .height(12)
          .backgroundColor($r('app.color.common_color_6'))
      }
      if (this.detail.bpmAttachList.length > 0) {
        ForEach(this.detail.bpmAttachList, (attach: OaWorkApplyAttach, ai: number) => {
          this.attachRow(attach)
        }, (attach: OaWorkApplyAttach, ai: number) => ai.toString() + attach.wfOrUnid)
        Row()
          .width('100%')
          .height(12)
          .backgroundColor($r('app.color.common_color_6'))
      }
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }

  /**
   * 源码 ProcedureLayout.p(FLOWING) + WorkApplyDetailActivity.q3：
   *   q3：最后一节点 nextNodeName 空 → "审核"（渲染前修补）。
   *   p() 单节点：BOTTOM 行 + 伪 TOP/CURRENT 行（nodeName=nextNodeName，userName=nextUserList，
   *     空→当前登录用户 d.a.c().getUserName()=LoginSession.sessionName）。
   *   p() 多节点：首行 BOTTOM（career"发出申请"）、中段 NORMAL、末行 TOP；末行 nextNodeName
   *     非空 → TOP+CURRENT（伪节点分支 n2 未 addView，源码死代码不复现）。
   */
  private buildFlowRows(): void {
    const list: OaWorkApplyFlowNode[] = this.detail.processFlowDocList;
    const rows: FlowRowVM[] = [];
    if (list.length === 0) {
      this.flowRows = rows;
      return;
    }
    const lastNode: OaWorkApplyFlowNode = list[list.length - 1];
    if (lastNode.nextNodeName === '') {
      lastNode.nextNodeName = '审核';
    }
    // 源码 p()：this.i = list[0].userId 仅多节点时赋值（setNodeState 回退"确认"判定基准）
    const creatorId: string = list.length > 1 ? list[0].userId : '';
    if (list.length === 1) {
      rows.push(this.flowRowOf(list[0], creatorId, true, false));
      const pseudo: OaWorkApplyFlowNode = new OaWorkApplyFlowNode();
      pseudo.nodeName = list[0].nextNodeName;
      pseudo.userName = list[0].nextUserList === '' ? LoginSession.sessionName : list[0].nextUserList;
      rows.push(this.flowRowOf(pseudo, creatorId, false, true));
    } else {
      for (let i = 0; i < list.length; i++) {
        const node: OaWorkApplyFlowNode = list[i];
        if (i === 0) {
          // BOTTOM 类型（career"发出申请"）
          rows.push(this.flowRowOf(node, creatorId, true, false));
        } else if (i === list.length - 1) {
          // 末行 TOP：nextNodeName 非空 → FLOW_STATE.CURRENT（绿点/greenbox）
          rows.push(this.flowRowOf(node, creatorId, false, node.nextNodeName !== ''));
        } else {
          rows.push(this.flowRowOf(node, creatorId, false, false));
        }
      }
    }
    this.flowRows = rows;
  }

  /**
   * TimelineLayout.parseData/commonSetting/setNodeState 行内容：
   *   career：BOTTOM/NONE 固定"发出申请"，TOP/NORMAL 取 deptName（空隐藏）；
   *   date：commonSetting 取 endTime（空 INVISIBLE）；comment：remark（BOTTOM/NONE trim 判定）；
   *   tag：nodeName 空回退（userId 空或 ≠ createUserId → "审核"，否则"确认"）。
   */
  private flowRowOf(node: OaWorkApplyFlowNode, creatorId: string, isStart: boolean, current: boolean): FlowRowVM {
    const row: FlowRowVM = new FlowRowVM();
    if (node.nodeName !== '') {
      row.nodeName = node.nodeName;
    } else if (node.userId === '' || node.userId.trim() !== creatorId) {
      row.nodeName = '审核';
    } else {
      row.nodeName = '确认';
    }
    row.userName = node.userName;
    row.career = isStart ? '发出申请' : node.deptName;
    if (node.remark !== '' && (isStart ? node.remark.trim() !== '' : true)) {
      row.remark = node.remark;
    }
    row.date = node.endTime;
    row.current = current;
    return row;
  }

  /** TimelineLayout 节点行（mobile_campus_oa_todoitem_process.xml）：圆点 + tag chip + 处理人 + 单位/发出申请 + 意见 + 日期 */
  @Builder
  flowRow(row: FlowRowVM) {
    Row() {
      Image(row.current ? $r('app.media.mobile_campus_oa_circle_green') : $r('app.media.mobile_campus_oa_circle_grey'))
        .width(15)
        .height(15)
        .margin({ left: 15, right: 6 })
      Column() {
        Row() {
          // process_tag：白字 10fp，greybox/greenbox 底（setNodeState：CURRENT → greenbox）
          Text(row.nodeName)
            .fontSize(10)
            .fontColor($r('app.color.white'))
            .padding({ left: 13, right: 9, top: 2, bottom: 2 })
            .backgroundImage(row.current ? $r('app.media.mobile_campus_oa_greenbox_9')
              : $r('app.media.mobile_campus_oa_greybox'))
            .backgroundImageSize(ImageSize.Cover)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
          Blank()
          // process_date：commonSetting → endTime（空隐藏）
          if (row.date !== '') {
            Text(row.date)
              .fontSize(12)
              .fontColor($r('app.color.common_color_3'))
              .margin({ left: 8 })
          }
        }
        .width('100%')
        .margin({ top: 6 })
        // process_handler
        if (row.userName !== '') {
          Text(row.userName)
            .fontSize(15)
            .fontColor($r('app.color.common_color_1'))
            .margin({ top: 2 })
        }
        // process_career：BOTTOM"发出申请"/其余 deptName（空隐藏）
        if (row.career !== '') {
          Text(row.career)
            .fontSize(15)
            .fontColor($r('app.color.common_color_3'))
            .margin({ top: 2 })
        }
        // process_comment：primary 色
        if (row.remark !== '') {
          Text(row.remark)
            .fontSize(15)
            .fontColor($r('app.color.mobile_campus_primary_color_default'))
            .margin({ top: 2 })
        }
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
      .margin({ right: 12 })
    }
    .width('100%')
    .padding({ top: 8, bottom: 12 })
    .alignItems(VerticalAlign.Top)
  }

  /** formFieldConfigList 只读展示行（源码控件带值渲染；无提交出口 → 展示行呈现） */
  @Builder
  formShowRow(field: OaFormField) {
    Column() {
      Row() {
        Text(field.fieldScreenName)
          .fontSize(16)
          .fontColor($r('app.color.common_color_3'))
          .width(80)
        Text(this.fieldDisplay(field))
          .fontSize(16)
          .fontColor($r('app.color.common_color_1'))
          .layoutWeight(1)
      }
      .width('100%')
      .padding({ left: 12, right: 12, top: 15, bottom: 15 })
      Divider().color($r('app.color.common_color_5')).strokeWidth(0.5).width('100%')
    }
    .width('100%')
  }

  /** 字段展示值：picker/attachment 类取 fieldValue（逗号串），date 原值，空显示 "-" */
  private fieldDisplay(field: OaFormField): string {
    const t: string = field.fieldType;
    if (t === 'select' || t === 'radio') {
      return field.fieldAnotherValue === '' ? field.fieldValue : field.fieldAnotherValue;
    }
    if (t === 'file') {
      return field.fieldValue === '' ? '-' : field.fieldValue;
    }
    return field.fieldValue === '' ? '-' : field.fieldValue;
  }

  /** 附件条：realFileName + fileSize（widget.b） */
  @Builder
  attachRow(attach: OaWorkApplyAttach) {
    Row() {
      Text(attach.realFileName)
        .fontSize(16)
        .fontColor($r('app.color.mobile_campus_primary_color_default'))
        .layoutWeight(1)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
      if (attach.fileSize !== '') {
        Text(attach.fileSize)
          .fontSize(13)
          .fontColor($r('app.color.common_color_3'))
          .margin({ left: 8 })
      }
    }
    .width('100%')
    .padding({ left: 12, right: 12, top: 12, bottom: 12 })
    .onClick(() => {
      this.openAttach(attach);
    })
    Divider().color($r('app.color.common_color_5')).strokeWidth(0.5).width('100%')
      .margin({ left: 12 })
  }
}
