import { router } from '@kit.ArkUI';
import { BusinessError } from '@kit.BasicServicesKit';
import { ApiService } from '../network/ApiService';
import { ApiResponse } from '../model/ResponseModel';
import { SuperviseTeacher } from '../model/SuperviseModel';
import { EmptyView } from '../components/EmptyView';
import { LoadingView } from '../components/LoadingView';
import { PreferencesUtil } from '../data/PreferencesUtil';
import { BreakpointSystem } from '../common/BreakpointSystem';

/**
 * 督导教师搜索页 — 源码级翻译 [W21 supervise]（SuperviseSearchActivity.java 逐行 → ArkTS）：
 *
 * 【布局】mobile_campus_supervise_activity_supervise_search.xml：竖排
 *   mobile_campus_supervise_toolbar_search.xml：44dip main_bg Toolbar → 白底 RelativeLayout pr12：
 *     ClearableEditText（navigation_bar_search_et_input_search_key）32dip 14sp common_color_1，
 *     f1() setHint("输入教师姓名...")（覆盖 XML hint）hint#B5B5B5，search_b 图标 pad9，
 *     imeOptions=actionSearch；"取消"（navigation_bar_search_tv_right_btn）→ finish；灰细分隔线
 *   common_refresh_lv_rl：PullToRefreshLayout（setEnabled(false) 无下拉）+ ListView + MultiStateView
 *
 * 【历史缓存】SuperviseCachePImpl（supervise/b/a.java）：本地持久化 List<String>
 *   b(str)：10 条上限（==10 先删尾）→ 旧值去重移除 → add(0, str) 插头；a() 读；c(list) 覆写清空。
 *   HAP 等价 = PreferencesUtil 'supervise_search_cache'（JSON string[]，LitePal/Hawk 语义）。
 *   缓存非空 → 头 view_search_cache_top"历史搜索"（48dip 13sp common_color_3 pad12）+
 *   脚 view_search_cache_footer"清空搜索记录"（13sp#696969 + rubbish 图标 pad8 mt29.5）；
 *   行 view_search_cache：48dip pad12 tvCacheName 14sp + close_g p8（逐条删）。
 *
 * 【交互】c.onEditorAction（IME 3/6）：空 → toast"输入的内容不能为空"（input_can_not_be_empty）；
 *   非空 → t.b(str) 存缓存 → T2(str) 搜索。b.afterTextChanged：清空输入且缓存非空 → 回缓存列表。
 *   T2 → SuperviseModel.c1：POST searchSector {xm} → SearchSector[]{GH,XM,BMMC}
 *   （2026-11-18 实测 {xm:'张'} 95 行 / {xm:''} 全量）。g() 回调：有数据 content / 无数据 empty /
 *   e() error → MultiStateView 三态。
 *   d.onItemClick：结果行 → setResult {name:XM, id:GH} → finish（AppStorage 'supervise_search_result'）；
 *   缓存行 → 填入关键词 + T2 直搜。
 */

@Entry
@Component
struct SuperviseSearchPage {
  @State keyword: string = '';
  /** 源码 t.a()：历史搜索缓存（SuperviseCachePImpl 持久化） */
  @State cacheList: string[] = [];
  @State showCache: boolean = false;
  @State results: SuperviseTeacher[] = [];
  @State isLoading: boolean = false;
  /** MultiStateView 三态等价：content/empty/error */
  @State viewState: string = 'empty';
  @StorageProp('currentBreakpoint') currentBreakpoint: string = 'sm';
  @StorageProp('avoidAreaBottomVp') avoidAreaBottomVp: number = 0;
  @StorageProp('avoidAreaLeftVp') avoidAreaLeftVp: number = 0;
  @StorageProp('avoidAreaRightVp') avoidAreaRightVp: number = 0;
  @StorageProp('keyboardHeightVp') keyboardHeightVp: number = 0;
  private readonly CACHE_KEY: string = 'supervise_search_cache';
  private static readonly SEARCH_RESULT_KEY: string = 'supervise_search_result';

  onPageShow(): void {
    this.restoreCache();
  }

  /** 源码 SuperviseCachePImpl.a()：读缓存列表 */
  private restoreCache(): void {
    PreferencesUtil.getString(this.CACHE_KEY, '[]')
      .then((v: string) => {
        const list: string[] = [];
        try {
          const parsed: Object = JSON.parse(v) as Object;
          if (Array.isArray(parsed)) {
            for (const one of parsed as Object[]) {
              if (typeof one === 'string') {
                list.push(one as string);
              }
            }
          }
        } catch {
          ApiService.logError('SuperviseSearchPage cache restore fail');
        }
        this.cacheList = list;
        this.showCache = list.length > 0;
        if (list.length === 0 && this.viewState !== 'content') {
          this.viewState = 'empty';
        }
      });
  }

  /** 源码 SuperviseCachePImpl.b(str)：10 条上限（==10 先删尾）→ 去重 → add(0,str) 插头 → 持久化 */
  private saveCache(word: string): void {
    // 源码分支顺序 1:1：先判 size==10 删尾，再去重，最后插头（满 10 且含重复词时尾部仍被删）
    const list: string[] = this.cacheList.slice();
    if (list.length === 10) {
      list.pop();
    }
    const deduped: string[] = [];
    for (const one of list) {
      if (one !== word) {
        deduped.push(one);
      }
    }
    deduped.splice(0, 0, word);
    this.cacheList = deduped;
    this.showCache = deduped.length > 0;
    this.persistCache(deduped);
  }

  /** 源码 SuperviseCachePImpl.c(list)：覆写/清空持久化 */
  private persistCache(list: string[]): void {
    PreferencesUtil.putString(this.CACHE_KEY, JSON.stringify(list));
  }

  /** 源码 c.onEditorAction：空 toast；非空 存缓存 + T2 搜索 */
  private submitSearch(): void {
    const word: string = this.keyword.trim();
    if (word === '') {
      this.getUIContext().getPromptAction().showToast({ message: '输入的内容不能为空' });
      return;
    }
    this.saveCache(word);
    this.requestSearch(word);
  }

  /** 源码 T2：s.w(...).r(str) → POST searchSector {xm}；g() 三态 + 结果集 */
  private requestSearch(word: string): void {
    this.isLoading = true;
    ApiService.searchSuperviseTeacher(word)
      .then((response: ApiResponse<SuperviseTeacher[]>) => {
        if (response.code === 1000) {
          // 登录失效统一处理已在网络层触发（HttpClient.bizRequest 拦截：清会话+toast+跳登录）
          return;
        }
        if (response.code === 0) {
          this.results = response.data;
          this.viewState = this.results.length > 0 ? 'content' : 'empty';
        } else {
          ApiService.logError('SuperviseSearchPage search degrade: code=' + response.code +
            ' msg=' + response.message);
          this.results = [];
          this.viewState = 'error';
        }
        this.isLoading = false;
      })
      .catch((error: BusinessError) => {
        ApiService.logError('SuperviseSearchPage search fail: ' + error.message);
        this.results = [];
        this.viewState = 'error';
        this.isLoading = false;
      });
  }

  /** 源码 d.onItemClick（结果 adapter 分支）：intent{name:XM, id:GH} setResult finish */
  private onResultClick(item: SuperviseTeacher): void {
    const payload: Record<string, string> = { 'XM': item.XM, 'GH': item.GH };
    AppStorage.setOrCreate<string>(SuperviseSearchPage.SEARCH_RESULT_KEY, JSON.stringify(payload));
    router.back();
  }

  /** 源码 d.onItemClick（缓存分支）：填入关键词 + T2 直搜 */
  private onCacheItemClick(word: string): void {
    this.keyword = word;
    this.requestSearch(word);
  }

  /** 源码 g.a(i)：缓存单条移除 → c(list) 持久化；空 → 空态 */
  private onCacheRemove(index: number): void {
    const rest: string[] = [];
    for (let i = 0; i < this.cacheList.length; i++) {
      if (i !== index) {
        rest.push(this.cacheList[i]);
      }
    }
    this.cacheList = rest;
    this.showCache = rest.length > 0;
    this.persistCache(rest);
    if (rest.length === 0) {
      this.viewState = 'empty';
    }
  }

  /** 源码 h.onClick（footer）：o.clear() + t.c 持久化 + 空态 */
  private clearCache(): void {
    this.cacheList = [];
    this.showCache = false;
    this.persistCache([]);
    this.viewState = 'empty';
  }

  build() {
    Column() {
      // mobile_campus_supervise_toolbar_search.xml：44dip main_bg + 白底搜索框 32dip + "取消"
      Column() {
        Row() {
          Row() {
            Image($r('app.media.mobile_campus_supervise_search'))
              .width(16)
              .height(16)
              .margin({ left: 8, right: 9 })
            TextInput({ text: this.keyword, placeholder: '输入教师姓名...' })
              .fontSize(14)
              .fontColor($r('app.color.common_color_1'))
              .placeholderColor('#B5B5B5')
              .placeholderFont({ size: 14 })
              .backgroundColor(Color.Transparent)
              .border({ width: 0 })
              .padding(0)
              .layoutWeight(1)
              .height(32)
              .defaultFocus(true)
              .onChange((value: string) => {
                this.keyword = value;
                // 源码 b.afterTextChanged：清空且缓存非空 → 回缓存列表
                if (value === '' && this.cacheList.length > 0) {
                  this.showCache = true;
                }
              })
              .onSubmit(() => {
                this.submitSearch();
              })
          }
          .width('100%')
          .height(32)
          .borderRadius(4)
          .backgroundColor($r('app.color.white'))
          .padding({ left: 8, right: 8 })
          .alignItems(VerticalAlign.Center)
          .layoutWeight(1)

          Text('取消')
            .fontSize(15)
            .fontColor($r('app.color.common_color_1'))
            .height(44)
            .padding({ left: 8, right: 4 })
            .onClick(() => {
              // 源码 f.onClick：finish
              this.getUIContext().getRouter().back();
            })
        }
        .width('100%')
        .height(44)
        .padding({
          left: Math.max(12, this.avoidAreaLeftVp),
          right: Math.max(12, this.avoidAreaRightVp)
        })
        .constraintSize({ maxWidth: BreakpointSystem.getContentMaxWidth(this.currentBreakpoint) })
        .alignSelf(ItemAlign.Center)
        .backgroundColor($r('app.color.main_bg'))
        .alignItems(VerticalAlign.Center)

        Divider()
          .color($r('app.color.common_color_5'))
          .strokeWidth(0.5)
          .width('100%')
      }
      .width('100%')
      .backgroundColor($r('app.color.main_bg'))
      .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP])

      if (this.isLoading) {
        LoadingView()
      } else if (this.showCache) {
        this.cacheListView()
      } else if (this.viewState === 'error') {
        Column() {
          EmptyView({ tipText: '加载失败' })
        }
        .width('100%')
        .constraintSize({ maxWidth: BreakpointSystem.getContentMaxWidth(this.currentBreakpoint) })
        .alignSelf(ItemAlign.Center)
        .padding({
          left: this.avoidAreaLeftVp,
          right: this.avoidAreaRightVp,
          bottom: this.keyboardHeightVp + this.avoidAreaBottomVp
        })
        .layoutWeight(1)
      } else if (this.viewState === 'content' && this.results.length > 0) {
        this.resultList()
      } else {
        Column() {
          EmptyView()
        }
        .width('100%')
        .constraintSize({ maxWidth: BreakpointSystem.getContentMaxWidth(this.currentBreakpoint) })
        .alignSelf(ItemAlign.Center)
        .padding({
          left: this.avoidAreaLeftVp,
          right: this.avoidAreaRightVp,
          bottom: this.keyboardHeightVp + this.avoidAreaBottomVp
        })
        .layoutWeight(1)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.common_color_6'))
  }

  /** 缓存列表（view_search_cache_top 头 + view_search_cache 行 + footer） */
  @Builder
  cacheListView() {
    List() {
      // mobile_campus_supervise_view_search_cache_top.xml："历史搜索" 48dip 13sp common_color_3 pad12
      ListItem() {
        Text('历史搜索')
          .fontSize(13)
          .fontColor($r('app.color.common_color_3'))
          .width('100%')
          .height(48)
          .padding(12)
          .backgroundColor($r('app.color.white'))
      }
      ForEach(this.cacheList, (word: string, index: number) => {
        ListItem() {
          this.cacheRow(word, index)
        }
      }, (word: string) => word)
      // mobile_campus_supervise_view_search_cache_footer.xml："清空搜索记录"+rubbish 图标 mt29.5
      ListItem() {
        Row() {
          Text('清空搜索记录')
            .fontSize(13)
            .fontColor('#696969')
          Image($r('app.media.mobile_campus_supervise_rubbish_icon'))
            .width(14)
            .height(14)
            .padding(8)
            .margin({ left: 8 })
        }
        .width('100%')
        .justifyContent(FlexAlign.Center)
        .padding({ top: 29.5, bottom: 20 })
        .onClick(() => {
          this.clearCache();
        })
      }
    }
    .width('100%')
    .constraintSize({ maxWidth: BreakpointSystem.getContentMaxWidth(this.currentBreakpoint) })
    .alignSelf(ItemAlign.Center)
    .padding({ left: this.avoidAreaLeftVp, right: this.avoidAreaRightVp })
    .contentEndOffset(this.keyboardHeightVp + this.avoidAreaBottomVp)
    .layoutWeight(1)
    .scrollBar(BarState.Off)
    .backgroundColor($r('app.color.common_color_6'))
  }

  /** mobile_campus_supervise_view_search_cache.xml */
  @Builder
  cacheRow(word: string, index: number) {
    Column() {
      Row() {
        Text(word)
          .fontSize(14)
          .fontColor($r('app.color.common_color_1'))
          .height(48)
          .layoutWeight(1)
          .maxLines(1)
          .textAlign(TextAlign.Start)
        Image($r('app.media.mobile_campus_supervise_close_g'))
          .width(14)
          .height(14)
          .padding(8)
          .onClick(() => {
            this.onCacheRemove(index);
          })
      }
      .width('100%')
      .padding({ left: 12, right: 12 })
      .backgroundColor($r('app.color.white'))
      .alignItems(VerticalAlign.Center)
      .onClick(() => {
        this.onCacheItemClick(word);
      })

      Divider()
        .color($r('app.color.common_color_5'))
        .strokeWidth(0.5)
        .width('100%')
    }
    .width('100%')
  }

  /** 搜索结果 view_search：48dip pad12 tvName=XM 17sp + tvMajor=BMMC 14sp ml12（各 maxLines 1） */
  @Builder
  resultList() {
    List() {
      ForEach(this.results, (item: SuperviseTeacher) => {
        ListItem() {
          Column() {
            Row() {
              Text(item.XM)
                .fontSize(17)
                .fontColor($r('app.color.common_color_1'))
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
              Text(item.BMMC)
                .fontSize(14)
                .fontColor($r('app.color.common_color_3'))
                .margin({ left: 12 })
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
            }
            .width('100%')
            .height(48)
            .padding(12)
            .alignItems(VerticalAlign.Center)
            .backgroundColor($r('app.color.white'))
            .onClick(() => {
              this.onResultClick(item);
            })

            Divider()
              .color($r('app.color.common_color_5'))
              .strokeWidth(0.5)
              .width('100%')
          }
          .width('100%')
        }
      }, (item: SuperviseTeacher) => item.GH + '_' + item.XM)
    }
    .width('100%')
    .constraintSize({ maxWidth: BreakpointSystem.getContentMaxWidth(this.currentBreakpoint) })
    .alignSelf(ItemAlign.Center)
    .padding({ left: this.avoidAreaLeftVp, right: this.avoidAreaRightVp })
    .contentEndOffset(this.keyboardHeightVp + this.avoidAreaBottomVp)
    .layoutWeight(1)
    .scrollBar(BarState.Off)
    .backgroundColor($r('app.color.common_color_6'))
  }
}
