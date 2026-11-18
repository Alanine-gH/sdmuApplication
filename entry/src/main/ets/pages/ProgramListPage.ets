import { TitleBar } from '../components/TitleBar';
import { router } from '@kit.ArkUI';
import { ApiService } from '../network/ApiService';
import { ApiResponse } from '../model/ResponseModel';
import { ReimbursementEntry } from '../model/ContactModel';
import { EmptyView } from '../components/EmptyView';
import { LoadingView } from '../components/LoadingView';

/**
 * 科研项目列表页 — 源码级翻译（ProgramListActivity.java 逐行 → ArkTS，[W25 misc-b]）：
 *
 * 【布局】mobile_campus_reimburse_activity_program_list.xml：bg#f2f2f2 toolbar("科研项目"，T1 gVar.n)
 *   + common_refresh_lv_rl（PullToRefreshLayout + ListView padT12 + reimburse divider）
 * 【数据】O2() → ReimburseP.f() → ReimburseModel.V0：GET project/reimbursement 无参（AchievementFactory
 *   域，ReimburseFactory a()="api" b()="project"）→ Reimbursement[]；下拉刷新重载（c 类 a()）；
 *   成功 g() → adapter setData；b()：count>0 → content / 空 → EMPTY；e() → ERROR；f() → toast(message)
 * 【行】mobile_campus_reimburse_item_program.xml（px_to_dip N=N/2）：块1 padH12 padT17 padB18：
 *   "项目名称" 14fp common_color_3 + PROJECT_NAME 16fp common_color_1 ml12（tvState XML gone 保真省略）；
 *   mt17："部门编号" + DEPT_NUMBER ml12 + arrow_right；mt8："项目编码" + PROJECT_NUMBER；
 *   块2 三列：总金额 AMOUNT #1b68b7 / 冻结金额 FIZZEZ_AMOUNT common_color_1 / 可用金额 USABLE_AMOUNT
 *   #1b68b7 + 标签 13fp common_color_3 mt8；
 *   "查看项目详情" 16fp #1b68b7 高44 居中（点击 d 类 → /reimburse/detail{PROJECT_NUMBER}）
 * 【跳转】行点击 b 类 → /reimburse/receiptList{PROJECT_NUMBER}（HAP ReceiptListPage）；
 *   "查看项目详情" d 类 → /reimburse/detail{PROJECT_NUMBER}（HAP ReceiptDetailPage，映射表 no-source 占位）
 */
@Entry
@Component
struct ProgramListPage {
  @State list: ReimbursementEntry[] = [];
  @State isLoading: boolean = true;
  @State showError: boolean = false;
  @State isRefreshing: boolean = false;

  aboutToAppear(): void {
    this.loadData(false);
  }

  /** 源码 O2()：ReimburseModel.V0 GET project/reimbursement 无参 */
  private loadData(isRefresh: boolean): void {
    this.isRefreshing = isRefresh;
    this.isLoading = !isRefresh;
    ApiService.getReimbursementList()
      .then((response: ApiResponse<ReimbursementEntry[]>) => {
        if (response.code === 1000) {
          // 登录失效统一拦截层已处理
          this.isLoading = false;
          this.isRefreshing = false;
          return;
        }
        this.isLoading = false;
        this.isRefreshing = false;
        if (response.code !== 0) {
          // 源码 f()：toast(message)
          const msg: string = response.message === '' ? '服务器繁忙，请稍后再试' : response.message;
          this.getUIContext().getPromptAction().showToast({ message: msg });
          if (!isRefresh) {
            this.showError = true;
          }
          return;
        }
        // 源码 g() + b()：有数据 → content；空 → EMPTY
        this.list = response.data;
      })
      .catch(() => {
        // 源码 e()：异常 → ERROR
        ApiService.logError('ProgramListPage load error');
        this.isLoading = false;
        this.isRefreshing = false;
        this.showError = true;
      });
  }

  /** 源码 b 类：行点击 → /reimburse/receiptList{PROJECT_NUMBER} */
  private openReceiptList(bean: ReimbursementEntry): void {
    router.pushUrl({ url: 'pages/ReceiptListPage',
      params: { 'PROJECT_NUMBER': bean.PROJECT_NUMBER } as Record<string, string> });
  }

  /** 源码 d 类：查看项目详情 → /reimburse/detail{PROJECT_NUMBER} */
  private openProjectDetail(bean: ReimbursementEntry): void {
    router.pushUrl({ url: 'pages/ReceiptDetailPage',
      params: { 'PROJECT_NUMBER': bean.PROJECT_NUMBER } as Record<string, string> });
  }

  build() {
    Column() {
      TitleBar({ title: '科研项目', showBack: true })

      if (this.isLoading) {
        LoadingView()
      } else if (this.showError) {
        // 源码 e() → ERROR 态
        Column() {
          EmptyView({ tipText: '加载失败，请检查网络后重试' })
        }
        .width('100%')
        .layoutWeight(1)
      } else if (this.list.length === 0) {
        // 源码 b()：count==0 → EMPTY
        Column() {
          EmptyView({ tipText: '暂无数据' })
        }
        .width('100%')
        .layoutWeight(1)
      } else {
        Refresh({ refreshing: this.isRefreshing }) {
          List() {
            ForEach(this.list, (bean: ReimbursementEntry) => {
              ListItem() {
                this.programRow(bean)
              }
            }, (bean: ReimbursementEntry, idx: number) => bean.PROJECT_NUMBER + '_' + idx)
          }
          .width('100%')
          .padding({ top: 12 })
          .scrollBar(BarState.Off)
        }
        .width('100%')
        .layoutWeight(1)
        .onRefreshing(() => {
          // 源码 PullToRefreshLayout c 类 a()：下拉 → O2() 重载
          this.loadData(true);
        })
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F2F2F2')
  }

  // mobile_campus_reimburse_item_program.xml：块1(名称/编号) + 块2(三列金额) + 查看项目详情
  @Builder
  programRow(bean: ReimbursementEntry) {
    Column() {
      Column() {
        Row() {
          Text('项目名称')
            .fontSize(14)
            .fontColor($r('app.color.common_color_3'))
          Text(bean.PROJECT_NAME)
            .fontSize(16)
            .fontColor($r('app.color.common_color_1'))
            .margin({ left: 12 })
            .layoutWeight(1)
            .maxLines(1)
          // tvState：XML visibility=gone，adapter 无显示操作 → 保真省略
        }
        .width('100%')
        .alignItems(VerticalAlign.Center)

        Column() {
          Row() {
            Text('部门编号')
              .fontSize(14)
              .fontColor($r('app.color.common_color_3'))
            Text(String(bean.DEPT_NUMBER))
              .fontSize(14)
              .fontColor($r('app.color.common_color_1'))
              .margin({ left: 12 })
              .layoutWeight(1)
            Image($r('app.media.mobile_campus_reimburse_arrow_right'))
              .width(14)
              .height(14)
          }
          .width('100%')
          .alignItems(VerticalAlign.Center)

          Row() {
            Text('项目编码')
              .fontSize(14)
              .fontColor($r('app.color.common_color_3'))
            Text(bean.PROJECT_NUMBER)
              .fontSize(14)
              .fontColor($r('app.color.common_color_1'))
              .margin({ left: 12 })
              .layoutWeight(1)
          }
          .width('100%')
          .margin({ top: 8 })
          .alignItems(VerticalAlign.Center)
        }
        .width('100%')
        .margin({ top: 17 })
      }
      .width('100%')
      .padding({ left: 12, right: 12, top: 17, bottom: 18 })

      Divider()
        .color($r('app.color.common_color_5'))
        .strokeWidth(0.5)
        .width('100%')

      Column() {
        Row() {
          Column() {
            Text(String(bean.AMOUNT))
              .fontColor('#1B68B7')
            Text('总金额（元）')
              .fontSize(13)
              .fontColor($r('app.color.common_color_3'))
              .margin({ top: 8 })
          }
          .width('100%')
          .alignItems(HorizontalAlign.Center)
          .layoutWeight(1)

          Column() {
            Text(bean.FIZZEZ_AMOUNT)
              .fontColor($r('app.color.common_color_1'))
            Text('冻结金额（元）')
              .fontSize(13)
              .fontColor($r('app.color.common_color_3'))
              .margin({ top: 8 })
          }
          .width('100%')
          .alignItems(HorizontalAlign.Center)
          .layoutWeight(1)

          Column() {
            Text(bean.USABLE_AMOUNT)
              .fontColor('#1B68B7')
            Text('可用金额（元）')
              .fontSize(13)
              .fontColor($r('app.color.common_color_3'))
              .margin({ top: 8 })
          }
          .width('100%')
          .alignItems(HorizontalAlign.Center)
          .layoutWeight(1)
        }
        .width('100%')
        .padding({ left: 12, right: 12, top: 17, bottom: 18 })
        .alignItems(VerticalAlign.Center)
      }
      .width('100%')

      // tvProjectDetail："查看项目详情" 16fp #1b68b7 高44（d 类 → detail）
      Text('查看项目详情')
        .fontSize(16)
        .fontColor('#1B68B7')
        .width('100%')
        .height(44)
        .textAlign(TextAlign.Center)
        .onClick(() => {
          this.openProjectDetail(bean);
        })
    }
    .width('100%')
    .backgroundColor($r('app.color.white'))
    .onClick(() => {
      this.openReceiptList(bean);
    })
  }
}
