import { router } from '@kit.ArkUI';
import { TitleBar } from '../components/TitleBar';

interface TodoDeptItem {
  deptId: number;
  name: string;
  hasChild: boolean;
  checked: boolean;
}

/**
 * OA部门待办页 — 1:1 复刻（px_to_dip_N = N/2 vp, px_to_sp_N = N/2 fp）：
 * mobile_campus_oa_activity_todo_department.xml：bg #F2F2F2 + toolbar_normal（TitleBar 复用）
 *   + 顶部白卡 48vp mT12 mB12（checkbox 20×20 + "组织架构" 17fp #333 mL12）
 *   + 部门列表（mobile_campus_oa_view_todo_department.xml：白底 48vp 行 checkbox 20×20 + 名称 17fp #333
 *     + "下级" 15fp #1B6BB7 带 lowerlevel 图标 drawablePadding 4）+ thin 分隔线
 *   + 底部栏 49vp 白底 padL12：已选择 16fp #1B68B7 + 确定 17fp 白字 bg #1B68B7 宽80
 */
@Entry
@Component
struct TodoDepartmentPage {
  @State deptList: TodoDeptItem[] = [
    { deptId: 1, name: '党委办公室', hasChild: true, checked: false },
    { deptId: 2, name: '院长办公室', hasChild: false, checked: false },
    { deptId: 3, name: '教务处', hasChild: true, checked: false },
    { deptId: 4, name: '学生工作处', hasChild: false, checked: false },
    { deptId: 5, name: '人事处', hasChild: false, checked: false },
    { deptId: 6, name: '财务处', hasChild: false, checked: false },
    { deptId: 7, name: '后勤管理处', hasChild: true, checked: false },
    { deptId: 8, name: '图书馆', hasChild: false, checked: false }
  ];
  @State totalCount: number = 0;

  private toggleCheck(deptId: number): void {
    const next: TodoDeptItem[] = [];
    let count: number = 0;
    for (const item of this.deptList) {
      const checked: boolean = item.deptId === deptId ? !item.checked : item.checked;
      if (checked) {
        count++;
      }
      next.push({ deptId: item.deptId, name: item.name, hasChild: item.hasChild, checked: checked });
    }
    this.deptList = next;
    this.totalCount = count;
  }

  build() {
    Column() {
      TitleBar({ title: '部门待办' })

      Column() {
        Column() {
          Row() {
            Image($r('app.media.mobile_campus_oa_chose'))
              .width(20)
              .height(20)
            Text('组织架构')
              .fontSize(17)
              .fontColor($r('app.color.common_color_1'))
              .margin({ left: 12 })
            Blank()
          }
          .width('100%')
          .height(48)
          .padding({ left: 12, right: 12 })
          .alignItems(VerticalAlign.Center)
          .backgroundColor($r('app.color.white'))
        }
        .width('100%')
        .margin({ top: 12, bottom: 12 })

        List() {
          ForEach(this.deptList, (item: TodoDeptItem) => {
            ListItem() {
              Column() {
                Row() {
                  Image(item.checked ? $r('app.media.mobile_campus_oa_choose') : $r('app.media.mobile_campus_oa_chose'))
                    .width(20)
                    .height(20)
                  Text(item.name)
                    .fontSize(17)
                    .fontColor($r('app.color.common_color_1'))
                    .maxLines(1)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                    .margin({ left: 12 })
                  Blank()
                  if (item.hasChild) {
                    Row() {
                      Image($r('app.media.mobile_campus_oa_lowerlevel'))
                        .width(14)
                        .height(14)
                      Text('下级')
                        .fontSize(15)
                        .fontColor('#1B6BB7')
                        .margin({ left: 4 })
                    }
                  }
                }
                .width('100%')
                .height(48)
                .padding({ left: 12, right: 12 })
                .alignItems(VerticalAlign.Center)
                .onClick(() => {
                  this.toggleCheck(item.deptId);
                })

                Divider()
                  .color($r('app.color.common_color_5'))
                  .strokeWidth(0.5)
                  .width('100%')
              }
              .backgroundColor($r('app.color.white'))
            }
          }, (item: TodoDeptItem) => item.deptId.toString() + '_' + item.checked.toString())
        }
        .width('100%')
        .layoutWeight(1)
        .scrollBar(BarState.Off)

        Row() {
          Text('已选择：' + this.totalCount.toString() + '人')
            .fontSize(16)
            .fontColor($r('app.color.mobile_campus_primary_color_default'))
          Blank()
          Text('确定')
            .fontSize(17)
            .fontColor($r('app.color.white'))
            .textAlign(TextAlign.Center)
            .width(80)
            .height('100%')
            .backgroundColor($r('app.color.mobile_campus_primary_color_default'))
            .onClick(() => {
              router.back();
            })
        }
        .width('100%')
        .height(49)
        .padding({ left: 12 })
        .alignItems(VerticalAlign.Center)
        .backgroundColor($r('app.color.white'))
      }
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F2F2F2')
  }
}
