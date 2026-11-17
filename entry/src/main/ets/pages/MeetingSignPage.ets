import { TitleBar } from '../components/TitleBar';

/**
 * 会议签到 — 1:1 复刻（px_to_dip_N = N/2 vp, px_to_sp_N = N/2 fp）：
 * mobile_campus_meeting_activity_sign.xml：bg #F2F2F2 + toolbar + ScrollView：
 *   白底卡（居中竖排）：imgQRCode 200x200 marginTop 23 fitXY + "扫描二维码签到" marginTop/Bottom 14
 * mobile_campus_meeting_view_sign_grid.xml：白底卡 marginTop 12：tvTitle 40vp padding 12 + 细分隔线
 *   + GridViewInScrollView 5 列 padding 12（项 = 圆形头像 36vp + 名字 13fp）
 */

interface SignPerson {
  name: string;
  color: string;
}

interface SignGroup {
  groupId: string;
  title: string;
  persons: SignPerson[];
}

function buildSignSample(): SignGroup[] {
  const signed: SignPerson[] = [
    { name: '王建国', color: '#1B68B7' },
    { name: '李梅', color: '#97000C' },
    { name: '张伟', color: '#52C41A' },
    { name: '刘洋', color: '#FAAD14' },
    { name: '陈静', color: '#E96161' },
    { name: '赵强', color: '#18B4ED' }
  ];
  const unsigned: SignPerson[] = [
    { name: '孙丽', color: '#747474' },
    { name: '周杰', color: '#FF8900' },
    { name: '吴敏', color: '#67B438' },
    { name: '郑凯', color: '#295998' }
  ];
  const g1: SignGroup = { groupId: 'sign0', title: '已签到（6人）', persons: signed };
  const g2: SignGroup = { groupId: 'sign1', title: '未签到（4人）', persons: unsigned };
  return [g1, g2];
}

@Component
struct SignGridPerson {
  person: SignPerson = { name: '', color: '' };

  build() {
    Column() {
      Column() {
        Text(this.person.name.substring(0, 1))
          .fontSize(18)
          .fontColor($r('app.color.ybg_white'))
          .textAlign(TextAlign.Center)
      }
      .width(36)
      .height(36)
      .borderRadius(18)
      .backgroundColor(this.person.color)
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)

      Text(this.person.name)
        .fontSize(13)
        .fontColor($r('app.color.common_color_1'))
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .margin({ top: 8, bottom: 12 })
    }
    .alignItems(HorizontalAlign.Center)
    .width('100%')
  }
}

@Component
struct SignGridView {
  title: string = '';
  persons: SignPerson[] = [];

  build() {
    Column() {
      Text(this.title)
        .fontSize(14)
        .fontColor($r('app.color.common_color_1'))
        .height(40)
        .width('100%')
        .padding({ left: 12, right: 12 })
        .maxLines(1)

      Divider()
        .color($r('app.color.common_color_5'))
        .strokeWidth(0.5)
        .width('100%')

      Grid() {
        ForEach(this.persons, (person: SignPerson) => {
          GridItem() {
            SignGridPerson({ person: person })
          }
        }, (person: SignPerson) => this.title + '_' + person.name)
      }
      .width('100%')
      .columnsTemplate('1fr 1fr 1fr 1fr 1fr')
      .padding({ left: 12, right: 12, top: 12 })
    }
    .width('100%')
    .backgroundColor($r('app.color.white'))
  }
}

@Entry
@Component
struct MeetingSignPage {
  @State signGroups: SignGroup[] = buildSignSample();

  build() {
    Column() {
      TitleBar({ title: '会议签到', showBack: true })

      Scroll() {
        Column() {
          // 二维码卡
          Column() {
            Image($r('app.media.mobile_campus_meeting_qrcode'))
              .width(200)
              .height(200)
              .objectFit(ImageFit.Fill)
              .margin({ top: 23 })

            Text('扫描二维码签到')
              .fontSize(14)
              .fontColor($r('app.color.common_color_1'))
              .margin({ top: 14, bottom: 14 })
          }
          .width('100%')
          .backgroundColor($r('app.color.white'))
          .alignItems(HorizontalAlign.Center)

          ForEach(this.signGroups, (group: SignGroup) => {
            SignGridView({ title: group.title, persons: group.persons })
              .margin({ top: 12 })
          }, (group: SignGroup) => group.groupId)
        }
        .width('100%')
        .padding({ bottom: 24 })
      }
      .width('100%')
      .layoutWeight(1)
      .align(Alignment.Top)
      .scrollBar(BarState.Off)
      .backgroundColor($r('app.color.mobile_campus_bg_color'))
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.mobile_campus_bg_color'))
  }
}
