interface SearchPerson {
  id: string;
  name: string;
  career: string;
  sub: string;
}

interface SearchGroup {
  title: string;
  members: SearchPerson[];
}

/**
 * 通讯录搜索页 — 1:1 复刻：
 * mobile_campus_toolbar_base_search.xml：Toolbar 44vp 搜索框 32vp(#F2F2F2 圆角8) hint #B5B5B5 14fp 右侧"取消"
 * mobile_campus_contact_view_search_header.xml：历史搜索 13fp #696969 高32 padL12.5 白底 + 0.5分隔线
 * mobile_campus_contact_view_search_cache.xml：行高48 名16fp close图标(pad12) + 分隔线
 * mobile_campus_contact_view_search_footer.xml：清空搜索记录 13fp #696969 mt29.5 垃圾篓图标(间距8)
 * mobile_campus_contact_view_search_group.xml：分组标题 15fp #696969 高36 bg#F2F2F2 padH12
 * mobile_campus_contact_view_search_child.xml：行高60 图标36vp 名17fp 职14fp#999(ml11) 电话14fp(ml8) 呼叫/短信图标 mr23 分隔线
 */
@Entry
@Component
struct ContactSearchPage {
  @State keyword: string = '';
  @State histories: string[] = ['张伟', '教务处', '王芳', '学生工作处'];
  @State searching: boolean = false;
  @State groups: SearchGroup[] = [];
  private avatarColors: string[] = ['#1B68B7', '#18B4ED', '#52C41A', '#FAAD14', '#97000C'];

  private allPersons: SearchPerson[] = [
    { id: 'p1', name: '张伟', career: '教师', sub: '13700000001' },
    { id: 'p2', name: '王芳', career: '教师', sub: '13700000002' },
    { id: 'p3', name: '李娜', career: '辅导员', sub: '13700000003' },
    { id: 'p4', name: '刘强', career: '教师', sub: '13700000004' },
    { id: 'p5', name: '陈静', career: '教务处', sub: '13700000005' },
    { id: 'p6', name: '赵磊', career: '学生工作处', sub: '13700000006' }
  ];

  private applyFilter(word: string): void {
    this.keyword = word;
    if (word === '') {
      this.searching = false;
      this.groups = [];
      return;
    }
    this.searching = true;
    const groups: SearchGroup[] = [];
    for (const person of this.allPersons) {
      if (person.name.indexOf(word) >= 0 || person.career.indexOf(word) >= 0 || person.sub.indexOf(word) >= 0) {
        let matched: boolean = false;
        for (const group of groups) {
          if (group.title === person.career) {
            group.members.push(person);
            matched = true;
            break;
          }
        }
        if (!matched) {
          const members: SearchPerson[] = [person];
          groups.push({ title: person.career, members: members });
        }
      }
    }
    this.groups = groups;
  }

  private removeHistory(item: string): void {
    const rest: string[] = [];
    for (const h of this.histories) {
      if (h !== item) {
        rest.push(h);
      }
    }
    this.histories = rest;
  }

  private clearHistory(): void {
    this.histories = [];
    this.getUIContext().getPromptAction().showToast({ message: '已清空搜索记录' });
  }

  private firstChar(text: string): string {
    if (text === '') {
      return ' ';
    }
    return text.substring(0, 1);
  }

  private colorOf(seed: string): string {
    let total: number = 0;
    for (const ch of seed) {
      total += ch.charCodeAt(0);
    }
    return this.avatarColors[total % this.avatarColors.length];
  }

  private toast(msg: string): void {
    this.getUIContext().getPromptAction().showToast({ message: msg });
  }

  build() {
    Column() {
      // mobile_campus_toolbar_base_search.xml
      Column() {
        Row() {
          Row() {
            Image($r('app.media.search_b'))
              .width(16)
              .height(16)
              .margin({ left: 8, right: 9 })
            TextInput({ placeholder: '输入姓名、电话号码搜索', text: this.keyword })
              .fontSize(14)
              .fontColor($r('app.color.common_color_1'))
              .placeholderColor('#B5B5B5')
              .placeholderFont({ size: 14 })
              .backgroundColor(Color.Transparent)
              .padding({ left: 0, right: 8 })
              .height('100%')
              .layoutWeight(1)
              .onChange((value: string) => {
                this.applyFilter(value);
              })
              .onSubmit(() => {
                this.toast('搜索: ' + this.keyword);
              })
          }
          .width('100%')
          .height(32)
          .margin({ right: 4 })
          .borderRadius(8)
          .backgroundColor($r('app.color.common_color_6'))
          .alignItems(VerticalAlign.Center)

          Text('取消')
            .fontSize(14)
            .fontColor($r('app.color.common_color_1'))
            .margin({ left: 8 })
            .height(44)
            .textAlign(TextAlign.Center)
        }
        .width('100%')
        .height(44)
        .padding({ right: 12 })
        .alignItems(VerticalAlign.Center)
        .backgroundColor($r('app.color.main_bg'))

        Divider()
          .color($r('app.color.common_color_5'))
          .strokeWidth(0.5)
          .width('100%')
      }
      .width('100%')

      if (this.searching) {
        List() {
          ForEach(this.groups, (group: SearchGroup) => {
            // mobile_campus_contact_view_search_group.xml
            ListItem() {
              Text(group.title)
                .fontSize(15)
                .fontColor('#696969')
                .width('100%')
                .height(36)
                .padding({ left: 12, right: 12 })
                .backgroundColor('#F2F2F2')
                .textAlign(TextAlign.Start)
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
            }

            ForEach(group.members, (person: SearchPerson) => {
              ListItem() {
                this.searchChildRow(person)
              }
            }, (person: SearchPerson) => person.id)
          }, (group: SearchGroup) => group.title)
        }
        .width('100%')
        .layoutWeight(1)
        .scrollBar(BarState.Off)
        .backgroundColor($r('app.color.white'))
      } else {
        Column() {
          if (this.histories.length > 0) {
            // mobile_campus_contact_view_search_header.xml
            Column() {
              Text('历史搜索')
                .fontSize(13)
                .fontColor('#696969')
                .width('100%')
                .height(32)
                .padding({ left: 12.5 })
                .backgroundColor($r('app.color.white'))
                .textAlign(TextAlign.Start)
              Divider()
                .color($r('app.color.common_color_5'))
                .strokeWidth(0.5)
                .width('100%')
            }
            .width('100%')

            ForEach(this.histories, (item: string) => {
              Column() {
                Row() {
                  Text(item)
                    .fontSize(16)
                    .fontColor($r('app.color.common_color_1'))
                    .height(48)
                    .layoutWeight(1)
                    .textAlign(TextAlign.Start)
                  Image($r('app.media.mobile_campus_supervise_close_g'))
                    .width(14)
                    .height(14)
                    .padding(12)
                    .onClick(() => {
                      this.removeHistory(item);
                    })
                }
                .width('100%')
                .padding({ left: 12.5, right: 12 })
                .alignItems(VerticalAlign.Center)
                .backgroundColor($r('app.color.white'))

                Divider()
                  .color($r('app.color.common_color_5'))
                  .strokeWidth(0.5)
                  .width('100%')
              }
            }, (item: string) => item)

            // mobile_campus_contact_view_search_footer.xml
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
            .margin({ top: 29.5 })
            .onClick(() => {
              this.clearHistory();
            })
          }
        }
        .width('100%')
        .layoutWeight(1)
        .backgroundColor($r('app.color.mobile_campus_bg_color'))
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.mobile_campus_bg_color'))
  }

  // mobile_campus_contact_view_search_child.xml
  @Builder
  searchChildRow(person: SearchPerson) {
    Column() {
      Row() {
        Text(this.firstChar(person.name))
          .fontSize(18.5)
          .fontColor($r('app.color.ybg_white'))
          .width(36)
          .height(36)
          .textAlign(TextAlign.Center)
          .backgroundColor(this.colorOf(person.id))
          .borderRadius(18)

        Column() {
          Row() {
            Text(person.name)
              .fontSize(17)
              .fontColor($r('app.color.common_color_1'))
              .maxLines(1)
            Text(person.career)
              .fontSize(14)
              .fontColor('#999999')
              .margin({ left: 11 })
              .maxLines(1)
          }
          .alignItems(VerticalAlign.Center)

          Text(person.sub)
            .fontSize(14)
            .fontColor($r('app.color.mobile_campus_contact'))
            .margin({ top: 8 })
            .maxLines(1)
        }
        .alignItems(HorizontalAlign.Start)
        .margin({ left: 12 })
        .layoutWeight(1)

        Row() {
          Image($r('app.media.mobile_campus_contact_call'))
            .width(18)
            .height(18)
            .onClick(() => {
              this.toast('呼叫: ' + person.sub);
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
      .height(60)
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
}
