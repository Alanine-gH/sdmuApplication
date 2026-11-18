import { router } from '@kit.ArkUI';
import { call } from '@kit.TelephonyKit';
import { ApiService } from '../network/ApiService';
import { ApiResponse } from '../model/ResponseModel';
import { ContactYellowPage as ContactYellowPageData, ContactYellowPageGroup,
  ContactYellowTypeListBean, ContactYellowCommonBean } from '../model/ContactModel';
import { TitleBar } from '../components/TitleBar';
import { EmptyView } from '../components/EmptyView';
import { LoadingView } from '../components/LoadingView';

/**
 * 校园黄页页 — 源码级翻译（ContactYellowActivity.java + YellowPageFragment.java 逐行 → ArkTS）：
 *
 * 【容器】ContactYellowActivity：mobile_campus_contact_activity_yellow = toolbar_normal + fl_container，
 *   标题 mobile_campus_contact_yellow_page="校园黄页"（源码 setTypeface BOLD，HAP TitleBar 等价无粗体），
 *   f1() 加载 YellowPageFragment。
 *
 * 【列表】YellowPageFragment（mobile_campus_contact_fragment_yellow.xml MultiStateView + exListView）：
 *   U1() → ContactYellowPagePImpl.f() → ContactYellowPageModel.U0：e.b(g("yellowPage")) 裸 GET
 *   （ContactYellowPageFactory open/addressbook；实测 2026-11-17 裸 GET code=0，
 *   服务器返回 {departmentName:"校园黄页", dataList:[typeList空, commonlyPhoneList空]}）
 *   g() 回调：adapter.c(dataList)；标题 = departmentName（空则"校园黄页"）；
 *   V1(dataList)：所有组 typeList/commonlyPhoneList 全空 → 空态（B1），否则 content
 *   下拉刷新 setEnabled(false)（源码禁用，HAP 不做刷新手势）
 *
 * 【适配器】adapter/e.java ContactYellowAdapter：
 *   组头 getGroupView：getChildrenCount!=0 → 12dip #f2f2f2 间隔条（==0 → 0 高空 View）
 *   typeList 组子项 view_yellow_group：48dip(px_to_dip_96) 白底 padL12 tvTitle 17sp(px_to_sp_34)
 *   common_color_1 + arrow_right + 1dip 分隔；子项点击（b.onChildClick name=="typeList"）
 *   → 黄页分类页{dm:typeList.DM}（e.a.k0 ContactYellowTypeActivity）
 *   commonlyPhoneList 组子项 view_yellow_child：白底 padL12 minHeight50 头像36(icon 首字
 *   MC，底色 idx%4：0 green_circle#92D860 1 pink_circle#FF8080 2 yellow_circle#FFD11F
 *   3 blue_circle#97D0F2) tvName 16sp(px_to_sp_32) bold black mt4 mb8；
 *   tvSub DH 14sp(px_to_sp_28) mobile_campus_contact icon_yellow_page_phone dp2 mb4（DH 空 invisible）；
 *   tvAddress ADDRESS 14sp address 图标 dp2 pr5 mb4（空 gone）；tvEmail EMAIL 14sp email 图标
 *   dp4 mb4（空 gone）；imgPhone(call) DH 空隐藏、imgMsg(msn) gone；
 *   imgMsg 点 a 类 → c.a(0,DH) 直接拨；imgPhone 点 b 类 → c.a(1,DH) 确认框"拨打电话"→ 拨号
 *   多号：DH.replace("/")→"," split（ContactListDialog 选号，HAP showActionSheet 等价）
 */
@Entry
@Component
struct ContactYellowPage {
  @State pageTitle: string = '校园黄页';
  @State groups: ContactYellowPageGroup[] = [];
  @State isLoading: boolean = true;

  onPageShow(): void {
    this.loadYellowPage();
  }

  /** 源码 YellowPageFragment.U1()：请求黄页列表 */
  private loadYellowPage(): void {
    this.isLoading = true;
    ApiService.getYellowPage()
      .then((response: ApiResponse<ContactYellowPageData>) => {
        if (response.code === 1000) {
          // 登录失效统一处理已在网络层触发（HttpClient.getNoParams 拦截：清会话+toast+跳登录）
          return;
        }
        if (response.code === 0) {
          // 源码 a.g()：标题 = departmentName（空则"校园黄页"）
          this.pageTitle = response.data.departmentName === '' ? '校园黄页' : response.data.departmentName;
          this.groups = response.data.dataList;
        } else {
          ApiService.logError('ContactYellowPage load fail code=' + response.code + ' msg=' + response.message);
          this.groups = [];
          this.pageTitle = '校园黄页';
        }
        this.isLoading = false;
      })
      .catch(() => {
        ApiService.logError('ContactYellowPage load error');
        this.groups = [];
        this.isLoading = false;
      });
  }

  /** 源码 V1()：dataList 所有组子列表全空 → 空态 */
  private hasContent(): boolean {
    for (const g of this.groups) {
      if (g.typeList.length > 0 || g.commonlyPhoneList.length > 0) {
        return true;
      }
    }
    return false;
  }

  /** 组子项数（源码 getChildrenCount：按 name 分流） */
  private childCount(group: ContactYellowPageGroup): number {
    if (group.name === 'typeList') {
      return group.typeList.length;
    }
    if (group.name === 'commonlyPhoneList') {
      return group.commonlyPhoneList.length;
    }
    return 0;
  }

  /** 源码 b.onChildClick：typeList 子项 → 黄页分类页{dm:DM} */
  private onTypeClick(bean: ContactYellowTypeListBean): void {
    router.pushUrl({ url: 'pages/ContactYellowTypePage',
      params: { 'dm': bean.DM } as Record<string, string> });
  }

  /** 源码 d 类 c.a(i,DH,"")：空号 toast；多号弹选号；i=0 直接拨 / i=1 确认框 */
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

  /** 源码 Z1()：确认框"拨打电话"→ 确认拨号 */
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
      ApiService.logError('ContactYellowPage makeCall fail');
    }
  }

  /** 源码 e(int,TextView)：头像底色 idx%4 四色圆（green/pink/yellow/blue_circle） */
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
      } else if (!this.hasContent()) {
        // 源码 V1()==false → B1 空态
        Column() {
          EmptyView({ tipText: '暂无黄页数据' })
        }
        .width('100%')
        .layoutWeight(1)
      } else {
        this.yellowList()
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.mobile_campus_bg_color'))
  }

  /** ExpandableListView：组头 12dip #f2f2f2 间隔 + 子项（源码 getGroupView/getChildView） */
  @Builder
  yellowList() {
    List() {
      ForEach(this.groups, (group: ContactYellowPageGroup) => {
        if (this.childCount(group) > 0) {
          // 源码 getGroupView：children!=0 → 12dip #f2f2f2 间隔条
          ListItem() {
            Row()
              .width('100%')
              .height(12)
              .backgroundColor('#F2F2F2')
          }
          if (group.name === 'typeList') {
            ForEach(group.typeList, (bean: ContactYellowTypeListBean) => {
              ListItem() {
                this.typeRow(bean)
              }
            }, (bean: ContactYellowTypeListBean) => bean.DM + '_' + bean.XLH)
          } else {
            ForEach(group.commonlyPhoneList, (bean: ContactYellowCommonBean, idx: number) => {
              ListItem() {
                this.commonRow(bean, idx)
              }
            }, (bean: ContactYellowCommonBean) => bean.XLH + '_' + bean.MC)
          }
        }
      }, (group: ContactYellowPageGroup) => group.name + '_' + group.typeList.length + '_' + group.commonlyPhoneList.length)
    }
    .width('100%')
    .layoutWeight(1)
    .scrollBar(BarState.Off)
  }

  /** view_yellow_group（typeList 子项）：48dip 白底 padL12 17sp + arrow_right + 1dip 分隔 */
  @Builder
  typeRow(bean: ContactYellowTypeListBean) {
    Column() {
      Row() {
        Text(bean.MC)
          .fontSize(17)
          .fontColor($r('app.color.common_color_1'))
          .height(48)
          .padding({ left: 12, right: 12 })
          .layoutWeight(1)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .textAlign(TextAlign.Start)
        Image($r('app.media.arrow_right'))
          .width(16)
          .height(16)
          .margin({ right: 12 })
      }
      .width('100%')
      .backgroundColor($r('app.color.white'))
      .alignItems(VerticalAlign.Center)
      .onClick(() => {
        this.onTypeClick(bean);
      })

      Divider()
        .color($r('app.color.common_color_5'))
        .strokeWidth(1)
        .width('100%')
    }
    .width('100%')
  }

  /** view_yellow_child（commonlyPhoneList 子项）：白底 padL12 minHeight50 */
  @Builder
  commonRow(bean: ContactYellowCommonBean, idx: number) {
    Column() {
      Row() {
        // 源码 icon：MC 首字 + idx%4 四色圆底
        Text(bean.MC === '' ? ' ' : bean.MC.substring(0, 1))
          .fontSize(18.5)
          .fontColor($r('app.color.ybg_white'))
          .width(36)
          .height(36)
          .textAlign(TextAlign.Center)
          .backgroundColor(this.circleColorOf(idx))
          .borderRadius(18)

        Column() {
          Text(bean.MC)
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor($r('app.color.black'))
            .margin({ top: 4, bottom: 8 })
            .maxLines(1)

          // tvSub：DH 14sp + phone 图标 dp2 mb4（DH 空 setVisibility(4) INVISIBLE → opacity 0 占位）
          Row() {
            Image($r('app.media.icon_yellow_page_phone'))
              .width(12)
              .height(12)
              .margin({ right: 2 })
            Text(bean.DH)
              .fontSize(14)
              .fontColor($r('app.color.mobile_campus_contact'))
              .maxLines(1)
          }
          .margin({ bottom: 4 })
          .opacity(bean.DH === '' ? 0 : 1)

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

        // imgPhone(call)：DH 空隐藏；imgMsg(msn) 源码 gone —— imgPhone 点 → c.a(1) 确认框
        Image($r('app.media.mobile_campus_contact_call'))
          .width(18)
          .height(18)
          .margin({ right: 23 })
          .visibility(bean.DH === '' ? Visibility.None : Visibility.Visible)
          .onClick(() => {
            this.onPhoneTap(bean.DH, 1);
          })
      }
      .width('100%')
      .padding({ left: 12 })
      .constraintSize({ minHeight: 50 })
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
