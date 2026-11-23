@Entry
@Component
struct QuickEntryWidgetCard {
  @LocalStorageProp('cardTitle') cardTitle: string = '校园快捷入口';

  build() {
    Column() {
      Text(this.cardTitle)
        .fontSize(13)
        .fontWeight(FontWeight.Bold)
        .fontColor('#333333')
        .width('100%')
        .margin({ bottom: 8 })

      Row() {
        Column() {
          Text('💳')
            .fontSize(20)
          Text('一卡通')
            .fontSize(11)
            .fontColor('#333333')
            .margin({ top: 4 })
        }
        .layoutWeight(1)
        .height('100%')
        .justifyContent(FlexAlign.Center)
        .backgroundColor('#FFF5F5')
        .borderRadius(8)
        .margin({ right: 6 })
        .onClick(() => {
          postCardAction(this, {
            action: 'router',
            abilityName: 'EntryAbility',
            params: {
              targetPage: 'pages/LightAppPage',
              yyid: 'ewm',
              title: '一卡通'
            }
          });
        })

        Column() {
          Text('📋')
            .fontSize(20)
          Text('待办')
            .fontSize(11)
            .fontColor('#333333')
            .margin({ top: 4 })
        }
        .layoutWeight(1)
        .height('100%')
        .justifyContent(FlexAlign.Center)
        .backgroundColor('#F5F8FF')
        .borderRadius(8)
        .onClick(() => {
          postCardAction(this, {
            action: 'router',
            abilityName: 'EntryAbility',
            params: {
              targetPage: 'pages/TodoPage'
            }
          });
        })
      }
      .width('100%')
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .padding(12)
    .backgroundColor('#FFFFFF')
  }
}
