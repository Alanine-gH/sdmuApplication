import { TitleBar } from '../components/TitleBar';

/**
 * 早餐个人报表 — 复刻 student_report_layout_main.xml（breakfastReport/PersonalActivity）
 * WebView 壳按 H5 结构原生复刻：月度概况卡（打卡次数 / 连续天数 / 本月打卡率）
 * + 早餐打卡记录列表（日期 / 打卡食堂 / 打卡时间）
 */
interface BreakfastRecord {
  date: string;
  canteen: string;
  time: string;
  checked: boolean;
}

interface BreakfastSummary {
  checkCount: string;
  continueDays: string;
  monthRate: string;
}

@Entry
@Component
struct BreakfastPersonalPage {
  @State summary: BreakfastSummary = new BreakfastSummaryData('18', '6天', '82%');
  @State records: BreakfastRecord[] = [
    new BreakfastRecordData('2026-11-16', '第一食堂', '07:32', true),
    new BreakfastRecordData('2026-11-15', '第二食堂', '07:15', true),
    new BreakfastRecordData('2026-11-14', '第一食堂', '07:48', true),
    new BreakfastRecordData('2026-11-13', '风味餐厅', '07:20', true),
    new BreakfastRecordData('2026-11-12', '未打卡', '--', false),
    new BreakfastRecordData('2026-11-11', '第一食堂', '07:39', true),
    new BreakfastRecordData('2026-11-10', '第二食堂', '07:26', true),
    new BreakfastRecordData('2026-11-09', '第一食堂', '07:51', true)
  ] as BreakfastRecord[];

  build() {
    Column() {
      TitleBar({ title: '早餐打卡', showBack: true })

      Scroll() {
        Column() {
          // 概况卡
          Row() {
            this.summaryCell('本月打卡', this.summary.checkCount + '次')
            this.summaryCell('连续打卡', this.summary.continueDays)
            this.summaryCell('打卡率', this.summary.monthRate)
          }
          .width('100%')
          .padding({ top: 20, bottom: 20 })
          .backgroundColor($r('app.color.white'))
          .borderRadius(8)

          // 打卡记录列表头
          Row() {
            Text('日期')
              .fontSize(14)
              .fontColor($r('app.color.common_color_3'))
              .layoutWeight(3)
            Text('食堂')
              .fontSize(14)
              .fontColor($r('app.color.common_color_3'))
              .layoutWeight(3)
            Text('打卡时间')
              .fontSize(14)
              .fontColor($r('app.color.common_color_3'))
              .layoutWeight(2)
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

          // 打卡记录行
          Column() {
            ForEach(this.records, (record: BreakfastRecord) => {
              Row() {
                Text(record.date)
                  .fontSize(14)
                  .fontColor($r('app.color.common_color_1'))
                  .layoutWeight(3)
                Text(record.canteen)
                  .fontSize(14)
                  .fontColor($r('app.color.common_color_2'))
                  .layoutWeight(3)
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
                Text(record.time)
                  .fontSize(14)
                  .fontColor($r('app.color.common_color_2'))
                  .layoutWeight(2)
                  .textAlign(TextAlign.Center)
                Text(record.checked ? '已打卡' : '缺卡')
                  .fontSize(13)
                  .fontColor(record.checked ? $r('app.color.mobile_campus_todo_tag_green') :
                    $r('app.color.mobile_campus_schedule_color7'))
                  .layoutWeight(2)
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
            }, (record: BreakfastRecord) => 'breakfast' + record.date)
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

class BreakfastSummaryData implements BreakfastSummary {
  checkCount: string;
  continueDays: string;
  monthRate: string;

  constructor(checkCount: string, continueDays: string, monthRate: string) {
    this.checkCount = checkCount;
    this.continueDays = continueDays;
    this.monthRate = monthRate;
  }
}

class BreakfastRecordData implements BreakfastRecord {
  date: string;
  canteen: string;
  time: string;
  checked: boolean;

  constructor(date: string, canteen: string, time: string, checked: boolean) {
    this.date = date;
    this.canteen = canteen;
    this.time = time;
    this.checked = checked;
  }
}
