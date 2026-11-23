import { display, UIContext, window } from '@kit.ArkUI';

export type BreakpointType = 'xs' | 'sm' | 'md' | 'lg' | 'xl';
export type HeightBreakpointType = 'sm' | 'md' | 'lg';

export interface CreaseRegionVp {
  left: number;
  top: number;
  width: number;
  height: number;
}

/**
 * 多形态设备响应式断点与窗口安全区系统：
 * - xs (<320vp): 穿戴设备 / 超窄折叠外屏 / 极窄分屏
 * - sm (320vp~599vp): 直板手机竖屏 / 折叠屏外屏
 * - md (600vp~839vp): 阔直板 (Pura X Max)、折叠屏展开态、小尺寸平板竖屏
 * - lg (840vp~1439vp): 平板横屏、三折叠屏展开态
 * - xl (>=1440vp): 大屏平板 / 桌面窗口
 */
export class BreakpointSystem {
  public static readonly KEY_BREAKPOINT: string = 'currentBreakpoint';
  public static readonly KEY_HEIGHT_BREAKPOINT: string = 'heightBreakpoint';
  public static readonly KEY_IS_WIDE: string = 'isWideScreen';
  public static readonly KEY_IS_LANDSCAPE: string = 'isLandscape';
  public static readonly KEY_IS_COMPACT_HEIGHT: string = 'isCompactHeight';
  public static readonly KEY_WINDOW_WIDTH_VP: string = 'windowWidthVp';
  public static readonly KEY_WINDOW_HEIGHT_VP: string = 'windowHeightVp';
  public static readonly KEY_ASPECT_RATIO: string = 'aspectRatio';
  public static readonly KEY_FOLD_STATUS: string = 'foldStatus';
  public static readonly KEY_FOLD_DISPLAY_MODE: string = 'foldDisplayMode';
  public static readonly KEY_CREASE_REGION_VP: string = 'creaseRegionVp';
  public static readonly KEY_AVOID_TOP_VP: string = 'avoidAreaTopVp';
  public static readonly KEY_AVOID_BOTTOM_VP: string = 'avoidAreaBottomVp';
  public static readonly KEY_AVOID_LEFT_VP: string = 'avoidAreaLeftVp';
  public static readonly KEY_AVOID_RIGHT_VP: string = 'avoidAreaRightVp';
  public static readonly KEY_KEYBOARD_HEIGHT_VP: string = 'keyboardHeightVp';

  public static readonly BP_XS_MAX: number = 320;
  public static readonly BP_SM_MAX: number = 600;
  public static readonly BP_MD_MAX: number = 840;
  public static readonly BP_LG_MAX: number = 1440;
  public static readonly HEIGHT_RATIO_SM_MAX: number = 0.8;
  public static readonly HEIGHT_RATIO_MD_MAX: number = 1.2;
  public static readonly COMPACT_HEIGHT_VP_MAX: number = 520;

  private static foldStatusCallback: ((status: display.FoldStatus) => void) | null = null;
  private static foldDisplayModeCallback: ((mode: display.FoldDisplayMode) => void) | null = null;

  /** 纯函数：根据 vp 宽度计算五档宽度断点 */
  public static computeBreakpoint(widthVp: number): BreakpointType {
    if (widthVp >= BreakpointSystem.BP_LG_MAX) {
      return 'xl';
    }
    if (widthVp >= BreakpointSystem.BP_MD_MAX) {
      return 'lg';
    }
    if (widthVp >= BreakpointSystem.BP_SM_MAX) {
      return 'md';
    }
    if (widthVp >= BreakpointSystem.BP_XS_MAX) {
      return 'sm';
    }
    return 'xs';
  }

  /** 纯函数：根据窗口高宽比（height / width）计算三档高度断点 */
  public static computeHeightBreakpoint(widthVp: number, heightVp: number): HeightBreakpointType {
    if (!Number.isFinite(widthVp) || !Number.isFinite(heightVp) || widthVp <= 0 || heightVp <= 0) {
      return 'sm';
    }
    const ratio: number = heightVp / widthVp;
    if (ratio < BreakpointSystem.HEIGHT_RATIO_SM_MAX) {
      return 'sm';
    }
    if (ratio < BreakpointSystem.HEIGHT_RATIO_MD_MAX) {
      return 'md';
    }
    return 'lg';
  }

  /** 纯函数：计算高宽比（heightVp / widthVp） */
  public static computeAspectRatio(widthVp: number, heightVp: number): number {
    if (!Number.isFinite(widthVp) || !Number.isFinite(heightVp) || widthVp <= 0 || heightVp <= 0) {
      return 0;
    }
    return heightVp / widthVp;
  }

  /** 纯函数：判断是否应切换侧边导航栏（平板/三折叠/横屏矮窗） */
  public static shouldUseSideRail(
    widthBp: string,
    heightBp: string,
    isLandscape: boolean = false
  ): boolean {
    if (widthBp === 'lg' || widthBp === 'xl') {
      return true;
    }
    if (heightBp === 'sm') {
      return true;
    }
    if (isLandscape && widthBp === 'sm') {
      return true;
    }
    return false;
  }

  /** 纯函数：是否为紧凑窄屏（xs / sm） */
  public static isCompactWidth(bp: string): boolean {
    return bp === 'xs' || bp === 'sm';
  }

  /** 纯函数：将 ArkUI WidthBreakpoint 枚举数值映射为断点名 */
  public static mapWidthBreakpoint(val: number): BreakpointType {
    if (val === 0) {
      return 'xs';
    }
    if (val === 1) {
      return 'sm';
    }
    if (val === 2) {
      return 'md';
    }
    if (val === 3) {
      return 'lg';
    }
    if (val === 4) {
      return 'xl';
    }
    return 'sm';
  }

  /** 纯函数：将 ArkUI HeightBreakpoint 枚举数值映射为高度断点名 */
  public static mapHeightBreakpoint(val: number): HeightBreakpointType {
    if (val === 0) {
      return 'sm';
    }
    if (val === 1) {
      return 'md';
    }
    return 'lg';
  }

  /** 纯函数：根据断点返回内容区最大宽度 */
  public static getContentMaxWidth(bp: string): number | string {
    if (bp === 'xl') {
      return 1200;
    }
    if (bp === 'lg') {
      return 1080;
    }
    if (bp === 'md') {
      return 720;
    }
    return '100%';
  }

  /** 纯函数：根据断点返回应用宫格列数 */
  public static getAppGridColumns(bp: string): number {
    if (bp === 'xl') {
      return 10;
    }
    if (bp === 'lg') {
      return 8;
    }
    if (bp === 'md') {
      return 6;
    }
    if (bp === 'xs') {
      return 3;
    }
    return 4;
  }

  /** 纯函数：根据断点返回卡片列表列数 */
  public static getListColumns(bp: string): number {
    if (bp === 'lg' || bp === 'xl') {
      return 2;
    }
    return 1;
  }

  /** 纯函数：根据断点及手机基准列数推算通用宫格列数 */
  public static getGridColumns(bp: string, basePhoneCols: number = 4): number {
    const safeBase: number = basePhoneCols > 0 ? basePhoneCols : 4;
    if (bp === 'xl') {
      return Math.max(safeBase, Math.round(safeBase * 2.5));
    }
    if (bp === 'lg') {
      return safeBase * 2;
    }
    if (bp === 'md') {
      return Math.max(safeBase, Math.round(safeBase * 1.5));
    }
    if (bp === 'xs') {
      return Math.max(2, safeBase - 1);
    }
    return safeBase;
  }

  /** 纯函数：计算弹窗最大宽度（vp） */
  public static getDialogMaxWidth(bp: string, windowWidthVp: number): number {
    const safeWidth: number = windowWidthVp > 0 ? windowWidthVp : 360;
    const marginCap: number = Math.max(240, safeWidth - 32);
    if (bp === 'xs' || bp === 'sm') {
      return Math.min(400, marginCap);
    }
    if (bp === 'md') {
      return Math.min(480, marginCap);
    }
    return Math.min(560, marginCap);
  }

  /** 纯函数：计算弹窗最大高度（vp） */
  public static getDialogMaxHeight(windowHeightVp: number): number {
    const safeHeight: number = windowHeightVp > 0 ? windowHeightVp : 640;
    return Math.max(220, Math.round(safeHeight * 0.82));
  }

  /** 纯函数：计算手势密码九宫格自适应尺寸（vp） */
  public static computeGestureGridSize(windowWidthVp: number, windowHeightVp: number): number {
    const safeW: number = windowWidthVp > 0 ? windowWidthVp : 360;
    const safeH: number = windowHeightVp > 0 ? windowHeightVp : 640;
    const availW: number = Math.max(180, safeW - 48);
    const availH: number = Math.max(180, safeH * 0.45);
    return Math.round(Math.min(340, availW, availH));
  }

  /** 纯函数：px 转 vp（独立于原生 display） */
  public static pxToVpWithDensity(px: number, density: number): number {
    if (!Number.isFinite(px) || px <= 0) {
      return 0;
    }
    const safeDensity: number = Number.isFinite(density) && density > 0 ? density : 1;
    return px / safeDensity;
  }

  /** 纯函数：将物理像素折痕矩形转换为 vp */
  public static convertCreaseRectToVp(
    leftPx: number,
    topPx: number,
    widthPx: number,
    heightPx: number,
    density: number
  ): CreaseRegionVp | null {
    if (widthPx <= 0 || heightPx <= 0) {
      return null;
    }
    return {
      left: BreakpointSystem.pxToVpWithDensity(leftPx, density),
      top: BreakpointSystem.pxToVpWithDensity(topPx, density),
      width: BreakpointSystem.pxToVpWithDensity(widthPx, density),
      height: BreakpointSystem.pxToVpWithDensity(heightPx, density)
    };
  }

  private static getSafeDensity(): number {
    try {
      const density: number = display.getDefaultDisplaySync().densityPixels;
      return density > 0 ? density : 1;
    } catch {
      return 1;
    }
  }

  private static pxToVp(px: number, uiContext?: UIContext): number {
    if (px <= 0) {
      return 0;
    }
    if (uiContext) {
      try {
        return uiContext.px2vp(px);
      } catch {
        // 回落密度换算
      }
    }
    return BreakpointSystem.pxToVpWithDensity(px, BreakpointSystem.getSafeDensity());
  }

  /** 更新 AppStorage 中的窗口断点、高度断点与横竖屏状态 */
  public static updateFromPx(widthPx: number, heightPx: number, uiContext?: UIContext): void {
    try {
      const widthVp: number = BreakpointSystem.pxToVp(widthPx, uiContext);
      const heightVp: number = BreakpointSystem.pxToVp(heightPx, uiContext);
      const bp: BreakpointType = BreakpointSystem.computeBreakpoint(widthVp);
      const hBp: HeightBreakpointType = BreakpointSystem.computeHeightBreakpoint(widthVp, heightVp);
      const ratio: number = BreakpointSystem.computeAspectRatio(widthVp, heightVp);
      const isCompactHeight: boolean = hBp === 'sm' ||
        (heightVp > 0 && heightVp < BreakpointSystem.COMPACT_HEIGHT_VP_MAX);

      AppStorage.setOrCreate<string>(BreakpointSystem.KEY_BREAKPOINT, bp);
      AppStorage.setOrCreate<string>(BreakpointSystem.KEY_HEIGHT_BREAKPOINT, hBp);
      AppStorage.setOrCreate<boolean>(BreakpointSystem.KEY_IS_WIDE, !BreakpointSystem.isCompactWidth(bp));
      AppStorage.setOrCreate<boolean>(BreakpointSystem.KEY_IS_LANDSCAPE, widthVp > heightVp);
      AppStorage.setOrCreate<boolean>(BreakpointSystem.KEY_IS_COMPACT_HEIGHT, isCompactHeight);
      AppStorage.setOrCreate<number>(BreakpointSystem.KEY_WINDOW_WIDTH_VP, widthVp);
      AppStorage.setOrCreate<number>(BreakpointSystem.KEY_WINDOW_HEIGHT_VP, heightVp);
      AppStorage.setOrCreate<number>(BreakpointSystem.KEY_ASPECT_RATIO, ratio);
      BreakpointSystem.refreshFoldMetrics();
    } catch {
      // 忽略异常窗口尺寸回调
    }
  }

  /** 根据 UIObserver WindowSizeLayoutBreakpointInfo 更新布局断点 */
  public static updateFromLayoutBreakpoint(widthBpVal: number, heightBpVal: number): void {
    try {
      const bp: BreakpointType = BreakpointSystem.mapWidthBreakpoint(widthBpVal);
      const hBp: HeightBreakpointType = BreakpointSystem.mapHeightBreakpoint(heightBpVal);
      const winH: number = AppStorage.get<number>(BreakpointSystem.KEY_WINDOW_HEIGHT_VP) ?? 0;
      const isCompactHeight: boolean = hBp === 'sm' ||
        (winH > 0 && winH < BreakpointSystem.COMPACT_HEIGHT_VP_MAX);

      AppStorage.setOrCreate<string>(BreakpointSystem.KEY_BREAKPOINT, bp);
      AppStorage.setOrCreate<string>(BreakpointSystem.KEY_HEIGHT_BREAKPOINT, hBp);
      AppStorage.setOrCreate<boolean>(BreakpointSystem.KEY_IS_WIDE, !BreakpointSystem.isCompactWidth(bp));
      AppStorage.setOrCreate<boolean>(BreakpointSystem.KEY_IS_COMPACT_HEIGHT, isCompactHeight);
    } catch {
      // 忽略异常断点通知
    }
  }

  /** 读取并聚合系统栏/刘海/导航条/软键盘避让区 */
  public static updateAvoidAreas(win: window.Window, uiContext?: UIContext): void {
    try {
      const types: window.AvoidAreaType[] = [
        window.AvoidAreaType.TYPE_SYSTEM,
        window.AvoidAreaType.TYPE_CUTOUT,
        window.AvoidAreaType.TYPE_NAVIGATION_INDICATOR,
        window.AvoidAreaType.TYPE_KEYBOARD
      ];
      let topPx: number = 0;
      let bottomPx: number = 0;
      let leftPx: number = 0;
      let rightPx: number = 0;
      let keyboardPx: number = 0;

      for (const t of types) {
        try {
          const area: window.AvoidArea = win.getWindowAvoidArea(t);
          if (!area) {
            continue;
          }
          if (t === window.AvoidAreaType.TYPE_KEYBOARD) {
            if (area.visible) {
              keyboardPx = Math.max(keyboardPx, area.bottomRect.height);
            }
            continue;
          }
          if (area.visible || t === window.AvoidAreaType.TYPE_CUTOUT) {
            topPx = Math.max(topPx, area.topRect.height);
            bottomPx = Math.max(bottomPx, area.bottomRect.height);
            leftPx = Math.max(leftPx, area.leftRect.width);
            rightPx = Math.max(rightPx, area.rightRect.width);
          }
        } catch {
          // 单类型避让区查询失败忽略
        }
      }

      AppStorage.setOrCreate<number>(BreakpointSystem.KEY_AVOID_TOP_VP, BreakpointSystem.pxToVp(topPx, uiContext));
      AppStorage.setOrCreate<number>(
        BreakpointSystem.KEY_AVOID_BOTTOM_VP,
        BreakpointSystem.pxToVp(bottomPx, uiContext)
      );
      AppStorage.setOrCreate<number>(BreakpointSystem.KEY_AVOID_LEFT_VP, BreakpointSystem.pxToVp(leftPx, uiContext));
      AppStorage.setOrCreate<number>(BreakpointSystem.KEY_AVOID_RIGHT_VP, BreakpointSystem.pxToVp(rightPx, uiContext));
      AppStorage.setOrCreate<number>(
        BreakpointSystem.KEY_KEYBOARD_HEIGHT_VP,
        BreakpointSystem.pxToVp(keyboardPx, uiContext)
      );
    } catch {
      // 忽略异常
    }
  }

  /** 更新软键盘高度（vp） */
  public static updateKeyboardHeightPx(heightPx: number, uiContext?: UIContext): void {
    try {
      AppStorage.setOrCreate<number>(
        BreakpointSystem.KEY_KEYBOARD_HEIGHT_VP,
        BreakpointSystem.pxToVp(heightPx, uiContext)
      );
    } catch {
      // 忽略异常
    }
  }

  /** 刷新折叠屏状态、显示模式与折痕矩形（vp） */
  public static refreshFoldMetrics(): void {
    try {
      if (!display.isFoldable()) {
        AppStorage.setOrCreate<number>(BreakpointSystem.KEY_FOLD_STATUS, 0);
        AppStorage.setOrCreate<number>(BreakpointSystem.KEY_FOLD_DISPLAY_MODE, 0);
        AppStorage.setOrCreate<CreaseRegionVp | null>(BreakpointSystem.KEY_CREASE_REGION_VP, null);
        return;
      }
      const status: display.FoldStatus = display.getFoldStatus();
      const mode: display.FoldDisplayMode = display.getFoldDisplayMode();
      AppStorage.setOrCreate<number>(BreakpointSystem.KEY_FOLD_STATUS, status);
      AppStorage.setOrCreate<number>(BreakpointSystem.KEY_FOLD_DISPLAY_MODE, mode);

      const density: number = BreakpointSystem.getSafeDensity();
      let region: display.FoldCreaseRegion | null = null;
      try {
        const defDisplay: display.Display = display.getDefaultDisplaySync();
        region = defDisplay.getLiveCreaseRegion();
      } catch {
        try {
          region = display.getCurrentFoldCreaseRegion();
        } catch {
          region = null;
        }
      }

      if (region && region.creaseRects && region.creaseRects.length > 0) {
        const r: display.Rect = region.creaseRects[0];
        const converted = BreakpointSystem.convertCreaseRectToVp(r.left, r.top, r.width, r.height, density);
        AppStorage.setOrCreate<CreaseRegionVp | null>(BreakpointSystem.KEY_CREASE_REGION_VP, converted);
      } else {
        AppStorage.setOrCreate<CreaseRegionVp | null>(BreakpointSystem.KEY_CREASE_REGION_VP, null);
      }
    } catch {
      // 非折叠屏或模拟器忽略
    }
  }

  /** 注册折叠屏折叠态与显示模式监听 */
  public static registerFoldListener(): void {
    try {
      if (display.isFoldable()) {
        BreakpointSystem.refreshFoldMetrics();
        if (BreakpointSystem.foldStatusCallback === null) {
          BreakpointSystem.foldStatusCallback = (status: display.FoldStatus): void => {
            AppStorage.setOrCreate<number>(BreakpointSystem.KEY_FOLD_STATUS, status);
            BreakpointSystem.refreshFoldMetrics();
          };
          display.on('foldStatusChange', BreakpointSystem.foldStatusCallback);
        }
        if (BreakpointSystem.foldDisplayModeCallback === null) {
          BreakpointSystem.foldDisplayModeCallback = (mode: display.FoldDisplayMode): void => {
            AppStorage.setOrCreate<number>(BreakpointSystem.KEY_FOLD_DISPLAY_MODE, mode);
            BreakpointSystem.refreshFoldMetrics();
          };
          display.on('foldDisplayModeChange', BreakpointSystem.foldDisplayModeCallback);
        }
      }
    } catch {
      // 非折叠屏设备忽略
    }
  }

  /** 注销折叠屏监听（在 onWindowStageDestroy 中清理） */
  public static unregisterFoldListener(): void {
    try {
      if (BreakpointSystem.foldStatusCallback !== null) {
        display.off('foldStatusChange', BreakpointSystem.foldStatusCallback);
        BreakpointSystem.foldStatusCallback = null;
      }
      if (BreakpointSystem.foldDisplayModeCallback !== null) {
        display.off('foldDisplayModeChange', BreakpointSystem.foldDisplayModeCallback);
        BreakpointSystem.foldDisplayModeCallback = null;
      }
    } catch {
      BreakpointSystem.foldStatusCallback = null;
      BreakpointSystem.foldDisplayModeCallback = null;
    }
  }
}
