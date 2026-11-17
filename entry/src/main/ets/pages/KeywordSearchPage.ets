import { router } from '@kit.ArkUI';
import { TitleBar } from '../components/TitleBar';

/**
 * 关键词搜索页 — 1:1 复刻 mobile_campus_activity_keyword_search.xml：
 * 白底 + toolbar_normal + 搜索行(padV6)：输入框区 weight1(#F2F2F2 r3 marginL15 pad 7/12/7/45，
 * 左侧搜索图标 drawablePadding 4.25 + 清除按钮 40×27 pad5) + "搜索" 14fp primary padH15
 * 历史搜索区 padT16："历史搜索" 14fp #555 pad 16/8 + 删除图标 + FlowLayout 流式标签(16fp #333，
 * 超7字截断，pad 16/7，margin 0/8/16/8，bg #F2F2F2 r8，按压 #E2E2E2)
 */
interface SearchHistoryChip {
  id: string;
  label: string;
}

@Entry
@Component
struct KeywordSearchPage {
  @State searchText: string = '';
  @State historyList: SearchHistoryChip[] = [
    { id: 'h1', label: '成绩查询' },
    { id: 'h2', label: '课表' },
    { id: 'h3', label: '校园卡' },
    { id: 'h4', label: '图书馆' },
    { id: 'h5', label: '会议通知' },
    { id: 'h6', label: '奖学金评定申请' }
  ];

  private chipLabel(label: string): string {
    if (label.length <= 7) {
      return label;
    }
    return label.substring(0, 7) + '...';
  }

  build() {
    Column() {
      TitleBar({ title: '搜索', showBack: true })

      Row() {
        Row() {
          Image(this.searchText.length > 0 ? $r('app.media.icon_search_black') : $r('app.media.icon_search_gray'))
            .width(14)
            .height(14)
            .objectFit(ImageFit.Contain)

          TextInput({ text: this.searchText, placeholder: '输入标题进行搜索...' })
            .fontSize(13)
            .fontColor('#333333')
            .placeholderColor('#B8B0B0')
            .backgroundColor(Color.Transparent)
            .padding({ left: 4, right: 45, top: 7, bottom: 7 })
            .layoutWeight(1)
            .onChange((value: string) => {
              this.searchText = value;
            })
            .onSubmit(() => {
              router.back();
            })

          if (this.searchText.length > 0) {
            Image($r('app.media.icon_search_history_clear'))
              .width(30)
              .height(27)
              .padding(5)
              .objectFit(ImageFit.Contain)
              .onClick(() => {
                this.searchText = '';
              })
          }
        }
        .layoutWeight(1)
        .backgroundColor('#F2F2F2')
        .borderRadius(3)
        .margin({ left: 15 })
        .padding({ left: 12, top: 4, bottom: 4 })
        .alignItems(VerticalAlign.Center)

        Text('搜索')
          .fontSize(14)
          .fontColor($r('app.color.mobile_campus_primary_color'))
          .height(36)
          .padding({ left: 15, right: 15 })
          .textAlign(TextAlign.Center)
          .onClick(() => {
            router.back();
          })
      }
      .width('100%')
      .padding({ top: 6, bottom: 6 })
      .backgroundColor($r('app.color.white'))
      .alignItems(VerticalAlign.Center)

      if (this.historyList.length > 0) {
        Column() {
          Row() {
            Text('历史搜索')
              .fontSize(14)
              .fontColor('#555555')
              .padding({ left: 16, right: 16, top: 8, bottom: 8 })
              .layoutWeight(1)

            Image($r('app.media.icon_delete'))
              .height(24)
              .width(24)
              .margin({ right: 16 })
              .objectFit(ImageFit.Contain)
              .onClick(() => {
                this.historyList = [];
              })
          }
          .width('100%')
          .alignItems(VerticalAlign.Center)

          Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.Start, alignItems: ItemAlign.Center }) {
            ForEach(this.historyList, (item: SearchHistoryChip) => {
              Text(this.chipLabel(item.label))
                .fontSize(16)
                .fontColor('#333333')
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
                .padding({ left: 16, right: 16, top: 7, bottom: 7 })
                .backgroundColor('#F2F2F2')
                .borderRadius(8)
                .margin({ left: 16, top: 8, bottom: 8 })
                .onClick(() => {
                  this.searchText = item.label;
                })
            }, (item: SearchHistoryChip) => item.id)
          }
          .width('100%')
          .padding({ top: 8, bottom: 8 })
        }
        .width('100%')
        .padding({ top: 16 })
        .alignItems(HorizontalAlign.Start)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.white'))
    .alignItems(HorizontalAlign.Start)
  }
}
