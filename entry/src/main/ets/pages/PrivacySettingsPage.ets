/**
 * 隐私设置页 — 1:1 复刻 activity_privacy_settings_ex.xml + privacy_setting_item.xml
 * + common_ios_toggle_btn.xml（px_to_dip_N = N/2 vp, px_to_sp_N = N/2 fp）：
 * - my_fragment_linear：竖向、背景 common_color_6(#F2F2F2)、fill 尺寸；
 * - include toolbar_normal（复用 TitleBar 组件，标题"隐私设置"）；
 * - layoutPrivacy 白底分组：隐私开关条目；
 * - layoutFindOne 白底分组、marginTop 12dip(=12vp)：查找手机条目；
 * - 条目结构：行 padH px_to_dip_30(=15vp)、padV px_to_dip_16(=8vp)、center_vertical；
 *   名称 TextSize2.Color2(17fp #555555)、提示 TextSize3.Color3(16fp #999999) end 对齐权重 1；
 * - IOSToggleButton：宽 52dip(=52vp)、边框 2px(=1vp) #E7E7E7、
 *   offColor/divider_grey、onColor/ybg_blue(#18B4ED)、spot 白色。
 */
import { TitleBar } from '../components/TitleBar';

@Component
struct IosToggleBtn {
  @Prop switchOn: boolean = false;
  onToggle: (nextVal: boolean) => void = (nextVal: boolean) => {};

  build() {
    Row() {
      Circle()
        .width(26)
        .height(26)
        .fill($r('app.color.ybg_white'))
        .border({ width: 1, color: $r('app.color.common_color_5') })
    }
    .width(52)
    .height(32)
    .borderRadius(16)
    .padding(2)
    .justifyContent(this.switchOn ? FlexAlign.End : FlexAlign.Start)
    .backgroundColor(this.switchOn ? $r('app.color.ybg_blue') : $r('app.color.common_color_5'))
    .border({ width: 1, color: $r('app.color.common_color_5') })
    .onClick(() => {
      this.onToggle(!this.switchOn);
    })
  }
}

@Entry
@Component
struct PrivacySettingsPage {
  @State hideScoreFlag: boolean = false;
  @State hideScheduleFlag: boolean = false;
  @State hideContactFlag: boolean = false;
  @State findPhoneFlag: boolean = true;

  build() {
    Column() {
      // include toolbar_normal
      TitleBar({ title: '隐私设置', showBack: true })

      Column() {
        // layoutPrivacy：隐私条目分组（白底）
        Column() {
          Row() {
            Text('隐藏我的成绩')
              .fontSize(17)
              .fontColor($r('app.color.common_color_2'))
            Text('开启后其他用户不可见')
              .fontSize(16)
              .fontColor($r('app.color.common_color_3'))
              .textAlign(TextAlign.End)
              .layoutWeight(1)
              .margin({ right: 8 })
            IosToggleBtn({
              switchOn: this.hideScoreFlag,
              onToggle: (nextVal: boolean) => {
                this.hideScoreFlag = nextVal;
              }
            })
          }
          .width('100%')
          .padding({ left: 15, right: 15, top: 8, bottom: 8 })
          .alignItems(VerticalAlign.Center)

          Row() {
            Text('隐藏我的课表')
              .fontSize(17)
              .fontColor($r('app.color.common_color_2'))
            Text('开启后其他用户不可见')
              .fontSize(16)
              .fontColor($r('app.color.common_color_3'))
              .textAlign(TextAlign.End)
              .layoutWeight(1)
              .margin({ right: 8 })
            IosToggleBtn({
              switchOn: this.hideScheduleFlag,
              onToggle: (nextVal: boolean) => {
                this.hideScheduleFlag = nextVal;
              }
            })
          }
          .width('100%')
          .padding({ left: 15, right: 15, top: 8, bottom: 8 })
          .alignItems(VerticalAlign.Center)

          Row() {
            Text('隐藏我的联系方式')
              .fontSize(17)
              .fontColor($r('app.color.common_color_2'))
            Text('开启后其他用户不可见')
              .fontSize(16)
              .fontColor($r('app.color.common_color_3'))
              .textAlign(TextAlign.End)
              .layoutWeight(1)
              .margin({ right: 8 })
            IosToggleBtn({
              switchOn: this.hideContactFlag,
              onToggle: (nextVal: boolean) => {
                this.hideContactFlag = nextVal;
              }
            })
          }
          .width('100%')
          .padding({ left: 15, right: 15, top: 8, bottom: 8 })
          .alignItems(VerticalAlign.Center)
        }
        .width('100%')
        .backgroundColor($r('app.color.white'))

        // layoutFindOne：查找手机分组（白底、marginTop 12vp）
        Column() {
          Row() {
            Text('查找手机')
              .fontSize(17)
              .fontColor($r('app.color.common_color_2'))
            Text('开启后可远程定位设备位置')
              .fontSize(16)
              .fontColor($r('app.color.common_color_3'))
              .textAlign(TextAlign.End)
              .layoutWeight(1)
              .margin({ right: 8 })
            IosToggleBtn({
              switchOn: this.findPhoneFlag,
              onToggle: (nextVal: boolean) => {
                this.findPhoneFlag = nextVal;
              }
            })
          }
          .width('100%')
          .padding({ left: 15, right: 15, top: 8, bottom: 8 })
          .alignItems(VerticalAlign.Center)
        }
        .width('100%')
        .backgroundColor($r('app.color.white'))
        .margin({ top: 12 })
      }
      .width('100%')
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.common_color_6'))
  }
}
