import { router } from '@kit.ArkUI';
import { ApiService } from '../network/ApiService';
import { ApiResponse } from '../model/ResponseModel';
import { OaInspectionRecord } from '../model/OaTodoModel';
import { TitleBar } from '../components/TitleBar';
import { EmptyView } from '../components/EmptyView';
import { LoadingView } from '../components/LoadingView';
import { BusinessError } from '@kit.BasicServicesKit';

/**
 * 巡检记录列表页 — 源码级翻译（W23，原空占位重写）：
 * APK InspectionRecordActivity（inspection/view，入口 AppInfo{YYID} 宫格应用）。
 *
 * 【布局】inspection_activity_record.xml：
 *   toolbar"寝室检查"（inspection_title）+ 头部 tvAddRecord"添加记录"（inspection_shape_add
 *   圆角4 common_color_5 bg、inspection_add 图标、高 62dip、14fp common_color_3、pad 12）
 *   + MultiStateView（lvRecord pad 15dip、行间隔 15dip）。
 * 【数据流源码还原】
 *   N2 → InspectionPImpl.f → InspectionModel.Y0：GET getCheckRecordsList 无参
 *   → CheckRecord[]{XLH, JCJLMC}（2026-11-18 实测测试账号 [] 真实空态）。
 * 【列表】InspectionRecordAdapter（inspection_item_record.xml：白色圆角4 高62dip
 *   padL12/R15 + tvWeek=JCJLMC 14fp black；tvContent 无绑定恒空）。
 * 【路由】a 类添加 → InspectionActivity {addRecord:true, yyid} rc100；
 *   b 类条目点击 → InspectionActivity {XLH, JCJLMC, yyid} rc100。
 * 【返回消费】onActivityResult：101 → updateItem(XLH, JCJLMC)；102 → deleteItem+重拉；
 *   103 → 重拉。HAP 等价 AppStorage 'inspection_result' = JSON {op:"update"|"delete"|"create",
 *   XLH, JCJLMC}，onPageShow 消费。
 * 【禁 mock】getCheckRecordsList 真实接口；空态=真实空态。
 */
@Entry
@Component
struct InspectionRecordPage {
  @State records: OaInspectionRecord[] = [];
  @State isLoading: boolean = true;
  /** 入参 appInfo.getYYID（HAP 宫格入口 route params） */
  private yyid: string = '';

  aboutToAppear(): void {
    const params: Record<string, Object> | undefined = router.getParams() as Record<string, Object> | undefined;
    if (params !== undefined && params !== null) {
      const v: Object = params['yyid'];
      if (typeof v === 'string') {
        this.yyid = v as string;
      }
    }
    this.loadRecords();
  }

  onPageShow(): void {
    // 源码 onActivityResult：101 update / 102 delete+重拉 / 103 重拉
    const result: string | undefined = AppStorage.get<string>('inspection_result');
    if (result === undefined || result === '') {
      return;
    }
    AppStorage.setOrCreate<string>('inspection_result', '');
    try {
      const rec: Record<string, Object> = JSON.parse(result) as Record<string, Object>;
      const op: string = this.strOf(rec, 'op');
      const xlh: string = this.strOf(rec, 'XLH');
      if (op === 'update') {
        for (const r of this.records) {
          if (r.XLH === xlh) {
            r.JCJLMC = this.strOf(rec, 'JCJLMC');
            break;
          }
        }
        this.records = this.records.slice();
        return;
      }
      if (op === 'delete') {
        const rest: OaInspectionRecord[] = [];
        for (const r of this.records) {
          if (r.XLH !== xlh) {
            rest.push(r);
          }
        }
        this.records = rest;
      }
      this.loadRecords();
    } catch (error) {
      const err = error as BusinessError;
      ApiService.logError('InspectionRecord consume result fail: ' + err.message);
    }
  }

  private strOf(rec: Record<string, Object>, key: string): string {
    const v: Object = rec[key];
    if (typeof v === 'string') {
      return v as string;
    }
    if (typeof v === 'number') {
      return String(v as number);
    }
    return '';
  }

  /** 源码 N2：getCheckRecordsList 无参 GET */
  private loadRecords(): void {
    ApiService.getInspectionRecords()
      .then((response: ApiResponse<OaInspectionRecord[]>) => {
        if (response.code === 1000) {
          return;
        }
        if (response.code === 0) {
          this.records = response.data;
        } else {
          ApiService.logError('getCheckRecordsList fail code=' + response.code);
          this.records = [];
        }
        this.isLoading = false;
      })
      .catch((error: BusinessError) => {
        ApiService.logError('getCheckRecordsList error: ' + error.message);
        this.records = [];
        this.isLoading = false;
      });
  }

  /** 源码 a 类：添加 → InspectionActivity {addRecord:true, yyid} */
  private gotoAddRecord(): void {
    router.pushUrl({ url: 'pages/InspectionPage',
      params: { 'addRecord': 'true', 'yyid': this.yyid } as Record<string, string> });
  }

  /** 源码 b 类：条目点击 → InspectionActivity {XLH, JCJLMC, yyid} */
  private gotoRecord(record: OaInspectionRecord): void {
    router.pushUrl({ url: 'pages/InspectionPage',
      params: {
        'XLH': record.XLH,
        'JCJLMC': record.JCJLMC,
        'yyid': this.yyid
      } as Record<string, string> });
  }

  build() {
    Column() {
      TitleBar({ title: '寝室检查', showBack: true })
      // tvAddRecord：inspection_shape_add 圆角4 common_color_5 bg
      Column() {
        Row() {
          Image($r('app.media.inspection_add'))
            .width(18)
            .height(18)
            .margin({ right: 13 })
          Text('添加记录')
            .fontSize(14)
            .fontColor($r('app.color.common_color_3'))
            .layoutWeight(1)
        }
        .width('100%')
        .height(62)
        .padding({ left: 12, right: 12 })
        .borderRadius(4)
        .backgroundColor($r('app.color.common_color_5'))
        .alignItems(VerticalAlign.Center)
        .onClick(() => {
          this.gotoAddRecord();
        })
      }
      .width('100%')
      .padding({ left: 15, right: 15, top: 15 })

      if (this.isLoading) {
        Column() {
          LoadingView()
        }
        .width('100%')
        .layoutWeight(1)
      } else if (this.records.length === 0) {
        Column() {
          EmptyView({ tipText: '暂无检查记录' })
        }
        .width('100%')
        .layoutWeight(1)
      } else {
        List({ space: 15 }) {
          ForEach(this.records, (record: OaInspectionRecord) => {
            ListItem() {
              Column() {
                Text(record.JCJLMC)
                  .fontSize(14)
                  .fontColor($r('app.color.black'))
                  .width('100%')
                  .textAlign(TextAlign.Start)
              }
              .width('100%')
              .height(62)
              .padding({ left: 12, right: 15 })
              .borderRadius(4)
              .backgroundColor($r('app.color.white'))
              .alignItems(HorizontalAlign.Center)
              .justifyContent(FlexAlign.Center)
              .onClick(() => {
                this.gotoRecord(record);
              })
            }
          }, (record: OaInspectionRecord) => record.XLH)
        }
        .width('100%')
        .padding(15)
        .layoutWeight(1)
        .scrollBar(BarState.Off)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F2F2F2')
  }
}
