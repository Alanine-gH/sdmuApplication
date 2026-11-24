import { motion } from '@kit.MultimodalAwarenessKit';
import { Callback } from '@kit.BasicServicesKit';

export const HOLDING_HAND_NOT_HELD: number = 0;
export const HOLDING_HAND_LEFT: number = 1;
export const HOLDING_HAND_RIGHT: number = 2;
export const HOLDING_HAND_BOTH: number = 3;
export const HOLDING_HAND_UNKNOWN: number = 16;

export interface FabHandAlignment {
  alignLeft: boolean;
  leftMarginVp: number;
  rightMarginVp: number;
  statusLabel: string;
}

/**
 * 端侧智感握姿感知助手（基于 @kit.MultimodalAwarenessKit motion.HoldingHandStatus, API 20+）
 * - 权限：ohos.permission.DETECT_GESTURE（normal system_grant）
 * - 在直板/阔直板/折叠屏闭合态（xs/sm）下感知用户左手/右手单手握持，动态调整课表页等右下角悬浮 FAB 的左右停靠位置
 * - 在平板/展开态（md/lg/xl）或双手/未握持/不支持传感器设备上默认保持右侧停靠
 */
export class HoldingHandHelper {
  public static readonly STORAGE_KEY_HOLDING_HAND: string = 'holdingHandStatus';
  private static isSubscribed: boolean = false;
  private static listener: Callback<motion.HoldingHandStatus> | null = null;

  /**
   * 纯函数：归一化握姿状态枚举值
   */
  public static normalizeHoldingHandStatus(raw: number): number {
    if (raw === HOLDING_HAND_NOT_HELD ||
      raw === HOLDING_HAND_LEFT ||
      raw === HOLDING_HAND_RIGHT ||
      raw === HOLDING_HAND_BOTH) {
      return raw;
    }
    return HOLDING_HAND_UNKNOWN;
  }

  /**
   * 纯函数：获取握姿状态的中文描述
   */
  public static getHoldingHandLabel(status: number): string {
    const norm: number = HoldingHandHelper.normalizeHoldingHandStatus(status);
    if (norm === HOLDING_HAND_LEFT) {
      return '左手握持';
    }
    if (norm === HOLDING_HAND_RIGHT) {
      return '右手握持';
    }
    if (norm === HOLDING_HAND_BOTH) {
      return '双手握持';
    }
    if (norm === HOLDING_HAND_NOT_HELD) {
      return '未握持';
    }
    return '默认右手布局';
  }

  /**
   * 纯函数：判断是否应将单手操作悬浮按钮（FAB）停靠在左侧
   * 仅当设备处于单手手机/外屏形态（xs 或 sm）且明确识别为左手握持（HOLDING_HAND_LEFT）时左停靠
   */
  public static shouldAlignFabLeft(
    holdingStatus: number,
    breakpoint: string,
    isSplitTwoPane: boolean = false
  ): boolean {
    if (isSplitTwoPane) {
      return false;
    }
    const bp: string = (breakpoint || 'sm').trim().toLowerCase();
    if (bp !== 'xs' && bp !== 'sm') {
      return false;
    }
    const norm: number = HoldingHandHelper.normalizeHoldingHandStatus(holdingStatus);
    return norm === HOLDING_HAND_LEFT;
  }

  /**
   * 纯函数：计算悬浮 FAB 的左右边距与对齐方式（避让课表左侧节次轴与安全区）
   */
  public static computeFabHandAlignment(
    holdingStatus: number,
    breakpoint: string,
    avoidLeftVp: number = 0,
    avoidRightVp: number = 0,
    leftAxisOffsetVp: number = 50,
    isSplitTwoPane: boolean = false
  ): FabHandAlignment {
    const safeAvoidLeft: number = Number.isFinite(avoidLeftVp) && avoidLeftVp > 0 ? avoidLeftVp : 0;
    const safeAvoidRight: number = Number.isFinite(avoidRightVp) && avoidRightVp > 0 ? avoidRightVp : 0;
    const safeAxisOffset: number = Number.isFinite(leftAxisOffsetVp) && leftAxisOffsetVp > 0 ? leftAxisOffsetVp : 0;
    const alignLeft: boolean = HoldingHandHelper.shouldAlignFabLeft(holdingStatus, breakpoint, isSplitTwoPane);
    const leftMarginVp: number = alignLeft
      ? Math.max(12, safeAvoidLeft + 10) + safeAxisOffset
      : Math.max(10, safeAvoidLeft + 10);
    const rightMarginVp: number = Math.max(10, safeAvoidRight + 10);
    return {
      alignLeft: alignLeft,
      leftMarginVp: leftMarginVp,
      rightMarginVp: rightMarginVp,
      statusLabel: HoldingHandHelper.getHoldingHandLabel(holdingStatus)
    };
  }

  /**
   * 订阅系统智感握姿变化事件并同步至 AppStorage('holdingHandStatus')
   */
  public static subscribeHoldingHandChanged(): boolean {
    try {
      AppStorage.setOrCreate<number>(HoldingHandHelper.STORAGE_KEY_HOLDING_HAND, HOLDING_HAND_UNKNOWN);
    } catch {
      // Host 单测无 AppStorage 时忽略
    }
    if (HoldingHandHelper.isSubscribed) {
      return true;
    }
    try {
      if (typeof canIUse === 'function' && !canIUse('SystemCapability.MultimodalAwareness.Motion')) {
        return false;
      }
      const cb: Callback<motion.HoldingHandStatus> = (status: motion.HoldingHandStatus): void => {
        const norm: number = HoldingHandHelper.normalizeHoldingHandStatus(Number(status));
        try {
          AppStorage.setOrCreate<number>(HoldingHandHelper.STORAGE_KEY_HOLDING_HAND, norm);
        } catch {
          // 忽略
        }
      };
      motion.on('holdingHandChanged', cb);
      HoldingHandHelper.listener = cb;
      HoldingHandHelper.isSubscribed = true;
      return true;
    } catch {
      HoldingHandHelper.listener = null;
      HoldingHandHelper.isSubscribed = false;
      return false;
    }
  }

  /**
   * 取消订阅智感握姿变化事件
   */
  public static unsubscribeHoldingHandChanged(): void {
    if (!HoldingHandHelper.isSubscribed) {
      return;
    }
    try {
      if (HoldingHandHelper.listener !== null) {
        motion.off('holdingHandChanged', HoldingHandHelper.listener);
      } else {
        motion.off('holdingHandChanged');
      }
    } catch {
      // 设备不支持或已注销时忽略
    } finally {
      HoldingHandHelper.listener = null;
      HoldingHandHelper.isSubscribed = false;
    }
  }
}
