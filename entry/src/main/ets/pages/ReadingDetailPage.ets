import { router } from '@kit.ArkUI';
import { TitleBar } from '../components/TitleBar';
import { ReadingBook } from './ReadingPage';

/** 详情页内置示例书籍数据（与服务不可达时的首页数据保持一致，可按 router id 命中） */
function buildDetailBooks(): ReadingBook[] {
  const books: ReadingBook[] = [
    new ReadingBook('B1', '高等数学（第七版）上册', '同济大学数学系', '高等教育出版社', '图书馆三层自然科学借阅室', '212904000123',
      '2026-10-12', '2026-11-12', '还剩8天', false, 'O13/38', '9787040396614', '在馆', '458', 'CNY49.00',
      '本书是同济大学数学系编《高等数学》第七版上册，内容包括函数与极限、导数与微分、微分中值定理与导数的应用、不定积分、定积分及其应用、微分方程等。'),
    new ReadingBook('B2', '数据结构（C语言版）', '严蔚敏', '清华大学出版社', '图书馆三层自然科学借阅室', '212904000456',
      '2026-10-20', '2026-11-20', '还剩15天', true, 'TP311/22', '9787302147510', '可借', '344', 'CNY35.00',
      '本书系统地介绍了数据结构的基本概念和基本算法，包括线性表、栈、队列、串、数组、广义表、树和二叉树、图、查找、排序等。'),
    new ReadingBook('B3', '计算机网络（第8版）', '谢希仁', '电子工业出版社', '图书馆三层自然科学借阅室', '212904000789',
      '2026-09-28', '2026-10-28', '还剩3天', false, 'TP393/15', '9787121422547', '在馆', '412', 'CNY79.00',
      '本书全面介绍了计算机网络的基本概念、原理和技术，包括物理层、数据链路层、网络层、运输层、应用层以及网络安全等内容。'),
    new ReadingBook('B4', '平凡的世界（全三册）', '路遥', '北京十月文艺出版社', '图书馆二层文学借阅室', '212904001012',
      '2026-08-05', '2026-11-05', '逾期5天', false, 'I247.5/88', '9787530216781', '可借', '1632', 'CNY108.00',
      '《平凡的世界》是一部全景式地表现中国当代城乡社会生活的长篇小说，作者在近十年间广阔背景上，通过复杂的矛盾纠葛，刻画了社会各阶层众多普通人的形象。'),
    new ReadingBook('B5', '活着', '余华', '作家出版社', '图书馆二层文学借阅室', '212904001345',
      '2026-10-01', '2026-10-31', '还剩10天', true, 'I247.5/102', '9787506365437', '在馆', '191', 'CNY28.00',
      '《活着》讲述了农村人福贵悲惨的人生遭遇，展现了一个普通人在时代洪流中与命运抗争的故事。'),
    new ReadingBook('B6', '围城', '钱锺书', '人民文学出版社', '图书馆二层文学借阅室', '212904001678',
      '2026-09-15', '2026-10-15', '还剩1天', false, 'I246.5/12', '9787020127894', '可借', '359', 'CNY36.00',
      '《围城》是钱锺书所著的长篇小说，故事主要写抗战初期知识分子的群相，被誉为“新儒林外史”。'),
    new ReadingBook('B7', '百年孤独', '加西亚·马尔克斯', '南海出版公司', '图书馆二层文学借阅室', '212904001901',
      '2026-07-20', '2026-10-20', '还剩0天', false, 'I775.4/3', '9787544253994', '在馆', '360', 'CNY39.50',
      '《百年孤独》是魔幻现实主义文学的代表作，描写了布恩迪亚家族七代人的传奇故事。')
  ];
  return books;
}

/**
   * 书籍详情页 — 按反编译布局 1:1 复刻 mobile_campus_reading_activity_detail.xml：
 *   LinearLayout vertical（fill_parent）
 *   - include toolbar_normal（标题“书籍详情”）
 *   - StickyNavLayout
 *     - topview：FrameLayout 380.0dip=380vp → MobileCampusReadingDetailTopView
 *       （mobile_campus_reading_view_detail_top.xml：layoutSpace 77.5vp + 白底 225vp + 居中封面图）
 *     - indicator：FrameLayout #F2F2F2 + TabLayout 44vp（marginTop 8.0dip、tabGravity=center、
 *       tabIndicatorHeight=0、选中色 mobile_campus_primary_color_default）
 *     - viewpager：简介（mobile_campus_reading_fragment_detail_introduction.xml）/
 *       书籍信息（mobile_campus_reading_fragment_detail_find.xml）
 */
@Entry
@Component
struct ReadingDetailPage {
  @State currentTab: number = 0;
  @State currentBook: ReadingBook = buildDetailBooks()[0];

  aboutToAppear(): void {
    const params: object = router.getParams();
    if (params) {
      const record: Record<string, Object> = params as Record<string, Object>;
      const bookId: Object = record['id'];
      if (typeof bookId === 'string') {
        const books: ReadingBook[] = buildDetailBooks();
        const found: ReadingBook | undefined = books.find((b: ReadingBook): boolean => b.id === bookId);
        if (found) {
          this.currentBook = found;
        }
      }
    }
  }

  /**
   * mobile_campus_reading_view_detail_top.xml — 详情顶部视图。
   * FrameLayout 380.0dip=380vp：layoutSpace 155.0dip=155vp + 白底 LinearLayout（px_to_dip_450=225vp）。
   * tvTitle：px_to_sp_36=18fp、marginTop=px_to_dip_190=95vp、居中。
   * tvAuthor/tvDate：px_to_sp_26=13fp、marginTop=px_to_dip_24=12vp / px_to_dip_14=7vp。
   * 封面 img：px_to_dip_252 x px_to_dip_333=126x166.5vp、marginTop=75.0dip=75vp、水平居中。
   */
  @Builder
  detailTopView() {
    Stack({ alignContent: Alignment.TopStart }) {
      Column() {
        // layoutSpace：155.0dip=155vp
        Row()
          .width('100%')
          .height(155)
        // 白底信息块：height=px_to_dip_450=225vp、bg=@color/white
        Column() {
          // tvTitle：px_to_sp_36=18fp、common_color_1、marginTop=px_to_dip_190=95vp、layout_gravity=center
          Text(this.currentBook.title)
            .fontSize(18) // px_to_sp_36/2=18fp
            .fontColor($r('app.color.common_color_1'))
            .margin({ top: 95 }) // px_to_dip_190/2=95vp
          // tvAuthor：px_to_sp_26=13fp、marginTop=px_to_dip_24=12vp
          Text(this.currentBook.author)
            .fontSize(13) // px_to_sp_26/2=13fp
            .fontColor($r('app.color.common_color_1'))
            .margin({ top: 12 }) // px_to_dip_24/2=12vp
          // tvDate：px_to_sp_26=13fp、marginTop=px_to_dip_14=7vp
          Text(`借阅日期：${this.currentBook.borrowDate}`)
            .fontSize(13)
            .fontColor($r('app.color.common_color_1'))
            .margin({ top: 7 }) // px_to_dip_14/2=7vp
        }
        .alignItems(HorizontalAlign.Center)
        .width('100%')
        .height(225) // px_to_dip_450/2=225vp
        .backgroundColor($r('app.color.white'))
      }
      .width('100%')
      .height(380)
      // 封面 img：126x166.5vp、marginTop=75.0dip=75vp、layout_gravity=center|top
      Row() {
        Image($r('app.media.mobile_campus_reading_book_default'))
          .width(126) // px_to_dip_252/2=126vp
          .height(166.5) // px_to_dip_333/2=166.5vp
          .objectFit(ImageFit.Contain)
      }
      .width('100%')
      .justifyContent(FlexAlign.Center)
      .margin({ top: 75 }) // 75.0dip=75vp
    }
    .width('100%')
    .height(380) // 380.0dip=380vp
  }

  /**
   * indicator TabLayout — height=px_to_dip_88=44vp、marginTop=8.0dip=8vp、
   * tabGravity=center、tabIndicatorHeight=0.0dip、tabSelectedTextColor=mobile_campus_primary_color_default。
   */
  @Builder
  detailTabItem(name: string, index: number) {
    Text(name)
      .fontSize(15)
      .fontColor(this.currentTab === index ? $r('app.color.mobile_campus_primary_color_default') : $r('app.color.common_color_3'))
      .padding({ left: 16, right: 16 })
      .height('100%')
      .textAlign(TextAlign.Center)
      .onClick(() => {
        this.currentTab = index;
      })
  }

  /**
   * mobile_campus_reading_fragment_detail_introduction.xml — 简介页。
   * ScrollView padding=px_to_dip_30=15vp；Text(“简介”) px_to_dip_30=15fp、common_color_1；tvIntro marginTop=px_to_dip_30=15vp。
   */
  @Builder
  introductionFragment() {
    Scroll() {
      Column() {
        Text('简介')
          .fontSize(15) // px_to_dip_30/2=15fp
          .fontColor($r('app.color.common_color_1'))
        Text(this.currentBook.intro)
          .fontSize(14) // px_to_sp_28/2=14fp
          .fontColor($r('app.color.common_color_2'))
          .lineHeight(24)
          .margin({ top: 15 }) // px_to_dip_30/2=15vp
      }
      .alignItems(HorizontalAlign.Start)
      .width('100%')
      .padding(15) // px_to_dip_30/2=15vp
    }
    .width('100%')
    .height('100%')
    .scrollBar(BarState.Off)
    .align(Alignment.TopStart)
  }

  /**
   * mobile_campus_reading_fragment_detail_find.xml — 书籍信息页。
   * ScrollView → LinearLayout vertical padding=15.0dip=15vp，逐行：label(px_to_sp_28=14fp) + value。
   */
  @Builder
  findRow(label: string, content: string) {
    Row() {
      Text(label)
        .fontSize(14) // px_to_sp_28/2=14fp
        .fontColor($r('app.color.common_color_1'))
      Text(content)
        .fontSize(13) // px_to_sp_26/2=13fp
        .fontColor($r('app.color.common_color_1'))
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .layoutWeight(1)
    }
    .alignItems(VerticalAlign.Center)
    .width('100%')
    .margin({ top: 15 }) // px_to_dip_30/2=15vp
  }

  @Builder
  findFragment() {
    Scroll() {
      Column() {
        // 出版社：tvPress
        this.findRow('出版社：', this.currentBook.publishing)
        // 索书号：tvIndex
        this.findRow('索书号：', this.currentBook.index)
        // 馆藏地：tvLocation
        this.findRow('馆藏地：', this.currentBook.location)
        // ISBN：tvIsbn
        this.findRow('ISBN：', this.currentBook.isbn)
        // 条形码：tvBarCode
        this.findRow('条形码：', this.currentBook.barCode)
        // 在馆状态：tvIsBorrow
        this.findRow('在馆状态：', this.currentBook.isBorrow)
        // 页面：tvPageNum
        this.findRow('页面：', this.currentBook.pageNum)
        // 价格信息：tvPrice
        this.findRow('价格信息：', this.currentBook.price)
      }
      .alignItems(HorizontalAlign.Start)
      .width('100%')
      .padding(15) // 15.0dip=15vp
    }
    .width('100%')
    .height('100%')
    .scrollBar(BarState.Off)
    .align(Alignment.TopStart)
  }

  build() {
    // mobile_campus_reading_activity_detail.xml 根 LinearLayout vertical（fill_parent）
    Column() {
      // include toolbar_normal
      TitleBar({ title: '书籍详情', showBack: true })
      // id_stickynavlayout_topview：FrameLayout 380.0dip=380vp
      this.detailTopView()
      // id_stickynavlayout_indicator：FrameLayout #F2F2F2 + TabLayout（marginTop=8.0dip、height=44vp）
      Column() {
        Row() {
          this.detailTabItem('简介', 0)
          this.detailTabItem('书籍信息', 1)
        }
        .justifyContent(FlexAlign.Center)
        .width('100%')
        .height(44) // px_to_dip_88/2=44vp
        .backgroundColor($r('app.color.ybg_white'))
      }
      .width('100%')
      .backgroundColor($r('app.color.common_color_6'))
      .margin({ top: 8 }) // 8.0dip=8vp
      // id_stickynavlayout_viewpager：ViewPager 白底
      if (this.currentTab === 0) {
        this.introductionFragment()
      } else {
        this.findFragment()
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.white'))
  }
}
