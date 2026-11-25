import { TitleBar } from '../components/TitleBar';
import { router } from '@kit.ArkUI';
import { call } from '@kit.TelephonyKit';
import { ApiService } from '../network/ApiService';
import { ApiResponse } from '../model/ResponseModel';
import { ContactClassStudentBean, contactClassPhoneOf } from '../model/ContactModel';
import { EmptyView } from '../components/EmptyView';
import { LoadingView } from '../components/LoadingView';

interface LetterGroup {
  letter: string;
  students: ContactClassStudentBean[];
}

/**
 * 班级通讯录页 — 源码级翻译（ContactClassAddressBookActivity.java 逐行 → ArkTS，[W25 misc-b]）：
 *
 * 【布局】mobile_campus_activity_contact_class_address_book.xml：toolbar + MultiStateView(IndexableLayout 白底，
 *   indexBar 文字 11fp(px_to_sp_22) ybg_blue 间隔4dip)
 * 【入参】y(Intent)：bjid（ContactPage 班级 tab 子项点击已带参）+ title（T1 gVar.n(m) toolbar 标题=班级名）
 * 【数据】P2() → ContactPImpl.n → ContactModel.X0：GET getClassAddressbook {bjid} → ClassAddressBook[]
 *   成功 b() 回调：size>0 → content 态；空 → EMPTY 态；业务失败 f() → toast(message)；网络失败 e() → ERROR 态
 * 【分组】IndexableLayout（ClassContactAdapter extends IndexableAdapter）：按 XM 拼音序 + 首字母分组；
 *   组头 mobile_campus_contact_item_class_title.xml（40dip bg#f2f2f2 11fp common_color_1 padH12）
 * 【行】mobile_campus_contact_view_classaddressbook.xml：60dip padL12 白底：
 *   icon 36dip 首字(px_to_sp_37≈18.5fp ybg_white) 背景=XB 性别三色 drawable（v()：男 gender_man/女
 *   gender_woman/其他 gender_unknown，W9 实证 #3A7BFF/#FF5F5F/#F9C043）；
 *   tvName=XM 17fp(px_to_sp_34)；tvSub=电话(BDSJH 空→SJHM) 14fp(px_to_sp_28) mt8 空隐藏；
 *   右侧 imgPhone(call)+imgMsg(msn ml15) 电话非空才显示（j() 138-141 行），imgMsg 无点击监听（源码只挂 imgPhone）；
 *   底部 divider_horizontal_grey_thin 1dip
 * 【交互】行点击 b()：{gh:XH} → ContactPersonalDetailActivity（e.a.m0 路由，HAP ContactPersonalDetailPage）
 *   imgPhone 点击 d()：电话空 → toast"暂无该联系人电话号码"；多号(","分隔，mipush ACCEPT_TIME_SEPARATOR_SP)
 *   → ContactListDialog 底部选号弹窗；单号 → Q2(1,1,phone) → R2 确认框"拨打电话"
 *   弹窗选号 c 类：Q2(弹窗项数, p()=1, item) → 项数>1 → d0.a 直接拨号（权限回调后 CALL）；≤1 → R2 确认框
 *   R2 确认框（widget.a "拨打电话"）确认 → d0.a 拨号
 * 【索引】IndexableLayout 首字母 = 拼音首字母（HAP 用 zh-Hans-CN 字典序 + 23 个参考汉字区间判定，零数据表）
 */
@Entry
@Component
struct ContactClassAddressBookPage {
  /** 班级名 = toolbar 标题（源码 T1 gVar.n(m)） */
  @State title: string = '';
  @State groups: LetterGroup[] = [];
  @State isLoading: boolean = true;
  @State showError: boolean = false;
  private bjid: string = '';
  private scroller: Scroller = new Scroller();
  /** 组头在 List 扁平项中的起始下标（字母条跳转用） */
  private groupStartIndex: number[] = [];
  /** IndexableLayout 字母序（源码 IndexBar 默认 A-Z，I/U/V 不参与中文拼音） */
  private readonly LETTERS: string = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';

  aboutToAppear(): void {
    const params = router.getParams() as Record<string, string>;
    if (params !== null && params !== undefined) {
      this.bjid = params['bjid'] !== undefined && params['bjid'] !== null ? params['bjid'] : '';
      this.title = params['title'] !== undefined && params['title'] !== null ? params['title'] : '';
    }
    this.loadData();
  }

  /** 源码 P2()：ContactModel.X0 GET getClassAddressbook {bjid} */
  private loadData(): void {
    this.isLoading = true;
    this.showError = false;
    ApiService.getClassAddressbook(this.bjid)
      .then((response: ApiResponse<ContactClassStudentBean[]>) => {
        if (response.code === 1000) {
          // 登录失效统一拦截层已处理（清会话+跳登录）
          this.isLoading = false;
          return;
        }
        this.isLoading = false;
        if (response.code !== 0) {
          // 源码 f() 回调：业务失败 → toast(message)
          const msg: string = response.message === '' ? '服务器繁忙，请稍后再试' : response.message;
          this.getUIContext().getPromptAction().showToast({ message: msg });
          this.showError = true;
          return;
        }
        // 源码 g() + b()：size>0 → content；空 → EMPTY
        this.groups = this.buildGroups(response.data);
      })
      .catch(() => {
        // 源码 e() 回调：异常 → ERROR 态
        ApiService.logError('ContactClassAddressBookPage load error');
        this.isLoading = false;
        this.showError = true;
      });
  }

  /** 拼音首字母判定：zh-Hans-CN 字典序 + 23 个参考汉字区间（对应 A B C D E F G H J K L M N O P Q R S T W X Y Z） */
  private pinyinFirstLetter(name: string): string {
    if (name === '') {
      return '#';
    }
    const ch: string = name.substring(0, 1);
    if (!/[\u4e00-\u9fff]/.test(ch)) {
      const upper: string = ch.toUpperCase();
      return upper >= 'A' && upper <= 'Z' ? upper : '#';
    }
    const refs: string[] = ['阿', '八', '擦', '搭', '蛾', '发', '嘎', '哈', '机', '咔', '垃', '妈',
      '拿', '哦', '趴', '七', '然', '撒', '塌', '挖', '希', '压', '匝'];
    const letters: string = 'ABCDEFGHJKLMNOPQRSTWXYZ';
    for (let i = 0; i < refs.length; i++) {
      if (ch.localeCompare(refs[i], 'zh-Hans-CN') < 0) {
        return i === 0 ? 'A' : letters.charAt(i - 1);
      }
    }
    return 'Z';
  }

  /** IndexableLayout 等价：XM 拼音序排序 → 首字母分组 */
  private buildGroups(list: ContactClassStudentBean[]): LetterGroup[] {
    const sorted: ContactClassStudentBean[] = list.slice()
      .sort((a: ContactClassStudentBean, b2: ContactClassStudentBean) =>
        a.XM.localeCompare(b2.XM, 'zh-Hans-CN'));
    const result: LetterGroup[] = [];
    this.groupStartIndex = [];
    for (const bean of sorted) {
      const letter: string = this.pinyinFirstLetter(bean.XM);
      if (result.length === 0 || result[result.length - 1].letter !== letter) {
        // List 扁平项下标 = 组头数 + 学生数（组头 1 项/组）
        this.groupStartIndex.push(this.flatCount(result));
        const group: LetterGroup = { letter: letter, students: [] };
        group.students.push(bean);
        result.push(group);
      } else {
        result[result.length - 1].students.push(bean);
      }
    }
    return result;
  }

  /** List 扁平项计数（组头 + 学生） */
  private flatCount(groups: LetterGroup[]): number {
    let count: number = 0;
    for (const g of groups) {
      count += 1 + g.students.length;
    }
    return count;
  }

  /** 字母条点击 → scrollToIndex 该组组头 */
  private scrollToLetter(letter: string): void {
    for (let i = 0; i < this.groups.length; i++) {
      if (this.groups[i].letter === letter) {
        this.scroller.scrollToIndex(this.groupStartIndex[i]);
        return;
      }
    }
  }

  /** 源码 d 类：行电话点击 → 空号 toast / 多号弹窗 / 单号确认框 */
  private onRowPhoneTap(phone: string): void {
    if (phone === '') {
      this.getUIContext().getPromptAction().showToast({ message: '暂无该联系人电话号码' });
      return;
    }
    const numbers: string[] = phone.replace('/', ',').split(',');
    if (numbers.length > 1) {
      this.showNumberSheet(numbers);
      return;
    }
    // 源码 Q2(len<=1, type=1) → R2 确认框
    this.showCallConfirm(phone);
  }

  /** 源码 ContactListDialog + c 类：选号弹窗（type=1）→ Q2(count>1) → d0.a 直接拨号 */
  private showNumberSheet(numbers: string[]): void {
    const sheets: SheetInfo[] = [];
    for (const num of numbers) {
      const trimmed: string = num.trim();
      sheets.push({
        title: trimmed,
        action: (): void => {
          // 源码 Q2(count,1,item)：弹窗项数>1 → d0.a 直接拨号
          this.makeCall(trimmed);
        }
      });
    }
    this.getUIContext().showActionSheet({ title: '选择号码', message: '请选择要拨打的号码', sheets: sheets });
  }

  /** 源码 R2（widget.a）：确认框"拨打电话" → 确认后 d0.a 拨号 */
  private showCallConfirm(phone: string): void {
    AlertDialog.show({
      title: '拨打电话',
      message: phone,
      autoCancel: true,
      alignment: DialogAlignment.Center,
      primaryButton: { value: '取消', action: () => {
      } },
      secondaryButton: { value: '确定', action: () => {
        this.makeCall(phone);
      } }
    });
  }

  /** 源码 d0.a：权限回调后 ACTION_CALL 拨号 */
  private makeCall(phone: string): void {
    try {
      call.makeCall(phone, () => {
      });
    } catch {
      ApiService.logError('ContactClassAddressBookPage makeCall fail');
    }
  }

  /** 源码 b 类：行点击 → {gh:XH} → ContactPersonalDetailActivity */
  private openDetail(bean: ContactClassStudentBean): void {
    router.pushUrl({ url: 'pages/ContactPersonalDetailPage',
      params: { 'gh': bean.XH, 'phone': contactClassPhoneOf(bean) } as Record<string, string> });
  }

  /** 源码 v(XB)：性别底色 gender_man#3A7BFF/gender_woman#FF5F5F/gender_unknown#F9C043（W9 drawable 实证） */
  private genderColorOf(xb: string): string {
    if (xb === '女') {
      return '#FF5F5F';
    }
    if (xb === '男') {
      return '#3A7BFF';
    }
    return '#F9C043';
  }

  build() {
    Column() {
      TitleBar({ title: this.title, showBack: true })

      if (this.isLoading) {
        LoadingView()
      } else if (this.showError) {
        // 源码 e() → MultiStateView ERROR（error_view 布局语义）
        Column() {
          EmptyView({ tipText: '加载失败，请检查网络后重试' })
        }
        .width('100%')
        .layoutWeight(1)
      } else if (this.groups.length === 0) {
        // 源码 b()：size==0 → MultiStateView EMPTY
        Column() {
          EmptyView({ tipText: '暂无数据' })
        }
        .width('100%')
        .layoutWeight(1)
      } else {
        Stack({ alignContent: Alignment.End }) {
          List({ scroller: this.scroller }) {
            ForEach(this.groups, (group: LetterGroup) => {
              // mobile_campus_contact_item_class_title.xml：索引组头 40dip #f2f2f2 11fp padH12
              ListItem() {
                Text(group.letter)
                  .fontSize(11)
                  .fontColor($r('app.color.common_color_1'))
                  .width('100%')
                  .height(40)
                  .padding({ left: 12, right: 12 })
                  .backgroundColor('#F2F2F2')
                  .textAlign(TextAlign.Start)
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
              }
              ForEach(group.students, (bean: ContactClassStudentBean) => {
                ListItem() {
                  this.studentRow(bean)
                }
              }, (bean: ContactClassStudentBean) => bean.XH + '_' + bean.XM)
            }, (group: LetterGroup) => group.letter)
          }
          .width('100%')
          .layoutWeight(1)
          .scrollBar(BarState.Off)
          .backgroundColor($r('app.color.white'))

          // IndexableLayout 右侧字母索引条：11fp ybg_blue 间隔 4dip
          Column() {
            ForEach(this.groups, (group: LetterGroup) => {
              Text(group.letter)
                .fontSize(11)
                .fontColor($r('app.color.ybg_blue'))
                .margin({ top: 2, bottom: 2 })
                .padding({ left: 6, right: 6 })
                .onClick(() => {
                  this.scrollToLetter(group.letter);
                })
            }, (group: LetterGroup) => group.letter)
          }
          .margin({ right: 2 })
        }
        .width('100%')
        .layoutWeight(1)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.white'))
  }

  // mobile_campus_contact_view_classaddressbook.xml：学生行 60dip padL12 + 1dip 分隔线
  @Builder
  studentRow(bean: ContactClassStudentBean) {
    Column() {
      Row() {
        // icon 36dip 首字 + XB 性别三色背景（源码 v()；XM 空 → 空文本仍显示圆）
        Text(bean.XM === '' ? '' : bean.XM.substring(0, 1))
          .fontSize(18.5)
          .fontColor($r('app.color.ybg_white'))
          .width(36)
          .height(36)
          .textAlign(TextAlign.Center)
          .backgroundColor(this.genderColorOf(bean.XB))
          .borderRadius(18)

        Column() {
          Text(bean.XM)
            .fontSize(17)
            .fontColor($r('app.color.common_color_1'))
            .maxLines(1)
          Text(contactClassPhoneOf(bean))
            .fontSize(14)
            .fontColor($r('app.color.mobile_campus_contact'))
            .margin({ top: 8 })
            .maxLines(1)
            .visibility(contactClassPhoneOf(bean) === '' ? Visibility.None : Visibility.Visible)
        }
        .alignItems(HorizontalAlign.Start)
        .margin({ left: 12 })
        .layoutWeight(1)

        Row() {
          // imgPhone(call)：唯一点击监听 → d 类电话链
          Image($r('app.media.mobile_campus_contact_call'))
            .width(22)
            .height(22)
            .visibility(contactClassPhoneOf(bean) === '' ? Visibility.None : Visibility.Visible)
            .onClick(() => {
              this.onRowPhoneTap(contactClassPhoneOf(bean));
            })
          // imgMsg(msn)：电话非空显示，源码无点击监听（j() 只挂 imgPhone）
          Image($r('app.media.mobile_campus_contact_msn'))
            .width(22)
            .height(22)
            .margin({ left: 15 })
            .visibility(contactClassPhoneOf(bean) === '' ? Visibility.None : Visibility.Visible)
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
        this.openDetail(bean);
      })

      // divider_horizontal_grey_thin
      Divider()
        .color($r('app.color.common_color_5'))
        .strokeWidth(0.5)
        .width('100%')
    }
    .width('100%')
    .backgroundColor($r('app.color.white'))
  }
}
