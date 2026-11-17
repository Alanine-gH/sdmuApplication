import { TitleBar } from '../components/TitleBar';

/**
 * 选课程页 — 1:1 复刻 choose_course.xml
 * 结构：LinearLayout(竖向) + toolbar_normal + common_refresh_lv_with_search_box
 *   列表项：左侧课程名 TextSize1.Color1 + 提供同学信息 TextSize2.Color3
 *   (choose_course_exam/section/week 为周数/节数选择弹层，见 EditCoursePage 选择交互)
 */
class CourseItem {
  name: string;
  provider: string;
  weekInfo: string;

  constructor(name: string, provider: string, weekInfo: string) {
    this.name = name;
    this.provider = provider;
    this.weekInfo = weekInfo;
  }
}

@Entry
@Component
struct ChooseCoursePage {
  @State searchKey: string = '';
  @State selectedName: string = '';
  private courses: CourseItem[] = [
    new CourseItem('高等数学（上）', '张同学', '第1-18周'),
    new CourseItem('大学英语（二）', '李同学', '第1-16周 单周'),
    new CourseItem('大学物理', '王同学', '第2-17周'),
    new CourseItem('马克思主义基本原理', '刘同学', '第1-17周'),
    new CourseItem('数据结构与算法', '陈同学', '第1-18周'),
    new CourseItem('线性代数', '杨同学', '第3-18周'),
    new CourseItem('体育（篮球）', '赵同学', '第1-16周 双周'),
    new CourseItem('毛泽东思想和中国特色社会主义理论体系概论', '黄同学', '第1-17周'),
    new CourseItem('计算机组成原理', '周同学', '第1-18周'),
    new CourseItem('概率论与数理统计', '吴同学', '第2-16周')
  ];

  private chooseCourse(item: CourseItem): void {
    this.selectedName = item.name;
    this.getUIContext().getPromptAction().showToast({ message: '已选择：' + item.name });
  }

  build() {
    Column() {
      TitleBar({ title: '选择课程', showBack: true })

      // common_refresh_lv_with_search_box：搜索框 + 刷新列表
      Column() {
        // search_box：浅灰圆角容器
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
        .width('100%')
        .alignItems(VerticalAlign.Center)
        .padding({ left: 15, right: 15, top: 3, bottom: 3 })
        .margin({ top: 10 })
        .borderRadius(4)
        .backgroundColor('#F5F5F5')

        List() {
          ForEach(this.courses, (item: CourseItem) => {
            ListItem() {
              Column() {
                Row() {
                  Column() {
                    Text(item.name)
                      .fontSize(19)
                      .fontColor($r('app.color.common_color_1'))
                      .maxLines(1)
                      .textOverflow({ overflow: TextOverflow.Ellipsis })
                    Text('本课上课时间由' + item.provider + '提供 · ' + item.weekInfo)
                      .fontSize(17)
                      .fontColor($r('app.color.common_color_3'))
                      .maxLines(1)
                      .textOverflow({ overflow: TextOverflow.Ellipsis })
                      .margin({ top: 6 })
                  }
                  .alignItems(HorizontalAlign.Start)
                  .layoutWeight(1)

                  Text(this.selectedName === item.name ? '已选' : '选择')
                    .fontSize(17)
                    .fontColor(this.selectedName === item.name ? $r('app.color.common_color_3') : $r('app.color.ybg_blue'))
                    .padding({ left: 10, right: 10, top: 10, bottom: 10 })
                }
                .width('100%')
                .alignItems(VerticalAlign.Center)
                .padding(15)
              }
              .width('100%')
              .backgroundColor($r('app.color.ybg_white'))
              .onClick(() => {
                this.chooseCourse(item);
              })
            }
          }, (item: CourseItem) => item.name)
        }
        .width('100%')
        .layoutWeight(1)
        .divider({
          strokeWidth: 0.5,
          color: '#E7E7E7',
          startMargin: 15,
          endMargin: 15
        })
        .backgroundColor($r('app.color.main_bg'))
      }
      .width('100%')
      .layoutWeight(1)
      .backgroundColor($r('app.color.main_bg'))
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.main_bg'))
  }
}
