import { router } from '@kit.ArkUI';
import { TitleBar } from '../components/TitleBar';
import { LoadingView } from '../components/LoadingView';
import { EmptyView } from '../components/EmptyView';
import { ApiService } from '../network/ApiService';
import { ApiResponse } from '../model/ResponseModel';
import { ReadingBookEntry, ReadingHomeData } from '../model/ContactModel';
import { Constants } from '../data/Constants';
import { BusinessError } from '@kit.BasicServicesKit';

/**
 * 阅读首页 — 源码级翻译（MobileCampusReadingActivity + MobileCampusReadingFragment +
 * HistoryFragment + CollectFragment + TopView + 三个 Adapter，[W28 final-b]）。
 *
 * 【布局】mobile_campus_reading_activity：toolbar_normal("我的借阅") + MultiStateView +
 *   StickyNavLayout(id_stick)：
 *   - TopView 149dip 背景 mobile_campus_reading_bg_card：左上"借书卡" 50sp #0effffff
 *     ml26 mt18；左下"卡状态" 12sp 白 + tvState 12sp #38a2f3 白底圆角4 0.5 #cecece 49×28dip；
 *     中央 tvNum 36sp 白 + "已借（本）" 15sp 白；右下 tvDate 12sp 白 = home.userId；
 *     overdue>0 或 arrearage!="0" → 显示两格 #f2f2f2 61dip：tvOverdue 18sp #38a2f3+"本"13sp/
 *     "当前逾期书本"12sp #666666；tvPrice 18sp #38a2f3+"元"13sp/"欠费金额"12sp #666666。
 *   - TabLayout 44dip（tabGravity=center，tabIndicator #1b68b7；子项 margin 12dip）：
 *     当前借阅/历史借阅/我的收藏（l 字面量）。
 *   - ViewPager：三个 Fragment 共用 mobile_campus_reading_fragment（MultiStateView+ListView）。
 *   - 右下浮动按钮 mobile_campus_reading_btn_library → e.a.Y=/reading/search（ReadingSearchPage）。
 * 【数据】X2()：GET library/getHomePageData 无参 → HomePageData{status,borrowNum,userId,overdue,
 *   arrearage,currentBorrow[]}；历史 Y1()：POST getReturnData {pageNum,pageSize:ACK_REMOVE_PACKAGE="10"}
 *   → returnData[]（<10 停止上拉）；收藏 S1()：GET getMyCollect（复用 W25 方法）。
 * 【行】当前借阅 item_home 133dip：img 80×109 TP 网络图/默认书封 + SJMC 17sp + "借书日期：JYRQ"
 *   12sp mt12 + "还书日期：YHRQ" 12sp mt6 + 右侧 tvDate 64×24dip 12sp（DAY>0"还剩N天"#333 /
 *   DAY==0"即将逾期" / DAY<0"逾期N天"#F23C3C；tvRenew XML gone 恒隐藏保真）。
 *   历史 item_history 同上无右侧，附作者/出版社/馆藏地/索书号 12sp mt12/3/3/3；footer
 *   "仅显示最近一个月的数据" 白底 pad4 居中。收藏 item_search：img 80×109 + 四行字段 12sp；
 *   imgFavourite 源码 setVisibility(8) 恒隐藏保真。
 * 【点击】当前/历史/收藏行 → e.a.X=/reading/detail + {data,position}（500ms 防抖）→ ReadingDetailPage；
 *   详情返回 setResult(-1) → 刷新当前列表（AppStorage reading_detail_changed）。
 * 【探针】temp/probe_w28_final_b.py 锚点 [W28 final-b]。
 */
@Entry
@Component
struct ReadingPage {
  @State tab: number = 0;
  @State home: ReadingHomeData = new ReadingHomeData();
  @State currentBorrow: ReadingBookEntry[] = [];
  @State historyList: ReadingBookEntry[] = [];
  @State collectList: ReadingBookEntry[] = [];
  @State homeState: string = 'loading';
  @State historyState: string = 'loading';
  @State collectState: string = 'loading';
  @State historyPageNum: number = 1;
  @State historyHasMore: boolean = true;
  private lastClickTime: number = 0;

  aboutToAppear(): void {
    this.loadHome();
    this.loadHistory(true);
    this.loadCollect();
  }

  onPageShow(): void {
    const changed: string | undefined = AppStorage.get<string>('reading_detail_changed');
    if (changed !== undefined && changed !== null && changed !== '') {
      AppStorage.setOrCreate<string>('reading_detail_changed', '');
      this.loadHome();
      this.loadHistory(true);
      this.loadCollect();
    }
  }

  /** 源码 X2() → MobileCampusReadingModel.V0：GET getHomePageData */
  private loadHome(): void {
    this.homeState = this.currentBorrow.length === 0 ? 'loading' : 'content';
    ApiService.getReadingHomePage()
      .then((response: ApiResponse<ReadingHomeData>) => {
        if (response.code === 1000) {
          return;
        }
        if (response.code !== 0) {
          this.homeState = this.currentBorrow.length === 0 ? 'error' : 'content';
          ApiService.logError('reading home fail: ' + response.message);
          return;
        }
        this.home = response.data;
        this.currentBorrow = response.data.currentBorrow;
        this.homeState = this.currentBorrow.length > 0 ? 'content' : 'empty';
      })
      .catch((error: BusinessError) => {
        ApiService.logError('reading home error: ' + error.message);
        this.homeState = this.currentBorrow.length === 0 ? 'error' : 'content';
      });
  }

  /** 源码 HistoryFragment.W1()：POST getReturnData {pageNum,pageSize:"10"} */
  private loadHistory(reset: boolean): void {
    if (reset) {
      this.historyPageNum = 1;
      this.historyHasMore = true;
      this.historyState = this.historyList.length === 0 ? 'loading' : 'content';
    }
    const page: number = this.historyPageNum;
    ApiService.getReadingReturnData(String(page))
      .then((response: ApiResponse<ReadingBookEntry[]>) => {
        if (response.code === 1000) {
          return;
        }
        if (response.code !== 0) {
          if (page === 1) {
            this.historyState = 'error';
          }
          return;
        }
        const rows: ReadingBookEntry[] = response.data;
        if (page === 1) {
          this.historyList = rows;
        } else {
          this.historyList = this.historyList.concat(rows);
        }
        this.historyHasMore = rows.length >= 10;
        if (rows.length > 0) {
          this.historyPageNum = page + 1;
        }
        this.historyState = this.historyList.length > 0 ? 'content' : 'empty';
      })
      .catch((error: BusinessError) => {
        ApiService.logError('reading history fail: ' + error.message);
        if (page === 1) {
          this.historyState = 'error';
        }
      });
  }

  /** 源码 CollectFragment.Q1()：GET getMyCollect */
  private loadCollect(): void {
    this.collectState = this.collectList.length === 0 ? 'loading' : 'content';
    ApiService.getReadingMyCollect()
      .then((response: ApiResponse<ReadingBookEntry[]>) => {
        if (response.code === 1000) {
          return;
        }
        if (response.code !== 0) {
          this.collectState = this.collectList.length === 0 ? 'error' : 'content';
          return;
        }
        this.collectList = response.data;
        this.collectState = this.collectList.length > 0 ? 'content' : 'empty';
      })
      .catch((error: BusinessError) => {
        ApiService.logError('reading collect fail: ' + error.message);
        this.collectState = this.collectList.length === 0 ? 'error' : 'content';
      });
  }

  /** 书封 URL：源码 i.e(0, TP)（TP 为完整/相对路径，沿用 ReadingDetailPage 口径） */
  private coverUrl(book: ReadingBookEntry): ResourceStr {
    if (book.TP === '') {
      return $r('app.media.mobile_campus_reading_book_default');
    }
    return book.TP.startsWith('http') ? book.TP : Constants.SOCKET_HOST + book.TP;
  }

  private dayOf(book: ReadingBookEntry): number {
    const day: number = Number(book.DAY);
    return Number.isNaN(day) ? 0 : day;
  }

  /** 当前借阅右侧日期：DAY>0"还剩N天"/0"即将逾期"/<0"逾期N天" */
  private dayText(book: ReadingBookEntry): string {
    const day: number = this.dayOf(book);
    if (day > 0) {
      return '还剩' + String(day) + '天';
    }
    if (day === 0) {
      return '即将逾期';
    }
    return '逾期' + String(Math.abs(day)) + '天';
  }

  /** 源码 a/d/c 类：500ms 防抖 → ReadingDetailActivity{data,position}（110/111） */
  private openDetail(book: ReadingBookEntry, position: number): void {
    const now: number = Date.now();
    if (now - this.lastClickTime <= 500) {
      this.lastClickTime = now;
      return;
    }
    this.lastClickTime = now;
    router.pushUrl({
      url: 'pages/ReadingDetailPage',
      params: { 'data': JSON.stringify(book), 'position': String(position) } as Record<string, string>
    });
  }

  @Builder
  cardTop() {
    Stack({ alignContent: Alignment.Center }) {
      Image($r('app.media.mobile_campus_reading_bg_card'))
        .width('100%')
        .height('100%')
        .objectFit(ImageFit.Fill)

      Column() {
        Text('借书卡')
          .fontSize(50)
          .fontColor('#0EFFFFFF')
          .margin({ left: 26, top: 18 })
        Blank()
        Row() {
          Row() {
            Text('卡状态').fontSize(12).fontColor(Color.White)
            Text(this.home.status)
              .fontSize(12)
              .fontColor('#38A2F3')
              .width(49)
              .height(28)
              .textAlign(TextAlign.Center)
              .backgroundColor(Color.White)
              .borderRadius(2)
              .border({ width: 0.5, color: '#CECECE' })
              .margin({ left: 8 })
          }
          .alignItems(VerticalAlign.Center)
          Blank()
          Text(this.home.userId).fontSize(12).fontColor(Color.White)
        }
        .width('100%')
        .alignItems(VerticalAlign.Bottom)
        .padding({ left: 26, right: 26, bottom: 15 })
      }
      .width('100%')
      .height('100%')
      .alignItems(HorizontalAlign.Start)

      Column() {
        Text(this.home.borrowNum)
          .fontSize(36)
          .fontColor(Color.White)
          .maxLines(1)
        Text('已借（本）')
          .fontSize(15)
          .fontColor(Color.White)
      }
      .width('100%')
      .alignItems(HorizontalAlign.Center)
      .margin({ top: 18 })
    }
    .width('100%')
    .height(149)
    .backgroundColor(Color.White)
  }

  @Builder
  statePanel() {
    Row() {
      Column() {
        Row() {
          Text(this.home.overdue).fontSize(18).fontColor('#38A2F3')
          Text('本').fontSize(13).fontColor($r('app.color.common_color_1'))
        }
        .alignItems(VerticalAlign.Bottom)
        Text('当前逾期书本').fontSize(12).fontColor('#666666')
      }
      .layoutWeight(1)
      .height('100%')
      .justifyContent(FlexAlign.Center)
      .backgroundColor('#F2F2F2')
      .margin({ right: 7.5 })

      Column() {
        Row() {
          // 源码 setStateData(overdue, arrearage 空→"0")
          Text(this.home.arrearage === '' ? '0' : this.home.arrearage).fontSize(18).fontColor('#38A2F3')
          Text('元').fontSize(13).fontColor($r('app.color.common_color_1'))
        }
        .alignItems(VerticalAlign.Bottom)
        Text('欠费金额').fontSize(12).fontColor('#666666')
      }
      .layoutWeight(1)
      .height('100%')
      .justifyContent(FlexAlign.Center)
      .backgroundColor('#F2F2F2')
      .margin({ left: 7.5 })
    }
    .width('100%')
    .height(61)
    .padding({ left: 15, right: 15 })
    .margin({ top: 9, bottom: 9 })
  }

  @Builder
  tabItem(label: string, index: number) {
    Column() {
      Text(label)
        .fontSize(14)
        .fontColor(this.tab === index ? $r('app.color.mobile_campus_primary_color_default')
          : $r('app.color.common_color_3'))
        .padding({ left: 12, right: 12 })
      Column()
        .width(20)
        .height(2)
        .borderRadius(1)
        .backgroundColor($r('app.color.mobile_campus_primary_color_default'))
        .margin({ top: 2 })
        .visibility(this.tab === index ? Visibility.Visible : Visibility.Hidden)
    }
    .onClick(() => {
      this.tab = index;
    })
  }

  @Builder
  tabBar() {
    Row() {
      this.tabItem('当前借阅', 0)
      this.tabItem('历史借阅', 1)
      this.tabItem('我的收藏', 2)
    }
    .width('100%')
    .height(44)
    .justifyContent(FlexAlign.Center)
    .backgroundColor(Color.White)
  }

  /** 当前借阅行（mobile_campus_reading_item_home.xml 133dip） */
  @Builder
  currentItem(book: ReadingBookEntry, index: number) {
    Row() {
      Image(this.coverUrl(book))
        .width(80)
        .height(109)
        .objectFit(ImageFit.Cover)
        .margin({ left: 7.5, right: 8 })
      Column() {
        Text(book.SJMC).fontSize(17).fontColor($r('app.color.common_color_1')).maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        Text('借书日期：' + book.JYRQ).fontSize(12).fontColor($r('app.color.common_color_1'))
          .margin({ top: 12 }).maxLines(1)
        Text('还书日期：' + book.YHRQ).fontSize(12).fontColor($r('app.color.common_color_1'))
          .margin({ top: 6 }).maxLines(1)
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
      Column() {
        Text(this.dayText(book))
          .fontSize(12)
          .fontColor(this.dayOf(book) < 0 ? '#F23C3C' : $r('app.color.common_color_1'))
          .width(64)
          .height(24)
          .textAlign(TextAlign.Center)
      }
      .margin({ right: 7.5 })
    }
    .width('100%')
    .height(133)
    .backgroundColor(Color.White)
    .onClick(() => {
      this.openDetail(book, index);
    })
  }

  /** 历史借阅行（mobile_campus_reading_item_history.xml 133dip） */
  @Builder
  historyItem(book: ReadingBookEntry, index: number) {
    Row() {
      Image(this.coverUrl(book))
        .width(80)
        .height(109)
        .objectFit(ImageFit.Cover)
        .margin({ left: 7.5, right: 8 })
      Column() {
        Text(book.SJMC).fontSize(17).fontColor($r('app.color.common_color_1')).maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        Text('作者：' + book.ZZ).fontSize(12).fontColor($r('app.color.common_color_1'))
          .margin({ top: 12 }).maxLines(1)
        Text('出版社：' + book.CBS).fontSize(12).fontColor($r('app.color.common_color_1'))
          .margin({ top: 3 }).maxLines(1)
        Text('馆藏地：' + book.GCD).fontSize(12).fontColor($r('app.color.common_color_1'))
          .margin({ top: 3 }).maxLines(1)
        Text('索书号：' + book.SQH).fontSize(12).fontColor($r('app.color.common_color_1'))
          .margin({ top: 3 }).maxLines(1)
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .height(133)
    .backgroundColor(Color.White)
    .onClick(() => {
      this.openDetail(book, index);
    })
  }

  /** 收藏行（mobile_campus_reading_item_search.xml；imgFavourite 恒 gone 保真） */
  @Builder
  collectItem(book: ReadingBookEntry, index: number) {
    Row() {
      Image(this.coverUrl(book))
        .width(80)
        .height(109)
        .objectFit(ImageFit.Cover)
        .margin({ right: 8 })
      Column() {
        Text(book.SJMC).fontSize(17).fontColor($r('app.color.common_color_1')).maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        Text('作者：' + book.ZZ).fontSize(12).fontColor($r('app.color.common_color_1'))
          .margin({ top: 12 }).maxLines(1)
        Text('出版社：' + book.CBS).fontSize(12).fontColor($r('app.color.common_color_1'))
          .margin({ top: 3 }).maxLines(1)
        Text('馆藏地：' + book.GCD).fontSize(12).fontColor($r('app.color.common_color_1'))
          .margin({ top: 3 }).maxLines(1)
        Text('索书号：' + book.SQH).fontSize(12).fontColor($r('app.color.common_color_1'))
          .margin({ top: 3 }).maxLines(1)
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .padding(7.5)
    .backgroundColor(Color.White)
    .onClick(() => {
      this.openDetail(book, index);
    })
  }

  @Builder
  stateView(state: string, emptyTip: string) {
    if (state === 'loading') {
      Column() { LoadingView() }.width('100%').height('100%')
    } else if (state === 'error') {
      Column() { EmptyView({ tipText: '获取数据失败，请下拉重试' }) }.width('100%').height('100%')
    } else {
      Column() { EmptyView({ tipText: emptyTip }) }.width('100%').height('100%')
    }
  }

  @Builder
  currentPage() {
    if (this.homeState !== 'content') {
      this.stateView(this.homeState, '暂无借阅')
    } else {
      List() {
        ForEach(this.currentBorrow, (book: ReadingBookEntry, index: number) => {
          ListItem() {
            this.currentItem(book, index)
          }
        }, (book: ReadingBookEntry, index: number) => 'cur_' + book.SJMC + '_' + String(index))
      }
      .width('100%')
      .height('100%')
      .divider({ strokeWidth: 0.5, color: $r('app.color.common_color_5') })
      .scrollBar(BarState.Off)
    }
  }

  @Builder
  historyPage() {
    if (this.historyState !== 'content') {
      this.stateView(this.historyState, '暂无历史借阅')
    } else {
      List() {
        ForEach(this.historyList, (book: ReadingBookEntry, index: number) => {
          ListItem() {
            this.historyItem(book, index)
          }
        }, (book: ReadingBookEntry, index: number) => 'his_' + book.SJMC + '_' + String(index))
        ListItem() {
          Text('仅显示最近一个月的数据')
            .fontSize(12)
            .fontColor($r('app.color.common_color_3'))
            .width('100%')
            .textAlign(TextAlign.Center)
            .padding(4)
            .backgroundColor(Color.White)
        }
      }
      .width('100%')
      .height('100%')
      .divider({ strokeWidth: 0.5, color: $r('app.color.common_color_5') })
      .scrollBar(BarState.Off)
      .onReachEnd(() => {
        if (this.historyHasMore) {
          this.loadHistory(false);
        }
      })
    }
  }

  @Builder
  collectPage() {
    if (this.collectState !== 'content') {
      this.stateView(this.collectState, '更多好书等你来收藏')
    } else {
      List() {
        ForEach(this.collectList, (book: ReadingBookEntry, index: number) => {
          ListItem() {
            this.collectItem(book, index)
          }
        }, (book: ReadingBookEntry, index: number) => 'col_' + book.SJMC + '_' + String(index))
      }
      .width('100%')
      .height('100%')
      .divider({ strokeWidth: 0.5, color: $r('app.color.common_color_5') })
      .scrollBar(BarState.Off)
    }
  }

  build() {
    Stack({ alignContent: Alignment.BottomEnd }) {
      Column() {
        TitleBar({ title: '我的借阅', showBack: true })
        this.cardTop()
        if (Number(this.home.overdue) > 0 || this.home.arrearage !== '0') {
          this.statePanel()
        }
        this.tabBar()
        if (this.tab === 0) {
          this.currentPage()
        } else if (this.tab === 1) {
          this.historyPage()
        } else {
          this.collectPage()
        }
      }
      .width('100%')
      .height('100%')
      .backgroundColor($r('app.color.common_color_6'))

      Image($r('app.media.mobile_campus_reading_btn_library'))
        .width(50)
        .height(50)
        .margin({ right: 15, bottom: 15 })
        .onClick(() => {
          router.pushUrl({ url: 'pages/ReadingSearchPage' });
        })
    }
    .width('100%')
    .height('100%')
  }
}
