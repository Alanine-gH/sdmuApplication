import { router } from '@kit.ArkUI';
import { ChooseSchoolItem } from '../components/ChooseSchoolItem';

/**
 * 选择学校页 — 1:1 复刻 mobile_campus_choose_school.xml（ChooseSchoolActivity）
 * 结构：LinearLayout(垂直)
 *   - toolbar 隐藏（gone）
 *   - 头部 45vp main_bg：返回键(paddingH 15/paddingV 4) + 搜索框
 *     （bg #F2F2F2 圆角 25vp、marginL/T/B 5vp、search_icon 36x36 marginL 5、
 *      输入框 15fp(px30÷2) common_color_1 hint common_color_3）
 *   - divider 0.5vp
 *   - 学校列表（common_refresh_lv_rl + school_item）
 */
@Entry
@Component
struct ChooseSchoolPage {
  @State searchText: string = '';
  private schoolList: string[] = [
    '山东管理学院', '山东女子学院', '山东青年政治学院', '山东传媒职业学院',
    '山东医学高等专科学校', '山东商业职业技术学院', '山东电力高等专科学校',
    '山东职业学院', '济南职业学院', '青岛职业技术学院', '淄博职业学院',
    '烟台职业学院', '潍坊职业学院', '济宁职业技术学院', '泰安职业技术学院',
    '威海职业学院', '日照职业技术学院', '临沂职业学院', '德州职业技术学院'
  ];

  private filteredSchools(): string[] {
    if (this.searchText === '') {
      return this.schoolList;
    }
    return this.schoolList.filter((name: string): boolean => name.includes(this.searchText));
  }

  build() {
    Column() {
      // 头部搜索区 45vp
      Column() {
        Row() {
          Image($r('app.media.nav_back_btn'))
            .width(10)
            .height(18)
            .padding({ left: 15, right: 15, top: 4, bottom: 4 })
            .onClick(() => {
              router.back();
            })

          Row() {
            Image($r('app.media.search_icon'))
              .width(36)
              .height(36)
              .margin({ left: 5 })

            TextInput({ placeholder: '搜索学校名称', text: this.searchText })
              .fontSize(15)
              .fontColor($r('app.color.common_color_1'))
              .placeholderColor($r('app.color.common_color_3'))
              .placeholderFont({ size: 15 })
              .height('100%')
              .layoutWeight(1)
              .backgroundColor(Color.Transparent)
              .padding({ left: 4, right: 8 })
              .onChange((value: string) => {
                this.searchText = value;
              })
          }
          .layoutWeight(1)
          .height(34)
          .borderRadius(25)
          .backgroundColor($r('app.color.common_color_6'))
          .margin({ left: 5, top: 5, bottom: 5 })
          .alignItems(VerticalAlign.Center)
        }
        .width('100%')
        .height(44)
        .alignItems(VerticalAlign.Center)
        .padding({ top: 5, bottom: 5 })

        Divider()
          .color($r('app.color.common_color_5'))
          .strokeWidth(0.5)
          .width('100%')
      }
      .width('100%')
      .height(45)
      .backgroundColor($r('app.color.main_bg'))
      .justifyContent(FlexAlign.Center)

      // 学校列表
      List() {
        ForEach(this.filteredSchools(), (name: string) => {
          ListItem() {
            ChooseSchoolItem({ schoolName: name, extraInfo: '' })
          }
        }, (name: string) => name)
      }
      .width('100%')
      .height('100%')
      .scrollBar(BarState.Off)
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.main_bg'))
  }
}
