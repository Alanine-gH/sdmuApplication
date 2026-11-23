import { router } from '@kit.ArkUI';
import { BusinessError } from '@kit.BasicServicesKit';
import { ApiService } from '../network/ApiService';
import { ApiResponse } from '../model/ResponseModel';
import { SuperviseCourseItem, SuperviseDayGroup } from '../model/SuperviseModel';
import { EmptyView } from '../components/EmptyView';
import { BreakpointSystem } from '../common/BreakpointSystem';

/**
 * 督导听课主页 — 源码级翻译 [W21 supervise]（SuperviseMainActivity.java 逐行 → ArkTS）：
 *
 * 【布局】mobile_campus_supervise_activity_supervise_main.xml：#f2f2f2 竖排
 *   toolbar（mobile_campus_supervise_toolbar_normal.xml）：44dip main_bg，标题"督导听课"17sp ybg_blue，
 *     右侧 toolBaImg1=search（→ 搜索页 120）/ toolBaImg2=screen（→ 筛选页 121），各 marginRight 15
 *   layoutTips（gone→visible）：#1B68B7 底 padH12，teacher 图标 18 白 tint + tvSelect 白字 32dip 高
 *     （搜索结果 → "任课老师：XM"；筛选结果 → "筛选条件：BMMC/djj节(0=全天)"，MainActivity.onActivityResult）
 *   WeekView（widget/WeekView.java）：WEEK={"日","一","二","三","四","五","六"} 周日开头（FIRST_DAY=1
 *     setToFirstDay(get(7)==SUNDAY)），dates=本周周日..周六真实日期号（"dd"），today 默认选中；
 *     首末列 label/日期 common_color_3，中间 common_color_1；选中日期 #1B68B7 圆 32 白字（shape_week_check）
 *   列表 view_main：行 60dip 白底，tvSection=DJJ（>3 字符截"前3...节"，空→""）17sp #1b6bb7，
 *     tvTitle=KCMC 15sp，tvMajor=SKDD(type0)/SKLSXM(type1) 14sp common_color_3（SuperviseMainAdapter）
 *   FrameLayout paddingTop 12 + imgMy 右下角（→ 我的听课 M0）
 *
 * 【数据】f1() 仅 q2(n)（初始空态，不自动拉取）；getUserCourseList 仅在搜索/筛选回传后调
 *   （Q2(selectDay, type, skls | bmdm,djj)）；响应 UserCourseList[]{detail,xqj} 7 组按日缓存（t），
 *   点日期只切换 t.get(i).detail 不重新请求（WeekAdapter.c 回调）。
 *   2026-11-18 probe_w21_supervise.py：三形态 code=0，测试账号 detail 全空 → 真实空态。
 *
 * 【路由】条目点击 → /supervise/add {xlh}（SuperviseAddPage）；搜索/筛选结果经 AppStorage 管道回传
 *   （'supervise_search_result'/'supervise_filter_result'，onPageShow 消费，router.back 无参等价）。
 */

class SuperviseWeekDay {
  dayLabel: string;
  dateNumber: string;
  checked: boolean;
  /** 首末列灰色（WeekAdapter.getView：i==0 || i==count-1 → common_color_3） */
  edge: boolean;

  constructor(dayLabel: string, dateNumber: string, checked: boolean, edge: boolean) {
    this.dayLabel = dayLabel;
    this.dateNumber = dateNumber;
    this.checked = checked;
    this.edge = edge;
  }
}

/** 源码 WeekView.WEEK 周日开头 + getAllweekDays（本周周日..周六真实日期号） */
function buildCurrentWeekDays(): SuperviseWeekDay[] {
  const labels: string[] = ['日', '一', '二', '三', '四', '五', '六'];
  const now: Date = new Date();
  const offset: number = now.getDay();
  const sunday: Date = new Date(now.getFullYear(), now.getMonth(), now.getDate() - offset);
  const days: SuperviseWeekDay[] = [];
  for (let i: number = 0; i < 7; i++) {
    const d: Date = new Date(sunday.getFullYear(), sunday.getMonth(), sunday.getDate() + i);
    const dateNumber: string = (d.getDate() < 10 ? '0' : '') + String(d.getDate());
    days.push(new SuperviseWeekDay(labels[i], dateNumber, dateNumber === buildToday(), i === 0 || i === 6));
  }
  return days;
}

/** 源码 WeekAdapter.today = SimpleDateFormat("dd") */
function buildToday(): string {
  const now: Date = new Date();
  return (now.getDate() < 10 ? '0' : '') + String(now.getDate());
}

@Entry
@Component
struct SupervisePage {
  @State weekDays: SuperviseWeekDay[] = buildCurrentWeekDays();
  /** 源码 t：getUserCourseList 7 组按日缓存（WeekView 点击只切组不重拉） */
  @State dayGroups: SuperviseDayGroup[] = [];
  /** 源码 selectDay()：当前选中日期下标（0..6 周日开头） */
  private dayIndex: number = new Date().getDay();
  /** 源码 adapter.type：0=搜索(skls→tvMajor=SKDD) 1=筛选(bmdm,djj→tvMajor=SKLSXM) */
  private rowType: number = 0;
  /** 当前展示列表（t.get(selectDay).detail） */
  @State listRows: SuperviseCourseItem[] = [];
  /** 源码 tvSelect/layoutTips：搜索或筛选回传后显示，空= gone */
  @State filterLabel: string = '';
  @StorageProp('currentBreakpoint') currentBreakpoint: string = 'sm';
  @StorageProp('avoidAreaBottomVp') avoidAreaBottomVp: number = 0;
  @StorageProp('avoidAreaLeftVp') avoidAreaLeftVp: number = 0;
  @StorageProp('avoidAreaRightVp') avoidAreaRightVp: number = 0;
  private static readonly SEARCH_RESULT_KEY: string = 'supervise_search_result';
  private static readonly FILTER_RESULT_KEY: string = 'supervise_filter_result';

  onPageShow(): void {
    // 源码 onActivityResult(120)：搜索页回传 {XM("name"), id(GH)} → tvSelect="任课老师：XM" → Q2(type=0, skls)
    const searchResult: string | undefined = AppStorage.get<string>(SupervisePage.SEARCH_RESULT_KEY);
    if (searchResult !== undefined && searchResult !== '') {
      AppStorage.setOrCreate<string>(SupervisePage.SEARCH_RESULT_KEY, '');
      this.applySearchResult(searchResult);
      return;
    }
    // 源码 onActivityResult(121)：筛选页回传 bjData{BMDM,BMMC} + djj → tvSelect="筛选条件：..." → Q2(type=1)
    const filterResult: string | undefined = AppStorage.get<string>(SupervisePage.FILTER_RESULT_KEY);
    if (filterResult !== undefined && filterResult !== '') {
      AppStorage.setOrCreate<string>(SupervisePage.FILTER_RESULT_KEY, '');
      this.applyFilterResult(filterResult);
    }
  }

  /** 源码 onActivityResult i==120：result XM/GH → 提示行 + type=0 重拉 */
  private applySearchResult(json: string): void {
    try {
      const parsed: Record<string, Object> = JSON.parse(json) as Record<string, Object>;
      const xm: Object = parsed['XM'];
      const gh: Object = parsed['GH'];
      const name: string = typeof xm === 'string' ? xm as string : '';
      const teacherGH: string = typeof gh === 'string' ? gh as string : '';
      this.filterLabel = '任课老师：' + name;
      this.rowType = 0;
      this.loadDayGroups(teacherGH, '', '');
    } catch (error) {
      ApiService.logError('SupervisePage searchResult parse fail: ' + (error as BusinessError).message);
    }
  }

  /** 源码 onActivityResult i==121：bjData/djj → 提示行（0=全天）+ type=1 重拉 */
  private applyFilterResult(json: string): void {
    try {
      const parsed: Record<string, Object> = JSON.parse(json) as Record<string, Object>;
      const bmdmV: Object = parsed['BMDM'];
      const bmmcV: Object = parsed['BMMC'];
      const djjV: Object = parsed['djj'];
      const bmdm: string = typeof bmdmV === 'string' ? bmdmV as string : '';
      const bmmc: string = typeof bmmcV === 'string' ? bmmcV as string : '';
      const djj: string = typeof djjV === 'string' ? djjV as string : '';
      this.filterLabel = '筛选条件：' + bmmc + '/' + (djj === '0' ? '全天' : djj + '节');
      this.rowType = 1;
      this.loadDayGroups('', bmdm, djj);
    } catch (error) {
      ApiService.logError('SupervisePage filterResult parse fail: ' + (error as BusinessError).message);
    }
  }

  /** 源码 Q2(selectDay, type, ...) → SuperviseModel.b1：POST getUserCourseList（7 组缓存 + 当日 detail） */
  private loadDayGroups(skls: string, bmdm: string, djj: string): void {
    ApiService.getSuperviseDayGroups(skls, bmdm, djj)
      .then((response: ApiResponse<SuperviseDayGroup[]>) => {
        if (response.code !== 0) {
          ApiService.logError('SupervisePage getUserCourseList degrade: code=' + response.code +
            ' msg=' + response.message);
        }
        this.dayGroups = response.data;
        this.applySelectedDay();
      })
      .catch((error: BusinessError) => {
        ApiService.logError('SupervisePage getUserCourseList fail: ' + error.message);
        this.dayGroups = [];
        this.listRows = [];
      });
  }

  /** 源码 adapter.setData(t.get(selectDay).detail)：空组（测试账号）→ 空态 */
  private applySelectedDay(): void {
    if (this.dayIndex < this.dayGroups.length) {
      this.listRows = this.dayGroups[this.dayIndex].detail;
    } else {
      this.listRows = [];
    }
  }

  /** 源码 WeekAdapter.refreshState + WeekAdapter.c 回调：仅刷新选中与展示列表，不重新请求 */
  private toggleWeekDay(target: SuperviseWeekDay, index: number): void {
    this.dayIndex = index;
    this.weekDays = this.weekDays.map((day: SuperviseWeekDay): SuperviseWeekDay => {
      return new SuperviseWeekDay(day.dayLabel, day.dateNumber, day.dateNumber === target.dateNumber, day.edge);
    });
    this.applySelectedDay();
  }

  /** 源码 SuperviseMainAdapter.getView tvSection：DJJ 空→""、len>3→substring(0,3)+"...节"、否则原值 */
  private sectionText(item: SuperviseCourseItem): string {
    if (item.DJJ === '') {
      return '';
    }
    if (item.DJJ.length > 3) {
      return item.DJJ.substring(0, 3) + '...节';
    }
    return item.DJJ;
  }

  /** 源码 SuperviseMainAdapter.getView tvMajor：type=0 → SKDD / type=1 → SKLSXM */
  private majorText(item: SuperviseCourseItem): string {
    return this.rowType === 0 ? item.SKDD : item.SKLSXM;
  }

  build() {
    Column() {
      // mobile_campus_supervise_toolbar_normal.xml：45vp 白底 + 44vp 工具栏 + 细分隔线
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
          Text('督导听课')
            .fontSize(17)
            .fontColor($r('app.color.ybg_blue'))
            .layoutWeight(1)
            .textAlign(TextAlign.Center)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
          Row() {
            // 源码 toolBaImg1 → /supervise/search（N0）requestCode 120
            Image($r('app.media.mobile_campus_supervise_search'))
              .width(24)
              .height(24)
              .margin({ right: 15 })
              .onClick(() => {
                router.pushUrl({ url: 'pages/SuperviseSearchPage' });
              })
            // 源码 toolBaImg2 → /supervise/filter（I0）requestCode 121
            Image($r('app.media.mobile_campus_supervise_screen'))
              .width(24)
              .height(24)
              .margin({ right: 15 })
              .onClick(() => {
                router.pushUrl({ url: 'pages/SuperviseFilterPage' });
              })
          }
          .alignItems(VerticalAlign.Center)
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

      // layoutTips：#1B68B7 提示行（源码 gone → onActivityResult 回传后 visible；teacher 图标白 tint）
      if (this.filterLabel !== '') {
        Row() {
          Image($r('app.media.mobile_campus_supervise_teacher'))
            .width(18)
            .height(18)
            .fillColor(Color.White)
            .margin({ right: 8 })
          Text(this.filterLabel)
            .fontColor(Color.White)
            .fontSize(14)
            .height(32)
            .textAlign(TextAlign.Start)
            .layoutWeight(1)
        }
        .width('100%')
        .alignItems(VerticalAlign.Center)
        .padding({ left: 12, right: 12 })
        .backgroundColor($r('app.color.blue_default'))
      }

      // WeekView.java：WEEK 周日开头，dates=本周周日..周六，today 默认选中，首末列灰
      Row() {
        ForEach(this.weekDays, (day: SuperviseWeekDay, index: number) => {
          Column() {
            Text(day.dayLabel)
              .fontSize(14)
              .fontColor(day.edge ? $r('app.color.common_color_3') : $r('app.color.common_color_1'))
            Text(day.dateNumber)
              .fontSize(14)
              .fontColor(day.checked ? Color.White :
                (day.edge ? $r('app.color.common_color_3') : $r('app.color.common_color_1')))
              .width(32)
              .height(32)
              .borderRadius(16)
              .textAlign(TextAlign.Center)
              .backgroundColor(day.checked ? '#1B68B7' : Color.Transparent)
              .margin({ top: 8 })
              .onClick(() => {
                this.toggleWeekDay(day, index);
              })
          }
          .layoutWeight(1)
          .padding(12)
          .alignItems(HorizontalAlign.Center)
        }, (day: SuperviseWeekDay) => day.dayLabel + day.dateNumber)
      }
      .width('100%')
      .constraintSize({ maxWidth: BreakpointSystem.getContentMaxWidth(this.currentBreakpoint) })
      .alignSelf(ItemAlign.Center)
      .padding({ left: this.avoidAreaLeftVp, right: this.avoidAreaRightVp })
      .backgroundColor($r('app.color.main_bg'))

      // FrameLayout paddingTop 12：列表（f1() 初始空态；仅搜索/筛选回传后拉取）+ 右下角 imgMy
      Stack({ alignContent: Alignment.BottomEnd }) {
        if (this.listRows.length === 0) {
          Column() {
            EmptyView()
          }
          .width('100%')
          .height('100%')
        } else {
          List({ space: 0 }) {
            ForEach(this.listRows, (item: SuperviseCourseItem) => {
              ListItem() {
                Row() {
                  Text(this.sectionText(item))
                    .fontSize(17)
                    .fontColor('#1B6BB7')
                    .padding({ left: 12, right: 15 })
                    .height('100%')
                    .textAlign(TextAlign.Start)
                  Column() {
                    Text(item.KCMC)
                      .fontSize(15)
                      .fontColor($r('app.color.common_color_1'))
                      .maxLines(1)
                      .textOverflow({ overflow: TextOverflow.Ellipsis })
                      .padding({ top: 2 })
                      .layoutWeight(1)
                    Text(this.majorText(item))
                      .fontSize(14)
                      .fontColor($r('app.color.common_color_3'))
                      .maxLines(1)
                      .textOverflow({ overflow: TextOverflow.Ellipsis })
                      .padding({ top: 2 })
                      .layoutWeight(1)
                  }
                  .width(59)
                  .height(59)
                  .alignItems(HorizontalAlign.Start)
                  .justifyContent(FlexAlign.Center)

                  Divider()
                    .color($r('app.color.common_color_4'))
                    .strokeWidth(0.5)
                    .width('100%')
                }
                .width('100%')
                .height(60)
                .alignItems(VerticalAlign.Center)
                .backgroundColor($r('app.color.main_bg'))
                // 源码 d.onItemClick：bundle{xlh=DetailBean.XLH} → /supervise/add（H0）
                .onClick(() => {
                  router.pushUrl({ url: 'pages/SuperviseAddPage',
                    params: { 'xlh': item.XLH } as Record<string, string> });
                })
              }
            }, (item: SuperviseCourseItem) => item.XLH + '_' + item.KCMC)
          }
          .width('100%')
          .height('100%')
          .contentEndOffset(this.avoidAreaBottomVp)
          .backgroundColor($r('app.color.common_color_6'))
        }

        Image($r('app.media.mobile_campus_supervise_supervisor'))
          .width(52)
          .height(52)
          .margin({ right: 12 + this.avoidAreaRightVp, bottom: 12 + this.avoidAreaBottomVp })
          .onClick(() => {
            // 源码 b.onClick：g2(a.M0) → /supervise/mine
            router.pushUrl({ url: 'pages/SuperviseMinePage' });
          })
      }
      .layoutWeight(1)
      .width('100%')
      .constraintSize({ maxWidth: BreakpointSystem.getContentMaxWidth(this.currentBreakpoint) })
      .alignSelf(ItemAlign.Center)
      .padding({ top: 12, left: this.avoidAreaLeftVp, right: this.avoidAreaRightVp })
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.common_color_6'))
  }
}
