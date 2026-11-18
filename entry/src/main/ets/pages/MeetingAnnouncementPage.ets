import { router } from '@kit.ArkUI';
import { ApiService } from '../network/ApiService';
import { ApiResponse } from '../model/ResponseModel';
import { BusinessError } from '@kit.BasicServicesKit';
import { TitleBar } from '../components/TitleBar';
import { EmptyView } from '../components/EmptyView';
import { LoadingView } from '../components/LoadingView';
import { MeetingAnnouncementEntity } from '../model/MeetingApiModel';

/**
 * 会议公告页 — MeetingAnnouncementActivity.java(225行) 源码级翻译
 * 【源码链路】MeetingDetailActivity 公告 badge（e.d.a）→ h0 bundle{canRelease, meetingId, meetingTitle}
 *   → y(intent)：p=canRelease、q=meetingId、r=meetingTitle → f1() → V2() = MeetingPImpl.W().D(q)
 *   → MeetingModel.a1：POST findMeetingFeedBack {meetingId} → MeetingAnnouncement[]。
 * 【布局】mobile_campus_meeting_activity_announcement.xml：toolbar("公告") + MultiStateView
 *   + ListView（白底，divider common_color_3）；canRelease 时 addHeaderView(MeetingAnnouncementHeaderView)。
 * 【item】mobile_campus_meeting_item_view_announcement.xml：tvName USER_NAME 14fp #4986C5
 *   + tvTime CREATE_TIME 14fp（右）+ tvText MESSAGE 16fp（mt19 mb19 ml28）。
 * 【header】mobile_campus_meeting_widget_announcement_edit.xml：tvTitle="“标题”" 18.5fp 主色居中
 *   + 提示条"在这里您可以发送公告给所有参会人员，\n参会人员会收到公告。"
 *   + etContent hint "输入公告内容..."（103vp 高）+ tvSubmit "确定" 44vp 白字。
 *   提交：空 → "公告内容不能为空！"；确认弹窗"确认提交通知公告？"→ MeetingModel.T0：
 *   POST addMeetingFeedBack {meetingId,message} → 成功刷新列表+清空输入。
 * 【空态判定】源码 b.b()：adapter 有数据或 canRelease → 内容态；否则 EMPTY 空态。
 * 【返回】源码 onBackPressed setResult(meetingNotice=count) —— HAP 无 setResult，
 *   详情页 onPageShow 重拉 findMeetingFeedBack 刷新角标（等价实现）。
 * 【实测】findMeetingFeedBack 管道通（probe_w13_meeting_series.py，测试账号无会议 → 空态）。
 */
@Entry
@Component
struct MeetingAnnouncementPage {
  @State announcements: MeetingAnnouncementEntity[] = [];
  @State loading: boolean = true;
  @State listFail: boolean = false;
  /** 源码 p：canRelease（feedBackType=1 且进行中） */
  @State canRelease: boolean = false;
  /** 发布输入内容（etContent） */
  @State draftMessage: string = '';
  @State submitting: boolean = false;
  private meetingId: string = '';
  private meetingTitle: string = '';

  aboutToAppear(): void {
    // 源码 y(intent)：p=canRelease q=meetingId r=meetingTitle
    const params: object | undefined = router.getParams() as object | undefined;
    if (params !== null && params !== undefined) {
      const record = params as Record<string, Object>;
      const id: Object | undefined = record['meetingId'];
      if (typeof id === 'string') {
        this.meetingId = id as string;
      }
      const title: Object | undefined = record['meetingTitle'];
      if (typeof title === 'string') {
        this.meetingTitle = title as string;
      }
      const cr: Object | undefined = record['canRelease'];
      if (typeof cr === 'boolean') {
        this.canRelease = cr as boolean;
      }
    }
    this.loadAnnouncements();
  }

  /** 源码 V2()：n.W(new b(MeetingAnnouncement.class)).D(q) → POST findMeetingFeedBack {meetingId} */
  private loadAnnouncements(): void {
    ApiService.findMeetingFeedback(this.meetingId)
      .then((response: ApiResponse<MeetingAnnouncementEntity[]>) => {
        if (response.code === 1000) {
          // 登录失效统一处理已在网络层触发（HttpClient.bizRequest 拦截：清会话+toast+跳登录）
          this.listFail = true;
          this.loading = false;
          return;
        }
        if (response.code === 0) {
          this.announcements = response.data;
          this.listFail = false;
        } else {
          this.announcements = [];
          this.listFail = true;
          this.toast(response.message === '' ? '获取公告失败' : response.message);
        }
        this.loading = false;
      })
      .catch((error: BusinessError) => {
        ApiService.logError('MeetingAnnouncementPage load fail: ' + error.message);
        this.announcements = [];
        this.listFail = true;
        this.loading = false;
      });
  }

  /** 源码 MeetingAnnouncementHeaderView.a.onClick：空内容拦截（"公告内容不能为空！"） */
  private submitDraft(): void {
    if (this.draftMessage.trim() === '') {
      this.toast('公告内容不能为空！');
      return;
    }
    // 源码 c.a(str)：确认弹窗"确认提交通知公告？" → X2(str)
    AlertDialog.show({
      message: '确认提交通知公告？',
      autoCancel: true,
      alignment: DialogAlignment.Center,
      primaryButton: {
        value: '取消',
        action: (): void => {
        }
      },
      secondaryButton: {
        value: '确定',
        action: (): void => {
          this.doSubmitAnnouncement();
        }
      }
    });
  }

  /** 源码 X2(str)：n.R(new d(String.class)).v(q, str) → POST addMeetingFeedBack {meetingId,message} */
  private doSubmitAnnouncement(): void {
    if (this.submitting) {
      return;
    }
    this.submitting = true;
    ApiService.addMeetingFeedback(this.meetingId, this.draftMessage)
      .then((response: ApiResponse<string>) => {
        this.submitting = false;
        if (response.code === 0) {
          // 源码 d.g()：code=0 → V2() 刷新 + m.clearViewState()
          this.draftMessage = '';
          this.loadAnnouncements();
        } else {
          this.toast(response.message === '' ? '提交失败' : response.message);
        }
      })
      .catch((error: BusinessError) => {
        ApiService.logError('MeetingAnnouncementPage submit fail: ' + error.message);
        this.submitting = false;
        this.toast('网络请求失败');
      });
  }

  private toast(message: string): void {
    this.getUIContext().getPromptAction().showToast({ message: message });
  }

  build() {
    Column() {
      TitleBar({ title: '公告', showBack: true })

      if (this.loading) {
        LoadingView()
      } else if (this.announcements.length === 0 && !this.canRelease) {
        // 源码 b.b()：无数据且无 header → EMPTY 态
        EmptyView({ tipText: '暂无公告' })
      } else {
        List() {
          if (this.canRelease) {
            ListItem() {
              this.releaseHeader()
            }
          }
          ForEach(this.announcements, (item: MeetingAnnouncementEntity) => {
            ListItem() {
              this.announcementRow(item)
            }
          }, (item: MeetingAnnouncementEntity) => 'ann_' + item.ID)
        }
        .width('100%')
        .layoutWeight(1)
        .backgroundColor($r('app.color.white'))
        .scrollBar(BarState.Off)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.white'))
  }

  /** 行：tvName(14fp #4986C5)+tvTime(14fp) / tvText(16fp)——item_view_announcement.xml 1:1 */
  @Builder
  announcementRow(item: MeetingAnnouncementEntity) {
    Column() {
      Row() {
        Text(item.USER_NAME)
          .fontSize(14)
          .fontColor('#4986C5')
          .layoutWeight(1)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        Text(item.CREATE_TIME)
          .fontSize(14)
          .fontColor($r('app.color.common_color_3'))
          .maxLines(1)
          .margin({ left: 8 })
      }
      .width('100%')
      .margin({ top: 27, left: 12, right: 12 })
      .alignItems(VerticalAlign.Center)
      Text(item.MESSAGE)
        .fontSize(16)
        .fontColor($r('app.color.common_color_1'))
        .width('100%')
        .margin({ top: 19, bottom: 19, left: 28, right: 19 })
    }
    .width('100%')
    .backgroundColor($r('app.color.white'))
    Divider()
      .color($r('app.color.common_color_3'))
      .strokeWidth(0.5)
      .width('100%')
  }

  /** MeetingAnnouncementHeaderView（canRelease）：标题 + 提示条 + 输入框 + 确定 */
  @Builder
  releaseHeader() {
    Column() {
      Column() {
        Text('“' + this.meetingTitle + '”')
          .fontSize(18)
          .fontColor($r('app.color.mobile_campus_primary_color_default'))
          .textAlign(TextAlign.Center)
          .width('100%')
          .height(64)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        Text('在这里您可以发送公告给所有参会人员，\n参会人员会收到公告。')
          .fontSize(13)
          .fontColor($r('app.color.common_color_1'))
          .textAlign(TextAlign.Center)
          .width('100%')
          .height(60)
          .backgroundColor($r('app.color.mobile_campus_bg_color'))
          .borderRadius(4)
          .margin({ bottom: 16 })
        TextArea({ text: this.draftMessage, placeholder: '输入公告内容...' })
          .fontSize(16)
          .fontColor($r('app.color.common_color_1'))
          .backgroundColor($r('app.color.mobile_campus_bg_color'))
          .width('100%')
          .height(103)
          .padding({ left: 10, right: 10, top: 8, bottom: 8 })
          .margin({ bottom: 16 })
          .onChange((value: string) => {
            this.draftMessage = value;
          })
        Text(this.submitting ? '提交中...' : '确定')
          .fontSize(17)
          .fontColor($r('app.color.white'))
          .textAlign(TextAlign.Center)
          .width('100%')
          .height(44)
          .borderRadius(20)
          .backgroundColor($r('app.color.mobile_campus_primary_color_default'))
          .onClick(() => {
            this.submitDraft();
          })
      }
      .width('100%')
      .padding({ left: 12, right: 12, bottom: 13 })
      .backgroundColor($r('app.color.white'))
    }
    .width('100%')
    .backgroundColor($r('app.color.white'))
  }
}
