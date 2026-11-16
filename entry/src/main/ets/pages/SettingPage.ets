import { TitleBar } from '../components/TitleBar';

/**
 * 设置页：消息通知开关、字体大小、清除缓存、关于我们。
 */
@Entry
@Component
struct SettingPage {
  @State notifyOn: boolean = true;

  @Builder
  settingRow(icon: string, label: string, tipMsg: string) {
    Row() {
      Text(icon)
        .fontSize(18)
        .width(32)
      Text(label)
        .fontSize(15)
        .fontColor($r('app.color.sdmu_text_primary'))
        .layoutWeight(1)
        .margin({ left: 8 })
      Text('＞')
        .fontSize(14)
        .fontColor($r('app.color.sdmu_text_hint'))
    }
    .width('100%')
    .height(52)
    .padding({ left: 16, right: 16 })
    .backgroundColor($r('app.color.sdmu_card_bg'))
    .border({ width: { bottom: 1 }, color: $r('app.color.sdmu_divider') })
    .onClick(() => {
      this.getUIContext().getPromptAction().showToast({ message: tipMsg });
    })
  }

  build() {
    Column() {
      TitleBar({ title: '设置', showBack: true })

      List() {
        ListItem() {
          Row() {
            Text('🔔')
              .fontSize(18)
              .width(32)
            Text('消息通知')
              .fontSize(15)
              .fontColor($r('app.color.sdmu_text_primary'))
              .layoutWeight(1)
              .margin({ left: 8 })
            Toggle({ type: ToggleType.Switch, isOn: this.notifyOn })
              .onChange((isOn: boolean) => {
                this.notifyOn = isOn;
                this.getUIContext().getPromptAction().showToast({
                  message: isOn ? '已开启消息通知' : '已关闭消息通知'
                });
              })
          }
          .width('100%')
          .height(52)
          .padding({ left: 16, right: 16 })
          .backgroundColor($r('app.color.sdmu_card_bg'))
          .border({ width: { bottom: 1 }, color: $r('app.color.sdmu_divider') })
          .onClick(() => {
            this.getUIContext().getPromptAction().showToast({ message: '请使用开关调整消息通知' });
          })
        }
        ListItem() {
          this.settingRow('🔤', '字体大小', '字体大小设置开发中')
        }
        ListItem() {
          this.settingRow('🧹', '清除缓存', '缓存已清除')
        }
        ListItem() {
          this.settingRow('ℹ️', '关于我们', '山东管理学院 v3.2.0')
        }
      }
      .width('100%')
      .layoutWeight(1)
      .backgroundColor($r('app.color.sdmu_card_bg'))
      .margin({ top: 10 })
      .borderRadius(12)
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.sdmu_bg'))
  }
}
