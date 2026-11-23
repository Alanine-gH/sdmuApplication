import { router } from '@kit.ArkUI';
import { BusinessError } from '@kit.BasicServicesKit';
import { common } from '@kit.AbilityKit';
import { TitleBar } from '../components/TitleBar';
import { EmptyView } from '../components/EmptyView';
import { LoadingView } from '../components/LoadingView';
import { ApiService } from '../network/ApiService';
import { ApiResponse } from '../model/ResponseModel';
import { ComingExamEntity, FinishExamEntity } from '../model/ScoreModel';
import { ReminderCalendarHelper } from '../common/ReminderCalendarHelper';

/**
 * 考试信息 — ExamListActivity + ExamComingFragment + ExamFinishFragment +
 * ComingExamListAdapter + FinishExamListAdapter 源码级翻译。
 *
 * 【布局】examination_examlist_activity：toolbar_normal（T1 标题 R.string.examination_exam_title
 *   ="考试信息"，右键 nav_plus_btn → AddExamListActivity）+ RadioGroup 高 45vp（未考/已考，
 *   textcolor_blue_selector）+ examination_view_blueline + 15vp 灰条 + 两 FrameLayout。
 * 【未考】ExamComingFragment：PullToRefresh + SwipeMenuListView（divider list_padding_line）；
 *   ComingExamListAdapter：LX=="1"→"教务提供"蓝标签；LX=="2" 且 TGRXH 空→提醒角标；
 *   LX=="3"→examinationaddexam_list_item 灰字"待添加"；时间行 "yyyy/MM/dd（周X） HH:mm" +
 *   剩余天数逐位方块（<15 红 #FF6C6C / >=15 绿 #73BE3D；=0 显示"今天"20fp #FF6C6C）。
 *   左滑删除 → deleteExam{kslx,kmmc}；点击 LX=="2"/"3" → HandleExamCourseActivity(edit)。
 * 【已考】FinishExamFragment：行同 examination_list_item（课程/时间/地点/座位/学期），
 *   点击 CommonAdapter → KeyValue 弹窗（学年/学期/科目名称/开始时间/结束时间/考试地点/座位号）。
 */
const WEEK_CHARS: string[] = ['日', '一', '二', '三', '四', '五', '六'];

function pad2(n: number): string {
  return n < 10 ? '0' + String(n) : String(n);
}

function parseDate(text: string): Date | null {
  const t: string = text.trim().replace(/\//g, '-');
  const m: RegExpMatchArray | null = t.match(/^(\d{4})-(\d{2})-(\d{2})[ T](\d{2}):(\d{2})/);
  if (m === null) {
    return null;
  }
  const d: Date = new Date(Number(m[1]), Number(m[2]) - 1, Number(m[3]), Number(m[4]), Number(m[5]));
  return Number.isNaN(d.getTime()) ? null : d;
}

/** 源码 e.j(sdf, e.i="yyyy/MM/dd") + e.f(周X) + e.j(sdf, e.e="HH:mm") */
function formatExamTime(text: string): string {
  const d: Date | null = parseDate(text);
  if (d === null) {
    return text;
  }
  return d.getFullYear() + '/' + pad2(d.getMonth() + 1) + '/' + pad2(d.getDate()) +
    '（周' + WEEK_CHARS[d.getDay()] + '） ' + pad2(d.getHours()) + ':' + pad2(d.getMinutes());
}

/** 源码 q.a：数字逐位转中文（1→一、2→二…），用于"第X学期" */
function semesterCn(text: string): string {
  const digits: string[] = ['零', '一', '二', '三', '四', '五', '六', '七', '八', '九'];
  let out: string = '';
  for (let i = 0; i < text.length; i++) {
    const ch: string = text.charAt(i);
    const n: number = Number(ch);
    out += Number.isNaN(n) ? ch : digits[n];
  }
  return out;
}

/** 源码 e.b(sdf,KSSJ,now)：日历天差值（两端均取零点） */
function remainingDays(text: string): number | null {
  const d: Date | null = parseDate(text);
  if (d === null) {
    return null;
  }
  const now: Date = new Date();
  const today: Date = new Date(now.getFullYear(), now.getMonth(), now.getDate());
  const examDay: Date = new Date(d.getFullYear(), d.getMonth(), d.getDate());
  return Math.round((examDay.getTime() - today.getTime()) / (24 * 3600 * 1000));
}

/** 源码 FinishExamListAdapter.convert：起止不同天时追加 "~（周X） 起HH:mm" */
function formatFinishTime(start: string, end: string): string {
  const d: Date | null = parseDate(start);
  if (d === null) {
    return start;
  }
  const head: string = d.getFullYear() + '/' + pad2(d.getMonth() + 1) + '/' + pad2(d.getDate()) +
    '（周' + WEEK_CHARS[d.getDay()] + '）';
  const time: string = pad2(d.getHours()) + ':' + pad2(d.getMinutes());
  const endD: Date | null = parseDate(end);
  if (endD === null) {
    return head + ' ' + time;
  }
  const endHead: string = endD.getFullYear() + '/' + pad2(endD.getMonth() + 1) + '/' + pad2(endD.getDate()) +
    '~（周' + WEEK_CHARS[endD.getDay()] + '）';
  return head + endHead + ' ' + time;
}

@Entry
@Component
struct ExamPage {
  @State activeTab: number = 0;
  @State comingList: ComingExamEntity[] = [];
  @State finishList: FinishExamEntity[] = [];
  @State comingLoaded: boolean = false;
  @State finishLoaded: boolean = false;
  @State isLoading: boolean = true;
  @State errorText: string = '';

  aboutToAppear(): void {
    this.loadComing();
  }

  private loadComing(): void {
    this.isLoading = true;
    this.errorText = '';
    ApiService.getComingExamList()
      .then((response: ApiResponse<ComingExamEntity[]>) => {
        if (response.code === 1000) {
          return;
        }
        if (response.code === 0) {
          this.comingList = response.data;
          this.comingLoaded = true;
        } else {
          this.comingList = [];
          this.errorText = response.message;
        }
        this.isLoading = false;
      })
      .catch((error: BusinessError) => {
        ApiService.logError('beginExamList fail: ' + error.message);
        this.comingList = [];
        this.errorText = '网络异常，请稍后重试';
        this.isLoading = false;
      });
  }

  private loadFinish(): void {
    this.isLoading = true;
    this.errorText = '';
    ApiService.getFinishExamList()
      .then((response: ApiResponse<FinishExamEntity[]>) => {
        if (response.code === 1000) {
          return;
        }
        if (response.code === 0) {
          this.finishList = response.data;
          this.finishLoaded = true;
        } else {
          this.finishList = [];
          this.errorText = response.message;
        }
        this.isLoading = false;
      })
      .catch((error: BusinessError) => {
        ApiService.logError('endExamList fail: ' + error.message);
        this.finishList = [];
        this.errorText = '网络异常，请稍后重试';
        this.isLoading = false;
      });
  }

  private switchTab(index: number): void {
    if (this.activeTab === index) {
      return;
    }
    this.activeTab = index;
    if (index === 0 && !this.comingLoaded) {
      this.loadComing();
    } else if (index === 1 && !this.finishLoaded) {
      this.loadFinish();
    } else {
      this.errorText = '';
      this.isLoading = false;
    }
  }

  private toast(message: string): void {
    this.getUIContext().getPromptAction().showToast({ message: message, duration: 2000 });
  }

  /** 源码 showTime：1~9 天补前导 0（"0"+iB）；负数原样逐位 */
  private dayBadgeChars(days: number): string[] {
    const text: string = days > 0 && days < 10 ? '0' + String(days) : String(days);
    return text.split('');
  }

  private examDays(item: ComingExamEntity): number | null {
    return remainingDays(item.KSSJ);
  }

  private async scheduleExamReminder(item: ComingExamEntity): Promise<void> {
    const startDate: Date | null = parseDate(item.KSSJ);
    if (startDate === null) {
      this.toast('考试时间格式暂不支持设置提醒');
      return;
    }
    const triggerMs: number = ReminderCalendarHelper.computeExamReminderTriggerMs(startDate.getTime(), 60, Date.now());
    if (triggerMs < 0) {
      this.toast('该场考试已临近或已结束，无法设置考前提醒');
      return;
    }
    const ctx = this.getUIContext().getHostContext() as common.UIAbilityContext;
    const parts: string[] = [];
    if (item.KSSJ !== '') { parts.push(item.KSSJ); }
    if (item.KSDD !== '') { parts.push(item.KSDD); }
    if (item.ZWH !== '') { parts.push('座位 ' + item.ZWH); }
    const content: string = parts.length > 0 ? parts.join(' · ') : '请提前做好考试准备';
    const res = await ReminderCalendarHelper.publishCalendarReminderWithResult(
      `考试提醒：${item.KMMC}`,
      content,
      new Date(triggerMs),
      ctx
    );
    if (res.success) {
      const triggerDate: Date = new Date(triggerMs);
      this.toast(`已设置考前提醒（${pad2(triggerDate.getHours())}:${pad2(triggerDate.getMinutes())}）`);
    } else {
      this.toast(res.message);
    }
  }

  private async addExamToCalendar(item: ComingExamEntity): Promise<void> {
    const startDate: Date | null = parseDate(item.KSSJ);
    if (startDate === null) {
      this.toast('考试时间格式暂不支持写入日历');
      return;
    }
    const endDate: Date | null = item.JSSJ !== '' ? parseDate(item.JSSJ) : null;
    const startMs: number = startDate.getTime();
    const endMs: number = endDate !== null && endDate.getTime() > startMs
      ? endDate.getTime()
      : startMs + 2 * 3600 * 1000;
    const descParts: string[] = [];
    if (item.ZWH !== '') { descParts.push('座位号：' + item.ZWH); }
    if (item.ZKZH !== '') { descParts.push('准考证号：' + item.ZKZH); }
    const ctx = this.getUIContext().getHostContext() as common.UIAbilityContext;
    const res = await ReminderCalendarHelper.addCalendarEventWithResult(
      ctx,
      `考试：${item.KMMC}`,
      descParts.join('  '),
      startMs,
      endMs,
      item.KSDD,
      [60, 15]
    );
    this.toast(res.message);
  }

  /** 源码 ExamComingPresenter.d → ExamModel.w deleteExam{kslx,kmmc}；成功后刷新未考 */
  private confirmDelete(item: ComingExamEntity): void {
    this.getUIContext().showAlertDialog({
      title: '',
      message: '确认删除？',
      primaryButton: { value: '取消', action: (): void => {} },
      secondaryButton: {
        value: '删除',
        action: (): void => {
          ApiService.deleteExam(item.KSLX, item.KMMC)
            .then((response: ApiResponse<string>) => {
              if (response.code === 0) {
                this.loadComing();
              } else {
                this.toast('删除失败');
              }
            })
            .catch((error: BusinessError) => {
              ApiService.logError('deleteExam fail: ' + error.message);
              this.toast('删除失败');
            });
        }
      }
    });
  }

  /** 源码 ExamComingFragment.b：type1/2 → X1(examCourseInfo, edit)；HAP → HandleExamCoursePage */
  private openComing(item: ComingExamEntity): void {
    const type: number = item.LX === '3' ? 2 : (item.LX === '2' ? 1 : 0);
    if (type === 0) {
      return;
    }
    const info: Record<string, Object> = {
      'KMMC': item.KMMC, 'KSDD': item.KSDD, 'KSSJ': item.KSSJ, 'KSLX': item.KSLX,
      'ZWH': item.ZWH, 'ZKZH': item.ZKZH, 'JSSJ': item.JSSJ
    };
    router.pushUrl({
      url: 'pages/HandleExamCoursePage',
      params: {
        'handleExamType': 'edit',
        'handleExamTitle': item.KSLX === '0' ? '期末考试' : '等级考试',
        'examCourseInfo': info
      } as Record<string, Object>
    });
  }

  /** 源码 FinishExamListAdapter.createFinishExamBeanList + KeyValue 弹窗 */
  private showFinishDetail(item: FinishExamEntity): void {
    const lines: string[] = [];
    if (item.XN !== '') { lines.push('学年：' + item.XN); }
    if (item.XQ !== '') { lines.push('学期：' + item.XQ); }
    if (item.KMMC !== '') { lines.push('科目名称：' + item.KMMC); }
    if (item.KSSJ !== '') { lines.push('开始时间：' + item.KSSJ); }
    if (item.JSSJ !== '') { lines.push('结束时间：' + item.JSSJ); }
    if (item.KSDD !== '') { lines.push('考试地点：' + item.KSDD); }
    if (item.ZWH !== '') { lines.push('座位号：' + item.ZWH); }
    this.getUIContext().showAlertDialog({
      title: item.KMMC,
      message: lines.join('\n'),
      primaryButton: { value: '确定', action: (): void => {} }
    });
  }

  @Builder
  dayBadges(days: number) {
    Row() {
      if (days !== 0) {
        // 源码 iB==0 时隐藏"剩余/天"两个文案（today 分支只渲染"今天"）
        Text('剩余')
          .fontSize(16)
          .fontColor('#747474')
          .margin({ right: 4 })
      }
      if (days === 0) {
        Text('今天')
          .fontSize(20)
          .fontColor('#FF6C6C')
      } else {
        ForEach(this.dayBadgeChars(days), (ch: string) => {
          Text(ch)
            .fontSize(18)
            .fontColor($r('app.color.white'))
            .backgroundColor(days < 15 ? '#FF6C6C' : '#73BE3D')
            .borderRadius(3)
            .padding({ left: 5, right: 5, top: 1, bottom: 1 })
            .margin({ left: 1, right: 1 })
        }, (ch: string, index: number) => 'day_' + index + '_' + ch)
        Text('天')
          .fontSize(16)
          .fontColor('#747474')
          .margin({ left: 4 })
      }
    }
    .alignItems(VerticalAlign.Center)
  }

  @Builder
  comingItem(item: ComingExamEntity, index: number) {
    Column() {
      if (item.LX === '3') {
        Row() {
          Text(item.KMMC)
            .fontSize(16)
            .fontColor('#CECECE')
            .layoutWeight(1)
          Text('待添加')
            .fontSize(16)
            .fontColor('#18B4ED')
        }
        .width('100%')
        .height(60)
        .padding({ left: 12, right: 12 })
        .alignItems(VerticalAlign.Center)
      } else {
        Row() {
          Text(item.KMMC)
            .fontSize(16)
            .fontColor($r('app.color.black'))
            .maxLines(2)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
          if (item.LX === '1') {
            Text('教务提供')
              .fontSize(10)
              .fontColor($r('app.color.white'))
              .backgroundColor($r('app.color.ybg_blue'))
              .borderRadius(3)
              .padding({ left: 6, right: 6, top: 3, bottom: 3 })
              .margin({ left: 6, top: 1 })
          }
          if (item.LX === '2' && item.TGRXH === '') {
            // 源码 examination_attention_iv：examnation_attention 36dip=18vp
            Image($r('app.media.examnation_attention'))
              .width(18)
              .height(18)
              .margin({ left: 2, top: 2 })
          }
          Blank().layoutWeight(1)
        }
        .width('100%')
        .alignItems(VerticalAlign.Center)
        Row() {
          Image($r('app.media.examination_time'))
            .width(15)
            .height(15)
          Text(formatExamTime(item.KSSJ))
            .fontSize(16)
            .fontColor('#747474')
            .margin({ left: 8 })
            .layoutWeight(1)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
          if (this.examDays(item) !== null) {
            this.dayBadges(this.examDays(item) as number)
          }
        }
        .width('100%')
        .margin({ top: 12 })
        .alignItems(VerticalAlign.Center)
        if (item.KSDD !== '') {
          Row() {
            Image($r('app.media.examination_place')).width(15).height(15)
            Text(item.KSDD).fontSize(14).fontColor('#747474').margin({ left: 8 }).layoutWeight(1)
          }
          .width('100%')
          .margin({ top: 6 })
          .alignItems(VerticalAlign.Center)
        }
        if (item.ZWH !== '') {
          Row() {
            Image($r('app.media.examination_table')).width(15).height(15)
            Text(item.ZWH).fontSize(14).fontColor('#747474').margin({ left: 8 }).layoutWeight(1)
          }
          .width('100%')
          .margin({ top: 6 })
          .alignItems(VerticalAlign.Center)
        }
        if (parseDate(item.KSSJ) !== null) {
          Row({ space: 8 }) {
            Text('考前提醒')
              .fontSize(12)
              .fontColor('#18B4ED')
              .backgroundColor('#E8F7FD')
              .borderRadius(14)
              .padding({ left: 10, right: 10, top: 5, bottom: 5 })
              .onClick((): void => {
                this.scheduleExamReminder(item);
              })
            Text('加入日历')
              .fontSize(12)
              .fontColor($r('app.color.sdmu_primary'))
              .backgroundColor('#FDECEE')
              .borderRadius(14)
              .padding({ left: 10, right: 10, top: 5, bottom: 5 })
              .onClick((): void => {
                this.addExamToCalendar(item);
              })
          }
          .width('100%')
          .margin({ top: 10 })
          .justifyContent(FlexAlign.End)
        }
      }
    }
    .width('100%')
    .padding({ left: 12, right: 12, top: 15, bottom: 12 })
    .backgroundColor($r('app.color.white'))
    .alignItems(HorizontalAlign.Start)
    .onClick((): void => { this.openComing(item); })
    .gesture(LongPressGesture({ repeat: false }).onAction((): void => { this.confirmDelete(item); }))
  }

  @Builder
  finishItem(item: FinishExamEntity) {
    Column() {
      Text(item.KMMC)
        .fontSize(16)
        .fontColor($r('app.color.black'))
        .maxLines(2)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
      Row() {
        Image($r('app.media.examination_time')).width(15).height(15)
        Text(formatFinishTime(item.KSSJ, item.JSSJ))
          .fontSize(16)
          .fontColor('#747474')
          .margin({ left: 8 })
          .layoutWeight(1)
      }
      .width('100%')
      .margin({ top: 12 })
      .alignItems(VerticalAlign.Center)
      if (item.KSDD !== '') {
        Row() {
          Image($r('app.media.examination_place')).width(15).height(15)
          Text(item.KSDD).fontSize(14).fontColor('#747474').margin({ left: 8 }).layoutWeight(1)
        }
        .width('100%')
        .margin({ top: 6 })
      }
      if (item.ZWH !== '') {
        Row() {
          Image($r('app.media.examination_table')).width(15).height(15)
          Text(item.ZWH).fontSize(14).fontColor('#747474').margin({ left: 8 }).layoutWeight(1)
        }
        .width('100%')
        .margin({ top: 6 })
      }
      Row() {
        Image($r('app.media.examination_term')).width(15).height(15)
        Text(item.XN + '年第' + semesterCn(item.XQ) + '学期')
          .fontSize(14)
          .fontColor('#747474')
          .margin({ left: 8 })
          .layoutWeight(1)
      }
      .width('100%')
      .margin({ top: 6 })
    }
    .width('100%')
    .padding({ left: 12, right: 12, top: 15, bottom: 12 })
    .backgroundColor($r('app.color.white'))
    .alignItems(HorizontalAlign.Start)
    .onClick((): void => { this.showFinishDetail(item); })
  }

  build() {
    Column() {
      TitleBar({
        title: '考试信息',
        showBack: true,
        rightIcon: $r('app.media.nav_plus_btn'),
        onRightClick: (): void => {
          router.pushUrl({ url: 'pages/ExamAddListPage' }).catch((error: BusinessError) => {
            ApiService.logError('open ExamAddList fail: ' + error.message);
          });
        }
      })
      Row() {
        ForEach(['即将开始', '已经结束'], (label: string, index: number) => {
          Column() {
            Text(label)
              .fontSize(14)
              .fontColor(this.activeTab === index ? '#18B4ED' : '#747474')
              .height(43)
              .textAlign(TextAlign.Center)
              .width('100%')
            Divider()
              .color(this.activeTab === index ? '#18B4ED' : Color.Transparent)
              .strokeWidth(2)
              .width(85)
          }
          .layoutWeight(1)
          .height(45)
          .onClick((): void => { this.switchTab(index); })
        }, (label: string) => label)
      }
      .width('100%')
      .height(45)
      .backgroundColor($r('app.color.white'))
      Divider().color('#F2F2F2').strokeWidth(15).width('100%')
      if (this.isLoading) {
        LoadingView()
      } else if (this.errorText !== '') {
        EmptyView({ tipText: this.errorText })
      } else if (this.activeTab === 0) {
        if (this.comingList.length === 0) {
          EmptyView({ tipText: '呀，一门考试信息都没呢，要不要添加一下~' })
        } else {
          List() {
            ForEach(this.comingList, (item: ComingExamEntity, index: number) => {
              ListItem() {
                this.comingItem(item, index)
              }
            }, (item: ComingExamEntity) => item.KMMC + item.KSLX + item.KSSJ)
          }
          .layoutWeight(1)
          .width('100%')
          .divider({ strokeWidth: 0.5, color: '#E7E7E7', startMargin: 12, endMargin: 12 })
          .scrollBar(BarState.Off)
        }
      } else {
        if (this.finishList.length === 0) {
          EmptyView({ tipText: '小奕数据不足，暂无历史考试信息呢' })
        } else {
          List() {
            ForEach(this.finishList, (item: FinishExamEntity) => {
              ListItem() {
                this.finishItem(item)
              }
            }, (item: FinishExamEntity) => item.KMMC + item.KSSJ)
          }
          .layoutWeight(1)
          .width('100%')
          .divider({ strokeWidth: 0.5, color: '#E7E7E7', startMargin: 12, endMargin: 12 })
          .scrollBar(BarState.Off)
        }
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.white'))
  }
}
