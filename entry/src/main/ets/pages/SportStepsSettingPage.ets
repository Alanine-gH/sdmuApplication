import { TitleBar } from '../components/TitleBar';
import { BreakpointSystem } from '../common/BreakpointSystem';

/**
 * 运动步数设置页 — 源码级翻译（SportStepsSettingActivity.java 逐行 → ArkTS，[W25 misc-b]）：
 *
 * 【布局】mobile_campus_activity_app_sport_steps_setting.xml：MToolBar("设置") + 提示行
 *   "打开后将在榜单中显示您的对应名称" 12fp explainColor(#999999) padH15 padT16 + 4 个单选行
 *   （pad15：label 16fp black pl15 + "当前显示" 14fp #3A7DF0(invisible/visible) pr8 + 图标 16dip）：
 *   姓名 全称 / 姓氏 + 老师 / 姓氏 + ** / ******
 * 【交互】J2(i)：单选切换（sport_steps_setting_btn_select/un_select 图标 + 对应 tvDesc invisible↔visible
 *   visibility 0/4=invisible）；f1 无持久化读取、J2 无持久化写入 → 源码每次进入重置为选项 1（保真）
 * 【无网络请求】纯本地 UI 页
 */
@Entry
@Component
struct SportStepsSettingPage {
  /** 源码 J2 选中态（初始未调用 → XML 首项 select 图标 + tvDesc1 invisible，其余 un_select） */
  @State selected: number = 0;
  @StorageProp('currentBreakpoint') currentBreakpoint: string = 'sm';
  @StorageProp('avoidAreaBottomVp') avoidAreaBottomVp: number = 0;
  @StorageProp('avoidAreaLeftVp') avoidAreaLeftVp: number = 0;
  @StorageProp('avoidAreaRightVp') avoidAreaRightVp: number = 0;
  private readonly labels: string[] = ['姓名全称', '姓氏 + 老师', '姓氏 + **', '******'];

  /** 源码 J2(i)：i 1..4 → 选中项 */
  private select(idx: number): void {
    this.selected = idx;
  }

  build() {
    Column() {
      TitleBar({ title: '设置', showBack: true })

      Scroll() {
        Column() {
          Text('打开后将在榜单中显示您的对应名称')
            .fontSize(12)
            .fontColor('#999999')
            .padding({ left: 15, right: 15, top: 16 })
            .maxLines(1)
            .width('100%')

          ForEach(this.labels, (label: string, idx: number) => {
            Row() {
              Text(label)
                .fontSize(16)
                .fontColor($r('app.color.black'))
                .padding({ left: 15 })
                .layoutWeight(1)
                .maxLines(1)
              Text('当前显示')
                .fontSize(14)
                .fontColor('#3A7DF0')
                .padding({ right: 8 })
                .visibility(this.selected === idx ? Visibility.Visible : Visibility.Hidden)
              Image(this.selected === idx ? $r('app.media.sport_steps_setting_btn_select')
                : $r('app.media.sport_steps_setting_btn_un_select'))
                .width(16)
                .height(16)
            }
            .width('100%')
            .padding(15)
            .alignItems(VerticalAlign.Center)
            .onClick(() => {
              this.select(idx);
            })
          }, (label: string) => label)
        }
        .width('100%')
        .constraintSize({ maxWidth: BreakpointSystem.getContentMaxWidth(this.currentBreakpoint) })
        .alignSelf(ItemAlign.Center)
        .padding({
          left: this.avoidAreaLeftVp,
          right: this.avoidAreaRightVp,
          bottom: this.avoidAreaBottomVp
        })
      }
      .width('100%')
      .layoutWeight(1)
      .scrollBar(BarState.Off)
      .align(Alignment.Top)
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.white'))
  }
}
