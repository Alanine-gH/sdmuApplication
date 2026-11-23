import { router } from '@kit.ArkUI';
import { BusinessError } from '@kit.BasicServicesKit';
import { ApiService } from '../network/ApiService';
import { ApiResponse } from '../model/ResponseModel';
import { SuperviseDepartment } from '../model/SuperviseModel';
import { BreakpointSystem } from '../common/BreakpointSystem';
import { AdaptiveLayoutHelper } from '../common/AdaptiveLayoutHelper';

/**
 * 督导筛选页 — 源码级翻译 [W21 supervise]（SuperviseFilterActivity.java 逐行 → ArkTS）：
 *
 * 【布局】mobile_campus_supervise_activity_supervise_filter.xml：#f2f2f2 竖排 + 底部提交钮
 *   toolbar：标题"搜索"（T1: gVar.n("搜索")）
 *   卡1（白底 mt12）：行 pad12 "选择学院" 16sp + tvSchool（flex ml12，hint"请选择"#B4BDC8，
 *     drawableRight=mobile_campus_supervise_arrow；点击 → 学院滚轮弹窗）；"选择专业"行源码
 *     visibility=gone（tvMajor 无交互逻辑）→ 按 XML 保真省略
 *   卡2（白底 mt12）：行 pad12 "选择节次"；GridView numColumns=5 × mobile_campus_supervise_view_filter
 *     （CheckBox 无原生按钮框 button=@null，高 48dip，文字 16sp selector_text：选中白/未选 #B2BDC9，
 *     背景 selector_filter：选中 #1B68B7 / 未选透明）；节次数组 arrays.xml course_section =
 *     全天,1..13 共 14 项
 *   superviseSubmit（alignParentBottom）："提交" 17sp padV10，selector_filter_btn（enabled #1B68B7 /
 *     disabled 透明）+ selector_filter 色（enabled 白 / disabled #999999），XML enabled=false 初始禁用
 *
 * 【交互】b.onClick(tvSchool) → SuperviseFilterDialog（WheelView visibleItems=7 白底，tvChoose 空，
 *   tvFinish"完成"）；Q2 → SuperviseModel.Y0 GET getDepartmentList（19 学院 2026-11-18 实测）
 *   → dialog.s(list)。e.a(勾选回调)：djj=getSelected() 下标串 "," 连接；勾选数 0 或学院空 → 禁用。
 *   d.a(选院回调)：tvSchool=BMMC；勾选数>0 才启用。a.onClick(勾选)：i=0（全天）→ 清其余；
 *   i>0 → 清"全天"位（refreshState/booleans[0]=false，其余节次可多选）。
 *   f.onClick(提交)：setResult bjData=DepartmentList{BMDM,BMMC} + djj → finish。
 */

const SECTIONS: string[] = ['全天', '1', '2', '3', '4', '5', '6', '7', '8', '9', '10', '11', '12', '13'];

@Entry
@Component
struct SuperviseFilterPage {
  /** 源码 s：选中学院（提交 bjData） */
  private school: SuperviseDepartment | null = null;
  @State schoolName: string = '';
  /** 源码 p.booleans：节次勾选状态（14 项） */
  @State checks: boolean[] = [false, false, false, false, false, false, false,
    false, false, false, false, false, false, false];
  /** 源码 t：getSelected() 下标串 "," 连接 */
  @State djj: string = '';
  /** 源码 n.setEnabled：勾选数>0 且学院非空 */
  @State submitEnabled: boolean = false;
  /** 学院清单（Q2 → getDepartmentList；2026-11-18 实测 19 项） */
  @State departments: SuperviseDepartment[] = [];
  /** 学院滚轮弹窗（SuperviseFilterDialog 等价 bindSheet） */
  @State wheelVisible: boolean = false;
  @State pickerIndex: number = 0;
  @StorageProp('currentBreakpoint') currentBreakpoint: string = 'sm';
  @StorageProp('isCompactHeight') isCompactHeight: boolean = false;
  @StorageProp('windowHeightVp') windowHeightVp: number = 640;
  @StorageProp('avoidAreaBottomVp') avoidAreaBottomVp: number = 0;
  @StorageProp('avoidAreaLeftVp') avoidAreaLeftVp: number = 0;
  @StorageProp('avoidAreaRightVp') avoidAreaRightVp: number = 0;
  @StorageProp('keyboardHeightVp') keyboardHeightVp: number = 0;

  aboutToAppear(): void {
    this.loadDepartments();
  }

  /** 源码 Q2：r.s(...).n() → GET getDepartmentList → dialog.s(arrayList) */
  private loadDepartments(): void {
    ApiService.getSuperviseDepartments()
      .then((response: ApiResponse<SuperviseDepartment[]>) => {
        if (response.code !== 0) {
          ApiService.logError('SuperviseFilterPage departments degrade: code=' + response.code +
            ' msg=' + response.message);
        }
        this.departments = response.data;
      })
      .catch((error: BusinessError) => {
        ApiService.logError('SuperviseFilterPage departments fail: ' + error.message);
        this.departments = [];
      });
  }

  /** 源码 SuperviseFilterAdapter.refreshState + a.onClick：i=0 清全部后置 i；i>0 清"全天"位 */
  private onSectionCheck(index: number, checked: boolean): void {
    const next: boolean[] = this.checks.slice();
    if (index === 0) {
      for (let i = 0; i < next.length; i++) {
        next[i] = false;
      }
      next[0] = checked;
    } else {
      next[0] = false;
      next[index] = checked;
    }
    this.checks = next;
    this.afterCheckChanged();
  }

  /** 源码 e.a：djj=选中下标串；勾选数 0 或学院空 → 禁用提交 */
  private afterCheckChanged(): void {
    const selected: string[] = [];
    for (let i = 0; i < this.checks.length; i++) {
      if (this.checks[i]) {
        selected.push(String(i));
      }
    }
    this.djj = selected.join(',');
    this.submitEnabled = selected.length > 0 && this.schoolName.trim() !== '';
  }

  /** 源码 d.a：tvSchool=BMMC；勾选数>0 → 启用 */
  private onDepartmentPicked(): void {
    if (this.departments.length === 0) {
      return;
    }
    const idx: number = this.pickerIndex < this.departments.length ? this.pickerIndex : 0;
    this.school = this.departments[idx];
    this.schoolName = this.departments[idx].BMMC;
    this.submitEnabled = this.djj !== '';
    this.wheelVisible = false;
  }

  /** 源码 f.onClick：setResult bjData + djj → finish（AppStorage 管道回传 SupervisePage） */
  private submitFilter(): void {
    if (!this.submitEnabled || this.school === null) {
      return;
    }
    const payload: Record<string, string> = {
      'BMDM': this.school.BMDM,
      'BMMC': this.school.BMMC,
      'djj': this.djj
    };
    AppStorage.setOrCreate<string>('supervise_filter_result', JSON.stringify(payload));
    router.back();
  }

  build() {
    Column() {
      Column() {
        Row() {
          Text('＜')
            .fontSize(16)
            .fontColor($r('app.color.common_color_1'))
            .width(40)
            .height('100%')
            .textAlign(TextAlign.Center)
            .margin({ left: 15 })
            .onClick(() => {
              router.back();
            })
          Text('搜索')
            .fontSize(17)
            .fontColor($r('app.color.ybg_blue'))
            .layoutWeight(1)
            .textAlign(TextAlign.Center)
            .maxLines(1)
          Blank()
            .width(55)
        }
        .width('100%')
        .height(44)
        .padding({ left: this.avoidAreaLeftVp, right: this.avoidAreaRightVp })
        .constraintSize({ maxWidth: BreakpointSystem.getContentMaxWidth(this.currentBreakpoint) })
        .alignSelf(ItemAlign.Center)
        .alignItems(VerticalAlign.Center)

        Divider()
          .color($r('app.color.common_color_5'))
          .strokeWidth(0.5)
          .width('100%')
      }
      .width('100%')
      .backgroundColor($r('app.color.main_bg'))
      .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP])

      Scroll() {
        Column() {
          Blank()
            .height(12)

          // 卡1：选择学院（"选择专业"行源码 gone，按 XML 保真省略）
          Column() {
            Row() {
              Text('选择学院')
                .fontSize(16)
                .fontColor($r('app.color.common_color_1'))
              Row() {
                Text(this.schoolName === '' ? '请选择' : this.schoolName)
                  .fontSize(16)
                  .fontColor(this.schoolName === '' ? '#B4BDC8' : $r('app.color.common_color_1'))
                  .layoutWeight(1)
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
                Image($r('app.media.mobile_campus_supervise_arrow'))
                  .width(14)
                  .height(14)
                  .margin({ left: 6 })
              }
            .layoutWeight(1)
            .margin({ left: 12 })
            .alignItems(VerticalAlign.Center)
            .hoverEffect(HoverEffect.Highlight)
            .onClick(() => {
              // 源码 b.onClick：SuperviseFilterDialog.show()
              this.pickerIndex = 0;
              this.wheelVisible = true;
            })
          }
          .width('100%')
          .padding(12)
          .alignItems(VerticalAlign.Center)
        }
        .width('100%')
        .backgroundColor($r('app.color.white'))

        Blank()
          .height(12)

        // 卡2：选择节次 GridView（响应式列 × 14 项 checkbox）
        Column() {
          Row() {
            Text('选择节次')
              .fontSize(16)
              .fontColor($r('app.color.common_color_1'))
          }
          .width('100%')
          .padding(12)

          Grid() {
            ForEach(SECTIONS, (label: string, index: number) => {
              GridItem() {
                Text(label)
                  .fontSize(16)
                  .fontColor(this.checks[index] ? Color.White : '#B2BDC9')
                  .textAlign(TextAlign.Center)
                  .width('100%')
                  .height(48)
                  .backgroundColor(this.checks[index] ? '#1B68B7' : Color.Transparent)
                  .hoverEffect(HoverEffect.Highlight)
                  .onClick(() => {
                    this.onSectionCheck(index, !this.checks[index]);
                  })
              }
            }, (label: string) => label)
          }
          .columnsTemplate(AdaptiveLayoutHelper.buildColumnsTemplate(
            BreakpointSystem.getGridColumns(this.currentBreakpoint, 5)
          ))
          .width('100%')
          .padding({ left: 12, right: 12, bottom: 12 })
          .height(AdaptiveLayoutHelper.computeGridHeightVp(
            SECTIONS.length,
            BreakpointSystem.getGridColumns(this.currentBreakpoint, 5),
            48,
            0,
            12
          ))
        }
        .width('100%')
        .backgroundColor($r('app.color.white'))
      }
      .width('100%')
      .constraintSize({ maxWidth: BreakpointSystem.getContentMaxWidth(this.currentBreakpoint) })
      .alignSelf(ItemAlign.Center)
      .padding({
        left: this.avoidAreaLeftVp,
        right: this.avoidAreaRightVp,
        bottom: this.keyboardHeightVp
      })
    }
    .width('100%')
    .layoutWeight(1)
    .scrollBar(BarState.Off)
    .align(Alignment.Top)

    // superviseSubmit：selector_filter_btn 双态（enabled #1B68B7 / disabled 透明）+ 字色白/#999999
    Text('提交')
      .fontSize(17)
      .fontColor(this.submitEnabled ? Color.White : '#999999')
      .textAlign(TextAlign.Center)
      .width('100%')
      .constraintSize({ maxWidth: BreakpointSystem.getContentMaxWidth(this.currentBreakpoint) })
      .alignSelf(ItemAlign.Center)
      .padding({
        top: 10,
        bottom: 10 + this.avoidAreaBottomVp,
        left: this.avoidAreaLeftVp,
        right: this.avoidAreaRightVp
      })
      .backgroundColor(this.submitEnabled ? '#1B68B7' : Color.Transparent)
      .hoverEffect(HoverEffect.Highlight)
      .onClick(() => {
        this.submitFilter();
      })
  }
  .width('100%')
  .height('100%')
  .backgroundColor('#F2F2F2')
  .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.BOTTOM])
  .bindSheet($$this.wheelVisible, this.departmentWheelBuilder(), {
    height: Math.min(280, BreakpointSystem.getDialogMaxHeight(this.windowHeightVp)),
    preferType: AdaptiveLayoutHelper.getSheetPreferType(this.currentBreakpoint, this.isCompactHeight),
    dragBar: false,
    showClose: false,
    backgroundColor: $r('app.color.ybg_white')
  } as SheetOptions)
}

/** SuperviseFilterDialog（mobile_campus_supervise_dialog.xml）：tvChoose 空 + tvFinish"完成" + WheelView */
@Builder
departmentWheelBuilder() {
  Scroll() {
    Column() {
      Row() {
        Blank()
        Text('完成')
          .fontSize(15)
          .fontColor($r('app.color.common_color_1'))
          .padding({ left: 10, right: 10, top: 10, bottom: 10 })
          .hoverEffect(HoverEffect.Highlight)
          .onClick(() => {
            this.onDepartmentPicked();
          })
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)

      if (this.departments.length === 0) {
        // 源码 wheel 空数据形态（getDepartmentList 失败/空 → 空滚轮区）
        Text('暂无学院数据')
          .fontSize(15)
          .fontColor($r('app.color.common_color_3'))
          .height(200)
          .width('100%')
          .textAlign(TextAlign.Center)
      } else {
        TextPicker({ range: this.departmentNames(), selected: this.pickerIndex })
          .width('100%')
          .height(220)
          .canLoop(false)
          .backgroundColor($r('app.color.ybg_white'))
          .onChange((value: string | string[], index: number | number[]) => {
            const idx: number = typeof index === 'number' ? index : 0;
            this.pickerIndex = idx;
          })
      }
    }
    .width('100%')
  }
  .width('100%')
  .height('100%')
}

  /** WheelView adapter e(i)=BMMC（弹窗空清单 → 空滚轮，服务器失败保真） */
  private departmentNames(): string[] {
    const names: string[] = [];
    for (const dept of this.departments) {
      names.push(dept.BMMC);
    }
    return names;
  }
}
