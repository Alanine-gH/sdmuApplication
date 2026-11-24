import { schedulingOptimization } from '@kit.FASTKit';
import { UIContext } from '@kit.ArkUI';
import { BusinessError } from '@kit.BasicServicesKit';

export const FAST_SCENE_APP_LAUNCH: number = 1;
export const FAST_SCENE_PAGE_TRANSITION: number = 2;
export const FAST_SCENE_PAGE_LOAD: number = 3;
export const FAST_SCENE_NETWORK_FILE_PROCESSING: number = 4;
export const FAST_SCENE_LOCAL_FILE_PROCESSING: number = 5;
export const FAST_SCENE_PAGE_DRAWING: number = 6;
export const FAST_SCENE_ANIMATION: number = 7;
export const FAST_SCENE_MEDIA_PLAYBACK: number = 8;

export const FAST_STATE_END: number = 0;
export const FAST_STATE_BEGIN: number = 1;

export const FAST_DURATION_SHORT: number = 1;
export const FAST_DURATION_MEDIUM: number = 2;
export const FAST_DURATION_LONG: number = 3;

export const HDS_SNACKBAR_OP_TEXT_ONLY: number = 0;
export const HDS_SNACKBAR_OP_CLOSE_BUTTON_ONLY: number = 1;
export const HDS_SNACKBAR_OP_TEXT_WITH_CLOSE: number = 3;

export interface PerfHintPayload {
  sceneType: number;
  sceneState: number;
  durationType: number;
  tids: number[];
}

/**
 * HarmonyOS 7.0 (API 26) FASTKit 系统性能调度助手 & UIDesignKit HdsSnackBar 提示助手
 * - 在冷启动、重度课表/成绩 WebView 加载与复杂长列表切换时向系统上报 schedulingOptimization.perfHint
 * - 严格遵守 SDK 间隔约束（SHORT > 3s, MEDIUM > 30s, LONG > 180s，tids <= 16），防止触发 1027700005
 * - 提供 HdsSnackBar 规范反馈条，并在不支持设备上自动回退至 UIContext promptAction.showToast
 */
export class PerformanceSchedulerHelper {
  private static lastReportTimestampMap: Map<string, number> = new Map<string, number>();

  /**
   * 纯函数：获取不同 DurationType 的最小安全上报间隔（毫秒）
   * SDK 约束：SHORT 间隔 > 3s，MEDIUM 间隔 > 30s，LONG 间隔 > 180s
   */
  public static getMinIntervalMs(durationType: number): number {
    if (durationType === FAST_DURATION_LONG) {
      return 180500;
    }
    if (durationType === FAST_DURATION_MEDIUM) {
      return 30500;
    }
    return 3100;
  }

  /**
   * 纯函数：清洗线程 ID 数组（仅保留正整数、去重，且长度不超过 SDK 上限 16）
   */
  public static sanitizeThreadIds(tids?: number[]): number[] {
    if (!Array.isArray(tids) || tids.length === 0) {
      return [];
    }
    const result: number[] = [];
    const seen: Set<number> = new Set<number>();
    for (let i = 0; i < tids.length; i++) {
      const raw: number = tids[i];
      if (!Number.isFinite(raw)) {
        continue;
      }
      const tid: number = Math.floor(raw);
      if (tid <= 0 || seen.has(tid)) {
        continue;
      }
      seen.add(tid);
      result.push(tid);
      if (result.length >= 16) {
        break;
      }
    }
    return result;
  }

  /**
   * 纯函数：校验 sceneType 是否属于合法的 FASTKit 场景枚举（1..9）
   */
  public static normalizeSceneType(sceneType: number): number {
    if (!Number.isFinite(sceneType)) {
      return FAST_SCENE_PAGE_LOAD;
    }
    const code: number = Math.floor(sceneType);
    return (code >= 1 && code <= 9) ? code : FAST_SCENE_PAGE_LOAD;
  }

  /**
   * 纯函数：校验 durationType 是否属于合法的 FASTKit 时长枚举（1..3）
   */
  public static normalizeDurationType(durationType: number): number {
    if (durationType === FAST_DURATION_MEDIUM || durationType === FAST_DURATION_LONG) {
      return durationType;
    }
    return FAST_DURATION_SHORT;
  }

  /**
   * 纯函数：判断是否满足上报节流间隔并更新时间戳表
   */
  public static canReportPerfHint(
    sceneType: number,
    durationType: number,
    nowMs: number,
    recordMap?: Map<string, number>
  ): boolean {
    if (!Number.isFinite(nowMs) || nowMs < 0) {
      return false;
    }
    const normScene: number = PerformanceSchedulerHelper.normalizeSceneType(sceneType);
    const normDuration: number = PerformanceSchedulerHelper.normalizeDurationType(durationType);
    const key: string = `${normScene}_${normDuration}`;
    const mapToUse: Map<string, number> = recordMap ?? PerformanceSchedulerHelper.lastReportTimestampMap;
    const prevMs: number | undefined = mapToUse.get(key);
    const minInterval: number = PerformanceSchedulerHelper.getMinIntervalMs(normDuration);
    if (prevMs !== undefined && (nowMs - prevMs) < minInterval) {
      return false;
    }
    mapToUse.set(key, nowMs);
    return true;
  }

  /**
   * 纯函数：重置节流状态表（供单元测试使用）
   */
  public static resetThrottleForTest(): void {
    PerformanceSchedulerHelper.lastReportTimestampMap.clear();
  }

  /**
   * 纯函数：构建符合 PerfHintConfig 契约的负载
   */
  public static buildPerfHintPayload(
    sceneType: number,
    sceneState: number,
    durationType: number = FAST_DURATION_SHORT,
    tids?: number[]
  ): PerfHintPayload {
    return {
      sceneType: PerformanceSchedulerHelper.normalizeSceneType(sceneType),
      sceneState: sceneState === FAST_STATE_END ? FAST_STATE_END : FAST_STATE_BEGIN,
      durationType: PerformanceSchedulerHelper.normalizeDurationType(durationType),
      tids: PerformanceSchedulerHelper.sanitizeThreadIds(tids)
    };
  }

  /**
   * 纯函数：将 FASTKit 错误码转换为可读诊断信息
   */
  public static formatPerfHintError(code: number): string {
    if (code === 1027700001) {
      return '系统高负载中，已跳过额外调度提示';
    }
    if (code === 1027700002) {
      return '省电模式下不启用激进性能调度';
    }
    if (code === 1027700003) {
      return '低电量模式下不启用性能调度提示';
    }
    if (code === 1027700004) {
      return '非前台场景无需上报性能调度';
    }
    if (code === 1027700005) {
      return '调度上报间隔未达阈值，已自动节流';
    }
    if (code === 1027700006) {
      return '系统性能调度服务未就绪';
    }
    return '性能调度提示已静默降级';
  }

  /**
   * 上报性能敏感场景开始（带自动间隔节流与异常兜底）
   */
  public static async reportSceneBegin(
    sceneType: number,
    durationType: number = FAST_DURATION_SHORT,
    tids?: number[]
  ): Promise<boolean> {
    const nowMs: number = Date.now();
    if (!PerformanceSchedulerHelper.canReportPerfHint(sceneType, durationType, nowMs)) {
      return false;
    }
    const payload: PerfHintPayload = PerformanceSchedulerHelper.buildPerfHintPayload(
      sceneType,
      FAST_STATE_BEGIN,
      durationType,
      tids
    );
    try {
      await schedulingOptimization.perfHint({
        sceneType: payload.sceneType as schedulingOptimization.SceneType,
        sceneState: payload.sceneState as schedulingOptimization.SceneState,
        durationType: payload.durationType as schedulingOptimization.DurationType,
        tids: payload.tids
      });
      return true;
    } catch {
      return false;
    }
  }

  /**
   * 上报性能敏感场景结束
   */
  public static async reportSceneEnd(
    sceneType: number,
    durationType: number = FAST_DURATION_SHORT,
    tids?: number[]
  ): Promise<boolean> {
    const payload: PerfHintPayload = PerformanceSchedulerHelper.buildPerfHintPayload(
      sceneType,
      FAST_STATE_END,
      durationType,
      tids
    );
    try {
      await schedulingOptimization.perfHint({
        sceneType: payload.sceneType as schedulingOptimization.SceneType,
        sceneState: payload.sceneState as schedulingOptimization.SceneState,
        durationType: payload.durationType as schedulingOptimization.DurationType,
        tids: payload.tids
      });
      return true;
    } catch {
      return false;
    }
  }

  /**
   * 展示符合鸿蒙规范的轻提示（支持标题+副标题组装，安全降级不崩溃）
   */
  public static showHdsOrFallbackSnackBar(
    uiContext: UIContext | null | undefined,
    title: string,
    content: string = '',
    _actionText: string = '',
    _onAction?: () => void
  ): boolean {
    const cleanTitle: string = (title || '').trim();
    const cleanContent: string = (content || '').trim();
    if (cleanTitle === '' && cleanContent === '') {
      return false;
    }
    if (!uiContext) {
      return false;
    }
    try {
      const toastMsg: string = cleanContent !== '' && cleanTitle !== ''
        ? `${cleanTitle}：${cleanContent}`
        : (cleanTitle !== '' ? cleanTitle : cleanContent);
      uiContext.getPromptAction().showToast({ message: toastMsg, duration: 2000 });
      return true;
    } catch (_toastErr) {
      const _ignore = _toastErr as BusinessError;
      return false;
    }
  }
}
