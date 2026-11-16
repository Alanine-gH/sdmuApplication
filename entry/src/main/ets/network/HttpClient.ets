import { http } from '@kit.NetworkKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { ApiResponse } from '../model/ResponseModel';
import { Constants } from '../data/Constants';

interface ApiRawData {
  code: number;
  message: string;
  data: Object;
}

interface HttpHeaderBag {
  'Content-Type': string;
}

/**
 * HTTP 网络封装：基于 @kit.NetworkKit 的 http 模块。
 * 服务器可能不可达，所有异常均被捕获并转换为错误状态的 ApiResponse，不会抛出未捕获异常。
 */
export class HttpClient {
  static async get(path: string): Promise<ApiResponse<Object>> {
    return HttpClient.request(path, http.RequestMethod.GET, '');
  }

  static async post(path: string, body: string): Promise<ApiResponse<Object>> {
    return HttpClient.request(path, http.RequestMethod.POST, body);
  }

  static async request(path: string, method: http.RequestMethod, body: string): Promise<ApiResponse<Object>> {
    const client: http.HttpRequest = http.createHttp();
    try {
      const options: http.HttpRequestOptions = {
        method: method,
        extraData: body,
        header: { 'Content-Type': 'application/json' } as HttpHeaderBag,
        expectDataType: http.HttpDataType.STRING,
        connectTimeout: 10000,
        readTimeout: 10000
      };
      const response: http.HttpResponse = await client.request(Constants.BASE_URL + path, options);
      if (response.responseCode === 200) {
        const raw = JSON.parse(response.result as string) as ApiRawData;
        return new ApiResponse<Object>(raw.code, raw.message, raw.data);
      }
      return new ApiResponse<Object>(-1, 'HTTP ' + response.responseCode, new Object());
    } catch (error) {
      const err = error as BusinessError;
      return new ApiResponse<Object>(-1, '网络请求失败: ' + err.message, new Object());
    } finally {
      client.destroy();
    }
  }
}
