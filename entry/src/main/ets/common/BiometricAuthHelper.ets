import { userAuth } from '@kit.UserAuthenticationKit';
import { cryptoFramework } from '@kit.CryptoArchitectureKit';
import { common } from '@kit.AbilityKit';
import { preferences } from '@kit.ArkData';
import { BusinessError } from '@kit.BasicServicesKit';
import { PreferencesUtil } from '../data/PreferencesUtil';
import { LoginSession } from '../network/LoginSession';

export interface BiometricCapability {
  faceAvailable: boolean;
  fingerprintAvailable: boolean;
  pinAvailable: boolean;
  anyBiometric: boolean;
  anyAvailable: boolean;
  authTypes: userAuth.UserAuthType[];
  description: string;
}

export interface BiometricAuthOptions {
  title: string;
  navigationButtonText?: string;
  authTypes?: userAuth.UserAuthType[];
  trustLevel?: userAuth.AuthTrustLevel;
  uiContext?: common.Context;
}

export interface BiometricAuthOutcome {
  success: boolean;
  canceled: boolean;
  fallbackToCustom: boolean;
  locked: boolean;
  notEnrolled: boolean;
  code: number;
  message: string;
}

const SECURITY_PREF_FILE: string = 'sdmu_security_prefs';

/**
 * 本地生物识别与锁屏验证助手（基于 @kit.UserAuthenticationKit userAuth）
 * - 支持人脸 / 指纹 / 锁屏密码能力探测与单次认证实例封装
 * - 开关状态持久化于独立首选项 sdmu_security_prefs + PreferencesUtil + AppStorage（不受退出登录 clear 影响）
 */
export class BiometricAuthHelper {
  public static readonly KEY_BIOMETRIC_ENABLED: string = 'biometric_unlock_enabled';
  public static readonly DEFAULT_BIOMETRIC_ENABLED: boolean = false;

  private static activeInstance: userAuth.UserAuthInstance | null = null;
  private static activeCallback: userAuth.IAuthCallback | null = null;
  private static cachedEnabled: boolean | null = null;

  /** 纯函数：根据可用标记组装认证类型列表（仅限本机人脸/指纹/PIN，排除跨端伴随设备） */
  public static buildAvailableAuthTypes(
    faceOk: boolean,
    fingerOk: boolean,
    pinOk: boolean
  ): userAuth.UserAuthType[] {
    const types: userAuth.UserAuthType[] = [];
    if (faceOk) {
      types.push(userAuth.UserAuthType.FACE);
    }
    if (fingerOk) {
      types.push(userAuth.UserAuthType.FINGERPRINT);
    }
    if (pinOk) {
      types.push(userAuth.UserAuthType.PIN);
    }
    return types;
  }

  /** 纯函数：提取纯生物识别类型（仅人脸/指纹，排除 PIN） */
  public static getBiometricOnlyTypes(cap: BiometricCapability): userAuth.UserAuthType[] {
    const types: userAuth.UserAuthType[] = [];
    if (!cap) {
      return types;
    }
    if (cap.faceAvailable) {
      types.push(userAuth.UserAuthType.FACE);
    }
    if (cap.fingerprintAvailable) {
      types.push(userAuth.UserAuthType.FINGERPRINT);
    }
    return types;
  }

  /** 纯函数：安全构建 WidgetParam（含 PIN 时禁止传 navigationButtonText；不传 2in1 专用 uiContext） */
  public static buildWidgetParam(
    title: string,
    authTypes: userAuth.UserAuthType[],
    navigationButtonText?: string
  ): userAuth.WidgetParam {
    const widgetParam: userAuth.WidgetParam = {
      title: (title || '').trim() !== '' ? title.trim() : '身份验证'
    };
    const navText: string = (navigationButtonText || '').trim();
    const hasPin: boolean = authTypes.indexOf(userAuth.UserAuthType.PIN) >= 0;
    if (navText !== '' && !hasPin) {
      widgetParam.navigationButtonText = navText;
    }
    return widgetParam;
  }

  /** 纯函数：生成合法长度（1..32 字节）的密码学随机挑战值 */
  public static generateChallenge(length: number = 16): Uint8Array {
    const safeLen: number = Number.isFinite(length)
      ? Math.min(32, Math.max(1, Math.floor(length)))
      : 16;
    try {
      const rand: cryptoFramework.Random = cryptoFramework.createRandom();
      const blob: cryptoFramework.DataBlob = rand.generateRandomSync(safeLen);
      if (blob && blob.data && blob.data.byteLength === safeLen) {
        return blob.data;
      }
    } catch {
      // 单元测试无原生 CryptoArchitectureKit 环境时回退
    }
    const challenge: Uint8Array = new Uint8Array(safeLen);
    for (let i = 0; i < safeLen; i++) {
      challenge[i] = Math.floor(Math.random() * 256);
    }
    return challenge;
  }

  /** 纯函数：映射 UserAuthResultCode 为结构化认证结果 */
  public static mapAuthResultCode(code: number): BiometricAuthOutcome {
    if (code === userAuth.UserAuthResultCode.SUCCESS) {
      return {
        success: true,
        canceled: false,
        fallbackToCustom: false,
        locked: false,
        notEnrolled: false,
        code: code,
        message: '验证成功'
      };
    }
    if (code === userAuth.UserAuthResultCode.FAIL) {
      return {
        success: false,
        canceled: false,
        fallbackToCustom: false,
        locked: false,
        notEnrolled: false,
        code: code,
        message: '生物特征不匹配，请重试'
      };
    }
    if (code === userAuth.UserAuthResultCode.CANCELED) {
      return {
        success: false,
        canceled: true,
        fallbackToCustom: false,
        locked: false,
        notEnrolled: false,
        code: code,
        message: '已取消验证'
      };
    }
    if (code === userAuth.UserAuthResultCode.CANCELED_FROM_WIDGET) {
      return {
        success: false,
        canceled: true,
        fallbackToCustom: true,
        locked: false,
        notEnrolled: false,
        code: code,
        message: '已切换为手势密码验证'
      };
    }
    if (code === userAuth.UserAuthResultCode.TIMEOUT) {
      return {
        success: false,
        canceled: false,
        fallbackToCustom: false,
        locked: false,
        notEnrolled: false,
        code: code,
        message: '身份验证超时，请重试'
      };
    }
    if (code === userAuth.UserAuthResultCode.TYPE_NOT_SUPPORT) {
      return {
        success: false,
        canceled: false,
        fallbackToCustom: true,
        locked: false,
        notEnrolled: false,
        code: code,
        message: '当前设备不支持该生物识别方式'
      };
    }
    if (code === userAuth.UserAuthResultCode.TRUST_LEVEL_NOT_SUPPORT) {
      return {
        success: false,
        canceled: false,
        fallbackToCustom: true,
        locked: false,
        notEnrolled: false,
        code: code,
        message: '当前设备安全等级不支持该认证'
      };
    }
    if (code === userAuth.UserAuthResultCode.BUSY) {
      return {
        success: false,
        canceled: false,
        fallbackToCustom: false,
        locked: false,
        notEnrolled: false,
        code: code,
        message: '身份认证服务忙，请稍后重试'
      };
    }
    if (code === userAuth.UserAuthResultCode.INVALID_PARAMETERS || code === 401) {
      return {
        success: false,
        canceled: false,
        fallbackToCustom: false,
        locked: false,
        notEnrolled: false,
        code: code,
        message: '身份认证参数无效'
      };
    }
    if (code === userAuth.UserAuthResultCode.LOCKED) {
      return {
        success: false,
        canceled: false,
        fallbackToCustom: true,
        locked: true,
        notEnrolled: false,
        code: code,
        message: '失败次数过多，生物识别已锁定'
      };
    }
    if (code === userAuth.UserAuthResultCode.NOT_ENROLLED) {
      return {
        success: false,
        canceled: false,
        fallbackToCustom: true,
        locked: false,
        notEnrolled: true,
        code: code,
        message: '系统尚未录入指纹或人脸信息'
      };
    }
    if (code === userAuth.UserAuthResultCode.PIN_EXPIRED) {
      return {
        success: false,
        canceled: false,
        fallbackToCustom: true,
        locked: false,
        notEnrolled: false,
        code: code,
        message: '系统锁屏密码已过期'
      };
    }
    if (code === 201) {
      return {
        success: false,
        canceled: false,
        fallbackToCustom: true,
        locked: false,
        notEnrolled: false,
        code: code,
        message: '未获得生物识别权限'
      };
    }
    return {
      success: false,
      canceled: false,
      fallbackToCustom: false,
      locked: false,
      notEnrolled: false,
      code: code,
      message: '生物识别服务暂不可用'
    };
  }

  /** 纯函数：判断是否应提供“生物识别快捷验证”开关 */
  public static shouldOfferBiometricToggle(cap: BiometricCapability): boolean {
    if (!cap) {
      return false;
    }
    return cap.anyAvailable || cap.anyBiometric || cap.pinAvailable;
  }

  /** 纯函数：判断是否应在手势验证页展示生物识别快捷验证入口 */
  public static shouldShowBiometricVerify(
    enabled: boolean,
    cap: BiometricCapability,
    frozen: boolean
  ): boolean {
    if (!enabled || frozen || !cap) {
      return false;
    }
    return cap.anyAvailable || cap.anyBiometric || cap.pinAvailable;
  }

  /** 纯函数：规范化布尔首选项 */
  public static normalizeBiometricFlag(
    raw: boolean | string | number | undefined | null,
    defaultValue: boolean = BiometricAuthHelper.DEFAULT_BIOMETRIC_ENABLED
  ): boolean {
    if (typeof raw === 'boolean') {
      return raw;
    }
    if (typeof raw === 'number') {
      return Number.isFinite(raw) ? raw !== 0 : defaultValue;
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

  private static buildTrustLevelOrder(preferredTrustLevel: userAuth.AuthTrustLevel): userAuth.AuthTrustLevel[] {
    const candidates: userAuth.AuthTrustLevel[] = [
      preferredTrustLevel,
      userAuth.AuthTrustLevel.ATL2,
      userAuth.AuthTrustLevel.ATL3,
      userAuth.AuthTrustLevel.ATL1
    ];
    const unique: userAuth.AuthTrustLevel[] = [];
    for (const level of candidates) {
      if (unique.indexOf(level) < 0) {
        unique.push(level);
      }
    }
    return unique;
  }

  private static resolveWorkingTrustLevel(
    authType: userAuth.UserAuthType,
    preferredTrustLevel: userAuth.AuthTrustLevel
  ): userAuth.AuthTrustLevel | null {
    const levels: userAuth.AuthTrustLevel[] = BiometricAuthHelper.buildTrustLevelOrder(preferredTrustLevel);
    for (const level of levels) {
      try {
        userAuth.getAvailableStatus(authType, level);
        return level;
      } catch {
        // 尝试下一个安全等级
      }
    }
    return null;
  }

  private static isTypeAvailable(
    authType: userAuth.UserAuthType,
    trustLevel: userAuth.AuthTrustLevel
  ): boolean {
    return BiometricAuthHelper.resolveWorkingTrustLevel(authType, trustLevel) !== null;
  }

  /** 同步探测当前设备可用生物识别/锁屏能力 */
  public static checkCapability(
    trustLevel: userAuth.AuthTrustLevel = userAuth.AuthTrustLevel.ATL1
  ): BiometricCapability {
    const faceOk: boolean = BiometricAuthHelper.isTypeAvailable(userAuth.UserAuthType.FACE, trustLevel);
    const fingerOk: boolean = BiometricAuthHelper.isTypeAvailable(userAuth.UserAuthType.FINGERPRINT, trustLevel);
    const pinOk: boolean = BiometricAuthHelper.isTypeAvailable(userAuth.UserAuthType.PIN, trustLevel);
    const authTypes: userAuth.UserAuthType[] = BiometricAuthHelper.buildAvailableAuthTypes(
      faceOk,
      fingerOk,
      pinOk
    );
    const labels: string[] = [];
    if (faceOk) {
      labels.push('人脸');
    }
    if (fingerOk) {
      labels.push('指纹');
    }
    if (pinOk && !faceOk && !fingerOk) {
      labels.push('锁屏密码');
    }
    const description: string = labels.length > 0
      ? `支持：${labels.join(' / ')}`
      : '当前设备未录入或不支持生物识别';
    return {
      faceAvailable: faceOk,
      fingerprintAvailable: fingerOk,
      pinAvailable: pinOk,
      anyBiometric: faceOk || fingerOk,
      anyAvailable: authTypes.length > 0,
      authTypes: authTypes,
      description: description
    };
  }

  /** 发起单次用户身份认证（内部先做 getAvailableStatus 探测并管理监听清理） */
  public static authenticate(options: BiometricAuthOptions): Promise<BiometricAuthOutcome> {
    BiometricAuthHelper.cancelActiveAuth();
    const preferredLevel: userAuth.AuthTrustLevel = options.trustLevel ?? userAuth.AuthTrustLevel.ATL1;
    const requestedTypes: userAuth.UserAuthType[] = options.authTypes && options.authTypes.length > 0
      ? options.authTypes
      : BiometricAuthHelper.checkCapability(preferredLevel).authTypes;

    const trustCandidates: userAuth.AuthTrustLevel[] = BiometricAuthHelper.buildTrustLevelOrder(preferredLevel);
    let selectedLevel: userAuth.AuthTrustLevel = preferredLevel;
    let availableTypes: userAuth.UserAuthType[] = [];
    let firstErrorCode: number = userAuth.UserAuthResultCode.TYPE_NOT_SUPPORT;

    for (const level of trustCandidates) {
      const matched: userAuth.UserAuthType[] = [];
      for (const t of requestedTypes) {
        try {
          userAuth.getAvailableStatus(t, level);
          matched.push(t);
        } catch (err) {
          const be = err as BusinessError;
          if (typeof be.code === 'number') {
            firstErrorCode = be.code;
          }
        }
      }
      if (matched.length > 0) {
        availableTypes = matched;
        selectedLevel = level;
        break;
      }
    }

    if (availableTypes.length === 0) {
      return Promise.resolve(BiometricAuthHelper.mapAuthResultCode(firstErrorCode));
    }

    return new Promise<BiometricAuthOutcome>((resolve) => {
      try {
        const authParam: userAuth.AuthParam = {
          challenge: BiometricAuthHelper.generateChallenge(16),
          authType: availableTypes,
          authTrustLevel: selectedLevel
        };
        const widgetParam: userAuth.WidgetParam = BiometricAuthHelper.buildWidgetParam(
          options.title,
          availableTypes,
          options.navigationButtonText
        );

        let instance: userAuth.UserAuthInstance | null = null;
        try {
          instance = userAuth.getUserAuthInstance(authParam, widgetParam);
        } catch (instErr) {
          const beInst = instErr as BusinessError;
          if (widgetParam.navigationButtonText && (beInst.code === 401 || beInst.code === 12500007)) {
            const fallbackWidgetParam: userAuth.WidgetParam = { title: widgetParam.title };
            instance = userAuth.getUserAuthInstance(authParam, fallbackWidgetParam);
          } else {
            const failCode: number = typeof beInst.code === 'number'
              ? beInst.code
              : userAuth.UserAuthResultCode.GENERAL_ERROR;
            resolve(BiometricAuthHelper.mapAuthResultCode(failCode));
            return;
          }
        }

        if (instance === null) {
          resolve(BiometricAuthHelper.mapAuthResultCode(userAuth.UserAuthResultCode.GENERAL_ERROR));
          return;
        }
        const authInstance: userAuth.UserAuthInstance = instance;

        let settled: boolean = false;
        const callback: userAuth.IAuthCallback = {
          onResult: (result: userAuth.UserAuthResult): void => {
            if (settled) {
              return;
            }
            settled = true;
            try {
              authInstance.off('result', callback);
            } catch {
              // 忽略解绑异常
            }
            if (BiometricAuthHelper.activeInstance === authInstance) {
              BiometricAuthHelper.activeInstance = null;
              BiometricAuthHelper.activeCallback = null;
            }
            resolve(BiometricAuthHelper.mapAuthResultCode(result.result));
          }
        };
        BiometricAuthHelper.activeInstance = authInstance;
        BiometricAuthHelper.activeCallback = callback;
        authInstance.on('result', callback);
        authInstance.start();
      } catch (err) {
        BiometricAuthHelper.activeInstance = null;
        BiometricAuthHelper.activeCallback = null;
        const be = err as BusinessError;
        const code: number = typeof be.code === 'number'
          ? be.code
          : userAuth.UserAuthResultCode.GENERAL_ERROR;
        resolve(BiometricAuthHelper.mapAuthResultCode(code));
      }
    });
  }

  /** 安全取消进行中的认证并清理回调订阅 */
  public static cancelActiveAuth(): void {
    const inst: userAuth.UserAuthInstance | null = BiometricAuthHelper.activeInstance;
    const cb: userAuth.IAuthCallback | null = BiometricAuthHelper.activeCallback;
    BiometricAuthHelper.activeInstance = null;
    BiometricAuthHelper.activeCallback = null;
    if (inst === null) {
      return;
    }
    try {
      inst.cancel();
    } catch {
      // 忽略取消异常
    }
    try {
      if (cb !== null) {
        inst.off('result', cb);
      } else {
        inst.off('result');
      }
    } catch {
      // 忽略解绑异常
    }
  }

  private static resolveContext(ctx?: common.BaseContext): common.BaseContext | null {
    if (ctx) {
      return ctx;
    }
    return LoginSession.uiContext;
  }

  private static syncAppStorage(enabled: boolean): void {
    try {
      AppStorage.setOrCreate<boolean>(BiometricAuthHelper.KEY_BIOMETRIC_ENABLED, enabled);
    } catch {
      // 单元测试无 ArkUI AppStorage 环境时安全忽略
    }
  }

  /** 仅用于单元测试重置内存缓存状态 */
  public static resetStateForTest(initialEnabled: boolean | null = null): void {
    BiometricAuthHelper.cancelActiveAuth();
    BiometricAuthHelper.cachedEnabled = initialEnabled;
  }

  /** 读取“生物识别快捷验证”开关状态 */
  public static async isBiometricUnlockEnabled(ctx?: common.BaseContext): Promise<boolean> {
    if (BiometricAuthHelper.cachedEnabled !== null) {
      return BiometricAuthHelper.cachedEnabled;
    }
    const resolvedCtx: common.BaseContext | null = BiometricAuthHelper.resolveContext(ctx);
    let enabled: boolean = BiometricAuthHelper.DEFAULT_BIOMETRIC_ENABLED;
    let foundInBackup: boolean = false;

    if (resolvedCtx) {
      try {
        const store = preferences.getPreferencesSync(resolvedCtx, { name: SECURITY_PREF_FILE });
        if (store.hasSync(BiometricAuthHelper.KEY_BIOMETRIC_ENABLED)) {
          const raw = store.getSync(
            BiometricAuthHelper.KEY_BIOMETRIC_ENABLED,
            BiometricAuthHelper.DEFAULT_BIOMETRIC_ENABLED
          );
          enabled = BiometricAuthHelper.normalizeBiometricFlag(raw as boolean | string | number);
          foundInBackup = true;
        }
      } catch {
        // 忽略备份库读取失败
      }
    }

    if (!foundInBackup) {
      try {
        const prefVal: boolean = await PreferencesUtil.getBoolean(
          BiometricAuthHelper.KEY_BIOMETRIC_ENABLED,
          BiometricAuthHelper.DEFAULT_BIOMETRIC_ENABLED
        );
        enabled = BiometricAuthHelper.normalizeBiometricFlag(prefVal);
      } catch {
        enabled = BiometricAuthHelper.DEFAULT_BIOMETRIC_ENABLED;
      }
    } else {
      await PreferencesUtil.putBoolean(BiometricAuthHelper.KEY_BIOMETRIC_ENABLED, enabled);
    }

    BiometricAuthHelper.cachedEnabled = enabled;
    BiometricAuthHelper.syncAppStorage(enabled);
    return enabled;
  }

  /** 保存“生物识别快捷验证”开关状态 */
  public static async setBiometricUnlockEnabled(
    enabled: boolean,
    ctx?: common.BaseContext
  ): Promise<boolean> {
    const normalized: boolean = Boolean(enabled);
    BiometricAuthHelper.cachedEnabled = normalized;
    BiometricAuthHelper.syncAppStorage(normalized);

    const resolvedCtx: common.BaseContext | null = BiometricAuthHelper.resolveContext(ctx);
    if (resolvedCtx) {
      try {
        const store = preferences.getPreferencesSync(resolvedCtx, { name: SECURITY_PREF_FILE });
        store.putSync(BiometricAuthHelper.KEY_BIOMETRIC_ENABLED, normalized);
        store.flushSync();
      } catch {
        // 忽略备份库写入异常
      }
    }
    await PreferencesUtil.putBoolean(BiometricAuthHelper.KEY_BIOMETRIC_ENABLED, normalized);
    return normalized;
  }
}
