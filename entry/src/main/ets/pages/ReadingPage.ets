import { router } from '@kit.ArkUI';
import { TitleBar } from '../components/TitleBar';

/**
 * 读书条目模型 — 服务不可达时使用内置示例数据。
 * item_home / item_history / item_search / 详情页共用。
 */
export class ReadingBook {
  id: string;
  title: string;
  author: string;
  publishing: string;
  location: string;
  barCode: string;
  borrowDate: string;
  returnDate: string;
  daysLeft: string;
  favourite: boolean;
  index: string;
  isbn: string;
  isBorrow: string;
  pageNum: string;
  price: string;
  intro: string;

  constructor(id: string, title: string, author: string, publishing: string, location: string,
    barCode: string, borrowDate: string, returnDate: string, daysLeft: string, favourite: boolean,
    index: string, isbn: string, isBorrow: string, pageNum: string, price: string, intro: string) {
    this.id = id;
    this.title = title;
    this.author = author;
    this.publishing = publishing;
    this.location = location;
    this.barCode = barCode;
    this.borrowDate = borrowDate;
    this.returnDate = returnDate;
    this.daysLeft = daysLeft;
    this.favourite = favourite;
    this.index = index;
    this.isbn = isbn;
    this.isBorrow = isBorrow;
    this.pageNum = pageNum;
    this.price = price;
    this.intro = intro;
  }
}

/** 服务不可达时的内置示例书籍数据 */
function buildReadingBooks(): ReadingBook[] {
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
 * 读书首页 — 按反编译布局 1:1 复刻 mobile_campus_reading_activity.xml：
 *   LinearLayout vertical（fill_parent）
 *   - include toolbar_normal（标题“读书”）
 *   - MultiStateView（content 状态）
 *     - StickyNavLayout
 *       - topview：FrameLayout 白底 → MobileCampusReadingTopView（mobile_campus_reading_view_top.xml）
 *       - indicator：TabLayout 44vp（tab_item：图标 + 文字，选中色 mobile_campus_primary_color_default）
 *       - viewpager：mobile_campus_reading_fragment.xml（PullToRefreshLayout + common_single_lv_sub 列表）
 *     - imgSearch：MobileCampusDragFloatActionButton（bottom|center|right，src=mobile_campus_reading_btn_library）
 */
@Entry
@Component
struct ReadingPage {
  @State currentTab: number = 0;
  @State bookList: ReadingBook[] = buildReadingBooks();

  /**
   * mobile_campus_reading_view_top.xml — 顶部借书卡视图。
   * RelativeLayout background=@mipmap/mobile_campus_reading_bg_card、height=px_to_dip_298=149vp。
   */
  @Builder
  readingTopView() {
    Stack({ alignContent: Alignment.TopStart }) {
      Image($r('app.media.mobile_campus_reading_bg_card'))
        .width('100%')
        .height(149) // px_to_dip_298/2=149vp
        .objectFit(ImageFit.Fill)
      // “借书卡”：textSize=px_to_sp_100=50fp、textColor=#0effffff、marginLeft=px_to_dip_52=26vp、marginTop=px_to_dip_36=18vp
      Text('借书卡')
        .fontSize(50) // px_to_sp_100/2=50fp
        .fontColor('#0EFFFFFF')
        .margin({ left: 26, top: 18 }) // px_to_dip_52/2=26vp、px_to_dip_36/2=18vp
      // layoutLeft：marginLeft=26.0dip、marginBottom=15.0dip、alignParentLeft+alignParentBottom、gravity=center
      Row() {
        // “卡状态”：textSize=px_to_dip_24=12fp、textColor=@color/white
        Text('卡状态')
          .fontSize(12) // px_to_dip_24/2=12fp
          .fontColor($r('app.color.white'))
        // tvState：textSize=12fp、textColor=#ff38a2f3、background=@drawable/shape_white（白底0.5dip #CECECE描边2vp圆角）、marginLeft=8.0dip
        Text('正常')
          .fontSize(12)
          .fontColor('#38A2F3')
          .backgroundColor($r('app.color.white'))
          .borderRadius(2) // px_to_dip_4/2=2vp
          .border({ width: 0.5, color: $r('app.color.common_color_4') })
          .padding({ left: 4, right: 4, top: 2, bottom: 2 })
          .margin({ left: 8 }) // 8.0dip=8vp
      }
      .alignItems(VerticalAlign.Center)
      .margin({ left: 26, bottom: 15 }) // 26.0dip=26vp、15.0dip=15vp
      .align(Alignment.BottomStart)
      // layoutMid：centerInParent、gravity=center vertical、marginLeft=-16.0dip
      Column() {
        // tvNum：textSize=px_to_dip_72=36fp、textColor=@color/white
        Text('3')
          .fontSize(36) // px_to_dip_72/2=36fp
          .fontColor($r('app.color.white'))
        // “已借（本）”：textSize=px_to_dip_30=15fp、textColor=@color/white
        Text('已借（本）')
          .fontSize(15) // px_to_dip_30/2=15fp
          .fontColor($r('app.color.white'))
      }
      .alignItems(HorizontalAlign.Center)
      .justifyContent(FlexAlign.Center)
      .align(Alignment.Center)
      // layoutRight：marginRight=26.0dip、marginBottom=15.0dip、alignParentRight+alignParentBottom
      Text('2026-11-16')
        .fontSize(12) // px_to_dip_24/2=12fp
        .fontColor($r('app.color.white'))
        .margin({ right: 26, bottom: 15 }) // 26.0dip=26vp、15.0dip=15vp
        .align(Alignment.BottomEnd)
    }
    .width('100%')
    .height(149)
    .clip(true)
  }

  /**
   * mobile_campus_reading_item_home.xml — 首页在借书籍条目。
   * RelativeLayout background=@color/ybg_white、paddingLeft/Right=px_to_dip_15=7.5vp、height=px_to_dip_266=133vp。
   */
  @Builder
  bookHomeItem(item: ReadingBook) {
    Row() {
      // img：80x109vp（px_to_dip_160=80、px_to_dip_218=109）、src=mobile_campus_reading_book_default、centerVertical
      Image($r('app.media.mobile_campus_reading_book_default'))
        .width(80) // px_to_dip_160/2=80vp
        .height(109) // px_to_dip_218/2=109vp
        .objectFit(ImageFit.Contain)
      // 中部信息 LinearLayout vertical：marginLeft=px_to_dip_16=8vp、centerVertical
      Column() {
        // tvTitle：textSize=px_to_sp_34=17fp、textColor=@color/common_color_1、maxLines=1
        Text(item.title)
          .fontSize(17) // px_to_sp_34/2=17fp
          .fontColor($r('app.color.common_color_1'))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        // tvAuthor：textSize=px_to_sp_24=12fp、marginTop=px_to_dip_24=12vp
        Text(item.author)
          .fontSize(12) // px_to_sp_24/2=12fp
          .fontColor($r('app.color.common_color_1'))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .margin({ top: 12 }) // px_to_dip_24/2=12vp
        // tvPublishing：textSize=12fp、marginTop=px_to_dip_12=6vp
        Text(item.publishing)
          .fontSize(12)
          .fontColor($r('app.color.common_color_1'))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .margin({ top: 6 }) // px_to_dip_12/2=6vp
      }
      .alignItems(HorizontalAlign.Start)
      .margin({ left: 8 }) // px_to_dip_16/2=8vp
      .layoutWeight(1)
      // layoutRight：alignParentRight、centerVertical、gravity=center vertical
      Column() {
        // tvRenew：续借按钮（visibility=gone）：textColor=#ff38a2f3、background=@drawable/mobile_campus_reading_shape（0.5dip #38A2F3 描边4vp圆角）
        Text('续借')
          .fontSize(12) // px_to_sp_24/2=12fp
          .fontColor('#38A2F3')
          .borderRadius(4)
          .border({ width: 0.5, color: '#38A2F3' })
          .padding({ left: 10, right: 10, top: 4, bottom: 4 })
          .visibility(Visibility.None)
        // tvDate：textSize=px_to_sp_24=12fp、width=px_to_dip_128=64vp、height=px_to_dip_48=24vp、marginTop=px_to_dip_24=12vp
        Text(item.daysLeft)
          .fontSize(12)
          .fontColor($r('app.color.common_color_1'))
          .width(64) // px_to_dip_128/2=64vp
          .height(24) // px_to_dip_48/2=24vp
          .textAlign(TextAlign.Center)
          .margin({ top: 12 }) // px_to_dip_24/2=12vp
      }
      .alignItems(HorizontalAlign.Center)
      .justifyContent(FlexAlign.Center)
    }
    .alignItems(VerticalAlign.Center)
    .padding({ left: 7.5, right: 7.5 }) // px_to_dip_15/2=7.5vp
    .height(133) // px_to_dip_266/2=133vp
    .width('100%')
    .backgroundColor($r('app.color.ybg_white'))
    .onClick(() => {
      router.pushUrl({ url: 'pages/ReadingDetailPage', params: { id: item.id } });
    })
  }

  /**
   * mobile_campus_reading_item_search.xml — 寻书（收藏）条目。
   * RelativeLayout padding=px_to_dip_15=7.5vp、height=wrap_content。
   * 与首页条目差异：无右侧日期，右侧为 imgFavourite（mobile_campus_reading_icon_heart_red、marginRight=14.0dip）。
   */
  @Builder
  bookSearchItem(item: ReadingBook) {
    Row() {
      // img：80x109vp
      Image($r('app.media.mobile_campus_reading_book_default'))
        .width(80) // px_to_dip_160/2=80vp
        .height(109) // px_to_dip_218/2=109vp
        .objectFit(ImageFit.Contain)
      // 中部信息：marginLeft=px_to_dip_16=8vp、centerVertical
      Column() {
        // tvTitle：textSize=px_to_sp_34=17fp、singleLine
        Text(item.title)
          .fontSize(17)
          .fontColor($r('app.color.common_color_1'))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        // tvAuthor：textSize=px_to_sp_24=12fp、marginTop=px_to_dip_24=12vp
        Text(item.author)
          .fontSize(12)
          .fontColor($r('app.color.common_color_1'))
          .margin({ top: 12 }) // px_to_dip_24/2=12vp
        // tvPublishing：textSize=12fp、marginTop=px_to_dip_6=3vp
        Text(item.publishing)
          .fontSize(12)
          .fontColor($r('app.color.common_color_1'))
          .margin({ top: 3 }) // px_to_dip_6/2=3vp
        // tvLocation：textSize=12fp、marginTop=3vp
        Text(item.location)
          .fontSize(12)
          .fontColor($r('app.color.common_color_1'))
          .margin({ top: 3 })
        // tvID：textSize=12fp、marginTop=3vp
        Text(item.barCode)
          .fontSize(12)
          .fontColor($r('app.color.common_color_1'))
          .margin({ top: 3 })
      }
      .alignItems(HorizontalAlign.Start)
      .margin({ left: 8 }) // px_to_dip_16/2=8vp
      .layoutWeight(1)
      // imgFavourite：src=@mipmap/mobile_campus_reading_icon_heart_red、marginRight=14.0dip、centerVertical
      Image($r('app.media.mobile_campus_reading_icon_heart_red'))
        .width(22)
        .height(22)
        .margin({ right: 14 }) // 14.0dip=14vp
        .objectFit(ImageFit.Contain)
    }
    .alignItems(VerticalAlign.Center)
    .padding(7.5) // px_to_dip_15/2=7.5vp
    .width('100%')
    .backgroundColor($r('app.color.ybg_white'))
    .onClick(() => {
      router.pushUrl({ url: 'pages/ReadingDetailPage', params: { id: item.id } });
    })
  }

  /**
   * mobile_campus_reading_tab_item.xml — Tab 条目。
   * LinearLayout horizontal gravity=center：ImageView + tvName（textSize=px_to_dip_30=15fp、
   * textColor=@color/mobile_campus_reading_selector_tab：选中 #1B68B7 / 未选中 #999999、marginLeft=px_to_dip_18=9vp）。
   */
  @Builder
  readingTabItem(name: string, iconSel: Resource, iconDef: Resource, index: number) {
    Row() {
      Image(this.currentTab === index ? iconSel : iconDef)
        .width(22)
        .height(22)
        .objectFit(ImageFit.Contain)
      Text(name)
        .fontSize(15) // px_to_dip_30/2=15fp
        .fontColor(this.currentTab === index ? $r('app.color.mobile_campus_primary_color_default') : $r('app.color.common_color_3'))
        .margin({ left: 9 }) // px_to_dip_18/2=9vp
    }
    .alignItems(VerticalAlign.Center)
    .justifyContent(FlexAlign.Center)
    .height('100%')
    .padding({ left: 16, right: 16 })
    .onClick(() => {
      this.currentTab = index;
    })
  }

  build() {
    // mobile_campus_reading_activity.xml 根 LinearLayout vertical（fill_parent）
    Stack({ alignContent: Alignment.BottomEnd }) {
      Column() {
        // include toolbar_normal
        TitleBar({ title: '读书', showBack: true })
        // id_stickynavlayout_topview：FrameLayout 白底
        this.readingTopView()
        // id_stickynavlayout_indicator：TabLayout height=px_to_dip_88=44vp、tabGravity=center
        Row() {
          this.readingTabItem('首页', $r('app.media.mobile_campus_reading_icon_book_selected'),
            $r('app.media.mobile_campus_reading_icon_book_default'), 0)
          this.readingTabItem('寻书', $r('app.media.mobile_campus_reading_icon_xunshu_selected'),
            $r('app.media.mobile_campus_reading_icon_xunshu_default'), 1)
        }
        .width('100%')
        .height(44) // px_to_dip_88/2=44vp
        .justifyContent(FlexAlign.Center)
        .backgroundColor($r('app.color.white'))
        // id_stickynavlayout_viewpager：PullToRefreshLayout 白底 + common_single_lv_sub 列表
        List() {
          if (this.currentTab === 0) {
            ForEach(this.bookList, (item: ReadingBook) => {
              ListItem() {
                this.bookHomeItem(item)
              }
            }, (item: ReadingBook) => item.id)
          } else {
            ForEach(this.bookList, (item: ReadingBook) => {
              ListItem() {
                if (item.favourite) {
                  this.bookSearchItem(item)
                } else {
                  this.bookSearchItem(item)
                }
              }
            }, (item: ReadingBook) => item.id)
          }
        }
        .width('100%')
        .layoutWeight(1)
        .backgroundColor($r('app.color.white'))
        .scrollBar(BarState.Off)
        .divider({ strokeWidth: 0.5, color: $r('app.color.common_color_5'), startMargin: 7.5, endMargin: 7.5 })
      }
      .width('100%')
      .height('100%')
      // imgSearch：MobileCampusDragFloatActionButton、layout_gravity=bottom|center|right、src=mobile_campus_reading_btn_library
      Image($r('app.media.mobile_campus_reading_btn_library'))
        .width(56)
        .height(56)
        .objectFit(ImageFit.Contain)
        .margin({ right: 16, bottom: 24 })
        .onClick(() => {
          router.pushUrl({ url: 'pages/ReadingSearchPage' });
        })
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.white'))
  }
}
