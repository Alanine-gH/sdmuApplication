import { TitleBar } from '../components/TitleBar';

interface CarbonDepartment {
  id: string;
  name: string;
  count: string;
}

/**
 * 抄送列表页 — 1:1 复刻 mobile_campus_oa_activity_carbon_copy.xml：
 * toolbar + bg#F2F2F2
 * RadioGroup 白底 pad8：按组织架构选择(默认选中)/按角色选择/人员分组
 * 白行高48 mt12：复选框20 + "组织架构" 17fp
 * 部门列表 mt12（复选行结构）
 * 底部 layoutBottom 高49：已选择：N人(16fp primary) 确定按钮(17fp 白字 primary 宽80)
 */
@Entry
@Component
struct CarbonCopyListPage {
  @State modeIndex: number = 0;
  @State modes: string[] = ['按组织架构选择', '按角色选择', '人员分组'];
  @State orgChecked: boolean = true;
  @State departments: CarbonDepartment[] = [];
  @State checkedIds: string[] = [];

  aboutToAppear(): void {
    this.departments = [
      { id: 'cd1', name: '学校办公室', count: '25人' },
      { id: 'cd2', name: '教务处', count: '38人' },
      { id: 'cd3', name: '学生工作处', count: '42人' },
      { id: 'cd4', name: '人事处', count: '16人' },
      { id: 'cd5', name: '保卫处', count: '21人' },
      { id: 'cd6', name: '应用英语学院', count: '86人' }
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
      TitleBar({ title: '抄送列表', showBack: true })

      // RadioGroup 白底 pad8
      Row() {
        ForEach(this.modes, (mode: string, index: number) => {
          Row() {
            Circle()
              .width(16)
              .height(16)
              .fill(this.modeIndex === index ? $r('app.color.mobile_campus_primary_color_default') : Color.Transparent)
              .stroke(this.modeIndex === index ? $r('app.color.mobile_campus_primary_color_default') : $r('app.color.common_color_3'))
              .strokeWidth(1)
            Text(mode)
              .fontSize(14)
              .fontColor($r('app.color.common_color_1'))
              .margin({ left: 4 })
          }
          .alignItems(VerticalAlign.Center)
          .margin({ right: 8 })
          .onClick(() => {
            this.modeIndex = index;
          })
        }, (mode: string) => mode)
      }
      .width('100%')
      .padding(8)
      .backgroundColor($r('app.color.white'))

      // 组织架构行 高48 mt12
      Row() {
        this.checkBox(this.orgChecked)

        Text('组织架构')
          .fontSize(17)
          .fontColor($r('app.color.common_color_1'))
          .margin({ left: 12 })
      }
      .width('100%')
      .height(48)
      .padding({ left: 12, right: 12 })
      .margin({ top: 12 })
      .alignItems(VerticalAlign.Center)
      .backgroundColor($r('app.color.white'))
      .onClick(() => {
        this.orgChecked = !this.orgChecked;
      })

      // 部门列表 mt12
      List() {
        ForEach(this.departments, (dept: CarbonDepartment) => {
          ListItem() {
            this.departmentRow(dept)
          }
          .onClick(() => {
            this.toggleCheck(dept.id);
          })
        }, (dept: CarbonDepartment) => dept.id)
      }
      .width('100%')
      .layoutWeight(1)
      .margin({ top: 12 })
      .scrollBar(BarState.Off)
      .backgroundColor($r('app.color.white'))
      .divider({ strokeWidth: 0.5, color: $r('app.color.common_color_5'), startMargin: 12 })

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
    .backgroundColor($r('app.color.mobile_campus_bg_color'))
  }

  @Builder
  departmentRow(dept: CarbonDepartment) {
    Row() {
      this.checkBox(this.isChecked(dept.id))

      Text(dept.name)
        .fontSize(17)
        .fontColor($r('app.color.common_color_1'))
        .margin({ left: 12 })
        .maxLines(1)
        .layoutWeight(1)

      Text(dept.count)
        .fontSize(14)
        .fontColor($r('app.color.common_color_3'))
    }
    .width('100%')
    .height(48)
    .padding({ left: 12, right: 12 })
    .alignItems(VerticalAlign.Center)
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
