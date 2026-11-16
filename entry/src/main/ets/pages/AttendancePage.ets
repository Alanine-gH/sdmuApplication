import { ApiService } from '../network/ApiService';
import { AttendanceItem } from '../model/AttendanceModel';
import { TitleBar } from '../components/TitleBar';
import { EmptyView } from '../components/EmptyView';
import { LoadingView } from '../components/LoadingView';

/**
 * 考勤记录页：类型Tag（正常绿/迟到橙/缺勤红）。
 */
@Entry
@Component
struct AttendancePage {
  @State records: AttendanceItem[] = [];
  @State isLoading: boolean = true;

  aboutToAppear(): void {
    ApiService.getAttendanceList()
      .then((response) => {
        this.records = response.data;
        this.isLoading = false;
      })
      .catch(() => {
        this.records = [];
        this.isLoading = false;
      });
  }

  private statusColor(status: string): Resource {
    if (status === '正常') {
      return $r('app.color.sdmu_success');
    }
    if (status === '迟到') {
      return $r('app.color.sdmu_warning');
    }
    return $r('app.color.sdmu_danger');
  }

  build() {
    Column() {
      TitleBar({ title: '考勤记录', showBack: true })
      if (this.isLoading) {
        LoadingView()
      } else {
        if (this.records.length === 0) {
          EmptyView()
        } else {
          List() {
            ForEach(this.records, (item: AttendanceItem) => {
              ListItem() {
                Row({ space: 12 }) {
                  Column({ space: 6 }) {
                    Text(item.courseName)
                      .fontSize(16)
                      .fontWeight(FontWeight.Medium)
                      .fontColor($r('app.color.sdmu_text_primary'))
                    Text(item.time + ' · ' + item.type + ' · ' + item.location)
                      .fontSize(12)
                      .fontColor($r('app.color.sdmu_text_hint'))
                      .maxLines(1)
                      .textOverflow({ overflow: TextOverflow.Ellipsis })
                  }
                  .alignItems(HorizontalAlign.Start)
                  .layoutWeight(1)
                  Text(item.status)
                    .fontSize(12)
                    .fontColor(this.statusColor(item.status))
                    .padding({ left: 10, right: 10, top: 4, bottom: 4 })
                    .borderRadius(10)
                    .backgroundColor($r('app.color.sdmu_bg'))
                }
                .width('100%')
                .padding(14)
                .borderRadius(10)
                .backgroundColor($r('app.color.sdmu_card_bg'))
                .margin({ left: 12, right: 12, top: 10 })
              }
            }, (item: AttendanceItem) => item.id)
          }
          .width('100%')
          .layoutWeight(1)
          .backgroundColor($r('app.color.sdmu_bg'))
          .scrollBar(BarState.Off)
        }
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.sdmu_bg'))
  }
}
