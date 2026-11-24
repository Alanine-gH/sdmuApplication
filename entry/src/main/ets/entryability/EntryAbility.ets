import { AbilityConstant, ConfigurationConstant, UIAbility, Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { window, UIContext, uiObserver } from '@kit.ArkUI';
import { BusinessError } from '@kit.BasicServicesKit';
import { PreferencesUtil } from '../data/PreferencesUtil';
import { LoginSession } from '../network/LoginSession';
import { BreakpointSystem } from '../common/BreakpointSystem';
import { PrivacyWindowHelper } from '../common/PrivacyWindowHelper';
import {
  PerformanceSchedulerHelper,
  FAST_SCENE_APP_LAUNCH,
  FAST_DURATION_SHORT
} from '../common/PerformanceSchedulerHelper';
import { HoldingHandHelper } from '../common/HoldingHandHelper';

const DOMAIN = 0x0000;

export default class EntryAbility extends UIAbility {
  private mainWindow: window.Window | null = null;
  private mainUIContext: UIContext | null = null;
  private windowSizeCb: ((size: window.Size) => void) | null = null;
  private avoidAreaCb: ((options: window.AvoidAreaOptions) => void) | null = null;
  private keyboardHeightCb: ((heightPx: number) => void) | null = null;
  private layoutBreakpointCb: ((info: uiObserver.WindowSizeLayoutBreakpointInfo) => void) | null = null;

  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onCreate');
    PerformanceSchedulerHelper.reportSceneBegin(FAST_SCENE_APP_LAUNCH, FAST_DURATION_SHORT);
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

  private registerWindowListeners(win: window.Window): void {
    this.mainWindow = win;
    PrivacyWindowHelper.attachMainWindow(win);

    try {
      const rect = win.getWindowProperties().windowRect;
      BreakpointSystem.updateFromPx(rect.width, rect.height, this.mainUIContext ?? undefined);
      BreakpointSystem.updateAvoidAreas(win, this.mainUIContext ?? undefined);
      BreakpointSystem.registerFoldListener();
    } catch (err) {
      hilog.error(DOMAIN, 'testTag', 'Initial window metrics failed: %{public}s', JSON.stringify(err));
    }

    if (this.windowSizeCb === null) {
      this.windowSizeCb = (size: window.Size): void => {
        BreakpointSystem.updateFromPx(size.width, size.height, this.mainUIContext ?? undefined);
        if (this.mainWindow !== null) {
          BreakpointSystem.updateAvoidAreas(this.mainWindow, this.mainUIContext ?? undefined);
        }
      };
      try {
        win.on('windowSizeChange', this.windowSizeCb);
      } catch {
        this.windowSizeCb = null;
      }
    }

    if (this.avoidAreaCb === null) {
      this.avoidAreaCb = (_options: window.AvoidAreaOptions): void => {
        if (this.mainWindow !== null) {
          BreakpointSystem.updateAvoidAreas(this.mainWindow, this.mainUIContext ?? undefined);
        }
      };
      try {
        win.on('avoidAreaChange', this.avoidAreaCb);
      } catch {
        this.avoidAreaCb = null;
      }
    }

    if (this.keyboardHeightCb === null) {
      this.keyboardHeightCb = (heightPx: number): void => {
        BreakpointSystem.updateKeyboardHeightPx(heightPx, this.mainUIContext ?? undefined);
      };
      try {
        win.on('keyboardHeightChange', this.keyboardHeightCb);
      } catch {
        this.keyboardHeightCb = null;
      }
    }
  }

  private registerLayoutBreakpointObserver(win: window.Window): void {
    try {
      const uiCtx: UIContext = win.getUIContext();
      this.mainUIContext = uiCtx;
      const rect = win.getWindowProperties().windowRect;
      BreakpointSystem.updateFromPx(rect.width, rect.height, uiCtx);
      BreakpointSystem.updateAvoidAreas(win, uiCtx);

      if (this.layoutBreakpointCb === null) {
        this.layoutBreakpointCb = (info: uiObserver.WindowSizeLayoutBreakpointInfo): void => {
          BreakpointSystem.updateFromLayoutBreakpoint(info.widthBreakpoint, info.heightBreakpoint);
        };
        uiCtx.getUIObserver().on('windowSizeLayoutBreakpointChange', this.layoutBreakpointCb);
      }
    } catch (err) {
      hilog.info(DOMAIN, 'testTag', 'registerLayoutBreakpointObserver fallback: %{public}s', JSON.stringify(err));
    }
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    // Main window is created, set main page for this ability
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onWindowStageCreate');

    PreferencesUtil.init(this.context)
      .then(() => {
        PrivacyWindowHelper.isEnabled(this.context);
      })
      .catch((error: BusinessError) => {
        hilog.error(DOMAIN, 'testTag', 'Preferences init failed: %{public}s', JSON.stringify(error));
      });

    // [tablet-adapt] 注册窗口尺寸/避让区/键盘/折叠态监听
    windowStage.getMainWindow((err: BusinessError, win: window.Window) => {
      if (err.code) {
        hilog.error(DOMAIN, 'testTag', 'getMainWindow failed: %{public}s', JSON.stringify(err));
        return;
      }
      this.registerWindowListeners(win);
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
      PerformanceSchedulerHelper.reportSceneEnd(FAST_SCENE_APP_LAUNCH, FAST_DURATION_SHORT);
      HoldingHandHelper.subscribeHoldingHandChanged();
      if (this.mainWindow !== null) {
        this.registerLayoutBreakpointObserver(this.mainWindow);
      } else {
        try {
          const syncWin: window.Window = windowStage.getMainWindowSync();
          this.registerWindowListeners(syncWin);
          this.registerLayoutBreakpointObserver(syncWin);
        } catch {
          // 忽略获取主窗异常
        }
      }
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
    if (this.mainWindow !== null) {
      try {
        if (this.windowSizeCb !== null) {
          this.mainWindow.off('windowSizeChange', this.windowSizeCb);
        }
        if (this.avoidAreaCb !== null) {
          this.mainWindow.off('avoidAreaChange', this.avoidAreaCb);
        }
        if (this.keyboardHeightCb !== null) {
          this.mainWindow.off('keyboardHeightChange', this.keyboardHeightCb);
        }
      } catch {
        // 忽略窗口已销毁时注销异常
      }
    }
    if (this.mainUIContext !== null && this.layoutBreakpointCb !== null) {
      try {
        this.mainUIContext.getUIObserver().off('windowSizeLayoutBreakpointChange', this.layoutBreakpointCb);
      } catch {
        // 忽略 UIContext 销毁异常
      }
    }
    this.windowSizeCb = null;
    this.avoidAreaCb = null;
    this.keyboardHeightCb = null;
    this.layoutBreakpointCb = null;
    this.mainUIContext = null;
    this.mainWindow = null;
    BreakpointSystem.unregisterFoldListener();
    HoldingHandHelper.unsubscribeHoldingHandChanged();
    PrivacyWindowHelper.detachMainWindow();
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
