import { router } from '@kit.ArkUI';
import { TitleBar } from '../components/TitleBar';

interface YellowContact {
  id: string;
  name: string;
  phone: string;
  address: string;
  email: string;
}

/**
 * 黄页列表页 — 1:1 复刻：
 * contact_view_yellow_child.xml：白底 padL12 minHeight50 图标36vp
 *   名16fp粗体black(mt4 mb8) 电话14fp(图标间距2) 地址14fp(图标间距2 pr5) 邮箱14fp(图标间距4)
 *   右侧呼叫图标 mr23 + 0.5分隔线
 * yellow_group.xml：分组标题 17fp 高48 padH12 arrow_right + 1分隔线
 */
@Entry
@Component
struct ContactYellowListPage {
  @State groupName: string = '行政机构';
  @State entries: YellowContact[] = [];

  aboutToAppear(): void {
    const params: Record<string, string> = router.getParams() as Record<string, string>;
    if (params !== undefined && params !== null && params.title !== undefined && params.title !== null) {
      this.groupName = params.title;
    }
    this.entries = [
      { id: 'l1', name: '学校办公室', phone: '{{PHONE_2bdnepea}}', address: '行政楼301室', email: '{{EMAIL_pz4jvwss}}' },
      { id: 'l2', name: '教务处', phone: '{{PHONE_6dpe2fxo}}', address: '行政楼205室', email: '{{EMAIL_lbsiro4w}}' },
      { id: 'l3', name: '学生工作处', phone: '{{PHONE_tocouayf}}', address: '行政楼308室', email: '{{EMAIL_iq2stlwe}}' },
      { id: 'l4', name: '人事处', phone: '{{PHONE_frnrgpjb}}', address: '行政楼402室', email: '{{EMAIL_wmzttbvi}}' },
      { id: 'l5', name: '财务处', phone: '{{PHONE_s37ulv4m}}', address: '行政楼106室', email: '{{EMAIL_dgrzzyy5}}' }
    ];
  }

  private toast(msg: string): void {
    this.getUIContext().getPromptAction().showToast({ message: msg });
  }

  build() {
    Column() {
      TitleBar({ title: this.groupName, showBack: true })

      List() {
        // yellow_group.xml：分组标题
        ListItem() {
          Column() {
            Row() {
              Text(this.groupName)
                .fontSize(17)
                .fontColor($r('app.color.common_color_1'))
                .width('100%')
                .height(48)
                .padding({ left: 12, right: 12 })
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
              Image($r('app.media.arrow_right'))
                .width(16)
                .height(16)
                .margin({ right: 12 })
            }
            .width('100%')
            .alignItems(VerticalAlign.Center)
            .backgroundColor($r('app.color.white'))

            Divider()
              .color($r('app.color.common_color_5'))
              .strokeWidth(1)
              .width('100%')
          }
          .width('100%')
        }

        ForEach(this.entries, (entry: YellowContact) => {
          ListItem() {
            this.yellowChildRow(entry)
          }
        }, (entry: YellowContact) => entry.id)
      }
      .width('100%')
      .layoutWeight(1)
      .scrollBar(BarState.Off)
      .backgroundColor($r('app.color.white'))
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.white'))
  }

  // contact_view_yellow_child.xml
  @Builder
  yellowChildRow(entry: YellowContact) {
    Column() {
      Row() {
        Text(entry.name.substring(0, 1))
          .fontSize(18.5)
          .fontColor($r('app.color.ybg_white'))
          .width(36)
          .height(36)
          .textAlign(TextAlign.Center)
          .backgroundColor($r('app.color.blue_default'))
          .borderRadius(18)

        Column() {
          Text(entry.name)
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor($r('app.color.black'))
            .margin({ top: 4, bottom: 8 })
            .maxLines(1)

          Row() {
            Image($r('app.media.icon_yellow_page_phone'))
              .width(12)
              .height(12)
              .margin({ right: 2 })
            Text(entry.phone)
              .fontSize(14)
              .fontColor($r('app.color.mobile_campus_contact'))
              .maxLines(1)
          }
          .margin({ bottom: 4 })

          Row() {
            Image($r('app.media.icon_yellow_page_address'))
              .width(12)
              .height(12)
              .margin({ right: 2 })
            Text(entry.address)
              .fontSize(14)
              .fontColor($r('app.color.mobile_campus_contact'))
              .padding({ right: 5 })
              .maxLines(1)
          }
          .margin({ bottom: 4 })

          Row() {
            Image($r('app.media.icon_yellow_page_email'))
              .width(12)
              .height(12)
              .margin({ right: 4 })
            Text(entry.email)
              .fontSize(14)
              .fontColor($r('app.color.mobile_campus_contact'))
              .maxLines(1)
          }
          .margin({ bottom: 4 })
        }
        .alignItems(HorizontalAlign.Start)
        .margin({ left: 12 })
        .layoutWeight(1)

        Image($r('app.media.mobile_campus_contact_call'))
          .width(18)
          .height(18)
          .margin({ right: 23 })
          .onClick(() => {
            this.toast('呼叫: ' + entry.phone);
          })
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
    .backgroundColor($r('app.color.white'))
  }
}
