import { filePreview } from '@kit.PreviewKit';
import { fileUri, fileIo as fs } from '@kit.CoreFileKit';
import { common, Want, wantConstant } from '@kit.AbilityKit';
import { http } from '@kit.NetworkKit';
import { Constants } from '../data/Constants';
import { LoginSession } from '../network/LoginSession';

export type FilePreviewMethod = 'previewKit' | 'pdfView' | 'want' | 'none';

export interface FilePreviewResult {
  success: boolean;
  method: FilePreviewMethod;
  localPath: string;
  message: string;
}

const PREVIEW_MIME_MAP: Record<string, string> = {
  'txt': 'text/plain',
  'cpp': 'text/x-c',
  'c': 'text/x-c',
  'h': 'text/x-c',
  'java': 'text/x-java-source',
  'xhtml': 'application/xhtml+xml',
  'xml': 'text/xml',
  'html': 'text/html',
  'htm': 'text/html',
  'jpg': 'image/jpeg',
  'jpeg': 'image/jpeg',
  'png': 'image/png',
  'gif': 'image/gif',
  'webp': 'image/webp',
  'bmp': 'image/bmp',
  'svg': 'image/svg+xml',
  'm4a': 'audio/mp4a-latm',
  'aac': 'audio/aac',
  'mp3': 'audio/mpeg',
  'ogg': 'audio/ogg',
  'wav': 'audio/x-wav',
  'mp4': 'video/mp4',
  'mkv': 'video/x-matroska',
  'ts': 'video/mp2ts',
  'pdf': 'application/pdf',
  'doc': 'application/msword',
  'docx': 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
  'xls': 'application/vnd.ms-excel',
  'xlsx': 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
  'ppt': 'application/vnd.ms-powerpoint',
  'pptx': 'application/vnd.openxmlformats-officedocument.presentationml.presentation',
  'csv': 'text/csv',
  'ofd': 'general.ofd'
};

/**
 * 原生文档预览与附件下载助手（@kit.PreviewKit + @kit.PDFKit 降级 + Want 兜底）
 * - 使用 fileUri.getUriFromPath 构造带 bundleName 权限的沙箱 URI
 * - 覆盖 PreviewKit 完整办公/PDF/音视频/图片/文本 MIME 映射表
 */
export class FilePreviewHelper {
  /** 纯函数：提取小写文件扩展名（自动剥离查询串与锚点） */
  public static extractExtension(fileName: string): string {
    if (!fileName) {
      return '';
    }
    const clean: string = fileName.trim().split('?')[0].split('#')[0];
    const slashIdx: number = Math.max(clean.lastIndexOf('/'), clean.lastIndexOf('\\'));
    const base: string = slashIdx >= 0 ? clean.substring(slashIdx + 1) : clean;
    const dotIdx: number = base.lastIndexOf('.');
    if (dotIdx <= 0 || dotIdx === base.length - 1) {
      return '';
    }
    return base.substring(dotIdx + 1).toLowerCase();
  }

  /** 纯函数：根据文件名返回 PreviewKit 精确 MIME 类型，未知格式返回 '' */
  public static getPreviewMimeType(fileName: string): string {
    const ext: string = FilePreviewHelper.extractExtension(fileName);
    if (ext === '') {
      return '';
    }
    const mime: string | undefined = PREVIEW_MIME_MAP[ext];
    return mime !== undefined ? mime : '';
  }

  /** 纯函数：判断是否为 PDF 文件 */
  public static isPdfFileName(fileName: string): boolean {
    return FilePreviewHelper.extractExtension(fileName) === 'pdf';
  }

  /** 纯函数：判断文件扩展名是否在 PreviewKit 官方支持列表中 */
  public static isPreviewKitSupportedExt(fileName: string): boolean {
    return FilePreviewHelper.getPreviewMimeType(fileName) !== '';
  }

  /** 纯函数：解析附件下载地址（保留绝对 URL，相对路径拼接 SOCKET_HOST） */
  public static resolveDownloadUrl(rawUrl: string): string {
    const trimmed: string = (rawUrl || '').trim();
    if (trimmed === '') {
      return '';
    }
    const lower: string = trimmed.toLowerCase();
    if (lower.startsWith('http://') || lower.startsWith('https://')) {
      return trimmed;
    }
    if (trimmed.startsWith('/')) {
      return `${Constants.SOCKET_HOST}${trimmed}`;
    }
    return `${Constants.SOCKET_HOST}/${trimmed}`;
  }

  /** 纯函数：清理不安全文件名字符并防止目录穿越 */
  public static sanitizeFileName(rawName: string, fallbackPrefix: string = 'attachment'): string {
    const cleanPrefix: string = (fallbackPrefix || 'attachment').replace(/[\\/:*?"<>|]/g, '_') || 'attachment';
    if (!rawName || rawName.trim() === '') {
      return cleanPrefix;
    }
    const noQuery: string = rawName.trim().split('?')[0].split('#')[0];
    const slashIdx: number = Math.max(noQuery.lastIndexOf('/'), noQuery.lastIndexOf('\\'));
    const base: string = slashIdx >= 0 ? noQuery.substring(slashIdx + 1) : noQuery;
    const replaced: string = base
      .replace(/\.\.+/g, '_')
      .replace(/[\\/:*?"<>|]/g, '_')
      .replace(/^\.+/, '')
      .trim();
    if (replaced === '' || replaced === '.' || replaced === '..') {
      return cleanPrefix;
    }
    return replaced;
  }

  /** 将沙箱绝对路径转为带 bundleName 授权的 file:// URI */
  public static buildSandboxUri(localPath: string): string {
    if (!localPath || localPath.trim() === '') {
      return '';
    }
    try {
      return fileUri.getUriFromPath(localPath);
    } catch {
      return '';
    }
  }

  /** 预览沙箱本地文件（PreviewKit -> PDF 内置组件提示 -> Want viewData） */
  public static async openLocalFilePreview(
    context: common.UIAbilityContext,
    localPath: string,
    title?: string
  ): Promise<FilePreviewResult> {
    if (!context || !localPath || localPath.trim() === '') {
      return {
        success: false,
        method: 'none',
        localPath: '',
        message: '文件路径为空'
      };
    }
    try {
      if (!fs.accessSync(localPath)) {
        return {
          success: false,
          method: 'none',
          localPath: localPath,
          message: '文件不存在'
        };
      }
    } catch {
      return {
        success: false,
        method: 'none',
        localPath: localPath,
        message: '无法访问文件'
      };
    }

    const uri: string = FilePreviewHelper.buildSandboxUri(localPath);
    if (uri === '') {
      return {
        success: false,
        method: 'none',
        localPath: localPath,
        message: '无法生成文件访问URI'
      };
    }

    const displayTitle: string = (title && title.trim() !== '')
      ? title.trim()
      : FilePreviewHelper.sanitizeFileName(localPath);
    const mimeType: string = FilePreviewHelper.getPreviewMimeType(displayTitle) ||
      FilePreviewHelper.getPreviewMimeType(localPath);

    try {
      const canPreview: boolean = await filePreview.canPreview(context, uri);
      if (canPreview) {
        const previewInfo: filePreview.PreviewInfo = {
          title: displayTitle,
          uri: uri,
          mimeType: mimeType
        };
        await filePreview.openPreview(context, previewInfo);
        return {
          success: true,
          method: 'previewKit',
          localPath: localPath,
          message: ''
        };
      }
    } catch {
      // 回退至内置 PDF 或系统 Want 预览
    }

    if (FilePreviewHelper.isPdfFileName(displayTitle) || FilePreviewHelper.isPdfFileName(localPath)) {
      return {
        success: false,
        method: 'pdfView',
        localPath: localPath,
        message: '使用内置 PDF 预览'
      };
    }

    try {
      const want: Want = {
        action: 'ohos.want.action.viewData',
        uri: uri,
        type: mimeType !== '' ? mimeType : '*/*',
        flags: wantConstant.Flags.FLAG_AUTH_READ_URI_PERMISSION
      };
      await context.startAbility(want);
      return {
        success: true,
        method: 'want',
        localPath: localPath,
        message: ''
      };
    } catch {
      return {
        success: false,
        method: 'none',
        localPath: localPath,
        message: '暂不支持打开该格式文件'
      };
    }
  }

  /** 预览已由选择器/相机返回的 file:// 或系统 URI */
  public static async openUriPreview(
    context: common.UIAbilityContext,
    uri: string,
    title?: string
  ): Promise<FilePreviewResult> {
    const trimmedUri: string = (uri || '').trim();
    if (!context || trimmedUri === '') {
      return {
        success: false,
        method: 'none',
        localPath: '',
        message: '文件路径为空'
      };
    }
    const lower: string = trimmedUri.toLowerCase();
    if (!lower.startsWith('file://') && !lower.startsWith('content://') && !lower.startsWith('datashare://')) {
      return await FilePreviewHelper.openLocalFilePreview(context, trimmedUri, title);
    }

    const displayTitle: string = (title && title.trim() !== '')
      ? title.trim()
      : FilePreviewHelper.sanitizeFileName(trimmedUri);
    const mimeType: string = FilePreviewHelper.getPreviewMimeType(displayTitle) ||
      FilePreviewHelper.getPreviewMimeType(trimmedUri);

    try {
      const canPreview: boolean = await filePreview.canPreview(context, trimmedUri);
      if (canPreview) {
        const previewInfo: filePreview.PreviewInfo = {
          title: displayTitle,
          uri: trimmedUri,
          mimeType: mimeType
        };
        await filePreview.openPreview(context, previewInfo);
        return {
          success: true,
          method: 'previewKit',
          localPath: '',
          message: ''
        };
      }
    } catch {
      // 回退系统 Want
    }

    try {
      const want: Want = {
        action: 'ohos.want.action.viewData',
        uri: trimmedUri,
        type: mimeType !== '' ? mimeType : '*/*',
        flags: wantConstant.Flags.FLAG_AUTH_READ_URI_PERMISSION
      };
      await context.startAbility(want);
      return {
        success: true,
        method: 'want',
        localPath: '',
        message: ''
      };
    } catch {
      return {
        success: false,
        method: 'none',
        localPath: '',
        message: '暂不支持打开该格式文件'
      };
    }
  }

  /** 下载远端附件至沙箱缓存并调用原生预览 */
  public static async downloadAndPreview(
    context: common.UIAbilityContext,
    url: string,
    fileName: string,
    subDir: 'meeting' | 'todo' | 'download'
  ): Promise<FilePreviewResult> {
    if (!context) {
      return {
        success: false,
        method: 'none',
        localPath: '',
        message: '缺少应用上下文'
      };
    }
    const resolvedUrl: string = FilePreviewHelper.resolveDownloadUrl(url);
    if (resolvedUrl === '') {
      return {
        success: false,
        method: 'none',
        localPath: '',
        message: '附件下载地址为空'
      };
    }

    const baseDir: string = subDir === 'download'
      ? `${context.filesDir}/download`
      : `${context.cacheDir}/${subDir}`;
    try {
      if (!fs.accessSync(baseDir)) {
        fs.mkdirSync(baseDir, true);
      }
    } catch {
      try {
        fs.mkdirSync(baseDir, true);
      } catch {
        return {
          success: false,
          method: 'none',
          localPath: '',
          message: '无法创建附件缓存目录'
        };
      }
    }

    const safeName: string = FilePreviewHelper.sanitizeFileName(fileName, 'attachment');
    const targetPath: string = `${baseDir}/${safeName}`;

    try {
      if (fs.accessSync(targetPath)) {
        const stat: fs.Stat = fs.statSync(targetPath);
        if (stat.size > 0) {
          return await FilePreviewHelper.openLocalFilePreview(context, targetPath, safeName);
        }
      }
    } catch {
      // 文件不存在，继续下载
    }

    const client: http.HttpRequest = http.createHttp();
    let outFile: fs.File | null = null;
    try {
      const headers: Record<string, string> = {};
      if (resolvedUrl.startsWith(Constants.SOCKET_HOST) && LoginSession.sessionKey !== '') {
        headers['Access-Token'] = LoginSession.sessionKey;
        headers['Unique-Code'] = LoginSession.deviceCode;
      }
      const resp: http.HttpResponse = await client.request(resolvedUrl, {
        method: http.RequestMethod.GET,
        header: headers,
        expectDataType: http.HttpDataType.ARRAY_BUFFER,
        connectTimeout: 15000,
        readTimeout: 30000
      });
      if (resp.responseCode !== 200 || !(resp.result instanceof ArrayBuffer)) {
        return {
          success: false,
          method: 'none',
          localPath: '',
          message: '附件下载失败'
        };
      }
      const buffer: ArrayBuffer = resp.result as ArrayBuffer;
      if (buffer.byteLength <= 0) {
        return {
          success: false,
          method: 'none',
          localPath: '',
          message: '附件内容为空'
        };
      }
      outFile = fs.openSync(targetPath, fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE | fs.OpenMode.TRUNC);
      fs.writeSync(outFile.fd, buffer);
    } catch {
      return {
        success: false,
        method: 'none',
        localPath: '',
        message: '附件下载失败，请检查网络连接'
      };
    } finally {
      if (outFile !== null) {
        try {
          fs.closeSync(outFile);
        } catch {
          // 忽略关闭异常
        }
      }
      client.destroy();
    }

    return await FilePreviewHelper.openLocalFilePreview(context, targetPath, safeName);
  }
}
