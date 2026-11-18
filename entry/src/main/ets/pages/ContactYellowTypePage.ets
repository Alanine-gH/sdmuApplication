import { router } from '@kit.ArkUI';
import { call } from '@kit.TelephonyKit';
import { ApiService } from '../network/ApiService';
import { ApiResponse } from '../model/ResponseModel';
import { ContactYellowTypeResult as ContactYellowTypeData, ContactYellowDepPhoneBean } from '../model/ContactModel';
import { TitleBar } from '../components/TitleBar';
import { EmptyView } from '../components/EmptyView';
import { LoadingView } from '../components/LoadingView';

/**
 * 黄页分类页 — 源码级翻译（ContactYellowTypeActivity.java 逐行 → ArkTS）：
 *
 * 【入口】YellowPageFragment.b.onChildClick：typeList 子项 → {dm:typeList.DM}（e.a.k0）。
 *
 * 【布局】mobile_campus_contact_activity_yellow_page.xml：#f2f2f2 竖排
 *   toolbar_normal（标题 tv=响应 currentDep，源码 setTypeface BOLD）+
 *   common_refresh_lv_rl（MultiStateView + common_refresh_lv ListView divider=null）marginTop 12dip
 *
 * 【请求】T2() → ContactYellowPagePImpl.g(dm) → ContactYellowPageModel.T0：
 *   e.b(g("getYellowByType")) + {dm}（实测 2026-11-17 data= 加密 GET code=0；
 *   响应 {currentDep, name:"DepPhoneList", DepPhoneList[]} 结构 1:1，本校数据为空）
 *   a.g()：adapter.setDatas(DepPhoneList)；标题 currentDep；空 → q2 空态
 *   下拉刷新（b.a() → T2 重载）；setPullUpToLoadEnable(false) 无上拉
 *
 * 【子项】ContactYellowTypeAdapter（view_yellow_type.xml）：
 *   白底 padL12 头像36 icon 首字 XM 底色 idx%4（0#92D860 1#FF8080 2#FFD11F 3#97D0F2）
 *   tvName 16sp(px_to_sp_32) bold black mt4 mb8；tvSub SJHM 14sp(px_to_sp_28) mobile_campus_contact
 *   phone 图标 dp2 mb4（SJHM 空 gone）；tvAddress ADDRESS 14sp address 图标 dp2 pr5 mb4（空 gone）；
 *   tvEmail EMAIL 14sp email 图标 dp4 mb4（空 gone）；imgPhone(call) SJHM 空隐藏、imgMsg(msn) gone；
 *   imgMsg → c.a(0,SJHM) 直接拨；imgPhone → c.a(1,SJHM) 确认框"拨打电话"→ 拨号；
 *   多号 SJHM.replace("/")→"," split → ContactListDialog 选号（HAP showActionSheet 等价）
 */
@Entry
@Component
struct ContactYellowTypePage {
  @State pageTitle: string = '';
  @State depList: ContactYellowDepPhoneBean[] = [];
  @State isLoading: boolean = true;
  /** 源码 r：intent "dm"（黄页分类部门代码） */
  private dm: string = '';

  aboutToAppear(): void {
    const params: Record<string, string> | undefined = router.getParams() as Record<string, string> | undefined;
    if (params !== undefined && params !== null) {
      this.dm = params['dm'] === undefined ? '' : params['dm'];
    }
  }

  onPageShow(): void {
    this.loadYellowType();
  }

  /** 源码 T2()：请求 getYellowByType{dm} */
  private loadYellowType(): void {
    this.isLoading = true;
    ApiService.getYellowByType(this.dm)
      .then((response: ApiResponse<ContactYellowTypeData>) => {
        if (response.code === 1000) {
          // 登录失效统一处理已在网络层触发（HttpClient.bizRequest 拦截：清会话+toast+跳登录）
          return;
        }
        if (response.code === 0) {
          this.depList = response.data.DepPhoneList;
          this.pageTitle = response.data.currentDep;
        } else {
          ApiService.logError('ContactYellowTypePage load fail code=' + response.code + ' msg=' + response.message);
          this.depList = [];
          this.pageTitle = '';
        }
        this.isLoading = false;
      })
      .catch(() => {
        ApiService.logError('ContactYellowTypePage load error');
        this.depList = [];
        this.isLoading = false;
      });
  }

  /** 源码 c 类 c.a(i,SJHM,"")：空号 toast；多号弹选号；i=0 直接拨 / i=1 确认框 */
  private onPhoneTap(phone: string, tapType: number): void {
    if (phone === '') {
      this.getUIContext().getPromptAction().showToast({ message: '暂无该联系人电话号码' });
      return;
    }
    const numbers: string[] = phone.replace('/', ',').split(',');
    if (numbers.length > 1) {
      this.showNumberSheet(numbers, tapType);
      return;
    }
    if (tapType === 0) {
      this.makeCall(phone);
      return;
    }
    this.showCallConfirm(phone);
  }

  /** 源码 ContactListDialog：多号码选号弹窗 */
  private showNumberSheet(numbers: string[], tapType: number): void {
    const sheets: SheetInfo[] = [];
    for (const num of numbers) {
      const trimmed: string = num.trim();
      sheets.push({
        title: trimmed,
        action: (): void => {
          this.makeCall(trimmed);
        }
      });
    }
    this.getUIContext().showActionSheet({ title: '选择号码', message: '请选择要拨打的号码', sheets: sheets });
  }

  /** 源码 S2()：确认框"拨打电话"→ 确认拨号 */
  private showCallConfirm(phone: string): void {
    AlertDialog.show({
      title: '拨打电话',
      message: phone,
      autoCancel: true,
      alignment: DialogAlignment.Center,
      primaryButton: {
        value: '取消',
        action: () => {
        }
      },
      secondaryButton: {
        value: '确定',
        action: () => {
          this.makeCall(phone);
        }
      }
    });
  }

  /** 源码 d0.c/d0.a → 系统拨号 */
  private makeCall(phone: string): void {
    try {
      call.makeCall(phone, () => {
      });
    } catch {
      ApiService.logError('ContactYellowTypePage makeCall fail');
    }
  }

  /** 源码 setTextBackground(int,TextView)：idx%4 四色圆 */
  private circleColorOf(idx: number): string {
    const mod: number = idx % 4;
    if (mod === 0) {
      return '#92D860';
    }
    if (mod === 1) {
      return '#FF8080';
    }
    if (mod === 2) {
      return '#FFD11F';
    }
    return '#97D0F2';
  }

  build() {
    Column() {
      TitleBar({ title: this.pageTitle, showBack: true })
      if (this.isLoading) {
        LoadingView()
      } else if (this.depList.length === 0) {
        // 源码 q2：DepPhoneList 空 → 空态
        Column() {
          EmptyView({ tipText: '暂无黄页数据' })
        }
        .width('100%')
        .layoutWeight(1)
      } else {
        this.depListView()
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F2F2F2')
  }

  /** common_refresh_lv：ListView marginTop12 divider=null（下拉刷新 → T2 重载） */
  @Builder
  depListView() {
    List() {
      ForEach(this.depList, (bean: ContactYellowDepPhoneBean, idx: number) => {
        ListItem() {
          this.depRow(bean, idx)
        }
      }, (bean: ContactYellowDepPhoneBean) => bean.XLH + '_' + bean.XM)
    }
    .width('100%')
    .layoutWeight(1)
    .scrollBar(BarState.Off)
    .margin({ top: 12 })
    .backgroundColor($r('app.color.white'))
  }

  /** view_yellow_type：白底 padL12 头像36(首字四色圆) 名16bold 电话/地址/邮箱 + call 图标 mr23 */
  @Builder
  depRow(bean: ContactYellowDepPhoneBean, idx: number) {
    Column() {
      Row() {
        Text(bean.XM === '' ? ' ' : bean.XM.substring(0, 1))
          .fontSize(18.5)
          .fontColor($r('app.color.ybg_white'))
          .width(36)
          .height(36)
          .textAlign(TextAlign.Center)
          .backgroundColor(this.circleColorOf(idx))
          .borderRadius(18)

        Column() {
          Text(bean.XM)
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor($r('app.color.black'))
            .margin({ top: 4, bottom: 8 })
            .maxLines(1)

          // tvSub：SJHM 14sp + phone 图标 dp2 mb4（SJHM 空 gone）
          Row() {
            Image($r('app.media.icon_yellow_page_phone'))
              .width(12)
              .height(12)
              .margin({ right: 2 })
            Text(bean.SJHM)
              .fontSize(14)
              .fontColor($r('app.color.mobile_campus_contact'))
              .maxLines(1)
          }
          .margin({ bottom: 4 })
          .visibility(bean.SJHM === '' ? Visibility.None : Visibility.Visible)

          // tvAddress：ADDRESS 14sp + address 图标 dp2 pr5 mb4（空 gone）
          Row() {
            Image($r('app.media.icon_yellow_page_address'))
              .width(12)
              .height(12)
              .margin({ right: 2 })
            Text(bean.ADDRESS)
              .fontSize(14)
              .fontColor($r('app.color.mobile_campus_contact'))
              .padding({ right: 5 })
              .maxLines(1)
          }
          .margin({ bottom: 4 })
          .visibility(bean.ADDRESS === '' ? Visibility.None : Visibility.Visible)

          // tvEmail：EMAIL 14sp + email 图标 dp4 mb4（空 gone）
          Row() {
            Image($r('app.media.icon_yellow_page_email'))
              .width(12)
              .height(12)
              .margin({ right: 4 })
            Text(bean.EMAIL)
              .fontSize(14)
              .fontColor($r('app.color.mobile_campus_contact'))
              .maxLines(1)
          }
          .margin({ bottom: 4 })
          .visibility(bean.EMAIL === '' ? Visibility.None : Visibility.Visible)
        }
        .alignItems(HorizontalAlign.Start)
        .margin({ left: 12 })
        .layoutWeight(1)

        // imgPhone(call)：SJHM 空隐藏；点击 → c.a(1) 确认框（imgMsg 源码 gone）
        Image($r('app.media.mobile_campus_contact_call'))
          .width(18)
          .height(18)
          .margin({ right: 23 })
          .visibility(bean.SJHM === '' ? Visibility.None : Visibility.Visible)
          .onClick(() => {
            this.onPhoneTap(bean.SJHM, 1);
          })
      }
      .width('100%')
      .padding({ left: 12 })
      .alignItems(VerticalAlign.Center)
      .backgroundColor($r('app.color.white'))

      Divider()
        .color($r('app.color.common_color_5'))
        .strokeWidth(1)
        .width('100%')
    }
    .width('100%')
    .backgroundColor($r('app.color.white'))
  }
}
