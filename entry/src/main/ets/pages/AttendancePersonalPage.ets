import { router } from '@kit.ArkUI';
import { BusinessError } from '@kit.BasicServicesKit';
import { TitleBar } from '../components/TitleBar';
import { EmptyView } from '../components/EmptyView';
import { LoadingView } from '../components/LoadingView';
import { ApiService } from '../network/ApiService';
import { ApiResponse } from '../model/ResponseModel';
import { AttendanceDetail, AttendanceByDayBean, AttendanceDetailErrorRecord } from '../model/AttendanceModel';
import { Constants } from '../data/Constants';

/**
 * 个人考勤 — AttendancePersonalActivity 源码级翻译（attendance/activity/view）。
 *
 * 【入口】AttendanceLeaderFragment 院系月份统计子项点击 → /attendance/personal {id=userId}
 *   （AttendancePage.openPersonalPage 已按此路由）。
 * 【布局】attendance_activity_personal.xml：
 *   toolbar_normal（T1 标题"考勤月历"）+ attendance_bg 背景（marginTop -22vp fitXY）
 *   + 白卡（marginH 12vp、marginTop 44vp、paddingTop 20vp、paddingBottom 10vp、圆角）：
 *     tvDate 右对齐 15fp #50B3FE + arrow_down_blue_desk_widget（点击年月选择）
 *     + 头像 40vp + tvName 16fp #333333 + tvDepartment 12fp #999999
 *     + 右侧 tvDay1"正常打卡N天"/tvDay2"月需打卡N天" 16fp #333333
 *     + 分隔线 + layoutContainer（异常记录 AttendanceRecordView 行）
 *   + tvTips 14fp #999999 高 36vp："班次；X    考勤组：Y"
 *   + MultiStateView/ListView（item=attendance_view_date：tvDate 16fp #333 高 40vp + 分割线
 *     + AttendanceDateStateView 上午/下午两段：时间 18.5fp bold + 16dip 圆点 + 48dip 竖线 + 状态
 *     14fp + 说明 chip 12fp #388CFC）。
 * 【数据】W2(month,yyyy-MM; id) → AttendanceModel.U0 POST detail {month,id}：
 *   userName/departmentName/dayOfAttendance/days/classes/attendanceGroup/imgUrl/errorRecord/attendanceByDay。
 *   month 初始 yyyy-MM；年月选择回调同 W2。源码 end 段"缺勤/缺卡"说明取 sbdkfs（上午）——原样保真。
 */
function pad2(n: number): string {
  return n < 10 ? '0' + String(n) : String(n);
}

@Entry
@Component
struct AttendancePersonalPage {
  @State detail: AttendanceDetail = new AttendanceDetail();
  @State isLoading: boolean = true;
  @State monthText: string = '';
  @State showPicker: boolean = false;
  @State selYear: number = 2026;
  @State selMonth: number = 1;
  private personId: string = '';
  private monthValue: string = '';

  aboutToAppear(): void {
    const params: Record<string, Object> | undefined = router.getParams() as Record<string, Object> | undefined;
    if (params !== undefined && params !== null) {
      const id: Object = params['id'];
      if (typeof id === 'string') {
        this.personId = id as string;
      }
    }
    const now: Date = new Date();
    this.selYear = now.getFullYear();
    this.selMonth = now.getMonth() + 1;
    this.monthValue = String(this.selYear) + '-' + pad2(this.selMonth);
    this.monthText = this.monthValue;
    this.loadDetail();
  }

  /** 源码 W2(month,id) → AttendanceModel.U0 POST detail */
  private loadDetail(): void {
    this.isLoading = true;
    ApiService.getAttendanceDetail(this.monthValue, this.personId)
      .then((response: ApiResponse<AttendanceDetail>) => {
        if (response.code === 1000) {
          return;
        }
        if (response.code === 0) {
          this.detail = response.data;
        } else {
          this.detail = new AttendanceDetail();
          ApiService.logError('AttendancePersonal detail code=' + response.code + ' ' + response.message);
        }
        this.isLoading = false;
      })
      .catch((error: BusinessError) => {
        ApiService.logError('AttendancePersonal detail fail: ' + error.message);
        this.detail = new AttendanceDetail();
        this.isLoading = false;
      });
  }

  private avatarUrl(): string {
    if (this.detail.imgUrl === '') {
      return '';
    }
    if (this.detail.imgUrl.startsWith('http')) {
      return this.detail.imgUrl;
    }
    return Constants.SOCKET_HOST + this.detail.imgUrl;
  }

  private pickerYears(): string[] {
    const now: Date = new Date();
    const years: string[] = [];
    for (let y = now.getFullYear() - 10; y <= now.getFullYear() + 10; y++) {
      years.push(String(y));
    }
    return years;
  }

  private pickerMonths(): string[] {
    const months: string[] = [];
    for (let m = 1; m <= 12; m++) {
      months.push(String(m));
    }
    return months;
  }

  private selYearIndex(): number {
    const years: string[] = this.pickerYears();
    for (let i = 0; i < years.length; i++) {
      if (years[i] === String(this.selYear)) {
        return i;
      }
    }
    return 10;
  }

  private onPickerConfirm(): void {
    this.showPicker = false;
    const next: string = String(this.selYear) + '-' + pad2(this.selMonth);
    if (next === this.monthValue) {
      return;
    }
    this.monthValue = next;
    this.monthText = next;
    this.loadDetail();
  }

  /** 源码 AttendanceDateStateView.setData：开始段 */
  private startColor(bean: AttendanceByDayBean): string {
    if (bean.sbdkzt === '正常') {
      return '#388CFC';
    }
    if (bean.sbdkzt === '缺勤' || bean.sbdkzt === '缺卡') {
      return '#EE6D60';
    }
    return '#B4B4B4';
  }

  /** 源码 AttendanceDateStateView.setData：结束段（正常文案固定"正常"；错误说明取 sbdkfs 保真） */
  private endColor(bean: AttendanceByDayBean): string {
    if (bean.xbdkzt === '正常') {
      return '#388CFC';
    }
    if (bean.xbdkzt === '缺勤' || bean.xbdkzt === '缺卡') {
      return '#EE6D60';
    }
    return '#B4B4B4';
  }

  private showDesc(status: string): boolean {
    return status === '正常' || status === '缺勤' || status === '缺卡';
  }

  private toast(message: string): void {
    this.getUIContext().getPromptAction().showToast({ message: message, duration: 2000 });
  }

  @Builder
  stateLine(time: string, status: string, desc: string, color: string, isEnd: boolean) {
    Row() {
      Text(time)
        .fontSize(18.5)
        .fontWeight(FontWeight.Bold)
        .fontColor('#333333')
        .width(56)
      Column() {
        if (isEnd) {
          Divider().color('#E7E7E7').strokeWidth(1).width(1).height(24)
        }
        Circle()
          .width(8)
          .height(8)
          .fill(color)
        if (!isEnd) {
          Divider().color('#E7E7E7').strokeWidth(1).width(1).height(24)
        }
      }
      .width(16)
      .alignItems(HorizontalAlign.Center)
      Column() {
        Text(status)
          .fontSize(14)
          .fontColor('#333333')
        if (this.showDesc(status)) {
          Text(desc)
            .fontSize(12)
            .fontColor('#388CFC')
            .backgroundColor('#DDECFF')
            .borderRadius(2)
            .padding({ left: 2, right: 2, top: 1, bottom: 1 })
            .margin({ top: 6 })
        }
      }
      .margin({ left: 16 })
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
    }
    .width('100%')
    .alignItems(VerticalAlign.Top)
  }

  @Builder
  dayCard(bean: AttendanceByDayBean) {
    Column() {
      Row() {
        Image($r('app.media.attendance_time'))
          .width(16)
          .height(16)
        Text(bean.date)
          .fontSize(16)
          .fontColor('#333333')
          .margin({ left: 8 })
      }
      .width('100%')
      .height(40)
      .padding({ left: 12 })
      .alignItems(VerticalAlign.Center)
      Divider().color('#E7E7E7').strokeWidth(1).width('100%')
      Column() {
        this.stateLine(bean.sbdksj, bean.sbdkzt, bean.sbdkfs, this.startColor(bean), false)
        Row().height(8)
        this.stateLine(bean.xbdksj, bean.xbdkzt === '正常' ? '正常' : bean.xbdkzt,
          bean.xbdkzt === '正常' ? bean.xbdkfs : (this.showDesc(bean.xbdkzt) ? bean.sbdkfs : ''),
          this.endColor(bean), true)
      }
      .width('100%')
      .padding({ left: 12, right: 12, top: 9, bottom: 8 })
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .backgroundColor($r('app.color.white'))
  }

  @Builder
  monthPickerPanel() {
    Column() {
      Row() {
        Text('取消')
          .fontSize(16)
          .fontColor('#333333')
          .padding({ left: 16, right: 16, top: 12, bottom: 12 })
          .onClick((): void => { this.showPicker = false; })
        Blank().layoutWeight(1)
        Text('确定')
          .fontSize(16)
          .fontColor('#057DFF')
          .padding({ left: 16, right: 16, top: 12, bottom: 12 })
          .onClick((): void => { this.onPickerConfirm(); })
      }
      .width('100%')
      .backgroundColor('#F5F5F5')
      Row() {
        TextPicker({ range: this.pickerYears(), selected: this.selYearIndex() })
          .layoutWeight(1)
          .height(160)
          .onChange((value: string | string[], index: number | number[]) => {
            const idx: number = Array.isArray(index) ? (index.length > 0 ? index[0] : 0) : index;
            const years: string[] = this.pickerYears();
            if (idx >= 0 && idx < years.length) {
              this.selYear = Number(years[idx]);
            }
          })
        TextPicker({ range: this.pickerMonths(), selected: this.selMonth - 1 })
          .layoutWeight(1)
          .height(160)
          .onChange((value: string | string[], index: number | number[]) => {
            const idx: number = Array.isArray(index) ? (index.length > 0 ? index[0] : 0) : index;
            this.selMonth = idx + 1;
          })
      }
      .width('100%')
    }
    .width('100%')
    .backgroundColor($r('app.color.white'))
    .borderRadius({ topLeft: 12, topRight: 12 })
  }

  build() {
    Stack() {
      Column() {
        TitleBar({ title: '考勤月历', showBack: true })
        if (this.isLoading) {
          LoadingView()
        } else {
          this.profileCard()
          Text(this.detail.classes === '' && this.detail.attendanceGroup === '' ? '' :
            '班次；' + this.detail.classes + '    考勤组：' + this.detail.attendanceGroup)
            .fontSize(14)
            .fontColor('#999999')
            .width('100%')
            .height(36)
            .padding({ left: 12, right: 12 })
            .textAlign(TextAlign.Start)
          if (this.detail.attendanceByDay.length === 0) {
            EmptyView({ tipText: '暂无考勤记录' })
          } else {
            List() {
              ForEach(this.detail.attendanceByDay, (bean: AttendanceByDayBean) => {
                ListItem() {
                  this.dayCard(bean)
                }
              }, (bean: AttendanceByDayBean) => bean.date)
            }
            .layoutWeight(1)
            .width('100%')
            .divider({ strokeWidth: 12, color: '#F2F2F2' })
            .backgroundColor('#F2F2F2')
            .scrollBar(BarState.Off)
          }
        }
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#F2F2F2')
      if (this.showPicker) {
        Column() {
          Blank().onClick((): void => { this.showPicker = false; })
          this.monthPickerPanel()
        }
        .width('100%')
        .height('100%')
        .backgroundColor('#66000000')
      }
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  profileCard() {
    Column() {
      Stack() {
        Image($r('app.media.attendance_bg'))
          .width('100%')
          .height(110)
          .objectFit(ImageFit.Fill)
        Column() {
          Row() {
            Blank().layoutWeight(1)
            Row() {
              Text(this.monthText)
                .fontSize(15)
                .fontColor('#50B3FE')
              Image($r('app.media.arrow_down_blue_desk_widget'))
                .width(12)
                .height(12)
                .margin({ left: 8 })
            }
            .onClick((): void => { this.showPicker = true; })
          }
          .width('100%')
          Row() {
            if (this.avatarUrl() !== '') {
              Image(this.avatarUrl())
                .width(40)
                .height(40)
                .borderRadius(20)
                .objectFit(ImageFit.Cover)
            } else {
              Image($r('app.media.default_avatar'))
                .width(40)
                .height(40)
                .borderRadius(20)
            }
            Column() {
              Text(this.detail.userName)
                .fontSize(16)
                .fontColor('#333333')
              Text(this.detail.departmentName)
                .fontSize(12)
                .fontColor('#999999')
                .margin({ top: 8 })
            }
            .margin({ left: 12 })
            .alignItems(HorizontalAlign.Start)
            Blank().layoutWeight(1)
            Column() {
              Text('正常打卡' + this.detail.dayOfAttendance + '天')
                .fontSize(16)
                .fontColor('#333333')
              Text('月需打卡' + this.detail.days + '天')
                .fontSize(16)
                .fontColor('#333333')
                .margin({ top: 6 })
            }
            .alignItems(HorizontalAlign.End)
          }
          .width('100%')
          .margin({ top: 20 })
          Divider().color('#E7E7E7').strokeWidth(0.5).width('100%').margin({ top: 16, bottom: 8 })
          ForEach(this.detail.errorRecord, (record: AttendanceDetailErrorRecord) => {
            Row() {
              Text(record.errorDetailName)
                .fontSize(16)
                .fontColor('#999999')
              Blank().layoutWeight(1)
              Text(record.errorDetailTimes + '次')
                .fontSize(17)
                .fontColor('#333333')
            }
            .width('100%')
            .margin({ top: 11 })
          }, (record: AttendanceDetailErrorRecord) => record.errorDetailType + record.errorDetailTimes)
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 20, bottom: 10 })
        .backgroundColor($r('app.color.white'))
        .borderRadius(4)
        .margin({ top: 44, left: 12, right: 12 })
        .alignItems(HorizontalAlign.Start)
      }
      .width('100%')
      .alignContent(Alignment.Top)
    }
    .width('100%')
  }
}
