interface YellowType {
  id: string;
  name: string;
  sub: string;
}

/**
 * 黄页分类页 — 1:1 复刻 contact_view_yellow_type.xml：
 * 白底 padL12 图标36vp(首字 ybg_white 18.5fp)
 * 名16fp粗体 black(mt4 mb8) 电话行14fp mobile_campus_contact 图标间距2
 * 右侧呼叫图标 mr23 + 0.5分隔线（结构同 yellow_child，由 ContactYellowTypeActivity 加载分类数据）
 */
@Entry
@Component
struct ContactYellowTypePage {
  @State types: YellowType[] = [];

  aboutToAppear(): void {
    this.types = [
      { id: 't1', name: '行政机构', sub: '{{PHONE_g7mj2twe}}' },
      { id: 't2', name: '教学单位', sub: '{{PHONE_g3hb3umx}}' },
      { id: 't3', name: '直属单位', sub: '{{PHONE_nkfytrwd}}' },
      { id: 't4', name: '后勤服务', sub: '{{PHONE_z2ceixzv}}' },
      { id: 't5', name: '学生服务', sub: '{{PHONE_twt6bsfb}}' }
    ];
  }

  private toast(msg: string): void {
    this.getUIContext().getPromptAction().showToast({ message: msg });
  }

  build() {
    Column() {
      // toolbar_normal
      Column() {
        Row() {
          Text('＜')
            .fontSize(16)
            .fontColor($r('app.color.common_color_1'))
            .width(40)
            .height('100%')
            .textAlign(TextAlign.Center)
            .margin({ left: 15 })
            .onClick(() => {
              this.getUIContext().getRouter().back();
            })
          Text('黄页分类')
            .fontSize(16)
            .fontColor($r('app.color.common_color_1'))
            .layoutWeight(1)
            .textAlign(TextAlign.Center)
            .maxLines(1)
          Blank().width(40)
        }
        .width('100%')
        .height(44)
        .alignItems(VerticalAlign.Center)
        .backgroundColor($r('app.color.main_bg'))

        Divider()
          .color($r('app.color.common_color_5'))
          .strokeWidth(0.5)
          .width('100%')
      }
      .width('100%')
      .height(45)
      .backgroundColor($r('app.color.main_bg'))

      List() {
        ForEach(this.types, (item: YellowType) => {
          ListItem() {
            this.yellowTypeRow(item)
          }
        }, (item: YellowType) => item.id)
      }
      .width('100%')
      .layoutWeight(1)
      .scrollBar(BarState.Off)
      .backgroundColor($r('app.color.white'))
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.white'))
  }

  // contact_view_yellow_type.xml
  @Builder
  yellowTypeRow(item: YellowType) {
    Column() {
      Row() {
        Text(item.name.substring(0, 1))
          .fontSize(18.5)
          .fontColor($r('app.color.ybg_white'))
          .width(36)
          .height(36)
          .textAlign(TextAlign.Center)
          .backgroundColor($r('app.color.blue_default'))
          .borderRadius(18)

        Column() {
          Text(item.name)
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor($r('app.color.black'))
            .margin({ top: 4, bottom: 8 })
            .maxLines(1)

          Row() {
            Image($r('app.media.icon_yellow_page_phone'))
              .width(12)
              .height(12)
              .margin({ right: 2 })
            Text(item.sub)
              .fontSize(14)
              .fontColor($r('app.color.mobile_campus_contact'))
              .maxLines(1)
          }
          .margin({ bottom: 4 })
        }
        .alignItems(HorizontalAlign.Start)
        .margin({ left: 12 })
        .layoutWeight(1)

        Image($r('app.media.mobile_campus_contact_call'))
          .width(18)
          .height(18)
          .margin({ right: 23 })
          .onClick(() => {
            this.toast('呼叫: ' + item.sub);
          })
      }
      .width('100%')
      .padding({ left: 12, top: 8, bottom: 8 })
      .alignItems(VerticalAlign.Center)
      .backgroundColor($r('app.color.white'))

      Divider()
        .color($r('app.color.common_color_5'))
        .strokeWidth(0.5)
        .width('100%')
    }
    .width('100%')
    .backgroundColor($r('app.color.white'))
  }
}
