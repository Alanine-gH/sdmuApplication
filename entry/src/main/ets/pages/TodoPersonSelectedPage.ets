import { BreakpointSystem } from '../common/BreakpointSystem';

interface SelectedPerson {
  id: string;
  name: string;
}

interface SelectedGroup {
  id: string;
  title: string;
  members: SelectedPerson[];
}

/**
 * 待办人员选择页 — 1:1 复刻 mobile_campus_oa_activity_todo_search_selected.xml：
 * mobile_campus_toolbar_base_search.xml：Toolbar 44 搜索框32(#F2F2F2 圆角8) hint #B5B5B5 14fp + "取消"
 * ExpandableListView：
 *   mobile_campus_oa_view_todo_search_group.xml：分组标题 15fp #696969 高36 bg#F2F2F2 padH12
 *   mobile_campus_oa_view_todo_search_child.xml：行高60 复选框20 图标36(ml12) 名17fp + 分隔线
 * layoutBottom 高49 白底 padL12：已选择：N人(16fp primary) 确定按钮(17fp 白字 primary 宽80)
 */
@Entry
@Component
struct TodoPersonSelectedPage {
  @State keyword: string = '';
  @State groups: SelectedGroup[] = [];
  @State checkedIds: string[] = [];
  @StorageProp('currentBreakpoint') currentBreakpoint: string = 'sm';
  @StorageProp('avoidAreaBottomVp') avoidAreaBottomVp: number = 0;
  @StorageProp('avoidAreaLeftVp') avoidAreaLeftVp: number = 0;
  @StorageProp('avoidAreaRightVp') avoidAreaRightVp: number = 0;
  @StorageProp('keyboardHeightVp') keyboardHeightVp: number = 0;
  private avatarColors: string[] = ['#1B68B7', '#18B4ED', '#52C41A', '#FAAD14', '#97000C'];

  aboutToAppear(): void {
    const g1: SelectedGroup = {
      id: 'sg1', title: '教务处',
      members: [
        { id: 'sg1-p1', name: '张伟' },
        { id: 'sg1-p2', name: '王芳' },
        { id: 'sg1-p3', name: '李娜' }
      ]
    };
    const g2: SelectedGroup = {
      id: 'sg2', title: '学生工作处',
      members: [
        { id: 'sg2-p1', name: '赵磊' },
        { id: 'sg2-p2', name: '陈静' }
      ]
    };
    const g3: SelectedGroup = {
      id: 'sg3', title: '人事处',
      members: [
        { id: 'sg3-p1', name: '刘强' },
        { id: 'sg3-p2', name: '孙丽' }
      ]
    };
    this.groups = [g1, g2, g3];
  }

  private isChecked(id: string): boolean {
    for (const item of this.checkedIds) {
      if (item === id) {
        return true;
      }
    }
    return false;
  }

  private toggleCheck(id: string): void {
    const rest: string[] = [];
    let found: boolean = false;
    for (const item of this.checkedIds) {
      if (item === id) {
        found = true;
      } else {
        rest.push(item);
      }
    }
    if (!found) {
      rest.push(id);
    }
    this.checkedIds = rest;
  }

  private colorOf(seed: string): string {
    let total: number = 0;
    for (const ch of seed) {
      total += ch.charCodeAt(0);
    }
    return this.avatarColors[total % this.avatarColors.length];
  }

  private submit(): void {
    this.getUIContext().getPromptAction().showToast({ message: '已选择：' + this.checkedIds.length + '人' });
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
                this.keyword = value;
              })
          }
            .layoutWeight(1)
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
        .padding({
          left: Math.max(8, this.avoidAreaLeftVp),
          right: Math.max(12, this.avoidAreaRightVp)
        })
        .constraintSize({ maxWidth: BreakpointSystem.getContentMaxWidth(this.currentBreakpoint) })
        .alignSelf(ItemAlign.Center)
        .alignItems(VerticalAlign.Center)

        Divider()
          .color($r('app.color.common_color_5'))
          .strokeWidth(0.5)
          .width('100%')
      }
      .width('100%')
      .backgroundColor($r('app.color.main_bg'))
      .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP])

      // ExpandableListView：分组 + 人员行
      List() {
        ForEach(this.groups, (group: SelectedGroup) => {
          // mobile_campus_oa_view_todo_search_group.xml
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
          }

          ForEach(group.members, (person: SelectedPerson) => {
            ListItem() {
              this.personRow(person)
            }
            .onClick(() => {
              this.toggleCheck(person.id);
            })
          }, (person: SelectedPerson) => person.id)
        }, (group: SelectedGroup) => group.id)
      }
      .width('100%')
      .constraintSize({ maxWidth: BreakpointSystem.getContentMaxWidth(this.currentBreakpoint) })
      .alignSelf(ItemAlign.Center)
      .padding({ left: this.avoidAreaLeftVp, right: this.avoidAreaRightVp })
      .contentEndOffset(this.keyboardHeightVp)
      .layoutWeight(1)
      .scrollBar(BarState.Off)
      .backgroundColor($r('app.color.white'))

      // layoutBottom 高49 白底 padL12
      Column() {
        Row() {
          Text('已选择：' + this.checkedIds.length + '人')
            .fontSize(16)
            .fontColor($r('app.color.mobile_campus_primary_color_default'))

          Blank()

          Text('确定')
            .fontSize(17)
            .fontColor($r('app.color.white'))
            .backgroundColor($r('app.color.mobile_campus_primary_color_default'))
            .width(80)
            .height('100%')
            .textAlign(TextAlign.Center)
            .onClick(() => {
              this.submit();
            })
        }
        .width('100%')
        .height(49)
        .padding({ left: 12 })
        .constraintSize({ maxWidth: BreakpointSystem.getContentMaxWidth(this.currentBreakpoint) })
        .alignSelf(ItemAlign.Center)
        .alignItems(VerticalAlign.Center)
      }
      .width('100%')
      .padding({
        left: this.avoidAreaLeftVp,
        right: this.avoidAreaRightVp,
        bottom: this.avoidAreaBottomVp
      })
      .backgroundColor($r('app.color.white'))
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.white'))
  }

  // mobile_campus_oa_view_todo_search_child.xml：行高60
  @Builder
  personRow(person: SelectedPerson) {
    Column() {
      Row() {
        this.checkBox(this.isChecked(person.id))

        Text(person.name.substring(0, 1))
          .fontSize(18.5)
          .fontColor($r('app.color.ybg_white'))
          .width(36)
          .height(36)
          .margin({ left: 12 })
          .textAlign(TextAlign.Center)
          .backgroundColor(this.colorOf(person.id))
          .borderRadius(18)

        Text(person.name)
          .fontSize(17)
          .fontColor($r('app.color.common_color_1'))
          .margin({ left: 12 })
          .maxLines(1)
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

  // mobile_campus_oa_todo_cb：复选框20
  @Builder
  checkBox(checked: boolean) {
    Stack() {
      Circle()
        .width(20)
        .height(20)
        .fill(Color.Transparent)
        .stroke(checked ? $r('app.color.mobile_campus_primary_color_default') : $r('app.color.common_color_3'))
        .strokeWidth(1)
      if (checked) {
        Text('✓')
          .fontSize(12)
          .fontColor($r('app.color.white'))
          .backgroundColor($r('app.color.mobile_campus_primary_color_default'))
          .width(20)
          .height(20)
          .textAlign(TextAlign.Center)
          .borderRadius(10)
      }
    }
    .width(20)
    .height(20)
  }
}
