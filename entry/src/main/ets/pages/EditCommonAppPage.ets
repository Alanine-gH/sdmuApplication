import { router } from '@kit.ArkUI';
import { HttpClient } from '../network/HttpClient';
import { ApiResponse } from '../model/ResponseModel';
import { Constants } from '../data/Constants';

/**
 * 添加常用应用页 — 源码级复刻 EditCommonAppActivity（newUI 包，ARouter /app/EditCommonAppActivity）。
 * 源码：mobile_campus_activity_edit_common_app 布局 = MToolBar(title"添加常用应用" +
 * rightIcon icon_work_search → e.a.y 搜索页) + SmartRefreshLayout(#f8f8f8) + RecyclerView(padH15)；
 * T2()：/api/app/list {zdlx:'3',khdbb,type:'1'}（YDXYAppModel.V0）→ X2(list)：
 *   U2 = TYPE=="0" 组 DATA → 头部 CommonAppHeaderAdapter 4 列（空 → layout_header_edit_common_app_empty
 *   "暂无应用~" 120dip）；
 *   R2 = 非 "0" 且 DATA 非空组 → 4 列补位（size%4 → 1/2/3 个 AppBean(null)）+ type_round
 *   （倒数第 4 位=1 左上圆角 / 末位=2 右上圆角）+ 末尾 YDAPPInfo(true) footer（15dip 空行）；
 * EditCommonAppAdapter：组头 item_header_edit_common_app（vLine 首组 15dip 其余 12dip +
 * YYFL 18sp bold #333 padH14 高 60 上圆角8；子项非空时 tvTitle 背景底圆角 8）+ item_child_edit_common_app
 * （55×45：图标 35×35 底对齐 + 右上 flStatus 18×18 白圆 + 16×16 减号 color_jian #fd5f65（常用）
 * /加号 color_jia #80d38d + 白横杠 10×2 + 非常用竖杠 2×10；名称 12sp #333 lines2 padding10）；
 * 点击（头部 e / 组内 b）→ Q2 → configApp{yyid,"1"} → 成功 f.a(7, null)（HAP 等价重拉）。
 */
/** /api/app/list 应用项（下发字段 + 渲染态） */
class EditAppBean {
  yyid: string = '';
  yymc: string = '';
  lx: string = '';
  url: string = '';
  yytb: string = '';
  /** isNull=true 的补位占位（AppBean(true)） */
  isNull: boolean = false;
  /** type_round：1=左上圆角 2=右上圆角（EditCommonAppAdapter R2 规则） */
  typeRound: number = 0;
}

class EditAppGroup {
  yyfl: string = '';
  isFooter: boolean = false;
  isFirst: boolean = false;
  /** TYPE=="0" 头部（isCommon=true 减号态）或普通分组 */
  isCommon: boolean = false;
  apps: EditAppBean[] = [];

  constructor(yyfl: string) {
    this.yyfl = yyfl;
  }
}

@Entry
@Component
struct EditCommonAppPage {
  @State groups: EditAppGroup[] = [];
  @State loading: boolean = false;
  /** Refresh 容器刷新态（SmartRefreshLayout 等价） */
  @State isRefreshing: boolean = false;

  aboutToAppear(): void {
    this.loadApps();
  }

  /** EventBus 7 等价：搜索页 toggle 后返回本页 → T2() 重拉（onPageShow 跳过首次） */
  private firstShow: boolean = true;

  onPageShow(): void {
    if (this.firstShow) {
      this.firstShow = false;
      return;
    }
    this.loadApps();
  }

  /** T2()：/api/app/list {zdlx:'3',khdbb,type:'1'} + X2/R2 分组加工 */
  private loadApps(): void {
    this.loading = true;
    const params: Record<string, Object> = {
      'zdlx': '3',
      'khdbb': Constants.CLIENT_VERSION,
      'type': '1'
    };
    HttpClient.getWithEncParams('/mobileapi_ydxy/api/app/list', params)
      .then((response: ApiResponse<Object>) => {
        const built: EditAppGroup[] = [];
        if (HttpClient.normalizeCode(response.code) === 0 && typeof response.data === 'string') {
          try {
            const raw: Object[] = JSON.parse(response.data as string) as Object[];
            let first = true;
            // 头部：TYPE=="0" 常用应用组
            for (const one of raw) {
              const rec = one as Record<string, Object>;
              const type: string = typeof rec['TYPE'] === 'string' ? rec['TYPE'] as string : '';
              const yyfl: string = typeof rec['YYFL'] === 'string' ? rec['YYFL'] as string : '';
              const dataArr: Object[] = Array.isArray(rec['DATA']) ? rec['DATA'] as Object[] : [];
              const apps: EditAppBean[] = [];
              for (const d of dataArr) {
                const dr = d as Record<string, Object>;
                const bean = new EditAppBean();
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
              if (type === '0') {
                const head = new EditAppGroup(yyfl);
                head.isCommon = true;
                head.isFirst = first;
                head.apps = apps;
                built.push(head);
                first = false;
              }
            }
            // R2：非 "0" 组（DATA 非空）4 列补位 + type_round + footer
            for (const one of raw) {
              const rec = one as Record<string, Object>;
              const type: string = typeof rec['TYPE'] === 'string' ? rec['TYPE'] as string : '';
              const yyfl: string = typeof rec['YYFL'] === 'string' ? rec['YYFL'] as string : '';
              const dataArr: Object[] = Array.isArray(rec['DATA']) ? rec['DATA'] as Object[] : [];
              if (type === '0' || dataArr.length === 0) {
                continue;
              }
              const apps: EditAppBean[] = [];
              for (const d of dataArr) {
                const dr = d as Record<string, Object>;
                const bean = new EditAppBean();
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
              // 补位 AppBean(true)：size%4 为 1/2/3 时补 4-size 个
              const remainder: number = apps.length % 4;
              if (remainder === 1 || remainder === 2 || remainder === 3) {
                for (let i = 0; i < 4 - remainder; i++) {
                  const pad = new EditAppBean();
                  pad.isNull = true;
                  apps.push(pad);
                }
              }
              // type_round：倒数第 4 位=1（左上圆角）、末位=2（右上圆角）
              for (let i = 0; i < apps.length; i++) {
                if (i === apps.length - 4) {
                  apps[i].typeRound = 1;
                } else if (i === apps.length - 1) {
                  apps[i].typeRound = 2;
                }
              }
              const group = new EditAppGroup(yyfl);
              group.isFirst = first;
              group.apps = apps;
              built.push(group);
              first = false;
            }
          } catch (err) {
            // 解析失败保持空态（禁 mock）
          }
        }
        // arrayList4.add(new YDAPPInfo(true))：末尾 footer
        const footer = new EditAppGroup('');
        footer.isFooter = true;
        built.push(footer);
        this.groups = built;
        this.loading = false;
      })
      .catch(() => {
        this.groups = [];
        this.loading = false;
        this.getUIContext().getPromptAction().showToast({ message: '网络请求失败，请稍后再试' });
      });
  }

  /** Q2(appBean)：configApp{yyid,"1"} 成功 → f.a(7)（HAP 重拉全量） */
  private toggleApp(app: EditAppBean): void {
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
        // f.a(7, null) EventBus 等价：通知主页 AppsTab 重拉（onActivityResult 5467 等价链）
        AppStorage.setOrCreate<number>('common_app_changed', Date.now());
        this.loadApps();
      })
      .catch(() => {
        this.getUIContext().getPromptAction().showToast({ message: '网络请求失败，请稍后再试' });
      });
  }

  private iconUrl(app: EditAppBean): string {
    if (app.yyid === 'yibaogao' || app.yytb === '') {
      return '';
    }
    return Constants.SOCKET_HOST + '/mobileapi_ydxy/open/image/' + app.yytb;
  }

  /** type_round → 各角圆角 vp（e=左上 8 / f=右上 8 / 其余直角） */
  private cellRadius(app: EditAppBean): BorderRadiuses {
    const r: BorderRadiuses = { topLeft: 0, topRight: 0, bottomRight: 0, bottomLeft: 0 };
    if (app.typeRound === 1) {
      r.topLeft = 8;
    } else if (app.typeRound === 2) {
      r.topRight = 8;
    }
    return r;
  }

  /** 组头 tvTitle 背景：子项非空 → 底部两角圆角 8（f15847b）；空 → 全圆角 8（f15848c） */
  private headerRadius(hasChildren: boolean): BorderRadiuses {
    const r: BorderRadiuses = { topLeft: 8, topRight: 8, bottomRight: 0, bottomLeft: 0 };
    if (!hasChildren) {
      r.bottomRight = 8;
      r.bottomLeft = 8;
    }
    return r;
  }

  /** item_child_edit_common_app 单格 */
  @Builder
  appCell(app: EditAppBean, isCommonGroup: boolean) {
    Column() {
      Stack({ alignContent: Alignment.BottomEnd }) {
        if (app.isNull) {
          Column()
            .width(35)
            .height(35)
        } else if (this.iconUrl(app) === '') {
          Image($r('app.media.default_app_icon'))
            .width(35)
            .height(35)
            .objectFit(ImageFit.Contain)
        } else {
          Image(this.iconUrl(app))
            .width(35)
            .height(35)
            .objectFit(ImageFit.Contain)
            .alt($r('app.media.default_app_icon'))
        }
        // flStatus：常用组减号（红）恒显；普通组按 isCommonApp——下发数据无标记 → 源码
        // EditCommonAppActivity.W2(yDAPPInfo, false) 全部 setCommonApp(false)=加号（绿）
        Stack({ alignContent: Alignment.Center }) {
          Circle()
            .width(16)
            .height(16)
            .fill(isCommonGroup ? '#fd5f65' : '#80d38d')
          Column() {
            Row()
              .width(10)
              .height(2)
              .borderRadius(1)
              .backgroundColor(Color.White)
            if (!isCommonGroup) {
              Row()
                .width(2)
                .height(10)
                .borderRadius(1)
                .backgroundColor(Color.White)
            }
          }
          .alignItems(HorizontalAlign.Center)
          .justifyContent(FlexAlign.Center)
        }
        .width(18)
        .height(18)
        .backgroundColor(Color.White)
        .borderRadius(9)
        .margin({ bottom: 0 })
      }
      .width(55)
      .height(45)
      .margin({ top: 5 })

      if (!app.isNull) {
        Text(app.yymc)
          .fontSize(12)
          .fontColor('#333333')
          .textAlign(TextAlign.Center)
          .maxLines(2)
          .padding(10)
          .width('100%')
      }
    }
    .width('100%')
    .alignItems(HorizontalAlign.Center)
    .backgroundColor(Color.White)
    .borderRadius(this.cellRadius(app))
    .onClick(() => {
      if (app.isNull) {
        return;
      }
      this.toggleApp(app);
    })
  }

  build() {
    Column() {
      // MToolBar：标题"添加常用应用" + 右 icon_work_search(padding 3)
      Row() {
        Text('＜')
          .fontSize(17)
          .fontColor($r('app.color.common_color_1'))
          .width(40)
          .height('100%')
          .textAlign(TextAlign.Center)
          .margin({ left: 15 })
          .onClick(() => {
            router.back();
          })
        Text('添加常用应用')
          .fontSize(17)
          .fontColor($r('app.color.common_color_1'))
          .layoutWeight(1)
          .textAlign(TextAlign.Center)
          .maxLines(1)
        Image($r('app.media.icon_work_search'))
          .width(35)
          .height(35)
          .objectFit(ImageFit.Contain)
          .padding(3)
          .margin({ right: 12 })
          .onClick(() => {
            // f.c(imageView)：→ e.a.y 搜索页
            router.pushUrl({ url: 'pages/EditCommonAppSearchPage' });
          })
      }
      .width('100%')
      .height(44)
      .alignItems(VerticalAlign.Center)
      .backgroundColor($r('app.color.main_bg'))
      .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP])

      // SmartRefreshLayout #f8f8f8 + RecyclerView padH15（Refresh 容器下拉刷新等价）
      Refresh({ refreshing: this.isRefreshing }) {
        Scroll() {
          Column() {
          ForEach(this.groups, (group: EditAppGroup, gIndex: number) => {
            if (group.isFooter) {
              // YDAPPInfo(true) footer：vLine 15dip
              Row()
                .width('100%')
                .height(15)
            } else {
              // vLine：首组 15dip 其余 12dip（组头 item_header_edit_common_app）
              Row()
                .width('100%')
                .height(group.isFirst ? 15 : 12)
              Column() {
                // tvTitle YYFL 18sp bold #333 padH14 高 60dip（footer 组不渲染 tvTitle）
                Text(group.yyfl)
                  .fontSize(18)
                  .fontWeight(FontWeight.Bold)
                  .fontColor('#333333')
                  .maxLines(1)
                  .padding({ left: 14, right: 14 })
                  .width('100%')
                  .height(60)
                  .textAlign(TextAlign.Start)
                  .backgroundColor(Color.White)
                  .borderRadius(this.headerRadius(group.apps.length > 0))

                if (group.apps.length === 0 && group.isCommon) {
                  // layout_header_edit_common_app_empty："暂无应用~" 120dip
                  Text('暂无应用~')
                    .fontSize(14)
                    .fontColor('#555555')
                    .textAlign(TextAlign.Center)
                    .width('100%')
                    .height(120)
                    .backgroundColor(Color.White)
                } else if (group.apps.length > 0) {
                  Grid() {
                    ForEach(group.apps, (app: EditAppBean) => {
                      GridItem() {
                        this.appCell(app, group.isCommon)
                      }
                    }, (app: EditAppBean) => 'cell_' + app.yyid + '_' + app.yymc + '_' + String(app.isNull))
                  }
                  .columnsTemplate('1fr 1fr 1fr 1fr')
                  .width('100%')
                  .height(Math.ceil(group.apps.length / 4) * 92)
                  .backgroundColor(Color.White)
                  .borderRadius({ bottomLeft: 8, bottomRight: 8 })
                }
              }
              .width('100%')
            }
          }, (group: EditAppGroup) => 'grp_' + group.yyfl + '_' + String(group.isFooter) + '_' + String(group.isCommon))
        }
        .width('100%')
        .padding({ left: 15, right: 15 })
      }
      .scrollable(ScrollDirection.Vertical)
      .scrollBar(BarState.Off)
      .width('100%')
      .height('100%')
      .backgroundColor('#f8f8f8')
      }
      .onRefreshing(() => {
        // RefreshActivity.L2 → T2（SmartRefreshLayout 下拉刷新等价）
        this.loadApps();
        this.isRefreshing = false;
      })
      .width('100%')
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#f8f8f8')
  }
}
