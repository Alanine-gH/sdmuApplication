import { TitleBar } from '../components/TitleBar';

interface DepartmentNode {
  id: string;
  name: string;
  hasChild: boolean;
}

/**
 * 部门列表页 — 1:1 复刻（oa/selector/DepartmentListActivity）：
 * toolbar + 部门选择列表（mobile_campus_oa_view_todo_department.xml 结构）：
 *   行高48(px_to_dip_96) 白底 padL12 padR12 复选框20(px_to_dip_40) 标题17fp
 *   可选"下级"入口(15fp #1B6BB7 图标 mobile_campus_oa_lowerlevel 间距4) + 分隔线
 * 底部确认栏(mobile_campus_oa_activity_todo_search_department.xml layoutBottom)：
 *   高49 白底 padL12 已选择：N人(16fp primary) 确定按钮(17fp 白字 primary bg 宽80)
 */
@Entry
@Component
struct DepartmentListPage {
  @State departments: DepartmentNode[] = [];
  @State checkedIds: string[] = [];

  aboutToAppear(): void {
    this.departments = [
      { id: 'dep1', name: '学校办公室', hasChild: true },
      { id: 'dep2', name: '教务处', hasChild: true },
      { id: 'dep3', name: '学生工作处', hasChild: true },
      { id: 'dep4', name: '人事处', hasChild: false },
      { id: 'dep5', name: '财务处', hasChild: false },
      { id: 'dep6', name: '保卫处', hasChild: false },
      { id: 'dep7', name: '图书馆', hasChild: false },
      { id: 'dep8', name: '应用英语学院', hasChild: true },
      { id: 'dep9', name: '国际商学院', hasChild: true }
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
    this.getUIContext().getPromptAction().showToast({ message: '已选择：' + this.checkedIds.length + '个部门' });
  }

  build() {
    Column() {
      TitleBar({ title: '部门选择', showBack: true })

      List() {
        ForEach(this.departments, (dept: DepartmentNode) => {
          ListItem() {
            this.departmentRow(dept)
          }
          .onClick(() => {
            this.toggleCheck(dept.id);
          })
        }, (dept: DepartmentNode) => dept.id)
      }
      .width('100%')
      .layoutWeight(1)
      .scrollBar(BarState.Off)
      .backgroundColor($r('app.color.white'))

      // layoutBottom：高49 白底 padL12
      Row() {
        Text('已选择：' + this.checkedIds.length + '个部门')
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

  // mobile_campus_oa_view_todo_department.xml：行高48 padH12
  @Builder
  departmentRow(dept: DepartmentNode) {
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

  // mobile_campus_oa_todo_cb：复选框20 圆形边框 选中填充
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
