import { router } from '@kit.ArkUI';
import { ApiService } from '../network/ApiService';
import { ApiResponse } from '../model/ResponseModel';
import { OaDormitoryRecord, OaLdmc, OaRecordsDetail } from '../model/OaTodoModel';
import { TitleBar } from '../components/TitleBar';
import { EmptyView } from '../components/EmptyView';
import { LoadingView } from '../components/LoadingView';
import { PreferencesUtil } from '../data/PreferencesUtil';
import { BusinessError } from '@kit.BasicServicesKit';

/**
 * 寝室卫生检查页 — 源码级翻译（W23，原空占位重写）：
 * APK InspectionActivity（inspection/view，/inspection/detail；入口 InspectionRecordActivity
 * 条目/添加按钮 rc100）。
 *
 * 【双模式】y(Intent)：t=addRecord（true=新增记录模式）/u=JCJLMC（标题）/v=XLH（记录序号）/
 *   B=yyid（InspectionSharePreference "app_dormitory" 缓存键）。
 * 【布局】inspection_activity.xml：toolbar + MultiStateView（ExpandableListView[header=
 *   InspectionHeaderView] + rlMore 底部"N个寝室已评分/点击查看更多"）。
 * 【头部 InspectionHeaderView（inspection_view_header.xml）】
 *   白卡圆角4 margin 15：tvUpdate CheckBox"修改"（change 图标，14fp common_color_7，右对齐）+
 *   inspection_pic 图 + tvTitle EditText（居中 17fp、hint"第xx周  宿舍检查记录"、maxLength15、
 *   focusable false 初始）+ tvSelect"选择宿舍"（15fp+arrow_down2，margin 15）。
 *   tvUpdate 点击（a 类）：未勾选→"修改"文案+失焦+回调（更新记录名 w3）；勾选→"保存"文案+
 *   空取 hint+可编辑+selectAllOnFocus+requestFocus。
 * 【数据流源码还原（InspectionPImpl/InspectionModel）】
 *   查看模式：p.p(u) 预填标题 + p3(v) → b1 getLdmcList {recordXlh} → Ldmc[]{LDMC}（实测 []）
 *   → b 回调 r.s(list)；空→直接 content；非空→w=首楼或缓存楼名（d.a.d(yyid)）→ q3(v,w) →
 *   c1 getRecordsDetail {recordXlh, ldmc} → RecordsDetail（实测 {hadScoreSize:0,
 *   datalist:[{name:"notCheckList",data:[]}]})→ a 回调 q.c(datalist)+d.a.e(yyid,楼名)+rlMore
 *   hadScoreSize>0 显示"N个寝室已评分"。
 *   新增模式：rlMore 隐藏 + 标题=e.e(MM-dd)+"  寝室卫生检查" → n3(str) → V0
 *   addDormitoryCheckRecords {recordName} → DormitoryCheckRecords{recordXlh}（实测 code=0）→
 *   t=true → v=recordXlh → p3(v)。
 * 【Expandable 分组（adapter a.java）】name=="notCheckList"→组头"待检查寝室"（inspection_check
 *   图标，40dip，恒展开）；否则"待评价寝室"（inspection_evaluate，mt12）；子行
 *   inspection_view_item：tvName=QSH+" 寝室"+imgAdd（TYPE=="1" 显示）。
 * 【子项点击 j 类】TYPE=="1" → 拍照打分页（inspection_add_record rc1234，HAP 对应
 *   AddRecordActivity 未翻译→无跳转）；TYPE!="1" → u3 → 已评分详情（同上未翻译）。
 * 【rlMore i 类】→ inspection_rank_list {XLH, ldmc}（HAP InspectionRankPage 路由占位可达）。
 * 【toolbar T1】查看模式右"删除"（inspection_delete）→ l 类确认"是否删除该条记录" →
 *   o3(v) X0 deleteDormitoryCheckRecords {recordXlh}（实测 code=0）→ c 类 "删除成功"+
 *   setResult(102,{XLH})+finish（HAP：AppStorage 'inspection_result'{op:"delete",XLH}+back）；
 *   新增模式右"保存"（inspection_save）→ l 类：标题空 toast"请输入记录标题"；否则 setResult(103)
 *   +finish（HAP：{op:"create"}+back）。
 * 【更新标题】tvSelect/回车（g 类 66）→ w3(标题, v) → d1 updateRecordName {recordName,
 *   recordXlh}（实测 code=0）→ m 类 "更新成功"+t 模式 setResult(103)/否则 setResult(101,
 *   {XLH, JCJLMC})（HAP：{op:"update",XLH,JCJLMC}；不 back——源码不 finish）。
 * 【返回键】新增 → s3 确认"是否保存记录"（确定 e 类 setResult(103)+finish / 取消 onCancel →
 *   o3 删除记录）；查看 → 直接 finish。HAP：onBack 覆写。
 * 【楼层选择 InspectionDialog】WheelView visibleItems 7 白底 + tvFinish"完成" → 回调 a(楼名) →
 *   w=楼名 + p.q(楼名) + q3(v, 楼名)。HAP：bindSheet TextPicker 等价（W21 SuperviseFilter 同款）。
 * 【禁 mock】全部真实接口；楼层/寝室空列表=真实空态。
 */
interface InspectionNavParams {
  addRecord: boolean;
  XLH: string;
  JCJLMC: string;
  yyid: string;
}

/** 分组行渲染 VM（adapter a.java 组头文案/图标分流） */
class InspectionGroupVM {
  name: string = '';
  groupTitle: string = '';
  isNotCheck: boolean = true;
  dorms: OaInspectionDormRow[] = [];
}

/** 子行 VM（QSH+" 寝室" + TYPE） */
class OaInspectionDormRow {
  QSH: string = '';
  RECORDDETAILXLH: string = '';
  TYPE: string = '';
}

@Entry
@Component
struct InspectionPage {
  @State titleText: string = '';
  @State titleEditable: boolean = false;
  @State updateLabel: string = '修改';
  @State floorText: string = '选择宿舍';
  @State groups: InspectionGroupVM[] = [];
  @State hadScoreSize: number = 0;
  @State isLoading: boolean = true;
  @State showFloorPicker: boolean = false;
  @State floors: OaLdmc[] = [];
  @State floorPickerIdx: number = 0;
  /** 新增模式（源码 t） */
  private isAddRecord: boolean = false;
  private recordXlh: string = '';
  private yyid: string = '';
  private floorName: string = '';

  aboutToAppear(): void {
    const params: Record<string, Object> | undefined = router.getParams() as Record<string, Object> | undefined;
    if (params !== undefined && params !== null) {
      const add: Object = params['addRecord'];
      if (typeof add === 'string') {
        this.isAddRecord = (add as string) === 'true';
      } else if (typeof add === 'boolean') {
        this.isAddRecord = add as boolean;
      }
      const xlh: Object = params['XLH'];
      if (typeof xlh === 'string') {
        this.recordXlh = xlh as string;
      }
      const name: Object = params['JCJLMC'];
      if (typeof name === 'string') {
        this.titleText = name as string;
      }
      const yid: Object = params['yyid'];
      if (typeof yid === 'string') {
        this.yyid = yid as string;
      }
    }
    if (this.isAddRecord) {
      // 源码 f1 新增分支：e.e(MM-dd)+"  寝室卫生检查"（两个空格保真）
      const now: Date = new Date();
      const mm: string = String(now.getMonth() + 1).padStart(2, '0');
      const dd: string = String(now.getDate()).padStart(2, '0');
      this.titleText = mm + '-' + dd + '  寝室卫生检查';
      this.createRecord();
    } else {
      this.fetchFloors();
    }
  }

  /** 源码 n3：addDormitoryCheckRecords {recordName} → recordXlh → p3 */
  private createRecord(): void {
    ApiService.addInspectionRecord(this.titleText)
      .then((response: ApiResponse<OaDormitoryRecord>) => {
        if (response.code === 1000) {
          return;
        }
        if (response.code === 0 && response.data.recordXlh !== '') {
          this.recordXlh = response.data.recordXlh;
          this.fetchFloors();
        } else {
          ApiService.logError('addDormitoryCheckRecords fail code=' + response.code);
          this.isLoading = false;
        }
      })
      .catch((error: BusinessError) => {
        ApiService.logError('addDormitoryCheckRecords error: ' + error.message);
        this.isLoading = false;
      });
  }

  /** 源码 p3：getLdmcList {recordXlh} → b 回调 r.s(list) */
  private fetchFloors(): void {
    ApiService.getInspectionLdmcList(this.recordXlh)
      .then((response: ApiResponse<OaLdmc[]>) => {
        if (response.code === 1000) {
          return;
        }
        if (response.code === 0) {
          this.floors = response.data;
          if (this.floors.length === 0) {
            this.isLoading = false;
            return;
          }
          this.pickInitialFloor();
        } else {
          ApiService.logError('getLdmcList fail code=' + response.code);
          this.isLoading = false;
        }
      })
      .catch((error: BusinessError) => {
        ApiService.logError('getLdmcList error: ' + error.message);
        this.isLoading = false;
      });
  }

  /** 源码 b 回调：w=首楼或缓存楼名（InspectionSharePreference d(yyid)）→ q3 */
  private async pickInitialFloor(): Promise<void> {
    this.floorName = this.floors[0].LDMC;
    const cached: string = await PreferencesUtil.getString('app_dormitory_' + this.yyid, '');
    if (cached !== '') {
      this.floorName = cached;
    }
    this.floorText = this.floorName;
    this.fetchRecordsDetail();
  }

  /** 源码 q3：getRecordsDetail {recordXlh, ldmc} → a 回调 */
  private fetchRecordsDetail(): void {
    ApiService.getInspectionRecordsDetail(this.recordXlh, this.floorName)
      .then((response: ApiResponse<OaRecordsDetail>) => {
        if (response.code === 1000) {
          return;
        }
        if (response.code === 0) {
          this.groups = this.buildGroups(response.data);
          this.hadScoreSize = response.data.hadScoreSize;
          PreferencesUtil.putString('app_dormitory_' + this.yyid, this.floorName);
        } else {
          ApiService.logError('getRecordsDetail fail code=' + response.code);
          this.groups = [];
        }
        this.isLoading = false;
      })
      .catch((error: BusinessError) => {
        ApiService.logError('getRecordsDetail error: ' + error.message);
        this.groups = [];
        this.isLoading = false;
      });
  }

  /** adapter a.java 分组：name=="notCheckList"→"待检查寝室" / 否则"待评价寝室" */
  private buildGroups(detail: OaRecordsDetail): InspectionGroupVM[] {
    const out: InspectionGroupVM[] = [];
    for (const group of detail.datalist) {
      const vm: InspectionGroupVM = new InspectionGroupVM();
      vm.name = group.name;
      vm.isNotCheck = group.name === 'notCheckList';
      vm.groupTitle = vm.isNotCheck ? '待检查寝室' : '待评价寝室';
      for (const dorm of group.data) {
        const row: OaInspectionDormRow = new OaInspectionDormRow();
        row.QSH = dorm.QSH;
        row.RECORDDETAILXLH = dorm.RECORDDETAILXLH;
        row.TYPE = dorm.TYPE;
        vm.dorms.push(row);
      }
      out.push(vm);
    }
    return out;
  }

  /** InspectionDialog 回调 k 类：选楼 → w=楼名 + p.q(楼名) + q3 */
  private onFloorPicked(): void {
    if (this.floorPickerIdx >= 0 && this.floorPickerIdx < this.floors.length) {
      this.floorName = this.floors[this.floorPickerIdx].LDMC;
      this.floorText = this.floorName;
      this.fetchRecordsDetail();
    }
    this.showFloorPicker = false;
  }

  /** 源码 w3：updateRecordName {recordName, recordXlh} → m 类 "更新成功"+setResult(101) */
  private updateRecordName(): void {
    ApiService.updateInspectionRecordName(this.titleText, this.recordXlh)
      .then((response: ApiResponse<Object>) => {
        if (response.code === 1000) {
          return;
        }
        if (response.code === 0) {
          this.toast('更新成功');
          const result: Record<string, Object> = {
            'op': 'update', 'XLH': this.recordXlh, 'JCJLMC': this.titleText
          };
          AppStorage.setOrCreate<string>('inspection_result', JSON.stringify(result));
        } else {
          this.toast(response.message);
        }
      })
      .catch((error: BusinessError) => {
        ApiService.logError('updateRecordName fail: ' + error.message);
        this.toast(responseFailMsg(error));
      });
  }

  /** 源码 o3：deleteDormitoryCheckRecords {recordXlh} → c 类 "删除成功"+setResult(102)+finish */
  private deleteRecord(): void {
    ApiService.deleteInspectionRecord(this.recordXlh)
      .then((response: ApiResponse<Object>) => {
        if (response.code === 1000) {
          return;
        }
        if (response.code === 0) {
          this.toast('删除成功');
          const result: Record<string, Object> = { 'op': 'delete', 'XLH': this.recordXlh };
          AppStorage.setOrCreate<string>('inspection_result', JSON.stringify(result));
          this.getUIContext().getRouter().back();
        } else {
          this.toast(response.message);
        }
      })
      .catch((error: BusinessError) => {
        ApiService.logError('deleteRecord fail: ' + error.message);
        this.toast(responseFailMsg(error));
      });
  }

  /** 源码 l 类（toolbar 右键）：查看=删除确认 / 新增=保存 */
  private onToolbarRight(): void {
    if (this.isAddRecord) {
      // 源码 l 类：标题空 → "请输入记录标题"；否则 setResult(103)+finish
      if (this.titleText.trim() === '') {
        this.toast('请输入记录标题');
        return;
      }
      const result: Record<string, Object> = { 'op': 'create', 'XLH': this.recordXlh };
      AppStorage.setOrCreate<string>('inspection_result', JSON.stringify(result));
      this.getUIContext().getRouter().back();
      return;
    }
    this.confirmDialog('是否删除该条记录', (): void => {
      this.deleteRecord();
    });
  }

  /** 源码 onBackPressed：新增 → s3 确认"是否保存记录"（取消 → o3 → c 类"删除成功"+
   *  setResult(102,{XLH})+finish，与查看模式删除同一回调链）；查看 → 直接 finish */
  private handleBack(): void {
    if (!this.isAddRecord) {
      this.getUIContext().getRouter().back();
      return;
    }
    this.getUIContext().showAlertDialog({
      message: '是否保存记录',
      autoCancel: true,
      alignment: DialogAlignment.Center,
      primaryButton: {
        value: '取消',
        action: (): void => {
          // 源码 e 类 onCancel：o3(v) → c 类 g()：toast"删除成功"+setResult(102,{XLH})+finish
          this.deleteRecord();
        }
      },
      secondaryButton: {
        value: '确定',
        action: (): void => {
          // 源码 e 类 a()：setResult(103)+finish
          const result: Record<string, Object> = { 'op': 'create', 'XLH': this.recordXlh };
          AppStorage.setOrCreate<string>('inspection_result', JSON.stringify(result));
          this.getUIContext().getRouter().back();
        }
      }
    });
  }

  /** 源码 i 类：rlMore → inspection_rank_list {XLH, ldmc} */
  private gotoRank(): void {
    router.pushUrl({ url: 'pages/InspectionRankPage',
      params: { 'XLH': this.recordXlh, 'ldmc': this.floorName } as Record<string, string> });
  }

  /** 源码 InspectionHeaderView a 类：tvUpdate 修改/保存切换 */
  private onUpdateClick(): void {
    if (!this.titleEditable) {
      // 源码：勾选→"保存"+可编辑+selectAllOnFocus+requestFocus；空取 hint
      this.titleEditable = true;
      this.updateLabel = '保存';
      if (this.titleText === '') {
        this.titleText = '第xx周  宿舍检查记录';
      }
      return;
    }
    // 源码：取消勾选→"修改"+失焦+view.tag=标题+回调（w3 更新）
    this.titleEditable = false;
    this.updateLabel = '修改';
    this.updateRecordName();
  }

  private confirmDialog(message: string, onSure: () => void): void {
    this.getUIContext().showAlertDialog({
      message: message,
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
          onSure();
        }
      }
    });
  }

  private toast(message: string): void {
    this.getUIContext().getPromptAction().showToast({ message: message });
  }

  build() {
    Column() {
      TitleBar({
        title: '寝室检查',
        showBack: true,
        rightText: this.isAddRecord ? '保存' : '删除',
        onRightClick: (): void => {
          this.onToolbarRight();
        },
        onBack: (): void => {
          this.handleBack();
        }
      })
      if (this.isLoading) {
        Column() {
          LoadingView()
        }
        .width('100%')
        .layoutWeight(1)
      } else if (this.groups.length === 0 && this.floors.length === 0 && !this.isAddRecord) {
        Column() {
          EmptyView({ tipText: '暂无检查数据' })
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

  /** MultiStateView content：ExpandableListView[header] + rlMore */
  @Builder
  content() {
    Stack({ alignContent: Alignment.Bottom }) {
      List() {
        ListItem() {
          this.headerView()
        }
        ForEach(this.groups, (group: InspectionGroupVM) => {
          ListItem() {
            this.groupBlock(group)
          }
        }, (group: InspectionGroupVM) => group.name)
      }
      .width('100%')
      .layoutWeight(1)
      .scrollBar(BarState.Off)
      .padding({ bottom: 27 })

      if (this.hadScoreSize > 0 && !this.isAddRecord) {
        // rlMore：inspection_shape_more 圆角8 timetable_showcolor8 bg 高62dip marginH15/B27
        Row() {
          Row() {
            Image($r('app.media.instection_star'))
              .width(16)
              .height(16)
              .margin({ right: 10 })
            Text(this.hadScoreSize + '个寝室已评分')
              .fontSize(17)
              .fontColor('#FFFEFE')
          }
          .alignItems(VerticalAlign.Center)
          Blank()
          Row() {
            Text('点击查看更多')
              .fontSize(17)
              .fontColor('#FFFEFE')
            Image($r('app.media.my_check_while'))
              .width(16)
              .height(16)
              .margin({ left: 10 })
          }
          .alignItems(VerticalAlign.Center)
        }
        .width('calc(100% - 30vp)')
        .height(62)
        .padding(12)
        .borderRadius(8)
        .backgroundColor($r('app.color.timetable_showcolor8'))
        .margin({ bottom: 27 })
        .alignItems(VerticalAlign.Center)
        .onClick(() => {
          this.gotoRank();
        })
      }
    }
    .width('100%')
    .layoutWeight(1)
    // 楼层选择 bindSheet（InspectionDialog WheelView visibleItems7 等价）
    .bindSheet(this.showFloorPicker, this.floorSheet(), {
      height: 320,
      backgroundColor: Color.White,
      onDisappear: (): void => {
        this.showFloorPicker = false;
      }
    })
  }

  /** inspection_view_header：白卡（修改/标题/选择宿舍） */
  @Builder
  headerView() {
    Column() {
      Column() {
        Row() {
          Blank()
          Row() {
            Image($r('app.media.change'))
              .width(14)
              .height(14)
              .margin({ right: 4 })
            Text(this.updateLabel)
              .fontSize(12)
              .fontColor($r('app.color.common_color_7'))
          }
          .alignItems(VerticalAlign.Center)
          .onClick(() => {
            this.onUpdateClick();
          })
        }
        .width('100%')

        Row() {
          Image($r('app.media.inspection_pic'))
            .width(40)
            .height(40)
            .objectFit(ImageFit.Contain)
          TextInput({ text: this.titleText, placeholder: '第xx周  宿舍检查记录' })
            .fontSize(17)
            .fontColor($r('app.color.common_color_1'))
            .placeholderColor($r('app.color.common_color_1'))
            .placeholderFont({ size: 17 })
            .backgroundColor(Color.Transparent)
            .maxLength(15)
            .textAlign(TextAlign.Center)
            .enabled(this.titleEditable)
            .layoutWeight(1)
            .margin({ left: 24, right: 24 })
            .onChange((value: string) => {
              this.titleText = value;
            })
            .onSubmit((_enterKey: EnterKeyType) => {
              // 源码 g 类 key 66：更新记录名
              this.updateRecordName();
            })
        }
        .width('100%')
        .alignItems(VerticalAlign.Center)
      }
      .width('calc(100% - 30vp)')
      .padding(15)
      .borderRadius(4)
      .backgroundColor($r('app.color.white'))
      .margin(15)

      Row() {
        Text(this.floorText)
          .fontSize(17)
          .fontColor($r('app.color.common_color_1'))
        Image($r('app.media.arrow_down2'))
          .width(14)
          .height(14)
          .margin({ left: 8 })
      }
      .width('100%')
      .padding(15)
      .alignItems(VerticalAlign.Center)
      .onClick(() => {
        // 源码 v3：InspectionDialog show（q2 楼层列表）
        this.floorPickerIdx = 0;
        this.showFloorPicker = true;
      })
    }
    .width('100%')
  }

  /** 组块：组头 40dip（图标+文案）+ 子行（tvName=QSH+" 寝室"+imgAdd TYPE=1） */
  @Builder
  groupBlock(group: InspectionGroupVM) {
    Column() {
      Row() {
        Image(group.isNotCheck ? $r('app.media.inspection_check') : $r('app.media.inspection_evaluate'))
          .width(16)
          .height(16)
          .margin({ right: 8 })
        Text(group.groupTitle)
          .fontSize(15)
          .fontColor($r('app.color.common_color_1'))
      }
      .width('100%')
      .height(40)
      .padding({ left: 12 })
      .margin({ top: group.isNotCheck ? 0 : 12 })
      .alignItems(VerticalAlign.Center)

      ForEach(group.dorms, (dorm: OaInspectionDormRow) => {
        Row() {
          Text(dorm.QSH + ' 寝室')
            .fontSize(14)
            .fontColor($r('app.color.common_color_1'))
            .layoutWeight(1)
          if (dorm.TYPE === '1') {
            Image($r('app.media.inspection_add'))
              .width(16)
              .height(16)
          }
        }
        .width('100%')
        .height(44)
        .padding({ left: 24, right: 12 })
        .backgroundColor($r('app.color.white'))
        .alignItems(VerticalAlign.Center)
        .onClick(() => {
          // 源码 j 类：TYPE=1 → 拍照打分 / 其他 → 已评分详情（AddRecordActivity 未翻译无跳转）
        })
      }, (dorm: OaInspectionDormRow) => dorm.RECORDDETAILXLH + '_' + dorm.QSH)
    }
    .width('100%')
  }

  /** InspectionDialog 等价：tvChoose 空 + WheelView(TextPicker visibleItems7) + 完成 */
  @Builder
  floorSheet() {
    Column() {
      Row() {
        Blank()
        Text('完成')
          .fontSize(15)
          .fontColor($r('app.color.common_color_7'))
          .padding(10)
          .onClick(() => {
            this.onFloorPicked();
          })
      }
      .width('100%')

      if (this.floors.length > 0) {
        TextPicker({ range: this.floorLabels(), selected: this.floorPickerIdx })
          .width('100%')
          .layoutWeight(1)
          .onChange((value: string | string[], index: number | number[]) => {
            // [W23 修复] OnTextPickerChangeCallback 签名（string|string[]）→ 单列取首值
            this.floorPickerIdx = typeof index === 'number' ? index as number : (index as number[])[0];
          })
      } else {
        Column() {
          EmptyView({ tipText: '暂无楼层' })
        }
        .width('100%')
        .layoutWeight(1)
      }
    }
    .width('100%')
  }

  private floorLabels(): string[] {
    const labels: string[] = [];
    for (const floor of this.floors) {
      labels.push(floor.LDMC);
    }
    return labels;
  }
}

/** 网络层失败兜底文案 */
function responseFailMsg(_error: BusinessError): string {
  return '网络请求失败，请稍后再试';
}
