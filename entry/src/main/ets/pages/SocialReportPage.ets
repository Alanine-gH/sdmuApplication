import { router, promptAction } from '@kit.ArkUI';
import { BusinessError } from '@kit.BasicServicesKit';
import { TitleBar } from '../components/TitleBar';
import { ApiService } from '../network/ApiService';
import { ApiResponse } from '../model/ResponseModel';

/**
 * 校圈举报页 — 源码级翻译 ReportActivity（social_report_activity，[P-B placeholder]）：
 * 【入口】MarketPage 更多菜单 / MarkDetailPage 更多菜单 / PostDetailPage 更多菜单
 *   （params: id=帖子id, fromMarket=是否集市来源）。
 * 【布局】toolbar 标题 R.string.scoial_choose_reason="选择原因"；右上"举报"按钮
 *   selector_post_color 文字 + selector_post 背景 setEnabled(true)。
 *   common_sv_rg RadioGroup：首行 divider + "请选择举报原因"（padding px_to_dip_30=15vp /
 *   TextSize3_Color3）+ divider；随后 R.array.report_reason 五项 RadioButton（右图
 *   social_report_rb_selector）：色情/欺诈骗钱/诅咒谩骂/广告骚扰/政治，默认 check 第 0 项，
 *   每项后 divider；RadioGroup 背景 ybg_white 高 MATCH_PARENT。
 * 【提交】a.onClick：取选中 RadioButton 文本 → !fromMarket 时
 *   presenter.b(id, reason)→SocialModel.V→LIANYI reportCircle {id,content}（push 域）；
 *   fromMarket 时 O2() 空实现（源码无任何副作用，保真）。
 *   回调 b0(str)：STATUS_FALSE("0")→toast network_or_service_error"连接不到网络，请稍后再试"；
 *   否则 toast"举报成功"+finish。
 *   探针实测 push 域 reportCircle SSL EOF 不可达 → 真实错误 toast，绝不编造成功。
 */
const REPORT_REASONS: string[] = ['色情', '欺诈骗钱', '诅咒谩骂', '广告骚扰', '政治'];

@Entry
@Component
struct SocialReportPage {
  @State reasons: string[] = REPORT_REASONS;
  @State selected: number = 0;
  @State submitting: boolean = false;
  private postId: string = '';
  private fromMarket: boolean = false;

  aboutToAppear(): void {
    const params: Record<string, Object> = (router.getParams() ?? {}) as Record<string, Object>;
    const idVal: Object | undefined = params['id'];
    this.postId = typeof idVal === 'string' ? idVal as string : '';
    const fm: Object | undefined = params['fromMarket'];
    this.fromMarket = fm === true;
  }

  /** 源码 a.onClick：举报按钮提交（fromMarket→O2 空实现；否则 reportCircle push） */
  private submit(): void {
    if (this.submitting) {
      return;
    }
    // 源码 fromMarket 分支 O2(str,str2) 方法体为空：无任何网络/UI 副作用，1:1 保真
    if (this.fromMarket) {
      return;
    }
    const reason: string = this.reasons[this.selected];
    this.submitting = true;
    ApiService.pushReportCircle(this.postId, reason)
      .then((response: ApiResponse<Object>) => {
        this.submitting = false;
        // 源码 b0：STATUS_FALSE("0")→network_or_service_error，否则"举报成功"+finish
        if (response.code !== 0) {
          promptAction.showToast({ message: '连接不到网络，请稍后再试' });
          return;
        }
        const data: Object = response.data;
        const dataStr: string = typeof data === 'string' ? data as string : '';
        if (dataStr === '0') {
          promptAction.showToast({ message: '连接不到网络，请稍后再试' });
          return;
        }
        promptAction.showToast({ message: '举报成功' });
        router.back();
      })
      .catch((error: BusinessError) => {
        this.submitting = false;
        ApiService.logError('reportCircle fail: ' + error.message);
        promptAction.showToast({ message: '连接不到网络，请稍后再试' });
      });
  }

  build() {
    Column() {
      TitleBar({
        title: '选择原因',
        rightText: '举报',
        rightButtonStyle: true,
        rightEnabled: !this.submitting,
        onRightClick: (): void => { this.submit(); }
      })

      Scroll() {
        Column() {
          Divider().color($r('app.color.common_color_5')).strokeWidth(8)
          Row() {
            Text('请选择举报原因')
              .fontSize(15)
              .fontColor($r('app.color.common_color_3'))
          }
          .width('100%')
          .padding(15)
          Divider().color($r('app.color.common_color_5')).strokeWidth(1)
          ForEach(this.reasons, (reason: string, index: number) => {
            Column() {
              Row() {
                Circle()
                  .width(18).height(18)
                  .stroke(this.selected === index ? $r('app.color.sdmu_primary') : $r('app.color.common_color_4'))
                  .strokeWidth(1.5)
                  .fill(this.selected === index ? $r('app.color.sdmu_primary') : Color.Transparent)
                  .margin({ right: 10 })
                Text(reason)
                  .fontSize(16)
                  .fontColor($r('app.color.common_color_1'))
                  .layoutWeight(1)
                Image($r('app.media.arrow_right2'))
                  .width(16).height(16)
                  .objectFit(ImageFit.Contain)
              }
              .width('100%')
              .padding({ left: 15, right: 15, top: 13, bottom: 13 })
              .onClick(() => { this.selected = index; })
              Divider().color($r('app.color.common_color_5')).strokeWidth(1)
            }
          }, (reason: string) => reason)
        }
        .width('100%')
        .backgroundColor($r('app.color.white'))
      }
      .width('100%')
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.main_bg'))
  }
}
