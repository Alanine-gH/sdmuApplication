import { router } from '@kit.ArkUI';
import { TitleBar } from '../components/TitleBar';

/**
 * 消息列表条目模型 — 服务不可达时使用内置示例数据。
 */
export class MessageItem {
  id: string;
  title: string;
  time: string;
  unread: boolean;
  hasNotificationIcon: boolean;

  constructor(id: string, title: string, time: string, unread: boolean, hasNotificationIcon: boolean) {
    this.id = id;
    this.title = title;
    this.time = time;
    this.unread = unread;
    this.hasNotificationIcon = hasNotificationIcon;
  }
}

/** 消息列表示例数据 */
function buildMessageItems(): MessageItem[] {
  const list: MessageItem[] = [
    new MessageItem('M1', '【OA办公】您有一条新的公文待处理，请及时查阅并办理。', '2026-11-17 09:30', true, true),
    new MessageItem('M2', '【会议通知】本周五下午3点在行政楼第二会议室召开教学工作例会。', '2026-11-17 08:15', true, false),
    new MessageItem('M3', '【教务处】2026-2027学年第一学期期末考试安排已发布。', '2026-11-16 17:42', false, false),
    new MessageItem('M4', '【人事处】请您于本月25日前完成年度考核表的填报工作。', '2026-11-16 10:05', true, false),
    new MessageItem('M5', '【财务处】11月份工资条已发放，请注意查收核对。', '2026-11-15 16:20', false, false),
    new MessageItem('M6', '【图书馆】您借阅的图书即将到期，请及时归还或续借。', '2026-11-15 09:00', false, true),
    new MessageItem('M7', '【信息中心】校园网将于本周六晚22点进行系统升级维护。', '2026-11-14 14:30', false, false)
  ];
  return list;
}

/**
 * 消息列表页 — 按源布局 1:1 复刻 mobile_campus_activity_message_list.xml：
 *   LinearLayout vertical（背景 #E5E5E5）
 *   - FrameLayout 45vp 白底：返回按钮 45x45（padding 13）、标题“消息” 17sp #252525 居中 margin 45
 *   - View 10vp 间隔
 *   - MultiStateView（列表区）
 *     item：mobile_campus_item_message_list — 白底 padding left=10/top=12/right=15/bottom=12，
 *     左列 30vp（通知图标 16x16 marginTop=3.5 + 未读红点 5x5）、标题 16sp #333 paddingLeft=10、
 *     时间 13sp #999 marginTop=8、底部分隔线 0.5vp #E7E7E7
 *   - tvDelete“删除（0）”编辑状态（默认 gone，不展示）
 */
@Entry
@Component
struct MessageListPage {
  @State messageList: MessageItem[] = buildMessageItems();

  /**
   * mobile_campus_item_message_list.xml — 消息列表条目。
   */
  @Builder
  messageItem(item: MessageItem) {
    Column() {
      Row() {
        // 左列 RelativeLayout width=30vp：通知图标 16x16（marginTop=3.5，不可见时占位）+ 未读红点 5x5
        Stack({ alignContent: Alignment.TopStart }) {
          Image($r('app.media.icon_unify_notification_notification'))
            .width(16)
            .height(16)
            .objectFit(ImageFit.Contain)
            .visibility(item.hasNotificationIcon ? Visibility.Visible : Visibility.None)
            .margin({ left: 7, top: 3.5 })
          // 未读红点：5x5 圆形 read_dot_bg、右上角
          Circle()
            .width(5)
            .height(5)
            .fill($r('app.color.read_dot_bg'))
            .margin({ left: 18, top: 3.5 })
            .visibility(item.unread ? Visibility.Visible : Visibility.None)
        }
        .width(30)
        .height('100%')

        Column() {
          Text(item.title)
            .fontSize(16)
            .fontColor('#333333')
            .padding({ left: 10 })
            .lineHeight(21)
            .width('100%')
          Text(item.time)
            .fontSize(13)
            .fontColor('#999999')
            .padding({ left: 10 })
            .lineHeight(18)
            .margin({ top: 8 })
            .width('100%')
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
      }
      .width('100%')
      .backgroundColor($r('app.color.white'))
      .padding({ left: 10, top: 12, right: 15, bottom: 12 })
      .alignItems(VerticalAlign.Center)

      Divider()
        .color('#E7E7E7')
        .strokeWidth(0.5)
    }
    .width('100%')
    .onClick(() => {
      router.pushUrl({ url: 'pages/EmcMessageDetailPage', params: { id: item.id } });
    })
  }

  build() {
    Column() {
      // FrameLayout 45vp 白底标题栏
      Stack({ alignContent: Alignment.Start }) {
        TitleBar({ title: '消息' })
        // ivBack：45x45、padding 13 → 图标 19x19 左侧 13vp
        Image($r('app.media.nav_back_btn'))
          .width(19)
          .height(19)
          .margin({ left: 13 })
          .objectFit(ImageFit.Contain)
      }
      .width('100%')
      .height(45)
      .backgroundColor($r('app.color.white'))

      // View 10vp 间隔
      Column()
        .width('100%')
        .height(10)

      // MultiStateView 列表区
      List() {
        ForEach(this.messageList, (item: MessageItem) => {
          ListItem() {
            this.messageItem(item)
          }
        }, (item: MessageItem) => item.id)
      }
      .width('100%')
      .layoutWeight(1)
      .scrollBar(BarState.Off)
      .backgroundColor($r('app.color.message_page_bg'))
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.message_page_bg'))
  }
}
