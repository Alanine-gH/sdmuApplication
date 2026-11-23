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
        .width(3)
        .height(22)
        .borderRadius(1.5)
        .backgroundColor('#97000C')
        .margin({ right: 6 })
      Column() {
        Text(name)
          .fontSize(12)
          .fontWeight(FontWeight.Medium)
          .fontColor('#222222')
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        if (info !== '') {
          Text(info)
            .fontSize(10)
            .fontColor('#666666')
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .margin({ top: 4 })
  }

  build() {
    Column() {
      Row() {
        Text('📅 ' + this.title)
          .fontSize(13)
          .fontWeight(FontWeight.Bold)
          .fontColor('#97000C')
          .maxLines(1)
          .layoutWeight(1)
        Text('山管')
          .fontSize(10)
          .fontColor('#999999')
      }
      .width('100%')

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
            .fontSize(12)
            .fontColor('#333333')
            .maxLines(2)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
          Text('打开课表后自动同步今日课程')
            .fontSize(10)
            .fontColor('#888888')
            .margin({ top: 4 })
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Start)
      }
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
