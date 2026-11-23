import { BreakpointSystem, CreaseRegionVp } from './BreakpointSystem';

export interface SplitPaneConfig {
  useTwoPane: boolean;
  masterRatio: number;
  detailRatio: number;
  masterMinWidthVp: number;
}

/**
 * 纯响应式自适应布局辅助工具（无原生系统依赖，支持 Host 单元测试直接执行）
 */
export class AdaptiveLayoutHelper {
  /** 构建 Grid columnsTemplate 字符串 */
  public static buildColumnsTemplate(cols: number): string {
    const safeCols: number = Number.isFinite(cols) && cols > 0 ? Math.min(24, Math.floor(cols)) : 1;
    let tpl: string = '1fr';
    for (let i = 1; i < safeCols; i++) {
      tpl += ' 1fr';
    }
    return tpl;
  }

  /** 计算弹窗最大宽度（vp） */
  public static getDialogMaxWidth(bp: string, windowWidthVp: number): number {
    return BreakpointSystem.getDialogMaxWidth(bp, windowWidthVp);
  }

  /** 计算弹窗最大高度（vp） */
  public static getDialogMaxHeight(windowHeightVp: number): number {
    return BreakpointSystem.getDialogMaxHeight(windowHeightVp);
  }

  /** 判断半模态弹窗是否应居中展示（大屏或横屏紧凑高窗优先居中） */
  public static shouldUseCenterSheet(bp: string, isCompactHeight: boolean = false): boolean {
    if (isCompactHeight) {
      return true;
    }
    return bp === 'md' || bp === 'lg' || bp === 'xl';
  }

  /** 计算半模态弹窗最大宽度 */
  public static getSheetMaxWidth(bp: string, windowWidthVp: number): number | string {
    if (bp === 'xs' || bp === 'sm') {
      return '100%';
    }
    const safeW: number = windowWidthVp > 0 ? windowWidthVp : 720;
    if (bp === 'md') {
      return Math.min(520, Math.max(360, safeW - 64));
    }
    return Math.min(600, Math.max(420, safeW - 96));
  }

  /** 计算主从双栏分屏配置（适用于 lg/xl 宽屏平板与折叠屏展开态） */
  public static getSplitPaneConfig(bp: string, windowWidthVp: number): SplitPaneConfig {
    const safeW: number = windowWidthVp > 0 ? windowWidthVp : 360;
    if (bp === 'lg' || bp === 'xl' || (bp === 'md' && safeW >= 720)) {
      return {
        useTwoPane: true,
        masterRatio: 2,
        detailRatio: 3,
        masterMinWidthVp: 300
      };
    }
    return {
      useTwoPane: false,
      masterRatio: 1,
      detailRatio: 0,
      masterMinWidthVp: safeW
    };
  }

  /** 计算手势密码九宫格尺寸（vp） */
  public static computeGestureGridSize(windowWidthVp: number, windowHeightVp: number): number {
    return BreakpointSystem.computeGestureGridSize(windowWidthVp, windowHeightVp);
  }

  /** 判断是否处于半折叠悬停态（含单折叠与双折叠枚举值） */
  public static isHalfFoldedStatus(foldStatus: number): boolean {
    return foldStatus === 3 || foldStatus === 13 || foldStatus === 21 || foldStatus === 22 || foldStatus === 23;
  }

  /** 判断当前是否需要避让折痕区 */
  public static shouldAvoidCrease(creaseRegionVp: CreaseRegionVp | null, foldStatus: number): boolean {
    return AdaptiveLayoutHelper.isHalfFoldedStatus(foldStatus) &&
      creaseRegionVp !== null &&
      creaseRegionVp.height > 0;
  }

  /** 获取折痕避让高度（vp） */
  public static getCreaseAvoidHeightVp(creaseRegionVp: CreaseRegionVp | null, foldStatus: number): number {
    if (!AdaptiveLayoutHelper.shouldAvoidCrease(creaseRegionVp, foldStatus)) {
      return 0;
    }
    return creaseRegionVp !== null ? creaseRegionVp.height : 0;
  }
}
