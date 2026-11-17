import { router } from '@kit.ArkUI';
import { TitleBar } from '../components/TitleBar';

class ExpenseItem {
  money: string = '';
  projectName: string = '';
  date: string = '';
  billNo: string = '';

  constructor(money: string, projectName: string, date: string, billNo: string) {
    this.money = money;
    this.projectName = projectName;
    this.date = date;
    this.billNo = billNo;
  }
}

@Entry
@Component
struct ReceiptListPage {
  @State currentIndex: number = 0;
  private unExpenseList: ExpenseItem[] = [
    new ExpenseItem('¥1,250.00', '横向科研-数据平台建设', '2026-05-12', 'BX20260512001'),
    new ExpenseItem('¥860.50', '教学耗材采购项目', '2026-05-20', 'BX20260520003'),
    new ExpenseItem('¥3,400.00', '学术会议差旅费报销', '2026-06-02', 'BX20260602008')
  ];
  private expenseList: ExpenseItem[] = [
    new ExpenseItem('¥2,180.00', '实验室设备维护费', '2026-04-15', 'DJ20260415002'),
    new ExpenseItem('¥450.00', '图书资料购置费', '2026-04-28', 'DJ20260428005'),
    new ExpenseItem('¥5,760.00', '科研调研差旅费', '2026-05-06', 'DJ20260506001')
  ];

  @Builder
  labelView(text: string) {
    Text(text)
      .fontSize(15)
      .fontColor($r('app.color.common_color_3'))
      .width(64)
      .height('100%')
      .textAlign(TextAlign.Start)
  }

  @Builder
  unExpenseItem(item: ExpenseItem) {
    Column() {
      Row() {
        this.labelView('金额')
        Text(item.money)
          .fontSize(17)
          .fontColor($r('app.color.blue_default'))
          .margin({ left: 12 })
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)

      Row() {
        this.labelView('项目名称')
        Text(item.projectName)
          .fontSize(14)
          .fontColor($r('app.color.common_color_1'))
          .margin({ left: 12 })
          .layoutWeight(1)
        Image($r('app.media.mobile_campus_reimburse_arrow_right'))
          .width(16)
          .height(16)
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)
      .margin({ top: 15 })

      Row() {
        this.labelView('报销日期')
        Text(item.date)
          .fontSize(14)
          .fontColor($r('app.color.common_color_1'))
          .margin({ left: 12 })
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)
      .margin({ top: 15 })
    }
    .width('100%')
    .padding({ left: 12, right: 12, top: 15, bottom: 15 })
    .backgroundColor($r('app.color.white'))
    .onClick(() => {
      router.pushUrl({ url: 'pages/ReceiptDetailPage' });
    })
  }

  @Builder
  expenseItem(item: ExpenseItem) {
    Column() {
      Row() {
        this.labelView('单据编号')
        Text(item.billNo)
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

      Row() {
        this.labelView('金额')
        Text(item.money)
          .fontSize(17)
          .fontColor($r('app.color.blue_default'))
          .margin({ left: 12 })
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)
      .margin({ top: 15 })

      Row() {
        this.labelView('单据日期')
        Text(item.date)
          .fontSize(14)
          .fontColor($r('app.color.blue_default'))
          .margin({ left: 12 })
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)
      .margin({ top: 15 })
    }
    .width('100%')
    .padding({ left: 12, right: 12, top: 15, bottom: 15 })
    .backgroundColor($r('app.color.white'))
    .onClick(() => {
      router.pushUrl({ url: 'pages/ReceiptDetailPage' });
    })
  }

  @Builder
  listContent(list: ExpenseItem[], isV2: boolean) {
    List() {
      ForEach(list, (item: ExpenseItem, index: number) => {
        ListItem() {
          if (isV2) {
            this.expenseItem(item)
          } else {
            this.unExpenseItem(item)
          }
        }
      }, (item: ExpenseItem, index: number) => isV2 + '_' + index + '_' + item.billNo)
    }
    .width('100%')
    .height('100%')
    .divider({
      strokeWidth: 0.5,
      color: $r('app.color.common_color_6'),
      startMargin: 12,
      endMargin: 12
    })
    .scrollBar(BarState.Off)
  }

  build() {
    Column() {
      TitleBar({ title: '报销单' })
      Tabs({ barPosition: BarPosition.Start, index: this.currentIndex }) {
        TabContent() {
          this.listContent(this.unExpenseList, false)
        }
        .tabBar(this.tabBar('未报销', 0))

        TabContent() {
          this.listContent(this.expenseList, true)
        }
        .tabBar(this.tabBar('已报销', 1))
      }
      .barHeight(44)
      .width('100%')
      .layoutWeight(1)
      .onChange((index: number) => {
        this.currentIndex = index;
      })
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.main_bg'))
  }

  @Builder
  tabBar(title: string, index: number) {
    Text(title)
      .fontSize(16)
      .fontColor(this.currentIndex === index ? $r('app.color.mobile_campus_primary_color_default') : $r('app.color.common_color_1'))
      .fontWeight(this.currentIndex === index ? FontWeight.Medium : FontWeight.Normal)
  }
}
