import { TitleBar } from '../components/TitleBar';

/**
 * 新增会议 — 1:1 复刻（px_to_dip_N = N/2 vp, px_to_sp_N = N/2 fp）：
 * mobile_campus_meeting_activity_add_meeting.xml：竖向 LinearLayout bg common_color_6 + toolbar
 *   + ScrollView 白底：divider 12vp + 表单行 RelativeLayout 48vp（* 红 17fp / 图标+label 16fp #333 /
 *   TextInput 16fp hint #B8C0C9 / 底线 #DFE4EA）+ divider + 主持人/参会人员/必须参加（图标 21vp addto_white）
 *   + 外部人员 + divider + 会议通知 RadioGroup（radio 图标 drawablePadding 8）+ divider +
 *   底部双按钮列（alert 气泡图 12fp #FDFFFF / "新增会议" 16fp / "提交" 16fp 白字，paddingTop/Bottom 10）
 */

interface NotifyOption {
  key: string;
  label: string;
}

interface PersonSection {
  label: string;
  iconRes: Resource;
  count: number;
}

@Entry
@Component
struct MeetingAddPage {
  @State titleInput: string = '';
  @State locationInput: string = '';
  @State startTimeText: string = '';
  @State endTimeText: string = '';
  @State notifyKey: string = 'no';
  @State compereCount: number = 1;
  @State attendCount: number = 5;
  @State mustAttendCount: number = 2;
  @State outsidePerson: string = '张三（外校专家）';
  private notifyOptions: NotifyOption[] = [
    { key: 'no', label: '不通知' },
    { key: 'one', label: '会前一小时提醒' },
    { key: 'specific', label: '指定时间提醒' }
  ];
  private personSections: PersonSection[] = [
    { label: '主持人', iconRes: $r('app.media.mobile_campus_meeting_compere'), count: 1 },
    { label: '参会人员', iconRes: $r('app.media.mobile_campus_meeting_person'), count: 5 },
    { label: '必须参加', iconRes: $r('app.media.mobile_campus_meeting_person'), count: 2 }
  ];

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

          // 会议地点行 48vp
          Row() {
            Text('*')
              .fontSize(17)
              .fontWeight(FontWeight.Bold)
              .fontColor($r('app.color.ybg_red'))
              .margin({ left: 4, right: 3 })
            this.formLabel($r('app.media.mobile_campus_meeting_local'), '会议地点')
            TextInput({ text: this.locationInput, placeholder: '请输入会议地点' })
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
              .onClick(() => {
                this.startTimeText = '2026-11-17 09:00';
              })
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

          // 会议结束时间行 48vp（label invisible 占位 12+12+16+12）
          Row() {
            Row() {
              Image($r('app.media.mobile_campus_meeting_time'))
                .width(16)
                .height(16)
                .margin({ right: 12 })
                .opacity(0)
              Text('会议时间')
                .fontSize(16)
                .fontColor($r('app.color.common_color_1'))
                .margin({ right: 12 })
                .opacity(0)
            }
            .visibility(Visibility.None)
            Blank()
              .width(57)
            Text(this.endTimeText === '' ? '请选择会议结束时间' : this.endTimeText)
              .fontSize(16)
              .fontColor(this.endTimeText === ''
                ? $r('app.color.common_color_35')
                : $r('app.color.common_color_1'))
              .layoutWeight(1)
              .maxLines(1)
              .onClick(() => {
                this.endTimeText = '2026-11-17 11:00';
              })
            Image($r('app.media.mobile_campus_meeting_arrow_right'))
              .width(14)
              .height(14)
              .margin({ right: 12 })
          }
          .width('100%')
          .height(48)
          .alignItems(VerticalAlign.Center)

          // 12vp 灰色分隔
          Divider()
            .color($r('app.color.common_color_6'))
            .strokeWidth(12)
            .width('100%')

          // 主持人 / 参会人员 / 必须参加
          ForEach(this.personSections, (section: PersonSection) => {
            Row() {
              Image(section.iconRes)
                .width(16)
                .height(16)
                .margin({ left: 12, right: 12 })
              Text(section.label)
                .fontSize(16)
                .fontColor($r('app.color.common_color_1'))
                .margin({ right: 12 })
              Text(section.count + '人')
                .fontSize(16)
                .fontColor('#326EA3')
                .margin({ right: 12 })
              Blank()
              Image($r('app.media.mobile_campus_meeting_addto_white'))
                .width(21)
                .height(21)
                .margin({ right: 12 })
            }
            .width('100%')
            .padding({ top: 16, bottom: 16 })
            .alignItems(VerticalAlign.Center)
            .onClick(() => {
              this.getUIContext().getPromptAction().showToast({ message: '选择' + section.label });
            })
          }, (section: PersonSection) => section.label)

          // 外部人员
          Row() {
            Image($r('app.media.mobile_campus_meeting_person'))
              .width(16)
              .height(16)
              .margin({ left: 12, right: 12 })
            Text('外部人员')
              .fontSize(16)
              .fontColor($r('app.color.common_color_1'))
              .margin({ right: 12 })
            Text(this.outsidePerson)
              .fontSize(16)
              .fontColor('#326EA3')
              .layoutWeight(1)
              .maxLines(2)
              .padding({ right: 10 })
          }
          .width('100%')
          .padding({ top: 12, bottom: 12 })
          .alignItems(VerticalAlign.Center)

          // 12vp 灰色分隔
          Divider()
            .color($r('app.color.common_color_6'))
            .strokeWidth(12)
            .width('100%')

          // 会议通知 RadioGroup（padding 10/12.5/10/12）
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
                Text('请选择提醒时间')
                  .fontSize(16)
                  .fontColor($r('app.color.common_color_35'))
                  .margin({ left: 8 })
              }
              .width('100%')
              .margin({ top: 12 })
              .alignItems(VerticalAlign.Center)
              .onClick(() => {
                this.getUIContext().getPromptAction().showToast({ message: '选择提醒时间' });
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

          // 底部双按钮列（marginStart 17 marginEnd 7 / marginStart 17 marginEnd 14）
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
                  this.getUIContext().getPromptAction().showToast({ message: '会议已提交' });
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
  }
}
