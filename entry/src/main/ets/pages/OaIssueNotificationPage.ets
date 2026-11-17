import { router } from '@kit.ArkUI';
import { TitleBar } from '../components/TitleBar';

/**
 * 通知设置 — 1:1 复刻 mobile_campus_oa_issue_activity_notificaiton.xml
 * + view_notification.xml（条目卡：标题 17fp 黑 + 右侧箭头图、
 * 地点/时间/人员三行小字（图标+13fp 灰字），条目底部细分割线）
 */
class OaNotificationItem {
  id: string;
  title: string;
  location: string;
  time: string;
  people: string;

  constructor(id: string, title: string, location: string, time: string, people: string) {
    this.id = id;
    this.title = title;
    this.location = location;
    this.time = time;
    this.people = people;
  }
}

@Entry
@Component
struct OaIssueNotificationPage {
  @State notifyList: OaNotificationItem[] = [
    new OaNotificationItem('n1', '第42次党委会议', '行政楼三楼第一会议室', '2026-11-18 09:00', '校党委全体委员'),
    new OaNotificationItem('n2', '第41次校长办公会', '行政楼二楼会议室', '2026-11-11 14:30', '校领导班子'),
    new OaNotificationItem('n3', '本科教学评估动员会', '图书馆学术报告厅', '2026-11-20 15:00', '各院系负责人'),
    new OaNotificationItem('n4', '冬季消防安全检查', '全校各楼宇', '2026-11-15 14:00', '各部门负责人'),
    new OaNotificationItem('n5', '期中教学检查', '各教学楼', '2026-11-16 09:00', '各教学单位')
  ];

  private goDetail(): void {
    router.pushUrl({ url: 'pages/OaIssueDetailPage' });
  }

  build() {
    Column() {
      TitleBar({ title: '通知设置', showBack: true })

      List({ space: 0 }) {
        ForEach(this.notifyList, (item: OaNotificationItem) => {
          ListItem() {
            Column() {
              Column() {
                Row() {
                  Text(item.title)
                    .fontSize(17)
                    .fontColor($r('app.color.black'))
                    .layoutWeight(1)
                    .maxLines(1)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                  Image($r('app.media.mobile_campus_oa_issue_check_g_m'))
                    .width(14)
                    .height(14)
                    .margin({ left: 8 })
                }
                .width('100%')
                .alignItems(VerticalAlign.Center)

                Row() {
                  Image($r('app.media.mobile_campus_oa_issue_location'))
                    .width(14)
                    .height(14)
                    .margin({ right: 8 })
                  Text(item.location)
                    .fontSize(13)
                    .fontColor($r('app.color.common_color_3'))
                }
                .width('100%')
                .margin({ top: 12 })
                .alignItems(VerticalAlign.Center)

                Row() {
                  Image($r('app.media.mobile_campus_oa_issue_time'))
                    .width(14)
                    .height(14)
                    .margin({ right: 8 })
                  Text(item.time)
                    .fontSize(13)
                    .fontColor($r('app.color.common_color_3'))
                }
                .width('100%')
                .margin({ top: 12 })
                .alignItems(VerticalAlign.Center)

                Row() {
                  Image($r('app.media.mobile_campus_oa_issue_people'))
                    .width(14)
                    .height(14)
                    .margin({ right: 8 })
                  Text(item.people)
                    .fontSize(13)
                    .fontColor($r('app.color.common_color_3'))
                }
                .width('100%')
                .margin({ top: 12 })
                .alignItems(VerticalAlign.Center)
              }
              .width('100%')
              .padding({ left: 12, right: 12, top: 20, bottom: 15.5 })
              .backgroundColor($r('app.color.white'))
              .onClick(() => {
                this.goDetail();
              })

              Divider()
                .color($r('app.color.common_color_5'))
                .strokeWidth(0.5)
                .width('100%')
            }
            .width('100%')
            .backgroundColor($r('app.color.white'))
          }
        }, (item: OaNotificationItem) => item.id)
      }
      .width('100%')
      .layoutWeight(1)
      .backgroundColor($r('app.color.mobile_campus_bg_color'))
      .scrollBar(BarState.Off)
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.mobile_campus_bg_color'))
  }
}
