import { router } from '@kit.ArkUI';
import { ApiService } from '../network/ApiService';
import { WorkApplyEntry } from '../model/OaTodoModel';
import { BusinessError } from '@kit.BasicServicesKit';
import { EmptyView } from '../components/EmptyView';

/**
 * 业务申请更多页 — 1:1 翻译原 APK WorkApplyMoreActivity.java(107行)：
 *
 * 【布局】mobile_campus_oa_activity_workapply_more.xml：toolbar_normal("更多") +
 *   MultiStateView[AutoGridView apply_grid（白底 padL10 padT12.5 padR10 padB12、4 列、
 *   水平间距 16、垂直间距 10）]。条目 = mobile_campus_oa_item_workapply_header.xml
 *   （WorkApplyMoreAdapter：ImageView 不另设图 → XML 默认 mobile_campus_oa_workapply、
 *   名称 12fp）。
 *
 * 【数据流源码还原】
 *   1. y(Intent)：m = intent.getSerializableExtra("list")（WorkApply[]）。
 *   2. f1：setData(m)；count==0 → MultiStateView 空态，否则内容态。
 *   3. 条目点击 a → h2(a.Q=WorkApplyFormConfigActivity){processid,title} 5347；
 *      onActivityResult 5347 RESULT_OK → setResult(-1)+finish（透传刷新主列表）。
 *   【调用方考证】全源码 grep WorkApplyMoreActivity 仅自身命中——APK 中为无入口孤儿页
 *   （历史版本入口已移除）。HAP 保真翻译：入参 AppStorage 'workapply_more_list'，
 *   出参走 onPageShow 透传返回（管道就绪，入口由后续 worker 按需接线）。
 */
@Entry
@Component
struct WorkApplyMorePage {
  @State items: WorkApplyEntry[] = [];
  /** 源码 5347 RESULT_OK → setResult(-1)+finish 标记 */
  private picked: boolean = false;

  aboutToAppear(): void {
    const raw: string | undefined = AppStorage.get<string>('workapply_more_list');
    if (raw !== undefined && raw !== '') {
      try {
        this.items = JSON.parse(raw) as WorkApplyEntry[];
      } catch (error) {
        const err = error as BusinessError;
        ApiService.logError('WorkApplyMore parse list fail: ' + err.message);
      }
    }
  }

  /** 源码 onActivityResult(5347)：返回 OK → setResult(-1)+finish */
  onPageShow(): void {
    if (this.picked) {
      router.back();
    }
  }

  /** 源码 a：宫格项 → a.Q{processid,title} */
  private openFormConfig(item: WorkApplyEntry): void {
    this.picked = true;
    router.pushUrl({
      url: 'pages/WorkApplyFormConfigPage',
      params: { 'processid': item.processId, 'title': item.processName } as Record<string, string>
    });
  }

  build() {
    Column() {
      // toolbar_normal（T1：gVar.n("更多")）
      Row() {
        Text('＜')
          .fontSize(17)
          .fontColor($r('app.color.common_color_1'))
          .width(40)
          .height('100%')
          .textAlign(TextAlign.Center)
          .margin({ left: 15 })
          .onClick(() => {
            router.back();
          })
        Text('更多')
          .fontSize(17)
          .fontColor($r('app.color.common_color_1'))
          .layoutWeight(1)
          .textAlign(TextAlign.Center)
          .maxLines(1)
        Blank().width(40)
      }
      .width('100%')
      .height(44)
      .alignItems(VerticalAlign.Center)
      .backgroundColor($r('app.color.main_bg'))
      .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP])
      Divider().color($r('app.color.common_color_5')).strokeWidth(0.5).width('100%')

      if (this.items.length === 0) {
        // MultiStateView 空态
        Column() {
          EmptyView({ tipText: '暂无更多申请流程' })
        }
        .width('100%')
        .layoutWeight(1)
      } else {
        Grid() {
          ForEach(this.items, (item: WorkApplyEntry, idx: number) => {
            GridItem() {
              Column() {
                Image($r('app.media.mobile_campus_oa_workapply'))
                  .width(59)
                  .height(59)
                  .objectFit(ImageFit.Contain)
                  .margin({ top: 13 })
                Text(item.processName)
                  .fontSize(12)
                  .fontColor($r('app.color.common_color_1'))
                  .textAlign(TextAlign.Center)
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
                  .padding({ left: 3, right: 3 })
                  .margin({ top: 4, bottom: 12 })
              }
              .alignItems(HorizontalAlign.Center)
              .width('100%')
              .onClick(() => {
                this.openFormConfig(item);
              })
            }
          }, (item: WorkApplyEntry, idx: number) => idx.toString() + item.processId)
        }
        .columnsTemplate('1fr 1fr 1fr 1fr')
        .columnsGap(16)
        .rowsGap(10)
        .width('100%')
        .layoutWeight(1)
        .padding({ left: 10, top: 12.5, right: 10, bottom: 12 })
        .backgroundColor($r('app.color.ybg_white'))
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.ybg_white'))
  }
}
