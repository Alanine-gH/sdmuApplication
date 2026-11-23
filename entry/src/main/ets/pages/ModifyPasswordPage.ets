import { router } from '@kit.ArkUI';
import { common } from '@kit.AbilityKit';
import { TitleBar } from '../components/TitleBar';
import { ApiService } from '../network/ApiService';
import { LoginSession } from '../network/LoginSession';
import { PreferencesUtil } from '../data/PreferencesUtil';
import { PrivacyWindowHelper } from '../common/PrivacyWindowHelper';
import { BreakpointSystem } from '../common/BreakpointSystem';
import { AdaptiveLayoutHelper } from '../common/AdaptiveLayoutHelper';

/**
 * 修改密码页 — 1:1 复刻 ModifyPwdActivity.java + mobile_campus_activity_modify_pwd.xml
 * 结构：LinearLayout(#F2F2F2) + toolbar_normal（T1 标题"密码修改"）
 *   白卡1（marginTop 16、paddingL 12、行间 divider）：
 *     行1 高48："账号：" + tvName（16fp colorPrimary=#97000C；f1() = 登录用户名）
 *     行2 高48：tvOriginalPwd 原密码输入（16fp common_color_3、hint"请输入原密码"、
 *       textPassword、marginR 12；f1() g0.j 请求焦点）
 *   白卡2（marginTop 12）：tvNewPwd/tvConfirmPwd 高48、maxLength 12、
 *     hint "请输入新密（6-12位）"/"再次请输入新密（6-12位）"
 *   tvErrorTips：12.5fp #FD6161 marginH 12 marginTop 8（默认 gone）
 *   tvSubmit"确定设置"：高44 marginH 12 marginTop 48；selector_modify_pwd：
 *     enabled bg primary_color 圆角4 白字 / disabled bg #DEE3E9 圆角4 common_color_3 字
 * 行为（源码逐行）：
 *   Q2(实时校验)：old空→禁用；新/确认 0<len<6→"*密码格式错误"；两者全空→禁用；
 *     相等→启用；否则→"*两次密码输入不一致"
 *   P2(提交)：POST changePasswByOldPassw {passw,passwNew,passwNewAgain}
 *   业务错误 1020-1024 → tvErrorTips；其余 → toast；成功 → ModifyDialog
 *     "修改密码成功，请重新登录"+"新密码：confirm"，onShow 2 秒后 dismiss + logout
 */
@Entry
@Component
struct ModifyPasswordPage {
  @State oldPwd: string = '';
  @State newPwd: string = '';
  @State confirmPwd: string = '';
  @State errorTipsVisible: boolean = false;
  @State errorTipsText: string = '';
  /** tvSubmit enabled（selector 色/字随动） */
  @State submitEnabled: boolean = false;
  /** 提交中防重复（源码 loading g0.i / e() dismiss） */
  @State submitting: boolean = false;
  /** 成功弹窗（ModifyDialog 复刻：白卡圆角6 标题+新密码回显） */
  @State showSuccessDialog: boolean = false;
  @StorageProp('currentBreakpoint') currentBreakpoint: string = 'sm';
  @StorageProp('windowWidthVp') windowWidthVp: number = 360;
  @StorageProp('windowHeightVp') windowHeightVp: number = 780;
  @StorageProp('avoidAreaBottomVp') avoidAreaBottomVp: number = 0;
  @StorageProp('keyboardHeightVp') keyboardHeightVp: number = 0;

  aboutToAppear(): void {
    // 源码 f1()：tvName.setText(d.a.c().getUserName())
  }

  onPageShow(): void {
    const ctx = this.getUIContext().getHostContext() as common.UIAbilityContext;
    PrivacyWindowHelper.enterSensitivePage('ModifyPasswordPage', ctx);
  }

  onPageHide(): void {
    const ctx = this.getUIContext().getHostContext() as common.UIAbilityContext;
    PrivacyWindowHelper.leaveSensitivePage('ModifyPasswordPage', ctx);
  }

  aboutToDisappear(): void {
    const ctx = this.getUIContext().getHostContext() as common.UIAbilityContext;
    PrivacyWindowHelper.leaveSensitivePage('ModifyPasswordPage', ctx);
  }

  /** 登录用户名（f1：d.a.c().getUserName()；会话空则回退 preferences 缓存） */
  private displayName(): string {
    if (LoginSession.sessionName !== '') {
      return LoginSession.sessionName;
    }
    return '';
  }

  /** 源码 Q2：输入变化实时校验，逐分支翻译 */
  private validate(): void {
    const old: string = this.oldPwd;
    const pwdNew: string = this.newPwd;
    const pwdAgain: string = this.confirmPwd;
    if (old === '') {
      this.errorTipsVisible = false;
      this.submitEnabled = false;
      return;
    }
    if ((pwdNew.length > 0 && pwdNew.length < 6) || (pwdAgain.length > 0 && pwdAgain.length < 6)) {
      this.errorTipsText = '*密码格式错误';
      this.errorTipsVisible = true;
      this.submitEnabled = false;
      return;
    }
    if (pwdNew === '' && pwdAgain === '') {
      this.errorTipsVisible = false;
      this.submitEnabled = false;
      return;
    }
    if (pwdNew === pwdAgain) {
      this.errorTipsVisible = false;
      this.submitEnabled = true;
      return;
    }
    this.errorTipsText = '*两次密码输入不一致';
    this.errorTipsVisible = true;
    this.submitEnabled = false;
  }

  /** 源码 P2：提交（UI 不直接发 HTTP，走 ApiService） */
  private async submit(): Promise<void> {
    if (this.submitting || !this.submitEnabled) {
      return;
    }
    this.submitting = true;
    try {
      const resp = await ApiService.changePasswByOldPassw(this.oldPwd, this.newPwd, this.confirmPwd);
      if (resp.code === 0) {
        // 源码 f.g()：ModifyDialog.o(confirm) + show；onShow 2 秒后 dismiss + logout
        this.showSuccessDialog = true;
        setTimeout(() => {
          this.showSuccessDialog = false;
          this.logoutAndRelogin();
        }, 2000);
      } else if (resp.code === 1020 || resp.code === 1021 || resp.code === 1022
        || resp.code === 1023 || resp.code === 1024) {
        // 源码 f.f() switch "1020"-"1024"：错误显示在 tvErrorTips
        this.errorTipsText = resp.message;
        this.errorTipsVisible = true;
      } else {
        // 源码 f.f() default：toast(msg)，errorTips 隐藏
        this.errorTipsVisible = false;
        this.getUIContext().getPromptAction().showToast({ message: resp.message });
      }
    } finally {
      this.submitting = false;
    }
  }

  /** 源码 ((BaseApplication)...).logout(context, "", true)：清会话回登录页（MineTab.doLogout 同款） */
  private async logoutAndRelogin(): Promise<void> {
    await PreferencesUtil.clear();
    this.getUIContext().getPromptAction().showToast({ message: '已退出登录' });
    router.replaceUrl({ url: 'pages/LoginPage' });
  }

  @Builder
  cardDivider() {
    // shape_vertical_divider：白卡内行间分隔线
    Divider()
      .color($r('app.color.common_color_6'))
      .strokeWidth(1)
      .width('100%')
  }

  build() {
    Stack() {
      Column() {
        TitleBar({ title: '密码修改', showBack: true })

        Scroll() {
          Column() {
            // 白卡1：账号 + 原密码（marginTop 16、paddingL 12、divider middle）
            Column() {
              // 行1 高48：账号：<tvName>
              Row() {
                Text('账号：')
                  .fontSize(16)
                  .fontColor($r('app.color.mobile_campus_primary_color'))
                Text(this.displayName())
                  .fontSize(16)
                  .fontColor($r('app.color.mobile_campus_primary_color'))
              }
              .width('100%')
              .height(48)
              .alignItems(VerticalAlign.Center)

              this.cardDivider()

              // 行2 高48：tvOriginalPwd（g0.j 请求焦点 → defaultFocus）
              Row() {
                TextInput({ placeholder: '请输入原密码', text: this.oldPwd })
                  .type(InputType.Password)
                  .fontSize(16)
                  .fontColor($r('app.color.common_color_3'))
                  .placeholderColor($r('app.color.common_color_3'))
                  .placeholderFont({ size: 16 })
                  .backgroundColor(Color.Transparent)
                  .padding(0)
                  .layoutWeight(1)
                  .margin({ right: 12 })
                  .defaultFocus(true)
                  .onChange((value: string) => {
                    this.oldPwd = value;
                    this.validate();
                  })
              }
              .width('100%')
              .height(48)
              .alignItems(VerticalAlign.Center)
            }
            .width('100%')
            .margin({ top: 16 })
            .padding({ left: 12 })
            .backgroundColor($r('app.color.white'))

            // 白卡2：新密码 + 确认（marginTop 12、divider middle）
            Column() {
              Row() {
                TextInput({ placeholder: '请输入新密（6-12位）', text: this.newPwd })
                  .type(InputType.Password)
                  .fontSize(16)
                  .fontColor($r('app.color.common_color_3'))
                  .placeholderColor($r('app.color.common_color_3'))
                  .placeholderFont({ size: 16 })
                  .maxLength(12)
                  .backgroundColor(Color.Transparent)
                  .padding(0)
                  .layoutWeight(1)
                  .margin({ right: 12 })
                  .onChange((value: string) => {
                    this.newPwd = value;
                    this.validate();
                  })
              }
              .width('100%')
              .height(48)
              .alignItems(VerticalAlign.Center)

              this.cardDivider()

              Row() {
                TextInput({ placeholder: '再次请输入新密（6-12位）', text: this.confirmPwd })
                  .type(InputType.Password)
                  .fontSize(16)
                  .fontColor($r('app.color.common_color_3'))
                  .placeholderColor($r('app.color.common_color_3'))
                  .placeholderFont({ size: 16 })
                  .maxLength(12)
                  .backgroundColor(Color.Transparent)
                  .padding(0)
                  .layoutWeight(1)
                  .margin({ right: 12 })
                  .onChange((value: string) => {
                    this.confirmPwd = value;
                    this.validate();
                  })
              }
              .width('100%')
              .height(48)
              .alignItems(VerticalAlign.Center)
            }
            .width('100%')
            .margin({ top: 12 })
            .padding({ left: 12 })
            .backgroundColor($r('app.color.white'))

            // tvErrorTips：12.5fp #FD6161 paddingH 12 marginTop 8（visibility 随校验）
            if (this.errorTipsVisible) {
              Text(this.errorTipsText)
                .fontSize(12.5)
                .fontColor('#FD6161')
                .textAlign(TextAlign.Center)
                .width('100%')
                .padding({ left: 12, right: 12 })
                .margin({ top: 8 })
            }

            // tvSubmit "确定设置"：高44 paddingH 12 top 48，selector 色随 enabled
            Column() {
              Text('确定设置')
                .fontSize(16)
                .fontColor(this.submitEnabled ? $r('app.color.ybg_white') : $r('app.color.common_color_3'))
                .width('100%')
                .height(44)
                .textAlign(TextAlign.Center)
                .borderRadius(4)
                .backgroundColor(this.submitEnabled ?
                  $r('app.color.mobile_campus_primary_color') : '#DEE3E9')
                .onClick(() => {
                  this.submit();
                })
            }
            .width('100%')
            .padding({ left: 12, right: 12, top: 48 })
          }
          .width('100%')
          .constraintSize({ maxWidth: BreakpointSystem.getContentMaxWidth(this.currentBreakpoint) })
          .padding({ bottom: Math.max(24, this.avoidAreaBottomVp + this.keyboardHeightVp + 16) })
        }
        .width('100%')
        .layoutWeight(1)
        .scrollBar(BarState.Off)
        .align(Alignment.Top)
      }
      .width('100%')
      .height('100%')
      .backgroundColor($r('app.color.common_color_6'))

      if (this.showSuccessDialog) {
        this.successDialogBuilder()
      }
    }
    .width('100%')
    .height('100%')
  }

  /** ModifyDialog 复刻（mobile_campus_dialog_modify.xml）：带遮罩、自适应宽高 */
  @Builder
  successDialogBuilder() {
    Column() {
      Column() {
        Text('修改密码成功，请重新登录')
          .fontSize(19)
          .fontColor($r('app.color.ybg_black'))
          .textAlign(TextAlign.Center)
          .width('100%')
          .padding(16)

        Row() {
          Text('新密码：')
            .fontSize(16)
            .fontColor($r('app.color.common_color_3'))
          Text(this.confirmPwd)
            .fontSize(16)
            .fontColor($r('app.color.mobile_campus_primary_color'))
        }
        .margin({ top: 17 })
      }
      .width(AdaptiveLayoutHelper.getDialogMaxWidth(this.currentBreakpoint, this.windowWidthVp))
      .constraintSize({ maxHeight: AdaptiveLayoutHelper.getDialogMaxHeight(this.windowHeightVp) })
      .padding({ bottom: 27 })
      .backgroundColor($r('app.color.ybg_white'))
      .borderRadius(6)
    }
    .width('100%')
    .height('100%')
    .padding({ left: 16, right: 16 })
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .backgroundColor('#66000000')
  }
}
