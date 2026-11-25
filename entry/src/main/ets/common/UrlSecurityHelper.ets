/**
 * URL 与文件安全校验工具（防御性安全加固）
 * - 校验 http/https 协议与受信任校园/合作域名，防止凭据泄露至不可信第三方
 * - 校验外部拉起 URI Scheme，防止非预期协议触发
 * - 清洗下载文件名与 Multipart 表单头字段，防止路径穿越与头注入
 */
export class UrlSecurityHelper {
  private static readonly TRUSTED_AUTH_DOMAINS: string[] = [
    'sdmu.edu.cn',
    'zfpt.wru.edu.cn',
    'yibaogao.com',
    'ly-sky.com'
  ];

  private static readonly TRUSTED_CAMPUS_SSL_DOMAINS: string[] = [
    'sdmu.edu.cn'
  ];

  private static readonly SAFE_EXTERNAL_SCHEMES: string[] = [
    'http:',
    'https:',
    'tel:',
    'sms:',
    'mailto:'
  ];

  /** 提取 http/https URL 的小写主机名（不含端口与 userinfo）；非法格式返回空串 */
  public static extractHttpHost(rawUrl: string): string {
    const trimmed: string = (rawUrl || '').trim();
    if (trimmed === '') {
      return '';
    }
    const lower: string = trimmed.toLowerCase();
    let rest: string = '';
    if (lower.startsWith('https://')) {
      rest = trimmed.substring(8);
    } else if (lower.startsWith('http://')) {
      rest = trimmed.substring(7);
    } else {
      return '';
    }
    const slashIdx: number = rest.indexOf('/');
    const queryIdx: number = rest.indexOf('?');
    const hashIdx: number = rest.indexOf('#');
    let endIdx: number = rest.length;
    if (slashIdx >= 0 && slashIdx < endIdx) {
      endIdx = slashIdx;
    }
    if (queryIdx >= 0 && queryIdx < endIdx) {
      endIdx = queryIdx;
    }
    if (hashIdx >= 0 && hashIdx < endIdx) {
      endIdx = hashIdx;
    }
    const authority: string = rest.substring(0, endIdx);
    // 拒绝含 @ 的 userinfo 欺骗（如 http://sdmu.edu.cn@evil.com）
    if (authority === '' || authority.indexOf('@') >= 0) {
      return '';
    }
    const colonIdx: number = authority.indexOf(':');
    const host: string = (colonIdx >= 0 ? authority.substring(0, colonIdx) : authority).toLowerCase();
    if (host === '' || host.indexOf(' ') >= 0) {
      return '';
    }
    return host;
  }

  /** 判断是否为安全的 http/https URL */
  public static isSafeHttpUrl(rawUrl: string): boolean {
    return UrlSecurityHelper.extractHttpHost(rawUrl) !== '';
  }

  private static hostMatchesDomains(host: string, domains: string[]): boolean {
    if (host === '') {
      return false;
    }
    for (const domain of domains) {
      if (host === domain || host.endsWith('.' + domain)) {
        return true;
      }
    }
    return false;
  }

  /** 判断 URL 是否属于允许注入校园认证凭据（Access-Token / Unique-Code / Cookie）的受信任域名 */
  public static isTrustedAuthHost(rawUrl: string): boolean {
    const host: string = UrlSecurityHelper.extractHttpHost(rawUrl);
    return UrlSecurityHelper.hostMatchesDomains(host, UrlSecurityHelper.TRUSTED_AUTH_DOMAINS);
  }

  /** 判断 URL 是否属于允许兼容校内自签证书的校园域名 */
  public static isTrustedCampusSslHost(rawUrl: string): boolean {
    const host: string = UrlSecurityHelper.extractHttpHost(rawUrl);
    return UrlSecurityHelper.hostMatchesDomains(host, UrlSecurityHelper.TRUSTED_CAMPUS_SSL_DOMAINS);
  }

  /** 判断外部拉起 URI 是否属于安全 Scheme */
  public static isSafeExternalUri(rawUri: string): boolean {
    const trimmed: string = (rawUri || '').trim();
    if (trimmed === '') {
      return false;
    }
    const lower: string = trimmed.toLowerCase();
    if (lower.startsWith('http://') || lower.startsWith('https://')) {
      return UrlSecurityHelper.isSafeHttpUrl(trimmed);
    }
    for (const scheme of UrlSecurityHelper.SAFE_EXTERNAL_SCHEMES) {
      if (scheme !== 'http:' && scheme !== 'https:' && lower.startsWith(scheme)) {
        return trimmed.length > scheme.length;
      }
    }
    return false;
  }

  /** 清洗下载文件名，防止路径穿越（../、/、\）及控制字符 */
  public static sanitizeFileName(rawName: string, fallbackPrefix: string = 'download'): string {
    const cleaned: string = (rawName || '')
      .replace(/[\\/:*?"<>|\r\n\t]/g, '_')
      .replace(/\.{2,}/g, '.')
      .trim();
    if (cleaned === '' || cleaned === '.' || cleaned === '..') {
      return fallbackPrefix + '_' + String(Date.now());
    }
    return cleaned.length > 128 ? cleaned.substring(0, 128) : cleaned;
  }

  /** 清洗 Multipart 头字段值（去除引号与回车换行，防止头注入） */
  public static sanitizeMultipartToken(rawValue: string): string {
    return (rawValue || '').replace(/[\r\n"\\]/g, '_').trim();
  }

  /** 日志脱敏：仅保留前 4 位与总长度 */
  public static redactSecret(secret: string): string {
    if (!secret || secret === '') {
      return '<empty>';
    }
    if (secret.length <= 4) {
      return '***(' + String(secret.length) + ')';
    }
    return secret.substring(0, 4) + '***(' + String(secret.length) + ')';
  }
}
