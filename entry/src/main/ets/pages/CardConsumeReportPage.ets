import { TitleBar } from '../components/TitleBar';

/**
 * 一卡通消费报表 — 复刻 student_report_layout_main.xml（cardReport WebActivity 壳）
 * WebView 壳按 H5 结构原生复刻：月份选择 + 消费概况卡（消费总额 / 充值总额 / 余额）
 * + 消费流水列表（商户 / 金额 / 时间）
 */
interface ConsumeRow {
  date: string;
  merchant: string;
  amount: number;
  type: string;
}

interface ConsumeSummary {
  totalCost: string;
  totalRecharge: string;
  balance: string;
}

@Entry
@Component
struct CardConsumeReportPage {
  @State currentMonth: string = '2026-11';
  @State months: string[] = ['2026-11', '2026-10', '2026-09'];
  @State summary: ConsumeSummary = new ConsumeSummaryData('486.50', '200.00', '312.80');
  @State consumeRows: ConsumeRow[] = [
    new ConsumeRowData('2026-11-16 07:35', '第一食堂', 7.5, '消费'),
    new ConsumeRowData('2026-11-16 12:10', '第二食堂', 13.0, '消费'),
    new ConsumeRowData('2026-11-15 18:22', '风味餐厅', 16.5, '消费'),
    new ConsumeRowData('2026-11-15 07:40', '第一食堂', 6.5, '消费'),
    new ConsumeRowData('2026-11-14 12:05', '教工食堂', 12.0, '消费'),
    new ConsumeRowData('2026-11-14 09:18', '校内超市', 8.6, '消费'),
    new ConsumeRowData('2026-11-13 14:30', '校园浴室', 3.0, '消费'),
    new ConsumeRowData('2026-11-12 10:00', '网上充值', 200.0, '充值')
  ] as ConsumeRow[];

  build() {
    Column() {
      TitleBar({ title: '一卡通消费', showBack: true })

      Scroll() {
        Column() {
          // 月份切换
          Row() {
            ForEach(this.months, (month: string) => {
              Text(month)
                .fontSize(14)
                .fontColor(month === this.currentMonth ?
                  $r('app.color.white') : $r('app.color.common_color_2'))
                .backgroundColor(month === this.currentMonth ?
                  $r('app.color.mobile_campus_primary_color') : $r('app.color.white'))
                .borderRadius(14)
                .padding({ left: 14, right: 14, top: 6, bottom: 6 })
                .onClick(() => {
                  this.currentMonth = month;
                })
            }, (month: string) => 'cardmonth' + month)
          }
          .width('100%')
          .height(44)
          .padding({ left: 15 })
          .alignItems(VerticalAlign.Center)

          // 消费概况卡
          Row() {
            this.summaryCell('消费总额', this.summary.totalCost)
            this.summaryCell('充值总额', this.summary.totalRecharge)
            this.summaryCell('当前余额', this.summary.balance)
          }
          .width('100%')
          .padding({ top: 20, bottom: 20 })
          .backgroundColor($r('app.color.white'))
          .borderRadius(8)

          // 流水列表头
          Row() {
            Text('商户')
              .fontSize(14)
              .fontColor($r('app.color.common_color_3'))
              .layoutWeight(3)
            Text('类型')
              .fontSize(14)
              .fontColor($r('app.color.common_color_3'))
              .layoutWeight(2)
              .textAlign(TextAlign.Center)
            Text('金额')
              .fontSize(14)
              .fontColor($r('app.color.common_color_3'))
              .layoutWeight(2)
              .textAlign(TextAlign.Center)
            Text('时间')
              .fontSize(14)
              .fontColor($r('app.color.common_color_3'))
              .layoutWeight(3)
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

          // 消费流水行
          Column() {
            ForEach(this.consumeRows, (row: ConsumeRow) => {
              Row() {
                Text(row.merchant)
                  .fontSize(14)
                  .fontColor($r('app.color.common_color_1'))
                  .layoutWeight(3)
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
                Text(row.type)
                  .fontSize(13)
                  .fontColor(row.type === '充值' ? $r('app.color.report_rate_green') :
                    $r('app.color.common_color_3'))
                  .layoutWeight(2)
                  .textAlign(TextAlign.Center)
                Text((row.type === '充值' ? '+' : '-') + row.amount.toFixed(2))
                  .fontSize(14)
                  .fontColor(row.type === '充值' ? $r('app.color.report_rate_green') :
                    $r('app.color.common_color_1'))
                  .layoutWeight(2)
                  .textAlign(TextAlign.Center)
                Text(row.date)
                  .fontSize(12)
                  .fontColor($r('app.color.common_color_3'))
                  .layoutWeight(3)
                  .textAlign(TextAlign.End)
              }
              .width('100%')
              .height(48)
              .padding({ left: 15, right: 15 })
              .alignItems(VerticalAlign.Center)

              Divider()
                .color($r('app.color.common_color_5'))
                .strokeWidth(0.5)
                .width('100%')
            }, (row: ConsumeRow) => 'consume' + row.date + row.merchant)
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

class ConsumeSummaryData implements ConsumeSummary {
  totalCost: string;
  totalRecharge: string;
  balance: string;

  constructor(totalCost: string, totalRecharge: string, balance: string) {
    this.totalCost = totalCost;
    this.totalRecharge = totalRecharge;
    this.balance = balance;
  }
}

class ConsumeRowData implements ConsumeRow {
  date: string;
  merchant: string;
  amount: number;
  type: string;

  constructor(date: string, merchant: string, amount: number, type: string) {
    this.date = date;
    this.merchant = merchant;
    this.amount = amount;
    this.type = type;
  }
}
