import { router } from '@kit.ArkUI';
import { TitleBar } from '../components/TitleBar';

class OaIssueItem {
  id: string = '';
  title: string = '';
  location: string = '';
  time: string = '';
  people: string = '';
  selectable: boolean = false;

  constructor(id: string, title: string, location: string, time: string, people: string, selectable: boolean) {
    this.id = id;
    this.title = title;
    this.location = location;
    this.time = time;
    this.people = people;
    this.selectable = selectable;
  }
}

class OaIssueGroup {
  id: string = '';
  title: string = '';
  items: OaIssueItem[] = [];

  constructor(id: string, title: string, items: OaIssueItem[]) {
    this.id = id;
    this.title = title;
    this.items = items;
  }
}

class OaIssueSection {
  id: string = '';
  name: string = '';
  groups: OaIssueGroup[] = [];

  constructor(id: string, name: string, groups: OaIssueGroup[]) {
    this.id = id;
    this.name = name;
    this.groups = groups;
  }
}

@Entry
@Component
struct OaIssuePage {
  @State sections: OaIssueSection[] = [
    new OaIssueSection('s1', '第42次党委会议', [
      new OaIssueGroup('g1', '上会议题', [
        new OaIssueItem('i1', '关于调整2026年度预算支出结构的议题', '行政楼三楼第一会议室', '2026-11-18 09:00', '校党委全体委员', true),
        new OaIssueItem('i2', '学生宿舍改造工程进展情况汇报', '行政楼三楼第一会议室', '2026-11-18 10:00', '校党委全体委员', true),
        new OaIssueItem('i3', '校园安全稳定工作专项报告', '行政楼三楼第一会议室', '2026-11-18 10:30', '校党委全体委员', true)
      ]),
      new OaIssueGroup('g2', '通知事项', [
        new OaIssueItem('i4', '关于冬季消防安全检查的通知', '行政楼三楼第一会议室', '2026-11-15 14:00', '各部门负责人', false),
        new OaIssueItem('i5', '关于期中教学检查工作安排的通知', '行政楼三楼第一会议室', '2026-11-16 09:00', '各教学单位', false)
      ])
    ]),
    new OaIssueSection('s2', '第41次校长办公会', [
      new OaIssueGroup('g3', '上会议题', [
        new OaIssueItem('i6', '关于2026年度实训设备采购计划的议题', '行政楼二楼会议室', '2026-11-11 14:30', '校领导班子', true)
      ]),
      new OaIssueGroup('g4', '通知事项', [
        new OaIssueItem('i7', '关于教职工体检工作安排的通知', '行政楼二楼会议室', '2026-11-08 10:00', '全体教职工', false)
      ])
    ]),
    new OaIssueSection('s3', '专题会议', [
      new OaIssueGroup('g5', '通知事项', [
        new OaIssueItem('i8', '关于召开本科教学评估动员会的通知', '图书馆学术报告厅', '2026-11-20 15:00', '各院系负责人', false)
      ])
    ])
  ];
  @State expandedId: string = 's1';
  @State checkedIds: string[] = [];

  private toggleSection(id: string): void {
    if (this.expandedId === id) {
      this.expandedId = '';
    } else {
      this.expandedId = id;
    }
  }

  private toggleCheck(id: string): void {
    if (this.checkedIds.indexOf(id) >= 0) {
      this.checkedIds = this.checkedIds.filter((x: string): boolean => x !== id);
    } else {
      this.checkedIds = this.checkedIds.concat([id]);
    }
  }

  private goDetail(): void {
    router.pushUrl({ url: 'pages/OaIssueDetailPage' });
  }

  build() {
    Column() {
      TitleBar({ title: 'OA事项', showBack: true })

      Scroll() {
        Column() {
          ForEach(this.sections, (section: OaIssueSection) => {
            Column() {
              Text(section.name)
                .fontSize(18)
                .fontColor($r('app.color.oa_issue_blue'))
                .textAlign(TextAlign.Center)
                .width('100%')
                .height(56)
                .margin({ top: 0.5 })
                .backgroundColor($r('app.color.white'))
                .onClick(() => {
                  this.toggleSection(section.id);
                })

              if (this.expandedId === section.id) {
                Column() {
                  ForEach(section.groups, (group: OaIssueGroup) => {
                    Column() {
                      Row() {
                        Text(group.title)
                          .fontSize(13)
                          .fontColor($r('app.color.oa_issue_group_title'))
                      }
                      .width('100%')
                      .height(36)
                      .padding({ left: 12, right: 12 })
                      .alignItems(VerticalAlign.Center)
                      .backgroundColor($r('app.color.oa_issue_group_bg'))

                      ForEach(group.items, (issue: OaIssueItem) => {
                        Column() {
                          Row() {
                            Text(issue.title)
                              .fontSize(17)
                              .fontColor($r('app.color.black'))
                              .maxLines(1)
                              .textOverflow({ overflow: TextOverflow.Ellipsis })
                              .layoutWeight(1)
                            if (issue.selectable) {
                              Image(this.checkedIds.indexOf(issue.id) >= 0 ?
                                $r('app.media.mobile_campus_oa_issue_close') :
                                $r('app.media.mobile_campus_oa_issue_open'))
                                .width(26)
                                .height(26)
                                .objectFit(ImageFit.Contain)
                                .margin({ left: 8 })
                                .onClick(() => {
                                  this.toggleCheck(issue.id);
                                })
                            }
                            Image($r('app.media.mobile_campus_oa_issue_check_g_m'))
                              .width(16)
                              .height(16)
                              .objectFit(ImageFit.Contain)
                              .margin({ left: 8 })
                          }
                          .width('100%')
                          .alignItems(VerticalAlign.Center)

                          Row() {
                            Image($r('app.media.mobile_campus_oa_issue_location'))
                              .width(12)
                              .height(12)
                              .objectFit(ImageFit.Contain)
                            Text(issue.location)
                              .fontSize(13)
                              .fontColor($r('app.color.common_color_3'))
                              .margin({ left: 8 })
                          }
                          .width('100%')
                          .alignItems(VerticalAlign.Center)
                          .margin({ top: 12 })

                          Row() {
                            Image($r('app.media.mobile_campus_oa_issue_time'))
                              .width(12)
                              .height(12)
                              .objectFit(ImageFit.Contain)
                            Text(issue.time)
                              .fontSize(13)
                              .fontColor($r('app.color.common_color_3'))
                              .margin({ left: 8 })
                          }
                          .width('100%')
                          .alignItems(VerticalAlign.Center)
                          .margin({ top: 12 })

                          Row() {
                            Image($r('app.media.mobile_campus_oa_issue_people'))
                              .width(12)
                              .height(12)
                              .objectFit(ImageFit.Contain)
                            Text(issue.people)
                              .fontSize(13)
                              .fontColor($r('app.color.common_color_3'))
                              .margin({ left: 8 })
                          }
                          .width('100%')
                          .alignItems(VerticalAlign.Center)
                          .margin({ top: 12 })

                          Divider()
                            .strokeWidth(0.5)
                            .color($r('app.color.common_color_5'))
                            .margin({ top: 12 })
                            .width('100%')
                        }
                        .padding({ left: 12, top: 20, right: 12, bottom: 15.5 })
                        .width('100%')
                        .alignItems(HorizontalAlign.Start)
                        .backgroundColor($r('app.color.white'))
                        .onClick(() => {
                          this.goDetail();
                        })
                      }, (issue: OaIssueItem) => issue.id)
                    }
                    .width('100%')
                  }, (group: OaIssueGroup) => group.id)
                }
                .width('100%')
              }
            }
            .width('100%')
          }, (section: OaIssueSection) => section.id)
        }
        .width('100%')
      }
      .width('100%')
      .layoutWeight(1)
      .scrollBar(BarState.Off)
      .backgroundColor($r('app.color.main_bg'))
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.main_bg'))
  }
}
