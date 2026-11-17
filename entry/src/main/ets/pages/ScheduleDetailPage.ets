import { TitleBar } from '../components/TitleBar';

/**
 * 日程详情页 — 1:1 复刻 mobile_campus_schedule_activity_schedule_detail.xml
 *   + view_add_schedule_input.xml + view_add_schedule_select.xml + view_schedule_detail.xml
 * 结构：RelativeLayout(#F2F2F2) + toolbar_normal("日程详情") + ScrollView(MultiStateView content)
 *   1. 标题行(白底)：tag "重要" 14fp(px_to_sp_28) mobile_campus_schedule_color1
 *      边框1vp(px_to_dip_2) padding 3/2vp marginL 12vp(itemtag_bgorange) + 标题 17fp(px_to_sp_34) 粗体
 *      paddingH 12vp minHeight 48vp(px_to_dip_96)
 *   2. AddScheduleInputView：日程标题/地点/时间 只读展示
 *   3. selectNotifyView：日程提醒 + systemSchedule：来源；selectImportanceView visibility=gone 跳过
 *   4. tvSubmit："删除日程" 16fp(px_to_sp_32) mobile_campus_main_item_bg_orange 白底 高48vp
 *      marginTop 32vp(px_to_dip_64) marginBottom 27vp(px_to_dip_54)
 *
 * 数据源：无服务器接口 — ApiService 未提供日程详情端点，页面为内置示例数据（ScheduleOADetailActivity 同布局复用）。
 */
class DetailRow {
  label: string;
  value: string;

  constructor(label: string, value: string) {
    this.label = label;
    this.value = value;
  }
}

@Entry
@Component
struct ScheduleDetailPage {
  @State title: string = '期中学风建设主题班会';
  @State important: boolean = true;
  private location: string = '第一教学楼 301';
  private startTime: string = '2026-11-18 08:30';
  private endTime: string = '2026-11-18 10:10';
  private detail: string = '请各班委提前10分钟到场，准备签到表与主题材料，会后收集同学意见反馈。';
  private notify: string = '15分钟前';
  private source: string = '手动创建';
  private rows: DetailRow[] = [
    new DetailRow('日程地点', ''),
    new DetailRow('日程时间', '')
  ];

  build() {
    Column() {
      TitleBar({ title: '日程详情', showBack: true })

      Scroll() {
        Column() {
          // 标题行：白底 tag + 标题
          Row() {
            if (this.important) {
              Text('重要')
                .fontSize(14)
                .fontColor($r('app.color.mobile_campus_schedule_color1'))
                .border({ width: 1, color: $r('app.color.mobile_campus_schedule_color1') })
                .padding({ left: 3, right: 3, top: 2, bottom: 2 })
                .margin({ left: 12 })
            }
            Text(this.title)
              .fontSize(17)
              .fontWeight(FontWeight.Bold)
              .fontColor($r('app.color.common_color_1'))
              .padding({ left: 12, right: 12 })
              .constraintSize({ minHeight: 48 })
              .layoutWeight(1)
          }
          .width('100%')
          .alignItems(VerticalAlign.Center)
          .backgroundColor($r('app.color.white'))

          // AddScheduleInputView 只读：白底 paddingL 12vp
          Column() {
            Row() {
              Text('日程标题')
                .fontSize(16)
                .fontColor($r('app.color.common_color_1'))
              Text(this.title)
                .fontSize(16)
                .fontColor($r('app.color.common_color_1'))
                .layoutWeight(1)
                .margin({ left: 24 })
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
            }
            .width('100%')
            .height(48)
            .alignItems(VerticalAlign.Center)

            Divider()
              .color($r('app.color.common_color_5'))
              .strokeWidth(0.5)

            Row() {
              Text('日程地点')
                .fontSize(16)
                .fontColor($r('app.color.common_color_1'))
              Text(this.location)
                .fontSize(16)
                .fontColor($r('app.color.common_color_1'))
                .layoutWeight(1)
                .margin({ left: 24 })
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
            }
            .width('100%')
            .height(48)
            .alignItems(VerticalAlign.Center)

            Divider()
              .color($r('app.color.common_color_5'))
              .strokeWidth(0.5)

            Row() {
              Text('日程时间')
                .fontSize(16)
                .fontColor($r('app.color.common_color_1'))
                .margin({ top: 12 })
              Column() {
                Row() {
                  Text(this.startTime + ' - ' + this.endTime)
                    .fontSize(16)
                    .fontColor($r('app.color.common_color_1'))
                    .layoutWeight(1)
                }
                .width('100%')
                .height(48)
                .alignItems(VerticalAlign.Center)
              }
              .width('100%')
              .layoutWeight(1)
              .margin({ left: 24 })
            }
            .width('100%')
            .alignItems(VerticalAlign.Top)
          }
          .width('100%')
          .padding({ left: 12, bottom: 12 })
          .backgroundColor($r('app.color.white'))

          // ScheduleDetailView：白底 marginTop 12vp "日程详情" + 内容
          Column() {
            Row() {
              Text('日程详情')
                .fontSize(16)
                .fontColor($r('app.color.common_color_1'))
              Text(this.detail)
                .fontSize(16)
                .fontColor($r('app.color.common_color_1'))
                .layoutWeight(1)
                .margin({ left: 24, right: 12 })
            }
            .width('100%')
            .alignItems(VerticalAlign.Top)
          }
          .width('100%')
          .padding({ left: 12, top: 12 })
          .backgroundColor($r('app.color.white'))
          .margin({ top: 12 })

          // selectNotifyView：日程提醒
          Column() {
            Row() {
              Text('日程提醒')
                .fontSize(16)
                .fontColor($r('app.color.common_color_1'))
                .margin({ top: 6 })
              Text(this.notify)
                .fontSize(16)
                .fontColor($r('app.color.common_color_1'))
                .layoutWeight(1)
                .margin({ left: 12 })
            }
            .width('100%')
            .alignItems(VerticalAlign.Top)
          }
          .width('100%')
          .padding({ left: 12, right: 12, bottom: 12 })
          .backgroundColor($r('app.color.white'))
          .margin({ top: 12 })

          // systemSchedule：日程来源
          Column() {
            Row() {
              Text('日程来源')
                .fontSize(16)
                .fontColor($r('app.color.common_color_1'))
                .margin({ top: 6 })
              Text(this.source)
                .fontSize(16)
                .fontColor($r('app.color.common_color_1'))
                .layoutWeight(1)
                .margin({ left: 12 })
            }
            .width('100%')
            .alignItems(VerticalAlign.Top)
          }
          .width('100%')
          .padding({ left: 12, right: 12, bottom: 12 })
          .backgroundColor($r('app.color.white'))
          .margin({ top: 12 })

          // tvSubmit："删除日程" 白底高48vp marginTop 32vp marginBottom 27vp
          Text('删除日程')
            .fontSize(16)
            .fontColor($r('app.color.mobile_campus_main_item_bg_orange'))
            .textAlign(TextAlign.Center)
            .width('100%')
            .height(48)
            .backgroundColor($r('app.color.white'))
            .margin({ top: 32, bottom: 27 })
            .onClick(() => {
              this.getUIContext().getPromptAction().showToast({ message: '日程已删除' });
            })
        }
        .width('100%')
      }
      .width('100%')
      .layoutWeight(1)
      .scrollBar(BarState.Off)
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.mobile_campus_bg_color'))
  }
}
