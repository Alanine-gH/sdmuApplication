import { TitleBar } from '../components/TitleBar';

/**
 * 同学列表页 — timetable/ClassmatesListActivity
 * 原生包 加壳无对应独立布局，按课程详情“本课上课时间由XX同学提供”同学列表交互复刻：
 * toolbar_normal + ListView：左侧头像占位 + 姓名 TextSize2.Color1 + 提供课程数 TextSize2.Color3
 */
class ClassmateItem {
  name: string;
  info: string;

  constructor(name: string, info: string) {
    this.name = name;
    this.info = info;
  }
}

@Entry
@Component
struct ClassmatesListPage {
  private classmates: ClassmateItem[] = [
    new ClassmateItem('张三', '提供了3门课程时间'),
    new ClassmateItem('李四', '提供了2门课程时间'),
    new ClassmateItem('王五', '提供了1门课程时间'),
    new ClassmateItem('刘六', '提供了1门课程时间'),
    new ClassmateItem('陈七', '提供了4门课程时间'),
    new ClassmateItem('杨八', '提供了2门课程时间'),
    new ClassmateItem('赵九', '提供了1门课程时间'),
    new ClassmateItem('周十', '提供了2门课程时间')
  ];

  build() {
    Column() {
      TitleBar({ title: '同班同学', showBack: true })

      List() {
        ForEach(this.classmates, (item: ClassmateItem) => {
          ListItem() {
            Column() {
              Row() {
                // 头像占位：姓名首字
                Text(item.name.substring(0, 1))
                  .fontSize(18)
                  .fontColor($r('app.color.white'))
                  .width(40)
                  .height(40)
                  .textAlign(TextAlign.Center)
                  .borderRadius(20)
                  .backgroundColor($r('app.color.mobile_campus_score_common_color1'))

                Column() {
                  Text(item.name)
                    .fontSize(17)
                    .fontColor($r('app.color.common_color_1'))
                    .maxLines(1)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                  Text(item.info)
                    .fontSize(15)
                    .fontColor($r('app.color.common_color_3'))
                    .maxLines(1)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                    .margin({ top: 4 })
                }
                .alignItems(HorizontalAlign.Start)
                .layoutWeight(1)
                .margin({ left: 12 })

                Text('＞')
                  .fontSize(15)
                  .fontColor($r('app.color.common_color_3'))
              }
              .width('100%')
              .alignItems(VerticalAlign.Center)
              .padding(15)
            }
            .width('100%')
            .backgroundColor($r('app.color.ybg_white'))
          }
        }, (item: ClassmateItem) => item.name)
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
    .height('100%')
    .backgroundColor($r('app.color.main_bg'))
  }
}
