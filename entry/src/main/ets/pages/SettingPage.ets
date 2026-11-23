import { router } from '@kit.ArkUI';
import { common } from '@kit.AbilityKit';
import fs from '@ohos.file.fs';
import { TitleBar } from '../components/TitleBar';
import { ApiService } from '../network/ApiService';
import { LoginSession } from '../network/LoginSession';
import { ApiResponse } from '../model/ResponseModel';
import { GestureManager, GesturePwdBean } from '../model/GestureManager';

/**
 * 设置页 — 1:1 复刻 mobile_campus_activity_setting.xml
 * 结构：LinearLayout(common_color_6 #F2F2F2) + toolbar_normal + ScrollView
 *   第一组：检测更新(箭头) / 清除缓存(缓存值16fp #1B68B7+箭头) / 字体大小(箭头) / 推送设置(Switch)
 *   第二组：服务协议(箭头) / 隐私政策(箭头) / 关于我们(版本16fp #1B68B7+箭头)
 *   行：高48vp(px96/2)、paddingH 12vp(px24/2)、文字16fp(px32/2) #333333
 *   分隔线：#DFE4EA 0.5vp(px1/2) marginLeft 12vp
 * Switch 样式（mobile_campus_switchCompat.control）：选中 #1B68B7、thumb 白色
 * 检测更新对话框复刻 activity_custom_app_update.xml
 */
@Entry
@Component
struct SettingPage {
  @State cacheSize: string = '0.00M';
  /** 源码 version_name：显示当前版本号，主色红 */
  @State versionName: string = 'V3.3.0';

  aboutToAppear(): void {
    this.calcCacheSize();
  }

  /** 源码 f1：Math.round(g.e(cacheDir))，>1MB 显示 MB 否则 KB */
  private calcCacheSize(): void {
    try {
      const ctx = this.getUIContext().getHostContext() as common.UIAbilityContext;
      const total: number = this.dirSize(ctx.cacheDir);
      const kb = Math.round(total / 1024);
      if (kb / 1024 > 1) {
        this.cacheSize = Math.round(kb / 1024) + 'MB';
      } else {
        this.cacheSize = kb + 'KB';
      }
    } catch {
      this.cacheSize = '0.00M';
    }
  }

  private dirSize(path: string): number {
    let total = 0;
    try {
      const stat: fs.Stat = fs.statSync(path);
      if (stat.isDirectory()) {
        const names: string[] = fs.listFileSync(path);
        for (const name of names) {
          total += this.dirSize(path + '/' + name);
        }
      } else {
        total = Number(stat.size);
      }
    } catch {
    }
    return total;
  }
  @State pushEnabled: boolean = true;
  @State showUpdateDialog: boolean = false;
  /** [W22 launch-chain] SettingActivity h() 手势密码链：校验密码弹窗态 + 输入值 */
  @State showGesturePwdDialog: boolean = false;
  @State checkPassword: string = '';

  /** 源码 h.onClick（llGesturePwdLayout）：GestureManager.b(userId) 有已存手势 →
   *  g2(e.a.k=/my/GesturePwdVerifyActivity){jsonStr}；无 → "校验密码"弹窗。 */
  private async onGestureRow(): Promise<void> {
    const bean: GesturePwdBean | null = await GestureManager.find(LoginSession.userId);
    if (bean === null) {
      this.showGesturePwdDialog = true;
      return;
    }
    // 源码：bundle jsonStr = Gson(bean)
    router.pushUrl({ url: 'pages/GesturePwdVerifyPage',
      params: { 'jsonStr': JSON.stringify(bean) } as Record<string, string> });
  }

  /** 源码 h$a.a(bVar, str)：密码非空 → VerificationModel.U0 POST checkPass；
   *  g → dismiss + g2(e.a.j=/my/GesturePwdSettingActivity)；f → toast(message)。 */
  private async submitCheckPassword(): Promise<void> {
    // 源码 a$a.a：TextUtils.isEmpty(str) → return（弹窗停留）
    if (this.checkPassword === '') {
      return;
    }
    try {
      const resp: ApiResponse<Object> = await ApiService.checkGesturePassword(this.checkPassword);
      if (resp.code !== 0) {
        // 源码 C0406a.f：m(str2)
        this.getUIContext().getPromptAction().showToast({ message: resp.message });
        return;
      }
      // 源码 C0406a.g：dismiss + g2(e.a.j)
      this.showGesturePwdDialog = false;
      this.checkPassword = '';
      router.pushUrl({ url: 'pages/GesturePwdSettingPage' });
    } catch (error) {
      ApiService.logError('checkPass fail: ' + error.message);
    }
  }

  /** 源码 h$a.b(bVar, str)：取消 → dismiss */
  private cancelCheckPassword(): void {
    this.showGesturePwdDialog = false;
    this.checkPassword = '';
  }

  /** 源码 com.lysoft.android.lyyd.report.baseapp.b.b 弹窗复刻
   *  （title"校验密码" + message"请输入登录密码验证身份..." + 密码输入 + 确定/取消）
   *  [W22-review 修复] 原实现为常驻 .overlay(gesturePwdDialog())：showGesturePwdDialog=false
   *  时 Builder 输出空，但 overlay 空层实测拦截整页输入（模拟器实测：设置页所有行点击与
   *  TitleBar 返回全部失效，hilog "Click try accept Row" 不出现；移除 overlay 后 Row 命中
   *  恢复）。改为条件挂载的全屏遮罩层：仅弹窗态渲染，遮罩不透传点击，等价 setCancelable(false)。 */
  @Builder
  gesturePwdDialog() {
    if (this.showGesturePwdDialog) {
      Column() {
        Column() {
        Text('校验密码')
          .fontSize(16)
          .fontColor($r('app.color.common_color_1'))
          .textAlign(TextAlign.Center)
          .width('100%')
          .padding({ top: 20 })
        Text('请输入登录密码验证身份...')
          .fontSize(14)
          .fontColor($r('app.color.common_color_2'))
          .textAlign(TextAlign.Center)
          .width('100%')
          .padding({ left: 24, right: 24, top: 12 })
        TextInput({ placeholder: '登录密码', text: this.checkPassword })
          .type(InputType.Password)
          .fontSize(15)
          .height(42)
          .margin({ left: 24, right: 24, top: 12 })
          .onChange((value: string) => {
            this.checkPassword = value;
          })
        Divider()
          .color($r('app.color.common_color_6'))
          .strokeWidth(0.5)
          .margin({ top: 16 })
        Row() {
          Text('取消')
            .fontSize(15)
            .fontColor($r('app.color.common_color_1'))
            .textAlign(TextAlign.Center)
            .layoutWeight(1)
            .padding({ top: 12, bottom: 12 })
            .onClick(() => {
              this.cancelCheckPassword();
            })
          Divider()
            .vertical(true)
            .color($r('app.color.common_color_6'))
            .strokeWidth(0.5)
            .height(40)
          Text('确定')
            .fontSize(15)
            .fontColor($r('app.color.mobile_campus_primary_color'))
            .textAlign(TextAlign.Center)
            .layoutWeight(1)
            .padding({ top: 12, bottom: 12 })
            .onClick(() => {
              this.submitCheckPassword();
            })
        }
        .alignItems(VerticalAlign.Center)
        }
        .width(280)
        .backgroundColor($r('app.color.ybg_white'))
        .borderRadius(6)
      }
      .width('100%')
      .height('100%')
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
      .backgroundColor('rgba(0,0,0,0.35)')
    }
  }

  private clearCache(): void {
    this.getUIContext().getPromptAction().showToast({ message: '清除成功' });
    try {
      const ctx = this.getUIContext().getHostContext() as common.UIAbilityContext;
      fs.rmdirSync(ctx.cacheDir);
    } catch {
    }
    this.cacheSize = '0KB';
    this.calcCacheSize();
  }

  private checkUpdate(): void {
    // 服务端不可达时按 Android 端无新版本分支处理
    this.getUIContext().getPromptAction().showToast({ message: '当前已经是最新版本' });
  }

  @Builder
  settingDivider() {
    Divider()
      .color($r('app.color.menu_divider'))
      .strokeWidth(0.5)
      .width('100%')
      .margin({ left: 12 })
  }

  @Builder
  arrowIcon() {
    Image($r('app.media.arrow_right'))
      .width(16)
      .height(16)
  }

  build() {
    Stack() {
      Column() {
      TitleBar({ title: '设置', showBack: true })

      Scroll() {
        Column() {
          // 组间空隙 12vp(px24/2)
          Row()
            .height(12)

          // 检测更新
          Row() {
            Text('检测更新')
              .fontSize(16)
              .fontColor($r('app.color.common_color_1'))
              .layoutWeight(1)
            this.arrowIcon()
          }
          .width('100%')
          .height(48)
          .padding({ left: 12, right: 12 })
          .alignItems(VerticalAlign.Center)
          .backgroundColor($r('app.color.white'))
          .onClick(() => {
            this.checkUpdate();
          })

          this.settingDivider()

          // 清除缓存 + 缓存大小
          Row() {
            Text('清除缓存')
              .fontSize(16)
              .fontColor($r('app.color.common_color_1'))
              .layoutWeight(1)
            Text(this.cacheSize)
              .fontSize(16)
              .fontColor($r('app.color.blue_default'))
              .margin({ right: 15 })
            this.arrowIcon()
          }
          .width('100%')
          .height(48)
          .padding({ left: 12, right: 12 })
          .alignItems(VerticalAlign.Center)
          .backgroundColor($r('app.color.white'))
          .onClick(() => {
            this.clearCache();
          })

          this.settingDivider()

          // 字体大小
          Row() {
            Text('字体大小')
              .fontSize(16)
              .fontColor($r('app.color.common_color_1'))
              .layoutWeight(1)
            this.arrowIcon()
          }
          .width('100%')
          .height(48)
          .padding({ left: 12, right: 12 })
          .alignItems(VerticalAlign.Center)
          .backgroundColor($r('app.color.white'))
          .onClick(() => {
            router.pushUrl({ url: 'pages/FontSizePage' });
          })

          this.settingDivider()

          // 推送设置 + Switch
          Row() {
            Text('推送设置')
              .fontSize(16)
              .fontColor($r('app.color.common_color_1'))
              .layoutWeight(1)
            Toggle({ type: ToggleType.Switch, isOn: this.pushEnabled })
              .selectedColor($r('app.color.blue_default'))
              .switchPointColor($r('app.color.white'))
              .onChange((isOn: boolean) => {
                this.pushEnabled = isOn;
              })
          }
          .width('100%')
          .height(48)
          .padding({ left: 12, right: 12 })
          .alignItems(VerticalAlign.Center)
          .backgroundColor($r('app.color.white'))

          this.settingDivider()

          // [W22 launch-chain] 手势密码行（源码 llGesturePwdLayout，SettingActivity L452
          // setVisibility(0) 恒可见 + L416 setOnClickListener(new h())）
          Row() {
            Text('手势密码')
              .fontSize(16)
              .fontColor($r('app.color.common_color_1'))
              .layoutWeight(1)
            this.arrowIcon()
          }
          .width('100%')
          .height(48)
          .padding({ left: 12, right: 12 })
          .alignItems(VerticalAlign.Center)
          .backgroundColor($r('app.color.white'))
          .onClick(() => {
            this.onGestureRow();
          })

          // 组间空隙 12vp
          Row()
            .height(12)

          // 服务协议
          Row() {
            Text('服务协议')
              .fontSize(16)
              .fontColor($r('app.color.common_color_1'))
              .layoutWeight(1)
            this.arrowIcon()
          }
          .width('100%')
          .height(48)
          .padding({ left: 12, right: 12 })
          .alignItems(VerticalAlign.Center)
          .backgroundColor($r('app.color.white'))
          .onClick(() => {
            router.pushUrl({
              url: 'pages/PrivacyTextPage',
              params: { type: 'service' }
            });
          })

          this.settingDivider()

          // 隐私政策
          Row() {
            Text('隐私政策')
              .fontSize(16)
              .fontColor($r('app.color.common_color_1'))
              .layoutWeight(1)
            this.arrowIcon()
          }
          .width('100%')
          .height(48)
          .padding({ left: 12, right: 12 })
          .alignItems(VerticalAlign.Center)
          .backgroundColor($r('app.color.white'))
          .onClick(() => {
            router.pushUrl({
              url: 'pages/PrivacyTextPage',
              params: { type: 'privacy' }
            });
          })

          this.settingDivider()

          // 关于我们 + 版本号
          Row() {
            Text('关于我们')
              .fontSize(16)
              .fontColor($r('app.color.common_color_1'))
              .layoutWeight(1)
            Text('V1.0.0')
              .fontSize(16)
              .fontColor($r('app.color.blue_default'))
              .margin({ right: 15 })
            this.arrowIcon()
          }
          .width('100%')
          .height(48)
          .padding({ left: 12, right: 12 })
          .alignItems(VerticalAlign.Center)
          .backgroundColor($r('app.color.white'))
          .onClick(() => {
            router.pushUrl({ url: 'pages/AboutPage' });
          })
        }
        .width('100%')
      }
      .width('100%')
      .layoutWeight(1)
      .scrollBar(BarState.Off)
      .align(Alignment.Top)
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.common_color_6'))

    // [W22-review 修复] 弹窗层条件挂载（替代常驻 .overlay，见 gesturePwdDialog 注释）
    if (this.showGesturePwdDialog) {
      this.gesturePwdDialog()
    }
    }
  }
}
