import { TitleBar } from '../components/TitleBar';

/**
 * 选学院页 — 1:1 复刻 mobile_campus_timetable_activity_chooseacademy.xml
 * 结构：LinearLayout(main_bg) + toolbar_normal
 *   + 搜索区 FrameLayout(ybg_white, paddingTB 10vp, marginH 10vp) 内嵌 search_box
 *   + divider_horizontal_grey_normal
 *   + VaryingBubbles 气泡云(paddingTB 19vp) 学院气泡
 */
class AcademyBubble {
  name: string;
  size: number;

  constructor(name: string, size: number) {
    this.name = name;
    this.size = size;
  }
}

@Entry
@Component
struct ChooseAcademyPage {
  @State searchKey: string = '';
  private bubbles: AcademyBubble[] = [
    new AcademyBubble('马克思主义学院', 16),
    new AcademyBubble('文学院', 15),
    new AcademyBubble('外国语学院', 17),
    new AcademyBubble('经济管理学院', 14),
    new AcademyBubble('政法学院', 15),
    new AcademyBubble('教育科学学院', 16),
    new AcademyBubble('数学与统计学院', 14),
    new AcademyBubble('物理与电子工程学院', 13),
    new AcademyBubble('化学化工学院', 15),
    new AcademyBubble('生命科学学院', 14),
    new AcademyBubble('计算机学院', 17),
    new AcademyBubble('体育学院', 15),
    new AcademyBubble('音乐学院', 16),
    new AcademyBubble('美术学院', 15),
    new AcademyBubble('历史文化学院', 14)
  ];

  private selectAcademy(name: string): void {
    this.getUIContext().getPromptAction().showToast({ message: '已选择：' + name });
  }

  build() {
    Column() {
      TitleBar({ title: '选择学院', showBack: true })

      // 搜索区：ybg_white paddingTB 10vp
      Row() {
        // search_box：浅灰圆角容器 paddingH 15vp paddingTB 3vp
        Row() {
          Image($r('app.media.search_grey'))
            .width(16)
            .height(16)
            .margin({ right: 10 })
          TextInput({ placeholder: '请输入', text: this.searchKey })
            .fontSize(16)
            .fontColor($r('app.color.common_color_2'))
            .placeholderColor($r('app.color.common_color_3'))
            .placeholderFont({ size: 16 })
            .backgroundColor(Color.Transparent)
            .padding(0)
            .layoutWeight(1)
            .height(32)
            .onChange((value: string) => {
              this.searchKey = value;
            })
        }
        .layoutWeight(1)
        .alignItems(VerticalAlign.Center)
        .padding({ left: 15, right: 15, top: 3, bottom: 3 })
        .borderRadius(4)
        .backgroundColor('#F5F5F5')
      }
      .width('100%')
      .padding({ left: 10, right: 10, top: 10, bottom: 10 })
      .backgroundColor($r('app.color.ybg_white'))

      // divider_horizontal_grey_normal 1vp
      Divider()
        .color($r('app.color.common_color_5'))
        .strokeWidth(1)
        .width('100%')

      // VaryingBubbles 气泡云
      Scroll() {
        Flex({
          direction: FlexDirection.Row,
          wrap: FlexWrap.Wrap,
          justifyContent: FlexAlign.Center,
          alignItems: ItemAlign.Center
        }) {
          ForEach(this.bubbles, (item: AcademyBubble) => {
            Text(item.name)
              .fontSize(item.size)
              .fontColor('#FFFFFF')
              .maxLines(1)
              .padding({ left: 14, right: 14, top: 8, bottom: 8 })
              .margin(6)
              .borderRadius(item.size + 8)
              .backgroundColor($r('app.color.timetable_per_blue'))
              .onClick(() => {
                this.selectAcademy(item.name);
              })
          }, (item: AcademyBubble) => item.name)
        }
        .width('100%')
        .padding({ top: 19, bottom: 19 })
      }
      .width('100%')
      .layoutWeight(1)
      .scrollBar(BarState.Off)
      .backgroundColor($r('app.color.ybg_white'))
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.main_bg'))
  }
}
