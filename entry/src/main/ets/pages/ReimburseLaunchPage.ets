import { TitleBar } from '../components/TitleBar';

/**
 * 发起报销页 — 复刻 reimburse 发起表单（ReimburseLaunchActivity V2 + dialog_detail表单区）
 * 结构：toolbar「发起报销」+ 表单：
 *   - 报销类型选择（差旅/日常/招待）
 *   - 报销金额输入
 *   - 发生日期选择
 *   - 报销事由多行输入
 *   - 发票附件选择（票据列表入口+添加）
 *   - 底部提交按钮
 */
@Entry
@Component
struct ReimburseLaunchPage {
  @State amount: string = '';
  @State reason: string = '';
  @State typeName: string = '差旅费';
  @State dateStr: string = '';
  @State receiptCount: number = 0;

  build() {
    Column() {
      TitleBar({ title: '发起报销', showBack: true })

      Scroll() {
        Column() {
          // 报销类型
          Row() {
            Text('报销类型')
              .fontSize(16)
              .fontColor($r('app.color.common_color_1'))
              .margin({ left: 15 })
            Text(this.typeName)
              .fontSize(16)
              .fontColor($r('app.color.blue_default'))
              .layoutWeight(1)
              .textAlign(TextAlign.End)
              .margin({ right: 8 })
            Image($r('app.media.arrow_right2'))
              .width(14)
              .height(14)
              .margin({ right: 15 })
          }
          .width('100%')
          .height(48)
          .alignItems(VerticalAlign.Center)
          .backgroundColor($r('app.color.white'))
          .onClick(() => {
            const types: string[] = ['差旅费', '日常费用', '招待费'];
            const idx: number = types.indexOf(this.typeName);
            this.typeName = types[(idx + 1) % types.length];
          })

          Divider().color($r('app.color.common_color_5')).strokeWidth(0.5).width('100%')

          // 报销金额
          Row() {
            Text('报销金额')
              .fontSize(16)
              .fontColor($r('app.color.common_color_1'))
              .margin({ left: 15 })
            TextInput({ placeholder: '请输入金额(元)', text: this.amount })
              .type(InputType.NUMBER_DECIMAL)
              .fontSize(16)
              .fontColor($r('app.color.common_color_1'))
              .placeholderColor($r('app.color.common_color_4'))
              .height(48)
              .backgroundColor(Color.Transparent)
              .padding(0)
              .layoutWeight(1)
              .margin({ left: 30, right: 15 })
              .onChange((v: string) => {
                this.amount = v;
              })
          }
          .width('100%')
          .height(48)
          .alignItems(VerticalAlign.Center)
          .backgroundColor($r('app.color.white'))

          Divider().color($r('app.color.common_color_5')).strokeWidth(0.5).width('100%')

          // 发生日期
          Row() {
            Text('发生日期')
              .fontSize(16)
              .fontColor($r('app.color.common_color_1'))
              .margin({ left: 15 })
            Text(this.dateStr === '' ? '请选择日期' : this.dateStr)
              .fontSize(16)
              .fontColor(this.dateStr === '' ? $r('app.color.common_color_4') : $r('app.color.common_color_1'))
              .layoutWeight(1)
              .textAlign(TextAlign.End)
              .margin({ right: 8 })
            Image($r('app.media.arrow_right2'))
              .width(14)
              .height(14)
              .margin({ right: 15 })
          }
          .width('100%')
          .height(48)
          .alignItems(VerticalAlign.Center)
          .backgroundColor($r('app.color.white'))
          .onClick(() => {
            this.dateStr = '2026-11-17';
          })

          // 报销事由
          Text('报销事由')
            .fontSize(16)
            .fontColor($r('app.color.common_color_1'))
            .padding({ left: 15, top: 15, bottom: 8 })
            .width('100%')
            .backgroundColor($r('app.color.white'))
            .alignSelf(ItemAlign.Start)

          TextArea({ placeholder: '请输入报销事由说明', text: this.reason })
            .fontSize(14)
            .fontColor($r('app.color.common_color_1'))
            .placeholderColor($r('app.color.common_color_4'))
            .height(100)
            .backgroundColor($r('app.color.white'))
            .padding({ left: 15, right: 15 })
            .onChange((v: string) => {
              this.reason = v;
            })

          // 发票附件
          Row() {
            Text('发票附件')
              .fontSize(16)
              .fontColor($r('app.color.common_color_1'))
              .margin({ left: 15 })
            Text(this.receiptCount + ' 张')
              .fontSize(16)
              .fontColor($r('app.color.common_color_3'))
              .layoutWeight(1)
              .textAlign(TextAlign.End)
              .margin({ right: 8 })
            Image($r('app.media.arrow_right2'))
              .width(14)
              .height(14)
              .margin({ right: 15 })
          }
          .width('100%')
          .height(48)
          .alignItems(VerticalAlign.Center)
          .backgroundColor($r('app.color.white'))
          .margin({ top: 12 })
          .onClick(() => {
            this.receiptCount = (this.receiptCount + 1) % 4;
          })

          Blank()
            .height(30)
        }
        .width('100%')
      }
      .width('100%')
      .layoutWeight(1)
      .backgroundColor($r('app.color.common_color_6'))

      // 提交
      Text('提交报销')
        .fontSize(17)
        .fontColor($r('app.color.white'))
        .width('100%')
        .height(48)
        .textAlign(TextAlign.Center)
        .backgroundColor($r('app.color.blue_default'))
        .onClick(() => {
          if (this.amount === '') {
            this.getUIContext().getPromptAction().showToast({ message: '请输入报销金额' });
            return;
          }
          this.getUIContext().getPromptAction().showToast({ message: '报销单已提交，等待审批' });
        })
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.common_color_6'))
  }
}
