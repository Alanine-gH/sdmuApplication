import { TitleBar } from '../components/TitleBar';

/**
 * 主通知条目模型 — 服务不可达时使用内置示例数据。
 */
export class NotificationItem {
  id: string;
  title: string;
  brief: string;
  time: string;

  constructor(id: string, title: string, brief: string, time: string) {
    this.id = id;
    this.title = title;
    this.brief = brief;
    this.time = time;
  }
}

/** 主通知列表示例数据 */
function buildNotificationItems(): NotificationItem[] {
  const list: NotificationItem[] = [
    new NotificationItem('N1', '通知公告', '2017~2018常委常务会议一测试会议纪要', '2026-11-17'),
    new NotificationItem('N2', '通知公告', '关于开展2026年度消防安全专项检查的通知', '2026-11-16'),
    new NotificationItem('N3', '通知公告', '关于2026-2027学年第一学期期末考试安排的通知', '2026-11-15'),
    new NotificationItem('N4', '通知公告', '关于申报2027年度校级科研项目的通知', '2026-11-14'),
    new NotificationItem('N5', '通知公告', '校园网络系统升级维护公告', '2026-11-13'),
    new NotificationItem('N6', '通知公告', '关于召开全校教职工代表大会的通知', '2026-11-12')
  ];
  return list;
}

/**
 * 主通知页 — 按反编译布局 1:1 复刻 mobile_campus_activity_main_notification_new.xml：
 *   LinearLayout vertical
 *   - include toolbar_normal（TitleBar）
 *   - calendar_container（FrameLayout，默认 gone，不展示）
 *   - View 分隔：common_color_6 高 px_to_dip_16=8vp + px_to_dip_2=1vp
 *   - common_refresh_lv_rl 列表：
 *     mobile_campus_item_view_notification_new — 白底 padding left/top=px_to_dip_28=14vp，
 *     标题 34/2=17fp common_color_1、摘要 28/2=14fp common_color_3、右侧箭头图、
 *     底部分隔线 common_color_6 高 px_to_dip_2=1vp
 */
@Entry
@Component
struct MainNotificationPage {
  @State notificationList: NotificationItem[] = buildNotificationItems();

  /**
   * mobile_campus_item_view_notification_new.xml — 主通知条目。
   */
  @Builder
  notificationItem(item: NotificationItem) {
    Column() {
      Row() {
        Column() {
          Text(item.title)
            .fontSize(17)
            .fontColor($r('app.color.common_color_1'))
            .margin({ right: 12, bottom: 8 })
            .width('100%')
          Text(item.brief)
            .fontSize(14)
            .fontColor($r('app.color.common_color_3'))
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .width('100%')
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)

        Image($r('app.media.mobile_campus_main_message_arrow'))
          .width(16)
          .height(16)
          .margin({ right: 12 })
          .objectFit(ImageFit.Contain)
      }
      .alignItems(VerticalAlign.Center)
      .margin({ bottom: 12 })
      .width('100%')

      // item_main_notification_divider：common_color_6 高 px_to_dip_2=1vp
      Divider()
        .color($r('app.color.common_color_6'))
        .strokeWidth(1)
    }
    .width('100%')
    .backgroundColor($r('app.color.white'))
    .padding({ left: 14, top: 14, right: 14 })
  }

  build() {
    Column() {
      TitleBar({ title: '通知公告' })
      // View：common_color_6 高 px_to_dip_16=8vp + px_to_dip_2=1vp
      Column()
        .width('100%')
        .height(8)
        .backgroundColor($r('app.color.common_color_6'))
      Column()
        .width('100%')
        .height(1)
        .backgroundColor($r('app.color.common_color_6'))

      // common_refresh_lv_rl 列表
      List() {
        ForEach(this.notificationList, (item: NotificationItem) => {
          ListItem() {
            this.notificationItem(item)
          }
        }, (item: NotificationItem) => item.id)
      }
      .width('100%')
      .layoutWeight(1)
      .scrollBar(BarState.Off)
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.main_bg'))
  }
}
