import { TitleBar } from '../components/TitleBar';

/**
 * 上网流量报表 — 复刻 student_report_layout_main.xml（netReport WebActivity 壳）
 * WebView 壳按 H5 结构原生复刻：月度概况卡（本月流量 / 已用流量 / 剩余流量）
 * + 近7日流量记录列表（日期 / 流量 / 在线时长）
 */
interface TrafficRow {
  date: string;
  traffic: string;
  onlineHours: string;
}

interface TrafficSummary {
  monthTotal: string;
  usedTraffic: string;
  remainTraffic: string;
}

@Entry
@Component
struct NetTrafficReportPage {
  @State summary: TrafficSummary = new TrafficSummaryData('30GB', '12.6GB', '17.4GB');
  @State trafficRows: TrafficRow[] = [
    new TrafficRowData('2026-11-16', '1.85GB', '6.2小时'),
    new TrafficRowData('2026-11-15', '2.10GB', '7.5小时'),
    new TrafficRowData('2026-11-14', '1.62GB', '5.8小时'),
    new TrafficRowData('2026-11-13', '1.90GB', '6.6小时'),
    new TrafficRowData('2026-11-12', '1.40GB', '4.9小时'),
    new TrafficRowData('2026-11-11', '2.05GB', '7.1小时'),
    new TrafficRowData('2026-11-10', '1.68GB', '5.5小时')
  ] as TrafficRow[];

  build() {
    Column() {
      TitleBar({ title: '上网流量', showBack: true })

      Scroll() {
        Column() {
          // 月度概况卡
          Row() {
            this.summaryCell('本月套餐', this.summary.monthTotal)
            this.summaryCell('已用流量', this.summary.usedTraffic)
            this.summaryCell('剩余流量', this.summary.remainTraffic)
          }
          .width('100%')
          .padding({ top: 20, bottom: 20 })
          .backgroundColor($r('app.color.white'))
          .borderRadius(8)

          // 近7日流量列表头
          Row() {
            Text('日期')
              .fontSize(14)
              .fontColor($r('app.color.common_color_3'))
              .layoutWeight(3)
            Text('使用流量')
              .fontSize(14)
              .fontColor($r('app.color.common_color_3'))
              .layoutWeight(2)
              .textAlign(TextAlign.Center)
            Text('在线时长')
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

          // 流量记录行
          Column() {
            ForEach(this.trafficRows, (row: TrafficRow) => {
              Row() {
                Text(row.date)
                  .fontSize(14)
                  .fontColor($r('app.color.common_color_1'))
                  .layoutWeight(3)
                Text(row.traffic)
                  .fontSize(14)
                  .fontColor($r('app.color.ybg_blue'))
                  .layoutWeight(2)
                  .textAlign(TextAlign.Center)
                Text(row.onlineHours)
                  .fontSize(14)
                  .fontColor($r('app.color.common_color_2'))
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
            }, (row: TrafficRow) => 'traffic' + row.date)
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

class TrafficSummaryData implements TrafficSummary {
  monthTotal: string;
  usedTraffic: string;
  remainTraffic: string;

  constructor(monthTotal: string, usedTraffic: string, remainTraffic: string) {
    this.monthTotal = monthTotal;
    this.usedTraffic = usedTraffic;
    this.remainTraffic = remainTraffic;
  }
}

class TrafficRowData implements TrafficRow {
  date: string;
  traffic: string;
  onlineHours: string;

  constructor(date: string, traffic: string, onlineHours: string) {
    this.date = date;
    this.traffic = traffic;
    this.onlineHours = onlineHours;
  }
}
