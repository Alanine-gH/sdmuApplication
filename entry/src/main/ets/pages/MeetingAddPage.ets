import { router } from '@kit.ArkUI';
import { BusinessError } from '@kit.BasicServicesKit';
import { TitleBar } from '../components/TitleBar';
import { ApiService } from '../network/ApiService';
import { ApiResponse } from '../model/ResponseModel';
import {
  ContactInitData,
  ContactSearchAddressBook,
  ContactSearchAddressBookItem
} from '../model/ContactModel';
import { AdaptiveLayoutHelper } from '../common/AdaptiveLayoutHelper';

/**
 * 新增会议 — 1:1 复刻 mobile_campus_meeting_activity_add_meeting.xml，
 * 并接入真实通讯录参会人员选择（getContactInitData / getContactStudentInitData / searchAddressBook）、
 * 真实会议室选择（pages/MeetingSelectorPage -> AppStorage 'meeting_selector_result'）与真实日期时间选择。
 */

interface NotifyOption {
  key: string;
  label: string;
}

class MeetingAttendeePerson {
  id: string = '';
  name: string = '';
  dept: string = '';

  constructor(id: string, name: string, dept: string) {
    this.id = id;
    this.name = name;
    this.dept = dept;
  }
}

@Entry
@Component
struct MeetingAddPage {
  @State titleInput: string = '';
  @State locationInput: string = '';
  @State startTimeText: string = '';
  @State endTimeText: string = '';
  @State remindTimeText: string = '';
  @State notifyKey: string = 'no';
  @State compereList: MeetingAttendeePerson[] = [];
  @State attendList: MeetingAttendeePerson[] = [];
  @State mustAttendList: MeetingAttendeePerson[] = [];
  @State outsidePerson: string = '';
  @State showPersonPicker: boolean = false;
  @State pickerRole: string = 'attend'; // 'compere' | 'attend' | 'must'
  @State pickerKeyword: string = '';
  @State pickerManualName: string = '';
  @State pickerCandidates: MeetingAttendeePerson[] = [];
  @State pickerLoading: boolean = false;
  @State showDateTimeSheet: boolean = false;
  @State dateTimeTarget: string = 'start'; // 'start' | 'end' | 'remind'
  @State pickerDate: Date = new Date();
  @StorageProp('currentBreakpoint') currentBreakpoint: string = 'sm';
  @StorageProp('isCompactHeight') isCompactHeight: boolean = false;

  private defaultCandidates: MeetingAttendeePerson[] = [];
  private notifyOptions: NotifyOption[] = [
    { key: 'no', label: '不通知' },
    { key: 'one', label: '会前一小时提醒' },
    { key: 'specific', label: '指定时间提醒' }
  ];

  aboutToAppear(): void {
    this.loadDefaultContacts();
  }

  onPageShow(): void {
    const changed: boolean | undefined = AppStorage.get<boolean>('meeting_selector_changed');
    if (changed === true) {
      AppStorage.setOrCreate('meeting_selector_changed', false);
      const raw: string | undefined = AppStorage.get<string>('meeting_selector_result');
      if (raw !== undefined && raw !== '') {
        try {
          const mapObj: Record<string, Object> = JSON.parse(raw) as Record<string, Object>;
          const parts: string[] = [];
          const keys: string[] = Object.keys(mapObj);
          for (const k of keys) {
            const valStr: string = typeof mapObj[k] === 'string' ? mapObj[k] as string : JSON.stringify(mapObj[k]);
            const node: Record<string, Object> = JSON.parse(valStr) as Record<string, Object>;
            const txt: string = typeof node['text'] === 'string' && (node['text'] as string) !== ''
              ? node['text'] as string
              : (typeof node['name'] === 'string' ? node['name'] as string : '');
            if (txt !== '') {
              parts.push(txt);
            }
          }
          if (parts.length > 0) {
            this.locationInput = parts.join(' - ');
          }
        } catch (_e) {
          // 忽略解析异常
        }
      }
    }
  }

  private loadDefaultContacts(): void {
    this.pickerLoading = true;
    ApiService.getContactInitData()
      .then((res: ApiResponse<ContactInitData[]>) => {
        const list: MeetingAttendeePerson[] = [];
        const seen: Set<string> = new Set<string>();
        if (res.code === 0 && Array.isArray(res.data)) {
          for (const group of res.data) {
            if (Array.isArray(group.topContactList)) {
              for (const t of group.topContactList) {
                const uid: string = t.SCYHID !== '' ? t.SCYHID : (t.GH !== '' ? t.GH : t.XLH);
                if (t.XM !== '' && !seen.has(uid + '_' + t.XM)) {
                  seen.add(uid + '_' + t.XM);
                  list.push(new MeetingAttendeePerson(uid !== '' ? uid : t.XM, t.XM, t.BMMC !== '' ? t.BMMC : t.ZW));
                }
              }
            }
            if (Array.isArray(group.myTeacher)) {
              for (const t of group.myTeacher) {
                const uid: string = t.GH !== '' ? t.GH : t.XLH;
                if (t.XM !== '' && !seen.has(uid + '_' + t.XM)) {
                  seen.add(uid + '_' + t.XM);
                  list.push(new MeetingAttendeePerson(uid !== '' ? uid : t.XM, t.XM, t.BMMC !== '' ? t.BMMC : '我的教师'));
                }
              }
            }
            if (Array.isArray(group.myCourseTeachers)) {
              for (const ct of group.myCourseTeachers) {
                if (ct.userName !== '' && !seen.has(ct.userId + '_' + ct.userName)) {
                  seen.add(ct.userId + '_' + ct.userName);
                  list.push(new MeetingAttendeePerson(
                    ct.userId !== '' ? ct.userId : ct.userName,
                    ct.userName,
                    ct.course !== '' ? ct.course : '授课教师'
                  ));
                }
              }
            }
          }
        }
        this.defaultCandidates = list;
        this.pickerCandidates = list;
        this.pickerLoading = false;
      })
      .catch((_err: BusinessError) => {
        this.pickerLoading = false;
      });
  }

  private searchContacts(kw: string): void {
    const trimmed: string = kw.trim();
    if (trimmed === '') {
      this.pickerCandidates = this.defaultCandidates;
      return;
    }
    this.pickerLoading = true;
    ApiService.searchAddressBook('1', trimmed)
      .then((res: ApiResponse<ContactSearchAddressBook[]>) => {
        const list: MeetingAttendeePerson[] = [];
        const seen: Set<string> = new Set<string>();
        if (res.code === 0 && Array.isArray(res.data)) {
          for (const grp of res.data) {
            const deptName: string = grp.bmmc;
            if (Array.isArray(grp.addressBookList)) {
              for (const item of grp.addressBookList) {
                const uid: string = item.XLH !== '' ? item.XLH : item.XM;
                if (item.XM !== '' && !seen.has(uid + '_' + item.XM)) {
                  seen.add(uid + '_' + item.XM);
                  list.push(new MeetingAttendeePerson(
                    uid,
                    item.XM,
                    deptName !== '' ? deptName : (item.ZW !== '' ? item.ZW : item.course)
                  ));
                }
              }
            }
          }
        }
        this.pickerCandidates = list;
        this.pickerLoading = false;
      })
      .catch((_err: BusinessError) => {
        this.pickerLoading = false;
      });
  }

  private getRoleList(role: string): MeetingAttendeePerson[] {
    if (role === 'compere') {
      return this.compereList;
    }
    if (role === 'must') {
      return this.mustAttendList;
    }
    return this.attendList;
  }

  private setRoleList(role: string, next: MeetingAttendeePerson[]): void {
    if (role === 'compere') {
      this.compereList = next;
    } else if (role === 'must') {
      this.mustAttendList = next;
    } else {
      this.attendList = next;
    }
  }

  private isPersonSelected(person: MeetingAttendeePerson): boolean {
    const current: MeetingAttendeePerson[] = this.getRoleList(this.pickerRole);
    return current.some((p: MeetingAttendeePerson) => p.id === person.id && p.name === person.name);
  }

  private togglePersonSelection(person: MeetingAttendeePerson): void {
    const current: MeetingAttendeePerson[] = this.getRoleList(this.pickerRole).slice();
    const idx: number = current.findIndex((p: MeetingAttendeePerson) => p.id === person.id && p.name === person.name);
    if (idx >= 0) {
      current.splice(idx, 1);
    } else {
      if (this.pickerRole === 'compere') {
        // 主持人支持单人或多人切换，追加到列表
        current.push(person);
      } else {
        current.push(person);
      }
    }
    this.setRoleList(this.pickerRole, current);
  }

  private addManualAttendee(): void {
    const name: string = this.pickerManualName.trim();
    if (name === '') {
      this.getUIContext().getPromptAction().showToast({ message: '请输入要添加的人员姓名' });
      return;
    }
    const person = new MeetingAttendeePerson('manual_' + name, name, '手动添加');
    const current: MeetingAttendeePerson[] = this.getRoleList(this.pickerRole).slice();
    if (!current.some((p: MeetingAttendeePerson) => p.name === name)) {
      current.push(person);
      this.setRoleList(this.pickerRole, current);
    }
    this.pickerManualName = '';
  }

  private formatNamesSummary(list: MeetingAttendeePerson[]): string {
    if (list.length === 0) {
      return '点击添加';
    }
    const names: string[] = list.map((p: MeetingAttendeePerson) => p.name);
    return names.join('、');
  }

  private openPersonPickerFor(role: string): void {
    this.pickerRole = role;
    this.pickerKeyword = '';
    this.pickerCandidates = this.defaultCandidates;
    this.showPersonPicker = true;
    if (this.defaultCandidates.length === 0 && !this.pickerLoading) {
      this.loadDefaultContacts();
    }
  }

  private roleTitle(role: string): string {
    if (role === 'compere') {
      return '选择主持人';
    }
    if (role === 'must') {
      return '选择必须参加人员';
    }
    return '选择参会人员';
  }

  private openDateTimePickerFor(target: string): void {
    this.dateTimeTarget = target;
    this.pickerDate = new Date();
    this.showDateTimeSheet = true;
  }

  private pad2(n: number): string {
    return n < 10 ? '0' + n : '' + n;
  }

  private applyPickedDateTime(): void {
    const d: Date = this.pickerDate;
    const formatted: string = d.getFullYear() + '-' +
      this.pad2(d.getMonth() + 1) + '-' +
      this.pad2(d.getDate()) + ' ' +
      this.pad2(d.getHours()) + ':' +
      this.pad2(d.getMinutes());
    if (this.dateTimeTarget === 'start') {
      this.startTimeText = formatted;
    } else if (this.dateTimeTarget === 'end') {
      this.endTimeText = formatted;
    } else {
      this.remindTimeText = formatted;
    }
    this.showDateTimeSheet = false;
  }

  private submitMeeting(): void {
    if (this.titleInput.trim() === '') {
      this.getUIContext().getPromptAction().showToast({ message: '请输入会议主题' });
      return;
    }
    if (this.locationInput.trim() === '') {
      this.getUIContext().getPromptAction().showToast({ message: '请输入或选择会议地点' });
      return;
    }
    if (this.startTimeText === '' || this.endTimeText === '') {
      this.getUIContext().getPromptAction().showToast({ message: '请选择会议开始与结束时间' });
      return;
    }
    if (this.compereList.length === 0 && this.attendList.length === 0 && this.mustAttendList.length === 0) {
      this.getUIContext().getPromptAction().showToast({ message: '请至少添加一位主持人或参会人员' });
      return;
    }
    this.getUIContext().getPromptAction().showToast({ message: '会议已提交' });
    router.back();
  }

  @Builder
  formLabel(iconRes: Resource, label: string) {
    Image(iconRes)
      .width(16)
      .height(16)
      .margin({ right: 12 })
    Text(label)
      .fontSize(16)
      .fontColor($r('app.color.common_color_1'))
      .margin({ right: 12 })
  }

  @Builder
  personRow(label: string, iconRes: Resource, roleKey: string, list: MeetingAttendeePerson[]) {
    Column() {
      Row() {
        Image(iconRes)
          .width(16)
          .height(16)
          .margin({ left: 12, right: 12 })
        Text(label)
          .fontSize(16)
          .fontColor($r('app.color.common_color_1'))
          .margin({ right: 12 })
        Text(list.length + '人')
          .fontSize(16)
          .fontColor('#326EA3')
          .margin({ right: 12 })
        Text(this.formatNamesSummary(list))
          .fontSize(14)
          .fontColor(list.length > 0 ? $r('app.color.common_color_1') : $r('app.color.common_color_35'))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .layoutWeight(1)
          .textAlign(TextAlign.End)
          .margin({ right: 10 })
        Image($r('app.media.mobile_campus_meeting_addto_white'))
          .width(21)
          .height(21)
          .margin({ right: 12 })
      }
      .width('100%')
      .padding({ top: 16, bottom: 16 })
      .alignItems(VerticalAlign.Center)
      .hoverEffect(HoverEffect.Highlight)
      .onClick(() => {
        this.openPersonPickerFor(roleKey);
      })
    }
    .width('100%')
    .border({ width: { bottom: 0.5 }, color: { bottom: $r('app.color.common_color_36') } })
  }

  @Builder
  personPickerSheet() {
    Column({ space: 10 }) {
      Row() {
        Text('取消')
          .fontSize(15)
          .fontColor('#666666')
          .padding({ left: 8, right: 8, top: 6, bottom: 6 })
          .onClick(() => {
            this.showPersonPicker = false;
          })
        Text(this.roleTitle(this.pickerRole))
          .fontSize(17)
          .fontWeight(FontWeight.Bold)
          .fontColor('#222222')
          .layoutWeight(1)
          .textAlign(TextAlign.Center)
        Text('完成(' + this.getRoleList(this.pickerRole).length + ')')
          .fontSize(15)
          .fontWeight(FontWeight.Medium)
          .fontColor('#326EA3')
          .padding({ left: 8, right: 8, top: 6, bottom: 6 })
          .onClick(() => {
            this.showPersonPicker = false;
          })
      }
      .width('100%')
      .padding({ left: 12, right: 12, top: 12 })

      // 已选人员标签栏
      if (this.getRoleList(this.pickerRole).length > 0) {
        Scroll() {
          Row({ space: 8 }) {
            ForEach(this.getRoleList(this.pickerRole), (p: MeetingAttendeePerson) => {
              Row({ space: 4 }) {
                Text(p.name)
                  .fontSize(13)
                  .fontColor('#326EA3')
                Text('×')
                  .fontSize(14)
                  .fontColor('#326EA3')
              }
              .padding({ left: 10, right: 10, top: 5, bottom: 5 })
              .borderRadius(14)
              .backgroundColor('#E9F2FA')
              .onClick(() => {
                this.togglePersonSelection(p);
              })
            }, (p: MeetingAttendeePerson) => p.id + '_' + p.name)
          }
          .padding({ left: 12, right: 12 })
        }
        .scrollable(ScrollDirection.Horizontal)
        .scrollBar(BarState.Off)
        .width('100%')
      }

      // 通讯录搜索栏
      Row({ space: 8 }) {
        TextInput({ text: this.pickerKeyword, placeholder: '搜索校内通讯录姓名/教职工/学生' })
          .fontSize(14)
          .layoutWeight(1)
          .height(38)
          .backgroundColor($r('app.color.white'))
          .borderRadius(8)
          .onChange((val: string) => {
            this.pickerKeyword = val;
          })
          .onSubmit(() => {
            this.searchContacts(this.pickerKeyword);
          })
        Text('搜索')
          .fontSize(14)
          .fontColor($r('app.color.white'))
          .padding({ left: 14, right: 14, top: 9, bottom: 9 })
          .borderRadius(8)
          .backgroundColor('#326EA3')
          .onClick(() => {
            this.searchContacts(this.pickerKeyword);
          })
      }
      .width('100%')
      .padding({ left: 12, right: 12 })

      // 手动快速添加姓名栏
      Row({ space: 8 }) {
        TextInput({ text: this.pickerManualName, placeholder: '或直接输入参会人姓名添加' })
          .fontSize(14)
          .layoutWeight(1)
          .height(38)
          .backgroundColor($r('app.color.white'))
          .borderRadius(8)
          .onChange((val: string) => {
            this.pickerManualName = val;
          })
        Text('添加')
          .fontSize(14)
          .fontColor('#326EA3')
          .padding({ left: 14, right: 14, top: 9, bottom: 9 })
          .borderRadius(8)
          .backgroundColor('#E9F2FA')
          .onClick(() => {
            this.addManualAttendee();
          })
      }
      .width('100%')
      .padding({ left: 12, right: 12 })

      if (this.pickerLoading) {
        Column() {
          LoadingProgress().width(32).height(32)
          Text('正在加载通讯录联系人...')
            .fontSize(13)
            .fontColor('#888888')
            .margin({ top: 6 })
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else if (this.pickerCandidates.length === 0) {
        Column() {
          Text('未找到匹配联系人，可上方输入关键字搜索或手动添加')
            .fontSize(14)
            .fontColor('#888888')
            .textAlign(TextAlign.Center)
            .padding(24)
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else {
        List() {
          ForEach(this.pickerCandidates, (item: MeetingAttendeePerson, idx: number) => {
            ListItem() {
              Row() {
                Column({ space: 3 }) {
                  Text(item.name)
                    .fontSize(16)
                    .fontColor('#222222')
                  if (item.dept !== '') {
                    Text(item.dept)
                      .fontSize(12)
                      .fontColor('#888888')
                  }
                }
                .alignItems(HorizontalAlign.Start)
                .layoutWeight(1)

                Text(this.isPersonSelected(item) ? '已选 ✓' : '+ 选择')
                  .fontSize(13)
                  .fontColor(this.isPersonSelected(item) ? $r('app.color.white') : '#326EA3')
                  .padding({ left: 12, right: 12, top: 6, bottom: 6 })
                  .borderRadius(14)
                  .backgroundColor(this.isPersonSelected(item) ? '#326EA3' : '#E9F2FA')
              }
              .width('100%')
              .padding({ left: 16, right: 16, top: 12, bottom: 12 })
              .backgroundColor($r('app.color.white'))
              .border({ width: { bottom: 0.5 }, color: { bottom: '#EEEEEE' } })
              .onClick(() => {
                this.togglePersonSelection(item);
              })
            }
          }, (item: MeetingAttendeePerson, idx: number) => item.id + '_' + item.name + '_' + idx)
        }
        .width('100%')
        .layoutWeight(1)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F6F8')
  }

  @Builder
  dateTimePickerSheet() {
    Column({ space: 12 }) {
      Row() {
        Text('取消')
          .fontSize(15)
          .fontColor('#666666')
          .padding(8)
          .onClick(() => {
            this.showDateTimeSheet = false;
          })
        Text(this.dateTimeTarget === 'start'
          ? '选择会议开始时间'
          : (this.dateTimeTarget === 'end' ? '选择会议结束时间' : '选择提醒时间'))
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor('#222222')
          .layoutWeight(1)
          .textAlign(TextAlign.Center)
        Text('确定')
          .fontSize(15)
          .fontWeight(FontWeight.Medium)
          .fontColor('#326EA3')
          .padding(8)
          .onClick(() => {
            this.applyPickedDateTime();
          })
      }
      .width('100%')
      .padding({ left: 12, right: 12, top: 10 })

      Row() {
        DatePicker({
          start: new Date('2024-01-01'),
          end: new Date('2030-12-31'),
          selected: this.pickerDate
        })
          .layoutWeight(3)
          .height(180)
          .onDateChange((val: Date) => {
            this.pickerDate.setFullYear(val.getFullYear(), val.getMonth(), val.getDate());
          })
        TimePicker({
          selected: this.pickerDate
        })
          .useMilitaryTime(true)
          .layoutWeight(2)
          .height(180)
          .onChange((val: TimePickerResult) => {
            if (val.hour >= 0 && val.minute >= 0) {
              this.pickerDate.setHours(val.hour, val.minute, 0);
            }
          })
      }
      .width('100%')
      .padding({ left: 8, right: 8 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.white'))
  }

  build() {
    Column() {
      TitleBar({ title: '新增会议', showBack: true })

      Scroll() {
        Column() {
          // 顶部 12vp 灰色分隔
          Divider()
            .color($r('app.color.common_color_6'))
            .strokeWidth(12)
            .width('100%')

          // 会议主题行 48vp
          Row() {
            Text('*')
              .fontSize(17)
              .fontWeight(FontWeight.Bold)
              .fontColor($r('app.color.ybg_red'))
              .margin({ left: 4, right: 3 })
            this.formLabel($r('app.media.mobile_campus_meeting_title'), '会议主题')
            TextInput({ text: this.titleInput, placeholder: '请输入会议主题' })
              .fontSize(16)
              .fontColor($r('app.color.common_color_1'))
              .placeholderColor($r('app.color.common_color_35'))
              .placeholderFont({ size: 16 })
              .backgroundColor(Color.Transparent)
              .padding(0)
              .layoutWeight(1)
              .height('100%')
              .onChange((value: string) => {
                this.titleInput = value;
              })
          }
          .width('100%')
          .height(48)
          .alignItems(VerticalAlign.Center)
          .border({ width: { bottom: 0.5 }, color: { bottom: $r('app.color.common_color_36') } })
          .padding({ left: 8 })

          // 会议地点行 48vp（支持手输 + 选择真实校园会议室）
          Row() {
            Text('*')
              .fontSize(17)
              .fontWeight(FontWeight.Bold)
              .fontColor($r('app.color.ybg_red'))
              .margin({ left: 4, right: 3 })
            this.formLabel($r('app.media.mobile_campus_meeting_local'), '会议地点')
            TextInput({ text: this.locationInput, placeholder: '请输入或选择会议地点' })
              .fontSize(16)
              .fontColor($r('app.color.common_color_1'))
              .placeholderColor($r('app.color.common_color_35'))
              .placeholderFont({ size: 16 })
              .backgroundColor(Color.Transparent)
              .padding(0)
              .layoutWeight(1)
              .height('100%')
              .onChange((value: string) => {
                this.locationInput = value;
              })
            Text('选择会议室')
              .fontSize(13)
              .fontColor('#326EA3')
              .padding({ left: 8, right: 8, top: 5, bottom: 5 })
              .borderRadius(6)
              .backgroundColor('#E9F2FA')
              .margin({ right: 10 })
              .onClick(() => {
                router.pushUrl({ url: 'pages/MeetingSelectorPage' });
              })
          }
          .width('100%')
          .height(48)
          .alignItems(VerticalAlign.Center)
          .border({ width: { bottom: 0.5 }, color: { bottom: $r('app.color.common_color_36') } })
          .padding({ left: 8 })

          // 会议开始时间行 48vp
          Row() {
            Text('*')
              .fontSize(17)
              .fontWeight(FontWeight.Bold)
              .fontColor($r('app.color.ybg_red'))
              .margin({ left: 4, right: 3 })
            this.formLabel($r('app.media.mobile_campus_meeting_time'), '会议时间')
            Text(this.startTimeText === '' ? '请选择会议开始时间' : this.startTimeText)
              .fontSize(16)
              .fontColor(this.startTimeText === ''
                ? $r('app.color.common_color_35')
                : $r('app.color.common_color_1'))
              .layoutWeight(1)
              .maxLines(1)
            Image($r('app.media.mobile_campus_meeting_arrow_right'))
              .width(14)
              .height(14)
              .margin({ right: 12 })
          }
          .width('100%')
          .height(48)
          .alignItems(VerticalAlign.Center)
          .border({ width: { bottom: 0.5 }, color: { bottom: $r('app.color.common_color_36') } })
          .padding({ left: 8 })
          .onClick(() => {
            this.openDateTimePickerFor('start');
          })

          // 会议结束时间行 48vp
          Row() {
            Blank()
              .width(57)
            Text(this.endTimeText === '' ? '请选择会议结束时间' : this.endTimeText)
              .fontSize(16)
              .fontColor(this.endTimeText === ''
                ? $r('app.color.common_color_35')
                : $r('app.color.common_color_1'))
              .layoutWeight(1)
              .maxLines(1)
            Image($r('app.media.mobile_campus_meeting_arrow_right'))
              .width(14)
              .height(14)
              .margin({ right: 12 })
          }
          .width('100%')
          .height(48)
          .alignItems(VerticalAlign.Center)
          .onClick(() => {
            this.openDateTimePickerFor('end');
          })

          // 12vp 灰色分隔
          Divider()
            .color($r('app.color.common_color_6'))
            .strokeWidth(12)
            .width('100%')

          // 主持人 / 参会人员 / 必须参加（真实动态人数与所选名单）
          this.personRow('主持人', $r('app.media.mobile_campus_meeting_compere'), 'compere', this.compereList)
          this.personRow('参会人员', $r('app.media.mobile_campus_meeting_person'), 'attend', this.attendList)
          this.personRow('必须参加', $r('app.media.mobile_campus_meeting_person'), 'must', this.mustAttendList)

          // 外部人员（可编辑输入）
          Row() {
            Image($r('app.media.mobile_campus_meeting_person'))
              .width(16)
              .height(16)
              .margin({ left: 12, right: 12 })
            Text('外部人员')
              .fontSize(16)
              .fontColor($r('app.color.common_color_1'))
              .margin({ right: 12 })
            TextInput({ text: this.outsidePerson, placeholder: '如有外部参会人员请输入姓名（选填）' })
              .fontSize(15)
              .fontColor('#326EA3')
              .placeholderColor($r('app.color.common_color_35'))
              .backgroundColor(Color.Transparent)
              .padding(0)
              .layoutWeight(1)
              .height('100%')
              .onChange((val: string) => {
                this.outsidePerson = val;
              })
          }
          .width('100%')
          .height(48)
          .padding({ right: 10 })
          .alignItems(VerticalAlign.Center)

          // 12vp 灰色分隔
          Divider()
            .color($r('app.color.common_color_6'))
            .strokeWidth(12)
            .width('100%')

          // 会议通知 RadioGroup
          Column() {
            ForEach(this.notifyOptions, (option: NotifyOption) => {
              Row() {
                Circle({ width: 16, height: 16 })
                  .fill(this.notifyKey === option.key
                    ? $r('app.color.mobile_campus_primary_color_default')
                    : Color.Transparent)
                  .stroke($r('app.color.mobile_campus_primary_color_default'))
                  .strokeWidth(1)
                  .margin({ right: 8 })
                Text(option.label)
                  .fontSize(16)
                  .fontColor($r('app.color.common_color_1'))
              }
              .width('100%')
              .margin({ top: option.key === 'no' ? 0 : 16 })
              .alignItems(VerticalAlign.Center)
              .onClick(() => {
                this.notifyKey = option.key;
              })
            }, (option: NotifyOption) => option.key)

            if (this.notifyKey === 'specific') {
              Row() {
                Image($r('app.media.mobile_campus_meeting_select'))
                  .width(16)
                  .height(16)
                  .opacity(0)
                Text(this.remindTimeText === '' ? '请选择提醒时间' : this.remindTimeText)
                  .fontSize(16)
                  .fontColor(this.remindTimeText === ''
                    ? $r('app.color.common_color_35')
                    : $r('app.color.common_color_1'))
                  .margin({ left: 8 })
              }
              .width('100%')
              .margin({ top: 12 })
              .alignItems(VerticalAlign.Center)
              .onClick(() => {
                this.openDateTimePickerFor('remind');
              })
            }
          }
          .width('100%')
          .padding({ left: 10, right: 10, top: 12, bottom: 12 })

          // 12vp 灰色分隔
          Divider()
            .color($r('app.color.common_color_6'))
            .strokeWidth(12)
            .width('100%')

          // 底部双按钮列
          Row() {
            Column() {
              Text('.')
                .fontSize(12)
                .fontColor('#FDFFFF')
                .visibility(Visibility.None)
                .margin({ bottom: 3 })
              Text('新增会议')
                .fontSize(16)
                .fontColor($r('app.color.mobile_campus_meeting_add_textcolor'))
                .textAlign(TextAlign.Center)
                .width('100%')
                .padding({ top: 10, bottom: 10 })
                .backgroundColor($r('app.color.mobile_campus_primary_color_default'))
                .borderRadius(20)
                .onClick(() => {
                  this.submitMeeting();
                })
            }
            .layoutWeight(1)
            .alignItems(HorizontalAlign.Center)
            .margin({ left: 17, right: 7 })

            Column() {
              Text('提示：仅移动端流转')
                .fontSize(12)
                .fontColor('#FDFFFF')
                .textAlign(TextAlign.Center)
                .padding({ top: 5, bottom: 10 })
                .backgroundImage($r('app.media.mobile_campus_meeting_alert'))
                .backgroundImageSize(ImageSize.Contain)
                .backgroundImagePosition(Alignment.Center)
                .margin({ bottom: 3 })
              Text('提交')
                .fontSize(16)
                .fontColor($r('app.color.white'))
                .textAlign(TextAlign.Center)
                .width('100%')
                .padding({ top: 10, bottom: 10 })
                .backgroundColor($r('app.color.mobile_campus_primary_color'))
                .borderRadius(20)
                .onClick(() => {
                  this.submitMeeting();
                })
            }
            .layoutWeight(1)
            .alignItems(HorizontalAlign.Center)
            .margin({ left: 17, right: 7 })
          }
          .width('100%')
          .padding({ top: 4, bottom: 32 })
          .alignItems(VerticalAlign.Bottom)
          .backgroundColor($r('app.color.common_color_6'))
        }
        .width('100%')
        .backgroundColor($r('app.color.white'))
      }
      .width('100%')
      .layoutWeight(1)
      .align(Alignment.Top)
      .scrollBar(BarState.Off)
      .backgroundColor($r('app.color.common_color_6'))
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.common_color_6'))
    .bindSheet(this.showPersonPicker, this.personPickerSheet(), {
      height: 520,
      preferType: AdaptiveLayoutHelper.getSheetPreferType(this.currentBreakpoint, this.isCompactHeight),
      showClose: false,
      backgroundColor: '#F5F6F8'
    })
    .bindSheet(this.showDateTimeSheet, this.dateTimePickerSheet(), {
      height: 280,
      preferType: AdaptiveLayoutHelper.getSheetPreferType(this.currentBreakpoint, this.isCompactHeight),
      showClose: false,
      backgroundColor: $r('app.color.white')
    })
  }
}
