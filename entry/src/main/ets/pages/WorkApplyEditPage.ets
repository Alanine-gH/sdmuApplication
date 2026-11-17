import { TitleBar } from '../components/TitleBar';

/**
 * 审批编辑页 — 1:1 复刻 mobile_campus_oa_activity_workapply_edit.xml：
 * toolbar + ScrollView(weight1) + 底部提交按钮(17fp 白字 primary bg padV12)
 * ScrollView 内容：mobile_campus_oa_workapply_detail_header.xml
 *   padH12 padT12 padB16：标签行(特提10fp 白字 schedule_color7 bg padH5 padV3 /
 *   委10fp schedule_color8 bg绿 padH4 padV3 / 催办10fp schedule_color9 bg蓝 padH5 padV3)
 *   标题18.5fp粗体 mt12 mb16 催办按钮(16fp primary border bg padV10)
 *   + divider_horizontal_grey_normal(高8 common_color_6)
 */
@Entry
@Component
struct WorkApplyEditPage {
  @State title: string = '海南外国语职业学院多功能报告厅使用申请（copy）';

  private toast(msg: string): void {
    this.getUIContext().getPromptAction().showToast({ message: msg });
  }

  build() {
    Column() {
      TitleBar({ title: '审批编辑', showBack: true })

      Scroll() {
        Column() {
          // mobile_campus_oa_workapply_detail_header.xml
          Column() {
            // header_tag_container
            Row() {
              Text('特提')
                .fontSize(10)
                .fontColor($r('app.color.white'))
                .padding({ left: 5, right: 5, top: 3, bottom: 3 })
                .backgroundColor($r('app.color.mobile_campus_schedule_color7'))
              Text('委')
                .fontSize(10)
                .fontColor($r('app.color.mobile_campus_schedule_color8'))
                .padding({ left: 4, right: 4, top: 3, bottom: 3 })
                .backgroundColor('#E8F8EA')
                .margin({ left: 8 })
              Text('催办')
                .fontSize(10)
                .fontColor($r('app.color.mobile_campus_schedule_color9'))
                .padding({ left: 5, right: 5, top: 3, bottom: 3 })
                .backgroundColor('#E8F1FB')
                .margin({ left: 8 })
            }
            .width('100%')

            Text(this.title)
              .fontSize(18.5)
              .fontWeight(FontWeight.Bold)
              .fontColor($r('app.color.common_color_1'))
              .width('100%')
              .margin({ top: 12, bottom: 16 })
              .maxLines(2)
              .textOverflow({ overflow: TextOverflow.Ellipsis })

            Text('催办')
              .fontSize(16)
              .fontColor($r('app.color.mobile_campus_primary_color_default'))
              .width('100%')
              .padding({ top: 10, bottom: 10 })
              .textAlign(TextAlign.Center)
              .border({ width: 1, color: $r('app.color.ybg_dark_blue') })
              .onClick(() => {
                this.toast('已发送催办提醒');
              })
          }
          .width('100%')
          .padding({ left: 12, top: 12, right: 12, bottom: 16 })
          .backgroundColor($r('app.color.white'))

          // divider_horizontal_grey_normal：高8 common_color_6
          Column()
            .width('100%')
            .height(8)
            .backgroundColor($r('app.color.common_color_6'))

          // 表单编辑区（edit_container 动态表单，示例项）
          Column() {
            ForEach(this.formRows(), (row: string[]) => {
              this.formRow(row[0], row[1])
            }, (row: string[]) => row[0])
          }
          .width('100%')
          .padding({ left: 12, right: 12 })
          .backgroundColor($r('app.color.white'))
        }
        .width('100%')
      }
      .width('100%')
      .layoutWeight(1)
      .scrollBar(BarState.Off)
      .align(Alignment.Top)

      // btn_sure 提交
      Text('提交')
        .fontSize(17)
        .fontColor($r('app.color.white'))
        .width('100%')
        .padding({ top: 12, bottom: 12 })
        .textAlign(TextAlign.Center)
        .backgroundColor($r('app.color.mobile_campus_primary_color_default'))
        .onClick(() => {
          this.toast('提交成功');
        })
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.white'))
  }

  private formRows(): string[][] {
    const rows: string[][] = [
      ['申请部门：', '教务处'],
      ['申请人：', '张伟'],
      ['使用时间：', '2026-11-20 14:30 - 17:30'],
      ['使用人数：', '120人'],
      ['申请事由：', '举办英语演讲比赛决赛']
    ];
    return rows;
  }

  @Builder
  formRow(name: string, content: string) {
    Column() {
      Row() {
        Text(name)
          .fontSize(16)
          .fontColor($r('app.color.common_color_1'))
        Text(content)
          .fontSize(16)
          .fontColor($r('app.color.common_color_1'))
          .layoutWeight(1)
          .textAlign(TextAlign.Start)
          .maxLines(1)
      }
      .width('100%')
      .padding({ top: 11, bottom: 11 })
      .alignItems(VerticalAlign.Center)

      Divider()
        .color($r('app.color.common_color_5'))
        .strokeWidth(0.5)
        .width('100%')
    }
    .width('100%')
  }
}
