import { router } from '@kit.ArkUI';
import { ApiService } from '../network/ApiService';
import { MeetingItem } from '../model/MeetingModel';
import { TitleBar } from '../components/TitleBar';
import { EmptyView } from '../components/EmptyView';
import { LoadingView } from '../components/LoadingView';

/**
 * 会议列表页：状态Tag（未开始蓝/进行中橙/已结束灰）。
 */
@Entry
@Component
struct MeetingPage {
  @State meetingList: MeetingItem[] = [];
  @State isLoading: boolean = true;

  aboutToAppear(): void {
    ApiService.getMeetingList()
      .then((response) => {
        this.meetingList = response.data;
        this.isLoading = false;
      })
      .catch(() => {
        this.meetingList = [];
        this.isLoading = false;
      });
  }

  private statusText(status: string): string {
    if (status === '1') {
      return '进行中';
    }
    if (status === '2') {
      return '已结束';
    }
    return '未开始';
  }

  private statusColor(status: string): Resource {
    if (status === '1') {
      return $r('app.color.sdmu_warning');
    }
    if (status === '2') {
      return $r('app.color.sdmu_text_hint');
    }
    return $r('app.color.sdmu_primary');
  }

  build() {
    Column() {
      TitleBar({ title: '会议', showBack: true })
      if (this.isLoading) {
        LoadingView()
      } else {
        if (this.meetingList.length === 0) {
          EmptyView()
        } else {
          List() {
            ForEach(this.meetingList, (item: MeetingItem) => {
              ListItem() {
                Column({ space: 8 }) {
                  Row() {
                    Text(item.title)
                      .fontSize(16)
                      .fontWeight(FontWeight.Bold)
                      .fontColor($r('app.color.sdmu_text_primary'))
                      .layoutWeight(1)
                      .maxLines(2)
                      .textOverflow({ overflow: TextOverflow.Ellipsis })
                    Text(this.statusText(item.status))
                      .fontSize(11)
                      .fontColor(this.statusColor(item.status))
                      .padding({ left: 8, right: 8, top: 3, bottom: 3 })
                      .borderRadius(10)
                      .backgroundColor($r('app.color.sdmu_bg'))
                  }
                  .width('100%')
                  Row() {
                    Text('🕐 ' + item.time)
                      .fontSize(13)
                      .fontColor($r('app.color.sdmu_text_secondary'))
                      .layoutWeight(1)
                  }
                  .width('100%')
                  Row() {
                    Text('📍 ' + item.location)
                      .fontSize(13)
                      .fontColor($r('app.color.sdmu_text_secondary'))
                  }
                  .width('100%')
                }
                .alignItems(HorizontalAlign.Start)
                .padding(14)
                .borderRadius(10)
                .backgroundColor($r('app.color.sdmu_card_bg'))
                .margin({ left: 12, right: 12, top: 10 })
                .onClick(() => {
                  router.pushUrl({ url: 'pages/MeetingDetailPage', params: { id: item.id } });
                })
              }
            }, (item: MeetingItem) => item.id)
          }
          .width('100%')
          .layoutWeight(1)
          .backgroundColor($r('app.color.sdmu_bg'))
          .scrollBar(BarState.Off)
        }
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.sdmu_bg'))
  }
}
