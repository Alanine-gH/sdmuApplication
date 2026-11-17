import { router } from '@kit.ArkUI';
import { TitleBar } from '../components/TitleBar';

class ProgramStat {
  value: string = '';
  label: string = '';
  isBlue: boolean = true;

  constructor(value: string, label: string, isBlue: boolean) {
    this.value = value;
    this.label = label;
    this.isBlue = isBlue;
  }
}

class ProgramItem {
  name: string = '';
  departNum: string = '';
  projectCode: string = '';
  stats: ProgramStat[] = [];

  constructor(name: string, departNum: string, projectCode: string, stats: ProgramStat[]) {
    this.name = name;
    this.departNum = departNum;
    this.projectCode = projectCode;
    this.stats = stats;
  }
}

@Entry
@Component
struct ProgramListPage {
  @State programList: ProgramItem[] = [
    new ProgramItem('数据中台关键技术研究与应用', 'D0010', 'XM2026A01', [
      new ProgramStat('120,000.00', '总金额（元）', true),
      new ProgramStat('20,000.00', '冻结金额（元）', false),
      new ProgramStat('100,000.00', '可用金额（元）', true)
    ]),
    new ProgramItem('智慧校园信息服务平台建设', 'D0022', 'XM2026B03', [
      new ProgramStat('85,600.00', '总金额（元）', true),
      new ProgramStat('5,600.00', '冻结金额（元）', false),
      new ProgramStat('80,000.00', '可用金额（元）', true)
    ]),
    new ProgramItem('人工智能实验室设备采购', 'D0015', 'XM2026C02', [
      new ProgramStat('56,800.00', '总金额（元）', true),
      new ProgramStat('0.00', '冻结金额（元）', false),
      new ProgramStat('56,800.00', '可用金额（元）', true)
    ])
  ];

  @Builder
  statItem(stat: ProgramStat) {
    Column() {
      Text(stat.value)
        .fontSize(16)
        .fontColor(stat.isBlue ? $r('app.color.blue_default') : $r('app.color.common_color_1'))
      Text(stat.label)
        .fontSize(13)
        .fontColor($r('app.color.common_color_3'))
        .margin({ top: 8 })
    }
    .layoutWeight(1)
    .alignItems(HorizontalAlign.Center)
    .justifyContent(FlexAlign.Center)
  }

  @Builder
  programCard(item: ProgramItem) {
    Column() {
      Column() {
        Row() {
          Text('项目名称')
            .fontSize(14)
            .fontColor($r('app.color.common_color_3'))
          Text(item.name)
            .fontSize(16)
            .fontColor($r('app.color.blue_default'))
            .margin({ left: 12 })
            .layoutWeight(1)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
        .width('100%')
        .alignItems(VerticalAlign.Center)

        Row() {
          Text('部门编号')
            .fontSize(14)
            .fontColor($r('app.color.common_color_3'))
          Text(item.departNum)
            .fontSize(14)
            .fontColor($r('app.color.blue_default'))
            .margin({ left: 12 })
            .layoutWeight(1)
          Image($r('app.media.mobile_campus_reimburse_arrow_right'))
            .width(16)
            .height(16)
        }
        .width('100%')
        .alignItems(VerticalAlign.Center)
        .margin({ top: 17 })

        Row() {
          Text('项目编码')
            .fontSize(14)
            .fontColor($r('app.color.common_color_3'))
          Text(item.projectCode)
            .fontSize(14)
            .fontColor($r('app.color.blue_default'))
            .margin({ left: 12 })
        }
        .width('100%')
        .alignItems(VerticalAlign.Center)
        .margin({ top: 8 })
      }
      .width('100%')
      .padding({ left: 12, right: 12, top: 17, bottom: 18 })

      Divider()
        .color($r('app.color.common_color_6'))
        .strokeWidth(0.5)
        .width('100%')

      Row() {
        ForEach(item.stats, (stat: ProgramStat, index: number) => {
          this.statItem(stat)
        }, (stat: ProgramStat, index: number) => index + '_' + stat.label)
      }
      .width('100%')
      .padding({ left: 12, right: 12, top: 17, bottom: 18 })

      Divider()
        .color($r('app.color.common_color_6'))
        .strokeWidth(0.5)
        .width('100%')

      Text('查看项目详情')
        .fontSize(16)
        .fontColor($r('app.color.blue_default'))
        .width('100%')
        .height(44)
        .textAlign(TextAlign.Center)
        .onClick(() => {
          router.pushUrl({ url: 'pages/ProgramDetailPage' });
        })
    }
    .width('100%')
    .backgroundColor($r('app.color.white'))
  }

  build() {
    Column() {
      TitleBar({ title: '项目列表' })
      List({ space: 12 }) {
        ForEach(this.programList, (item: ProgramItem, index: number) => {
          ListItem() {
            this.programCard(item)
          }
        }, (item: ProgramItem, index: number) => index + '_' + item.projectCode)
      }
      .width('100%')
      .layoutWeight(1)
      .padding({ top: 12, left: 12, right: 12 })
      .scrollBar(BarState.Off)
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.common_color_6'))
  }
}
