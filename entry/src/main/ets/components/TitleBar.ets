import { router } from '@kit.ArkUI';

/**
 * 通用标题栏 — 1:1 复刻 toolbar_normal.xml
 * 结构：toolBarView 状态栏占位(paddingTop安全区) + LinearLayout 45vp 高（白底 main_bg）
 *   - Toolbar 44vp：左侧返回、中央标题 17fp(px_to_sp_34/2) common_color_1 居中 maxLength 18
 *   - divider_horizontal_grey_thin 细分隔线 0.5vp
 * 安全区：expandSafeArea顶部跟随，标题不被状态栏遮挡
 */
@Component
export struct TitleBar {
  @Prop title: string = '';
  @Prop showBack: boolean = true;
  /** 右侧文字按钮（源码 toolbar_normal 的 toolBar_text_but，如反馈页"反馈记录"，黑色） */
  @Prop rightText: string = '';
  /** 右侧图标资源（源码 toolbar toolBar_image_but，如校圈主页 SocialMainActivity.T1 social_more） */
  rightIcon: Resource | null = null;
  /** 右侧按钮点击回调（普通属性，TitleBar({ onRightClick: () => {} }) 传入） */
  onRightClick: (() => void) | null = null;
  /** [W4 sms-login] 自定义返回回调（验证码页返回手机号输入阶段；null 保持 router.back 默认行为） */
  onBack: (() => void) | null = null;
  /**
   * [W15 score-series] 右侧按钮启用 selector_post 双态 pill（ScoreCommentPostActivity.T1 /
   * HandleExamCourseActivity.T1：selector_post 蓝态 shape_blue #88d9ff、灰态 shape_white
   * 白底 0.5dip #cecece 描边；selector_post_color 灰态字 #999999；98x56dip=49x28vp 圆角 2；
   * toolBar_text_but px_to_dip_32=16fp）。false 保持既有纯文字形态。
   */
  rightButtonStyle: boolean = false;
  /** selector_post 双态开关（源码 setEnabled：false 时按钮不可点、走灰态配色） */
  @Prop rightEnabled: boolean = true;
  /** [W20 social] 右侧文字自定义色（PostDetailActivity.T1 "更多" ybg_blue；null 保持黑色） */
  rightTextColor: string | null = null;
  /** [tablet-adapt] EntryAbility 写入的宽屏断点（≥600vp）：标题栏内容区同步限宽 560vp 居中 */
  @StorageProp('isWideScreen') isWideScreen: boolean = false;

  build() {
    Column() {
      Row() {
        if (this.showBack) {
          Text('＜')
            .fontSize(17)
            .fontColor($r('app.color.common_color_1'))
            .width(40)
            .height('100%')
            .textAlign(TextAlign.Center)
            .margin({ left: 15 })
            .onClick(() => {
              if (this.onBack !== null) {
                this.onBack();
              } else {
                router.back();
              }
            })
        }
        Text(this.title)
          .fontSize(17)
          .fontColor($r('app.color.common_color_1'))
          .layoutWeight(1)
          .textAlign(TextAlign.Center)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        if (this.rightIcon !== null) {
          Image(this.rightIcon)
            .width(35)
            .height(35)
            .objectFit(ImageFit.Contain)
            .margin({ right: 12 })
            .onClick(() => {
              if (this.onRightClick !== null) {
                this.onRightClick();
              }
            })
        } else if (this.rightText !== '') {
          if (this.rightButtonStyle) {
            // selector_post 双态 pill：enabled 蓝底白字 / disabled 白底描边灰字且不可点
            Text(this.rightText)
              .fontSize(16)
              .fontColor(this.rightEnabled ? Color.White : $r('app.color.common_color_3'))
              .textAlign(TextAlign.Center)
              .width(49)
              .height(28)
              .borderRadius(2)
              .backgroundColor(this.rightEnabled ? $r('app.color.common_color_12') : Color.White)
              .border({
                width: this.rightEnabled ? 0 : 0.5,
                color: $r('app.color.common_color_4')
              })
              .margin({ right: 15 })
              .onClick(() => {
                if (this.rightEnabled && this.onRightClick !== null) {
                  this.onRightClick();
                }
              })
          } else {
            Text(this.rightText)
              .fontSize(16)
              .fontColor(this.rightTextColor === null ? $r('app.color.black') : this.rightTextColor)
              .margin({ right: 12 })
              .onClick(() => {
                if (this.onRightClick !== null) {
                  this.onRightClick();
                }
              })
          }
        } else if (this.showBack) {
          Blank()
            .width(40)
        } else {
          Blank()
            .width(16)
        }
      }
      .width('100%')
      .height(44)
      .alignItems(VerticalAlign.Center)
      .backgroundColor($r('app.color.main_bg'))
      // [tablet-adapt] 宽屏标题栏内容限宽 560vp 居中（窄屏 100% 与改动前一致）
      .constraintSize({ maxWidth: this.isWideScreen ? 560 : '100%' })
      .alignSelf(ItemAlign.Center)

      Divider()
        .color($r('app.color.common_color_5'))
        .strokeWidth(0.5)
        .width('100%')
        .constraintSize({ maxWidth: this.isWideScreen ? 560 : '100%' })
        .alignSelf(ItemAlign.Center)
    }
    .width('100%')
    .height(45)
    .backgroundColor($r('app.color.main_bg'))
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP])
  }
}


