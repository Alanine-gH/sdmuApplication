import { TitleBar } from '../components/TitleBar';

/**
 * 账号绑定页（QQ/微信绑定） — 1:1 复刻 my_activity_accountbind.xml
 * 结构：ScrollView(common_color_6) + toolbar_normal
 *   + 学号行(图标52px=26vp + 学号 + 值)
 *   + 手机号行(图标46px=23vp + 手机号 + 更换 + 箭头20px=10vp)
 *   + 提示文字(TextSize4.Color3=14fp #999)
 *   + QQ/微信/支付宝行(图标52px=26vp + 名称 + IOSToggleButton)
 * 行内边距：H 15vp(px30/2) V 12vp(px24/2)；Toggle: onColor=ybg_blue
 */
interface BindAccount {
  key: string;
  icon: Resource;
  name: string;
  bound: boolean;
}

@Entry
@Component
struct ChangeQqWechatPage {
  @State studentNumber: string = '2023010101';
  @State phoneNumber: string = '138****6688';
  @State bindAccounts: BindAccount[] = [
    { key: 'qq', icon: $r('app.media.qq'), name: 'QQ账号', bound: false },
    { key: 'wechat', icon: $r('app.media.wechat'), name: '微信账号', bound: true },
    { key: 'alipay', icon: $r('app.media.alipay'), name: '支付宝账号', bound: false }
  ];

  @Builder
  greyThinDivider() {
    Divider()
      .color($r('app.color.divider_grey'))
      .strokeWidth(0.5)
      .width('100%')
  }

  build() {
    Column() {
      TitleBar({ title: '账号绑定', showBack: true })

      Scroll() {
        Column() {
          // 学号行
          Row() {
            Image($r('app.media.xuehao'))
              .width(26)
              .height(26)
            Text('学号')
              .fontSize(15)
              .fontColor($r('app.color.common_color_1'))
              .margin({ left: 15 })
            Text(this.studentNumber)
              .fontSize(15)
              .fontColor($r('app.color.common_color_1'))
              .maxLines(1)
              .layoutWeight(1)
              .margin({ left: 6 })
          }
          .width('100%')
          .padding({ left: 15, right: 15, top: 12, bottom: 12 })
          .alignItems(VerticalAlign.Center)
          .backgroundColor($r('app.color.ybg_white'))

          this.greyThinDivider()

          // 手机号行
          Row() {
            Image($r('app.media.cellphone'))
              .width(23)
              .height(23)
            Text('手机号')
              .fontSize(15)
              .fontColor($r('app.color.common_color_1'))
              .margin({ left: 15 })
            Text(this.phoneNumber)
              .fontSize(15)
              .fontColor($r('app.color.common_color_1'))
              .layoutWeight(1)
              .margin({ left: 4 })
            Text('更换')
              .fontSize(14)
              .fontColor($r('app.color.common_color_3'))
              .padding({ left: 15, top: 7, bottom: 7 })
            Image($r('app.media.arrow_right'))
              .width(10)
              .height(10)
              .margin({ left: 6 })
          }
          .width('100%')
          .padding({ left: 15, right: 15, top: 12, bottom: 12 })
          .alignItems(VerticalAlign.Center)
          .backgroundColor($r('app.color.ybg_white'))

          this.greyThinDivider()

          // 第三方绑定提示
          Text('绑定第三方账号，可以使用第三方账号快捷登录')
            .fontSize(14)
            .fontColor($r('app.color.common_color_3'))
            .width('100%')
            .padding({ top: 12, bottom: 12 })
            .margin({ left: 15 })

          // QQ / 微信 / 支付宝 绑定行
          ForEach(this.bindAccounts, (item: BindAccount, index: number) => {
            Row() {
              Image(item.icon)
                .width(26)
                .height(26)
              Text(item.name)
                .fontSize(15)
                .fontColor($r('app.color.common_color_1'))
                .layoutWeight(1)
                .margin({ left: 15 })
              Toggle({ type: ToggleType.Switch, isOn: item.bound })
                .selectedColor($r('app.color.ybg_blue'))
                .width(51)
                .onChange((isOn: boolean) => {
                  this.bindAccounts[index].bound = isOn;
                })
            }
            .width('100%')
            .padding({ left: 15, right: 15, top: 10, bottom: 10 })
            .alignItems(VerticalAlign.Center)
            .backgroundColor($r('app.color.ybg_white'))

            if (index < this.bindAccounts.length - 1) {
              this.greyThinDivider()
            }
          }, (item: BindAccount): string => item.key)
        }
      }
      .scrollBar(BarState.Off)
      .width('100%')
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.common_color_6'))
  }
}
