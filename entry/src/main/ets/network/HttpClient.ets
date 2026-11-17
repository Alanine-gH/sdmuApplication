import { util } from '@kit.ArkTS';
import { http } from '@kit.NetworkKit';
import { BusinessError } from '@kit.BasicServicesKit';
import fs from '@ohos.file.fs';
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
 *   - Unique-Code头 = onlyCode（协商响应解密产物=会话UC；实测：登录与业务统一用它）
 *   - Access-Token头 = AES加密的HeadParamsEntity JSON（含sessionKey/userId/userType/xxdm=sdmu）
 *   - POST body = AES加密的JSON
 *   - GET参数 = JSON({}) AES加密 → data=<密文>
 *   - 响应data字段AES加密，需解密
 * 错误码透传：0成功 1005密码错 0006解密失败 0001系统异常 1000未登录 401参数检查失败
 */
export class HttpClient {
  static base64Helper: util.Base64Helper = new util.Base64Helper();

  /** 构建加密后的Access-Token头（AES(HeadParamsEntity JSON, 协商key)）
   * 字段名与原生 HeadParamsEntity.java 1:1 对应（clientVersion/deviceId/deviceModel/
   * sessionKey/userId/userType/xxdm），xxdm 取登录响应 schoolId（原 APK 实证 = 'SDGY'）。
   */
  static async buildEncryptedAccessToken(): Promise<string> {
    const sk: string = LoginSession.sessionKey === '' ? Constants.SESSION_KEY : LoginSession.sessionKey;
    const uid: string = LoginSession.userId === '' ? '' : LoginSession.userId;
    const utype: string = LoginSession.userType === '' ? '1' : LoginSession.userType;
    // 原生 e.java:47 headParamsEntity.setXxdm(schoolId) —— schoolId 来自登录响应 UserEntity.schoolId
    const xxdm: string = LoginSession.schoolId === '' ? 'sdmu' : LoginSession.schoolId;
    const token: Record<string, string> = {
      'clientVersion': Constants.CLIENT_VERSION,
      'deviceId': Constants.DEVICE_ID,
      'deviceModel': Constants.DEVICE_MODEL,
      'sessionKey': sk,
      'userId': uid,
      'userType': utype,
      'xxdm': xxdm
    };
    const json: string = JSON.stringify(token);
    CryptoUtil.log('AT json=' + json);
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

  /** GET + data 加密参数请求（原 APK e.a() 同款：参数明文 JSON AES 加密进 query，响应 data 解密） */
  static async getWithEncParams(path: string, params: Record<string, Object>): Promise<ApiResponse<Object>> {
    const client: http.HttpRequest = http.createHttp();
    try {
      const atEnc: string = await HttpClient.buildEncryptedAccessToken();
      const dataEnc: string = await CryptoUtil.encryptAES(JSON.stringify(params), LoginSession.aesKey);
      const url: string = Constants.SOCKET_HOST + path + '?data=' + encodeURIComponent(dataEnc);
      const header: Record<string, string> = {
        'Access-Token': atEnc,
        'Unique-Code': LoginSession.onlyCode,
        'AppType': Constants.APP_TYPE,
        'User-Agent': 'Dalvik/2.1.0 (Linux; U; Android 14; 25060RK16C Build/UQ1A.240205.11101510)'
      };
      const options: http.HttpRequestOptions = {
        method: http.RequestMethod.GET,
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
      CryptoUtil.log('getWithEncParams fail @' + path + ' code=' + be.code + ' msg=' + be.message);
      return new ApiResponse<Object>(-1, '网络请求失败: ' + be.message + ' @' + path, new Object());
    } finally {
      client.destroy();
    }
  }

  /** 裸 GET 加密响应请求（无 data 参数，如 /open/app/touristList）：响应 data AES 解密 */
  static async getNoParams(path: string): Promise<ApiResponse<Object>> {
    const client: http.HttpRequest = http.createHttp();
    try {
      const atEnc: string = await HttpClient.buildEncryptedAccessToken();
      const header: Record<string, string> = {
        'Access-Token': atEnc,
        'Unique-Code': LoginSession.onlyCode,
        'AppType': Constants.APP_TYPE,
        'User-Agent': 'Dalvik/2.1.0 (Linux; U; Android 14; 25060RK16C Build/UQ1A.240205.11101510)'
      };
      const options: http.HttpRequestOptions = {
        method: http.RequestMethod.GET,
        header: header,
        expectDataType: http.HttpDataType.STRING,
        connectTimeout: 10000,
        readTimeout: 10000
      };
      const response: http.HttpResponse = await client.request(Constants.SOCKET_HOST + path, options);
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
      CryptoUtil.log('getNoParams fail @' + path + ' code=' + be.code + ' msg=' + be.message);
      return new ApiResponse<Object>(-1, '网络请求失败: ' + be.message + ' @' + path, new Object());
    } finally {
      client.destroy();
    }
  }

  /** 旧接口兼容：普通请求（协商/登录/开放接口用）
   * Access-Token：原生 e.g() 里是明文 JSON（k.m 序列化，不加密）。
   * 协商接口（asymKey 非 public）时为空；业务明文接口时带上完整 token JSON。
   */
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
      // 明文业务接口（非协商）：带明文 JSON token（与原生 e.g() 的 k.m(headParamsEntity) 一致）
      if (asymKey === '' && uniqueCode !== '' && path.indexOf('/open/security/asym/key') < 0
        && path.indexOf('/open/auth/login') < 0) {
        const token: Record<string, string> = {
          'clientVersion': Constants.CLIENT_VERSION,
          'deviceId': Constants.DEVICE_ID,
          'deviceModel': Constants.DEVICE_MODEL,
          'sessionKey': LoginSession.sessionKey === '' ? Constants.SESSION_KEY : LoginSession.sessionKey,
          'userId': LoginSession.userId,
          'userType': LoginSession.userType === '' ? '1' : LoginSession.userType,
          'xxdm': LoginSession.schoolId === '' ? 'sdmu' : LoginSession.schoolId
        };
        header['Access-Token'] = JSON.stringify(token);
        header['Unique-Code'] = LoginSession.deviceCode === '' ? uniqueCode : LoginSession.deviceCode;
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

  // ===== T3 misc-worker：意见反馈模块通道（源码 f.o() 逐行还原）=====
  // 原生 f.o()：bVar.j=false 时既不走 k 分支也不走 j 分支 → f.s()（协商key加密）整体短路，
  // 直接 u.e() 发送。FeedbackModel 六个接口（T0/U0/V0/W0/X0/Y0）均显式 j=false，因此：
  //   - Access-Token 头 = 明文 JSON（e.g() k.m(HeadParamsEntity) 原样，无 AES）
  //   - Unique-Code 头 = d.a.d()（设备码）；无 AppType 头（AppType 仅在 f.s() 内添加）
  //   - GET 参数 = 普通 query 对（impl.k() case 1 addQueryStringParameter）
  //   - multipart 表单字段 = 普通 form-data part（impl.k() case 7 addBodyParameter），
  //     data 字段值 = 固定key密文（FeedbackModel 内 c.i(json,固定key) 已加密，无需再包一层）
  //   - 响应 y()：j=false 不走 r() 解密 → data 明文
  // Host = feedbackUrl（SystemSwitch 下发，缺省 ydxy_url_release=https://ydxy.ly-sky.com:8098）。

  /** 明文 Access-Token 头（源码 e.g()：k.m(HeadParamsEntity)，字段与 requestRaw 明文分支一致） */
  private static plainAccessToken(): string {
    const token: Record<string, string> = {
      'clientVersion': Constants.CLIENT_VERSION,
      'deviceId': Constants.DEVICE_ID,
      'deviceModel': Constants.DEVICE_MODEL,
      'sessionKey': LoginSession.sessionKey === '' ? Constants.SESSION_KEY : LoginSession.sessionKey,
      'userId': LoginSession.userId,
      'userType': LoginSession.userType === '' ? '1' : LoginSession.userType,
      'xxdm': LoginSession.schoolId === '' ? 'sdmu' : LoginSession.schoolId
    };
    return JSON.stringify(token);
  }

  /** feedback 头（j=false：明文 AT + 设备码 UC，无 AppType——源码 e.g() 只有这两个头） */
  private static feedbackHeader(contentType: string): Record<string, string> {
    const header: Record<string, string> = {
      'Content-Type': contentType,
      'Access-Token': HttpClient.plainAccessToken(),
      'Unique-Code': LoginSession.deviceCode === '' ?
        (LoginSession.onlyCode === '' ? Constants.UNIQUE_CODE : LoginSession.onlyCode)
        : LoginSession.deviceCode,
      'User-Agent': 'Dalvik/2.1.0 (Linux; U; Android 14; 25060RK16C Build/UQ1A.240205.11101510)'
    };
    return header;
  }

  /** feedback GET（源码 impl.k() case 1：参数逐个 addQueryStringParameter，值原样透传） */
  static async feedbackGet(url: string, formFields: Record<string, string>): Promise<ApiResponse<Object>> {
    const client: http.HttpRequest = http.createHttp();
    try {
      let fullUrl: string = url;
      const keys: string[] = Object.keys(formFields);
      for (let i = 0; i < keys.length; i++) {
        fullUrl = fullUrl + (i === 0 ? '?' : '&') + encodeURIComponent(keys[i]) +
          '=' + encodeURIComponent(formFields[keys[i]]);
      }
      const options: http.HttpRequestOptions = {
        method: http.RequestMethod.GET,
        header: HttpClient.feedbackHeader('application/json'),
        expectDataType: http.HttpDataType.STRING,
        connectTimeout: 15000,
        readTimeout: 50000
      };
      const response: http.HttpResponse = await client.request(fullUrl, options);
      if (response.responseCode === 200) {
        const raw = JSON.parse(response.result as string) as ApiRawData;
        return new ApiResponse<Object>(HttpClient.normalizeCode(raw.code), raw.message, raw.data);
      }
      return new ApiResponse<Object>(-1, 'HTTP ' + response.responseCode + ' @feedback', new Object());
    } catch (error) {
      const be = error as BusinessError;
      CryptoUtil.log('feedbackGet fail @' + url + ' code=' + be.code + ' msg=' + be.message);
      return new ApiResponse<Object>(-1, '网络请求失败: ' + be.message, new Object());
    } finally {
      client.destroy();
    }
  }

  /** 数组字节拼接（multipart 组包用） */
  private static concatBytes(parts: Uint8Array[]): Uint8Array {
    let total: number = 0;
    for (const p of parts) {
      total += p.length;
    }
    const out: Uint8Array = new Uint8Array(total);
    let offset: number = 0;
    for (const p of parts) {
      out.set(p, offset);
      offset += p.length;
    }
    return out;
  }

  /** 单个文件 part（源码 FeedbackPImpl.g() 逐图 SubmitFileBean keyName="imgs" → impl.k() case 7） */
  private static appendFilePart(parts: Uint8Array[], encoder: util.TextEncoder,
    boundary: string, uri: string): void {
    const fileName: string = uri.substring(uri.lastIndexOf('/') + 1);
    const stat: fs.Stat = fs.statSync(uri);
    const file = fs.openSync(uri, fs.OpenMode.READ_ONLY);
    try {
      const buf: ArrayBuffer = new ArrayBuffer(stat.size);
      fs.readSync(file.fd, buf);
      const ext: string = fileName.lastIndexOf('.') >= 0 ?
        fileName.substring(fileName.lastIndexOf('.') + 1).toLowerCase() : 'jpg';
      const mime: string = ext === 'png' ? 'image/png' : 'image/jpeg';
      parts.push(encoder.encodeInto('--' + boundary + '\r\n'));
      parts.push(encoder.encodeInto('Content-Disposition: form-data; name="imgs"; filename="' +
        fileName + '"\r\n'));
      parts.push(encoder.encodeInto('Content-Type: ' + mime + '\r\n\r\n'));
      parts.push(new Uint8Array(buf));
      parts.push(encoder.encodeInto('\r\n'));
    } finally {
      fs.closeSync(file);
    }
  }

  /** feedback 提交 multipart（源码 e.f() POST_MULTIPART j=false）：
   *  表单字段逐个普通 form-data part（data=固定key密文原样，不再外层加密）；
   *  图片文件逐个 imgs part；响应 data 明文 Boolean（j=false）。
   */
  static async feedbackSubmitMultipart(url: string, formFields: Record<string, string>,
    photoUris: string[]): Promise<ApiResponse<Object>> {
    const client: http.HttpRequest = http.createHttp();
    try {
      const boundary: string = '----WebKitFormBoundary' + Date.now();
      const parts: Uint8Array[] = [];
      const encoder: util.TextEncoder = new util.TextEncoder();
      const fieldKeys: string[] = Object.keys(formFields);
      for (const key of fieldKeys) {
        parts.push(encoder.encodeInto('--' + boundary + '\r\n'));
        parts.push(encoder.encodeInto('Content-Disposition: form-data; name="' +
          encodeURIComponent(key) + '"\r\n\r\n'));
        parts.push(encoder.encodeInto(formFields[key] + '\r\n'));
      }
      for (const uri of photoUris) {
        HttpClient.appendFilePart(parts, encoder, boundary, uri);
      }
      parts.push(encoder.encodeInto('--' + boundary + '--\r\n'));
      const body: ArrayBuffer = HttpClient.concatBytes(parts).buffer as ArrayBuffer;
      const options: http.HttpRequestOptions = {
        method: http.RequestMethod.POST,
        header: HttpClient.feedbackHeader('multipart/form-data; boundary=' + boundary),
        extraData: body,
        expectDataType: http.HttpDataType.STRING,
        connectTimeout: 15000,
        readTimeout: 50000
      };
      const response: http.HttpResponse = await client.request(url, options);
      if (response.responseCode === 200) {
        const raw = JSON.parse(response.result as string) as ApiRawData;
        return new ApiResponse<Object>(HttpClient.normalizeCode(raw.code), raw.message, raw.data);
      }
      return new ApiResponse<Object>(-1, 'HTTP ' + response.responseCode + ' @feedback submit', new Object());
    } catch (error) {
      const be = error as BusinessError;
      CryptoUtil.log('feedbackSubmit fail code=' + be.code + ' msg=' + be.message);
      return new ApiResponse<Object>(-1, '网络请求失败: ' + be.message, new Object());
    } finally {
      client.destroy();
    }
  }
}





