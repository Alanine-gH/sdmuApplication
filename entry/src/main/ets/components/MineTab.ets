import { router } from '@kit.ArkUI';
import { PreferencesUtil } from '../data/PreferencesUtil';
import { Constants } from '../data/Constants';

/**
 * 我的 Tab：用户头部 + 功能入口列表 + 退出登录。
 */
@Component
export struct MineTab {
  @State userName: string = '张明理';
  @State userNo: string = '20230001';

  aboutToAppear(): void {
    PreferencesUtil.getString(Constants.KEY_USER_NAME, '张明理')
      .then((name: string) => {
        this.userName = name;
      });
    PreferencesUtil.getString(Constants.KEY_USER_ID, '20230001')
      .then((id: string) => {
        this.userNo = id;
      });
  }

  private async logout(): Promise<void> {
    await PreferencesUtil.clear();
    this.getUIContext().getPromptAction().showToast({ message: '已退出登录' });
    router.replaceUrl({ url: 'pages/LoginPage' });
  }

  @Builder
  menuRow(icon: string, label: string, target: string) {
    Row() {
      Text(icon)
        .fontSize(20)
        .width(36)
      Text(label)
        .fontSize(15)
        .fontColor($r('app.color.sdmu_text_primary'))
        .layoutWeight(1)
        .margin({ left: 8 })
      Text('＞')
        .fontSize(14)
        .fontColor($r('app.color.sdmu_text_hint'))
    }
    .width('100%')
    .height(52)
    .padding({ left: 16, right: 16 })
    .backgroundColor($r('app.color.sdmu_card_bg'))
    .border({ width: { bottom: 1 }, color: $r('app.color.sdmu_divider') })
    .onClick(() => {
      router.pushUrl({ url: target });
    })
  }

  build() {
    Column() {
      // 头部
      Row({ space: 14 }) {
        Text('山')
          .fontSize(28)
          .fontColor(Color.White)
          .width(64)
          .height(64)
          .textAlign(TextAlign.Center)
          .backgroundColor('#33FFFFFF')
          .borderRadius(32)
        Column({ space: 6 }) {
          Text(this.userName)
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor(Color.White)
          Text('学号: ' + this.userNo)
            .fontSize(13)
            .fontColor('#E6FFFFFF')
        }
        .alignItems(HorizontalAlign.Start)
      }
      .width('100%')
      .padding({ left: 24, top: 40, bottom: 30 })
      .backgroundColor($r('app.color.sdmu_primary'))
      .alignItems(VerticalAlign.Center)

      // 功能列表
      List() {
        ListItem() {
          this.menuRow('👤', '个人资料', 'pages/PersonalDetailPage')
        }
        ListItem() {
          this.menuRow('📅', '我的课表', 'pages/SchedulePage')
        }
        ListItem() {
          this.menuRow('📊', '我的成绩', 'pages/ScorePage')
        }
        ListItem() {
          this.menuRow('🕐', '考试安排', 'pages/ExamPage')
        }
        ListItem() {
          this.menuRow('👥', '通讯录', 'pages/ContactPage')
        }
        ListItem() {
          this.menuRow('⚙️', '设置', 'pages/SettingPage')
        }
      }
      .width('100%')
      .layoutWeight(1)
      .backgroundColor($r('app.color.sdmu_card_bg'))
      .margin({ top: 10 })
      .borderRadius({ topLeft: 12, topRight: 12 })

      // 退出登录
      Button('退出登录')
        .width('90%')
        .height(44)
        .fontSize(16)
        .fontColor($r('app.color.sdmu_danger'))
        .backgroundColor($r('app.color.sdmu_card_bg'))
        .borderRadius(22)
        .margin({ bottom: 20 })
        .onClick(() => {
          this.logout();
        })
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.sdmu_bg'))
  }
}
