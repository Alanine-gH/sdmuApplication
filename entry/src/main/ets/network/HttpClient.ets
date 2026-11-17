import { util } from '@kit.ArkTS';
import { http } from '@kit.NetworkKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { ApiResponse } from '../model/ResponseModel';
import { CryptoUtil } from './CryptoUtil';
import { LoginSession } from './LoginSession';
import { Constants } from '../data/Constants';

interface ApiRawData {
  code: Object;
  message: string;
  data: Object;
}

/**
 * HTTP网络封装 — 1:1复刻原生 f.java s() 方法加密请求协议（2026-11-17服务器实测）：
 *   - Unique-Code头 = onlyCode（协商产物）
 *   - Access-Token头 = AES加密的HeadParamsEntity JSON（含sessionKey/userId/userType/xxdm=sdmu）
 *   - POST body = AES加密的JSON
 *   - GET参数 = JSON({}) AES加密 → data=<密文>
 *   - 响应data字段AES加密，需解密
 * 错误码透传：0成功 1005密码错 0006解密失败 0001系统异常 1000未登录 401参数检查失败
 */
export class HttpClient {
  static base64Helper: util.Base64Helper = new util.Base64Helper();

  /** 构建加密后的Access-Token头（AES(HeadParamsEntity JSON, 协商key)） */
  static async buildEncryptedAccessToken(): Promise<string> {
    const sk: string = LoginSession.sessionKey === '' ? Constants.SESSION_KEY : LoginSession.sessionKey;
    const uid: string = LoginSession.userId === '' ? '' : LoginSession.userId;
    const utype: string = LoginSession.userType === '' ? '1' : LoginSession.userType;
    const token: Record<string, string> = {
      'clientVersion': Constants.CLIENT_VERSION,
      'deviceId': Constants.DEVICE_ID,
      'deviceModel': Constants.DEVICE_MODEL,
      'sessionKey': sk,
      'userId': uid,
      'userType': utype,
      'xxdm': 'sdmu'
    };
    const json: string = JSON.stringify(token);
    return CryptoUtil.encryptAES(json, LoginSession.aesKey);
  }

  static normalizeCode(raw: Object): number {
    if (typeof raw === 'number') {
      return raw as number;
    }
    if (typeof raw === 'string') {
      return Number(raw as string);
    }
    return -1;
  }

  /** 解密响应data字段（AES-协商key） */
  static async decryptData(dataB64: string): Promise<string> {
    return CryptoUtil.decryptAES(dataB64, LoginSession.aesKey);
  }

  /**
   * 加密业务请求（1:1复刻f.java s()方法）：
   * GET：参数JSON加密 → data=参数
   * POST：body JSON加密
   * 返回 ApiResponse（data为解密后字符串，业务自行JSON.parse）
   */
  static async bizRequest(path: string, method: string, params: Record<string, Object>): Promise<ApiResponse<Object>> {
    const client: http.HttpRequest = http.createHttp();
    try {
      const atEnc: string = await HttpClient.buildEncryptedAccessToken();
      let body: string = '';
      let url: string = Constants.SOCKET_HOST + path;
      if (method === 'POST') {
        body = await CryptoUtil.encryptAES(JSON.stringify(params), LoginSession.aesKey);
      } else {
        const paramJson: string = JSON.stringify(params);
        const dataEnc: string = await CryptoUtil.encryptAES(paramJson, LoginSession.aesKey);
        url = url + (path.includes('?') ? '&' : '?') + 'data=' + encodeURIComponent(dataEnc);
      }
      const header: Record<string, string> = {
        'Content-Type': 'text/plain',
        'Access-Token': atEnc,
        'Unique-Code': LoginSession.onlyCode,
        'AppType': Constants.APP_TYPE,
        'User-Agent': 'Dalvik/2.1.0 (Linux; U; Android 14; 25060RK16C Build/UQ1A.240205.11101510)'
      };
      const reqMethod: http.RequestMethod = method === 'POST' ? http.RequestMethod.POST : http.RequestMethod.GET;
      const options: http.HttpRequestOptions = {
        method: reqMethod,
        extraData: reqMethod === http.RequestMethod.POST ? body : undefined,
        header: header,
        expectDataType: http.HttpDataType.STRING,
        connectTimeout: 10000,
        readTimeout: 10000
      };
      const response: http.HttpResponse = await client.request(url, options);
      if (response.responseCode === 200) {
        const raw = JSON.parse(response.result as string) as ApiRawData;
        const code: number = HttpClient.normalizeCode(raw.code);
        const dataStr: string = raw.data as string ?? '';
        if (code === 0 && dataStr !== '') {
          const plain: string = await HttpClient.decryptData(dataStr);
          return new ApiResponse<Object>(0, raw.message, plain as Object);
        }
        return new ApiResponse<Object>(code, raw.message, raw.data);
      }
      return new ApiResponse<Object>(-1, 'HTTP ' + response.responseCode + ' @' + path, new Object());
    } catch (error) {
      const be = error as BusinessError;
      CryptoUtil.log('bizRequest fail @' + path + ' code=' + be.code + ' msg=' + be.message);
      return new ApiResponse<Object>(-1, '网络请求失败: ' + be.message + ' @' + path, new Object());
    } finally {
      client.destroy();
    }
  }

  /** 旧接口兼容：普通请求（协商/登录/开放接口用） */
  static async requestRaw(path: string, method: string, body: string, contentType: string,
    uniqueCode: string, asymKey: string): Promise<ApiResponse<Object>> {
    const client: http.HttpRequest = http.createHttp();
    try {
      const header: Record<string, string> = {
        'Content-Type': contentType,
        'Access-Token': '',
        'Unique-Code': uniqueCode,
        'AppType': Constants.APP_TYPE,
        'User-Agent': 'Dalvik/2.1.0 (Linux; U; Android 14; 25060RK16C Build/UQ1A.240205.11101510)'
      };
      if (asymKey !== '') {
        header['Asym-Key'] = asymKey;
      }
      const reqMethod: http.RequestMethod = method === 'POST' ? http.RequestMethod.POST : http.RequestMethod.GET;
      const options: http.HttpRequestOptions = {
        method: reqMethod,
        extraData: reqMethod === http.RequestMethod.POST ? body : undefined,
        header: header,
        expectDataType: http.HttpDataType.STRING,
        connectTimeout: 10000,
        readTimeout: 10000
      };
      const response: http.HttpResponse = await client.request(Constants.SOCKET_HOST + path, options);
      if (response.responseCode === 200) {
        const raw = JSON.parse(response.result as string) as ApiRawData;
        return new ApiResponse<Object>(HttpClient.normalizeCode(raw.code), raw.message, raw.data);
      }
      return new ApiResponse<Object>(-1, 'HTTP ' + response.responseCode + ' @' + path, new Object());
    } catch (error) {
      const be = error as BusinessError;
      CryptoUtil.log('requestRaw fail @' + path + ' code=' + be.code + ' msg=' + be.message);
      return new ApiResponse<Object>(-1, '网络请求失败: ' + be.message + ' @' + path, new Object());
    } finally {
      client.destroy();
    }
  }

  static async request(path: string, method: http.RequestMethod, body: string, contentType: string): Promise<ApiResponse<Object>> {
    return HttpClient.requestRaw(path, method === http.RequestMethod.POST ? 'POST' : 'GET', body, contentType,
      LoginSession.onlyCode === '' ? Constants.UNIQUE_CODE : LoginSession.onlyCode, '');
  }

  static async get(path: string): Promise<ApiResponse<Object>> {
    return HttpClient.requestRaw(path, 'GET', '', 'application/json',
      LoginSession.onlyCode === '' ? Constants.UNIQUE_CODE : LoginSession.onlyCode, '');
  }

  static async post(path: string, body: string): Promise<ApiResponse<Object>> {
    return HttpClient.requestRaw(path, 'POST', body, 'application/json',
      LoginSession.onlyCode === '' ? Constants.UNIQUE_CODE : LoginSession.onlyCode, '');
  }

  static async postForm(path: string, formBody: string): Promise<ApiResponse<Object>> {
    return HttpClient.requestRaw(path, 'POST', formBody, 'application/x-www-form-urlencoded',
      LoginSession.onlyCode === '' ? Constants.UNIQUE_CODE : LoginSession.onlyCode, '');
  }
}

