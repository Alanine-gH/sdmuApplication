import { router } from '@kit.ArkUI';
import { ApiService } from '../network/ApiService';
import { ApiResponse } from '../model/ResponseModel';
import { OaReimbursed } from '../model/OaTodoModel';
import { TitleBar } from '../components/TitleBar';
import { EmptyView } from '../components/EmptyView';
import { LoadingView } from '../components/LoadingView';
import { BusinessError } from '@kit.BasicServicesKit';

/**
 * 科研项目回执列表页 — 源码级翻译（W23，原空占位重写）：
 * APK ReceiptListActivity（reimburse/view，标题"科研项目"；入口 ProjectDetailActivity
 * {PROJECT_NUMBER}，HAP Index 宫格/WMHTab"发票助手"直达无参→空 PROJECT_NUMBER）。
 *
 * 【布局】mobile_campus_reimburse_activity_receipt_list：toolbar + TabLayout(m 间距 48dip)
 *   + ViewPager。
 * 【页签源码 bug 保真】static l = {"未报销单据","已报销单据"}；o = [ExpenseFragment(已报销),
 *   UnExpenseFragment(未报销)] —— getPageTitle(l[i]) 与 Fragment 顺序**错位**：第 0 页签
 *   "未报销单据"显示 ExpenseFragment（已报销数据 reimbursed 接口），第 1 页签"已报销单据"
 *   显示 UnExpenseFragment（未报销数据 unreimbursed 接口）。HAP 按源码错位保真。
 * 【数据流源码还原（ReimburseP/ReimburseModel api/project）】
 *   ExpenseFragment.Q1 → h(...).e(PROJECT_NUMBER) → U0：POST reimbursed {PROJECT_NUMBER}
 *   → Reimbursed[]（2026-11-18 实测空 PROJECT_NUMBER code=0001 → 真实错误态）；
 *   UnExpenseFragment.Q1(k) → j(str) → W0：POST unreimbursed {PROJECT_NUMBER}（实测同 0001）。
 *   回调：count>0 → v(content) / 空 → B1(empty) / 异常 → F1(error)。
 * 【条目】ExpenseAdapter（mobile_campus_reimburse_item_expense.xml）：
 *   "金额"15fp common_color_3 + tvMoney=String.valueOf(AMOUNT) 17fp #1B68B7 ml12；
 *   "项目名称" + tvName=PROJECT_NAME 14fp + 右箭头 mobile_campus_reimburse_arrow_right；
 *   "报销日期" + tvDate=SimpleDateFormat("yyyy-MM-dd")(REIMBURSE_DATE ms) 14fp；padH12 padV15。
 * 【详情弹窗 ReimburseDetailDialog（0.8 宽）】tvTitle=PROJECT_NAME 18.5fp #1B68B7 高59dip；
 *   预约单号=SUB_NUMBER/业务编号=BUSINESS_NUMBER/业务类型=REIMBURSE_TYPE/报销金额=AMOUNT；
 *   报销人员=REIMBURSE_PEOPLE/报销日期=yyyy-MM-dd(REIMBURSE_DATE)/报销状态=REIMBURSE_TYPE/
 *   部门编号=DEPT_NUMBER/项目编号=PROJECT_NAME（**源码原样：tvProjectNum 填 PROJECT_NAME**）；
 *   摘要=DESC；确定 160dip×40dip #1B68B7 关闭；ticketfoot 底图。
 * 【禁 mock】reimbursed/unreimbursed 全真实接口；0001/空数据走真实错误/空态。
 */
@Entry
@Component
struct ReceiptListPage {
  @State pageTab: number = 0;
  @State expenseRows: OaReimbursed[] = [];
  @State unexpenseRows: OaReimbursed[] = [];
  @State expenseState: string = 'loading';
  @State unexpenseState: string = 'loading';
  @State showDetail: boolean = false;
  @State detailRow: OaReimbursed | null = null;
  /** 入参 PROJECT_NUMBER（源码 y(Intent)；Index/WMHTab 直达入口无参） */
  private projectNumber: string = '';

  aboutToAppear(): void {
    const params: Record<string, Object> | undefined = router.getParams() as Record<string, Object> | undefined;
    if (params !== undefined && params !== null) {
      const v: Object = params['PROJECT_NUMBER'];
      if (typeof v === 'string') {
        this.projectNumber = v as string;
      }
    }
    this.loadExpense();
    this.loadUnexpense();
  }

  /** 源码 ExpenseFragment.Q1：POST reimbursed {PROJECT_NUMBER}（页签错位：0 页签标题下的数据） */
  private loadExpense(): void {
    this.expenseState = 'loading';
    ApiService.getReimbursedList(this.projectNumber)
      .then((response: ApiResponse<OaReimbursed[]>) => {
        if (response.code === 1000) {
          return;
        }
        if (response.code === 0) {
          this.expenseRows = response.data;
          this.expenseState = this.expenseRows.length > 0 ? 'content' : 'empty';
        } else {
          ApiService.logError('reimbursed fail code=' + response.code + ' msg=' + response.message);
          this.expenseRows = [];
          this.expenseState = 'error';
        }
      })
      .catch((error: BusinessError) => {
        ApiService.logError('reimbursed error: ' + error.message);
        this.expenseRows = [];
        this.expenseState = 'error';
      });
  }

  /** 源码 UnExpenseFragment.Q1：POST unreimbursed {PROJECT_NUMBER}（1 页签标题下的数据） */
  private loadUnexpense(): void {
    this.unexpenseState = 'loading';
    ApiService.getUnreimbursedList(this.projectNumber)
      .then((response: ApiResponse<OaReimbursed[]>) => {
        if (response.code === 1000) {
          return;
        }
        if (response.code === 0) {
          this.unexpenseRows = response.data;
          this.unexpenseState = this.unexpenseRows.length > 0 ? 'content' : 'empty';
        } else {
          ApiService.logError('unreimbursed fail code=' + response.code + ' msg=' + response.message);
          this.unexpenseRows = [];
          this.unexpenseState = 'error';
        }
      })
      .catch((error: BusinessError) => {
        ApiService.logError('unreimbursed error: ' + error.message);
        this.unexpenseRows = [];
        this.unexpenseState = 'error';
      });
  }

  /** 源码 b 类：条目点击 → ReimburseDetailDialog.o(bean)+show */
  private openDetail(row: OaReimbursed): void {
    this.detailRow = row;
    this.showDetail = true;
  }

  /** SimpleDateFormat("yyyy-MM-dd")(REIMBURSE_DATE ms) */
  private formatDate(ms: number): string {
    if (ms <= 0) {
      return '';
    }
    const date: Date = new Date(ms);
    const y: string = String(date.getFullYear());
    const m: string = String(date.getMonth() + 1).padStart(2, '0');
    const d: string = String(date.getDate()).padStart(2, '0');
    return y + '-' + m + '-' + d;
  }

  build() {
    Stack() {
      Column() {
        TitleBar({ title: '科研项目', showBack: true })

        // TabLayout（l = 未报销单据/已报销单据；间距 48dip）
        Row() {
          this.tabItem('未报销单据', 0)
          this.tabItem('已报销单据', 1)
        }
        .width('100%')
        .height(44)
        .padding({ left: 24 })
        .alignItems(VerticalAlign.Center)
        .backgroundColor($r('app.color.white'))

        Divider().color($r('app.color.common_color_5')).strokeWidth(0.5)

        if (this.pageTab === 0) {
          this.expensePage()
        } else {
          this.unexpensePage()
        }
      }
      .width('100%')
      .height('100%')
      .backgroundColor($r('app.color.main_bg'))

      // ReimburseDetailDialog（0.8 宽弹窗）
      if (this.showDetail && this.detailRow !== null) {
        this.detailDialog()
      }
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  tabItem(label: string, index: number) {
    Column() {
      Text(label)
        .fontSize(16)
        .fontColor(this.pageTab === index ? $r('app.color.mobile_campus_primary_color_default')
          : $r('app.color.common_color_1'))
        .margin({ right: 24 })
      if (this.pageTab === index) {
        Column()
          .width(24)
          .height(2)
          .backgroundColor($r('app.color.mobile_campus_primary_color_default'))
          .margin({ top: 4 })
      }
    }
    .alignItems(HorizontalAlign.Center)
    .onClick(() => {
      this.pageTab = index;
    })
  }

  /** ExpenseFragment 页（页签 0，标题"未报销单据"——源码错位保真：数据=reimbursed 已报销） */
  @Builder
  expensePage() {
    Refresh({ refreshing: false }) {
      this.reimburseList(this.expenseRows, this.expenseState)
    }
    .onRefreshing(() => {
      this.loadExpense();
    })
    .width('100%')
    .layoutWeight(1)
  }

  /** UnExpenseFragment 页（页签 1，标题"已报销单据"——源码错位保真：数据=unreimbursed） */
  @Builder
  unexpensePage() {
    Refresh({ refreshing: false }) {
      this.reimburseList(this.unexpenseRows, this.unexpenseState)
    }
    .onRefreshing(() => {
      this.loadUnexpense();
    })
    .width('100%')
    .layoutWeight(1)
  }

  /** common_refresh_lv_rl：MultiStateView 三态 */
  @Builder
  reimburseList(rows: OaReimbursed[], state: string) {
    if (state === 'loading') {
      Column() {
        LoadingView()
      }
      .width('100%')
      .height('100%')
    } else if (state === 'error') {
      Column() {
        EmptyView({ tipText: '获取数据失败，请下拉重试' })
      }
      .width('100%')
      .height('100%')
    } else if (rows.length === 0) {
      Column() {
        EmptyView({ tipText: '暂无单据' })
      }
      .width('100%')
      .height('100%')
    } else {
      List() {
        ForEach(rows, (row: OaReimbursed) => {
          ListItem() {
            this.expenseItem(row)
          }
        }, (row: OaReimbursed) => row.SUB_NUMBER + '_' + row.BUSINESS_NUMBER + '_' + String(row.AMOUNT))
      }
      .width('100%')
      .height('100%')
      .scrollBar(BarState.Off)
      .backgroundColor($r('app.color.white'))
    }
  }

  /** mobile_campus_reimburse_item_expense：金额/项目名称/报销日期 三行 + 右箭头 */
  @Builder
  expenseItem(row: OaReimbursed) {
    Column() {
      Row() {
        Text('金额')
          .fontSize(15)
          .fontColor($r('app.color.common_color_3'))
          .width(32)
        Text(String(row.AMOUNT))
          .fontSize(17)
          .fontColor('#1B68B7')
          .margin({ left: 12 })
        Blank()
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)

      Row() {
        Text('项目名称')
          .fontSize(15)
          .fontColor($r('app.color.common_color_3'))
          .width(32)
        Text(row.PROJECT_NAME)
          .fontSize(14)
          .fontColor($r('app.color.common_color_1'))
          .margin({ left: 12 })
          .layoutWeight(1)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        Image($r('app.media.mobile_campus_reimburse_arrow_right'))
          .width(14)
          .height(14)
          .objectFit(ImageFit.Contain)
      }
      .width('100%')
      .margin({ top: 15 })
      .alignItems(VerticalAlign.Center)

      Row() {
        Text('报销日期')
          .fontSize(15)
          .fontColor($r('app.color.common_color_3'))
          .width(32)
        Text(this.formatDate(row.REIMBURSE_DATE))
          .fontSize(14)
          .fontColor($r('app.color.common_color_1'))
          .margin({ left: 12 })
        Blank()
      }
      .width('100%')
      .margin({ top: 15 })
      .alignItems(VerticalAlign.Center)
    }
    .width('100%')
    .padding({ left: 12, right: 12, top: 15, bottom: 15 })
    .border({ width: { bottom: 0.5 }, color: $r('app.color.common_color_5') })
    .onClick(() => {
      this.openDetail(row);
    })
  }

  /** mobile_campus_reimburse_dialog_detail：0.8 宽弹窗 + ticketfoot 底图 */
  @Builder
  detailDialog() {
    Stack({ alignContent: Alignment.Center }) {
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor('rgba(0,0,0,0.5)')
        .onClick(() => {
          this.showDetail = false;
        })

      Column() {
        Column() {
          Text(this.detailRow === null ? '' : this.detailRow.PROJECT_NAME)
            .fontSize(18.5)
            .fontColor('#1B68B7')
            .height(59)
            .width('100%')
            .textAlign(TextAlign.Center)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })

          Column() {
            this.detailLine('预约单号', this.detailRow === null ? '' : this.detailRow.SUB_NUMBER)
            this.detailLine('业务编号', this.detailRow === null ? '' : this.detailRow.BUSINESS_NUMBER)
            this.detailLine('业务类型', this.detailRow === null ? '' : this.detailRow.REIMBURSE_TYPE)
            this.detailLine('报销金额',
              this.detailRow === null ? '' : String(this.detailRow.AMOUNT))
          }
          .width('100%')
          .padding({ left: 18, right: 18, top: 21, bottom: 21 })

          Column() {
            this.detailLine('报销人员', this.detailRow === null ? '' : this.detailRow.REIMBURSE_PEOPLE)
            this.detailLine('报销日期',
              this.detailRow === null ? '' : this.formatDate(this.detailRow.REIMBURSE_DATE))
            // 源码原样：报销状态 tvExpenseType = REIMBURSE_TYPE
            this.detailLine('报销状态', this.detailRow === null ? '' : this.detailRow.REIMBURSE_TYPE)
            this.detailLine('部门编号', this.detailRow === null ? '' : this.detailRow.DEPT_NUMBER)
            // 源码原样 bug：tvProjectNum 填 PROJECT_NAME（ReimburseDetailDialog.o:73）
            this.detailLine('项目编号', this.detailRow === null ? '' : this.detailRow.PROJECT_NAME)
          }
          .width('100%')
          .padding({ left: 18, right: 18, top: 21, bottom: 21 })

          Column() {
            Row() {
              Text('摘         要')
                .fontSize(14)
                .fontColor($r('app.color.common_color_1'))
              Text(this.detailRow === null ? '' : this.detailRow.DESC)
                .fontSize(14)
                .fontColor($r('app.color.common_color_3'))
                .margin({ left: 12 })
                .layoutWeight(1)
            }
            .width('100%')
            .alignItems(VerticalAlign.Top)

            Text('确定')
              .fontSize(17)
              .fontColor($r('app.color.white'))
              .backgroundColor('#1B68B7')
              .width(160)
              .height(40)
              .textAlign(TextAlign.Center)
              .margin({ top: 24 })
              .onClick(() => {
                this.showDetail = false;
              })
          }
          .width('100%')
          .padding({ left: 18, right: 18, top: 21, bottom: 21 })
        }
        .width('80%')
        .borderRadius(8)
        .backgroundColor($r('app.color.white'))

        Image($r('app.media.mobile_campus_reimburse_ticketfoot'))
          .width('80%')
          .height(40)
          .objectFit(ImageFit.Cover)
          .margin({ top: -8 })
      }
      .width('100%')
      .alignItems(HorizontalAlign.Center)
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  detailLine(label: string, value: string) {
    Row() {
      Text(label)
        .fontSize(14)
        .fontColor($r('app.color.common_color_1'))
      Text(value)
        .fontSize(14)
        .fontColor($r('app.color.common_color_3'))
        .margin({ left: 12 })
        .layoutWeight(1)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
    }
    .width('100%')
    .margin({ top: 12 })
    .alignItems(VerticalAlign.Center)
  }
}
