import { TitleBar } from '../components/TitleBar';
import { ApiService, FeedbackRecordEntry } from '../network/ApiService';
import { EmptyView } from '../components/EmptyView';

/**
 * 反馈记录页 — 1:1 复刻 FeedbackRecordActivity.java + mobile_campus_feedback_activity_record
 * 结构：toolbar_normal（T1 标题"反馈记录"）+ PullToRefreshLayout(ListView common_color_5 底、
 *   paddingTop 8) + MultiStateView 空态。
 * 行为（源码逐行）：
 *   f1()：f2() → o2() loading + M2(userId, lyyd3SchoolId||schoolId)
 *     → n.j(userId, xxdm) → GET records/ciphertext（data 双重加密，响应明文数组）
 *   a.g()：setData；空列表 → MultiStateView 空态；否则列表
 *   a.f()：toast(msg)；a.b()：刷新结束
 *   item 点击 c → FeedbackDetailActivity（详情页本次任务范围外，见报告说明）
 *   item（mobile_campus_feedback_item_record.xml）：横向白底 padding 14(px28/2)
 *     左列：content 17fp common_color_1 单行 ellipsize；下行 marginTop 11(px22/2)：
 *       "申请时间" + time（e.f13232a "yyyy-MM-dd HH:mm"，13fp(px26/2) common_color_3）
 *     右侧：state 17fp common_color_3 + marginL 30(px60/2) + 箭头 icon（drawablePadding 7）
 */
@Entry
@Component
struct FeedbackRecordPage {
  @State records: FeedbackRecordEntry[] = [];
  @State loading: boolean = false;
  @State loaded: boolean = false;
  @State errorMsg: string = '';

  aboutToAppear(): void {
    this.refresh();
  }

  /** 源码 f2()：刷新（下拉/首次）→ 拉取记录 */
  private async refresh(): Promise<void> {
    this.loading = true;
    try {
      const resp = await ApiService.getFeedbackRecords();
      if (resp.code === 0) {
        this.records = resp.data;
      } else {
        // 源码 a.f：toast(msg)
        this.getUIContext().getPromptAction().showToast({ message: resp.message });
      }
    } catch {
      this.getUIContext().getPromptAction().showToast({ message: '网络请求失败' });
    } finally {
      this.loading = false;
      this.loaded = true;
    }
  }

  /** 时间戳 → "yyyy-MM-dd HH:mm"（源码 e.f13232a.format(item.time)） */
  private formatTime(ms: number): string {
    if (ms <= 0) {
      return '';
    }
    const d: Date = new Date(ms);
    const pad = (n: number): string => {
      return n < 10 ? '0' + n : String(n);
    };
    return d.getFullYear() + '-' + pad(d.getMonth() + 1) + '-' + pad(d.getDate()) +
      ' ' + pad(d.getHours()) + ':' + pad(d.getMinutes());
  }

  build() {
    Column() {
      TitleBar({ title: '反馈记录', showBack: true })

      // ListView：common_color_5 背景、paddingTop 8
      Column() {
        if (this.records.length === 0 && this.loaded && !this.loading) {
          // MultiStateView 空态（源码 q2(l)）
          Column() {
            EmptyView()
          }
          .layoutWeight(1)
        } else {
          List() {
            ForEach(this.records, (item: FeedbackRecordEntry) => {
              ListItem() {
                // mobile_campus_feedback_item_record.xml
                Row() {
                  Column() {
                    Text(item.content)
                      .fontSize(17)
                      .fontColor($r('app.color.common_color_1'))
                      .maxLines(1)
                      .textOverflow({ overflow: TextOverflow.Ellipsis })
                      .width('100%')

                    Row() {
                      Text('申请时间')
                        .fontSize(13)
                        .fontColor($r('app.color.common_color_3'))
                      Text(this.formatTime(item.time))
                        .fontSize(13)
                        .fontColor($r('app.color.common_color_3'))
                        .margin({ left: 8 })
                    }
                    .margin({ top: 11 })
                  }
                  .layoutWeight(1)
                  .alignItems(HorizontalAlign.Start)

                  Text(ApiService.feedbackStateText(item.status))
                    .fontSize(17)
                    .fontColor($r('app.color.common_color_3'))
                    .margin({ left: 30 })
                  Image($r('app.media.mobile_campus_feedback__arrow'))
                    .width(14)
                    .height(14)
                    .margin({ left: 7 })
                }
                .width('100%')
                .padding(14)
                .backgroundColor($r('app.color.white'))
                .alignItems(VerticalAlign.Center)
              }
            }, (item: FeedbackRecordEntry) => String(item.id))
          }
          .width('100%')
          .layoutWeight(1)
          .scrollBar(BarState.Off)
          .divider({
            strokeWidth: 0.5,
            color: $r('app.color.common_color_6'),
            startMargin: 0,
            endMargin: 0
          })
        }
      }
      .width('100%')
      .layoutWeight(1)
      .backgroundColor($r('app.color.common_color_5'))
      .padding({ top: 8 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.white'))
  }
}
