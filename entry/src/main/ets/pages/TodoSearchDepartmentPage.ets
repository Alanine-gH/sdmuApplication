interface SearchDepartment {
  id: string;
  name: string;
  hasChild: boolean;
}

/**
 * 待办部门搜索页 — 1:1 复刻 mobile_campus_oa_activity_todo_search_department.xml：
 * mobile_campus_toolbar_base_search.xml：Toolbar 44 搜索框32(#F2F2F2 圆角8) + "取消"
 * ListView：mobile_campus_oa_view_todo_search_department.xml
 *   行高48 白底 padL12 padR12 复选框20 标题17fp ml12 可选"下级"(15fp #1B6BB7 图标间距4) + 分隔线
 * layoutBottom 高49：已选择：N人(16fp primary) 确定按钮(17fp 白字 primary 宽80)
 */
@Entry
@Component
struct TodoSearchDepartmentPage {
  @State keyword: string = '';
  @State departments: SearchDepartment[] = [];
  @State checkedIds: string[] = [];

  aboutToAppear(): void {
    this.departments = [
      { id: 'sd1', name: '学校办公室', hasChild: true },
      { id: 'sd2', name: '教务处', hasChild: true },
      { id: 'sd3', name: '学生工作处', hasChild: true },
      { id: 'sd4', name: '人事处', hasChild: false },
      { id: 'sd5', name: '财务处', hasChild: false },
      { id: 'sd6', name: '保卫处', hasChild: false },
      { id: 'sd7', name: '图书馆', hasChild: false },
      { id: 'sd8', name: '应用英语学院', hasChild: true },
      { id: 'sd9', name: '国际商学院', hasChild: true },
      { id: 'sd10', name: '信息工程学院', hasChild: true }
    ];
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

      // ListView
      List() {
        ForEach(this.departments, (dept: SearchDepartment) => {
          ListItem() {
            this.departmentRow(dept)
          }
          .onClick(() => {
            this.toggleCheck(dept.id);
          })
        }, (dept: SearchDepartment) => dept.id)
      }
      .width('100%')
      .layoutWeight(1)
      .scrollBar(BarState.Off)
      .backgroundColor($r('app.color.white'))

      // layoutBottom 高49 白底 padL12
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
      .alignItems(VerticalAlign.Center)
      .backgroundColor($r('app.color.white'))
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.white'))
  }

  // mobile_campus_oa_view_todo_search_department.xml：行高48 padH12
  @Builder
  departmentRow(dept: SearchDepartment) {
    Column() {
      Row() {
        this.checkBox(this.isChecked(dept.id))

        Text(dept.name)
          .fontSize(17)
          .fontColor($r('app.color.common_color_1'))
          .margin({ left: 12 })
          .maxLines(1)

        Blank()

        if (dept.hasChild) {
          Row() {
            Image($r('app.media.mobile_campus_oa_lowerlevel'))
              .width(14)
              .height(14)
              .margin({ right: 4 })
            Text('下级')
              .fontSize(15)
              .fontColor($r('app.color.mobile_campus_oa_next_level'))
          }
          .alignItems(VerticalAlign.Center)
          .onClick(() => {
            this.getUIContext().getPromptAction().showToast({ message: dept.name + '下级部门' });
          })
        }
      }
      .width('100%')
      .height(48)
      .padding({ left: 12, right: 12 })
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
