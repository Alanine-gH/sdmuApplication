import { router } from '@kit.ArkUI';
import { TitleBar } from '../components/TitleBar';

/**
 * 督导筛选 — 1:1 复刻 mobile_campus_supervise_activity_supervise_filter.xml
 * + view_filter.xml（节次格子：高 48vp，选中 #1B68B7 白字，未选中透明 #B2BDC9 字）
 * 底部提交：selector_filter_btn enabled #1B68B7 / disabled 透明字 #999999
 */
class SuperviseFilterSection {
  name: string;
  checked: boolean;

  constructor(name: string, checked: boolean) {
    this.name = name;
    this.checked = checked;
  }
}

@Entry
@Component
struct SuperviseFilterPage {
  @State selectedAcademy: string = '';
  @State showMajorRow: boolean = false;
  @State selectedMajor: string = '';
  @State sections: SuperviseFilterSection[] = [
    new SuperviseFilterSection('第1节', false),
    new SuperviseFilterSection('第2节', false),
    new SuperviseFilterSection('第3节', false),
    new SuperviseFilterSection('第4节', false),
    new SuperviseFilterSection('第5节', false),
    new SuperviseFilterSection('第6节', false),
    new SuperviseFilterSection('第7节', false),
    new SuperviseFilterSection('第8节', false),
    new SuperviseFilterSection('第9节', false),
    new SuperviseFilterSection('第10节', false),
    new SuperviseFilterSection('第11节', false),
    new SuperviseFilterSection('第12节', false)
  ];

  private chooseAcademy(): void {
    this.selectedAcademy = '计算机学院';
    this.showMajorRow = true;
  }

  private chooseMajor(): void {
    this.selectedMajor = '软件工程';
  }

  private toggleSection(target: SuperviseFilterSection): void {
    this.sections = this.sections.map((item: SuperviseFilterSection): SuperviseFilterSection => {
      return new SuperviseFilterSection(item.name, item.name === target.name ? !item.checked : item.checked);
    });
  }

  private submitFilter(): void {
    router.back();
  }

  build() {
    Stack({ alignContent: Alignment.Bottom }) {
      Column() {
        TitleBar({ title: '筛选', showBack: true })

        // 学院/专业卡：白底 marginTop 12，行间细分割线
        Column() {
          Row() {
            Text('选择学院')
              .fontSize(16)
              .fontColor($r('app.color.common_color_1'))
              .textAlign(TextAlign.Center)
            Text(this.selectedAcademy === '' ? '请选择' : this.selectedAcademy)
              .fontSize(16)
              .fontColor(this.selectedAcademy === '' ? $r('app.color.mobile_campus_supervise_filter_hint') : $r('app.color.common_color_1'))
              .textAlign(TextAlign.Start)
              .layoutWeight(1)
              .margin({ left: 12 })
              .onClick(() => {
                this.chooseAcademy();
              })
            Image($r('app.media.mobile_campus_supervise_arrow'))
              .width(12)
              .height(12)
          }
          .width('100%')
          .padding(12)
          .alignItems(VerticalAlign.Center)

          if (this.showMajorRow) {
            Row() {
              Text('选择专业')
                .fontSize(16)
                .fontColor($r('app.color.common_color_1'))
                .textAlign(TextAlign.Center)
              Text(this.selectedMajor === '' ? '请选择' : this.selectedMajor)
                .fontSize(16)
                .fontColor($r('app.color.mobile_campus_supervise_filter_hint'))
                .textAlign(TextAlign.Start)
                .layoutWeight(1)
                .margin({ left: 12 })
                .onClick(() => {
                  this.chooseMajor();
                })
              Image($r('app.media.mobile_campus_supervise_arrow'))
                .width(12)
                .height(12)
            }
            .width('100%')
            .padding(12)
            .alignItems(VerticalAlign.Center)
          }
        }
        .width('100%')
        .backgroundColor($r('app.color.white'))
        .margin({ top: 12 })

        // 节次卡：白底 marginTop 12 + 5 列 Grid
        Column() {
          Row() {
            Text('选择节次')
              .fontSize(16)
              .fontColor($r('app.color.common_color_1'))
              .textAlign(TextAlign.Center)
          }
          .width('100%')
          .padding(12)

          Grid() {
            ForEach(this.sections, (item: SuperviseFilterSection) => {
              GridItem() {
                Text(item.name)
                  .fontSize(16)
                  .fontColor(item.checked ? Color.White : $r('app.color.mobile_campus_supervise_notify_solid'))
                  .textAlign(TextAlign.Center)
                  .width('100%')
                  .height(48)
                  .backgroundColor(item.checked ? $r('app.color.mobile_campus_primary_color_default') : Color.Transparent)
                  .onClick(() => {
                    this.toggleSection(item);
                  })
              }
            }, (item: SuperviseFilterSection) => item.name)
          }
          .columnsTemplate('1fr 1fr 1fr 1fr 1fr')
          .width('100%')
          .height(96)
        }
        .width('100%')
        .backgroundColor($r('app.color.white'))
        .margin({ top: 12 })

        Blank()
          .layoutWeight(1)
      }
      .width('100%')
      .height('100%')

      // 底部提交：有选中节次时 enabled（#1B68B7 白字），否则透明底灰字
      Text('提交')
        .fontSize(17)
        .fontColor(this.hasSelection() ? Color.White : $r('app.color.common_color_3'))
        .textAlign(TextAlign.Center)
        .width('100%')
        .padding({ top: 10, bottom: 10 })
        .backgroundColor(this.hasSelection() ? $r('app.color.mobile_campus_primary_color_default') : Color.Transparent)
        .onClick(() => {
          if (this.hasSelection()) {
            this.submitFilter();
          }
        })
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.common_color_6'))
  }

  private hasSelection(): boolean {
    return this.sections.some((item: SuperviseFilterSection): boolean => item.checked);
  }
}
