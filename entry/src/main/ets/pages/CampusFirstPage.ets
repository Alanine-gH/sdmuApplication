import { router } from '@kit.ArkUI';
import { BusinessError } from '@kit.BasicServicesKit';
import { LoginSession } from '../network/LoginSession';

/**
 * 校园首启路由页 — 1:1 复刻 CampusFirstActivity（module/launch/view，51 行）
 * [W22 launch-chain] 源码级翻译：J1()=0 无布局透明壳 + f1() 三分支转发：
 *   1) lifemanager.d.b.b()（d.a.c().getSession_key() 非空 = 已登录）→ g2(e.a.r=/launch/logined)
 *      带 {jpush_extra}（HAP 无推送通道 → 空 param，链路终点 LoginedLaunchPage）
 *   2) else if (InitConstant.G && SchoolEntityUtils.f()) → g2(e.a.t=/launch/chosen) 带 {isFirst:true}
 *      —— 本构建 InitConstant.G = R$string.mobile_campus_school_resources_switch = "false"
 *      且单校包 SchoolEntityUtils.f() 恒 false → 死分支，保真注释保留
 *   3) else → g2(e.a.s=/launch/common)（CommonLaunchActivity → HAP CommonLaunchPage）
 * 入口链（APK AndroidManifest）：LAUNCHER = DispatchActivity（签名校验 + SchoolEntity 初始化 +
 * 清 homeMessageDatas/unifyTodoUnreadDatas）→ F2() = X1(ConfigurationInfo.f12720b=CampusFirstActivity)。
 * HAP 等价：EntryAbility.loadContent → 本页（Dispatch 初始化逻辑由 PreferencesUtil.init +
 * LoginSession.restoreSession 承载），分支判定后立即 replaceUrl 并销毁自身（源码 finish()）。
 */
@Entry
@Component
struct CampusFirstPage {
  aboutToAppear(): void {
    // 源码 f1()：this.g=false; this.k=false; 后按 b.b() 分流
    LoginSession.restoreSession()
      .then(() => {
        if (LoginSession.sessionKey !== '') {
          // 分支1：已登录 → /launch/logined（jpush_extra 本端无推送 → 空）
          router.replaceUrl({ url: 'pages/LoginedLaunchPage', params: { 'jpushExtra': '' } });
        } else {
          // 分支2（G=false 死分支，保真注释）：InitConstant.G && SchoolEntityUtils.f()
          //   → /launch/chosen {isFirst:true}（ChooseSchoolActivity，本构建不可达）
          // 分支3：未登录 → /launch/common
          router.replaceUrl({ url: 'pages/CommonLaunchPage' });
        }
      })
      .catch((error: BusinessError) => {
        // restoreSession 异常按未登录处理（等价 b.b()==false）
        LoginSession.log('CampusFirst restore fail: ' + error.message);
        router.replaceUrl({ url: 'pages/CommonLaunchPage' });
      });
  }

  build() {
    // J1()=0：无 setContentView，透明空壳页（跳转即 finish）
    Stack()
      .width('100%')
      .height('100%')
      .backgroundColor(Color.Transparent)
  }
}
