import { router } from '@kit.ArkUI';
import { ApiService } from '../network/ApiService';
import { ApiResponse } from '../model/ResponseModel';
import { WorkApplyEntry, OaWorkApplyRow, OaWorkApplyList } from '../model/OaTodoModel';
import { BusinessError } from '@kit.BasicServicesKit';
import { LoadingView } from '../components/LoadingView';

/**
 * 业务申请列表页 — 1:1 翻译原 APK WorkApplyActivity.java(479行)+Launch：
 *
 * 【布局】mobile_campus_oa_activity_workapply.xml：toolbar_normal("业务申请") + AppBarLayout
 *   (ScrollView[AutoExpandableListView 分类宫格] + 固定头[12vp 灰条 + "我发起的"14fp
 *   schedule_color11 + btn_screen 筛选(primary 14fp+apply_screen 图标) + 细线 + screen_layout
 *   筛选条 schedule_color19 bg]) + PullToRefreshLayout[RecyclerView apply_list 我的申请]。
 *
 * 【数据流源码还原】
 *   1. V2()：ApplyModel.U0 → GET processList（无参）→ WorkApply[]；g 回调按 folderName 分组
 *      （空→"未分类"，LinkedHashMap 保序）→ WorkApplyEntity[groupTitle, workApplyList]。
 *   2. W2(page)：GET myApply {pageSize:"1000"(字面量), pageNum} → MyApplyList{rows,total}；
 *      条目行 c.b.o 全字段 HTML 逆转义（WorkApplyListAdapter.h）。rows 逆转义。
 *   3. X2(page)：筛选态 GET screen {pageSize:"10"(AgooConstants.ACK_REMOVE_PACKAGE), pageNum,
 *      processid=t}（t=筛选返回的 processid）。
 *   4. 宫格组头（WorkApplyExpandAdapter getGroupView）：item_title 顶线#DFE4EA + 标题14fp
 *      padV15 ml12 + arrow_up/arrow_down mr12；单组展开模式（f：点击已展开组收起，否则互斥展开，
 *      初始展开第 0 组）。子项=GridLayoutManager 4 列宫格（WorkApplyAdapter），图标按
 *      e(i,folderName) 关键词映射（报修/档案/公文|收文/会议/业务→固定图，兜底 i/4 循环）。
 *   5. 宫格点击 e → h2(a.Q=WorkApplyFormConfigActivity){processid,title} 5347；
 *      申请条目点击 g：appid 空≠"ydbg" → toast"移动端暂不支持该流程，请移动到电脑端进行操作"，
 *      否则 h2(a.S=WorkApplyDetailActivity){applybean,type:"apply"}。
 *   6. btn_screen i → h2(a.P=WorkApplyScreenActivity){list} 5346；onActivityResult 5346：
 *      t=processid、o=keyword、screen_layout 可见、列表直接用回传 applyList、s=1。
 *   7. onActivityResult 5347（详情/表单返回）：s=0 重载（t 空走 W2，否则 X2）。
 *   8. j 下拉/上拉：s=0 首屏，b 上拉 page+1（t 空走 W2 否则 X2）；空页 setHasNoMoreData。
 *   9. h 关闭筛选：screen_layout 隐藏 + t="" + s=0 重载。
 *
 * 【HAP 等价】router+AppStorage 管道（EditTodoDetailPage 同款）：筛选结果经
 *   'workapply_screen_result' 回传；条目参数经 'workapply_detail_row'。
 */

/** WorkApplyEntity.java {groupTitle, workApplyList}（宫格分组） */
class ApplyGroup {
  groupTitle: string = '';
  workApplyList: WorkApplyEntry[] = [];
}

interface ScreenResult {
  keyword: string;
  processid: string;
  rows: OaWorkApplyRow[];
  total: string;
}

@Entry
@Component
struct WorkApplyPage {
  @State groups: ApplyGroup[] = [];
  @State expandedIdx: number = 0;
  @State rows: OaWorkApplyRow[] = [];
  @State firstLoading: boolean = true;
  @State loadingMore: boolean = false;
  @State hasNoMore: boolean = false;
  @State screenName: string = '';
  @State screenPid: string = '';
  @State screenVisible: boolean = false;
  /** onPageShow 首次触发跳过（aboutToAppear 已首载） */
  private entered: boolean = false;
  /** 筛选态分页走 screen 接口（源码 s=1 + t 非空） */
  private screenMode: boolean = false;
  /** 源码 s：当前页码（W2(s+1) 上拉语义） */
  private pageNum: number = 0;

  aboutToAppear(): void {
    this.loadProcesses();
    this.refreshList();
  }

  /** 源码 onActivityResult(5347/5346) 等价：筛选结果消费或整页重载 */
  onPageShow(): void {
    if (!this.entered) {
      this.entered = true;
      return;
    }
    const resultStr: string | undefined = AppStorage.get<string>('workapply_screen_result');
    if (resultStr !== undefined && resultStr !== '') {
      AppStorage.setOrCreate<string>('workapply_screen_result', '');
      this.applyScreenResult(resultStr);
      return;
    }
    this.refreshList();
  }

  /** 源码 a.g 回调：按 folderName 分组（空→"未分类"，保序） */
  private loadProcesses(): void {
    ApiService.getWorkApplyProcessList()
      .then((response: ApiResponse<WorkApplyEntry[]>) => {
        if (response.code !== 0) {
          this.firstLoading = false;
          return;
        }
        const map: Map<string, WorkApplyEntry[]> = new Map();
        for (const one of response.data) {
          const folder: string = one.folderName === '' ? '未分类' : one.folderName;
          let bucket: WorkApplyEntry[] | undefined = map.get(folder);
          if (bucket === undefined) {
            bucket = [];
            map.set(folder, bucket);
          }
          bucket.push(one);
        }
        const list: ApplyGroup[] = [];
        map.forEach((value: WorkApplyEntry[], key: string) => {
          const group: ApplyGroup = new ApplyGroup();
          group.groupTitle = key;
          group.workApplyList = value;
          list.push(group);
        });
        this.groups = list;
        this.firstLoading = false;
      })
      .catch((error: BusinessError) => {
        ApiService.logError('WorkApply processList fail: ' + error.message);
        this.firstLoading = false;
      });
  }

  /** 源码 j.a 下拉 / h 关闭筛选 / onActivityResult(5347)：s=0 重载 */
  private refreshList(): void {
    this.rows = [];
    this.pageNum = 0;
    this.fetchMyApply(1, false);
  }

  /** 源码 j.b 上拉：page+1 追加 */
  private loadMore(): void {
    if (this.hasNoMore || this.loadingMore) {
      return;
    }
    this.fetchMyApply(this.pageNum + 1, true);
  }

  /** 源码 W2/X2：t（筛选 processid）空走 myApply，否则 screen；首屏替换/加载更多追加 */
  private fetchMyApply(pageNum: number, append: boolean): void {
    this.pageNum = pageNum;
    if (!append) {
      this.firstLoading = true;
    }
    this.loadingMore = true;
    const caller: Promise<ApiResponse<OaWorkApplyList>> = this.screenMode
      ? ApiService.screenMyApplyList(String(pageNum), this.screenPid)
      : ApiService.getMyApplyList(pageNum);
    caller
      .then((response: ApiResponse<OaWorkApplyList>) => {
        this.consumeList(response, pageNum, append);
      })
      .catch((error: BusinessError) => {
        ApiService.logError('WorkApply myApply fail: ' + error.message);
        this.firstLoading = false;
        this.loadingMore = false;
        this.hasNoMore = true;
      });
  }

  /** 源码 c/d.g：首屏 setAdapter 替换 + 空页 setHasNoMoreData(true) */
  private consumeList(response: ApiResponse<OaWorkApplyList>, pageNum: number, append: boolean): void {
    this.firstLoading = false;
    this.loadingMore = false;
    if (response.code !== 0) {
      this.hasNoMore = true;
      return;
    }
    const list: OaWorkApplyList = response.data;
    if (append) {
      const merged: OaWorkApplyRow[] = this.rows.slice();
      for (const row of list.rows) {
        merged.push(row);
      }
      this.rows = merged;
    } else {
      this.rows = list.rows;
    }
    if (list.rows.length === 0) {
      this.hasNoMore = true;
    }
    ApiService.logError('WorkApply list page=' + pageNum + ' rows=' + list.rows.length);
  }

  /** 源码 onActivityResult(5346)：t=processid、keyword 条、列表用回传 applyList、s=1 */
  private applyScreenResult(resultStr: string): void {
    try {
      const result: ScreenResult = JSON.parse(resultStr) as ScreenResult;
      this.screenPid = result.processid;
      this.screenName = result.keyword;
      this.screenVisible = true;
      this.screenMode = true;
      // 源码 onActivityResult(5346)：this.s = 1（下次上拉 page=2 起）
      this.pageNum = 1;
      this.rows = result.rows;
      this.hasNoMore = result.rows.length === 0;
    } catch (error) {
      const err = error as BusinessError;
      ApiService.logError('WorkApply screenResult parse fail: ' + err.message);
    }
  }

  /** 源码 h 关闭筛选：screen_layout 隐藏 + t="" + s=0 重载 */
  private closeScreen(): void {
    this.screenVisible = false;
    this.screenName = '';
    this.screenPid = '';
    this.screenMode = false;
    this.refreshList();
  }

  /** 源码 i：btn_screen → ScreenActivity{list}（HAP 经 AppStorage 传宫格数据） */
  private openScreen(): void {
    const plain: WorkApplyEntry[] = [];
    for (const group of this.groups) {
      for (const one of group.workApplyList) {
        plain.push(one);
      }
    }
    AppStorage.setOrCreate<string>('workapply_screen_list', JSON.stringify(plain));
    router.pushUrl({ url: 'pages/WorkApplyScreenPage' });
  }

  /** 源码 e：宫格项 → a.Q{processid,title} */
  private openFormConfig(item: WorkApplyEntry): void {
    router.pushUrl({
      url: 'pages/WorkApplyFormConfigPage',
      params: { 'processid': item.processId, 'title': item.processName } as Record<string, string>
    });
  }

  /** 源码 g：条目点击，appid!="ydbg" 拦截 toast，否则 → a.S{applybean,type:"apply"} */
  private openDetail(row: OaWorkApplyRow): void {
    if (row.appid !== 'ydbg') {
      this.toast('移动端暂不支持该流程，请移动到电脑端进行操作');
      return;
    }
    AppStorage.setOrCreate<string>('workapply_detail_row', JSON.stringify(row));
    router.pushUrl({ url: 'pages/WorkApplyDetailPage' });
  }

  /** WorkApplyExpandAdapter.e(i, folderName)：关键词映射 + i/4 兜底循环 */
  private gridIcon(groupIdx: number, folderName: string): Resource {
    if (folderName === '') {
      return $r('app.media.mobile_campus_oa_apply');
    }
    if (folderName.includes('报修')) {
      return $r('app.media.mobile_campus_oa_repair');
    }
    if (folderName.includes('档案')) {
      return $r('app.media.mobile_campus_oa_document');
    }
    if (folderName.includes('公文') || folderName.includes('收文')) {
      return $r('app.media.mobile_campus_oa_public_document');
    }
    if (folderName.includes('会议')) {
      return $r('app.media.mobile_campus_oa_meeting');
    }
    if (folderName.includes('业务')) {
      return $r('app.media.mobile_campus_oa_apply');
    }
    const mod: number = Math.floor(groupIdx / 4);
    if (mod === 1) {
      return $r('app.media.mobile_campus_oa_document');
    }
    if (mod === 2) {
      return $r('app.media.mobile_campus_oa_meeting');
    }
    if (mod === 3) {
      return $r('app.media.mobile_campus_oa_public_document');
    }
    return $r('app.media.mobile_campus_oa_apply');
  }

  private toast(msg: string): void {
    this.getUIContext().getPromptAction().showToast({ message: msg });
  }

  /** 源码 f OnGroupClickListener：互斥展开（点击已展开组收起） */
  private toggleGroup(idx: number): void {
    if (this.expandedIdx === idx) {
      this.expandedIdx = -1;
      return;
    }
    this.expandedIdx = idx;
  }

  build() {
    Column() {
      // toolbar_normal（T1：gVar.n("业务申请")）
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
        Text('业务申请')
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

      List() {
        // AppBarLayout 内 ScrollView[AutoExpandableListView]：分类宫格
        ForEach(this.groups, (group: ApplyGroup, gi: number) => {
          ListItem() {
            this.groupBlock(group, gi)
          }
        }, (group: ApplyGroup, gi: number) => gi.toString() + group.groupTitle)

        // 固定头：12vp 灰条 + "我发起的" + 筛选 + 细线 + 筛选条
        ListItem() {
          this.myApplyHeader()
        }

        if (this.firstLoading) {
          ListItem() {
            LoadingView()
          }
        } else {
          ForEach(this.rows, (row: OaWorkApplyRow, ri: number) => {
            ListItem() {
              this.applyRow(row)
            }
          }, (row: OaWorkApplyRow, ri: number) => ri.toString() + row.orUnid)
          // footerview：已显示全部（hasNoMoreData）
          ListItem() {
            this.footerRow()
          }
        }
      }
      .width('100%')
      .layoutWeight(1)
      .scrollBar(BarState.Off)
      .backgroundColor($r('app.color.ybg_white'))
      .onReachEnd(() => {
        this.loadMore();
      })
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.ybg_white'))
  }

  /** 宫格分组块：item_title 组头 + 展开时 item_content 宫格 */
  @Builder
  groupBlock(group: ApplyGroup, gi: number) {
    Column() {
      // mobile_campus_oa_activity_workapply_item_title.xml
      Stack({ alignContent: Alignment.Top }) {
        Row() {
          Text(group.groupTitle)
            .fontSize(14)
            .fontColor($r('app.color.common_color_1'))
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .margin({ left: 12 })
            .padding({ top: 15, bottom: 15 })
            .layoutWeight(1)
          Image(this.expandedIdx === gi ? $r('app.media.arrow_up') : $r('app.media.arrow_down'))
            .width(14)
            .height(14)
            .margin({ right: 12 })
        }
        .width('100%')
        .alignItems(VerticalAlign.Center)
        .onClick(() => {
          this.toggleGroup(gi);
        })
        Divider().color('#DFE4EA').strokeWidth(0.5).width('100%')
      }
      .width('100%')
      if (this.expandedIdx === gi && group.workApplyList.length > 0) {
        // mobile_campus_oa_activity_workapply_item_content.xml：GridLayoutManager 4 列宫格
        Grid() {
          ForEach(group.workApplyList, (item: WorkApplyEntry, ai: number) => {
            GridItem() {
              Column() {
                // mobile_campus_oa_item_workapply_header.xml：图标 59vp + 名称 12fp
                Image(this.gridIcon(gi, group.groupTitle))
                  .width(59)
                  .height(59)
                  .objectFit(ImageFit.Contain)
                  .margin({ top: 13 })
                Text(item.processName)
                  .fontSize(12)
                  .fontColor($r('app.color.common_color_1'))
                  .textAlign(TextAlign.Center)
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
                  .padding({ left: 3, right: 3 })
                  .margin({ top: 4, bottom: 12 })
              }
              .alignItems(HorizontalAlign.Center)
              .width('100%')
              .onClick(() => {
                this.openFormConfig(item);
              })
            }
          }, (item: WorkApplyEntry, ai: number) => ai.toString() + item.processId)
        }
        .columnsTemplate('1fr 1fr 1fr 1fr')
        .width('100%')
        .padding({ left: 7.5, right: 7.5, top: 7.5, bottom: 7.5 })
        Divider().color($r('app.color.common_color_6')).strokeWidth(0.5).width('100%')
      }
    }
    .width('100%')
  }

  /** 固定头：灰条 + "我发起的"/筛选 行 + 细线 + 筛选条 */
  @Builder
  myApplyHeader() {
    Column() {
      Row()
        .width('100%')
        .height(12)
        .backgroundColor($r('app.color.common_color_6'))
      Row() {
        Text('我发起的')
          .fontSize(14)
          .fontColor($r('app.color.mobile_campus_schedule_color11'))
          .padding({ top: 10, bottom: 10 })
        Blank()
        Row() {
          Image($r('app.media.mobile_campus_oa_apply_screen'))
            .width(14)
            .height(14)
            .margin({ right: 8 })
          Text('筛选')
            .fontSize(14)
            .fontColor($r('app.color.mobile_campus_primary_color_default'))
        }
        .alignItems(VerticalAlign.Center)
        .padding({ top: 5, bottom: 5 })
        .onClick(() => {
          this.openScreen();
        })
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)
      .padding({ left: 12, right: 12 })
      Divider().color($r('app.color.common_color_5')).strokeWidth(0.5).width('100%')
      if (this.screenVisible) {
        // screen_layout：schedule_color19 bg，"筛选: " + 名称 + close
        Row() {
          Text('筛选: ')
            .fontSize(13)
            .fontColor($r('app.color.mobile_campus_schedule_color11'))
            .margin({ top: 8, bottom: 8 })
          Text(this.screenName)
            .fontSize(13)
            .fontColor($r('app.color.mobile_campus_schedule_color11'))
            .layoutWeight(1)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .margin({ top: 8, bottom: 8, right: 5 })
          Image($r('app.media.mobile_campus_oa_apply_close'))
            .width(16)
            .height(16)
            .padding(5)
            .onClick(() => {
              this.closeScreen();
            })
        }
        .width('100%')
        .alignItems(VerticalAlign.Center)
        .backgroundColor($r('app.color.mobile_campus_schedule_color19'))
        .padding({ left: 12, right: 12 })
      }
    }
    .width('100%')
  }

  /** mobile_campus_oa_item_workapply.xml 条目 */
  @Builder
  applyRow(row: OaWorkApplyRow) {
    Column() {
      Column() {
        Row() {
          // apply_cuied：bussStatus=="1" → "已催办"（shape_border_darkblue 描边）
          Text('已催办')
            .fontSize(10)
            .fontColor($r('app.color.mobile_campus_primary_color_default'))
            .padding({ left: 5, right: 5, top: 3, bottom: 3 })
            .border({ width: 0.5, color: $r('app.color.mobile_campus_primary_color_default') })
            .margin({ right: 12 })
            .visibility(row.bussStatus === '1' ? Visibility.Visible : Visibility.None)
          // apply_node："结束"→"审核完成"灰；否则"当前节点：X"蓝（空隐藏 INVISIBLE=4）
          Text(row.currentNodeName === '结束' ? '审核完成' : '当前节点：' + row.currentNodeName)
            .fontSize(13)
            .fontColor(row.currentNodeName === '结束' ? $r('app.color.common_color_3')
              : $r('app.color.mobile_campus_schedule_color17'))
            .layoutWeight(1)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .margin({ right: 5 })
            .visibility(row.currentNodeName === '' ? Visibility.None : Visibility.Visible)
        }
        .width('100%')
        .alignItems(VerticalAlign.Center)
        .margin({ bottom: 8 })
        // apply_title：17fp maxLines 2
        Text(row.subject)
          .fontSize(17)
          .fontColor($r('app.color.common_color_1'))
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .margin({ bottom: 12 })
        Row() {
          Text('申请时间：')
            .fontSize(13)
            .fontColor($r('app.color.common_color_3'))
          Text(row.docCreated)
            .fontSize(13)
            .fontColor($r('app.color.common_color_3'))
            .layoutWeight(1)
        }
        .width('100%')
      }
      .width('100%')
      .padding(12)
      .onClick(() => {
        this.openDetail(row);
      })
      // 左缩进 12 的 0.5 分隔线（schedule_color18）
      Divider()
        .color($r('app.color.mobile_campus_schedule_color18'))
        .strokeWidth(0.5)
        .width('100%')
        .margin({ left: 12 })
    }
    .width('100%')
  }

  /** mobile_campus_oa_layout_workapply_footerview.xml：两侧线 + "已显示全部" */
  @Builder
  footerRow() {
    Row() {
      Divider().color($r('app.color.common_color_5')).strokeWidth(0.5).layoutWeight(1)
      Text(this.loadingMore ? '加载中...' : '已显示全部')
        .fontSize(13)
        .fontColor($r('app.color.common_color_3'))
        .margin({ left: 20, right: 20 })
      Divider().color($r('app.color.common_color_5')).strokeWidth(0.5).layoutWeight(1)
    }
    .width('100%')
    .padding({ top: 12, bottom: 12 })
    .visibility(this.rows.length === 0 ? Visibility.None : Visibility.Visible)
  }
}
