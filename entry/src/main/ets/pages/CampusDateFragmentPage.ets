import { TitleBar } from '../components/TitleBar';

class CampusDateDayInfo {
  dayKey: string;
  weekLabel: string;
  dayNumber: string;
  lunarLabel: string;

  constructor(dayKey: string, weekLabel: string, dayNumber: string, lunarLabel: string) {
    this.dayKey = dayKey;
    this.weekLabel = weekLabel;
    this.dayNumber = dayNumber;
    this.lunarLabel = lunarLabel;
  }
}

/**
 * 日期页 — 1:1 复刻 mobile_campus_fragment_date.xml：
 * LinearLayout horizontal（fill_parent、wrap_content）：
 *   7 个 DateView 子控件，layout_width=0dip + layout_weight=1.0（等分 7 列）
 * DateView（原生日期选择控件）：每列展示星期标签 + 日期数字 + 农历/备注，
 * 选中列以主题色高亮。本页内置 7 天示例数据（2026-11-16 起一周），点击切换选中日。
 */
@Entry
@Component
struct CampusDateFragmentPage {
  @State selectedDayIndex: number = 1;
  @State dayList: CampusDateDayInfo[] = [
    new CampusDateDayInfo('d1', '周一', '16', '初一'),
    new CampusDateDayInfo('d2', '周二', '17', '初二'),
    new CampusDateDayInfo('d3', '周三', '18', '初三'),
    new CampusDateDayInfo('d4', '周四', '19', '初四'),
    new CampusDateDayInfo('d5', '周五', '20', '小雪'),
    new CampusDateDayInfo('d6', '周六', '21', '初六'),
    new CampusDateDayInfo('d7', '周日', '22', '初七')
  ];

  /**
   * DateView — 单日列。日期数字：选中 18fp 粗体主题色，未选中 16fp common_color_1；
   * 星期与农历标签 11fp common_color_3；选中列底部主题色 2vp 指示条。
   */
  @Builder
  dateColumn(dayItem: CampusDateDayInfo, itemIndex: number) {
    Column() {
      Text(dayItem.weekLabel)
        .fontSize(11)
        .fontColor(this.selectedDayIndex === itemIndex
          ? $r('app.color.mobile_campus_primary_color')
          : $r('app.color.common_color_3'))
      Text(dayItem.dayNumber)
        .fontSize(this.selectedDayIndex === itemIndex ? 18 : 16)
        .fontWeight(this.selectedDayIndex === itemIndex ? FontWeight.Bold : FontWeight.Normal)
        .fontColor(this.selectedDayIndex === itemIndex
          ? $r('app.color.mobile_campus_primary_color')
          : $r('app.color.common_color_1'))
        .margin({ top: 4 })
      Text(dayItem.lunarLabel)
        .fontSize(11)
        .fontColor(this.selectedDayIndex === itemIndex
          ? $r('app.color.mobile_campus_primary_color')
          : $r('app.color.common_color_3'))
        .margin({ top: 4 })
      Column()
        .width(16)
        .height(2)
        .backgroundColor(this.selectedDayIndex === itemIndex
          ? $r('app.color.mobile_campus_primary_color')
          : Color.Transparent)
        .margin({ top: 6 })
    }
    .layoutWeight(1)
    .padding({ top: 12, bottom: 12 })
    .alignItems(HorizontalAlign.Center)
    .onClick(() => {
      this.selectedDayIndex = itemIndex;
    })
  }

  build() {
    // 根 LinearLayout vertical：承载日期横条
    Column() {
      TitleBar({ title: '日期选择', showBack: true })
      // mobile_campus_fragment_date.xml — 7 列等分日期条（fill_parent）
      Column() {
        Row() {
          ForEach(this.dayList, (dayItem: CampusDateDayInfo, itemIndex: number) => {
            this.dateColumn(dayItem, itemIndex)
          }, (dayItem: CampusDateDayInfo) => dayItem.dayKey)
        }
        .width('100%')
        .alignItems(VerticalAlign.Top)
        // 选中日信息条：展示当前选中日期说明（示例）
        Text('2026年11月 ' + this.dayList[this.selectedDayIndex].dayNumber + '日 ' +
          this.dayList[this.selectedDayIndex].weekLabel + ' · ' +
          this.dayList[this.selectedDayIndex].lunarLabel)
          .fontSize(13)
          .fontColor($r('app.color.common_color_3'))
          .margin({ top: 16 })
          .width('100%')
          .textAlign(TextAlign.Center)
      }
      .width('100%')
      .padding({ top: 8 })
      .backgroundColor($r('app.color.white'))
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.white'))
  }
}
