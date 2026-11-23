import { HttpClient } from '../network/HttpClient';
import { ApiResponse } from '../model/ResponseModel';
import { Constants } from '../data/Constants';
import { BreakpointSystem } from '../common/BreakpointSystem';
import { AdaptiveLayoutHelper } from '../common/AdaptiveLayoutHelper';

/**
 * 常用功能设置页 — 源码级复刻 AppsSettingActivity（view 包，ARouter /app/editCommonApp，
 * 主页工作台"点击添加"入口 e.a.x，requestCode 5467）。
 * 源码：mobile_campus_apps_activity 布局 = toolbar_normal(toolBarView 隐藏 T1) + MultiStateView +
 * PullToRefreshLayout(上拉禁用) + ExpandableListView；N2()：g("1", true)（YDXYAppModel.V0
 * refresh=true 不读缓存）→ 响应过滤 TYPE=="appStore" 移除 → AppSettingExAdapter.d(list) 全展开；
 * 组头 mobile_campus_apppage_app_title（4vp 红条 + YYFL 14fp common_color_3 marginL 8vp）仅
 * TYPE=="0" 或 DATA 非空组渲染，其余组 getGroupType==1 → 空 View；子项 mobile_campus_apppage_gridview
 * （4 列 GridViewInScrollView pad(12,0,12,12) 竖距12 横距4 ybg_white）+ item
 * mobile_campus_apppage_app_item（#f9f9f9 + 图标 32vp + 名称 13fp + 右上 12vp 减号
 * mobile_campus_delete(TYPE=="0")/加号 mobile_campus_addto）；TYPE=="0" 且空 →
 * "点击右侧设置，可添加常用功能" 13fp 高 80vp common_color_5 + app_divider_block 12vp；
 * 点击 → configApp{yyid,"1"}（YDXYAppModel.T0 toggle）成功 → 同 TYPE 组迁移 + setResult +
 * EventBus 7（HAP 等价：重拉全量）。
 */
class SettingAppBean {
  yyid: string = '';
  yymc: string = '';
  lx: string = '';
  url: string = '';
  yytb: string = '';
}

class SettingAppGroup {
  type: string = '';
  yyfl: string = '';
  /** 组头是否渲染（getGroupType：TYPE=="0" 或 DATA 非空 → 0，否则 1=空 View） */
  showHeader: boolean = false;
  apps: SettingAppBean[] = [];
}

@Entry
@Component
struct AppsSettingPage {
  @State groups: SettingAppGroup[] = [];
  @State loading: boolean = false;
  /** Refresh 容器刷新态（PullToRefreshLayout 等价） */
  @State isRefreshing: boolean = false;
  @StorageProp('currentBreakpoint') currentBreakpoint: string = 'sm';
  @StorageProp('avoidAreaTopVp') avoidAreaTopVp: number = 0;
  @StorageProp('avoidAreaBottomVp') avoidAreaBottomVp: number = 0;
  @StorageProp('avoidAreaLeftVp') avoidAreaLeftVp: number = 0;
  @StorageProp('avoidAreaRightVp') avoidAreaRightVp: number = 0;

  aboutToAppear(): void {
    this.loadApps();
  }

  /** N2()：g("1", true) → /api/app/list {zdlx:'3',khdbb,type:'1'}；a 回调过滤 appStore 组 */
  private loadApps(): void {
    this.loading = true;
    const params: Record<string, Object> = {
      'zdlx': '3',
      'khdbb': Constants.CLIENT_VERSION,
      'type': '1'
    };
    HttpClient.getWithEncParams('/mobileapi_ydxy/api/app/list', params)
      .then((response: ApiResponse<Object>) => {
        const built: SettingAppGroup[] = [];
        if (HttpClient.normalizeCode(response.code) === 0 && typeof response.data === 'string') {
          try {
            const raw: Object[] = JSON.parse(response.data as string) as Object[];
            for (const one of raw) {
              const rec = one as Record<string, Object>;
              const type: string = typeof rec['TYPE'] === 'string' ? rec['TYPE'] as string : '';
              // a.g()：TYPE=="appStore"（试用应用）组移除
              if (type === 'appStore') {
                continue;
              }
              const yyfl: string = typeof rec['YYFL'] === 'string' ? rec['YYFL'] as string : '';
              const dataArr: Object[] = Array.isArray(rec['DATA']) ? rec['DATA'] as Object[] : [];
              const apps: SettingAppBean[] = [];
              for (const d of dataArr) {
                const dr = d as Record<string, Object>;
                const bean = new SettingAppBean();
                const pick = (k: string): string => {
                  const v: Object = dr[k];
                  return typeof v === 'string' ? v as string : '';
                };
                bean.yyid = pick('YYID');
                bean.yymc = pick('YYMC');
                bean.lx = pick('LX');
                bean.url = pick('URL');
                bean.yytb = pick('YYTB');
                apps.push(bean);
              }
              const group = new SettingAppGroup();
              group.type = type;
              group.yyfl = yyfl;
              // getGroupType：TYPE=="0" 或 DATA 非空 → 组头渲染
              group.showHeader = type === '0' || apps.length > 0;
              group.apps = apps;
              built.push(group);
            }
          } catch (err) {
            // 解析失败保持空态（禁 mock）
          }
        }
        this.groups = built;
        this.loading = false;
      })
      .catch(() => {
        this.groups = [];
        this.loading = false;
        this.getUIContext().getPromptAction().showToast({ message: '网络请求失败，请稍后再试' });
      });
  }

  /** M2(appBean, i)：p.k(new d).e(yyid, "1") → configApp{yyid,"1"} toggle 成功 → 重拉 */
  private toggleApp(app: SettingAppBean): void {
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
        // setResult(-1) + f.a(7, null) EventBus 等价：通知主页 AppsTab 重拉
        AppStorage.setOrCreate<number>('common_app_changed', Date.now());
        this.loadApps();
      })
      .catch(() => {
        this.getUIContext().getPromptAction().showToast({ message: '网络请求失败，请稍后再试' });
      });
  }

  private iconUrl(app: SettingAppBean): string {
    if (app.yyid === 'yibaogao' || app.yytb === '') {
      return '';
    }
    return Constants.SOCKET_HOST + '/mobileapi_ydxy/open/image/' + app.yytb;
  }

  /** item：#f9f9f9 图标 32vp + 名称 13fp + 右上加减角标 */
  @Builder
  appCell(app: SettingAppBean, isCommonGroup: boolean) {
    Stack({ alignContent: Alignment.TopEnd }) {
      Column() {
        if (this.iconUrl(app) === '') {
          Image($r('app.media.default_app_icon'))
            .width(32)
            .height(32)
            .objectFit(ImageFit.Contain)
            .alignSelf(ItemAlign.Center)
        } else {
          Image(this.iconUrl(app))
            .width(32)
            .height(32)
            .objectFit(ImageFit.Contain)
            .alt($r('app.media.default_app_icon'))
            .alignSelf(ItemAlign.Center)
        }
        Text(app.yymc)
          .fontSize(13)
          .fontColor($r('app.color.common_color_1'))
          .textAlign(TextAlign.Center)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .margin({ top: 6 })
      }
      .width('100%')
      .padding({ top: 8, bottom: 6.5 })
      .alignItems(HorizontalAlign.Center)

      Image(isCommonGroup ? $r('app.media.mobile_campus_delete') : $r('app.media.mobile_campus_addto'))
        .width(12)
        .height(12)
        .objectFit(ImageFit.Contain)
        .margin({ top: 4, right: 4 })
    }
    .width('100%')
    .backgroundColor('#f9f9f9')
    .hoverEffect(HoverEffect.Highlight)
    .onClick(() => {
      this.toggleApp(app);
    })
  }

  build() {
    // T1：toolBarView 隐藏 → 无标题栏，直接 ExpandableListView（fitsSystemWindows）
    Column() {
      Refresh({ refreshing: this.isRefreshing }) {
        Scroll() {
          Column() {
          ForEach(this.groups, (group: SettingAppGroup) => {
            Column() {
              if (group.showHeader) {
                // mobile_campus_apppage_app_title：4vp 红条 + YYFL 14fp common_color_3 marginL 8
                Row() {
                  Row()
                    .width(4)
                    .height(16)
                    .backgroundColor($r('app.color.sdmu_primary'))
                  Text(group.yyfl)
                    .fontSize(14)
                    .fontColor($r('app.color.common_color_3'))
                    .margin({ left: 8 })
                }
                .width('100%')
                .padding({ left: 12, right: 12 })
                .alignItems(VerticalAlign.Center)
                .backgroundColor($r('app.color.ybg_white'))
              }

              if (group.apps.length === 0) {
                if (group.type === '0') {
                  // appage_apppage_emptyview："点击右侧设置，可添加常用功能" 高 80vp common_color_5
                  Text('点击右侧设置，可添加常用功能')
                    .fontSize(13)
                    .fontColor($r('app.color.common_color_3'))
                    .textAlign(TextAlign.Center)
                    .padding(10)
                    .width('100%')
                    .height(80)
                    .backgroundColor($r('app.color.common_color_5'))
                  // app_divider_block 12vp（TYPE=="0" 时显示）
                  Row()
                    .width('100%')
                    .height(12)
                    .backgroundColor($r('app.color.divider_dark_grey'))
                }
              } else {
                Grid() {
                  ForEach(group.apps, (app: SettingAppBean) => {
                    GridItem() {
                      this.appCell(app, group.type === '0')
                    }
                  }, (app: SettingAppBean) => 'st_' + app.yyid + '_' + app.yymc)
                }
                .columnsTemplate(AdaptiveLayoutHelper.buildColumnsTemplate(
                  BreakpointSystem.getGridColumns(this.currentBreakpoint, 4)
                ))
                .rowsGap(12)
                .columnsGap(4)
                .width('100%')
                .padding({ left: 12, right: 12, bottom: 12 })
                .height(AdaptiveLayoutHelper.computeGridHeightVp(
                  group.apps.length,
                  BreakpointSystem.getGridColumns(this.currentBreakpoint, 4),
                  60,
                  12,
                  12
                ))
                .backgroundColor($r('app.color.ybg_white'))
              }
            }
            .width('100%')
          }, (group: SettingAppGroup) => 'sg_' + group.type + '_' + group.yyfl)
        }
        .width('100%')
        .constraintSize({ maxWidth: BreakpointSystem.getContentMaxWidth(this.currentBreakpoint) })
        .alignSelf(ItemAlign.Center)
        .padding({
          left: this.avoidAreaLeftVp,
          right: this.avoidAreaRightVp,
          bottom: this.avoidAreaBottomVp
        })
      }
      .scrollable(ScrollDirection.Vertical)
      .scrollBar(BarState.Off)
      .width('100%')
      .height('100%')
      }
      .onRefreshing(() => {
        // PullToRefreshLayout 下拉刷新 → N2()
        this.loadApps();
        this.isRefreshing = false;
      })
      .width('100%')
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .padding({ top: this.avoidAreaTopVp })
    .backgroundColor($r('app.color.ybg_white'))
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP])
  }
}
