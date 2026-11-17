import { TitleBar } from '../components/TitleBar';

class ZhyCriterionInfo {
  criterionId: string;
  criterionText: string;
  criterionDesc: string;

  constructor(criterionId: string, criterionText: string, criterionDesc: string) {
    this.criterionId = criterionId;
    this.criterionText = criterionText;
    this.criterionDesc = criterionDesc;
  }
}

/**
 * 迎新四准则 — 1:1 复刻 mobile_campus_view_main_zhy_four_criterion.xml +
 * mobile_campus_view_main_zhy_four_criterion_item.xml：
 * four_criterion：RecyclerView background=@color/white、paddingL/R 2.5dip、paddingT 7.5dip
 * item（item.xml 761B）：
 *   - llLayout：LinearLayout center_horizontal、paddingH 2.5dip
 *   - tvContent（BLTextView）：14.0sp=14fp、textColor=#ff283163、gravity=center、
 *     paddingV 10.0dip、bl_corners_radius=8.0dip、bl_solid_color=#19283163
 * 卡片双列宫格展示（四准则卡），内置示例数据。
 */
@Entry
@Component
struct ZhyFourPage {
  @State criterionList: ZhyCriterionInfo[] = [
    new ZhyCriterionInfo('c1', '遵规守纪', '自觉遵守校纪校规，维护校园秩序'),
    new ZhyCriterionInfo('c2', '诚实守信', '诚信做人守信做事，杜绝弄虚作假'),
    new ZhyCriterionInfo('c3', '勤俭节约', '厉行节约反对浪费，养成良好习惯'),
    new ZhyCriterionInfo('c4', '安全自律', '增强安全防范意识，规范日常言行')
  ];

  /**
   * mobile_campus_view_main_zhy_four_criterion_item.xml — 四准则卡片。
   * 卡片文字 14fp #283163、圆角 8.0dip=8vp、
   * 实底 #19283163、paddingV 10vp(10.0dip)、gravity=center。
   */
  @Builder
  criterionCard(cardItem: ZhyCriterionInfo) {
    Column() {
      Text(cardItem.criterionText)
        .fontSize(14)
        .fontColor($r('app.color.zhy_criterion_text'))
        .textAlign(TextAlign.Center)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
      Text(cardItem.criterionDesc)
        .fontSize(11)
        .fontColor($r('app.color.common_color_3'))
        .maxLines(2)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .margin({ top: 2 })
    }
    .width('100%')
    .padding({ top: 10, bottom: 10, left: 6, right: 6 })
    .borderRadius(8)
    .backgroundColor($r('app.color.zhy_criterion_bg'))
    .alignItems(HorizontalAlign.Center)
    .justifyContent(FlexAlign.Center)
  }

  build() {
    // 容器：RecyclerView 白底、paddingL/R 2.5vp、paddingT 7.5vp
    Column() {
      TitleBar({ title: '迎新四准则', showBack: true })
      Scroll() {
        Column() {
          Grid() {
            ForEach(this.criterionList, (cardItem: ZhyCriterionInfo) => {
              GridItem() {
                this.criterionCard(cardItem)
              }
            }, (cardItem: ZhyCriterionInfo) => cardItem.criterionId)
          }
          .columnsTemplate('1fr 1fr')
          .rowsGap(5)
          .width('100%')
          .padding({ left: 2.5, right: 2.5, top: 7.5 })
          .backgroundColor($r('app.color.white'))
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)
      }
      .width('100%')
      .layoutWeight(1)
      .backgroundColor($r('app.color.white'))
      .scrollBar(BarState.Off)
      .align(Alignment.Top)
    }
    .width('100%')
    .height('100%')
  }
}

