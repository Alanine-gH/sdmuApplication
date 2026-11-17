import { TitleBar } from '../components/TitleBar';

/**
 * 常用应用设置页 — 1:1 复刻 settings_page_function_item.xml + settings_page_separator_item.xml
 * 结构：分组列表(common_color_6 背景，组间 separator px_to_dip_30=15vp)
 *   function_item：白底 paddingLeft 15vp + 行(上下 padding 15vp, 右 padding 15vp)
 *     名称 TextSize2.Color2 16fp #555555 + 附加信息 TextSize2.Color1 16fp #333333 + 箭头 marginL 15vp
 *     + thin 分隔线
 */
interface FunctionItem {
  key: string;
  name: string;
  extraInfo: string;
}

interface FunctionGroup {
  key: string;
  items: FunctionItem[];
}

@Entry
@Component
struct AppsSettingPage {
  @State groups: FunctionGroup[] = [
    {
      key: 'group_1',
      items: [
        { key: 'push', name: '推送设置', extraInfo: '已开启' },
        { key: 'clear_cache', name: '清除缓存', extraInfo: '12.6M' }
      ]
    },
    {
      key: 'group_2',
      items: [
        { key: 'font', name: '字体大小', extraInfo: '标准' },
        { key: 'update', name: '检查更新', extraInfo: 'V5.2.1' },
        { key: 'about', name: '关于我们', extraInfo: '' }
      ]
    }
  ];

  private onItemTap(item: FunctionItem): void {
    this.getUIContext().getPromptAction().showToast({ message: item.name });
  }

  @Builder
  functionRow(item: FunctionItem) {
    Column() {
      Row() {
        Text(item.name)
          .fontSize(16)
          .fontColor($r('app.color.common_color_2'))
          .layoutWeight(1)
        Text(item.extraInfo)
          .fontSize(16)
          .fontColor($r('app.color.common_color_1'))
        Image($r('app.media.arrow_right'))
          .width(16)
          .height(16)
          .margin({ left: 15 })
      }
      .width('100%')
      .padding({ top: 15, right: 15, bottom: 15 })
      .alignItems(VerticalAlign.Center)
      .onClick(() => {
        this.onItemTap(item);
      })

      Divider()
        .color($r('app.color.divider_grey'))
        .strokeWidth(0.5)
        .width('100%')
    }
    .width('100%')
    .backgroundColor($r('app.color.white'))
  }

  build() {
    Column() {
      TitleBar({ title: '常用应用设置', showBack: true })

      Scroll() {
        Column() {
          ForEach(this.groups, (group: FunctionGroup, gIndex: number) => {
            ForEach(group.items, (item: FunctionItem) => {
              this.functionRow(item)
            }, (item: FunctionItem): string => item.key)

            if (gIndex < this.groups.length - 1) {
              // separator_item：px_to_dip_30 = 15vp
              Row()
                .width('100%')
                .height(15)
            }
          }, (group: FunctionGroup): string => group.key)
        }
      }
      .scrollBar(BarState.Off)
      .width('100%')
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.common_color_6'))
  }
}
