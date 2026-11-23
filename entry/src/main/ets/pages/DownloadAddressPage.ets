import { common } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { BreakpointSystem } from '../common/BreakpointSystem';
import { TitleBar } from '../components/TitleBar';

/**
 * 下载地址页 — 复刻 Android 端 tvDownload("下载地址") 入口
 * Android 端跳转浏览器显示应用下载页；HarmonyOS 端跳转华为应用市场（AppGallery）。
 * 结构：toolbar_normal + 版本卡片 + 下载说明 + 前往应用市场按钮
 */
@Entry
@Component
struct DownloadAddressPage {
  @StorageProp('currentBreakpoint') currentBreakpoint: string = 'sm';
  @StorageProp('avoidAreaBottomVp') avoidAreaBottomVp: number = 0;

  private openAppGallery(): void {
    // 拉起华为应用市场（AppGallery）搜索本应用
    const context = this.getUIContext().getHostContext() as common.UIAbilityContext;
    context.openLink('https://appgallery.huawei.com/search?keyword=%E5%B1%B1%E4%B8%9C%E7%AE%A1%E7%90%86%E5%AD%A6%E9%99%A2')
      .catch((error: BusinessError) => {
        // AppGallery 拉起失败时降级到应用市场首页
        context.openLink('https://appgallery.huawei.com/')
          .catch((err: BusinessError) => {
            this.getUIContext().getPromptAction().showToast({ message: '无法打开应用市场，请检查设备' });
          });
      });
  }

  build() {
    Column() {
      TitleBar({ title: '下载地址', showBack: true })

      Scroll() {
        Column() {
          // 应用图标 + 名称 + 版本
          Column() {
            Image($r('app.media.app_icon'))
              .width(80)
              .height(80)
              .borderRadius(16)
              .margin({ top: 40 })

            Text($r('app.string.app_name'))
              .fontSize(17)
              .fontColor($r('app.color.black'))
              .margin({ top: 16 })

            Text('V1.0.0')
              .fontSize(14)
              .fontColor($r('app.color.explain_color'))
              .margin({ top: 4 })
          }
          .width('100%')
          .alignItems(HorizontalAlign.Center)

          // 下载说明卡片
          Column() {
            Text('官方下载渠道')
              .fontSize(16)
              .fontColor($r('app.color.common_color_1'))
              .margin({ bottom: 8 })

            Text('请通过华为应用市场下载本应用，谨防非官方渠道的安全风险。')
              .fontSize(14)
              .fontColor($r('app.color.common_color_3'))
              .lineHeight(22)
          }
          .width('100%')
          .padding(16)
          .borderRadius(8)
          .backgroundColor($r('app.color.white'))
          .margin({ top: 24 })
          .alignItems(HorizontalAlign.Start)

          // 前往应用市场按钮：#97000C 圆角 10vp，拉起华为应用市场
          Text('前往华为应用市场')
            .fontSize(18)
            .fontColor($r('app.color.white'))
            .width('100%')
            .height(44)
            .textAlign(TextAlign.Center)
            .borderRadius(10)
            .backgroundColor($r('app.color.mobile_campus_primary_color'))
            .margin({ top: 30 })
            .onClick(() => {
              this.openAppGallery();
            })
        }
        .width('100%')
        .constraintSize({ maxWidth: BreakpointSystem.getContentMaxWidth(this.currentBreakpoint) })
        .padding({ left: 12, right: 12, bottom: Math.max(24, this.avoidAreaBottomVp) })
      }
      .width('100%')
      .layoutWeight(1)
      .scrollBar(BarState.Off)
      .align(Alignment.Top)
      .backgroundColor($r('app.color.common_color_6'))
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.common_color_6'))
  }
}
