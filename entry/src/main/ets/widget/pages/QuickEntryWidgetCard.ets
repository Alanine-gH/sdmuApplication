@Entry
@Component
struct QuickEntryWidgetCard {
  @LocalStorageProp('cardTitle') cardTitle: string = '校园快捷入口';

  @Builder
  entryTile(icon: string, label: string, bg: string, targetPage: string, yyid: string = '', title: string = '') {
    Column() {
      Text(icon)
        .fontSize(18)
      Text(label)
        .fontSize(11)
        .fontColor('#333333')
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .margin({ top: 3 })
    }
    .layoutWeight(1)
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .backgroundColor(bg)
    .borderRadius(8)
    .onClick(() => {
      if (yyid !== '') {
        postCardAction(this, {
          action: 'router',
          abilityName: 'EntryAbility',
          params: {
            targetPage: targetPage,
            yyid: yyid,
            title: title
          }
        });
      } else {
        postCardAction(this, {
          action: 'router',
          abilityName: 'EntryAbility',
          params: {
            targetPage: targetPage
          }
        });
      }
    })
  }

  build() {
    Column() {
      Text(this.cardTitle)
        .fontSize(12)
        .fontWeight(FontWeight.Bold)
        .fontColor('#333333')
        .width('100%')
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .margin({ bottom: 6 })

      Column({ space: 6 }) {
        Row({ space: 6 }) {
          this.entryTile('💳', '一卡通', '#FFF5F5', 'pages/LightAppPage', 'ewm', '一卡通')
          this.entryTile('📋', '待办', '#F5F8FF', 'pages/TodoPage')
        }
        .width('100%')
        .layoutWeight(1)

        Row({ space: 6 }) {
          this.entryTile('📅', '课表', '#F3FBF6', 'pages/SchedulePage')
          this.entryTile('🧾', '发票', '#FFF9EE', 'pages/ReceiptAssistPage')
        }
        .width('100%')
        .layoutWeight(1)
      }
      .width('100%')
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .padding(10)
    .backgroundColor('#FFFFFF')
  }
}
