import { TitleBar } from '../components/TitleBar';

/**
 * 考试科目处理页 — 1:1 复刻 examination_handleexamcourse.xml（12KB）
 * 结构：toolbar + ScrollView(common_color_6) >
 *   1. 科目输入行（TextSize2.Color1 17fp #333 + EditText hint #CECECE + 清除钮）
 *      分隔线 divider_horizontal_grey_thin 0.5vp
 *   2. 考试时间行（点击选择 → tv显示 + arrow_right2）
 *   3. 考试地点输入行 + 分隔线
 *   4. 座位号输入行 + 分隔线
 *   5. 考号输入行 + 分隔线(normal)
 *   6. 提醒时间选择行（arrow_right2）
 *   7. 注意事项行（16dip examnation_attention图标 + TextSize4.Color7 12fp #18B4ED）
 *   8. 「同考试人」分组标题（TextSize2.Color2 17fp #555）+ 同考试人编辑区
 *   底部：确定提交
 */
@Entry
@Component
struct HandleExamCoursePage {
  @State subject: string = '';
  @State examTime: string = '';
  @State place: string = '';
  @State seatNo: string = '';
  @State examNo: string = '';
  @State alarmTime: string = '';

  @Builder
  inputRow(label: string, hint: string, value: string, onInput: (v: string) => void) {
    Column() {
      Row() {
        Text(label)
          .fontSize(17)
          .fontColor($r('app.color.common_color_1'))
          .margin({ left: 15 })
        TextInput({ placeholder: hint, text: value })
          .fontSize(17)
          .fontColor($r('app.color.common_color_1'))
          .placeholderColor($r('app.color.common_color_4'))
          .placeholderFont({ size: 17 })
          .height(48)
          .backgroundColor(Color.Transparent)
          .padding({ left: 0, right: 15 })
          .layoutWeight(1)
          .onChange((v: string) => {
            onInput(v);
          })
      }
      .width('100%')
      .height(48)
      .alignItems(VerticalAlign.Center)
      .backgroundColor($r('app.color.white'))
    }
    .width('100%')
  }

  @Builder
  selectRow(label: string, value: string, onPick: () => void) {
    Column() {
      Row() {
        Text(label)
          .fontSize(17)
          .fontColor($r('app.color.common_color_1'))
          .margin({ left: 15 })
        Text(value === '' ? '请选择' : value)
          .fontSize(17)
          .fontColor(value === '' ? $r('app.color.common_color_4') : $r('app.color.common_color_1'))
          .layoutWeight(1)
          .textAlign(TextAlign.End)
          .margin({ right: 8 })
        Image($r('app.media.arrow_right2'))
          .width(14)
          .height(14)
          .margin({ right: 15 })
      }
      .width('100%')
      .height(48)
      .alignItems(VerticalAlign.Center)
      .backgroundColor($r('app.color.white'))
      .onClick(() => {
        onPick();
      })
    }
    .width('100%')
  }

  @Builder
  thinDivider() {
    Divider()
      .color($r('app.color.common_color_5'))
      .strokeWidth(0.5)
      .width('100%')
  }

  build() {
    Column() {
      TitleBar({ title: '考试科目处理', showBack: true })

      Scroll() {
        Column() {
          // 1. 科目
          this.inputRow('科目', '输入考试科目', this.subject, (v: string) => {
            this.subject = v;
          })
          this.thinDivider()

          // 2. 考试时间（选择行）
          this.selectRow('考试时间', this.examTime, () => {
            this.examTime = '2026-12-28 09:00';
          })
          this.thinDivider()

          // 3. 考试地点
          this.inputRow('考试地点', '输入考试地点', this.place, (v: string) => {
            this.place = v;
          })
          this.thinDivider()

          // 4. 座位号
          this.inputRow('座位号', '输入座位号', this.seatNo, (v: string) => {
            this.seatNo = v;
          })
          this.thinDivider()

          // 5. 考号
          this.inputRow('考号', '输入考号', this.examNo, (v: string) => {
            this.examNo = v;
          })
          Row()
            .width('100%')
            .height(15)
            .backgroundColor($r('app.color.common_color_6'))

          // 6. 提醒时间
          this.selectRow('提醒时间', this.alarmTime, () => {
            this.alarmTime = '考前30分钟';
          })

          // 7. 注意事项（16dip图标 + TextSize4.Color7 12fp #18B4ED）
          Row() {
            Image($r('app.media.examination_time'))
              .width(16)
              .height(16)
              .margin({ left: 15, right: 8 })
            Text('添加考试信息后可在考试安排中查看，并可设置提醒')
              .fontSize(12)
              .fontColor($r('app.color.ybg_blue'))
              .layoutWeight(1)
              .margin({ right: 15 })
          }
          .width('100%')
          .padding({ top: 10, bottom: 10 })
          .alignItems(VerticalAlign.Center)

          // 8. 同考试人分组（TextSize2.Color2 17fp #555）
          Text('同考试人')
            .fontSize(17)
            .fontColor($r('app.color.common_color_2'))
            .padding({ left: 15, top: 10, bottom: 10 })
            .width('100%')
            .alignSelf(ItemAlign.Start)

          Text('暂无同考试人，可在通讯录中添加')
            .fontSize(13)
            .fontColor($r('app.color.common_color_3'))
            .padding({ left: 15, bottom: 20 })
            .width('100%')
            .alignSelf(ItemAlign.Start)
        }
        .width('100%')
      }
      .width('100%')
      .layoutWeight(1)
      .backgroundColor($r('app.color.common_color_6'))

      // 底部确定
      Text('确定')
        .fontSize(17)
        .fontColor($r('app.color.white'))
        .width('100%')
        .height(48)
        .textAlign(TextAlign.Center)
        .backgroundColor($r('app.color.ybg_blue'))
        .onClick(() => {
          if (this.subject === '') {
            this.getUIContext().getPromptAction().showToast({ message: '请输入科目' });
            return;
          }
          this.getUIContext().getPromptAction().showToast({ message: '已保存' });
        })
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.common_color_6'))
  }
}
