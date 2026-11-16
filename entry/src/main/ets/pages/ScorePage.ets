import { ApiService } from '../network/ApiService';
import { ScoreItem } from '../model/ScoreModel';
import { TitleBar } from '../components/TitleBar';
import { EmptyView } from '../components/EmptyView';
import { LoadingView } from '../components/LoadingView';

/**
 * 成绩页 — 1:1 复刻 mobile_campus_score_activity_score_main.xml + fragment_score_main.xml +
 * item_score_parent.xml（学期分组头）+ item_score_child.xml（课程成绩行）
 *
 * activity_score_main.xml：LinearLayout 白底 + toolbar_normal + TabLayout(mTabLayout) + 内容
 * fragment_score_main.xml（NestedScrollView）：
 *   score_view_top / divider_horizontal_grey_normal / 白底块(score_view_mid 概况 +
 *   tvScore"查看学生具体成绩" #1B68B7 padding 12dip 右侧箭头) /
 *   divider_horizontal_grey_normal / score_view_bottom（学期分组可折叠列表）
 *
 * item_score_parent.xml（分组头）：高 px_to_dip_96=48vp、paddingH px_to_dip_24=12vp 居中、
 *   学年/学期 px_to_sp_32=16fp mobile_campus_score_common_color1(#3267B1)、
 *   学期 marginLeft 12vp weight=1、右侧 arrow_down 箭头
 * item_score_child.xml（成绩行）：padding px_to_dip_50/24 → L25 R12 T12 B12、
 *   课程名 px_to_sp_28=14fp common_color_1 weight=6、
 *   分数 14fp common_color_2 居中 weight=4、名次 14fp common_color_2
 */
class ScoreTermGroup {
  semester: string;
  xn: string;
  xq: string;
  items: ScoreItem[];

  constructor(semester: string, xn: string, xq: string) {
    this.semester = semester;
    this.xn = xn;
    this.xq = xq;
    this.items = [];
  }
}

@Entry
@Component
struct ScorePage {
  @State scoreList: ScoreItem[] = [];
  @State groups: ScoreTermGroup[] = [];
  @State isLoading: boolean = true;
  @State selectedTab: number = 0;
  @State expandedIndex: number = -1;
  @State avgGpa: string = '0.00';
  @State courseCount: number = 0;

  aboutToAppear(): void {
    ApiService.getScoreList()
      .then((response) => {
        this.scoreList = response.data;
        this.buildGroups();
        this.isLoading = false;
      })
      .catch(() => {
        this.scoreList = [];
        this.groups = [];
        this.isLoading = false;
      });
  }

  private buildGroups(): void {
    const groupList: ScoreTermGroup[] = [];
    let gpaSum: number = 0;
    for (const item of this.scoreList) {
      gpaSum += item.gpa;
      // semester 形如 "2025-2026-1" → 学年 + 第几学期
      const parts: string[] = item.semester.split('-');
      const xn: string = parts.length >= 3 ? parts[0] + '-' + parts[1] : item.semester;
      const xq: string = parts.length >= 3 ? '第' + parts[2] + '学期' : '';
      let target: ScoreTermGroup | null = null;
      for (const group of groupList) {
        if (group.semester === item.semester) {
          target = group;
          break;
        }
      }
      if (target === null) {
        target = new ScoreTermGroup(item.semester, xn, xq);
        groupList.push(target);
      }
      target.items.push(item);
    }
    this.groups = groupList;
    this.courseCount = this.scoreList.length;
    this.avgGpa = this.scoreList.length > 0 ? (gpaSum / this.scoreList.length).toFixed(2) : '0.00';
    this.expandedIndex = groupList.length > 0 ? 0 : -1;
  }

  private tabLabels(): string[] {
    const labels: string[] = ['全部'];
    for (const group of this.groups) {
      labels.push(group.xn + ' ' + group.xq);
    }
    return labels;
  }

  private visibleGroups(): ScoreTermGroup[] {
    if (this.selectedTab === 0) {
      return this.groups;
    }
    if (this.selectedTab - 1 < this.groups.length) {
      const single: ScoreTermGroup[] = [this.groups[this.selectedTab - 1]];
      return single;
    }
    return [];
  }

  private rankOf(item: ScoreItem, group: ScoreTermGroup): string {
    const sorted: ScoreItem[] = group.items.slice();
    sorted.sort((a: ScoreItem, b: ScoreItem): number => b.score - a.score);
    for (let i = 0; i < sorted.length; i++) {
      if (sorted[i].id === item.id) {
        return '第' + (i + 1) + '名';
      }
    }
    return '';
  }

  build() {
    // activity_score_main.xml：LinearLayout 白底
    Column() {
      // include toolbar_normal
      TitleBar({ title: '我的成绩', showBack: true })
      if (this.isLoading) {
        LoadingView()
      } else {
        if (this.scoreList.length === 0) {
          EmptyView()
        } else {
          // mTabLayout：学期筛选 Tab（选中 mobile_campus_score_common_color1 加粗）
          Column() {
            Row() {
              ForEach(this.tabLabels(), (label: string, index: number) => {
                Text(label)
                  .fontSize(14)
                  .fontColor(index === this.selectedTab ?
                    $r('app.color.mobile_campus_score_common_color1') : $r('app.color.common_color_2'))
                  .fontWeight(index === this.selectedTab ? FontWeight.Bold : FontWeight.Normal)
                  .padding({ left: 15, right: 15 })
                  .height(44)
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
                  .onClick(() => {
                    this.selectedTab = index;
                    this.expandedIndex = 0;
                  })
              }, (label: string) => 'scoretab' + label)
            }
            .width('100%')
            .height(44)
            .justifyContent(FlexAlign.Center)
          }
          .width('100%')
          .backgroundColor($r('app.color.main_bg'))

          // fragment_score_main.xml：NestedScrollView
          Scroll() {
            Column() {
              // include divider_horizontal_grey_normal
              Divider()
                .color($r('app.color.common_color_5'))
                .strokeWidth(0.5)
                .width('100%')
              // 白底块：score_view_mid 概况 + tvScore 入口
              Column() {
                // score_view_mid：绩点概况
                Row() {
                  Text('平均绩点 ' + this.avgGpa + ' · 共 ' + this.courseCount + ' 门')
                    .fontSize(14)
                    .fontColor($r('app.color.common_color_2'))
                    .layoutWeight(1)
                }
                .width('100%')
                .padding(12)
                // tvScore：查看学生具体成绩（#1B68B7、padding 12dip、右侧蓝色箭头）
                Row() {
                  Text($r('app.string.score_view_detail'))
                    .fontSize(14)
                    .fontColor($r('app.color.blue_default'))
                    .layoutWeight(1)
                  Image($r('app.media.arrow_right_blue_desk_widget'))
                    .width(6)
                    .height(11)
                }
                .width('100%')
                .padding(12)
              }
              .width('100%')
              .backgroundColor($r('app.color.white'))
              // include divider_horizontal_grey_normal
              Divider()
                .color($r('app.color.common_color_5'))
                .strokeWidth(0.5)
                .width('100%')
              // score_view_bottom：学期分组可折叠列表
              Column() {
                ForEach(this.visibleGroups(), (group: ScoreTermGroup, index: number) => {
                  // item_score_parent.xml：学期分组头（48vp 高、#3267B1 16fp、箭头）
                  Row() {
                    Text(group.xn)
                      .fontSize(16)
                      .fontColor($r('app.color.mobile_campus_score_common_color1'))
                    Text(group.xq)
                      .fontSize(16)
                      .fontColor($r('app.color.mobile_campus_score_common_color1'))
                      .margin({ left: 12 })
                      .layoutWeight(1)
                    Image($r('app.media.arrow_down'))
                      .width(15)
                      .height(8.5)
                      .rotate({ angle: index === this.expandedIndex ? 180 : 0 })
                  }
                  .width('100%')
                  .height(48)
                  .padding({ left: 12, right: 12 })
                  .alignItems(VerticalAlign.Center)
                  .onClick(() => {
                    this.expandedIndex = index === this.expandedIndex ? -1 : index;
                  })
                  if (index === this.expandedIndex) {
                    // item_score_child.xml：课程成绩行
                    ForEach(group.items, (item: ScoreItem) => {
                      Row() {
                        // 课程名 14fp #333333 weight=6
                        Text(item.courseName)
                          .fontSize(14)
                          .fontColor($r('app.color.common_color_1'))
                          .layoutWeight(6)
                          .maxLines(1)
                          .textOverflow({ overflow: TextOverflow.Ellipsis })
                        // 分数 14fp #555555 居中 weight=4
                        Text(item.score + '')
                          .fontSize(14)
                          .fontColor($r('app.color.common_color_2'))
                          .layoutWeight(4)
                          .textAlign(TextAlign.Center)
                        // 名次 14fp #555555
                        Text(this.rankOf(item, group))
                          .fontSize(14)
                          .fontColor($r('app.color.common_color_2'))
                      }
                      .width('100%')
                      .padding({ left: 25, right: 12, top: 12, bottom: 12 })
                    }, (item: ScoreItem) => 'score' + item.id)
                  }
                }, (group: ScoreTermGroup) => 'scoregroup' + group.semester)
              }
              .width('100%')
              .backgroundColor($r('app.color.white'))
            }
            .width('100%')
          }
          .width('100%')
          .layoutWeight(1)
          .backgroundColor($r('app.color.main_bg'))
          .scrollBar(BarState.Off)
        }
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.main_bg'))
  }
}
