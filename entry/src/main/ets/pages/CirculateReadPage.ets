import { router } from '@kit.ArkUI';
import { TitleBar } from '../components/TitleBar';

/**
 * OA传阅已读页 — 1:1 复刻（px_to_dip_N = N/2 vp, px_to_sp_N = N/2 fp）：
 * mobile_campus_oa_activity_circulate_read.xml：toolbar_normal（TitleBar 复用）+ 12vp 灰分隔
 *   + ScrollView 正文（CopyViewLayout：传阅正文示例）+ 右下角"传阅"按钮 113×44 白字
 *     enabled #1B68B7 / disabled #B2BDC9（mobile_campus_schedule_color12）
 */
@Entry
@Component
struct CirculateReadPage {
  @State circulateTitle: string = '关于召开2026年秋季学期教学工作会议的通知';
  @State bodyParagraphs: string[] = [
    '各二级学院、各部门：',
    '经学校研究决定，定于2026年11月25日（星期三）下午14:30在行政楼第一会议室召开2026年秋季学期教学工作会议。会议将通报本学期教学运行情况，部署期末考试、教材征订及下学期开课计划等工作。',
    '请各单位主要负责人提前安排好工作，准时参会。因故不能参会者，须提前向教务处履行请假手续。',
    '特此通知。'
  ];
  @State canCirculate: boolean = true;

  build() {
    Column() {
      TitleBar({ title: '传阅' })

      Divider()
        .color($r('app.color.common_color_5'))
        .strokeWidth(12)
        .width('100%')

      Stack({ alignContent: Alignment.BottomEnd }) {
        Scroll() {
          Column() {
            Text(this.circulateTitle)
              .fontSize(18.5)
              .fontWeight(FontWeight.Bold)
              .fontColor($r('app.color.common_color_1'))
              .width('100%')
              .margin({ bottom: 16 })

            ForEach(this.bodyParagraphs, (item: string, index: number) => {
              Text(item)
                .fontSize(16)
                .fontColor($r('app.color.common_color_1'))
                .lineHeight(28)
                .width('100%')
                .copyOption(CopyOptions.InApp)
                .margin({ bottom: index === this.bodyParagraphs.length - 1 ? 0 : 12 })
            }, (item: string, index: number) => index.toString() + '_' + item)

            Row() {
              Text('发文单位：院长办公室')
                .fontSize(15)
                .fontColor($r('app.color.common_color_3'))
              Blank()
              Text('2026-11-17 09:24')
                .fontSize(15)
                .fontColor($r('app.color.common_color_3'))
            }
            .width('100%')
            .margin({ top: 24 })
          }
          .width('100%')
          .padding(12)
        }
        .width('100%')
        .height('100%')
        .scrollBar(BarState.Off)

        Text('传阅')
          .fontSize(17)
          .fontColor($r('app.color.white'))
          .textAlign(TextAlign.Center)
          .width(113)
          .height(44)
          .backgroundColor(this.canCirculate
            ? $r('app.color.mobile_campus_primary_color_default')
            : $r('app.color.mobile_campus_schedule_color12'))
          .onClick(() => {
            if (this.canCirculate) {
              this.canCirculate = false;
              router.back();
            }
          })
          .margin({ right: 12, bottom: 12 })
      }
      .width('100%')
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.white'))
  }
}
