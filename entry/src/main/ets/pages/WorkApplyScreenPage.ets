import { router } from '@kit.ArkUI';
import { ApiService } from '../network/ApiService';
import { ApiResponse } from '../model/ResponseModel';
import { WorkApplyEntry, OaWorkApplyRow, OaWorkApplyList } from '../model/OaTodoModel';
import { BusinessError } from '@kit.BasicServicesKit';
import { LoadingView } from '../components/LoadingView';

/**
 * 筛选页 — 1:1 翻译原 APK WorkApplyScreenActivity.java(180行)：
 *
 * 【布局】mobile_campus_oa_activity_workapply_screen.xml：toolbar_normal("筛选") +
 *   MultiStateView[PullToRefreshLayout(setPullUpToLoadEnable(false)+setEnabled(false) 禁刷新)
 *   [ExpandableListView exListView bg common_color_6]]。
 *
 * 【数据流源码还原】
 *   1. y(Intent)：q = intent.getSerializableExtra("list")（WorkApplyActivity.i 传入宫格全集）
 *      → r.addAll(K2())：K2 按 folderName HashMap 分组 → ScreenGroup{folderName, data}。
 *      （folderName 已由主列表页 processList 回调归一为非空，此处原样分组）
 *   2. ScreenExpandAdapter（adapter/a.java）：组头 groupitem_screen（folderName 14fp
 *      common_color_3 padV10 px12 bg common_color_6，getGroupView 内 expandGroup(i) 全展开）；
 *      子项 childitem_screen（processName 17fp common_color_1 padV10 px12 白底 selector 按压
 *      schedule_color18 + 底线 schedule_color18）。
 *   3. 子项点击 b.a(workApply) → L2(processName, processId)：
 *      ApplyModel.X0 → GET screen {pageSize:AgooConstants.ACK_REMOVE_PACKAGE="10", pageNum:"1",
 *      processid} → MyApplyList。
 *   4. 成功 a.g：setResult(-1){keyword=processName, processid, applyList} → l.postDelayed
 *      1000ms finish；失败 a.f → toast"筛选数据失败"；e → MultiStateView 内容态。
 *
 * 【HAP 等价】入参 AppStorage 'workapply_screen_list'；出参 AppStorage 'workapply_screen_result'
 *   {keyword,processid,rows,total}（WorkApplyPage.onPageShow 消费）+ 延迟 1s router.back。
 */

interface ScreenGroupItem {
  folderName: string;
  data: WorkApplyEntry[];
}

interface ScreenPickResult {
  keyword: string;
  processid: string;
  rows: OaWorkApplyRow[];
  total: string;
}

@Entry
@Component
struct WorkApplyScreenPage {
  @State groups: ScreenGroupItem[] = [];
  @State searching: boolean = false;

  aboutToAppear(): void {
    const raw: string | undefined = AppStorage.get<string>('workapply_screen_list');
    if (raw !== undefined && raw !== '') {
      this.buildGroups(raw);
    }
  }

  /** 源码 y(Intent)+K2()：宫格全集按 folderName HashMap 分组（保序） */
  private buildGroups(raw: string): void {
    try {
      const list: WorkApplyEntry[] = JSON.parse(raw) as WorkApplyEntry[];
      const map: Map<string, WorkApplyEntry[]> = new Map();
      for (const one of list) {
        let bucket: WorkApplyEntry[] | undefined = map.get(one.folderName);
        if (bucket === undefined) {
          bucket = [];
          map.set(one.folderName, bucket);
        }
        bucket.push(one);
      }
      const result: ScreenGroupItem[] = [];
      map.forEach((value: WorkApplyEntry[], key: string) => {
        const group: ScreenGroupItem = { folderName: key, data: value };
        result.push(group);
      });
      this.groups = result;
    } catch (error) {
      const err = error as BusinessError;
      ApiService.logError('WorkApplyScreen parse list fail: ' + err.message);
    }
  }

  /** 源码 L2(processName, processId)：GET screen {pageSize:"10", pageNum:"1", processid} */
  private pick(item: WorkApplyEntry): void {
    if (this.searching) {
      return;
    }
    this.searching = true;
    ApiService.screenMyApplyList('1', item.processId)
      .then((response: ApiResponse<OaWorkApplyList>) => {
        this.finishPick(response, item);
      })
      .catch((error: BusinessError) => {
        ApiService.logError('WorkApplyScreen screen fail: ' + error.message);
        this.searching = false;
        // 源码 netutil 失败回调 a.f 同样覆盖网络异常分支 → m("筛选数据失败")
        this.getUIContext().getPromptAction().showToast({ message: '筛选数据失败' });
      });
  }

  /** 源码 a.g：setResult{keyword,processid,applyList} + 延迟 1s finish */
  private finishPick(response: ApiResponse<OaWorkApplyList>, item: WorkApplyEntry): void {
    this.searching = false;
    if (response.code !== 0) {
      // 源码 a.f：m("筛选数据失败")
      this.getUIContext().getPromptAction().showToast({ message: '筛选数据失败' });
      return;
    }
    const result: ScreenPickResult = {
      keyword: item.processName,
      processid: item.processId,
      rows: response.data.rows,
      total: response.data.total
    };
    AppStorage.setOrCreate<string>('workapply_screen_result', JSON.stringify(result));
    setTimeout(() => {
      router.back();
    }, 1000);
  }

  build() {
    Column() {
      // toolbar_normal（T1：gVar.n("筛选")）
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
        Text('筛选')
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

      if (this.searching) {
        LoadingView()
      } else {
        // ExpandableListView：组头全展开 + 子项列表
        List() {
          ForEach(this.groups, (group: ScreenGroupItem) => {
            ListItem() {
              Column() {
                // mobile_campus_oa_groupitem_screen.xml
                Text(group.folderName)
                  .fontSize(14)
                  .fontColor($r('app.color.common_color_3'))
                  .width('100%')
                  .padding({ top: 10, bottom: 10 })
                  .backgroundColor($r('app.color.common_color_6'))
                ForEach(group.data, (item: WorkApplyEntry) => {
                  this.childRow(item)
                }, (item: WorkApplyEntry) => item.processId)
              }
              .width('100%')
            }
          }, (group: ScreenGroupItem) => group.folderName)
        }
        .width('100%')
        .layoutWeight(1)
        .scrollBar(BarState.Off)
        .backgroundColor($r('app.color.common_color_6'))
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.common_color_6'))
  }

  /** mobile_campus_oa_childitem_screen.xml：白底 selector + 子名 17fp + 底线 schedule_color18 */
  @Builder
  childRow(item: WorkApplyEntry) {
    Column() {
      Text(item.processName)
        .fontSize(17)
        .fontColor($r('app.color.common_color_1'))
        .width('100%')
        .padding({ top: 10, bottom: 10, left: 12, right: 12 })
      Divider()
        .color($r('app.color.mobile_campus_schedule_color18'))
        .strokeWidth(0.5)
        .width('100%')
    }
    .width('100%')
    .backgroundColor($r('app.color.white'))
    .onClick(() => {
      this.pick(item);
    })
  }
}
