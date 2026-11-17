import { TitleBar } from '../components/TitleBar';

/**
 * 添加课程页 — 1:1 复刻 mobile_campus_schedule_activity_add_course.xml
 * 结构：RelativeLayout(#F2F2F2) + toolbar_normal + 表单 + 底部提交按钮
 *
 * 数据源：无服务器接口 — ApiService 未提供添加课程端点，
 * 表单为本地默认值、提交为本地模拟，未接 ApiService。
 */
class AddCourseForm {
  courseName: string = '';
  place: string = '';
  weekNum: string = '';
  sectionNum: string = '';

  constructor(courseName: string, place: string, weekNum: string, sectionNum: string) {
    this.courseName = courseName;
    this.place = place;
    this.weekNum = weekNum;
    this.sectionNum = sectionNum;
  }
}

@Entry
@Component
struct AddCoursePage {
  @State form: AddCourseForm = new AddCourseForm('高等数学', '教学楼A栋302', '第1-18周', '第1-2节');

  private submit(): void {
    if (this.form.courseName === '') {
      this.getUIContext().getPromptAction().showToast({ message: '请输入课程名称' });
      return;
    }
    if (this.form.weekNum === '' || this.form.sectionNum === '') {
      this.getUIContext().getPromptAction().showToast({ message: '请选择上课周数和课程节数' });
      return;
    }
    this.getUIContext().getPromptAction().showToast({ message: '课程添加成功' });
  }

  build() {
    Column() {
      TitleBar({ title: '添加课程', showBack: true })

      Scroll() {
        Column() {
          // 课程名称输入行：高48vp(px96/2) paddingH 12vp(px24/2) marginTop 12vp
          Row() {
            Image($r('app.media.mobile_campus_schedule_title'))
              .width(23)
              .height(23)
            Text('课程名称')
              .fontSize(16)
              .fontColor($r('app.color.common_color_1'))
              .margin({ left: 12, right: 12 })
            TextInput({ placeholder: '请输入课程名称', text: this.form.courseName })
              .fontSize(16)
              .fontColor($r('app.color.common_color_1'))
              .placeholderColor($r('app.color.edit_hint_color'))
              .placeholderFont({ size: 16 })
              .maxLength(20)
              .height(48)
              .backgroundColor(Color.Transparent)
              .padding(0)
              .layoutWeight(1)
              .onChange((value: string) => {
                this.form.courseName = value;
              })
          }
          .width('100%')
          .height(48)
          .alignItems(VerticalAlign.Center)
          .padding({ left: 12, right: 12 })
          .margin({ top: 12 })
          .backgroundColor($r('app.color.white'))

          // divider_horizontal_grey_thin 0.5vp
          Divider()
            .color($r('app.color.common_color_5'))
            .strokeWidth(0.5)
            .width('100%')

          // 上课地点输入行
          Row() {
            Image($r('app.media.mobile_campus_schedule_local'))
              .width(23)
              .height(23)
            Text('上课地点')
              .fontSize(16)
              .fontColor($r('app.color.common_color_1'))
              .margin({ left: 12, right: 12 })
            TextInput({ placeholder: '请输入上课地点', text: this.form.place })
              .fontSize(16)
              .fontColor($r('app.color.common_color_1'))
              .placeholderColor($r('app.color.edit_hint_color'))
              .placeholderFont({ size: 16 })
              .maxLength(20)
              .height(48)
              .backgroundColor(Color.Transparent)
              .padding(0)
              .layoutWeight(1)
              .onChange((value: string) => {
                this.form.place = value;
              })
          }
          .width('100%')
          .height(48)
          .alignItems(VerticalAlign.Center)
          .padding({ left: 12, right: 12 })
          .backgroundColor($r('app.color.white'))

          // divider_horizontal_grey_thin 0.5vp
          Divider()
            .color($r('app.color.common_color_5'))
            .strokeWidth(0.5)
            .width('100%')

          // 课程周数选择行：高48vp paddingH 12vp marginTop 15vp(px30/2)
          Row() {
            Image($r('app.media.mobile_campus_schedule_class_b'))
              .width(23)
              .height(23)
            Text('课程周数')
              .fontSize(16)
              .fontColor($r('app.color.common_color_1'))
              .margin({ left: 12, right: 12 })
            Text(this.form.weekNum === '' ? '点击修改上课周数' : this.form.weekNum)
              .fontSize(16)
              .fontColor(this.form.weekNum === '' ? $r('app.color.edit_hint_color') : $r('app.color.common_color_1'))
              .layoutWeight(1)
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
          }
          .width('100%')
          .height(48)
          .alignItems(VerticalAlign.Center)
          .padding({ left: 12, right: 12 })
          .margin({ top: 15 })
          .backgroundColor($r('app.color.white'))
          .onClick(() => {
            this.getUIContext().getPromptAction().showToast({ message: '点击修改上课周数' });
          })

          // divider_horizontal_grey_thin 0.5vp
          Divider()
            .color($r('app.color.common_color_5'))
            .strokeWidth(0.5)
            .width('100%')

          // 课程节数选择行：高48vp paddingH 12vp
          Row() {
            Image($r('app.media.mobile_campus_schedule_class_b'))
              .width(23)
              .height(23)
            Text('课程节数')
              .fontSize(16)
              .fontColor($r('app.color.common_color_1'))
              .margin({ left: 12, right: 12 })
            Text(this.form.sectionNum === '' ? '点击修改上课时间' : this.form.sectionNum)
              .fontSize(16)
              .fontColor(this.form.sectionNum === '' ? $r('app.color.edit_hint_color') : $r('app.color.common_color_1'))
              .layoutWeight(1)
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
          }
          .width('100%')
          .height(48)
          .alignItems(VerticalAlign.Center)
          .padding({ left: 12, right: 12 })
          .backgroundColor($r('app.color.white'))
          .onClick(() => {
            this.getUIContext().getPromptAction().showToast({ message: '点击修改上课时间' });
          })

          // divider_horizontal_grey_thin 0.5vp
          Divider()
            .color($r('app.color.common_color_5'))
            .strokeWidth(0.5)
            .width('100%')
        }
        .width('100%')
      }
      .width('100%')
      .layoutWeight(1)
      .scrollBar(BarState.Off)

      // 提交按钮：高40vp(px80/2) 圆角4vp(px8/2) marginH 12vp marginTop 48vp marginBottom 27vp(px54/2)
      Text('提交')
        .fontSize(16)
        .fontColor($r('app.color.white'))
        .width('100%')
        .height(40)
        .textAlign(TextAlign.Center)
        .borderRadius(4)
        .backgroundColor(this.form.courseName === '' ? $r('app.color.edit_hint_color') : $r('app.color.mobile_campus_schedule_confirm_blue'))
        .margin({ left: 12, right: 12, top: 48, bottom: 27 })
        .onClick(() => {
          this.submit();
        })
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.common_color_6'))
  }
}
