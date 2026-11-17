import { BusinessError } from '@kit.BasicServicesKit';
import { util } from '@kit.ArkTS';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { HttpClient } from './HttpClient';
import { CryptoUtil } from './CryptoUtil';
import { ApiResponse } from '../model/ResponseModel';
import { UserInfo } from '../model/UserModel';
import { Constants } from '../data/Constants';
import { ApiService } from './ApiService';

const TAG = 0x0000;
const DOMAIN = 'SDMU';

/**
 * 登录会话管理 — 1:1 复刻原生 GetKeyUtil + LoginModel（服务器实测协议）：
 *   1. GET /open/security/asym/key（Asym-Key: public）动态取RSA公钥
 *   2. POST 协商（Asym-Key: private，Unique-Code=随机UUID）→ onlyCode
 *   3. 登录：body=AES(完整实体)，Unique-Code=onlyCode → code=0
 *   4. 解密响应 → session_key + 真实用户信息
 * 错误码：0成功 1005账号密码错 0006解密失败 0001系统异常
 */
export class LoginSession {
  static aesKey: string = '';
  static onlyCode: string = '';
  static sessionKey: string = '';
  static userType: string = '';
  static userId: string = '';
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

  private static fail(code: number, msg: string, account: string): ApiResponse<UserInfo> {
    LoginSession.log('FAIL [' + LoginSession.step + '] code=' + code + ' msg=' + msg);
    return new ApiResponse<UserInfo>(code, msg, ApiService.mockUser(account));
  }

  static async login(account: string, password: string): Promise<ApiResponse<UserInfo>> {
    try {
      // ===== 第0步：GET动态公钥 =====
      LoginSession.step = 'fetchPubKey';
      const pubResp: ApiResponse<Object> = await HttpClient.requestRaw(
        '/mobileapi_ydxy/open/security/asym/key', 'GET', '', 'application/json',
        LoginSession.randomUuid(), 'public');
      let pubKey: string = Constants.RSA_PUBLIC_KEY;
      if (pubResp.code === 0 && pubResp.data !== null && pubResp.data !== undefined) {
        const fetched: string = pubResp.data as string;
        if (fetched !== '' && fetched.length > 100) {
          pubKey = fetched;
        }
      }
      LoginSession.log('pubKey len=' + pubKey.length + ' 前20=' + pubKey.substring(0, 20));

      // ===== 第1步：生成key+协商body =====
      LoginSession.step = 'genKey';
      LoginSession.aesKey = CryptoUtil.generateKey();
      LoginSession.log('aesKey=' + LoginSession.aesKey.substring(0, 8) + '...');

      LoginSession.step = 'rsaNegotiate';
      const negotiateBody: string = await CryptoUtil.buildNegotiateBody(LoginSession.aesKey, pubKey);
      LoginSession.log('negoBody len=' + negotiateBody.length);

      // ===== 第2步：POST协商 =====
      LoginSession.step = 'negotiateRequest';
      const negoResp: ApiResponse<Object> = await HttpClient.requestRaw(
        '/mobileapi_ydxy/open/security/asym/key', 'POST', negotiateBody, 'text/plain',
        LoginSession.randomUuid(), 'private');
      if (negoResp.code !== 0) {
        return LoginSession.fail(negoResp.code, 'key协商失败: ' + negoResp.message, account);
      }
      const negoData: string = negoResp.data as string ?? '';
      if (negoData === '') {
        return LoginSession.fail(negoResp.code, 'key协商响应data为空', account);
      }

      // ===== 第3步：解密onlyCode =====
      LoginSession.step = 'decryptOnlyCode';
      LoginSession.onlyCode = await CryptoUtil.decryptAES(negoData, LoginSession.aesKey);
      LoginSession.log('onlyCode=' + LoginSession.onlyCode);

      // ===== 第4步：AES加密登录body =====
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

      // ===== 第5步：登录（Unique-Code=onlyCode） =====
      LoginSession.step = 'loginRequest';
      const loginResp: ApiResponse<Object> = await HttpClient.requestRaw(
        '/mobileapi_ydxy/open/auth/login', 'POST', loginBody, 'text/plain',
        LoginSession.onlyCode, '');
      LoginSession.log('login resp code=' + loginResp.code + ' msg=' + loginResp.message);
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

      // ===== 第6步：解密用户信息 =====
      LoginSession.step = 'decryptUser';
      const userJson: string = await CryptoUtil.decryptAES(loginData, LoginSession.aesKey);
      const user: UserInfo = LoginSession.parseUserEntity(userJson);
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

