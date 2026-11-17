import { TitleBar } from '../components/TitleBar';

/**
 * 编辑课程页 — 1:1 复刻 edit_course.xml
 * 结构：LinearLayout(common_color_6) + toolbar_normal
 *   + 课程名输入行(ybg_white, padding 15vp, marginTop 15vp)：label 15fp color2 marginR 21vp + 输入框 + delete_icon
 *   + divider_thin
 *   + 课室输入行
 *   + divider_thin
 *   + 周数行：label 周数 + "点击修改上课周数"(ybg_black)
 *   + divider_thin
 *   + 节数行：label 节数 + "点击修改上课时间"(ybg_black)
 *   + divider_thin
 *   + 确定按钮：ybg_blue 圆角(coner_radius_normal 4vp)，marginH 25vp marginTop 24vp padding 12vp
 */
class EditCourseForm {
  courseName: string;
  place: string;
  weekNum: string;
  sectionNum: string;

  constructor(courseName: string, place: string, weekNum: string, sectionNum: string) {
    this.courseName = courseName;
    this.place = place;
    this.weekNum = weekNum;
    this.sectionNum = sectionNum;
  }
}

@Entry
@Component
struct EditCoursePage {
  @State form: EditCourseForm = new EditCourseForm('高等数学（上）', '第一教学楼A栋301', '第1-18周', '第1-2节');

  private confirm(): void {
    if (this.form.courseName === '') {
      this.getUIContext().getPromptAction().showToast({ message: '请输入课程名称' });
      return;
    }
    this.getUIContext().getPromptAction().showToast({ message: '课程修改成功' });
  }

  build() {
    Column() {
      TitleBar({ title: '编辑课程', showBack: true })

      // 课程名输入行
      Row() {
        Text('课程')
          .fontSize(15)
          .fontColor($r('app.color.common_color_2'))
          .margin({ right: 21 })
        TextInput({ placeholder: '请输入课程名称', text: this.form.courseName })
          .fontSize(15)
          .fontColor($r('app.color.ybg_black'))
          .placeholderColor($r('app.color.common_color_3'))
          .placeholderFont({ size: 15 })
          .maxLength(20)
          .backgroundColor(Color.Transparent)
          .padding(0)
          .layoutWeight(1)
          .height(40)
          .onChange((value: string) => {
            this.form.courseName = value;
          })
        if (this.form.courseName !== '') {
          Image($r('app.media.delete_icon'))
            .width(18)
            .height(18)
            .onClick(() => {
              this.form.courseName = '';
            })
        }
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)
      .padding(15)
      .margin({ top: 15 })
      .backgroundColor($r('app.color.ybg_white'))

      // divider_horizontal_grey_thin 0.5vp
      Divider()
        .color($r('app.color.common_color_5'))
        .strokeWidth(0.5)
        .width('100%')

      // 课室输入行
      Row() {
        Text('课室')
          .fontSize(15)
          .fontColor($r('app.color.common_color_2'))
          .margin({ right: 21 })
        TextInput({ placeholder: '请输入上课地点', text: this.form.place })
          .fontSize(15)
          .fontColor($r('app.color.ybg_black'))
          .placeholderColor($r('app.color.common_color_3'))
          .placeholderFont({ size: 15 })
          .maxLength(20)
          .backgroundColor(Color.Transparent)
          .padding(0)
          .layoutWeight(1)
          .height(40)
          .onChange((value: string) => {
            this.form.place = value;
          })
        if (this.form.place !== '') {
          Image($r('app.media.delete_icon'))
            .width(18)
            .height(18)
            .onClick(() => {
              this.form.place = '';
            })
        }
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)
      .padding(15)
      .backgroundColor($r('app.color.ybg_white'))

      // divider_horizontal_grey_thin 0.5vp
      Divider()
        .color($r('app.color.common_color_5'))
        .strokeWidth(0.5)
        .width('100%')

      // 周数行
      Row() {
        Text('周数')
          .fontSize(15)
          .fontColor($r('app.color.common_color_2'))
          .margin({ right: 21 })
        Text(this.form.weekNum === '' ? '点击修改上课周数' : this.form.weekNum)
          .fontSize(15)
          .fontColor($r('app.color.ybg_black'))
          .layoutWeight(1)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)
      .padding(15)
      .backgroundColor($r('app.color.ybg_white'))
      .onClick(() => {
        this.getUIContext().getPromptAction().showToast({ message: '点击修改上课周数' });
      })

      // divider_horizontal_grey_thin 0.5vp
      Divider()
        .color($r('app.color.common_color_5'))
        .strokeWidth(0.5)
        .width('100%')

      // 节数行
      Row() {
        Text('节数')
          .fontSize(15)
          .fontColor($r('app.color.common_color_2'))
          .margin({ right: 21 })
        Text(this.form.sectionNum === '' ? '点击修改上课时间' : this.form.sectionNum)
          .fontSize(15)
          .fontColor($r('app.color.ybg_black'))
          .layoutWeight(1)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)
      .padding(15)
      .backgroundColor($r('app.color.ybg_white'))
      .onClick(() => {
        this.getUIContext().getPromptAction().showToast({ message: '点击修改上课时间' });
      })

      // divider_horizontal_grey_thin 0.5vp
      Divider()
        .color($r('app.color.common_color_5'))
        .strokeWidth(0.5)
        .width('100%')

      // 确定按钮：ybg_blue 圆角，marginH 25vp marginTop 24vp padding 12vp
      Text('确定')
        .fontSize(17)
        .fontColor($r('app.color.ybg_white'))
        .width('100%')
        .textAlign(TextAlign.Center)
        .padding(12)
        .margin({ left: 25, right: 25, top: 24 })
        .borderRadius(4)
        .backgroundColor($r('app.color.ybg_blue'))
        .onClick(() => {
          this.confirm();
        })
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.common_color_6'))
  }
}
