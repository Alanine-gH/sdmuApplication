/**
 * 弹窗合集页 — 1:1 复刻两份源布局（px_to_dip_N = N/2 vp, px_to_sp_N = N/2 fp）：
 *
 * 一、activity_mobile_campus_popupwindow.xml（学校切换弹窗，白底）：
 *   - 行结构：LinearLayout 水平、padH 15dip(=15vp)、gravity center_vertical；
 *   - 校名 BLTextView 18sp(=18fp) padV 10dip(=10vp) 权重 1，选中色 #1B68B7 / 未选中 #333333；
 *   - 选中行右侧 icon_select_blue 图标；
 *   - 行间分隔线 #F5F5F5 高 1dip(=1vp)、marginH 15vp。
 *
 * 二、mobile_campus_main_popup.xml（主页右上角主菜单弹窗，主色底 #97000C）：
 *   - 垂直 LinearLayout、divider 白色 1px(=1vp)、dividerPadding px_to_dip_2(=1vp)、showDividers middle；
 *   - 菜单行高 px_to_dip_88(=44vp)、padH px_to_dip_18(=9vp)、图标 26dip(=26vp)；
 *   - 文字 px_to_sp_30(=15fp) 白色、marginL px_to_dip_16(=8vp)；
 *   - 四项：扫一扫 / 添加日程 / 自定义课程 / 发票识别号。
 */
class SchoolOption {
  schoolId: string = '';
  schoolName: string = '';

  constructor(schoolId: string, schoolName: string) {
    this.schoolId = schoolId;
    this.schoolName = schoolName;
  }
}

class MainPopupEntry {
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
struct PopupWindowPage {
  @State selectedSchoolId: string = 'gz';
  private schools: SchoolOption[] = [
    new SchoolOption('gz', '广州华夏职业学院'),
    new SchoolOption('gd', '广东华夏高级技工学校')
  ];
  private popupEntries: MainPopupEntry[] = [
    new MainPopupEntry('scan', '扫一扫', $r('app.media.mobile_campus_main_scan')),
    new MainPopupEntry('addplan', '添加日程', $r('app.media.mobile_campus_main_addplan')),
    new MainPopupEntry('addclass', '自定义课程', $r('app.media.mobile_campus_main_addclass')),
    new MainPopupEntry('invoice', '发票识别号', $r('app.media.mobile_campus_main_invoice'))
  ];

  build() {
    Column() {
      // activity_mobile_campus_popupwindow.xml：学校切换弹窗（fill_parent 宽、白底）
      Column() {
        ForEach(this.schools, (school: SchoolOption, index: number) => {
          Column() {
            Row() {
              Text(school.schoolName)
                .fontSize(18)
                .fontColor(this.selectedSchoolId === school.schoolId ? '#1B68B7' : '#333333')
                .padding({ top: 10, bottom: 10 })
                .layoutWeight(1)
                .maxLines(1)
              if (this.selectedSchoolId === school.schoolId) {
                Image($r('app.media.icon_select_blue'))
                  .width(20)
                  .height(20)
              }
            }
            .width('100%')
            .padding({ left: 15, right: 15 })
            .alignItems(VerticalAlign.Center)
            .onClick(() => {
              this.selectedSchoolId = school.schoolId;
            })

            // 分隔线 #F5F5F5 高 1vp、marginH 15vp
            if (index < this.schools.length - 1) {
              Divider()
                .color('#F5F5F5')
                .strokeWidth(1)
                .margin({ left: 15, right: 15 })
            }
          }
          .width('100%')
        }, (school: SchoolOption) => school.schoolId)
      }
      .width('100%')
      .backgroundColor($r('app.color.white'))

      Column()
        .height(20)

      // mobile_campus_main_popup.xml：主页主菜单弹窗（wrap 宽、主色 #97000C 底）
      Column() {
        ForEach(this.popupEntries, (entry: MainPopupEntry, index: number) => {
          Column() {
            Row() {
              Image(entry.entryIcon)
                .width(26)
                .height(26)
              Text(entry.entryLabel)
                .fontSize(15)
                .fontColor($r('app.color.white'))
                .margin({ left: 8 })
            }
            .width('100%')
            .height(44)
            .padding({ left: 9, right: 9 })
            .alignItems(VerticalAlign.Center)

            // showDividers middle：白色 1vp 分隔线、dividerPadding 1vp
            if (index < this.popupEntries.length - 1) {
              Divider()
                .color($r('app.color.white'))
                .strokeWidth(1)
                .margin({ left: 1, right: 1 })
            }
          }
          .width('100%')
        }, (entry: MainPopupEntry) => entry.entryId)
      }
      .width(150)
      .backgroundColor($r('app.color.mobile_campus_primary_color'))
    }
    .width('100%')
    .height('100%')
    .padding({ left: 24, right: 24 })
    .backgroundColor('#F2F2F2')
    .alignItems(HorizontalAlign.Center) // 弹窗示例居中展示
  }
}
