import { TitleBar } from '../components/TitleBar';

/**
 * 图书借阅报表 — 复刻 student_report_layout_main.xml（libraryReport WebActivity 壳）
 * WebView 壳按 H5 结构原生复刻：借阅概况卡（累计借阅 / 本年借阅 / 在借册数）
 * + 借阅记录列表（书名 / 借阅日期 / 归还状态）
 */
interface BorrowRow {
  bookName: string;
  borrowDate: string;
  returnDate: string;
  returned: boolean;
}

interface BorrowSummary {
  totalBorrow: string;
  yearBorrow: string;
  currentBorrow: string;
}

@Entry
@Component
struct BookBorrowReportPage {
  @State summary: BorrowSummary = new BorrowSummaryData('36', '9', '2');
  @State borrowRows: BorrowRow[] = [
    new BorrowRowData('算法导论（第三版）', '2026-09-12', '2026-10-08', true),
    new BorrowRowData('深入理解计算机系统', '2026-09-20', '', false),
    new BorrowRowData('活着', '2026-10-05', '2026-10-30', true),
    new BorrowRowData('Java并发编程实战', '2026-10-18', '', false),
    new BorrowRowData('百年孤独', '2026-08-15', '2026-09-10', true),
    new BorrowRowData('三体', '2026-07-02', '2026-07-28', true),
    new BorrowRowData('人类简史', '2026-06-10', '2026-07-01', true)
  ] as BorrowRow[];

  build() {
    Column() {
      TitleBar({ title: '图书借阅', showBack: true })

      Scroll() {
        Column() {
          // 借阅概况卡
          Row() {
            this.summaryCell('累计借阅', this.summary.totalBorrow + '册')
            this.summaryCell('本年借阅', this.summary.yearBorrow + '册')
            this.summaryCell('在借', this.summary.currentBorrow + '册')
          }
          .width('100%')
          .padding({ top: 20, bottom: 20 })
          .backgroundColor($r('app.color.white'))
          .borderRadius(8)

          // 借阅记录列表头
          Row() {
            Text('书名')
              .fontSize(14)
              .fontColor($r('app.color.common_color_3'))
              .layoutWeight(4)
            Text('借阅日期')
              .fontSize(14)
              .fontColor($r('app.color.common_color_3'))
              .layoutWeight(3)
              .textAlign(TextAlign.Center)
            Text('状态')
              .fontSize(14)
              .fontColor($r('app.color.common_color_3'))
              .layoutWeight(2)
              .textAlign(TextAlign.End)
          }
          .width('100%')
          .height(40)
          .padding({ left: 15, right: 15 })
          .backgroundColor($r('app.color.white'))
          .alignItems(VerticalAlign.Center)

          Divider()
            .color($r('app.color.common_color_5'))
            .strokeWidth(0.5)
            .width('100%')

          // 借阅记录行
          Column() {
            ForEach(this.borrowRows, (row: BorrowRow) => {
              Row() {
                Column() {
                  Text(row.bookName)
                    .fontSize(14)
                    .fontColor($r('app.color.common_color_1'))
                    .maxLines(1)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                  Text(row.returned ? '归还于 ' + row.returnDate : '应还 2026-12-18')
                    .fontSize(12)
                    .fontColor($r('app.color.common_color_3'))
                    .margin({ top: 4 })
                }
                .layoutWeight(4)
                .alignItems(HorizontalAlign.Start)

                Text(row.borrowDate)
                  .fontSize(13)
                  .fontColor($r('app.color.common_color_2'))
                  .layoutWeight(3)
                  .textAlign(TextAlign.Center)
                Text(row.returned ? '已归还' : '在借')
                  .fontSize(13)
                  .fontColor(row.returned ? $r('app.color.common_color_3') :
                    $r('app.color.blue_default'))
                  .layoutWeight(2)
                  .textAlign(TextAlign.End)
              }
              .width('100%')
              .padding({ top: 12, bottom: 12 })
              .padding({ left: 15, right: 15 })
              .alignItems(VerticalAlign.Center)

              Divider()
                .color($r('app.color.common_color_5'))
                .strokeWidth(0.5)
                .width('100%')
            }, (row: BorrowRow) => 'borrow' + row.bookName + row.borrowDate)
          }
          .width('100%')
          .backgroundColor($r('app.color.white'))
        }
        .width('100%')
      }
      .width('100%')
      .layoutWeight(1)
      .backgroundColor($r('app.color.common_color_6'))
      .scrollBar(BarState.Off)
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.common_color_6'))
  }

  @Builder
  summaryCell(labelText: string, valueText: string) {
    Column() {
      Text(valueText)
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.mobile_campus_primary_color'))
      Text(labelText)
        .fontSize(12)
        .fontColor($r('app.color.common_color_3'))
        .margin({ top: 6 })
    }
    .layoutWeight(1)
    .alignItems(HorizontalAlign.Center)
  }
}

class BorrowSummaryData implements BorrowSummary {
  totalBorrow: string;
  yearBorrow: string;
  currentBorrow: string;

  constructor(totalBorrow: string, yearBorrow: string, currentBorrow: string) {
    this.totalBorrow = totalBorrow;
    this.yearBorrow = yearBorrow;
    this.currentBorrow = currentBorrow;
  }
}

class BorrowRowData implements BorrowRow {
  bookName: string;
  borrowDate: string;
  returnDate: string;
  returned: boolean;

  constructor(bookName: string, borrowDate: string, returnDate: string, returned: boolean) {
    this.bookName = bookName;
    this.borrowDate = borrowDate;
    this.returnDate = returnDate;
    this.returned = returned;
  }
}
