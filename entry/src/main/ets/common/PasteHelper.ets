import { pasteboard, BusinessError } from '@kit.BasicServicesKit';

export interface PasteReadResult {
  success: boolean;
  text: string;
  isEmpty: boolean;
  unauthorized: boolean;
  message: string;
}

export interface MergeContentResult {
  text: string;
  truncated: boolean;
}

/**
 * 剪贴板零权限粘贴助手（配合 ArkUI 安全控件 PasteButton 使用）
 */
export class PasteHelper {
  /** 纯函数：统一换行符并去除首尾空白 */
  public static normalizePastedText(raw: string): string {
    if (!raw) {
      return '';
    }
    return raw.replace(/\r\n/g, '\n').replace(/\r/g, '\n').trim();
  }

  /** 纯函数：单行输入框文本规范化（换行/制表符转空格，可选限长） */
  public static normalizeSingleLine(raw: string, maxLen: number = 0): string {
    const normalized: string = PasteHelper.normalizePastedText(raw).replace(/[\n\t]+/g, ' ').trim();
    if (maxLen > 0 && normalized.length > maxLen) {
      return normalized.substring(0, maxLen);
    }
    return normalized;
  }

  /** 纯函数：将粘贴内容合并到已有正文并控制最大长度 */
  public static mergeContentWithLimit(
    existing: string,
    pasted: string,
    maxLength: number = 300
  ): MergeContentResult {
    const cleanPaste: string = PasteHelper.normalizePastedText(pasted);
    if (cleanPaste === '') {
      return { text: existing, truncated: false };
    }
    const base: string = existing || '';
    const combined: string = base === '' ? cleanPaste : `${base}\n${cleanPaste}`;
    if (maxLength > 0 && combined.length > maxLength) {
      return {
        text: combined.substring(0, maxLength),
        truncated: true
      };
    }
    return { text: combined, truncated: false };
  }

  /** 纯函数：校验是否为 http/https 链接 */
  public static isHttpUrl(text: string): boolean {
    const trimmed: string = (text || '').trim().toLowerCase();
    return trimmed.startsWith('http://') || trimmed.startsWith('https://');
  }

  /** 纯函数：按优先级从 PasteData 提取文本 */
  public static extractTextFromPasteData(
    primaryText: string,
    primaryUri: string,
    fallbackPlain: string = ''
  ): string {
    const candidates: string[] = [primaryText, fallbackPlain, primaryUri];
    for (const c of candidates) {
      const normalized: string = PasteHelper.normalizePastedText(c);
      if (normalized !== '') {
        return normalized;
      }
    }
    return '';
  }

  /**
   * 仅应在 PasteButton OnClickResult.SUCCESS 回调内调用：
   * 读取系统剪贴板文本并返回结构化结果（无需 ohos.permission.READ_PASTEBOARD）
   */
  public static async readPlainTextFromSystemPasteboard(): Promise<PasteReadResult> {
    try {
      const board: pasteboard.SystemPasteboard = pasteboard.getSystemPasteboard();
      const hasData: boolean = await board.hasData();
      if (!hasData) {
        return {
          success: false,
          text: '',
          isEmpty: true,
          unauthorized: false,
          message: '剪贴板暂无文本内容'
        };
      }
      const data: pasteboard.PasteData = await board.getData();
      let primaryText: string = '';
      let primaryUri: string = '';
      let fallbackPlain: string = '';
      try {
        primaryText = data.getPrimaryText() || '';
      } catch {
        primaryText = '';
      }
      try {
        primaryUri = data.getPrimaryUri() || '';
      } catch {
        primaryUri = '';
      }
      try {
        if (data.getRecordCount() > 0) {
          fallbackPlain = data.getRecord(0).toPlainText() || '';
        }
      } catch {
        fallbackPlain = '';
      }
      const extracted: string = PasteHelper.extractTextFromPasteData(primaryText, primaryUri, fallbackPlain);
      if (extracted === '') {
        return {
          success: false,
          text: '',
          isEmpty: true,
          unauthorized: false,
          message: '剪贴板暂无文本内容'
        };
      }
      return {
        success: true,
        text: extracted,
        isEmpty: false,
        unauthorized: false,
        message: '已粘贴'
      };
    } catch (err) {
      const be = err as BusinessError;
      const code: number = be.code ?? -1;
      const unauthorized: boolean = code === 201 || code === 27787277 || code === 12900005;
      return {
        success: false,
        text: '',
        isEmpty: false,
        unauthorized: unauthorized,
        message: unauthorized ? '未获得剪贴板授权' : '读取剪贴板失败'
      };
    }
  }
}
