import { display } from '@kit.ArkUI';

export type BreakpointType = 'sm' | 'md' | 'lg';

/**
 * 多形态设备响应式断点系统：
 * - sm (<600vp): 直板手机竖屏
 * - md (600vp~839vp): 阔直板 (Pura X Max)、折叠屏展开态、小尺寸平板竖屏
 * - lg (>=840vp): 平板横屏、三折叠屏展开态
 */
export class BreakpointSystem {
  public static readonly KEY_BREAKPOINT: string = 'currentBreakpoint';
  public static readonly KEY_IS_WIDE: string = 'isWideScreen';
  public static readonly KEY_IS_LANDSCAPE: string = 'isLandscape';
  public static readonly KEY_WINDOW_WIDTH_VP: string = 'windowWidthVp';
  public static readonly KEY_FOLD_STATUS: string = 'foldStatus';

  public static readonly BP_SM_MAX: number = 600;
  public static readonly BP_MD_MAX: number = 840;

  /** 纯函数：根据 vp 宽度计算断点 */
  public static computeBreakpoint(widthVp: number): BreakpointType {
    if (widthVp >= BreakpointSystem.BP_MD_MAX) {
      return 'lg';
    }
    if (widthVp >= BreakpointSystem.BP_SM_MAX) {
      return 'md';
    }
    return 'sm';
  }

  /** 纯函数：根据断点返回内容区最大宽度 */
  public static getContentMaxWidth(bp: string): number | string {
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
    if (bp === 'lg') {
      return 8;
    }
    if (bp === 'md') {
      return 6;
    }
    return 4;
  }

  /** 纯函数：根据断点返回卡片列表列数 */
  public static getListColumns(bp: string): number {
    if (bp === 'lg') {
      return 2;
    }
    return 1;
  }

  /** 更新 AppStorage 中的窗口断点与横竖屏状态 */
  public static updateFromPx(widthPx: number, heightPx: number): void {
    let density: number = 1;
    try {
      density = display.getDefaultDisplaySync().densityPixels;
    } catch {
      density = 1;
    }
    const safeDensity: number = density > 0 ? density : 1;
    const widthVp: number = widthPx / safeDensity;
    const heightVp: number = heightPx / safeDensity;
    const bp: BreakpointType = BreakpointSystem.computeBreakpoint(widthVp);
    AppStorage.setOrCreate<string>(BreakpointSystem.KEY_BREAKPOINT, bp);
    AppStorage.setOrCreate<boolean>(BreakpointSystem.KEY_IS_WIDE, bp !== 'sm');
    AppStorage.setOrCreate<boolean>(BreakpointSystem.KEY_IS_LANDSCAPE, widthVp > heightVp);
    AppStorage.setOrCreate<number>(BreakpointSystem.KEY_WINDOW_WIDTH_VP, widthVp);
  }

  /** 注册折叠屏折叠态监听 */
  public static registerFoldListener(): void {
    try {
      if (display.isFoldable()) {
        AppStorage.setOrCreate<number>(BreakpointSystem.KEY_FOLD_STATUS, display.getFoldStatus());
        display.on('foldStatusChange', (status: display.FoldStatus) => {
          AppStorage.setOrCreate<number>(BreakpointSystem.KEY_FOLD_STATUS, status);
        });
      }
    } catch {
      // 非折叠屏设备忽略
    }
  }
}
