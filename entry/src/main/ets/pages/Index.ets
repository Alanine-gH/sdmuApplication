import { router } from '@kit.ArkUI';
import { ApiService } from '../network/ApiService';
import { MeetingItem } from '../model/MeetingModel';
import { TodoItem } from '../model/TodoModel';
import { PreferencesUtil } from '../data/PreferencesUtil';
import { Constants } from '../data/Constants';
import { HomeTab } from '../components/HomeTab';
import { ScheduleGrid } from '../components/ScheduleGrid';
import { MineTab } from '../components/MineTab';

/**
 * 消息 Tab：待办 + 会议消息聚合列表。
 */
@Component
struct MessageTab {
  @State todoList: TodoItem[] = [];
  @State meetingList: MeetingItem[] = [];

  aboutToAppear(): void {
    ApiService.getTodoList()
      .then((response) => {
        this.todoList = response.data;
      })
      .catch(() => {
        this.todoList = [];
      });
    ApiService.getMeetingList()
      .then((response) => {
        this.meetingList = response.data;
      })
      .catch(() => {
        this.meetingList = [];
      });
  }

  @Builder
  messageCard(icon: string, title: string, time: string, tagText: string, tagColor: Resource) {
    Row({ space: 12 }) {
      Text(icon)
        .fontSize(22)
        .width(40)
        .height(40)
        .textAlign(TextAlign.Center)
        .backgroundColor($r('app.color.sdmu_bg'))
        .borderRadius(20)
      Column({ space: 4 }) {
        Text(title)
          .fontSize(15)
          .fontColor($r('app.color.sdmu_text_primary'))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        Text(time)
          .fontSize(12)
          .fontColor($r('app.color.sdmu_text_hint'))
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
      Text(tagText)
        .fontSize(11)
        .fontColor(tagColor)
        .padding({ left: 8, right: 8, top: 3, bottom: 3 })
        .borderRadius(10)
        .backgroundColor($r('app.color.sdmu_bg'))
    }
    .width('100%')
    .padding(14)
    .backgroundColor($r('app.color.sdmu_card_bg'))
    .borderRadius(10)
    .margin({ left: 12, right: 12, top: 10 })
  }

  build() {
    Column() {
      Text('消息')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor(Color.White)
        .width('100%')
        .height(56)
        .textAlign(TextAlign.Center)
        .backgroundColor($r('app.color.sdmu_primary'))

      Scroll() {
        Column() {
          ForEach(this.todoList, (item: TodoItem) => {
            this.messageCard('📝', item.title, item.deadline,
              item.status === '1' ? '已办' : '待办',
              item.status === '1' ? $r('app.color.sdmu_success') : $r('app.color.sdmu_warning'))
          }, (item: TodoItem) => 'todo' + item.id)
          ForEach(this.meetingList, (item: MeetingItem) => {
            this.messageCard('🏛', item.title, item.time,
              item.status === '1' ? '进行中' : (item.status === '2' ? '已结束' : '未开始'),
              item.status === '1' ? $r('app.color.sdmu_warning') :
                (item.status === '2' ? $r('app.color.sdmu_text_hint') : $r('app.color.sdmu_primary')))
          }, (item: MeetingItem) => 'meeting' + item.id)
        }
        .width('100%')
      }
      .layoutWeight(1)
      .align(Alignment.TopStart)
      .scrollBar(BarState.Off)
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.sdmu_bg'))
  }
}

/**
 * 主页：登录检查 + 底部 Tab 容器（首页/消息/课表/我的）。
 */
@Entry
@Component
struct Index {
  @State isReady: boolean = false;
  @State isLogged: boolean = false;

  aboutToAppear(): void {
    PreferencesUtil.getBoolean(Constants.KEY_IS_LOGIN, false)
      .then((logged: boolean) => {
        this.isLogged = logged;
        this.isReady = true;
        if (!logged) {
          router.replaceUrl({ url: 'pages/LoginPage' });
        }
      })
      .catch(() => {
        this.isReady = true;
        this.isLogged = false;
        router.replaceUrl({ url: 'pages/LoginPage' });
      });
  }

  build() {
    Column() {
      if (this.isReady && this.isLogged) {
        Tabs({ barPosition: BarPosition.End }) {
          TabContent() {
            HomeTab()
          }
          .tabBar(this.tabBuilder('🏠', '首页', 0))
          TabContent() {
            MessageTab()
          }
          .tabBar(this.tabBuilder('💬', '消息', 1))
          TabContent() {
            ScheduleGrid()
          }
          .tabBar(this.tabBuilder('📅', '课表', 2))
          TabContent() {
            MineTab()
          }
          .tabBar(this.tabBuilder('👤', '我的', 3))
        }
        .scrollable(true)
        .barMode(BarMode.Fixed)
        .onChange((index: number) => {
        })
      }
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  tabBuilder(icon: string, label: string, index: number) {
    Column({ space: 4 }) {
      Text(icon)
        .fontSize(22)
      Text(label)
        .fontSize(11)
    }
    .width('100%')
    .height(56)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }
}
