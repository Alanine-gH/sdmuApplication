import { TitleBar } from '../components/TitleBar';

/**
 * 绑定邮箱页 — 1:1 复刻 mobile_campus_my_item_personalinfo_bindemial_item.xml
 * 结构：顶部 1vp 分隔线(marginLeft 15, common_color_6)
 *   + 行(ybg_white, padding 15px_to_dip_30=15vp)：
 *     "绑定邮箱" 16fp(px_to_sp_32/2) #333333 宽120
 *     邮箱值 16fp mobile_campus_primary_color 靠右
 *     右箭头 px_to_dip_24=12vp marginStart px_to_dip_24=12vp
 */
@Entry
@Component
struct BindEmailPage {
  @State email: string = ''; // 零容忍：不展示编造邮箱，真实绑定值由会话/服务端下发;

  private goBind(): void {
    this.getUIContext().getPromptAction().showToast({ message: '前往绑定邮箱' });
  }

  build() {
    Column() {
      TitleBar({ title: '绑定邮箱', showBack: true })

      Column() {
        // 顶部 1vp 分隔线
        Divider()
          .color($r('app.color.common_color_6'))
          .strokeWidth(1)
          .width('100%')
          .margin({ left: 15 })

        // 绑定邮箱行
        Row() {
          Text('绑定邮箱')
            .fontSize(16)
            .fontColor('#333333')
            .width(120)
          Text(this.email)
            .fontSize(16)
            .fontColor($r('app.color.mobile_campus_primary_color'))
            .textAlign(TextAlign.End)
            .layoutWeight(1)
          Image($r('app.media.arrow_right'))
            .width(12)
            .height(12)
            .margin({ left: 12 })
        }
        .width('100%')
        .padding(15)
        .alignItems(VerticalAlign.Center)
        .backgroundColor($r('app.color.ybg_white'))
        .onClick(() => {
          this.goBind();
        })
      }
      .width('100%')
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.common_color_6'))
  }
}
