import { TitleBar } from '../components/TitleBar';

/**
 * 人员详情 — 1:1 复刻（px_to_dip_N = N/2 vp, px_to_sp_N = N/2 fp）：
 * mobile_campus_meeting_activity_person_detail.xml：toolbar + ExpandableListView（分组可展开列表）
 *   分组头 = 白底 40vp 标题 + 展开箭头；子项 = vertical 人员行（头像 36vp + 名字 17fp + 副标题 14fp 灰）
 */

interface PersonDetailItem {
  name: string;
  sub: string;
  color: string;
}

interface PersonDetailGroup {
  groupId: string;
  title: string;
  expanded: boolean;
  persons: PersonDetailItem[];
}

function buildPersonDetailSample(): PersonDetailGroup[] {
  const teachers: PersonDetailItem[] = [
    { name: '王建国', sub: '会议主持人', color: '#1B68B7' },
    { name: '李梅', sub: '参会人员', color: '#97000C' },
    { name: '张伟', sub: '参会人员', color: '#52C41A' }
  ];
  const students: PersonDetailItem[] = [
    { name: '刘洋', sub: '必须参加', color: '#FAAD14' },
    { name: '陈静', sub: '参会人员', color: '#E96161' }
  ];
  const g1: PersonDetailGroup = { groupId: 'pg0', title: '教职工（3人）', expanded: true, persons: teachers };
  const g2: PersonDetailGroup = { groupId: 'pg1', title: '学生（2人）', expanded: false, persons: students };
  return [g1, g2];
}

@Component
struct PersonDetailRow {
  person: PersonDetailItem = { name: '', sub: '', color: '' };

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
      .padding({ left: 22, top: 10, bottom: 10 })
      .alignItems(VerticalAlign.Center)

      Divider()
        .color($r('app.color.common_color_5'))
        .strokeWidth(0.5)
        .width('100%')
    }
    .width('100%')
  }
}

@Entry
@Component
struct MeetingPersonDetailPage {
  @State groups: PersonDetailGroup[] = buildPersonDetailSample();

  private toggleGroup(groupId: string): void {
    const updated: PersonDetailGroup[] = [];
    for (const g of this.groups) {
      if (g.groupId === groupId) {
        const toggled: PersonDetailGroup = {
          groupId: g.groupId, title: g.title, expanded: !g.expanded, persons: g.persons
        };
        updated.push(toggled);
      } else {
        updated.push(g);
      }
    }
    this.groups = updated;
  }

  build() {
    Column() {
      TitleBar({ title: '人员详情', showBack: true })

      Scroll() {
        Column() {
          ForEach(this.groups, (group: PersonDetailGroup) => {
            Column() {
              Row() {
                Text(group.title)
                  .fontSize(14)
                  .fontColor($r('app.color.common_color_1'))
                  .height(40)
                  .padding({ left: 12 })
                  .layoutWeight(1)
                  .maxLines(1)

                Image($r('app.media.mobile_campus_meeting_open'))
                  .width(16)
                  .height(16)
                  .margin({ right: 12 })
                  .rotate({ angle: group.expanded ? 90 : 0 })
              }
              .width('100%')
              .backgroundColor($r('app.color.white'))
              .alignItems(VerticalAlign.Center)
              .onClick(() => {
                this.toggleGroup(group.groupId);
              })

              Divider()
                .color($r('app.color.common_color_5'))
                .strokeWidth(0.5)
                .width('100%')

              if (group.expanded) {
                ForEach(group.persons, (person: PersonDetailItem) => {
                  PersonDetailRow({ person: person })
                }, (person: PersonDetailItem) => group.groupId + '_' + person.name)
              }
            }
            .width('100%')
            .backgroundColor($r('app.color.white'))
          }, (group: PersonDetailGroup) => group.groupId + (group.expanded ? '_open' : '_close'))
        }
        .width('100%')
      }
      .width('100%')
      .layoutWeight(1)
      .align(Alignment.Top)
      .scrollBar(BarState.Off)
      .backgroundColor($r('app.color.white'))
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.white'))
  }
}
