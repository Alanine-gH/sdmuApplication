import { GestureGridPair } from '../model/GestureGridPair';

/**
 * 手势密码九宫格 — 1:1 复刻 GesturePwdLayout + GesturePwdCircleView（lyyd/base/widget）
 * [W22 launch-chain] 按源码升级：
 *   - 圆点 = 单实心圆（无外环）：未选 #F3F6FD 半径 gw/18；选中 #1B68B7 半径 (gw/47*8)/2；
 *     错误 #EB5757（colorCheckedErr，文字白 colorUnCheckedErrText）
 *   - 大格（allowInteract=true）圆内显示数字 1..9（isShowText=ifAllowInteract，textSize 80px=40fp 加粗）；
 *     count=4（CDJS）时文字为 1,2,3,技,4,5,6,师,7,8,9,学,工,贸,职,院
 *   - 内边距 pad = (gw/47)*3/2（interact）| (gw/9)/2（非 interact），取整除
 *   - 命中区 = 圆点矩形四周收缩 marginRate 0.2（ifClickOnView）
 *   - 按下即清空上一笔画（ACTION_DOWN lockPath.reset+resetPwd）；连线宽 3px=1.5vp
 *   - 错误态：check 失败后圆点/连线转红（ifCheckOnErr），下次按下恢复
 *   - 抬起必回 onSwipeFinish（源码 e() 先于长度校验），seq≥4 才回 onFinish
 *   - 未达 minLength(4) 不触发模式回调（页面按长度给"请最少连接4个点"）
 */
@Component
export struct GesturePwdGrid {
  @Prop @Watch('onResetTokenChange') resetToken: number = 0;
  /** 错误标记：来源页校验失败后 bump —— 圆点/连线转红，直到下次按下 */
  @Prop @Watch('onErrorTokenChange') errorToken: number = 0;
  @Prop gridWidth: number = 336;
  @Prop allowInteract: boolean = true;
  /** 九宫格阶数（源码 mCount：3=3x3 九点，4=4x4 十六点 CDJS） */
  @Prop count: number = 3;
  /** 非交互模式展示的图案（小九宫格预览 refreshPwdKeyboard） */
  @Prop displaySeq: number[] = [];
  /** 笔画结束（源码 onSwipeFinish → e() 回调，每笔必回） */
  onSwipeFinish: (seq: number[]) => void = (seq: number[]) => {};
  /** 达到最小长度后的模式回调（reset/check 判定交页面） */
  onFinish: (seq: number[]) => void = (seq: number[]) => {};
  @State private seq: number[] = [];
  @State private renderError: boolean = false;
  @State private dragging: boolean = false;
  @State private dragX: number = 0;
  @State private dragY: number = 0;

  /** 源码 textStrs（mCount==4 时 16 点文字；3x3 时 (idx+1)） */
  private static readonly COUNT4_TEXTS: string[] =
    ['1', '2', '3', '技', '4', '5', '6', '师', '7', '8', '9', '学', '工', '贸', '职', '院'];

  private onResetTokenChange(): void {
    this.seq = [];
    this.renderError = false;
    this.dragging = false;
    this.dragX = 0;
    this.dragY = 0;
  }

  private onErrorTokenChange(): void {
    // 源码 onCheck 错误分支：currentPaint=paint_error + 圆点 switchStatus(3)，保持到下次按下
    this.renderError = true;
  }

  /** 源码 onMeasure pad 公式（整数除法 1:1） */
  private pad(): number {
    const gw: number = Math.floor(this.gridWidth);
    return this.allowInteract ? Math.floor(Math.floor(gw / 47) * 3 / 2) : Math.floor(Math.floor(gw / 9) / 2);
  }

  private cellSize(): number {
    return (this.gridWidth - this.pad() * 2) / this.count;
  }

  private centerX(idx: number): number {
    return this.pad() + (idx % this.count) * this.cellSize() + this.cellSize() / 2;
  }

  private centerY(idx: number): number {
    return this.pad() + Math.floor(idx / this.count) * this.cellSize() + this.cellSize() / 2;
  }

  /** 源码 getCircleView 半径公式：interact (h/47*8)/2；非 interact h/9/2 */
  private dotRadius(): number {
    const gw: number = Math.floor(this.gridWidth);
    return this.allowInteract ? Math.floor(Math.floor(gw / 47) * 8 / 2) : Math.floor(Math.floor(gw / 9) / 2);
  }

  private lineWidth(): number {
    // 源码 paint.setStrokeWidth(y.a(3.0f)) = 3px = 1.5vp
    return 1.5;
  }

  private dotFontSize(): number {
    const scale: number = this.count === 4 ? 1.05 : 1.2;
    return Math.min(40, Math.max(11, Math.round(this.dotRadius() * scale)));
  }

  private dotText(idx: number): string {
    if (this.count === 4) {
      return GesturePwdGrid.COUNT4_TEXTS[idx];
    }
    return String(idx + 1);
  }

  private renderSeq(): number[] {
    return this.allowInteract ? this.seq : this.displaySeq;
  }

  private pairs(): GestureGridPair[] {
    const s: number[] = this.renderSeq();
    const arr: GestureGridPair[] = [];
    for (let i = 0; i + 1 < s.length; i++) {
      arr.push(new GestureGridPair(s[i], s[i + 1]));
    }
    return arr;
  }

  private isDotSelected(idx: number): boolean {
    return this.renderSeq().indexOf(idx) !== -1;
  }

  /** 源码 ifClickOnView：圆点矩形四周收缩 20% 后 contains 点 */
  private hitIndex(x: number, y: number): number {
    const shrink: number = this.cellSize() * 0.2;
    for (let i = 0; i < this.count * this.count; i++) {
      const left: number = this.centerX(i) - this.cellSize() / 2 + shrink;
      const top: number = this.centerY(i) - this.cellSize() / 2 + shrink;
      const right: number = this.centerX(i) + this.cellSize() / 2 - shrink;
      const bottom: number = this.centerY(i) + this.cellSize() / 2 - shrink;
      if (x >= left && x <= right && y >= top && y <= bottom) {
        return i;
      }
    }
    return -1;
  }

  private addPwd(idx: number): void {
    // 源码 addPwd：checkRepetition 去重
    if (idx >= 0 && this.seq.indexOf(idx) === -1) {
      const next: number[] = this.seq.slice();
      next.push(idx);
      this.seq = next;
    }
  }

  private handleMove(x: number, y: number): void {
    const idx: number = this.hitIndex(x, y);
    if (idx >= 0 && this.seq.length > 0 && this.seq[this.seq.length - 1] !== idx) {
      this.addPwd(idx);
    }
    this.dragX = x;
    this.dragY = y;
  }

  build() {
    Stack() {
      // 连线（源码 dispatchDraw：仅 ifAllowInteract 时画 lockPath）
      ForEach(this.pairs(), (pair: GestureGridPair) => {
        Line()
          .startPoint([this.centerX(pair.fromIdx), this.centerY(pair.fromIdx)])
          .endPoint([this.centerX(pair.toIdx), this.centerY(pair.toIdx)])
          .strokeWidth(this.lineWidth())
          .stroke(this.renderError ? '#EB5757' : '#1B68B7')
          .width(this.gridWidth)
          .height(this.gridWidth)
      }, (pair: GestureGridPair) => `line_${pair.fromIdx}_${pair.toIdx}`)

      // 拖动引导线（drawMovingPath）
      if (this.allowInteract && this.dragging && this.seq.length >= 1) {
        Line()
          .startPoint([this.centerX(this.seq[this.seq.length - 1]), this.centerY(this.seq[this.seq.length - 1])])
          .endPoint([this.dragX, this.dragY])
          .strokeWidth(this.lineWidth())
          .stroke(this.renderError ? '#EB5757' : '#1B68B7')
          .width(this.gridWidth)
          .height(this.gridWidth)
      }

      // 圆点（GesturePwdCircleView：实心圆；interact 格所有点显示数字，
      // 文字色随状态：未选 #B9C0D0 / 选中·错误 #FFFFFF，textSize 80px=40fp 加粗）
      ForEach(Array.from({ length: this.count * this.count }, (v: Object, i: number) => i), (i: number) => {
        Stack() {
          Text(this.dotText(i))
            .fontSize(this.dotFontSize())
            .fontWeight(FontWeight.Bold)
            .fontColor(this.isDotSelected(i) ? '#FFFFFF' : '#B9C0D0')
            .visibility(this.allowInteract ? Visibility.Visible : Visibility.None)
        }
        .width(this.dotRadius() * 2)
        .height(this.dotRadius() * 2)
        .borderRadius(this.dotRadius())
        .backgroundColor(this.isDotSelected(i) ?
          (this.renderError ? '#EB5757' : '#1B68B7') : '#F3F6FD')
        .position({ x: this.centerX(i) - this.dotRadius(), y: this.centerY(i) - this.dotRadius() })
      }, (i: number) => `dot_${i}`)
    }
    .width(this.gridWidth)
    .height(this.gridWidth)
    .gesture(PanGesture({ fingers: 1 })
      .onActionStart((event: GestureEvent) => {
        if (!this.allowInteract) {
          return;
        }
        // 源码 ACTION_DOWN：lockPath.reset + resetPwd（新一笔从零开始）+ ifCheckOnErr 复位
        const finger: FingerInfo = event.fingerList[0];
        this.seq = [];
        this.renderError = false;
        this.dragging = true;
        this.dragX = finger.localX;
        this.dragY = finger.localY;
        this.addPwd(this.hitIndex(finger.localX, finger.localY));
      })
      .onActionUpdate((event: GestureEvent) => {
        if (!this.allowInteract) {
          return;
        }
        const finger: FingerInfo = event.fingerList[0];
        this.handleMove(finger.localX, finger.localY);
      })
      .onActionEnd(() => {
        if (!this.allowInteract) {
          return;
        }
        // 源码 ACTION_UP：resetAllCircleBtn + onSwipeFinish（e 回调）→ 长度校验 → 模式回调
        this.dragging = false;
        this.onSwipeFinish(this.seq.slice());
        if (this.seq.length >= 4) {
          this.onFinish(this.seq.slice());
        }
      }))
  }
}
