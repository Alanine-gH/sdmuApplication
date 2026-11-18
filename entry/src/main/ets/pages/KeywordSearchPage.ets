import { router } from '@kit.ArkUI';
import { PreferencesUtil } from '../data/PreferencesUtil';

/**
 * 关键词搜索页 — 源码级复刻 KeywordSearchActivity（main 包，ARouter /app/KeywordSearchActivity，
 * UnifyNotificationActivity2.b3(title,keyword,from:"UnifyNotification") 进入）。
 * 源码：mobile_campus_activity_keyword_search 布局 = toolbar_normal(title=路由参) + 搜索行
 * （BL 输入框 13sp 圆角 3 #f2f2f2 marginL15 pad(12,7,45,7) drawableLeft icon_unify_todo_search
 * padding 8.5 + ivClear 40×27 + tvSearch"搜索" 14sp primary padH15）+ 历史区（同款 chips FlowLayout）；
 * f1()：from=="UnifyNotification" → hint"输入标题进行搜索..."；预填 keyword 光标末位；
 * O2()（IME actionSearch / tvSearch 点击）：g0.f 隐键盘 → 非空 P2 保存历史（from 键，去重插头
 * 10 条上限）→ EventBus 64 携 keyword → finish()；onBackPressed 同样发 64（带当前输入）；
 * K2()：x.f(from,"[]") 清空历史；历史 chips ≤7 字截断+"..."。
 * EventBus 64 消费方 = UnifyNotificationActivity2（HAP 统一资讯页未翻译）→ HAP 等价管道
 * AppStorage 'keyword_search_result'（回填+触发重查的宿主侧消费约定）。
 */
const HISTORY_MAX: number = 10;

@Entry
@Component
struct KeywordSearchPage {
  @State searchText: string = '';
  @State historyList: string[] = [];
  /** y(Intent)：title/keyword/from */
  private pageTitle: string = '搜索';
  private fromKey: string = '';
  private hint: string = '';

  aboutToAppear(): void {
    const params: object | undefined = router.getParams() as object | undefined;
    if (params !== null && params !== undefined) {
      const record = params as Record<string, Object>;
      const t: Object = record['title'];
      if (typeof t === 'string') {
        this.pageTitle = t as string;
      }
      const kw: Object = record['keyword'];
      if (typeof kw === 'string') {
        this.searchText = kw as string;
      }
      const from: Object = record['from'];
      if (typeof from === 'string') {
        this.fromKey = from as string;
      }
    }
    if (this.fromKey === 'UnifyNotification') {
      // f1()：UnifyNotification 覆盖 hint
      this.hint = '输入标题进行搜索...';
    }
    this.loadHistory();
  }

  /** L2()：x.e(from,"[]") gson 解析 */
  private async loadHistory(): Promise<void> {
    if (this.fromKey === '') {
      this.historyList = [];
      return;
    }
    const raw: string = await PreferencesUtil.getString(this.fromKey, '[]');
    try {
      this.historyList = JSON.parse(raw) as string[];
    } catch (error) {
      this.historyList = [];
    }
  }

  /** P2(str)：M2 命中先移除 → add(0) → 超 10 条截断 → x.f 持久化 */
  private async saveHistory(keyword: string): Promise<void> {
    if (this.fromKey === '') {
      return;
    }
    const list: string[] = this.historyList.slice();
    const idx: number = list.indexOf(keyword);
    if (idx >= 0) {
      list.splice(idx, 1);
    }
    list.unshift(keyword);
    const trimmed: string[] = list.length > HISTORY_MAX ? list.slice(0, HISTORY_MAX) : list;
    this.historyList = trimmed;
    await PreferencesUtil.putString(this.fromKey, JSON.stringify(trimmed));
  }

  /** O2()：隐键盘 → 非空存历史 → EventBus 64(strTrim) 等价 AppStorage 管道 → finish */
  private submitSearch(): void {
    const keyword: string = this.searchText.trim();
    if (keyword !== '') {
      this.saveHistory(keyword);
    }
    // f.a(64, strTrim)：宿主（UnifyNotificationActivity2.c2 code==64）回填+重查
    AppStorage.setOrCreate('keyword_search_result', keyword);
    router.back();
  }

  /** K2()：x.f(from,"[]") + N2() */
  private async clearHistory(): Promise<void> {
    if (this.fromKey !== '') {
      await PreferencesUtil.putString(this.fromKey, '[]');
    }
    this.historyList = [];
  }

  /** J2(str)：chip ≤7 字截断+"..." */
  private chipText(raw: string): string {
    return raw.length <= 7 ? raw : raw.substring(0, 7) + '...';
  }

  @Builder
  historyChip(keyword: string) {
    Text(this.chipText(keyword))
      .fontSize(16)
      .fontColor('#333333')
      .maxLines(1)
      .textOverflow({ overflow: TextOverflow.Ellipsis })
      .padding({ left: 16, right: 16, top: 7, bottom: 7 })
      .borderRadius(8)
      .backgroundColor('#f2f2f2')
      .margin({ left: 0, right: 16, top: 8, bottom: 8 })
      .onClick(() => {
        // c(str)：回填 + 光标末位 + O2()
        this.searchText = keyword;
        this.submitSearch();
      })
  }

  build() {
    Column() {
      // toolbar_normal：title=路由参 + 返回（nav_back_btn paddingL23 R15 顶2）
      Row() {
        Image($r('app.media.nav_back_btn'))
          .width(20)
          .height(20)
          .objectFit(ImageFit.Contain)
          .padding({ left: 11.5, right: 7.5, top: 1 })
          .onClick(() => {
            // e()：onBackPressed → 同发 64
            this.submitSearch();
          })
        Text(this.pageTitle)
          .fontSize(17)
          .fontColor($r('app.color.common_color_1'))
          .layoutWeight(1)
          .textAlign(TextAlign.Center)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        Blank()
          .width(35)
      }
      .width('100%')
      .height(44)
      .alignItems(VerticalAlign.Center)
      .backgroundColor($r('app.color.main_bg'))
      .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP])

      // 搜索行：BL 输入框（13sp 圆角3 #f2f2f2 marginL15 pad(12,7,45,7)）+ ivClear + tvSearch
      Row() {
        Stack({ alignContent: Alignment.End }) {
          Row() {
            Image($r('app.media.icon_unify_todo_search'))
              .width(16)
              .height(16)
              .objectFit(ImageFit.Contain)
              .margin({ left: 12 })

            TextInput({ text: this.searchText, placeholder: this.hint })
              .fontSize(13)
              .fontColor($r('app.color.common_color_1'))
              .placeholderColor($r('app.color.explain_color'))
              .placeholderFont({ size: 13 })
              .backgroundColor(Color.Transparent)
              .border({ width: 0 })
              .padding({ left: 8.5, right: 22 })
              .layoutWeight(1)
              .height(28)
              .enterKeyType(EnterKeyType.Search)
              .onChange((value: string) => {
                this.searchText = value;
              })
              .onSubmit((enterKey: EnterKeyType) => {
                if (enterKey === EnterKeyType.Search) {
                  this.submitSearch();
                }
              })
          }
          .width('100%')
          .height(28)
          .borderRadius(3)
          .backgroundColor('#f2f2f2')
          .margin({ left: 15 })
          .alignItems(VerticalAlign.Center)

          if (this.searchText !== '') {
            Image($r('app.media.icon_search_history_clear'))
              .width(20)
              .height(13.5)
              .objectFit(ImageFit.None)
              .onClick(() => {
                // g()：清空输入
                this.searchText = '';
              })
          }
        }
        .layoutWeight(1)

        Text('搜索')
          .fontSize(14)
          .fontColor($r('app.color.sdmu_primary'))
          .padding({ left: 15, right: 15 })
          .height('100%')
          .onClick(() => {
            // f()：O2()
            this.submitSearch();
          })
      }
      .width('100%')
      .padding({ top: 3, bottom: 3 })
      .alignItems(VerticalAlign.Center)
      .backgroundColor($r('app.color.white'))

      // 历史区（N2：空历史 q.setVisibility(8)）
      if (this.historyList.length > 0) {
        Column() {
          Row() {
            Text('历史搜索')
              .fontSize(14)
              .fontColor('#555555')
              .padding({ left: 16, right: 16, top: 8, bottom: 8 })
              .layoutWeight(1)
            Image($r('app.media.icon_delete'))
              .width(20)
              .height(20)
              .objectFit(ImageFit.Contain)
              .padding({ left: 16, right: 16 })
              .onClick(() => {
                // h()：确认弹窗 → K2()
                this.getUIContext().showAlertDialog({
                  title: '',
                  message: '确认删除全部历史记录？',
                  primaryButton: {
                    value: '取消',
                    action: () => {
                    }
                  },
                  secondaryButton: {
                    value: '确认',
                    action: () => {
                      this.clearHistory();
                    }
                  }
                });
              })
          }
          .width('100%')
          .alignItems(VerticalAlign.Center)

          Flex({
            direction: FlexDirection.Row,
            wrap: FlexWrap.Wrap,
            justifyContent: FlexAlign.Start,
            alignItems: ItemAlign.Center
          }) {
            ForEach(this.historyList, (keyword: string) => {
              this.historyChip(keyword)
            }, (keyword: string) => 'chip_' + keyword)
          }
          .width('100%')
          .padding({ left: 16, right: 16, top: 8, bottom: 8 })
        }
        .width('100%')
        .padding({ top: 16 })
        .backgroundColor($r('app.color.white'))
      } else {
        Column()
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
