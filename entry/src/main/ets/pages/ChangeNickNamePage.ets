import { router } from '@kit.ArkUI';
import { TitleBar } from '../components/TitleBar';
import { ApiService } from '../network/ApiService';
import { BreakpointSystem } from '../common/BreakpointSystem';

/**
 * 修改昵称页 — 1:1 翻译 ChangeNickNameActivity.java + mobile_campus_activity_personal_change_nickname.xml
 *
 * 【源码依据】ARouter /personal/changeNickName（e.a.o1），入口 = PersonalDetailNewActivity 头部
 *   昵称行点击（class d → g2(activity, e.a.o1, bundle{nickname})）。
 *
 * 【布局】LinearLayout(common_color_6) + toolbar_normal（标题 R$string.change_nickname="设置昵称"）
 *   + etNickName AppCompatEditText（白底 padding 15、marginTop 20、hint 请设置您的昵称、
 *     maxLength 15、singleLine；f1() 预填 bundle nickname 并置光标到末尾）
 *   + 提示文字 14sp padding 15/12 "支持2-15个字符哦~(*^▽^*)"
 *   + tvSubmit BLTextView 17sp 圆角8 marginH 15 marginT 20 上下 padding 13 "确定设置"
 *     DrawableCreator：enabled #1B68B7/白字、unEnabled gray_nickname=#DFE4EA/gray_text=#999999
 *
 * 【行为】TextWatcher(a)：trim 长度 <2 → tvSubmit.setEnabled(false)，否则 true。
 *   tvSubmit 点击（b.onClick）：g0.h 显示 loading → ChangeNickNameModel.T0
 *     POST /mobileapi_ydxy/api/user/updateNickname {nickname}（e.d 加密 body POST）。
 *   成功（b$a.g）→ ChangeNickNameModel.U0 连乙同步 POST https://www.yibaogao.com/mobileapi/campus/
 *     user/updateNickname {nickname} + 请求头 xxdm（C0401a 仅隐藏 loading）→ finish。
 *   失败（b$a.b）→ g0.b() 隐藏 loading + f.a(4,null) 广播刷新（无 toast，页面停留）——
 *     HAP 等价：返回后 PersonalDetailPage.onPageShow 重拉 getUserInfo。
 */
@Entry
@Component
struct ChangeNickNamePage {
  @State nickName: string = '';
  /** 提交中防重复（源码 g0.h/g0.b loading 对） */
  @State submitting: boolean = false;
  @StorageProp('currentBreakpoint') currentBreakpoint: string = 'sm';
  @StorageProp('avoidAreaBottomVp') avoidAreaBottomVp: number = 0;
  @StorageProp('keyboardHeightVp') keyboardHeightVp: number = 0;

  aboutToAppear(): void {
    // 源码 y(Intent)：this.l = intent.getStringExtra("nickname")；f1()：m.setText(l)
    const params: object | undefined = router.getParams() as object | undefined;
    if (params !== undefined && params !== null) {
      const rec: Record<string, Object> = params as Record<string, Object>;
      const v: Object | undefined = rec['nickname'];
      if (typeof v === 'string') {
        this.nickName = v as string;
      }
    }
  }

  /** 源码 TextWatcher a.afterTextChanged：trim 后长度 >=2 才可提交 */
  private canSubmit(): boolean {
    return this.nickName.trim().length >= 2;
  }

  /** 源码 b.onClick → ChangeNickNameModel.T0；成功 g → U0 连乙同步 + finish */
  private async submit(): Promise<void> {
    if (this.submitting || !this.canSubmit()) {
      return;
    }
    this.submitting = true;
    try {
      const nickname: string = this.nickName.trim();
      const resp = await ApiService.updateNickname(nickname);
      if (resp.code === 1000) {
        // 登录失效统一拦截已在网络层处理（清会话+toast+跳登录），页面保持
        return;
      }
      if (resp.code === 0) {
        // 源码 b$a.g：U0(nickname, C0401a) 连乙同步（结果仅隐藏 loading，不阻塞主流程）→ finish
        ApiService.syncNicknameToLianyi(nickname)
          .catch((error: BusinessError) => {
            ApiService.logError('syncNickname fail: ' + error.message);
          });
        router.back();
      }
      // 源码失败分支（b$a.b / f）无 toast：隐藏 loading + 广播刷新，页面停留
    } catch (error) {
      const be = error as BusinessError;
      ApiService.logError('updateNickname fail: ' + be.message);
    } finally {
      this.submitting = false;
    }
  }

  build() {
    Column() {
      TitleBar({ title: '设置昵称', showBack: true })

      Scroll() {
        Column() {
          TextInput({ text: this.nickName, placeholder: '请设置您的昵称' })
            .width('100%')
            .backgroundColor($r('app.color.white'))
            .fontSize(16)
            .fontColor($r('app.color.common_color_1'))
            .placeholderColor($r('app.color.common_color_3'))
            .placeholderFont({ size: 16 })
            .maxLength(15)
            .padding(15)
            .margin({ top: 20 })
            .defaultFocus(true)
            .enterKeyType(EnterKeyType.Done)
            .onSubmit(() => {
              this.submit();
            })
            .onChange((value: string) => {
              this.nickName = value;
            })

          Text('支持2-15个字符哦~(*^▽^*)')
            .fontSize(14)
            .fontColor($r('app.color.common_color_1'))
            .width('100%')
            .padding({ left: 15, right: 15, top: 12, bottom: 12 })

          Column() {
            Text('确定设置')
              .fontSize(17)
              .fontColor(this.canSubmit() ? $r('app.color.white') : $r('app.color.gray_text'))
              .textAlign(TextAlign.Center)
              .width('100%')
              .padding({ top: 13, bottom: 13 })
              .backgroundColor(this.canSubmit() ? '#1B68B7' : $r('app.color.gray_nickname'))
              .borderRadius(8)
              .hoverEffect(HoverEffect.Highlight)
              .onClick(() => {
                this.submit();
              })
          }
          .width('100%')
          .padding({ left: 15, right: 15, top: 20 })
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
  }
}
