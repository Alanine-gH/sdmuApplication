import { AbilityConstant, ConfigurationConstant, UIAbility, Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { window, display } from '@kit.ArkUI';
import { BusinessError } from '@kit.BasicServicesKit';
import { PreferencesUtil } from '../data/PreferencesUtil';
import { LoginSession } from '../network/LoginSession';

const DOMAIN = 0x0000;
/** [tablet-adapt] 宽屏断点（vp）：≥600 视为平板/折叠屏展开态，内容区限宽居中 */
const WIDE_SCREEN_VP = 600;

export default class EntryAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onCreate');
    // 注入UIAbility上下文供会话持久化使用
    LoginSession.uiContext = this.context;
  }

  onDestroy(): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onDestroy');
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    // Main window is created, set main page for this ability
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onWindowStageCreate');

    PreferencesUtil.init(this.context)
      .catch((error: BusinessError) => {
        hilog.error(DOMAIN, 'testTag', 'Preferences init failed: %{public}s', JSON.stringify(error));
      });

    // [tablet-adapt] 注册窗口尺寸监听：宽屏（≥600vp）→ AppStorage 'isWideScreen'，
    // 供 Index 三 Tab 内容区与 TitleBar 断点限宽居中（review_tablet-adapt.md 方案 1）。
    windowStage.getMainWindow((err: BusinessError, win: window.Window) => {
      if (err.code) {
        hilog.error(DOMAIN, 'testTag', 'getMainWindow failed: %{public}s', JSON.stringify(err));
        return;
      }
      this.updateWideScreen(win.getWindowProperties().windowRect.width);
      win.on('windowSizeChange', (size: window.Size) => {
        this.updateWideScreen(size.width);
      });
    });

    // [W22 launch-chain] APK 启动链：LAUNCHER=DispatchActivity（SchoolEntity 初始化 + 清缓存）
    //   → CampusFirstActivity（登录态分流：已登录 → LoginedLaunchActivity；未登录 →
    //   CommonLaunchActivity）→ LoginPage / MainActivity(Index)。
    // HAP 等价：PreferencesUtil.init 承载 Dispatch 初始化，首页载入 CampusFirstPage
    // （DispatchActivity→CampusFirstActivity 链首），分流与跳转链在启动链三页内完成。
    windowStage.loadContent('pages/CampusFirstPage', (err) => {
      if (err.code) {
        hilog.error(DOMAIN, 'testTag', 'Failed to load the content. Cause: %{public}s', JSON.stringify(err));
        return;
      }
      hilog.info(DOMAIN, 'testTag', 'Succeeded in loading the content.');
    });

    try {
      this.context.getApplicationContext().setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET);
    } catch (err) {
      hilog.error(DOMAIN, 'testTag', 'Failed to set colorMode. Cause: %{public}s', JSON.stringify(err));
    }
  }

  /** [tablet-adapt] px→vp 换算后写断点；窄屏恒 false，渲染与旧版完全一致 */
  private updateWideScreen(widthPx: number): void {
    const density: number = display.getDefaultDisplaySync().densityPixels;
    const wide: boolean = density > 0 ? widthPx / density >= WIDE_SCREEN_VP : false;
    AppStorage.setOrCreate<boolean>('isWideScreen', wide);
    hilog.info(DOMAIN, 'testTag', 'windowSizeChange vp=%{public}f wide=%{public}s',
      widthPx / Math.max(density, 1), String(wide));
  }

  onWindowStageDestroy(): void {
    // Main window is destroyed, release UI related resources
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onWindowStageDestroy');
  }

  onForeground(): void {
    // Ability has brought to foreground
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onForeground');
  }

  onBackground(): void {
    // Ability has back to background
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onBackground');
  }
}