import { router } from '@kit.ArkUI';

interface TodoHeaderTag {
  tagId: number;
  label: string;
  textColor: ResourceColor;
  borderColor: ResourceColor;
  filled: boolean;
}

/**
 * OA待办读件页 — 1:1 复刻（px_to_dip_N = N/2 vp, px_to_sp_N = N/2 fp）：
 * mobile_campus_oa_activity_todoitem_detail.xml：自定义顶栏 44vp（返回图 pad10 / 标题 18.5fp bold invisible / 撤回·编辑 16fp #3A3A3A 带图标）
 *   + ScrollView 白底内容（mobile_campus_oa_todoitem_detail_header.xml：标签行 特提 10fp 白底 #FF6C6C / 委 #57C06B / 催办 #1B68B7 描边；
 *     标题 18.5fp bold #333 mT12 mB16；到达时间/当前节点 label 16fp #999 w90 mR12 + 值 16fp #333）
 *   + 底部：阴影 12vp + 处理流程/传阅 17fp #1B68B7 padV10 白底居中
 */
@Entry
@Component
struct TodoReadPage {
  @State title: string = '海南外国语职业学院多功能报告厅使用申请（copy）';
  @State arriveTime: string = '2026-11-17 09:24';
  @State currentNode: string = '办公室主任审批';
  @State startTime: string = '2026-11-16 8:00';
  @State endTime: string = '2026-11-18 9:00';
  @State showRecover: boolean = true;
  @State showEdit: boolean = true;
  @State showHandleProcess: boolean = true;
  @State showCirculate: boolean = true;

  private headerTags: TodoHeaderTag[] = [
    { tagId: 1, label: '特提', textColor: '#FFFFFF', borderColor: '#FF6C6C', filled: true },
    { tagId: 2, label: '委', textColor: '#57C06B', borderColor: '#57C06B', filled: false },
    { tagId: 3, label: '催办', textColor: '#1B68B7', borderColor: '#1B68B7', filled: false }
  ];

  @Builder
  private headerBlock() {
    Column() {
      Row() {
        ForEach(this.headerTags, (item: TodoHeaderTag) => {
          Text(item.label)
            .fontSize(10)
            .fontColor(item.textColor)
            .textAlign(TextAlign.Center)
            .padding({ left: item.filled ? 5 : 4, right: item.filled ? 5 : 4, top: 3, bottom: 3 })
            .border({ width: 0.5, color: item.borderColor })
            .backgroundColor(item.filled ? item.borderColor : Color.Transparent)
            .margin({ right: 8 })
        }, (item: TodoHeaderTag) => item.tagId.toString())
      }
      .width('100%')

      Text(this.title)
        .fontSize(18.5)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.common_color_1'))
        .maxLines(2)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .width('100%')
        .margin({ top: 12, bottom: 16 })

      Row() {
        Text('到达时间')
          .fontSize(16)
          .fontColor($r('app.color.common_color_3'))
          .width(90)
          .margin({ right: 12 })
        Text(this.arriveTime)
          .fontSize(16)
          .fontColor($r('app.color.common_color_1'))
      }
      .width('100%')
      .margin({ bottom: 8 })

      Row() {
        Text('当前节点')
          .fontSize(16)
          .fontColor($r('app.color.common_color_3'))
          .width(90)
          .margin({ right: 12 })
        Text(this.currentNode)
          .fontSize(16)
          .fontColor($r('app.color.common_color_1'))
      }
      .width('100%')
    }
    .width('100%')
    .padding({ left: 12, top: 12, right: 12, bottom: 16 })
    .backgroundColor($r('app.color.white'))
  }

  @Builder
  private nodeTimeBlock() {
    Row() {
      Text('当前节点')
        .fontSize(16)
        .fontColor($r('app.color.common_color_3'))
        .width(35)
        .margin({ right: 12 })
      Column() {
        Row() {
          Text('起')
            .fontSize(16)
            .fontColor($r('app.color.mobile_campus_schedule_color2'))
            .margin({ right: 12 })
          Text(this.startTime)
            .fontSize(16)
            .fontColor($r('app.color.common_color_1'))
        }
        .width('100%')

        Row() {
          Text('止')
            .fontSize(16)
            .fontColor($r('app.color.mobile_campus_schedule_color2'))
            .margin({ right: 12 })
          Text(this.endTime)
            .fontSize(16)
            .fontColor($r('app.color.common_color_1'))
        }
        .width('100%')
        .margin({ top: 4 })
      }
      .layoutWeight(1)
      .margin({ right: 12 })
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .padding({ left: 12, top: 15 })
    .backgroundColor($r('app.color.white'))
  }

  build() {
    Column() {
      Row() {
        Image($r('app.media.nav_back_btn'))
          .width(30)
          .height(30)
          .padding(5)
          .onClick(() => {
            router.back();
          })
        Text(this.title)
          .fontSize(18.5)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.common_color_1'))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .layoutWeight(1)
          .margin({ left: 10, right: 10 })
          .visibility(Visibility.Hidden)
        Row() {
          if (this.showRecover) {
            Row() {
              Image($r('app.media.mobile_campus_meeting_recovery'))
                .width(16)
                .height(16)
              Text('撤回')
                .fontSize(16)
                .fontColor($r('app.color.mobile_campus_schedule_color6'))
                .margin({ left: 4 })
            }
            .margin({ right: 8 })
          }
          if (this.showEdit) {
            Row() {
              Image($r('app.media.mobile_campus_oa_edit_p'))
                .width(16)
                .height(16)
              Text('编辑')
                .fontSize(16)
                .fontColor($r('app.color.mobile_campus_schedule_color6'))
                .margin({ left: 4 })
            }
            .onClick(() => {
              router.pushUrl({ url: 'pages/EditTodoDetailPage' });
            })
          }
        }
        .height('100%')
      }
      .width('100%')
      .height(44)
      .padding({ left: 10, right: 10 })
      .alignItems(VerticalAlign.Center)
      .backgroundColor($r('app.color.white'))

      Stack({ alignContent: Alignment.Bottom }) {
        Scroll() {
          Column() {
            this.headerBlock()
            Divider()
              .color($r('app.color.common_color_5'))
              .strokeWidth(0.5)
              .width('100%')
            this.nodeTimeBlock()
          }
          .width('100%')
          .padding({ bottom: 20 })
          .backgroundColor($r('app.color.white'))
        }
        .width('100%')
        .height('100%')
        .backgroundColor($r('app.color.common_color_6'))
        .scrollBar(BarState.Off)

        Column() {
          Column()
            .width('100%')
            .height(12)
            .linearGradient({
              angle: 90,
              colors: [['#1A000000', 0], ['#0DFFFFFF', 1]]
            })
          if (this.showHandleProcess) {
            Text('处理流程')
              .fontSize(17)
              .fontColor('#1B68B7')
              .textAlign(TextAlign.Center)
              .width('100%')
              .padding({ top: 10, bottom: 10 })
              .backgroundColor($r('app.color.ybg_white'))
          }
          if (this.showCirculate) {
            Text('传阅')
              .fontSize(17)
              .fontColor('#1B68B7')
              .textAlign(TextAlign.Center)
              .width('100%')
              .padding({ top: 10, bottom: 10 })
              .backgroundColor($r('app.color.ybg_white'))
              .onClick(() => {
                router.pushUrl({ url: 'pages/CirculateReadPage' });
              })
          }
        }
        .width('100%')
      }
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.white'))
  }
}
