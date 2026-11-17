/**
 * 右上角功能入口弹窗页 — 1:1 复刻 layout_home_right_function_enter_dialog.xml
 * + item_home_right_function_enter_dialog.xml（px_to_dip_N = N/2 vp）：
 * - 外层 LinearLayout 竖向 wrap 尺寸、layout_gravity center_horizontal、padH 8dip(=8vp)；
 * - TriangleView：10dip × 6dip(=10×6vp) 白色三角、方向 top、layout_gravity right、marginR 13dip(=13vp)；
 * - BLLinearLayout 白底圆角 8dip(=8vp)、pad 20/10dip(=20/10vp)；
 * - 内部 RecyclerView GridLayoutManager spanCount=1（单列宫格列表）；
 * - 条目：行 padV 18dip(=18vp)、图标 20dip(=20vp) centerCrop、标题 14sp(=14fp) titleColor(#000000)、padL 10dip(=10vp)。
 */
class HomeFuncEntry {
  entryId: string = '';
  entryLabel: string = '';
  entryIcon: Resource = $r('app.media.mobile_campus_main_scan');

  constructor(entryId: string, entryLabel: string, entryIcon: Resource) {
    this.entryId = entryId;
    this.entryLabel = entryLabel;
    this.entryIcon = entryIcon;
  }
}

@Entry
@Component
struct HomeFunctionDialogPage {
  private funcEntries: HomeFuncEntry[] = [
    new HomeFuncEntry('scan', '扫一扫', $r('app.media.mobile_campus_main_scan')),
    new HomeFuncEntry('addplan', '添加日程', $r('app.media.mobile_campus_main_addplan')),
    new HomeFuncEntry('addclass', '自定义课程', $r('app.media.mobile_campus_main_addclass')),
    new HomeFuncEntry('invoice', '发票识别号', $r('app.media.mobile_campus_main_invoice'))
  ];

  build() {
    Column() {
      // 弹窗容器：center_horizontal、padH 8vp
      Column() {
        // TriangleView：白色上指三角 10×6vp、居右、marginR 13vp
        Path()
          .commands('M5 0 L10 6 L0 6 Z')
          .width(10)
          .height(6)
          .fill($r('app.color.white'))
          .alignSelf(ItemAlign.End)
          .margin({ right: 13 })

        // BLLinearLayout：白底圆角 8vp、pad 20/10vp、单列宫格
        Column() {
          ForEach(this.funcEntries, (entry: HomeFuncEntry) => {
            Row() {
              Image(entry.entryIcon)
                .width(20)
                .height(20)
                .objectFit(ImageFit.Cover)
              Text(entry.entryLabel)
                .fontSize(14)
                .fontColor($r('app.color.titleColor'))
                .padding({ left: 10 })
                .maxLines(1)
            }
            .width('100%')
            .padding({ top: 18, bottom: 18 })
            .alignItems(VerticalAlign.Center)
          }, (entry: HomeFuncEntry) => entry.entryId)
        }
        .width('100%')
        .padding({ left: 20, right: 20, top: 10, bottom: 10 })
        .borderRadius(8)
        .backgroundColor($r('app.color.white'))
      }
      .width(210)
      .padding({ left: 8, right: 8 })
      .margin({ top: 90 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#99000000')
    .alignItems(HorizontalAlign.Center) // layout_gravity center_horizontal
  }
}
