import { TitleBar } from '../components/TitleBar';

class OaIssueSummaryItem {
  id: string = '';
  title: string = '';
  department: string = '';
  needTime: string = '';
  reporter: string = '';
  queueType: string = '';
  sortNum: string = '';

  constructor(id: string, title: string, department: string, needTime: string, reporter: string,
    queueType: string, sortNum: string) {
    this.id = id;
    this.title = title;
    this.department = department;
    this.needTime = needTime;
    this.reporter = reporter;
    this.queueType = queueType;
    this.sortNum = sortNum;
  }
}

class OaIssueFlowNode {
  id: string = '';
  person: string = '';
  initial: string = '';
  step: string = '';
  stateText: string = '';
  flowTime: string = '';

  constructor(id: string, person: string, step: string, stateText: string, flowTime: string) {
    this.id = id;
    this.person = person;
    this.initial = person.substring(0, 1);
    this.step = step;
    this.stateText = stateText;
    this.flowTime = flowTime;
  }
}

@Entry
@Component
struct OaIssueDetailPage {
  @State issueTitle: string = '关于调整2026年度预算支出结构并细化绩效目标的议题';
  @State meetingLocation: string = '行政楼三楼第一会议室';
  @State meetingTime: string = '2026-11-18 09:00-11:30';
  @State abortTime: string = '2026-11-15 17:00';
  @State issueType: string = '审议类';
  @State attendees: string = '校党委全体委员';
  @State noteText: string = '无';
  @State summaryItems: OaIssueSummaryItem[] = [
    new OaIssueSummaryItem('m1', '关于2026年度预算调整方案的议题', '财务处', '15分钟', '王建国', '上会审议', '1'),
    new OaIssueSummaryItem('m2', '学生宿舍改造工程进展情况汇报', '后勤管理处', '20分钟', '李明', '上会审议', '2'),
    new OaIssueSummaryItem('m3', '校园安全稳定工作专项报告', '保卫处', '10分钟', '赵德芳', '上会审议', '3')
  ];
  @State flowNodes: OaIssueFlowNode[] = [
    new OaIssueFlowNode('f1', '郑王毛', '提交议题', '已提交', '2026-11-10 14:22'),
    new OaIssueFlowNode('f2', '李明', '部门审核', '已通过', '2026-11-11 09:15'),
    new OaIssueFlowNode('f3', '党委办公室', '汇总上会', '进行中', '2026-11-12 10:00'),
    new OaIssueFlowNode('f4', '校党委', '审议表决', '待上会', '')
  ];

  build() {
    Column() {
      TitleBar({ title: '议题详情', showBack: true })

      Scroll() {
        Column() {
          Column() {
            Row() {
              Text(this.issueTitle)
                .fontSize(18)
                .fontColor($r('app.color.common_color_1'))
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
                .layoutWeight(1)
            }
            .width('100%')
            .height(60)
            .padding({ left: 12, right: 12 })
            .alignItems(VerticalAlign.Center)

            Divider()
              .strokeWidth(0.5)
              .color($r('app.color.common_color_5'))
              .width('100%')

            Column() {
              Row() {
                Text('会议地点  ')
                  .fontSize(14)
                  .fontColor($r('app.color.common_color_31'))
                Text(this.meetingLocation)
                  .fontSize(14)
                  .fontColor($r('app.color.common_color_1'))
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
                  .layoutWeight(1)
              }
              .width('100%')
              .alignItems(VerticalAlign.Center)

              Row() {
                Text('会议时间  ')
                  .fontSize(14)
                  .fontColor($r('app.color.common_color_31'))
                Text(this.meetingTime)
                  .fontSize(14)
                  .fontColor($r('app.color.common_color_1'))
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
                  .layoutWeight(1)
              }
              .width('100%')
              .alignItems(VerticalAlign.Center)
              .margin({ top: 8 })

              Row() {
                Text('审议截止  ')
                  .fontSize(14)
                  .fontColor($r('app.color.common_color_31'))
                Text(this.abortTime)
                  .fontSize(14)
                  .fontColor($r('app.color.common_color_1'))
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
                  .layoutWeight(1)
              }
              .width('100%')
              .alignItems(VerticalAlign.Center)
              .margin({ top: 8 })

              Row() {
                Text('议题类型  ')
                  .fontSize(14)
                  .fontColor($r('app.color.common_color_31'))
                Text(this.issueType)
                  .fontSize(14)
                  .fontColor($r('app.color.common_color_1'))
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
                  .layoutWeight(1)
              }
              .width('100%')
              .alignItems(VerticalAlign.Center)
              .margin({ top: 8 })

              Row() {
                Text('出席人员  ')
                  .fontSize(14)
                  .fontColor($r('app.color.common_color_31'))
                Text(this.attendees)
                  .fontSize(14)
                  .fontColor($r('app.color.common_color_1'))
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
                  .layoutWeight(1)
              }
              .width('100%')
              .alignItems(VerticalAlign.Center)
              .margin({ top: 8 })

              Row() {
                Text('备        注  ')
                  .fontSize(14)
                  .fontColor($r('app.color.common_color_31'))
                Text(this.noteText)
                  .fontSize(14)
                  .fontColor($r('app.color.common_color_1'))
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
                  .layoutWeight(1)
              }
              .width('100%')
              .alignItems(VerticalAlign.Center)
              .margin({ top: 8 })
            }
            .padding(12)
            .width('100%')

            Divider()
              .strokeWidth(0.5)
              .color($r('app.color.common_color_5'))
              .width('100%')
          }
          .width('100%')
          .backgroundColor($r('app.color.white'))

          Row() {
            Text('议题汇总单')
              .fontSize(13)
              .fontColor($r('app.color.common_color_3'))
          }
          .width('100%')
          .height(36)
          .padding({ left: 12 })
          .alignItems(VerticalAlign.Center)

          Column() {
            ForEach(this.summaryItems, (summary: OaIssueSummaryItem) => {
              Column() {
                Row() {
                  Text(summary.title)
                    .fontSize(17)
                    .fontColor($r('app.color.common_color_1'))
                    .maxLines(1)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                    .layoutWeight(1)
                }
                .width('100%')
                .height(60)
                .alignItems(VerticalAlign.Center)

                Column() {
                  Row() {
                    Text('提出部门')
                      .fontSize(14)
                      .fontColor($r('app.color.common_color_31'))
                    Text(summary.department)
                      .fontSize(14)
                      .fontColor($r('app.color.common_color_1'))
                      .maxLines(1)
                      .textOverflow({ overflow: TextOverflow.Ellipsis })
                      .margin({ left: 12 })
                      .layoutWeight(1)
                  }
                  .width('100%')
                  .alignItems(VerticalAlign.Center)

                  Row() {
                    Text('所需时间')
                      .fontSize(14)
                      .fontColor($r('app.color.common_color_31'))
                    Text(summary.needTime)
                      .fontSize(14)
                      .fontColor($r('app.color.common_color_1'))
                      .maxLines(1)
                      .textOverflow({ overflow: TextOverflow.Ellipsis })
                      .margin({ left: 12 })
                      .layoutWeight(1)
                  }
                  .width('100%')
                  .alignItems(VerticalAlign.Center)
                  .margin({ top: 8 })

                  Row() {
                    Text('汇报人     ')
                      .fontSize(14)
                      .fontColor($r('app.color.common_color_31'))
                    Text(summary.reporter)
                      .fontSize(14)
                      .fontColor($r('app.color.common_color_1'))
                      .maxLines(1)
                      .textOverflow({ overflow: TextOverflow.Ellipsis })
                      .margin({ left: 12 })
                      .layoutWeight(1)
                  }
                  .width('100%')
                  .alignItems(VerticalAlign.Center)
                  .margin({ top: 8 })

                  Row() {
                    Text('排队类型')
                      .fontSize(14)
                      .fontColor($r('app.color.common_color_31'))
                    Text(summary.queueType)
                      .fontSize(14)
                      .fontColor($r('app.color.mobile_campus_score_common_color1'))
                      .margin({ left: 12 })
                    Image($r('app.media.mobile_campus_oa_issue_check_g_m'))
                      .width(16)
                      .height(16)
                      .objectFit(ImageFit.Contain)
                      .margin({ left: 8 })
                  }
                  .width('100%')
                  .alignItems(VerticalAlign.Center)
                  .margin({ top: 8 })

                  Row() {
                    Text('排序号：')
                      .fontSize(14)
                      .fontColor($r('app.color.common_color_31'))
                    Text(summary.sortNum)
                      .fontSize(14)
                      .fontColor($r('app.color.common_color_1'))
                      .maxLines(1)
                      .textOverflow({ overflow: TextOverflow.Ellipsis })
                      .margin({ left: 12 })
                      .layoutWeight(1)
                  }
                  .width('100%')
                  .alignItems(VerticalAlign.Center)
                  .margin({ top: 8 })
                }
                .width('100%')
                .margin({ top: 17 })
              }
              .padding({ left: 12, top: 15, right: 12, bottom: 15 })
              .width('100%')
              .alignItems(HorizontalAlign.Start)
              .backgroundColor($r('app.color.white'))

              Divider()
                .strokeWidth(0.5)
                .color($r('app.color.common_color_5'))
                .width('100%')
            }, (summary: OaIssueSummaryItem) => summary.id)
          }
          .width('100%')

          Row() {
            Text('议题流程')
              .fontSize(13)
              .fontColor($r('app.color.common_color_3'))
          }
          .width('100%')
          .height(36)
          .padding({ left: 12 })
          .alignItems(VerticalAlign.Center)

          Column() {
            ForEach(this.flowNodes, (node: OaIssueFlowNode, idx: number) => {
              Row() {
                Column() {
                  Stack({ alignContent: Alignment.Center }) {
                    Column()
                      .width(38)
                      .height(38)
                      .borderRadius(19)
                      .backgroundColor($r('app.color.common_color_7'))
                    Text(node.initial)
                      .fontSize(18)
                      .fontColor($r('app.color.white'))
                  }
                  .width(38)
                  .height(38)

                  Text(node.person)
                    .fontSize(12)
                    .fontColor($r('app.color.common_color_1'))
                    .margin({ top: 8 })

                  if (idx < this.flowNodes.length - 1) {
                    Column()
                      .width(1)
                      .layoutWeight(1)
                      .backgroundColor($r('app.color.common_color_5'))
                      .margin({ top: 4 })
                  }
                }
                .width(38)
                .height('100%')
                .alignItems(HorizontalAlign.Center)

                Column() {
                  Text(node.step)
                    .fontSize(14)
                    .fontColor($r('app.color.common_color_1'))
                  Text(node.stateText)
                    .fontSize(13)
                    .fontColor($r('app.color.common_color_3'))
                    .margin({ top: 4 })
                  Text(node.flowTime === '' ? '暂无记录' : node.flowTime)
                    .fontSize(13)
                    .fontColor($r('app.color.common_color_3'))
                    .margin({ top: 2 })
                }
                .layoutWeight(1)
                .padding({ left: 16, top: 8, bottom: 12 })
                .alignItems(HorizontalAlign.Start)
              }
              .height(88)
              .width('100%')
            }, (node: OaIssueFlowNode) => node.id)
          }
          .padding({ left: 12, right: 12, top: 4, bottom: 8 })
          .width('100%')
          .alignItems(HorizontalAlign.Start)
          .backgroundColor($r('app.color.white'))
        }
        .width('100%')
      }
      .width('100%')
      .layoutWeight(1)
      .scrollBar(BarState.Off)
      .backgroundColor($r('app.color.common_color_6'))
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.common_color_6'))
  }
}
