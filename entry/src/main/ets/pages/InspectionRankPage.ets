import { router } from '@kit.ArkUI';
import { BusinessError } from '@kit.BasicServicesKit';
import { TitleBar } from '../components/TitleBar';
import { EmptyView } from '../components/EmptyView';
import { LoadingView } from '../components/LoadingView';
import { ApiService } from '../network/ApiService';
import { ApiResponse } from '../model/ResponseModel';
import { NewHadScore } from '../model/ScoreModel';

/**
 * 巡检排名 — NewInspectionRankListActivity + InspectionRankListActivity + InspectionRankAdapter
 * 源码级翻译（inspection/view）。
 *
 * 【入口】InspectionActivity 底部 rlMore"查看已评分寝室" → inspection_rank_list {XLH, ldmc}
 *   （InspectionPage.gotoRank 已接）。
 * 【布局】new_inspection_activity_recordlist：toolbar_normal（T1"寝室评分列表"）
 *   + 10vp common_color_6 灰条 + common_refresh_lv_rl（MultiStateView + PullToRefresh +
 *   ListView，divider null，bg #F2F2F2，PullUpToLoad 禁用）。
 * 【行】inspection_item_commented_record：白底高 45vp paddingH 15vp：
 *   排名圆 24vp（前 3 名 #F6C744，其余 #B4B4B4）+ 白字 12fp；寝室名 QSH+"寝室" 16fp #333333；
 *   BaseRatingBar numStars=5 starSize=15 starPadding=8 touchable=false；分数 SCORE+"分" 16fp #FFD11F。
 * 【数据】InspectionModel.a1（InspectionPImpl.h）：POST getHadScoreList {recordXlh,ldmc} → NewHadScore[]
 *   （实测 code=0 空表）。点击行 → NewAddRecordActivity{comment_state:true,recorddetailxlh,dormitory_name}
 *   （HAP 未翻译 → 无跳转保真）。
 */
@Entry
@Component
struct InspectionRankPage {
  @State list: NewHadScore[] = [];
  @State isLoading: boolean = true;
  @State errorText: string = '';
  private recordXlh: string = '';
  private ldmc: string = '';

  aboutToAppear(): void {
    const params: Record<string, Object> | undefined = router.getParams() as Record<string, Object> | undefined;
    if (params !== undefined && params !== null) {
      const xlh: Object = params['XLH'];
      const floor: Object = params['ldmc'];
      this.recordXlh = typeof xlh === 'string' ? xlh as string : '';
      this.ldmc = typeof floor === 'string' ? floor as string : '';
    }
    this.loadList();
  }

  /** 源码 P2(recordXlh,ldmc) → InspectionPImpl.h → getHadScoreList */
  private loadList(): void {
    this.isLoading = true;
    this.errorText = '';
    ApiService.getInspectionRankList(this.recordXlh, this.ldmc)
      .then((response: ApiResponse<NewHadScore[]>) => {
        if (response.code === 1000) {
          return;
        }
        if (response.code === 0) {
          this.list = response.data;
        } else {
          this.list = [];
          this.errorText = response.message;
        }
        this.isLoading = false;
      })
      .catch((error: BusinessError) => {
        ApiService.logError('getHadScoreList fail: ' + error.message);
        this.list = [];
        this.errorText = '网络异常，请稍后重试';
        this.isLoading = false;
      });
  }

  private scoreValue(item: NewHadScore): number {
    const n: number = Number(item.SCORE);
    return Number.isNaN(n) ? 0 : n;
  }

  @Builder
  starRow(item: NewHadScore) {
    Row() {
      ForEach([0, 1, 2, 3, 4], (index: number) => {
        Text('★')
          .fontSize(15)
          .fontColor(index < this.scoreValue(item) ? '#FFD11F' : '#CECECE')
          .margin({ right: 8 })
      }, (index: number) => 'star_' + index)
    }
    .layoutWeight(1)
    .justifyContent(FlexAlign.End)
  }

  @Builder
  rankRow(item: NewHadScore) {
    Column() {
      Row() {
        Stack() {
          Circle()
            .width(24)
            .height(24)
            .fill(item.RANKNUM > 0 && item.RANKNUM <= 3 ? '#F6C744' : '#B4B4B4')
          Text(String(item.RANKNUM))
            .fontSize(12)
            .fontColor($r('app.color.white'))
        }
        .width(24)
        .height(24)
        Text(item.QSH + '寝室')
          .fontSize(16)
          .fontColor($r('app.color.common_color_1'))
          .margin({ left: 8 })
        this.starRow(item)
        Text(item.SCORE + '分')
          .fontSize(16)
          .fontColor('#FFD11F')
          .margin({ left: 5 })
      }
      .width('100%')
      .height(45)
      .padding({ left: 15, right: 15 })
      .backgroundColor($r('app.color.white'))
      .alignItems(VerticalAlign.Center)
      Divider().color($r('app.color.common_color_5')).strokeWidth(0.5).width('100%')
    }
    .width('100%')
    .onClick((): void => {
      this.getUIContext().getPromptAction().showToast({ message: '评分详情页未翻译', duration: 1500 });
    })
  }

  build() {
    Column() {
      TitleBar({ title: '寝室评分列表', showBack: true })
      Divider().color($r('app.color.common_color_6')).strokeWidth(10).width('100%')
      if (this.isLoading) {
        LoadingView()
      } else if (this.errorText !== '') {
        EmptyView({ tipText: this.errorText })
      } else if (this.list.length === 0) {
        EmptyView({ tipText: '暂无评分记录' })
      } else {
        List() {
          ForEach(this.list, (item: NewHadScore) => {
            ListItem() {
              this.rankRow(item)
            }
          }, (item: NewHadScore) => item.XLH + '_' + item.RANKNUM)
        }
        .layoutWeight(1)
        .width('100%')
        .backgroundColor('#F2F2F2')
        .scrollBar(BarState.Off)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.white'))
  }
}
