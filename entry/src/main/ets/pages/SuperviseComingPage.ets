import { router } from '@kit.ArkUI';
import { TitleBar } from '../components/TitleBar';

/**
 * 待督导 — 1:1 复刻 mobile_campus_supervise_activity_supervise_coming.xml
 * LectureDetailView + LectureNotifyView（buttonType=delete：删除听课，红描边按钮）
 * 底部固定"听课评价"按钮（#1B68B7 白字）跳转评课表单
 */
@Entry
@Component
struct SuperviseComingPage {
  @State className: string = '数据结构';
  @State teacherName: string = '王强';
  @State teacherNumber: string = '3001126';
  @State academyName: string = '计算机学院';
  @State weekText: string = '第12周';
  @State sectionText: string = '6-7节';
  @State locationText: string = '理工楼A210';
  @State listenTime: string = '2026-11-18 14:00';
  @State remindOn: boolean = false;

  private deleteListen(): void {
    router.back();
  }

  private goEvaluate(): void {
    router.pushUrl({ url: 'pages/SuperviseEvaluatePage' });
  }

  build() {
    Column() {
      TitleBar({ title: '待督导', showBack: true })

      Scroll() {
        Column() {
          // 课程信息卡（LectureDetailView）
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

          // 听课提醒卡（LectureNotifyView，buttonType=delete）
          Column() {
            Row() {
              Image($r('app.media.mobile_campus_supervise_time'))
                .width(14)
                .height(14)
                .margin({ right: 8 })
              Text('听课时间')
                .fontSize(14)
                .fontColor($r('app.color.common_color_1'))
                .margin({ right: 21 })
              Text(this.listenTime)
                .fontSize(14)
                .fontColor($r('app.color.common_color_1'))
                .layoutWeight(1)
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
                Row() {
                  Image(this.remindOn ? $r('app.media.mobile_campus_supervise_choosed') : $r('app.media.mobile_campus_supervise_choose'))
                    .width(16)
                    .height(16)
                    .margin({ right: 8 })
                  Text('不提醒')
                    .fontSize(14)
                    .fontColor(!this.remindOn ? $r('app.color.common_color_1') : $r('app.color.common_color_35'))
                }
                .margin({ top: 12.5 })
                .alignItems(VerticalAlign.Center)
                .onClick(() => {
                  this.remindOn = false;
                })

                Row() {
                  Image(this.remindOn ? $r('app.media.mobile_campus_supervise_choosed') : $r('app.media.mobile_campus_supervise_choose'))
                    .width(16)
                    .height(16)
                    .margin({ right: 8 })
                  Text('指定时间提醒')
                    .fontSize(14)
                    .fontColor(this.remindOn ? $r('app.color.common_color_1') : $r('app.color.common_color_35'))
                }
                .margin({ top: 16 })
                .alignItems(VerticalAlign.Center)
                .onClick(() => {
                  this.remindOn = true;
                })
              }
              .layoutWeight(1)
              .alignItems(HorizontalAlign.Start)
            }
            .width('100%')
            .padding({ bottom: 4 })
            .alignItems(VerticalAlign.Top)

            // 删除听课：delete_button_bg 红描边 radius 4，字色 #E60012
            Text('删除听课')
              .fontSize(14)
              .fontColor($r('app.color.mobile_campus_supervise_edit_textcolor'))
              .textAlign(TextAlign.Center)
              .width('100%')
              .padding({ top: 10, bottom: 10 })
              .margin({ left: 9, right: 9, top: 30 })
              .borderRadius(4)
              .border({ width: 0.5, color: $r('app.color.mobile_campus_supervise_edit_textcolor') })
              .onClick(() => {
                this.deleteListen();
              })
          }
          .width('100%')
          .padding({ left: 12, right: 12, bottom: 18 })
          .borderRadius(6)
          .backgroundColor($r('app.color.white'))
          .margin({ left: 12, right: 12, top: 20 })
        }
        .width('100%')
      }
      .layoutWeight(1)
      .width('100%')
      .scrollBar(BarState.Off)

      // 底部固定按钮：听课评价（#1B68B7 白字 16fp，padding V10）
      Text('听课评价')
        .fontSize(16)
        .fontColor(Color.White)
        .textAlign(TextAlign.Center)
        .width('100%')
        .padding({ top: 10, bottom: 10 })
        .backgroundColor($r('app.color.mobile_campus_primary_color_default'))
        .onClick(() => {
          this.goEvaluate();
        })
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.common_color_6'))
  }
}
