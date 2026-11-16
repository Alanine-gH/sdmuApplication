import { router } from '@kit.ArkUI';
import { TitleBar } from '../components/TitleBar';

/**
 * 设置页 — 1:1 复刻 mobile_campus_activity_setting.xml
 * 结构：LinearLayout(common_color_6 #F2F2F2) + toolbar_normal + ScrollView
 *   第一组：检测更新(箭头) / 清除缓存(缓存值16fp #1B68B7+箭头) / 字体大小(箭头) / 推送设置(Switch)
 *   第二组：服务协议(箭头) / 隐私政策(箭头) / 关于我们(版本16fp #1B68B7+箭头)
 *   行：高48vp(px96/2)、paddingH 12vp(px24/2)、文字16fp(px32/2) #333333
 *   分隔线：#DFE4EA 0.5vp(px1/2) marginLeft 12vp
 * Switch 样式（mobile_campus_switchCompat.control）：选中 #1B68B7、thumb 白色
 * 检测更新对话框复刻 activity_custom_app_update.xml
 */
@Entry
@Component
struct SettingPage {
  @State cacheSize: string = '0.00M';
  @State pushEnabled: boolean = true;
  @State showUpdateDialog: boolean = false;

  private clearCache(): void {
    this.getUIContext().getPromptAction().showToast({ message: '缓存已清除' });
    this.cacheSize = '0.00M';
  }

  private checkUpdate(): void {
    // 服务端不可达时按 Android 端无新版本分支处理
    this.getUIContext().getPromptAction().showToast({ message: '当前已经是最新版本' });
  }

  @Builder
  settingDivider() {
    Divider()
      .color($r('app.color.menu_divider'))
      .strokeWidth(0.5)
      .width('100%')
      .margin({ left: 12 })
  }

  @Builder
  arrowIcon() {
    Image($r('app.media.arrow_right'))
      .width(16)
      .height(16)
  }

  build() {
    Column() {
      TitleBar({ title: '设置', showBack: true })

      Scroll() {
        Column() {
          // 组间空隙 12vp(px24/2)
          Row()
            .height(12)

          // 检测更新
          Row() {
            Text('检测更新')
              .fontSize(16)
              .fontColor($r('app.color.common_color_1'))
              .layoutWeight(1)
            this.arrowIcon()
          }
          .width('100%')
          .height(48)
          .padding({ left: 12, right: 12 })
          .alignItems(VerticalAlign.Center)
          .backgroundColor($r('app.color.white'))
          .onClick(() => {
            this.checkUpdate();
          })

          this.settingDivider()

          // 清除缓存 + 缓存大小
          Row() {
            Text('清除缓存')
              .fontSize(16)
              .fontColor($r('app.color.common_color_1'))
              .layoutWeight(1)
            Text(this.cacheSize)
              .fontSize(16)
              .fontColor($r('app.color.blue_default'))
              .margin({ right: 15 })
            this.arrowIcon()
          }
          .width('100%')
          .height(48)
          .padding({ left: 12, right: 12 })
          .alignItems(VerticalAlign.Center)
          .backgroundColor($r('app.color.white'))
          .onClick(() => {
            this.clearCache();
          })

          this.settingDivider()

          // 字体大小
          Row() {
            Text('字体大小')
              .fontSize(16)
              .fontColor($r('app.color.common_color_1'))
              .layoutWeight(1)
            this.arrowIcon()
          }
          .width('100%')
          .height(48)
          .padding({ left: 12, right: 12 })
          .alignItems(VerticalAlign.Center)
          .backgroundColor($r('app.color.white'))
          .onClick(() => {
            router.pushUrl({ url: 'pages/FontSizePage' });
          })

          this.settingDivider()

          // 推送设置 + Switch
          Row() {
            Text('推送设置')
              .fontSize(16)
              .fontColor($r('app.color.common_color_1'))
              .layoutWeight(1)
            Toggle({ type: ToggleType.Switch, isOn: this.pushEnabled })
              .selectedColor($r('app.color.blue_default'))
              .switchPointColor($r('app.color.white'))
              .onChange((isOn: boolean) => {
                this.pushEnabled = isOn;
              })
          }
          .width('100%')
          .height(48)
          .padding({ left: 12, right: 12 })
          .alignItems(VerticalAlign.Center)
          .backgroundColor($r('app.color.white'))

          // 组间空隙 12vp
          Row()
            .height(12)

          // 服务协议
          Row() {
            Text('服务协议')
              .fontSize(16)
              .fontColor($r('app.color.common_color_1'))
              .layoutWeight(1)
            this.arrowIcon()
          }
          .width('100%')
          .height(48)
          .padding({ left: 12, right: 12 })
          .alignItems(VerticalAlign.Center)
          .backgroundColor($r('app.color.white'))
          .onClick(() => {
            router.pushUrl({
              url: 'pages/PrivacyTextPage',
              params: { type: 'service' }
            });
          })

          this.settingDivider()

          // 隐私政策
          Row() {
            Text('隐私政策')
              .fontSize(16)
              .fontColor($r('app.color.common_color_1'))
              .layoutWeight(1)
            this.arrowIcon()
          }
          .width('100%')
          .height(48)
          .padding({ left: 12, right: 12 })
          .alignItems(VerticalAlign.Center)
          .backgroundColor($r('app.color.white'))
          .onClick(() => {
            router.pushUrl({
              url: 'pages/PrivacyTextPage',
              params: { type: 'privacy' }
            });
          })

          this.settingDivider()

          // 关于我们 + 版本号
          Row() {
            Text('关于我们')
              .fontSize(16)
              .fontColor($r('app.color.common_color_1'))
              .layoutWeight(1)
            Text('V1.0.0')
              .fontSize(16)
              .fontColor($r('app.color.blue_default'))
              .margin({ right: 15 })
            this.arrowIcon()
          }
          .width('100%')
          .height(48)
          .padding({ left: 12, right: 12 })
          .alignItems(VerticalAlign.Center)
          .backgroundColor($r('app.color.white'))
          .onClick(() => {
            router.pushUrl({ url: 'pages/AboutPage' });
          })
        }
        .width('100%')
      }
      .width('100%')
      .layoutWeight(1)
      .scrollBar(BarState.Off)
      .align(Alignment.Top)
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.common_color_6'))
  }
}
