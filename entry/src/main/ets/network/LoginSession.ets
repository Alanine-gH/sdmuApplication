import { BusinessError } from '@kit.BasicServicesKit';
import { util } from '@kit.ArkTS';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { preferences } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';
import { HttpClient } from './HttpClient';
import { CryptoUtil } from './CryptoUtil';
import { ApiResponse } from '../model/ResponseModel';
import { UserInfo } from '../model/UserModel';
import { Constants } from '../data/Constants';
import { ApiService } from './ApiService';
import { LoginSecretBundle, SecureAssetHelper } from '../common/SecureAssetHelper';
import { UrlSecurityHelper } from '../common/UrlSecurityHelper';

const TAG = 0x0000;
const DOMAIN = 'SDMU';
const LOGIN_SECRET_ALIAS: string = 'sdmu_login_secrets';

/**
 * 登录会话管理 — 复刻原生 GetKeyUtil + LoginModel（服务器实测协议，2026-11-17 全链路打通）：
 *   1. GET /open/security/asym/key（Asym-Key: public）动态取RSA公钥
 *   2. POST 协商（Asym-Key: private，Unique-Code=随机UUID）→ 响应data=AES(onlyCode)
 *      关键实测结论：协商请求头使用的 UC 被服务器绑定为会话标识，
 *      业务请求的 Unique-Code 必须用「协商时的UC」，而非解密产物 onlyCode
 *   3. 登录：body=AES(完整实体)，Unique-Code=onlyCode → code=0
 *   4. 解密响应 → session_key + 真实用户信息
 *   5. onlyCode/aesKey/sessionKey 持久化 preferences：重启后免重新协商直接复用会话
 * 错误码：0成功 1005账号密码错 0006解密失败 0001系统异常
 */
export class LoginSession {
  static aesKey: string = '';
  static onlyCode: string = '';
  /** 设备UC（协商请求标识，业务请求Unique-Code；持久化） */
  static deviceCode: string = '';
  static sessionKey: string = '';
  static userType: string = '';
  static userId: string = '';
  /** 学校代码（来自登录响应 UserEntity.schoolId，Access-Token 的 xxdm 字段） */
  static schoolId: string = '';
  /** 登录用户全字段（parseUserEntity 填充，persistSession 持久化，个人资料页真数据源） */
  static sessionName: string = '';
  static sessionCollege: string = '';
  static sessionMajor: string = '';
  static sessionClass: string = '';
  static sessionGrade: string = '';
  static sessionPhone: string = '';
  static step: string = '';

  static log(msg: string): void {
    hilog.info(TAG, DOMAIN, 'login %{public}s', msg);
  }

  private static randomUuid(): string {
    const bytes: Uint8Array = CryptoUtil.generateRandomBytes(16);
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    const hex: string[] = [];
    for (let i = 0; i < 16; i++) {
      hex.push(bytes[i].toString(16).padStart(2, '0'));
    }
    return hex.slice(0, 4).join('') + '-' + hex.slice(4, 6).join('') + '-' +
      hex.slice(6, 8).join('') + '-' + hex.slice(8, 10).join('') + '-' +
      hex.slice(10, 16).join('');
  }

  /** 会话持久化：UC/userId/userType/schoolId/用户全字段写入 preferences，敏感密钥优先存入 AssetStoreKit TEE */
  static async persistSession(): Promise<void> {
    try {
      const ctx = LoginSession.uiContext ?? LoginSession.fallbackContext();
      if (ctx === null || ctx === undefined) {
        return;
      }
      const hasSecrets: boolean = LoginSession.aesKey !== '' ||
        LoginSession.onlyCode !== '' ||
        LoginSession.sessionKey !== '';
      let storedInTee: boolean = false;
      if (hasSecrets) {
        const bundleJson: string = SecureAssetHelper.packLoginSecretBundle({
          aesKey: LoginSession.aesKey,
          onlyCode: LoginSession.onlyCode,
          sessionKey: LoginSession.sessionKey
        });
        const assetRes = await SecureAssetHelper.putSecret(LOGIN_SECRET_ALIAS, bundleJson);
        storedInTee = assetRes.storedInTee;
      } else {
        await SecureAssetHelper.removeSecret(LOGIN_SECRET_ALIAS);
      }

      const store: preferences.Preferences =
        await preferences.getPreferences(ctx, Constants.PREF_NAME);
      await store.put('deviceCode', LoginSession.deviceCode);
      await store.put('aesKey', storedInTee ? '' : LoginSession.aesKey);
      await store.put('onlyCode', storedInTee ? '' : LoginSession.onlyCode);
      await store.put('sessionKey', storedInTee ? '' : LoginSession.sessionKey);
      await store.put('sessionUserId', LoginSession.userId);
      await store.put('sessionUserType', LoginSession.userType);
      await store.put('sessionSchoolId', LoginSession.schoolId);
      // 用户资料全字段（个人资料页真数据源）
      await store.put('sessionName', LoginSession.sessionName);
      await store.put('sessionCollege', LoginSession.sessionCollege);
      await store.put('sessionMajor', LoginSession.sessionMajor);
      await store.put('sessionClass', LoginSession.sessionClass);
      await store.put('sessionGrade', LoginSession.sessionGrade);
      await store.put('sessionPhone', LoginSession.sessionPhone);
      await store.flush();
    } catch (error) {
      LoginSession.log('persistSession失败: ' + (error as BusinessError).message);
    }
  }

  /** 恢复持久化会话（应用启动时调用；先校验 deviceCode 非空以保持退出登录语义，再从 TEE/preferences 恢复密钥） */
  static async restoreSession(): Promise<boolean> {
    try {
      const ctx = LoginSession.uiContext ?? LoginSession.fallbackContext();
      if (ctx === null || ctx === undefined) {
        return false;
      }
      const store: preferences.Preferences =
        await preferences.getPreferences(ctx, Constants.PREF_NAME);
      const uc: preferences.ValueType = await store.get('deviceCode', '');
      if (typeof uc !== 'string' || uc === '') {
        return false;
      }

      const rawSecret: string = await SecureAssetHelper.getSecret(LOGIN_SECRET_ALIAS);
      const bundle: LoginSecretBundle | null = rawSecret !== ''
        ? SecureAssetHelper.unpackLoginSecretBundle(rawSecret)
        : null;

      const legacyKey: preferences.ValueType = await store.get('aesKey', '');
      const legacySk: preferences.ValueType = await store.get('sessionKey', '');
      const legacyOc: preferences.ValueType = await store.get('onlyCode', '');

      const resolvedAesKey: string = (bundle !== null && bundle.aesKey !== '')
        ? bundle.aesKey
        : (typeof legacyKey === 'string' ? legacyKey : '');
      const resolvedOnlyCode: string = bundle !== null
        ? bundle.onlyCode
        : (typeof legacyOc === 'string' ? legacyOc : '');
      const resolvedSessionKey: string = bundle !== null
        ? bundle.sessionKey
        : (typeof legacySk === 'string' ? legacySk : '');

      if (resolvedAesKey !== '') {
        LoginSession.deviceCode = uc;
        LoginSession.aesKey = resolvedAesKey;
        LoginSession.sessionKey = resolvedSessionKey;
        LoginSession.onlyCode = resolvedOnlyCode;
        if (bundle === null) {
          const bundleJson: string = SecureAssetHelper.packLoginSecretBundle({
            aesKey: resolvedAesKey,
            onlyCode: resolvedOnlyCode,
            sessionKey: resolvedSessionKey
          });
          const migrateRes = await SecureAssetHelper.putSecret(LOGIN_SECRET_ALIAS, bundleJson);
          if (migrateRes.storedInTee) {
            await store.put('aesKey', '');
            await store.put('onlyCode', '');
            await store.put('sessionKey', '');
            await store.flush();
          }
        }
        const uid: preferences.ValueType = await store.get('sessionUserId', '');
        if (typeof uid === 'string') {
          LoginSession.userId = uid;
        }
        const ut: preferences.ValueType = await store.get('sessionUserType', '');
        if (typeof ut === 'string') {
          LoginSession.userType = ut;
        }
        const sid: preferences.ValueType = await store.get('sessionSchoolId', '');
        if (typeof sid === 'string') {
          LoginSession.schoolId = sid;
        }
        // 用户资料全字段恢复
        const n1: preferences.ValueType = await store.get('sessionName', '');
        if (typeof n1 === 'string') {
          LoginSession.sessionName = n1;
        }
        const n2: preferences.ValueType = await store.get('sessionCollege', '');
        if (typeof n2 === 'string') {
          LoginSession.sessionCollege = n2;
        }
        const n3: preferences.ValueType = await store.get('sessionMajor', '');
        if (typeof n3 === 'string') {
          LoginSession.sessionMajor = n3;
        }
        const n4: preferences.ValueType = await store.get('sessionClass', '');
        if (typeof n4 === 'string') {
          LoginSession.sessionClass = n4;
        }
        const n5: preferences.ValueType = await store.get('sessionGrade', '');
        if (typeof n5 === 'string') {
          LoginSession.sessionGrade = n5;
        }
        const n6: preferences.ValueType = await store.get('sessionPhone', '');
        if (typeof n6 === 'string') {
          LoginSession.sessionPhone = n6;
        }
        LoginSession.log('会话恢复成功 UC=' + UrlSecurityHelper.redactSecret(uc));
        return true;
      }
    } catch (error) {
      LoginSession.log('restoreSession失败: ' + (error as BusinessError).message);
    }
    return false;
  }


  /**
   * 会话失效清理 — 复刻源码 NetUtils.f() code=1000 分支 `d.a.f(new UserEntity())`：
   * 用户实体整体重置（sessionKey/userId/userType/schoolId/资料全字段清空）并立即落盘，
   * 下次 restoreSession 不再复活过期 sessionKey；isLogin 同步置 false（Index 启动判定走登录页）。
   * 保留 deviceCode/aesKey/onlyCode（设备协商产物，APK Hawk 同语义保留，重登免重新协商）。
   */
  static async clearSession(): Promise<void> {
    LoginSession.sessionKey = '';
    LoginSession.userType = '';
    LoginSession.userId = '';
    LoginSession.schoolId = '';
    LoginSession.sessionName = '';
    LoginSession.sessionCollege = '';
    LoginSession.sessionMajor = '';
    LoginSession.sessionClass = '';
    LoginSession.sessionGrade = '';
    LoginSession.sessionPhone = '';
    await LoginSession.persistSession();
    LoginSession.log('会话已清除（登录失效统一处理）');
  }

  /** 兜底获取UIAbility上下文（避免调用已弃用的 globalThis.getContext） */
  private static fallbackContext(): common.UIAbilityContext | null {
    return LoginSession.uiContext;
  }
  /** UI上下文（EntryAbility启动时注入） */
  static uiContext: common.UIAbilityContext | null = null;

  private static fail(code: number, msg: string, account: string): ApiResponse<UserInfo> {
    LoginSession.log('FAIL [' + LoginSession.step + '] code=' + code + ' msg=' + msg);
    return new ApiResponse<UserInfo>(code, msg, ApiService.mockUser(account));
  }

  static async login(account: string, password: string): Promise<ApiResponse<UserInfo>> {
    try {
      // ===== 第0步：恢复已有UC（有则复用，无则新生成并持久）=====
      LoginSession.step = 'restoreUC';
      if (LoginSession.deviceCode === '') {
        await LoginSession.restoreSession();
        if (LoginSession.deviceCode === '') {
          LoginSession.deviceCode = LoginSession.randomUuid();
        }
      }
      LoginSession.log('UC=' + UrlSecurityHelper.redactSecret(LoginSession.deviceCode));

      // ===== 第1步：GET动态公钥 =====
      LoginSession.step = 'fetchPubKey';
      const pubResp: ApiResponse<Object> = await HttpClient.requestRaw(
        '/mobileapi_ydxy/open/security/asym/key', 'GET', '', 'application/json',
        LoginSession.deviceCode, 'public');
      let pubKey: string = Constants.RSA_PUBLIC_KEY;
      if (pubResp.code === 0 && pubResp.data !== null && pubResp.data !== undefined) {
        const fetched: string = pubResp.data as string;
        if (fetched !== '' && fetched.length > 100) {
          pubKey = fetched;
        }
      }

      // ===== 第2步：生成key+协商body =====
      LoginSession.step = 'genKey';
      LoginSession.aesKey = CryptoUtil.generateKey();

      LoginSession.step = 'rsaNegotiate';
      const negotiateBody: string = await CryptoUtil.buildNegotiateBody(LoginSession.aesKey, pubKey);

      // ===== 第3步：POST协商（UC=设备UC，全链路复用）=====
      LoginSession.step = 'negotiateRequest';
      const negoResp: ApiResponse<Object> = await HttpClient.requestRaw(
        '/mobileapi_ydxy/open/security/asym/key', 'POST', negotiateBody, 'text/plain',
        LoginSession.deviceCode, 'private');
      if (negoResp.code !== 0) {
        return LoginSession.fail(negoResp.code, 'key协商失败: ' + negoResp.message, account);
      }
      const negoData: string = negoResp.data as string ?? '';
      if (negoData === '') {
        return LoginSession.fail(negoResp.code, 'key协商响应data为空', account);
      }

      // ===== 第4步：解密onlyCode（记录，业务用deviceCode）=====
      LoginSession.step = 'decryptOnlyCode';
      LoginSession.onlyCode = await CryptoUtil.decryptAES(negoData, LoginSession.aesKey);

      // ===== 第5步：AES加密登录body =====
      LoginSession.step = 'aesLoginBody';
      const entity: Record<string, string> = {
        'userId': account,
        'passw': password,
        'schoolId': 'SDGY',
        'city': '',
        'province': '',
        'clientVersion': Constants.CLIENT_VERSION,
        'serverApiVersion': Constants.CLIENT_VERSION,
        'androidClientVersionCode': '68',
        'deviceModel': Constants.DEVICE_MODEL,
        'deviceType': '1',
        'deviceVersion': '14',
        'latitude': '',
        'longitude': '',
        'imei': '',
        'deviceId': Constants.DEVICE_ID
      };
      const loginBody: string = await CryptoUtil.encryptAES(JSON.stringify(entity), LoginSession.aesKey);

      // ===== 第6步：登录（Unique-Code=设备UC）=====
      LoginSession.step = 'loginRequest';
      const loginResp: ApiResponse<Object> = await HttpClient.requestRaw(
        '/mobileapi_ydxy/open/auth/login', 'POST', loginBody, 'text/plain',
        LoginSession.onlyCode, '');
      if (loginResp.code === 1005) {
        return LoginSession.fail(1005, '账号或密码错误，请重试', account);
      }
      if (loginResp.code !== 0) {
        return LoginSession.fail(loginResp.code, '登录失败: ' + loginResp.message, account);
      }
      const loginData: string = loginResp.data as string ?? '';
      if (loginData === '') {
        return LoginSession.fail(loginResp.code, '登录响应data为空', account);
      }

      // ===== 第7步：解密用户信息 =====
      LoginSession.step = 'decryptUser';
      const userJson: string = await CryptoUtil.decryptAES(loginData, LoginSession.aesKey);
      const user: UserInfo = LoginSession.parseUserEntity(userJson);
      // 会话持久化（重启免协商）
      await LoginSession.persistSession();
      LoginSession.log('登录成功 userId=' + user.userId + ' name=' + user.name);
      return new ApiResponse<UserInfo>(0, '请求成功', user);
    } catch (error) {
      const be = error as BusinessError;
      LoginSession.log('EXCEPTION step=' + LoginSession.step + ' code=' + be.code + ' msg=' + be.message);
      return new ApiResponse<UserInfo>(-1,
        '登录异常[' + LoginSession.step + '] code=' + be.code + ' ' + be.message,
        ApiService.mockUser(account));
    }
  }

  /** UserEntity JSON → UserInfo（字段1:1对应原生UserEntity） */
  static parseUserEntity(json: string): UserInfo {
    const rec: Record<string, Object> = JSON.parse(json) as Record<string, Object>;
    const pick = (k: string): string => {
      const v: Object = rec[k];
      return typeof v === 'string' ? v as string : '';
    };
    LoginSession.sessionKey = pick('session_key');
    LoginSession.userType = pick('userType') === '' ? '1' : pick('userType');
    LoginSession.userId = pick('userId');
    // 原生 e.java:47 xxdm ← schoolId（登录响应 UserEntity.schoolId，SDGY）
    LoginSession.schoolId = pick('schoolId') === '' ? 'sdmu' : pick('schoolId');
    // 用户资料全字段（个人资料页真数据源；persistSession 持久化）
    LoginSession.sessionName = pick('userName');
    LoginSession.sessionCollege = pick('department');
    LoginSession.sessionMajor = pick('professionName');
    LoginSession.sessionClass = pick('className');
    LoginSession.sessionGrade = pick('grade');
    LoginSession.sessionPhone = pick('mobileNo');
    LoginSession.log('parsed sessionKey len=' + LoginSession.sessionKey.length +
      ' userId=' + LoginSession.userId + ' userType=' + LoginSession.userType +
      ' schoolId=' + LoginSession.schoolId);
    // 确保新 session 持久化：调用方显式 persist 之外的兜底（幂等，重复写入同值无害）；
    // 防止未来新增 parseUserEntity 调用路径漏 persist 导致新 sessionKey 重启丢失
    LoginSession.persistSession();
    return new UserInfo(
      pick('userId'),
      pick('userName'),
      pick('userId'),
      pick('className'),
      pick('department'),
      pick('professionName'),
      pick('grade'),
      pick('mobileNo'),
      pick('email'),
      '',
      pick('session_key')
    );
  }

  // ===== [W4 sms-login] 手机号登录：登录前协商复用（APK GetKeyUtil 启动即协商同款） =====
  /** 确保加密通道已协商：已有持久化 deviceCode+aesKey+onlyCode 直接复用；
   *  否则走完整协商（GET 公钥 → 生成 aesKey → RSA 协商 → 解密 onlyCode）。
   *  APK 依据：GetKeyUtil 在应用启动即完成协商，checkLoginPhone/SendSms/loginBySms
   *  三个 /open/auth/ 接口的加密 body 均使用同一协商 aesKey（IdentifyCodeModel 链路）。
   *  复刻自 login() 第0-4步，独立成方法供手机号登录页在 SendSms 前调用。
   */
  static async ensureNegotiated(): Promise<boolean> {
    try {
      // 第0步：恢复已有UC（有则复用，无则新生成）
      LoginSession.step = 'restoreUC';
      if (LoginSession.deviceCode === '') {
        await LoginSession.restoreSession();
        if (LoginSession.deviceCode === '') {
          LoginSession.deviceCode = LoginSession.randomUuid();
        }
      }
      if (LoginSession.aesKey !== '' && LoginSession.onlyCode !== '') {
        LoginSession.log('ensureNegotiated 复用 UC=' + UrlSecurityHelper.redactSecret(LoginSession.deviceCode));
        return true;
      }
      // 第1步：GET动态公钥
      LoginSession.step = 'fetchPubKey';
      const pubResp: ApiResponse<Object> = await HttpClient.requestRaw(
        '/mobileapi_ydxy/open/security/asym/key', 'GET', '', 'application/json',
        LoginSession.deviceCode, 'public');
      let pubKey: string = Constants.RSA_PUBLIC_KEY;
      if (pubResp.code === 0 && pubResp.data !== null && pubResp.data !== undefined) {
        const fetched: string = pubResp.data as string;
        if (fetched !== '' && fetched.length > 100) {
          pubKey = fetched;
        }
      }
      // 第2步：生成key+协商body
      LoginSession.step = 'genKey';
      LoginSession.aesKey = CryptoUtil.generateKey();
      LoginSession.step = 'rsaNegotiate';
      const negotiateBody: string = await CryptoUtil.buildNegotiateBody(LoginSession.aesKey, pubKey);
      // 第3步：POST协商（UC=设备UC，全链路复用）
      LoginSession.step = 'negotiateRequest';
      const negoResp: ApiResponse<Object> = await HttpClient.requestRaw(
        '/mobileapi_ydxy/open/security/asym/key', 'POST', negotiateBody, 'text/plain',
        LoginSession.deviceCode, 'private');
      if (negoResp.code !== 0) {
        LoginSession.log('ensureNegotiated FAIL [' + LoginSession.step + '] code=' + negoResp.code +
          ' msg=' + negoResp.message);
        return false;
      }
      const negoData: string = negoResp.data as string ?? '';
      if (negoData === '') {
        LoginSession.log('ensureNegotiated FAIL 协商响应data为空');
        return false;
      }
      // 第4步：解密onlyCode（业务请求Unique-Code仍用deviceCode，同 login() 实测结论）
      LoginSession.step = 'decryptOnlyCode';
      LoginSession.onlyCode = await CryptoUtil.decryptAES(negoData, LoginSession.aesKey);
      // 第5步：持久化新协商产物（APK GetKeyUtil 启动即协商并持久化 UC/aesKey/onlyCode；
      // 冷启动进入手机号登录时免重复协商。此时无登录态，会话用户字段本就为空，覆盖安全）
      await LoginSession.persistSession();
      LoginSession.log('ensureNegotiated OK UC=' + UrlSecurityHelper.redactSecret(LoginSession.deviceCode));
      return true;
    } catch (error) {
      const be = error as BusinessError;
      LoginSession.log('ensureNegotiated EXCEPTION step=' + LoginSession.step +
        ' code=' + be.code + ' msg=' + be.message);
      return false;
    }
  }
}






