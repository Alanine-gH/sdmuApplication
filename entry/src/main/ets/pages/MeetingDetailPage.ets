import { router } from '@kit.ArkUI';
import { ApiService } from '../network/ApiService';
import { MeetingItem } from '../model/MeetingModel';
import { TitleBar } from '../components/TitleBar';
import { LoadingView } from '../components/LoadingView';
import { EmptyView } from '../components/EmptyView';

/**
 * 会议详情页。
 */
@Entry
@Component
struct MeetingDetailPage {
  @State meeting: MeetingItem = new MeetingItem('', '', '', '', '2', '', '');
  @State isLoading: boolean = true;

  aboutToAppear(): void {
    const params: object = router.getParams();
    let meetingId: string = '';
    if (params !== null && params !== undefined) {
      const record = params as Record<string, Object>;
      const idValue: Object = record['id'];
      if (typeof idValue === 'string') {
        meetingId = idValue as string;
      }
    }
    ApiService.getMeetingDetail(meetingId)
      .then((response) => {
        this.meeting = response.data;
        this.isLoading = false;
      })
      .catch(() => {
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

  build() {
    Column() {
      TitleBar({ title: '会议详情', showBack: true })
      if (this.isLoading) {
        LoadingView()
      } else {
        if (this.meeting.id === '') {
          EmptyView({ tipText: '内容不存在' })
        } else {
          Scroll() {
            Column({ space: 12 }) {
              Text(this.meeting.title)
                .fontSize(20)
                .fontWeight(FontWeight.Bold)
                .fontColor($r('app.color.sdmu_text_primary'))
                .width('100%')
              Text('状态: ' + this.statusText(this.meeting.status))
                .fontSize(13)
                .fontColor($r('app.color.sdmu_primary'))
                .width('100%')
              Column({ space: 10 }) {
                Text('🕐 时间: ' + this.meeting.time)
                  .fontSize(14)
                  .fontColor($r('app.color.sdmu_text_secondary'))
                  .width('100%')
                Text('📍 地点: ' + this.meeting.location)
                  .fontSize(14)
                  .fontColor($r('app.color.sdmu_text_secondary'))
                  .width('100%')
                Text('👤 组织者: ' + this.meeting.organizer)
                  .fontSize(14)
                  .fontColor($r('app.color.sdmu_text_secondary'))
                  .width('100%')
              }
              .padding(14)
              .borderRadius(10)
              .backgroundColor($r('app.color.sdmu_card_bg'))
              .alignItems(HorizontalAlign.Start)
              .width('100%')
              Text('会议内容')
                .fontSize(16)
                .fontWeight(FontWeight.Medium)
                .fontColor($r('app.color.sdmu_text_primary'))
                .width('100%')
                .margin({ top: 8 })
              Text(this.meeting.content)
                .fontSize(14)
                .lineHeight(24)
                .fontColor($r('app.color.sdmu_text_secondary'))
                .width('100%')
                .padding(14)
                .borderRadius(10)
                .backgroundColor($r('app.color.sdmu_card_bg'))
            }
            .alignItems(HorizontalAlign.Start)
            .padding(16)
          }
          .layoutWeight(1)
          .scrollBar(BarState.Off)
        }
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.sdmu_bg'))
  }
}
