/**
 * 手势连线段数据
 */
export class GestureGridPair {
  fromIdx: number;
  toIdx: number;

  constructor(fromIdx: number, toIdx: number) {
    this.fromIdx = fromIdx;
    this.toIdx = toIdx;
  }
}
