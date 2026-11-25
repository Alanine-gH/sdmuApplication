import { util } from '@kit.ArkTS';
import { http } from '@kit.NetworkKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { promptAction, router } from '@kit.ArkUI';
import fs from '@ohos.file.fs';
import { ApiResponse } from '../model/ResponseModel';
import { CryptoUtil } from './CryptoUtil';
import { LoginSession } from './LoginSession';
import { Constants } from '../data/Constants';
import { PreferencesUtil } from '../data/PreferencesUtil';
import { UrlSecurityHelper } from '../common/UrlSecurityHelper';

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

  // ===== 登录失效统一拦截（W11：源码 NetUtils/BaseActivityEx 复刻）=====
  /** 业务码 1000 = 登录已失效（源码 netutil/f.java j(str)："1000".equals(str)） */
  private static readonly SESSION_EXPIRED_CODE: number = 1000;
  /** 防抖标记：并发多请求同时返回 1000 时只触发一次清会话+跳转 */
  private static sessionExpiredHandling: boolean = false;

  /** 当前是否在登录页（防循环：登录页上 open/auth 接口的 1000 不触发统一跳转） */
  private static isOnLoginPage(): boolean {
    try {
      const state: router.RouterState = router.getState();
      return state.name === 'LoginPage' || state.path.indexOf('LoginPage') >= 0;
    } catch (error) {
      return false;
    }
  }

  /**
   * 业务响应 code=1000 统一处理 — APK 源码证据链：
   *   1. netutil/f.java(NetUtils).f()：code=="1000" → c()(清缓存) +
   *      d.a.f(new UserEntity())（登录会话整体重置）+ EventBus(19,1000)
   *   2. BaseActivityEx.c2()：EventBusBean code==19 data==1000 →
   *      弹"下线通知/登录失效，请重新登录"（"重新登录"按钮）
   *   3. BaseActivityEx$e.a()：确认 → g0.b()（清 Activity 栈）+ logout() → 跳登录页
   * HAP 等价：清 LoginSession（clearSession=新 UserEntity 落盘）+ isLogin=false +
   * toast"登录已失效，请重新登录" + router.clear() + replaceUrl LoginPage（登录页为唯一页）。
   * 仅在非登录页触发；并发 1000 由防抖标记收敛为一次。
   */
  static async handleSessionExpired(): Promise<void> {
    if (HttpClient.isOnLoginPage()) {
      // 登录页自身请求的 1000（如短信登录异常码）→ 不清会话不跳转，交页面分支处理
      HttpClient.sessionExpiredHandling = false;
      return;
    }
    if (HttpClient.sessionExpiredHandling) {
      return;
    }
    HttpClient.sessionExpiredHandling = true;
    try {
      // = d.a.f(new UserEntity())：清用户态并持久化（保留设备协商产物，重登免协商）
      await LoginSession.clearSession();
      await PreferencesUtil.putBoolean(Constants.KEY_IS_LOGIN, false);
      promptAction.showToast({ message: '登录已失效，请重新登录' });
      // = g0.b() + logout()：清栈后当前页替换为登录页（FontSizePage 登出同款顺序）
      router.clear();
      router.replaceUrl({ url: 'pages/LoginPage' });
    } catch (error) {
      const be = error as BusinessError;
      CryptoUtil.log('handleSessionExpired fail: ' + be.message);
      HttpClient.sessionExpiredHandling = false;
    }
  }

  /** code 归一后统一挂钩：1000 → 登录失效处理；0 → 复位防抖标记 */
  private static interceptSessionCode(code: number): void {
    if (code === HttpClient.SESSION_EXPIRED_CODE) {
      HttpClient.handleSessionExpired();
    } else if (code === 0) {
      HttpClient.sessionExpiredHandling = false;
    }
  }

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
        HttpClient.interceptSessionCode(code);
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
        HttpClient.interceptSessionCode(code);
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
        HttpClient.interceptSessionCode(code);
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
  private static plainAccessToken(): string {    const token: Record<string, string> = {
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

  // ===== [W1 light-url] WebView 免登专用加密 AT（APK X5LightActivity.B3()+a.b.a.c.i 逐行还原）=====
  // 源码依据：
  // - X5LightActivity.B3() L1452-1461 / LightActivity.l3() L829-838：明文 AT = Gson(HeadParamsEntity)，
  //   只 set userId/userType/sessionKey/xxdm 四字段；k.m = GsonBuilder().disableHtmlEscaping().create()
  //   （gson/f.java c() 仅关 htmlSafe，serializeNulls 保持默认 false）→ clientVersion/deviceId/deviceModel
  //   为 null 被省略 → 4 字段 JSON，键序按实体声明序 = sessionKey,userId,userType,xxdm。
  // - 加密 = c.i(plain, strE) → SecretUtil c.i L29-31 / z.d L42-51：
  //   Base64(AES/ECB/PKCS5(plain, base64decode(randomBase64AESKey)))——HAP 同款
  //   CryptoUtil.encryptAES(json, LoginSession.aesKey)（登录协商生成的 aesKey 即 APK randomBase64AESKey）。
  // - 用途：thirdAuth 等服务端 H5 单点页（LX=8"第三方应用对接移动校园单点"）解析的 AT；
  //   与业务 API 的 7 字段 AT（buildEncryptedAccessToken）并存，互不影响。
  /** WebView 免登 4 字段加密 AT（APK B3() 明文 + c.i() AES，同步；无会话时抛错由页面 catch 兜底） */
  static buildWebEncryptedAccessToken(): string {
    const sk: string = LoginSession.sessionKey === '' ? Constants.SESSION_KEY : LoginSession.sessionKey;
    const uid: string = LoginSession.userId;
    const utype: string = LoginSession.userType === '' ? '1' : LoginSession.userType;
    const xxdm: string = LoginSession.schoolId === '' ? 'sdmu' : LoginSession.schoolId;
    const token: Record<string, string> = {
      'sessionKey': sk,
      'userId': uid,
      'userType': utype,
      'xxdm': xxdm
    };
    return CryptoUtil.encryptAES(JSON.stringify(token), LoginSession.aesKey);
  }

  // ===== [W12 message-series] 专用通道 =====

  /**
   * j=false 明文 GET（源码 NetUtils.f.o()：bVar.j=false 跳过 s() 加密分支，BaseRemoteXUtils3Impl.k
   * case1 把 f13171d 逐个 addQueryStringParameter；响应 y() 不走 r() 解密 → data 明文）。
   * 头 = e.g()：Access-Token=明文 7 字段 JSON（k.m(HeadParamsEntity)）+ Unique-Code=onlyCode
   * （W1 实测定案 d.a.d()=登录会话 onlyCode；2026-11-18 EmcMessageContent 探针 code=0 同款头）。
   * 无 AppType 头。EmcMessageDetailActivity 拉详情用。
   * 响应同样流经 APK NetUtils.y()（j=false 不走 r() 解密但 code 仍进 f() 统一拦截），
   * 故与加密通道同挂钩 interceptSessionCode（W11-review 补齐）。
   */
  static async plainBizGet(path: string, params: Record<string, string>): Promise<ApiResponse<Object>> {
    const client: http.HttpRequest = http.createHttp();
    try {
      let url: string = Constants.SOCKET_HOST + path;
      const keys: string[] = Object.keys(params);
      for (let i = 0; i < keys.length; i++) {
        url = url + (i === 0 ? '?' : '&') + encodeURIComponent(keys[i]) + '=' +
          encodeURIComponent(params[keys[i]]);
      }
      const header: Record<string, string> = {
        'Access-Token': HttpClient.plainAccessToken(),
        'Unique-Code': LoginSession.onlyCode === '' ? Constants.UNIQUE_CODE : LoginSession.onlyCode,
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
        // W11 统一拦截：APK j=false 明文业务通道响应同样流经 NetUtils.y()→f()，code=1000 触发统一处理
        HttpClient.interceptSessionCode(code);
        return new ApiResponse<Object>(code, raw.message, raw.data);
      }
      return new ApiResponse<Object>(-1, 'HTTP ' + response.responseCode + ' @' + path, new Object());
    } catch (error) {
      const be = error as BusinessError;
      CryptoUtil.log('plainBizGet fail @' + path + ' code=' + be.code + ' msg=' + be.message);
      return new ApiResponse<Object>(-1, '网络请求失败: ' + be.message + ' @' + path, new Object());
    } finally {
      client.destroy();
    }
  }

  // ===== [W25 misc-b] 聚合认证外部域通道（源码 PolymerizationModel.W0 逐行还原）=====
  // bVarD.f13168a=POST_CONTENT；bVarD.j=false（不走 s() 加密分支→无 Access-Token/AppType 头）；
  // bVarD.f13170c=Z0()（请求头 map 被整体替换为 {appid,secret,userId}）；l="application/json"；
  // e=k.m(map)（body 明文 JSON）；m=new polymerization.a()（响应 {meta:{success,message}} → code 0/1）。
  // URL=扫码 result.domain 拼接的完整外部域（非校内 SOCKET_HOST）。

  /** 外部域明文 JSON POST（完整 URL + 自定义头 + application/json 明文 body） */
  static async plainJsonPost(url: string, headers: Record<string, string>,
    body: string): Promise<ApiResponse<Object>> {
    const client: http.HttpRequest = http.createHttp();
    try {
      const header: Record<string, string> = {
        'Content-Type': 'application/json',
        'User-Agent': 'Dalvik/2.1.0 (Linux; U; Android 14; 25060RK16C Build/UQ1A.240205.11101510)'
      };
      const keys: string[] = Object.keys(headers);
      for (const k of keys) {
        header[k] = headers[k];
      }
      const options: http.HttpRequestOptions = {
        method: http.RequestMethod.POST,
        extraData: body,
        header: header,
        expectDataType: http.HttpDataType.STRING,
        connectTimeout: 10000,
        readTimeout: 10000
      };
      const response: http.HttpResponse = await client.request(url, options);
      if (response.responseCode === 200) {
        return new ApiResponse<Object>(0, '', response.result as Object);
      }
      return new ApiResponse<Object>(-1, 'HTTP ' + response.responseCode + ' @' + url, new Object());
    } catch (error) {
      const be = error as BusinessError;
      CryptoUtil.log('plainJsonPost fail @' + url + ' code=' + be.code + ' msg=' + be.message);
      return new ApiResponse<Object>(-1, '网络请求失败: ' + be.message + ' @' + url, new Object());
    } finally {
      client.destroy();
    }
  }

  /**
   * push 域名加密 POST（源码 PushModel：e.d=POST_CONTENT + m(true) 走 s() 加密管道；
   * f13170c 额外 put xxdm → f13170c 是请求头 map，故 xxdm 为明文请求头，值=登录会话 schoolId）。
   * Host = lianyi_url_release = https://www.yibaogao.com（Api.PUSH_HOST）；body=AES(JSON)。
   * 2026-11-18 实测该域名校园网不可达（SSL EOF/http 502）→ 调用方按失败走真实空态。
   */
  static async pushBizPost(fullUrl: string, params: Record<string, Object>): Promise<ApiResponse<Object>> {
    const client: http.HttpRequest = http.createHttp();
    try {
      const atEnc: string = await HttpClient.buildEncryptedAccessToken();
      const body: string = await CryptoUtil.encryptAES(JSON.stringify(params), LoginSession.aesKey);
      const header: Record<string, string> = {
        'Content-Type': 'text/plain',
        'Access-Token': atEnc,
        'Unique-Code': LoginSession.onlyCode === '' ? Constants.UNIQUE_CODE : LoginSession.onlyCode,
        'AppType': Constants.APP_TYPE,
        'xxdm': LoginSession.schoolId === '' ? 'sdmu' : LoginSession.schoolId,
        'User-Agent': 'Dalvik/2.1.0 (Linux; U; Android 14; 25060RK16C Build/UQ1A.240205.11101510)'
      };
      const options: http.HttpRequestOptions = {
        method: http.RequestMethod.POST,
        extraData: body,
        header: header,
        expectDataType: http.HttpDataType.STRING,
        connectTimeout: 10000,
        readTimeout: 10000
      };
      const response: http.HttpResponse = await client.request(fullUrl, options);
      if (response.responseCode === 200) {
        const raw = JSON.parse(response.result as string) as ApiRawData;
        const code: number = HttpClient.normalizeCode(raw.code);
        HttpClient.interceptSessionCode(code);
        const dataStr: string = raw.data as string ?? '';
        if (code === 0 && dataStr !== '') {
          const plain: string = await HttpClient.decryptData(dataStr);
          return new ApiResponse<Object>(0, raw.message, plain as Object);
        }
        return new ApiResponse<Object>(code, raw.message, raw.data);
      }
      return new ApiResponse<Object>(-1, 'HTTP ' + response.responseCode + ' @push', new Object());
    } catch (error) {
      const be = error as BusinessError;
      CryptoUtil.log('pushBizPost fail @' + fullUrl + ' code=' + be.code + ' msg=' + be.message);
      return new ApiResponse<Object>(-1, '网络请求失败: ' + be.message + ' @push', new Object());
    } finally {
      client.destroy();
    }
  }

  /**
   * [W20 social] push 域加密 GET（源码 SocialModel/MarketModel e.b 管道：GET data=AES(JSON 参数)，
   * 请求头与 pushBizPost 同款（e.g 明文 AT + onlyCode + AppType + 明文请求头 xxdm）。
   * postInfo/comments/likes/getSomeoneCircleList/getCircleRecentlyPic/getUserScores 走本通道。
   * Host = https://www.yibaogao.com（W12/2026-11-18 实测校园网不可达 → 调用方按失败走真实错误态）。
   */
  static async pushBizGet(fullUrl: string, params: Record<string, Object>): Promise<ApiResponse<Object>> {
    const client: http.HttpRequest = http.createHttp();
    try {
      const atEnc: string = await HttpClient.buildEncryptedAccessToken();
      const dataEnc: string = await CryptoUtil.encryptAES(JSON.stringify(params), LoginSession.aesKey);
      const url: string = fullUrl + '?data=' + encodeURIComponent(dataEnc);
      const header: Record<string, string> = {
        'Access-Token': atEnc,
        'Unique-Code': LoginSession.onlyCode === '' ? Constants.UNIQUE_CODE : LoginSession.onlyCode,
        'AppType': Constants.APP_TYPE,
        'xxdm': LoginSession.schoolId === '' ? 'sdmu' : LoginSession.schoolId,
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
        HttpClient.interceptSessionCode(code);
        const dataStr: string = raw.data as string ?? '';
        if (code === 0 && dataStr !== '') {
          const plain: string = await HttpClient.decryptData(dataStr);
          return new ApiResponse<Object>(0, raw.message, plain as Object);
        }
        return new ApiResponse<Object>(code, raw.message, raw.data);
      }
      return new ApiResponse<Object>(-1, 'HTTP ' + response.responseCode + ' @push', new Object());
    } catch (error) {
      const be = error as BusinessError;
      CryptoUtil.log('pushBizGet fail @' + fullUrl + ' code=' + be.code + ' msg=' + be.message);
      return new ApiResponse<Object>(-1, '网络请求失败: ' + be.message + ' @push', new Object());
    } finally {
      client.destroy();
    }
  }

  /**
   * [W20 social] push 域加密 multipart（源码 e.f 管道：SocialModel.f / MarketModel.k1 发帖，
   * 文本字段 content/type/marketType/score/time 逐个 AES 加密后作 form-data part，
   * 文件按 SubmitFileBean keyName=pic1..picN；请求头同 push 通道（明文 AT + xxdm）。
   * 2026-11-18 实测域名不可达 → 网络层真实失败，由调用方透传错误。
   */
  static async pushMultipartPost(fullUrl: string, fields: Record<string, string>,
    photoUris: string[]): Promise<ApiResponse<Object>> {
    const client: http.HttpRequest = http.createHttp();
    try {
      const boundary: string = '----WebKitFormBoundary' + Date.now();
      const parts: Uint8Array[] = [];
      const encoder: util.TextEncoder = new util.TextEncoder();
      const fieldKeys: string[] = Object.keys(fields);
      for (const key of fieldKeys) {
        const encVal: string = await CryptoUtil.encryptAES(fields[key], LoginSession.aesKey);
        parts.push(encoder.encodeInto('--' + boundary + '\r\n'));
        parts.push(encoder.encodeInto('Content-Disposition: form-data; name="' +
          encodeURIComponent(key) + '"\r\n\r\n'));
        parts.push(encoder.encodeInto(encVal + '\r\n'));
      }
      let index = 0;
      for (const uri of photoUris) {
        index++;
        HttpClient.appendFilePart(parts, encoder, boundary, uri, 'pic' + String(index));
      }
      parts.push(encoder.encodeInto('--' + boundary + '--\r\n'));
      const body: ArrayBuffer = HttpClient.concatBytes(parts).buffer as ArrayBuffer;
      const atEnc: string = await HttpClient.buildEncryptedAccessToken();
      const header: Record<string, string> = {
        'Content-Type': 'multipart/form-data; boundary=' + boundary,
        'Access-Token': atEnc,
        'Unique-Code': LoginSession.onlyCode === '' ? Constants.UNIQUE_CODE : LoginSession.onlyCode,
        'AppType': Constants.APP_TYPE,
        'xxdm': LoginSession.schoolId === '' ? 'sdmu' : LoginSession.schoolId,
        'User-Agent': 'Dalvik/2.1.0 (Linux; U; Android 14; 25060RK16C Build/UQ1A.240205.11101510)'
      };
      const options: http.HttpRequestOptions = {
        method: http.RequestMethod.POST,
        header: header,
        extraData: body,
        expectDataType: http.HttpDataType.STRING,
        connectTimeout: 15000,
        readTimeout: 50000
      };
      const response: http.HttpResponse = await client.request(fullUrl, options);
      if (response.responseCode === 200) {
        const raw = JSON.parse(response.result as string) as ApiRawData;
        const code: number = HttpClient.normalizeCode(raw.code);
        HttpClient.interceptSessionCode(code);
        return new ApiResponse<Object>(code, raw.message, raw.data);
      }
      return new ApiResponse<Object>(-1, 'HTTP ' + response.responseCode + ' @push', new Object());
    } catch (error) {
      const be = error as BusinessError;
      CryptoUtil.log('pushMultipartPost fail @' + fullUrl + ' code=' + be.code + ' msg=' + be.message);
      return new ApiResponse<Object>(-1, '网络请求失败: ' + be.message + ' @push', new Object());
    } finally {
      client.destroy();
    }
  }

  /** feedback 头（j=false：明文 AT + 设备码 UC，无 AppType——源码 e.g() 只有这两个头） */
  private static feedbackHeader(contentType: string): Record<string, string> {    const header: Record<string, string> = {
      'Content-Type': contentType,
      'Access-Token': HttpClient.plainAccessToken(),
      'Unique-Code': LoginSession.deviceCode === '' ?
        (LoginSession.onlyCode === '' ? Constants.UNIQUE_CODE : LoginSession.onlyCode)
        : LoginSession.deviceCode,
      'User-Agent': 'Dalvik/2.1.0 (Linux; U; Android 14; 25060RK16C Build/UQ1A.240205.11101510)'
    };
    return header;
  }

  /**
   * [W18 meeting-remain] 业务加密通道 multipart（MeetingModel.l1/m1 → e.f(path, files) 管道，
   * 源码 BaseRemoteXUtils3Impl.k() case 7 逐行还原）：
   *   - 表单字段（【验收修正】f.java s() 实证：POST_MULTIPART 通道 f13171d 整体 k.m() JSON 序列化
   *     → AES 加密 → clear 后仅剩 {data: 密文}，case 7 addBodyParameter("data", 密文) 一个普通
   *     form-data part——不是逐字段明文 part）；
   *   - 文件逐个 addBodyParameter(keyName=PIC, stream, mime, fileName)（SubmitFileBean.setKeyName("PIC")）；
   *   - 请求头同 bizRequest（加密 AT + Unique-Code + AppType，源码 e.g() 两头 + f.s() 加密链）；
   *   - 响应走 y()→r()（m(true) 加密通道）→ data 解密，与 bizRequest 响应段一致。
   */
  static async bizMultipartPost(path: string, formFields: Record<string, string>,
    fileUris: string[], fileKeyName: string = 'PIC'): Promise<ApiResponse<Object>> {
    const client: http.HttpRequest = http.createHttp();
    try {
      const boundary: string = '----WebKitFormBoundary' + Date.now();
      const parts: Uint8Array[] = [];
      const encoder: util.TextEncoder = new util.TextEncoder();
      // 源码 f.java s()：POST_MULTIPART 参数 JSON → AES 加密 → 单个 data= 字段（case 7 addBodyParameter）
      const payloadJson: string = JSON.stringify(formFields);
      const payloadEnc: string = await CryptoUtil.encryptAES(payloadJson, LoginSession.aesKey);
      parts.push(encoder.encodeInto('--' + boundary + '\r\n'));
      parts.push(encoder.encodeInto('Content-Disposition: form-data; name="data"\r\n\r\n'));
      parts.push(encoder.encodeInto(payloadEnc + '\r\n'));
      for (const uri of fileUris) {
        HttpClient.appendFilePart(parts, encoder, boundary, uri, fileKeyName);
      }
      parts.push(encoder.encodeInto('--' + boundary + '--\r\n'));
      const body: ArrayBuffer = HttpClient.concatBytes(parts).buffer as ArrayBuffer;
      const atEnc: string = await HttpClient.buildEncryptedAccessToken();
      const header: Record<string, string> = {
        'Content-Type': 'multipart/form-data; boundary=' + boundary,
        'Access-Token': atEnc,
        'Unique-Code': LoginSession.onlyCode === '' ? Constants.UNIQUE_CODE : LoginSession.onlyCode,
        'AppType': Constants.APP_TYPE,
        'User-Agent': 'Dalvik/2.1.0 (Linux; U; Android 14; 25060RK16C Build/UQ1A.240205.11101510)'
      };
      const options: http.HttpRequestOptions = {
        method: http.RequestMethod.POST,
        header: header,
        extraData: body,
        expectDataType: http.HttpDataType.STRING,
        connectTimeout: 15000,
        readTimeout: 50000
      };
      const response: http.HttpResponse = await client.request(Constants.SOCKET_HOST + path, options);
      if (response.responseCode === 200) {
        const raw = JSON.parse(response.result as string) as ApiRawData;
        const code: number = HttpClient.normalizeCode(raw.code);
        HttpClient.interceptSessionCode(code);
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
      CryptoUtil.log('bizMultipartPost fail @' + path + ' code=' + be.code + ' msg=' + be.message);
      return new ApiResponse<Object>(-1, '网络请求失败: ' + be.message + ' @' + path, new Object());
    } finally {
      client.destroy();
    }
  }

  /**
   * [W23 oa-remain] 处理页附件上传明文 multipart（源码 TodoModel.o1 → e.f(str, files) 管道：
   * bVarF = e.f(完整URL, files)；f13171d 字段 {DocUnid,Processid,NodeName,FdName}；bVarF.j=false。
   * j=false 管道（源码 BaseRemoteXUtils3Impl.k() case 7）：表单字段逐个普通 form-data part 明文；
   * 文件按 SubmitFileBean.keyName（APK 固定 "selectfile"）逐个 addBodyParameter(keyName,stream,mime,name)；
   * 头 = e.g() 明文 AT + UC=onlyCode，无 AppType；响应 data 明文（不走 r() 解密）。
   * URL = bmpurl + "R_S017_B066"（OA 服务器原域，非校内加密域）。
   */
  static async plainMultipartPost(fullUrl: string, fields: Record<string, string>,
    fileUris: string[], fileKeyName: string): Promise<ApiResponse<Object>> {
    const client: http.HttpRequest = http.createHttp();
    try {
      const boundary: string = '----WebKitFormBoundary' + Date.now();
      const parts: Uint8Array[] = [];
      const encoder: util.TextEncoder = new util.TextEncoder();
      const fieldKeys: string[] = Object.keys(fields);
      for (const key of fieldKeys) {
        parts.push(encoder.encodeInto('--' + boundary + '\r\n'));
        parts.push(encoder.encodeInto('Content-Disposition: form-data; name="' +
          encodeURIComponent(key) + '"\r\n\r\n'));
        parts.push(encoder.encodeInto(fields[key] + '\r\n'));
      }
      for (const uri of fileUris) {
        HttpClient.appendFilePart(parts, encoder, boundary, uri, fileKeyName);
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
      const response: http.HttpResponse = await client.request(fullUrl, options);
      if (response.responseCode === 200) {
        const raw = JSON.parse(response.result as string) as ApiRawData;
        const code: number = HttpClient.normalizeCode(raw.code);
        // W11 统一拦截：j=false 明文通道响应同样流经 NetUtils.y()→f()
        HttpClient.interceptSessionCode(code);
        return new ApiResponse<Object>(code, raw.message, raw.data);
      }
      return new ApiResponse<Object>(-1, 'HTTP ' + response.responseCode + ' @plainMultipart', new Object());
    } catch (error) {
      const be = error as BusinessError;
      CryptoUtil.log('plainMultipartPost fail @' + fullUrl + ' code=' + be.code + ' msg=' + be.message);
      return new ApiResponse<Object>(-1, '网络请求失败: ' + be.message, new Object());
    } finally {
      client.destroy();
    }
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
        const code: number = HttpClient.normalizeCode(raw.code);
        // W11 统一拦截：APK feedback 明文通道响应同样流经 NetUtils.y()→f()，code=1000 触发统一处理
        HttpClient.interceptSessionCode(code);
        return new ApiResponse<Object>(code, raw.message, raw.data);
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

  /**
   * [W22 launch-chain] 聚合认证专用通道（PolymerizationModel T0/U0/W0/X0 逐行还原）：
   *   - 请求：POST_CONTENT + Content-Type application/json + j=false（不走 s() 加密管道），
   *     body = 明文 JSON；头只有 appid/secret/userId 三字段（f13170c 直接作请求头，无 AT/UC）。
   *   - 响应：m = PolymerizationDatasAdapter —— 原始体 {data, meta:{message,statusCode,success}}，
   *     归一化为 {"code": success?"0":"1", "msg": meta.message, "data":""}；
   *     故 code=0 即 meta.success=true，message 透传。
   *   域名为扫码下发 PolymerizationResultBean.domain（校园按校部署），失败透传真实网络错误。
   */
  static async polyPostJson(fullUrl: string, headers: Record<string, string>,
    bodyObj: Record<string, Object>): Promise<ApiResponse<Object>> {
    const client: http.HttpRequest = http.createHttp();
    try {
      const header: Record<string, string> = {
        'Content-Type': 'application/json',
        'User-Agent': 'Dalvik/2.1.0 (Linux; U; Android 14; 25060RK16C Build/UQ1A.240205.11101510)'
      };
      const keys: string[] = Object.keys(headers);
      for (const k of keys) {
        header[k] = headers[k];
      }
      const options: http.HttpRequestOptions = {
        method: http.RequestMethod.POST,
        extraData: JSON.stringify(bodyObj),
        header: header,
        expectDataType: http.HttpDataType.STRING,
        connectTimeout: 10000,
        readTimeout: 15000
      };
      const response: http.HttpResponse = await client.request(fullUrl, options);
      if (response.responseCode === 200) {
        // PolymerizationDatasAdapter.a()：{meta:{success,message}} → code 0/1
        const raw = JSON.parse(response.result as string) as Record<string, Object>;
        const meta = raw['meta'];
        if (meta !== null && meta !== undefined && typeof meta === 'object') {
          const rec = meta as Record<string, Object>;
          const success: Object = rec['success'];
          const ok: boolean = success === true;
          const message: Object = rec['message'];
          return new ApiResponse<Object>(ok ? 0 : 1,
            typeof message === 'string' ? message as string : '', raw['data'] ?? new Object());
        }
        return new ApiResponse<Object>(1, '聚合认证响应格式异常', new Object());
      }
      return new ApiResponse<Object>(-1, 'HTTP ' + response.responseCode + ' @cam', new Object());
    } catch (error) {
      const be = error as BusinessError;
      CryptoUtil.log('polyPostJson fail @' + fullUrl + ' code=' + be.code + ' msg=' + be.message);
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
    boundary: string, uri: string, keyName: string = 'imgs'): void {
    const rawName: string = uri.substring(uri.lastIndexOf('/') + 1);
    const fileName: string = UrlSecurityHelper.sanitizeFileName(rawName, 'upload');
    const safeKeyName: string = UrlSecurityHelper.sanitizeMultipartToken(keyName) || 'imgs';
    const stat: fs.Stat = fs.statSync(uri);
    const maxFileBytes: number = 50 * 1024 * 1024;
    if (stat.size <= 0 || stat.size > maxFileBytes) {
      throw new Error('上传文件大小超出安全限制: ' + String(stat.size));
    }
    const file = fs.openSync(uri, fs.OpenMode.READ_ONLY);
    try {
      const buf: ArrayBuffer = new ArrayBuffer(stat.size);
      fs.readSync(file.fd, buf);
      const ext: string = fileName.lastIndexOf('.') >= 0 ?
        fileName.substring(fileName.lastIndexOf('.') + 1).toLowerCase() : 'jpg';
      const mime: string = ext === 'png' ? 'image/png' : 'image/jpeg';
      parts.push(encoder.encodeInto('--' + boundary + '\r\n'));
      parts.push(encoder.encodeInto('Content-Disposition: form-data; name="' + safeKeyName +
        '"; filename="' + fileName + '"\r\n'));
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
        const code: number = HttpClient.normalizeCode(raw.code);
        // W11 统一拦截：APK feedback 明文通道响应同样流经 NetUtils.y()→f()，code=1000 触发统一处理
        HttpClient.interceptSessionCode(code);
        return new ApiResponse<Object>(code, raw.message, raw.data);
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





