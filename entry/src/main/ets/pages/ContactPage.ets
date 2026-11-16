import { ApiService } from '../network/ApiService';
import { ContactItem } from '../model/ContactModel';
import { TitleBar } from '../components/TitleBar';
import { EmptyView } from '../components/EmptyView';
import { LoadingView } from '../components/LoadingView';

interface ContactGroup {
  department: string;
  members: ContactItem[];
}

/**
 * 通讯录页：搜索 + 按部门分组。
 */
@Entry
@Component
struct ContactPage {
  @State allGroups: ContactGroup[] = [];
  @State shownGroups: ContactGroup[] = [];
  @State keyword: string = '';
  @State isLoading: boolean = true;

  aboutToAppear(): void {
    ApiService.getContactList()
      .then((response) => {
        const groups: ContactGroup[] = [];
        for (const contact of response.data) {
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
        this.allGroups = groups;
        this.shownGroups = groups;
        this.isLoading = false;
      })
      .catch(() => {
        this.allGroups = [];
        this.shownGroups = [];
        this.isLoading = false;
      });
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
        if (member.name.indexOf(word) >= 0 || member.department.indexOf(word) >= 0) {
          members.push(member);
        }
      }
      if (members.length > 0) {
        groups.push({ department: group.department, members: members });
      }
    }
    this.shownGroups = groups;
  }

  build() {
    Column() {
      TitleBar({ title: '通讯录', showBack: true })
      TextInput({ placeholder: '搜索姓名或部门', text: this.keyword })
        .height(38)
        .fontSize(14)
        .placeholderColor($r('app.color.sdmu_text_hint'))
        .backgroundColor($r('app.color.sdmu_card_bg'))
        .borderRadius(19)
        .margin({ left: 12, right: 12, top: 10 })
        .padding({ left: 16, right: 16 })
        .onChange((value: string) => {
          this.keyword = value;
          this.applyFilter(value);
        })
      if (this.isLoading) {
        LoadingView()
      } else {
        if (this.shownGroups.length === 0) {
          EmptyView({ tipText: '未找到联系人' })
        } else {
          List() {
            ForEach(this.shownGroups, (group: ContactGroup) => {
              ListItemGroup({ header: this.groupHeader(group.department) }) {
                ForEach(group.members, (member: ContactItem) => {
                  ListItem() {
                    Row() {
                      Column({ space: 4 }) {
                        Text(member.name)
                          .fontSize(15)
                          .fontColor($r('app.color.sdmu_text_primary'))
                        Text(member.position + ' · ' + member.phone)
                          .fontSize(12)
                          .fontColor($r('app.color.sdmu_text_hint'))
                      }
                      .alignItems(HorizontalAlign.Start)
                      .layoutWeight(1)
                      Text('＞')
                        .fontSize(14)
                        .fontColor($r('app.color.sdmu_text_hint'))
                    }
                    .width('100%')
                    .padding({ left: 16, right: 16, top: 12, bottom: 12 })
                    .onClick(() => {
                      this.getUIContext().getPromptAction().showToast({ message: member.name + ': ' + member.phone });
                    })
                  }
                }, (member: ContactItem) => member.id)
              }
            }, (group: ContactGroup) => group.department)
          }
          .width('100%')
          .layoutWeight(1)
          .backgroundColor($r('app.color.sdmu_card_bg'))
          .margin({ top: 10 })
          .borderRadius({ topLeft: 12, topRight: 12 })
          .scrollBar(BarState.Off)
        }
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.sdmu_bg'))
  }

  @Builder
  groupHeader(name: string) {
    Text(name)
      .fontSize(12)
      .fontColor($r('app.color.sdmu_text_hint'))
      .width('100%')
      .padding({ left: 16, top: 10, bottom: 6 })
      .backgroundColor($r('app.color.sdmu_bg'))
  }
}
