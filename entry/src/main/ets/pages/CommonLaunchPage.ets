import { common } from '@kit.AbilityKit';
import { router } from '@kit.ArkUI';
import { BusinessError } from '@kit.BasicServicesKit';
import { BreakpointSystem } from '../common/BreakpointSystem';
import { PreferencesUtil } from '../data/PreferencesUtil';

/**
 * 通用启动页 — 1:1 复刻 CommonLaunchActivity（126 行）+ mobile_campus_common_launch.xml
 * [W22 launch-chain] 源码级翻译：
 *   布局：LinearLayout(vertical)：ivBg 全屏 centerCrop（SchoolEntityUtils.a().getCampusLaunch()
 *     = 单校包本地 mipmap mobile_campus_launch）+ tvVersion/tvTimer（XML 恒 gone，无逻辑引用）。
 *   f1()：隐私协议未展示（PrivacyDialogSharePreferencesUtil.e() =
 *     isShowPrivacyDialog_<schoolCode> 缺省 true）→ J2() 弹 PrivacyDialog2：
 *       标题"服务协议及隐私政策说明" + 正文（《服务协议》《隐私政策》ClickableSpan → WebView）
 *       + "退出App"（btn_cancel onCreate 覆盖）| "同意"；
 *       同意 → dismiss + f(true)/g(false)（isAgreePrivacyPolicy=true/isShowPrivacyDialog=false 落盘）
 *         + 1000ms → K2；取消 → dismiss + finish()（栈顶即根 → 应用退出）。
 *     已展示 → 1500ms → K2。
 *   K2()：InitConstant.C = R$string.mobile_campus_unLogin_first_activity_tag = "1"（本构建常量）
 *     → g2(e.a.u=/launch/newlogin)（MobileCampusLoginNewActivity → HAP LoginPage）；
 *     else 死分支 → e.a.f10993a=/launch/main（保真注释）。
 * 入口链：CampusFirstPage（DispatchActivity）→ 本页 → LoginPage。
 */
const PRIVACY_SCHOOL_CODE: string = 'SDGY';
const KEY_IS_AGREE: string = 'isAgreePrivacyPolicy_' + PRIVACY_SCHOOL_CODE;
const KEY_IS_SHOW_DIALOG: string = 'isShowPrivacyDialog_' + PRIVACY_SCHOOL_CODE;

@Entry
@Component
struct CommonLaunchPage {
  /** 源码 cVar：PrivacyDialog2 显示态 */
  @State showPrivacyDialog: boolean = false;
  @StorageProp('currentBreakpoint') currentBreakpoint: string = 'sm';
  @StorageProp('windowWidthVp') windowWidthVp: number = 360;
  @StorageProp('windowHeightVp') windowHeightVp: number = 640;
  @StorageProp('avoidAreaTopVp') avoidAreaTopVp: number = 0;
  @StorageProp('avoidAreaBottomVp') avoidAreaBottomVp: number = 0;
  @StorageProp('avoidAreaLeftVp') avoidAreaLeftVp: number = 0;
  @StorageProp('avoidAreaRightVp') avoidAreaRightVp: number = 0;
  private timerId: number = -1;

  aboutToAppear(): void {
    // 源码 f1()：先加载 ivBg（本地资源直接渲染），再判隐私弹窗
    PreferencesUtil.getBoolean(KEY_IS_SHOW_DIALOG, true)
      .then((show: boolean) => {
        if (show) {
          // 源码 J2()：cVar.show()
          this.showPrivacyDialog = true;
        } else {
          // 源码 new Handler().postDelayed(new a(), 1500L)
          this.timerId = setTimeout(() => {
            this.goK2();
          }, 1500);
        }
      })
      .catch((error: BusinessError) => {
        // 读取失败按未展示过处理（getBoolean 缺省 true 同语义）
        this.showPrivacyDialog = true;
      });
  }

  aboutToDisappear(): void {
    if (this.timerId !== -1) {
      clearTimeout(this.timerId);
      this.timerId = -1;
    }
  }

  /** 源码 K2()：C=="1"（本构建常量）→ /launch/newlogin；else 死分支 → /launch/main */
  private goK2(): void {
    router.replaceUrl({ url: 'pages/LoginPage' });
  }

  /** 源码 b.a()（同意回调）：dismiss + a.f(true)/a.g(false) + umeng/MobSDK + 1000ms → K2 */
  private onAgree(): void {
    this.showPrivacyDialog = false;
    PreferencesUtil.putBoolean(KEY_IS_AGREE, true)
      .then(() => {
        return PreferencesUtil.putBoolean(KEY_IS_SHOW_DIALOG, false);
      })
      .then(() => {
        this.timerId = setTimeout(() => {
          this.goK2();
        }, 1000);
      })
      .catch((error: BusinessError) => {
        // 落盘失败同样继续放行（源码 commit 无失败分支）
        this.timerId = setTimeout(() => {
          this.goK2();
        }, 1000);
      });
  }

  /** 源码 b.b()（退出App回调）：dismiss + finish()（根页 finish → 应用退出） */
  private onQuit(): void {
    this.showPrivacyDialog = false;
    try {
      const ctx: Object = this.getUIContext().getHostContext() as Object;
      (ctx as common.UIAbilityContext).terminateSelf();
    } catch (error) {
      // terminateSelf 失败静默（源码 finish 无失败分支）
    }
  }

  /** 源码 ClickableSpan d/e：module.app.util.a.m(context, "隐私政策"/"服务协议", schoolUrl+policy)
   *  → HAP WebViewPage（LoginPage 底部协议链接同款落点）。 */
  private openPolicy(title: string, url: string): void {
    router.pushUrl({ url: 'pages/WebViewPage', params: { 'title': title, 'url': url } as Record<string, string> });
  }

  build() {
    Stack() {
      // ivBg：SchoolEntityUtils.a().getCampusLaunch()（单校包 = 本地 mipmap，centerCrop）
      Image($r('app.media.mobile_campus_launch'))
        .width('100%')
        .height('100%')
        .objectFit(ImageFit.Cover)
        .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])

      // tvVersion / tvTimer：XML visibility=gone 且源码无引用（保真省略渲染）

      if (this.showPrivacyDialog) {
        // PrivacyDialog2（mobile_campus_privacy_dialog.xml）
        Column() {
          Text('服务协议及隐私政策说明')
            .fontSize(18.5)
            .fontColor($r('app.color.common_color_1'))
            .textAlign(TextAlign.Center)
            .margin({ top: 24 })

          Scroll() {
            Text() {
              Span('\u0009\u0009\u0009\u0009亲爱的用户，感谢您使用本应用！为了更好地保障您的个人权益，请您务必在使用前，认真阅读')
              Span('《服务协议》')
                .fontColor($r('app.color.mobile_campus_primary_color'))
                .onClick(() => {
                  this.openPolicy('服务协议', 'https://www.sdmu.edu.cn/');
                })
              Span('和')
              Span('《隐私政策》')
                .fontColor($r('app.color.mobile_campus_primary_color'))
                .onClick(() => {
                  this.openPolicy('隐私政策', 'https://www.sdmu.edu.cn/');
                })
              Span('的全部内容。如您同意并接受全部条款，请点击“同意”，开始使用我们的产品和服务。')
            }
            .fontSize(14)
            .fontColor($r('app.color.common_color_1'))
            .padding({ left: 16, right: 16 })
          }
          .width('100%')
          .constraintSize({ maxHeight: Math.max(110, BreakpointSystem.getDialogMaxHeight(this.windowHeightVp) - 130) })
          .scrollBar(BarState.Off)
          .margin({ top: 12 })

          Divider()
            .color($r('app.color.common_color_5'))
            .strokeWidth(1)
            .width('100%')
            .margin({ top: 12 })

          Row() {
            Text('退出App')
              .fontSize(16)
              .fontColor($r('app.color.mobile_campus_primary_color'))
              .textAlign(TextAlign.Center)
              .layoutWeight(1)
              .padding({ top: 12, bottom: 12 })
              .maxLines(1)
              .onClick(() => {
                this.onQuit();
              })

            Divider()
              .vertical(true)
              .color($r('app.color.common_color_5'))
              .strokeWidth(1)
              .height(40)

            Text('同意')
              .fontSize(16)
              .fontColor($r('app.color.mobile_campus_primary_color'))
              .textAlign(TextAlign.Center)
              .layoutWeight(1)
              .padding({ top: 12, bottom: 12 })
              .maxLines(1)
              .onClick(() => {
                this.onAgree();
              })
          }
          .width('100%')
          .alignItems(VerticalAlign.Center)
        }
        .width('86%')
        .constraintSize({
          maxWidth: Math.min(340, BreakpointSystem.getDialogMaxWidth(this.currentBreakpoint, this.windowWidthVp)),
          maxHeight: BreakpointSystem.getDialogMaxHeight(this.windowHeightVp)
        })
        .backgroundColor($r('app.color.ybg_white'))
        .borderRadius(6)
        .alignItems(HorizontalAlign.Center)
        .margin({
          top: this.avoidAreaTopVp,
          bottom: this.avoidAreaBottomVp,
          left: this.avoidAreaLeftVp,
          right: this.avoidAreaRightVp
        })
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.black'))
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
  }
}
