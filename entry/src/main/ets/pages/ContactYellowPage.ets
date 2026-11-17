interface YellowEntry {
  id: string;
  name: string;
  phone: string;
  email: string;
}

interface YellowCategory {
  id: string;
  title: string;
  entries: YellowEntry[];
}

/**
 * 校园黄页页 — 1:1 复刻：
 * mobile_campus_contact_activity_yellow.xml：toolbar_normal + FrameLayout 容器
 * mobile_campus_contact_fragment_yellow.xml：ExpandableListView(透明背景 无分组指示)
 * mobile_campus_contact_view_yellow_group.xml：分组标题 17fp common_color_1 高48(px_to_dip_96) padH12 + arrow_right + 0.5分隔线
 * mobile_campus_contact_view_yellow_child.xml：白底 padL12 minHeight50 图标36vp 名16fp粗体(mt4 mb8)
 *   电话/邮箱行 14fp mobile_campus_contact 图标+2间距 右侧呼叫图标 mr23 + 0.5分隔线
 */
@Entry
@Component
struct ContactYellowPage {
  @State categories: YellowCategory[] = [];
  @State expandedId: string = '';

  aboutToAppear(): void {
    const cat1: YellowCategory = {
      id: 'y1', title: '行政机构',
      entries: [
        { id: 'y1-1', name: '学校办公室', phone: '0531-89636001', email: 'bgs@sdmu.edu.cn' },
        { id: 'y1-2', name: '教务处', phone: '0531-89636002', email: 'jwc@sdmu.edu.cn' },
        { id: 'y1-3', name: '学生工作处', phone: '0531-89636003', email: 'xsc@sdmu.edu.cn' }
      ]
    };
    const cat2: YellowCategory = {
      id: 'y2', title: '教学单位',
      entries: [
        { id: 'y2-1', name: '应用英语学院', phone: '0531-89636101', email: 'yyxy@sdmu.edu.cn' },
        { id: 'y2-2', name: '国际商学院', phone: '0531-89636102', email: 'gjsxy@sdmu.edu.cn' },
        { id: 'y2-3', name: '信息工程学院', phone: '0531-89636103', email: 'xxgc@sdmu.edu.cn' }
      ]
    };
    const cat3: YellowCategory = {
      id: 'y3', title: '直属单位',
      entries: [
        { id: 'y3-1', name: '图书馆', phone: '0531-89636004', email: 'lib@sdmu.edu.cn' },
        { id: 'y3-2', name: '校医院', phone: '0531-89636120', email: 'xyy@sdmu.edu.cn' }
      ]
    };
    this.categories = [cat1, cat2, cat3];
    if (this.categories.length > 0) {
      this.expandedId = this.categories[0].id;
    }
  }

  private toggle(id: string): void {
    if (this.expandedId === id) {
      this.expandedId = '';
    } else {
      this.expandedId = id;
    }
  }

  private toast(msg: string): void {
    this.getUIContext().getPromptAction().showToast({ message: msg });
  }

  build() {
    Column() {
      // mobile_campus_contact_activity_yellow.xml: toolbar_normal
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
          Text('校园黄页')
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
        ForEach(this.categories, (cat: YellowCategory) => {
          // mobile_campus_contact_view_yellow_group.xml
          ListItem() {
            Column() {
              Row() {
                Text(cat.title)
                  .fontSize(17)
                  .fontColor($r('app.color.common_color_1'))
                  .width('100%')
                  .height(48)
                  .padding({ left: 12, right: 12 })
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
                Image($r('app.media.arrow_right'))
                  .width(16)
                  .height(16)
                  .margin({ right: 12 })
              }
              .width('100%')
              .alignItems(VerticalAlign.Center)
              .backgroundColor($r('app.color.white'))

              Divider()
                .color($r('app.color.common_color_5'))
                .strokeWidth(1)
                .width('100%')
            }
            .width('100%')
          }
          .onClick(() => {
            this.toggle(cat.id);
          })

          if (this.expandedId === cat.id) {
            ForEach(cat.entries, (entry: YellowEntry) => {
              ListItem() {
                this.yellowChildRow(entry)
              }
            }, (entry: YellowEntry) => entry.id)
          }
        }, (cat: YellowCategory) => cat.id)
      }
      .width('100%')
      .layoutWeight(1)
      .scrollBar(BarState.Off)
      .backgroundColor($r('app.color.mobile_campus_bg_color'))
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.mobile_campus_bg_color'))
  }

  // mobile_campus_contact_view_yellow_child.xml
  @Builder
  yellowChildRow(entry: YellowEntry) {
    Column() {
      Row() {
        Text(entry.name.substring(0, 1))
          .fontSize(18.5)
          .fontColor($r('app.color.ybg_white'))
          .width(36)
          .height(36)
          .textAlign(TextAlign.Center)
          .backgroundColor($r('app.color.blue_default'))
          .borderRadius(18)

        Column() {
          Text(entry.name)
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
            Text(entry.phone)
              .fontSize(14)
              .fontColor($r('app.color.mobile_campus_contact'))
              .maxLines(1)
          }
          .margin({ bottom: 4 })

          Row() {
            Image($r('app.media.icon_yellow_page_email'))
              .width(12)
              .height(12)
              .margin({ right: 4 })
            Text(entry.email)
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
            this.toast('呼叫: ' + entry.phone);
          })
      }
      .width('100%')
      .padding({ left: 12, right: 0, top: 8, bottom: 8 })
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
