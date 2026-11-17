import { router } from '@kit.ArkUI';

interface EditTagItem {
  tagId: number;
  label: string;
  textColor: ResourceColor;
  borderColor: ResourceColor;
  filled: boolean;
}

/**
 * OA编辑待办详情页 — 1:1 复刻（px_to_dip_N = N/2 vp, px_to_sp_N = N/2 fp）：
 * mobile_campus_oa_activity_edit_todoitem.xml：自定义顶栏 44vp（返回图 / 标题"编辑" 18.5fp #333 居中 / 占位返回图）
 *   + ScrollView（mobile_campus_oa_todoitem_detail_header.xml 头部块 + 12vp 灰色分隔 + 编辑容器）
 *   + 底部 确定 17fp 白字 bg common_color_7(#18B4ED) padV15
 */
@Entry
@Component
struct EditTodoDetailPage {
  @State title: string = '海南外国语职业学院多功能报告厅使用申请（copy）';
  @State arriveTime: string = '2026-11-17 09:24';
  @State currentNode: string = '办公室主任审批';
  @State opinion: string = '经审核，会议时间安排合理，同意按流程提交分管领导审批。';

  private headerTags: EditTagItem[] = [
    { tagId: 1, label: '特提', textColor: '#FFFFFF', borderColor: '#FF6C6C', filled: true },
    { tagId: 2, label: '委', textColor: '#57C06B', borderColor: '#57C06B', filled: false },
    { tagId: 3, label: '催办', textColor: '#1B68B7', borderColor: '#1B68B7', filled: false }
  ];

  @Builder
  private headerBlock() {
    Column() {
      Row() {
        ForEach(this.headerTags, (item: EditTagItem) => {
          Text(item.label)
            .fontSize(10)
            .fontColor(item.textColor)
            .textAlign(TextAlign.Center)
            .padding({ left: item.filled ? 5 : 4, right: item.filled ? 5 : 4, top: 3, bottom: 3 })
            .border({ width: 0.5, color: item.borderColor })
            .backgroundColor(item.filled ? item.borderColor : Color.Transparent)
            .margin({ right: 8 })
        }, (item: EditTagItem) => item.tagId.toString())
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
        Text('编辑')
          .fontSize(18.5)
          .fontColor($r('app.color.common_color_1'))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .layoutWeight(1)
          .textAlign(TextAlign.Center)
          .margin({ left: 10, right: 10 })
        Image($r('app.media.nav_back_btn'))
          .width(30)
          .height(30)
          .padding(5)
          .visibility(Visibility.Hidden)
      }
      .width('100%')
      .height(44)
      .padding({ left: 10, right: 10 })
      .alignItems(VerticalAlign.Center)
      .backgroundColor($r('app.color.white'))

      Scroll() {
        Column() {
          this.headerBlock()
          Divider()
            .color($r('app.color.common_color_5'))
            .strokeWidth(12)
            .width('100%')

          Column() {
            Text('审批意见')
              .fontSize(16)
              .fontColor($r('app.color.common_color_3'))
              .margin({ top: 15 })

            TextArea({ text: this.opinion, placeholder: '请输入审批意见...' })
              .fontSize(16)
              .fontColor($r('app.color.common_color_1'))
              .placeholderColor($r('app.color.edit_hint_color'))
              .backgroundColor($r('app.color.white'))
              .constraintSize({ minHeight: 120 })
              .width('100%')
              .margin({ top: 12 })
          }
          .width('100%')
          .padding({ left: 12, right: 12, bottom: 16 })
          .backgroundColor($r('app.color.white'))
        }
        .width('100%')
      }
      .width('100%')
      .layoutWeight(1)
      .scrollBar(BarState.Off)

      Text('确定')
        .fontSize(17)
        .fontColor($r('app.color.white'))
        .textAlign(TextAlign.Center)
        .width('100%')
        .padding({ top: 15, bottom: 15 })
        .backgroundColor($r('app.color.common_color_7'))
        .onClick(() => {
          router.back();
        })
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.white'))
  }
}
