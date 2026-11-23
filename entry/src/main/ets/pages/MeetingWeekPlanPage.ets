import { router } from '@kit.ArkUI';
import { scanBarcode, scanCore } from '@kit.ScanKit';
import { ApiService } from '../network/ApiService';
import { ApiResponse } from '../model/ResponseModel';
import { BusinessError } from '@kit.BasicServicesKit';
import { TitleBar } from '../components/TitleBar';
import { LoadingView } from '../components/LoadingView';
import { EmptyView } from '../components/EmptyView';
import { MeetingWeekDetailEntity } from '../model/MeetingApiModel';

/**
 * 周程会议详情页 — MeetingWeekDetailActivity.java(247行) 源码级翻译
 * 【映射表勘误】本页 APK 源码 = MeetingWeekDetailActivity（路由 a0=/meeting/weekdetail），
 *   映射表原标注 MeetingWeekPlanFragment 有误：该 Fragment 是 MeetingMainActivity"周程会议"页签，
 *   已由 E3 完整翻进 MeetingPage（MeetingWeekPlanFragment.java 234 行），页面拆分见 review_E3。
 * 【源码链路】MeetingPage 子项点击（TASK_TYPE=weekPlan → bundle{xlh}）/ 周程列表点击 →
 *   MeetingWeekDetailActivity.y(intent)：t=IS_JOIN、u=appInfo.XLH 或 r="xlh" → f1() →
 *   Y2() = MeetingPImpl.e0(new a(MeetingWeekDetail.class)).K(r) → MeetingModel.i1：
 *   GET getWeekPlanDetails {xlh} → MeetingWeekDetail。
 * 【布局】mobile_campus_meeting_activity_week_detail.xml：toolbar + MultiStateView(#F2F2F2)
 *   + ScrollView(detailView + detailFileView gone) + layoutBottom 底栏。
 * 【detailView】WeekPlanWeekDetailView.setData（mobile_campus_meeting_view_weekplan_detail.xml，
 *   与 MeetingDetailActivity 同款视图）：tvTitle=ZT(19fp) + 行项（非空才加）：
 *   会议地点(DD)/会议时间(KSSJ\nJSSJ 恒显)/举办单位(ZBDW)/主持人(ZCR topMargin12)/
 *   联系电话(LXDH)/参会人员(CYRY)/备注(BZ)。
 * 【底栏】widget.d(MobileDetailBottomBtnView)：f1 里 k(0)（不覆盖 XML arrow_up 图标）；
 *   初始文案 XML="查看参会情况"；详情成功回调 m(IS_MY_WEEK_PLAN=="0"?"添加到个人会议":"取消添加到个人会议")；
 *   点击 c：s!=null → IS_MY_WEEK_PLAN=="0" → W2()=i0().w(r) → MeetingModel.U0 POST addMyWeekPlan {xlh}
 *   成功 → s.IS_MY_WEEK_PLAN="1" + "已将该会议添加到首页【我的会议】"；否则 X2()=i0().z(r) →
 *   MeetingModel.X0 POST cancelWeekPlan {xlh} 成功 → "已将该会议取消添加到个人会议"。
 * 【右上图标】toolbar gVar.k(mobile_campus_meeting_scan)，成功回调 p.setVisibility(0)（初始 gone）；
 *   点击 b：s!=null → 扫码（ScanBookQRNewActivity, requestCode 415）→ onActivityResult(415)
 *   → h2(d0=/meeting/attend, 无 bundle) → MeetingAttendPage（无 result 走服务器校验）。
 * 【接口实测】probe_w18_meeting_remain.py：getWeekPlanDetails 真实 xlh code=0 全字段；
 *   addMyWeekPlan 无效 xlh code=2014"周程详情出错"/cancelWeekPlan code=2004（写端点连通，不真实写入）。
 * 【数据规则】禁止 mock；失败/空态走真实空态。
 */
@Entry
@Component
struct MeetingWeekPlanPage {
  /** 周程详情数据（源码 s） */
  @State detail: MeetingWeekDetailEntity = new MeetingWeekDetailEntity();
  /** 加载/失败/空态（MultiStateView） */
  @State loading: boolean = true;
  @State loadFail: boolean = false;
  @State isEmpty: boolean = false;
  /** 底栏文案（源码 widget.d.m；初始 XML 文案） */
  @State bottomBtnText: string = '查看参会情况';
  /** 详情成功后扫码图标可见（源码 p.setVisibility(0)） */
  @State scanVisible: boolean = false;
  private xlh: string = '';

  aboutToAppear(): void {
    // 源码 y(intent)：appInfo.XLH 优先，否则 intent "xlh"（HAP 直传 xlh）
    const params: object | undefined = router.getParams() as object | undefined;
    if (params !== null && params !== undefined) {
      const record = params as Record<string, Object>;
      const v: Object | undefined = record['xlh'];
      if (typeof v === 'string') {
        this.xlh = v as string;
      }
    }
    this.loadDetail();
  }

  /** 源码 onActivityResult(415) 等价：从签到页返回（扫码成功跳 attend 无参） */
  onPageShow(): void {
    // 源码 414 分支（p.setVisibility(8)）发起方不在本 Activity 源码内，HAP 无对应链路，保留语义注释
  }

  /** 源码 Y2()：l.e0(new a).K(r) → MeetingModel.i1 GET getWeekPlanDetails {xlh} */
  private loadDetail(): void {
    if (this.xlh === '') {
      this.loadFail = true;
      this.loading = false;
      return;
    }
    ApiService.getMeetingWeekPlanDetails(this.xlh)
      .then((response: ApiResponse<MeetingWeekDetailEntity>) => {
        if (response.code === 1000) {
          // 登录失效统一处理已在网络层触发（HttpClient.bizRequest 拦截：清会话+toast+跳登录）
          this.loading = false;
          return;
        }
        if (response.code === 0 && response.data.ZT !== '') {
          // 源码 a.g()：o.setData + s=meetingWeekDetail + 底栏文案 + 扫码图标可见
          this.detail = response.data;
          this.loadFail = false;
          this.isEmpty = false;
          this.bottomBtnText = response.data.IS_MY_WEEK_PLAN === '0' ? '添加到个人会议' : '取消添加到个人会议';
          this.scanVisible = true;
        } else if (response.code === 0) {
          // 源码 a.g() data==null → q2(n) 空态
          this.isEmpty = true;
        } else {
          this.loadFail = true;
        }
        this.loading = false;
      })
      .catch((error: BusinessError) => {
        ApiService.logError('MeetingWeekPlanPage loadDetail fail: ' + error.message);
        this.loadFail = true;
        this.loading = false;
      });
  }

  /** 源码 c.onClick：s!=null → IS_MY_WEEK_PLAN=="0" 添加，否则取消 */
  private onBottomBtnClick(): void {
    if (this.detail.XLH === '' && this.detail.ZT === '') {
      return;
    }
    if (this.detail.IS_MY_WEEK_PLAN === '0') {
      this.submitAddWeekPlan();
    } else {
      this.submitCancelWeekPlan();
    }
  }

  /** 源码 W2() → MeetingPImpl.i0(new e).w(r) → MeetingModel.U0：POST addMyWeekPlan {xlh} */
  private submitAddWeekPlan(): void {
    ApiService.addMyWeekPlan(this.xlh)
      .then((response: ApiResponse<string>) => {
        if (response.code === 1000) {
          return;
        }
        if (response.code === 0) {
          // 源码 e.g()：s.IS_MY_WEEK_PLAN="1" + 底栏重建 + 文案 + toast
          this.detail.IS_MY_WEEK_PLAN = '1';
          this.bottomBtnText = '取消添加到个人会议';
          this.toast('已将该会议添加到首页【我的会议】');
        } else {
          // 源码 e.f(str2)：m(str2) toast 服务器文案
          this.toast(response.message === '' ? '添加失败' : response.message);
        }
      })
      .catch((error: BusinessError) => {
        ApiService.logError('MeetingWeekPlanPage addMyWeekPlan fail: ' + error.message);
        this.toast('添加失败');
      });
  }

  /** 源码 X2() → MeetingPImpl.i0(new d).z(r) → MeetingModel.X0：POST cancelWeekPlan {xlh} */
  private submitCancelWeekPlan(): void {
    ApiService.cancelWeekPlan(this.xlh)
      .then((response: ApiResponse<string>) => {
        if (response.code === 1000) {
          return;
        }
        if (response.code === 0) {
          // 源码 d.g()：s.IS_MY_WEEK_PLAN="0" + 文案 + toast
          this.detail.IS_MY_WEEK_PLAN = '0';
          this.bottomBtnText = '添加到个人会议';
          this.toast('已将该会议取消添加到个人会议');
        } else {
          this.toast(response.message === '' ? '取消失败' : response.message);
        }
      })
      .catch((error: BusinessError) => {
        ApiService.logError('MeetingWeekPlanPage cancelWeekPlan fail: ' + error.message);
        this.toast('取消失败');
      });
  }

  /** 源码 b.onClick：s!=null → 扫码（ScanBookQRNewActivity 415）→ 成功跳 attend（无参） */
  private onScanClick(): void {
    if (this.detail.ZT === '' && this.detail.XLH === '') {
      return;
    }
    const options: scanBarcode.ScanOptions = { scanTypes: [scanCore.ScanType.QR_CODE] };
    scanBarcode.startScan(options)
      .then((_result: scanBarcode.ScanResult) => {
        // 源码 onActivityResult(415)：h2(d0=/meeting/attend, null) → MeetingAttendPage 无 result
        this.pushRoute('pages/MeetingAttendPage', {});
      })
      .catch((error: BusinessError) => {
        ApiService.logError('MeetingWeekPlanPage startScan fail: ' + error.message);
      });
  }

  private pushRoute(url: string, params: Record<string, Object>): void {
    try {
      router.pushUrl({ url: url, params: params }).catch((error: BusinessError) => {
        ApiService.logError('MeetingWeekPlanPage route fail @' + url + ': ' + error.message);
      });
    } catch (error) {
      const err = error as BusinessError;
      ApiService.logError('MeetingWeekPlanPage route throw @' + url + ': ' + err.message);
    }
  }

  private toast(message: string): void {
    this.getUIContext().getPromptAction().showToast({ message: message });
  }

  // 登录失效统一处理已下沉网络层（HttpClient.bizRequest code=1000 拦截），页面 1000 分支只 return

  build() {
    Stack() {
      Column() {
        TitleBar({ title: '会议详情', showBack: true })
        // 右上扫码图标（toolbar gVar.k）：详情成功回调才可见（源码 p.setVisibility(0)）
        if (this.scanVisible && !this.loading && !this.loadFail && !this.isEmpty) {
          Image($r('app.media.mobile_campus_meeting_scan'))
            .width(20)
            .height(20)
            .margin({ right: 15 })
            .onClick(() => {
              this.onScanClick();
            })
        }
        if (this.loading) {
          LoadingView()
        } else if (this.isEmpty) {
          EmptyView({ tipText: '暂无会议详情' })
        } else if (this.loadFail || this.detail.ZT === '') {
          EmptyView({ tipText: '获取会议详情失败' })
        } else {
          this.contentView()
        }
      }
      .width('100%')
      .height('100%')
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.mobile_campus_bg_color'))
    .alignContent(Alignment.Center)
  }

  /** mobile_campus_meeting_activity_week_detail.xml：ScrollView(detailView) + layoutBottom 底栏 */
  @Builder
  contentView() {
    Column() {
      Scroll() {
        Column() {
          this.weekDetailView()
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)
      }
      .width('100%')
      .layoutWeight(1)
      .scrollBar(BarState.Off)
      .align(Alignment.Top)

      // layoutBottom：widget.d（mobile_campus_meeting_view_detail_btn 白底 48dip）
      this.bottomBar()
    }
    .width('100%')
    .height('100%')
  }

  /** WeekPlanWeekDetailView.setData：tvTitle=ZT + 行项（非空才加，顺序同源码） */
  @Builder
  weekDetailView() {
    Column() {
      Text(this.detail.ZT)
        .fontSize(19)
        .fontColor($r('app.color.common_color_1'))
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .width('100%')
        .padding({ left: 18, right: 18, top: 19, bottom: 15 })
      Divider()
        .color($r('app.color.mobile_campus_bg_color'))
        .strokeWidth(0.5)
        .width('100%')
      Column() {
        if (this.detail.DD !== '') {
          this.detailRow($r('app.media.mobile_campus_meeting_local_2'), '会议地点', this.detail.DD, 0)
        }
        // 源码：会议时间行恒显（无判空）
        this.detailRow($r('app.media.mobile_campus_meeting_time_2'), '会议时间',
          this.detail.KSSJ + '\n' + this.detail.JSSJ, 0)
        if (this.detail.ZBDW !== '') {
          this.detailRow($r('app.media.mobile_campus_meeting_class'), '举办单位', this.detail.ZBDW, 0)
        }
        if (this.detail.ZCR !== '') {
          // 源码：主持人行 topMargin 12dip
          this.detailRow($r('app.media.mobile_campus_meeting_staff'), '主持人', this.detail.ZCR, 12)
        }
        if (this.detail.LXDH !== '') {
          // 源码：WeekPlanWeekDetailView 未调用 enablePhoneLink → 普通行（不发短信场景）
          this.detailRow($r('app.media.mobile_campus_meeting_contact_number'), '联系电话', this.detail.LXDH, 0)
        }
        if (this.detail.CYRY !== '') {
          this.detailRow($r('app.media.mobile_campus_meeting_staff'), '参会人员', this.detail.CYRY, 0)
        }
        if (this.detail.BZ !== '') {
          this.detailRow($r('app.media.mobile_campus_meeting_edit'), '备注', this.detail.BZ, 0)
        }
      }
      .width('100%')
      .margin({ top: 12 })
      .padding({ bottom: 6 })
      .backgroundColor($r('app.color.white'))
    }
    .width('100%')
    .backgroundColor($r('app.color.white'))
  }

  /** WeekPlanDetailItemView 复刻（与 MeetingDetailActivity 同款视图，样式对齐 MeetingDetailPage.detailRow） */
  @Builder
  detailRow(icon: Resource, label: string, value: string, topMargin: number) {
    Row() {
      Image(icon)
        .width(12)
        .height(12)
        .margin({ right: 6 })
      Text(label)
        .fontSize(12)
        .fontColor($r('app.color.common_color_3'))
        .width(56)
      Text(value)
        .fontSize(13)
        .fontColor($r('app.color.common_color_1'))
        .layoutWeight(1)
        .maxLines(7)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
    }
    .width('100%')
    .padding({ left: 18, right: 18, top: 8, bottom: 8 })
    .alignItems(VerticalAlign.Top)
    .margin({ top: topMargin })
  }

  /** mobile_campus_meeting_view_detail_btn：白底 48dip + tvSituation 16fp 主色（icon 源码 k(0) 不覆盖 XML arrow_up） */
  @Builder
  bottomBar() {
    Column() {
      Divider()
        .color($r('app.color.common_color_5'))
        .strokeWidth(0.5)
        .width('100%')
      Text(this.bottomBtnText)
        .fontSize(16)
        .fontColor($r('app.color.mobile_campus_primary_color_default'))
        .textAlign(TextAlign.Center)
        .width('100%')
        .height(47.5)
        .onClick(() => {
          this.onBottomBtnClick();
        })
    }
    .width('100%')
    .height(48)
    .backgroundColor($r('app.color.white'))
  }
}
