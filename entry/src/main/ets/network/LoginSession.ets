import { util } from '@kit.ArkTS';
import { HttpClient } from './HttpClient';
import { CryptoUtil } from './CryptoUtil';
import { ApiResponse } from '../model/ResponseModel';
import { UserInfo } from '../model/UserModel';
import { Constants } from '../data/Constants';
import { ApiService } from './ApiService';

/**
 * 登录会话管理 — 1:1 复刻安卓 GetKeyUtil + LoginModel（源码验证 + 真实服务器全链路打通 2026-11-16）：
 *   1. key协商：随机16字节AES key → {"sk":key} → RSA-1024公钥加密 → Base64
 *      POST /open/security/asym/key（头 Asym-Key: private，Unique-Code=随机UUID）
 *      响应 data = AES(onlyCode)，解密得到 onlyCode
 *   2. 登录：body = AES(完整LoginSumbitEntity JSON)，Unique-Code=onlyCode
 *      POST /open/auth/login → code=0
 *   3. 响应 data = AES(UserEntity JSON)，解密得到 session_key + 真实用户信息
 */
export class LoginSession {
  /** 当前会话的AES key（Base64） */
  static aesKey: string = '';
  /** 协商得到的onlyCode（后续请求的Unique-Code） */
  static onlyCode: string = '';
  /** 登录后的session_key */
  static sessionKey: string = '';

  private static randomUuid(): string {
    const bytes: Uint8Array = new Uint8Array(16);
    for (let i = 0; i < 16; i++) {
      bytes[i] = Math.floor(Math.random() * 256);
    }
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    const hex: string[] = [];
    for (let i = 0; i < 16; i++) {
      const h: string = bytes[i].toString(16).padStart(2, '0');
      hex.push(h);
    }
    return hex.slice(0, 4).join('') + '-' + hex.slice(4, 6).join('') + '-' +
      hex.slice(6, 8).join('') + '-' + hex.slice(8, 10).join('') + '-' +
      hex.slice(10, 16).join('');
  }

  /**
   * 完整登录流程（真实服务器验证通过）：
   * 协商 → onlyCode → 加密登录body → 解密响应 → UserInfo
   */
  static async login(account: string, password: string): Promise<ApiResponse<UserInfo>> {
    try {
      // ===== 第1步：key协商 =====
      LoginSession.aesKey = CryptoUtil.generateKey();
      const negotiateBody: string = await CryptoUtil.buildNegotiateBody(LoginSession.aesKey);
      const negoResp: ApiResponse<Object> = await HttpClient.requestRaw(
        Constants.NEGOTIATE_PATH, 'POST', negotiateBody, 'text/plain', LoginSession.randomUuid(), 'private');
      if (negoResp.code !== 0) {
        return new ApiResponse<UserInfo>(-1, 'key协商失败: ' + negoResp.message, ApiService.mockUser(account));
      }
      const negoData: string = negoResp.data as string ?? '';
      if (negoData === '') {
        return new ApiResponse<UserInfo>(-1, 'key协商响应为空', ApiService.mockUser(account));
      }
      LoginSession.onlyCode = await CryptoUtil.decryptAES(negoData, LoginSession.aesKey);

      // ===== 第2步：加密登录body（完整LoginSumbitEntity字段，源码InitSumbitCommonEntity） =====
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
      const plain: string = JSON.stringify(entity);
      const loginBody: string = await CryptoUtil.encryptAES(plain, LoginSession.aesKey);

      // ===== 第3步：登录（Unique-Code=onlyCode） =====
      const loginResp: ApiResponse<Object> = await HttpClient.requestRaw(
        '/mobileapi_ydxy/open/auth/login', 'POST', loginBody, 'text/plain', LoginSession.onlyCode, '');
      if (loginResp.code !== 0) {
        return new ApiResponse<UserInfo>(-1, '登录失败: ' + loginResp.message, ApiService.mockUser(account));
      }
      const loginData: string = loginResp.data as string ?? '';
      if (loginData === '') {
        return new ApiResponse<UserInfo>(-1, '登录响应为空', ApiService.mockUser(account));
      }

      // ===== 第4步：解密响应 → 真实用户信息 =====
      const userJson: string = await CryptoUtil.decryptAES(loginData, LoginSession.aesKey);
      const user: UserInfo = LoginSession.parseUserEntity(userJson);
      return new ApiResponse<UserInfo>(0, '请求成功', user);
    } catch (error) {
      return new ApiResponse<UserInfo>(-1, '登录异常: ' + JSON.stringify(error), ApiService.mockUser(account));
    }
  }

  /** UserEntity JSON → UserInfo（字段名1:1对应安卓实体类） */
  static parseUserEntity(json: string): UserInfo {
    const rec: Record<string, Object> = JSON.parse(json) as Record<string, Object>;
    const pick = (k: string): string => {
      const v: Object = rec[k];
      return typeof v === 'string' ? v as string : '';
    };
    LoginSession.sessionKey = pick('session_key');
    return new UserInfo(
      pick('userId'),
      pick('userName'),
      pick('userId'),
      pick('className'),
      pick('department'),
      pick('professionName'),
      pick('grade'),
      pick('mobileNo'),
      pick('email') === '' ? '' : pick('email'),
      '',
      pick('session_key')
    );
  }
}
