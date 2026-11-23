import { router } from '@kit.ArkUI';
import { BusinessError } from '@kit.BasicServicesKit';
import { TitleBar } from '../components/TitleBar';
import { ApiService } from '../network/ApiService';
import { ApiResponse } from '../model/ResponseModel';
import { MobileCampusUserInfo } from '../model/MobileCampusUserInfoModel';
import { LoginSession } from '../network/LoginSession';
import { BreakpointSystem } from '../common/BreakpointSystem';

/**
 * 绑定邮箱页 — 1:1 翻译 MobileCampusInputEmailActivity.java +
 *   mobile_campus_activity_mobile_campus_bind_email.xml
 *
 * 【源码依据】ARouter /my/bindemail_main（RouteConstant e.a.n），入口 =
 *   PersonalDetailNewActivity 绑定区"邮箱"行（class b case "邮箱" → h2(activity, e.a.n, null, 6)，
 *   mySetup.myemail!="1" 时 toast"暂不支持修改"）。
 *
 * 【布局】LinearLayout(ybg_white) + toolbar_normal（T1 标题"绑定邮箱"）+ 细分隔线
 *   + 居中纵向：图标(invisible, marginTop 40) + "电子邮箱"(common_color_1, marginTop 12)
 *     + "请输入邮箱"(px_to_sp_26=13sp, marginTop 8)
 *     + edEmail EditText（marginH px_to_dip_112=56、marginTop 18、gravity center、
 *       theme mobile_campus_bind_phone_editText=下划线灰 #CECECE）
 *     + tvSubmit "完成"(px_to_sp_30=15sp、selector_bind_phone：enabled #1B68B7/禁用 #CECECE、
 *       padding 10、marginTop 38)
 *   + 底部 FrameLayout(paddingH 50) 居中 "温馨提醒:\n\n请输入本人使用的邮箱地址。"
 *
 * 【行为】f1()：UserEntity.email 非空 → 预填（HAP 取 getUserInfo 的 email 字段）。
 *   tvSubmit 点击（a.a）：N2 正则 ^\w+([-+.]\w+)*@\w+([-.]\w+)*\.\w+([-.]\w+)*$ 校验，
 *     失败 toast"请输入正确的邮箱地址！"；通过 → M2 → BindEmailPImpl.b → BindEmailModel.T0
 *     POST /mobileapi_ydxy/api/bindPhone/saveEmail {userId, userType, email_url}。
 *   业务成功（b.g）→ toast"绑定邮箱成功！" + UserEntity.setEmail 本地缓存 + setResult(-1) + finish。
 *   业务失败（b.f）→ f0.c toast(message)。code=1000 登录失效网络层统一拦截。
 */
@Entry
@Component
struct InputEmailPage {
  @State email: string = '';
  /** 提交中防重复（源码 g0.b/g0.i loading 对） */
  @State submitting: boolean = false;
  @StorageProp('currentBreakpoint') currentBreakpoint: string = 'sm';
  @StorageProp('avoidAreaBottomVp') avoidAreaBottomVp: number = 0;
  @StorageProp('keyboardHeightVp') keyboardHeightVp: number = 0;

  aboutToAppear(): void {
    // 源码 f1()：TextUtils.isEmpty(UserEntity.getEmail()) ? 不填 : l.setText(email)
    // HAP 登录会话未持久化 email 字段 → 走 getUserInfo 真实数据源（与 PersonalDetailPage 同管道）
    if (LoginSession.userId === '') {
      return;
    }
    ApiService.getUserInfo(LoginSession.userId)
      .then((response: ApiResponse<MobileCampusUserInfo>) => {
        if (response.code === 0 && response.data.email !== '') {
          this.email = response.data.email;
        }
      })
      .catch((error: BusinessError) => {
        ApiService.logError('InputEmail getUserInfo fail: ' + error.message);
      });
  }

  /** 源码 N2：^\w+([-+.]\w+)*@\w+([-.]\w+)*\.\w+([-.]\w+)*$ */
  private validEmail(str: string): boolean {
    return str !== '' &&
      /^[\w]+([\-+.][\w]+)*@[\w]+([\-\.][\w]+)*\.[\w]+([\-\.][\w]+)*$/.test(str);
  }

  /** 源码 a.a → M2 → BindEmailModel.T0；成功 g → toast + finish */
  private async submit(): Promise<void> {
    const str: string = this.email.trim();
    if (this.submitting) {
      return;
    }
    if (!this.validEmail(str)) {
      this.getUIContext().getPromptAction().showToast({ message: '请输入正确的邮箱地址！' });
      return;
    }
    this.submitting = true;
    try {
      const resp = await ApiService.saveEmail(str);
      if (resp.code === 1000) {
        return;
      }
      if (resp.code === 0) {
        this.getUIContext().getPromptAction().showToast({ message: '绑定邮箱成功！' });
        router.back();
      } else {
        // 源码 b.f：f0.c(context, str2) toast(message)
        this.getUIContext().getPromptAction().showToast({ message: resp.message });
      }
    } catch (error) {
      const be = error as BusinessError;
      ApiService.logError('saveEmail fail: ' + be.message);
    } finally {
      this.submitting = false;
    }
  }

  build() {
    Column() {
      TitleBar({ title: '绑定邮箱', showBack: true })
      Divider()
        .color($r('app.color.divider_grey'))
        .strokeWidth(0.5)
        .width('100%')

      Scroll() {
        Column() {
          Image($r('app.media.mobile_campus_phone_nub'))
            .visibility(Visibility.None)
            .margin({ top: 40 })

          Text('电子邮箱')
            .fontSize(16)
            .fontColor($r('app.color.common_color_1'))
            .margin({ top: 12 })

          Text('请输入邮箱')
            .fontSize(13)
            .fontColor($r('app.color.common_color_1'))
            .margin({ top: 8 })

          TextInput({ text: this.email, placeholder: '' })
            .width('100%')
            .height(40)
            .textAlign(TextAlign.Center)
            .fontSize(16)
            .fontColor($r('app.color.common_color_1'))
            .backgroundColor(Color.Transparent)
            .type(InputType.Email)
            .enterKeyType(EnterKeyType.Done)
            .padding({ left: 56, right: 56 })
            .margin({ top: 18 })
            .defaultFocus(true)
            .onSubmit(() => {
              this.submit();
            })
            .onChange((value: string) => {
              this.email = value;
            })

          Text('完成')
            .fontSize(15)
            .fontColor(this.submitting ? '#CECECE' : '#1B68B7')
            .padding(10)
            .margin({ top: 38 })
            .hoverEffect(HoverEffect.Highlight)
            .onClick(() => {
              this.submit();
            })

          Blank().layoutWeight(1)

          Column() {
            Text('温馨提醒:\n\n请输入本人使用的邮箱地址。')
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
  }
}
