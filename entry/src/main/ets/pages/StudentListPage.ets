// 数据源：无服务器接口，页面数据为内置示例数据（离线演示用），未接 ApiService。
import { router } from '@kit.ArkUI';
import { TitleBar } from '../components/TitleBar';

/**
 * 学生列表页 — 1:1 复刻 mobile_campus_score_activity_student_list.xml +
 * mobile_campus_score_item_student_list.xml + mobile_campus_score_activity_student_search.xml
 *
 * activity_student_list.xml：LinearLayout vertical main_bg + toolbar_normal +
 *   TextView 搜索框(shape_contact_sesarch_bg 圆角 #E7E7E7 底 1px #DADBDF 描边、高 32dip、
 *   marginH px_to_dip_24=12vp、marginV px_to_dip_16=8vp、paddingH 8dip、
 *   drawableLeft=search_b 间距 9dip、hint"输入学生姓名信息搜索..."、字号 px_to_sp_28=14fp) +
 *   divider_horizontal_grey_normal +
 *   TabLayout（scrollable、无指示条、tabPadding px_to_dip_10=5vp）+ ViewPager
 *
 * item_student_list.xml：学生名 px_to_sp_32=16fp common_color_1、行高 px_to_dip_88=44vp、
 *   padding px_to_dip_24=12vp、右箭头 arrow_right2、底部 common_color_6 分隔线 marginH 12vp
 */
class ScoreStudentItem {
  name: string;
  className: string;

  constructor(name: string, className: string) {
    this.name = name;
    this.className = className;
  }
}

class ScoreCollegeTab {
  college: string;
  students: ScoreStudentItem[];

  constructor(college: string, students: ScoreStudentItem[]) {
    this.college = college;
    this.students = students;
  }
}

function buildStudentTabs(): ScoreCollegeTab[] {
  const tabs: ScoreCollegeTab[] = [];
  tabs.push(new ScoreCollegeTab('文学院', [
    new ScoreStudentItem('张晓雨', '汉语言文学2023级1班'),
    new ScoreStudentItem('李梦瑶', '汉语言文学2023级2班'),
    new ScoreStudentItem('王子涵', '新闻学2024级1班')
  ]));
  tabs.push(new ScoreCollegeTab('理学院', [
    new ScoreStudentItem('陈嘉禾', '数学与应用数学2023级1班'),
    new ScoreStudentItem('刘一鸣', '物理学2022级2班')
  ]));
  tabs.push(new ScoreCollegeTab('工学院', [
    new ScoreStudentItem('赵梓豪', '计算机科学与技术2023级3班'),
    new ScoreStudentItem('孙艺宁', '软件工程2024级1班'),
    new ScoreStudentItem('周子墨', '电子信息工程2023级2班'),
    new ScoreStudentItem('吴思远', '机械设计制造及其自动化2022级1班')
  ]));
  tabs.push(new ScoreCollegeTab('商学院', [
    new ScoreStudentItem('郑雅琪', '会计学2023级1班'),
    new ScoreStudentItem('冯浩然', '工商管理2024级2班')
  ]));
  tabs.push(new ScoreCollegeTab('医学院', [
    new ScoreStudentItem('许安然', '临床医学2023级5班')
  ]));
  return tabs;
}

@Entry
@Component
struct StudentListPage {
  @State currentTabIndex: number = 0;
  @State searchKey: string = '';
  private tabs: ScoreCollegeTab[] = buildStudentTabs();

  build() {
    Column() {
      TitleBar({ title: '学生列表' })
      // 搜索框：shape_contact_sesarch_bg — 圆角胶囊、#E7E7E7 底、#DADBDF 1px 描边、高 32dip=32vp
      Row() {
        Image($r('app.media.search_b'))
          .width(16)
          .height(16)
          .margin({ right: 9 }) // drawablePadding 9dip
        TextInput({ text: this.searchKey, placeholder: '输入学生姓名信息搜索...' })
          .fontSize(14) // px_to_sp_28/2=14fp
          .fontColor($r('app.color.common_color_1'))
          .placeholderColor('#B5B5B5')
          .placeholderFont({ size: 14 })
          .backgroundColor(Color.Transparent)
          .padding(0)
          .layoutWeight(1)
          .height(28)
          .onChange((value: string) => {
            this.searchKey = value;
          })
      }
      .width('100%')
      .height(32) // 32.0dip
      .padding({ left: 8, right: 8 }) // paddingLeft/Right 8.0dip
      .margin({ left: 12, right: 12, top: 8, bottom: 8 }) // px_to_dip_24/2=12、px_to_dip_16/2=8
      .borderRadius(16)
      .backgroundColor('#E7E7E7')
      .border({ width: 0.5, color: '#DADBDF' })
      .alignItems(VerticalAlign.Center)

      // divider_horizontal_grey_normal
      Divider()
        .color($r('app.color.common_color_5'))
        .strokeWidth(0.5)
        .width('100%')

      // TabLayout：scrollable、无指示条、tabPadding px_to_dip_10/2=5vp
      Scroll() {
        Row({ space: 0 }) {
          ForEach(this.tabs, (tab: ScoreCollegeTab, index: number) => {
            Text(tab.college)
              .fontSize(14)
              .fontColor(index === this.currentTabIndex
                ? $r('app.color.mobile_campus_primary_color_default')
                : $r('app.color.common_color_1'))
              .padding({ left: 5, right: 5 }) // tabPaddingStart/End px_to_dip_10/2=5vp
              .padding({ left: 10, right: 10 })
              .height(36)
              .textAlign(TextAlign.Center)
              .onClick(() => {
                this.currentTabIndex = index;
              })
          }, (tab: ScoreCollegeTab) => tab.college)
        }
      }
      .scrollable(ScrollDirection.Horizontal)
      .width('100%')

      // ViewPager：当前学院学生列表
      List() {
        ForEach(this.filteredStudents(this.currentTabIndex), (student: ScoreStudentItem, index: number) => {
          ListItem() {
            Column() {
              Row() {
                Text(student.name)
                  .fontSize(16) // px_to_sp_32/2=16fp
                  .fontColor($r('app.color.common_color_1'))
                  .layoutWeight(1)
                  .height('100%')
                  .textAlign(TextAlign.Start)
                Image($r('app.media.arrow_right2'))
                  .width(14)
                  .height(14)
                  .objectFit(ImageFit.Contain)
              }
              .width('100%')
              .height(44) // px_to_dip_88/2=44vp
              .padding({ left: 12, right: 12 }) // px_to_dip_24/2=12vp
              .alignItems(VerticalAlign.Center)
              .onClick(() => {
                router.pushUrl({ url: 'pages/StudentScorePage' });
              })
              // 分隔线：common_color_6、高 px_to_dip_1/2=0.5vp、marginH 12vp
              Divider()
                .color($r('app.color.common_color_6'))
                .strokeWidth(0.5)
                .margin({ left: 12, right: 12 })
            }
          }
        }, (student: ScoreStudentItem, index: number) => this.currentTabIndex + '_' + index + '_' + student.name)
      }
      .width('100%')
      .layoutWeight(1)
      .backgroundColor($r('app.color.main_bg'))
      .divider({ strokeWidth: 0, color: Color.Transparent, startMargin: 0, endMargin: 0 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.main_bg'))
  }

  private filteredStudents(currentTabIndex: number): ScoreStudentItem[] {
    const tab: ScoreCollegeTab | undefined = this.tabs[currentTabIndex];
    if (tab === undefined) {
      return [];
    }
    const key: string = this.searchKey.trim();
    if (key.length === 0) {
      return tab.students;
    }
    const result: ScoreStudentItem[] = [];
    for (let i = 0; i < tab.students.length; i++) {
      const student: ScoreStudentItem = tab.students[i];
      if (student.name.includes(key)) {
        result.push(student);
      }
    }
    return result;
  }
}
