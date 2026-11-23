import { router } from '@kit.ArkUI';
import { BusinessError } from '@kit.BasicServicesKit';
import { ApiService } from '../network/ApiService';
import { ApiResponse } from '../model/ResponseModel';
import { TitleBar } from '../components/TitleBar';
import { BreakpointSystem } from '../common/BreakpointSystem';

/**
 * 教学评价表单 — 源码级翻译 [W21 supervise]（SuperviseEvaluateActivity.java 逐行 → ArkTS）：
 *
 * 【布局】mobile_campus_supervise_activity_supervise_evaluate.xml：白卡 padH12 padB18 mt12
 *   应到/实到两列（TextStyle3 label + TextStyle5 输入框 68 宽 padV8 底 #F8F8F9 描边 #DFE4EA 圆角4），
 *   灰细线，"课程评价"17sp 居中 mt24，BaseRatingBar（numStars=5 rating=0 starSize=20 starPadding=8），
 *   supervise_evaluate_content lines=5 hint=mobile_campus_supervise_evaluate_hint
 *   "本次课程整体效果如何呢？"；底部"提交评价"（selector_evaluate_btn：shape_evaluate #1B68B7）
 *
 * 【路由参数】y(Intent)：xlh = intent.getStringExtra("xlh")（SuperviseMinePastListFragment.d.a 回传）
 * 【校验】Q2() 顺序：应到人数不能为空 → 实到人数不能为空 → (rating<1) 请在评分条进行评分 →
 *   教学评价不能为空（首错 toast，提交终止）
 * 【提交】b.onClick → L2(String.valueOf((int)rating), ydrs, sdrs, nr, xlh) → SuperviseModel.U0：
 *   POST commentsListenCourse {dj, ydrs, sdrs, nr, xlh}；c.g：data=="true"(STATUS_TRUE) 成功 →
 *   x2("评论成功") + setResult(-1) + finish；否则 m(str2) toast(message)。
 *   2026-11-18 probe_w21_supervise.py：假 xlh → code=0001 系统异常（端点存活）。
 * 【回传】成功 setResult → MineActivity.onActivityResult 120 RESULT_OK → 两 Fragment 重拉
 *   （HAP：AppStorage 'supervise_evaluate_done'='1' + router.back）。
 */

class SuperviseStar {
  index: number;
  lit: boolean;

  constructor(index: number, lit: boolean) {
    this.index = index;
    this.lit = lit;
  }
}

@Entry
@Component
struct SuperviseEvaluatePage {
  @State attendanceExpect: string = '';
  @State attendanceActual: string = '';
  @State evaluateContent: string = '';
  @State starRating: number = 0;
  @State stars: SuperviseStar[] = [
    new SuperviseStar(1, false),
    new SuperviseStar(2, false),
    new SuperviseStar(3, false),
    new SuperviseStar(4, false),
    new SuperviseStar(5, false)
  ];
  @State isSubmitting: boolean = false;
  @StorageProp('currentBreakpoint') currentBreakpoint: string = 'sm';
  @StorageProp('avoidAreaBottomVp') avoidAreaBottomVp: number = 0;
  @StorageProp('avoidAreaLeftVp') avoidAreaLeftVp: number = 0;
  @StorageProp('avoidAreaRightVp') avoidAreaRightVp: number = 0;
  @StorageProp('keyboardHeightVp') keyboardHeightVp: number = 0;
  /** 源码 r：intent "xlh"（听课示例行唯一标识，提交必需） */
  private xlh: string = '';

  aboutToAppear(): void {
    // 源码 y(Intent)：this.r = intent.getStringExtra("xlh")
    const params: object | undefined = router.getParams() as object | undefined;
    if (params !== undefined && params !== null) {
      const rec: Record<string, Object> = params as Record<string, Object>;
      const xlhV: Object = rec['xlh'];
      if (typeof xlhV === 'string') {
        this.xlh = xlhV as string;
      }
    }
  }

  private refreshStars(rating: number): void {
    this.starRating = rating;
    this.stars = this.stars.map((star: SuperviseStar): SuperviseStar => {
      return new SuperviseStar(star.index, star.index <= rating);
    });
  }

  /** 源码 Q2()：首错校验串（空串=通过） */
  private validateForm(): string {
    if (this.attendanceExpect === '') {
      return '应到人数不能为空';
    }
    if (this.attendanceActual === '') {
      return '实到人数不能为空';
    }
    if (this.starRating < 1) {
      return '请在评分条进行评分';
    }
    if (this.evaluateContent === '') {
      return '教学评价不能为空';
    }
    return '';
  }

  /** 源码 b.onClick：Q2 非空 → m(strQ2) toast 终止；通过 → L2 提交 */
  private submitEvaluate(): void {
    if (this.isSubmitting) {
      return;
    }
    const invalid: string = this.validateForm();
    if (invalid !== '') {
      this.getUIContext().getPromptAction().showToast({ message: invalid });
      return;
    }
    this.isSubmitting = true;
    // 源码 L2：dj=String.valueOf((int)rating), ydrs=O2(), sdrs=M2(), nr=N2(), xlh=r
    ApiService.submitSuperviseComment(String(this.starRating), this.attendanceExpect,
      this.attendanceActual, this.evaluateContent, this.xlh)
      .then((response: ApiResponse<string>) => {
        this.isSubmitting = false;
        if (response.code === 1000) {
          // 登录失效统一处理已在网络层触发（HttpClient.bizRequest 拦截：清会话+toast+跳登录）
          return;
        }
        if (response.code === 0 && response.data === 'true') {
          // 源码 c.g：x2("评论成功") + setResult(-1) + finish
          this.getUIContext().getPromptAction().showToast({ message: '评论成功' });
          AppStorage.setOrCreate<string>('supervise_evaluate_done', '1');
          router.back();
        } else {
          // 源码 c.g：data!="true" → m(str2) toast(message)
          this.getUIContext().getPromptAction().showToast({
            message: response.message === '' ? '提交失败' : response.message
          });
        }
      })
      .catch((error: BusinessError) => {
        this.isSubmitting = false;
        ApiService.logError('SuperviseEvaluatePage submit fail: ' + error.message);
        this.getUIContext().getPromptAction().showToast({ message: '提交失败' });
      });
  }

  build() {
    Column() {
      // T1：R$string.mobile_campus_supervise_activity_evaluate_title = "教学评价"
      TitleBar({ title: '教学评价', showBack: true })

      Scroll() {
        Column() {
          // 白色内容卡：marginTop 12，padding L/R 12，bottom 18
          Column() {
            // 应到/实到人数两列（TextStyle5：宽 68vp，padding V8，编辑框底 #F8F8F9 描边 #DFE4EA 圆角 4）
            Row() {
              Row() {
                Text('应到人数')
                  .fontSize(14)
                  .fontColor($r('app.color.common_color_1'))
                TextInput({ text: this.attendanceExpect, placeholder: '' })
                  .fontSize(14)
                  .fontColor($r('app.color.common_color_1'))
                  .maxLength(3)
                  .type(InputType.Number)
                  .textAlign(TextAlign.Center)
                  .width(68)
                  .height(36)
                  .padding({ top: 8, bottom: 8 })
                  .backgroundColor($r('app.color.mobile_campus_supervise_evaluate_edittext_solid'))
                  .borderRadius(4)
                  .border({ width: 0.5, color: $r('app.color.mobile_campus_supervise_evaluate_edittext_stroke') })
                  .onChange((value: string) => {
                    this.attendanceExpect = value;
                  })
              }
              .layoutWeight(1)

              Row() {
                Text('实到人数')
                  .fontSize(14)
                  .fontColor($r('app.color.common_color_1'))
                TextInput({ text: this.attendanceActual, placeholder: '' })
                  .fontSize(14)
                  .fontColor($r('app.color.common_color_1'))
                  .maxLength(3)
                  .type(InputType.Number)
                  .textAlign(TextAlign.Center)
                  .width(68)
                  .height(36)
                  .padding({ top: 8, bottom: 8 })
                  .backgroundColor($r('app.color.mobile_campus_supervise_evaluate_edittext_solid'))
                  .borderRadius(4)
                  .border({ width: 0.5, color: $r('app.color.mobile_campus_supervise_evaluate_edittext_stroke') })
                  .onChange((value: string) => {
                    this.attendanceActual = value;
                  })
              }
              .layoutWeight(1)
            }
            .width('100%')
            .margin({ top: 12, bottom: 12 })
            .alignItems(VerticalAlign.Center)

            Divider()
              .color($r('app.color.common_color_5'))
              .strokeWidth(0.5)
              .width('100%')

            Text('课程评价')
              .fontSize(17)
              .fontColor($r('app.color.common_color_1'))
              .margin({ top: 24 })

            // BaseRatingBar：numStars 5，starSize 20px→10vp，starPadding 8px→4vp
            Row({ space: 4 }) {
              ForEach(this.stars, (star: SuperviseStar) => {
                Image(star.lit ? $r('app.media.mobile_campus_supervise_star_light') : $r('app.media.mobile_campus_supervise_star_grey'))
                  .width(10)
                  .height(10)
                  .onClick(() => {
                    this.refreshStars(star.index);
                  })
              }, (star: SuperviseStar) => star.index.toString())
            }
            .margin({ top: 21, bottom: 17 })

            TextArea({ text: this.evaluateContent, placeholder: '本次课程整体效果如何呢？' })
              .fontSize(14)
              .fontColor($r('app.color.common_color_1'))
              .placeholderColor($r('app.color.edit_hint_color'))
              .placeholderFont({ size: 14 })
              .backgroundColor($r('app.color.mobile_campus_supervise_evaluate_edittext_solid'))
              .borderRadius(4)
              .border({ width: 0.5, color: $r('app.color.mobile_campus_supervise_evaluate_edittext_stroke') })
              .padding(7)
              .height(120)
              .width('100%')
              .margin({ top: 15 })
              .onChange((value: string) => {
                this.evaluateContent = value;
              })
          }
          .width('100%')
          .backgroundColor($r('app.color.white'))
          .padding({ left: 12, right: 12, bottom: 18 })
          .margin({ top: 12 })

          // 提交评价：shape_evaluate 纯色 #1B68B7 无圆角，文字白色 17fp，padding V10
          Text('提交评价')
            .fontSize(17)
            .fontColor(Color.White)
            .textAlign(TextAlign.Center)
            .width('100%')
            .padding({ top: 10, bottom: 10 })
            .margin({ top: 20 })
            .backgroundColor($r('app.color.mobile_campus_primary_color_default'))
            .onClick(() => {
              this.submitEvaluate();
            })
        }
        .width('100%')
        .constraintSize({
          minHeight: '100%',
          maxWidth: BreakpointSystem.getContentMaxWidth(this.currentBreakpoint)
        })
        .alignSelf(ItemAlign.Center)
        .justifyContent(FlexAlign.SpaceBetween)
        .padding({
          left: this.avoidAreaLeftVp,
          right: this.avoidAreaRightVp,
          bottom: this.keyboardHeightVp + this.avoidAreaBottomVp
        })
      }
      .width('100%')
      .layoutWeight(1)
      .scrollBar(BarState.Off)
      .align(Alignment.Top)
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.common_color_6'))
  }
}
