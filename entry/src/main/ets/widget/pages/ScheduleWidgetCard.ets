@Entry
@Component
struct ScheduleWidgetCard {
  @LocalStorageProp('title') title: string = '今日课表';
  @LocalStorageProp('subtitle') subtitle: string = '点击查看完整课表';

  build() {
    Column() {
      Row() {
        Text('📅 ' + this.title)
          .fontSize(14)
          .fontWeight(FontWeight.Bold)
          .fontColor('#97000C')
          .maxLines(1)
        Blank()
        Text('山管')
          .fontSize(11)
          .fontColor('#999999')
      }
      .width('100%')

      Column() {
        Text(this.subtitle)
          .fontSize(12)
          .fontColor('#333333')
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        Text('点击直达课表页')
          .fontSize(11)
          .fontColor('#666666')
          .margin({ top: 4 })
      }
      .width('100%')
      .layoutWeight(1)
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .height('100%')
    .padding(12)
    .backgroundColor('#FFFFFF')
    .onClick(() => {
      postCardAction(this, {
        action: 'router',
        abilityName: 'EntryAbility',
        params: {
          targetPage: 'pages/SchedulePage'
        }
      });
    })
  }
}
