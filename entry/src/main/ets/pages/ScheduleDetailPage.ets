import { router } from '@kit.ArkUI';
import { TitleBar } from '../components/TitleBar';
import { ApiService } from '../network/ApiService';
import { ApiResponse } from '../model/ResponseModel';
import { ScheduleDetailEntry } from '../model/ContactModel';
import { EmptyView } from '../components/EmptyView';
import { LoadingView } from '../components/LoadingView';
import { common } from '@kit.AbilityKit';
import { ReminderCalendarHelper } from '../common/ReminderCalendarHelper';

/**
 * 日程详情页 — 源码级翻译（ScheduleDetailActivity.java + AddScheduleInputView +
 * AddScheduleSelectView + ScheduleDetailView 逐行 → ArkTS，[W25 misc-b]）：
 *
 * 【布局】mobile_campus_schedule_activity_schedule_detail.xml：bg#f2f2f2 toolbar("日程详情"+右上"编辑/保存")
 *   + tag(schedule_color 1紧急/2重要 红描边 14fp bgorange) + tvTitle 17fp bold minHeight48 + 白底表单：
 *   AddScheduleInputView（mobile_campus_schedule_view_add_schedule_input.xml：日程标题行 48dip 16fp
 *   edTitle hint#b8c0c9 maxLines3 + 日程地点行 maxLines2 + 日程时间（开始/结束 tvStart/tvEnd 编辑态显示
 *   48dip arrow_right）+ ScheduleDetailView 详情（WebView/EditText 双态→RichText 展示/TextArea 编辑））
 *   + 3 个 AddScheduleSelectView（日程提醒[当天提醒项恒 gone]/重要程度/XML gone 编辑态显示/日程同步）
 *   + tvSubmit"删除日程" 16fp #FF5D3D 高48 mt32 mb27
 * 【数据】y(intent)：xlh（appInfo 可覆盖）→ ScheduleModel.a1 POST getDetailsSchedule {xlh} →
 *   ScheduleDetail；null→EMPTY；-3010→ERROR_NETWORK else EMPTY；k3()：SCHEDULE_REMIND 数字→索引
 *   （2→setTime(REMIND_TIME)）；SCHEDULE_COLOR 数字→tag 索引（-1）/B；同步 p.setSelect(已同步?0:1)
 * 【编辑】toolbar"编辑"→l=true 可编辑+SelectView showEditData+重要程度显示；"保存"→校验
 *   （isFill：请输入标题/请输入除空格以外的标题/请输入日程开始时间/日程时间不得小于当前时间/
 *   提醒时间不能晚于开始时间或早于当前时间/结束时间不能早于开始时间 + 指定时间空→"请输入指定时间"）
 *   → ScheduleModel.e1 POST updateSchedule 9 参 → data="1"→"保存成功"+setResult(-1) else "保存失败"；
 *   p(tag==0 同步)→系统日历写入（j0.a.g/c，HAP 无系统日历 API→保留选择态不写入，注释记录）
 * 【删除】tvSubmit → i3() deleteSchedule {xlh}（无确认框）→ data=="1"→"删除成功"+setResult(xlh)+finish
 *   else "删除失败"
 * 【时间弹窗】c（年月日时分滚轮）→ HAP 等价 DatePickerDialog+TimePickerDialog 串联拼 "yyyy-MM-dd HH:mm"
 */
@Entry
@Component
struct ScheduleDetailPage {
  @State isLoading: boolean = true;
  @State showError: boolean = false;
  @State showEmpty: boolean = false;
  @State detail: ScheduleDetailEntry = new ScheduleDetailEntry();
  /** 源码 l：编辑态开关 */
  @State editing: boolean = false;
  @State tagText: string = '';
  /** 表单值（AddScheduleInputView 等价状态） */
  @State title: string = '';
  @State location: string = '';
  @State startTime: string = '';
  @State endTime: string = '';
  @State content: string = '';
  /** 源码 n（日程提醒）：tag 索引 0/1/2（"当天提醒"恒 gone） */
  @State notifyIndex: number = 0;
  @State notifyTime: string = '';
  /** 源码 o（重要程度）：B 值 1/2/3 */
  @State importanceB: string = '';
  /** 源码 p（日程同步）：0 同步 / 1 不同步 */
  @State syncIndex: number = 1;
  /** 源码 s：选择"指定时间提醒"（index==t.size()-1） */
  private timeSelectOpen: boolean = false;
  private xlh: string = '';
  private readonly NOTIFY_ITEMS: string[] = ['不提醒', '当天提醒', '指定时间提醒'];
  private readonly IMPORTANCE_ITEMS: string[] = ['紧急', '重要', '一般'];
  private readonly SYNC_ITEMS: string[] = ['同步到系统日历', '不同步'];

  aboutToAppear(): void {
    const params = router.getParams() as Record<string, string>;
    if (params !== null && params !== undefined) {
      this.xlh = params['xlh'] !== undefined && params['xlh'] !== null ? params['xlh'] : '';
    }
    this.loadDetail();
  }

  /** 源码 j3()：ScheduleModel.a1 POST getDetailsSchedule {xlh} */
  private loadDetail(): void {
    this.isLoading = true;
    this.showError = false;
    this.showEmpty = false;
    ApiService.getScheduleDetail(this.xlh)
      .then((response: ApiResponse<ScheduleDetailEntry>) => {
        this.isLoading = false;
        if (response.code === 1000) {
          return;
        }
        if (response.code !== 0) {
          const msg: string = response.message === '' ? '服务器繁忙，请稍后再试' : response.message;
          this.getUIContext().getPromptAction().showToast({ message: msg });
          if (String(response.code) === '-3010') {
            this.showError = true;
          } else {
            this.showEmpty = true;
          }
          return;
        }
        if (response.data.TITLE === '') {
          // 源码 g()：null → EMPTY
          this.showEmpty = true;
          return;
        }
        this.detail = response.data;
        this.k3(response.data);
      })
      .catch(() => {
        ApiService.logError('ScheduleDetailPage load error');
        this.isLoading = false;
        this.showError = true;
      });
  }

  /** 源码 k3()：填充表单 + tag/选择态 */
  private k3(bean: ScheduleDetailEntry): void {
    this.title = bean.TITLE;
    this.location = bean.LOCATE;
    this.startTime = bean.KSRQ;
    this.endTime = bean.END_TIME;
    this.content = bean.SCHEDULE_CONTENT;
    if (bean.SCHEDULE_REMIND === '' || !/^\d+$/.test(bean.SCHEDULE_REMIND)) {
      this.notifyIndex = 0;
    } else {
      const idx: number = Number(bean.SCHEDULE_REMIND);
      this.notifyIndex = idx;
      if (idx === 2 && bean.REMIND_TIME !== '') {
        this.notifyTime = bean.REMIND_TIME;
      }
    }
    if (bean.SCHEDULE_COLOR === '' || !/^\d+$/.test(bean.SCHEDULE_COLOR)) {
      this.importanceB = '2';
    } else {
      this.importanceB = bean.SCHEDULE_COLOR;
    }
    // 源码 l3(false)：tag 文案（紧急/重要）
    this.applyTagText();
    this.syncIndex = 1;
  }

  /** 源码 l3(false)：B=="1"→"紧急"、B=="2"→"重要"、else gone */
  private applyTagText(): void {
    if (this.importanceB === '1') {
      this.tagText = '紧急';
    } else if (this.importanceB === '2') {
      this.tagText = '重要';
    } else {
      this.tagText = '';
    }
  }

  /** 源码 h 类：toolbar 编辑/保存切换 */
  private onToolbarTap(): void {
    if (!this.editing) {
      this.editing = true;
      return;
    }
    // 源码 isFill 校验链
    const fillMsg: string = this.isFill();
    if (fillMsg !== '') {
      this.getUIContext().getPromptAction().showToast({ message: fillMsg });
      return;
    }
    if (this.timeSelectOpen && this.notifyTime.trim() === '') {
      this.getUIContext().getPromptAction().showToast({ message: '请输入指定时间' });
      return;
    }
    this.editing = false;
    this.applyTagText();
    // 源码 o3 → ScheduleModel.e1 updateSchedule 9 参（scheduleColor=B、scheduleRemind=选择索引）
    ApiService.updateSchedule(this.xlh, this.startTime, this.endTime, this.title, this.content,
      this.importanceB, String(this.notifyIndex), this.location,
      this.notifyIndex === 2 ? this.notifyTime : '')
      .then((response: ApiResponse<string>) => {
        if (response.code !== 0 || response.data !== '1') {
          this.getUIContext().getPromptAction().showToast({ message: '保存失败' });
          return;
        }
        // 源码 p tag==0（同步到系统日历）→ 接入系统日历写入与代理提醒
        if (this.syncIndex === 0) {
          const ctx = this.getUIContext().getHostContext() as common.UIAbilityContext;
          const startMs: number = this.parseTime(this.startTime);
          const endMs: number = this.endTime !== '' ? this.parseTime(this.endTime) : startMs + 3600000;
          if (startMs > 0) {
            ReminderCalendarHelper.addCalendarEvent(ctx, this.title, this.content, startMs, endMs, this.location);
          }
        }
        if (this.notifyIndex === 2 && this.notifyTime !== '') {
          const remindMs: number = this.parseTime(this.notifyTime);
          if (remindMs > Date.now()) {
            ReminderCalendarHelper.publishCalendarReminder(this.title, this.location || this.content, new Date(remindMs));
          }
        }
        this.getUIContext().getPromptAction().showToast({ message: '保存成功' });
        AppStorage.setOrCreate<string>('schedule_detail_changed', String(Date.now()));
      });
  }

  /** 源码 isFill()：校验链 1:1 */
  private isFill(): string {
    if (this.title === '') {
      return '请输入标题';
    }
    if (this.title.trim() === '') {
      return '请输入除空格以外的标题';
    }
    if (this.startTime === '') {
      return '请输入日程开始时间';
    }
    const startMs: number = this.parseTime(this.startTime);
    if (startMs < Date.now()) {
      return '日程时间不得小于当前时间';
    }
    if (this.notifyTime !== '') {
      const notifyMs: number = this.parseTime(this.notifyTime);
      if (startMs < notifyMs || notifyMs < Date.now()) {
        return '提醒时间不能晚于开始时间或早于当前时间';
      }
    }
    if (this.endTime !== '' && this.startTime !== '') {
      const endMs: number = this.parseTime(this.endTime);
      if (endMs < startMs) {
        return '结束时间不能早于开始时间';
      }
    }
    return '';
  }

  /** "yyyy-MM-dd HH:mm" → 时间戳（解析失败 → 0） */
  private parseTime(text: string): number {
    const normalized: string = text.replace(/-/g, '/').replace(',', ' ');
    const ms: number = new Date(normalized).getTime();
    return isNaN(ms) ? 0 : ms;
  }

  /** 源码 i3()：deleteSchedule {xlh}（无确认框） */
  private onDeleteTap(): void {
    ApiService.deleteSchedule(this.xlh)
      .then((response: ApiResponse<string>) => {
        if (response.code !== 0 || response.data !== '1') {
          this.getUIContext().getPromptAction().showToast({ message: '删除失败' });
          return;
        }
        this.getUIContext().getPromptAction().showToast({ message: '删除成功' });
        AppStorage.setOrCreate<string>('schedule_detail_changed', String(Date.now()));
        router.back();
      });
  }

  /** 源码 d 类：提醒选择 → index==2 → 指定时间行 */
  private onNotifySelect(idx: number): void {
    this.notifyIndex = idx;
    this.timeSelectOpen = idx === this.NOTIFY_ITEMS.length - 1;
  }

  /** 源码 e 类：重要程度选择 → B = index+1 */
  private onImportanceSelect(idx: number): void {
    this.importanceB = String(idx + 1);
  }

  /** 源码 f 类：日程同步选择（0=同步需权限链，1=不同步） */
  private onSyncSelect(idx: number): void {
    this.syncIndex = idx;
  }

  /** 源码 showDateDialog：DatePickerDialog+TimePickerDialog 串联 */
  private showDateTimePicker(isStart: boolean): void {
    this.getUIContext().showDatePickerDialog({
      onDateAccept: (value: Date) => {
        const y: number = value.getFullYear();
        const m: number = value.getMonth() + 1;
        const d: number = value.getDate();
        this.getUIContext().showTimePickerDialog({
          useMilitaryTime: true,
          onAccept: (t: TimePickerResult) => {
            const hh: string = t.hour < 10 ? '0' + t.hour : String(t.hour);
            const mm: string = t.minute < 10 ? '0' + t.minute : String(t.minute);
            const text: string = `${y}-${m < 10 ? '0' + m : m}-${d < 10 ? '0' + d : d} ${hh}:${mm}`;
            if (isStart) {
              this.startTime = text;
            } else {
              this.endTime = text;
            }
          }
        });
      }
    });
  }

  /** 源码 SelectView tvTime 时间弹窗（指定提醒时间） */
  private showNotifyTimePicker(): void {
    this.getUIContext().showDatePickerDialog({
      onDateAccept: (value: Date) => {
        const y: number = value.getFullYear();
        const m: number = value.getMonth() + 1;
        const d: number = value.getDate();
        this.getUIContext().showTimePickerDialog({
          useMilitaryTime: true,
          onAccept: (t: TimePickerResult) => {
            const hh: string = t.hour < 10 ? '0' + t.hour : String(t.hour);
            const mm: string = t.minute < 10 ? '0' + t.minute : String(t.minute);
            this.notifyTime = `${y}-${m < 10 ? '0' + m : m}-${d < 10 ? '0' + d : d} ${hh}:${mm}`;
          }
        });
      }
    });
  }

  /** 展示态选择文本（源码 showData：tag 索引；2→时间文本） */
  private notifyShowText(): string {
    if (this.notifyIndex === 2) {
      return this.notifyTime;
    }
    return this.NOTIFY_ITEMS[this.notifyIndex];
  }

  build() {
    Column() {
      TitleBar({ title: '日程详情', showBack: true, rightText: this.editing ? '保存' : '编辑',
        onRightClick: (): void => {
          this.onToolbarTap();
        } })

      if (this.isLoading) {
        LoadingView()
      } else if (this.showError || this.showEmpty) {
        Column() {
          EmptyView({ tipText: this.showError ? '加载失败，请检查网络后重试' : '暂无数据' })
        }
        .width('100%')
        .layoutWeight(1)
      } else {
        Scroll() {
          Column() {
            // tag + tvTitle（白底）
            Row() {
              if (this.tagText !== '') {
                Text(this.tagText)
                  .fontSize(14)
                  .fontColor('#FF5151')
                  .border({ width: 1, color: '#FF5151' })
                  .padding({ left: 3, right: 3, top: 2, bottom: 2 })
                  .margin({ left: 12 })
              }
              Text(this.detail.TITLE)
                .fontSize(17)
                .fontWeight(FontWeight.Bold)
                .fontColor($r('app.color.common_color_1'))
                .padding({ left: 12, right: 12 })
                .constraintSize({ minHeight: 48 })
                .layoutWeight(1)
            }
            .width('100%')
            .backgroundColor($r('app.color.white'))
            .alignItems(VerticalAlign.Center)

            this.inputView()
            this.selectView('日程提醒', this.notifyShowText(), true, this.editing, () => {
            })
            if (this.editing) {
              this.radioView('重要程度', this.IMPORTANCE_ITEMS, this.importanceB === '' ? 2
                : Number(this.importanceB) - 1, (idx: number) => {
                this.onImportanceSelect(idx);
              }, false)
            }
            this.syncView()
            // tvSubmit："删除日程" 16fp #FF5D3D 高48 mt32 mb27
            Text('删除日程')
              .fontSize(16)
              .fontColor('#FF5D3D')
              .width('100%')
              .height(48)
              .textAlign(TextAlign.Center)
              .backgroundColor($r('app.color.white'))
              .margin({ top: 32, bottom: 27 })
              .onClick(() => {
                this.onDeleteTap();
              })
          }
          .width('100%')
        }
        .width('100%')
        .layoutWeight(1)
        .scrollBar(BarState.Off)
        .align(Alignment.Top)
        .backgroundColor('#F2F2F2')
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F2F2F2')
  }

  /** AddScheduleInputView 等价（标题/地点/时间/详情） */
  @Builder
  inputView() {
    Column() {
      Column() {
        // 日程标题行 48dip
        Row() {
          Image($r('app.media.mobile_campus_schedule_title'))
            .width(16)
            .height(16)
          Text('日程标题')
            .fontSize(16)
            .fontColor($r('app.color.common_color_1'))
            .margin({ left: 12 })
          Column() {
            TextInput({ text: this.title, placeholder: '请输入日程标题' })
              .fontSize(16)
              .fontColor($r('app.color.common_color_1'))
              .placeholderColor('#B8C0C9')
              .backgroundColor(Color.Transparent)
              .border({ width: 0 })
              .padding(0)
              .layoutWeight(1)
              .height(46)
              .maxLength(100)
              .enabled(this.editing)
              .onChange((value: string) => {
                this.title = value;
              })
            Divider()
              .color($r('app.color.common_color_5'))
              .strokeWidth(0.5)
              .width('100%')
          }
          .margin({ left: 12 })
          .layoutWeight(1)
        }
        .width('100%')
        .height(48)
        .padding({ left: 12 })
        .alignItems(VerticalAlign.Center)

        // 日程地点行
        Row() {
          Image($r('app.media.mobile_campus_schedule_local'))
            .width(16)
            .height(16)
          Text('日程地点')
            .fontSize(16)
            .fontColor($r('app.color.common_color_1'))
            .margin({ left: 12 })
          Column() {
            TextInput({ text: this.location, placeholder: '请输入日程地点' })
              .fontSize(16)
              .fontColor($r('app.color.common_color_1'))
              .placeholderColor('#B8C0C9')
              .backgroundColor(Color.Transparent)
              .border({ width: 0 })
              .padding(0)
              .layoutWeight(1)
              .height(46)
              .enabled(this.editing)
              .onChange((value: string) => {
                this.location = value;
              })
            Divider()
              .color($r('app.color.common_color_5'))
              .strokeWidth(0.5)
              .width('100%')
          }
          .margin({ left: 12 })
          .layoutWeight(1)
        }
        .width('100%')
        .height(48)
        .padding({ left: 12 })
        .alignItems(VerticalAlign.Center)

        // 日程时间（开始/结束）
        Row() {
          Image($r('app.media.mobile_campus_schedule_time'))
            .width(16)
            .height(16)
            .margin({ top: 12 })
          Column() {
            Row() {
              if (this.editing) {
                Text('开始')
                  .fontSize(14)
                  .fontColor('#B8C0C9')
                  .margin({ right: 12.5 })
              }
              Text(this.startTime === '' ? '请输入日程开始时间' : this.startTime)
                .fontSize(16)
                .fontColor(this.startTime === '' ? '#B8C0C9' : $r('app.color.common_color_1'))
                .layoutWeight(1)
                .height(48)
                .maxLines(1)
              Image($r('app.media.arrow_right'))
                .width(14)
                .height(14)
                .visibility(this.editing ? Visibility.Visible : Visibility.None)
            }
            .width('100%')
            .alignItems(VerticalAlign.Center)
            .onClick(() => {
              if (this.editing) {
                this.showDateTimePicker(true);
              }
            })
            Divider()
              .color($r('app.color.common_color_5'))
              .strokeWidth(0.5)
              .width('100%')
            Row() {
              if (this.editing) {
                Text('结束')
                  .fontSize(14)
                  .fontColor('#B8C0C9')
                  .margin({ right: 12.5 })
              }
              Text(this.endTime === '' ? '请输入日程结束时间' : this.endTime)
                .fontSize(16)
                .fontColor(this.endTime === '' ? '#B8C0C9' : $r('app.color.common_color_1'))
                .layoutWeight(1)
                .height(48)
                .maxLines(1)
              Image($r('app.media.arrow_right'))
                .width(14)
                .height(14)
                .visibility(this.editing ? Visibility.Visible : Visibility.None)
            }
            .width('100%')
            .alignItems(VerticalAlign.Center)
            .onClick(() => {
              if (this.editing) {
                this.showDateTimePicker(false);
              }
            })
          }
          .margin({ left: 12 })
          .layoutWeight(1)
        }
        .width('100%')
        .padding({ left: 12 })
        .alignItems(VerticalAlign.Top)

        // ScheduleDetailView：编辑态 TextArea / 展示态 RichText
        if (this.editing) {
          TextArea({ text: this.content, placeholder: '' })
            .fontSize(16)
            .fontColor($r('app.color.common_color_1'))
            .backgroundColor(Color.Transparent)
            .width('100%')
            .height(120)
            .onChange((value: string) => {
              this.content = value;
            })
        } else {
          RichText(this.content === '' ? '<p></p>' : this.content)
            .width('100%')
            .height(120)
        }
      }
      .width('100%')
      .backgroundColor($r('app.color.white'))
      .padding({ top: 6, bottom: 6 })
    }
    .width('100%')
  }

  /** 展示态 SelectView（tvShow + 指定时间行） */
  @Builder
  selectView(label: string, showText: string, showTimeRow: boolean, editing: boolean, onTap: () => void) {
    Row() {
      Image($r('app.media.mobile_campus_schedule_time'))
        .width(16)
        .height(16)
      Text(label)
        .fontSize(16)
        .fontColor($r('app.color.common_color_1'))
        .margin({ left: 12 })
      Column() {
        if (editing) {
          this.radioView(label, this.NOTIFY_ITEMS, this.notifyIndex, (idx: number) => {
            this.onNotifySelect(idx);
          }, true)
        } else {
          Text(showText === '' ? '--' : showText)
            .fontSize(16)
            .fontColor($r('app.color.common_color_1'))
        }
        if (showTimeRow && this.notifyIndex === 2 && this.editing) {
          Row() {
            Text(this.notifyTime === '' ? '请输入指定提醒时间' : this.notifyTime)
              .fontSize(16)
              .fontColor(this.notifyTime === '' ? '#B8C0C9' : $r('app.color.common_color_1'))
              .layoutWeight(1)
              .height(48)
            Image($r('app.media.arrow_right'))
              .width(14)
              .height(14)
          }
          .width('100%')
          .alignItems(VerticalAlign.Center)
          .onClick(() => {
            this.showNotifyTimePicker();
          })
        } else if (showTimeRow && this.notifyIndex === 2 && !this.editing && this.notifyTime !== '') {
          Text(this.notifyTime)
            .fontSize(16)
            .fontColor($r('app.color.common_color_1'))
            .height(48)
        }
      }
      .margin({ left: 12 })
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .backgroundColor($r('app.color.white'))
    .padding({ left: 12, top: 12, bottom: 12 })
    .margin({ top: 12 })
    .alignItems(VerticalAlign.Top)
    .onClick(() => {
      onTap();
    })
  }

  /** 编辑态 RadioGroup（selector_schedule_checked 圆点等价：选中蓝点/未选灰圈） */
  @Builder
  radioView(label: string, items: string[], selected: number, onSelect: (idx: number) => void,
    hideIndexOne: boolean) {
    Column() {
      ForEach(items, (item: string, idx: number) => {
        Row() {
          Circle({ width: 16, height: 16 })
            .fill(selected === idx ? '#1B68B7' : Color.Transparent)
            .stroke(selected === idx ? '#1B68B7' : '#B2BDC9')
            .strokeWidth(1)
          Text(item)
            .fontSize(16)
            .fontColor(selected === idx ? '#1B68B7' : $r('app.color.common_color_1'))
            .margin({ left: 12 })
        }
        .width('100%')
        .height(36)
        .alignItems(VerticalAlign.Center)
        .visibility(hideIndexOne && idx === 1 ? Visibility.None : Visibility.Visible)
        .onClick(() => {
          onSelect(idx);
        })
      }, (item: string, idx: number) => item + '_' + idx)
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }

  /** 日程同步 SelectView（编辑态 radio / 展示态文本） */
  @Builder
  syncView() {
    Row() {
      Image($r('app.media.mobile_campus_schedule_time'))
        .width(16)
        .height(16)
        .visibility(Visibility.None)
      Text('日程同步')
        .fontSize(16)
        .fontColor($r('app.color.common_color_1'))
        .margin({ left: 12 })
      Column() {
        if (this.editing) {
          this.radioView('日程同步', this.SYNC_ITEMS, this.syncIndex, (idx: number) => {
            this.onSyncSelect(idx);
          }, false)
        } else {
          Text(this.SYNC_ITEMS[this.syncIndex])
            .fontSize(16)
            .fontColor($r('app.color.common_color_1'))
        }
      }
      .margin({ left: 12 })
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .backgroundColor($r('app.color.white'))
    .padding({ left: 12, top: 12, bottom: 12 })
    .margin({ top: 12 })
    .alignItems(VerticalAlign.Top)
  }
}
