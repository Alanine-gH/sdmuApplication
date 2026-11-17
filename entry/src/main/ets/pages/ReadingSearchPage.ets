import { router } from '@kit.ArkUI';
import { TitleBar } from '../components/TitleBar';
import { ReadingBook } from './ReadingPage';

/** 搜索页内置示例书籍数据 */
function buildSearchBooks(): ReadingBook[] {
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
 * 读书搜索页 — 按源布局 1:1 复刻 mobile_campus_reading_activity_search.xml：
 *   LinearLayout vertical（fill_parent）
 *   - include toolbar_normal（标题“搜索书籍”）
 *   - ClearableEditText：bg=@drawable/mobile_campus_shape_base_sesarch_bg、height=32.0dip=32vp、
 *     margin=14.0dip（marginRight=4.0dip）、paddingLeft/Right=12.0dip、hint=“搜索书籍”（#B5B5B5）、
 *     drawableLeft=@mipmap/mobile_campus_reading_search、drawablePadding=9.0dip、textSize=px_to_sp_28=14fp
 *   - MultiStateView（content）→ 刷新列表（mobile_campus_reading_item_search.xml 条目）
 */
@Entry
@Component
struct ReadingSearchPage {
  @State searchKey: string = '';
  @State resultList: ReadingBook[] = buildSearchBooks();

  /** 按书名/作者过滤本地示例数据 */
  doSearch(key: string): void {
    const books: ReadingBook[] = buildSearchBooks();
    if (key.length === 0) {
      this.resultList = books;
      return;
    }
    this.resultList = books.filter((b: ReadingBook): boolean => b.title.includes(key) || b.author.includes(key));
  }

  /**
   * mobile_campus_reading_item_search.xml — 搜索结果条目。
   * RelativeLayout padding=px_to_dip_15=7.5vp：img(80x109vp) + 信息列 + imgFavourite(heart_red、marginRight=14.0dip)。
   */
  @Builder
  searchItem(item: ReadingBook) {
    Row() {
      // img：px_to_dip_160 x px_to_dip_218=80x109vp、centerVertical
      Image($r('app.media.mobile_campus_reading_book_default'))
        .width(80) // px_to_dip_160/2=80vp
        .height(109) // px_to_dip_218/2=109vp
        .objectFit(ImageFit.Contain)
      // 中部信息 LinearLayout vertical：marginLeft=px_to_dip_16=8vp、centerVertical
      Column() {
        // tvTitle：px_to_sp_34=17fp、singleLine
        Text(item.title)
          .fontSize(17) // px_to_sp_34/2=17fp
          .fontColor($r('app.color.common_color_1'))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        // tvAuthor：px_to_sp_24=12fp、marginTop=px_to_dip_24=12vp
        Text(item.author)
          .fontSize(12) // px_to_sp_24/2=12fp
          .fontColor($r('app.color.common_color_1'))
          .margin({ top: 12 }) // px_to_dip_24/2=12vp
        // tvPublishing：px_to_sp_24=12fp、marginTop=px_to_dip_6=3vp
        Text(item.publishing)
          .fontSize(12)
          .fontColor($r('app.color.common_color_1'))
          .margin({ top: 3 }) // px_to_dip_6/2=3vp
        // tvLocation：12fp、marginTop=3vp
        Text(item.location)
          .fontSize(12)
          .fontColor($r('app.color.common_color_1'))
          .margin({ top: 3 })
        // tvID：12fp、marginTop=3vp
        Text(item.barCode)
          .fontSize(12)
          .fontColor($r('app.color.common_color_1'))
          .margin({ top: 3 })
      }
      .alignItems(HorizontalAlign.Start)
      .margin({ left: 8 }) // px_to_dip_16/2=8vp
      .layoutWeight(1)
      // imgFavourite：src=mobile_campus_reading_icon_heart_red、marginRight=14.0dip=14vp、centerVertical
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

  build() {
    // mobile_campus_reading_activity_search.xml 根 LinearLayout vertical（fill_parent）
    Column() {
      // include toolbar_normal
      TitleBar({ title: '搜索书籍', showBack: true })
      // ClearableEditText：height=32.0dip=16vp、margin=14.0dip（right=4.0dip）、bg=搜索底色、paddingLeft/Right=12.0dip
      Row() {
        Image($r('app.media.mobile_campus_reading_search'))
          .width(16)
          .height(16)
          .objectFit(ImageFit.Contain)
        TextInput({ placeholder: '搜索书籍', text: this.searchKey })
          .fontSize(14) // px_to_sp_28/2=14fp
          .fontColor($r('app.color.common_color_1'))
          .placeholderColor('#B5B5B5')
          .placeholderFont({ size: 14 })
          .backgroundColor(Color.Transparent)
          .padding({ left: 9, right: 9 }) // drawablePadding=9.0dip=9vp
          .layoutWeight(1)
          .height(32) // 32.0dip=32vp
          .onChange((value: string) => {
            this.searchKey = value;
            this.doSearch(value);
          })
          .onSubmit((enterKey: EnterKeyType) => {
            this.doSearch(this.searchKey);
          })
      }
      .alignItems(VerticalAlign.Center)
      .width('100%')
      .height(32) // 32.0dip=32vp
      .padding({ left: 12, right: 12 }) // 12.0dip=12vp
      .borderRadius(8)
      .backgroundColor($r('app.color.common_color_6'))
      .margin({ left: 14, top: 14, bottom: 14, right: 4 }) // 14.0dip（marginRight=4.0dip）
      // MultiStateView（content）→ common_refresh_layout_wrap_lv 列表
      if (this.resultList.length === 0) {
        Column() {
          Text('暂无搜索结果')
            .fontSize(14)
            .fontColor($r('app.color.common_color_3'))
            .margin({ top: 60 })
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Start)
        .alignItems(HorizontalAlign.Center)
      } else {
        List() {
          ForEach(this.resultList, (item: ReadingBook) => {
            ListItem() {
              this.searchItem(item)
            }
          }, (item: ReadingBook) => item.id)
        }
        .width('100%')
        .layoutWeight(1)
        .backgroundColor($r('app.color.white'))
        .scrollBar(BarState.Off)
        .divider({ strokeWidth: 0.5, color: $r('app.color.common_color_5'), startMargin: 7.5, endMargin: 7.5 })
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.white'))
  }
}
