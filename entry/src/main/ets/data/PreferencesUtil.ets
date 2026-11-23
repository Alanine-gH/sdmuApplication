import { preferences } from '@kit.ArkData';
import { Context } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { Constants } from './Constants';

const DOMAIN = 0x0000;

/**
 * 轻量数据持久化封装：基于 @kit.ArkData 的 preferences 模块。
 * 需在 EntryAbility.onWindowStageCreate 中调用 init 完成初始化。
 */
export class PreferencesUtil {
  private static store: preferences.Preferences | null = null;

  static async init(context: Context): Promise<void> {
    if (PreferencesUtil.store === null) {
      try {
        PreferencesUtil.store = await preferences.getPreferences(context, Constants.PREF_NAME);
      } catch (err) {
        hilog.error(DOMAIN, 'PreferencesUtil', 'init failed: %{public}s', JSON.stringify(err));
      }
    }
  }

  static async putString(key: string, value: string): Promise<void> {
    if (PreferencesUtil.store === null) {
      return;
    }
    try {
      await PreferencesUtil.store.put(key, value);
      await PreferencesUtil.store.flush();
    } catch (err) {
      hilog.error(DOMAIN, 'PreferencesUtil', 'putString failed: %{public}s', JSON.stringify(err));
    }
  }

  static async getString(key: string, defValue: string): Promise<string> {
    if (PreferencesUtil.store === null) {
      return defValue;
    }
    try {
      const value: preferences.ValueType = await PreferencesUtil.store.get(key, defValue);
      return value as string;
    } catch (err) {
      hilog.error(DOMAIN, 'PreferencesUtil', 'getString failed: %{public}s', JSON.stringify(err));
      return defValue;
    }
  }

  static async putBoolean(key: string, value: boolean): Promise<void> {
    if (PreferencesUtil.store === null) {
      return;
    }
    try {
      await PreferencesUtil.store.put(key, value);
      await PreferencesUtil.store.flush();
    } catch (err) {
      hilog.error(DOMAIN, 'PreferencesUtil', 'putBoolean failed: %{public}s', JSON.stringify(err));
    }
  }

  static async getBoolean(key: string, defValue: boolean): Promise<boolean> {
    if (PreferencesUtil.store === null) {
      return defValue;
    }
    try {
      const value: preferences.ValueType = await PreferencesUtil.store.get(key, defValue);
      return value as boolean;
    } catch (err) {
      hilog.error(DOMAIN, 'PreferencesUtil', 'getBoolean failed: %{public}s', JSON.stringify(err));
      return defValue;
    }
  }

  static async delete(key: string): Promise<void> {
    if (PreferencesUtil.store === null) {
      return;
    }
    try {
      await PreferencesUtil.store.delete(key);
      await PreferencesUtil.store.flush();
    } catch (err) {
      hilog.error(DOMAIN, 'PreferencesUtil', 'delete failed: %{public}s', JSON.stringify(err));
    }
  }

  static async clear(): Promise<void> {
    if (PreferencesUtil.store === null) {
      return;
    }
    try {
      await PreferencesUtil.store.clear();
      await PreferencesUtil.store.flush();
    } catch (err) {
      hilog.error(DOMAIN, 'PreferencesUtil', 'clear failed: %{public}s', JSON.stringify(err));
    }
  }
}
