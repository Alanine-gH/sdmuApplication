import { TitleBar } from '../components/TitleBar';

/**
 * 待办主管页 — 1:1 复刻 mobile_campus_oa_activity_todo_main.xml（TodoMainActivity key=which主管模式）
 * 结构：
 *   - toolbar_normal「待办事项」
 *   - 11.5dip #F2F2F2隔条(px_to_dip_23/2)
 *   - SlidingTabLayout 48dip(px96/2)：指示器#1B68B7(primary_default)高2dip与标题等宽、
 *     tab padding 20dip等宽、选中#1B68B7/未选#999999
 *   - ViewPager：待我审批/我发起的/抄送我的 三段列表
 */
class TodoSuperviseItem {
  title: string;
  from: string;
  time: string;
  status: string;

  constructor(title: string, from: string, time: string, status: string) {
    this.title = title;
    this.from = from;
    this.time = time;
    this.status = status;
  }
}

@Entry
@Component
struct TodoSupervisePage {
  @State segIndex: number = 0;
  private tabTitles: string[] = ['待我审批', '我发起的', '抄送我的'];
  @State items: TodoSuperviseItem[][] = [
    [
      new TodoSuperviseItem('关于2026年度经费预算的审批', '财务处', '2026-11-16 14:20', '待审批'),
      new TodoSuperviseItem('实验室设备采购申请', '教务处', '2026-11-15 09:10', '待审批'),
      new TodoSuperviseItem('学生活动场地借用申请', '校团委', '2026-11-14 16:45', '待审批')
    ],
    [
      new TodoSuperviseItem('教师出差报销单', '我', '2026-11-10 11:30', '审批中'),
      new TodoSuperviseItem('办公用品采购申请', '我', '2026-11-08 10:00', '已通过')
    ],
    [
      new TodoSuperviseItem('期中教学检查通报', '教学质量办', '2026-11-12 15:00', '已读'),
      new TodoSuperviseItem('教研室工作计划', '信息工程学院', '2026-11-05 09:00', '已读')
    ]
  ];

  @Builder
  todoRow(item: TodoSuperviseItem) {
    Column() {
      Row() {
        Text(item.title)
          .fontSize(16)
          .fontColor($r('app.color.common_color_1'))
          .layoutWeight(1)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        Text(item.status)
          .fontSize(13)
          .fontColor(item.status === '待审批' ? $r('app.color.mobile_campus_primary_color_default') :
            item.status === '审批中' ? $r('app.color.ybg_blue') : $r('app.color.common_color_3'))
      }
      .width('100%')

      Row() {
        Text(item.from)
          .fontSize(13)
          .fontColor($r('app.color.common_color_3'))
        Text(item.time)
          .fontSize(12)
          .fontColor($r('app.color.common_color_3'))
          .layoutWeight(1)
          .textAlign(TextAlign.End)
      }
      .width('100%')
      .margin({ top: 6 })
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
    .padding({ left: 15, right: 15, top: 12, bottom: 12 })
    .backgroundColor($r('app.color.white'))
  }

  build() {
    Column() {
      TitleBar({ title: '待办事项', showBack: true })

      // 11.5dip #F2F2F2 隔条
      Row()
        .width('100%')
        .height(12)
        .backgroundColor($r('app.color.common_color_6'))

      // SlidingTabLayout 48dip
      Row() {
        ForEach(this.tabTitles, (t: string, i: number) => {
          Column() {
            Text(t)
              .fontSize(14)
              .fontColor(this.segIndex === i ? $r('app.color.mobile_campus_primary_color_default') :
                $r('app.color.common_color_3'))
              .padding({ left: 20, right: 20 })
              .height(46)
              .onClick(() => {
                this.segIndex = i;
              })
            // 指示器：高2dip与标题等宽 primary_default
            Row()
              .width(36)
              .height(2)
              .backgroundColor(this.segIndex === i ? $r('app.color.mobile_campus_primary_color_default') :
                Color.Transparent)
          }
          .layoutWeight(1)
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)
        }, (t: string) => 'todo_tab_' + t)
      }
      .width('100%')
      .height(48)
      .backgroundColor($r('app.color.white'))

      // ViewPager：三段列表
      List() {
        ForEach(this.items[this.segIndex], (item: TodoSuperviseItem) => {
          ListItem() {
            this.todoRow(item)
          }
        }, (item: TodoSuperviseItem) => item.title)
      }
      .width('100%')
      .layoutWeight(1)
      .divider({
        strokeWidth: 0.5,
        color: $r('app.color.common_color_5'),
        startMargin: 15,
        endMargin: 15
      })
      .backgroundColor($r('app.color.white'))
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.common_color_6'))
  }
}

