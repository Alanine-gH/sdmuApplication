import { TitleBar } from '../components/TitleBar';

/**
 * 出席情况 — 1:1 复刻（px_to_dip_N = N/2 vp, px_to_sp_N = N/2 fp）：
 * mobile_campus_meeting_activity_staff_situation.xml：bg #F2F2F2 + toolbar + ExpandableListView
 *   group=item_view_staff_situation_group：白底卡 marginTop 12，tvTitle 40vp padding 12 + 细分隔线
 *   child=horizontal：5 列网格，项 = 圆形头像 36vp（文字 18.5fp 白）+ tvName 13fp #333 marginBottom 15，
 *     padding 11，imgLayout paddingTop 12 paddingBottom 8
 *   child=vertical：白底 paddingLeft 22，头像 36vp + marginLeft 12 + tvName 17fp #333 / tvSub 14fp
 *     mobile_campus_meeting(灰) marginTop 4 + 1vp 细分隔线
 */

interface StaffPerson {
  name: string;
  sub: string;
  color: string;
}

interface StaffSituationGroup {
  groupId: string;
  title: string;
  mode: string;
  persons: StaffPerson[];
}

function buildStaffSample(): StaffSituationGroup[] {
  const attended: StaffPerson[] = [
    { name: '王建国', sub: '签到 09:02', color: '#1B68B7' },
    { name: '李梅', sub: '签到 09:03', color: '#97000C' },
    { name: '张伟', sub: '签到 09:05', color: '#52C41A' }
  ];
  const unattended: StaffPerson[] = [
    { name: '刘洋', sub: '未签到', color: '#FAAD14' },
    { name: '陈静', sub: '未签到', color: '#E96161' }
  ];
  const gridPersons: StaffPerson[] = [
    { name: '王建国', sub: '', color: '#1B68B7' },
    { name: '李梅', sub: '', color: '#97000C' },
    { name: '张伟', sub: '', color: '#52C41A' },
    { name: '刘洋', sub: '', color: '#FAAD14' },
    { name: '陈静', sub: '', color: '#E96161' },
    { name: '赵强', sub: '', color: '#18B4ED' }
  ];
  const g1: StaffSituationGroup = { groupId: 'sg0', title: '参会人员（6人）', mode: 'horizontal', persons: gridPersons };
  const g2: StaffSituationGroup = { groupId: 'sg1', title: '已签到（3人）', mode: 'vertical', persons: attended };
  const g3: StaffSituationGroup = { groupId: 'sg2', title: '未签到（2人）', mode: 'vertical', persons: unattended };
  return [g1, g2, g3];
}

@Component
struct StaffGridPerson {
  person: StaffPerson = { name: '', sub: '', color: '' };

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
        .margin({ top: 8, bottom: 15 })
    }
    .padding({ left: 11, right: 11, top: 12 })
    .alignItems(HorizontalAlign.Center)
  }
}

@Component
struct StaffVerticalPerson {
  person: StaffPerson = { name: '', sub: '', color: '' };

  build() {
    Column() {
      Row() {
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

      Column() {
        Text(this.person.name)
          .fontSize(17)
          .fontColor($r('app.color.common_color_1'))
          .maxLines(1)
          .width('100%')
        Text(this.person.sub)
          .fontSize(14)
          .fontColor($r('app.color.common_color_3'))
          .width('100%')
          .margin({ top: 4 })
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
      .margin({ left: 12 })
    }
    .width('100%')
    .backgroundColor($r('app.color.white'))
    .padding({ left: 22 })
    .alignItems(VerticalAlign.Center)

      Divider()
        .color($r('app.color.common_color_5'))
        .strokeWidth(0.5)
        .width('100%')
    }
  }
}

@Entry
@Component
struct MeetingStaffSituationPage {
  @State groups: StaffSituationGroup[] = buildStaffSample();

  build() {
    Column() {
      TitleBar({ title: '出席情况', showBack: true })

      Scroll() {
        Column() {
          ForEach(this.groups, (group: StaffSituationGroup) => {
            Column() {
              Text(group.title)
                .fontSize(14)
                .fontColor($r('app.color.common_color_1'))
                .height(40)
                .width('100%')
                .padding({ left: 12, right: 12 })
                .maxLines(1)
                .backgroundColor($r('app.color.white'))

              Divider()
                .color($r('app.color.common_color_5'))
                .strokeWidth(0.5)
                .width('100%')

              if (group.mode === 'horizontal') {
                Grid() {
                  ForEach(group.persons, (person: StaffPerson) => {
                    GridItem() {
                      StaffGridPerson({ person: person })
                    }
                  }, (person: StaffPerson) => group.groupId + '_' + person.name)
                }
                .width('100%')
                .columnsTemplate('1fr 1fr 1fr 1fr 1fr')
                .backgroundColor($r('app.color.white'))
              } else {
                ForEach(group.persons, (person: StaffPerson) => {
                  StaffVerticalPerson({ person: person })
                }, (person: StaffPerson) => group.groupId + '_' + person.name)
              }
            }
            .width('100%')
            .margin({ top: 12 })
            .backgroundColor($r('app.color.white'))
          }, (group: StaffSituationGroup) => group.groupId)
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
