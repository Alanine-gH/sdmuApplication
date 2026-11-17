import { router } from '@kit.ArkUI';
import { TitleBar } from '../components/TitleBar';

class AchievementMember {
  name: string = '';
  role: string = '';

  constructor(name: string, role: string) {
    this.name = name;
    this.role = role;
  }
}

@Entry
@Component
struct AchievementDetailPage {
  private members: AchievementMember[] = [
    new AchievementMember('张明（主持人）', '教授'),
    new AchievementMember('李红', '副教授'),
    new AchievementMember('王强', '讲师'),
    new AchievementMember('赵雪', '博士生'),
    new AchievementMember('陈晨', '硕士生')
  ];

  build() {
    Column() {
      TitleBar({ title: '成果成员' })
      Column() {
        Column() {
          Text('成果成员')
            .fontSize(18.5)
            .fontColor($r('app.color.blue_default'))
            .width('100%')
            .height(59)
            .textAlign(TextAlign.Center)

          Scroll() {
            Column() {
              ForEach(this.members, (member: AchievementMember, index: number) => {
                Text(member.name + '　' + member.role)
                  .fontSize(14)
                  .fontColor($r('app.color.common_color_1'))
                  .width('100%')
                  .height(30)
                  .textAlign(TextAlign.Start)
                  .margin({ left: 12 })
              }, (member: AchievementMember, index: number) => 'm_' + index + '_' + member.name)
            }
            .width('100%')
          }
          .width('100%')
          .layoutWeight(1)
          .scrollBar(BarState.Off)
          .align(Alignment.Top)

          Text('确定')
            .fontSize(16)
            .fontColor($r('app.color.white'))
            .width(160)
            .height(40)
            .textAlign(TextAlign.Center)
            .backgroundColor($r('app.color.blue_default'))
            .margin({ top: 24, bottom: 21 })
        }
        .width('100%')
        .height(300)
        .backgroundColor($r('app.color.white'))
        .borderRadius(4)

        Image($r('app.media.mobile_campus_reimburse_ticketfoot'))
          .width('100%')
          .objectFit(ImageFit.Cover)
      }
      .width('100%')
      .padding({ left: 20, right: 20 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.common_color_5'))
    .justifyContent(FlexAlign.Center)
  }
}
