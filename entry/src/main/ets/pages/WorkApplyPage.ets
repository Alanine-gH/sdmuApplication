import { router } from '@kit.ArkUI';
import { TitleBar } from '../components/TitleBar';

class WorkApplyItem {
  id: string = '';
  title: string = '';
  node: string = '';
  date: string = '';
  urgent: boolean = false;
  cuiban: boolean = false;

  constructor(id: string, title: string, node: string, date: string, urgent: boolean, cuiban: boolean) {
    this.id = id;
    this.title = title;
    this.node = node;
    this.date = date;
    this.urgent = urgent;
    this.cuiban = cuiban;
  }
}

class WorkApplyCategory {
  id: string = '';
  name: string = '';
  icon: Resource = $r('app.media.mobile_campus_oa_workapply');

  constructor(id: string, name: string, icon: Resource) {
    this.id = id;
    this.name = name;
    this.icon = icon;
  }
}

@Entry
@Component
struct WorkApplyPage {
  @State categories: WorkApplyCategory[] = [
    new WorkApplyCategory('c1', '通知公告', $r('app.media.mobile_campus_oa_workapply')),
    new WorkApplyCategory('c2', '呈批件', $r('app.media.mobile_campus_oa_word')),
    new WorkApplyCategory('c3', '收文', $r('app.media.mobile_campus_oa_document')),
    new WorkApplyCategory('c4', '请假申请', $r('app.media.mobile_campus_oa_apply'))
  ];
  @State applyList: WorkApplyItem[] = [
    new WorkApplyItem('w1', '关于举办2026年秋季学期教职工运动会的通知', '办公室审核中', '2026-11-12 09:30', false, false),
    new WorkApplyItem('w2', '海南外国语职业学院多功能报告厅使用申请', '院办审核 · 审批中', '2026-11-10 15:42', true, true),
    new WorkApplyItem('w3', '关于2026年度部门预算调整的请示', '分管校领导审批中', '2026-11-08 11:20', false, false),
    new WorkApplyItem('w4', '关于校园网络机房改造方案的呈批件', '待审批', '2026-11-06 16:05', false, true),
    new WorkApplyItem('w5', '关于推荐王建国同志参评省级优秀教师的报告', '已通过', '2026-11-05 09:12', false, false),
    new WorkApplyItem('w6', '关于采购实验教学耗材的申请', '已通过', '2026-11-03 14:30', false, false)
  ];
  @State showFilter: boolean = false;
  @State filterName: string = '党委会议议题';

  private toggleFilter(): void {
    this.showFilter = !this.showFilter;
  }

  private closeFilter(): void {
    this.showFilter = false;
  }

  private goDetail(): void {
    router.pushUrl({ url: 'pages/WorkApplyDetailPage' });
  }

  build() {
    Column() {
      TitleBar({ title: '我的申请', showBack: true })

      Scroll() {
        Row() {
          ForEach(this.categories, (cat: WorkApplyCategory) => {
            Column() {
              Image(cat.icon)
                .width(59)
                .height(59)
                .objectFit(ImageFit.Fill)
                .margin({ top: 13 })
              Text(cat.name)
                .fontSize(12)
                .fontColor($r('app.color.common_color_1'))
                .margin({ top: 4, bottom: 12 })
                .padding({ left: 3, right: 3 })
            }
            .alignItems(HorizontalAlign.Center)
            .margin({ left: 8, right: 8 })
            .onClick(() => {
              this.toggleFilter();
            })
          }, (cat: WorkApplyCategory) => cat.id)
        }
        .alignItems(VerticalAlign.Top)
        .padding({ left: 4, right: 4 })
      }
      .scrollable(ScrollDirection.Horizontal)
      .scrollBar(BarState.Off)
      .width('100%')
      .backgroundColor($r('app.color.main_bg'))

      Column()
        .width('100%')
        .height(12)
        .backgroundColor($r('app.color.common_color_6'))

      Row() {
        Text('我发起的')
          .fontSize(14)
          .fontColor($r('app.color.mobile_campus_schedule_color11'))
          .padding({ top: 10, bottom: 10 })
        Blank()
        Row() {
          Image($r('app.media.mobile_campus_oa_apply_screen'))
            .width(16)
            .height(16)
            .objectFit(ImageFit.Contain)
          Text('筛选')
            .fontSize(14)
            .fontColor($r('app.color.mobile_campus_primary_color_default'))
            .padding({ top: 5, bottom: 5 })
            .margin({ left: 8 })
        }
        .alignItems(VerticalAlign.Center)
        .onClick(() => {
          this.toggleFilter();
        })
      }
      .width('100%')
      .padding({ left: 12, right: 12 })
      .alignItems(VerticalAlign.Center)
      .backgroundColor($r('app.color.main_bg'))

      Divider()
        .strokeWidth(0.5)
        .color($r('app.color.common_color_5'))
        .width('100%')

      if (this.showFilter) {
        Row() {
          Text('筛选: ')
            .fontSize(13)
            .fontColor($r('app.color.mobile_campus_schedule_color11'))
            .margin({ top: 8, bottom: 8 })
          Text(this.filterName)
            .fontSize(13)
            .fontColor($r('app.color.mobile_campus_schedule_color11'))
            .layoutWeight(1)
            .margin({ top: 8, bottom: 8 })
          Image($r('app.media.mobile_campus_oa_apply_close'))
            .width(16)
            .height(16)
            .objectFit(ImageFit.Contain)
            .padding(5)
            .onClick(() => {
              this.closeFilter();
            })
        }
        .width('100%')
        .padding({ left: 12, right: 12 })
        .alignItems(VerticalAlign.Center)
        .backgroundColor($r('app.color.mobile_campus_schedule_color19'))
      }

      List() {
        ForEach(this.applyList, (item: WorkApplyItem) => {
          ListItem() {
            Column() {
              Column() {
                Row() {
                  if (item.urgent) {
                    Text('特提')
                      .fontSize(10)
                      .fontColor($r('app.color.white'))
                      .textAlign(TextAlign.Center)
                      .backgroundColor($r('app.color.mobile_campus_schedule_color7'))
                      .borderRadius(2)
                      .padding({ left: 5, right: 5, top: 3, bottom: 3 })
                      .margin({ right: 8 })
                  }
                  if (item.cuiban) {
                    Text('已催办')
                      .fontSize(10)
                      .fontColor($r('app.color.mobile_campus_primary_color_default'))
                      .textAlign(TextAlign.Center)
                      .borderRadius(2)
                      .border({ width: 0.5, color: $r('app.color.mobile_campus_primary_color_default') })
                      .padding({ left: 5, right: 5, top: 3, bottom: 3 })
                      .margin({ right: 12 })
                  }
                  Text(item.node)
                    .fontSize(13)
                    .fontColor($r('app.color.mobile_campus_schedule_color17'))
                    .layoutWeight(1)
                    .maxLines(1)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                }
                .width('100%')
                .alignItems(VerticalAlign.Center)
                .margin({ bottom: 8 })

                Text(item.title)
                  .fontSize(17)
                  .fontColor($r('app.color.common_color_1'))
                  .maxLines(2)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
                  .width('100%')
                  .margin({ bottom: 12 })

                Row() {
                  Text('申请时间：')
                    .fontSize(13)
                    .fontColor($r('app.color.common_color_3'))
                  Text(item.date)
                    .fontSize(13)
                    .fontColor($r('app.color.common_color_3'))
                    .layoutWeight(1)
                }
                .width('100%')
                .alignItems(VerticalAlign.Center)
              }
              .padding(12)
              .width('100%')
              .alignItems(HorizontalAlign.Start)
              .onClick(() => {
                this.goDetail();
              })

              Divider()
                .strokeWidth(0.5)
                .color($r('app.color.menu_divider'))
                .margin({ left: 12 })
                .width('100%')
            }
            .width('100%')
            .alignItems(HorizontalAlign.Start)
          }
        }, (item: WorkApplyItem) => item.id)

        ListItem() {
          Row() {
            Divider()
              .strokeWidth(0.5)
              .color($r('app.color.common_color_5'))
              .layoutWeight(1)
            Text('已显示全部')
              .fontSize(13)
              .fontColor($r('app.color.common_color_3'))
              .margin({ left: 20, right: 20 })
            Divider()
              .strokeWidth(0.5)
              .color($r('app.color.common_color_5'))
              .layoutWeight(1)
          }
          .width('100%')
          .alignItems(VerticalAlign.Center)
          .padding({ top: 14, bottom: 14, left: 12, right: 12 })
        }
      }
      .width('100%')
      .layoutWeight(1)
      .backgroundColor($r('app.color.white'))
      .scrollBar(BarState.Off)
      .edgeEffect(EdgeEffect.None)
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.main_bg'))
  }
}
