import { TitleBar } from '../components/TitleBar';

/**
 * 指纹绑定设备页 — 1:1 复刻 mobile_campus_activity_setting_bind_device.xml
 * 结构：LinearLayout(bg common_color_6) + toolbar_normal + ScrollView
 *   - 间隔 12vp(px24÷2)
 *   - 信息行（白底、paddingH 12vp px24÷2）：label 16fp(px32÷2) #555555 宽 50vp、
 *     值 16fp black maxLines 2、行间分隔线 0.5vp marginL 12vp
 *   - 行：账号 / (间隔10vp) / 姓名 / 性别 / 所属部门 / 身份证号 / 手机号 / 手机唯一码
 *   - "绑定设备" 按钮 16fp 白色、bg #1790FF 圆角 22vp(px44÷2)、
 *     paddingTB 6vp(12÷2)、marginH 12vp、marginT 10vp
 */
@Entry
@Component
struct FingerBindDevicePage {
  @State accountText: string = 'sdmu001';
  @State nameText: string = '张三';
  @State genderText: string = '男';
  @State departmentText: string = '信息中心';
  @State idCardText: string = '3702**********1234';
  @State phoneText: string = '138****5678';
  @State androidIdText: string = 'A1B2C3D4E5F6';

  private bindDevice(): void {
    this.getUIContext().getPromptAction().showToast({ message: '绑定设备成功' });
  }

  @Builder
  private infoRow(label: string, infoText: string) {
    Row() {
      Text(label)
        .fontSize(16)
        .fontColor($r('app.color.common_color_2'))
        .width(50)
        .padding({ top: 15, bottom: 15 })

      Text(infoText)
        .fontSize(16)
        .fontColor($r('app.color.black'))
        .maxLines(2)
        .layoutWeight(1)
        .alignSelf(ItemAlign.Center)
    }
    .width('100%')
    .backgroundColor($r('app.color.white'))
    .padding({ left: 12, right: 12 })
    .alignItems(VerticalAlign.Center)
  }

  @Builder
  private rowDivider() {
    Divider()
      .color($r('app.color.common_color_5'))
      .strokeWidth(0.5)
      .width('100%')
      .margin({ left: 12 })
  }

  build() {
    Column() {
      TitleBar({ title: '绑定设备', showBack: true })

      Scroll() {
        Column() {
          Row()
            .width('100%')
            .height(12)

          this.infoRow('账号', this.accountText)

          Row()
            .width('100%')
            .height(10)

          this.infoRow('姓名', this.nameText)
          this.rowDivider()
          this.infoRow('性别', this.genderText)
          this.rowDivider()
          this.infoRow('所属部门', this.departmentText)
          this.rowDivider()
          this.infoRow('身份证号', this.idCardText)
          this.rowDivider()
          this.infoRow('手机号', this.phoneText)
          this.rowDivider()
          this.infoRow('手机唯一码', this.androidIdText)

          Text('绑定设备')
            .fontSize(16)
            .fontColor($r('app.color.white'))
            .textAlign(TextAlign.Center)
            .width('100%')
            .padding({ top: 6, bottom: 6 })
            .borderRadius(22)
            .backgroundColor($r('app.color.finger_blue'))
            .margin({ left: 12, right: 12, top: 10 })
            .onClick(() => {
              this.bindDevice();
            })
        }
        .width('100%')
      }
      .width('100%')
      .height('100%')
      .scrollBar(BarState.Off)
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.common_color_6'))
  }
}
