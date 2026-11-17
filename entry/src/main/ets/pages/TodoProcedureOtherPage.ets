interface TodoProcessNode {
  nodeId: number;
  tagName: string;
  handler: string;
  career: string;
  comment: string;
  date: string;
  done: boolean;
}

/**
 * OA流程其他页 — 1:1 复刻（px_to_dip_N = N/2 vp, px_to_sp_N = N/2 fp）：
 * mobile_campus_oa_todoitem_process.xml（merge）：padT8 padB12
 *   首行：灰色圆点 15×15 mL15 + 标签"收文处理单" 10fp 白字 greybox 背景 padL13 padR9 mX
 *   下级：办理人 15fp #333 mT12 mL4 + 职务 15fp #999 + 审批意见 15fp #1B68B7 可复制 + 日期 12fp #999 右上
 *   竖向时间线（灰色圆点串起各节点），页面内置流程节点/审批意见示例数据
 */
@Entry
@Component
struct TodoProcedureOtherPage {
  @State processList: TodoProcessNode[] = [
    {
      nodeId: 1,
      tagName: '收文处理单',
      handler: '张建国',
      career: '办公室主任',
      comment: '同意，请按流程办理。',
      date: '2026-11-16 14:02',
      done: true
    },
    {
      nodeId: 2,
      tagName: '拟办意见',
      handler: '李文静',
      career: '办公室秘书科',
      comment: '已登记收文，呈请领导批示。',
      date: '2026-11-16 16:37',
      done: true
    },
    {
      nodeId: 3,
      tagName: '领导批示',
      handler: '王明远',
      career: '分管副院长',
      comment: '同意，请相关部门落实执行，并做好跟踪反馈。',
      date: '2026-11-17 09:15',
      done: false
    },
    {
      nodeId: 4,
      tagName: '部门承办',
      handler: '赵晓峰',
      career: '后勤管理处',
      comment: '',
      date: '',
      done: false
    }
  ];

  build() {
    Column() {
      Text('流程其他')
        .fontSize(18.5)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.common_color_1'))
        .width('100%')
        .height(44)
        .textAlign(TextAlign.Center)
        .backgroundColor($r('app.color.white'))

      Scroll() {
        Column() {
          ForEach(this.processList, (item: TodoProcessNode, index: number) => {
            Row() {
              Column() {
                Image($r('app.media.mobile_campus_oa_circle_grey'))
                  .width(15)
                  .height(15)
                  .margin({ left: 15 })
                if (index < this.processList.length - 1) {
                  Column()
                    .width(0.5)
                    .layoutWeight(1)
                    .backgroundColor($r('app.color.common_color_5'))
                    .margin({ top: 4 })
                }
              }
              .alignItems(HorizontalAlign.Center)

              Column() {
                Row() {
                  Text(item.tagName)
                    .fontSize(10)
                    .fontColor($r('app.color.white'))
                    .textAlign(TextAlign.Center)
                    .padding({ left: 13, right: 9, top: 4, bottom: 4 })
                    .backgroundImage($r('app.media.mobile_campus_oa_greybox'))
                    .backgroundImageSize(ImageSize.Contain)
                    .margin({ left: 8, right: 12 })
                  Blank()
                  if (item.date !== '') {
                    Text(item.date)
                      .fontSize(12)
                      .fontColor($r('app.color.common_color_3'))
                      .margin({ right: 10 })
                  }
                }
                .width('100%')

                if (item.handler !== '') {
                  Text(item.handler)
                    .fontSize(15)
                    .fontColor($r('app.color.common_color_1'))
                    .margin({ top: 12, left: 4 })
                }
                if (item.career !== '') {
                  Text(item.career)
                    .fontSize(15)
                    .fontColor($r('app.color.common_color_3'))
                    .margin({ top: 11, left: 4 })
                }
                if (item.comment !== '') {
                  Text(item.comment)
                    .fontSize(15)
                    .fontColor($r('app.color.mobile_campus_primary_color_default'))
                    .margin({ top: 11, left: 4 })
                    .copyOption(CopyOptions.InApp)
                }
              }
              .layoutWeight(1)
              .alignItems(HorizontalAlign.Start)
            }
            .width('100%')
            .alignItems(VerticalAlign.Top)
            .padding({ top: 8, bottom: 12 })
          }, (item: TodoProcessNode) => item.nodeId.toString())
        }
        .width('100%')
        .padding({ bottom: 24 })
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
}
