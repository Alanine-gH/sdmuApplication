import { router } from '@kit.ArkUI';
import { BusinessError } from '@kit.BasicServicesKit';
import { ApiService } from '../network/ApiService';
import { ApiResponse } from '../model/ResponseModel';
import { SuperviseListenRecord } from '../model/SuperviseModel';
import { EmptyView } from '../components/EmptyView';
import { LoadingView } from '../components/LoadingView';
import { BreakpointSystem } from '../common/BreakpointSystem';

/**
 * 我的听课页 — 源码级翻译 [W21 supervise]（SuperviseMineActivity.java + 两 Fragment 逐行 → ArkTS）：
 *
 * 【布局】mobile_campus_supervise_activity_supervise_mine.xml：竖排
 *   toolbar：标题"我的听课"（T1: gVar.n("我的听课")）
 *   TabLayout（48dip 白底，indicator 2dip #1B68B7，fixed center）：
 *     a.f15253a = {"待听课", "已过期"}（顺序源码 1:1；选中 #1B68B7 / 未选 common_color_3）
 *   ViewPager：SuperviseMineListenFragment（tab0）/ SuperviseMinePastListFragment（tab1）
 *
 * 【tab0 待听课】SuperviseMineListenFragment.Q1 → SuperviseModel.Z0：GET getNotListening → NotListening[]
 *   行 mobile_campus_supervise_view_mine.xml：横排 padV8；tvDate=LISTENTIME 17sp#1B68B7 宽106 padL12；
 *   右列（内容高 111.5）：tvTitle=KCMC 17sp、tvTeacher=SKLSXM 13sp mt15（teacher 图标 pad8）、
 *   tvLocation=SKDD 13sp mt16（location 图标）、tvTime="周XQJ 第DJJ节" 13sp mt16（time 图标）；灰细线
 *   b.onItemClick → bundle{xlh} → /supervise/ongoing（K0）= SuperviseComingPage
 * 【tab1 已过期】SuperviseMinePastListFragment.R1 → SuperviseModel.a1：GET getStaleListening → StaleListening[]
 *   行 mobile_campus_supervise_view_mine_past.xml（高 112）：同上右列 + tvComment（80x32 圆角4
 *   selector_mine：enabled 蓝描边 / disabled 灰描边；selector_mine 色：enabled #1B68B7 / disabled #999999）；
 *   ISEVALUATE=="0" → "评价" enabled → d.a → bundle{xlh} → /supervise/evaluate（L0）
 *   requestCode 120，onActivityResult RESULT_OK → R1() 重拉两列表；否则 "已评价" disabled
 *   b.onItemClick → bundle{xlh} → /supervise/finished（J0）= SuperviseFinishedPage
 * 【回传】评价提交成功（SuperviseEvaluatePage）→ AppStorage 'supervise_evaluate_done' →
 *   onPageShow 消费并重拉（onActivityResult 120 RESULT_OK 等价管道）。
 * 2026-11-18 probe_w21_supervise.py：getNotListening/getStaleListening 均 code=0 空数组 → 真实空态。
 */

@Entry
@Component
struct SuperviseMinePage {
  @State selectedTabIndex: number = 0;
  /** tab0 待听课（SuperviseMineAdapter.data） */
  @State futureRecords: SuperviseListenRecord[] = [];
  /** tab1 已过期（SuperviseMinePastAdapter.data） */
  @State pastRecords: SuperviseListenRecord[] = [];
  @State isLoadingListen: boolean = true;
  @State isLoadingPast: boolean = true;
  @StorageProp('currentBreakpoint') currentBreakpoint: string = 'sm';
  @StorageProp('avoidAreaBottomVp') avoidAreaBottomVp: number = 0;
  @StorageProp('avoidAreaLeftVp') avoidAreaLeftVp: number = 0;
  @StorageProp('avoidAreaRightVp') avoidAreaRightVp: number = 0;
  private static readonly EVALUATE_DONE_KEY: string = 'supervise_evaluate_done';

  aboutToAppear(): void {
    // 源码两 Fragment f1() 各自独立拉取
    this.loadNotListening();
    this.loadStaleListening();
  }

  onPageShow(): void {
    // 源码 MineActivity.onActivityResult(120, RESULT_OK) → 两 Fragment 重拉
    const done: string | undefined = AppStorage.get<string>(SuperviseMinePage.EVALUATE_DONE_KEY);
    if (done !== undefined && done === '1') {
      AppStorage.setOrCreate<string>(SuperviseMinePage.EVALUATE_DONE_KEY, '');
      this.loadNotListening();
      this.loadStaleListening();
    }
  }

  /** 源码 SuperviseMineListenFragment.Q1 → d.a.v(...).o()：GET getNotListening */
  private loadNotListening(): void {
    this.isLoadingListen = true;
    ApiService.getSuperviseNotListening()
      .then((response: ApiResponse<SuperviseListenRecord[]>) => {
        if (response.code !== 0) {
          ApiService.logError('SuperviseMinePage notListening degrade: code=' + response.code +
            ' msg=' + response.message);
        }
        this.futureRecords = response.data;
        this.isLoadingListen = false;
      })
      .catch((error: BusinessError) => {
        ApiService.logError('SuperviseMinePage notListening fail: ' + error.message);
        this.futureRecords = [];
        this.isLoadingListen = false;
      });
  }

  /** 源码 SuperviseMinePastListFragment.R1 → d.a.x(...).p()：GET getStaleListening */
  private loadStaleListening(): void {
    this.isLoadingPast = true;
    ApiService.getSuperviseStaleListening()
      .then((response: ApiResponse<SuperviseListenRecord[]>) => {
        if (response.code !== 0) {
          ApiService.logError('SuperviseMinePage staleListening degrade: code=' + response.code +
            ' msg=' + response.message);
        }
        this.pastRecords = response.data;
        this.isLoadingPast = false;
      })
      .catch((error: BusinessError) => {
        ApiService.logError('SuperviseMinePage staleListening fail: ' + error.message);
        this.pastRecords = [];
        this.isLoadingPast = false;
      });
  }

  /** 源码 SuperviseMineAdapter.getView tvTime："周XQJ 第DJJ节" */
  private timeText(record: SuperviseListenRecord): string {
    return '周' + record.XQJ + ' 第' + record.DJJ + '节';
  }

  build() {
    Column() {
      // toolbar_normal.xml："我的听课"
      Column() {
        Row() {
          Text('＜')
            .fontSize(16)
            .fontColor($r('app.color.common_color_1'))
            .width(40)
            .height('100%')
            .textAlign(TextAlign.Center)
            .margin({ left: 15 })
            .onClick(() => {
              router.back();
            })
          Text('我的听课')
            .fontSize(17)
            .fontColor($r('app.color.ybg_blue'))
            .layoutWeight(1)
            .textAlign(TextAlign.Center)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
          Blank()
            .width(55)
        }
        .width('100%')
        .height(44)
        .padding({ left: this.avoidAreaLeftVp, right: this.avoidAreaRightVp })
        .constraintSize({ maxWidth: BreakpointSystem.getContentMaxWidth(this.currentBreakpoint) })
        .alignSelf(ItemAlign.Center)
        .alignItems(VerticalAlign.Center)

        Divider()
          .color($r('app.color.common_color_5'))
          .strokeWidth(0.5)
          .width('100%')
      }
      .width('100%')
      .backgroundColor($r('app.color.main_bg'))
      .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP])

      // TabLayout：48dip 白底 indicator 2dip #1B68B7；a.f15253a 待听课/已过期
      Column() {
        Row() {
          Column() {
            Text('待听课')
              .fontSize(15)
              .fontColor(this.selectedTabIndex === 0 ? '#1B68B7' : $r('app.color.common_color_3'))
              .layoutWeight(1)
              .textAlign(TextAlign.Center)
            Divider()
              .color(this.selectedTabIndex === 0 ? '#1B68B7' : Color.Transparent)
              .strokeWidth(2)
              .width('100%')
          }
          .layoutWeight(1)
          .height(46)
          .justifyContent(FlexAlign.Center)
          .onClick(() => {
            this.selectedTabIndex = 0;
          })

          Column() {
            Text('已过期')
              .fontSize(15)
              .fontColor(this.selectedTabIndex === 1 ? '#1B68B7' : $r('app.color.common_color_3'))
              .layoutWeight(1)
              .textAlign(TextAlign.Center)
            Divider()
              .color(this.selectedTabIndex === 1 ? '#1B68B7' : Color.Transparent)
              .strokeWidth(2)
              .width('100%')
          }
          .layoutWeight(1)
          .height(46)
          .justifyContent(FlexAlign.Center)
          .onClick(() => {
            this.selectedTabIndex = 1;
          })
        }
        .width('100%')
        .height(48)
        .padding({ left: this.avoidAreaLeftVp, right: this.avoidAreaRightVp })
        .constraintSize({ maxWidth: BreakpointSystem.getContentMaxWidth(this.currentBreakpoint) })
        .alignSelf(ItemAlign.Center)
        .alignItems(VerticalAlign.Center)
        .backgroundColor($r('app.color.white'))

        Divider()
          .color($r('app.color.common_color_5'))
          .strokeWidth(0.5)
          .width('100%')
      }
      .width('100%')
      .backgroundColor($r('app.color.white'))

      // ViewPager：tab0 待听课 / tab1 已过期（失败/空 → 空态，不展示编造记录）
      if (this.selectedTabIndex === 0) {
        this.listenList()
      } else {
        this.pastList()
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.common_color_6'))
  }

  /** tab0：mobile_campus_supervise_view_mine.xml 行（padV8，内容高 111.5） */
  @Builder
  listenList() {
    if (this.isLoadingListen) {
      LoadingView()
    } else if (this.futureRecords.length === 0) {
      EmptyView()
    } else {
      List({ space: 0 }) {
        ForEach(this.futureRecords, (record: SuperviseListenRecord) => {
          ListItem() {
            this.listenRow(record)
          }
        }, (record: SuperviseListenRecord) => record.XLH + '_' + record.KCMC)
      }
      .width('100%')
      .constraintSize({ maxWidth: BreakpointSystem.getContentMaxWidth(this.currentBreakpoint) })
      .alignSelf(ItemAlign.Center)
      .padding({ left: this.avoidAreaLeftVp, right: this.avoidAreaRightVp })
      .contentEndOffset(this.avoidAreaBottomVp)
      .layoutWeight(1)
      .scrollBar(BarState.Off)
      .backgroundColor($r('app.color.common_color_6'))
    }
  }

  @Builder
  listenRow(record: SuperviseListenRecord) {
    Column() {
      Row() {
        Text(record.LISTENTIME)
          .fontSize(17)
          .fontColor('#1B68B7')
          .width(106)
          .padding({ left: 12 })
          .height('100%')
          .textAlign(TextAlign.Start)
        Column() {
          Column() {
            Text(record.KCMC)
              .fontSize(17)
              .fontColor($r('app.color.common_color_1'))
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
            Row() {
              Image($r('app.media.mobile_campus_supervise_teacher'))
                .width(12)
                .height(12)
                .margin({ right: 8 })
              Text(record.SKLSXM)
                .fontSize(13)
                .fontColor($r('app.color.common_color_3'))
                .maxLines(1)
            }
            .margin({ top: 15 })
            .alignItems(VerticalAlign.Center)

            Row() {
              Image($r('app.media.mobile_campus_supervise_location'))
                .width(12)
                .height(12)
                .margin({ right: 8 })
              Text(record.SKDD)
                .fontSize(13)
                .fontColor($r('app.color.common_color_3'))
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
            }
            .margin({ top: 8 })
            .alignItems(VerticalAlign.Center)

            Row() {
              Image($r('app.media.mobile_campus_supervise_time'))
                .width(16)
                .height(16)
                .margin({ right: 8 })
              Text(this.timeText(record))
                .fontSize(13)
                .fontColor($r('app.color.common_color_3'))
            }
            .margin({ top: 8 })
            .alignItems(VerticalAlign.Center)
          }
          .height(111.5)
          .layoutWeight(1)
          .alignItems(HorizontalAlign.Start)
          .justifyContent(FlexAlign.Center)

          Divider()
            .color($r('app.color.common_color_5'))
            .strokeWidth(0.5)
            .width('100%')
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)
      }
      .width('100%')
      .padding({ top: 8, bottom: 8 })
      .alignItems(VerticalAlign.Center)
      .backgroundColor($r('app.color.white'))
      // 源码 b.onItemClick：bundle{xlh=NotListening.XLH} → /supervise/ongoing（K0）
      .onClick(() => {
        router.pushUrl({ url: 'pages/SuperviseComingPage',
          params: { 'xlh': record.XLH } as Record<string, string> });
      })
    }
    .width('100%')
  }

  /** tab1：mobile_campus_supervise_view_mine_past.xml 行（高 112 + 右侧评价钮） */
  @Builder
  pastList() {
    if (this.isLoadingPast) {
      LoadingView()
    } else if (this.pastRecords.length === 0) {
      EmptyView()
    } else {
      List({ space: 0 }) {
        ForEach(this.pastRecords, (record: SuperviseListenRecord) => {
          ListItem() {
            this.pastRow(record)
          }
        }, (record: SuperviseListenRecord) => record.XLH + '_' + record.KCMC)
      }
      .width('100%')
      .constraintSize({ maxWidth: BreakpointSystem.getContentMaxWidth(this.currentBreakpoint) })
      .alignSelf(ItemAlign.Center)
      .padding({ left: this.avoidAreaLeftVp, right: this.avoidAreaRightVp })
      .contentEndOffset(this.avoidAreaBottomVp)
      .layoutWeight(1)
      .scrollBar(BarState.Off)
      .backgroundColor($r('app.color.common_color_6'))
    }
  }

  @Builder
  pastRow(record: SuperviseListenRecord) {
    Column() {
      Row() {
        Text(record.LISTENTIME)
          .fontSize(17)
          .fontColor('#1B68B7')
          .width(106)
          .padding({ left: 12 })
          .height('100%')
          .textAlign(TextAlign.Start)
        Column() {
          Row() {
            Column() {
              Text(record.KCMC)
                .fontSize(17)
                .fontColor($r('app.color.common_color_1'))
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
              Row() {
                Image($r('app.media.mobile_campus_supervise_teacher'))
                  .width(12)
                  .height(12)
                  .margin({ right: 8 })
                Text(record.SKLSXM)
                  .fontSize(13)
                  .fontColor($r('app.color.common_color_3'))
                  .maxLines(1)
              }
              .margin({ top: 15 })
              .alignItems(VerticalAlign.Center)

              Row() {
                Image($r('app.media.mobile_campus_supervise_location'))
                  .width(12)
                  .height(12)
                  .margin({ right: 8 })
                Text(record.SKDD)
                  .fontSize(13)
                  .fontColor($r('app.color.common_color_3'))
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
              }
              .margin({ top: 8 })
              .alignItems(VerticalAlign.Center)

              Row() {
                Image($r('app.media.mobile_campus_supervise_time'))
                  .width(16)
                  .height(16)
                  .margin({ right: 8 })
                Text(this.timeText(record))
                  .fontSize(13)
                  .fontColor($r('app.color.common_color_3'))
              }
              .margin({ top: 8 })
              .alignItems(VerticalAlign.Center)
            }
            .height(111.5)
            .layoutWeight(1)
            .alignItems(HorizontalAlign.Start)
            .justifyContent(FlexAlign.Center)

            // tvComment：selector_mine 双态（ISEVALUATE=="0" → 评价 enabled / 已评价 disabled）
            Text(record.ISEVALUATE === '0' ? '评价' : '已评价')
              .fontSize(14)
              .fontColor(record.ISEVALUATE === '0' ? '#1B68B7' : '#999999')
              .width(80)
              .height(32)
              .textAlign(TextAlign.Center)
              .borderRadius(4)
              .border({
                width: 1,
                color: record.ISEVALUATE === '0' ? '#1B68B7' : '#999999'
              })
              .margin({ right: 12 })
              .onClick(() => {
                if (record.ISEVALUATE === '0') {
                  // 源码 d.a：bundle{xlh} → /supervise/evaluate（L0）requestCode 120 → RESULT_OK 重拉
                  router.pushUrl({ url: 'pages/SuperviseEvaluatePage',
                    params: { 'xlh': record.XLH } as Record<string, string> });
                }
              })
          }
          .width('100%')
          .alignItems(VerticalAlign.Center)

          Divider()
            .color($r('app.color.common_color_5'))
            .strokeWidth(0.5)
            .width('100%')
        }
        .layoutWeight(1)
        .height(112)
        .alignItems(HorizontalAlign.Start)
      }
      .width('100%')
      .height(112)
      .alignItems(VerticalAlign.Center)
      .backgroundColor($r('app.color.white'))
      // 源码 b.onItemClick：bundle{xlh=StaleListening.XLH} → /supervise/finished（J0）
      .onClick(() => {
        router.pushUrl({ url: 'pages/SuperviseFinishedPage',
          params: { 'xlh': record.XLH } as Record<string, string> });
      })
    }
    .width('100%')
  }
}
