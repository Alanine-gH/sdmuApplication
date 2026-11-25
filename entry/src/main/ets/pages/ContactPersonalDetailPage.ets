import { TitleBar } from '../components/TitleBar';
import { router } from '@kit.ArkUI';
import { call } from '@kit.TelephonyKit';
import { common, abilityAccessCtrl, Want } from '@kit.AbilityKit';
import { contact } from '@kit.ContactsKit';
import { image } from '@kit.ImageKit';
import { ApiService } from '../network/ApiService';
import { ApiResponse } from '../model/ResponseModel';
import { LoginSession } from '../network/LoginSession';
import { Constants } from '../data/Constants';
import { ContactAddressBookUserInfo } from '../model/ContactModel';
import { EmptyView } from '../components/EmptyView';
import { LoadingView } from '../components/LoadingView';
import { BarcodeHelper } from '../common/BarcodeHelper';
import { BreakpointSystem } from '../common/BreakpointSystem';
import { AdaptiveLayoutHelper } from '../common/AdaptiveLayoutHelper';

/**
 * 联系人个人详情页 — 源码级翻译（ContactPersonalDetailActivity.java 逐行 → ArkTS，[W25 misc-b]）：
 *
 * 【布局】mobile_campus_contact_activity_personal_detail.xml：bg#fff2f2f2 toolbar_normal + MultiStateView(ScrollView)：
 *   头部白卡 padT8(px_to_dip_16)：居中 imgLayout(img 60dip gone / icon blue_circle 30fp(px_to_sp_60) 白字，
 *   TX 空时 post(setWidth(getHeight())) 方形) + tvName 17fp(px_to_sp_34) mt12；
 *   操作行 mt25.5(px_to_dip_51) pad5(px_to_dip_10) gravity center|top：发短信/打电话/发邮件/私聊
 *   各宽 88(px_to_dip_176) #3a92ed 图标上文本下 drawablePadding 8(px_to_dip_16)；
 *   layoutContainer mt12(px_to_dip_24) 白底
 * 【行】widget.a(ContactPersonalDetailView)：view_personal_detail_item padL11.5(px_to_dip_23) padV11
 *   (px_to_dip_22)：tvName/tvContent 16fp(px_to_sp_32，本校非 GNYX 17→16) + 底分隔线；空值 "--"
 * 【数据】y(Intent)：gh(v) + contactSearchType(B)；l3()：B 空 → ContactModel.f1 GET userInfo {gh}；
 *   B 非空 → ContactModel.g1 GET userMessage/userInfo {gh,searchType}（Constants.KEY_USER_ID="userInfo"）
 *   → AddressBookUserInfo{name,roleType,title,type,userInfo{28字段}}；null→EMPTY；异常→ERROR；
 *   业务失败→toast(message)，-3010→ERROR_NETWORK（非 -3010 源码为 s2 loading 死态，HAP 折中空态同 W9 先例）
 * 【渲染 r3】TX 空→icon 首字+XB 性别角标背景(gender_man #3A7BFF/女 #FF5F5F/未知 #F9C043)；TX 非空→网络图；
 *   DZYJ 空→tvMail gone；ImConstant 默认 false→tvIm 恒 gone（仅 ContactPage IM 分组渲染时置 true，HAP 无 IM 组）；
 *   行序：授课(教师+登录者非教师)/部门/学号或工号/手机(电话色 #3a92ed 可点)/电话/短号/邮箱(可点发邮件)/地址/
 *   QQ号/微信号号(源码文案原样)/职位/职称/车牌 + 学生附加块(性别/籍贯/辅导员/辅导员电话/班级/专业)；
 *   手机行值=BDSJH 空→SJHM 并回写 userInfo.SJHM（源码 613-614）；三号全空→tvMsg/tvPhone gone
 * 【more 弹窗】ContactMoreDialog(mobile_campus_contact_view_more_dialog.xml)：56dip(px_to_dip_112) 18fp
 *   (px_to_sp_36) #3a92ed 白底 mt1；登录者 userType=="1"→tvAddToNet gone；t(type)："0"添加到常用联系人/
 *   "1"移除常用联系人；s(roleType)："0"gone/"1"手机号码对其可见/"2"手机号码对其不可见；取消 20fp bold mt8
 * 【more 交互】h 类：tvAddToNet→"0"→addTopContact{scyhid:gh,type:"1"} data="1"→toast"已添加到常用联系人"
 *   +t("1")；else delTopContact{gh} data="1"→t("0")（无 toast）；tvPermissions→"1"→openRole{gh}
 *   （msg=="已对其开放手机号码查看权限"||"已开放权限"→s("2")；toast=msg）/"2"→hideRole{gh}
 *   （data="1"→s("1")）；tvAddToLocal→收集 BGDH+SJDH+SJHM(覆写后) 非空→系统通讯录写入
 *   （HAP ContactsKit.addContact 等价 l0 权限链，成功 toast"已保存到本地通讯录"）
 * 【拨号链】q3(i)：号集 BGDH+SJDH+SJHM(覆写后)，BDSJH 非空→清空只用 BDSJH，去重；
 *   t3：空→toast"暂无该联系人电话号码"；>1→ContactListDialog 选号弹窗；o3：i2==0→d0.c 短信
 *   （HAP 无短信跳转 API，等价 makeCall 同 W9 先例）；i2==1：count<=1→s3 确认框"拨打电话"
 *   （确认→d0.a 拨号+addTopContact{scyhid:GH,type:"0"}+setResult(-1)）；count>1→d0.a 直接拨号
 *   +addTopContact+setResult(-1)（setResult 等价=刷新标记，上游 onPageShow 重拉）
 * 【发邮件】C 类：DZYJ 空 return；ACTION_SEND message/rfc822 chooser（HAP 等价 mailto 隐式 want，
 *   无应用响应→catch toast"请安装邮箱应用"）
 */
@Entry
@Component
struct ContactPersonalDetailPage {
  @State isLoading: boolean = true;
  @State showError: boolean = false;
  @State showEmpty: boolean = false;
  @State info: ContactAddressBookUserInfo = new ContactAddressBookUserInfo();
  /** more 弹窗显隐 + ContactMoreDialog.i/y.t(type) 与 .j/y.s(roleType) 等价状态 */
  @State showMore: boolean = false;
  @State moreAddType: string = '0';
  @State moreRoleType: string = '0';
  @State showQrModal: boolean = false;
  @State qrPixelMap: image.PixelMap | null = null;
  @State qrLoading: boolean = false;
  @State qrSaving: boolean = false;
  @StorageProp('currentBreakpoint') currentBreakpoint: string = 'sm';
  @StorageProp('windowWidthVp') windowWidthVp: number = 360;
  @StorageProp('windowHeightVp') windowHeightVp: number = 780;
  @StorageProp('avoidAreaBottomVp') avoidAreaBottomVp: number = 0;
  @StorageProp('isCompactHeight') isCompactHeight: boolean = false;
  private gh: string = '';
  private fallbackPhone: string = '';
  private contactSearchType: string = '';
  /** 源码 l 类 setResult(-1) 等价：拨号/常用变化刷新标记，上游 onPageShow 消费 */
  private refreshFlag: boolean = false;

  aboutToDisappear(): void {
    this.releaseQrPixelMap();
  }

  private releaseQrPixelMap(): void {
    if (this.qrPixelMap !== null) {
      const pm: image.PixelMap = this.qrPixelMap;
      this.qrPixelMap = null;
      try {
        pm.release();
      } catch {
        // 忽略释放异常
      }
    }
  }

  private closeQrModal(): void {
    this.showQrModal = false;
    if (!this.qrSaving) {
      this.releaseQrPixelMap();
    }
  }

  private async openQrModal(): Promise<void> {
    const u = this.info.userInfo;
    const payload: string = BarcodeHelper.buildContactVCard({
      name: this.info.name,
      org: u.BMMC,
      title: u.ZW !== '' ? u.ZW : u.GW,
      phone: u.SJHM,
      tel: u.BGDH !== '' ? u.BGDH : u.SJDH,
      email: u.DZYJ,
      address: u.BGDZ
    });
    if (payload === '') {
      this.getUIContext().getPromptAction().showToast({ message: '暂无可生成的联系人信息' });
      return;
    }
    this.releaseQrPixelMap();
    this.qrLoading = true;
    this.showQrModal = true;
    const res = await BarcodeHelper.generateQrPixelMap(payload, 480);
    this.qrLoading = false;
    if (!this.showQrModal) {
      if (res.pixelMap !== null) {
        try {
          res.pixelMap.release();
        } catch {
          // 忽略释放异常
        }
      }
      return;
    }
    if (res.success && res.pixelMap !== null) {
      this.qrPixelMap = res.pixelMap;
    } else {
      this.showQrModal = false;
      this.getUIContext().getPromptAction().showToast({ message: res.message });
    }
  }

  private async saveQrToGallery(): Promise<void> {
    if (this.qrPixelMap === null || this.qrSaving) {
      return;
    }
    this.qrSaving = true;
    try {
      const ctx = this.getUIContext().getHostContext() as common.Context;
      const res = await BarcodeHelper.savePixelMapToGallery(ctx, this.qrPixelMap);
      this.getUIContext().getPromptAction().showToast({ message: res.message });
    } finally {
      this.qrSaving = false;
      if (!this.showQrModal) {
        this.releaseQrPixelMap();
      }
    }
  }

  onPageShow(): void {
    const params = router.getParams() as Record<string, string>;
    if (params !== null && params !== undefined) {
      const ghParam: string = params['gh'] !== undefined && params['gh'] !== null ? params['gh'] : '';
      const phoneParam: string = params['phone'] !== undefined && params['phone'] !== null ? params['phone'] : '';
      const typeParam: string = params['contactSearchType'] !== undefined &&
        params['contactSearchType'] !== null ? params['contactSearchType'] : '';
      // 源码仅 onCreate 读 intent；HAP onPageShow 只在首次带参时装载
      if (this.gh === '' && ghParam !== '') {
        this.gh = ghParam;
        this.fallbackPhone = phoneParam;
        this.contactSearchType = typeParam;
        this.loadData();
      }
      if (this.refreshFlag) {
        this.refreshFlag = false;
      }
    }
  }

  /** 源码 l3()：contactSearchType 空 → f1 userInfo {gh}；非空 → g1 userMessage/userInfo {gh,searchType} */
  private loadData(): void {
    this.isLoading = true;
    this.showError = false;
    this.showEmpty = false;
    ApiService.getContactUserInfo(this.gh, this.contactSearchType)
      .then((response: ApiResponse<ContactAddressBookUserInfo>) => {
        if (response.code === 1000) {
          this.isLoading = false;
          return;
        }
        this.isLoading = false;
        if (response.code !== 0) {
          // 源码 f()：toast(message)；-3010 → ERROR_NETWORK；非 -3010 源码为 s2 loading 死态，HAP 折中空态
          const msg: string = response.message === '' ? '服务器繁忙，请稍后再试' : response.message;
          this.getUIContext().getPromptAction().showToast({ message: msg });
          if (String(response.code) === '-3010') {
            this.showError = true;
          } else {
            this.showEmpty = true;
          }
          return;
        }
        // 源码 g()：null → EMPTY；否则 CONTENT + r3 渲染
        if (response.data.name === '' && response.data.userInfo.GH === '') {
          this.showEmpty = true;
          return;
        }
        // 源码 r3 613-614：手机行值 = BDSJH 空 → SJHM，并回写 userInfo.SJHM（后续 q3/tvAddToLocal 收集覆写后值）
        const bean: ContactAddressBookUserInfo = response.data;
        bean.userInfo.SJHM = bean.userInfo.BDSJH === '' ? bean.userInfo.SJHM : bean.userInfo.BDSJH;
        if (bean.userInfo.SJHM === '' && this.fallbackPhone !== '') {
          bean.userInfo.SJHM = this.fallbackPhone;
        }
        this.info = bean;
        this.moreAddType = response.data.type === '' ? '0' : response.data.type;
        this.moreRoleType = response.data.roleType === '' ? '0' : response.data.roleType;
      })
      .catch(() => {
        // 源码 e() → ERROR 态
        ApiService.logError('ContactPersonalDetailPage load error');
        this.isLoading = false;
        this.showError = true;
      });
  }

  /** 行值：label/value 空值处理（源码 j3：label 空→""、value 空→"--"） */
  private rowValue(value: string): string {
    return value === '' ? '--' : value;
  }

  /** 源码 p3/e 类：内容点击 → t3(单号拆分, 1, GH) 打电话链 */
  private onPhoneTextTap(phone: string): void {
    if (phone === '') {
      return;
    }
    const numbers: string[] = phone.replace('/', ',').split(',');
    this.showDialSheet(numbers, 1, this.info.userInfo.GH);
  }

  /** 源码 q3(i)：发短信(i=0)/打电话(i=1) 工具按钮 → 号集收集（BDSJH 非空清空集合） */
  private onActionPhoneTap(tapType: number): void {
    if (this.info.userInfo.GH === '' && this.info.userInfo.BDSJH === '' &&
      this.info.userInfo.BGDH === '' && this.info.userInfo.SJDH === '' &&
      this.info.userInfo.SJHM === '') {
      return;
    }
    const list: string[] = [];
    const collect = (raw: string): void => {
      if (raw === '') {
        return;
      }
      const parts: string[] = raw.replace('/', ',').split(',');
      for (const p of parts) {
        list.push(p);
      }
    };
    collect(this.info.userInfo.BGDH);
    collect(this.info.userInfo.SJDH);
    collect(this.info.userInfo.SJHM);
    if (this.info.userInfo.BDSJH !== '') {
      list.length = 0;
      collect(this.info.userInfo.BDSJH);
    }
    // 源码 new HashSet(arrayList) 去重
    const unique: string[] = [];
    for (const p of list) {
      if (!unique.includes(p)) {
        unique.push(p);
      }
    }
    this.showDialSheet(unique, tapType, this.info.userInfo.GH);
  }

  /** 源码 t3：空→toast；>1→ContactListDialog 选号弹窗；≤1→o3 直处理 */
  private showDialSheet(numbers: string[], tapType: number, gh: string): void {
    if (numbers.length === 0) {
      this.getUIContext().getPromptAction().showToast({ message: '暂无该联系人电话号码' });
      return;
    }
    if (numbers.length <= 1) {
      this.handleDialChoice(1, tapType, numbers[0], gh);
      return;
    }
    const sheets: SheetInfo[] = [];
    for (const num of numbers) {
      const trimmed: string = num.trim();
      sheets.push({
        title: trimmed,
        action: (): void => {
          // 源码 k 类：弹窗点击 → o3(弹窗项数, z.p(), item, GH)（弹窗项数>1）
          this.handleDialChoice(sheets.length, tapType, trimmed, gh);
        }
      });
    }
    this.getUIContext().showActionSheet({ title: '选择号码', message: '请选择要拨打的号码', sheets: sheets });
  }

  /** 源码 o3：i2==0→d0.c 短信（HAP 等价 makeCall，同 W9 先例）；i2==1：≤1→s3 确认框；>1→直接拨+addTopContact */
  private handleDialChoice(count: number, tapType: number, phone: string, gh: string): void {
    if (tapType === 0) {
      this.makeCall(phone);
      return;
    }
    if (tapType !== 1) {
      return;
    }
    if (count <= 1) {
      // 源码 s3 确认框（widget.a m 类回调）：确认 → d0.a + addTopContact{scyhid:GH,type:"0"} + setResult(-1)
      AlertDialog.show({
        title: '拨打电话',
        message: phone,
        autoCancel: true,
        alignment: DialogAlignment.Center,
        primaryButton: { value: '取消', action: () => {
        } },
        secondaryButton: { value: '确定', action: () => {
          this.makeCall(phone);
          ApiService.addTopContact(gh, '0');
          this.refreshFlag = true;
        } }
      });
      return;
    }
    // 源码 count>1：埋点+ d0.a 直接拨号 + addTopContact + setResult(-1)
    this.makeCall(phone);
    ApiService.addTopContact(gh, '0');
    this.refreshFlag = true;
  }

  /** 源码 d0.a：权限回调后 ACTION_CALL 拨号 */
  private makeCall(phone: string): void {
    try {
      call.makeCall(phone, () => {
      });
    } catch {
      ApiService.logError('ContactPersonalDetailPage makeCall fail');
    }
  }

  /** 源码 C 类：发邮件 → mailto 隐式 want（无应用响应 → catch toast"请安装邮箱应用"） */
  private onMailTap(): void {
    const email: string = this.info.userInfo.DZYJ;
    if (email === '') {
      return;
    }
    const ctx = this.getUIContext().getHostContext() as common.UIAbilityContext;
    const first: string = email.replace('/', ',').split(',')[0].trim();
    try {
      ctx.startAbility({
        action: 'mailto:' + first,
        entities: ['entity.system.default'],
        parameters: { 'email': email.replace('/', ',').split(',') }
      } as Want).catch(() => {
        this.getUIContext().getPromptAction().showToast({ message: '请安装邮箱应用' });
      });
    } catch {
      this.getUIContext().getPromptAction().showToast({ message: '请安装邮箱应用' });
    }
  }

  /** 源码 h 类 tvAddToLocal：BGDH+SJDH+SJHM(覆写后) 非空 → 免受限权限拉起系统通讯录保存页 */
  private saveToLocal(): void {
    const list: string[] = [];
    if (this.info.userInfo.BGDH !== '') {
      list.push(this.info.userInfo.BGDH.replace('/', ',').split(',')[0].trim());
    }
    if (this.info.userInfo.SJDH !== '') {
      list.push(this.info.userInfo.SJDH.replace('/', ',').split(',')[0].trim());
    }
    if (this.info.userInfo.SJHM !== '') {
      list.push(this.info.userInfo.SJHM.replace('/', ',').split(',')[0].trim());
    }
    const displayName: string = this.info.name !== '' ? this.info.name : this.info.userInfo.XM;
    if (list.length === 0 && displayName === '' && this.info.userInfo.DZYJ === '') {
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
        name: { fullName: displayName !== '' ? displayName : this.gh } as contact.Name
      } as contact.Contact;
      if (phones.length > 0) {
        c.phoneNumbers = phones;
      }
      if (this.info.userInfo.DZYJ !== '') {
        const emailAddr: string = this.info.userInfo.DZYJ.replace('/', ',').split(',')[0].trim();
        if (emailAddr !== '') {
          c.emails = [{ email: emailAddr } as contact.Email];
        }
      }
      if (this.info.userInfo.BMMC !== '' || this.info.userInfo.ZW !== '') {
        c.organization = {
          name: this.info.userInfo.BMMC,
          title: this.info.userInfo.ZW
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
          ApiService.logError('ContactPersonalDetailPage addContactViaUI fail');
          this.getUIContext().getPromptAction().showToast({ message: '拉起系统通讯录失败，请检查设备通讯录服务' });
        });
    } catch (_e) {
      ApiService.logError('ContactPersonalDetailPage saveToLocal exception');
      this.getUIContext().getPromptAction().showToast({ message: '拉起系统通讯录失败' });
    }
  }

  /** 源码 h 类 tvAddToNet："0"→h3 addTopContact{scyhid:gh,type:"1"}；else k3 delTopContact{gh} */
  private onAddToNetTap(): void {
    if (this.moreAddType === '0') {
      ApiService.addToTopContact(this.gh, '1')
        .then((response: ApiResponse<string>) => {
          if (response.code !== 0) {
            return;
          }
          if (response.data === '1') {
            this.getUIContext().getPromptAction().showToast({ message: '已添加到常用联系人' });
            this.moreAddType = '1';
            this.refreshFlag = true;
          }
        });
      return;
    }
    if (this.info.userInfo.GH === '') {
      return;
    }
    ApiService.removeTopContact(this.info.userInfo.GH)
      .then((response: ApiResponse<string>) => {
        if (response.code !== 0) {
          return;
        }
        if (response.data === '1') {
          this.moreAddType = '0';
          this.refreshFlag = true;
        }
      });
  }

  /** 源码 h 类 tvPermissions："1"→n3 openRole；"2"→m3 hideRole */
  private onPermissionsTap(): void {
    if (this.moreRoleType === '1') {
      ApiService.openRole(this.gh)
        .then((response: ApiResponse<string>) => {
          if (response.code !== 0) {
            return;
          }
          if (response.message === '已对其开放手机号码查看权限' || response.message === '已开放权限') {
            this.moreRoleType = '2';
          }
          this.getUIContext().getPromptAction().showToast({ message: response.message });
        });
      return;
    }
    if (this.moreRoleType === '2') {
      ApiService.hideRole(this.gh)
        .then((response: ApiResponse<string>) => {
          if (response.code !== 0) {
            return;
          }
          if (response.data === '1') {
            this.moreRoleType = '1';
          }
        });
    }
  }

  /** 源码 r3：头像区。TX 空 → icon 首字+性别角标；TX 非空 → 网络图(netconstant.d.c()+TX) */
  private avatarUrl(): string {
    if (this.info.userInfo.TX === '') {
      return '';
    }
    return Constants.SOCKET_HOST + this.info.userInfo.TX;
  }

  /** 源码 r3：icon 背景 = XB 性别角标（男 gender_man/女 gender_woman/其他 gender_unknown） */
  private genderColor(): string {
    const xb: string = this.info.userInfo.XB;
    if (xb === '女') {
      return '#FF5F5F';
    }
    if (xb === '男') {
      return '#3A7BFF';
    }
    return '#F9C043';
  }

  /** 源码 r3：三号全空 → tvMsg/tvPhone gone */
  private phoneActionsVisible(): boolean {
    const u = this.info.userInfo;
    return !(u.SJHM === '' && u.BGDH === '' && u.SJDH === '');
  }

  /** 源码 r3：登录者非教师(userInfo.userType=="2" && 登录者!="2") → 授课行 */
  private teacherCourseVisible(): boolean {
    return this.info.userInfo.userType === '2' && LoginSession.userType !== '2';
  }

  /** 源码 more g()：登录者 userType=="1" → tvAddToNet gone */
  private addToNetVisible(): boolean {
    return LoginSession.userType !== '1';
  }

  /** 源码 s(roleType)："0"gone/"1"手机号码对其可见/"2"手机号码对其不可见 */
  private permissionsText(): string {
    if (this.moreRoleType === '1') {
      return '手机号码对其可见';
    }
    if (this.moreRoleType === '2') {
      return '手机号码对其不可见';
    }
    return '手机号码对其可见';
  }

  /** 源码 t(type)："0"添加到常用联系人/"1"移除常用联系人 */
  private addToNetText(): string {
    return this.moreAddType === '1' ? '移除常用联系人' : '添加到常用联系人';
  }

  build() {
    Stack() {
      Column() {
        TitleBar({
          title: '',
          showBack: true,
          rightIcon: $r('app.media.mobile_campus_contact_more'),
          onRightClick: () => {
            this.showMore = true;
          }
        })
        // 源码 T1：more 图标 padding 8dip（TitleBar 组件默认边距等价）

        if (this.isLoading) {
          LoadingView()
        } else if (this.showError) {
          Column() {
            EmptyView({ tipText: '加载失败，请检查网络后重试' })
          }
          .width('100%')
          .layoutWeight(1)
        } else if (this.showEmpty) {
          Column() {
            EmptyView({ tipText: '暂无数据' })
          }
          .width('100%')
          .layoutWeight(1)
        } else {
          Scroll() {
            Column() {
              // 头部白卡 padT8
              Column() {
                Column() {
                  if (this.avatarUrl() !== '') {
                    Image(this.avatarUrl())
                      .width(60)
                      .height(60)
                      .borderRadius(30)
                  } else {
                    // icon：blue_circle 30fp 白字，post(setWidth(height)) 方形等价 40×40
                    Text(this.info.name === '' ? '' : this.info.name.substring(0, 1))
                      .fontSize(30)
                      .fontColor($r('app.color.ybg_white'))
                      .width(40)
                      .height(40)
                      .textAlign(TextAlign.Center)
                      .backgroundColor(this.genderColor())
                      .borderRadius(20)
                  }
                  Text(this.info.name)
                    .fontSize(17)
                    .fontColor($r('app.color.common_color_1'))
                    .margin({ top: 12 })
                }
                .width('100%')
                .alignItems(HorizontalAlign.Center)

                // 操作行 mt25.5 pad5：自动折行避免窄屏溢出
                Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.Center, alignItems: ItemAlign.Start }) {
                  this.actionItem('发短信', $r('app.media.mobile_campus_contact_msn_b'), () => {
                    // 源码 i 类：q3(0) 短信链
                    this.onActionPhoneTap(0);
                  })
                  this.actionItem('打电话', $r('app.media.mobile_campus_contact_call_b'), () => {
                    // 源码 j 类：q3(1) 电话链
                    this.onActionPhoneTap(1);
                  })
                  // [W23 协作解堵] @Builder 返回 void 不能链 .visibility（原 487:20）→ if 包裹等价
                  if (this.info.userInfo.DZYJ !== '') {
                    this.actionItem('发邮件', $r('app.media.mobile_campus_contact_email_b'), () => {
                      this.onMailTap();
                    })
                  }
                  this.qrActionItem('名片码', () => {
                    this.openQrModal();
                  })
                  // tvIm：ImConstant 默认 false → 恒 gone（源码 r3 589-593）——不渲染等价 Visibility.None
                }
                .width('100%')
                .padding(5)
                .margin({ top: 25.5 })
              }
              .width('100%')
              .padding({ top: 8 })
              .backgroundColor($r('app.color.white'))

              // layoutContainer mt12 白底
              Column() {
                this.detailRows()
              }
              .width('100%')
              .margin({ top: 12 })
              .backgroundColor($r('app.color.white'))
            }
            .width('100%')
            .constraintSize({ maxWidth: BreakpointSystem.getContentMaxWidth(this.currentBreakpoint) })
            .padding({ bottom: Math.max(12, this.avoidAreaBottomVp) })
          }
          .width('100%')
          .layoutWeight(1)
          .scrollBar(BarState.Off)
          .align(Alignment.Top)
        }
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#F2F2F2')

      if (this.showQrModal) {
        this.qrModalOverlay()
      }
    }
    .width('100%')
    .height('100%')
    .bindSheet(this.showMore, this.moreSheetBuilder(), {
      height: 380,
      preferType: AdaptiveLayoutHelper.getSheetPreferType(this.currentBreakpoint, this.isCompactHeight),
      showClose: false,
      backgroundColor: '#F2F2F2',
      onDisappear: () => {
        this.showMore = false;
      }
    })
  }

  @Builder
  qrActionItem(label: string, onTap: () => void) {
    Column() {
      SymbolGlyph($r('sys.symbol.qrcode'))
        .fontSize(26)
        .fontColor(['#3A92ED'])
        .width(28)
        .height(28)
      Text(label)
        .fontSize(14)
        .fontColor('#3A92ED')
        .margin({ top: 8 })
    }
    .width(84)
    .alignItems(HorizontalAlign.Center)
    .onClick(() => {
      onTap();
    })
  }

  @Builder
  qrModalOverlay() {
    Column() {
      Scroll() {
        Column() {
          Row() {
            Text('联系人名片二维码')
              .fontSize(17)
              .fontWeight(FontWeight.Medium)
              .fontColor($r('app.color.common_color_1'))
              .layoutWeight(1)
            Text('关闭')
              .fontSize(15)
              .fontColor('#3A92ED')
              .padding({ left: 8, right: 4, top: 4, bottom: 4 })
              .onClick(() => {
                this.closeQrModal();
              })
          }
          .width('100%')

          if (this.info.name !== '') {
            Text(this.info.name)
              .fontSize(16)
              .fontWeight(FontWeight.Bold)
              .fontColor($r('app.color.common_color_1'))
              .margin({ top: 10 })
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
          }
          if (this.info.userInfo.BMMC !== '') {
            Text(this.info.userInfo.BMMC)
              .fontSize(13)
              .fontColor($r('app.color.common_color_3'))
              .margin({ top: 4 })
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
          }

          if (this.qrLoading) {
            LoadingProgress()
              .width(42)
              .height(42)
              .margin({ top: 40, bottom: 40 })
          } else if (this.qrPixelMap !== null) {
            Image(this.qrPixelMap)
              .width(200)
              .height(200)
              .objectFit(ImageFit.Contain)
              .margin({ top: 14, bottom: 10 })
              .backgroundColor($r('app.color.white'))
          }

          Text('扫码可快速导入联系人名片（vCard 3.0）')
            .fontSize(12)
            .fontColor($r('app.color.common_color_3'))
            .margin({ bottom: 14 })

          if (this.qrPixelMap !== null) {
            SaveButton({
              icon: SaveIconStyle.FULL_FILLED,
              text: SaveDescription.SAVE_TO_GALLERY,
              buttonType: ButtonType.Capsule
            })
              .height(38)
              .fontSize(14)
              .fontColor($r('app.color.white'))
              .iconColor($r('app.color.white'))
              .backgroundColor('#3A92ED')
              .padding({ left: 18, right: 18 })
              .onClick((_event: ClickEvent, result: SaveButtonOnClickResult) => {
                if (result === SaveButtonOnClickResult.SUCCESS) {
                  this.saveQrToGallery();
                } else {
                  this.getUIContext().getPromptAction().showToast({ message: '未获得保存授权' });
                }
              })
          }
        }
        .width('100%')
        .alignItems(HorizontalAlign.Center)
        .padding({ left: 20, right: 20, top: 16, bottom: 20 })
      }
      .scrollBar(BarState.Off)
      .width(AdaptiveLayoutHelper.getDialogMaxWidth(this.currentBreakpoint, this.windowWidthVp))
      .constraintSize({ maxHeight: AdaptiveLayoutHelper.getDialogMaxHeight(this.windowHeightVp) })
      .backgroundColor($r('app.color.white'))
      .borderRadius(12)
      .onClick(() => {
        // 拦截弹窗内部点击冒泡
      })
    }
    .width('100%')
    .height('100%')
    .padding({ left: 16, right: 16 })
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .backgroundColor('#66000000')
    .onClick(() => {
      this.closeQrModal();
    })
  }

  /** 头部操作按钮：宽 88 #3a92ed 图标上文本下 */
  @Builder
  actionItem(label: string, icon: Resource, onTap: () => void) {
    Column() {
      Image(icon)
        .width(28)
        .height(28)
      Text(label)
        .fontSize(14)
        .fontColor('#3A92ED')
        .margin({ top: 8 })
    }
    .width(88)
    .alignItems(HorizontalAlign.Center)
    .onClick(() => {
      onTap();
    })
  }

  /** 详情行：view_personal_detail_item padL11.5 padV11 16fp + 分隔线；contentTap 仅内容区可点 */
  @Builder
  detailRow(label: string, content: string, contentColor: string, contentTap: () => void) {
    Column() {
      Row() {
        Text(label)
          .fontSize(16)
          .fontColor($r('app.color.common_color_1'))
          .maxLines(1)
          .textAlign(TextAlign.Center)
        Text(this.rowValue(content))
          .fontSize(16)
          .fontColor(contentColor)
          .layoutWeight(1)
          .textAlign(TextAlign.Start)
          .maxLines(1)
          .onClick(() => {
            contentTap();
          })
      }
      .width('100%')
      .padding({ top: 11, bottom: 11 })
      .alignItems(VerticalAlign.Center)

      Divider()
        .color($r('app.color.common_color_5'))
        .strokeWidth(0.5)
        .width('100%')
    }
    .width('100%')
    .padding({ left: 11.5 })
    .backgroundColor($r('app.color.white'))
  }

  /** 源码 r3 行序（逐行 1:1） */
  @Builder
  detailRows() {
    // 授课：教师且登录者非教师（r3 596-600）
    if (this.teacherCourseVisible()) {
      this.detailRow('授课：', this.info.userInfo.course, '#333333', () => {
      })
    }
    this.detailRow('部门：', this.info.userInfo.BMMC, '#333333', () => {
    })
    // userType=="1" 学生 → 学号；否则工号
    if (this.info.userInfo.userType === '1') {
      this.detailRow('学号：', this.info.userInfo.XH, '#333333', () => {
      })
    } else {
      this.detailRow('工号：', this.info.userInfo.GH, '#333333', () => {
      })
    }
    // 手机：BDSJH 空 → SJHM（覆写 userInfo.SJHM）；#3a92ed 可点
    this.detailRow('手机：', this.info.userInfo.SJHM, '#3A92ED', () => {
      this.onPhoneTextTap(this.info.userInfo.SJHM);
    })
    this.detailRow('电话：', this.info.userInfo.BGDH, '#3A92ED', () => {
      this.onPhoneTextTap(this.info.userInfo.BGDH);
    })
    this.detailRow('短号：', this.info.userInfo.SJDH, '#3A92ED', () => {
      this.onPhoneTextTap(this.info.userInfo.SJDH);
    })
    this.detailRow('邮箱：', this.info.userInfo.DZYJ, '#3A92ED', () => {
      this.onMailTap();
    })
    this.detailRow('地址：', this.info.userInfo.BGDZ, '#333333', () => {
    })
    if (this.info.userInfo.RZBD_QQ !== '') {
      this.detailRow('QQ号：', this.info.userInfo.RZBD_QQ, '#333333', () => {
      })
    }
    // 源码文案"微信号号："原样保真
    if (this.info.userInfo.RZBD_WX !== '') {
      this.detailRow('微信号号：', this.info.userInfo.RZBD_WX, '#333333', () => {
      })
    }
    if (this.info.userInfo.ZW !== '') {
      this.detailRow('职位：', this.info.userInfo.ZW, '#333333', () => {
      })
    }
    if (this.info.userInfo.GW !== '') {
      this.detailRow('职称：', this.info.userInfo.GW, '#333333', () => {
      })
    }
    if (this.info.userInfo.CARDNO !== '') {
      this.detailRow('车牌：', this.info.userInfo.CARDNO, '#333333', () => {
      })
    }
    // 学生附加块 i3()（userType=="1"）
    if (this.info.userInfo.userType === '1') {
      this.detailRow('性别：', this.info.userInfo.studentSex, '#333333', () => {
      })
      this.detailRow('籍贯：', this.info.userInfo.nativePlace, '#333333', () => {
      })
      this.detailRow('辅导员：', this.info.userInfo.teacherName, '#333333', () => {
      })
      this.detailRow('辅导员电话：', this.info.userInfo.teacherPhone, '#333333', () => {
        this.onPhoneTextTap(this.info.userInfo.teacherPhone);
      })
      this.detailRow('班级：', this.info.userInfo.className, '#333333', () => {
      })
      this.detailRow('专业：', this.info.userInfo.professionName, '#333333', () => {
      })
    }
  }

  /** ContactMoreDialog 底部弹窗（bindSheet 等价 ExpressionPopupAnim） */
  @Builder
  moreSheetBuilder() {
    Scroll() {
      Column() {
        if (this.addToNetVisible()) {
          Text(this.addToNetText())
            .fontSize(18)
            .fontColor('#3A92ED')
            .width('100%')
            .height(56)
            .textAlign(TextAlign.Center)
            .backgroundColor($r('app.color.white'))
            .hoverEffect(HoverEffect.Highlight)
            .onClick(() => {
              this.showMore = false;
              this.onAddToNetTap();
            })
        }
        // tvAddToLocal：收集三号 → 系统通讯录写入
        Text('保存到通讯录')
          .fontSize(18)
          .fontColor('#3A92ED')
          .width('100%')
          .height(56)
          .margin({ top: 1 })
          .textAlign(TextAlign.Center)
          .backgroundColor($r('app.color.white'))
          .hoverEffect(HoverEffect.Highlight)
          .onClick(() => {
            this.showMore = false;
            setTimeout(() => {
              this.saveToLocal();
            }, 120);
          })
        if (this.moreRoleType !== '0') {
          Text(this.permissionsText())
            .fontSize(18)
            .fontColor('#3A92ED')
            .width('100%')
            .height(56)
            .margin({ top: 1 })
            .textAlign(TextAlign.Center)
            .backgroundColor($r('app.color.white'))
            .hoverEffect(HoverEffect.Highlight)
            .onClick(() => {
              this.showMore = false;
              this.onPermissionsTap();
            })
        }
        Text('生成名片二维码')
          .fontSize(18)
          .fontColor('#3A92ED')
          .width('100%')
          .height(56)
          .margin({ top: 1 })
          .textAlign(TextAlign.Center)
          .backgroundColor($r('app.color.white'))
          .hoverEffect(HoverEffect.Highlight)
          .onClick(() => {
            this.showMore = false;
            this.openQrModal();
          })
        Text('取消')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor('#3A92ED')
          .width('100%')
          .height(56)
          .margin({ top: 8 })
          .textAlign(TextAlign.Center)
          .backgroundColor($r('app.color.white'))
          .hoverEffect(HoverEffect.Highlight)
          .onClick(() => {
            this.showMore = false;
          })
      }
      .width('100%')
      .padding({ top: 1 })
    }
    .width('100%')
    .scrollBar(BarState.Off)
  }
}
