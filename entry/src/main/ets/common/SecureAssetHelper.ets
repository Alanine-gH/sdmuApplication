import { asset } from '@kit.AssetStoreKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { PreferencesUtil } from '../data/PreferencesUtil';

export interface AssetOpResult {
  success: boolean;
  storedInTee: boolean;
  fallbackUsed: boolean;
  message: string;
}

export interface LoginSecretBundle {
  aesKey: string;
  onlyCode: string;
  sessionKey: string;
}

const MAX_ASSET_SECRET_BYTES: number = 1024;

/**
 * 硬件级关键资产安全存储助手（基于 @kit.AssetStoreKit）
 * - R3 合规约束：绝不设置 IS_PERSISTENT，强制 SYNC_TYPE = NEVER（仅单机本地保存）
 * - 不可用/模拟器/超长时自动回退至 PreferencesUtil，并在恢复可用时懒迁移至 TEE
 */
export class SecureAssetHelper {
  /** 纯函数：UTF-8 编码为 Uint8Array */
  public static encodeUtf8(text: string): Uint8Array {
    const src: string = text || '';
    if (src.length === 0) {
      return new Uint8Array(0);
    }
    const bytes: number[] = [];
    for (let i = 0; i < src.length; i++) {
      const code: number = src.charCodeAt(i);
      if (code < 0x80) {
        bytes.push(code);
      } else if (code < 0x800) {
        bytes.push(0xC0 | (code >> 6));
        bytes.push(0x80 | (code & 0x3F));
      } else if (code >= 0xD800 && code <= 0xDBFF && i + 1 < src.length) {
        const next: number = src.charCodeAt(i + 1);
        if (next >= 0xDC00 && next <= 0xDFFF) {
          const cp: number = 0x10000 + (((code - 0xD800) << 10) | (next - 0xDC00));
          bytes.push(0xF0 | (cp >> 18));
          bytes.push(0x80 | ((cp >> 12) & 0x3F));
          bytes.push(0x80 | ((cp >> 6) & 0x3F));
          bytes.push(0x80 | (cp & 0x3F));
          i += 1;
        } else {
          bytes.push(0xE0 | (code >> 12));
          bytes.push(0x80 | ((code >> 6) & 0x3F));
          bytes.push(0x80 | (code & 0x3F));
        }
      } else {
        bytes.push(0xE0 | (code >> 12));
        bytes.push(0x80 | ((code >> 6) & 0x3F));
        bytes.push(0x80 | (code & 0x3F));
      }
    }
    return new Uint8Array(bytes);
  }

  /** 纯函数：Uint8Array 解码为 UTF-8 字符串 */
  public static decodeUtf8(bytes: Uint8Array): string {
    if (!bytes || bytes.byteLength === 0) {
      return '';
    }
    let out: string = '';
    let i: number = 0;
    const len: number = bytes.byteLength;
    while (i < len) {
      const b0: number = bytes[i];
      if (b0 < 0x80) {
        out += String.fromCharCode(b0);
        i += 1;
      } else if ((b0 & 0xE0) === 0xC0 && i + 1 < len) {
        const b1: number = bytes[i + 1];
        out += String.fromCharCode(((b0 & 0x1F) << 6) | (b1 & 0x3F));
        i += 2;
      } else if ((b0 & 0xF0) === 0xE0 && i + 2 < len) {
        const b1: number = bytes[i + 1];
        const b2: number = bytes[i + 2];
        out += String.fromCharCode(((b0 & 0x0F) << 12) | ((b1 & 0x3F) << 6) | (b2 & 0x3F));
        i += 3;
      } else if ((b0 & 0xF8) === 0xF0 && i + 3 < len) {
        const b1: number = bytes[i + 1];
        const b2: number = bytes[i + 2];
        const b3: number = bytes[i + 3];
        const cp: number = ((b0 & 0x07) << 18) | ((b1 & 0x3F) << 12) | ((b2 & 0x3F) << 6) | (b3 & 0x3F);
        const offset: number = cp - 0x10000;
        out += String.fromCharCode(0xD800 + (offset >> 10), 0xDC00 + (offset & 0x3FF));
        i += 4;
      } else {
        out += '\uFFFD';
        i += 1;
      }
    }
    return out;
  }

  /** 纯函数：校验关键资产明文是否在 AssetStoreKit 1..1024 UTF-8 字节限制内 */
  public static isSecretWithinLimit(secret: string): boolean {
    if (!secret || secret.length === 0) {
      return false;
    }
    const byteLen: number = SecureAssetHelper.encodeUtf8(secret).byteLength;
    return byteLen >= 1 && byteLen <= MAX_ASSET_SECRET_BYTES;
  }

  /** 纯函数：构造新增/覆盖资产属性集（强制 SyncType.NEVER、不设 IS_PERSISTENT） */
  public static buildAddAttributes(alias: string, secret: string): asset.AssetMap {
    const attr: asset.AssetMap = new Map();
    attr.set(asset.Tag.ALIAS, SecureAssetHelper.encodeUtf8(alias));
    attr.set(asset.Tag.SECRET, SecureAssetHelper.encodeUtf8(secret));
    attr.set(asset.Tag.ACCESSIBILITY, asset.Accessibility.DEVICE_FIRST_UNLOCKED);
    attr.set(asset.Tag.AUTH_TYPE, asset.AuthType.NONE);
    attr.set(asset.Tag.SYNC_TYPE, asset.SyncType.NEVER);
    attr.set(asset.Tag.CONFLICT_RESOLUTION, asset.ConflictResolution.OVERWRITE);
    return attr;
  }

  /** 纯函数：构造查询资产属性集 */
  public static buildQueryAttributes(alias: string): asset.AssetMap {
    const query: asset.AssetMap = new Map();
    query.set(asset.Tag.ALIAS, SecureAssetHelper.encodeUtf8(alias));
    query.set(asset.Tag.RETURN_TYPE, asset.ReturnType.ALL);
    return query;
  }

  /** 纯函数：构造删除资产属性集 */
  public static buildRemoveAttributes(alias: string): asset.AssetMap {
    const query: asset.AssetMap = new Map();
    query.set(asset.Tag.ALIAS, SecureAssetHelper.encodeUtf8(alias));
    return query;
  }

  /** 纯函数：从 asset.query 返回数组中解析 SECRET 字段 */
  public static extractSecretFromResults(results: Array<asset.AssetMap>): string {
    if (!results || results.length === 0) {
      return '';
    }
    for (const row of results) {
      if (!row) {
        continue;
      }
      const val: asset.Value | undefined = row.get(asset.Tag.SECRET);
      if (val instanceof Uint8Array) {
        const decoded: string = SecureAssetHelper.decodeUtf8(val);
        if (decoded !== '') {
          return decoded;
        }
      }
    }
    return '';
  }

  /** 纯函数：映射 AssetStoreKit 错误码为可读提示 */
  public static formatAssetError(code: number): string {
    if (code === 201) {
      return '缺少安全存储权限';
    }
    if (code === 401 || code === 24000018) {
      return '安全存储参数无效';
    }
    if (code === 24000001) {
      return '关键资产服务暂不可用';
    }
    if (code === 24000002) {
      return '未找到对应安全资产';
    }
    if (code === 24000004) {
      return '关键资产访问被拒绝';
    }
    if (code === 24000005) {
      return '设备锁屏状态不匹配';
    }
    if (code === 24000017) {
      return '当前设备不支持硬件关键资产存储';
    }
    return '硬件安全存储异常，已切换本地回退';
  }

  /** 纯函数：序列化登录会话敏感凭据束 */
  public static packLoginSecretBundle(bundle: LoginSecretBundle): string {
    const safeObj: LoginSecretBundle = {
      aesKey: bundle.aesKey || '',
      onlyCode: bundle.onlyCode || '',
      sessionKey: bundle.sessionKey || ''
    };
    return JSON.stringify(safeObj);
  }

  /** 纯函数：反序列化登录会话敏感凭据束 */
  public static unpackLoginSecretBundle(raw: string): LoginSecretBundle | null {
    const trimmed: string = (raw || '').trim();
    if (trimmed === '') {
      return null;
    }
    try {
      const parsed: Object = JSON.parse(trimmed) as Object;
      if (parsed === null || typeof parsed !== 'object') {
        return null;
      }
      const rec = parsed as Record<string, Object>;
      const aesKey: string = typeof rec['aesKey'] === 'string' ? rec['aesKey'] as string : '';
      const onlyCode: string = typeof rec['onlyCode'] === 'string' ? rec['onlyCode'] as string : '';
      const sessionKey: string = typeof rec['sessionKey'] === 'string' ? rec['sessionKey'] as string : '';
      if (aesKey === '' && onlyCode === '' && sessionKey === '') {
        return null;
      }
      return {
        aesKey: aesKey,
        onlyCode: onlyCode,
        sessionKey: sessionKey
      };
    } catch {
      return null;
    }
  }

  /** 写入关键资产（优先硬件 TEE，不支持或超限时透明回退至 PreferencesUtil） */
  public static async putSecret(
    alias: string,
    value: string,
    fallbackPrefKey?: string
  ): Promise<AssetOpResult> {
    const cleanAlias: string = (alias || '').trim();
    if (cleanAlias === '') {
      return {
        success: false,
        storedInTee: false,
        fallbackUsed: false,
        message: '资产标识为空'
      };
    }
    if (!value || value === '') {
      await SecureAssetHelper.removeSecret(cleanAlias, fallbackPrefKey);
      return {
        success: true,
        storedInTee: false,
        fallbackUsed: false,
        message: ''
      };
    }

    let failMsg: string = '';
    if (SecureAssetHelper.isSecretWithinLimit(value)) {
      try {
        await asset.add(SecureAssetHelper.buildAddAttributes(cleanAlias, value));
        if (fallbackPrefKey && fallbackPrefKey.trim() !== '') {
          await PreferencesUtil.delete(fallbackPrefKey);
        }
        return {
          success: true,
          storedInTee: true,
          fallbackUsed: false,
          message: ''
        };
      } catch (err) {
        const be = err as BusinessError;
        failMsg = SecureAssetHelper.formatAssetError(be.code ?? -1);
      }
    } else {
      failMsg = '资产长度超过 1024 字节上限，已使用本地回退存储';
    }

    if (fallbackPrefKey && fallbackPrefKey.trim() !== '') {
      await PreferencesUtil.putString(fallbackPrefKey, value);
      return {
        success: true,
        storedInTee: false,
        fallbackUsed: true,
        message: failMsg
      };
    }
    return {
      success: false,
      storedInTee: false,
      fallbackUsed: false,
      message: failMsg
    };
  }

  /** 读取关键资产（优先 TEE；若仅存旧版明文首选项则尝试懒迁移入 TEE） */
  public static async getSecret(alias: string, fallbackPrefKey?: string): Promise<string> {
    const cleanAlias: string = (alias || '').trim();
    if (cleanAlias === '') {
      return '';
    }
    try {
      const results: Array<asset.AssetMap> = await asset.query(
        SecureAssetHelper.buildQueryAttributes(cleanAlias)
      );
      const fromTee: string = SecureAssetHelper.extractSecretFromResults(results);
      if (fromTee !== '') {
        return fromTee;
      }
    } catch {
      // 未找到或设备不支持 TEE 时尝试读取回退首选项
    }

    if (fallbackPrefKey && fallbackPrefKey.trim() !== '') {
      const legacy: string = await PreferencesUtil.getString(fallbackPrefKey, '');
      if (legacy !== '' && SecureAssetHelper.isSecretWithinLimit(legacy)) {
        try {
          await asset.add(SecureAssetHelper.buildAddAttributes(cleanAlias, legacy));
          await PreferencesUtil.delete(fallbackPrefKey);
        } catch {
          // 懒迁移失败保留明文回退，不影响正常读取
        }
      }
      return legacy;
    }
    return '';
  }

  /** 移除关键资产（同步清理 TEE 与回退首选项） */
  public static async removeSecret(alias: string, fallbackPrefKey?: string): Promise<boolean> {
    const cleanAlias: string = (alias || '').trim();
    let ok: boolean = true;
    if (cleanAlias !== '') {
      try {
        await asset.remove(SecureAssetHelper.buildRemoveAttributes(cleanAlias));
      } catch (err) {
        const be = err as BusinessError;
        if (be.code !== 24000002) {
          ok = false;
        }
      }
    }
    if (fallbackPrefKey && fallbackPrefKey.trim() !== '') {
      await PreferencesUtil.delete(fallbackPrefKey);
    }
    return ok;
  }
}
