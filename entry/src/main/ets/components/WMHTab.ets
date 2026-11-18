import { router } from '@kit.ArkUI';
import { BusinessError } from '@kit.BasicServicesKit';
import { ApiService } from '../network/ApiService';
import { ApiResponse } from '../model/ResponseModel';
import { TodoItem } from '../model/TodoModel';

/**
 * 微门户 Tab — 按 APK 实拍（学生账号登录后 getHomeTab/getList 下发结果）逐块复刻：
 *   1. 一卡通付款码行：白底，蓝色圆角图标 44vp + 标题 18fp #333333，行高 64vp，可点。
 *   2. 通知条（消息提醒横幅）：#F2F2F2 背景，喇叭图标 + 「【上课通知】您明天有课，请提前做好上课准备」
 *      15fp #333333 + 右侧红圆数字 1 + 灰色 >；点击跳消息列表（APK 源码依据：
 *      MessageRemindAdapter 监听器 WMHFragment$i0$/$h0 的 a()/b() 均 navigate e.a.B0 =
 *      strings mobile_campus_router_message_list_activity = /main/MessageListActivity）。
 *   3. 应用宫格：两列白卡（扫一扫 / 发票助手）——彩色圆底图标 + 名称 18fp + 副标题 14fp #999999。
 *   4. 其余区域 #F2F2F2 空白（与 APK 服务端未下发其他模块时的表现一致）。
 */
@Component
export struct WMHTab {
  /** 通知条未读数（getTodoTabCount 下发，缺省 1） */
  @State noticeCount: number = 1;
  @State noticeText: string = '【上课通知】您明天有课，请提前做好上课准备';

  aboutToAppear(): void {
    // 拉取待办数填通知红点；失败保持 APK 同款缺省文案
    ApiService.getTodoTabCount('')
      .then((response: ApiResponse<Object>) => {
        if (ApiService.isSuccess(response)) {
          const rec: Record<string, Object> = response.data as Record<string, Object>;
          const v: Object = rec['count'];
          if (typeof v === 'number' && (v as number) > 0) {
            this.noticeCount = v as number;
          }
        }
      })
      .catch((error: BusinessError) => {
        // 静默：与 APK 相同，通知条常显
      });
  }

  /** 一卡通付款码行 */
  @Builder
  payCodeRow() {
    Row() {
      // 蓝色圆底图标（系统符号：银行卡）
      Stack({ alignContent: Alignment.Center }) {
        SymbolGlyph($r('sys.symbol.creditcard'))
          .fontSize(22)
          .fontColor([$r('app.color.white')])
      }
      .width(44)
      .height(44)
      .borderRadius(22)
      .backgroundColor($r('app.color.blue_default'))

      Text('一卡通付款码')
        .fontSize(18)
        .fontColor($r('app.color.common_color_1'))
        .margin({ left: 16 })
        .layoutWeight(1)
    }
    .width('100%')
    .height(64)
    .padding({ left: 16, right: 16 })
    .alignItems(VerticalAlign.Center)
    .backgroundColor($r('app.color.white'))
    .onClick(() => {
      router.pushUrl({ url: 'pages/LightAppPage' });
    })
  }

  /** 通知条 */
  @Builder
  noticeBar() {
    Row() {
      SymbolGlyph($r('sys.symbol.speaker_wave_2_fill'))
        .fontSize(20)
        .fontColor([$r('app.color.common_color_2')])
      Text(this.noticeText)
        .fontSize(15)
        .fontColor($r('app.color.common_color_1'))
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .margin({ left: 8 })
        .layoutWeight(1)
      if (this.noticeCount > 0) {
        Text(this.noticeCount.toString())
          .fontSize(12)
          .fontColor($r('app.color.white'))
          .textAlign(TextAlign.Center)
          .width(20)
          .height(20)
          .borderRadius(10)
          .backgroundColor($r('app.color.main_notice_badge_red'))
          .margin({ right: 6 })
      }
      Text('＞')
        .fontSize(14)
        .fontColor($r('app.color.common_color_3'))
    }
    .width('100%')
    .height(46)
    .padding({ left: 16, right: 12 })
    .alignItems(VerticalAlign.Center)
    .backgroundColor($r('app.color.common_color_6'))
    .margin({ top: 9, bottom: 9 })
    .onClick(() => {
      // APK MessageRemindAdapter：tvText(标题)/tvMore(更多>)/tvMessageCount(红点) 三处点击
      // 统一走 WMHFragment$i0 a()/b() → /main/MessageListActivity，即消息列表页。
      router.pushUrl({ url: 'pages/MessageListPage' });
    })
  }

  /** 宫格单元：彩色圆底图标 + 名称 + 副标题 */
  @Builder
  gridCell(iconBg: Resource, glyph: Resource, name: string, sub: string, target: string) {
    Column() {
      Stack({ alignContent: Alignment.Center }) {
        SymbolGlyph(glyph)
          .fontSize(26)
          .fontColor([$r('app.color.white')])
      }
      .width(52)
      .height(52)
      .borderRadius(26)
      .backgroundColor(iconBg)

      Text(name)
        .fontSize(18)
        .fontColor($r('app.color.common_color_1'))
        .margin({ top: 10 })
      Text(sub)
        .fontSize(14)
        .fontColor($r('app.color.common_color_3'))
        .margin({ top: 4 })
    }
    .layoutWeight(1)
    .padding({ top: 24, bottom: 20 })
    .backgroundColor($r('app.color.white'))
    .onClick(() => {
      router.pushUrl({ url: target });
    })
  }

  build() {
    Column() {
      Scroll() {
        Column() {
          // 1. 一卡通付款码
          this.payCodeRow()

          // 2. 通知条（灰底，与上一行间有灰缝）
          this.noticeBar()

          // 3. 两列宫格：扫一扫 | 发票助手
          Row() {
            this.gridCell($r('app.color.wmh_grid_scan_pink'), $r('sys.symbol.qrcode'),
              '扫一扫', '扫码', 'pages/QrCodeScanPage')
            Divider()
              .vertical(true)
              .strokeWidth(1)
              .height(120)
              .color($r('app.color.common_color_6'))
            this.gridCell($r('app.color.blue_default'), $r('sys.symbol.doc_text'),
              '发票助手', '轻松开发票', 'pages/ReceiptAssistPage')
          }
          .width('100%')
          .alignItems(VerticalAlign.Center)
          .backgroundColor($r('app.color.white'))
        }
        .width('100%')
      }
      .scrollable(ScrollDirection.Vertical)
      .width('100%')
      .height('100%')
      .backgroundColor($r('app.color.common_color_6'))
      .align(Alignment.Top)
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.common_color_6'))
  }
}
