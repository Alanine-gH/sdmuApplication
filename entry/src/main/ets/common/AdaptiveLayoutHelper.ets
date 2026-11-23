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

  /** 计算半模态弹窗优先弹出类型 */
  public static getSheetPreferType(bp: string, isCompactHeight: boolean = false): SheetType {
    return AdaptiveLayoutHelper.shouldUseCenterSheet(bp, isCompactHeight) ? SheetType.CENTER : SheetType.BOTTOM;
  }

  /** 计算半模态弹窗最大宽度 */
  public static getSheetMaxWidth(bp: string, windowWidthVp: number): number | string {
    if (bp === 'xs' || bp === 'sm') {
      return '100%';
    }
    const safeW: number = Number.isFinite(windowWidthVp) && windowWidthVp > 0 ? windowWidthVp : 720;
    if (bp === 'md') {
      return Math.min(520, Math.max(360, safeW - 64));
    }
    return Math.min(600, Math.max(420, safeW - 96));
  }

  /** 计算主从双栏分屏配置（适用于 lg/xl 宽屏平板与折叠屏展开态） */
  public static getSplitPaneConfig(bp: string, windowWidthVp: number): SplitPaneConfig {
    const safeW: number = Number.isFinite(windowWidthVp) && windowWidthVp > 0 ? windowWidthVp : 360;
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

  /** 计算支持自定义主从比例的双栏分屏配置 */
  public static getSplitPaneConfigWithRatio(
    bp: string,
    windowWidthVp: number,
    masterRatio: number,
    detailRatio: number
  ): SplitPaneConfig {
    const base: SplitPaneConfig = AdaptiveLayoutHelper.getSplitPaneConfig(bp, windowWidthVp);
    if (!base.useTwoPane) {
      return base;
    }
    const safeMaster: number = Number.isFinite(masterRatio) && masterRatio > 0 ? masterRatio : base.masterRatio;
    const safeDetail: number = Number.isFinite(detailRatio) && detailRatio > 0 ? detailRatio : base.detailRatio;
    return {
      useTwoPane: true,
      masterRatio: safeMaster,
      detailRatio: safeDetail,
      masterMinWidthVp: base.masterMinWidthVp
    };
  }

  /** 计算自适应宫格总高度（vp） */
  public static computeGridHeightVp(
    itemCount: number,
    cols: number,
    rowHeightVp: number,
    rowGapVp: number = 0,
    extraPadVp: number = 0
  ): number {
    if (!Number.isFinite(itemCount) || itemCount <= 0) {
      return 0;
    }
    const safeCols: number = Number.isFinite(cols) && cols >= 1 ? Math.floor(cols) : 1;
    const safeRowH: number = Number.isFinite(rowHeightVp) && rowHeightVp > 0 ? rowHeightVp : 0;
    const safeGap: number = Number.isFinite(rowGapVp) && rowGapVp > 0 ? rowGapVp : 0;
    const safePad: number = Number.isFinite(extraPadVp) && extraPadVp > 0 ? extraPadVp : 0;
    const rows: number = Math.ceil(itemCount / safeCols);
    return rows * safeRowH + Math.max(0, rows - 1) * safeGap + safePad;
  }

  /** 计算瀑布流单列宽度（vp） */
  public static computeWaterFlowColWidthVp(
    windowWidthVp: number,
    maxContentWidthVp: number,
    cols: number,
    gapVp: number
  ): number {
    const safeW: number = Number.isFinite(windowWidthVp) && windowWidthVp > 0 ? windowWidthVp : 360;
    const safeMax: number = Number.isFinite(maxContentWidthVp) && maxContentWidthVp > 0
      ? Math.min(safeW, maxContentWidthVp)
      : safeW;
    const safeCols: number = Number.isFinite(cols) && cols >= 1 ? Math.floor(cols) : 1;
    const safeGap: number = Number.isFinite(gapVp) && gapVp >= 0 ? gapVp : 0;
    const avail: number = Math.max(80, safeMax - (safeCols + 1) * safeGap);
    return Math.floor(avail / safeCols);
  }

  /** 根据原始宽高与列宽按比例计算瀑布流条目高度（vp） */
  public static computeAspectScaledHeightVp(
    rawW: number,
    rawH: number,
    colWidthVp: number,
    fallbackHeightVp: number
  ): number {
    const safeFallback: number = Number.isFinite(fallbackHeightVp) && fallbackHeightVp > 0 ? fallbackHeightVp : 165;
    if (
      !Number.isFinite(rawW) ||
      !Number.isFinite(rawH) ||
      !Number.isFinite(colWidthVp) ||
      rawW <= 0 ||
      rawH <= 0 ||
      colWidthVp <= 0
    ) {
      return safeFallback;
    }
    return Math.max(40, Math.round((rawH / rawW) * colWidthVp));
  }

  /** 计算手势密码九宫格尺寸（vp） */
  public static computeGestureGridSize(windowWidthVp: number, windowHeightVp: number): number {
    return BreakpointSystem.computeGestureGridSize(windowWidthVp, windowHeightVp);
  }

  /** 判断是否处于半折叠悬停态（含单折叠与双折叠枚举值） */
  public static isHalfFoldedStatus(foldStatus: number): boolean {
    return foldStatus === 3 || foldStatus === 13 || foldStatus === 21 || foldStatus === 22 || foldStatus === 23;
  }

  /** 判断折痕区是否为横向折痕（排除竖屏纵向折痕） */
  public static isHorizontalCrease(creaseRegionVp: CreaseRegionVp | null): boolean {
    return creaseRegionVp !== null &&
      Number.isFinite(creaseRegionVp.width) &&
      Number.isFinite(creaseRegionVp.height) &&
      creaseRegionVp.width > creaseRegionVp.height &&
      creaseRegionVp.height > 0 &&
      creaseRegionVp.height < 200;
  }

  /** 判断当前是否需要避让折痕区 */
  public static shouldAvoidCrease(creaseRegionVp: CreaseRegionVp | null, foldStatus: number): boolean {
    return AdaptiveLayoutHelper.isHalfFoldedStatus(foldStatus) &&
      AdaptiveLayoutHelper.isHorizontalCrease(creaseRegionVp);
  }

  /** 获取折痕避让高度（vp） */
  public static getCreaseAvoidHeightVp(creaseRegionVp: CreaseRegionVp | null, foldStatus: number): number {
    if (!AdaptiveLayoutHelper.shouldAvoidCrease(creaseRegionVp, foldStatus)) {
      return 0;
    }
    return creaseRegionVp !== null ? creaseRegionVp.height : 0;
  }

  /** 计算半折叠悬停时折痕上方区域可用最大高度（vp） */
  public static computeCreaseUpperHeightVp(
    creaseRegionVp: CreaseRegionVp | null,
    foldStatus: number,
    fallbackVp: number
  ): number {
    const safeFallback: number = Number.isFinite(fallbackVp) && fallbackVp > 0 ? fallbackVp : 210;
    if (!AdaptiveLayoutHelper.shouldAvoidCrease(creaseRegionVp, foldStatus) || creaseRegionVp === null) {
      return safeFallback;
    }
    if (!Number.isFinite(creaseRegionVp.top) || creaseRegionVp.top <= 0) {
      return safeFallback;
    }
    return Math.min(safeFallback, Math.max(0, creaseRegionVp.top - 8));
  }
}
