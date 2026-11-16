import { ApiService } from '../network/ApiService';
import { ContactItem } from '../model/ContactModel';
import { TitleBar } from '../components/TitleBar';
import { EmptyView } from '../components/EmptyView';
import { LoadingView } from '../components/LoadingView';

interface ContactGroup {
  department: string;
  members: ContactItem[];
}

interface CommonPhoneEntry {
  id: string;
  name: string;
  phone: string;
}

/**
 * 通讯录页 — 1:1 复刻（单位换算 px_to_dip_N = N/2 vp, px_to_sp_N = N/2 fp）：
 * mobile_campus_contact_sub_fragment_contact.xml：搜索栏(px_to_dip_88=44vp 白底 padV px_to_dip_10=5vp) + ExpandableListView
 * mobile_campus_contact_view_department_group.xml：分组头 48vp 高 padL12 17fp #333 + arrow_right + 0.5vp 分隔线
 * mobile_campus_contact_view_department_child.xml：padT px_to_dip_15=7.5vp 头像36vp 名17fp 职14fp#999(ml px_to_dip_22=11) 电话14fp 蓝(ml px_to_dip_10=5) 通话/短信图标 mr 23 分隔线0.5
 * mobile_campus_contact_item_commonphonelist.xml：行高 px_to_dip_128=64vp padH px_to_dip_30=15vp 图标45vp 名17fp 号14fp#999 打电话按钮13fp(边框#999 圆角2) 底分隔线 px_to_dip_2=1vp
 */
@Entry
@Component
struct ContactPage {
  @State allGroups: ContactGroup[] = [];
  @State shownGroups: ContactGroup[] = [];
  @State commonPhones: CommonPhoneEntry[] = [];
  @State keyword: string = '';
  @State isLoading: boolean = true;
  @State expandedDept: string = '';
  private avatarColors: string[] = ['#1B68B7', '#18B4ED', '#52C41A', '#FAAD14', '#97000C'];

  aboutToAppear(): void {
    const phones: CommonPhoneEntry[] = [
      { id: 'CP1', name: '学校办公室', phone: '0531-89636001' },
      { id: 'CP2', name: '教务处', phone: '0531-89636002' },
      { id: 'CP3', name: '学生工作处', phone: '0531-89636003' },
      { id: 'CP4', name: '保卫处', phone: '0531-89636110' },
      { id: 'CP5', name: '图书馆', phone: '0531-89636004' },
      { id: 'CP6', name: '校医院', phone: '0531-89636120' }
    ];
    this.commonPhones = phones;
    ApiService.getContactList()
      .then((response) => {
        this.allGroups = ContactPage.buildGroups(response.data);
        this.shownGroups = this.allGroups;
        if (this.shownGroups.length > 0) {
          this.expandedDept = this.shownGroups[0].department;
        }
        this.isLoading = false;
      })
      .catch(() => {
        this.allGroups = [];
        this.shownGroups = [];
        this.isLoading = false;
      });
  }

  private static buildGroups(contacts: ContactItem[]): ContactGroup[] {
    const groups: ContactGroup[] = [];
    for (const contact of contacts) {
      let matched: boolean = false;
      for (const group of groups) {
        if (group.department === contact.department) {
          group.members.push(contact);
          matched = true;
          break;
        }
      }
      if (!matched) {
        const members: ContactItem[] = [contact];
        groups.push({ department: contact.department, members: members });
      }
    }
    return groups;
  }

  private applyFilter(word: string): void {
    if (word === '') {
      this.shownGroups = this.allGroups;
      return;
    }
    const groups: ContactGroup[] = [];
    for (const group of this.allGroups) {
      const members: ContactItem[] = [];
      for (const member of group.members) {
        if (member.name.indexOf(word) >= 0 || member.department.indexOf(word) >= 0 ||
          member.phone.indexOf(word) >= 0) {
          members.push(member);
        }
      }
      if (members.length > 0) {
        groups.push({ department: group.department, members: members });
      }
    }
    this.shownGroups = groups;
  }

  private firstChar(text: string): string {
    if (text === null || text === undefined || text === '') {
      return ' ';
    }
    return text.substring(0, 1);
  }

  private colorOf(seed: string): string {
    let total: number = 0;
    for (const ch of seed) {
      total += ch.charCodeAt(0);
    }
    const index: number = total % this.avatarColors.length;
    return this.avatarColors[index];
  }

  private toggleDept(dept: string): void {
    if (this.expandedDept === dept) {
      this.expandedDept = '';
    } else {
      this.expandedDept = dept;
    }
  }

  private dialPhone(phone: string): void {
    this.getUIContext().getPromptAction().showToast({ message: '呼叫: ' + phone });
  }

  build() {
    Column() {
      TitleBar({ title: '通讯录', showBack: true })

      // navigation_bar_search_container: 白底 高px_to_dip_88=44vp padV px_to_dip_10=5vp
      Column() {
        // mobile_campus_shape_base_sesarch_bg: #F2F2F2 圆角8 边1px #DADBDF 高28dip marginH px_to_dip_24=12vp
        Row() {
          Image($r('app.media.mobile_campus_contact_search_g'))
            .width(16)
            .height(16)
            .margin({ left: 9, right: 9 })
          TextInput({ placeholder: '输入姓名、电话号码搜索', text: this.keyword })
            .fontSize(14)
            .placeholderColor($r('app.color.mobile_campus_contact_search_hint'))
            .placeholderFont({ size: 14 })
            .fontColor($r('app.color.common_color_1'))
            .backgroundColor(Color.Transparent)
            .padding({ left: 0, right: 8 })
            .height(28)
            .layoutWeight(1)
            .onChange((value: string) => {
              this.keyword = value;
              this.applyFilter(value);
            })
        }
        .width('100%')
        .height(28)
        .margin({ left: 12, right: 12 })
        .padding({ left: 0, right: 0 })
        .borderRadius(8)
        .backgroundColor($r('app.color.common_color_6'))
        .border({ width: 0.5, color: $r('app.color.mobile_campus_contact_search_border') })
        .alignItems(VerticalAlign.Center)
      }
      .width('100%')
      .height(44)
      .padding({ top: 5, bottom: 5 })
      .backgroundColor($r('app.color.white'))

      if (this.isLoading) {
        LoadingView()
      } else {
        if (this.shownGroups.length === 0 && this.commonPhones.length === 0) {
          EmptyView({ tipText: '未找到联系人' })
        } else {
          List() {
            // 常用电话分组头（department_group 结构）
            ListItem() {
              Column() {
                Row() {
                  Text('常用电话')
                    .fontSize(17)
                    .fontColor($r('app.color.common_color_1'))
                    .layoutWeight(1)
                    .maxLines(1)
                  Image($r('app.media.arrow_right'))
                    .width(16)
                    .height(16)
                    .margin({ right: 12 })
                }
                .width('100%')
                .height(48)
                .padding({ left: 12 })
                .alignItems(VerticalAlign.Center)
                .backgroundColor($r('app.color.white'))
                Divider()
                  .color($r('app.color.common_color_5'))
                  .strokeWidth(0.5)
                  .width('100%')
              }
              .onClick(() => {
                this.toggleDept('常用电话');
              })
            }

            if (this.expandedDept === '常用电话') {
              ForEach(this.commonPhones, (phoneEntry: CommonPhoneEntry) => {
                ListItem() {
                  this.commonPhoneRow(phoneEntry)
                }
              }, (phoneEntry: CommonPhoneEntry) => phoneEntry.id)
            }

            ForEach(this.shownGroups, (group: ContactGroup) => {
              ListItem() {
                this.deptGroupHeader(group.department)
              }
              .onClick(() => {
                this.toggleDept(group.department);
              })

              if (this.expandedDept === group.department) {
                ForEach(group.members, (member: ContactItem) => {
                  ListItem() {
                    this.deptChildRow(member)
                  }
                }, (member: ContactItem) => member.id)
              }
            }, (group: ContactGroup) => group.department)
          }
          .width('100%')
          .layoutWeight(1)
          .backgroundColor($r('app.color.mobile_campus_bg_color'))
          .scrollBar(BarState.Off)
        }
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.mobile_campus_bg_color'))
  }

  // mobile_campus_contact_view_department_group.xml
  @Builder
  deptGroupHeader(dept: string) {
    Column() {
      Row() {
        Text(dept)
          .fontSize(17)
          .fontColor($r('app.color.common_color_1'))
          .layoutWeight(1)
          .maxLines(1)
        Image($r('app.media.arrow_right'))
          .width(16)
          .height(16)
          .margin({ right: 12 })
      }
      .width('100%')
      .height(48)
      .padding({ left: 12 })
      .alignItems(VerticalAlign.Center)
      .backgroundColor($r('app.color.white'))

      Divider()
        .color($r('app.color.common_color_5'))
        .strokeWidth(0.5)
        .width('100%')
    }
    .width('100%')
    .backgroundColor($r('app.color.white'))
  }

  // mobile_campus_contact_view_department_child.xml
  @Builder
  deptChildRow(member: ContactItem) {
    Column() {
      Row() {
        // imgLayout: icon 36dip 文字 18.5fp 白字
        Text(this.firstChar(member.name))
          .fontSize(18.5)
          .fontColor($r('app.color.white'))
          .width(36)
          .height(36)
          .textAlign(TextAlign.Center)
          .backgroundColor(this.colorOf(member.id))
          .borderRadius(18)

        Column() {
          Row() {
            Text(member.name)
              .fontSize(17)
              .fontColor($r('app.color.common_color_1'))
              .maxLines(1)
            Text(member.position)
              .fontSize(14)
              .fontColor($r('app.color.common_color_3'))
              .margin({ left: 11 })
              .maxLines(1)
          }
          .alignItems(VerticalAlign.Bottom)

          Text(member.phone)
            .fontSize(14)
            .fontColor($r('app.color.mobile_campus_contact_phone_text'))
            .margin({ top: 5 })
            .maxLines(1)
        }
        .alignItems(HorizontalAlign.Start)
        .margin({ left: 12 })
        .layoutWeight(1)

        // layout: imgPhone + imgMsg(marginLeft 15dip) marginRight 23dip
        Row() {
          Image($r('app.media.mobile_campus_contact_call'))
            .width(18)
            .height(18)
            .onClick(() => {
              this.dialPhone(member.phone);
            })
          Image($r('app.media.mobile_campus_contact_msn'))
            .width(18)
            .height(18)
            .margin({ left: 15 })
        }
        .margin({ right: 23 })
        .alignItems(VerticalAlign.Center)
      }
      .width('100%')
      .padding({ left: 12, right: 12 })
      .alignItems(VerticalAlign.Center)

      // include divider_horizontal_grey_thin: 0.5dip #E7E7E7, marginTop px_to_dip_15=7.5vp
      Divider()
        .color($r('app.color.common_color_5'))
        .strokeWidth(0.5)
        .width('100%')
        .margin({ top: 7.5 })
    }
    .width('100%')
    .padding({ top: 7.5 })
    .backgroundColor($r('app.color.white'))
  }

  // mobile_campus_contact_item_commonphonelist.xml
  @Builder
  commonPhoneRow(phoneEntry: CommonPhoneEntry) {
    Column() {
      Row() {
        // icon: 90px→45vp 白字 20fp(px_to_sp_40)
        Text(this.firstChar(phoneEntry.name))
          .fontSize(20)
          .fontColor($r('app.color.white'))
          .width(45)
          .height(45)
          .textAlign(TextAlign.Center)
          .backgroundColor(this.colorOf(phoneEntry.id))
          .borderRadius(22)

        Column() {
          Text(phoneEntry.name)
            .fontSize(17)
            .fontColor($r('app.color.common_color_1'))
            .maxLines(1)
          Text(phoneEntry.phone)
            .fontSize(14)
            .fontColor($r('app.color.common_color_3'))
            .maxLines(1)
        }
        .alignItems(HorizontalAlign.Start)
        .margin({ left: 12, right: 12 })
        .layoutWeight(1)

        // phone_call_text: round_shape_full_round4dp_corner(边框#999 圆角2) 13fp #333 padH px_to_dip_16=8 padV px_to_dip_10=5
        Text('打电话')
          .fontSize(13)
          .fontColor($r('app.color.common_color_1'))
          .padding({ left: 8, right: 8, top: 5, bottom: 5 })
          .borderRadius(2)
          .border({ width: 1, color: $r('app.color.common_color_3') })
          .onClick(() => {
            this.dialPhone(phoneEntry.phone);
          })
      }
      .width('100%')
      .height(64)
      .padding({ left: 15, right: 15 })
      .alignItems(VerticalAlign.Center)
      .backgroundColor($r('app.color.main_bg'))

      // View common_color_5 高 px_to_dip_2=1vp
      Divider()
        .color($r('app.color.common_color_5'))
        .strokeWidth(1)
        .width('100%')
    }
    .width('100%')
    .backgroundColor($r('app.color.white'))
  }
}
