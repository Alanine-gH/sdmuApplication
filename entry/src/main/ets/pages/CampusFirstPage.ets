/**
 * 校园首启路由页 — 1:1 复刻 CampusFirstActivity（module.launch.view）
 * 原始 Activity 无布局（J1() 返回 0），为透明跳转页：
 *   读取启动参数后立即转发到主界面并 finish。
 * 内置数据：推送跳转 / 首启选择学校 两种路由去向。
 */
@Entry
@Component
struct CampusFirstPage {
  @State routeTarget: string = '';
  @State hasPushExtra: boolean = false;

  aboutToAppear(): void {
    // 内置路由数据：模拟 jpush_extra / isFirst 分支
    this.hasPushExtra = false;
    if (this.hasPushExtra) {
      this.routeTarget = 'pages/Index';
    } else {
      this.routeTarget = 'pages/ChooseSchoolPage';
    }
  }

  build() {
    Stack() {
      // 原始布局为空 ConstraintLayout，透明背景
    }
    .width('100%')
    .height('100%')
    .backgroundColor(Color.Transparent)
  }
}
