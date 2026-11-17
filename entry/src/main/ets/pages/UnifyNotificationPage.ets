import { TitleBar } from '../components/TitleBar';

/**
 * 统一通知页 — 1:1 复刻 mobile_campus_view_unify_notification_main.xml + unify_notification_home_item.xml +
 * unify_notification_tab_item.xml（UnifyNotificationActivity2 / UnifyNotificationView）：
 * 白底：头部行(图标20×20 marginL12 + "通知公告" 16fp #333 padL8 + "更多" 16fp #999 pad 8 + 右箭头) +
 * tab 行 padH11(文字 13fp #999 pad 10/5 r4，选中 bg #191B68B7) +
 * 内容列表(16×16 图标+红点5 r2.5 + 标题 16fp #333 + 时间与来源 13fp #999 marginT8，行 pad 15/12，分隔线 #E7E7E7 0.5) +
 * 空态(线 #F2F2F2 marginBottom20 + 图 240×105 margin10 + 文本 16fp #BBD2E3) / 错误态 + 重试按钮 +
 * 底部 12vp #F2F2F2 占位
 */
interface NotificationTabItem {
  id: string;
  label: string;
}

interface NotificationHomeItem {
  id: string;
  title: string;
  timeAndSource: string;
  unRead: boolean;
}

@Entry
@Component
struct UnifyNotificationPage {
  @State currentTab: number = 0;
  @State tabs: NotificationTabItem[] = [
    { id: 't0', label: '全部' },
    { id: 't1', label: '教务通知' },
    { id: 't2', label: '学工通知' },
    { id: 't3', label: '其他' }
  ];
  @State allNotices: NotificationHomeItem[] = [
    { id: 'n1', title: '关于2026年寒假放假安排的通知', timeAndSource: '2026-11-16 · 校长办公室', unRead: true },
    { id: 'n2', title: '图书馆数据库使用培训通知', timeAndSource: '2026-11-15 · 图书馆', unRead: true },
    { id: 'n3', title: '期中教学质量检查安排', timeAndSource: '2026-11-14 · 教务处', unRead: false },
    { id: 'n4', title: '学生宿舍安全用电提醒', timeAndSource: '2026-11-13 · 学生处', unRead: false },
    { id: 'n5', title: '奖学金评定结果公示', timeAndSource: '2026-11-12 · 学生资助中心', unRead: false }
  ];

  private shownNotices(): NotificationHomeItem[] {
    if (this.currentTab === 0) {
      return this.allNotices;
    }
    const label: string = this.tabs[this.currentTab].label;
    return this.allNotices.filter((item: NotificationHomeItem): boolean => {
      return item.timeAndSource.indexOf(label.replace('通知', '')) >= 0;
    });
  }

  build() {
    Column() {
      TitleBar({ title: '统一通知', showBack: true })

      Row() {
        Image($r('app.media.icon_unify_notification'))
          .width(20)
          .height(20)
          .margin({ left: 12 })
          .objectFit(ImageFit.Contain)

        Text('通知公告')
          .fontSize(16)
          .fontColor('#333333')
          .padding({ left: 8 })
          .layoutWeight(1)

        Text('更多')
          .fontSize(16)
          .fontColor('#999999')
          .padding({ left: 8, top: 10, right: 6, bottom: 10 })

        Image($r('app.media.arrow_right'))
          .width(12)
          .height(12)
          .margin({ right: 8 })
          .objectFit(ImageFit.Contain)
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)

      Scroll() {
        Row() {
          ForEach(this.tabs, (tab: NotificationTabItem, idx: number) => {
            Text(tab.label)
              .fontSize(13)
              .fontColor(idx === this.currentTab ? '#1B68B7' : '#999999')
              .padding({ left: 10, right: 10, top: 5, bottom: 5 })
              .backgroundColor(idx === this.currentTab ? '#191B68B7' : '#F8F8F8')
              .borderRadius(4)
              .margin({ left: 4, right: 4 })
              .onClick(() => {
                this.currentTab = idx;
              })
          }, (tab: NotificationTabItem) => tab.id)
        }
        .padding({ left: 11, right: 11 })
        .alignItems(VerticalAlign.Center)
      }
      .scrollable(ScrollDirection.Horizontal)
      .scrollBar(BarState.Off)
      .width('100%')

      Column() {
        if (this.shownNotices().length > 0) {
          ForEach(this.shownNotices(), (item: NotificationHomeItem) => {
            Column() {
              Row() {
                Stack({ alignContent: Alignment.BottomEnd }) {
                  Image($r('app.media.icon_unify_notification_notification'))
                    .width(16)
                    .height(16)
                    .objectFit(ImageFit.Contain)

                  if (item.unRead) {
                    Circle()
                      .width(5)
                      .height(5)
                      .fill($r('app.color.read_dot_bg'))
                  }
                }
                .width(16)
                .height(16)
                .margin({ top: 3.5 })
                .alignSelf(ItemAlign.Start)

                Column() {
                  Text(item.title)
                    .fontSize(16)
                    .fontColor('#333333')
                    .maxLines(1)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                    .width('100%')

                  Text(item.timeAndSource)
                    .fontSize(13)
                    .fontColor('#999999')
                    .maxLines(1)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                    .padding({ right: 15 })
                    .margin({ top: 8 })
                    .width('100%')
                }
                .padding({ left: 10 })
                .layoutWeight(1)
                .alignItems(HorizontalAlign.Start)
              }
              .width('100%')
              .padding({ left: 15, right: 15, top: 12, bottom: 12 })
              .alignItems(VerticalAlign.Top)

              Divider()
                .color('#E7E7E7')
                .strokeWidth(0.5)
                .width('100%')
            }
            .width('100%')
          }, (item: NotificationHomeItem) => item.id)
        } else {
          Column() {
            Divider()
              .color('#F2F2F2')
              .strokeWidth(0.5)
              .width('100%')
              .margin({ bottom: 20 })

            Image($r('app.media.icon_unify_todo_notification_empty'))
              .width(240)
              .height(105)
              .margin({ top: 10, bottom: 10 })
              .objectFit(ImageFit.Contain)

            Text('暂无通知公告')
              .fontSize(16)
              .fontColor($r('app.color.mobile_campus_unify_todo_empty_text'))
          }
          .width('100%')
          .padding({ bottom: 19 })
          .alignItems(HorizontalAlign.Center)
        }
      }
      .width('100%')
      .layoutWeight(1)

      Row()
        .width('100%')
        .height(12)
        .backgroundColor('#F2F2F2')
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.white'))
    .alignItems(HorizontalAlign.Start)
  }
}
