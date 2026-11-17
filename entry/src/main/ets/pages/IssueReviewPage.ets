import { TitleBar } from '../components/TitleBar';

/**
 * 议题审议页 — 复刻 IssueMainActivity（常量「议题审议」，布局用 oa_issue_view_list/group/child族）
 * 结构：toolbar「议题审议」+ SlidingTabLayout（议题列表/我的审议）+ 列表
 *   - 分组头（#F1F1F1灰 40vp组行）
 *   - 议题行（蓝色会议行 56dip 可展开）
 *   - 审议状态标签
 */
class ReviewIssue {
  title: string;
  dept: string;
  date: string;
  status: string;
  itemCount: number;

  constructor(title: string, dept: string, date: string, status: string, itemCount: number) {
    this.title = title;
    this.dept = dept;
    this.date = date;
    this.status = status;
    this.itemCount = itemCount;
  }
}

@Entry
@Component
struct IssueReviewPage {
  @State segIndex: number = 0;
  private tabTitles: string[] = ['议题列表', '我的审议'];
  @State pending: ReviewIssue[] = [
    new ReviewIssue('信息工程学院专业建设议题', '信息工程学院', '2026-11-16', '待审议', 3),
    new ReviewIssue('2027年实验室建设规划议题', '教务处', '2026-11-12', '待审议', 5),
    new ReviewIssue('校园网络升级改造议题', '网络中心', '2026-11-10', '审议中', 2)
  ];
  @State mine: ReviewIssue[] = [
    new ReviewIssue('软件工程课程体系调整议题', '信息工程学院', '2026-11-08', '已审议', 4),
    new ReviewIssue('校企联合培养方案议题', '工商管理学院', '2026-10-28', '已审议', 6)
  ];

  @Builder
  issueRow(item: ReviewIssue) {
    Column() {
      Row() {
        Column() {
          Text(item.title)
            .fontSize(16)
            .fontColor($r('app.color.blue_default'))
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
          Row() {
            Text(item.dept)
              .fontSize(12)
              .fontColor($r('app.color.common_color_3'))
            Text(item.date)
              .fontSize(12)
              .fontColor($r('app.color.common_color_3'))
              .layoutWeight(1)
              .textAlign(TextAlign.End)
          }
          .width('100%')
          .margin({ top: 6 })
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)

        Column() {
          Text(item.status)
            .fontSize(12)
            .fontColor(Color.White)
            .padding({ left: 8, right: 8, top: 3, bottom: 3 })
            .borderRadius(3)
            .backgroundColor(item.status === '待审议' ? $r('app.color.blue_default') :
              item.status === '审议中' ? '#FF8900' : $r('app.color.common_color_3'))
          Text(item.itemCount + '项')
            .fontSize(11)
            .fontColor($r('app.color.common_color_3'))
            .margin({ top: 4 })
        }
        .margin({ left: 12 })
        .alignItems(HorizontalAlign.Center)
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)
    }
    .width('100%')
    .padding({ left: 15, right: 15, top: 12, bottom: 12 })
    .backgroundColor($r('app.color.white'))
    .alignItems(HorizontalAlign.Start)
  }

  build() {
    Column() {
      TitleBar({ title: '议题审议', showBack: true })

      // SlidingTabLayout
      Row() {
        ForEach(this.tabTitles, (t: string, i: number) => {
          Column() {
            Text(t)
              .fontSize(14)
              .fontColor(this.segIndex === i ? $r('app.color.blue_default') : $r('app.color.common_color_3'))
              .padding({ left: 20, right: 20 })
              .height(46)
              .onClick(() => {
                this.segIndex = i;
              })
            Row()
              .width(36)
              .height(2)
              .backgroundColor(this.segIndex === i ? $r('app.color.blue_default') : Color.Transparent)
          }
          .layoutWeight(1)
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)
        }, (t: string) => 'issue_tab_' + t)
      }
      .width('100%')
      .height(48)
      .backgroundColor($r('app.color.white'))

      // 分组头（#F1F1F1 40vp）
      Text(this.segIndex === 0 ? '全部议题' : '我参与的审议')
        .fontSize(14)
        .fontColor($r('app.color.common_color_2'))
        .padding({ left: 15, top: 10, bottom: 10 })
        .width('100%')
        .backgroundColor('#F1F1F1')
        .alignSelf(ItemAlign.Start)

      // 议题列表
      List() {
        ForEach(this.segIndex === 0 ? this.pending : this.mine, (item: ReviewIssue) => {
          ListItem() {
            this.issueRow(item)
          }
        }, (item: ReviewIssue) => item.title)
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

