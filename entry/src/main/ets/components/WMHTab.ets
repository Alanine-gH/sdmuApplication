import { AddFormMenuItem, router, SymbolGlyphModifier } from '@kit.ArkUI';
import { BusinessError } from '@kit.BasicServicesKit';
import { common } from '@kit.AbilityKit';
import { formBindingData } from '@kit.FormKit';
import { ApiService } from '../network/ApiService';
import { ApiResponse } from '../model/ResponseModel';
import { ImmersiveLightHelper } from '../common/ImmersiveLightHelper';
import { WidgetDataHelper } from '../common/WidgetDataHelper';
import { BreakpointSystem } from '../common/BreakpointSystem';

/**
 * 微门户 Tab — 按 APK 实拍（学生账号登录后 getHomeTab/getList 下发结果）逐块复刻：
 *   1. 一卡通付款码行：白底，蓝色圆角图标 44vp + 标题 18fp #333333，行高 64vp，可点。
 *   2. 通知条（消息提醒横幅）：#F2F2F2 背景，喇叭图标 + 「【上课通知】您明天有课，请提前做好上课准备」
 *      15fp #333333 + 右侧红圆数字 1 + 灰色 >；点击跳消息列表（APK 源码依据：
 *      MessageRemindAdapter 监听器 WMHFragment$i0$/$h0 的 a()/b() 均 navigate e.a.B0 =
 *      strings mobile_campus_router_message_list_activity = /main/MessageListActivity）。
 *   3. 应用宫格：两列白卡（扫一扫 / 发票助手）——彩色圆底图标 + 名称 18fp + 副标题 14fp #999999。
 *   4. 本周/今日课表速览卡 + 原生 AddFormMenuItem 桌面卡片添加入口。
 */
@Component
export struct WMHTab {
  /** 通知条未读数（getTodoTabCount 下发，缺省 1） */
  @State noticeCount: number = 1;
  @State noticeText: string = '【上课通知】您明天有课，请提前做好上课准备';
  @StorageProp('currentBreakpoint') currentBreakpoint: string = 'sm';
  @StorageProp('heightBreakpoint') heightBreakpoint: string = 'lg';
  @StorageProp('isLandscape') isLandscape: boolean = false;
  @State todaySummary: string = '点击查看本周课表详情';
  @State payTrigger: number = -1;
  @State gridTriggers: number[] = [-1, -1, -1, -1];
  @State pinTrigger: number = -1;

  private useSideRail(): boolean {
    return BreakpointSystem.shouldUseSideRail(
      this.currentBreakpoint,
      this.heightBreakpoint,
      this.isLandscape
    );
  }

  private nextTrigger(val: number): number {
    return val < 0 ? 1 : val + 1;
  }

  private bumpGridTrigger(idx: number): void {
    const next: number[] = this.gridTriggers.slice();
    next[idx] = this.nextTrigger(next[idx]);
    this.gridTriggers = next;
  }

  private loadWidgetBindingData(): formBindingData.FormBindingData {
    try {
      const ctx = this.getUIContext().getHostContext() as common.UIAbilityContext;
      return formBindingData.createFormBindingData(WidgetDataHelper.loadFormData(ctx));
    } catch {
      return formBindingData.createFormBindingData(WidgetDataHelper.buildPayload('今日课表', []));
    }
  }

  aboutToAppear(): void {
    try {
      const ctx = this.getUIContext().getHostContext() as common.UIAbilityContext;
      const widgetData = WidgetDataHelper.loadFormData(ctx);
      const sub = widgetData['subtitle'];
      if (typeof sub === 'string' && sub !== '') {
        this.todaySummary = sub;
      }
    } catch {
      // 忽略本地课表缓存读取失败
    }
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
      .catch((_error: BusinessError) => {
        // 静默：与 APK 相同，通知条常显
      });
  }

  @Builder
  wmhWidgetMenu() {
    Menu() {
      AddFormMenuItem(
        WidgetDataHelper.buildScheduleWidgetWant(),
        'wmh_schedule_pin_anchor',
        {
          formBindingData: this.loadWidgetBindingData(),
          callback: (err: BusinessError, formId: string): void => {
            if (!err && formId) {
              this.getUIContext().getPromptAction().showToast({ message: '课表卡片已添加到桌面' });
            }
          },
          style: {
            options: {
              content: '添加课表卡片到桌面',
              symbolStartIcon: new SymbolGlyphModifier($r('sys.symbol.plus_square_on_square'))
            }
          }
        }
      )
      AddFormMenuItem(
        WidgetDataHelper.buildQuickEntryWidgetWant(),
        'wmh_schedule_pin_anchor',
        {
          formBindingData: this.loadWidgetBindingData(),
          callback: (err: BusinessError, formId: string): void => {
            if (!err && formId) {
              this.getUIContext().getPromptAction().showToast({ message: '快捷入口卡片已添加到桌面' });
            }
          },
          style: {
            options: {
              content: '添加快捷入口卡片',
              symbolStartIcon: new SymbolGlyphModifier($r('sys.symbol.pin'))
            }
          }
        }
      )
      MenuItem({ content: '查看添加引导' })
        .onClick(() => {
          router.pushUrl({ url: 'pages/AppWidgetGuidePage' });
        })
    }
  }

  /** 一卡通付款码行 */
  @Builder
  payCodeRow() {
    Row() {
      // 蓝色圆底图标（系统符号：银行卡 + 轻弹动效）
      Stack({ alignContent: Alignment.Center }) {
        SymbolGlyph($r('sys.symbol.creditcard'))
          .fontSize(22)
          .fontColor([$r('app.color.white')])
          .symbolEffect(new BounceSymbolEffect(EffectScope.WHOLE, EffectDirection.UP), this.payTrigger)
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
    .backgroundColor(ImmersiveLightHelper.fallbackBg($r('app.color.white')))
    .borderRadius(16)
    .systemMaterial(ImmersiveLightHelper.cardMaterial())
    .clickEffect({ level: ClickEffectLevel.LIGHT, scale: 0.97 })
    .onClick(() => {
      this.payTrigger = this.nextTrigger(this.payTrigger);
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
        .symbolEffect(new PulseSymbolEffect(), this.noticeCount > 0)
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
    .backgroundColor(ImmersiveLightHelper.fallbackBg($r('app.color.white')))
    .margin({ top: 10, bottom: 10 })
    .borderRadius(14)
    .systemMaterial(ImmersiveLightHelper.cardMaterial())
    .clickEffect({ level: ClickEffectLevel.LIGHT, scale: 0.98 })
    .onClick(() => {
      // APK MessageRemindAdapter：tvText(标题)/tvMore(更多>)/tvMessageCount(红点) 三处点击
      // 统一走 WMHFragment$i0 a()/b() → /main/MessageListActivity，即消息列表页。
      router.pushUrl({ url: 'pages/MessageListPage' });
    })
  }

  /** 宫格单元：彩色圆底图标 + 名称 + 副标题 */
  @Builder
  gridCell(iconBg: Resource, glyph: Resource, name: string, sub: string, target: string, cellIdx: number) {
    Column() {
      Stack({ alignContent: Alignment.Center }) {
        SymbolGlyph(glyph)
          .fontSize(26)
          .fontColor([$r('app.color.white')])
          .symbolEffect(
            new BounceSymbolEffect(EffectScope.WHOLE, EffectDirection.UP),
            this.gridTriggers[cellIdx]
          )
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
    .width('100%')
    .height(128)
    .justifyContent(FlexAlign.Center)
    .padding({ top: 16, bottom: 16 })
    .backgroundColor(ImmersiveLightHelper.fallbackBg($r('app.color.white')))
    .borderRadius(16)
    .systemMaterial(ImmersiveLightHelper.cardMaterial())
    .clickEffect({ level: ClickEffectLevel.LIGHT, scale: 0.96 })
    .onClick(() => {
      this.bumpGridTrigger(cellIdx);
      router.pushUrl({ url: target });
    })
  }

  build() {
    Column() {
      Scroll() {
        Column() {
          // 1. 一卡通付款码
          this.payCodeRow()

          // 2. 通知条
          this.noticeBar()

          // 3. 宫格入口：紧凑窄屏(xs/sm)为两张独立毛玻璃卡片，宽屏扩展为 4 列卡片
          if (BreakpointSystem.isCompactWidth(this.currentBreakpoint)) {
            Row({ space: 10 }) {
              Column() {
                this.gridCell($r('app.color.wmh_grid_scan_pink'), $r('sys.symbol.qrcode'),
                  '扫一扫', '扫码', 'pages/QrCodeScanPage', 0)
              }
              .layoutWeight(1)
              Column() {
                this.gridCell($r('app.color.blue_default'), $r('sys.symbol.doc_text'),
                  '发票助手', '轻松开发票', 'pages/ReceiptAssistPage', 1)
              }
              .layoutWeight(1)
            }
            .width('100%')
            .alignItems(VerticalAlign.Center)
          } else {
            GridRow({ columns: 4, gutter: { x: 12, y: 12 } }) {
              GridCol({ span: 1 }) {
                this.gridCell($r('app.color.wmh_grid_scan_pink'), $r('sys.symbol.qrcode'),
                  '扫一扫', '扫码', 'pages/QrCodeScanPage', 0)
              }
              GridCol({ span: 1 }) {
                this.gridCell($r('app.color.blue_default'), $r('sys.symbol.doc_text'),
                  '发票助手', '轻松开发票', 'pages/ReceiptAssistPage', 1)
              }
              GridCol({ span: 1 }) {
                this.gridCell($r('app.color.sdmu_primary'), $r('sys.symbol.calendar'),
                  '课程表', '学期课表', 'pages/SchedulePage', 2)
              }
              GridCol({ span: 1 }) {
                this.gridCell($r('app.color.common_color_12'), $r('sys.symbol.person_2'),
                  '通讯录', '校内联系', 'pages/ContactPage', 3)
              }
            }
            .width('100%')
          }

          // 4. 本周/今日课表速览卡（含原生 AddFormMenuItem 加桌入口）
          Row() {
            Column() {
              Text('本周与今日课表')
                .fontSize(16)
                .fontWeight(FontWeight.Bold)
                .fontColor($r('app.color.common_color_1'))
              Text(this.todaySummary)
                .fontSize(13)
                .fontColor($r('app.color.common_color_3'))
                .margin({ top: 6 })
            }
            .layoutWeight(1)
            .alignItems(HorizontalAlign.Start)

            Row({ space: 8 }) {
              Row({ space: 4 }) {
                SymbolGlyph($r('sys.symbol.pin'))
                  .fontSize(13)
                  .fontColor([$r('app.color.sdmu_primary')])
                  .symbolEffect(new BounceSymbolEffect(EffectScope.WHOLE, EffectDirection.UP), this.pinTrigger)
                Text('加桌面')
                  .fontSize(12)
                  .fontColor($r('app.color.sdmu_primary'))
              }
              .padding({ left: 10, right: 10, top: 5, bottom: 5 })
              .borderRadius(14)
              .backgroundColor('#FDECEE')
              .bindMenu(this.wmhWidgetMenu())
              .onClick(() => {
                this.pinTrigger = this.nextTrigger(this.pinTrigger);
              })

              Text('查看课表 ＞')
                .fontSize(14)
                .fontColor($r('app.color.sdmu_primary'))
            }
            .alignItems(VerticalAlign.Center)
          }
          .id('wmh_schedule_pin_anchor')
          .width('100%')
          .padding(16)
          .margin({ top: 12 })
          .borderRadius(16)
          .backgroundColor(ImmersiveLightHelper.fallbackBg($r('app.color.white')))
          .systemMaterial(ImmersiveLightHelper.cardMaterial())
          .clickEffect({ level: ClickEffectLevel.LIGHT, scale: 0.98 })
          .bindContextMenu(this.wmhWidgetMenu(), ResponseType.LongPress)
          .onClick(() => {
            router.pushUrl({ url: 'pages/SchedulePage' });
          })
        }
        .width('100%')
        .padding({ left: 12, right: 12, top: 10, bottom: this.useSideRail() ? 16 : 92 })
      }
      .scrollable(ScrollDirection.Vertical)
      .width('100%')
      .height('100%')
      .backgroundColor('#EEF1F6')
      .align(Alignment.Top)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#EEF1F6')
  }
}
