import { router } from '@kit.ArkUI';
import { ApiService } from '../network/ApiService';
import { ApiResponse } from '../model/ResponseModel';
import { MeetingItem } from '../model/MeetingModel';
import { BusinessError } from '@kit.BasicServicesKit';
import { TitleBar } from '../components/TitleBar';
import { LoadingView } from '../components/LoadingView';
import { EmptyView } from '../components/EmptyView';

/**
 * 会议详情页 — 1:1 复刻（px_to_dip_N = N/2 vp, px_to_sp_N = N/2 fp）：
 * mobile_campus_meeting_activity_detail.xml：toolbar + MultiStateView(bg #F2F2F2) + ScrollView(detailView + detailFileView marginTop 12) + layoutBottom 底部按钮区
 * mobile_campus_meeting_view_detail_btn.xml：底栏白底高 48dip + 0.5 分隔线 + tvSituation px_to_sp_32=16fp #97000C 居中 + arrow_up drawablePadding 8dip
 * detailView 字段：主题 17fp #333 / 会议时间 / 会议地点 / 会议主持 / 会议内容 12fp #999 图标 drawablePadding 6
 */
@Entry
@Component
struct MeetingDetailPage {
  @State meeting: MeetingItem = new MeetingItem('', '', '', '', '2', '', '');
  @State isLoading: boolean = true;
  @State isOffline: boolean = false;
  @State offlineReason: string = '';

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
      .then((response: ApiResponse<MeetingItem>) => {
        const data: MeetingItem = response.data;
        if (data.title !== '') {
          this.meeting = data;
        }
        if (response.code !== 0) {
          this.isOffline = true;
          this.offlineReason = response.message;
        } else {
          this.isOffline = false;
          this.offlineReason = '';
        }
        this.isLoading = false;
      })
      .catch((error: BusinessError) => {
        console.info('MeetingDetailPage load fail: ' + error.message);
        this.isOffline = true;
        this.offlineReason = '网络请求失败: ' + error.message;
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
          if (this.isOffline) {
            Text('离线降级（' + this.offlineReason + '），当前展示本地模拟数据')
              .fontSize(12)
              .fontColor($r('app.color.mobile_campus_primary_color_default'))
              .width('100%')
              .textAlign(TextAlign.Center)
              .padding({ top: 6, bottom: 6 })
              .backgroundColor($r('app.color.common_color_6'))
          }

          // ScrollView 部分（layout_above layoutBottom）
          Scroll() {
            Column() {
              // detailView: 会议信息卡
              Column() {
                Text(this.meeting.title)
                  .fontSize(17)
                  .fontWeight(FontWeight.Bold)
                  .fontColor($r('app.color.common_color_1'))
                  .width('100%')
                  .margin({ bottom: 10 })

                Row() {
                  Image($r('app.media.mobile_campus_meeting_time_s'))
                    .width(12)
                    .height(12)
                    .margin({ right: 6 })
                  Text('会议时间')
                    .fontSize(12)
                    .fontColor($r('app.color.common_color_3'))
                    .width(64)
                  Text(this.meeting.time + '（' + this.statusText(this.meeting.status) + '）')
                    .fontSize(12)
                    .fontColor($r('app.color.common_color_1'))
                    .layoutWeight(1)
                    .maxLines(1)
                }
                .width('100%')
                .margin({ top: 6 })
                .alignItems(VerticalAlign.Center)

                Row() {
                  Image($r('app.media.mobile_campus_meeting_location_s'))
                    .width(12)
                    .height(12)
                    .margin({ right: 6 })
                  Text('会议地点')
                    .fontSize(12)
                    .fontColor($r('app.color.common_color_3'))
                    .width(64)
                  Text(this.meeting.location)
                    .fontSize(12)
                    .fontColor($r('app.color.common_color_1'))
                    .layoutWeight(1)
                    .maxLines(1)
                }
                .width('100%')
                .margin({ top: 6 })
                .alignItems(VerticalAlign.Center)

                Row() {
                  Image($r('app.media.mobile_campus_meeting_person'))
                    .width(12)
                    .height(12)
                    .margin({ right: 6 })
                  Text('会议主持')
                    .fontSize(12)
                    .fontColor($r('app.color.common_color_3'))
                    .width(64)
                  Text(this.meeting.organizer)
                    .fontSize(12)
                    .fontColor($r('app.color.common_color_1'))
                    .layoutWeight(1)
                    .maxLines(1)
                }
                .width('100%')
                .margin({ top: 6 })
                .alignItems(VerticalAlign.Center)

                Text(this.meeting.content)
                  .fontSize(14)
                  .lineHeight(22)
                  .fontColor($r('app.color.common_color_2'))
                  .width('100%')
                  .margin({ top: 12 })
              }
              .alignItems(HorizontalAlign.Start)
              .padding(12)
              .backgroundColor($r('app.color.white'))
              .width('100%')

              // detailFileView: 会议材料区 marginTop 12dip
              Column() {
                Text('会议材料')
                  .fontSize(15)
                  .fontColor($r('app.color.common_color_1'))
                  .width('100%')
                  .margin({ bottom: 8 })
                Text('暂无附件')
                  .fontSize(12)
                  .fontColor($r('app.color.common_color_3'))
                  .width('100%')
              }
              .alignItems(HorizontalAlign.Start)
              .padding(12)
              .backgroundColor($r('app.color.white'))
              .width('100%')
              .margin({ top: 12 })
            }
            .width('100%')
            .padding(12)
            .alignItems(HorizontalAlign.Start)
          }
          .width('100%')
          .layoutWeight(1)
          .align(Alignment.Top)
          .scrollBar(BarState.Off)
          .backgroundColor($r('app.color.mobile_campus_bg_color'))

          // mobile_campus_meeting_view_detail_btn.xml: layoutBottom 白底高 48dip
          Column() {
            Divider()
              .color($r('app.color.common_color_5'))
              .strokeWidth(0.5)
              .width('100%')
            Row() {
              Image($r('app.media.arrow_up'))
                .width(16)
                .height(16)
                .margin({ right: 8 })
              Text('查看参会情况')
                .fontSize(16)
                .fontColor($r('app.color.mobile_campus_primary_color'))
            }
            .height(47.5)
            .justifyContent(FlexAlign.Center)
            .width('100%')
            .backgroundColor($r('app.color.white'))
            .onClick(() => {
              this.getUIContext().getPromptAction().showToast({ message: '参会人员功能暂未开放' });
            })
          }
          .width('100%')
        }
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.mobile_campus_bg_color'))
  }
}
