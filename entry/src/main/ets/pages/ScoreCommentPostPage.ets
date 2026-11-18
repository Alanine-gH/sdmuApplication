import { router } from '@kit.ArkUI';
import { TitleBar } from '../components/TitleBar';
import { ApiService } from '../network/ApiService';
import { ApiResponse } from '../model/ResponseModel';
import { BusinessError } from '@kit.BasicServicesKit';

/**
 * 课评留言发布页 — 1:1 翻译原 APK ScoreCommentPostActivity.java（student_score/view）
 * + student_score_post_publish.xml + student_score_post_publish_bottom_bar.xml。
 *
 * 【入口链】y 传参 {xn,xq,kcdm}（源码 ScoreCommentListActivity.c / ScoreDetailActivity.a 两处
 *   putExtra xn/xq/kcdm，Q0 startActivityForResult 8914）。HAP 上游（ScoreCommentPage/
 *   StudentScoreDetailPage）为旧复刻无学期状态 → 透传缺省为空串，接口按源码真实发送。
 * 【标题栏】T1：标题"留言" + 右"发布"按钮 selector_post 双态 pill（TitleBar rightButtonStyle）：
 *   enabled→蓝底#88d9ff白字 49x28vp 圆角2；disabled→白底0.5vp#cecece描边#999灰字且不可点，
 *   初始 disabled（setTextEnabled(false)）。
 * 【输入区】EmojiconEditText（TextSize2.Color1 17fp#333，hint common_color_4，lines=6，
 *   maxLength=500 InputFilter.LengthFilter，margin 12dip=6vp，白底）。
 * 【TextWatcher】a.onTextChanged：trim 空 → 发布 disabled（publishEnabled 联动 TitleBar rightEnabled）。
 * 【发布】P2() 空 → toast"内容不能为空！"（content_can_not_be_null）；否则隐藏键盘 +
 *   ScorePostPresenter.b → ScoreModel.T0（student_score/b/b.java）：POST api/grade/sendComment
 *   {xn,xq,kcdm,plnr}。成功 g0(str 非空) → setResult(change=true)+finish；失败 m(msg) toast。
 *   （2026-11-18 实测：接口 code=0 data='true' 通；服务器不校验内容空——空拦截保留源码分支。）
 * 【表情面板】EmoticonsKeyBoardLayout（480dip=240vp gone）HAP 无等价组件 → emoji 网格等价实现
 *   （点击插入输入框；图标 school_edit_emotion/hover 切换，显隐切换 Q2()）。
 * 【finish 拦截】有内容 → 确认弹窗"是否放弃已写内容"，确认才 super.finish()。
 */
@Entry
@Component
struct ScoreCommentPostPage {
  @State inputContent: string = '';
  @State showEmojiPanel: boolean = false;
  /** 源码 T1：g.setEnabled(false) 初始禁用；TextWatcher 按 trim 内容联动 */
  @State publishEnabled: boolean = false;
  // 源码 f1：j=xn i=xq k=kcdm
  private xn: string = '';
  private xq: string = '';
  private kcdm: string = '';
  /** 源码 l = 500（InputFilter.LengthFilter 上限） */
  private readonly maxLength: number = 500;
  /** 常用 emoji 面板（源码 EmoticonsKeyBoardLayout emojicon 键盘等价，纯输入辅助无业务数据） */
  private readonly emojiList: string[] = ['😀', '😄', '😅', '😂', '🙂', '😍', '😘', '😜', '😎', '🤔',
    '😴', '😭', '😡', '👍', '👎', '👏', '🙏', '💪', '🎉', '❤️'];

  aboutToAppear(): void {
    const params: Record<string, Object> | undefined =
      router.getParams() as Record<string, Object> | undefined;
    if (params) {
      this.xn = this.strOf(params['xn']);
      this.xq = this.strOf(params['xq']);
      this.kcdm = this.strOf(params['kcdm']);
    }
  }

  private strOf(v: Object): string {
    if (typeof v === 'string') {
      return v as string;
    }
    return '';
  }

  /** 源码 P2()：TextUtils.isEmpty(trim) */
  private isEmpty(): boolean {
    return this.inputContent.trim() === '';
  }

  /** 源码 b.onClick：空拦截 → h.b(xn,xq,kcdm,trim) → 成功 setResult(change)+finish */
  private submitComment(): void {
    if (this.isEmpty()) {
      // 源码 YBGToastUtil.l(getString(content_can_not_be_null))
      this.getUIContext().getPromptAction().showToast({ message: '内容不能为空！' });
      return;
    }
    ApiService.sendScoreComment(this.xn, this.xq, this.kcdm, this.inputContent.trim())
      .then((response: ApiResponse<string>) => {
        if (response.code === 1000) {
          return;
        }
        if (response.code === 0 && response.data !== '') {
          // 源码 g0(str!=null)：setResult(change=true) + g0.b() 隐藏键盘 + super.finish()
          this.showEmojiPanel = false;
          router.back();
        } else if (response.message !== '') {
          // 源码 f(str2)：m(str2) toast
          this.getUIContext().getPromptAction().showToast({ message: response.message });
        }
      })
      .catch((error: BusinessError) => {
        ApiService.logError('ScoreCommentPost sendComment fail: ' + error.message);
      });
  }

  /** 源码 Q2()：表情面板显隐切换（展开延迟 200ms + 图标 hover 切换） */
  private toggleEmojiPanel(): void {
    this.showEmojiPanel = !this.showEmojiPanel;
  }

  /** 源码 finish()：有内容 → "是否放弃已写内容"确认弹窗 */
  private confirmDiscard(): void {
    if (this.isEmpty()) {
      router.back();
      return;
    }
    this.getUIContext().showAlertDialog({
      title: '提示',
      message: '是否放弃已写内容',
      primaryButton: {
        value: '取消',
        action: () => {
        }
      },
      secondaryButton: {
        value: '确定',
        fontColor: $r('app.color.common_color_7'),
        action: () => {
          // 源码 e.a() → super.finish()（不回传 change）
          this.inputContent = '';
          router.back();
        }
      },
      cancel: () => {
      }
    });
  }

  @Builder
  emojiPanel() {
    // EmoticonsKeyBoardLayout 480dip=240vp 等价：emoji 网格（点击插入输入框）
    Grid() {
      ForEach(this.emojiList, (emoji: string) => {
        GridItem() {
          Text(emoji)
            .fontSize(24)
            .width('100%')
            .height(40)
            .textAlign(TextAlign.Center)
            .onClick(() => {
              this.inputContent = this.inputContent + emoji;
            })
        }
      }, (emoji: string) => emoji)
    }
    .columnsTemplate('1 1 1 1 1 1 1 1')
    .rowsGap(4)
    .width('100%')
    .height(240)
    .padding({ left: 15, right: 15, top: 8, bottom: 8 })
    .backgroundColor($r('app.color.white'))
  }

  build() {
    Column() {
      TitleBar({
        title: '留言',
        showBack: true,
        rightText: '发布',
        rightButtonStyle: true,
        rightEnabled: this.publishEnabled,
        onBack: (): void => {
          this.confirmDiscard();
        },
        onRightClick: (): void => {
          this.submitComment();
        }
      })
      // ScrollView 白底 fillViewport（above bottom bar, below toolbar）
      Scroll() {
        TextArea({
          placeholder: '',
          text: this.inputContent
        })
          .fontSize(17)
          .fontColor($r('app.color.common_color_1'))
          .placeholderColor($r('app.color.common_color_4'))
          .maxLength(this.maxLength)
          .constraintSize({ minHeight: 132 })
          .margin(6)
          .backgroundColor(Color.Transparent)
          .onChange((value: string) => {
            // 源码 TextWatcher a.onTextChanged：trim 空 → 发布 disabled（g.setEnabled(false)）
            this.inputContent = value;
            this.publishEnabled = value.trim() !== '';
          })
      }
      .width('100%')
      .layoutWeight(1)
      .backgroundColor($r('app.color.white'))
      .align(Alignment.Top)

      // student_score_post_publish_bottom_bar：divider + 表情钮(padding 15/4, marginRight 20)
      Divider()
        .color($r('app.color.common_color_5'))
        .strokeWidth(0.5)
        .width('100%')
      Row() {
        Image(this.showEmojiPanel ? $r('app.media.school_edit_emotion_hover') : $r('app.media.school_edit_emotion'))
          .width(24)
          .height(24)
          .objectFit(ImageFit.Contain)
          .onClick(() => {
            this.toggleEmojiPanel();
          })
      }
      .width('100%')
      .padding({ left: 15, right: 15, top: 4, bottom: 4 })
      .alignItems(VerticalAlign.Center)
      .backgroundColor($r('app.color.white'))
      Divider()
        .color($r('app.color.common_color_5'))
        .strokeWidth(0.5)
        .width('100%')
      if (this.showEmojiPanel) {
        this.emojiPanel()
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.white'))
  }
}
