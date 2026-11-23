import { window } from '@kit.ArkUI';
import { common } from '@kit.AbilityKit';
import { preferences } from '@kit.ArkData';
import { BusinessError } from '@kit.BasicServicesKit';
import { PreferencesUtil } from '../data/PreferencesUtil';
import { LoginSession } from '../network/LoginSession';

export interface PrivacyApplyResult {
  applied: boolean;
  privacyMode: boolean;
  activeCount: number;
  message: string;
}

const PRIVACY_PREF_FILE: string = 'sdmu_privacy_prefs';
const SENSITIVE_PAGES: string[] = [
  'LoginPage',
  'PhoneLoginPage',
  'GesturePwdVerifyPage',
  'GesturePwdSettingPage',
  'ModifyPasswordPage',
  'PersonalDetailPage',
  'ReceiptDetailPage'
];

/**
 * 隐私防截屏/录屏窗口保护助手（基于 window.setWindowPrivacyMode）
 * - 支持 PreferencesUtil('privacy_window_enabled') + AppStorage 同步 + 独立隐私首选项备份（不受退出登录 clear() 影响）
 * - 通过 activePages 引用计数与串行队列防止敏感页间切换时的状态竞态
 */
export class PrivacyWindowHelper {
  public static readonly KEY_PRIVACY_WINDOW: string = 'privacy_window_enabled';
  public static readonly DEFAULT_PRIVACY_ENABLED: boolean = true;

  private static mainWindow: window.Window | null = null;
  private static activePages: Set<string> = new Set<string>();
  private static cachedEnabled: boolean | null = null;
  private static applyQueue: Promise<PrivacyApplyResult> = Promise.resolve<PrivacyApplyResult>({
    applied: false,
    privacyMode: false,
    activeCount: 0,
    message: ''
  });

  /** 纯函数：根据开关状态与当前活跃敏感页数量计算目标隐私模式 */
  public static computeTargetPrivacyMode(featureEnabled: boolean, activeSensitiveCount: number): boolean {
    return featureEnabled && activeSensitiveCount > 0;
  }

  /** 纯函数：判断页面名是否属于受保护敏感页面 */
  public static isSensitivePageName(pageName: string): boolean {
    return SENSITIVE_PAGES.indexOf((pageName || '').trim()) >= 0;
  }

  /** 纯函数：规范化持久化读取到的布尔标识 */
  public static normalizePrivacyFlag(
    raw: boolean | string | number | undefined | null,
    defaultValue: boolean = PrivacyWindowHelper.DEFAULT_PRIVACY_ENABLED
  ): boolean {
    if (typeof raw === 'boolean') {
      return raw;
    }
    if (typeof raw === 'number') {
      return raw !== 0;
    }
    if (typeof raw === 'string') {
      const lower: string = raw.trim().toLowerCase();
      if (lower === 'true' || lower === '1') {
        return true;
      }
      if (lower === 'false' || lower === '0') {
        return false;
      }
    }
    return defaultValue;
  }

  /** 绑定主窗口实例（由 EntryAbility.onWindowStageCreate 调用） */
  public static attachMainWindow(win: window.Window): void {
    PrivacyWindowHelper.mainWindow = win;
  }

  /** 解绑主窗口实例（由 EntryAbility.onWindowStageDestroy 调用） */
  public static detachMainWindow(): void {
    PrivacyWindowHelper.mainWindow = null;
    PrivacyWindowHelper.activePages.clear();
  }

  public static getActivePageCount(): number {
    return PrivacyWindowHelper.activePages.size;
  }

  /** 仅用于测试重置状态 */
  public static resetStateForTest(initialEnabled: boolean | null = null): void {
    PrivacyWindowHelper.activePages.clear();
    PrivacyWindowHelper.mainWindow = null;
    PrivacyWindowHelper.cachedEnabled = initialEnabled;
  }

  private static resolveContext(ctx?: common.BaseContext): common.BaseContext | null {
    if (ctx) {
      return ctx;
    }
    return LoginSession.uiContext;
  }

  private static syncAppStorage(enabled: boolean): void {
    try {
      AppStorage.setOrCreate<boolean>(PrivacyWindowHelper.KEY_PRIVACY_WINDOW, enabled);
    } catch {
      // 单元测试无 ArkUI AppStorage 环境时安全忽略
    }
  }

  /** 读取防截屏保护开关状态 */
  public static async isEnabled(ctx?: common.BaseContext): Promise<boolean> {
    if (PrivacyWindowHelper.cachedEnabled !== null) {
      return PrivacyWindowHelper.cachedEnabled;
    }
    const resolvedCtx = PrivacyWindowHelper.resolveContext(ctx);
    let enabled: boolean = PrivacyWindowHelper.DEFAULT_PRIVACY_ENABLED;
    let foundInBackup: boolean = false;

    if (resolvedCtx) {
      try {
        const store = preferences.getPreferencesSync(resolvedCtx, { name: PRIVACY_PREF_FILE });
        if (store.hasSync(PrivacyWindowHelper.KEY_PRIVACY_WINDOW)) {
          const raw = store.getSync(
            PrivacyWindowHelper.KEY_PRIVACY_WINDOW,
            PrivacyWindowHelper.DEFAULT_PRIVACY_ENABLED
          );
          enabled = PrivacyWindowHelper.normalizePrivacyFlag(raw as boolean | string | number);
          foundInBackup = true;
        }
      } catch {
        // 忽略备份库读取失败
      }
    }

    if (!foundInBackup) {
      try {
        const prefVal: boolean = await PreferencesUtil.getBoolean(
          PrivacyWindowHelper.KEY_PRIVACY_WINDOW,
          PrivacyWindowHelper.DEFAULT_PRIVACY_ENABLED
        );
        enabled = PrivacyWindowHelper.normalizePrivacyFlag(prefVal);
      } catch {
        enabled = PrivacyWindowHelper.DEFAULT_PRIVACY_ENABLED;
      }
    } else {
      await PreferencesUtil.putBoolean(PrivacyWindowHelper.KEY_PRIVACY_WINDOW, enabled);
    }

    PrivacyWindowHelper.cachedEnabled = enabled;
    PrivacyWindowHelper.syncAppStorage(enabled);
    return enabled;
  }

  /** 更新防截屏保护开关状态并立即应用到当前窗口 */
  public static async setEnabled(
    enabled: boolean,
    ctx?: common.BaseContext
  ): Promise<PrivacyApplyResult> {
    const normalized: boolean = Boolean(enabled);
    PrivacyWindowHelper.cachedEnabled = normalized;
    PrivacyWindowHelper.syncAppStorage(normalized);

    const resolvedCtx = PrivacyWindowHelper.resolveContext(ctx);
    if (resolvedCtx) {
      try {
        const store = preferences.getPreferencesSync(resolvedCtx, { name: PRIVACY_PREF_FILE });
        store.putSync(PrivacyWindowHelper.KEY_PRIVACY_WINDOW, normalized);
        store.flushSync();
      } catch {
        // 忽略备份库写入异常
      }
    }
    await PreferencesUtil.putBoolean(PrivacyWindowHelper.KEY_PRIVACY_WINDOW, normalized);
    return await PrivacyWindowHelper.applyPrivacyMode(ctx);
  }

  /** 进入敏感页：登记页面名并开启（若开关允许）防截屏模式 */
  public static async enterSensitivePage(
    pageName: string,
    ctx?: common.BaseContext
  ): Promise<PrivacyApplyResult> {
    if (pageName && pageName !== '') {
      PrivacyWindowHelper.activePages.add(pageName);
    }
    return await PrivacyWindowHelper.applyPrivacyMode(ctx);
  }

  /** 离开敏感页：注销页面名，仅当无其他活跃敏感页时解除防截屏模式 */
  public static async leaveSensitivePage(
    pageName: string,
    ctx?: common.BaseContext
  ): Promise<PrivacyApplyResult> {
    if (pageName && pageName !== '') {
      PrivacyWindowHelper.activePages.delete(pageName);
    }
    return await PrivacyWindowHelper.applyPrivacyMode(ctx);
  }

  /** 串行化应用目标隐私模式到当前窗口 */
  public static applyPrivacyMode(ctx?: common.BaseContext): Promise<PrivacyApplyResult> {
    const task = PrivacyWindowHelper.applyQueue.then(async (): Promise<PrivacyApplyResult> => {
      const enabled: boolean = await PrivacyWindowHelper.isEnabled(ctx);
      const activeCount: number = PrivacyWindowHelper.activePages.size;
      const targetMode: boolean = PrivacyWindowHelper.computeTargetPrivacyMode(enabled, activeCount);

      let targetWin: window.Window | null = PrivacyWindowHelper.mainWindow;
      const resolvedCtx = PrivacyWindowHelper.resolveContext(ctx);
      if (targetWin === null && resolvedCtx !== null) {
        try {
          targetWin = await window.getLastWindow(resolvedCtx);
        } catch {
          targetWin = null;
        }
      }

      if (targetWin === null) {
        return {
          applied: false,
          privacyMode: targetMode,
          activeCount: activeCount,
          message: '当前无可用窗口上下文'
        };
      }

      try {
        await targetWin.setWindowPrivacyMode(targetMode);
        return {
          applied: true,
          privacyMode: targetMode,
          activeCount: activeCount,
          message: targetMode ? '已开启防截屏隐私保护' : '已关闭防截屏隐私保护'
        };
      } catch (err) {
        const be = err as BusinessError;
        const code: number = be.code ?? -1;
        return {
          applied: false,
          privacyMode: targetMode,
          activeCount: activeCount,
          message: code === 201 ? '缺少隐私窗口权限' : '当前设备暂不支持隐私窗口模式'
        };
      }
    });
    const errResult: PrivacyApplyResult = {
      applied: false,
      privacyMode: false,
      activeCount: PrivacyWindowHelper.activePages.size,
      message: '隐私模式应用异常'
    };
    PrivacyWindowHelper.applyQueue = task.catch((): PrivacyApplyResult => errResult);
    return task;
  }
}
