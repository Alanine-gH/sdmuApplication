import { router } from '@kit.ArkUI';

/**
 * 添加常用应用搜索页 — 1:1 复刻 mobile_campus_activity_edit_common_app_search.xml
 *   + item_child_edit_common_app_search.xml + layout_edit_common_app_search_empty.xml
 * 结构：搜索栏(高44vp 白底：搜索框圆角8 #F2F2F2 hint"请输入应用名称搜索..." + 取消)
 *   + 历史搜索区(paddingT 16vp：标题14fp #555 + 删除图标) + FlowLayout 标签
 *   + 搜索结果列表：卡片 #F8F8F8 圆角8 margin 8/6 padding 12
 *     图标40vp + 标题16fp 黑 + 状态16fp #999 + 角标18vp(减#CECECE/加#57C06B)
 */
interface SearchAppItem {
  key: string;
  name: string;
  icon: Resource;
  added: boolean;
}

@Entry
@Component
struct EditCommonAppSearchPage {
  @State keyword: string = '';
  @State histories: string[] = ['一网通办', '图书馆', '成绩查询', '课表'];
  @State apps: SearchAppItem[] = [
    { key: 's1', name: '一网通办', icon: $r('app.media.app_icon'), added: true },
    { key: 's2', name: '教务系统', icon: $r('app.media.report'), added: true },
    { key: 's3', name: '成绩查询', icon: $r('app.media.report_blue'), added: false },
    { key: 's4', name: '图书馆', icon: $r('app.media.application'), added: false },
    { key: 's5', name: '一卡通充值', icon: $r('app.media.app_icon'), added: false }
  ];

  private cancel(): void {
    router.back();
  }

  private clearHistory(): void {
    this.histories = [];
  }

  private toggleApp(appKey: string): void {
    for (let i = 0; i < this.apps.length; i++) {
      if (this.apps[i].key === appKey) {
        this.apps[i].added = !this.apps[i].added;
      }
    }
  }

  private isMatched(app: SearchAppItem): boolean {
    return this.keyword.length > 0 && app.name.indexOf(this.keyword) >= 0;
  }

  @Builder
  statusBadge(added: boolean) {
    Stack() {
      Circle()
        .width(16)
        .height(16)
        .fill(added ? $r('app.color.color_cecece') : $r('app.color.report_rate_green'))
      Column()
        .width(10)
        .height(2)
        .borderRadius(1)
        .backgroundColor($r('app.color.white'))
      if (!added) {
        Column()
          .width(2)
          .height(10)
          .borderRadius(1)
          .backgroundColor($r('app.color.white'))
      }
    }
    .width(18)
    .height(18)
    .alignContent(Alignment.Center)
  }

  build() {
    Column() {
      // 搜索栏
      Row() {
        Row() {
          Image($r('app.media.icon_search_gray'))
            .width(16)
            .height(16)
            .margin({ left: 10, right: 8 })
          TextInput({ text: this.keyword, placeholder: '请输入应用名称搜索...' })
            .layoutWeight(1)
            .height(32)
            .backgroundColor(Color.Transparent)
            .padding({ right: 40 })
            .fontSize(14)
            .fontColor($r('app.color.title_color'))
            .placeholderColor($r('app.color.explain_color'))
            .onChange((value: string) => {
              this.keyword = value;
            })
        }
        .layoutWeight(1)
        .height(32)
        .borderRadius(8)
        .backgroundColor($r('app.color.sdmu_bg'))
        .alignItems(VerticalAlign.Center)
        .margin({ left: 16 })

        Text('取消')
          .fontSize(14)
          .fontColor($r('app.color.mobile_campus_primary_color'))
          .padding({ left: 16, right: 20 })
          .height('100%')
          .onClick(() => {
            this.cancel();
          })
      }
      .width('100%')
      .height(44)
      .alignItems(VerticalAlign.Center)
      .backgroundColor($r('app.color.white'))

      if (this.keyword.length === 0) {
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
                })
            }, (word: string, index: number): string => index.toString() + word)
          }
          .width('100%')
          .margin({ left: 16, right: 16, top: 8, bottom: 8 })
        }
        .width('100%')
        .padding({ top: 16 })
        .backgroundColor($r('app.color.white'))
      } else {
        // 搜索结果列表
        Scroll() {
          Column() {
            ForEach(this.apps, (app: SearchAppItem) => {
              if (this.isMatched(app)) {
                Row() {
                  Image(app.icon)
                    .width(40)
                    .height(40)
                    .objectFit(ImageFit.Cover)
                  Text(app.name)
                    .fontSize(16)
                    .fontColor($r('app.color.title_color'))
                    .padding({ left: 12, right: 12 })
                    .maxLines(2)
                    .layoutWeight(1)
                  Text(app.added ? '已添加' : '未添加')
                    .fontSize(16)
                    .fontColor($r('app.color.explain_color'))
                    .padding({ right: 8 })
                  this.statusBadge(app.added)
                }
                .width('100%')
                .padding(12)
                .margin({ left: 8, top: 6, right: 8, bottom: 6 })
                .borderRadius(8)
                .backgroundColor($r('app.color.edit_common_app_bg'))
                .alignItems(VerticalAlign.Center)
                .onClick(() => {
                  this.toggleApp(app.key);
                })
              }
            }, (app: SearchAppItem): string => app.key)
          }
        }
        .scrollBar(BarState.Off)
        .width('100%')
        .layoutWeight(1)
        .backgroundColor($r('app.color.white'))
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.white'))
  }
}
