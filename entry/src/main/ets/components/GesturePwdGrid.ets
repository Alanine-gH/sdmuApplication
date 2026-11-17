import { GestureGridPair } from '../model/GestureGridPair';

/**
 * 手势密码九宫格 — 1:1 复刻 GesturePwdLayout
 * 3x3 圆点 + 选中连线；大格 336vp（间距 112）、小格 72vp（间距 24）
 * allowInteract=false 时仅展示 displaySeq 图案（小图预览）
 */
@Component
export struct GesturePwdGrid {
  @Prop @Watch('onResetTokenChange') resetToken: number = 0;
  @Prop gridWidth: number = 336;
  @Prop allowInteract: boolean = true;
  @Prop displaySeq: number[] = [];
  onFinish: (seq: number[]) => void = (seq: number[]) => {};
  @State private seq: number[] = [];
  @State private dragging: boolean = false;
  @State private dragX: number = 0;
  @State private dragY: number = 0;

  private onResetTokenChange(): void {
    this.seq = [];
    this.dragging = false;
    this.dragX = 0;
    this.dragY = 0;
  }

  private cellSize(): number {
    return this.gridWidth / 3;
  }

  private centerX(idx: number): number {
    return (idx % 3) * this.cellSize() + this.cellSize() / 2;
  }

  private centerY(idx: number): number {
    return Math.floor(idx / 3) * this.cellSize() + this.cellSize() / 2;
  }

  private dotOuter(): number {
    return this.gridWidth > 100 ? 40 : 16;
  }

  private dotInner(): number {
    return this.gridWidth > 100 ? 12 : 6;
  }

  private lineWidth(): number {
    return this.gridWidth > 100 ? 4 : 2;
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

  private handleTouch(x: number, y: number): void {
    const half: number = this.cellSize() / 2;
    for (let i = 0; i < 9; i++) {
      const dx: number = x - this.centerX(i);
      const dy: number = y - this.centerY(i);
      if (dx * dx + dy * dy <= half * half) {
        if (this.seq.indexOf(i) === -1) {
          const next: number[] = this.seq.slice();
          next.push(i);
          this.seq = next;
        }
        return;
      }
    }
  }

  build() {
    Stack() {
      ForEach(this.pairs(), (pair: GestureGridPair) => {
        Line()
          .startPoint([this.centerX(pair.fromIdx), this.centerY(pair.fromIdx)])
          .endPoint([this.centerX(pair.toIdx), this.centerY(pair.toIdx)])
          .strokeWidth(this.lineWidth())
          .stroke($r('app.color.mobile_campus_primary_color'))
          .width(this.gridWidth)
          .height(this.gridWidth)
      }, (pair: GestureGridPair) => `line_${pair.fromIdx}_${pair.toIdx}`)

      if (this.allowInteract && this.dragging && this.seq.length >= 1) {
        Line()
          .startPoint([this.centerX(this.seq[this.seq.length - 1]), this.centerY(this.seq[this.seq.length - 1])])
          .endPoint([this.dragX, this.dragY])
          .strokeWidth(this.lineWidth())
          .stroke($r('app.color.mobile_campus_primary_color'))
          .width(this.gridWidth)
          .height(this.gridWidth)
      }

      ForEach([0, 1, 2, 3, 4, 5, 6, 7, 8], (i: number) => {
        Stack() {
          if (this.isDotSelected(i)) {
            Stack()
              .width(this.dotInner())
              .height(this.dotInner())
              .borderRadius(this.dotInner() / 2)
              .backgroundColor($r('app.color.white'))
          }
        }
        .width(this.dotOuter())
        .height(this.dotOuter())
        .borderRadius(this.dotOuter() / 2)
        .border({
          width: this.isDotSelected(i) ? 2 : 1,
          color: this.isDotSelected(i) ? $r('app.color.mobile_campus_primary_color') : $r('app.color.common_color_33')
        })
        .backgroundColor(this.isDotSelected(i) ? $r('app.color.mobile_campus_primary_color') : $r('app.color.white'))
        .position({ x: this.centerX(i) - this.dotOuter() / 2, y: this.centerY(i) - this.dotOuter() / 2 })
      }, (i: number) => `dot_${i}`)
    }
    .width(this.gridWidth)
    .height(this.gridWidth)
    .gesture(PanGesture({ fingers: 1 })
      .onActionStart((event: GestureEvent) => {
        if (!this.allowInteract) {
          return;
        }
        const finger: FingerInfo = event.fingerList[0];
        this.handleTouch(finger.localX, finger.localY);
        this.dragging = true;
        this.dragX = finger.localX;
        this.dragY = finger.localY;
      })
      .onActionUpdate((event: GestureEvent) => {
        if (!this.allowInteract) {
          return;
        }
        const finger: FingerInfo = event.fingerList[0];
        this.handleTouch(finger.localX, finger.localY);
        this.dragging = true;
        this.dragX = finger.localX;
        this.dragY = finger.localY;
      })
      .onActionEnd(() => {
        if (!this.allowInteract) {
          return;
        }
        this.dragging = false;
        if (this.seq.length >= 4) {
          this.onFinish(this.seq.slice());
        }
      }))
  }
}

