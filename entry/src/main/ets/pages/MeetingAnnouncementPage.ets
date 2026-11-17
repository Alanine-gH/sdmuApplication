import { TitleBar } from '../components/TitleBar';

/**
 * 会议公告 — 1:1 复刻（px_to_dip_N = N/2 vp, px_to_sp_N = N/2 fp）：
 * mobile_campus_meeting_activity_announcement.xml：toolbar + mListView 白底（divider common_color_3）
 * mobile_campus_meeting_widget_announcement_edit.xml（公告编辑卡）：
 *   顶部 12vp common_color_6 分隔 + 白底 padding 12 paddingBottom 13：
 *   tvTitle 18.5fp 主色 居中 高 64；remind 框 13fp #333 居中 高 60 圆角 marginBottom 16；
 *   etContent 16fp 高 103 圆角边框 padding 8/10 hint "输入公告内容..." marginBottom 16；
 *   tvSubmit 17fp 白字 高 44 确定按钮
 */

interface AnnouncementItem {
  annId: string;
  sender: string;
  content: string;
  time: string;
}

@Entry
@Component
struct MeetingAnnouncementPage {
  @State annInput: string = '';
  @State announcements: AnnouncementItem[] = [
    {
      annId: 'a1', sender: '王建国',
      content: '请各位参会人员提前10分钟入场，会议期间请将手机调至静音。',
      time: '11-17 08:30'
    },
    {
      annId: 'a2', sender: '李梅',
      content: '会议材料已上传至群文件，请提前查阅。',
      time: '11-17 08:45'
    }
  ];

  private submitAnnouncement(): void {
    if (this.annInput === '') {
      this.getUIContext().getPromptAction().showToast({ message: '请输入公告内容' });
      return;
    }
    const item: AnnouncementItem = {
      annId: 'a' + (this.announcements.length + 1).toString(),
      sender: '我',
      content: this.annInput,
      time: '刚刚'
    };
    this.announcements.push(item);
    this.annInput = '';
    this.getUIContext().getPromptAction().showToast({ message: '公告已发送给参会人员' });
  }

  build() {
    Column() {
      TitleBar({ title: '会议公告', showBack: true })

      List() {
        // widget_announcement_edit 编辑卡
        ListItem() {
          Column() {
            Divider()
              .color($r('app.color.common_color_6'))
              .strokeWidth(12)
              .width('100%')

            Column() {
              Text('发送公告')
                .fontSize(18)
                .fontColor($r('app.color.mobile_campus_primary_color_default'))
                .textAlign(TextAlign.Center)
                .width('100%')
                .height(64)

              Text('在这里您可以发送公告给所有参会人员，\n参会人员会收到公告。')
                .fontSize(13)
                .fontColor($r('app.color.common_color_1'))
                .textAlign(TextAlign.Center)
                .width('100%')
                .height(60)
                .backgroundColor($r('app.color.mobile_campus_exam_card_bg'))
                .borderRadius(6)
                .margin({ bottom: 16 })

              TextArea({ text: this.annInput, placeholder: '输入公告内容...' })
                .fontSize(16)
                .fontColor($r('app.color.common_color_1'))
                .placeholderColor($r('app.color.common_color_35'))
                .placeholderFont({ size: 16 })
                .backgroundColor($r('app.color.white'))
                .padding({ left: 10, right: 10, top: 8, bottom: 8 })
                .width('100%')
                .height(103)
                .borderRadius(6)
                .border({ width: 1, color: $r('app.color.common_color_36') })
                .margin({ bottom: 16 })
                .onChange((value: string) => {
                  this.annInput = value;
                })

              Text('确定')
                .fontSize(17)
                .fontColor($r('app.color.white'))
                .textAlign(TextAlign.Center)
                .width('100%')
                .height(44)
                .backgroundColor($r('app.color.mobile_campus_primary_color_default'))
                .borderRadius(22)
                .onClick(() => {
                  this.submitAnnouncement();
                })
            }
            .width('100%')
            .padding({ left: 12, right: 12, bottom: 13 })
            .backgroundColor($r('app.color.white'))
          }
          .width('100%')
          .backgroundColor($r('app.color.white'))
        }

        // 公告列表
        ForEach(this.announcements, (item: AnnouncementItem) => {
          ListItem() {
            Column() {
              Row() {
                Text(item.sender)
                  .fontSize(14)
                  .fontColor($r('app.color.mobile_campus_primary_color_default'))
                Blank()
                Text(item.time)
                  .fontSize(12)
                  .fontColor($r('app.color.common_color_3'))
              }
              .width('100%')

              Text(item.content)
                .fontSize(15)
                .fontColor($r('app.color.common_color_1'))
                .width('100%')
                .margin({ top: 6 })
            }
            .width('100%')
            .padding(12)
            .backgroundColor($r('app.color.white'))
            .border({ width: { bottom: 0.5 }, color: { bottom: $r('app.color.common_color_3') } })
          }
        }, (item: AnnouncementItem) => item.annId)
      }
      .width('100%')
      .layoutWeight(1)
      .backgroundColor($r('app.color.white'))
      .scrollBar(BarState.Off)
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.white'))
  }
}
