import { router } from '@kit.ArkUI';
import { HttpClient } from '../network/HttpClient';
import { ApiResponse } from '../model/ResponseModel';
import { PreferencesUtil } from '../data/PreferencesUtil';
import { Constants } from '../data/Constants';
import { BreakpointSystem } from '../common/BreakpointSystem';

/**
 * 常用应用搜索页 — 源码级复刻 EditCommonAppSearchActivity（newUI 包，
 * EditCommonAppActivity MToolBar 右图标 icon_work_search → e.a.y 进入）。
 * 源码：mobile_campus_activity_edit_common_app_search 布局（与 app_search 同族：
 * BL 搜索框 + 取消 + 历史区（commonAppSearchHistory 键）+ RecyclerView）；
 * 搜索动作发 EventBus 36 → 宿主 EditCommonAppActivity 回 37（其 S2() 数据）
 * 的 HAP 等价 = 自拉同源接口 /api/app/list {zdlx:'3',khdbb,type:'1'}；
 * N2(list)：过滤 YYMC.contains(trim) + setCommonApp("0".equals(TYPE))；
 * CommonAppSearchAdapter：item_child_edit_common_app_search（40×40 图标 + 标题 16sp +
 * tvStatus"移除/添加" 红 color_jian #fd5f65 / 绿 color_jia #80d38d + 圆形减号/加号视图）；
 * 点击 → configApp{yyid,"1"}（YDXYAppModel.T0）成功 → f.a(7, null) + 本行状态翻转。
 */
class CommonSearchAppBean {
  yyid: string = '';
  yymc: string = '';
  lx: string = '';
  url: string = '';
  yytb: string = '';
  /** N2()：setCommonApp("0".equals(TYPE)) — TYPE=="0"（常用应用组）标记 isCommonApp */
  isCommonApp: boolean = false;
}

const HISTORY_KEY: string = 'commonAppSearchHistory';
const HISTORY_MAX: number = 10;

@Entry
@Component
struct EditCommonAppSearchPage {
  @State searchText: string = '';
  @State historyList: string[] = [];
  @State showHistory: boolean = true;
  @State resultList: CommonSearchAppBean[] = [];
  @State searched: boolean = false;
  @StorageProp('currentBreakpoint') currentBreakpoint: string = 'sm';
  @StorageProp('avoidAreaBottomVp') avoidAreaBottomVp: number = 0;
  @StorageProp('avoidAreaLeftVp') avoidAreaLeftVp: number = 0;
  @StorageProp('avoidAreaRightVp') avoidAreaRightVp: number = 0;
  @StorageProp('keyboardHeightVp') keyboardHeightVp: number = 0;
  private allApps: CommonSearchAppBean[] = [];

  aboutToAppear(): void {
    this.loadHistory();
    this.loadApps();
  }

  /** O2()：gson 解析 commonAppSearchHistory（缺省 "[]"） */
  private async loadHistory(): Promise<void> {
    const raw: string = await PreferencesUtil.getString(HISTORY_KEY, '[]');
    try {
      const list: string[] = JSON.parse(raw) as string[];
      this.historyList = list;
    } catch (error) {
      this.historyList = [];
    }
    if (this.searchText === '') {
      this.showHistory = this.historyList.length > 0;
    }
  }

  /** T2(str)：P2 命中先移除 → add(0) → 超 10 条截断 → 持久化 */
  private async saveHistory(keyword: string): Promise<void> {
    const list: string[] = this.historyList.slice();
    const idx: number = list.indexOf(keyword);
    if (idx >= 0) {
      list.splice(idx, 1);
    }
    list.unshift(keyword);
    const trimmed: string[] = list.length > HISTORY_MAX ? list.slice(0, HISTORY_MAX) : list;
    this.historyList = trimmed;
    await PreferencesUtil.putString(HISTORY_KEY, JSON.stringify(trimmed));
  }

  /** L2()：清空 commonAppSearchHistory + R2() */
  private async clearHistory(): Promise<void> {
    await PreferencesUtil.putString(HISTORY_KEY, '[]');
    this.historyList = [];
  }

  /** 宿主 37 数据链等价：GET /api/app/list {zdlx:'3',khdbb,type:'1'}（YDXYAppModel.V0） */
  private loadApps(): void {
    const params: Record<string, Object> = {
      'zdlx': '3',
      'khdbb': Constants.CLIENT_VERSION,
      'type': '1'
    };
    HttpClient.getWithEncParams('/mobileapi_ydxy/api/app/list', params)
      .then((response: ApiResponse<Object>) => {
        const apps: CommonSearchAppBean[] = [];
        if (HttpClient.normalizeCode(response.code) === 0 && typeof response.data === 'string') {
          try {
            const raw: Object[] = JSON.parse(response.data as string) as Object[];
            for (const one of raw) {
              const rec = one as Record<string, Object>;
              const type: string = typeof rec['TYPE'] === 'string' ? rec['TYPE'] as string : '';
              const dataArr: Object[] = Array.isArray(rec['DATA']) ? rec['DATA'] as Object[] : [];
              for (const d of dataArr) {
                const dr = d as Record<string, Object>;
                const bean = new CommonSearchAppBean();
                const pick = (k: string): string => {
                  const v: Object = dr[k];
                  return typeof v === 'string' ? v as string : '';
                };
                bean.yyid = pick('YYID');
                bean.yymc = pick('YYMC');
                bean.lx = pick('LX');
                bean.url = pick('URL');
                bean.yytb = pick('YYTB');
                bean.isCommonApp = type === '0';
                apps.push(bean);
              }
            }
          } catch (err) {
            // 解析失败保持空池（禁 mock）
          }
        }
        this.allApps = apps;
        if (this.searchText !== '') {
          this.filterResult();
        }
      })
      .catch(() => {
        // 网络失败保持空池（禁 mock）
      });
  }

  /** N2(list)：过滤 YYMC.contains(trim) */
  private filterResult(): void {
    const keyword: string = this.searchText.trim();
    this.resultList = this.allApps.filter((app: CommonSearchAppBean): boolean =>
      app.yymc !== '' && app.yymc.includes(keyword));
  }

  /** S2()：搜索动作（IME actionSearch） */
  private doSearch(): void {
    const keyword: string = this.searchText.trim();
    if (keyword === '') {
      this.getUIContext().getPromptAction().showToast({ message: '请输入搜索内容' });
      return;
    }
    this.saveHistory(keyword);
    this.filterResult();
    this.searched = true;
    this.showHistory = false;
  }

  /**
   * M2(app, i)：configApp{yyid,"1"}（YDXYAppModel.T0 = /api/app/configApp）成功回调 e()：
   * f.a(7, null)（宿主重拉等价：HAP 重拉全量池）+ 本行 setCommonApp(!isCommonApp) 翻转
   */
  private toggleCommon(app: CommonSearchAppBean, index: number): void {
    const params: Record<string, Object> = {
      'yyid': app.yyid,
      'type': '1'
    };
    HttpClient.getWithEncParams('/mobileapi_ydxy/api/app/configApp', params)
      .then((response: ApiResponse<Object>) => {
        const code: number = HttpClient.normalizeCode(response.code);
        if (code !== 0) {
          this.getUIContext().getPromptAction().showToast({ message: response.message });
          return;
        }
        // f.a(7, null) EventBus 等价：宿主 EditCommonAppActivity 收 7 重拉 + 通知主页 AppsTab
        AppStorage.setOrCreate<number>('common_app_changed', Date.now());
        this.loadApps();
        const target: CommonSearchAppBean | undefined = this.resultList[index];
        if (target !== undefined && target.yyid === app.yyid) {
          const next: CommonSearchAppBean[] = this.resultList.slice();
          const idx: number = next.indexOf(target);
          if (idx >= 0) {
            // 显式复制（ArkTS 禁对象展开）
            const flipped = new CommonSearchAppBean();
            flipped.yyid = target.yyid;
            flipped.yymc = target.yymc;
            flipped.lx = target.lx;
            flipped.url = target.url;
            flipped.yytb = target.yytb;
            flipped.isCommonApp = !target.isCommonApp;
            next[idx] = flipped;
            this.resultList = next;
          }
        }
      })
      .catch(() => {
        this.getUIContext().getPromptAction().showToast({ message: '网络请求失败，请稍后再试' });
      });
  }

  private iconUrl(app: CommonSearchAppBean): string {
    if (app.yyid === 'yibaogao' || app.yytb === '') {
      return '';
    }
    return Constants.SOCKET_HOST + '/mobileapi_ydxy/open/image/' + app.yytb;
  }

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
      .hoverEffect(HoverEffect.Highlight)
      .onClick(() => {
        this.searchText = keyword;
        this.doSearch();
      })
  }

  /** item_child_edit_common_app_search：图标+标题+tvStatus+减/加圆点 */
  @Builder
  appRow(app: CommonSearchAppBean, index: number) {
    Column() {
      Row() {
        if (this.iconUrl(app) === '') {
          Image($r('app.media.default_app_icon'))
            .width(40)
            .height(40)
            .objectFit(ImageFit.Cover)
        } else {
          Image(this.iconUrl(app))
            .width(40)
            .height(40)
            .objectFit(ImageFit.Cover)
            .alt($r('app.media.default_app_icon'))
        }

        Text(app.yymc)
          .fontSize(16)
          .fontColor($r('app.color.common_color_1'))
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .padding({ left: 12, right: 12 })
          .layoutWeight(1)

        Text(app.isCommonApp ? '移除' : '添加')
          .fontSize(16)
          .fontColor(app.isCommonApp ? '#fd5f65' : '#80d38d')
          .maxLines(2)
          .padding({ right: 8 })

        // flStatus：18×18 白圆 + 16×16 color_jian/jia 圆 + 白横杠(+常显竖杠 vVertical)
        Stack({ alignContent: Alignment.Center }) {
          Circle()
            .width(16)
            .height(16)
            .fill(app.isCommonApp ? '#fd5f65' : '#80d38d')
          Column() {
            Row()
              .width(10)
              .height(2)
              .borderRadius(1)
              .backgroundColor(Color.White)
            if (!app.isCommonApp) {
              Row()
                .width(2)
                .height(10)
                .borderRadius(1)
                .backgroundColor(Color.White)
                .margin({ top: 0 })
            }
          }
          .alignItems(HorizontalAlign.Center)
          .justifyContent(FlexAlign.Center)
        }
        .width(18)
        .height(18)
        .backgroundColor(Color.White)
        .borderRadius(9)
      }
      .width('100%')
      .padding(12)
      .borderRadius(8)
      .backgroundColor($r('app.color.white'))
      .alignItems(VerticalAlign.Center)
      .hoverEffect(HoverEffect.Highlight)
      .onClick(() => {
        this.toggleCommon(app, index);
      })
    }
    .width('100%')
    .padding({ left: 8, right: 8, top: 6, bottom: 6 })
  }

  /** layout_edit_common_app_search_empty 空态 */
  @Builder
  searchEmpty() {
    Column() {
      Image($r('app.media.icon_empty_common_app_search'))
        .objectFit(ImageFit.Contain)
        .alignSelf(ItemAlign.Center)
      Text('没有找到相关内容')
        .fontSize(14)
        .fontColor($r('app.color.common_color_1'))
        .textAlign(TextAlign.Center)
        .margin({ top: 4 })
      Text('换个关键词试试吧~')
        .fontSize(12)
        .fontColor($r('app.color.explain_color'))
        .textAlign(TextAlign.Center)
        .margin({ top: 4 })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .backgroundColor($r('app.color.white'))
  }

  build() {
    Column() {
      Column() {
        Row() {
          Stack({ alignContent: Alignment.End }) {
            Row() {
              Image(this.searchText === '' ? $r('app.media.icon_search_gray') : $r('app.media.icon_search_black'))
                .width(16)
                .height(16)
                .objectFit(ImageFit.Contain)
                .margin({ left: 10 })

              TextInput({ text: this.searchText, placeholder: '请输入应用名称搜索...' })
                .fontSize(14)
                .fontColor($r('app.color.common_color_1'))
                .placeholderColor($r('app.color.explain_color'))
                .placeholderFont({ size: 14 })
                .backgroundColor(Color.Transparent)
                .border({ width: 0 })
                .padding({ left: 8, right: 40 })
                .layoutWeight(1)
                .height(34)
                .enterKeyType(EnterKeyType.Search)
                .defaultFocus(true)
                .onChange((value: string) => {
                  this.searchText = value;
                  if (value === '') {
                    this.showHistory = this.historyList.length > 0;
                    this.searched = false;
                  }
                })
                .onSubmit(() => {
                  this.doSearch();
                })
            }
            .width('100%')
            .height(34)
            .borderRadius(8)
            .backgroundColor('#f2f2f2')
            .alignItems(VerticalAlign.Center)

            if (this.searchText !== '') {
              Image($r('app.media.icon_search_history_clear'))
                .width(40)
                .height(40)
                .objectFit(ImageFit.None)
                .hoverEffect(HoverEffect.Highlight)
                .onClick(() => {
                  this.searchText = '';
                  this.searched = false;
                  this.showHistory = this.historyList.length > 0;
                })
            }
          }
          .layoutWeight(1)
          .margin({ left: 16 })

          Text('取消')
            .fontSize(14)
            .fontColor($r('app.color.sdmu_primary'))
            .padding({ left: 16, right: 20 })
            .height('100%')
            .hoverEffect(HoverEffect.Highlight)
            .onClick(() => {
              router.back();
            })
        }
        .width('100%')
        .height(45)
        .padding({ left: this.avoidAreaLeftVp, right: this.avoidAreaRightVp })
        .constraintSize({ maxWidth: BreakpointSystem.getContentMaxWidth(this.currentBreakpoint) })
        .alignSelf(ItemAlign.Center)
        .alignItems(VerticalAlign.Center)
      }
      .width('100%')
      .backgroundColor($r('app.color.white'))
      .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP])

      if (!this.searched && this.showHistory) {
        Scroll() {
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
                .hoverEffect(HoverEffect.Highlight)
                .onClick(() => {
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
          .constraintSize({ maxWidth: BreakpointSystem.getContentMaxWidth(this.currentBreakpoint) })
          .alignSelf(ItemAlign.Center)
          .padding({
            top: 16,
            left: this.avoidAreaLeftVp,
            right: this.avoidAreaRightVp,
            bottom: this.keyboardHeightVp + this.avoidAreaBottomVp
          })
          .backgroundColor($r('app.color.white'))
        }
        .width('100%')
        .layoutWeight(1)
        .scrollBar(BarState.Off)
        .align(Alignment.Top)
      } else {
        Column() {
          if (this.resultList.length === 0) {
            this.searchEmpty()
          } else {
            List() {
              ForEach(this.resultList, (app: CommonSearchAppBean, index: number) => {
                ListItem() {
                  this.appRow(app, index)
                }
              }, (app: CommonSearchAppBean) => 'app_' + app.yyid + '_' + String(app.isCommonApp))
            }
            .width('100%')
            .height('100%')
            .contentEndOffset(this.keyboardHeightVp + this.avoidAreaBottomVp)
            .scrollBar(BarState.Off)
            .backgroundColor($r('app.color.white'))
          }
        }
        .width('100%')
        .constraintSize({ maxWidth: BreakpointSystem.getContentMaxWidth(this.currentBreakpoint) })
        .alignSelf(ItemAlign.Center)
        .padding({ left: this.avoidAreaLeftVp, right: this.avoidAreaRightVp })
        .layoutWeight(1)
        .backgroundColor($r('app.color.white'))
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.white'))
  }
}
