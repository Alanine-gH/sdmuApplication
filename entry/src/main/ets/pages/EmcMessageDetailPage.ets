import { router } from '@kit.ArkUI';
import { BusinessError } from '@kit.BasicServicesKit';
import { promptAction } from '@kit.ArkUI';
import { ApiService } from '../network/ApiService';
import { ApiResponse } from '../model/ResponseModel';
import { TitleBar } from '../components/TitleBar';
import { EmptyView } from '../components/EmptyView';
import { LoadingView } from '../components/LoadingView';

/**
 * 消息详情页 — 1:1 翻译 EmcMessageDetailActivity.java（main/view，layout
 * mobile_campus_activity_emc_message_detail.xml，路由 /main/notification_detail）。
 *
 * 【入参】y(Intent) 读 bundle：xlh / channelCode / title / CONTENT / SENDTIME / SENDBY。
 *   MessageListPage.openDetail / LX=16 分支已带参跳入（MessageNavParams 同键）。
 * 【f1 分支】CONTENT 非空 → 直接内容态：tvTitle=title、tvContent=CONTENT、
 *   tvSendBy 空→隐藏否则"发布人员："+SENDBY、tvTime 空→隐藏否则"发布日期："+SENDTIME。
 *   CONTENT 空（EMC 推送无正文）→ MessageDetailPImpl.T0 拉 EmcMessageContent {magId:xlh, channelCode}
 *   （j=false 明文 GET，2026-11-18 探针 code=0 data=明文正文串）：
 *   成功 g() → 内容态 + tvContent=正文 + tvTitle 隐藏（源码 o.setVisibility(8)）；
 *   业务失败 f() → 空态 + toast"获取消息详情出错 , 请稍后再试"；异常 e() → 错误态（重试=重新拉取）。
 * 【样式】标题 20fp bold #333333 marginT/B24、时间/发布人 13fp #999999（tvSendBy marginTop16）、
 *   分隔线 #f2f2f2 1vp marginTop20、正文 17fp #333333 padT/B24 行距 8、容器白底 padH16。
 */

/** 路由参数（= EmcMessageDetailActivity.y(Intent) 的 bundle key，MessageListPage.MessageNavParams 同键） */
interface EmcNavParams {
  channelCode: string;
  xlh: string;
  title: string;
  sendTime: string;
  content: string;
  sendBy: string;
}

@Entry
@Component
struct EmcMessageDetailPage {
  /** MultiStateView 三态：loading / content / empty / error（u2=error、q2=empty、v=content） */
  @State viewState: string = 'loading';
  @State titleText: string = '';
  @State contentText: string = '';
  @State timeText: string = '';
  @State sendByText: string = '';
  /** 网络分支成功后 tvTitle 隐藏（源码 o.setVisibility(8)） */
  @State titleVisible: boolean = true;
  @State xlh: string = '';
  @State channelCode: string = '';

  aboutToAppear(): void {
    const params = router.getParams() as Record<string, Object>;
    if (params !== null && params !== undefined) {
      const xlhVal: Object = params['xlh'];
      if (typeof xlhVal === 'string') {
        this.xlh = xlhVal as string;
      }
      const chVal: Object = params['channelCode'];
      if (typeof chVal === 'string') {
        this.channelCode = chVal as string;
      }
      const titleVal: Object = params['title'];
      if (typeof titleVal === 'string') {
        this.titleText = titleVal as string;
      }
      const timeVal: Object = params['sendTime'];
      if (typeof timeVal === 'string') {
        this.timeText = timeVal as string;
      }
      const sendByVal: Object = params['sendBy'];
      if (typeof sendByVal === 'string') {
        this.sendByText = sendByVal as string;
      }
      const contentVal: Object = params['content'];
      if (typeof contentVal === 'string') {
        this.contentText = contentVal as string;
      }
    }
    // 源码 f1()：TextUtils.isEmpty(CONTENT) → 走网络详情；否则直接内容态
    if (this.contentText === '') {
      this.fetchDetail();
    } else {
      this.viewState = 'content';
    }
  }

  /** 源码 L2()：MessageDetailPImpl.T0 → g/d/e.b("EmcMessageContent") {magId, channelCode}，j=false */
  private fetchDetail(): void {
    this.viewState = 'loading';
    ApiService.getEmcMessageContent(this.xlh, this.channelCode)
      .then((response: ApiResponse<Object>) => {
        if (response.code === 1000) {
          return;
        }
        if (response.code !== 0) {
          // 源码 a.f()：q2(l) 空态 + m("获取消息详情出错 , 请稍后再试")
          this.viewState = 'empty';
          promptAction.showToast({ message: '获取消息详情出错 , 请稍后再试' });
          return;
        }
        // 源码 a.g()：v(l) 内容态 + p.setText(str4) + o.setVisibility(8)
        const data = response.data;
        this.contentText = typeof data === 'string' ? data as string : '';
        this.titleVisible = false;
        this.viewState = 'content';
      })
      .catch((error: BusinessError) => {
        // 源码 a.e()：u2(l) 错误态
        ApiService.logError('Emc detail fail: ' + error.message);
        this.viewState = 'error';
      });
  }

  build() {
    Column() {
      TitleBar({ title: '消息详情' })
      // MultiStateView marginTop = px_to_dip_24 / 2 = 12vp；内容容器 white
      Column() {
        if (this.viewState === 'loading') {
          LoadingView()
        } else if (this.viewState === 'empty') {
          EmptyView({ tipText: '暂无内容' })
        } else if (this.viewState === 'error') {
          // error_view：mobile_campus_page_error + "重试"（primary 底白字，重试=重新拉详情）
          Column() {
            Image($r('app.media.icon_message_error'))
              .width(96)
              .height(96)
              .objectFit(ImageFit.Contain)
            Text('重试')
              .fontSize(15)
              .fontColor($r('app.color.white'))
              .textAlign(TextAlign.Center)
              .padding({ left: 17, right: 17, top: 3, bottom: 3 })
              .backgroundColor($r('app.color.blue_default'))
              .margin({ top: 16 })
              .onClick(() => {
                this.fetchDetail();
              })
          }
          .width('100%')
          .height('100%')
          .justifyContent(FlexAlign.Center)
        } else {
          // NestedScrollView → LinearLayout(ybg_white padL/R=px32/2=16vp)
          Scroll() {
            Column() {
              // tvTitle：20fp bold #333333 marginT/B=24dip（源码原始 dip 值）
              if (this.titleVisible) {
                Text(this.titleText)
                  .fontSize(20)
                  .fontWeight(FontWeight.Bold)
                  .fontColor('#333333')
                  .width('100%')
                  .margin({ top: 24, bottom: 24 })
              }
              // tvTime：13fp #999999，SENDTIME 空 → gone
              if (this.timeText !== '') {
                Text('发布日期：' + this.timeText)
                  .fontSize(13)
                  .fontColor('#999999')
                  .width('100%')
              }
              // tvSendBy：13fp #999999 marginTop=px32/2=16vp，SENDBY 空 → gone
              if (this.sendByText !== '') {
                Text('发布人员：' + this.sendByText)
                  .fontSize(13)
                  .fontColor('#999999')
                  .width('100%')
                  .margin({ top: 16 })
              }
              // 分隔线 #f2f2f2 1dip marginTop=px40/2=20vp
              Divider()
                .color('#F2F2F2')
                .strokeWidth(1)
                .margin({ top: 20 })
              // tvContent：17fp #333333 padT/B=24dip 行距 8dip
              Text(this.contentText)
                .fontSize(17)
                .fontColor('#333333')
                .lineHeight(25)
                .width('100%')
                .padding({ top: 24, bottom: 24 })
            }
            .width('100%')
            .backgroundColor($r('app.color.white'))
            .padding({ left: 16, right: 16 })
          }
          .width('100%')
          .height('100%')
          .scrollBar(BarState.Off)
          .align(Alignment.Top)
        }
      }
      .width('100%')
      .layoutWeight(1)
      .margin({ top: 12 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.white'))
  }
}
