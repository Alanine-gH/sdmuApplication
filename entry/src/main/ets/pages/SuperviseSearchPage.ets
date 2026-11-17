import { TitleBar } from '../components/TitleBar';

/**
 * 督导搜索 — 1:1 复刻 mobile_campus_supervise_activity_supervise_search.xml
 * + toolbar_search.xml（44vp 白底工具栏：搜索框 #F2F2F2 描边 #DADBDF 圆角 4，右侧"取消"）
 * + view_search.xml（结果行 48vp：姓名 17fp + 专业 14fp）
 */
class SuperviseTeacher {
  id: string;
  name: string;
  phone: string;
  major: string;

  constructor(id: string, name: string, phone: string, major: string) {
    this.id = id;
    this.name = name;
    this.phone = phone;
    this.major = major;
  }
}

@Entry
@Component
struct SuperviseSearchPage {
  @State searchKey: string = '';
  @State teacherList: SuperviseTeacher[] = [
    new SuperviseTeacher('t1', '张明', '13812340001', '数学与统计学院'),
    new SuperviseTeacher('t2', '李华', '13812340002', '外国语学院'),
    new SuperviseTeacher('t3', '王强', '13812340003', '计算机学院'),
    new SuperviseTeacher('t4', '刘芳', '13812340004', '物理与电子工程学院'),
    new SuperviseTeacher('t5', '陈静', '13812340005', '马克思主义学院'),
    new SuperviseTeacher('t6', '赵磊', '13812340006', '经济管理学院'),
    new SuperviseTeacher('t7', '孙丽', '13812340007', '文学与传媒学院'),
    new SuperviseTeacher('t8', '周涛', '13812340008', '化学化工学院')
  ];

  private matchTeacher(teacher: SuperviseTeacher): boolean {
    if (this.searchKey === '') {
      return true;
    }
    return teacher.name.indexOf(this.searchKey) >= 0 || teacher.phone.indexOf(this.searchKey) >= 0;
  }

  build() {
    Column() {
      // toolbar_search.xml：44vp 工具栏 + 细分割线
      Column() {
        Row() {
          Row() {
            Image($r('app.media.search_b'))
              .width(16)
              .height(16)
              .margin({ left: 8, right: 9 })
            TextInput({ text: this.searchKey, placeholder: '输入姓名、电话号码搜索...' })
              .fontSize(14)
              .fontColor($r('app.color.common_color_1'))
              .placeholderColor('#B5B5B5')
              .placeholderFont({ size: 14 })
              .backgroundColor(Color.Transparent)
              .padding({ left: 0, right: 8 })
              .height(32)
              .layoutWeight(1)
              .onChange((value: string) => {
                this.searchKey = value;
              })
          }
          .height(32)
          .margin({ right: 4 })
          .layoutWeight(1)
          .alignItems(VerticalAlign.Center)
          .backgroundColor($r('app.color.common_color_6'))
          .borderRadius(4)
          .border({ width: 1, color: '#DADBDF' })

          Text('取消')
            .fontSize(14)
            .fontColor($r('app.color.common_color_1'))
            .height('100%')
            .textAlign(TextAlign.Center)
            .margin({ left: 8 })
            .onClick(() => {
              this.searchKey = '';
            })
        }
        .width('100%')
        .height(44)
        .padding({ right: 12 })
        .alignItems(VerticalAlign.Center)
        .backgroundColor($r('app.color.main_bg'))

        Divider()
          .color($r('app.color.common_color_5'))
          .strokeWidth(0.5)
          .width('100%')
      }
      .width('100%')
      .backgroundColor($r('app.color.main_bg'))

      // 结果列表：view_search.xml 行 48vp
      List({ space: 0 }) {
        ForEach(this.teacherList, (teacher: SuperviseTeacher) => {
          if (this.matchTeacher(teacher)) {
            ListItem() {
              Column() {
                Row() {
                  Text(teacher.name)
                    .fontSize(17)
                    .fontColor($r('app.color.common_color_1'))
                    .maxLines(1)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                  Text(teacher.major)
                    .fontSize(14)
                    .fontColor($r('app.color.common_color_3'))
                    .maxLines(1)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                    .margin({ left: 12 })
                }
                .width('100%')
                .height(48)
                .padding(12)
                .alignItems(VerticalAlign.Center)
                .backgroundColor($r('app.color.white'))

                Divider()
                  .color($r('app.color.common_color_5'))
                  .strokeWidth(0.5)
                  .width('100%')
              }
              .width('100%')
              .backgroundColor($r('app.color.white'))
            }
          }
        }, (teacher: SuperviseTeacher) => teacher.id)
      }
      .width('100%')
      .layoutWeight(1)
      .backgroundColor($r('app.color.common_color_6'))
      .scrollBar(BarState.Off)
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.common_color_6'))
  }
}
