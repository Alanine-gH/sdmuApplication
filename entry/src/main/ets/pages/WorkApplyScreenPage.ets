import { TitleBar } from '../components/TitleBar';

interface ScreenOption {
  id: string;
  label: string;
}

interface ScreenGroup {
  id: string;
  title: string;
  options: ScreenOption[];
}

/**
 * 审批大屏（筛选）页 — 1:1 复刻 mobile_campus_oa_activity_workapply_screen.xml：
 * toolbar + ExpandableListView(bg common_color_6)
 * mobile_campus_oa_activity_workapply_item_title.xml：
 *   顶线0.5 #DFE4EA 标题14fp common_color_1 padV15 ml12 右侧arrow_up mr12
 * mobile_campus_oa_activity_workapply_item_content.xml：
 *   内容区 m7.5 + 底部分隔线0.5 common_color_6
 */
@Entry
@Component
struct WorkApplyScreenPage {
  @State groups: ScreenGroup[] = [];
  @State checkedIds: string[] = [];
  @State expandedId: string = '';

  aboutToAppear(): void {
    const g1: ScreenGroup = {
      id: 'sc1', title: '申请类型',
      options: [
        { id: 'sc1-o1', label: '呈批件' },
        { id: 'sc1-o2', label: '发文' },
        { id: 'sc1-o3', label: '签报' },
        { id: 'sc1-o4', label: '请假申请' }
      ]
    };
    const g2: ScreenGroup = {
      id: 'sc2', title: '审批状态',
      options: [
        { id: 'sc2-o1', label: '审批中' },
        { id: 'sc2-o2', label: '已通过' },
        { id: 'sc2-o3', label: '已退回' }
      ]
    };
    const g3: ScreenGroup = {
      id: 'sc3', title: '紧急程度',
      options: [
        { id: 'sc3-o1', label: '普通' },
        { id: 'sc3-o2', label: '紧急' },
        { id: 'sc3-o3', label: '特提' }
      ]
    };
    this.groups = [g1, g2, g3];
    if (this.groups.length > 0) {
      this.expandedId = this.groups[0].id;
    }
  }

  private toggle(id: string): void {
    if (this.expandedId === id) {
      this.expandedId = '';
    } else {
      this.expandedId = id;
    }
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

  private toast(msg: string): void {
    this.getUIContext().getPromptAction().showToast({ message: msg });
  }

  build() {
    Column() {
      TitleBar({ title: '筛选', showBack: true })

      List() {
        ForEach(this.groups, (group: ScreenGroup) => {
          // mobile_campus_oa_activity_workapply_item_title.xml
          ListItem() {
            Stack({ alignContent: Alignment.Top }) {
              Row() {
                Text(group.title)
                  .fontSize(14)
                  .fontColor($r('app.color.common_color_1'))
                  .maxLines(1)
                Blank()
                Image($r('app.media.arrow_up'))
                  .width(14)
                  .height(14)
                  .margin({ right: 12 })
                  .rotate({ angle: this.expandedId === group.id ? 0 : 180 })
              }
              .width('100%')
              .padding({ top: 15, bottom: 15, left: 12 })
              .alignItems(VerticalAlign.Center)
              .backgroundColor($r('app.color.white'))

              Divider()
                .color($r('app.color.menu_divider'))
                .strokeWidth(0.5)
                .width('100%')
            }
            .width('100%')
          }
          .onClick(() => {
            this.toggle(group.id);
          })

          if (this.expandedId === group.id) {
            // mobile_campus_oa_activity_workapply_item_content.xml
            ListItem() {
              Column() {
                Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.Start }) {
                  ForEach(group.options, (option: ScreenOption) => {
                    Text(option.label)
                      .fontSize(14)
                      .fontColor(this.isChecked(option.id) ? $r('app.color.mobile_campus_primary_color_default') : $r('app.color.common_color_1'))
                      .padding({ left: 12, right: 12, top: 6, bottom: 6 })
                      .margin(4)
                      .borderRadius(2)
                      .border({ width: 1, color: this.isChecked(option.id) ? $r('app.color.mobile_campus_primary_color_default') : $r('app.color.common_color_3') })
                      .onClick(() => {
                        this.toggleCheck(option.id);
                      })
                  }, (option: ScreenOption) => option.id)
                }
                .width('100%')
                .padding({ left: 7.5, right: 7.5, top: 7.5, bottom: 7.5 })
                .backgroundColor($r('app.color.white'))

                Divider()
                  .color($r('app.color.common_color_6'))
                  .strokeWidth(0.5)
                  .width('100%')
              }
              .width('100%')
            }
          }
        }, (group: ScreenGroup) => group.id)
      }
      .width('100%')
      .layoutWeight(1)
      .scrollBar(BarState.Off)
      .backgroundColor($r('app.color.common_color_6'))

      // 筛选确认
      Row() {
        Text('重置')
          .fontSize(16)
          .fontColor($r('app.color.common_color_1'))
          .layoutWeight(1)
          .height('100%')
          .textAlign(TextAlign.Center)
          .backgroundColor($r('app.color.white'))
          .onClick(() => {
            this.checkedIds = [];
            this.toast('已重置筛选条件');
          })
        Text('确定')
          .fontSize(17)
          .fontColor($r('app.color.white'))
          .backgroundColor($r('app.color.mobile_campus_primary_color_default'))
          .layoutWeight(1)
          .height('100%')
          .textAlign(TextAlign.Center)
          .onClick(() => {
            this.toast('已筛选: ' + this.checkedIds.length + '项');
          })
      }
      .width('100%')
      .height(49)
      .alignItems(VerticalAlign.Center)
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.common_color_6'))
  }
}
