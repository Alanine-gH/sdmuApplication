import { TitleBar } from '../components/TitleBar';

/**
 * 课表登录页 — 复刻 timetable/TimeTableLoginActivity
 * 说明：原生包 经 360 加固（源码 仅 stub），res/layout 中不存在 timetable_login 专属布局，
 * 依据桌面小部件登录入口（desk_widget_timetable_login / no_login="请先登录"）与
 * 通用登录表单（timetable 主题色 timetable_bg / timetable_text）1:1 重建：
 * 结构：LinearLayout(#F2F2F2) + toolbar_normal("课表登录")
 *   + 登录卡（round_shape_timetable_bg 圆角6vp 白色60%）：课表图标48x48 + "请先登录" 15fp timetable_text
 *     + 学号/密码输入行 48vp(px96/2) + 登录按钮 40vp(px80/2) 圆角4 #1B68B6
 *
 * 数据源：无服务器接口 — ApiService 未提供教务系统登录端点，提交为本地模拟，未接 ApiService。
 */
@Entry
@Component
struct TimeTableLoginPage {
  @State schoolName: string = '山东管理学院';
  @State userId: string = '20230001';
  @State password: string = '';
  @State showPassword: boolean = false;

  private submit(): void {
    if (this.userId === '') {
      this.getUIContext().getPromptAction().showToast({ message: '请输入学号' });
      return;
    }
    if (this.password === '') {
      this.getUIContext().getPromptAction().showToast({ message: '请输入密码' });
      return;
    }
    this.getUIContext().getPromptAction().showToast({ message: '登录成功，正在导入课表' });
  }

  build() {
    Column() {
      TitleBar({ title: '课表登录', showBack: true })

      Stack() {
        Column()
          .width('100%')
          .height('100%')
          .backgroundColor($r('app.color.common_color_6'))

        // 登录卡：round_shape_timetable_bg 圆角6vp 底色 timetable_bg(#60FFFFFF)
        Column() {
          Image($r('app.media.mobile_campus_timetable_ic_widget_timetable'))
            .width(48)
            .height(48)
          Text('请先登录')
            .fontSize(15)
            .fontColor($r('app.color.timetable_text'))
            .margin({ top: 12 })

          // 学号输入行 高48vp(px96/2)
          Row() {
            Text('学号')
              .fontSize(16)
              .fontColor($r('app.color.timetable_text'))
              .width(60)
            TextInput({ placeholder: '请输入学号', text: this.userId })
              .fontSize(16)
              .fontColor($r('app.color.timetable_text'))
              .placeholderColor($r('app.color.edit_hint_color'))
              .placeholderFont({ size: 16 })
              .height(48)
              .backgroundColor(Color.Transparent)
              .padding(0)
              .layoutWeight(1)
              .onChange((value: string) => {
                this.userId = value;
              })
          }
          .width('100%')
          .height(48)
          .alignItems(VerticalAlign.Center)
          .margin({ top: 24 })

          Divider()
            .color($r('app.color.common_color_5'))
            .strokeWidth(0.5)

          // 密码输入行
          Row() {
            Text('密码')
              .fontSize(16)
              .fontColor($r('app.color.timetable_text'))
              .width(60)
            TextInput({ placeholder: '请输入密码', text: this.password })
              .fontSize(16)
              .fontColor($r('app.color.timetable_text'))
              .placeholderColor($r('app.color.edit_hint_color'))
              .placeholderFont({ size: 16 })
              .type(this.showPassword ? InputType.Normal : InputType.Password)
              .height(48)
              .backgroundColor(Color.Transparent)
              .padding(0)
              .layoutWeight(1)
              .onChange((value: string) => {
                this.password = value;
              })
            Text(this.showPassword ? '隐藏' : '显示')
              .fontSize(14)
              .fontColor($r('app.color.common_color_3'))
              .padding({ left: 8, right: 4 })
              .onClick(() => {
                this.showPassword = !this.showPassword;
              })
          }
          .width('100%')
          .height(48)
          .alignItems(VerticalAlign.Center)

          Divider()
            .color($r('app.color.common_color_5'))
            .strokeWidth(0.5)

          // 登录按钮 高40vp(px80/2) 圆角4vp(px8/2) #1B68B6
          Text('登录')
            .fontSize(16)
            .fontColor($r('app.color.white'))
            .textAlign(TextAlign.Center)
            .width('100%')
            .height(40)
            .backgroundColor($r('app.color.mobile_campus_schedule_confirm_blue'))
            .borderRadius(4)
            .margin({ top: 24 })
            .onClick(() => {
              this.submit();
            })
        }
        .width('100%')
        .padding(12)
        .backgroundColor($r('app.color.timetable_bg'))
        .borderRadius(6)
        .margin({ left: 12, right: 12 })
      }
      .width('100%')
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.common_color_6'))
  }
}
