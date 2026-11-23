/**
 * 共享主题与着色常量（消除 Index 与 MineTab 等多处重复定义）
 */
export class ThemeConstants {
  /** 主题红着色矩阵 (#97000C) */
  public static readonly TINT_RED: number[] =
    [0, 0, 0, 0, 0.59, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0.05, 0, 0, 0, 1, 0];
  /** 未选中灰着色矩阵 (#7D7D7D) */
  public static readonly TINT_GREY: number[] =
    [0, 0, 0, 0, 0.49, 0, 0, 0, 0, 0.49, 0, 0, 0, 0, 0.49, 0, 0, 0, 1, 0];
}
