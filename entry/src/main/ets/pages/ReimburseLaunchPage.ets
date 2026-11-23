import { router } from '@kit.ArkUI';

/**
 * 报销模块启动跳转页 — 1:1 复刻 ReimburseLaunchActivity（lyyd/reimburse/view，33 行）
 * [W22 launch-chain] 源码级翻译：J1()=0 无布局透明壳，f1() 唯一动作：
 *   g2(e.a.T0 = R$string.mobile_campus_reimburse_main = "/reimburse/main" → ProgramListActivity)
 *   随即 finish()。
 * HAP 等价：replaceUrl pages/ProgramListPage（/reimburse/main 既有翻译页）。
 * 同包 ReimburseLaunchActivityV2（33 行同构）→ e.a.X0 = "/new_reimburse/main" →
 * ProgramListActivityV2（HAP 暂无 V2 主列表翻译页，映射表仅登记本 Activity）。
 * 入口链：全源码（含 dex2/3 smali）无显式调用方 —— 兄弟端/外部显式 Intent 入口，应用内无导航；
 * 本页为源码壳页忠实翻译。
 */
@Entry
@Component
struct ReimburseLaunchPage {
  aboutToAppear(): void {
    // 源码 f1()：g2(a.T0, null) + finish()
    router.replaceUrl({ url: 'pages/ProgramListPage' });
  }

  build() {
    // J1()=0：无 setContentView，透明空壳页
    Stack()
      .width('100%')
      .height('100%')
      .backgroundColor(Color.Transparent)
      .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
  }
}
