import { router } from '@kit.ArkUI';
import { generateBarcode } from '@kit.ScanKit';
import { scanCore } from '@kit.ScanKit';
import { image } from '@kit.ImageKit';
import { ApiService } from '../network/ApiService';
import { ApiResponse } from '../model/ResponseModel';
import { BusinessError } from '@kit.BasicServicesKit';
import { TitleBar } from '../components/TitleBar';
import { LoadingView } from '../components/LoadingView';
import { EmptyView } from '../components/EmptyView';
import { SignUserEntity } from '../model/MeetingApiModel';
import { BreakpointSystem } from '../common/BreakpointSystem';
import { AdaptiveLayoutHelper } from '../common/AdaptiveLayoutHelper';

/**
 * 会议签到管理页 — MeetingSignActivity.java(350行) 源码级翻译
 * 【源码链路】MeetingDetailActivity 右上 qrcode 图（本人发起）→ e0 bundle{HYID} → y(intent)：r=HYID。
 * 【布局】mobile_campus_meeting_activity_sign.xml（bg #F2F2F2）：toolbar("签到") + MultiStateView
 *   + ScrollView：白底 QR 区（imgQRCode 200×200dip marginTop 23 + "扫描二维码签到"）+ 双
 *   MeetingSignGridView（marginTop 12：tvTitle 40dip + 细分隔线 + GridView numColumns 5）。
 * 【QR 内容】f1()：gson(Sign{qrcode_type:"meetingPlan_sign", meetingId:r}) 生成二维码
 *   （HAP 用 @kit.ScanKit generateBarcode.createBarcode 等价生成，无新依赖）。
 * 【名单】a3()=GET getSignUser{hyid}（已签，showType 0 → itemState1 删减角标，点击 noSign）；
 *   b3()=GET getNoSignUser{hyid}（未签，showType 1 → itemState0 对勾角标，点击 toSign）。
 *   标题计数：showType 0/2 → "已签到情况（N人）"；1 → "未签到情况（N人）"。
 * 【点击】未签→POST toSign{hyid,yhid} 成功首位移入已签 + "签到成功"；已签→POST noSign{hyid,yhid}
 *   成功首位移入未签 + "已经取消签到"；失败 toast "签到失败"/"取消签到失败"（g/h 回调）。
 * 【长按 QR】d3(r) → POST sign{hyid}（本人签到）→ 成功 a3()+b3() + "签到成功"。
 * 【头像】MeetingSignAdapter.setTextBackground：i%4 轮换 green/pink/yellow/blue_circle 底色，
 *   显示 YHNAME 首字；源码 itemState 2 → imgMinus 无图标。
 * 【实测】getSignUser/getNoSignUser 管道通（probe_w13_meeting_series2.py）；测试账号无会议 →
 *   无真实 HYID → 名单走真实空数据，不编造。
 */
@Entry
@Component
struct MeetingSignPage {
  /** 源码 r：会议 HYID */
  private hyid: string = '';
  /** 源码 p：已签名单 */
  @State signUsers: SignUserEntity[] = [];
  /** 源码 q：未签名单 */
  @State noSignUsers: SignUserEntity[] = [];
  /** QR PixelMap（generateBarcode 生成） */
  @State qrPixelMap: image.PixelMap | undefined = undefined;
  @State loading: boolean = true;
  @State loadFail: boolean = false;
  @StorageProp('currentBreakpoint') currentBreakpoint: string = 'sm';
  @StorageProp('avoidAreaBottomVp') avoidAreaBottomVp: number = 0;

  aboutToAppear(): void {
    // 源码 y(intent)：r = intent "HYID"
    const params: object | undefined = router.getParams() as object | undefined;
    if (params !== null && params !== undefined) {
      const record = params as Record<string, Object>;
      const v: Object | undefined = record['HYID'];
      if (typeof v === 'string') {
        this.hyid = v as string;
      }
    }
    this.buildQrCode();
    this.loadSignUsers();
    this.loadNoSignUsers();
  }

  /** 源码 f1()：t.a(context, gson(Sign{...})) → imgQRCode；HAP 用 ScanKit generateBarcode */
  private buildQrCode(): void {
    if (this.hyid === '') {
      return;
    }
    const qrJson: string = JSON.stringify({
      'qrcode_type': 'meetingPlan_sign',
      'meetingId': this.hyid
    } as Record<string, string>);
    const options: generateBarcode.CreateOptions = {
      scanType: scanCore.ScanType.QR_CODE,
      height: 600,
      width: 600,
      margin: 8
    };
    generateBarcode.createBarcode(qrJson, options)
      .then((pixelMap: image.PixelMap) => {
        this.qrPixelMap = pixelMap;
      })
      .catch((error: BusinessError) => {
        ApiService.logError('MeetingSignPage createBarcode fail: ' + error.message);
      });
  }

  /** 源码 a3()：s.h0(new e(SignUser.class)).H(r) → GET getSignUser {hyid} */
  private loadSignUsers(): void {
    ApiService.getMeetingSignUser(this.hyid)
      .then((response: ApiResponse<SignUserEntity[]>) => {
        if (response.code === 0) {
          this.signUsers = response.data;
          this.loadFail = false;
        } else {
          this.signUsers = [];
          this.loadFail = true;
        }
        this.loading = false;
      })
      .catch((error: BusinessError) => {
        ApiService.logError('MeetingSignPage loadSignUsers fail: ' + error.message);
        this.signUsers = [];
        this.loadFail = true;
        this.loading = false;
      });
  }

  /** 源码 b3()：s.k0(new f(SignUser.class)).I(r) → GET getNoSignUser {hyid} */
  private loadNoSignUsers(): void {
    ApiService.getMeetingNoSignUser(this.hyid)
      .then((response: ApiResponse<SignUserEntity[]>) => {
        if (response.code === 0) {
          this.noSignUsers = response.data;
        } else {
          this.noSignUsers = [];
          this.loadFail = true;
        }
        this.loading = false;
      })
      .catch((error: BusinessError) => {
        ApiService.logError('MeetingSignPage loadNoSignUsers fail: ' + error.message);
        this.noSignUsers = [];
        this.loadFail = true;
        this.loading = false;
      });
  }

  /** 源码 e3(xlh, yhid, i)：s.j0(new g).n0(str, str2) → POST toSign；成功未签首位移入已签 */
  private signOneUser(yhid: string): void {
    ApiService.toSignMeeting(this.hyid, yhid)
      .then((response: ApiResponse<string>) => {
        if (response.code === 0) {
          const moved: SignUserEntity | undefined = this.removeUser(this.noSignUsers, yhid);
          if (moved !== undefined) {
            this.signUsers = [moved, ...this.signUsers];
          }
          this.toast('签到成功');
        } else {
          this.toast('签到失败');
        }
      })
      .catch((error: BusinessError) => {
        ApiService.logError('MeetingSignPage toSign fail: ' + error.message);
        this.toast('签到失败');
      });
  }

  /** 源码 f3(xlh, yhid, i)：s.d0(new h).o0(str, str2) → POST noSign；成功已签首位移入未签 */
  private unSignOneUser(yhid: string): void {
    ApiService.noSignMeeting(this.hyid, yhid)
      .then((response: ApiResponse<string>) => {
        if (response.code === 0) {
          const moved: SignUserEntity | undefined = this.removeUser(this.signUsers, yhid);
          if (moved !== undefined) {
            this.noSignUsers = [moved, ...this.noSignUsers];
          }
          this.toast('已经取消签到');
        } else {
          this.toast('取消签到失败');
        }
      })
      .catch((error: BusinessError) => {
        ApiService.logError('MeetingSignPage noSign fail: ' + error.message);
        this.toast('取消签到失败');
      });
  }

  /** 源码 d3(r)：长按 QR → s.i0(new d).m0(r) → POST sign{hyid}（本人签到） */
  private signSelf(): void {
    ApiService.signMeeting(this.hyid)
      .then((response: ApiResponse<string>) => {
        if (response.code === 0) {
          this.loadSignUsers();
          this.loadNoSignUsers();
          this.toast('签到成功');
        } else {
          this.toast('签到失败');
        }
      })
      .catch((error: BusinessError) => {
        ApiService.logError('MeetingSignPage signSelf fail: ' + error.message);
        this.toast('签到失败');
      });
  }

  /** g/h 回调：q.remove(i)→p.add(0) / p.remove(i)→q.add(0)（按 YHID 定位） */
  private removeUser(list: SignUserEntity[], yhid: string): SignUserEntity | undefined {
    for (let i = 0; i < list.length; i++) {
      if (list[i].YHID === yhid) {
        const moved: SignUserEntity = list[i];
        const rest: SignUserEntity[] = list.slice(0, i).concat(list.slice(i + 1));
        if (list === this.signUsers) {
          this.signUsers = rest;
        } else {
          this.noSignUsers = rest;
        }
        return moved;
      }
    }
    return undefined;
  }

  /** 源码 setTextBackground：i%4 → green/pink/yellow/blue_circle 底色
   *  （drawable 实测：green_circle #92D860 / pink_circle #FF8080 / yellow_circle #FFD11F / blue_circle #97D0F2） */
  private avatarColor(index: number): ResourceColor {
    const mod: number = index % 4;
    if (mod === 0) {
      return '#FF92D860';
    }
    if (mod === 1) {
      return '#FFFF8080';
    }
    if (mod === 2) {
      return '#FFFFD11F';
    }
    return '#FF97D0F2';
  }

  private toast(message: string): void {
    this.getUIContext().getPromptAction().showToast({ message: message });
  }

  build() {
    Column() {
      TitleBar({ title: '签到', showBack: true })

      if (this.loading) {
        LoadingView()
      } else {
        Scroll() {
          Column() {
            this.qrSection()
            this.signGrid(true)
            this.signGrid(false)
          }
          .width('100%')
          .constraintSize({ maxWidth: BreakpointSystem.getContentMaxWidth(this.currentBreakpoint) })
          .alignSelf(ItemAlign.Center)
          .padding({ bottom: this.avoidAreaBottomVp })
          .alignItems(HorizontalAlign.Start)
        }
        .width('100%')
        .layoutWeight(1)
        .scrollBar(BarState.Off)
        .align(Alignment.Top)
        .backgroundColor($r('app.color.mobile_campus_bg_color'))
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.mobile_campus_bg_color'))
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.BOTTOM])
  }

  /** activity_sign 顶部 QR 区：白底 + imgQRCode 200×200(mt23) + "扫描二维码签到"（长按自签） */
  @Builder
  qrSection() {
    Column() {
      Image(this.qrPixelMap)
        .width(200)
        .height(200)
        .objectFit(ImageFit.Fill)
        .margin({ top: 23 })
        .gesture(LongPressGesture().onAction(() => {
          this.signSelf();
        }))
      Text('扫描二维码签到')
        .fontSize(14)
        .fontColor($r('app.color.common_color_1'))
        .margin({ top: 14, bottom: 14 })
    }
    .width('100%')
    .alignItems(HorizontalAlign.Center)
    .backgroundColor($r('app.color.white'))
  }

  /** MeetingSignGridView：tvTitle(40dip) + 分隔线 + 5 列网格（isSign=已签组） */
  @Builder
  signGrid(isSign: boolean) {
    Column() {
      Text(isSign ? '已签到情况（' + String(this.signUsers.length) + '人）'
        : '未签到情况（' + String(this.noSignUsers.length) + '人）')
        .fontSize(14)
        .fontColor($r('app.color.common_color_1'))
        .width('100%')
        .height(40)
        .padding({ left: 12, right: 12 })
      Divider()
        .color($r('app.color.common_color_5'))
        .strokeWidth(0.5)
        .width('100%')
      if (isSign ? this.signUsers.length === 0 : this.noSignUsers.length === 0) {
        EmptyView({ tipText: '暂无人员' })
      } else {
        Grid() {
          if (isSign) {
            ForEach(this.signUsers, (user: SignUserEntity, index: number) => {
              this.signCell(user, index, true)
            }, (user: SignUserEntity) => 'sign_' + user.YHID)
          } else {
            ForEach(this.noSignUsers, (user: SignUserEntity, index: number) => {
              this.signCell(user, index, false)
            }, (user: SignUserEntity) => 'nosign_' + user.YHID)
          }
        }
        .columnsTemplate(AdaptiveLayoutHelper.buildColumnsTemplate(
          BreakpointSystem.getGridColumns(this.currentBreakpoint, 5)
        ))
        .width('100%')
        .height(AdaptiveLayoutHelper.computeGridHeightVp(
          isSign ? this.signUsers.length : this.noSignUsers.length,
          BreakpointSystem.getGridColumns(this.currentBreakpoint, 5),
          92,
          0,
          8
        ))
        .padding({ left: 12, right: 12 })
        .backgroundColor($r('app.color.white'))
      }
    }
    .width('100%')
    .margin({ top: 12 })
    .backgroundColor($r('app.color.white'))
  }

  /** item_view_staff_situation_horizontal：36dip 圆头像字 + 角标（已签=delete2/未签=tick）+ tvName */
  @Builder
  signCell(user: SignUserEntity, index: number, isSign: boolean) {
    Column() {
      Stack({ alignContent: Alignment.TopEnd }) {
        Column() {
          Text(user.YHNAME === '' ? '' : user.YHNAME.substring(0, 1))
            .fontSize(18)
            .fontColor($r('app.color.ybg_white'))
            .width(36)
            .height(36)
            .textAlign(TextAlign.Center)
            .borderRadius(18)
            .backgroundColor(this.avatarColor(index))
        }
        .padding({ top: 12, bottom: 8 })
        Image(isSign ? $r('app.media.mobile_campus_meeting_delete2')
          : $r('app.media.mobile_campus_meeting_tick'))
          .width(16)
          .height(16)
          .offset({ x: 8, y: 4 })
      }
      .width('100%')
      Text(user.YHNAME)
        .fontSize(13)
        .fontColor($r('app.color.common_color_1'))
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .margin({ bottom: 15 })
    }
    .alignItems(HorizontalAlign.Center)
    .padding({ left: 11, right: 11 })
    .hoverEffect(HoverEffect.Highlight)
    .onClick(() => {
      if (isSign) {
        this.unSignOneUser(user.YHID);
      } else {
        this.signOneUser(user.YHID);
      }
    })
  }
}
