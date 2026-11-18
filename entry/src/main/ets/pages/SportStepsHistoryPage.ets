import { router } from '@kit.ArkUI';
import { TitleBar } from '../components/TitleBar';

/**
 * 运动步数历史页 — 源码级翻译（SportStepsHistoryActivity.java 逐行 → ArkTS，[W25 misc-b]）：
 *
 * 【布局】mobile_campus_activity_app_sport_steps_history.xml：MToolBar("历史记录") + SmartRefreshLayout
 *   + RecyclerView padV4
 * 【数据】O2() 源码字面硬编码 7 条 SportStepsHistoryBean(1234步, 5部门排名, 1校排名, 时间戳
 *   1664245510000 → 1664072710000 差 2 天(172800000ms)，此后逐条 -86400000)——APK 开发期占位数据
 *   源码字面，非运行时接口（保真复刻，非编造）；L2() 刷新回调空实现
 * 【行】item_sport_steps_history.xml：BLLinearLayout 圆角8 #F8F8F8 marginH15 marginV6：
 *   tvTime 16fp black pad20（昨日差 1 天 → "昨日"，否则 e0.c yyyy-MM-dd）+ "查看" 16fp #999999 mr13
 *   + icon_arrow_right_gray mr24
 * 【点击】a 类：行点击 → e.a.y0=/app/SportStepsHistoryDetailActivity（HAP SportStepsRankPage 排行榜详情）
 */
class SportStepsHistoryRow {
  step: number;
  departmentRanking: number;
  schoolRanking: number;
  time: number;

  constructor(step: number, departmentRanking: number, schoolRanking: number, time: number) {
    this.step = step;
    this.departmentRanking = departmentRanking;
    this.schoolRanking = schoolRanking;
    this.time = time;
  }
}

@Entry
@Component
struct SportStepsHistoryPage {
  @State list: SportStepsHistoryRow[] = [];

  aboutToAppear(): void {
    // 源码 O2()：字面硬编码 7 条（1664245510000→1664072710000 差 2 天，此后逐条 -86400000）
    this.list = [
      new SportStepsHistoryRow(1234, 5, 1, 1664245510000),
      new SportStepsHistoryRow(1234, 5, 1, 1664072710000),
      new SportStepsHistoryRow(1234, 5, 1, 1663986310000),
      new SportStepsHistoryRow(1234, 5, 1, 1663899910000),
      new SportStepsHistoryRow(1234, 5, 1, 1663813510000),
      new SportStepsHistoryRow(1234, 5, 1, 1663727110000),
      new SportStepsHistoryRow(1234, 5, 1, 1663640710000)
    ];
  }

  /** 源码 d(long)：时间戳与今天差恰好 1 天 → "昨日" */
  private timeTextOf(time: number): string {
    const d = new Date(time);
    const y: number = d.getFullYear();
    const m: number = d.getMonth() + 1;
    const day: number = d.getDate();
    const today = new Date();
    const diffDays: number = Math.floor(
      (new Date(today.getFullYear(), today.getMonth(), today.getDate()).getTime()
        - new Date(y, m - 1, day).getTime()) / 86400000);
    if (diffDays === 1) {
      return '昨日';
    }
    const mm: string = m < 10 ? '0' + m : String(m);
    const dd: string = day < 10 ? '0' + day : String(day);
    return `${y}-${mm}-${dd}`;
  }

  /** 源码 a 类：行点击 → /app/SportStepsHistoryDetailActivity */
  private openDetail(): void {
    router.pushUrl({ url: 'pages/SportStepsRankPage' });
  }

  build() {
    Column() {
      TitleBar({ title: '历史记录', showBack: true })

      List() {
        ForEach(this.list, (row: SportStepsHistoryRow, idx: number) => {
          ListItem() {
            // item_sport_steps_history.xml：圆角8 #F8F8F8 marginH15 marginV6
            Row() {
              Text(this.timeTextOf(row.time))
                .fontSize(16)
                .fontColor($r('app.color.black'))
                .padding({ left: 20, right: 20, top: 18, bottom: 18 })
                .layoutWeight(1)
                .maxLines(1)
              Text('查看')
                .fontSize(16)
                .fontColor('#999999')
                .margin({ right: 13 })
              Image($r('app.media.icon_arrow_right_gray'))
                .width(16)
                .height(16)
                .margin({ right: 24 })
            }
            .width('100%')
            .borderRadius(8)
            .backgroundColor('#F8F8F8')
            .margin({ left: 15, right: 15, top: 6, bottom: 6 })
            .alignItems(VerticalAlign.Center)
            .onClick(() => {
              this.openDetail();
            })
          }
        }, (row: SportStepsHistoryRow, idx: number) => String(row.time) + '_' + idx)
      }
      .width('100%')
      .layoutWeight(1)
      .padding({ top: 4, bottom: 4 })
      .scrollBar(BarState.Off)
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.white'))
  }
}
