import { router } from '@kit.ArkUI';
import { TitleBar } from '../components/TitleBar';
import { LoadingView } from '../components/LoadingView';
import { EmptyView } from '../components/EmptyView';
import { ApiService } from '../network/ApiService';
import { ApiResponse } from '../model/ResponseModel';
import { BusinessError } from '@kit.BasicServicesKit';
import { MeetingSelectorEntity } from '../model/MeetingApiModel';

/**
 * 会议室选择页 — MeetingSelectorActivity.java(166行) 源码级翻译
 * 【源码链路】发起/转发会议表单（会议室行）→ V=/selector/meetingselect。y(intent)：
 *   q=data（上级已下钻列表，首次空）、r=map（已选层级 HashMap<String,String>，首次空）。
 * 【布局】mobile_campus_oa_activity_metting_selector.xml：toolbar（标题"会议室选择"）+
 *   common_refresh_lv_rl（PullToRefreshLayout 禁用下拉/上拉 + ListView 无 divider）。
 * 【数据】O2() = SelectPImpl.B(new a(MeetingSelector.class)).r() → SelectModel.b1：
 *   GET select/meeting 无参 → MeetingSelector[] 树（实测 code=0：长清校区→文体中心→…递归 data）。
 *   f1：传入 q 空 → 请求；否则直接渲染 q。
 * 【item】mobile_campus_oa_meeting_view_item_selector：白底 padL 12；行高 48dip；
 *   tvTitle=item.text 17fp #333 marginL 12；tvNext 15fp #1B6BB7 + arrow_right drawablePadding 4
 *   （item.data 非空显示，空隐藏）；分隔线。
 * 【点击 b.onItemClick】r.put(type, gson({id,name,text,type}))；item.data 空（叶子）→
 *   setResult(map)+finish（选中完成）；非空 → h2(V 自递归, bundle{data, map}, 100) 进入下一级；
 *   onActivityResult(100,-1) → map 透传 setResult+finish。
 *   HAP 等价：Android startActivity 自递归压栈 → 页面内层级栈（levels 数组），进入子级=push、
 *   返回=pop（物理返回键/标题栏返回同语义），叶子=写 AppStorage 'meeting_selector_result'
 *   （JSON map）后整体 router.back 退出。
 * 【空态/错误】g 回调空列表 → q2 EMPTY；f 回调 -3010 → ERROR_NETWORK，其余 ERROR。
 * 【接口实测】probe_w18_meeting_remain.py：select/meeting code=0 真实会议室树。
 * 【数据规则】禁止 mock（原占位页 5 条假会议已清除，真实接口树渲染）。
 */
@Entry
@Component
struct MeetingSelectorPage {
  /** 当前层级列表（源码 ListView 数据） */
  @State levelItems: MeetingSelectorEntity[] = [];
  @State loading: boolean = true;
  @State loadFail: boolean = false;
  @State isEmpty: boolean = false;
  /** 层级栈（源码 startActivity 自递归：每级 = {本级列表, 已选 map}；栈底 = 首屏全树） */
  private levelStack: MeetingSelectorEntity[][] = [];
  /** 已选 map（源码 r：type → gson({id,name,text,type})） */
  private selectedMap: Record<string, Object> = {};
  private fetched: boolean = false;

  aboutToAppear(): void {
    // 源码 f1：传入 q（data）空 → O2() 请求；否则直接渲染 q（HAP 首屏无传入 → 请求全树）
    this.loadSelector();
  }

  /** 源码 O2()：p.B(new a).r() → SelectModel.b1 GET select/meeting */
  private loadSelector(): void {
    ApiService.getMeetingSelector()
      .then((response: ApiResponse<MeetingSelectorEntity[]>) => {
        if (response.code === 1000) {
          // 登录失效统一处理已在网络层触发
          this.loading = false;
          return;
        }
        if (response.code === 0) {
          // 源码 a.g()：空列表 → q2 空态；否则 setData + 内容态
          if (response.data.length === 0) {
            this.isEmpty = true;
          } else {
            this.levelStack = [response.data];
            this.levelItems = response.data;
            this.isEmpty = false;
          }
          this.loadFail = false;
        } else {
          // 源码 a.f()：-3010 → ERROR_NETWORK，其余 ERROR（MultiStateView 错误态）
          this.loadFail = true;
        }
        this.fetched = true;
        this.loading = false;
      })
      .catch((error: BusinessError) => {
        ApiService.logError('MeetingSelectorPage load fail: ' + error.message);
        this.loadFail = true;
        this.fetched = true;
        this.loading = false;
      });
  }

  /** 源码 b.onItemClick：选中记录 → 叶子 setResult 退出 / 非叶子进下一级 */
  private onItemSelect(item: MeetingSelectorEntity): void {
    // 源码：r.put(type, gson(new MeetingSelector{id,name,text,type}))
    const picked: MeetingSelectorEntity = new MeetingSelectorEntity();
    picked.id = item.id;
    picked.name = item.name;
    picked.text = item.text;
    picked.type = item.type;
    this.selectedMap[item.type] = JSON.stringify(picked) as Object;
    if (item.data.length === 0) {
      // 源码：叶子 → setResult(map)+finish（HAP：结果写 AppStorage 后整体退出）
      AppStorage.setOrCreate('meeting_selector_result', JSON.stringify(this.selectedMap));
      AppStorage.setOrCreate('meeting_selector_changed', true);
      router.back();
      return;
    }
    // 源码：非叶子 → h2(V 自递归, bundle{data, map}, 100)（HAP：层级栈 push）
    this.levelStack.push(item.data);
    this.levelItems = item.data;
  }

  /** 返回（源码物理返回/标题栏返回：叶子栈 pop，栈底退出） */
  private onBack(): void {
    if (this.levelStack.length > 1) {
      this.levelStack.pop();
      this.levelItems = this.levelStack[this.levelStack.length - 1];
      this.loadFail = false;
      this.isEmpty = false;
      return;
    }
    router.back();
  }

  /** 物理返回键同源码自递归 Activity 返回：层级栈 pop，栈底放行退出 */
  onBackPress(): boolean {
    if (this.levelStack.length > 1) {
      this.levelStack.pop();
      this.levelItems = this.levelStack[this.levelStack.length - 1];
      this.loadFail = false;
      this.isEmpty = false;
      return true;
    }
    return false;
  }

  build() {
    Column() {
      TitleBar({ title: '会议室选择', showBack: true, onBack: (): void => {
        this.onBack();
      } })
      if (this.loading) {
        LoadingView()
      } else if (this.loadFail) {
        EmptyView({ tipText: '获取会议室失败' })
      } else if (this.isEmpty || this.levelItems.length === 0) {
        EmptyView({ tipText: '暂无可选会议室' })
      } else {
        // common_refresh_lv：ListView 无 divider（PullToRefresh 源码禁用下拉/上拉）
        List() {
          ForEach(this.levelItems, (item: MeetingSelectorEntity, index: number) => {
            ListItem() {
              this.selectorRow(item)
            }
          }, (item: MeetingSelectorEntity, index: number) =>
            'sel_' + String(index) + '_' + item.id)
        }
        .width('100%')
        .layoutWeight(1)
        .scrollBar(BarState.Off)
        .backgroundColor($r('app.color.white'))
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.main_bg'))
  }

  /** mobile_campus_oa_meeting_view_item_selector：padL 12 / 行高 48 / tvTitle 17fp / tvNext 15fp #1B6BB7 */
  @Builder
  selectorRow(item: MeetingSelectorEntity) {
    Column() {
      Row() {
        Text(item.text)
          .fontSize(17)
          .fontColor($r('app.color.common_color_1'))
          .margin({ left: 12 })
          .layoutWeight(1)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        if (item.data.length > 0) {
          // tvNext：15fp #1B6BB7 + arrow_right（drawablePadding 4）
          Image($r('app.media.arrow_right'))
            .width(14)
            .height(14)
            .margin({ right: 12 })
        }
      }
      .width('100%')
      .height(48)
      .padding({ right: 12 })
      .alignItems(VerticalAlign.Center)
      .onClick(() => {
        this.onItemSelect(item);
      })
      Divider()
        .color($r('app.color.common_color_5'))
        .strokeWidth(0.5)
        .width('100%')
    }
    .width('100%')
    .padding({ left: 12 })
    .backgroundColor($r('app.color.white'))
  }
}
