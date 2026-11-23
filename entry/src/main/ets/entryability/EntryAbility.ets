import { AbilityConstant, ConfigurationConstant, UIAbility, Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { window, display } from '@kit.ArkUI';
import { BusinessError } from '@kit.BasicServicesKit';
import { PreferencesUtil } from '../data/PreferencesUtil';
import { LoginSession } from '../network/LoginSession';
import { BreakpointSystem } from '../common/BreakpointSystem';

const DOMAIN = 0x0000;

export default class EntryAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onCreate');
    // 注入UIAbility上下文供会话持久化使用
    LoginSession.uiContext = this.context;
    this.handleWidgetWant(want);
  }

  onNewWant(want: Want, _launchParam: AbilityConstant.LaunchParam): void {
    this.handleWidgetWant(want);
  }

  /** 接收桌面服务卡片 postCardAction 路由参数 */
  private handleWidgetWant(want: Want): void {
    if (!want.parameters) {
      return;
    }
    const targetPage = want.parameters['targetPage'];
    if (typeof targetPage === 'string' && targetPage !== '') {
      AppStorage.setOrCreate<string>('pendingWidgetPage', targetPage);
      const yyid = want.parameters['yyid'];
      const title = want.parameters['title'];
      AppStorage.setOrCreate<string>('pendingWidgetYyid', typeof yyid === 'string' ? yyid : '');
      AppStorage.setOrCreate<string>('pendingWidgetTitle', typeof title === 'string' ? title : '');
    }
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
      const rect = win.getWindowProperties().windowRect;
      BreakpointSystem.updateFromPx(rect.width, rect.height);
      BreakpointSystem.registerFoldListener();
      win.on('windowSizeChange', (size: window.Size) => {
        BreakpointSystem.updateFromPx(size.width, size.height);
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