import { router } from '@kit.ArkUI';

interface TodoSearchHistory {
  historyId: number;
  keyword: string;
}

interface TodoSearchResult {
  resultId: number;
  title: string;
  sender: string;
  arriveTime: string;
  node: string;
}

/**
 * OA待办搜索页 — 1:1 复刻（px_to_dip_N = N/2 vp, px_to_sp_N = N/2 fp）：
 * mobile_campus_oa_toolbar_todo_search.xml：Toolbar 44vp bg main_bg + 内层白色 RelativeLayout padR12
 *   （ClearableEditText 14fp #333 bg #F2F2F2 描边 #DADBDF 圆角8 高32 hint"输入关键字搜索..." #B5B5B5
 *     左侧 mobile_campus_oa_search_b 图标 drawablePadding 9 + 取消 16fp #1B68B7 mL8）+ thin 分隔线
 * mobile_campus_oa_activity_todo_search.xml：bg #F2F2F2 + ListView 分隔 #E7E7E7（搜索历史 + 搜索结果条目）
 */
@Entry
@Component
struct TodoSearchPage {
  @State keyword: string = '';
  @State historyList: TodoSearchHistory[] = [
    { historyId: 1, keyword: '报告厅使用申请' },
    { historyId: 2, keyword: '会议通知' },
    { historyId: 3, keyword: '用印审批' },
    { historyId: 4, keyword: '请假申请' }
  ];
  @State resultList: TodoSearchResult[] = [
    {
      resultId: 1,
      title: '关于举办2026年秋季运动会的请示',
      sender: '体育教学部',
      arriveTime: '2026-11-17 09:24',
      node: '办公室主任审批'
    },
    {
      resultId: 2,
      title: '多功能报告厅使用申请',
      sender: '团委办公室',
      arriveTime: '2026-11-16 15:41',
      node: '分管领导审批'
    },
    {
      resultId: 3,
      title: '关于申请购置办公设备的报告',
      sender: '资产管理处',
      arriveTime: '2026-11-15 10:05',
      node: '处长审批'
    }
  ];

  private doSearch(): void {
    if (this.keyword === '') {
      return;
    }
    const exists: boolean = this.historyList.some((item: TodoSearchHistory): boolean => item.keyword === this.keyword);
    if (!exists) {
      const newHistory: TodoSearchHistory = { historyId: Date.now(), keyword: this.keyword };
      const updated: TodoSearchHistory[] = [newHistory];
      this.historyList = updated.concat(this.historyList);
    }
  }

  build() {
    Column() {
      Column() {
        Row() {
          Row() {
            Image($r('app.media.mobile_campus_oa_search_b'))
              .width(16)
              .height(16)
              .margin({ left: 8 })
            TextInput({ text: this.keyword, placeholder: '输入关键字搜索...' })
              .fontSize(14)
              .fontColor($r('app.color.common_color_1'))
              .placeholderColor('#B5B5B5')
              .placeholderFont({ size: 14 })
              .backgroundColor(Color.Transparent)
              .border({ width: 0.5, color: Color.Transparent })
              .padding({ left: 9, right: 8 })
              .layoutWeight(1)
              .height(30)
              .onChange((value: string) => {
                this.keyword = value;
              })
              .onSubmit(() => {
                this.doSearch();
              })
          }
          .width(250)
          .height(32)
          .backgroundColor('#F2F2F2')
          .borderRadius(8)
          .border({ width: 0.5, color: '#DADBDF' })
          .alignItems(VerticalAlign.Center)

          Text('取消')
            .fontSize(16)
            .fontColor($r('app.color.mobile_campus_primary_color_default'))
            .margin({ left: 8 })
            .onClick(() => {
              router.back();
            })
        }
        .width('100%')
        .height(44)
        .padding({ right: 12 })
        .backgroundColor($r('app.color.white'))
        .alignItems(VerticalAlign.Center)

        Divider()
          .color($r('app.color.common_color_5'))
          .strokeWidth(0.5)
          .width('100%')
      }
      .width('100%')
      .backgroundColor($r('app.color.main_bg'))

      Column() {
        Scroll() {
          Column() {
            Text('搜索历史')
              .fontSize(15)
              .fontColor($r('app.color.common_color_3'))
              .width('100%')
              .padding({ left: 12, top: 12, bottom: 4 })

            ForEach(this.historyList, (item: TodoSearchHistory) => {
              Text(item.keyword)
                .fontSize(16)
                .fontColor($r('app.color.common_color_1'))
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
                .width('100%')
                .height(44)
                .padding({ left: 12, right: 12 })
                .backgroundColor($r('app.color.white'))
                .onClick(() => {
                  this.keyword = item.keyword;
                })
            }, (item: TodoSearchHistory) => item.historyId.toString())

            Text('搜索结果')
              .fontSize(15)
              .fontColor($r('app.color.common_color_3'))
              .width('100%')
              .padding({ left: 12, top: 12, bottom: 4 })

            ForEach(this.resultList, (item: TodoSearchResult) => {
              Column() {
                Text(item.title)
                  .fontSize(16)
                  .fontColor($r('app.color.common_color_1'))
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
                  .width('100%')

                Row() {
                  Text('发起人：' + item.sender)
                    .fontSize(13)
                    .fontColor($r('app.color.common_color_3'))
                  Blank()
                  Text(item.arriveTime)
                    .fontSize(13)
                    .fontColor($r('app.color.common_color_3'))
                }
                .width('100%')
                .margin({ top: 6 })

                Text('当前节点：' + item.node)
                  .fontSize(13)
                  .fontColor($r('app.color.common_color_3'))
                  .width('100%')
                  .margin({ top: 4 })

                Divider()
                  .color($r('app.color.common_color_5'))
                  .strokeWidth(0.5)
                  .width('100%')
                  .margin({ top: 12 })
              }
              .width('100%')
              .padding({ left: 12, right: 12, top: 12 })
              .backgroundColor($r('app.color.white'))
            }, (item: TodoSearchResult) => item.resultId.toString())
          }
          .width('100%')
          .padding({ bottom: 20 })
        }
        .width('100%')
        .layoutWeight(1)
        .scrollBar(BarState.Off)
      }
      .width('100%')
      .layoutWeight(1)
      .backgroundColor('#F2F2F2')
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F2F2F2')
  }
}
