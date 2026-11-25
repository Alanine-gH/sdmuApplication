import { router } from '@kit.ArkUI';
import { common, Want } from '@kit.AbilityKit';
import { contact } from '@kit.ContactsKit';
import { call } from '@kit.TelephonyKit';
import { pasteboard, BusinessError } from '@kit.BasicServicesKit';
import { ApiService } from '../network/ApiService';
import { ApiResponse } from '../model/ResponseModel';
import { ContactInitData, ContactTopContactListBean,
  ContactRootOrganizationBean, ContactClassAddressBookBean,
  ContactCourseTeacherBean, ContactAddressBookUserInfo } from '../model/ContactModel';
import { TitleBar } from '../components/TitleBar';
import { EmptyView } from '../components/EmptyView';
import { LoadingView } from '../components/LoadingView';
import { PreferencesUtil } from '../data/PreferencesUtil';
import { Constants } from '../data/Constants';
import { AdaptiveLayoutHelper, SplitPaneConfig } from '../common/AdaptiveLayoutHelper';

/**
 * 通讯录页 — 源码级翻译（APK 逐行 → ArkTS，禁截图猜测）：
 *
 * 【容器】ContactFragment.java：onResume 首次请求 getInitData（N1）；
 *   成功回调 a.g()：列表为空或仅 1 条 type=="yellowPage" → 标题"校园黄页"显示黄页页（R1）；
 *   否则标题"通讯录"显示 ContactSubFragment（P1）。
 *
 * 【主列表】ContactSubFragment.java（mobile_campus_contact_sub_fragment_contact.xml）：
 *   - navigation_bar_search_container：搜索栏 44dip 白底，点击跳搜索页（a1 o0 requestCode 2333）
 *   - llStatus 教师/学生 tab：userType=="2" 且 SystemSwitch.addressbook_query_student 才显示；
 *     HAP 未持久化 SystemSwitch（登录响应无该字段）→ 等价源码 systemSwitch==null 分支：tab 隐藏、w=0
 *   - q2()：w==0 → ContactModel.Y0 getInitData；w==1 → Z0 getStudentInitData
 *   - p2() 过滤：yellowPage 组 name=="hide" 剔除；其余 yellowPage name 空则补"校园黄页"
 *   - 组头点击 n()：yellowPage → 黄页页；im_card → 事件61（HAP 无 IM，toast）；
 *     其他 → 展开/折叠 + g.d(name, expanded) 持久化（ContactCachePImpl）
 *   - 子项点击 m()：organization→部门页(bmdm,bmmc)；topContactList→详情(SCYHID)；
 *     classAddressBook→班级页(bjid,title)；myTeacher→详情(GH)；myCourseTeachers→详情(userId)
 *   - 长按 topContactList 子项 l()：确认"是否移除常用联系人？"→ ContactModel.U0 delTopContact{gh}
 *   - 电话图标 c.a(i,phone,gh)：空号 toast"暂无该联系人电话号码"；多号(","分隔)弹选号；
 *     单号 i==0 直接拨号(d0.c)、i==1 确认框"拨打电话"后拨号+ContactModel.T0 addTopContact{scyhid,type=0}
 *
 * 【适配器】adapter/b.java ContactExpanAdapter：
 *   组头：yellowPage→view_group_yellow(60dip yellowpages图标)；organization/class→view_group_organize
 *   (48dip os图标 15sp #696969)；普通组→view_group(48dip contacts图标)；im_card→view_group_im(60dip im图标)；
 *   普通组 children==0 时整组隐藏；箭头 arrow_up/arrow_down
 *   子项：topContactList/myTeacher/myCourseTeachers→view_child(头像36 TX网络图/首字性别底色，
 *   名17sp 副INTRO|BMMC|course 14sp#747474 mt8，BDSJH||SJHM|phone 空则隐藏图标，vLine 末项隐藏)；
 *   organization/class→view_child_organize(48dip os2+arrow_right，末项 viewDivider 19.5dip)
 *
 * 【资源值】px_to_sp_34=17 px_to_sp_28=14 px_to_sp_37=18.5 px_to_sp_30=15 px_to_dip_96=48 px_to_dip_39=19.5
 *   组头字号 #696969；头像 host = netconstant.d.c()=serverUrl → Constants.SOCKET_HOST
 *   GNYX 校特判(字号15/底pad)不适用于 SDGY，未翻译。
 */
@Entry
@Component
struct ContactPage {
  @State pageTitle: string = '通讯录';
  @State groups: ContactInitData[] = [];
  @State isYellowMode: boolean = false;
  @State isLoading: boolean = true;
  /** 组展开状态（组名→已展开），持久化 contact_group_expand（源码 ContactCachePImpl b.e/b.f） */
  @State expandedKeys: string[] = [];
  @State selectedPersonGh: string = '';
  @State selectedPersonPhone: string = '';
  @State selectedPersonDetail: ContactAddressBookUserInfo | null = null;
  @State detailLoading: boolean = false;
  @State detailError: string = '';
  @StorageProp('currentBreakpoint') currentBreakpoint: string = 'sm';
  @StorageProp('windowWidthVp') windowWidthVp: number = 360;
  @StorageProp('avoidAreaLeftVp') avoidAreaLeftVp: number = 0;
  @StorageProp('avoidAreaRightVp') avoidAreaRightVp: number = 0;
  @StorageProp('avoidAreaBottomVp') avoidAreaBottomVp: number = 0;
  /** 源码 w：0=教师视图 getInitData，1=学生视图 getStudentInitData（SystemSwitch 缺省=0） */
  private viewMode: number = 0;
  private readonly EXPAND_KEY: string = 'contact_group_expand';

  aboutToAppear(): void {
    this.restoreExpanded();
  }

  /**
   * 源码 ContactSubFragment.U0()：每次可见 → q2() 重载（onPageShow 等价 onResume；
   * 容器 N1 首次决策黄页模式，之后每次可见刷新与源码一致）
   */
  onPageShow(): void {
    this.loadContacts();
  }

  /** 展开状态恢复（源码 adapter.c(true,...) → d.a.b(name) 缓存读取） */
  private restoreExpanded(): void {
    PreferencesUtil.getString(this.EXPAND_KEY, '[]')
      .then((v: string) => {
        try {
          const parsed: Object = JSON.parse(v) as Object;
          if (Array.isArray(parsed)) {
            const keys: string[] = [];
            for (const k of parsed as Object[]) {
              if (typeof k === 'string') {
                keys.push(k as string);
              }
            }
            this.expandedKeys = keys;
          }
        } catch (error) {
          ApiService.logError('ContactPage expand restore fail');
        }
      });
  }

  /** 组展开状态持久化（源码 d.a.d(name, expanded) → b.f(name, expanded)） */
  private persistExpanded(): void {
    PreferencesUtil.putString(this.EXPAND_KEY, JSON.stringify(this.expandedKeys));
  }

  /** 源码 ContactSubFragment.q2()：按 viewMode 请求初始化数据 */
  private loadContacts(): void {
    this.isLoading = true;
    const request: Promise<ApiResponse<ContactInitData[]>> = this.viewMode === 0
      ? ApiService.getContactInitData() : ApiService.getContactStudentInitData();
    request
      .then((response: ApiResponse<ContactInitData[]>) => {
        if (response.code === 1000) {
          // 登录失效统一处理已在网络层触发（HttpClient.bizRequest 拦截：清会话+toast+跳登录）
          return;
        }
        if (response.code === 0) {
          this.applyInitData(response.data);
        } else {
          ApiService.logError('ContactPage init fail code=' + response.code + ' msg=' + response.message);
          this.groups = [];
          this.isYellowMode = false;
          this.pageTitle = '通讯录';
        }
        this.isLoading = false;
      })
      .catch((error: BusinessError) => {
        ApiService.logError('ContactPage init error: ' + error.message);
        this.groups = [];
        this.isYellowMode = false;
        this.isLoading = false;
      });
  }

  /** 源码 ContactFragment.a.g()：空或仅 yellowPage → 黄页模式；否则 p2() 过滤后渲染 */
  private applyInitData(raw: ContactInitData[]): void {
    const yellowOnly: boolean = raw.length === 0 ||
      (raw.length === 1 && raw[0].type === 'yellowPage');
    if (yellowOnly) {
      // 源码 R1()：显示 YellowPageFragment（getYellowPage 黄页列表，属黄页子页范围）
      this.isYellowMode = true;
      this.pageTitle = '校园黄页';
      this.groups = [];
      return;
    }
    this.isYellowMode = false;
    this.pageTitle = '通讯录';
    this.groups = this.filterInitData(raw);
  }

  /** 源码 ContactSubFragment.p2()：yellowPage+hide 剔除；yellowPage 空名补"校园黄页" */
  private filterInitData(raw: ContactInitData[]): ContactInitData[] {
    const result: ContactInitData[] = [];
    for (const item of raw) {
      if (item.type === 'yellowPage') {
        if (item.name === 'hide') {
          continue;
        }
        if (item.name === '') {
          item.name = '校园黄页';
        }
      }
      result.push(item);
    }
    return result;
  }

  /** 源码 adapter.getChildrenCount()：按 type 返回子项数 */
  private childCount(group: ContactInitData): number {
    if (group.type === 'yellowPage' || group.type === 'im_card' || group.type === '') {
      return 0;
    }
    if (group.type === 'topContactList') {
      return group.topContactList.length;
    }
    if (group.type === 'organizationList') {
      return group.rootOrganization.length;
    }
    if (group.type === 'classAddressBook') {
      return group.classAddressBook.length;
    }
    if (group.type === 'myTeacher') {
      return group.myTeacher.length;
    }
    if (group.type === 'myCourseTeachers') {
      return group.myCourseTeachers.length;
    }
    return 0;
  }

  /** 源码 n.onGroupClick()：组头点击分流 */
  private onGroupClick(group: ContactInitData): void {
    if (group.type === 'yellowPage') {
      router.pushUrl({ url: 'pages/ContactYellowPage' });
      return;
    }
    if (group.type === 'im_card') {
      // 源码 f.a(61)：IM 私聊入口事件；HAP 无 IM 模块
      this.getUIContext().getPromptAction().showToast({ message: 'IM 私聊功能待接入' });
      return;
    }
    this.toggleGroup(group.name);
  }

  /** 展开/折叠 + 持久化（源码 n.onGroupClick else 分支） */
  private toggleGroup(name: string): void {
    const idx: number = this.expandedKeys.indexOf(name);
    if (idx >= 0) {
      const rest: string[] = [];
      for (const k of this.expandedKeys) {
        if (k !== name) {
          rest.push(k);
        }
      }
      this.expandedKeys = rest;
    } else {
      this.expandedKeys = this.expandedKeys.concat([name]);
    }
    this.persistExpanded();
  }

  private isExpanded(name: string): boolean {
    return this.expandedKeys.indexOf(name) >= 0;
  }

  /** 源码 m.onChildClick()：子项点击分流 */
  private onChildClick(group: ContactInitData, childIdx: number): void {
    if (group.type === 'organizationList') {
      // 源码 a1(l0, bundle{bmdm,bmmc,which}) 部门页；HAP 部门页待翻译
      this.getUIContext().getPromptAction().showToast({ message: '部门通讯录页面待接入' });
      return;
    }
    if (group.type === 'topContactList') {
      this.gotoPersonalDetail(group.topContactList[childIdx].SCYHID, this.phoneOf(group, childIdx));
      return;
    }
    if (group.type === 'classAddressBook') {
      const bean: ContactClassAddressBookBean = group.classAddressBook[childIdx];
      router.pushUrl({ url: 'pages/ContactClassAddressBookPage',
        params: { 'bjid': bean.BJID, 'title': bean.BJMC } as Record<string, string> });
      return;
    }
    if (group.type === 'myTeacher') {
      this.gotoPersonalDetail(group.myTeacher[childIdx].GH, this.phoneOf(group, childIdx));
      return;
    }
    if (group.type === 'myCourseTeachers') {
      this.gotoPersonalDetail(group.myCourseTeachers[childIdx].userId, this.phoneOf(group, childIdx));
    }
  }

  /** 源码 a1(m0, bundle{gh}) 个人详情页 */
  private gotoPersonalDetail(gh: string, fallbackPhone: string = ''): void {
    const splitCfg: SplitPaneConfig =
      AdaptiveLayoutHelper.getSplitPaneConfig(this.currentBreakpoint, this.windowWidthVp);
    if (!splitCfg.useTwoPane) {
      this.openPersonalDetailFullPage(gh, fallbackPhone);
      return;
    }
    this.selectPersonForPreview(gh, fallbackPhone);
  }

  private openPersonalDetailFullPage(gh: string, fallbackPhone: string = ''): void {
    router.pushUrl({ url: 'pages/ContactPersonalDetailPage',
      params: { 'gh': gh, 'phone': fallbackPhone } as Record<string, string> });
  }

  private selectPersonForPreview(gh: string, fallbackPhone: string = ''): void {
    this.selectedPersonGh = gh;
    this.selectedPersonPhone = fallbackPhone;
    this.selectedPersonDetail = null;
    this.detailError = '';
    this.detailLoading = true;
    ApiService.getContactUserInfo(gh, '')
      .then((response: ApiResponse<ContactAddressBookUserInfo>) => {
        if (response.code === 1000) {
          this.detailLoading = false;
          return;
        }
        if (this.selectedPersonGh !== gh) {
          return;
        }
        this.detailLoading = false;
        if (response.code === 0) {
          const bean: ContactAddressBookUserInfo = response.data;
          bean.userInfo.SJHM = bean.userInfo.BDSJH === '' ? bean.userInfo.SJHM : bean.userInfo.BDSJH;
          if (bean.userInfo.SJHM === '' && fallbackPhone !== '') {
            bean.userInfo.SJHM = fallbackPhone;
          }
          this.selectedPersonDetail = bean;
        } else {
          this.detailError = response.message === '' ? '获取联系人详情失败' : response.message;
        }
      })
      .catch((error: BusinessError) => {
        ApiService.logError('ContactPage inline detail fail: ' + error.message);
        if (this.selectedPersonGh === gh) {
          this.detailLoading = false;
          this.detailError = '网络异常，请稍后重试';
        }
      });
  }

  /** 源码 l.onItemLongClick()：topContactList 子项长按移除确认 */
  private confirmRemoveTop(groupIdx: number, childIdx: number): void {
    const group: ContactInitData = this.groups[groupIdx];
    if (group.type !== 'topContactList') {
      return;
    }
    const bean: ContactTopContactListBean = group.topContactList[childIdx];
    AlertDialog.show({
      title: '提示',
      message: '是否移除常用联系人？',
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
          this.removeTopContact(groupIdx, childIdx, bean.SCYHID);
        }
      }
    });
  }

  /** 源码 o2() → ContactModel.U0 delTopContact{gh=SCYHID}；成功后从组数据移除并刷新 */
  private removeTopContact(groupIdx: number, childIdx: number, scyhid: string): void {
    ApiService.delTopContact(scyhid)
      .then((response: ApiResponse<boolean>) => {
        if (response.code === 0) {
          const group: ContactInitData = this.groups[groupIdx];
          group.topContactList.splice(childIdx, 1);
          this.groups = this.groups.slice();
        } else if (response.code === 1000) {
          // 登录失效统一处理已在网络层触发（HttpClient.bizRequest 拦截：清会话+toast+跳登录）
          return;
        } else {
          this.getUIContext().getPromptAction().showToast({ message: response.message });
        }
      })
      .catch((error: BusinessError) => {
        ApiService.logError('ContactPage delTop fail: ' + error.message);
      });
  }

  /** 源码 c.a()：电话图标入口（i=0 imgMsg / i=1 imgPhone） */
  private onPhoneTap(phone: string, gh: string, tapType: number): void {
    if (phone === '') {
      this.getUIContext().getPromptAction().showToast({ message: '暂无该联系人电话号码' });
      return;
    }
    // 源码 str.replace("/", ",") 后 split(",")：兼容两种分隔符
    const numbers: string[] = phone.replace('/', ',').split(',');
    if (numbers.length > 1) {
      this.showNumberSheet(numbers, tapType, gh);
      return;
    }
    if (tapType === 0) {
      this.sendSms(phone);
      return;
    }
    this.showCallConfirm(phone, gh);
  }

  /** 源码 ContactListDialog：多号码弹选（选号后按 type 处理） */
  private showNumberSheet(numbers: string[], tapType: number, gh: string): void {
    const sheets: SheetInfo[] = [];
    for (const num of numbers) {
      const trimmed: string = num.trim();
      sheets.push({
        title: trimmed,
        action: (): void => {
          if (tapType === 0) {
            this.sendSms(trimmed);
          } else {
            this.makeCall(trimmed);
            if (tapType === 1) {
              ApiService.addTopContact(gh, '0');
            }
          }
        }
      });
    }
    this.getUIContext().showActionSheet({
      title: '选择号码',
      message: tapType === 0 ? '请选择要发送短信的号码' : '请选择要拨打的号码',
      sheets: sheets
    });
  }

  /** 源码 u2()：确认框"拨打电话"→ 确认后拨号 + addTopContact(gh, "0")（e 类回调） */
  private showCallConfirm(phone: string, gh: string): void {
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
          ApiService.addTopContact(gh, '0');
        }
      }
    });
  }

  /** 源码 d0.c/d0.a → 系统拨号（拉起拨号盘） */
  private makeCall(phone: string): void {
    try {
      call.makeCall(phone, () => {
      });
    } catch (error) {
      ApiService.logError('ContactPage makeCall fail');
    }
  }

  /** 拉起 HarmonyOS 系统短信应用 */
  private sendSms(phone: string): void {
    const num: string = phone.trim();
    if (num === '') {
      return;
    }
    try {
      const ctx = this.getUIContext().getHostContext() as common.UIAbilityContext;
      const want: Want = { action: 'ohos.want.action.sendToData', uri: 'sms:' + num };
      ctx.startAbility(want).catch(() => {
        this.getUIContext().getPromptAction().showToast({ message: '当前设备暂不支持短信功能' });
      });
    } catch {
      this.getUIContext().getPromptAction().showToast({ message: '当前设备暂不支持短信功能' });
    }
  }

  private copyFieldText(label: string, value: string): void {
    if (value === '' || value === '--') {
      return;
    }
    try {
      const data: pasteboard.PasteData = pasteboard.createData(pasteboard.MIMETYPE_TEXT_PLAIN, value);
      pasteboard.getSystemPasteboard().setData(data).then(() => {
        this.getUIContext().getPromptAction().showToast({ message: '已复制' + label + '：' + value });
      }).catch(() => {
        // 忽略剪贴板异常
      });
    } catch {
      // 忽略剪贴板异常
    }
  }

  /** 副标题文本：topContactList→INTRO；myTeacher→BMMC；courseTeacher→course（源码 getChildView） */
  private subTextOf(group: ContactInitData, childIdx: number): string {
    if (group.type === 'topContactList') {
      return group.topContactList[childIdx].INTRO;
    }
    if (group.type === 'myTeacher') {
      return group.myTeacher[childIdx].BMMC;
    }
    if (group.type === 'myCourseTeachers') {
      return group.myCourseTeachers[childIdx].course;
    }
    return '';
  }

  /** 电话号：BDSJH||SJHM（top/myTeacher）；phone（courseTeacher）（源码 getChildView） */
  private phoneOf(group: ContactInitData, childIdx: number): string {
    if (group.type === 'topContactList') {
      const bean: ContactTopContactListBean = group.topContactList[childIdx];
      return bean.BDSJH !== '' ? bean.BDSJH : bean.SJHM;
    }
    if (group.type === 'myTeacher') {
      const bean: ContactTopContactListBean = group.myTeacher[childIdx];
      return bean.BDSJH !== '' ? bean.BDSJH : bean.SJHM;
    }
    if (group.type === 'myCourseTeachers') {
      return group.myCourseTeachers[childIdx].phone;
    }
    return '';
  }

  /** 联系人 id（拨号埋点用）：topContactList→SCYHID；myTeacher→GH；courseTeacher→userId（源码 str3） */
  private ghOf(group: ContactInitData, childIdx: number): string {
    if (group.type === 'topContactList') {
      return group.topContactList[childIdx].SCYHID;
    }
    if (group.type === 'myTeacher') {
      return group.myTeacher[childIdx].GH;
    }
    if (group.type === 'myCourseTeachers') {
      return group.myCourseTeachers[childIdx].userId;
    }
    return '';
  }

  /** 姓名：XM / userName（源码 tvName） */
  private nameOf(group: ContactInitData, childIdx: number): string {
    if (group.type === 'topContactList') {
      return group.topContactList[childIdx].XM;
    }
    if (group.type === 'myTeacher') {
      return group.myTeacher[childIdx].XM;
    }
    if (group.type === 'myCourseTeachers') {
      return group.myCourseTeachers[childIdx].userName;
    }
    return '';
  }

  /** 头像 URL：TX/avatar 非空 → serverUrl + 路径（源码 netconstant.d.c()+TX） */
  private avatarUrlOf(group: ContactInitData, childIdx: number): string {
    let path: string = '';
    if (group.type === 'topContactList') {
      path = group.topContactList[childIdx].TX;
    } else if (group.type === 'myTeacher') {
      path = group.myTeacher[childIdx].TX;
    } else if (group.type === 'myCourseTeachers') {
      path = group.myCourseTeachers[childIdx].avatar;
    }
    if (path === '') {
      return '';
    }
    return Constants.SOCKET_HOST + path;
  }

  /** 性别：女→粉 男→蓝 其他→灰（源码 i()：gender_woman/man/unknown 背景资源，HAP 无资源用色块近似） */
  private genderColorOf(group: ContactInitData, childIdx: number): string {
    let sex: string = '';
    if (group.type === 'topContactList') {
      sex = group.topContactList[childIdx].XB;
    } else if (group.type === 'myTeacher') {
      sex = group.myTeacher[childIdx].XB;
    } else if (group.type === 'myCourseTeachers') {
      sex = group.myCourseTeachers[childIdx].sex;
    }
    if (sex === '女') {
      return '#F27B9B';
    }
    if (sex === '男') {
      return '#4A90D9';
    }
    return '#B2BDC8';
  }

  build() {
    Column() {
      TitleBar({ title: this.pageTitle, showBack: true })
      if (AdaptiveLayoutHelper.getSplitPaneConfig(this.currentBreakpoint, this.windowWidthVp).useTwoPane &&
        !this.isYellowMode) {
        Row() {
          Column() {
            this.searchBar()
            if (this.isLoading) {
              LoadingView()
            } else {
              this.groupList()
            }
          }
          .layoutWeight(AdaptiveLayoutHelper.getSplitPaneConfig(
            this.currentBreakpoint, this.windowWidthVp).masterRatio)
          .height('100%')

          Divider()
            .vertical(true)
            .width(0.5)
            .height('100%')
            .color($r('app.color.common_color_5'))

          Column() {
            this.contactDetailPane()
          }
          .layoutWeight(AdaptiveLayoutHelper.getSplitPaneConfig(
            this.currentBreakpoint, this.windowWidthVp).detailRatio)
          .height('100%')
        }
        .width('100%')
        .layoutWeight(1)
        .padding({ left: this.avoidAreaLeftVp, right: this.avoidAreaRightVp })
      } else {
        this.searchBar()
        if (this.isLoading) {
          LoadingView()
        } else if (this.isYellowMode) {
          // 源码 ContactFragment.a.g() 黄页分支：显示黄页入口（YellowPageFragment 内容属黄页子页）
          this.yellowEntryRow()
        } else {
          this.groupList()
        }
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.mobile_campus_bg_color'))
  }

  /** navigation_bar_search_container：44dip 白底 padV5，搜索框 #F2F2F2 圆角8 marginH12（源码点击跳搜索页） */
  @Builder
  searchBar() {
    Column() {
      Row() {
        Row() {
          Image($r('app.media.mobile_campus_contact_search_g'))
            .width(16)
            .height(16)
            .margin({ left: 9, right: 9 })
          Text('输入姓名、电话号码搜索')
            .fontSize(14)
            .fontColor($r('app.color.mobile_campus_contact_search_hint'))
        }
        .width('100%')
        .height(28)
        .borderRadius(8)
        .backgroundColor($r('app.color.common_color_6'))
        .border({ width: 0.5, color: $r('app.color.mobile_campus_contact_search_border') })
        .alignItems(VerticalAlign.Center)
      }
      .width('100%')
      .height(28)
      .alignItems(VerticalAlign.Center)
    }
    .width('100%')
    .height(44)
    .padding({ top: 5, bottom: 5, left: 12, right: 12 })
    .backgroundColor($r('app.color.white'))
    .hoverEffect(HoverEffect.Highlight)
    .onClick(() => {
      // 源码 a 类：a1(o0, bundle, 2333) → ContactSearchActivity；返回刷新
      router.pushUrl({ url: 'pages/ContactSearchPage' });
    })
  }

  /** 黄页模式内容（源码 R1 YellowPageFragment 的入口等价渲染） */
  @Builder
  yellowEntryRow() {
    Column() {
      Row() {
        Text('校园黄页')
          .fontSize(17)
          .fontColor($r('app.color.common_color_1'))
          .height(48)
          .padding({ left: 12, right: 12 })
          .layoutWeight(1)
          .textAlign(TextAlign.Start)
        Image($r('app.media.arrow_right'))
          .width(16)
          .height(16)
          .margin({ right: 12 })
      }
      .width('100%')
      .height(60)
      .margin({ top: 12 })
      .backgroundColor($r('app.color.white'))
      .alignItems(VerticalAlign.Center)
      .hoverEffect(HoverEffect.Highlight)
      .onClick(() => {
        router.pushUrl({ url: 'pages/ContactYellowPage' });
      })
    }
    .width('100%')
  }

  /** MultiStateView 内容区：空态/组列表（源码 f/g 回调 EMPTY/content 分流） */
  @Builder
  groupList() {
    if (this.groups.length === 0) {
      // 源码 CampusPage.EMPTY：getGroupCount()==0 → 空态
      Column() {
        EmptyView({ tipText: '暂无联系人' })
      }
      .width('100%')
      .layoutWeight(1)
    } else {
      List() {
        ForEach(this.groups, (group: ContactInitData, groupIdx: number) => {
          if (group.type === 'yellowPage') {
            ListItem() {
              this.yellowGroupHeader(group)
            }
          } else if (group.type === 'im_card') {
            ListItem() {
              this.imGroupHeader(group.name)
            }
          } else if (this.childCount(group) > 0) {
            // 源码 getGroupView：children==0 时 layoutContainer GONE（整组隐藏）
            ListItem() {
              this.normalGroupBlock(group, groupIdx)
            }
          }
        }, (group: ContactInitData) => group.type + '_' + group.name)
      }
      .width('100%')
      .layoutWeight(1)
      .scrollBar(BarState.Off)
      .backgroundColor($r('app.color.mobile_campus_bg_color'))
    }
  }

  /** view_group_yellow / view_group_im 组头（60dip 图标行）；点击走 onGroupClick（源码 n.onGroupClick yellowPage → 黄页页） */
  @Builder
  yellowGroupHeader(group: ContactInitData) {
    Row() {
      Text(group.name)
        .fontSize(17)
        .fontColor($r('app.color.common_color_1'))
        .height(48)
        .padding({ left: 12, right: 12 })
        .layoutWeight(1)
        .textAlign(TextAlign.Start)
      Image($r('app.media.arrow_right'))
        .width(16)
        .height(16)
        .margin({ right: 12 })
    }
    .width('100%')
    .height(60)
    .margin({ top: 12 })
    .backgroundColor($r('app.color.white'))
    .alignItems(VerticalAlign.Center)
    .hoverEffect(HoverEffect.Highlight)
    .onClick(() => {
      this.onGroupClick(group);
    })
  }

  @Builder
  imGroupHeader(name: string) {
    Row() {
      Text(name)
        .fontSize(17)
        .fontColor($r('app.color.common_color_1'))
        .height(48)
        .padding({ left: 12, right: 12 })
        .layoutWeight(1)
        .textAlign(TextAlign.Start)
      Image($r('app.media.arrow_right'))
        .width(16)
        .height(16)
        .margin({ right: 12 })
    }
    .width('100%')
    .height(60)
    .margin({ top: 12 })
    .backgroundColor($r('app.color.white'))
    .alignItems(VerticalAlign.Center)
    .onClick(() => {
      this.getUIContext().getPromptAction().showToast({ message: 'IM 私聊功能待接入' });
    })
  }

  /** 普通组（组头 + 展开子项）：组头样式按 type 分流（adapter.getGroupView） */
  @Builder
  normalGroupBlock(group: ContactInitData, groupIdx: number) {
    Column() {
      this.groupHeaderRow(group)
      if (this.isExpanded(group.name)) {
        this.groupChildren(group, groupIdx)
      }
    }
    .width('100%')
  }

  /** 组头：organization/class → os 图标 organize 样式；其他 → contacts 图标（源码 getGroupType） */
  @Builder
  groupHeaderRow(group: ContactInitData) {
    Column() {
      Row() {
        Image(group.type === 'organizationList' || group.type === 'classAddressBook'
          ? $r('app.media.mobile_campus_contact_os') : $r('app.media.mobile_campus_contact_contacts'))
          .width(16)
          .height(16)
          .margin({ left: 12, right: 12 })
        Text(group.name)
          .fontSize(15)
          .fontColor('#696969')
          .layoutWeight(1)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        Image(this.isExpanded(group.name) ? $r('app.media.arrow_up') : $r('app.media.arrow_down'))
          .width(14)
          .height(14)
          .margin({ right: 12 })
      }
      .width('100%')
      .height(48)
      .backgroundColor($r('app.color.white'))
      .alignItems(VerticalAlign.Center)

      Divider()
        .color($r('app.color.common_color_5'))
        .strokeWidth(1)
        .width('100%')
    }
    .width('100%')
    .margin({ top: 12 })
    .hoverEffect(HoverEffect.Highlight)
    .onClick(() => {
      this.onGroupClick(group);
    })
  }

  /** 子项集合：按 type 分流渲染（adapter.getChildView） */
  @Builder
  groupChildren(group: ContactInitData, groupIdx: number) {
    ForEach(this.childIndexList(group), (childIdx: number) => {
      if (group.type === 'organizationList' || group.type === 'classAddressBook') {
        this.organizeChildRow(group, childIdx)
      } else {
        this.personChildRow(group, groupIdx, childIdx)
      }
    }, (childIdx: number) => group.type + '_' + group.name + '_' + childIdx)
  }

  private childIndexList(group: ContactInitData): number[] {
    const list: number[] = [];
    const count: number = this.childCount(group);
    for (let i = 0; i < count; i++) {
      list.push(i);
    }
    return list;
  }

  /** view_child_organize：48dip 行 os2 图标 + arrow_right；末项 viewDivider 19.5dip（源码 case2/3） */
  @Builder
  organizeChildRow(group: ContactInitData, childIdx: number) {
    Column() {
      Row() {
        Text(this.organizeNameOf(group, childIdx))
          .fontSize(17)
          .fontColor($r('app.color.common_color_1'))
          .height(48)
          .padding({ left: 12, right: 12 })
          .layoutWeight(1)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .textAlign(TextAlign.Start)
        Image($r('app.media.mobile_campus_contact_os2'))
          .width(16)
          .height(16)
          .margin({ left: 12 })
        Image($r('app.media.arrow_right'))
          .width(16)
          .height(16)
          .margin({ left: 12, right: 12 })
      }
      .width('100%')
      .height(48)
      .backgroundColor($r('app.color.white'))
      .alignItems(VerticalAlign.Center)

      if (childIdx === this.childCount(group) - 1) {
        // 源码 viewDivider：isLastChild 时显示 19.5dip 分隔
        Row()
          .width('100%')
          .height(19.5)
      }
    }
    .width('100%')
    .hoverEffect(HoverEffect.Highlight)
    .onClick(() => {
      this.onChildClick(group, childIdx);
    })
  }

  /** 组织/班级子项标题：rootOrganization.BMMC / classAddressBook.BJMC */
  private organizeNameOf(group: ContactInitData, childIdx: number): string {
    if (group.type === 'organizationList') {
      const bean: ContactRootOrganizationBean = group.rootOrganization[childIdx];
      return bean.BMMC;
    }
    if (group.type === 'classAddressBook') {
      const bean: ContactClassAddressBookBean = group.classAddressBook[childIdx];
      return bean.BJMC;
    }
    return '';
  }

  /** view_child：人员行（头像36 名17 副14#747474 mt8 图标 mr23 vLine 末项隐藏） */
  @Builder
  personChildRow(group: ContactInitData, groupIdx: number, childIdx: number) {
    Column() {
      Row() {
        if (this.avatarUrlOf(group, childIdx) !== '') {
          Image(this.avatarUrlOf(group, childIdx))
            .width(36)
            .height(36)
            .borderRadius(18)
        } else {
          Text(this.nameOf(group, childIdx) === '' ? ' ' : this.nameOf(group, childIdx).substring(0, 1))
            .fontSize(18.5)
            .fontColor($r('app.color.ybg_white'))
            .width(36)
            .height(36)
            .textAlign(TextAlign.Center)
            .backgroundColor(this.genderColorOf(group, childIdx))
            .borderRadius(18)
        }

        Column() {
          Text(this.nameOf(group, childIdx))
            .fontSize(17)
            .fontColor($r('app.color.common_color_1'))
            .maxLines(1)
          Text(this.subTextOf(group, childIdx))
            .fontSize(14)
            .fontColor($r('app.color.ybg_grey'))
            .margin({ top: 8 })
            .maxLines(1)
        }
        .alignItems(HorizontalAlign.Start)
        .margin({ left: 12 })
        .layoutWeight(1)

        Row() {
          // 源码 imgMsg(msn 图标) 点击 → c.a(0)：直接拨号；imgPhone(call 图标) → c.a(1)：确认+记常用
          Image($r('app.media.mobile_campus_contact_call'))
            .width(18)
            .height(18)
            .opacity(this.phoneOf(group, childIdx) === '' ? 0 : 1)
            .hoverEffect(HoverEffect.Highlight)
            .onClick(() => {
              this.onPhoneTap(this.phoneOf(group, childIdx), this.ghOf(group, childIdx), 1);
            })
          Image($r('app.media.mobile_campus_contact_msn'))
            .width(18)
            .height(18)
            .margin({ left: 15 })
            .opacity(this.phoneOf(group, childIdx) === '' ? 0 : 1)
            .hoverEffect(HoverEffect.Highlight)
            .onClick(() => {
              this.onPhoneTap(this.phoneOf(group, childIdx), this.ghOf(group, childIdx), 0);
            })
        }
        .margin({ right: 23 })
        .alignItems(VerticalAlign.Center)
      }
      .width('100%')
      .padding({ left: 12, top: 10, bottom: 10 })
      .alignItems(VerticalAlign.Center)
      .backgroundColor(this.selectedPersonGh !== '' && this.selectedPersonGh === this.ghOf(group, childIdx)
        ? '#EEF5FC' : $r('app.color.white'))
      .hoverEffect(HoverEffect.Highlight)
      .onClick(() => {
        this.onChildClick(group, childIdx);
      })
      .gesture(LongPressGesture().onAction(() => {
        this.confirmRemoveTop(groupIdx, childIdx);
      }))

      if (childIdx !== this.childCount(group) - 1) {
        // 源码 vLine：divider_horizontal_grey_thin 1dip，末项隐藏
        Divider()
          .color($r('app.color.common_color_5'))
          .strokeWidth(1)
          .width('100%')
      }
    }
    .width('100%')
    .backgroundColor($r('app.color.white'))
  }

  private saveSelectedPersonToContacts(): void {
    if (this.selectedPersonDetail === null) {
      return;
    }
    const u = this.selectedPersonDetail.userInfo;
    const list: string[] = [];
    if (u.BGDH !== '') {
      list.push(u.BGDH.replace('/', ',').split(',')[0].trim());
    }
    if (u.SJDH !== '') {
      list.push(u.SJDH.replace('/', ',').split(',')[0].trim());
    }
    if (u.SJHM !== '') {
      list.push(u.SJHM.replace('/', ',').split(',')[0].trim());
    } else if (this.selectedPersonPhone !== '') {
      list.push(this.selectedPersonPhone.replace('/', ',').split(',')[0].trim());
    }
    const displayName: string = this.selectedPersonDetail.name !== '' ? this.selectedPersonDetail.name : u.XM;
    if (list.length === 0 && displayName === '' && u.DZYJ === '') {
      this.getUIContext().getPromptAction().showToast({ message: '该联系人暂无可保存的号码或姓名信息' });
      return;
    }
    try {
      const ctx = this.getUIContext().getHostContext() as common.UIAbilityContext;
      const phones: contact.PhoneNumber[] = [];
      for (const p of list) {
        if (p !== '') {
          phones.push({ phoneNumber: p } as contact.PhoneNumber);
        }
      }
      const c: contact.Contact = {
        name: { fullName: displayName !== '' ? displayName : this.selectedPersonGh } as contact.Name
      } as contact.Contact;
      if (phones.length > 0) {
        c.phoneNumbers = phones;
      }
      if (u.DZYJ !== '') {
        const emailAddr: string = u.DZYJ.replace('/', ',').split(',')[0].trim();
        if (emailAddr !== '') {
          c.emails = [{ email: emailAddr } as contact.Email];
        }
      }
      if (u.BMMC !== '' || u.ZW !== '') {
        c.organization = {
          name: u.BMMC,
          title: u.ZW
        } as contact.Organization;
      }
      contact.addContactViaUI(ctx, c)
        .then((contactId: number) => {
          if (contactId >= 0) {
            this.getUIContext().getPromptAction().showToast({ message: '已保存到本地通讯录' });
          } else {
            this.getUIContext().getPromptAction().showToast({
              message: list.length === 0 ? '该联系人未公开电话，已打开通讯录编辑' : '已取消或当前设备未完成通讯录保存'
            });
          }
        })
        .catch(() => {
          ApiService.logError('ContactPage addContactViaUI fail');
          this.getUIContext().getPromptAction().showToast({ message: '拉起系统通讯录失败，请检查设备通讯录服务' });
        });
    } catch (_e) {
      ApiService.logError('ContactPage saveSelectedPersonToContacts exception');
      this.getUIContext().getPromptAction().showToast({ message: '拉起系统通讯录失败' });
    }
  }

  /** 双栏右侧联系人详情预览面板 */
  @Builder
  contactDetailPane() {
    Column() {
      if (this.selectedPersonGh === '') {
        Column() {
          EmptyView({ tipText: '请选择左侧联系人查看详情' })
        }
        .width('100%')
        .height('100%')
      } else if (this.detailLoading) {
        Column() {
          LoadingView()
        }
        .width('100%')
        .height('100%')
      } else if (this.detailError !== '' || this.selectedPersonDetail === null) {
        Column({ space: 12 }) {
          Text(this.detailError !== '' ? this.detailError : '暂无联系人详情')
            .fontSize(14)
            .fontColor($r('app.color.common_color_3'))
          Text('打开完整页面')
            .fontSize(15)
            .fontColor($r('app.color.white'))
            .padding({ left: 20, right: 20, top: 10, bottom: 10 })
            .borderRadius(6)
            .backgroundColor('#3A92ED')
            .hoverEffect(HoverEffect.Highlight)
            .onClick(() => {
              this.openPersonalDetailFullPage(this.selectedPersonGh, this.selectedPersonPhone);
            })
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
      } else {
        Scroll() {
          Column({ space: 12 }) {
            Column({ space: 10 }) {
              if (this.selectedPersonDetail.userInfo.TX !== '') {
                Image(Constants.SOCKET_HOST + this.selectedPersonDetail.userInfo.TX)
                  .width(64)
                  .height(64)
                  .borderRadius(32)
              } else {
                Text(this.selectedPersonDetail.name === '' ? ' ' : this.selectedPersonDetail.name.substring(0, 1))
                  .fontSize(26)
                  .fontColor($r('app.color.ybg_white'))
                  .width(64)
                  .height(64)
                  .textAlign(TextAlign.Center)
                  .backgroundColor('#3A92ED')
                  .borderRadius(32)
              }
              Text(this.selectedPersonDetail.name)
                .fontSize(18)
                .fontWeight(FontWeight.Medium)
                .fontColor($r('app.color.common_color_1'))
              if (this.selectedPersonDetail.userInfo.BMMC !== '') {
                Text(this.selectedPersonDetail.userInfo.BMMC)
                  .fontSize(13)
                  .fontColor($r('app.color.common_color_3'))
              }
            }
            .width('100%')
            .padding(18)
            .borderRadius(8)
            .backgroundColor($r('app.color.white'))
            .alignItems(HorizontalAlign.Center)

            Row({ space: 10 }) {
              if (this.selectedPersonDetail.userInfo.SJHM !== '') {
                Text('拨打手机')
                  .fontSize(14)
                  .fontColor('#3A92ED')
                  .padding({ left: 16, right: 16, top: 9, bottom: 9 })
                  .borderRadius(6)
                  .backgroundColor('#EEF5FC')
                  .hoverEffect(HoverEffect.Highlight)
                  .onClick(() => {
                    if (this.selectedPersonDetail !== null) {
                      this.onPhoneTap(this.selectedPersonDetail.userInfo.SJHM,
                        this.selectedPersonDetail.userInfo.GH, 1);
                    }
                  })
              }
              Text('保存到通讯录')
                .fontSize(14)
                .fontColor('#3A92ED')
                .padding({ left: 16, right: 16, top: 9, bottom: 9 })
                .borderRadius(6)
                .backgroundColor('#EEF5FC')
                .hoverEffect(HoverEffect.Highlight)
                .onClick(() => {
                  this.saveSelectedPersonToContacts();
                })
              Text('打开完整页面')
                .fontSize(14)
                .fontColor($r('app.color.white'))
                .padding({ left: 18, right: 18, top: 9, bottom: 9 })
                .borderRadius(6)
                .backgroundColor('#3A92ED')
                .hoverEffect(HoverEffect.Highlight)
                .onClick(() => {
                  this.openPersonalDetailFullPage(this.selectedPersonGh, this.selectedPersonPhone);
                })
            }
            .width('100%')
            .justifyContent(FlexAlign.End)

            Column({ space: 8 }) {
              this.contactMetaRow(
                this.selectedPersonDetail.userInfo.userType === '1' ? '学号' : '工号',
                this.selectedPersonDetail.userInfo.userType === '1'
                  ? this.selectedPersonDetail.userInfo.XH
                  : this.selectedPersonDetail.userInfo.GH
              )
              this.contactMetaRow('手机', this.selectedPersonDetail.userInfo.SJHM)
              this.contactMetaRow('办公电话', this.selectedPersonDetail.userInfo.BGDH)
              this.contactMetaRow('短号', this.selectedPersonDetail.userInfo.SJDH)
              this.contactMetaRow('邮箱', this.selectedPersonDetail.userInfo.DZYJ)
              this.contactMetaRow('地址', this.selectedPersonDetail.userInfo.BGDZ)
              if (this.selectedPersonDetail.userInfo.ZW !== '') {
                this.contactMetaRow('职位', this.selectedPersonDetail.userInfo.ZW)
              }
              if (this.selectedPersonDetail.userInfo.GW !== '') {
                this.contactMetaRow('职称', this.selectedPersonDetail.userInfo.GW)
              }
            }
            .width('100%')
            .padding(16)
            .borderRadius(8)
            .backgroundColor($r('app.color.white'))
            .alignItems(HorizontalAlign.Start)
          }
          .width('100%')
          .padding({ left: 16, right: 16, top: 16, bottom: Math.max(16, this.avoidAreaBottomVp) })
        }
        .width('100%')
        .height('100%')
        .scrollBar(BarState.Off)
        .align(Alignment.Top)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.mobile_campus_bg_color'))
  }

  @Builder
  contactMetaRow(label: string, value: string) {
    Row() {
      Text(label)
        .fontSize(14)
        .fontColor($r('app.color.common_color_3'))
        .width(84)
        .flexShrink(0)
      Text(value === '' ? '--' : value)
        .fontSize(14)
        .fontColor($r('app.color.common_color_1'))
        .layoutWeight(1)
    }
    .width('100%')
    .alignItems(VerticalAlign.Top)
    .onClick(() => {
      this.copyFieldText(label, value);
    })
  }
}
