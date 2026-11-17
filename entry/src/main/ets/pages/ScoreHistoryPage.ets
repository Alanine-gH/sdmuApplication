// 数据源：无服务器接口，页面数据为内置示例数据（离线演示用），未接 ApiService。
import { TitleBar } from '../components/TitleBar';

/**
 * 成绩历史（搜索记录）页 — 1:1 复刻 mobile_campus_score_toolbar_search.xml +
 * mobile_campus_score_history_record.xml + item_history_record.xml + history_record_footer.xml
 *
 * toolbar_search.xml：Toolbar main_bg 44dip 高，内部 RelativeLayout 白底 paddingH px_to_dip_24=12vp：
 *   ClearableEditText（shape_contact_sesarch_bg、高 32dip、marginRight 4dip、
 *   drawableLeft=search_b 间距 9dip、hint"输入姓名、电话号码搜索..."、px_to_sp_28=14fp）+
 *   取消按钮（marginStart px_to_dip_16=8vp）
 *   底部 divider_horizontal_grey_thin
 *
 * history_record.xml：LinearLayout common_color_6 底：
 *   "历史搜索" px_to_sp_28=14fp common_color_3 白底 padding px_to_dip_16=8vp +
 *   divider_thin + ListView 白底（divider=divider_grey 0.8dip）
 *
 * item_history_record.xml：padding L/R px_to_dip_24=12vp T/B px_to_dip_18=9vp：
 *   姓名 14fp common_color_1 + 班级 14fp common_color_3 weight=1 marginL 12vp +
 *   delete_icon（padding px_to_dip_4=2vp）；底部 divider_thin marginL 12vp 高 0.5vp
 *
 * footer.xml："清空搜索记录" px_to_sp_34=17fp common_color_3 居中 padding T/B px_to_dip_32=16vp
 */
class ScoreHistoryRecord {
  name: string;
  className: string;

  constructor(name: string, className: string) {
    this.name = name;
    this.className = className;
  }
}

function buildHistoryRecords(): ScoreHistoryRecord[] {
  const records: ScoreHistoryRecord[] = [];
  records.push(new ScoreHistoryRecord('张晓雨', '汉语言文学2023级1班'));
  records.push(new ScoreHistoryRecord('陈嘉禾', '数学与应用数学2023级1班'));
  records.push(new ScoreHistoryRecord('赵梓豪', '计算机科学与技术2023级3班'));
  records.push(new ScoreHistoryRecord('郑雅琪', '会计学2023级1班'));
  records.push(new ScoreHistoryRecord('许安然', '临床医学2023级5班'));
  return records;
}

@Entry
@Component
struct ScoreHistoryPage {
  @State searchKey: string = '';
  @State records: ScoreHistoryRecord[] = buildHistoryRecords();

  build() {
    Column() {
      // mobile_campus_score_toolbar_search.xml
      Column() {
        Row() {
          // 搜索输入框：白底圆角、高 32dip
          Row() {
            Image($r('app.media.search_b'))
              .width(16)
              .height(16)
              .margin({ right: 9 }) // drawablePadding 9dip
            TextInput({ text: this.searchKey, placeholder: '输入姓名、电话号码搜索...' })
              .fontSize(14) // px_to_sp_28/2=14fp
              .fontColor($r('app.color.common_color_1'))
              .placeholderColor('#B5B5B5')
              .placeholderFont({ size: 14 })
              .backgroundColor(Color.Transparent)
              .padding(0)
              .layoutWeight(1)
              .height(28)
              .onChange((value: string) => {
                this.searchKey = value;
              })
          }
          .layoutWeight(1)
          .height(32) // 32.0dip
          .padding({ left: 8, right: 8 })
          .margin({ right: 4 }) // marginRight 4.0dip
          .borderRadius(16)
          .backgroundColor('#FFFFFF')
          .border({ width: 0.5, color: '#DADBDF' })
          .alignItems(VerticalAlign.Center)
          // 取消按钮
          Text('取消')
            .fontSize(14)
            .fontColor($r('app.color.common_color_1'))
            .height(32)
            .margin({ left: 8 }) // marginStart px_to_dip_16/2=8vp
            .textAlign(TextAlign.Center)
            .onClick(() => {
              this.searchKey = '';
            })
        }
        .width('100%')
        .height(44) // Toolbar 44.0dip
        .padding({ left: 12, right: 12 }) // px_to_dip_24/2=12vp
        .alignItems(VerticalAlign.Center)
        .backgroundColor($r('app.color.main_bg'))
        // divider_horizontal_grey_thin
        Divider()
          .color($r('app.color.common_color_5'))
          .strokeWidth(0.5)
          .width('100%')
      }
      .width('100%')

      // history_record.xml：common_color_6 底
      Column() {
        // "历史搜索" 头
        Text('历史搜索')
          .fontSize(14) // px_to_sp_28/2=14fp
          .fontColor($r('app.color.common_color_3'))
          .width('100%')
          .padding(8) // px_to_dip_16/2=8vp
          .backgroundColor($r('app.color.white'))
        Divider()
          .color($r('app.color.common_color_5'))
          .strokeWidth(0.5)
          .width('100%')

        // history_record_lv：白底列表、divider divider_grey 0.8dip
        List() {
          ForEach(this.records, (record: ScoreHistoryRecord, index: number) => {
            ListItem() {
              Column() {
                Row() {
                  Text(record.name)
                    .fontSize(14) // px_to_sp_28/2=14fp
                    .fontColor($r('app.color.common_color_1'))
                  Text(record.className)
                    .fontSize(14)
                    .fontColor($r('app.color.common_color_3'))
                    .layoutWeight(1)
                    .margin({ left: 12 }) // px_to_dip_24/2=12vp
                    .maxLines(1)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                  Image($r('app.media.delete_icon'))
                    .width(18)
                    .height(18)
                    .padding(2) // px_to_dip_4/2=2vp
                    .onClick(() => {
                      this.removeRecord(index);
                    })
                }
                .width('100%')
                .padding({ left: 12, right: 12, top: 9, bottom: 9 }) // px_to_dip_24/2=12、px_to_dip_18/2=9
                .alignItems(VerticalAlign.Center)
                // 底部 divider_thin marginL 12vp 高 0.5vp
                Divider()
                  .color($r('app.color.common_color_5'))
                  .strokeWidth(0.5)
                  .margin({ left: 12 })
              }
            }
          }, (record: ScoreHistoryRecord, index: number) => index + '_' + record.name)
        }
        .width('100%')
        .backgroundColor($r('app.color.white'))
        .divider({ strokeWidth: 0.8, color: $r('app.color.divider_grey'), startMargin: 0, endMargin: 0 })

        // history_record_footer.xml："清空搜索记录"
        Text('清空搜索记录')
          .fontSize(17) // px_to_sp_34/2=17fp
          .fontColor($r('app.color.common_color_3'))
          .width('100%')
          .textAlign(TextAlign.Center)
          .padding({ top: 16, bottom: 16 }) // px_to_dip_32/2=16vp
          .backgroundColor($r('app.color.white'))
          .onClick(() => {
            this.records = [];
          })
      }
      .width('100%')
      .layoutWeight(1)
      .backgroundColor($r('app.color.common_color_6'))
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.common_color_6'))
  }

  private removeRecord(index: number): void {
    const next: ScoreHistoryRecord[] = [];
    for (let i = 0; i < this.records.length; i++) {
      if (i !== index) {
        next.push(this.records[i]);
      }
    }
    this.records = next;
  }
}
