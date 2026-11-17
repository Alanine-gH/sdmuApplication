// 数据源：无服务器接口，OA申请详情/审批节点数据为内置示例数据（离线演示用），未接 ApiService。
import { TitleBar } from '../components/TitleBar';

class WorkApplyNode {
  id: string = '';
  nodeName: string = '';
  operator: string = '';
  nodeState: string = '';
  nodeTime: string = '';
  state: string = 'done';

  constructor(id: string, nodeName: string, operator: string, nodeState: string, nodeTime: string, state: string) {
    this.id = id;
    this.nodeName = nodeName;
    this.operator = operator;
    this.nodeState = nodeState;
    this.nodeTime = nodeTime;
    this.state = state;
  }
}

@Entry
@Component
struct WorkApplyDetailPage {
  @State headerTitle: string = '海南外国语职业学院多功能报告厅使用申请（copy）';
  @State showEmergency: boolean = true;
  @State showWei: boolean = false;
  @State showCuibanTag: boolean = false;
  @State nodes: WorkApplyNode[] = [
    new WorkApplyNode('n1', '发起申请', '张三', '已提交', '2026-11-10 14:22', 'done'),
    new WorkApplyNode('n2', '部门负责人审批', '李四', '已通过', '2026-11-11 09:15', 'done'),
    new WorkApplyNode('n3', '院办审核', '王建国', '审批中 · 当前节点', '2026-11-12 10:00', 'current'),
    new WorkApplyNode('n4', '分管校领导审批', '赵德芳', '待审批', '', 'wait')
  ];

  private doCuiban(): void {
    this.showCuibanTag = true;
  }

  private handleProcess(): void {
  }

  build() {
    Column() {
      TitleBar({ title: '审批详情', showBack: true })

      Scroll() {
        Column() {
          Column() {
            Row() {
              if (this.showEmergency) {
                Text('特提')
                  .fontSize(10)
                  .fontColor($r('app.color.white'))
                  .textAlign(TextAlign.Center)
                  .backgroundColor($r('app.color.mobile_campus_schedule_color7'))
                  .borderRadius(2)
                  .padding({ left: 5, right: 5, top: 3, bottom: 3 })
                  .margin({ right: 8 })
              }
              if (this.showWei) {
                Text('委')
                  .fontSize(10)
                  .fontColor($r('app.color.mobile_campus_schedule_color8'))
                  .textAlign(TextAlign.Center)
                  .borderRadius(2)
                  .border({ width: 0.5, color: $r('app.color.mobile_campus_schedule_color8') })
                  .padding({ left: 4, right: 4, top: 3, bottom: 3 })
                  .margin({ right: 8 })
              }
              if (this.showCuibanTag) {
                Text('催办')
                  .fontSize(10)
                  .fontColor($r('app.color.mobile_campus_schedule_color9'))
                  .textAlign(TextAlign.Center)
                  .borderRadius(2)
                  .border({ width: 0.5, color: $r('app.color.mobile_campus_schedule_color9') })
                  .padding({ left: 5, right: 5, top: 3, bottom: 3 })
              }
            }
            .width('100%')
            .alignItems(VerticalAlign.Center)

            Text(this.headerTitle)
              .fontSize(18.5)
              .fontWeight(FontWeight.Bold)
              .fontColor($r('app.color.common_color_1'))
              .maxLines(2)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
              .width('100%')
              .margin({ top: 12, bottom: 16 })

            Text('催办')
              .fontSize(16)
              .fontColor($r('app.color.mobile_campus_primary_color_default'))
              .textAlign(TextAlign.Center)
              .borderRadius(2)
              .border({ width: 0.5, color: $r('app.color.mobile_campus_primary_color_default') })
              .padding({ top: 10, bottom: 10 })
              .width('100%')
              .onClick(() => {
                this.doCuiban();
              })
          }
          .padding({ left: 12, top: 12, right: 12, bottom: 16 })
          .width('100%')
          .alignItems(HorizontalAlign.Start)
          .backgroundColor($r('app.color.white'))

          Column()
            .width('100%')
            .height(5)
            .backgroundColor($r('app.color.common_color_6'))

          Row() {
            Text('当前节点')
              .fontSize(16)
              .fontColor($r('app.color.common_color_3'))
          }
          .width('100%')
          .height(36)
          .padding({ left: 12, right: 12 })
          .alignItems(VerticalAlign.Center)
          .backgroundColor($r('app.color.white'))

          Divider()
            .strokeWidth(0.5)
            .color($r('app.color.common_color_5'))
            .width('100%')

          Column() {
            ForEach(this.nodes, (node: WorkApplyNode, idx: number) => {
              Row() {
                Column() {
                  Circle({
                    width: 9,
                    height: 9
                  })
                    .fill(node.state === 'done' ? $r('app.color.mobile_campus_schedule_color17') :
                      node.state === 'current' ? $r('app.color.mobile_campus_schedule_color9') :
                        $r('app.color.common_color_4'))
                    .margin({ top: 8 })
                  if (idx < this.nodes.length - 1) {
                    Column()
                      .width(1)
                      .layoutWeight(1)
                      .backgroundColor($r('app.color.common_color_5'))
                  }
                }
                .width(20)
                .height('100%')
                .alignItems(HorizontalAlign.Center)

                Column() {
                  Text(node.nodeName)
                    .fontSize(14)
                    .fontColor($r('app.color.common_color_1'))
                  Text(node.operator + ' · ' + node.nodeState)
                    .fontSize(13)
                    .fontColor($r('app.color.common_color_3'))
                    .margin({ top: 4 })
                  Text(node.nodeTime === '' ? '暂无记录' : node.nodeTime)
                    .fontSize(13)
                    .fontColor($r('app.color.common_color_3'))
                    .margin({ top: 2 })
                }
                .layoutWeight(1)
                .padding({ left: 4, top: 6, bottom: 12 })
                .alignItems(HorizontalAlign.Start)
              }
              .height(70)
              .width('100%')
            }, (node: WorkApplyNode) => node.id)
          }
          .padding({ left: 12, right: 12, top: 4 })
          .width('100%')
          .backgroundColor($r('app.color.white'))

          Column()
            .width('100%')
            .height(5)
            .backgroundColor($r('app.color.common_color_6'))

          Row() {
            Divider()
              .strokeWidth(0.5)
              .color($r('app.color.common_color_5'))
              .layoutWeight(1)
            Text('已显示全部')
              .fontSize(13)
              .fontColor($r('app.color.common_color_3'))
              .margin({ left: 20, right: 20 })
            Divider()
              .strokeWidth(0.5)
              .color($r('app.color.common_color_5'))
              .layoutWeight(1)
          }
          .width('100%')
          .alignItems(VerticalAlign.Center)
          .padding({ top: 14, bottom: 14, left: 12, right: 12 })
          .backgroundColor($r('app.color.white'))
        }
        .width('100%')
      }
      .width('100%')
      .layoutWeight(1)
      .scrollBar(BarState.Off)
      .backgroundColor($r('app.color.common_color_6'))

      Divider()
        .strokeWidth(0.5)
        .color($r('app.color.common_color_5'))
        .width('100%')

      Text('处理流程')
        .fontSize(17)
        .fontColor($r('app.color.mobile_campus_primary_color_default'))
        .textAlign(TextAlign.Center)
        .width('100%')
        .padding({ top: 10, bottom: 10 })
        .backgroundColor($r('app.color.white'))
        .onClick(() => {
          this.handleProcess();
        })
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.white'))
  }
}
