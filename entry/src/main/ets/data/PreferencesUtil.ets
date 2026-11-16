import { preferences } from '@kit.ArkData';
import { Context } from '@kit.AbilityKit';
import { Constants } from './Constants';

/**
 * 轻量数据持久化封装：基于 @kit.ArkData 的 preferences 模块。
 * 需在 EntryAbility.onWindowStageCreate 中调用 init 完成初始化。
 */
export class PreferencesUtil {
  private static store: preferences.Preferences | null = null;

  static async init(context: Context): Promise<void> {
    if (PreferencesUtil.store === null) {
      PreferencesUtil.store = await preferences.getPreferences(context, Constants.PREF_NAME);
    }
  }

  static async putString(key: string, value: string): Promise<void> {
    if (PreferencesUtil.store === null) {
      return;
    }
    await PreferencesUtil.store.put(key, value);
    await PreferencesUtil.store.flush();
  }

  static async getString(key: string, defValue: string): Promise<string> {
    if (PreferencesUtil.store === null) {
      return defValue;
    }
    const value: preferences.ValueType = await PreferencesUtil.store.get(key, defValue);
    return value as string;
  }

  static async putBoolean(key: string, value: boolean): Promise<void> {
    if (PreferencesUtil.store === null) {
      return;
    }
    await PreferencesUtil.store.put(key, value);
    await PreferencesUtil.store.flush();
  }

  static async getBoolean(key: string, defValue: boolean): Promise<boolean> {
    if (PreferencesUtil.store === null) {
      return defValue;
    }
    const value: preferences.ValueType = await PreferencesUtil.store.get(key, defValue);
    return value as boolean;
  }

  static async delete(key: string): Promise<void> {
    if (PreferencesUtil.store === null) {
      return;
    }
    await PreferencesUtil.store.delete(key);
    await PreferencesUtil.store.flush();
  }

  static async clear(): Promise<void> {
    if (PreferencesUtil.store === null) {
      return;
    }
    await PreferencesUtil.store.clear();
    await PreferencesUtil.store.flush();
  }
}
