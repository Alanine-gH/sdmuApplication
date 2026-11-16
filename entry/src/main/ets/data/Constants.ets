export class Constants {
  /**
   * 真实服务器（2026-11-16 抓包验证）：
   * 安卓版实际请求 http://mcp.sdmu.edu.cn:8081（校园内网，明文HTTP）
   * 此前使用的 https://portal.ly-sky.com 会返回 403（host 错误）
   */
  static readonly BASE_URL: string = 'http://mcp.sdmu.edu.cn:8081/mobileapi_ydxy';
  static readonly SOCKET_HOST: string = 'http://mcp.sdmu.edu.cn:8081';
  /** H5 明文接口（thirdpart_ydxy，无加密，抓包验证返回真实数据） */
  static readonly H5_HOST: string = 'http://mcp.sdmu.edu.cn:8081/thirdpart_ydxy';
  static readonly USER_AUTH_TYPE: string = 'YDXY';
  /** 安卓版必带请求头（抓包提取） */
  static readonly APP_TYPE: string = 'ydxy';
  static readonly CLIENT_VERSION: string = '3.2.0';
  /** 会话密钥（抓包提取，H5 接口验证有效） */
  static readonly SESSION_KEY: string = 'syw3vWQt2MuL';
  static readonly UNIQUE_CODE: string = 'd6b720d3-5784-4a32-b7f9-6a1d17b0a666';
  static readonly DEVICE_ID: string = '141ffcc5e67bf4a5';
  static readonly DEVICE_MODEL: string = '25060RK16C';
  static readonly PREF_NAME: string = 'sdmu_prefs';
  static readonly KEY_TOKEN: string = 'token';
  static readonly KEY_USER_ID: string = 'userId';
  static readonly KEY_IS_LOGIN: string = 'isLogin';
  static readonly KEY_USER_NAME: string = 'userName';
}
