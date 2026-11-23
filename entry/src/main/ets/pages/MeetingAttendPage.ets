import { router } from '@kit.ArkUI';
import { ApiService } from '../network/ApiService';
import { ApiResponse } from '../model/ResponseModel';
import { BusinessError } from '@kit.BasicServicesKit';
import { TitleBar } from '../components/TitleBar';
import { MeetingSignQrEntity } from '../model/MeetingApiModel';
import { BreakpointSystem } from '../common/BreakpointSystem';

/**
 * 会议签到页（扫码结果页）— MeetingAttendActivity.java(115行) 源码级翻译
 * 【源码链路】MeetingDetailActivity 扫码（ScanBookQRNewActivity requestCode 415）→ onActivityResult
 *   → g2(d0) bundle{result} → MeetingAttendActivity.y(intent)：l=result JSON 串，
 *   o=Sign.meetingId（gson 解析 {"qrcode_type":"meetingPlan_sign","meetingId"}）。
 * 【布局】mobile_campus_meeting_activity_attend.xml：toolbar("会议签到") + MultiStateView
 *   + RelativeLayout：ic_attend 图居中 marginTop px_to_dip_158=79vp；tvAttend "签到" 主色圆角
 *   44vp（marginLeft/Right 12、marginBottom px_to_dip_74=37vp，alignParentBottom）。
 * 【动作】K2() → MeetingPImpl.i0().m0(o) → MeetingModel.p1：POST sign {hyid}。
 *   回调 a.g()：服务器 msg(str3) 非空 → toast str3；空 → "签到成功" + setResult(-1)；
 *   a.f() 失败 → toast str3(msg)。源码 onStart 即 finish（HAP：结果 toast 后返回）。
 * 【空态】无 result 参数（HAP 未启动扫码或 result 缺失）→ 显示页面但无 meetingId，
 *   点击签到如实返回服务器校验结果，不编造。
 */
@Entry
@Component
struct MeetingAttendPage {
  /** 源码 o：Sign.meetingId（扫码 result 解析） */
  private meetingId: string = '';
  @State hasQrResult: boolean = false;
  @State submitting: boolean = false;
  @StorageProp('currentBreakpoint') currentBreakpoint: string = 'sm';
  @StorageProp('avoidAreaBottomVp') avoidAreaBottomVp: number = 0;
  @StorageProp('avoidAreaLeftVp') avoidAreaLeftVp: number = 0;
  @StorageProp('avoidAreaRightVp') avoidAreaRightVp: number = 0;

  aboutToAppear(): void {
    // 源码 y(intent)：l=result；TextUtils.isEmpty → 仅保存；否则 gson 解析 Sign.meetingId
    const params: object | undefined = router.getParams() as object | undefined;
    if (params !== null && params !== undefined) {
      const record = params as Record<string, Object>;
      const v: Object | undefined = record['result'];
      if (typeof v === 'string') {
        const raw = v as string;
        if (raw !== '') {
          try {
            const qr: MeetingSignQrEntity = JSON.parse(raw) as MeetingSignQrEntity;
            this.meetingId = qr.meetingId === undefined || qr.meetingId === null ? '' : qr.meetingId;
            this.hasQrResult = true;
          } catch (error) {
            const err = error as BusinessError;
            ApiService.logError('MeetingAttendPage parse result fail: ' + err.message);
          }
        }
      }
    }
  }

  /** 源码 K2()：m.i0(new a(String.class)).m0(o) → POST sign {hyid}；回调成功后返回详情页 */
  private submitSign(): void {
    if (this.submitting) {
      return;
    }
    this.submitting = true;
    ApiService.signMeeting(this.meetingId)
      .then((response: ApiResponse<string>) => {
        this.submitting = false;
        if (response.code === 0) {
          // 源码 a.g()：str3 非空 → toast str3；空 → "签到成功" + setResult(-1)
          this.toast(response.data === '' ? '签到成功' : response.data);
          router.back();
        } else {
          // 源码 a.f()：toast msg
          this.toast(response.message === '' ? '签到失败' : response.message);
        }
      })
      .catch((error: BusinessError) => {
        ApiService.logError('MeetingAttendPage sign fail: ' + error.message);
        this.submitting = false;
        this.toast('网络请求失败');
      });
  }

  private toast(message: string): void {
    this.getUIContext().getPromptAction().showToast({ message: message });
  }

  build() {
    Column() {
      TitleBar({ title: '会议签到', showBack: true })

      // RelativeLayout：ic_attend 居中（top 79vp）+ tvAttend 底部（left/right 12、bottom 37vp）
      Scroll() {
        Column() {
          Column() {
            Image($r('app.media.mobile_campus_meeting_ic_attend'))
              .width(160)
              .height(160)
              .objectFit(ImageFit.Contain)
              .margin({ top: 79 })
            if (!this.hasQrResult) {
              Text('未获取到扫码签到结果')
                .fontSize(14)
                .fontColor($r('app.color.common_color_3'))
                .margin({ top: 16 })
            }
          }
          .width('100%')
          .alignItems(HorizontalAlign.Center)

          Text(this.submitting ? '签到中...' : '签到')
            .fontSize(17)
            .fontColor($r('app.color.white'))
            .textAlign(TextAlign.Center)
            .width('100%')
            .height(44)
            .borderRadius(4)
            .margin({ top: 24 })
            .backgroundColor($r('app.color.mobile_campus_primary_color_default'))
            .onClick(() => {
              this.submitSign();
            })
        }
        .width('100%')
        .constraintSize({
          minHeight: '100%',
          maxWidth: BreakpointSystem.getContentMaxWidth(this.currentBreakpoint)
        })
        .alignSelf(ItemAlign.Center)
        .justifyContent(FlexAlign.SpaceBetween)
        .padding({
          left: Math.max(12, this.avoidAreaLeftVp),
          right: Math.max(12, this.avoidAreaRightVp),
          bottom: 37 + this.avoidAreaBottomVp
        })
        .backgroundColor($r('app.color.white'))
      }
      .width('100%')
      .layoutWeight(1)
      .scrollBar(BarState.Off)
      .align(Alignment.Top)
      .backgroundColor($r('app.color.white'))
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.white'))
  }
}
