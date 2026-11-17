import { TitleBar } from '../components/TitleBar';

class DetailRow {
  key: string = '';
  value: string = '';

  constructor(key: string, value: string) {
    this.key = key;
    this.value = value;
  }
}

@Entry
@Component
struct ProgramDetailPage {
  @State rows: DetailRow[] = [
    new DetailRow('项目名称', '数据中台关键技术研究与应用'),
    new DetailRow('项目分类', '纵向科研项目'),
    new DetailRow('项目成员', '张明、李红、王强'),
    new DetailRow('项目状态', '执行中'),
    new DetailRow('合同金额', '120,000.00 元'),
    new DetailRow('到账金额', '100,000.00 元'),
    new DetailRow('支付金额', '45,000.00 元'),
    new DetailRow('外拨金额', '0.00 元')
  ];

  build() {
    Column() {
      TitleBar({ title: '项目明细' })
      Scroll() {
        Column() {
          ForEach(this.rows, (row: DetailRow, index: number) => {
            Row() {
              Text(row.key)
                .fontSize(15)
                .fontColor($r('app.color.common_color_3'))
                .width(80)
              Text(row.value)
                .fontSize(15)
                .fontColor($r('app.color.blue_default'))
            }
            .width('100%')
            .alignItems(VerticalAlign.Top)
            .margin({ top: index > 0 ? 15 : 0 })
          }, (row: DetailRow, index: number) => 'r_' + index + '_' + row.key)
        }
        .width('100%')
        .padding({ left: 18, right: 18, bottom: 21 })
      }
      .width('100%')
      .layoutWeight(1)
      .scrollBar(BarState.Off)
      .align(Alignment.Top)
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.main_bg'))
  }
}
