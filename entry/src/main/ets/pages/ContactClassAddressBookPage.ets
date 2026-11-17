import { TitleBar } from '../components/TitleBar';

interface ClassStudent {
  id: string;
  name: string;
  sub: string;
}

interface ClassGroup {
  id: string;
  title: string;
  className: string;
  students: ClassStudent[];
}

/**
 * 班级通讯录页 — 1:1 复刻：
 * mobile_campus_activity_contact_class_address_book.xml：toolbar + IndexableLayout(白底 索引条 ybg_blue 11fp)
 * mobile_campus_contact_item_class_title.xml：索引标题 11fp(px_to_sp_22) common_color_1 高40 bg#F2F2F2 padH12
 * mobile_campus_contact_item_class_content.xml：班级行高56(px_to_dip_112) logo38(px_to_dip_76) ml16 名17fp + 底部分隔线
 * mobile_campus_contact_view_classaddressbook.xml：学生行高60 图标36 名17fp 副14fp mt8 呼叫/短信 mr23 + 分隔线
 */
@Entry
@Component
struct ContactClassAddressBookPage {
  @State groups: ClassGroup[] = [];
  @State expandedId: string = '';
  private avatarColors: string[] = ['#1B68B7', '#18B4ED', '#52C41A', '#FAAD14', '#97000C'];

  aboutToAppear(): void {
    const g1: ClassGroup = {
      id: 'g1', title: '2024级', className: '应用英语1班',
      students: [
        { id: 'g1-s1', name: '李明', sub: '{{PHONE_npjptud6}}' },
        { id: 'g1-s2', name: '赵雪', sub: '{{PHONE_kh2d4d7q}}' },
        { id: 'g1-s3', name: '王浩', sub: '{{PHONE_ybzaqixn}}' }
      ]
    };
    const g2: ClassGroup = {
      id: 'g2', title: '2024级', className: '应用英语2班',
      students: [
        { id: 'g2-s1', name: '刘洋', sub: '{{PHONE_iihdwwpi}}' },
        { id: 'g2-s2', name: '陈晨', sub: '{{PHONE_pvjj4fdw}}' }
      ]
    };
    const g3: ClassGroup = {
      id: 'g3', title: '2023级', className: '国际商务1班',
      students: [
        { id: 'g3-s1', name: '孙丽', sub: '{{PHONE_6u5gxcnc}}' },
        { id: 'g3-s2', name: '周杰', sub: '{{PHONE_7fdhpbuh}}' },
        { id: 'g3-s3', name: '吴敏', sub: '{{PHONE_r7zyvbqp}}' }
      ]
    };
    this.groups = [g1, g2, g3];
  }

  private toggle(id: string): void {
    if (this.expandedId === id) {
      this.expandedId = '';
    } else {
      this.expandedId = id;
    }
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
      TitleBar({ title: '班级通讯录', showBack: true })

      List() {
        ForEach(this.groups, (group: ClassGroup) => {
          // mobile_campus_contact_item_class_title.xml：索引分组标题
          ListItem() {
            Text(group.title)
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

          // mobile_campus_contact_item_class_content.xml：班级行
          ListItem() {
            Stack({ alignContent: Alignment.BottomStart }) {
              Row() {
                Image($r('app.media.ly_logo'))
                  .width(38)
                  .height(38)
                  .margin({ left: 16 })
                Text(group.className)
                  .fontSize(17)
                  .fontColor($r('app.color.common_color_1'))
                  .margin({ left: 8, right: 16.5 })
                  .maxLines(1)
              }
              .width('100%')
              .height(56)
              .alignItems(VerticalAlign.Center)
              .backgroundColor($r('app.color.white'))

              Divider()
                .color($r('app.color.common_color_5'))
                .strokeWidth(0.5)
                .width('100%')
            }
            .width('100%')
          }
          .onClick(() => {
            this.toggle(group.id);
          })

          if (this.expandedId === group.id) {
            ForEach(group.students, (student: ClassStudent) => {
              ListItem() {
                this.studentRow(student)
              }
            }, (student: ClassStudent) => student.id)
          }
        }, (group: ClassGroup) => group.id)
      }
      .width('100%')
      .layoutWeight(1)
      .scrollBar(BarState.Off)
      .backgroundColor($r('app.color.white'))
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.white'))
  }

  // mobile_campus_contact_view_classaddressbook.xml：学生行
  @Builder
  studentRow(student: ClassStudent) {
    Column() {
      Row() {
        Text(student.name.substring(0, 1))
          .fontSize(18.5)
          .fontColor($r('app.color.ybg_white'))
          .width(36)
          .height(36)
          .textAlign(TextAlign.Center)
          .backgroundColor(this.colorOf(student.id))
          .borderRadius(18)

        Column() {
          Text(student.name)
            .fontSize(17)
            .fontColor($r('app.color.common_color_1'))
            .maxLines(1)
          Text(student.sub)
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
              this.toast('呼叫: ' + student.sub);
            })
          Image($r('app.media.mobile_campus_contact_msn'))
            .width(18)
            .height(18)
            .margin({ left: 15 })
        }
        .margin({ right: 23 })
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
