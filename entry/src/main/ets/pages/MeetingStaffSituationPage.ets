import { router } from '@kit.ArkUI';
import { ApiService } from '../network/ApiService';
import { ApiResponse } from '../model/ResponseModel';
import { BusinessError } from '@kit.BasicServicesKit';
import { TitleBar } from '../components/TitleBar';
import { LoginSession } from '../network/LoginSession';
import { MeetingExtraEntity, MeetingExtraDataEntity } from '../model/MeetingApiModel';

/**
 * 参会人员情况页 — MeetingStaffSituationActivity.java(186行) 源码级翻译
 * 【源码链路】MeetingDetailActivity.e.d.b()（底栏"查看参会情况"）：
 *   bundle{xlh, HYID} + com.lysoft.android.lyyd.base.i.e.a.k(v.EXTRA)（静态内存共享参会人员数据）
 *   → h2(f0=/meeting/staffsituation) → 本页。
 * 【数据源】本 Activity 无网络请求：y(intent) 存 xlh/HYID，q = i.e.a.j()（详情页共享的
 *   ArrayList<MeetingObj.EXTRABean>）→ HAP 等价 = AppStorage 'meeting_staff_extra'（详情页写入）。
 * 【布局】mobile_campus_meeting_activity_staff_situation.xml：toolbar（标题"参会人员情况"
 *   + 右上 mobile_campus_meeting_qrcode 图标 → MeetingSignPage{HYID}）+ MultiStateView(#F2F2F2)
 *   + ExpandableListView（expandGroup(i) 恒展开）+ layoutContainer 底栏。
 * 【分组】MeetingStaffSituationAdapter（adapter/b.java）组头 40dip 白底 padL12 + 0.5 分隔线
 *   + marginTop 12：JOIN_LIST="拟参加（N人）"/UNCONFIRMED_LIST="未回应是否参加（N人）"/
 *   NO_JOIN_LIST="不参加（N人）"/SEND_MESSAGE_LIST="外部人员信息发送情况"。
 * 【子项】getChildType：JOIN_LIST/UNCONFIRMED_LIST → 横向 GridView（MeetingStaffHorizontalAdapter：
 *   36dip 四色圆 i%4 green#92D860/pink#FF8080/yellow#FFD11F/blue#97D0F2 + YHNAME 首字
 *   + imgMinus（仅本人 YHID==userId 可见）+ tvName 13fp）；NO_JOIN_LIST → 纵向行（36dip 圆
 *   i2%4 + tvName 17fp + tvSub=BCJYY 14fp 非空显示）；SEND_MESSAGE_LIST → 外部人员行
 *   （NAME 16fp + PHONE 16fp#999 + MESSAGE_SEND "1"→"信息已送达"#1B68B7/"发送失败"#C80D28
 *   + EMAIL 行同 EMAIL_SEND；PHONE/EMAIL 空隐藏行）。
 * 【减号操作】MeetingStaffHorizontalAdapter.b.a(DATABean) → MeetingEditeDialog（XML 默认标题
 *   "不参与会议的原因"+hint"请输入不参与会议原因"+maxLength50）→ confirm 空 → "理由不能为空"
 *   → N2(str) = i0().p0(s,"0",str) → MeetingModel.r1 POST upJoin {xlh,zt:"0",reason} →
 *   成功 setResult(-1)+finish（无 toast）；失败 f → toast(msg)。
 * 【底栏】widget.d：k(arrow_down) + m("回到会议详情") → onClick b → finish（router.back）。
 * 【返回刷新】MeetingDetailActivity.onActivityResult(100)：底栏重建 + 本人发起 q3() + p3() 重拉详情
 *   （MeetingDetailPage.onPageShow 等价）。
 * 【数据规则】禁止 mock：AppStorage 无共享数据 → 真实空列表。
 */
@Entry
@Component
struct MeetingStaffSituationPage {
  /** 参会人员分组（源码 q，详情页 EXTRA 共享） */
  @State extras: MeetingExtraEntity[] = [];
  /** 理由弹窗（MeetingEditeDialog） */
  @State showReasonDialog: boolean = false;
  @State reasonText: string = '';
  private xlh: string = '';
  private hyid: string = '';

  aboutToAppear(): void {
    // 源码 y(intent)：s="xlh"、u="HYID"、q=i.e.a.j()（HAP 等价 AppStorage 共享）
    const params: object | undefined = router.getParams() as object | undefined;
    if (params !== null && params !== undefined) {
      const record = params as Record<string, Object>;
      const x: Object | undefined = record['xlh'];
      if (typeof x === 'string') {
        this.xlh = x as string;
      }
      const h: Object | undefined = record['HYID'];
      if (typeof h === 'string') {
        this.hyid = h as string;
      }
    }
    const shared: string | undefined = AppStorage.get<string>('meeting_staff_extra');
    if (shared !== undefined && shared !== '') {
      try {
        const raw: Object = JSON.parse(shared) as Object;
        if (Array.isArray(raw)) {
          const rows: Object[] = raw as Object[];
          for (const one of rows) {
            this.extras.push(MeetingStaffSituationPage.parseExtra(one));
          }
        }
      } catch (error) {
        const err = error as BusinessError;
        ApiService.logError('MeetingStaffSituationPage parse extras fail: ' + err.message);
        this.extras = [];
      }
    }
  }

  /** MeetingObj.EXTRABean 解析（{LENGTH:int, TYPE, DATA[]}） */
  private static parseExtra(one: Object): MeetingExtraEntity {
    const rec = one as Record<string, Object>;
    const extra: MeetingExtraEntity = new MeetingExtraEntity();
    extra.LENGTH = MeetingStaffSituationPage.pickNum(rec, ['LENGTH']);
    extra.TYPE = MeetingStaffSituationPage.pickStr(rec, ['TYPE']);
    const dataVal: Object | undefined = rec['DATA'];
    if (dataVal !== undefined && Array.isArray(dataVal)) {
      const rows: Object[] = dataVal as Object[];
      for (const child of rows) {
        const cr = child as Record<string, Object>;
        const row: MeetingExtraDataEntity = new MeetingExtraDataEntity();
        row.BCJYY = MeetingStaffSituationPage.pickStr(cr, ['BCJYY']);
        row.EMAIL = MeetingStaffSituationPage.pickStr(cr, ['EMAIL']);
        row.EMAIL_SEND = MeetingStaffSituationPage.pickStr(cr, ['EMAIL_SEND']);
        row.MEETING_ID = MeetingStaffSituationPage.pickStr(cr, ['MEETING_ID']);
        row.MESSAGE_SEND = MeetingStaffSituationPage.pickStr(cr, ['MESSAGE_SEND']);
        row.NAME = MeetingStaffSituationPage.pickStr(cr, ['NAME']);
        row.PHONE = MeetingStaffSituationPage.pickStr(cr, ['PHONE']);
        row.XLH = MeetingStaffSituationPage.pickStr(cr, ['XLH']);
        row.YHID = MeetingStaffSituationPage.pickStr(cr, ['YHID']);
        row.YHNAME = MeetingStaffSituationPage.pickStr(cr, ['YHNAME']);
        extra.DATA.push(row);
      }
    }
    return extra;
  }

  private static pickStr(rec: Record<string, Object>, keys: string[]): string {
    for (const key of keys) {
      const v: Object | undefined = rec[key];
      if (typeof v === 'string') {
        return v as string;
      }
      if (typeof v === 'number') {
        return String(v as number);
      }
    }
    return '';
  }

  private static pickNum(rec: Record<string, Object>, keys: string[]): number {
    for (const key of keys) {
      const v: Object | undefined = rec[key];
      if (typeof v === 'number') {
        return v as number;
      }
      if (typeof v === 'string') {
        const n: number = Number(v as string);
        if (!Number.isNaN(n)) {
          return n;
        }
      }
    }
    return 0;
  }

  /** 源码 c.onClick：bundle{HYID} → h2(e0=/meeting/sign) → MeetingSignPage */
  private openSignPage(): void {
    this.pushRoute('pages/MeetingSignPage', { 'HYID': this.hyid });
  }

  /** 源码 MeetingStaffHorizontalAdapter.b.a：减号 → MeetingEditeDialog（理由弹窗） */
  private onMinusClick(_person: MeetingExtraDataEntity): void {
    this.reasonText = '';
    this.showReasonDialog = true;
  }

  /** 源码 C0188a.confirm：空理由拦截 → N2(str) */
  private submitReason(): void {
    if (this.reasonText.trim() === '') {
      this.toast('理由不能为空');
      return;
    }
    this.markNoJoin(this.reasonText);
  }

  /** 源码 N2(str)：i0(new d).p0(s,"0",str) → MeetingModel.r1 POST upJoin {xlh,zt:"0",reason} */
  private markNoJoin(reason: string): void {
    ApiService.upJoinMeeting(this.xlh, '0', reason)
      .then((response: ApiResponse<string>) => {
        if (response.code === 1000) {
          return;
        }
        if (response.code === 0) {
          // 源码 d.g()：setResult(-1)+finish（无 toast；详情页 onActivityResult(100) 重拉）
          this.showReasonDialog = false;
          AppStorage.setOrCreate('meeting_staff_changed', true);
          router.back();
        } else {
          // 源码 d.f(str2)：m(str2) toast
          this.toast(response.message === '' ? '提交失败' : response.message);
        }
      })
      .catch((error: BusinessError) => {
        ApiService.logError('MeetingStaffSituationPage upJoin fail: ' + error.message);
        this.toast('提交失败');
      });
  }

  /** 源码 b.onClick：回到会议详情 → finish */
  private backToDetail(): void {
    router.back();
  }

  private pushRoute(url: string, params: Record<string, Object>): void {
    try {
      router.pushUrl({ url: url, params: params }).catch((error: BusinessError) => {
        ApiService.logError('MeetingStaffSituationPage route fail @' + url + ': ' + error.message);
      });
    } catch (error) {
      const err = error as BusinessError;
      ApiService.logError('MeetingStaffSituationPage route throw @' + url + ': ' + err.message);
    }
  }

  private toast(message: string): void {
    this.getUIContext().getPromptAction().showToast({ message: message });
  }

  /** 源码 adapter.setTextBackground/e(i)：i%4 → green/pink/yellow/blue_circle（drawable 实测色值） */
  private avatarColor(index: number): ResourceColor {
    const colors: ResourceColor[] = ['#92D860', '#FF8080', '#FFD11F', '#97D0F2'];
    return colors[index % 4];
  }

  /** 源码 adapter.getGroupView：TYPE → 组头文案（LENGTH 计数） */
  private groupTitle(group: MeetingExtraEntity): string {
    if (group.TYPE === 'JOIN_LIST') {
      return '拟参加（' + String(group.LENGTH) + '人)';
    }
    if (group.TYPE === 'UNCONFIRMED_LIST') {
      return '未回应是否参加（' + String(group.LENGTH) + '人)';
    }
    if (group.TYPE === 'NO_JOIN_LIST') {
      return '不参加（' + String(group.LENGTH) + '人)';
    }
    if (group.TYPE === 'SEND_MESSAGE_LIST') {
      return '外部人员信息发送情况';
    }
    return '';
  }

  /** 本人判断（源码 getUserId().equals(item.YHID) → 减号可见） */
  private isSelf(person: MeetingExtraDataEntity): boolean {
    return LoginSession.userId === person.YHID;
  }

  build() {
    Stack() {
      Column() {
        TitleBar({ title: '参会人员情况', showBack: true })
        // 右上二维码图标（toolbar gVar.k(mobile_campus_meeting_qrcode)）
        Image($r('app.media.mobile_campus_meeting_qrcode'))
          .width(20)
          .height(20)
          .margin({ right: 15 })
          .onClick(() => {
            this.openSignPage();
          })
        List() {
          ForEach(this.extras, (group: MeetingExtraEntity, index: number) => {
            ListItem() {
              this.groupSection(group, index)
            }
          }, (group: MeetingExtraEntity, index: number) => group.TYPE + '_' + String(index))
        }
        .width('100%')
        .layoutWeight(1)
        .scrollBar(BarState.Off)

        // layoutContainer：widget.d 底栏（arrow_down + "回到会议详情"）
        this.bottomBar()
      }
      .width('100%')
      .height('100%')
      .alignItems(HorizontalAlign.Start)

      // MeetingEditeDialog 复刻（XML 默认标题/hint，同 MeetingDetailPage.editDialog 结构）
      if (this.showReasonDialog) {
        this.reasonDialog()
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.mobile_campus_bg_color'))
    .alignContent(Alignment.Center)
  }

  /** 分组：组头（40dip 白底）+ 子区（横向 grid / 纵向行 / 外部人员行） */
  @Builder
  groupSection(group: MeetingExtraEntity, groupIndex: number) {
    Column() {
      Row() {
        Text(this.groupTitle(group))
          .fontSize(14)
          .fontColor($r('app.color.common_color_1'))
          .padding({ left: 12, right: 12 })
      }
      .width('100%')
      .height(40)
      .backgroundColor($r('app.color.white'))
      .alignItems(VerticalAlign.Center)
      Divider()
        .color($r('app.color.common_color_5'))
        .strokeWidth(0.5)
        .width('100%')

      if (group.TYPE === 'JOIN_LIST' || group.TYPE === 'UNCONFIRMED_LIST') {
        this.horizontalGrid(group)
      } else if (group.TYPE === 'NO_JOIN_LIST') {
        this.verticalList(group)
      } else if (group.TYPE === 'SEND_MESSAGE_LIST') {
        this.outsideList(group)
      }
    }
    .width('100%')
    .margin({ top: 12 })
    .backgroundColor($r('app.color.white'))
  }

  /** mobile_campus_meeting_item_view_staff_situation_horizontal_child：GridViewInScrollView 横向头像 */
  @Builder
  horizontalGrid(group: MeetingExtraEntity) {
    Grid() {
      ForEach(group.DATA, (person: MeetingExtraDataEntity, index: number) => {
        GridItem() {
          this.horizontalCell(person, index)
        }
      }, (person: MeetingExtraDataEntity) => group.TYPE + '_' + person.YHID + '_' + String(person.XLH))
    }
    .columnsTemplate('1fr 1fr 1fr 1fr 1fr')
    .width('100%')
    .padding(12)
    .backgroundColor($r('app.color.white'))
  }

  /** 横向 cell：36dip 四色圆字头像 + imgMinus（本人）+ tvName 13fp（padL/R 11） */
  @Builder
  horizontalCell(person: MeetingExtraDataEntity, index: number) {
    Column() {
      Stack({ alignContent: Alignment.TopEnd }) {
        Text(person.YHNAME === '' ? '' : person.YHNAME.substring(0, 1))
          .fontSize(18)
          .fontColor($r('app.color.ybg_white'))
          .width(36)
          .height(36)
          .textAlign(TextAlign.Center)
          .borderRadius(18)
          .backgroundColor(this.avatarColor(index))
        if (this.isSelf(person)) {
          // 源码 imgMinus：margin -16/-16 padding 16（减号角标悬浮头像右上）
          Image($r('app.media.mobile_campus_meeting_minus'))
            .width(16)
            .height(16)
            .padding(4)
            .offset({ x: 8, y: -8 })
            .onClick(() => {
              this.onMinusClick(person);
            })
        }
      }
      .width('100%')
      Text(person.YHNAME)
        .fontSize(13)
        .fontColor($r('app.color.common_color_1'))
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .margin({ top: 8, bottom: 15 })
    }
    .alignItems(HorizontalAlign.Center)
    .padding({ left: 11, right: 11 })
  }

  /** mobile_campus_meeting_item_view_staff_situation_vertical_child：36dip 圆 + 姓名 + 请假原因行 */
  @Builder
  verticalList(group: MeetingExtraEntity) {
    ForEach(group.DATA, (person: MeetingExtraDataEntity, index: number) => {
      Row() {
        Text(person.YHNAME === '' ? '' : person.YHNAME.substring(0, 1))
          .fontSize(18)
          .fontColor($r('app.color.ybg_white'))
          .width(36)
          .height(36)
          .textAlign(TextAlign.Center)
          .borderRadius(18)
          .backgroundColor(this.avatarColor(index))
        Column() {
          Text(person.YHNAME)
            .fontSize(17)
            .fontColor($r('app.color.common_color_1'))
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
          if (person.BCJYY !== '') {
            Text(person.BCJYY)
              .fontSize(14)
              .fontColor($r('app.color.common_color_3'))
              .margin({ top: 4 })
          }
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)
        .margin({ left: 12 })
      }
      .width('100%')
      .padding({ left: 22, right: 12, top: 10, bottom: 10 })
      .alignItems(VerticalAlign.Center)
      .backgroundColor($r('app.color.white'))
      Divider()
        .color($r('app.color.common_color_5'))
        .strokeWidth(0.5)
        .width('100%')
    }, (person: MeetingExtraDataEntity, index: number) => 'nojoin_' + person.YHID + '_' + String(index))
  }

  /** mobile_campus_meeting_item_view_outside_person_vertical_child：姓名 + 电话/邮箱 + 发送状态 */
  @Builder
  outsideList(group: MeetingExtraEntity) {
    ForEach(group.DATA, (person: MeetingExtraDataEntity, index: number) => {
      Column() {
        Divider()
          .color($r('app.color.common_color_5'))
          .strokeWidth(0.5)
          .width('100%')
        Row() {
          Text(person.NAME)
            .fontSize(16)
            .fontColor($r('app.color.common_color_1'))
            .margin({ right: 11 })
          Column() {
            if (person.PHONE !== '') {
              Row() {
                Text(person.PHONE)
                  .fontSize(16)
                  .fontColor($r('app.color.common_color_3'))
                  .layoutWeight(1)
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
                Text(person.MESSAGE_SEND === '1' ? '信息已送达' : '发送失败')
                  .fontSize(16)
                  .fontColor(person.MESSAGE_SEND === '1' ? '#1B68B7' : '#C80D28')
                  .maxLines(1)
              }
              .width('100%')
              .alignItems(VerticalAlign.Center)
            }
            if (person.EMAIL !== '') {
              Row() {
                Text(person.EMAIL)
                  .fontSize(16)
                  .fontColor($r('app.color.common_color_3'))
                  .layoutWeight(1)
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
                Text(person.EMAIL_SEND === '1' ? '信息已送达' : '发送失败')
                  .fontSize(16)
                  .fontColor(person.EMAIL_SEND === '1' ? '#1B68B7' : '#C80D28')
                  .maxLines(1)
              }
              .width('100%')
              .margin({ top: 4 })
              .alignItems(VerticalAlign.Center)
            }
          }
          .layoutWeight(1)
          .alignItems(HorizontalAlign.Start)
        }
        .width('100%')
        .padding(12)
        .alignItems(VerticalAlign.Top)
      }
      .width('100%')
      .backgroundColor($r('app.color.white'))
    }, (person: MeetingExtraDataEntity, index: number) => 'send_' + person.XLH + '_' + String(index))
  }

  /** mobile_campus_meeting_view_detail_btn：白底 48dip + arrow_down + "回到会议详情" */
  @Builder
  bottomBar() {
    Column() {
      Divider()
        .color($r('app.color.common_color_5'))
        .strokeWidth(0.5)
        .width('100%')
      Row() {
        Image($r('app.media.arrow_down'))
          .width(14)
          .height(14)
          .margin({ right: 4 })
        Text('回到会议详情')
          .fontSize(16)
          .fontColor($r('app.color.mobile_campus_primary_color_default'))
      }
      .width('100%')
      .height(47.5)
      .justifyContent(FlexAlign.Center)
      .onClick(() => {
        this.backToDetail();
      })
    }
    .width('100%')
    .height(48)
    .backgroundColor($r('app.color.white'))
  }

  /** mobile_campus_meeting_edite.xml MeetingEditeDialog 复刻（XML 默认标题"不参与会议的原因"） */
  @Builder
  reasonDialog() {
    Column() {
      Text('不参与会议的原因')
        .fontSize(17)
        .fontColor($r('app.color.common_color_1'))
        .margin({ top: 8 })
      TextArea({
        text: this.reasonText,
        placeholder: '请输入不参与会议原因'
      })
        .fontSize(16)
        .fontColor($r('app.color.common_color_1'))
        .backgroundColor($r('app.color.mobile_campus_bg_color'))
        .width(246)
        .height(68)
        .margin({ top: 8, bottom: 8 })
        .maxLength(50)
        .onChange((value: string) => {
          this.reasonText = value;
        })
      Divider()
        .color($r('app.color.common_color_5'))
        .strokeWidth(0.5)
        .width('100%')
      Text('提交')
        .fontSize(17)
        .fontColor($r('app.color.mobile_campus_primary_color_default'))
        .textAlign(TextAlign.Center)
        .width('100%')
        .height(44)
        .onClick(() => {
          this.submitReason();
        })
    }
    .width(270)
    .borderRadius(8)
    .backgroundColor($r('app.color.white'))
    .alignItems(HorizontalAlign.Center)
    .clip(true)
  }
}
