import { TitleBar } from '../components/TitleBar';

/**
 * 意见反馈页 — 1:1 复刻 mobile_campus_feedback_activity.xml
 * 结构：toolbar_normal + divider + NestedScrollView(#F2F2F2)
 *   1. 白卡（padding 16vp/px32÷2）：内容输入 16fp 黑、hint #999999
 *      "请您输入APP使用过程中遇到的问题或意见"、高 58vp(px116÷2)、maxLines 3、maxLength 300、
 *      下方计数器 n/300
 *   2. 分隔线 common_color_6 1vp
 *   3. 白卡："添加相关问题截图" 16fp 黑 + "0/6" 16fp 黑；截图区 marginTop 16vp
 *   4. divider
 *   5. 白卡（paddingH 16vp、paddingV 14vp/px28÷2）：联系方式输入 17fp(px34÷2)
 *      hint #999999 "请输入您的手机号/QQ" 单行
 *   6. divider
 *   7. tvSubmit 提交按钮：高 44vp(px88÷2)、margin 30vp(px60÷2)、18fp(px36÷2) 白字居中、
 *      背景圆角 10dip：有内容 #97000C / 无内容 #CCCCCC(common_color_24)
 */
@Entry
@Component
struct FeedbackPage {
  @State content: string = '';
  @State contact: string = '';

  build() {
    Column() {
      TitleBar({ title: '意见反馈', showBack: true })

      Scroll() {
        Column() {
          // 卡片1：问题描述
          Column() {
            TextArea({ placeholder: '请您输入APP使用过程中遇到的问题或意见', text: this.content })
              .fontSize(16)
              .fontColor($r('app.color.black'))
              .placeholderColor($r('app.color.common_color_3'))
              .placeholderFont({ size: 16 })
              .height(58)
              .maxLines(3)
              .maxLength(300)
              .backgroundColor(Color.Transparent)
              .padding(0)
              .onChange((value: string) => {
                this.content = value;
              })

            // 计数器 n/300
            Text(this.content.length + '/300')
              .fontSize(12)
              .fontColor($r('app.color.common_color_3'))
              .width('100%')
              .textAlign(TextAlign.End)
              .margin({ top: 4 })
          }
          .width('100%')
          .padding(16)
          .backgroundColor($r('app.color.white'))
          .alignItems(HorizontalAlign.Start)

          // 分隔线 common_color_6 1vp
          Divider()
            .color($r('app.color.common_color_6'))
            .strokeWidth(1)
            .width('100%')

          // 卡片2：问题截图
          Column() {
            Row() {
              Text('添加相关问题截图')
                .fontSize(16)
                .fontColor($r('app.color.black'))
                .layoutWeight(1)
              Text('0/6')
                .fontSize(16)
                .fontColor($r('app.color.black'))
            }
            .width('100%')

            // 截图添加区（无图时的添加入口）
            Row() {
              Text('+')
                .fontSize(24)
                .fontColor($r('app.color.common_color_4'))
                .width(80)
                .height(80)
                .textAlign(TextAlign.Center)
                .borderRadius(2)
                .border({ width: 1, color: $r('app.color.common_color_5') })
            }
            .width('100%')
            .margin({ top: 16 })
          }
          .width('100%')
          .padding(16)
          .backgroundColor($r('app.color.white'))
          .alignItems(HorizontalAlign.Start)

          Divider()
            .color($r('app.color.common_color_5'))
            .strokeWidth(0.5)
            .width('100%')

          // 卡片3：联系方式
          Row() {
            TextInput({ placeholder: '请输入您的手机号/QQ', text: this.contact })
              .fontSize(17)
              .fontColor($r('app.color.black'))
              .placeholderColor($r('app.color.common_color_3'))
              .placeholderFont({ size: 17 })
              .height(44)
              .backgroundColor(Color.Transparent)
              .padding(0)
              .layoutWeight(1)
              .onChange((value: string) => {
                this.contact = value;
              })
          }
          .width('100%')
          .padding({ left: 16, right: 16, top: 14, bottom: 14 })
          .backgroundColor($r('app.color.white'))

          Divider()
            .color($r('app.color.common_color_5'))
            .strokeWidth(0.5)
            .width('100%')

          // tvSubmit 提交按钮
          Text('提交')
            .fontSize(18)
            .fontColor($r('app.color.white'))
            .width('100%')
            .height(44)
            .textAlign(TextAlign.Center)
            .margin({ left: 30, right: 30, top: 30 })
            .borderRadius(10)
            .backgroundColor(this.content.length > 0 ?
              $r('app.color.mobile_campus_primary_color') : $r('app.color.common_color_24'))
            .onClick(() => {
              if (this.content.length === 0) {
                this.getUIContext().getPromptAction().showToast({ message: '请输入反馈内容' });
                return;
              }
              this.getUIContext().getPromptAction().showToast({ message: '提交成功，感谢您的反馈' });
            })
        }
        .width('100%')
      }
      .width('100%')
      .layoutWeight(1)
      .scrollBar(BarState.Off)
      .align(Alignment.Top)
      .backgroundColor($r('app.color.common_color_6'))
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.white'))
  }
}
