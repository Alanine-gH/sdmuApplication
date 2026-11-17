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

const TAG = 0x0000;
const DOMAIN = 'SDMU';

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
  static step: string = '';

  static log(msg: string): void {
    hilog.info(TAG, DOMAIN, 'login %{public}s', msg);
  }

  private static randomUuid(): string {
    const bytes: Uint8Array = new Uint8Array(16);
    for (let i = 0; i < 16; i++) {
      bytes[i] = Math.floor(Math.random() * 256);
    }
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

  /** 会话持久化：UC/aesKey/sessionKey/userId/userType/schoolId 写入 preferences */
  static async persistSession(): Promise<void> {
    try {
      const ctx = LoginSession.uiContext ?? LoginSession.fallbackContext();
      if (ctx === null || ctx === undefined) {
        return;
      }
      const store: preferences.Preferences =
        await preferences.getPreferences(ctx, Constants.PREF_NAME);
      await store.put('deviceCode', LoginSession.deviceCode);
      await store.put('aesKey', LoginSession.aesKey);
      await store.put('onlyCode', LoginSession.onlyCode);
      await store.put('sessionKey', LoginSession.sessionKey);
      await store.put('sessionUserId', LoginSession.userId);
      await store.put('sessionUserType', LoginSession.userType);
      await store.put('sessionSchoolId', LoginSession.schoolId);
      await store.flush();
    } catch (error) {
      LoginSession.log('persistSession失败: ' + (error as BusinessError).message);
    }
  }

  /** 恢复持久化会话（应用启动时调用；有UC+aesKey则免协商） */
  static async restoreSession(): Promise<boolean> {
    try {
      const ctx = LoginSession.uiContext ?? LoginSession.fallbackContext();
      if (ctx === null || ctx === undefined) {
        return false;
      }
      const store: preferences.Preferences =
        await preferences.getPreferences(ctx, Constants.PREF_NAME);
      const uc: preferences.ValueType = await store.get('deviceCode', '');
      const key: preferences.ValueType = await store.get('aesKey', '');
      if (typeof uc === 'string' && typeof key === 'string' && uc !== '' && key !== '') {
        LoginSession.deviceCode = uc;
        LoginSession.aesKey = key;
        const sk: preferences.ValueType = await store.get('sessionKey', '');
        if (typeof sk === 'string') {
          LoginSession.sessionKey = sk;
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
        const oc: preferences.ValueType = await store.get('onlyCode', '');
        if (typeof oc === 'string') {
          LoginSession.onlyCode = oc;
        }
        LoginSession.log('会话恢复成功 UC=' + uc);
        return true;
      }
    } catch (error) {
      LoginSession.log('restoreSession失败: ' + (error as BusinessError).message);
    }
    return false;
  }


  /** 兜底获取UIAbility上下文（EntryAbility未注入时） */
  private static fallbackContext(): common.UIAbilityContext | null {
    try {
      const ctx: Object = globalThis.getContext();
      return ctx as common.UIAbilityContext;
    } catch (error) {
      return null;
    }
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
      LoginSession.log('UC=' + LoginSession.deviceCode);

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
    LoginSession.schoolId = pick('schoolId') === '' ? 'SDGY' : pick('schoolId');
    LoginSession.log('parsed sessionKey len=' + LoginSession.sessionKey.length +
      ' userId=' + LoginSession.userId + ' userType=' + LoginSession.userType +
      ' schoolId=' + LoginSession.schoolId);
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
}






