import { router } from '@kit.ArkUI';
import { TitleBar } from '../components/TitleBar';

interface FastReplyItem {
  replyId: number;
  label: string;
  checked: boolean;
}

/**
 * OA快速回复页 — 1:1 复刻（px_to_dip_N = N/2 vp, px_to_sp_N = N/2 fp）：
 * mobile_campus_oa_activity_todo_fastreply.xml：bg #F2F2F2 + toolbar_normal（TitleBar 复用，mB12）
 *   + 列表（mobile_campus_oa_view_todo_fast_reply.xml：白底 48vp 行，checkbox 图 + 标题 17fp #333 mL12 + thin 分隔线）
 *   + 空态图 empty_fast_reply + 底部 确定 17fp #1B68B7 白底 49vp
 */
@Entry
@Component
struct TodoFastReplyPage {
  @State replies: FastReplyItem[] = [
    { replyId: 1, label: '同意', checked: false },
    { replyId: 2, label: '同意，请按相关规定办理', checked: true },
    { replyId: 3, label: '不同意，请修改后重新提交', checked: false },
    { replyId: 4, label: '已阅', checked: false },
    { replyId: 5, label: '请办公室审核后报分管领导审批', checked: false },
    { replyId: 6, label: '情况属实，同意按流程办理', checked: false }
  ];

  private toggleCheck(replyId: number): void {
    const next: FastReplyItem[] = [];
    for (const item of this.replies) {
      next.push({
        replyId: item.replyId,
        label: item.label,
        checked: item.replyId === replyId ? !item.checked : item.checked
      });
    }
    this.replies = next;
  }

  build() {
    Column() {
      TitleBar({ title: '快速回复' })
      Column() {
        if (this.replies.length > 0) {
          Column() {
            List() {
              ForEach(this.replies, (item: FastReplyItem) => {
                ListItem() {
                  Column() {
                    Row() {
                      Image(item.checked ? $r('app.media.mobile_campus_oa_choose') : $r('app.media.mobile_campus_oa_chose'))
                        .width(20)
                        .height(20)
                      Text(item.label)
                        .fontSize(17)
                        .fontColor($r('app.color.common_color_1'))
                        .maxLines(1)
                        .textOverflow({ overflow: TextOverflow.Ellipsis })
                        .margin({ left: 12 })
                      Blank()
                    }
                    .width('100%')
                    .height('100%')
                    .padding({ left: 12 })
                    .alignItems(VerticalAlign.Center)
                    .onClick(() => {
                      this.toggleCheck(item.replyId);
                    })

                    Divider()
                      .color($r('app.color.common_color_5'))
                      .strokeWidth(0.5)
                      .width('100%')
                  }
                  .height(48)
                  .backgroundColor($r('app.color.white'))
                }
              }, (item: FastReplyItem) => item.replyId.toString() + '_' + item.checked.toString())
            }
            .width('100%')
            .scrollBar(BarState.Off)
          }
          .layoutWeight(1)
        } else {
          Column() {
            Image($r('app.media.empty_fast_reply'))
              .width(160)
              .height(160)
          }
          .width('100%')
          .layoutWeight(1)
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)
        }

        Text('确定')
          .fontSize(17)
          .fontColor($r('app.color.mobile_campus_primary_color_default'))
          .textAlign(TextAlign.Center)
          .width('100%')
          .height(49)
          .backgroundColor($r('app.color.white'))
          .onClick(() => {
            router.back();
          })
      }
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F2F2F2')
  }
}
