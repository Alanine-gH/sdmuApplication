import { TitleBar } from '../components/TitleBar';

/**
 * 添加日程页 — 1:1 复刻 mobile_campus_schedule_activity_add_schedule.xml
 *   + view_add_schedule_input.xml + view_add_schedule_select.xml + view_schedule_detail.xml
 * 结构：RelativeLayout(#F2F2F2) + toolbar_normal("添加日程") + ScrollView
 *   1. AddScheduleInputView：白底 paddingL 12vp
 *      - "日程标题"/"日程地点" 行 高48vp(px_to_dip_96) 图标 drawablePadding 12vp + divider 0.5vp
 *      - "日程时间" 行 marginTop 12vp：开始/结束时间行 高48vp + arrow_right
 *   2. ScheduleDetailView：白底 marginTop 12vp "日程详情" 16fp(px_to_sp_32) + 详情输入 maxLength 100
 *   3. AddScheduleSelectView×3：白底 paddingL 12vp marginTop 12vp，标题 marginTop 6vp(px_to_dip_12)
 *      + RadioGroup 选项行（日程提醒/重要程度/同步到系统日程）
 *   4. tvSubmit：底部 高40vp(px_to_dip_80) marginH 12vp marginTop 19vp(px_to_dip_38) marginBottom 12vp
 *      圆角4vp(px_to_dip_8) #1B68B6 白字 16fp
 *
 * 数据源：无服务器接口 — ApiService 未提供添加日程端点，提交为本地模拟，未接 ApiService。
 */
class SelectOption {
  label: string;

  constructor(label: string) {
    this.label = label;
  }
}

@Entry
@Component
struct ScheduleAddPage {
  @State title: string = '';
  @State location: string = '';
  @State startTime: string = '2026-11-18 08:30';
  @State endTime: string = '2026-11-18 10:10';
  @State detail: string = '';
  @State selectedNotify: number = 0;
  @State selectedImportance: number = 0;
  @State selectedSync: number = 0;
  private notifyOptions: SelectOption[] = [
    new SelectOption('不提醒'),
    new SelectOption('日程开始时'),
    new SelectOption('5分钟前'),
    new SelectOption('15分钟前'),
    new SelectOption('1小时前'),
    new SelectOption('1天前')
  ];
  private importanceOptions: SelectOption[] = [
    new SelectOption('普通'),
    new SelectOption('重要')
  ];
  private syncOptions: SelectOption[] = [
    new SelectOption('是'),
    new SelectOption('否')
  ];

  private submit(): void {
    if (this.title === '') {
      this.getUIContext().getPromptAction().showToast({ message: '请输入日程标题' });
      return;
    }
    this.getUIContext().getPromptAction().showToast({ message: '日程添加成功' });
  }

  @Builder
  RadioColumn(options: SelectOption[], selected: number, onChange: (index: number) => void) {
    Column() {
      ForEach(options, (option: SelectOption, index: number) => {
        Row() {
          Row() {
            if (index === selected) {
              Circle({ width: 6, height: 6 })
                .fill($r('app.color.mobile_campus_schedule_confirm_blue'))
            }
          }
          .width(16)
          .height(16)
          .borderRadius(8)
          .border({ width: 1, color: $r('app.color.mobile_campus_schedule_confirm_blue') })
          .justifyContent(FlexAlign.Center)
          .margin({ right: 8 })

          Text(option.label)
            .fontSize(16)
            .fontColor($r('app.color.common_color_1'))
        }
        .width('100%')
        .height(48)
        .alignItems(VerticalAlign.Center)
        .padding({ right: 12 })
        .onClick(() => {
          onChange(index);
        })
      }, (option: SelectOption) => option.label)
    }
    .width('100%')
  }

  /** 带单选列的设置卡（@Builder不支持lambda参数，改为合并实现） */
  @Builder
  SelectCardWithRadio(title: string, options: SelectOption[], selected: number, onPick: (index: number) => void) {
    Column() {
      Text(title)
        .fontSize(16)
        .fontColor($r('app.color.common_color_1'))
        .margin({ top: 6 })
      Column() {
        Column() {
          ForEach(options, (opt: SelectOption, index: number) => {
            Text(opt.label)
              .fontSize(14)
              .fontColor(index === selected ? $r('app.color.ybg_blue') : $r('app.color.common_color_3'))
              .padding({ top: 8, bottom: 8 })
              .width('100%')
              .onClick(() => {
                onPick(index);
              })
          }, (opt: string) => 'radio_' + opt)
        }
        .width('100%')
      }
      .width('100%')
      .layoutWeight(1)
      .padding({ left: 12 })
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
    .padding({ left: 12, right: 12, bottom: 12 })
    .backgroundColor($r('app.color.white'))
    .margin({ top: 12 })
  }
  @Builder
  InputRow(label: string, placeholder: string, text: string, onChange: (value: string) => void) {
    Column() {
      Row() {
        Text(label)
          .fontSize(16)
          .fontColor($r('app.color.common_color_1'))
        TextInput({ placeholder: placeholder, text: text })
          .fontSize(16)
          .fontColor($r('app.color.common_color_1'))
          .placeholderColor($r('app.color.edit_hint_color'))
          .placeholderFont({ size: 16 })
          .height(48)
          .backgroundColor(Color.Transparent)
          .padding(0)
          .layoutWeight(1)
          .margin({ left: 24 })
          .onChange((value: string) => {
            onChange(value);
          })
      }
      .width('100%')
      .height(48)
      .alignItems(VerticalAlign.Center)

      Divider()
        .color($r('app.color.common_color_5'))
        .strokeWidth(0.5)
    }
    .width('100%')
  }

  build() {
    Column() {
      TitleBar({ title: '添加日程', showBack: true })

      Scroll() {
        Column() {
          // AddScheduleInputView：白底 paddingL 12vp
          Column() {
            this.InputRow('日程标题', '请输入日程标题', this.title, (value: string) => {
              this.title = value;
            })
            this.InputRow('日程地点', '请输入日程地点', this.location, (value: string) => {
              this.location = value;
            })

            // 日程时间行 marginTop 12vp
            Row() {
              Text('日程时间')
                .fontSize(16)
                .fontColor($r('app.color.common_color_1'))
                .margin({ top: 12 })

              Column() {
                Row() {
                  Text(this.startTime)
                    .fontSize(16)
                    .fontColor($r('app.color.common_color_1'))
                    .layoutWeight(1)
                  Image($r('app.media.arrow_right'))
                    .width(12)
                    .height(12)
                    .objectFit(ImageFit.Contain)
                }
                .width('100%')
                .height(48)
                .alignItems(VerticalAlign.Center)
                .padding({ right: 12 })

                Divider()
                  .color($r('app.color.common_color_5'))
                  .strokeWidth(0.5)

                Row() {
                  Text(this.endTime)
                    .fontSize(16)
                    .fontColor($r('app.color.common_color_1'))
                    .layoutWeight(1)
                  Image($r('app.media.arrow_right'))
                    .width(12)
                    .height(12)
                    .objectFit(ImageFit.Contain)
                }
                .width('100%')
                .height(48)
                .alignItems(VerticalAlign.Center)
                .padding({ right: 12 })
              }
              .layoutWeight(1)
              .margin({ left: 24 })
            }
            .width('100%')
            .alignItems(VerticalAlign.Top)
          }
          .width('100%')
          .padding({ left: 12, bottom: 12 })
          .backgroundColor($r('app.color.white'))

          // ScheduleDetailView：白底 marginTop 12vp
          Column() {
            Row() {
              Text('日程详情')
                .fontSize(16)
                .fontColor($r('app.color.common_color_1'))
              TextInput({ placeholder: '请输入日程详情', text: this.detail })
                .fontSize(16)
                .fontColor($r('app.color.common_color_1'))
                .placeholderColor($r('app.color.edit_hint_color'))
                .placeholderFont({ size: 16 })
                .maxLength(100)
                .height(48)
                .backgroundColor(Color.Transparent)
                .padding(0)
                .layoutWeight(1)
                .margin({ left: 24, right: 12 })
                .onChange((value: string) => {
                  this.detail = value;
                })
            }
            .width('100%')
            .height(48)
            .alignItems(VerticalAlign.Center)
          }
          .width('100%')
          .padding({ left: 12, top: 12 })
          .backgroundColor($r('app.color.white'))
          .margin({ top: 12 })

          // selectNotifyView：日程提醒
          this.SelectCardWithRadio('日程提醒', this.notifyOptions, this.selectedNotify, (index: number) => {
            this.selectedNotify = index;
          })

          // selectImportanceView：重要程度
          this.SelectCardWithRadio('重要程度', this.importanceOptions, this.selectedImportance, (index: number) => {
            this.selectedImportance = index;
          })

          // systemSchedule：同步到系统日程
          this.SelectCardWithRadio('同步到系统日程', this.syncOptions, this.selectedSync, (index: number) => {
            this.selectedSync = index;
          })
        }
        .width('100%')
      }
      .width('100%')
      .layoutWeight(1)
      .scrollBar(BarState.Off)

      // tvSubmit：高40vp marginH 12vp marginTop 19vp marginBottom 12vp 圆角4 #1B68B6
      Row() {
        Text('提交')
          .fontSize(16)
          .fontColor($r('app.color.white'))
          .textAlign(TextAlign.Center)
          .width('100%')
          .height(40)
          .backgroundColor($r('app.color.mobile_campus_schedule_confirm_blue'))
          .borderRadius(4)
          .onClick(() => {
            this.submit();
          })
      }
      .width('100%')
      .padding({ left: 12, right: 12, top: 19, bottom: 12 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.mobile_campus_bg_color'))
  }
}






