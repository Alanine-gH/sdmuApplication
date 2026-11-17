import { TitleBar } from '../components/TitleBar';

/**
 * 文号选择页 — 1:1 复刻 mobile_campus_oa_activity_docnumber.xml：
 * toolbar + 细分隔线
 * 左侧类型列表：宽100 mt15 单选(mobile_campus_item_doc_number: 14fp 居中 padH9 padV12)
 * 竖分隔线 0.5vp common_color_4
 * 右侧 padL12：字号/年度/编号 标签(12fp common_color_1 bg common_color_5 padH6 padV4 mt15 mr12) + 选项列表
 *   (mobile_campus_oa_subitem_doc_number: 高50 ml6 mr12 16fp + 分隔线)
 * 底部：分隔线 + 高50 文号文本(14fp padL16) + 确定按钮(17fp 白字 primary bg 权重3)
 */
@Entry
@Component
struct DocNumberPage {
  @State docTypes: string[] = ['呈批件', '发文', '签报'];
  @State selectedType: string = '呈批件';
  @State zihaoList: string[] = ['院字', '院办字', '院党字', '院教字'];
  @State nianduList: string[] = ['2026', '2025', '2024'];
  @State bianhaoList: string[] = ['1号', '2号', '3号', '44号'];
  @State selectedZihao: string = '院办字';
  @State selectedNiandu: string = '2026';
  @State selectedBianhao: string = '44号';

  private docNumberText(): string {
    return '文号：' + this.selectedZihao + '[' + this.selectedType + '](' + this.selectedNiandu + ') ' + this.selectedBianhao;
  }

  private selectType(item: string): void {
    this.selectedType = item;
  }

  private submit(): void {
    this.getUIContext().getPromptAction().showToast({ message: this.docNumberText() });
  }

  build() {
    Column() {
      TitleBar({ title: '文号选择', showBack: true })

      Divider()
        .color($r('app.color.common_color_5'))
        .strokeWidth(0.5)
        .width('100%')

      Row() {
        // 左侧类型列表 宽100 mt15
        List() {
          ForEach(this.docTypes, (item: string) => {
            ListItem() {
              Text(item)
                .fontSize(14)
                .fontColor($r('app.color.mobile_campus_textcolor_doc_number'))
                .padding({ left: 9, right: 9, top: 12, bottom: 12 })
                .backgroundColor(this.selectedType === item ? $r('app.color.mobile_campus_oa_doc_check_bg') : Color.Transparent)
                .onClick(() => {
                  this.selectType(item);
                })
            }
          }, (item: string) => item)
        }
        .width(100)
        .height('100%')
        .margin({ top: 15 })
        .scrollBar(BarState.Off)
        .alignListItem(ListItemAlign.Center)

        // 竖分隔线 px_to_dip_2=1vp common_color_4
        Column()
          .width(0.5)
          .height('100%')
          .backgroundColor($r('app.color.common_color_4'))

        // 右侧
        Column() {
          Text('字号')
            .fontSize(12)
            .fontColor($r('app.color.common_color_1'))
            .width('100%')
            .padding({ left: 6, right: 6, top: 4, bottom: 4 })
            .margin({ top: 15, right: 12 })
            .backgroundColor($r('app.color.common_color_5'))
            .textAlign(TextAlign.Start)

          List() {
            ForEach(this.zihaoList, (item: string) => {
              ListItem() {
                this.optionRow(item, this.selectedZihao, (picked: string) => {
                  this.selectedZihao = picked;
                })
              }
            }, (item: string) => item)
          }
          .layoutWeight(1)
          .width('100%')
          .scrollBar(BarState.Off)

          Text('年度')
            .fontSize(12)
            .fontColor($r('app.color.common_color_1'))
            .width('100%')
            .padding({ left: 6, right: 6, top: 4, bottom: 4 })
            .margin({ top: 15, right: 12 })
            .backgroundColor($r('app.color.common_color_5'))
            .textAlign(TextAlign.Start)

          List() {
            ForEach(this.nianduList, (item: string) => {
              ListItem() {
                this.optionRow(item, this.selectedNiandu, (picked: string) => {
                  this.selectedNiandu = picked;
                })
              }
            }, (item: string) => item)
          }
          .layoutWeight(1)
          .width('100%')
          .scrollBar(BarState.Off)

          Text('编号')
            .fontSize(12)
            .fontColor($r('app.color.common_color_1'))
            .width('100%')
            .padding({ left: 6, right: 6, top: 4, bottom: 4 })
            .margin({ top: 15, right: 12 })
            .backgroundColor($r('app.color.common_color_5'))
            .textAlign(TextAlign.Start)

          List() {
            ForEach(this.bianhaoList, (item: string) => {
              ListItem() {
                this.optionRow(item, this.selectedBianhao, (picked: string) => {
                  this.selectedBianhao = picked;
                })
              }
            }, (item: string) => item)
          }
          .layoutWeight(1)
          .width('100%')
          .scrollBar(BarState.Off)
        }
        .layoutWeight(1)
        .height('100%')
        .padding({ left: 12 })
        .alignItems(HorizontalAlign.Start)
      }
      .width('100%')
      .layoutWeight(1)

      Divider()
        .color($r('app.color.common_color_5'))
        .strokeWidth(0.5)
        .width('100%')

      // 底部 bar 高 px_to_dip_100=50
      Row() {
        Text(this.docNumberText())
          .fontSize(14)
          .fontColor($r('app.color.common_color_1'))
          .layoutWeight(8)
          .height('100%')
          .padding({ left: 16 })
          .textAlign(TextAlign.Start)
          .maxLines(1)

        Text('确定')
          .fontSize(17)
          .fontColor($r('app.color.white'))
          .backgroundColor($r('app.color.mobile_campus_primary_color_default'))
          .layoutWeight(3)
          .height('100%')
          .textAlign(TextAlign.Center)
          .onClick(() => {
            this.submit();
          })
      }
      .width('100%')
      .height(50)
      .alignItems(VerticalAlign.Center)
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.white'))
  }

  // mobile_campus_oa_subitem_doc_number.xml：高50 ml6 mr12
  @Builder
  optionRow(item: string, current: string, onPick: (picked: string) => void) {
    Column() {
      Text(item)
        .fontSize(16)
        .fontColor(current === item ? $r('app.color.mobile_campus_primary_color_default') : $r('app.color.common_color_1'))
        .width('100%')
        .height(50)
        .padding({ left: 6 })
        .textAlign(TextAlign.Start)
        .onClick(() => {
          onPick(item);
        })

      Divider()
        .color($r('app.color.common_color_5'))
        .strokeWidth(0.5)
        .width('100%')
    }
    .width('100%')
    .margin({ left: 6, right: 12 })
  }
}
