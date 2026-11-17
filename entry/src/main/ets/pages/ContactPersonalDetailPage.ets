import { TitleBar } from '../components/TitleBar';

interface DetailEntry {
  id: string;
  name: string;
  content: string;
}

/**
 * 联系人详情页 — 1:1 复刻：
 * mobile_campus_contact_activity_personal_detail.xml：bg#F2F2F2 toolbar + ScrollView
 *   头部白卡 padT8：居中头像(blue_circle px_to_sp_60=30fp) 名17fp mt12
 *   操作行 mt25.5(px_to_dip_51) pad10：发短信/打电话/发邮件/私聊 各宽88(px_to_dip_176) #3A92ED 图标上 间距8
 *   layoutContainer 白底 mt12
 * mobile_campus_contact_view_personal_detail_item.xml：padL11.5 padV11(px_to_dip_22) 名/内容 16fp common_color_1 + 分隔线
 * mobile_campus_contact_view_child.xml：底部相关联系人行(图标36 名17fp 号14fp mr23)
 */
@Entry
@Component
struct ContactPersonalDetailPage {
  @State name: string = '张伟';
  @State phone: string = '{{PHONE_wn6xzuct}}';
  @State details: DetailEntry[] = [];
  @State relatedName: string = '王芳';
  @State relatedPhone: string = '{{PHONE_zji4wnxc}}';

  aboutToAppear(): void {
    this.details = [
      { id: 'd1', name: '部门：', content: '教务处' },
      { id: 'd2', name: '职务：', content: '教务科科长' },
      { id: 'd3', name: '办公电话：', content: '{{PHONE_6nrwtlnx}}' },
      { id: 'd4', name: '手机号码：', content: this.phone },
      { id: 'd5', name: '电子邮件：', content: '{{EMAIL_yjsfdqmr}}' },
      { id: 'd6', name: '办公地点：', content: '行政楼205室' }
    ];
  }

  private toast(msg: string): void {
    this.getUIContext().getPromptAction().showToast({ message: msg });
  }

  build() {
    Column() {
      TitleBar({ title: '联系人详情', showBack: true })

      Scroll() {
        Column() {
          // 头部白卡
          Column() {
            Column() {
              Text(this.name.substring(0, 1))
                .fontSize(30)
                .fontColor($r('app.color.ybg_white'))
                .width(60)
                .height(60)
                .textAlign(TextAlign.Center)
                .backgroundColor($r('app.color.blue_default'))
                .borderRadius(30)

              Text(this.name)
                .fontSize(17)
                .fontColor($r('app.color.common_color_1'))
                .margin({ top: 12 })
            }
            .width('100%')
            .alignItems(HorizontalAlign.Center)

            // 操作行 mt px_to_dip_51=25.5 pad px_to_dip_10=5
            Row() {
              this.actionItem('发短信', $r('app.media.mobile_campus_contact_msn_b'), () => {
                this.toast('发短信: ' + this.name);
              })
              this.actionItem('打电话', $r('app.media.mobile_campus_contact_call_b'), () => {
                this.toast('呼叫: ' + this.phone);
              })
              this.actionItem('发邮件', $r('app.media.mobile_campus_contact_email_b'), () => {
                this.toast('发邮件: ' + this.name);
              })
              this.actionItem('私聊', $r('app.media.mobile_campus_contact_im_b'), () => {
                this.toast('私聊: ' + this.name);
              })
            }
            .width('100%')
            .justifyContent(FlexAlign.Center)
            .padding(5)
            .margin({ top: 25.5 })
          }
          .width('100%')
          .padding({ top: 8 })
          .backgroundColor($r('app.color.white'))

          // layoutContainer mt px_to_dip_24=12
          Column() {
            ForEach(this.details, (detail: DetailEntry) => {
              this.detailItemRow(detail)
            }, (detail: DetailEntry) => detail.id)
          }
          .width('100%')
          .margin({ top: 12 })
          .backgroundColor($r('app.color.white'))

          // 相关联系人(contact_view_child)
          Column() {
            Row() {
              Text(this.relatedName.substring(0, 1))
                .fontSize(18.5)
                .fontColor($r('app.color.ybg_white'))
                .width(36)
                .height(36)
                .textAlign(TextAlign.Center)
                .backgroundColor($r('app.color.ybg_blue'))
                .borderRadius(18)

              Column() {
                Text(this.relatedName)
                  .fontSize(17)
                  .fontColor($r('app.color.common_color_1'))
                  .maxLines(1)
                Text(this.relatedPhone)
                  .fontSize(14)
                  .fontColor($r('app.color.ybg_grey'))
                  .margin({ top: 8 })
                  .maxLines(1)
              }
              .alignItems(HorizontalAlign.Start)
              .margin({ left: 12 })
              .layoutWeight(1)

              Row() {
                Image($r('app.media.mobile_campus_contact_call'))
                  .width(18)
                  .height(18)
                  .onClick(() => {
                    this.toast('呼叫: ' + this.relatedPhone);
                  })
                Image($r('app.media.mobile_campus_contact_msn'))
                  .width(18)
                  .height(18)
                  .margin({ left: 15 })
              }
              .margin({ right: 23 })
            }
            .width('100%')
            .padding({ left: 12, top: 8, bottom: 8 })
            .alignItems(VerticalAlign.Center)
            .backgroundColor($r('app.color.white'))

            Divider()
              .color($r('app.color.common_color_5'))
              .strokeWidth(0.5)
              .width('100%')
          }
          .width('100%')
          .margin({ top: 12 })
          .backgroundColor($r('app.color.white'))
        }
        .width('100%')
      }
      .width('100%')
      .layoutWeight(1)
      .scrollBar(BarState.Off)
      .align(Alignment.Top)
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.mobile_campus_bg_color'))
  }

  // 发短信/打电话/发邮件/私聊：宽88 #3A92ED 图标上间距8
  @Builder
  actionItem(label: string, icon: Resource, onTap: () => void) {
    Column() {
      Image(icon)
        .width(28)
        .height(28)
      Text(label)
        .fontSize(14)
        .fontColor('#3A92ED')
        .margin({ top: 8 })
    }
    .width(88)
    .alignItems(HorizontalAlign.Center)
    .onClick(() => {
      onTap();
    })
  }

  // mobile_campus_contact_view_personal_detail_item.xml
  @Builder
  detailItemRow(detail: DetailEntry) {
    Column() {
      Row() {
        Text(detail.name)
          .fontSize(16)
          .fontColor($r('app.color.common_color_1'))
          .maxLines(1)
        Text(detail.content)
          .fontSize(16)
          .fontColor($r('app.color.common_color_1'))
          .layoutWeight(1)
          .textAlign(TextAlign.Start)
          .maxLines(1)
      }
      .width('100%')
      .padding({ top: 11, bottom: 11 })
      .alignItems(VerticalAlign.Center)

      Divider()
        .color($r('app.color.common_color_5'))
        .strokeWidth(0.5)
        .width('100%')
    }
    .width('100%')
    .padding({ left: 11.5 })
    .backgroundColor($r('app.color.white'))
  }
}
