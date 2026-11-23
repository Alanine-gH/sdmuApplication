import { TitleBar } from '../components/TitleBar';
import { router } from '@kit.ArkUI';
import { BreakpointSystem } from '../common/BreakpointSystem';
import { ApiService } from '../network/ApiService';
import { ApiResponse } from '../model/ResponseModel';
import { ReadingBookEntry } from '../model/ContactModel';
import { EmptyView } from '../components/EmptyView';
import { LoadingView } from '../components/LoadingView';
import { Constants } from '../data/Constants';

/**
 * 图书馆搜索页 — 源码级翻译（MobileCampusReadingSearchActivity.java 逐行 → ArkTS，[W25 misc-b]）：
 *
 * 【布局】mobile_campus_reading_activity_search.xml：toolbar("图书馆"，T1) + ClearableEditText
 *   32dip margin14/4 hint"搜索书籍" 14fp(px_to_sp_28) hint#B5B5B5 search 图标 dp9 + MultiStateView(ListView)
 * 【初始】f1()：adapter=CollectingAdapter（收藏列表，imgFavourite 恒 gone）+ f3() =
 *   GET library/getMyCollect → a 类：空→EMPTY_READING；有→显示
 * 【搜索】d 类 IME action 3：u=trim 非空 → t=1 → g3()：POST library/searchMyCollect
 *   {startIndex:t, pageSize:AgooConstants.ACK_REMOVE_PACKAGE="10", keyword} → i 类：
 *   空&&t==1→setData+关上拉；有数据→t==1 setData+开上拉 else addData；t++（N2）；行=SearchAdapter
 * 【行】mobile_campus_reading_item_search.xml：img 80×109(px_to_dip_160×218) TP 网络图/默认书封 +
 *   SJMC 17fp(px_to_sp_34) + 作者：ZZ/出版社：CBS/馆藏地：GCD/索书号：SQH 12fp(px_to_sp_24) mt12/3/3/3 +
 *   imgFavourite mr14（搜索态显示 heart/heart_default；收藏态 gone）
 * 【心形】b 类：COLLECTXLH 空→e3 collectBook{8参}；非空→d3 cancelCollect{COLLECTXLH}；
 *   f 类：data=="1"→置 null；g 类：COLLECTXLH=data.replaceAll("\"","")
 * 【行点击】c/h 类：500ms 防抖 → 详情{data,position} 请求码110（e.a.X）→ RESULT_OK →
 *   setResult(-1) + 重拉当前列表（收藏态 f3 / 搜索态 g3(u)）
 * 【上拉】e 类 b()：keyword 非空 → g3（t 已自增）；下拉 a() 空实现
 * 【态】t==1：e()→ERROR / f()→NETWORK_ERROR+toast；详情收藏变化经 AppStorage reading_detail_changed
 *   等价 setResult(-1) 链（onPageShow 重拉）
 */
@Entry
@Component
struct ReadingSearchPage {
  @State keyword: string = '';
  @State collectList: ReadingBookEntry[] = [];
  @State searchList: ReadingBookEntry[] = [];
  /** 源码 n 当前 adapter：collect（初始）/ search（搜索后） */
  @State mode: string = 'collect';
  @State isLoading: boolean = true;
  @State showError: boolean = false;
  @State isRefreshing: boolean = false;
  @StorageProp('currentBreakpoint') currentBreakpoint: string = 'sm';
  @StorageProp('avoidAreaBottomVp') avoidAreaBottomVp: number = 0;
  /** 源码 t：搜索分页 startIndex（新搜索重置 1，有数据自增） */
  private page: number = 1;
  /** 源码 u：最近一次搜索词 */
  private lastKeyword: string = '';
  /** 源码 s：行点击防抖时间戳 */
  private lastClickTime: number = 0;

  onPageShow(): void {
    // 源码 onActivityResult(110, RESULT_OK)：详情收藏变化 → setResult(-1) + 重拉当前列表
    const changed = AppStorage.get<string>('reading_detail_changed');
    if (changed !== undefined && changed !== null && changed !== '') {
      AppStorage.setOrCreate<string>('reading_detail_changed', '');
      this.reloadCurrent();
    }
  }

  aboutToAppear(): void {
    this.loadCollect();
  }

  /** 源码 f3()：GET library/getMyCollect（收藏态，imgFavourite gone） */
  private loadCollect(): void {
    this.isLoading = this.collectList.length === 0;
    this.mode = 'collect';
    ApiService.getReadingMyCollect()
      .then((response: ApiResponse<ReadingBookEntry[]>) => {
        this.isLoading = false;
        this.isRefreshing = false;
        if (response.code === 1000) {
          return;
        }
        if (response.code !== 0) {
          // 源码 f()：NETWORK_ERROR 态 + toast(message)
          const msg: string = response.message === '' ? '服务器繁忙，请稍后再试' : response.message;
          this.getUIContext().getPromptAction().showToast({ message: msg });
          this.showError = this.collectList.length === 0;
          return;
        }
        // 源码 a 类 g()：空 → EMPTY_READING；有 → 显示
        this.collectList = response.data;
        this.showError = false;
      })
      .catch(() => {
        ApiService.logError('ReadingSearchPage collect error');
        this.isLoading = false;
        this.isRefreshing = false;
        this.showError = true;
      });
  }

  /** 源码 d 类 IME 搜索：u=trim 非空 → t=1 → g3(u) */
  private submitSearch(): void {
    const kw: string = this.keyword.trim();
    if (kw === '') {
      return;
    }
    this.lastKeyword = kw;
    this.page = 1;
    this.mode = 'search';
    this.isLoading = true;
    this.showError = false;
    this.requestSearch(false);
  }

  /** 源码 g3()：searchMyCollect {startIndex:t, pageSize:10, keyword} → i 类回调 */
  private requestSearch(append: boolean): void {
    ApiService.searchReadingCollect(String(this.page), this.lastKeyword)
      .then((response: ApiResponse<ReadingBookEntry[]>) => {
        this.isLoading = false;
        this.isRefreshing = false;
        if (response.code === 1000) {
          return;
        }
        if (response.code !== 0) {
          // 源码 f()：t==1 → NETWORK_ERROR 态 + toast；else 静默
          const msg: string = response.message === '' ? '服务器繁忙，请稍后再试' : response.message;
          this.getUIContext().getPromptAction().showToast({ message: msg });
          if (this.page === 1) {
            this.showError = true;
          }
          return;
        }
        const list: ReadingBookEntry[] = response.data;
        if (list.length === 0) {
          // 源码 i 类 g()：空 && t==1 → setData(空) + 关上拉
          if (this.page === 1) {
            this.searchList = [];
          }
          return;
        }
        if (this.page === 1) {
          this.searchList = list;
        } else {
          // 源码 addData：追加
          this.searchList = this.searchList.concat(list);
        }
        // 源码 N2：t++
        this.page = this.page + 1;
        this.showError = false;
      })
      .catch(() => {
        ApiService.logError('ReadingSearchPage search error');
        this.isLoading = false;
        this.isRefreshing = false;
        // 源码 e()：t==1 → ERROR；else 静默
        if (this.page === 1) {
          this.showError = true;
        }
      });
  }

  /** 源码 onActivityResult 等价：重拉当前态列表 */
  private reloadCurrent(): void {
    if (this.mode === 'collect') {
      this.loadCollect();
    } else if (this.lastKeyword !== '') {
      this.page = 1;
      this.requestSearch(false);
    }
  }

  /** 源码 c/h 类：行点击（500ms 防抖）→ 详情{data, position} */
  private openDetail(bean: ReadingBookEntry, position: number): void {
    const now: number = Date.now();
    if (now - this.lastClickTime <= 500) {
      this.lastClickTime = now;
      return;
    }
    this.lastClickTime = now;
    router.pushUrl({ url: 'pages/ReadingDetailPage',
      params: {
        'data': JSON.stringify(bean),
        'position': String(position)
      } as Record<string, string> });
  }

  /** 源码 b 类：心形点击 → collectBook/cancelCollect → 回写 COLLECTXLH */
  private onHeartTap(bean: ReadingBookEntry, position: number): void {
    if (bean.COLLECTXLH === '') {
      // 源码 e3 → collectBook{SJMC,TP,CBS,ZZ,GCD,SQH,CBRQ,TXM}
      ApiService.collectReadingBook(bean.SJMC, bean.TP, bean.CBS, bean.ZZ, bean.GCD, bean.SQH,
        bean.CBRQ, bean.TXM)
        .then((response: ApiResponse<string>) => {
          if (response.code !== 0) {
            this.toastFail(response.message);
            return;
          }
          // 源码 g 类：COLLECTXLH = data.replaceAll("\"","")
          bean.COLLECTXLH = response.data.replace(/"/g, '');
          this.notifyListChanged(bean, position);
        });
      return;
    }
    // 源码 d3 → cancelCollect{COLLECTXLH}：data=="1" → 置 null
    ApiService.cancelReadingCollect(bean.COLLECTXLH)
      .then((response: ApiResponse<string>) => {
        if (response.code !== 0) {
          this.toastFail(response.message);
          return;
        }
        if (response.data === '1') {
          bean.COLLECTXLH = '';
          this.notifyListChanged(bean, position);
        }
      });
  }

  /** 列表项更新（notifyDataSetChanged 等价：替换数组元素触发 ForEach 刷新） */
  private notifyListChanged(bean: ReadingBookEntry, position: number): void {
    if (this.mode === 'collect') {
      const list: ReadingBookEntry[] = this.collectList.slice();
      list[position] = bean;
      this.collectList = list;
    } else {
      const list: ReadingBookEntry[] = this.searchList.slice();
      list[position] = bean;
      this.searchList = list;
    }
  }

  private toastFail(message: string): void {
    const msg: string = message === '' ? '服务器繁忙，请稍后再试' : message;
    this.getUIContext().getPromptAction().showToast({ message: msg });
  }

  /** 头像/书封 URL（源码 i.e(0, netconstant.d.c()+TP)） */
  private coverUrlOf(bean: ReadingBookEntry): string {
    if (bean.TP === '') {
      return '';
    }
    return Constants.SOCKET_HOST + bean.TP;
  }

  build() {
    Column() {
      TitleBar({ title: '图书馆', showBack: true })

      // ClearableEditText：32dip margin14/4 hint"搜索书籍"
      Column() {
        Row() {
          Image($r('app.media.mobile_campus_reading_search'))
            .width(16)
            .height(16)
            .margin({ left: 12, right: 9 })
          TextInput({ text: this.keyword, placeholder: '搜索书籍' })
            .fontSize(14)
            .fontColor($r('app.color.common_color_1'))
            .placeholderColor('#B5B5B5')
            .placeholderFont({ size: 14 })
            .backgroundColor(Color.Transparent)
            .border({ width: 0 })
            .padding(0)
            .layoutWeight(1)
            .height(32)
            .onChange((value: string) => {
              this.keyword = value;
            })
            .onSubmit(() => {
              this.submitSearch();
            })
        }
        .width('100%')
        .height(32)
        .borderRadius(4)
        .backgroundColor($r('app.color.white'))
        .alignItems(VerticalAlign.Center)
      }
      .width('100%')
      .constraintSize({ maxWidth: BreakpointSystem.getContentMaxWidth(this.currentBreakpoint) })
      .padding({ left: 14, right: 4, top: 14 })

      if (this.isLoading) {
        LoadingView()
      } else if (this.showError) {
        Column() {
          EmptyView({ tipText: '加载失败，请检查网络后重试' })
        }
        .width('100%')
        .layoutWeight(1)
      } else if (this.mode === 'collect') {
        this.collectListView()
      } else if (this.searchList.length === 0) {
        // 源码 q2(EMPTY_READING)
        Column() {
          EmptyView({ tipText: '暂无数据' })
        }
        .width('100%')
        .layoutWeight(1)
      } else {
        this.searchListView()
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.white'))
  }

  /** 收藏态列表（CollectingAdapter：imgFavourite 恒 gone，行点击同样进详情） */
  @Builder
  collectListView() {
    Refresh({ refreshing: this.isRefreshing }) {
      List() {
        ForEach(this.collectList, (bean: ReadingBookEntry, idx: number) => {
          ListItem() {
            this.bookRow(bean, idx, false)
          }
        }, (bean: ReadingBookEntry, idx: number) => bean.TXM + '_' + idx)
      }
      .width('100%')
      .constraintSize({ maxWidth: BreakpointSystem.getContentMaxWidth(this.currentBreakpoint) })
      .padding({ bottom: this.avoidAreaBottomVp })
      .scrollBar(BarState.Off)
    }
    .width('100%')
    .layoutWeight(1)
    .onRefreshing(() => {
      this.loadCollect();
    })
  }

  /** 搜索态列表（SearchAdapter：心形可点 + 上拉分页） */
  @Builder
  searchListView() {
    List() {
      ForEach(this.searchList, (bean: ReadingBookEntry, idx: number) => {
        ListItem() {
          this.bookRow(bean, idx, true)
        }
      }, (bean: ReadingBookEntry, idx: number) => bean.TXM + '_' + idx)
    }
    .width('100%')
    .constraintSize({ maxWidth: BreakpointSystem.getContentMaxWidth(this.currentBreakpoint) })
    .padding({ bottom: this.avoidAreaBottomVp })
    .layoutWeight(1)
    .scrollBar(BarState.Off)
    .onReachEnd(() => {
      // 源码 e 类 b()：keyword 非空 → g3（t 已自增）
      if (this.lastKeyword !== '') {
        this.requestSearch(true);
      }
    })
  }

  // mobile_campus_reading_item_search.xml：书封 80×109 + 文本列 + 心形（搜索态）
  @Builder
  bookRow(bean: ReadingBookEntry, idx: number, showHeart: boolean) {
    Row() {
      if (this.coverUrlOf(bean) !== '') {
        Image(this.coverUrlOf(bean))
          .width(80)
          .height(109)
      } else {
        Image($r('app.media.mobile_campus_reading_book_default'))
          .width(80)
          .height(109)
      }

      Column() {
        Text(bean.SJMC)
          .fontSize(17)
          .fontColor($r('app.color.common_color_1'))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        Text('作者：' + bean.ZZ)
          .fontSize(12)
          .fontColor($r('app.color.common_color_1'))
          .margin({ top: 12 })
          .maxLines(1)
        Text('出版社：' + bean.CBS)
          .fontSize(12)
          .fontColor($r('app.color.common_color_1'))
          .margin({ top: 3 })
          .maxLines(1)
        Text('馆藏地：' + bean.GCD)
          .fontSize(12)
          .fontColor($r('app.color.common_color_1'))
          .margin({ top: 3 })
          .maxLines(1)
        Text('索书号：' + bean.SQH)
          .fontSize(12)
          .fontColor($r('app.color.common_color_1'))
          .margin({ top: 3 })
          .maxLines(1)
      }
      .alignItems(HorizontalAlign.Start)
      .margin({ left: 8 })
      .layoutWeight(1)

      // imgFavourite：搜索态显示（XML src=heart_red，代码按 COLLECTXLH 切 heart/heart_default）；
      // 收藏态（CollectingAdapter.a 类）恒 gone
      Image(bean.COLLECTXLH === '' ? $r('app.media.mobile_campus_reading_icon_heart_default')
        : $r('app.media.mobile_campus_reading_icon_heart'))
        .width(24)
        .height(24)
        .margin({ right: 14 })
        .visibility(showHeart ? Visibility.Visible : Visibility.None)
        .onClick(() => {
          this.onHeartTap(bean, idx);
        })
    }
    .width('100%')
    .padding(7.5)
    .alignItems(VerticalAlign.Center)
    .onClick(() => {
      this.openDetail(bean, idx);
    })
  }
}
