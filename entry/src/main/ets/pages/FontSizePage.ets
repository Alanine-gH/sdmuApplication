import { router } from '@kit.ArkUI';
import { TitleBar } from '../components/TitleBar';
import { PreferencesUtil } from '../data/PreferencesUtil';

/**
 * 字体大小设置页 — 1:1 翻译 FontSizeSettingActivity.java(122行)，HAP 页名 FontSizePage（SettingPage 既有路由） + FontResizeView.java：
 *   - 档位 1..5（FontSizeHelper.e()=5），默认档 a()=4
 *   - 缩放 c(i)：1→0.9 / 2→1.05 / 3→1.25 / 4→1.35 / 5→1.5
 *   - 预览：setTextSize(c(n) * 20f)
 *   - 保存 M2()：档位相同 → toast"设置成功"；否则弹窗"新的字体大小需要重启应用才能生效"
 *     → 确认 → d.f(n)：preferences key="currentUserFontScale" + 重启应用
 * HAP 侧：保存 preferences + AppStorage('appFontScale')，提示用户手动重启以完全生效。
 */
const SCALE_TABLE: number[] = [0.9, 1.05, 1.25, 1.35, 1.5];
const KEY_FONT_SCALE: string = 'currentUserFontScale';

@Entry
@Component
struct FontSizePage {
  @State previewText: string = '校园资讯早知道，学习生活更轻松。';
  @State previewSize: number = 20;
  @State currentGrade: number = 4;
  private savedGrade: number = 4;

  aboutToAppear(): void {
    // FontSizeHelper.d()：读取持久化档位（默认 4）；PreferencesUtil 仅支持 string，存档位数字串
    PreferencesUtil.getString(KEY_FONT_SCALE, '4').then((raw: string) => {
      const n: number = Number(raw);
      const grade: number = (n >= 1 && n <= 5) ? Math.floor(n) : 4;
      this.currentGrade = grade;
      this.savedGrade = grade;
      this.previewSize = SCALE_TABLE[grade - 1] * 20;
    });
  }

  /** 源码 c 回调：n = i + 1，预览 setTextSize(c(n)*20f) */
  private onGradeChange(index: number): void {
    this.currentGrade = index + 1;
    this.previewSize = SCALE_TABLE[this.currentGrade - 1] * 20;
  }

  /** 源码 M2()：相同档位 → "设置成功"；否则弹窗确认后保存并提示重启 */
  private onSave(): void {
    if (this.currentGrade === this.savedGrade) {
      this.getUIContext().getPromptAction().showToast({ message: '设置成功' });
      return;
    }
    AlertDialog.show({
      message: '新的字体大小需要重启应用才能生效',
      primaryButton: {
        value: '取消',
        action: () => {
        }
      },
      secondaryButton: {
        value: '确定',
        action: () => {
          // 源码 d.f(n)：持久化档位（string 存储："1".."5"）
          PreferencesUtil.putString(KEY_FONT_SCALE, String(this.currentGrade));
          AppStorage.setOrCreate('appFontScale', SCALE_TABLE[this.currentGrade - 1]);
          this.savedGrade = this.currentGrade;
          this.getUIContext().getPromptAction().showToast({ message: '已保存，重启应用后生效' });
          // 源码行为：finishAllActivities + 重启 —— HAP 侧返回登录页由用户手动重进
          router.clear();
          router.replaceUrl({ url: 'pages/LoginPage' });
        }
      }
    });
  }

  build() {
    Column() {
      TitleBar({ title: '字体大小', showBack: true, rightText: '保存', onRightClick: (): void => this.onSave() })

      Column() {
        // 源码 tv_show 预览文本（右对齐，颜色 common_color_2）
        Text(this.previewText)
          .fontSize(this.previewSize)
          .fontColor($r('app.color.common_color_1'))
          .width('90%')
          .textAlign(TextAlign.End)
          .margin({ top: 40, bottom: 30 })

        // FontResizeView 滑条（5 档：小/标准/大/特大/超大）
        Row() {
          Text('小').fontSize(13).fontColor($r('app.color.common_color_3'))
          Slider({
            value: this.currentGrade,
            min: 1,
            max: 5,
            step: 1,
            style: SliderStyle.OutSet
          })
            .layoutWeight(1)
            .margin({ left: 10, right: 10 })
            .onChange((value: number, mode: SliderChangeMode) => {
              if (mode === SliderChangeMode.End || mode === SliderChangeMode.Click) {
                this.onGradeChange(Math.round(value) - 1);
              }
            })
          Text('大').fontSize(13).fontColor($r('app.color.common_color_3'))
        }
        .width('86%')
        .margin({ top: 20 })

        Text('当前缩放：' + SCALE_TABLE[this.currentGrade - 1].toFixed(2) + ' 倍')
          .fontSize(13)
          .fontColor($r('app.color.common_color_3'))
          .margin({ top: 26 })
      }
      .width('100%')
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
      .padding({ left: 20, right: 20 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.main_bg'))
  }
}
