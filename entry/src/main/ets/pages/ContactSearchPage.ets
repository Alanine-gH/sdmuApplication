import { router } from '@kit.ArkUI';
import { call } from '@kit.TelephonyKit';
import { ApiService } from '../network/ApiService';
import { ApiResponse } from '../model/ResponseModel';
import { ContactSearchAddressBook, ContactSearchAddressBookItem } from '../model/ContactModel';
import { EmptyView } from '../components/EmptyView';
import { LoadingView } from '../components/LoadingView';
import { PreferencesUtil } from '../data/PreferencesUtil';
import { Constants } from '../data/Constants';
import { BreakpointSystem } from '../common/BreakpointSystem';

/**
 * 通讯录搜索页 — 源码级翻译（ContactSearchActivity.java 逐行 → ArkTS，禁截图猜测）：
 *
 * 【布局】mobile_campus_contact_activity_search.xml：#f2f2f2 竖排
 *   toolbar_base_search：44dip main_bg → 白底 RelativeLayout pr12：
 *     ClearableEditText（navigation_bar_search_et_input_search_key）32dip 14sp common_color_1
 *     hint"输入姓名、电话号码搜索" hint#B5B5B5 shape_base_search 圆角 padH8 search_b 图标 dp9
 *     imeOptions=actionSearch；"取消"（navigation_bar_search_tv_right_btn）15sp ml8 → finish
 *   MultiStateView：exListView（搜索结果 ExpandableListView）+ common_lv（历史缓存 ListView，默认 gone）
 *
 * 【历史缓存】ContactCachePImpl（contact/d/a.java）：Hawk 持久化 List<AddressBookListBean>
 *   最多 10 条、新条插头部、按 XM 去重；缓存非空 → k3() 显示 common_lv + 头"历史搜索"
 *   （32dip 13sp#696969 白底 padL12.5）+ 脚"清空搜索记录"（13sp#696969 mt29.5 rubbish 图标）
 *   缓存项 view_search_cache：48dip 白底 padL12.5 pr12 tvName 16sp + close_g p12
 *   点缓存项 → 填入关键词 + y=1 搜索（源码 b 类，不跳详情）；点 X → 移除该条
 *
 * 【搜索】h.onEditorAction（IME 3/6）：空 → toast"输入的内容不能为空"（input_can_not_be_empty）；
 *   非空 → o.e(bean{XM}) 存缓存 → y=1 → userType=="1"→m3（ContactPImpl.u→ContactModel.d1
 *   searchAddressBookForStu）userType=="2"→l3（x 空→ContactPImpl.t→ContactModel.c1 searchAddressBook；
 *   x 非空→ContactPImpl.v→ContactModel.e1 userMessage/searchUser）（"1"=学生/"2"=教师，
 *   [W25-review 注释纠偏] 原注释方向写反；HAP 分流在 ApiService.searchAddressBook 内部按 userType 实现）
 *   pageSize = AgooConstants.ACK_PACK_ERROR = "15"
 *   【实测 2026-11-17】searchAddressBook 教师接口恒 0001 系统异常；ForStu code=0 —— 失败即空态
 *
 * 【结果】adapter/d.java ContactSearchExpanAdapter：组=SearchAddressBook(bmmc 组名) 全展开；
 *   追加时同 bmdm 合并到最后一组（r.b）；组头 view_search_group 36dip bg#f2f2f2 15sp#696969，
 *   点击（x 空）→ 部门页{bmdm,bmmc} 2333（HAP 部门页未接入 → toast，与 ContactPage 一致）
 *   子项 view_search_child：60dip 白底 padL12 头像36（TX 网络图/首字+性别底色
 *   gender_man#3A7BFF gender_woman#FF5F5F gender_unknown#F9C043）名17sp tvCareer ZW 14sp#999999
 *   ml11（px_to_dip_22）tvSub 电话 BDSJH||SJHM 14sp mobile_campus_contact mt8（空→隐藏）；
 *   右侧 imgPhone(call)→c.a(1) 确认框+addTopContact{scyhid:XLH,type:"0"}、imgMsg(msn)→c.a(0) 直接拨，
 *   mr23 ml15（电话空整组隐藏）；行点击 isYellowCard=="1" → toast"黄页暂无详情"，否则详情{gh:XLH}
 *
 * 【分页】y 从 1 起，成功有数据 y+1 且开上拉；无数据关上拉；上拉 → 同参数追加（r.b 合并）；
 *   空结果 → EMPTY_SEARCH 空态；-3010 → ERROR_NETWORK
 */
@Entry
@Component
struct ContactSearchPage {
  @State keyword: string = '';
  @State groups: ContactSearchAddressBook[] = [];
  /** 历史搜索缓存（ContactCachePImpl 持久化，源码 Hawk key 等价自管） */
  @State cacheList: ContactSearchAddressBookItem[] = [];
  @State showCache: boolean = false;
  @State isLoading: boolean = false;
  @StorageProp('currentBreakpoint') currentBreakpoint: string = 'sm';
  @StorageProp('avoidAreaBottomVp') avoidAreaBottomVp: number = 0;
  @StorageProp('avoidAreaLeftVp') avoidAreaLeftVp: number = 0;
  @StorageProp('avoidAreaRightVp') avoidAreaRightVp: number = 0;
  @StorageProp('keyboardHeightVp') keyboardHeightVp: number = 0;
  /** 源码 y：分页页码（新搜索重置 1，成功有数据自增） */
  private pageNum: number = 1;
  /** 源码 x：contactSearchType（独立入口无该 intent 参数，恒空 → t/u 分支） */
  private readonly searchType: string = '';
  private readonly CACHE_KEY: string = 'contact_search_cache';

  onPageShow(): void {
    this.restoreCache();
  }

  /** ContactCachePImpl.a()：读缓存列表（按 XM 去重在写入侧完成） */
  private restoreCache(): void {
    PreferencesUtil.getString(this.CACHE_KEY, '[]')
      .then((v: string) => {
        const list: ContactSearchAddressBookItem[] = [];
        try {
          const parsed: Object = JSON.parse(v) as Object;
          if (Array.isArray(parsed)) {
            for (const one of parsed as Object[]) {
              const rec: Record<string, Object> = one as Record<string, Object>;
              const item: ContactSearchAddressBookItem = new ContactSearchAddressBookItem();
              item.XM = ApiService.pick(rec, ['XM']);
              item.XLH = ApiService.pick(rec, ['XLH']);
              list.push(item);
            }
          }
        } catch {
          ApiService.logError('ContactSearchPage cache restore fail');
        }
        this.cacheList = list;
        this.showCache = list.length > 0;
      });
  }

  /** ContactCachePImpl.e(bean)：入缓存（10 条上限、插头部、XM 去重） */
  private saveCache(item: ContactSearchAddressBookItem): void {
    const rest: ContactSearchAddressBookItem[] = [];
    for (const one of this.cacheList) {
      if (one.XM !== item.XM) {
        rest.push(one);
      }
    }
    rest.splice(0, 0, item);
    while (rest.length > 10) {
      rest.pop();
    }
    this.cacheList = rest;
    this.showCache = rest.length > 0;
    this.persistCache(rest);
  }

  /** ContactCachePImpl.f(list)：清空/覆写缓存 */
  private persistCache(list: ContactSearchAddressBookItem[]): void {
    const rows: Record<string, string>[] = [];
    for (const one of list) {
      const row: Record<string, string> = { 'XM': one.XM, 'XLH': one.XLH };
      rows.push(row);
    }
    PreferencesUtil.putString(this.CACHE_KEY, JSON.stringify(rows));
  }

  /** 源码 h.onEditorAction：IME 搜索/完成 → 提交搜索 */
  private submitSearch(): void {
    const kw: string = this.keyword.trim();
    if (kw === '') {
      this.getUIContext().getPromptAction().showToast({ message: '输入的内容不能为空' });
      return;
    }
    const bean: ContactSearchAddressBookItem = new ContactSearchAddressBookItem();
    bean.XM = kw;
    this.saveCache(bean);
    this.pageNum = 1;
    this.requestSearch(String(this.pageNum), kw, false);
  }

  /** 源码 m3/l3（b/h/g 类调用）：userType=="1"→m3→ContactModel.d1 searchAddressBookForStu；
   *  userType=="2"→l3→x 空 ContactModel.c1 searchAddressBook / x 非空 ContactModel.e1 searchUser。
   *  HAP 独立入口无 contactSearchType（x 恒空），userType 分流在 ApiService.searchAddressBook 内部。 */
  private requestSearch(page: string, kw: string, append: boolean): void {
    this.isLoading = !append;
    const request: Promise<ApiResponse<ContactSearchAddressBook[]>> = this.searchType === ''
      ? ApiService.searchAddressBook(page, kw) : ApiService.searchUser(this.searchType, page, kw);
    request
      .then((response: ApiResponse<ContactSearchAddressBook[]>) => {
        if (response.code === 1000) {
          // 登录失效统一处理已在网络层触发（HttpClient.bizRequest 拦截：清会话+toast+跳登录）
          return;
        }
        this.applyResult(response.data, append);
        this.isLoading = false;
      })
      .catch(() => {
        ApiService.logError('ContactSearchPage search error');
        this.groups = [];
        this.isLoading = false;
      });
  }

  /** 源码 d/e 类 g() 回调：新搜索 e(list) / 追加 b(list) 同 bmdm 合并；空→EMPTY_SEARCH */
  private applyResult(list: ContactSearchAddressBook[], append: boolean): void {
    if (append) {
      this.mergeAppend(list);
    } else {
      this.groups = list;
    }
    // 源码 g()：有数据 y+1 开上拉；空 y 不动关上拉（HAP List onReachEnd 按此判断）
    if (this.groups.length > 0 && this.hasChildren()) {
      this.pageNum = this.pageNum + 1;
    }
  }

  /** 源码 adapter.b()：追加时与最后一组同 bmdm 合并 */
  private mergeAppend(list: ContactSearchAddressBook[]): void {
    if (this.groups.length === 0) {
      this.groups = list;
      return;
    }
    const merged: ContactSearchAddressBook[] = this.groups.slice();
    const last: ContactSearchAddressBook = merged[merged.length - 1];
    if (list.length > 0 && list[0].bmdm === last.bmdm) {
      last.addressBookList = last.addressBookList.concat(list[0].addressBookList);
      for (let i = 1; i < list.length; i++) {
        merged.push(list[i]);
      }
    } else {
      for (const one of list) {
        merged.push(one);
      }
    }
    this.groups = merged;
  }

  private hasChildren(): boolean {
    let count: number = 0;
    for (const g of this.groups) {
      count += g.addressBookList.length;
    }
    return count > 0;
  }

  /** 源码 i.onGroupClick：x 空 → 部门页{bmdm,bmmc}（HAP 部门页未接入 → toast，与 ContactPage 一致） */
  private onGroupClick(group: ContactSearchAddressBook): void {
    this.getUIContext().getPromptAction().showToast({ message: '部门通讯录页面待接入' });
  }

  /** 源码 j.onChildClick / k.onItemClick：详情{gh:XLH}；黄页卡 toast"黄页暂无详情" */
  private onChildClick(group: ContactSearchAddressBook, childIdx: number): void {
    if (group.isYellowCard === '1') {
      this.getUIContext().getPromptAction().showToast({ message: '黄页暂无详情' });
      return;
    }
    const bean: ContactSearchAddressBookItem = group.addressBookList[childIdx];
    this.saveCache(bean);
    router.pushUrl({ url: 'pages/ContactPersonalDetailPage',
      params: { 'gh': bean.XLH } as Record<string, string> });
  }

  /** 源码 b.onItemClick（q 缓存 ListView）：仅填入关键词 + y=1 + 按 userType 搜索；
   *  不入缓存不跳详情（k 类挂在 ExpandableListView 上 instanceof 恒假，死代码不复刻） */
  private onCacheItemClick(item: ContactSearchAddressBookItem): void {
    this.keyword = item.XM;
    this.pageNum = 1;
    this.requestSearch(String(this.pageNum), item.XM, false);
  }

  /** 源码 a/n：缓存项移除 → o.f(剩余) 持久化，空则隐藏缓存列表 */
  private onCacheRemove(item: ContactSearchAddressBookItem): void {
    const rest: ContactSearchAddressBookItem[] = [];
    for (const one of this.cacheList) {
      if (!(one.XM === item.XM && one.XLH === item.XLH)) {
        rest.push(one);
      }
    }
    this.cacheList = rest;
    this.showCache = rest.length > 0;
    this.persistCache(rest);
  }

  /** 源码 a 类（footer 点击）：清空搜索记录 → o.f(getDatas) 持久化 + 隐藏 */
  private clearCache(): void {
    this.cacheList = [];
    this.showCache = false;
    this.persistCache([]);
  }

  /** 源码 c.a(i,phone,gh)：空号 toast；多号(","分隔)弹选号；i=0 直接拨 / i=1 确认+addTopContact */
  private onPhoneTap(phone: string, xlh: string, tapType: number): void {
    if (phone === '') {
      this.getUIContext().getPromptAction().showToast({ message: '暂无该联系人电话号码' });
      return;
    }
    const numbers: string[] = phone.replace('/', ',').split(',');
    if (numbers.length > 1) {
      this.showNumberSheet(numbers, tapType, xlh);
      return;
    }
    if (tapType === 0) {
      this.makeCall(phone);
      return;
    }
    this.showCallConfirm(phone, xlh);
  }

  /** 源码 ContactListDialog：底部选号弹窗（选号后按 type 处理） */
  private showNumberSheet(numbers: string[], tapType: number, xlh: string): void {
    const sheets: SheetInfo[] = [];
    for (const num of numbers) {
      const trimmed: string = num.trim();
      sheets.push({
        title: trimmed,
        action: (): void => {
          this.makeCall(trimmed);
          if (tapType === 1) {
            ApiService.addTopContact(xlh, '0');
          }
        }
      });
    }
    this.getUIContext().showActionSheet({ title: '选择号码', message: '请选择要拨打的号码', sheets: sheets });
  }

  /** 源码 o3()：确认框"拨打电话"→ 确认拨号 + addTopContact{scyhid:XLH,type:"0"} */
  private showCallConfirm(phone: string, xlh: string): void {
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
          ApiService.addTopContact(xlh, '0');
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
      ApiService.logError('ContactSearchPage makeCall fail');
    }
  }

  /** 子项电话（源码 getChildView）：BDSJH 空 → SJHM */
  private phoneOf(bean: ContactSearchAddressBookItem): string {
    return bean.BDSJH !== '' ? bean.BDSJH : bean.SJHM;
  }

  /** 头像 URL（源码 i.g(0, netconstant.d.c()+TX)） */
  private avatarUrlOf(bean: ContactSearchAddressBookItem): string {
    if (bean.TX === '') {
      return '';
    }
    return Constants.SOCKET_HOST + bean.TX;
  }

  /** 源码 adapter.g()：性别底色 gender_man#3A7BFF gender_woman#FF5F5F gender_unknown#F9C043 */
  private genderColorOf(bean: ContactSearchAddressBookItem): string {
    if (bean.XB === '女') {
      return '#FF5F5F';
    }
    if (bean.XB === '男') {
      return '#3A7BFF';
    }
    return '#F9C043';
  }

  build() {
    Column() {
      this.searchToolbar()
      if (this.isLoading) {
        LoadingView()
      } else if (this.showCache) {
        // 源码 k3()：缓存非空 → 显示历史缓存 ListView，隐藏结果
        this.cacheListView()
      } else if (this.groups.length === 0) {
        // 源码 CampusPage.EMPTY_SEARCH
        Column() {
          EmptyView({ tipText: '暂无搜索结果' })
        }
        .width('100%')
        .constraintSize({ maxWidth: BreakpointSystem.getContentMaxWidth(this.currentBreakpoint) })
        .alignSelf(ItemAlign.Center)
        .padding({
          left: this.avoidAreaLeftVp,
          right: this.avoidAreaRightVp,
          bottom: this.keyboardHeightVp + this.avoidAreaBottomVp
        })
        .layoutWeight(1)
      } else {
        this.resultList()
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F2F2F2')
  }

  /** toolbar_base_search：白底搜索框 32dip + "取消"（源码点击 finish） */
  @Builder
  searchToolbar() {
    Column() {
      Row() {
        Row() {
          Image($r('app.media.mobile_campus_contact_search_g'))
            .width(16)
            .height(16)
            .margin({ left: 8, right: 9 })
          TextInput({ text: this.keyword, placeholder: '输入姓名、电话号码搜索' })
            .fontSize(14)
            .fontColor($r('app.color.common_color_1'))
            .placeholderColor('#B5B5B5')
            .placeholderFont({ size: 14 })
            .backgroundColor(Color.Transparent)
            .border({ width: 0 })
            .padding(0)
            .layoutWeight(1)
            .height(32)
            .defaultFocus(true)
            .onChange((value: string) => {
              this.keyword = value;
            })
            .onSubmit(() => {
              this.submitSearch();
            })
        }
        .width('100%')
        .height(32)
        .borderRadius(4)
        .backgroundColor($r('app.color.white'))
        .padding({ left: 8, right: 8 })
        .alignItems(VerticalAlign.Center)
        .layoutWeight(1)

        Text('取消')
          .fontSize(15)
          .fontColor($r('app.color.common_color_1'))
          .height(44)
          .padding({ left: 8, right: 4 })
          .onClick(() => {
            this.getUIContext().getRouter().back();
          })
      }
      .width('100%')
      .height(44)
      .padding({
        left: Math.max(12, this.avoidAreaLeftVp),
        right: Math.max(12, this.avoidAreaRightVp)
      })
      .constraintSize({ maxWidth: BreakpointSystem.getContentMaxWidth(this.currentBreakpoint) })
      .alignSelf(ItemAlign.Center)
      .backgroundColor($r('app.color.main_bg'))
      .alignItems(VerticalAlign.Center)

      Divider()
        .color($r('app.color.common_color_5'))
        .strokeWidth(1)
        .width('100%')
    }
    .width('100%')
    .backgroundColor($r('app.color.main_bg'))
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP])
  }

  /** 历史缓存 ListView（源码 k3 + header/footer） */
  @Builder
  cacheListView() {
    List() {
      // view_search_header："历史搜索" 32dip 13sp#696969 白底 padL12.5
      ListItem() {
        Text('历史搜索')
          .fontSize(13)
          .fontColor('#696969')
          .width('100%')
          .height(32)
          .padding({ left: 12.5 })
          .backgroundColor($r('app.color.white'))
      }
      ForEach(this.cacheList, (item: ContactSearchAddressBookItem) => {
        ListItem() {
          this.cacheRow(item)
        }
      }, (item: ContactSearchAddressBookItem) => item.XM + '_' + item.XLH)
      // view_search_footer："清空搜索记录" + rubbish 图标 mt29.5
      ListItem() {
        Row() {
          Text('清空搜索记录')
            .fontSize(13)
            .fontColor('#696969')
          Image($r('app.media.rubbish_icon'))
            .width(14)
            .height(14)
            .margin({ left: 8 })
        }
        .width('100%')
        .justifyContent(FlexAlign.Center)
        .padding({ top: 29.5, bottom: 20 })
        .onClick(() => {
          this.clearCache();
        })
      }
    }
    .width('100%')
    .constraintSize({ maxWidth: BreakpointSystem.getContentMaxWidth(this.currentBreakpoint) })
    .alignSelf(ItemAlign.Center)
    .padding({ left: this.avoidAreaLeftVp, right: this.avoidAreaRightVp })
    .contentEndOffset(this.keyboardHeightVp + this.avoidAreaBottomVp)
    .layoutWeight(1)
    .scrollBar(BarState.Off)
    .backgroundColor('#F2F2F2')
  }

  /** view_search_cache：48dip 白底 padL12.5 pr12 tvName 16sp + close_g p12 */
  @Builder
  cacheRow(item: ContactSearchAddressBookItem) {
    Column() {
      Row() {
        Text(item.XM)
          .fontSize(16)
          .fontColor($r('app.color.common_color_1'))
          .height(48)
          .layoutWeight(1)
          .maxLines(1)
          .textAlign(TextAlign.Start)
        Image($r('app.media.mobile_campus_contact_close_g'))
          .width(14)
          .height(14)
          .padding(12)
          .onClick(() => {
            this.onCacheRemove(item);
          })
      }
      .width('100%')
      .padding({ left: 12.5, right: 12 })
      .backgroundColor($r('app.color.white'))
      .alignItems(VerticalAlign.Center)
      .onClick(() => {
        this.onCacheItemClick(item);
      })

      Divider()
        .color($r('app.color.common_color_5'))
        .strokeWidth(1)
        .width('100%')
    }
    .width('100%')
  }

  /** 搜索结果 ExpandableListView（源码全展开 + 上拉加载） */
  @Builder
  resultList() {
    List() {
      ForEach(this.groups, (group: ContactSearchAddressBook) => {
        ListItem() {
          this.groupBlock(group)
        }
      }, (group: ContactSearchAddressBook) => group.bmdm + '_' + group.bmmc)
    }
    .width('100%')
    .constraintSize({ maxWidth: BreakpointSystem.getContentMaxWidth(this.currentBreakpoint) })
    .alignSelf(ItemAlign.Center)
    .padding({ left: this.avoidAreaLeftVp, right: this.avoidAreaRightVp })
    .contentEndOffset(this.keyboardHeightVp + this.avoidAreaBottomVp)
    .layoutWeight(1)
    .scrollBar(BarState.Off)
    .onReachEnd(() => {
      // 源码 PullToRefreshLayout.b()：上拉 → 同参数追加（y 已自增）
      this.requestSearch(String(this.pageNum), this.keyword.trim(), true);
    })
  }

  /** 组块：组头 view_search_group + 子项 view_search_child（源码 expandGroup 全展开） */
  @Builder
  groupBlock(group: ContactSearchAddressBook) {
    Column() {
      Text(group.bmmc)
        .fontSize(15)
        .fontColor('#696969')
        .width('100%')
        .height(36)
        .padding({ left: 12, right: 12 })
        .backgroundColor('#F2F2F2')
        .maxLines(1)
        .textAlign(TextAlign.Start)
        .onClick(() => {
          this.onGroupClick(group);
        })
      ForEach(group.addressBookList, (bean: ContactSearchAddressBookItem, childIdx: number) => {
        this.searchChildRow(group, childIdx)
      }, (bean: ContactSearchAddressBookItem) => bean.XLH + '_' + bean.XM)
    }
    .width('100%')
  }

  /** view_search_child：60dip 白底 padL12（头像36 名17 职业14#999999 电话14 右侧双图标 mr23） */
  @Builder
  searchChildRow(group: ContactSearchAddressBook, childIdx: number) {
    Column() {
      Row() {
        if (this.avatarUrlOf(group.addressBookList[childIdx]) !== '') {
          Image(this.avatarUrlOf(group.addressBookList[childIdx]))
            .width(36)
            .height(36)
            .borderRadius(18)
        } else {
          Text(group.addressBookList[childIdx].XM === ''
            ? ' ' : group.addressBookList[childIdx].XM.substring(0, 1))
            .fontSize(18.5)
            .fontColor($r('app.color.ybg_white'))
            .width(36)
            .height(36)
            .textAlign(TextAlign.Center)
            .backgroundColor(this.genderColorOf(group.addressBookList[childIdx]))
            .borderRadius(18)
        }

        Column() {
          Row() {
            Text(group.addressBookList[childIdx].XM)
              .fontSize(17)
              .fontColor($r('app.color.common_color_1'))
              .maxLines(1)
            Text(group.addressBookList[childIdx].ZW)
              .fontSize(14)
              .fontColor('#999999')
              .margin({ left: 11 })
              .maxLines(1)
          }
          .alignItems(VerticalAlign.Center)

          Text(this.phoneOf(group.addressBookList[childIdx]))
            .fontSize(14)
            .fontColor($r('app.color.mobile_campus_contact'))
            .margin({ top: 8 })
            .maxLines(1)
            .visibility(this.phoneOf(group.addressBookList[childIdx]) === ''
              ? Visibility.None : Visibility.Visible)
        }
        .alignItems(HorizontalAlign.Start)
        .margin({ left: 12 })
        .layoutWeight(1)

        Row() {
          // 源码 imgPhone(call 图标) → c.a(1)：确认框+addTopContact；imgMsg(msn 图标) → c.a(0)：直接拨
          // 电话空 → 两者 setVisibility(8)（adapter/d.java:205-211），GONE 不占位
          Image($r('app.media.mobile_campus_contact_call'))
            .width(18)
            .height(18)
            .visibility(this.phoneOf(group.addressBookList[childIdx]) === '' ? Visibility.None : Visibility.Visible)
            .onClick(() => {
              this.onPhoneTap(this.phoneOf(group.addressBookList[childIdx]),
                group.addressBookList[childIdx].XLH, 1);
            })
          Image($r('app.media.mobile_campus_contact_msn'))
            .width(18)
            .height(18)
            .margin({ left: 15 })
            .visibility(this.phoneOf(group.addressBookList[childIdx]) === '' ? Visibility.None : Visibility.Visible)
            .onClick(() => {
              this.onPhoneTap(this.phoneOf(group.addressBookList[childIdx]),
                group.addressBookList[childIdx].XLH, 0);
            })
        }
        .margin({ right: 23 })
        .alignItems(VerticalAlign.Center)
      }
      .width('100%')
      .height(60)
      .padding({ left: 12 })
      .alignItems(VerticalAlign.Center)
      .backgroundColor($r('app.color.white'))
      .onClick(() => {
        this.onChildClick(group, childIdx);
      })

      Divider()
        .color($r('app.color.common_color_5'))
        .strokeWidth(1)
        .width('100%')
    }
    .width('100%')
    .backgroundColor($r('app.color.white'))
  }
}
