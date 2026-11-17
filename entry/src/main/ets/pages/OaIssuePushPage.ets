import { router } from '@kit.ArkUI';
import { TitleBar } from '../components/TitleBar';

/**
 * 事项推送 — 1:1 复刻 mobile_campus_oa_issue_activity_push.xml
 * IssueDepartmentSelectorView（推送部门）+ IssueSelectorView（推送人员标签流）
 * 底部推送：白底 sdmu_primary 红字
 */
class OaPushPerson {
  id: string;
  name: string;

  constructor(id: string, name: string) {
    this.id = id;
    this.name = name;
  }
}

@Entry
@Component
struct OaIssuePushPage {
  @State selectedDept: string = '党委办公室';
  @State peopleList: OaPushPerson[] = [
    new OaPushPerson('p1', '王志远'),
    new OaPushPerson('p2', '孙丽'),
    new OaPushPerson('p3', '赵磊'),
    new OaPushPerson('p4', '陈静')
  ];

  private chooseDept(): void {
    this.selectedDept = '校长办公室';
  }

  private submitPush(): void {
    router.back();
  }

  build() {
    Stack({ alignContent: Alignment.Bottom }) {
      Column() {
        TitleBar({ title: '事项推送', showBack: true })

        Column() {
          // 推送部门选择行
          Column() {
            Text('推送部门')
              .fontSize(16)
              .fontColor($r('app.color.common_color_3'))
              .width(80)

            Row() {
              Text(this.selectedDept)
                .fontSize(16)
                .fontColor($r('app.color.common_color_1'))
                .layoutWeight(1)
                .onClick(() => {
                  this.chooseDept();
                })
              Image($r('app.media.mobile_campus_supervise_arrow'))
                .width(12)
                .height(12)
            }
            .layoutWeight(1)
            .height(40)
            .padding({ right: 12 })
            .alignItems(VerticalAlign.Center)
          }
          .width('100%')
          .alignItems(HorizontalAlign.Start)
          .padding({ left: 12, top: 15 })
          .backgroundColor($r('app.color.white'))

          Row() {
            Blank()
              .width(92)
            Divider()
              .color($r('app.color.common_color_5'))
              .strokeWidth(0.5)
              .layoutWeight(1)
          }
          .width('100%')
          .backgroundColor($r('app.color.white'))

          // 推送人员（view_person：标签 + 人员标签流 + 添加按钮）
          Column() {
            Text('推送人员')
              .fontSize(16)
              .fontColor($r('app.color.common_color_3'))
              .width(80)

            Flex({ wrap: FlexWrap.Wrap }) {
              ForEach(this.peopleList, (person: OaPushPerson) => {
                Text(person.name)
                  .fontSize(14)
                  .fontColor($r('app.color.common_color_1'))
                  .padding({ left: 12, right: 12, top: 6, bottom: 6 })
                  .margin({ right: 8, bottom: 8 })
                  .borderRadius(4)
                  .backgroundColor($r('app.color.common_color_6'))
              }, (person: OaPushPerson) => person.id)

              Image($r('app.media.mobile_campus_oa_issue_addto_white'))
                .width(24)
                .height(24)
                .margin({ right: 8, bottom: 8 })
                .borderRadius(4)
                .backgroundColor($r('app.color.oa_issue_blue'))
            }
            .layoutWeight(1)
            .padding(12)
          }
          .width('100%')
          .alignItems(HorizontalAlign.Start)
          .padding({ left: 12, top: 15 })
          .backgroundColor($r('app.color.white'))
        }
        .width('100%')
        .margin({ top: 8 })

        Blank()
          .layoutWeight(1)
      }
      .width('100%')
      .height('100%')

      // 底部推送：白底红字 17fp，padding V10
      Text('推送')
        .fontSize(17)
        .fontColor($r('app.color.sdmu_primary'))
        .textAlign(TextAlign.Center)
        .width('100%')
        .padding({ top: 10, bottom: 10 })
        .backgroundColor($r('app.color.white'))
        .onClick(() => {
          this.submitPush();
        })
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.mobile_campus_bg_color'))
  }
}
