import { LoginSession } from './LoginSession';
import { http } from '@kit.NetworkKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { ApiResponse } from '../model/ResponseModel';
import { Constants } from '../data/Constants';

interface ApiRawData {
  code: Object;
  message: string;
  data: Object;
}

interface HttpHeaderBag {
  'Content-Type': string;
  'Access-Token': string;
  'Unique-Code': string;
  'AppType': string;
}

/**
 * HTTP 网络封装 — 按安卓版抓包协议复刻（2026-11-16 验证）：
 *   Host: http://mcp.sdmu.edu.cn:8081（校园内网）
 *   必带请求头：
 *     Access-Token: {"clientVersion":"3.2.0","deviceId":"...","deviceModel":"...",
 *                    "sessionKey":"...","userId":"...","userType":"","xxdm":""}
 *     Unique-Code: <UUID>
 *     AppType: ydxy
 * 服务器可能不可达（非校园网环境），所有异常均被捕获并转换为错误状态的 ApiResponse。
 */
export class HttpClient {
  static buildAccessToken(userId: string): string {
    const token: Record<string, string> = {
      'clientVersion': Constants.CLIENT_VERSION,
      'deviceId': Constants.DEVICE_ID,
      'deviceModel': Constants.DEVICE_MODEL,
      'sessionKey': LoginSession.sessionKey === '' ? Constants.SESSION_KEY : LoginSession.sessionKey,
      'userId': userId,
      'userType': LoginSession.userType === '' ? '1' : LoginSession.userType,
      'xxdm': 'sdmu'
    };
    return JSON.stringify(token);
  }

  static async get(path: string): Promise<ApiResponse<Object>> {
    return HttpClient.request(path, http.RequestMethod.GET, '', 'application/json');
  }

  static async post(path: string, body: string): Promise<ApiResponse<Object>> {
    return HttpClient.request(path, http.RequestMethod.POST, body, 'application/json');
  }

  static async postForm(path: string, formBody: string): Promise<ApiResponse<Object>> {
    return HttpClient.request(path, http.RequestMethod.POST, formBody, 'application/x-www-form-urlencoded');
  }

  static async request(path: string, method: http.RequestMethod, body: string, contentType: string): Promise<ApiResponse<Object>> {
    const client: http.HttpRequest = http.createHttp();
    try {
      const headerBag: HttpHeaderBag = {
        'Content-Type': contentType,
        'Access-Token': HttpClient.buildAccessToken(''),
        'Unique-Code': Constants.UNIQUE_CODE,
        'AppType': Constants.APP_TYPE
      };
      const options: http.HttpRequestOptions = {
        method: method,
        extraData: method === http.RequestMethod.POST ? body : undefined,
        header: headerBag as object as Record<string, string>,
        expectDataType: http.HttpDataType.STRING,
        connectTimeout: 10000,
        readTimeout: 10000
      };
      const response: http.HttpResponse = await client.request(Constants.SOCKET_HOST + path, options);
      if (response.responseCode === 200) {
        const raw = JSON.parse(response.result as string) as ApiRawData;
        return new ApiResponse<Object>(HttpClient.normalizeCode(raw.code), raw.message, raw.data);
      }
      return new ApiResponse<Object>(-1, 'HTTP ' + response.responseCode, new Object());
    } catch (error) {
      const err = error as BusinessError;
      return new ApiResponse<Object>(-1, '网络请求失败: ' + err.message, new Object());
    } finally {
      client.destroy();
    }
  }

  /**
   * 原始请求（协商/登录专用）：
   * 支持自定义 Unique-Code 与 Asym-Key 头（安卓 GetKeyUtil/LoginModel 协议）
   * 修复：GET不带extraData（鸿蒙http带extraData的GET会异常）；带安卓User-Agent避免服务器WAF 401
   */
  static async requestRaw(path: string, method: string, body: string, contentType: string,
    uniqueCode: string, asymKey: string): Promise<ApiResponse<Object>> {
    const client: http.HttpRequest = http.createHttp();
    try {
      const header: Record<string, string> = {
        'Content-Type': contentType,
        'Access-Token': HttpClient.buildAccessToken(''),
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
      const err = error as BusinessError;
      return new ApiResponse<Object>(-1, '网络请求失败: ' + err.message + ' @' + path, new Object());
    } finally {
      client.destroy();
    }
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
}



