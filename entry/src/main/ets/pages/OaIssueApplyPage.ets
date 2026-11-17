import { router } from '@kit.ArkUI';
import { TitleBar } from '../components/TitleBar';

/**
 * 事项申请 — 1:1 复刻 mobile_campus_oa_issue_activity_apply.xml
 * + widget_singletext.xml（标签列 80vp：红星+灰标签；内容 EditText；内容下细分割线）
 * + view_person.xml（参与人员：标签 + 人员标签流）
 * 底部保存：白底 sdmu_primary 红字
 */
class OaApplyPerson {
  id: string;
  name: string;

  constructor(id: string, name: string) {
    this.id = id;
    this.name = name;
  }
}

@Entry
@Component
struct OaIssueApplyPage {
  @State issueTitle: string = '关于举办校园文化艺术节的申请';
  @State issueDepartment: string = '校团委';
  @State issueApplyTime: string = '2026-11-17 09:00';
  @State issueCostTime: string = '2026-12-01';
  @State issueLeader: string = '王建国';
  @State peopleList: OaApplyPerson[] = [
    new OaApplyPerson('p1', '张明'),
    new OaApplyPerson('p2', '李华'),
    new OaApplyPerson('p3', '刘芳'),
    new OaApplyPerson('p4', '周涛')
  ];

  private submitApply(): void {
    router.back();
  }

  build() {
    Stack({ alignContent: Alignment.Bottom }) {
      Column() {
        TitleBar({ title: '事项申请', showBack: true })

        Column() {
          // 事项名称（必填红星）
          Column() {
            Row() {
              Text('*')
                .fontSize(17)
                .fontColor($r('app.color.ybg_red'))
                .margin({ right: 4 })
              Text('事项名称')
                .fontSize(16)
                .fontColor($r('app.color.common_color_3'))
            }
            .width(80)

            TextInput({ text: this.issueTitle })
              .fontSize(16)
              .fontColor($r('app.color.common_color_1'))
              .backgroundColor(Color.Transparent)
              .padding({ left: 0, right: 12 })
              .height(40)
              .layoutWeight(1)
              .maxLines(1)
              .onChange((value: string) => {
                this.issueTitle = value;
              })
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

          // 申请部门
          Column() {
            Text('申请部门')
              .fontSize(16)
              .fontColor($r('app.color.common_color_3'))
              .width(80)
            TextInput({ text: this.issueDepartment })
              .fontSize(16)
              .fontColor($r('app.color.common_color_1'))
              .backgroundColor(Color.Transparent)
              .padding({ left: 0, right: 12 })
              .height(40)
              .layoutWeight(1)
              .maxLines(1)
              .onChange((value: string) => {
                this.issueDepartment = value;
              })
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

          // 申请时间
          Column() {
            Text('申请时间')
              .fontSize(16)
              .fontColor($r('app.color.common_color_3'))
              .width(80)
            TextInput({ text: this.issueApplyTime })
              .fontSize(16)
              .fontColor($r('app.color.common_color_1'))
              .backgroundColor(Color.Transparent)
              .padding({ left: 0, right: 12 })
              .height(40)
              .layoutWeight(1)
              .maxLines(1)
              .onChange((value: string) => {
                this.issueApplyTime = value;
              })
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

          // 办理时限
          Column() {
            Text('办理时限')
              .fontSize(16)
              .fontColor($r('app.color.common_color_3'))
              .width(80)
            TextInput({ text: this.issueCostTime })
              .fontSize(16)
              .fontColor($r('app.color.common_color_1'))
              .backgroundColor(Color.Transparent)
              .padding({ left: 0, right: 12 })
              .height(40)
              .layoutWeight(1)
              .maxLines(1)
              .onChange((value: string) => {
                this.issueCostTime = value;
              })
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

          // 分管领导
          Column() {
            Text('分管领导')
              .fontSize(16)
              .fontColor($r('app.color.common_color_3'))
              .width(80)
            TextInput({ text: this.issueLeader })
              .fontSize(16)
              .fontColor($r('app.color.common_color_1'))
              .backgroundColor(Color.Transparent)
              .padding({ left: 0, right: 12 })
              .height(40)
              .layoutWeight(1)
              .maxLines(1)
              .onChange((value: string) => {
                this.issueLeader = value;
              })
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

          // 参与人员（view_person：标签 + 人员标签流 + 添加按钮）
          Column() {
            Text('参与人员')
              .fontSize(16)
              .fontColor($r('app.color.common_color_3'))
              .width(80)

            Flex({ wrap: FlexWrap.Wrap }) {
              ForEach(this.peopleList, (person: OaApplyPerson) => {
                Text(person.name)
                  .fontSize(14)
                  .fontColor($r('app.color.common_color_1'))
                  .padding({ left: 12, right: 12, top: 6, bottom: 6 })
                  .margin({ right: 8, bottom: 8 })
                  .borderRadius(4)
                  .backgroundColor($r('app.color.common_color_6'))
              }, (person: OaApplyPerson) => person.id)

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

      // 底部保存：白底红字 17fp，padding V10
      Text('保存')
        .fontSize(17)
        .fontColor($r('app.color.sdmu_primary'))
        .textAlign(TextAlign.Center)
        .width('100%')
        .padding({ top: 10, bottom: 10 })
        .backgroundColor($r('app.color.white'))
        .onClick(() => {
          this.submitApply();
        })
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.mobile_campus_bg_color'))
  }
}
