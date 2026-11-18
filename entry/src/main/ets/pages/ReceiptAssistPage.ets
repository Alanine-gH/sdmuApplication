import { BusinessError } from '@kit.BasicServicesKit';
import { LengthMetrics } from '@kit.ArkUI';
import { TitleBar } from '../components/TitleBar';
import { LoadingView } from '../components/LoadingView';
import { EmptyView } from '../components/EmptyView';
import { ApiService } from '../network/ApiService';
import { ApiResponse } from '../model/ResponseModel';
import { RatepayingEntry } from '../model/ContactModel';
import { Constants } from '../data/Constants';

/**
 * 发票助手 — 源码级翻译（ReceiptAssistActivity + ReceiptAssistFragment，[W28 final-b]）。
 *
 * 【布局】mobile_campus_activity_receipt：根 bg common_color_5(#e7e7e7) + toolbar_normal("发票助手")
 *   + MultiStateView + RelativeLayout：ViewPager(fill) + IndicatorLayout(底部居中 marginBottom 15dip)。
 *   IndicatorLayout = 6dip 圆点×N、间距 4dip（count>1 才绘制），本文档多张抬头时显示。
 * 【数据】RatepayingPImpl.b() → RatepayingModel.T0：GET ratepaying/getDetail 无参
 *   （RatepayingFactory a()="api" b()="ratepaying"，e.b GET）→ Ratepaying[]；
 *   f() 回调：-3010 → ERROR_NETWORK，其余 error → 错误态；空数组 → 空态。
 * 【页】mobile_campus_fragment_receipt_assist：ScrollView 内白卡（圆角4、左右 margin20、top15、
 *   paddingH15）：
 *   - tvContent：MC 22dip 主色 #1b68b7 + 其余 18dip #333，行距 10dip，文本=
 *     MC+"\n类型："+TYPE+"\n税号："+SH+"\n单位地址："+DWDZ+"\n"[电话号码：DHHM+"\n"（DHHM 非空且非空格）]
 *     +"开户银行："+KHYH+"\n银行账号："+YHZH；
 *   - my_receipt_name/type/number/address/dial/bank/bank_account 及其容器 XML visibility="gone"
 *     且源码 K1() 只 setText 不置可见 → 恒隐藏（保真省略渲染）；
 *   - my_receipt_qrcode 150×150dip 居中 mt25：d.c()+/mobileapi_ydxy/open/common/post/picture?uuid=QRCODE
 *     （失败占位 icon_share）+ "商家扫描二维码快速获取抬头信息" 14sp #b8c0c9 居中 mt14 mb14；
 *   - 分隔线 + "开票须知" 17sp #b8c0c9 居中 paddingTop9 paddingBottom12 marginTop5。
 * 【探针】temp/probe_w28_final_b.py 锚点 [W28 final-b]。
 */
@Entry
@Component
struct ReceiptAssistPage {
  @State rows: RatepayingEntry[] = [];
  @State pageState: string = 'loading';
  @State current: number = 0;

  aboutToAppear(): void {
    this.loadData();
  }

  /** 源码 M2() → RatepayingPImpl.b()：GET ratepaying/getDetail */
  private loadData(): void {
    this.pageState = 'loading';
    ApiService.getReceiptAssistList()
      .then((response: ApiResponse<RatepayingEntry[]>) => {
        if (response.code === 1000) {
          return;
        }
        if (response.code !== 0) {
          this.rows = [];
          this.pageState = 'error';
          ApiService.logError('receipt assist fail: ' + response.message);
          return;
        }
        this.rows = response.data;
        this.pageState = this.rows.length > 0 ? 'content' : 'empty';
      })
      .catch((error: BusinessError) => {
        ApiService.logError('receipt assist error: ' + error.message);
        this.rows = [];
        this.pageState = 'error';
      });
  }

  /** 源码 K1()：tvContent 全文（MC 首段主色 22dip，其余 18dip #333） */
  private contentOf(row: RatepayingEntry): string {
    let text: string = row.MC + '\n类型：' + row.TYPE + '\n税号：' + row.SH +
      '\n单位地址：' + row.DWDZ + '\n';
    if (row.DHHM !== '' && row.DHHM !== ' ') {
      text = text + '电话号码：' + row.DHHM + '\n';
    }
    return text + '开户银行：' + row.KHYH + '\n银行账号：' + row.YHZH;
  }

  private qrUrl(row: RatepayingEntry): string {
    return Constants.SOCKET_HOST + '/mobileapi_ydxy/open/common/post/picture?uuid=' + row.QRCODE;
  }

  @Builder
  receiptCard(row: RatepayingEntry) {
    Scroll() {
      Column() {
        Text() {
          Span(row.MC).fontSize(22).fontColor($r('app.color.mobile_campus_primary_color_default'))
          Span(this.contentOf(row).substring(row.MC.length))
            .fontSize(18)
            .fontColor($r('app.color.common_color_1'))
        }
        .width('100%')
        .lineSpacing(LengthMetrics.vp(10))
        .padding({ top: 10, bottom: 10 })

        Image(this.qrUrl(row))
          .width(150)
          .height(150)
          .objectFit(ImageFit.Contain)
          .alt($r('app.media.icon_share'))
          .margin({ top: 25 })

        Text('商家扫描二维码快速获取抬头信息')
          .fontSize(14)
          .fontColor('#B8C0C9')
          .width('100%')
          .textAlign(TextAlign.Center)
          .margin({ top: 14, bottom: 14 })

        Divider().color($r('app.color.common_color_36')).strokeWidth(0.5)

        Text('开票须知')
          .fontSize(17)
          .fontColor('#B8C0C9')
          .width('100%')
          .textAlign(TextAlign.Center)
          .padding({ top: 9, bottom: 12 })
          .margin({ top: 5 })
      }
      .width('100%')
      .padding({ left: 15, right: 15 })
      .backgroundColor(Color.White)
      .borderRadius(4)
      .margin({ left: 20, right: 20, top: 15 })
    }
    .width('100%')
    .height('100%')
    .scrollBar(BarState.Off)
  }

  @Builder
  contentView() {
    if (this.pageState === 'loading') {
      Column() { LoadingView() }.width('100%').height('100%')
    } else if (this.pageState === 'error') {
      Column() { EmptyView({ tipText: '获取发票抬头失败，请稍后重试' }) }.width('100%').height('100%')
    } else if (this.pageState === 'empty') {
      Column() { EmptyView({ tipText: '暂无发票抬头' }) }.width('100%').height('100%')
    } else {
      Column() {
        Swiper() {
          ForEach(this.rows, (row: RatepayingEntry) => {
            this.receiptCard(row)
          }, (row: RatepayingEntry) => row.XLH + '_' + row.MC)
        }
        .index(this.current)
        .loop(false)
        .indicator(false)
        .width('100%')
        .layoutWeight(1)
        .onChange((index: number) => {
          this.current = index;
        })

        if (this.rows.length > 1) {
          Row() {
            ForEach(this.rows, (row: RatepayingEntry, index: number) => {
              Circle()
                .width(6)
                .height(6)
                .fill(this.current === index ? '#1B68B7' : '#CCCCCC')
                .margin({ left: 4, right: 4 })
            }, (row: RatepayingEntry, index: number) => 'dot_' + String(index))
          }
          .justifyContent(FlexAlign.Center)
          .height(12)
          .margin({ bottom: 7.5 })
        }
      }
      .width('100%')
      .height('100%')
    }
  }

  build() {
    Column() {
      TitleBar({ title: '发票助手', showBack: true })
      this.contentView()
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#E7E7E7')
  }
}
