import { router } from '@kit.ArkUI';

/**
 * 举报页 — 1:1 复刻 social_report_activity.xml：
 * toolbar_normal + common_rg_sv（可滚动列表容器）
 * 举报理由单选列表
 */
interface ReportReason {
  id: number;
  name: string;
}

@Entry
@Component
struct SocialReportPage {
  @State reasonList: ReportReason[] = [
    { id: 1, name: '垃圾广告' },
    { id: 2, name: '恶意攻击谩骂' },
    { id: 3, name: '色情低俗' },
    { id: 4, name: '政治敏感' },
    { id: 5, name: '欺诈信息' },
    { id: 6, name: '泄露他人隐私' },
    { id: 7, name: '其他' }
  ];
  @State selectedId: number = 0;

  build() {
    Column() {
      Row() {
        Text('＜')
          .fontSize(16)
          .fontColor($r('app.color.common_color_1'))
          .width(40)
          .height('100%')
          .textAlign(TextAlign.Center)
          .margin({ left: 15 })
          .onClick(() => {
            router.back();
          })
        Text('举报')
          .fontSize(16)
          .fontColor($r('app.color.common_color_1'))
          .layoutWeight(1)
          .textAlign(TextAlign.Center)
          .maxLines(1)
        Blank()
          .width(40)
      }
      .width('100%')
      .height(44)
      .alignItems(VerticalAlign.Center)
      .backgroundColor($r('app.color.main_bg'))
      Divider()
        .color($r('app.color.common_color_5'))
        .strokeWidth(0.5)
        .width('100%')

      Scroll() {
        Column() {
          ForEach(this.reasonList, (item: ReportReason) => {
            Row() {
              Text(item.name)
                .fontSize(15)
                .fontColor($r('app.color.common_color_1'))
                .layoutWeight(1)
              Circle({ width: 16, height: 16 })
                .fill(this.selectedId === item.id ? $r('app.color.sdmu_primary') : Color.Transparent)
                .stroke(this.selectedId === item.id ? $r('app.color.sdmu_primary') : $r('app.color.common_color_4'))
                .strokeWidth(1)
            }
            .width('100%')
            .height(48)
            .padding({ left: 15, right: 15 })
            .alignItems(VerticalAlign.Center)
            .backgroundColor($r('app.color.main_bg'))
            .onClick(() => {
              this.selectedId = item.id;
            })

            Divider()
              .color($r('app.color.common_color_5'))
              .strokeWidth(0.5)
              .width('100%')
          }, (item: ReportReason) => item.id.toString())

          Button('提交')
            .width('90%')
            .height(44)
            .fontSize(16)
            .fontColor($r('app.color.white'))
            .backgroundColor($r('app.color.sdmu_primary'))
            .margin({ top: 24 })
            .onClick(() => {
              router.back();
            })
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)
      .align(Alignment.Top)
      .backgroundColor($r('app.color.common_color_6'))
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.main_bg'))
  }
}
