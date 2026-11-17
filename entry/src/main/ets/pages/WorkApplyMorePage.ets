import { TitleBar } from '../components/TitleBar';

class MoreAppItem {
  id: string = '';
  name: string = '';
  icon: Resource = $r('app.media.mobile_campus_oa_workapply');

  constructor(id: string, name: string, icon: Resource) {
    this.id = id;
    this.name = name;
    this.icon = icon;
  }
}

/**
 * 审批更多页 — 1:1 复刻 mobile_campus_oa_activity_workapply_more.xml：
 * toolbar + AutoGridView(白底 padL10 padT12.5 padR10 padB12 4列 水平间距16 垂直间距10)
 * 每项：图标 + 名称
 */
@Entry
@Component
struct WorkApplyMorePage {
  @State items: MoreAppItem[] = [
    new MoreAppItem('a1', '通知公告', $r('app.media.mobile_campus_oa_workapply')),
    new MoreAppItem('a2', '呈批件', $r('app.media.mobile_campus_oa_word')),
    new MoreAppItem('a3', '收文', $r('app.media.mobile_campus_oa_document')),
    new MoreAppItem('a4', '请假申请', $r('app.media.mobile_campus_oa_apply')),
    new MoreAppItem('a5', '出差申请', $r('app.media.mobile_campus_oa_apply')),
    new MoreAppItem('a6', '报销申请', $r('app.media.mobile_campus_oa_choose')),
    new MoreAppItem('a7', '会议室预约', $r('app.media.mobile_campus_meeting')),
    new MoreAppItem('a8', '用车申请', $r('app.media.mobile_campus_oa_edit'))
  ];

  private toast(name: string): void {
    this.getUIContext().getPromptAction().showToast({ message: name });
  }

  build() {
    Column() {
      TitleBar({ title: '更多', showBack: true })

      Grid() {
        ForEach(this.items, (item: MoreAppItem) => {
          GridItem() {
            Column() {
              Image(item.icon)
                .width(48)
                .height(48)
                .objectFit(ImageFit.Contain)
              Text(item.name)
                .fontSize(14)
                .fontColor($r('app.color.common_color_1'))
                .margin({ top: 6 })
            }
            .alignItems(HorizontalAlign.Center)
            .width('100%')
            .onClick(() => {
              this.toast(item.name);
            })
          }
        }, (item: MoreAppItem) => item.id)
      }
      .columnsTemplate('1fr 1fr 1fr 1fr')
      .columnsGap(16)
      .rowsGap(10)
      .width('100%')
      .layoutWeight(1)
      .padding({ left: 10, top: 12.5, right: 10, bottom: 12 })
      .backgroundColor($r('app.color.white'))
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.white'))
  }
}
