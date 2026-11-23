import { router } from '@kit.ArkUI';

/**
 * SSO 登录页 — 1:1 复刻 activity_mobile_campus_sso.xml
 * 结构：RelativeLayout 全屏封面图 mobile_campus_launch（xhdpi 720x1280 → 360x640vp）
 */
@Entry
@Component
struct SsoLoginPage {
  private enterApp(): void {
    router.pushUrl({ url: 'pages/Index' });
  }

  build() {
    Stack() {
      Image($r('app.media.mobile_campus_launch'))
        .width('100%')
        .height('100%')
        .objectFit(ImageFit.Cover)
        .onClick(() => {
          this.enterApp();
        })
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.white'))
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
  }
}
