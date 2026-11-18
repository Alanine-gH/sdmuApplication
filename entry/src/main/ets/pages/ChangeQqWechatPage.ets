import { router } from '@kit.ArkUI';
import { BusinessError } from '@kit.BasicServicesKit';
import { TitleBar } from '../components/TitleBar';
import { ApiService } from '../network/ApiService';

/**
 * 绑定/修改 QQ、微信号页 — 1:1 翻译 ChangeQqAndWechatActivity.java
 * （module/my/view/ChangeQqAndWechatActivity.java:26，manifest L237）。
 *
 * 【入口】PersonalDetailPage:387/396 绑定QQ/微信行 → router params {title:'QQ'|'微信', content:当前值}。
 * 【源码】mobile_campus_activity_personal_change_qq_and_wechat.xml：
 *   LinearLayout(common_color_6) + toolbar_normal（标题=intent title）+ etContent（白底 pad15 marginTop20
 *   singleLine）+ tvTip（14sp pad15/12）+ tvSubmit（17sp 圆角8 marginH15 marginT20 上下 pad13，
 *   enabled #1B68B7 白字 / disabled #DFE4EA #999999）+ tvClear（17sp #e96161 描边0.5 marginT16）。
 * 【分支】y()：l=title、m=content。
 *   QQ：hint"请输入您的QQ号"、tip"5-15个字符，仅支持数字。"、clear"清空QQ号"、inputType number。
 *   微信：hint"请输入您的微信号"、tip"须以字母开头，6-20个字符，支持字母、数字、下划线、减号。"、clear"清空微信号"。
 * 【校验】TextWatcher(a)：QQ trim 空或<5 禁用 / >15 截断；微信 trim 空或<6 禁用 / >20 截断。
 *   提交(b)：微信首字符须字母(N2)、不含中文/表情(L2/K2)、正则 ^[a-zA-Z][-_a-zA-Z0-9]{5,19}$(O2)，
 *   失败 toast(tvTip 文本)；QQ 无额外校验。清空(c)：直接提交空值。
 * 【接口】d.java（module/c/i/d）：V0 updateQq{qq} / W0 updateWechat{wechat} /
 *   X0 cleanQq{} / Y0 cleanWechat{}（源码 POST_CONTENT 加密；实测全 code=0）。
 *   成功：f.a(4,null) 广播刷新 → finish；清空成功额外 toast"清空成功"。
 */
@Entry
@Component
struct ChangeQqWechatPage {
  @State kind: string = 'QQ';
  @State content: string = '';
  @State submitting: boolean = false;
  private tipText: string = '';
  private clearText: string = '清空';

  aboutToAppear(): void {
    const params: Record<string, Object> = (router.getParams() ?? {}) as Record<string, Object>;
    const pick = (k: string): string => {
      const v: Object | undefined = params[k];
      return typeof v === 'string' ? v as string : '';
    };
    // 源码 y()：l=intent.title、m=intent.content；f1() setText(m)+光标末尾
    this.kind = pick('title') === '微信' ? '微信' : 'QQ';
    this.content = pick('content');
    if (this.kind === 'QQ') {
      this.tipText = '5-15个字符，仅支持数字。';
      this.clearText = '清空QQ号';
    } else {
      this.tipText = '须以字母开头，6-20个字符，支持字母、数字、下划线、减号。';
      this.clearText = '清空微信号';
    }
  }

  /** 源码 TextWatcher a：QQ 5-15 / 微信 6-20 字符启用提交 */
  private canSubmit(): boolean {
    const len: number = this.content.trim().length;
    return this.kind === 'QQ' ? len >= 5 : len >= 6;
  }

  private onInput(value: string): void {
    // 源码 >15(QQ)/>20(微信) 截断
    const max: number = this.kind === 'QQ' ? 15 : 20;
    this.content = value.length > max ? value.substring(0, max) : value;
  }

  /** 源码 b.onClick 微信三校验 + O2 正则；返回 null 表示通过，否则为 toast 文案 */
  private validate(): string | null {
    if (this.kind !== '微信') {
      return null;
    }
    const value: string = this.content.trim();
    if (!/^[a-zA-Z]/.test(value.substring(0, 1))) {
      return '须以字母开头，请重新输入';
    }
    if (/[\u3400-\u9FFF\u3000-\u303F\uFF00-\uFFEF]/.test(value)) {
      return '不支持输入表情包和中文，请重新输入';
    }
    if (!/^[a-zA-Z][-_a-zA-Z0-9]{5,19}$/.test(value)) {
      return this.tipText;
    }
    return null;
  }

  private async submit(clear: boolean): Promise<void> {
    if (this.submitting) {
      return;
    }
    if (!clear) {
      // 源码 TextWatcher a：trim 长度 QQ<5 / 微信<6 时提交按钮 disabled，不可提交
      // （不拦住会让空值流入 changeQqWechat，value==='' 会被路由到 cleanQq/cleanWechat 误清空）
      if (!this.canSubmit()) {
        return;
      }
      const err: string | null = this.validate();
      if (err !== null) {
        this.getUIContext().getPromptAction().showToast({ message: err as string });
        return;
      }
    }
    this.submitting = true;
    try {
      // 源码 clear → X0/Y0（value=""）；submit → V0/W0（value=trim）
      const value: string = clear ? '' : this.content.trim();
      const resp = await ApiService.changeQqWechat(this.kind, value);
      if (resp.code === 0) {
        if (clear) {
          this.getUIContext().getPromptAction().showToast({ message: '清空成功' });
        }
        router.back(); // 源码 f.a(4,null) 广播刷新 → PersonalDetail.onPageShow 重拉
      }
    } catch (error) {
      const be = error as BusinessError;
      ApiService.logError('changeQqWechat fail: ' + be.message);
    } finally {
      this.submitting = false;
    }
  }

  build() {
    Column() {
      TitleBar({ title: this.kind, showBack: true })

      TextInput({ text: this.content, placeholder: this.kind === 'QQ' ? '请输入您的QQ号' : '请输入您的微信号' })
        .width('100%')
        .backgroundColor($r('app.color.white'))
        .fontSize(16)
        .fontColor($r('app.color.common_color_1'))
        .placeholderColor($r('app.color.common_color_3'))
        .placeholderFont({ size: 16 })
        .maxLength(this.kind === 'QQ' ? 15 : 20)
        .padding(15)
        .margin({ top: 20 })
        .defaultFocus(true)
        .type(this.kind === 'QQ' ? InputType.Number : InputType.Normal)
        .onChange((value: string) => {
          this.onInput(value);
        })

      Text(this.tipText)
        .fontSize(14)
        .fontColor($r('app.color.common_color_1'))
        .width('100%')
        .padding({ left: 15, right: 15, top: 12, bottom: 12 })

      Text('确定')
        .fontSize(17)
        .fontColor(this.canSubmit() ? $r('app.color.white') : $r('app.color.gray_text'))
        .textAlign(TextAlign.Center)
        .width('100%')
        .padding({ top: 13, bottom: 13 })
        .margin({ left: 15, right: 15, top: 20 })
        .backgroundColor(this.canSubmit() ? '#1B68B7' : $r('app.color.gray_nickname'))
        .borderRadius(8)
        .onClick(() => {
          this.submit(false);
        })

      Text(this.clearText)
        .fontSize(17)
        .fontColor('#e96161')
        .textAlign(TextAlign.Center)
        .width('100%')
        .padding({ top: 13, bottom: 13 })
        .margin({ left: 15, right: 15, top: 16 })
        .borderRadius(8)
        .border({ width: 0.5, color: '#e96161' })
        .onClick(() => {
          this.submit(true);
        })
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.common_color_6'))
  }
}
