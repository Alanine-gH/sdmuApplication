import { bundleManager } from '@kit.AbilityKit';
import { BreakpointSystem } from '../common/BreakpointSystem';
import { TitleBar } from '../components/TitleBar';

/**
 * 关于我们页 — 1:1 复刻 AboutUsActivity.java + mobile_campus_about_us.xml
 * 结构：LinearLayout + toolbar_normal（标题"关于我们" T1()）+ 垂直居中列：
 *   - rivImage：RoundedImageView 120dip、marginTop 140dip、src @mipmap/icon、
 *     圆角 28dip(riv_corner_radius)、边框 #E7E7E7 1dip(riv_border_width/color)
 *   - tvAppName：17sp 黑 marginTop 24dip、text @string/app_name
 *   - tvAppVersion：14sp explainColor(#999999) marginTop 4dip
 * 源码行为 f1()：版本文本 = "当前版本号：V" + s.d() + "_" + s.e(context)
 *   - s.d()：versionName 空格→下划线；若含 "_" 取第一个 "_" 之后子串（如 ydxy_3.2.0 → 3.2.0）
 *   - s.e(context)：versionCode（int）
 * 无其它业务逻辑（无网络请求、无点击行为），H0() 返回 "about" 仅用于统计埋点。
 */
@Entry
@Component
struct AboutPage {
  /** tvAppVersion 文本（f1() 拼接结果，aboutToAppear 计算） */
  @State appVersion: string = '';
  @StorageProp('currentBreakpoint') currentBreakpoint: string = 'sm';
  @StorageProp('isCompactHeight') isCompactHeight: boolean = false;
  @StorageProp('avoidAreaBottomVp') avoidAreaBottomVp: number = 0;

  aboutToAppear(): void {
    try {
      const info: bundleManager.BundleInfo =
        bundleManager.getBundleInfoForSelfSync(bundleManager.BundleFlag.GET_BUNDLE_INFO_DEFAULT);
      this.appVersion = '当前版本号：V' + this.versionNameSuffix(info.versionName) + '_' + info.versionCode;
    } catch {
      // 取版本失败保持空文本（与 s.d() 异常返回 "" 一致）
      this.appVersion = '当前版本号：V_' + 0;
    }
  }

  /** 源码 s.d()：versionName 空格→"_"（String.replace 全量替换）；含 "_" 时取第一个 "_" 之后子串，否则原样返回 */
  private versionNameSuffix(versionName: string): string {
    const normalized: string = versionName.replace(/ /g, '_');
    if (normalized === '') {
      return '';
    }
    const idx: number = normalized.indexOf('_');
    if (idx < 0) {
      return normalized;
    }
    return idx + 1 < normalized.length ? normalized.substring(idx + 1) : normalized;
  }

  build() {
    Column() {
      TitleBar({ title: '关于我们', showBack: true })

      // 内层 LinearLayout：gravity=center_horizontal
      Scroll() {
        Column() {
          // rivImage：120dip、marginTop 140dip、圆角 28dip、边框 #E7E7E7 1dip、src @mipmap/icon
          Image($r('app.media.app_icon'))
            .width(120)
            .height(120)
            .borderRadius(28)
            .border({ width: 1, color: '#E7E7E7' })
            .margin({ top: this.isCompactHeight ? 32 : 140 })

          // tvAppName：17sp 黑、marginTop 24dip、@string/app_name
          Text($r('app.string.app_name'))
            .fontSize(17)
            .fontColor($r('app.color.black'))
            .margin({ top: 24 })

          // tvAppVersion：14sp explainColor(#999999)、marginTop 4dip（代码设置版本文本）
          Text(this.appVersion)
            .fontSize(14)
            .fontColor($r('app.color.explain_color'))
            .margin({ top: 4 })
        }
        .width('100%')
        .constraintSize({ maxWidth: BreakpointSystem.getContentMaxWidth(this.currentBreakpoint) })
        .padding({ bottom: Math.max(24, this.avoidAreaBottomVp) })
        .alignItems(HorizontalAlign.Center)
      }
      .width('100%')
      .layoutWeight(1)
      .scrollBar(BarState.Off)
      .align(Alignment.Top)
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.white'))
  }
}
