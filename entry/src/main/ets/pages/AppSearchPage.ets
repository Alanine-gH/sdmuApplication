import { router } from '@kit.ArkUI';

/**
 * 应用关键词搜索页 — 1:1 复刻 mobile_campus_activity_keyword_search.xml
 *   + item_child_app_search.xml
 * 结构：toolbar_normal(空标题) + 搜索行(paddingV 6vp：搜索框圆角3 #F2F2F2
 *   marginL 15 图标 icon_unify_todo_search + 输入13fp + "搜索"14fp 主题色 paddingH 15)
 *   + 历史搜索(标题14fp #555 + icon_delete) + FlowLayout 标签
 *   + 搜索结果(卡片 #F8F8F8 圆角8 margin 8/6 padding 12：
 *     图标区 50x45(图标40vp) + 标题16fp 黑 paddingH 12 + icon_arrow_gray_right)
 */
interface KeywordAppItem {
  key: string;
  name: string;
  icon: Resource;
}

@Entry
@Component
struct AppSearchPage {
  @State keyword: string = '';
  @State searched: boolean = false;
  @State histories: string[] = ['校园资讯', '图书馆', '成绩', '会议室'];
  @State apps: KeywordAppItem[] = [
    { key: 'k1', name: '校园资讯', icon: $r('app.media.app_icon') },
    { key: 'k2', name: '图书馆', icon: $r('app.media.application') },
    { key: 'k3', name: '成绩查询', icon: $r('app.media.report') },
    { key: 'k4', name: '会议室预约', icon: $r('app.media.report_blue') },
    { key: 'k5', name: '一卡通充值', icon: $r('app.media.app_icon') }
  ];

  private isMatched(app: KeywordAppItem): boolean {
    return this.keyword.length > 0 && app.name.indexOf(this.keyword) >= 0;
  }

  private doSearch(): void {
    if (this.keyword.length === 0) {
      this.getUIContext().getPromptAction().showToast({ message: '请输入搜索内容' });
      return;
    }
    this.searched = true;
    let matched = false;
    for (let i = 0; i < this.apps.length; i++) {
      if (this.isMatched(this.apps[i])) {
        matched = true;
      }
    }
    if (!matched) {
      this.getUIContext().getPromptAction().showToast({ message: '未找到相关应用' });
    }
  }

  private clearHistory(): void {
    this.histories = [];
  }

  private goBack(): void {
    router.back();
  }

  build() {
    Column() {
      // toolbar_normal（无标题）
      Row() {
        Text('＜')
          .fontSize(16)
          .fontColor($r('app.color.common_color_1'))
          .width(40)
          .height('100%')
          .textAlign(TextAlign.Center)
          .margin({ left: 15 })
          .onClick(() => {
            this.goBack();
          })
      }
      .width('100%')
      .height(44)
      .alignItems(VerticalAlign.Center)
      .backgroundColor($r('app.color.main_bg'))

      Divider()
        .color($r('app.color.common_color_5'))
        .strokeWidth(0.5)
        .width('100%')

      // 搜索行
      Row() {
        Row() {
          Image($r('app.media.icon_unify_todo_search'))
            .width(15)
            .height(15)
            .margin({ left: 12, right: 8.5 })
          TextInput({ text: this.keyword, placeholder: '搜索' })
            .layoutWeight(1)
            .height(30)
            .backgroundColor(Color.Transparent)
            .fontSize(13)
            .fontColor($r('app.color.common_color_1'))
            .placeholderColor($r('app.color.common_color_3'))
            .onChange((value: string) => {
              this.keyword = value;
            })
        }
        .layoutWeight(1)
        .height(30)
        .borderRadius(3)
        .backgroundColor($r('app.color.sdmu_bg'))
        .alignItems(VerticalAlign.Center)
        .margin({ left: 15 })

        Text('搜索')
          .fontSize(14)
          .fontColor($r('app.color.mobile_campus_primary_color'))
          .padding({ left: 15, right: 15 })
          .height('100%')
          .onClick(() => {
            this.doSearch();
          })
      }
      .width('100%')
      .padding({ top: 6, bottom: 6 })
      .alignItems(VerticalAlign.Center)
      .backgroundColor($r('app.color.white'))

      if (this.searched) {
        // 搜索结果列表
        Scroll() {
          Column() {
            ForEach(this.apps, (app: KeywordAppItem) => {
              if (this.isMatched(app)) {
                Row() {
                  Column() {
                    Image(app.icon)
                      .width(40)
                      .height(40)
                      .objectFit(ImageFit.Cover)
                      .alignSelf(ItemAlign.Start)
                  }
                  .width(50)
                  .height(45)
                  .justifyContent(FlexAlign.End)

                  Text(app.name)
                    .fontSize(16)
                    .fontColor($r('app.color.title_color'))
                    .padding({ left: 12, right: 12 })
                    .maxLines(2)
                    .layoutWeight(1)

                  Image($r('app.media.icon_arrow_gray_right'))
                    .width(16)
                    .height(16)
                }
                .width('100%')
                .padding(12)
                .margin({ left: 8, top: 6, right: 8, bottom: 6 })
                .borderRadius(8)
                .backgroundColor($r('app.color.edit_common_app_bg'))
                .alignItems(VerticalAlign.Center)
              }
            }, (app: KeywordAppItem): string => app.key)
          }
        }
        .scrollBar(BarState.Off)
        .width('100%')
        .layoutWeight(1)
        .backgroundColor($r('app.color.white'))
      } else {
        // 历史搜索
        Column() {
          Row() {
            Text('历史搜索')
              .fontSize(14)
              .fontColor('#555555')
              .padding({ left: 16, top: 8, right: 16, bottom: 8 })
              .layoutWeight(1)
            Image($r('app.media.icon_delete'))
              .width(18)
              .height(18)
              .padding({ left: 16, right: 16 })
              .onClick(() => {
                this.clearHistory();
              })
          }
          .width('100%')
          .alignItems(VerticalAlign.Center)

          Flex({ wrap: FlexWrap.Wrap }) {
            ForEach(this.histories, (word: string, index: number) => {
              Text(word)
                .fontSize(13)
                .fontColor($r('app.color.common_color_1'))
                .padding({ left: 10, right: 10, top: 6, bottom: 6 })
                .borderRadius(4)
                .backgroundColor($r('app.color.sdmu_bg'))
                .margin({ left: 8, right: 8, top: 8, bottom: 8 })
                .onClick(() => {
                  this.keyword = word;
                  this.searched = true;
                })
            }, (word: string, index: number): string => index.toString() + word)
          }
          .width('100%')
          .margin({ left: 16, right: 16, top: 8, bottom: 8 })
        }
        .width('100%')
        .padding({ top: 16 })
        .backgroundColor($r('app.color.white'))
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.white'))
  }
}
