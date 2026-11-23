import { router } from '@kit.ArkUI';
import { BreakpointSystem } from '../common/BreakpointSystem';
import { ApiService } from '../network/ApiService';
import { ApiResponse } from '../model/ResponseModel';
import { ReadingBookEntry } from '../model/ContactModel';
import { LoadingView } from '../components/LoadingView';
import { Constants } from '../data/Constants';

/**
 * 图书详情页 — 源码级翻译（MobileCampusReadingDetailActivity.java 逐行 → ArkTS，[W25 misc-b]）：
 *
 * 【布局】mobile_campus_reading_activity_detail.xml：toolbar gone（F2 状态色 #ffffff）+ StickyNavLayout：
 *   TopView 380dip（mobile_campus_reading_view_detail_top.xml：layoutSpace 155dip 透明区点击 finish +
 *   白底块 225dip：tvTitle 18fp mt95 + tvAuthor 13fp mt12 + tvDate mt7(CurrentBorrowBean 才显示，
 *   Search/收藏态 gone) + tvRenew"我要续借" XML gone 且两个分支都 setVisibility(8) 恒 gone 保真省略；
 *   img 126×166.5 mt75 居中 TP 网络图/默认书封；imgFavourite 32×32 right mt69 mr12 setData 显示）+
 *   指示条 bg#f2f2f2（TabLayout 44dip mt8 tabIndicator 无指示线 选中色 primary）+ ViewPager
 * 【页签】寻书 / 简介（custom view：icon+15fp(ml9) selector_tab 选中 #1B68B7 未选 #999999；
 *   xunshu/book 双态图）+ onTabSelected 双向联动
 * 【寻书页】FindFragment（mobile_campus_reading_fragment_detail_find.xml）pad15 8 行（mt15）：
 *   出版社 CBS/索书号 SQH/馆藏地 GCD/ISBN/条形码 TXM/在馆状态 ZGZT/页面 YS/价格 JG——空→"-----"；
 *   label 14fp(px_to_sp_28)，值 13fp（前两行 px_to_sp_26）/14fp
 * 【简介页】IntroductionFragment：layoutNone 显示（主区 gone）："暂无简介" 15fp + 引言 14fp#666 mt50
 *   + "---余秋雨" 14fp#666 右对齐（固定文案 XML 原样）
 * 【入参】data（BaseReadingData JSON；Search/收藏条目通用）+ position
 * 【收藏】imgFavourite 点击 b 类：COLLECTXLH 空→collectBook{8参}；非空→cancelCollect{COLLECTXLH}；
 *   成功→setData 重渲 + setResult(-1)（HAP AppStorage reading_detail_changed 等价 110 链）
 * 【tvRenew/layoutSpace】tvRenew 死代码（两分支均 gone）不复刻；layoutSpace 点击 finish
 */
interface ReadingTab {
  name: string;
  icon: Resource;
  iconSelected: Resource;
}

@Entry
@Component
struct ReadingDetailPage {
  @State book: ReadingBookEntry = new ReadingBookEntry();
  @State pageTab: number = 0;
  @State isBusy: boolean = false;
  @StorageProp('currentBreakpoint') currentBreakpoint: string = 'sm';
  @StorageProp('avoidAreaTopVp') avoidAreaTopVp: number = 0;
  @StorageProp('avoidAreaBottomVp') avoidAreaBottomVp: number = 0;
  @StorageProp('avoidAreaLeftVp') avoidAreaLeftVp: number = 0;
  @StorageProp('avoidAreaRightVp') avoidAreaRightVp: number = 0;
  private posName: string = '';
  private readonly tabs: ReadingTab[] = [
    { name: '寻书', icon: $r('app.media.mobile_campus_reading_icon_xunshu_default'),
      iconSelected: $r('app.media.mobile_campus_reading_icon_xunshu_selected') },
    { name: '简介', icon: $r('app.media.mobile_campus_reading_icon_book_default'),
      iconSelected: $r('app.media.mobile_campus_reading_icon_book_selected') }
  ];

  aboutToAppear(): void {
    const params = router.getParams() as Record<string, string>;
    if (params !== null && params !== undefined) {
      const dataJson: string = params['data'] !== undefined && params['data'] !== null ? params['data'] : '';
      this.posName = params['position'] !== undefined && params['position'] !== null ? params['position'] : '';
      if (dataJson !== '') {
        try {
          const parsed: Object = JSON.parse(dataJson) as Object;
          const rec: Record<string, Object> = parsed as Record<string, Object>;
          const bean: ReadingBookEntry = new ReadingBookEntry();
          bean.CBRQ = ApiService.pick(rec, ['CBRQ']);
          bean.CBS = ApiService.pick(rec, ['CBS']);
          bean.COLLECTXLH = ApiService.pick(rec, ['COLLECTXLH']);
          bean.GCD = ApiService.pick(rec, ['GCD']);
          bean.ISBN = ApiService.pick(rec, ['ISBN']);
          bean.JG = ApiService.pick(rec, ['JG']);
          bean.SJMC = ApiService.pick(rec, ['SJMC']);
          bean.SQH = ApiService.pick(rec, ['SQH']);
          bean.TMH = ApiService.pick(rec, ['TMH']);
          bean.TP = ApiService.pick(rec, ['TP']);
          bean.TXM = ApiService.pick(rec, ['TXM']);
          bean.YS = ApiService.pick(rec, ['YS']);
          bean.ZGZT = ApiService.pick(rec, ['ZGZT']);
          bean.ZZ = ApiService.pick(rec, ['ZZ']);
          this.book = bean;
        } catch {
          ApiService.logError('ReadingDetailPage parse data fail');
        }
      }
    }
  }

  /** 书封 URL（源码 i.e(0, netconstant.d.c()+TP)） */
  private coverUrl(): string {
    if (this.book.TP === '') {
      return '';
    }
    return Constants.SOCKET_HOST + this.book.TP;
  }

  /** FindFragment 值：空 → "-----" */
  private dashOf(value: string): string {
    return value === '' ? '-----' : value;
  }

  /** 源码 b 类 imgFavourite：收藏/取消收藏（成功 → 重渲 + setResult(-1) 等价） */
  private onHeartTap(): void {
    if (this.isBusy) {
      return;
    }
    this.isBusy = true;
    if (this.book.COLLECTXLH === '') {
      ApiService.collectReadingBook(this.book.SJMC, this.book.TP, this.book.CBS, this.book.ZZ,
        this.book.GCD, this.book.SQH, this.book.CBRQ, this.book.TXM)
        .then((response: ApiResponse<string>) => {
          this.isBusy = false;
          if (response.code !== 0) {
            const msg: string = response.message === '' ? '服务器繁忙，请稍后再试' : response.message;
            this.getUIContext().getPromptAction().showToast({ message: msg });
            return;
          }
          // 源码 d 类 g()：COLLECTXLH = data.replaceAll("\"","") + setData + setResult(-1)
          this.book.COLLECTXLH = response.data.replace(/"/g, '');
          this.refreshBook();
        });
      return;
    }
    ApiService.cancelReadingCollect(this.book.COLLECTXLH)
      .then((response: ApiResponse<string>) => {
        this.isBusy = false;
        if (response.code !== 0) {
          const msg: string = response.message === '' ? '服务器繁忙，请稍后再试' : response.message;
          this.getUIContext().getPromptAction().showToast({ message: msg });
          return;
        }
        if (response.data === '1') {
          // 源码 c 类 g()：COLLECTXLH = null + setData + setResult(-1)
          this.book.COLLECTXLH = '';
          this.refreshBook();
        }
      });
  }

  /** setResult(-1) 等价：收藏变化标记，上游 ReadingSearchPage.onPageShow 重拉 */
  private refreshBook(): void {
    const copy: ReadingBookEntry = new ReadingBookEntry();
    copy.CBRQ = this.book.CBRQ;
    copy.CBS = this.book.CBS;
    copy.COLLECTXLH = this.book.COLLECTXLH;
    copy.GCD = this.book.GCD;
    copy.ISBN = this.book.ISBN;
    copy.JG = this.book.JG;
    copy.SJMC = this.book.SJMC;
    copy.SQH = this.book.SQH;
    copy.TMH = this.book.TMH;
    copy.TP = this.book.TP;
    copy.TXM = this.book.TXM;
    copy.YS = this.book.YS;
    copy.ZGZT = this.book.ZGZT;
    copy.ZZ = this.book.ZZ;
    this.book = copy;
    AppStorage.setOrCreate<string>('reading_detail_changed', this.posName + '_' + String(Date.now()));
  }

  /** FindFragment 8 行 label */
  private readonly findLabels: string[] = ['出版社：', '索书号：', '馆藏地：', 'ISBN：', '条形码：', '在馆状态：', '页面：', '价格信息：'];

  build() {
    Column() {
      // 源码 toolbar_normal visibility=gone
      if (this.isBusy) {
        LoadingView()
      }
      Scroll() {
        Column() {
          // StickyNavLayout TopView 380dip
          Stack({ alignContent: Alignment.TopStart }) {
            Column() {
              // layoutSpace 155dip：点击 finish（源码 b 类）
              Column()
                .width('100%')
                .height(155)
                .onClick(() => {
                  this.getUIContext().getRouter().back();
                })

              // 白底块 225dip：tvTitle mt95 + tvAuthor mt12 + tvDate(CurrentBorrowBean 才有，搜索态 gone)
              Column() {
                Text(this.book.SJMC)
                  .fontSize(18)
                  .fontColor($r('app.color.common_color_1'))
                  .textAlign(TextAlign.Center)
                  .maxLines(2)
                  .margin({ top: 95 })
                Text(this.book.ZZ)
                  .fontSize(13)
                  .fontColor($r('app.color.common_color_1'))
                  .margin({ top: 12 })
                  .maxLines(1)
              }
              .width('100%')
              .height(225)
              .backgroundColor($r('app.color.white'))
              .alignItems(HorizontalAlign.Center)
            }
            .width('100%')

            // img 126×166.5 mt75 居中（center|top）
            Column() {
              if (this.coverUrl() !== '') {
                Image(this.coverUrl())
                  .width(126)
                  .height(166.5)
                  .margin({ top: 75 })
              } else {
                Image($r('app.media.mobile_campus_reading_book_default'))
                  .width(126)
                  .height(166.5)
                  .margin({ top: 75 })
              }
            }
            .width('100%')
            .alignItems(HorizontalAlign.Center)

            // imgFavourite 32×32 right mt69 mr12（setData 恒显示）
            Row() {
              Blank()
              Image(this.book.COLLECTXLH === '' ? $r('app.media.mobile_campus_reading_icon_heart_default')
                : $r('app.media.mobile_campus_reading_icon_heart'))
                .width(32)
                .height(32)
                .margin({ top: 69, right: 12 })
                .onClick(() => {
                  this.onHeartTap();
                })
            }
            .width('100%')
          }
          .width('100%')
          .height(380)

          // 指示条 bg#f2f2f2 mt8：tab 高 44(px_to_dip_88)
          Row() {
            ForEach(this.tabs, (tab: ReadingTab, idx: number) => {
              Row() {
                Image(this.pageTab === idx ? tab.iconSelected : tab.icon)
                  .width(18)
                  .height(18)
                Text(tab.name)
                  .fontSize(15)
                  .fontColor(this.pageTab === idx ? '#1B68B7' : '#999999')
                  .margin({ left: 9 })
              }
              .padding({ left: 14, right: 14 })
              .height(44)
              .alignItems(VerticalAlign.Center)
              .onClick(() => {
                // 源码 a 类：onTabSelected → setCurrentItem + 双向联动
                this.pageTab = idx;
              })
            }, (tab: ReadingTab) => tab.name)
          }
          .width('100%')
          .backgroundColor($r('app.color.white'))
          .margin({ top: 8 })
          .justifyContent(FlexAlign.Center)

          // ViewPager：寻书 / 简介
          if (this.pageTab === 0) {
            this.findPage()
          } else {
            this.introPage()
          }
        }
        .width('100%')
        .constraintSize({ maxWidth: BreakpointSystem.getContentMaxWidth(this.currentBreakpoint) })
        .padding({
          top: this.avoidAreaTopVp,
          bottom: Math.max(16, this.avoidAreaBottomVp),
          left: this.avoidAreaLeftVp,
          right: this.avoidAreaRightVp
        })
      }
      .width('100%')
      .layoutWeight(1)
      .scrollBar(BarState.Off)
      .backgroundColor($r('app.color.white'))
      .align(Alignment.Top)
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.white'))
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
  }

  // mobile_campus_reading_fragment_detail_find.xml：8 行信息（mt15）
  @Builder
  findPage() {
    Column() {
      this.findRow(this.findLabels[0], this.dashOf(this.book.CBS), 13)
      this.findRow(this.findLabels[1], this.dashOf(this.book.SQH), 13)
      this.findRow(this.findLabels[2], this.dashOf(this.book.GCD), 14)
      this.findRow(this.findLabels[3], this.dashOf(this.book.ISBN), 14)
      this.findRow(this.findLabels[4], this.dashOf(this.book.TXM), 14)
      this.findRow(this.findLabels[5], this.dashOf(this.book.ZGZT), 14)
      this.findRow(this.findLabels[6], this.dashOf(this.book.YS), 14)
      this.findRow(this.findLabels[7], this.dashOf(this.book.JG), 14)
    }
    .width('100%')
    .padding(15)
    .backgroundColor($r('app.color.white'))
  }

  @Builder
  findRow(label: string, value: string, valueSize: number) {
    Row() {
      Text(label)
        .fontSize(14)
        .fontColor($r('app.color.common_color_1'))
      Text(value)
        .fontSize(valueSize)
        .fontColor($r('app.color.common_color_1'))
        .layoutWeight(1)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
    }
    .width('100%')
    .margin({ top: 15 })
    .alignItems(VerticalAlign.Center)
  }

  // mobile_campus_reading_fragment_detail_introduction.xml：layoutNone 显示（主区 gone 固定态）
  @Builder
  introPage() {
    Scroll() {
      Column() {
        Text('暂无简介')
          .fontSize(15)
          .fontColor($r('app.color.common_color_1'))
          .width('100%')
        Text('阅读的最大理由是想摆脱平庸，早一天就多一份人生的精彩；迟一天就多一天平庸的困扰。')
          .fontSize(14)
          .fontColor($r('app.color.common_color_31'))
          .width('100%')
          .margin({ top: 50 })
        Text('---余秋雨')
          .fontSize(14)
          .fontColor($r('app.color.common_color_31'))
          .width('100%')
          .textAlign(TextAlign.End)
      }
      .width('100%')
      .padding(15)
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .scrollBar(BarState.Off)
    .backgroundColor($r('app.color.white'))
    .align(Alignment.Top)
  }
}
