import { imageSuperResolution, textSearchImage, visionBase } from '@kit.CoreVisionKit';
import { image } from '@kit.ImageKit';
import { BusinessError } from '@kit.BasicServicesKit';

export const DEFAULT_VISION_SEARCH_SCOPE: string = 'sdmuCampusGallery';
export const DOC_TYPE_DOC: number = 0;
export const DOC_TYPE_SHEET: number = 1;
export const DOC_FILTER_ORIGINAL: number = 0;
export const DOC_FILTER_MONOCHROME: number = 1;
export const DOC_FILTER_STRENGTHEN: number = 2;
export const DOC_SHOOT_AUTO: number = 0;
export const DOC_SHOOT_MANUAL: number = 1;
export const DOC_SAVE_JPG: number = 0;
export const DOC_SAVE_PDF: number = 1;

export interface VisionSearchMatchItem {
  imagePath: string;
  scope: string;
  similarity: number;
}

export interface VisionCaptionCandidate {
  id: string;
  title: string;
  imagePath: string;
}

export interface SuperResolutionResult {
  success: boolean;
  pixelMap: image.PixelMap | null;
  message: string;
}

export interface TextSearchQueryResult {
  supported: boolean;
  items: VisionSearchMatchItem[];
  message: string;
}

/**
 * 端侧 AI 视觉增强助手（HarmonyOS 5.0–7.0 / API 26）：
 * 1. CoreVisionKit.imageSuperResolution（API 26 端侧图像超分辨率增强）
 * 2. CoreVisionKit.textSearchImage（API 26 端侧本地语义文搜图索引与检索）
 * 3. VisionKit.DocumentScanner（端侧纸质票据/单据自动纠偏增强扫描配置）
 */
export class VisionEnhancementHelper {
  private static textSearchInitialized: boolean = false;

  /**
   * 纯函数：校验并规范化 textSearchImage 的 scope 参数
   * SDK 约束：仅允许字母或数字，长度 1..32，不可为空
   */
  public static sanitizeSearchScope(scope?: string): string {
    if (!scope || typeof scope !== 'string') {
      return DEFAULT_VISION_SEARCH_SCOPE;
    }
    let cleaned: string = '';
    for (let i = 0; i < scope.length; i++) {
      const code: number = scope.charCodeAt(i);
      const isDigit: boolean = code >= 48 && code <= 57;
      const isUpper: boolean = code >= 65 && code <= 90;
      const isLower: boolean = code >= 97 && code <= 122;
      if (isDigit || isUpper || isLower) {
        cleaned += scope.charAt(i);
        if (cleaned.length >= 32) {
          break;
        }
      }
    }
    return cleaned.length > 0 ? cleaned : DEFAULT_VISION_SEARCH_SCOPE;
  }

  /**
   * 纯函数：校验并规范化 textSearchImage 的 query 搜索词
   * SDK 约束：长度 1..100，支持中英文、数字与常见符号
   */
  public static sanitizeSearchQuery(query?: string): string {
    if (!query || typeof query !== 'string') {
      return '';
    }
    const trimmed: string = query.trim();
    if (trimmed.length === 0) {
      return '';
    }
    return trimmed.length > 100 ? trimmed.substring(0, 100) : trimmed;
  }

  /**
   * 纯函数：校验入库图片沙箱路径是否满足 textSearchImage.insertImage 规范（1..128 字符，非空）
   */
  public static isValidImagePathForIndex(imagePath?: string): boolean {
    if (!imagePath || typeof imagePath !== 'string') {
      return false;
    }
    const trimmed: string = imagePath.trim();
    return trimmed.length >= 1 && trimmed.length <= 128;
  }

  /**
   * 纯函数：判断图像尺寸是否适合端侧超分辨率处理（64..4096 px）
   */
  public static isEligibleForSuperResolution(widthPx: number, heightPx: number): boolean {
    if (!Number.isFinite(widthPx) || !Number.isFinite(heightPx)) {
      return false;
    }
    return widthPx >= 64 && heightPx >= 64 && widthPx <= 4096 && heightPx <= 4096;
  }

  /**
   * 纯函数：校验图片尺寸是否满足 DocumentScannerConfig.originalUris 规格
   * SDK 约束：单边 224..8000 px，宽高乘积 <= 6000*8000，宽高比与高宽比均 <= 3
   */
  public static validateDocScanOriginalUriSize(widthPx: number, heightPx: number): boolean {
    if (!Number.isFinite(widthPx) || !Number.isFinite(heightPx)) {
      return false;
    }
    if (widthPx < 224 || heightPx < 224 || widthPx > 8000 || heightPx > 8000) {
      return false;
    }
    if (widthPx * heightPx > 6000 * 8000) {
      return false;
    }
    const ratioWH: number = widthPx / heightPx;
    const ratioHW: number = heightPx / widthPx;
    return ratioWH <= 3 && ratioHW <= 3;
  }

  /**
   * 纯函数：过滤、排序并截取文搜图结果（similarity 范围 [-1, 1]，按相似度降序，topK 限制在 1..100）
   */
  public static filterAndRankSearchResults(
    items: VisionSearchMatchItem[],
    minSimilarity: number = 0.05,
    topK: number = 20
  ): VisionSearchMatchItem[] {
    if (!Array.isArray(items) || items.length === 0) {
      return [];
    }
    const safeMin: number = Number.isFinite(minSimilarity)
      ? Math.max(-1, Math.min(1, minSimilarity))
      : 0.05;
    const safeTopK: number = Number.isFinite(topK)
      ? Math.max(1, Math.min(100, Math.floor(topK)))
      : 20;
    const seenPaths: Set<string> = new Set<string>();
    const filtered: VisionSearchMatchItem[] = [];
    for (let i = 0; i < items.length; i++) {
      const item: VisionSearchMatchItem = items[i];
      if (!item || typeof item.imagePath !== 'string' || item.imagePath.trim() === '') {
        continue;
      }
      if (!Number.isFinite(item.similarity) || item.similarity < safeMin || item.similarity > 1) {
        continue;
      }
      const cleanPath: string = item.imagePath.trim();
      if (seenPaths.has(cleanPath)) {
        continue;
      }
      seenPaths.add(cleanPath);
      filtered.push({
        imagePath: cleanPath,
        scope: VisionEnhancementHelper.sanitizeSearchScope(item.scope),
        similarity: Number(item.similarity.toFixed(4))
      });
    }
    filtered.sort((a: VisionSearchMatchItem, b: VisionSearchMatchItem): number => {
      return b.similarity - a.similarity;
    });
    return filtered.slice(0, safeTopK);
  }

  /**
   * 纯函数：本地标题/关键词回退匹配（当模拟器或非 NPU 设备不支持 textSearchImage 时的离线检索回退）
   */
  public static matchCaptionsFallback(
    query: string,
    candidates: VisionCaptionCandidate[]
  ): string[] {
    const cleanQuery: string = VisionEnhancementHelper.sanitizeSearchQuery(query).toLowerCase();
    if (cleanQuery === '' || !Array.isArray(candidates)) {
      return [];
    }
    const matchedIds: string[] = [];
    for (let i = 0; i < candidates.length; i++) {
      const c = candidates[i];
      if (!c) {
        continue;
      }
      const titleLower: string = (c.title || '').toLowerCase();
      const pathLower: string = (c.imagePath || '').toLowerCase();
      if (titleLower.includes(cleanQuery) || pathLower.includes(cleanQuery)) {
        matchedIds.push(c.id);
      }
    }
    return matchedIds;
  }

  /**
   * 纯函数：格式化 CoreVisionKit / VisionKit 错误码为用户可读提示
   */
  public static formatVisionError(err: Object | string | number | null | undefined): string {
    if (err === null || err === undefined) {
      return '端侧视觉服务暂不可用';
    }
    let code: number = 0;
    let rawMsg: string = '';
    if (typeof err === 'number') {
      code = err;
    } else if (typeof err === 'string') {
      rawMsg = err;
    } else {
      const busErr = err as BusinessError;
      if (typeof busErr.code === 'number') {
        code = busErr.code;
      }
      if (typeof busErr.message === 'string') {
        rawMsg = busErr.message;
      }
    }
    if (code === 1018700001) {
      return '当前设备暂不支持端侧 AI 图像超分增强，已保留原图画质';
    }
    if (code === 1013100001) {
      return '图片路径不符合端侧文搜图索引要求';
    }
    if (code === 1013100002) {
      return '当前设备暂不支持端侧 AI 文搜图服务，已切换为关键词检索';
    }
    if (code === 1013100003) {
      return '端侧文搜图模型已更新，正在重建本地索引';
    }
    if (code === 1008601001) {
      return '所选图片尺寸不符合文档扫描规范（需单边 224~8000 像素）';
    }
    if (code === 200) {
      return '文档扫描完成';
    }
    return rawMsg !== '' ? rawMsg : '端侧视觉服务暂不可用';
  }

  /**
   * 纯函数：计算文档扫描控件的推荐最大连拍张数（1..6）
   */
  public static clampDocScanMaxShots(maxShots: number = 1): number {
    return Number.isFinite(maxShots) ? Math.max(1, Math.min(6, Math.floor(maxShots))) : 1;
  }

  /**
   * 查询当前设备是否支持文档扫描系统能力（SystemCapability.AI.Component.DocScan）
   */
  public static isDocumentSheetDetectionSupported(): boolean {
    try {
      if (typeof canIUse === 'function') {
        return Boolean(canIUse('SystemCapability.AI.Component.DocScan'));
      }
      return false;
    } catch {
      return false;
    }
  }

  /**
   * API 26 端侧图像超分辨率增强（CoreVisionKit.imageSuperResolution）
   * 在模拟器或无 NPU 算力设备上优雅降级并返回原图
   */
  public static async enhancePixelMapSuperResolution(
    pixelMap: image.PixelMap | null | undefined
  ): Promise<SuperResolutionResult> {
    if (!pixelMap) {
      return {
        success: false,
        pixelMap: null,
        message: '未提供有效图像数据'
      };
    }
    let analyzer: imageSuperResolution.ImageSRAnalyzer | null = null;
    try {
      const info: image.ImageInfo = await pixelMap.getImageInfo();
      if (info && info.size &&
        !VisionEnhancementHelper.isEligibleForSuperResolution(info.size.width, info.size.height)) {
        return {
          success: false,
          pixelMap: pixelMap,
          message: '当前图片尺寸已为高清或超出端侧超分范围'
        };
      }
      analyzer = await imageSuperResolution.ImageSRAnalyzer.create();
      const request: visionBase.Request = new visionBase.Request();
      request.inputData = { pixelMap: pixelMap };
      const response: imageSuperResolution.ISPResponse = await analyzer.process(request);
      if (response && response.pixelMap) {
        return {
          success: true,
          pixelMap: response.pixelMap,
          message: '已完成端侧 AI 超分辨率画质增强'
        };
      }
      return {
        success: false,
        pixelMap: pixelMap,
        message: '端侧超分未返回新图像，已保持原图'
      };
    } catch (err) {
      return {
        success: false,
        pixelMap: pixelMap,
        message: VisionEnhancementHelper.formatVisionError(err as Object)
      };
    } finally {
      if (analyzer !== null) {
        try {
          await analyzer.destroy();
        } catch {
          // 忽略释放异常
        }
      }
    }
  }

  /**
   * API 26 端侧文搜图：将本地缓存图片特征写入端侧索引库
   */
  public static async indexImageForTextSearch(
    imagePath: string,
    scope: string = DEFAULT_VISION_SEARCH_SCOPE
  ): Promise<boolean> {
    if (!VisionEnhancementHelper.isValidImagePathForIndex(imagePath)) {
      return false;
    }
    const cleanPath: string = imagePath.trim();
    const cleanScope: string = VisionEnhancementHelper.sanitizeSearchScope(scope);
    try {
      if (!VisionEnhancementHelper.textSearchInitialized) {
        const ok: boolean = await textSearchImage.init();
        if (!ok) {
          return false;
        }
        VisionEnhancementHelper.textSearchInitialized = true;
      }
      return await textSearchImage.insertImage(cleanPath, cleanScope);
    } catch (err) {
      const busErr = err as BusinessError;
      if (busErr && busErr.code === 1013100003) {
        try {
          await textSearchImage.clearData();
          return await textSearchImage.insertImage(cleanPath, cleanScope);
        } catch {
          return false;
        }
      }
      return false;
    }
  }

  /**
   * API 26 端侧文搜图：按自然语言描述检索本地已索引图片
   */
  public static async searchImagesByText(
    query: string,
    scope: string = DEFAULT_VISION_SEARCH_SCOPE,
    topK: number = 20
  ): Promise<TextSearchQueryResult> {
    const cleanQuery: string = VisionEnhancementHelper.sanitizeSearchQuery(query);
    if (cleanQuery === '') {
      return {
        supported: true,
        items: [],
        message: '请输入搜索描述词'
      };
    }
    const cleanScope: string = VisionEnhancementHelper.sanitizeSearchScope(scope);
    const clampedTopK: number = Number.isFinite(topK) ? Math.max(1, Math.min(100, Math.floor(topK))) : 20;
    try {
      if (!VisionEnhancementHelper.textSearchInitialized) {
        const ok: boolean = await textSearchImage.init();
        if (!ok) {
          return {
            supported: false,
            items: [],
            message: '端侧文搜图引擎初始化失败，已切换关键词筛选'
          };
        }
        VisionEnhancementHelper.textSearchInitialized = true;
      }
      const rawList: textSearchImage.ImageObject[] = await textSearchImage.search(cleanQuery, cleanScope, clampedTopK);
      const mapped: VisionSearchMatchItem[] = [];
      if (Array.isArray(rawList)) {
        for (let i = 0; i < rawList.length; i++) {
          const item = rawList[i];
          if (item && typeof item.imagePath === 'string') {
            mapped.push({
              imagePath: item.imagePath,
              scope: typeof item.scope === 'string' ? item.scope : cleanScope,
              similarity: typeof item.similarity === 'number' ? item.similarity : 0
            });
          }
        }
      }
      const ranked: VisionSearchMatchItem[] = VisionEnhancementHelper.filterAndRankSearchResults(mapped, 0.05, clampedTopK);
      return {
        supported: true,
        items: ranked,
        message: ranked.length > 0 ? `找到 ${ranked.length} 张语义匹配图片` : '未找到高度匹配的本地缓存图片'
      };
    } catch (err) {
      return {
        supported: false,
        items: [],
        message: VisionEnhancementHelper.formatVisionError(err as Object)
      };
    }
  }

  /**
   * 释放端侧文搜图引擎资源
   */
  public static async releaseTextSearchEngine(): Promise<boolean> {
    if (!VisionEnhancementHelper.textSearchInitialized) {
      return true;
    }
    VisionEnhancementHelper.textSearchInitialized = false;
    try {
      return await textSearchImage.release();
    } catch {
      return false;
    }
  }
}
