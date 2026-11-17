import { router } from '@kit.ArkUI';
import { TitleBar } from '../components/TitleBar';

/**
 * 演示页 — 1:1 复刻源布局 activity_demo.xml
 * 结构：toolbar_normal + MultiStateView(下拉刷新 PullToRefreshLayout + common_single_lv 单列表)
 * 以 List + Refresh 等价还原多状态视图 + 下拉刷新 + 单列数据
 */
interface DemoListItem {
  itemId: number;
  itemTitle: string;
  itemDesc: string;
}

@Entry
@Component
struct DemoPage {
  @State demoList: DemoListItem[] = [];
  @State refreshing: boolean = false;

  aboutToAppear(): void {
    this.loadDemoData();
  }

  private loadDemoData(): void {
    const titles: string[] = ['功能演示一', '功能演示二', '功能演示三', '功能演示四', '功能演示五'];
    const descs: string[] = [
      '多状态视图：加载中 / 空数据 / 错误 / 内容四态切换',
      '下拉刷新：下拉触发数据重新加载',
      '列表加载更多：滚动到底部自动追加数据',
      '列表项点击：跳转对应演示详情',
      '空数据视图：清空数据后展示空态提示'
    ];
    const seeds: number[] = [];
    for (let i = 0; i < titles.length; i++) {
      seeds.push(i);
    }
    this.demoList = seeds.map((i: number): DemoListItem => {
      return { itemId: i + 1, itemTitle: titles[i], itemDesc: descs[i] };
    });
  }

  build() {
    Column() {
      TitleBar({ title: '演示', showBack: true })

      Refresh({ refreshing: $$this.refreshing }) {
        List() {
          ForEach(this.demoList, (item: DemoListItem) => {
            ListItem() {
              Column() {
                Text(item.itemTitle)
                  .fontSize(16)
                  .fontColor($r('app.color.common_color_1'))
                  .width('100%')

                Text(item.itemDesc)
                  .fontSize(13)
                  .fontColor($r('app.color.common_color_3'))
                  .margin({ top: 6 })
                  .width('100%')
              }
              .padding({ left: 16, right: 16, top: 14, bottom: 14 })
              .width('100%')
              .onClick(() => {
                router.pushUrl({
                  url: 'pages/WebViewPage',
                  params: { url: 'https://www.sdmu.edu.cn/', title: '详情' }
                });
              })
            }
          }, (item: DemoListItem) => `demo_${item.itemId}`)

          ListItem() {
            Text('上拉加载更多演示数据')
              .fontSize(13)
              .fontColor($r('app.color.common_color_3'))
              .textAlign(TextAlign.Center)
              .padding({ top: 16, bottom: 20 })
              .width('100%')
          }
        }
        .width('100%')
        .height('100%')
        .divider({
          strokeWidth: 0.5,
          color: $r('app.color.common_color_5'),
          startMargin: 16,
          endMargin: 16
        })
        .scrollBar(BarState.Off)
      }
      .onRefreshing(() => {
        // 模拟下拉刷新
        setTimeout(() => {
          this.loadDemoData();
          this.refreshing = false;
        }, 1000);
      })
      .width('100%')
      .layoutWeight(1)
      .backgroundColor($r('app.color.main_bg'))
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.main_bg'))
  }
}
