import { router } from '@kit.ArkUI';
import { TitleBar } from '../components/TitleBar';

/**
 * 听课详情 — 1:1 复刻 mobile_campus_supervise_layout_lecture_detail.xml
 * + layout_lecture_notify.xml（CardView 白底 radius 6，日程提醒单选组，添加听课按钮）
 * TextStyle1：14fp common_color_3；TextStyle2：14fp common_color_1
 */
class SuperviseNotifyOption {
  id: string;
  label: string;
  checked: boolean;

  constructor(id: string, label: string, checked: boolean) {
    this.id = id;
    this.label = label;
    this.checked = checked;
  }
}

@Entry
@Component
struct SuperviseLectureDetailPage {
  @State className: string = '高等数学（下）';
  @State teacherName: string = '张明';
  @State teacherNumber: string = '1020384';
  @State academyName: string = '数学与统计学院';
  @State weekText: string = '第12周';
  @State sectionText: string = '1-2节';
  @State locationText: string = '明德楼A302';
  @State listenTime: string = '';
  @State notifyOptions: SuperviseNotifyOption[] = [
    new SuperviseNotifyOption('no', '不提醒', true),
    new SuperviseNotifyOption('specific', '指定时间提醒', false)
  ];
  @State showSpecificTime: boolean = false;
  @State specificTime: string = '';

  private chooseNotifyOption(target: SuperviseNotifyOption): void {
    this.notifyOptions = this.notifyOptions.map((option: SuperviseNotifyOption): SuperviseNotifyOption => {
      return new SuperviseNotifyOption(option.id, option.label, option.id === target.id);
    });
    this.showSpecificTime = target.id === 'specific';
  }

  private addListen(): void {
    router.pushUrl({ url: 'pages/SuperviseAddPage' });
  }

  build() {
    Column() {
      TitleBar({ title: '听课详情', showBack: true })

      Scroll() {
        Column() {
          // 课程信息卡：白底，padding H12 V20
          Column() {
            Text(this.className)
              .fontSize(16)
              .fontColor($r('app.color.mobile_campus_primary_color_default'))
              .margin({ bottom: 22 })

            Row() {
              Row() {
                Text('任课教师')
                  .fontSize(14)
                  .fontColor($r('app.color.common_color_3'))
                Text(this.teacherName)
                  .fontSize(14)
                  .fontColor($r('app.color.common_color_1'))
              }
              .layoutWeight(1)

              Row() {
                Text('工号')
                  .fontSize(14)
                  .fontColor($r('app.color.common_color_3'))
                Text(this.teacherNumber)
                  .fontSize(14)
                  .fontColor($r('app.color.common_color_1'))
              }
              .layoutWeight(1)
            }
            .width('100%')

            Row() {
              Text('开课院系')
                .fontSize(14)
                .fontColor($r('app.color.common_color_3'))
              Text(this.academyName)
                .fontSize(14)
                .fontColor($r('app.color.common_color_1'))
            }
            .width('100%')
            .margin({ top: 12 })

            Divider()
              .color($r('app.color.common_color_5'))
              .strokeWidth(0.5)
              .width('100%')
              .margin({ top: 17, bottom: 17 })

            Row() {
              Text('开课周数')
                .fontSize(14)
                .fontColor($r('app.color.common_color_3'))
              Text(this.weekText)
                .fontSize(14)
                .fontColor($r('app.color.common_color_1'))
            }
            .width('100%')

            Row() {
              Text('上课节数')
                .fontSize(14)
                .fontColor($r('app.color.common_color_3'))
              Text(this.sectionText)
                .fontSize(14)
                .fontColor($r('app.color.common_color_1'))
            }
            .width('100%')
            .margin({ top: 12 })

            Row() {
              Text('上课地点')
                .fontSize(14)
                .fontColor($r('app.color.common_color_3'))
              Text(this.locationText)
                .fontSize(14)
                .fontColor($r('app.color.common_color_1'))
            }
            .width('100%')
            .margin({ top: 12 })
          }
          .width('100%')
          .padding({ left: 12, right: 12, top: 20, bottom: 20 })
          .backgroundColor($r('app.color.white'))

          // 听课提醒卡：白卡 radius 6，margin H12 T32
          Column() {
            // 听课时间行：高 48vp
            Row() {
              Image($r('app.media.mobile_campus_supervise_time'))
                .width(14)
                .height(14)
                .margin({ right: 8 })
              Text('听课时间')
                .fontSize(14)
                .fontColor($r('app.color.common_color_1'))
                .margin({ right: 21 })
              Text(this.listenTime === '' ? '请选择听课时间' : this.listenTime)
                .fontSize(14)
                .fontColor(this.listenTime === '' ? $r('app.color.common_color_35') : $r('app.color.common_color_1'))
                .layoutWeight(1)
                .onClick(() => {
                  this.listenTime = '2026-11-18 08:00';
                })
              Image($r('app.media.mobile_campus_supervise_arrow'))
                .width(12)
                .height(12)
            }
            .width('100%')
            .height(48)
            .alignItems(VerticalAlign.Center)

            Divider()
              .color($r('app.color.common_color_5'))
              .strokeWidth(0.5)
              .width('100%')

            // 日程提醒 + 单选组
            Row() {
              Image($r('app.media.mobile_campus_supervise_notice'))
                .width(14)
                .height(14)
                .margin({ right: 8 })
              Text('日程提醒')
                .fontSize(14)
                .fontColor($r('app.color.common_color_1'))
                .margin({ right: 21 })

              Column() {
                ForEach(this.notifyOptions, (option: SuperviseNotifyOption) => {
                  Row() {
                    Image(option.checked ? $r('app.media.mobile_campus_supervise_choosed') : $r('app.media.mobile_campus_supervise_choose'))
                      .width(16)
                      .height(16)
                      .margin({ right: 8 })
                    Text(option.label)
                      .fontSize(14)
                      .fontColor(option.checked ? $r('app.color.common_color_1') : $r('app.color.common_color_35'))
                  }
                  .margin({ top: option.id === 'no' ? 12.5 : 16 })
                  .alignItems(VerticalAlign.Center)
                  .onClick(() => {
                    this.chooseNotifyOption(option);
                  })
                }, (option: SuperviseNotifyOption) => option.id)

                if (this.showSpecificTime) {
                  Row() {
                    Image($r('app.media.mobile_campus_supervise_choose'))
                      .width(16)
                      .height(16)
                      .opacity(0)
                    Text(this.specificTime === '' ? '请选择提醒时间' : this.specificTime)
                      .fontSize(14)
                      .fontColor($r('app.color.common_color_35'))
                      .layoutWeight(1)
                      .margin({ left: 8 })
                      .onClick(() => {
                        this.specificTime = '课前15分钟';
                      })
                  }
                  .width('100%')
                  .margin({ top: 12 })
                  .alignItems(VerticalAlign.Center)
                }
              }
              .layoutWeight(1)
              .alignItems(HorizontalAlign.Start)
            }
            .width('100%')
            .padding({ top: 0, bottom: 4 })
            .alignItems(VerticalAlign.Top)

            // 添加听课按钮：margin H9 T30，padding V10，白字蓝底 radius 4
            Text('添加听课')
              .fontSize(14)
              .fontColor(Color.White)
              .textAlign(TextAlign.Center)
              .width('100%')
              .padding({ top: 10, bottom: 10 })
              .margin({ left: 9, right: 9, top: 30 })
              .borderRadius(4)
              .backgroundColor($r('app.color.mobile_campus_primary_color_default'))
              .onClick(() => {
                this.addListen();
              })
          }
          .width('100%')
          .padding({ left: 12, right: 12, bottom: 18 })
          .borderRadius(6)
          .backgroundColor($r('app.color.white'))
          .margin({ left: 12, right: 12, top: 32 })
        }
        .width('100%')
      }
      .layoutWeight(1)
      .width('100%')
      .scrollBar(BarState.Off)
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.common_color_6'))
  }
}
