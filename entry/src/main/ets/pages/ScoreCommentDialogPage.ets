/**
 * 班主任评语弹窗页 — 1:1 复刻 fragment_score_comment_list.xml（px_to_dip_N = N/2 vp）：
 * - FrameLayout 背景 shape_scroe_comment：纯色 #4B4B4B、圆角 8dip(=8vp)、fill 尺寸；
 * - 内层 LinearLayout 竖向、padding px_to_dip_12(=6vp)；
 * - 头部 RelativeLayout：左侧 "班主任评语：" px_to_dip_34(=17fp) ybg_white(#FFFFFF)、
 *   右侧 imgClose 图标 code_close；
 * - ScrollView marginTop px_to_dip_12(=6vp)：tvContent px_to_dip_28(=14fp) ybg_white。
 */
import { router } from '@kit.ArkUI';
import { BreakpointSystem } from '../common/BreakpointSystem';

const HEAD_TEACHER_COMMENT: string = '该生本学期学习态度端正，课堂表现积极，能够按时完成各科作业，质量良好。\n\n' +
  '在班级活动中乐于助人，与同学相处融洽，具有较强的集体荣誉感。\n\n' +
  '希望今后继续保持良好的学习习惯，加强自主学习的规划性，在薄弱科目上多下功夫，\n' +
  '争取在下一次考试中取得更大的进步。';

@Entry
@Component
struct ScoreCommentDialogPage {
  @StorageProp('currentBreakpoint') currentBreakpoint: string = 'sm';
  @StorageProp('windowWidthVp') windowWidthVp: number = 360;
  @StorageProp('windowHeightVp') windowHeightVp: number = 640;
  @StorageProp('avoidAreaTopVp') avoidAreaTopVp: number = 0;
  @StorageProp('avoidAreaBottomVp') avoidAreaBottomVp: number = 0;
  @StorageProp('avoidAreaLeftVp') avoidAreaLeftVp: number = 0;
  @StorageProp('avoidAreaRightVp') avoidAreaRightVp: number = 0;

  build() {
    Column() {
      // shape_scroe_comment：#4B4B4B 圆角 8vp
      Column() {
        // 头部行：标题居左、关闭居右
        Row() {
          Text('班主任评语：')
            .fontSize(17)
            .fontColor($r('app.color.ybg_white'))

          Image($r('app.media.code_close'))
            .width(20)
            .height(20)
            .onClick(() => {
              router.back();
            })
        }
        .width('100%')
        .justifyContent(FlexAlign.SpaceBetween)
        .alignItems(VerticalAlign.Top)

        // 评语内容滚动区：marginTop 6vp
        Scroll() {
          Text(HEAD_TEACHER_COMMENT)
            .fontSize(14)
            .fontColor($r('app.color.ybg_white'))
            .lineHeight(22)
            .width('100%')
        }
        .width('100%')
        .layoutWeight(1)
        .margin({ top: 6 })
        .scrollBar(BarState.Off)
        .align(Alignment.TopStart)
      }
      .width('88%')
      .height(Math.min(320, BreakpointSystem.getDialogMaxHeight(this.windowHeightVp)))
      .constraintSize({
        maxWidth: BreakpointSystem.getDialogMaxWidth(this.currentBreakpoint, this.windowWidthVp),
        maxHeight: BreakpointSystem.getDialogMaxHeight(this.windowHeightVp)
      })
      .padding(6)
      .borderRadius(8)
      .backgroundColor('#4B4B4B')
    }
    .width('100%')
    .height('100%')
    .padding({
      top: this.avoidAreaTopVp,
      bottom: this.avoidAreaBottomVp,
      left: this.avoidAreaLeftVp,
      right: this.avoidAreaRightVp
    })
    .backgroundColor('#99000000')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
  }
}
