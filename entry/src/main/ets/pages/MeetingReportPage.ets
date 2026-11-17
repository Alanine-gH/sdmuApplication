import { router } from '@kit.ArkUI';
import { TitleBar } from '../components/TitleBar';

/**
 * 会议报告 — 1:1 复刻（px_to_dip_N = N/2 vp, px_to_sp_N = N/2 fp）：
 * mobile_campus_meeting_activity_report.xml：toolbar + 内容竖排：WebView layoutWeight 1 +
 *   layoutReport 白底 49vp（0.5 分隔线 + tvSituation 16fp 主色 图标 drawablePadding 8 居中）
 */
@Entry
@Component
struct MeetingReportPage {
  @State reportContent: string =
    '会议围绕秋季学期教学安排展开：\n\n' +
    '1. 各学院汇报期中教学检查情况；\n' +
    '2. 研究期末考试排考方案，确定考试时间为第十六周；\n' +
    '3. 部署下学期教学任务落实工作，要求两周内完成排课初稿。\n\n' +
    '会议要求各单位按时间节点推进落实。';

  build() {
    Column() {
      TitleBar({ title: '会议报告', showBack: true })

      // reportWebview 区域（此处以文本内容呈现）
      Scroll() {
        Column() {
          Text(this.reportContent)
            .fontSize(15)
            .lineHeight(24)
            .fontColor($r('app.color.common_color_1'))
            .width('100%')
            .padding(16)
        }
        .width('100%')
      }
      .width('100%')
      .layoutWeight(1)
      .align(Alignment.Top)
      .scrollBar(BarState.Off)
      .backgroundColor($r('app.color.white'))

      // layoutReport：白底 49vp
      Column() {
        Divider()
          .color($r('app.color.common_color_5'))
          .strokeWidth(0.5)
          .width('100%')

        Row() {
          Image($r('app.media.mobile_campus_meeting_edit'))
            .width(16)
            .height(16)
            .margin({ right: 8 })
          Text('编辑会议报告')
            .fontSize(16)
            .fontColor($r('app.color.mobile_campus_primary_color_default'))
        }
        .height(48.5)
        .justifyContent(FlexAlign.Center)
        .width('100%')
        .backgroundColor($r('app.color.white'))
        .onClick(() => {
          router.pushUrl({ url: 'pages/MeetingReportEditPage' });
        })
      }
      .width('100%')
      .height(49)
      .backgroundColor($r('app.color.white'))
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.white'))
  }
}
