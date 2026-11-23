import { router } from '@kit.ArkUI';
import { BusinessError } from '@kit.BasicServicesKit';
import { TitleBar } from '../components/TitleBar';
import { ApiService } from '../network/ApiService';
import { LoginSession } from '../network/LoginSession';
import { PreferencesUtil } from '../data/PreferencesUtil';
import { BreakpointSystem } from '../common/BreakpointSystem';
import { AdaptiveLayoutHelper } from '../common/AdaptiveLayoutHelper';

/**
 * 输入手机号页（绑定手机第一步）— 1:1 翻译 MobileCampusInputPhoneActivity.java +
 *   mobile_campus_activity_mobile_campus_get_code.xml
 *
 * 【源码依据】ARouter /my/bindphone_main（RouteConstant e.a.m）。入口两处：
 *   1) PersonalDetailNewActivity 绑定区"手机"行（class b case"手机"）→ bundle
 *      {bindPhoneState:PhoneStatus.bindPhone, needSmsVertify:PhoneStatus.message,
 *       hasBindPhone:PhoneStatus.hasPhone, currentBindPhone:UserEntity.bindMobile, source:"1"}；
 *   2) MobileCampusLoginNewActivity 登录未绑手机流程 → bundle
 *      {bindPhoneState, needSmsVertify, hasBindPhone:false, userInfoJson}。
 *
 * 【布局】ybg_white + toolbar（validation 空 → 标题"绑定手机号"；否则"设备验证"）+ 细分隔线
 *   + 居中纵向：图标(marginTop 40) + "输入手机号" + "请输入手机号码，以便绑定手机"(13sp)
 *     + edPhone（marginH 56、marginTop 18、phone 输入、灰下划线 #CECECE）
 *     + tvNext "下一步"/"完成"(15sp selector_bind_phone enabled #1B68B7/禁用 #CECECE, marginTop 48)
 *   + 底部 tvPhoneTip 居中 "温馨提醒:\n\n请输入本人使用的手机号码。"（HJJGC 学校另有文案，SDMU 走默认）
 *
 * 【行为】y()：validation 非空（换设备验证）→ 已绑手机则直接转 BindPhonePage{validation,phone} 并
 *   finish；否则清空 validation。bindPhoneState 空 → "2"。q=needSmsVertify、r=hasBindPhone(默认true)、
 *   t=source、s=isCircle。f1()：validation 非空 → 输入框禁焦；已绑手机 → 预填；
 *   !q → tvNext 文案"完成"（XML 默认"下一步"）。
 *   tvNext 点击（c）：空→"请输入手机号码"；≠11位→"请输入11位号码！"；
 *   q → V2 转 BindPhonePage{phone,validation,justBindPhone:true,isCircle,userInfoJson?}；
 *   否则 U2 → BindPhoneModel.U0 POST savePhone {code:userId,type:userType,phone}：
 *     code!="0" → toast"手机号码格式错误"；"0" → toast"绑定手机成功！"+本地缓存+initAtLogin+
 *     跳主页清栈（g2(e.a.r)+finishAllActivities）。
 *   返回键（onBackPressed）：t!="1"且!r且p=="1" → 弹窗"须输入手机号码完成绑定"（退出→W2 登出）；
 *     p=="2" → Hawk bindPhone=false（+userInfoJson 非空时跳主页清栈，当前链路无该参）。
 */
interface RouteParams {
  validation?: string;
  bindPhoneState?: string;
  needSmsVertify?: boolean;
  hasBindPhone?: boolean;
  currentBindPhone?: string;
  source?: string;
  isCircle?: boolean;
  userInfoJson?: string;
}

@Entry
@Component
struct InputPhonePage {
  @State phone: string = '';
  /** validation 非空 = 设备验证模式（标题"设备验证"+输入框禁焦） */
  @State validation: string = '';
  /** 源码 p：bindPhoneState（空 → "2"） */
  private bindPhoneState: string = '2';
  /** 源码 q：needSmsVertify（true → 转验证码页） */
  private needSmsVertify: boolean = false;
  /** 源码 r：hasBindPhone（默认 true） */
  private hasBindPhone: boolean = true;
  /** 源码 t：source（PersonalDetail 入口传 "1"） */
  private source: string = '';
  /** 源码 s：isCircle（校圈绑定） */
  private isCircle: boolean = false;
  /** 源码 w：userInfoJson（登录流程才有，HAP 当前链路为空） */
  private userInfoJson: string = '';
  /** 提交中防重复 */
  @State submitting: boolean = false;
  /** 源码 u：返回确认弹窗显示态 */
  @State showQuitDialog: boolean = false;
  @StorageProp('currentBreakpoint') currentBreakpoint: string = 'sm';
  @StorageProp('windowWidthVp') windowWidthVp: number = 360;
  @StorageProp('windowHeightVp') windowHeightVp: number = 780;
  @StorageProp('avoidAreaBottomVp') avoidAreaBottomVp: number = 0;
  @StorageProp('keyboardHeightVp') keyboardHeightVp: number = 0;

  aboutToAppear(): void {
    // 源码 y(Intent) 逐行还原
    const params: object | undefined = router.getParams() as object | undefined;
    const rec: RouteParams = params !== undefined && params !== null ? params as RouteParams :
      { currentBindPhone: '' } as RouteParams;
    if (params !== undefined && params !== null) {
      this.validation = typeof rec.validation === 'string' ? rec.validation : '';
      this.bindPhoneState = typeof rec.bindPhoneState === 'string' && rec.bindPhoneState !== ''
        ? rec.bindPhoneState : '2';
      this.needSmsVertify = rec.needSmsVertify === true;
      this.hasBindPhone = rec.hasBindPhone === undefined ? true : rec.hasBindPhone === true;
      this.source = typeof rec.source === 'string' ? rec.source : '';
      this.isCircle = rec.isCircle === true;
      this.userInfoJson = typeof rec.userInfoJson === 'string' ? rec.userInfoJson : '';
      // 源码：validation 非空且已绑手机 → 直接转 BindPhonePage{validation, phone} 并 finish
      if (this.validation !== '' && this.boundPhone(rec) !== '') {
        router.replaceUrl({
          url: 'pages/BindPhonePage',
          params: { 'validation': this.validation, 'phone': this.boundPhone(rec) } as Record<string, string>
        });
        return;
      }
      this.validation = '';
    }
    // 源码 f1()：UserEntity.bindMobile 非空 → 预填
    const bound: string = this.boundPhone(rec);
    if (bound !== '') {
      this.phone = bound;
    }
  }

  /** 当前绑定手机（源码 d.a.c().getBindMobile()；HAP 由 PersonalDetailPage 经 currentBindPhone 传入） */
  private boundPhone(rec: RouteParams): string {
    return typeof rec.currentBindPhone === 'string' ? rec.currentBindPhone : '';
  }

  /** 源码 c.onClick：前置校验 */
  private checkBeforeSubmit(): string {
    const str: string = this.phone.trim();
    if (str === '') {
      return '请输入手机号码';
    }
    if (str.length !== 11) {
      // R$string.please_input_11_numbers
      return '请输入11位号码！';
    }
    return '';
  }

  /** 源码 U2 → BindPhonePImpl.e → BindPhoneModel.U0 savePhone；
   *  code=="0"（g 回调，f.java 仅 code=0 进 g）→ toast"绑定手机成功！"跳主页清栈；
   *  code!="0" → f 回调 f0.c(context, str2) toast 服务器 message
   *  （源码 g 内 !"0".equals(code)→"手机号码格式错误" 为不可达防御分支）。
   */
  private async submitPhone(): Promise<void> {
    const str: string = this.phone.trim();
    this.submitting = true;
    try {
      const resp = await ApiService.savePhone(str);
      if (resp.code === 1000) {
        return;
      }
      if (resp.code !== 0) {
        // 源码 f.f：f0.c(context, str2) — toast 服务器返回 message
        this.getUIContext().getPromptAction().showToast({ message: resp.message });
        return;
      }
      this.getUIContext().getPromptAction().showToast({ message: '绑定手机成功！' });
      // 源码：UserEntity.setBindMobile + PhoneStatus.hasPhone + initAtLogin
      // + g2(e.a.r=主页) + finishAllActivities
      await PreferencesUtil.putString('sessionBindMobile', str);
      router.replaceUrl({ url: 'pages/Index' });
    } catch (error) {
      const be = error as BusinessError;
      ApiService.logError('savePhone fail: ' + be.message);
    } finally {
      this.submitting = false;
    }
  }

  /** 源码 c.onClick：q(needSmsVertify) → V2 转验证码页，否则 savePhone */
  private onNextClick(): void {
    const tip: string = this.checkBeforeSubmit();
    if (tip !== '') {
      this.getUIContext().getPromptAction().showToast({ message: tip });
      return;
    }
    // 源码 s.o(application) 网络预检 → "网络好像有点问题，过一会再试吧"（HAP 由请求层超时兜底）
    if (this.needSmsVertify) {
      // 源码 V2：h2(e.a.o=BindPhoneActivity, bundle{phone,validation,justBindPhone:true,isCircle,userInfoJson?}, 3)
      const bundleParams: Record<string, Object> = {
        'phone': this.phone.trim(),
        'validation': this.validation,
        'justBindPhone': true,
        'isCircle': this.isCircle
      };
      if (this.userInfoJson !== '') {
        bundleParams['userInfoJson'] = this.userInfoJson;
      }
      router.pushUrl({ url: 'pages/BindPhonePage', params: bundleParams });
      return;
    }
    this.submitPhone();
  }

  /** 源码 W2（弹窗"退出"回调）→ module/b/h/b.k → LoginModel.N0 auth/logout → logout */
  private async quitAndLogout(): Promise<void> {
    try {
      await ApiService.authLogout();
    } catch (error) {
      const be = error as BusinessError;
      ApiService.logError('authLogout fail: ' + be.message);
    }
    // 源码 b.b()：((BaseApplication)app).logout(context, "", true)
    await PreferencesUtil.clear();
    router.replaceUrl({ url: 'pages/LoginPage' });
  }

  /** 源码 onBackPressed 分支 */
  private async handleBack(): Promise<void> {
    if (this.source !== '1' && !this.hasBindPhone && this.bindPhoneState === '1') {
      // 源码：u.show() 弹窗"须输入手机号码完成绑定"
      this.showQuitDialog = true;
      return;
    }
    if (this.bindPhoneState === '2') {
      // 源码：d.a.g("bindPhone", false) Hawk 写入；userInfoJson 非空时跳主页清栈
      // （HAP 等价 Preferences 布尔持久化；当前链路 userInfoJson 为空 → 不跳转）
      await PreferencesUtil.putBoolean('bindPhone', false);
    }
    router.back();
  }

  /** 源码 tvNext：selector_bind_phone enabled #1B68B7 / disabled #CECECE；
   *  XML 默认"下一步"，f1() !q → "完成" */
  private nextLabel(): string {
    return this.needSmsVertify ? '下一步' : '完成';
  }

  /** 源码 com.lysoft.android.lyyd.base.widget.a 弹窗复刻（标题+退出/继续） */
  @Builder
  quitDialog() {
    Column() {
      Column() {
        Text('须输入手机号码完成绑定')
          .fontSize(15)
          .fontColor($r('app.color.common_color_1'))
          .textAlign(TextAlign.Center)
          .width('100%')
          .padding({ left: 24, right: 24, top: 24, bottom: 24 })
        Divider()
          .color($r('app.color.common_color_6'))
          .strokeWidth(0.5)
        Row() {
          Text('退出')
            .fontSize(16)
            .fontColor($r('app.color.common_color_1'))
            .textAlign(TextAlign.Center)
            .layoutWeight(1)
            .padding({ top: 12, bottom: 12 })
            .hoverEffect(HoverEffect.Highlight)
            .onClick(() => {
              this.showQuitDialog = false;
              this.quitAndLogout();
            })
          Divider()
            .vertical(true)
            .color($r('app.color.common_color_6'))
            .strokeWidth(0.5)
            .height(40)
          Text('继续')
            .fontSize(16)
            .fontColor('#1B68B7')
            .textAlign(TextAlign.Center)
            .layoutWeight(1)
            .padding({ top: 12, bottom: 12 })
            .hoverEffect(HoverEffect.Highlight)
            .onClick(() => {
              // 源码 sure 按钮 → a()：仅 dismiss
              this.showQuitDialog = false;
            })
        }
        .alignItems(VerticalAlign.Center)
      }
      .width(AdaptiveLayoutHelper.getDialogMaxWidth(this.currentBreakpoint, this.windowWidthVp))
      .constraintSize({ maxHeight: AdaptiveLayoutHelper.getDialogMaxHeight(this.windowHeightVp) })
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

  build() {
    Stack() {
      Column() {
        TitleBar({ title: this.validation === '' ? '绑定手机号' : '设备验证', showBack: true })
        Divider()
          .color($r('app.color.divider_grey'))
          .strokeWidth(0.5)
          .width('100%')

        Scroll() {
          Column() {
            Image($r('app.media.mobile_campus_phone_nub'))
              .margin({ top: 40 })

            Text('输入手机号')
              .fontSize(16)
              .fontColor($r('app.color.common_color_1'))
              .margin({ top: 12 })

            Text('请输入手机号码，以便绑定手机')
              .fontSize(13)
              .fontColor($r('app.color.common_color_1'))
              .margin({ top: 8 })

            TextInput({ text: this.phone, placeholder: '' })
              .width('100%')
              .height(40)
              .textAlign(TextAlign.Center)
              .fontSize(16)
              .fontColor($r('app.color.common_color_1'))
              .backgroundColor(Color.Transparent)
              .type(InputType.PhoneNumber)
              .enterKeyType(EnterKeyType.Done)
              .maxLength(11)
              .enabled(this.validation === '')
              .padding({ left: 56, right: 56 })
              .margin({ top: 18 })
              .onSubmit(() => {
                this.onNextClick();
              })
              .onChange((value: string) => {
                this.phone = value;
              })

            Text(this.nextLabel())
              .fontSize(15)
              .fontColor(this.phone.trim() === '' || this.submitting ? '#CECECE' : '#1B68B7')
              .padding(10)
              .margin({ top: 48 })
              .hoverEffect(HoverEffect.Highlight)
              .onClick(() => {
                this.onNextClick();
              })

            Blank().layoutWeight(1)

            Column() {
              Text('温馨提醒:\n\n请输入本人使用的手机号码。')
                .fontSize(15)
                .fontColor($r('app.color.common_color_1'))
                .textAlign(TextAlign.Center)
            }
            .width('100%')
            .justifyContent(FlexAlign.Center)
            .padding({ left: 50, right: 50, top: 24, bottom: Math.max(24, this.avoidAreaBottomVp + this.keyboardHeightVp + 16) })
          }
          .width('100%')
          .constraintSize({ minHeight: '100%', maxWidth: BreakpointSystem.getContentMaxWidth(this.currentBreakpoint) })
          .alignItems(HorizontalAlign.Center)
        }
        .width('100%')
        .layoutWeight(1)
        .scrollBar(BarState.Off)
      }
      .width('100%')
      .height('100%')
      .backgroundColor($r('app.color.ybg_white'))

      if (this.showQuitDialog) {
        this.quitDialog()
      }
    }
    .width('100%')
    .height('100%')
  }
}
