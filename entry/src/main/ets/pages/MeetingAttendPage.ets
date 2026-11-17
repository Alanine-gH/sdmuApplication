import { router, promptAction } from '@kit.ArkUI';
import { TitleBar } from '../components/TitleBar';

/**
 * 参会情况 — 1:1 复刻（px_to_dip_N = N/2 vp, px_to_sp_N = N/2 fp）：
 * meeting_activity_attend.xml：toolbar + 内容 RelativeLayout：
 *   ic_attend 图居中 marginTop 79vp；底部 签到 按钮 fill_parent 44vp 白字 17fp
 *   bg item_doc_number_selected（主色圆角）marginLeft/Right 12 marginBottom 37
 * view_attend_choose_btn.xml：不参加/参加 双按钮栏 主色底 48vp，中间 1x30 分隔 #084B8F 上下 margin 8
 */
@Entry
@Component
struct MeetingAttendPage {
  @State attendState: string = 'pending';

  private stateText(): string {
    if (this.attendState === 'attend') {
      return '已报名参加';
    }
    if (this.attendState === 'no') {
      return '已选择不参加';
    }
    return '请确认是否参加该会议';
  }

  build() {
    Column() {
      TitleBar({ title: '参会情况', showBack: true })

      // MultiStateView content
      Stack() {
        Image($r('app.media.mobile_campus_meeting_ic_attend'))
          .width(160)
          .height(160)
          .objectFit(ImageFit.Contain)
          .margin({ top: 79 })

        Text(this.stateText())
          .fontSize(16)
          .fontColor($r('app.color.common_color_3'))
          .margin({ top: 260 })

        Column() {
          Text('签到')
            .fontSize(17)
            .fontColor($r('app.color.white'))
            .textAlign(TextAlign.Center)
            .width('100%')
            .height(44)
            .backgroundColor($r('app.color.mobile_campus_primary_color_default'))
            .borderRadius(6)
            .onClick(() => {
              promptAction.showToast({ message: '请扫描二维码签到' });
              router.pushUrl({ url: 'pages/MeetingSignPage' });
            })
        }
        .width('100%')
        .padding({ left: 12, right: 12, bottom: 37 })
      }
      .width('100%')
      .layoutWeight(1)
      .alignContent(Alignment.Top)
      .backgroundColor($r('app.color.white'))

      // view_attend_choose_btn：不参加 / 参加栏
      Row() {
        Text('不参加')
          .fontSize(16)
          .fontColor($r('app.color.white'))
          .textAlign(TextAlign.Center)
          .layoutWeight(1)
          .height('100%')
          .onClick(() => {
            this.attendState = 'no';
          })

        Divider()
          .color('#084B8F')
          .strokeWidth(1)
          .vertical(true)
          .height(30)
          .margin({ top: 8, bottom: 8 })

        Text('参加')
          .fontSize(16)
          .fontColor($r('app.color.white'))
          .textAlign(TextAlign.Center)
          .layoutWeight(1)
          .height('100%')
          .onClick(() => {
            this.attendState = 'attend';
          })
      }
      .width('100%')
      .height(48)
      .backgroundColor($r('app.color.mobile_campus_primary_color_default'))
      .alignItems(VerticalAlign.Center)
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.white'))
  }
}
