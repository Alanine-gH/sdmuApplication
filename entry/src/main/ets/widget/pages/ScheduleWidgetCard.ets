@Entry
@Component
struct ScheduleWidgetCard {
  @LocalStorageProp('title') title: string = '今日课表';
  @LocalStorageProp('subtitle') subtitle: string = '点击查看完整课表';
  @LocalStorageProp('courseCount') courseCount: number = 0;
  @LocalStorageProp('c1Name') c1Name: string = '';
  @LocalStorageProp('c1Info') c1Info: string = '';
  @LocalStorageProp('c2Name') c2Name: string = '';
  @LocalStorageProp('c2Info') c2Info: string = '';
  @LocalStorageProp('c3Name') c3Name: string = '';
  @LocalStorageProp('c3Info') c3Info: string = '';
  @LocalStorageProp('c4Name') c4Name: string = '';
  @LocalStorageProp('c4Info') c4Info: string = '';

  @Builder
  courseItem(name: string, info: string) {
    Row() {
      Column()
        .width(4)
        .height(34)
        .borderRadius(2)
        .backgroundColor('#97000C')
        .margin({ right: 10 })
      Column() {
        Text(name)
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .fontColor('#222222')
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        if (info !== '') {
          Text(info)
            .fontSize(12)
            .fontColor('#666666')
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .margin({ top: 2 })
        }
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .padding({ top: 6, bottom: 6, left: 8, right: 8 })
    .backgroundColor('#F8F9FA')
    .borderRadius(8)
    .margin({ top: 8 })
  }

  build() {
    Column() {
      Row() {
        Text('📅 ' + this.title)
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor('#97000C')
          .maxLines(1)
          .layoutWeight(1)
        Text('山东管理学院')
          .fontSize(11)
          .fontColor('#999999')
      }
      .width('100%')
      .padding({ bottom: 6 })

      Divider().color('#EEEEEE').strokeWidth(0.5)

      if (this.courseCount > 0 && this.c1Name !== '') {
        Column() {
          this.courseItem(this.c1Name, this.c1Info)
          if (this.c2Name !== '') {
            this.courseItem(this.c2Name, this.c2Info)
          }
          if (this.c3Name !== '') {
            this.courseItem(this.c3Name, this.c3Info)
          }
          if (this.c4Name !== '') {
            this.courseItem(this.c4Name, this.c4Info)
          }
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Start)
      } else {
        Column() {
          Text(this.subtitle)
            .fontSize(14)
            .fontColor('#333333')
            .maxLines(2)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
          Text('打开课表后自动同步今日课程')
            .fontSize(12)
            .fontColor('#888888')
            .margin({ top: 6 })
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
      }
    }
    .width('100%')
    .height('100%')
    .padding(16)
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
