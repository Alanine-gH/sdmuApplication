import { textProcessing, EntityType } from '@kit.NaturalLanguageKit';
import { BusinessError } from '@kit.BasicServicesKit';

export type NluActionType = 'calendar' | 'location' | 'dial' | 'email' | 'url' | 'none';

export const NLU_ENTITY_DATETIME: string = 'datetime';
export const NLU_ENTITY_LOCATION: string = 'location';
export const NLU_ENTITY_PHONE_NO: string = 'phoneNo';
export const NLU_ENTITY_EMAIL: string = 'email';
export const NLU_ENTITY_URL: string = 'url';

export interface RawNluEntity {
  text: string;
  type: string;
  charOffset?: number;
  jsonObject?: string;
}

export interface NluEntityChip {
  type: string;
  typeLabel: string;
  text: string;
  action: NluActionType;
  actionLabel: string;
  timestampMs: number | null;
}

export interface NluExtractionResult {
  supported: boolean;
  entities: NluEntityChip[];
  message: string;
}

const TARGET_ENTITY_TYPE_STRINGS: string[] = [
  NLU_ENTITY_DATETIME,
  NLU_ENTITY_LOCATION,
  NLU_ENTITY_PHONE_NO,
  NLU_ENTITY_EMAIL,
  NLU_ENTITY_URL
];

/**
 * 端侧自然语言实体抽取助手（基于 @kit.NaturalLanguageKit textProcessing.getEntity）
 * - 纯端侧离线运行，无权限依赖
 * - 抽取出时间/地点/电话/邮箱/链接后映射为可点击快捷动作，并在不支持设备上优雅降级
 */
export class NluEntityHelper {
  /** 纯函数：清理富文本 HTML 标签、实体符号及多余空白 */
  public static cleanSourceText(raw: string): string {
    if (!raw || raw.trim() === '') {
      return '';
    }
    let text: string = raw
      .replace(/<script[\s\S]*?<\/script>/gi, ' ')
      .replace(/<style[\s\S]*?<\/style>/gi, ' ')
      .replace(/<br\s*\/?>/gi, '\n')
      .replace(/<\/(p|div|li|tr|h[1-6])>/gi, '\n')
      .replace(/<[^>]+>/g, ' ')
      .replace(/&nbsp;/gi, ' ')
      .replace(/&amp;/gi, '&')
      .replace(/&lt;/gi, '<')
      .replace(/&gt;/gi, '>')
      .replace(/&quot;/gi, '"')
      .replace(/&#39;|&apos;/gi, "'")
      .replace(/\r\n/g, '\n')
      .replace(/\r/g, '\n')
      .replace(/[ \t\u00A0]+/g, ' ')
      .replace(/\n{3,}/g, '\n\n');
    const lines: string[] = text.split('\n');
    const cleanedLines: string[] = [];
    for (const line of lines) {
      const trimmedLine: string = line.trim();
      if (trimmedLine !== '') {
        cleanedLines.push(trimmedLine);
      }
    }
    return cleanedLines.join('\n').trim();
  }

  /** 纯函数：按句读边界将长文本分片，每片不超过 maxChunkLen */
  public static chunkText(text: string, maxChunkLen: number = 800): string[] {
    const trimmed: string = (text || '').trim();
    if (trimmed === '') {
      return [];
    }
    const safeMax: number = Number.isFinite(maxChunkLen) && maxChunkLen >= 50
      ? Math.floor(maxChunkLen)
      : 800;
    if (trimmed.length <= safeMax) {
      return [trimmed];
    }

    const segments: string[] = [];
    let start: number = 0;
    for (let i = 0; i < trimmed.length; i++) {
      const ch: string = trimmed.charAt(i);
      if (ch === '\n' || ch === '。' || ch === '！' || ch === '？' || ch === '；') {
        const seg: string = trimmed.substring(start, i + 1).trim();
        if (seg !== '') {
          segments.push(seg);
        }
        start = i + 1;
      }
    }
    if (start < trimmed.length) {
      const tail: string = trimmed.substring(start).trim();
      if (tail !== '') {
        segments.push(tail);
      }
    }

    const chunks: string[] = [];
    let current: string = '';
    for (const seg of segments) {
      if (seg.length > safeMax) {
        if (current !== '') {
          chunks.push(current);
          current = '';
        }
        for (let offset = 0; offset < seg.length; offset += safeMax) {
          const piece: string = seg.substring(offset, offset + safeMax).trim();
          if (piece !== '') {
            chunks.push(piece);
          }
        }
        continue;
      }
      const candidate: string = current === '' ? seg : `${current}\n${seg}`;
      if (candidate.length <= safeMax) {
        current = candidate;
      } else {
        if (current !== '') {
          chunks.push(current);
        }
        current = seg;
      }
    }
    if (current !== '') {
      chunks.push(current);
    }
    return chunks;
  }

  /** 纯函数：按实体类型清洗提取文本（剔除 URL 尾标点与号码内空白） */
  public static normalizeEntityText(type: string, rawText: string): string {
    let text: string = (rawText || '').trim();
    if (text === '') {
      return '';
    }
    if (type === NLU_ENTITY_URL) {
      text = text.replace(/^[<("']+/, '').replace(/[。，、；：！？）】》"'>.,;!?]+$/, '').trim();
      if (text.endsWith(')') && text.indexOf('(') < 0) {
        text = text.substring(0, text.length - 1).trim();
      }
      return text;
    }
    if (type === NLU_ENTITY_PHONE_NO) {
      return text.replace(/[\s\u00A0]+/g, '');
    }
    if (type === NLU_ENTITY_EMAIL) {
      return text.replace(/^[<("']+|[>),.;:!?。，；]+$/g, '').trim();
    }
    return text.replace(/[\r\n]+/g, ' ').replace(/\s{2,}/g, ' ').trim();
  }

  /** 纯函数：将实体类型映射为前端快捷操作类型 */
  public static mapEntityToAction(type: string): NluActionType {
    if (type === NLU_ENTITY_DATETIME) {
      return 'calendar';
    }
    if (type === NLU_ENTITY_LOCATION) {
      return 'location';
    }
    if (type === NLU_ENTITY_PHONE_NO) {
      return 'dial';
    }
    if (type === NLU_ENTITY_EMAIL) {
      return 'email';
    }
    if (type === NLU_ENTITY_URL) {
      return 'url';
    }
    return 'none';
  }

  /** 纯函数：返回快捷动作按钮文案 */
  public static getActionLabel(type: string): string {
    if (type === NLU_ENTITY_DATETIME) {
      return '加日程';
    }
    if (type === NLU_ENTITY_LOCATION) {
      return '复制地点';
    }
    if (type === NLU_ENTITY_PHONE_NO) {
      return '拨号';
    }
    if (type === NLU_ENTITY_EMAIL) {
      return '发邮件';
    }
    if (type === NLU_ENTITY_URL) {
      return '打开链接';
    }
    return '查看';
  }

  /** 纯函数：返回实体类别中文标签 */
  public static getTypeLabel(type: string): string {
    if (type === NLU_ENTITY_DATETIME) {
      return '时间';
    }
    if (type === NLU_ENTITY_LOCATION) {
      return '地点';
    }
    if (type === NLU_ENTITY_PHONE_NO) {
      return '电话';
    }
    if (type === NLU_ENTITY_EMAIL) {
      return '邮箱';
    }
    if (type === NLU_ENTITY_URL) {
      return '链接';
    }
    return '信息';
  }

  private static normalizeTimestampValue(rawVal: Object | undefined): number | null {
    if (rawVal === undefined || rawVal === null) {
      return null;
    }
    let num: number = NaN;
    if (typeof rawVal === 'number') {
      num = rawVal;
    } else if (typeof rawVal === 'string') {
      const trimmed: string = (rawVal as string).trim();
      if (/^\d{10,13}$/.test(trimmed)) {
        num = Number(trimmed);
      } else if (trimmed !== '') {
        const parsedDate: number = Date.parse(trimmed);
        if (Number.isFinite(parsedDate)) {
          num = parsedDate;
        }
      }
    }
    if (!Number.isFinite(num) || num <= 0) {
      return null;
    }
    if (num < 100000000000) {
      num = num * 1000;
    }
    return Math.floor(num);
  }

  /** 纯函数：从 NLU jsonObject 或日期文本解析毫秒时间戳 */
  public static parseDatetimeMs(
    jsonObjectStr: string,
    fallbackText: string,
    refNowMs: number = Date.now()
  ): number | null {
    const rawJson: string = (jsonObjectStr || '').trim();
    if (rawJson !== '') {
      try {
        const parsed: Object = JSON.parse(rawJson) as Object;
        if (parsed !== null && typeof parsed === 'object') {
          const rec = parsed as Record<string, Object>;
          const candidateKeys: string[] = [
            'timestamp',
            'startTimestamp',
            'startTime',
            'time',
            'date'
          ];
          for (const key of candidateKeys) {
            const val: number | null = NluEntityHelper.normalizeTimestampValue(rec[key]);
            if (val !== null) {
              return val;
            }
          }
        }
      } catch {
        // 回退至正则日期解析
      }
    }

    const text: string = (fallbackText || '').trim();
    if (text === '') {
      return null;
    }

    const fullMatch: RegExpMatchArray | null = text.match(
      /(\d{4})[-/.年](\d{1,2})[-/.月](\d{1,2})[日号]?(?:\s+(\d{1,2})[:：](\d{1,2}))?/
    );
    if (fullMatch !== null) {
      const year: number = Number(fullMatch[1]);
      const month: number = Number(fullMatch[2]);
      const day: number = Number(fullMatch[3]);
      const hour: number = fullMatch[4] !== undefined ? Number(fullMatch[4]) : 9;
      const minute: number = fullMatch[5] !== undefined ? Number(fullMatch[5]) : 0;
      if (month >= 1 && month <= 12 && day >= 1 && day <= 31 && hour >= 0 && hour <= 23 && minute >= 0 && minute <= 59) {
        const ms: number = new Date(year, month - 1, day, hour, minute, 0, 0).getTime();
        return Number.isFinite(ms) ? ms : null;
      }
    }

    const mdMatch: RegExpMatchArray | null = text.match(
      /(\d{1,2})月(\d{1,2})[日号]?(?:\s+(\d{1,2})[:：](\d{1,2}))?/
    );
    if (mdMatch !== null) {
      const refDate: Date = Number.isFinite(refNowMs) && refNowMs > 0 ? new Date(refNowMs) : new Date();
      const month: number = Number(mdMatch[1]);
      const day: number = Number(mdMatch[2]);
      const hour: number = mdMatch[3] !== undefined ? Number(mdMatch[3]) : 9;
      const minute: number = mdMatch[4] !== undefined ? Number(mdMatch[4]) : 0;
      if (month >= 1 && month <= 12 && day >= 1 && day <= 31 && hour >= 0 && hour <= 23 && minute >= 0 && minute <= 59) {
        const ms: number = new Date(refDate.getFullYear(), month - 1, day, hour, minute, 0, 0).getTime();
        return Number.isFinite(ms) ? ms : null;
      }
    }

    return null;
  }

  /** 纯函数：清洗、去重并限制实体标签数量 */
  public static deduplicateEntities(
    raw: RawNluEntity[],
    maxItems: number = 10,
    refNowMs: number = Date.now()
  ): NluEntityChip[] {
    if (!raw || raw.length === 0) {
      return [];
    }
    const safeMax: number = Number.isFinite(maxItems) && maxItems > 0 ? Math.floor(maxItems) : 10;
    const seen: Set<string> = new Set<string>();
    const chips: NluEntityChip[] = [];

    for (const item of raw) {
      if (!item) {
        continue;
      }
      const action: NluActionType = NluEntityHelper.mapEntityToAction(item.type);
      if (action === 'none') {
        continue;
      }
      const normalized: string = NluEntityHelper.normalizeEntityText(item.type, item.text);
      if (normalized === '') {
        continue;
      }
      if (item.type === NLU_ENTITY_URL && normalized.indexOf('.') < 0) {
        continue;
      }
      if (item.type === NLU_ENTITY_EMAIL && normalized.indexOf('@') < 0) {
        continue;
      }
      if (item.type === NLU_ENTITY_PHONE_NO && normalized.length < 3) {
        continue;
      }
      const dedupKey: string = `${item.type}::${normalized.toLowerCase()}`;
      if (seen.has(dedupKey)) {
        continue;
      }
      seen.add(dedupKey);

      const timestampMs: number | null = item.type === NLU_ENTITY_DATETIME
        ? NluEntityHelper.parseDatetimeMs(item.jsonObject ?? '', normalized, refNowMs)
        : null;

      chips.push({
        type: item.type,
        typeLabel: NluEntityHelper.getTypeLabel(item.type),
        text: normalized,
        action: action,
        actionLabel: NluEntityHelper.getActionLabel(item.type),
        timestampMs: timestampMs
      });
      if (chips.length >= safeMax) {
        break;
      }
    }
    return chips;
  }

  /** 纯函数：拼装会议详情待抽取文本 */
  public static buildMeetingNluSource(
    title: string,
    address: string,
    kssj: string,
    jssj: string,
    lxr: string,
    lxrdh: string
  ): string {
    const parts: string[] = [];
    const cleanTitle: string = (title || '').trim();
    const cleanAddr: string = (address || '').trim();
    const cleanStart: string = (kssj || '').trim();
    const cleanEnd: string = (jssj || '').trim();
    const cleanContact: string = (lxr || '').trim();
    const cleanPhone: string = (lxrdh || '').trim();

    if (cleanTitle !== '') {
      parts.push(`会议：${cleanTitle}`);
    }
    if (cleanStart !== '' && cleanEnd !== '') {
      parts.push(`时间：${cleanStart} 至 ${cleanEnd}`);
    } else if (cleanStart !== '') {
      parts.push(`时间：${cleanStart}`);
    }
    if (cleanAddr !== '') {
      parts.push(`地点：${cleanAddr}`);
    }
    if (cleanContact !== '') {
      parts.push(`联系人：${cleanContact}`);
    }
    if (cleanPhone !== '') {
      parts.push(`联系电话：${cleanPhone}`);
    }
    return NluEntityHelper.cleanSourceText(parts.join('\n'));
  }

  /** 纯函数：映射 NLU 错误码为提示信息 */
  public static formatNluError(code: number): string {
    if (code === 200) {
      return '实体识别超时，请稍后重试';
    }
    if (code === 401) {
      return '实体识别参数无效';
    }
    if (code === 1011200001 || code === 1011200002) {
      return '当前设备暂不支持端侧智能实体识别';
    }
    return '当前设备暂不支持端侧智能实体识别';
  }

  /** 异步调用 NaturalLanguageKit 抽取时间、地点、电话、邮箱、链接实体 */
  public static async extractEntities(
    rawText: string,
    refTimestampMs: number = Date.now()
  ): Promise<NluExtractionResult> {
    const cleaned: string = NluEntityHelper.cleanSourceText(rawText);
    if (cleaned === '') {
      return {
        supported: true,
        entities: [],
        message: ''
      };
    }

    const safeTimestamp: number = Number.isFinite(refTimestampMs) && refTimestampMs > 0
      ? Math.floor(refTimestampMs)
      : Date.now();
    const chunks: string[] = NluEntityHelper.chunkText(cleaned, 800).slice(0, 5);
    const entityTypes: EntityType[] = TARGET_ENTITY_TYPE_STRINGS.map((val: string) => val as EntityType);
    const config: textProcessing.EntityConfig = {
      entityTypes: entityTypes,
      timestamp: safeTimestamp
    };
    const collected: RawNluEntity[] = [];

    try {
      for (const chunk of chunks) {
        const result: Array<textProcessing.Entity> = await textProcessing.getEntity(chunk, config);
        if (result && result.length > 0) {
          for (const item of result) {
            collected.push({
              text: item.text,
              type: String(item.type),
              charOffset: item.charOffset,
              jsonObject: item.jsonObject
            });
          }
        }
      }
      return {
        supported: true,
        entities: NluEntityHelper.deduplicateEntities(collected, 10, safeTimestamp),
        message: ''
      };
    } catch (err) {
      const be = err as BusinessError;
      const code: number = be.code ?? -1;
      return {
        supported: false,
        entities: [],
        message: NluEntityHelper.formatNluError(code)
      };
    } finally {
      try {
        await textProcessing.release();
      } catch {
        // 释放失败忽略
      }
    }
  }
}
