import { router } from '@kit.ArkUI';
import { ApiService } from '../network/ApiService';
import { ApiResponse } from '../model/ResponseModel';
import { OaTodoRow, OaTodoSearchGroup } from '../model/OaTodoModel';
import { BusinessError } from '@kit.BasicServicesKit';
import { LoadingView } from '../components/LoadingView';
import { EmptyView } from '../components/EmptyView';
import { PreferencesUtil } from '../data/PreferencesUtil';
import { BreakpointSystem } from '../common/BreakpointSystem';

/**
 * OA 待办搜索页 — 1:1 翻译原 APK TodoSearchActivity.java(332行)：
 *
 * 【页面结构】mobile_campus_oa_activity_todo_search.xml（bg #fff2f2f2）：
 *   toolbar_todo_search(44vp)：ClearableEditText（左搜索图标 mobile_campus_oa_search_b 间距9dip、
 *   bg 圆角灰 mobile_campus_shape_base_sesarch_bg、高32dip、hint"输入关键字搜索..."14fp、
 *   textColorHint #B5B5B5、ime actionSearch）+ 右"取消"（#1B68B7）→ finish；下方细分隔线。
 *   ViewSwitcher：child0=历史缓存 ListView(common_lv，header"历史搜搜"+footer"清空搜索记录")
 *                 child1=结果区(pullToRefreshLayout + ExpandableListView)。
 *
 * 【数据流源码还原】（TodoPImpl.n1 → GET search）
 *   1. IME 搜索（onEditorAction i==3/6）→ w=1 → b3(keyword, page)：空 → toast"输入不能为空"
 *      （input_can_not_be_empty）；写缓存 y.b(rowsBean{author_cn}) → GET search
 *   2. n1：GET search {keyword, pageNum, pageSize:"20"}（f13171d 明文 query 参数，R0 管道）
 *      → ArrayList<TodoSearch>{name,type,rows[RowsBean]}（分组）
 *   3. a.g：w==1 → t.d(list) 整体替换；否则 t.a(list) 追加（上拉加载 m+1）；
 *      groups.size()<=20 → 停加载；>20 → 记 x=keyword 允许下一页（f.b → b3(x, w+1)）
 *   4. 有结果 → ViewSwitcher 切 child1；无结果但有缓存 → child0；两者皆无 → EMPTY_SEARCH 空态
 *   5. child 点击 → bundle{type:child.type, bean} → e.a.J 详情（[W14] HAP → EditTodoDetailPage）
 *   6. 缓存（TodoCachePImpl c.c.a）：json 持久化、去重 author_cn、最多 10 条、新查置顶；
 *      单条移除/全部清空实时回写；缓存项点击 = 重查该关键字
 */
interface TodoNavParams {
  type: string;
  docUnid: string;
  processId: string;
  subject: string;
  hj: string;
  startTime: string;
  addName: string;
  nodeName: string;
  currentnodeid: string;
  authorCn: string;
}

const CACHE_KEY: string = 'sdmu_oa_todo_search_cache';

@Entry
@Component
struct TodoSearchPage {
  @State keyword: string = '';
  @State cache: OaTodoRow[] = [];
  @State groups: OaTodoSearchGroup[] = [];
  @State pageNum: number = 1;
  @State hasMore: boolean = false;
  @State lastKeyword: string = '';
  @State showCache: boolean = true;
  @State searching: boolean = false;
  @State everSearched: boolean = false;
  /** EMPTY_SEARCH / 失败态文案（''=不显示空态） */
  @State emptyText: string = '';
  @StorageProp('currentBreakpoint') currentBreakpoint: string = 'sm';
  @StorageProp('avoidAreaBottomVp') avoidAreaBottomVp: number = 0;
  @StorageProp('avoidAreaLeftVp') avoidAreaLeftVp: number = 0;
  @StorageProp('avoidAreaRightVp') avoidAreaRightVp: number = 0;
  @StorageProp('keyboardHeightVp') keyboardHeightVp: number = 0;

  aboutToAppear(): void {
    // 源码 f1：u.setData(y.a()) 读缓存；有缓存 → child0，无 → child1 且 n 隐藏
    this.loadCache();
  }

  /** 源码 c.c.a.a()：Preferences json → List<RowsBean>（HAP 侧等价存储） */
  private loadCache(): void {
    PreferencesUtil.getString(CACHE_KEY, '')
      .then((raw: string) => {
        const list: OaTodoRow[] = [];
        if (raw !== '') {
          try {
            const arr: Object = JSON.parse(raw) as Object;
            if (Array.isArray(arr)) {
              const rawArr: Object[] = arr as Object[];
              for (const one of rawArr) {
                list.push(OaTodoRow.fromRecord(one as Record<string, Object>));
              }
            }
          } catch (error) {
            const err = error as BusinessError;
            ApiService.logError('TodoSearch cache parse fail: ' + err.message);
          }
        }
        this.cache = list;
        this.showCache = this.cache.length > 0;
      })
      .catch((error: BusinessError) => {
        ApiService.logError('TodoSearch cache load fail: ' + error.message);
      });
  }

  private saveCache(): void {
    const arr: string[] = [];
    for (const row of this.cache) {
      arr.push(JSON.stringify(row));
    }
    PreferencesUtil.putString(CACHE_KEY, '[' + arr.join(',') + ']')
      .catch((error: BusinessError) => {
        ApiService.logError('TodoSearch cache save fail: ' + error.message);
      });
  }

  /** 源码 c.c.a.b(rowsBean)：去重 author_cn、最多 10 条、新查置顶 */
  private addCache(keyword: string): void {
    const row: OaTodoRow = new OaTodoRow();
    row.author_cn = keyword;
    const rest: OaTodoRow[] = [];
    for (const one of this.cache) {
      if (one.author_cn !== keyword) {
        rest.push(one);
      }
    }
    rest.unshift(row);
    this.cache = rest.length > 10 ? rest.slice(0, 10) : rest;
    this.saveCache();
  }

  // ===== 源码 b3(str, str2)：空值拦截 + 写缓存 + GET search =====
  private startSearch(keyword: string, pageNum: number): void {
    if (keyword === '') {
      // 源码 R$string.input_can_not_be_empty = "输入的内容不能为空"
      this.toast('输入的内容不能为空');
      return;
    }
    if (pageNum === 1) {
      this.addCache(keyword);
    }
    this.lastKeyword = keyword;
    this.pageNum = pageNum;
    this.searching = true;
    ApiService.searchOaTodo(keyword, pageNum)
      .then((response: ApiResponse<OaTodoSearchGroup[]>) => {
        this.searching = false;
        this.everSearched = true;
        if (response.code === 1000) {
          // 网络层统一拦截，页面仅 return
          return;
        }
        if (response.code === 0) {
          this.handleOk(pageNum, response.data);
        } else {
          this.handleFail(response.message);
        }
      })
      .catch((error: BusinessError) => {
        this.searching = false;
        ApiService.logError('TodoSearch fail: ' + error.message);
        this.handleFail('网络异常，请稍后重试');
      });
  }

  /** 源码 a.g：首页替换/加载页追加；groups<=20 停加载；三态切换 */
  private handleOk(pageNum: number, data: OaTodoSearchGroup[]): void {
    this.hasMore = data.length > 20;
    this.pageNum = pageNum;
    // 源码 TodoSearchAdapter.getGroupType：rows 空 → 空 View 不渲染组头（实测服务器恒返 5 空组）
    this.groups = pageNum === 1 ? this.dropEmpty(data) : this.groups.concat(this.dropEmpty(data));
    if (this.visibleRowCount() > 0) {
      this.showCache = false;
      this.emptyText = '';
      return;
    }
    if (this.cache.length > 0) {
      this.showCache = true;
      this.emptyText = '';
      return;
    }
    this.showCache = false;
    this.emptyText = '暂无搜索结果';
  }

  private dropEmpty(groups: OaTodoSearchGroup[]): OaTodoSearchGroup[] {
    const rest: OaTodoSearchGroup[] = [];
    for (const group of groups) {
      if (group.rows.length > 0) {
        rest.push(group);
      }
    }
    return rest;
  }

  private visibleRowCount(): number {
    let count: number = 0;
    for (const group of this.groups) {
      count += group.rows.length;
    }
    return count;
  }

  /** 源码 a.f：toast；结果区无数据显示空态（缓存存在则回缓存视图） */
  private handleFail(message: string): void {
    this.toast(message === '' ? '搜索失败' : message);
    if (this.groups.length === 0) {
      if (this.cache.length > 0) {
        this.showCache = true;
        this.emptyText = '';
      } else {
        this.showCache = false;
        this.emptyText = '暂无搜索结果';
      }
    }
  }

  // ===== 源码 e.onChildClick：bundle{type, bean} → 详情页 =====
  private onChildClick(child: OaTodoRow): void {
    const params: TodoNavParams = {
      type: child.type,
      docUnid: child.orUnid,
      processId: child.processId,
      subject: child.subject,
      hj: child.hj,
      startTime: child.startTime,
      addName: child.addName_cn,
      nodeName: child.currentnodename,
      currentnodeid: child.currentnodeid,
      authorCn: child.author_cn
    };
    router.pushUrl({ url: 'pages/EditTodoDetailPage', params: params });
  }

  // ===== 源码 b.onItemClick：缓存项点击 = 重查该关键字 =====
  private onCacheClick(row: OaTodoRow): void {
    this.keyword = row.author_cn;
    this.startSearch(row.author_cn, 1);
  }

  // ===== 源码 c.a：移除单条缓存并回写 =====
  private onCacheRemove(row: OaTodoRow): void {
    const rest: OaTodoRow[] = [];
    for (const one of this.cache) {
      if (one.author_cn !== row.author_cn) {
        rest.push(one);
      }
    }
    this.cache = rest;
    this.saveCache();
    if (this.cache.length === 0 && this.groups.length === 0) {
      this.showCache = false;
      this.emptyText = '';
    }
  }

  // ===== 源码 d.onClick：清空缓存并回写 =====
  private onCacheClear(): void {
    this.cache = [];
    this.saveCache();
    this.showCache = false;
    if (this.groups.length === 0) {
      this.emptyText = '';
    }
  }

  /** 源码 f.b：上拉 → b3(x, w+1)（仅首次成功且 >20 组后开启） */
  private loadMore(): void {
    if (!this.hasMore || this.lastKeyword === '') {
      return;
    }
    this.startSearch(this.lastKeyword, this.pageNum + 1);
  }

  private toast(message: string): void {
    this.getUIContext().getPromptAction().showToast({ message: message });
  }

  build() {
    Column() {
      this.searchBar()
      Divider()
        .color($r('app.color.common_color_5'))
        .strokeWidth(0.5)
        .width('100%')
      // ViewSwitcher：child0=缓存列表 / child1=搜索结果
      if (this.showCache && !this.searching) {
        this.cacheList()
      } else {
        this.resultArea()
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.common_color_6'))
  }

  /** mobile_campus_oa_toolbar_todo_search.xml：44vp 白底 + 搜索框(32vp 圆角灰) + "取消" */
  @Builder
  searchBar() {
    Column() {
      Row() {
        Row() {
          Image($r('app.media.mobile_campus_oa_search_b'))
            .width(16)
            .height(16)
            .margin({ left: 8, right: 9 })
          TextInput({
            text: this.keyword,
            placeholder: '输入关键字搜索...'
          })
            .fontSize(14)
            .fontColor($r('app.color.common_color_1'))
            .placeholderColor('#B5B5B5')
            .placeholderFont({ size: 14 })
            .backgroundColor(Color.Transparent)
            .padding(0)
            .layoutWeight(1)
            .height('100%')
            .enterKeyType(EnterKeyType.Search)
            .defaultFocus(true)
            .onChange((value: string) => {
              this.keyword = value;
            })
            .onSubmit(() => {
              // 源码 g.onEditorAction：IME actionSearch → w=1 → b3(keyword, 1)
              this.startSearch(this.keyword.trim(), 1);
            })
        }
        .width('100%')
        .height(32)
        // 源码 mobile_campus_shape_base_sesarch_bg：#F2F2F2 + 1px #DADBDF 描边 + 圆角 8dip
        .backgroundColor('#F2F2F2')
        .borderRadius(8)
        .border({ width: 1, color: '#DADBDF' })
        .layoutWeight(1)
        Text('取消')
          .fontSize(15)
          .fontColor($r('app.color.mobile_campus_primary_color_default'))
          .margin({ left: 8 })
          .hoverEffect(HoverEffect.Highlight)
          .onClick(() => {
            // 源码 h.onClick → finish()
            router.back();
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
      .alignItems(VerticalAlign.Center)
    }
    .width('100%')
    .backgroundColor($r('app.color.main_bg'))
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP])
  }

  /** child0：header"历史搜搜" + 缓存项(48vp 白底 + 移除叉) + footer"清空搜索记录" */
  @Builder
  cacheList() {
    Column() {
      Row() {
        Text('历史搜搜')
          .fontSize(13)
          .fontColor('#696969')
      }
      .width('100%')
      .height(32)
      .padding({ left: 12.5 })
      .alignItems(VerticalAlign.Center)
      .backgroundColor($r('app.color.white'))
      Divider()
        .color($r('app.color.common_color_5'))
        .strokeWidth(0.5)
        .width('100%')
      List({ space: 0 }) {
        ForEach(this.cache, (row: OaTodoRow) => {
          ListItem() {
            Row() {
              Text(row.author_cn)
                .fontSize(16)
                .fontColor($r('app.color.common_color_1'))
                .layoutWeight(1)
              Image($r('app.media.mobile_campus_oa_close_g'))
                .width(16)
                .height(16)
                .padding(4)
                .hoverEffect(HoverEffect.Highlight)
                .onClick(() => {
                  this.onCacheRemove(row);
                })
            }
            .width('100%')
            .height(48)
            .padding({ left: 12.5, right: 12 })
            .alignItems(VerticalAlign.Center)
            .backgroundColor($r('app.color.white'))
            .hoverEffect(HoverEffect.Highlight)
            .onClick(() => {
              this.onCacheClick(row);
            })
          }
        }, (row: OaTodoRow, idx: number) => idx.toString() + '-' + row.author_cn)
        ListItem() {
          Column() {
            Row() {
              Text('清空搜索记录')
                .fontSize(13)
                .fontColor('#696969')
                .margin({ right: 8 })
              // 源码 view_search_footer：drawableRight=rubbish_icon
              Image($r('app.media.rubbish_icon'))
                .width(14)
                .height(14)
            }
            .margin({ top: 29.5 })
          }
          .width('100%')
          .alignItems(HorizontalAlign.Center)
          .hoverEffect(HoverEffect.Highlight)
          .onClick(() => {
            this.onCacheClear();
          })
        }
      }
      .width('100%')
      .layoutWeight(1)
      .contentEndOffset(this.keyboardHeightVp + this.avoidAreaBottomVp)
      .scrollBar(BarState.Off)
    }
    .width('100%')
    .constraintSize({ maxWidth: BreakpointSystem.getContentMaxWidth(this.currentBreakpoint) })
    .alignSelf(ItemAlign.Center)
    .padding({ left: this.avoidAreaLeftVp, right: this.avoidAreaRightVp })
    .layoutWeight(1)
  }

  /** child1：搜索结果（分组头 36vp #F2F2F2 15fp #696969 + 子项 72vp 白底） */
  @Builder
  resultArea() {
    Column() {
      if (this.searching && this.groups.length === 0) {
        LoadingView()
      } else if (this.groups.length === 0) {
        Column() {
          EmptyView({ tipText: this.emptyText === '' ? '暂无搜索结果' : this.emptyText })
        }
        .width('100%')
        .padding({ bottom: this.keyboardHeightVp + this.avoidAreaBottomVp })
        .layoutWeight(1)
        .onClick(() => {
          if (this.emptyText !== '') {
            this.startSearch(this.keyword.trim(), 1);
          }
        })
      } else {
        List({ space: 0 }) {
          ForEach(this.groups, (group: OaTodoSearchGroup, gIdx: number) => {
            ListItem() {
              Text(group.name)
                .fontSize(15)
                .fontColor('#696969')
                .width('100%')
                .height(36)
                .padding({ left: 12, right: 12 })
                .backgroundColor($r('app.color.common_color_6'))
            }
            ForEach(group.rows, (row: OaTodoRow, cIdx: number) => {
              ListItem() {
                this.searchChild(row)
              }
            }, (row: OaTodoRow, cIdx: number) => gIdx.toString() + '-' + row.orUnid + '-' + cIdx.toString())
          }, (group: OaTodoSearchGroup, idx: number) => idx.toString() + group.name)
        }
        .width('100%')
        .layoutWeight(1)
        .contentEndOffset(this.keyboardHeightVp + this.avoidAreaBottomVp)
        .scrollBar(BarState.Off)
        .edgeEffect(EdgeEffect.Spring)
        .onReachEnd(() => {
          this.loadMore();
        })
      }
    }
    .width('100%')
    .constraintSize({ maxWidth: BreakpointSystem.getContentMaxWidth(this.currentBreakpoint) })
    .alignSelf(ItemAlign.Center)
    .padding({ left: this.avoidAreaLeftVp, right: this.avoidAreaRightVp })
    .layoutWeight(1)
  }

  /** mobile_campus_oa_view_item_todo_child.xml：72vp 白底 padL11.5 + 标题17fp + 第二行 申请人/hj/日期 */
  @Builder
  searchChild(row: OaTodoRow) {
    Column() {
      Column() {
        Text(row.subject)
          .fontSize(17)
          .fontColor($r('app.color.common_color_1'))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%')
        Row() {
          Text('申请人：' + row.author_cn)
            .fontSize(13)
            .fontColor($r('app.color.common_color_3'))
            .maxLines(1)
            .flexShrink(0)
          Blank().layoutWeight(1)
          this.hjBadge(row.hj)
          Text(row.docCreated)
            .fontSize(13)
            .fontColor($r('app.color.common_color_3'))
            .maxLines(1)
            .flexShrink(0)
        }
        .width('100%')
        .margin({ top: 12 })
        .alignItems(VerticalAlign.Center)
      }
      .width('100%')
      .height(69.5)
      .padding({ top: 8, right: 12 })
      Divider()
        .color($r('app.color.common_color_5'))
        .strokeWidth(0.5)
        .width('100%')
    }
    .width('100%')
    .height(72)
    .padding({ left: 11.5 })
    .backgroundColor($r('app.color.white'))
    .hoverEffect(HoverEffect.Highlight)
    .onClick(() => {
      this.onChildClick(row);
    })
  }

  /** tvState（e()）：一般/空 → gone；加急#FFC231 平急#82DC4B 急件#1B68B7 特急#ED874A 特提#FF6C6C */
  @Builder
  hjBadge(hj: string) {
    if (hj === '加急' || hj === '平急' || hj === '急件' || hj === '特急' || hj === '特提') {
      Text(hj)
        .fontSize(12)
        .fontColor($r('app.color.white'))
        .textAlign(TextAlign.Center)
        .width(32)
        .height(16)
        .backgroundColor(this.hjColor(hj))
        .margin({ right: 5 })
        .flexShrink(0)
    }
  }

  private hjColor(hj: string): string {
    if (hj === '加急') {
      return '#FFC231';
    }
    if (hj === '平急') {
      return '#82DC4B';
    }
    if (hj === '急件') {
      return '#1B68B7';
    }
    if (hj === '特急') {
      return '#ED874A';
    }
    return '#FF6C6C';
  }
}
