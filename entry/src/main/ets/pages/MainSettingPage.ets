import { BusinessError } from '@kit.BasicServicesKit';
import { TitleBar } from '../components/TitleBar';
import { HttpClient } from '../network/HttpClient';
import { ApiService } from '../network/ApiService';
import { ApiResponse } from '../model/ResponseModel';
import { MainAppGroup, MainAppItem } from '../model/ContactModel';
import { Constants } from '../data/Constants';

/**
 * 主页设置页 — 源码级翻译（MainSettingActivity.java + MainSettingAdapter.java 逐行 → ArkTS，
 * [W26 partial-finish]；原硬编码应用列表替换为真实数据链）：
 *
 * 【布局】mobile_campus_activity_message_setting.xml：toolbar 标题 mobile_campus_message_setting_title
 *   （toolBarView setVisibility(8) 隐藏，标题由 gVar.n() 供 TitleBar 等价）+ PullToRefreshLayout
 *   （setEnabled(false)/上拉禁用）+ ExpandableListView 白底 divider=null。
 * 【数据】O2() → d.g("2", false) → YDXYAppModel.V0("2", false)：e.b(g("list")) GET
 *   /mobileapi_ydxy/api/app/list {zdlx:"3", khdbb:s.d(), type:"2"} → ArrayList<YDAPPInfo>
 *   {TYPE, YYFL, DATA[AppBean]}。2026-11-18 探针实测 code=0 8 组真实分类（我的应用/办公应用/
 *   一卡通/数据服务/数据报告/轻松校园/后勤服务/移动学工，type=2 下 DATA 均 []）。
 * 【渲染】MainSettingAdapter：组标题=YYFL（app_title.xml padH12+4vp竖条+14fp #999 ml8）；
 *   getGroupType：TYPE=="0" 或 DATA>0 → 0（标题+宫格），否则 1 → **空 View（整组不可见）**；
 *   TYPE=="0" 组：app_divider_block 显示 + DATA 空 → "还没有添加提醒功能" 空态；角标 TYPE=="0"
 *   → delete / 其他 → addto；子项 app_item #F9F9F9：图标 32（CommonFactory YYTB 网络图，
 *   失败回 default_app_icon）+ 名称 13fp #333。
 * 【交互】点击任意 app（b.c.a(appBean, groupIndex)）→ N2 → d.e(yyid, "2") → YDXYAppModel.T0：
 *   POST /mobileapi_ydxy/api/app/configApp {yyid, type:"2"}（2026-11-18 实测假 yyid code=0001
 *   真实错误态）→ 成功：响应 YDAPPInfo{TYPE,DATA[0]} → TYPE 相同组 DATA 头部插入 → 点击组移除
 *   → setResult(-1)（HAP 等价 common_app_changed 信号，宿主页重拉同款 W24 机制）。
 * 【下拉刷新】PullToRefreshLayout 禁用（f1() setEnabled(false)）→ HAP 不挂 Refresh。
 * 【探针注】type=2 全组 DATA 空 → APK 真实渲染 = 组类型 1 全空 View，页面空白；
 *   HAP 同款渲染（组内无 app 不渲染），保持 1:1。
 */
interface MainSettingCell {
  groupIndex: number;
  appIndex: number;
  app: MainAppItem;
  isQuick: boolean;
}

@Entry
@Component
struct MainSettingPage {
  @State groups: MainAppGroup[] = [];
  @State isLoading: boolean = true;

  aboutToAppear(): void {
    this.loadGroups();
  }

  /** 源码 O2()：YDXYAppModel.V0("2", false) → GET app/list {zdlx:3, khdbb, type:2} */
  private loadGroups(): void {
    const params: Record<string, Object> = {
      'zdlx': '3',
      'khdbb': Constants.CLIENT_VERSION,
      'type': '2'
    };
    HttpClient.getWithEncParams('/mobileapi_ydxy/api/app/list', params)
      .then((response: ApiResponse<Object>) => {
        if (ApiService.isSuccess(response) && typeof response.data === 'string') {
          try {
            const raw: Object[] = JSON.parse(response.data as string) as Object[];
            const groups: MainAppGroup[] = [];
            for (const one of raw) {
              const rec = one as Record<string, Object>;
              const group: MainAppGroup = new MainAppGroup();
              group.YYFL = typeof rec['YYFL'] === 'string' ? rec['YYFL'] as string : '';
              group.TYPE = typeof rec['TYPE'] === 'string' ? rec['TYPE'] as string : '';
              const dataArr: Object[] = Array.isArray(rec['DATA']) ? rec['DATA'] as Object[] : [];
              for (const d of dataArr) {
                const dr = d as Record<string, Object>;
                const item: MainAppItem = new MainAppItem();
                item.YYID = typeof dr['YYID'] === 'string' ? dr['YYID'] as string : '';
                item.YYMC = typeof dr['YYMC'] === 'string' ? dr['YYMC'] as string : '';
                item.LX = typeof dr['LX'] === 'string' ? dr['LX'] as string : '';
                item.URL = typeof dr['URL'] === 'string' ? dr['URL'] as string : '';
                item.YYTB = typeof dr['YYTB'] === 'string' ? dr['YYTB'] as string : '';
                item.PXH = typeof dr['PXH'] === 'string' ? dr['PXH'] as string : '';
                group.DATA.push(item);
              }
              groups.push(group);
            }
            this.groups = groups;
          } catch (error) {
            const be = error as BusinessError;
            ApiService.logError('MainSettingPage parse fail: ' + be.message);
          }
        }
        this.isLoading = false;
      })
      .catch(() => {
        ApiService.logError('MainSettingPage load error');
        this.isLoading = false;
      });
  }

  /** 源码 getGroupType(i)：TYPE=="0" 或 DATA>0 → 0（渲染）；否则 1（空 View 整组不可见） */
  private groupVisible(group: MainAppGroup): boolean {
    return group.TYPE === '0' || group.DATA.length > 0;
  }

  /** 源码 ServerIcon 通道：CommonFactory.a = d.d() + "/mobileapi_ydxy/open/image/" + YYTB */
  private iconUrlOf(item: MainAppItem): string {
    if (item.YYTB === '') {
      return '';
    }
    return Constants.SOCKET_HOST + '/mobileapi_ydxy/open/image/' + item.YYTB;
  }

  /** 源码 N2(appBean, groupIndex)：d.e(yyid, "2") → T0 configApp {yyid, type:"2"} */
  private onAppClick(group: MainAppGroup, app: MainAppItem): void {
    if (app.YYID === '') {
      return;
    }
    ApiService.configMainApp(app.YYID)
      .then((response: ApiResponse<MainAppGroup>) => {
        if (response.code === 1000) {
          return;
        }
        if (response.code !== 0) {
          // 源码 b 类 f(...) → MainActivity.this.m(str2)（toast message）
          const msg: string = response.message === '' ? '服务器繁忙，请稍后再试' : response.message;
          this.getUIContext().getPromptAction().showToast({ message: msg });
          return;
        }
        // 源码 b 类 g(...)：响应 YDAPPInfo → TYPE 相同组 DATA 头部插入 DATA[0] → 点击组移除
        this.applyConfigResult(response.data, group, app);
      })
      .catch(() => {
        ApiService.logError('MainSettingPage configApp error');
        this.getUIContext().getPromptAction().showToast({ message: '服务器繁忙，请稍后再试' });
      });
  }

  /** 源码 b 类 g()：遍历组 TYPE 匹配 → group.DATA.add(0, resp.DATA.get(0))；
   *  无匹配组时源码不新增组（直接跳过插入）→ 点击组移除该 app → setResult(-1)。 */
  private applyConfigResult(result: MainAppGroup, fromGroup: MainAppGroup, app: MainAppItem): void {
    if (result === null || result.DATA.length <= 0) {
      return;
    }
    const moved: MainAppItem = result.DATA[0];
    for (const g of this.groups) {
      if (g.TYPE === result.TYPE) {
        g.DATA.unshift(moved);
        break;
      }
    }
    fromGroup.DATA = fromGroup.DATA.filter((a: MainAppItem): boolean => a.YYID !== app.YYID);
    this.groups = this.groups.slice();
    // 源码 setResult(-1)：宿主刷新等价（W24 onActivityResult 机制，Index 宫格重拉）
    AppStorage.setOrCreate<number>('common_app_changed', Date.now());
  }

  /** 收集当前可见渲染单元（组 0 才渲染标题+宫格） */
  private visibleGroups(): MainAppGroup[] {
    return this.groups.filter((g: MainAppGroup): boolean => this.groupVisible(g));
  }

  build() {
    Column() {
      TitleBar({ title: '添加提醒', showBack: true })

      if (this.isLoading) {
        Column()
          .width('100%')
          .layoutWeight(1)
      } else {
        Scroll() {
          Column() {
            ForEach(this.visibleGroups(), (group: MainAppGroup) => {
              Column() {
                // 组标题 app_title.xml：4vp primary 竖条 + 名称 14fp #999 marginL8
                Row() {
                  Row()
                    .width(4)
                    .backgroundColor($r('app.color.mobile_campus_primary_color'))
                    .margin({ left: 12, right: 8 })
                    .alignSelf(ItemAlign.Stretch)

                  Text(group.YYFL === '' ? '常用功能' : group.YYFL)
                    .fontSize(14)
                    .fontColor($r('app.color.common_color_3'))
                    .padding({ top: 8, bottom: 8 })
                }
                .width('100%')
                .alignItems(VerticalAlign.Center)

                // TYPE=="0" 组空态（adapter c 类："还没有添加提醒功能"）
                if (group.TYPE === '0' && group.DATA.length === 0) {
                  Text('还没有添加提醒功能')
                    .fontSize(14)
                    .fontColor($r('app.color.common_color_3'))
                    .padding({ left: 12, right: 12, top: 16, bottom: 16 })
                }

                // 子项宫格 apppage_gridview.xml：pad 12/16 + 4 列 #F9F9F9 卡片
                Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.Start }) {
                  ForEach(group.DATA, (app: MainAppItem) => {
                    Stack({ alignContent: Alignment.TopEnd }) {
                      Column() {
                        if (this.iconUrlOf(app) !== '') {
                          Image(this.iconUrlOf(app))
                            .width(32)
                            .height(32)
                            .objectFit(ImageFit.Contain)
                            .alt($r('app.media.default_app_icon'))
                            .onError(() => {
                              ApiService.logError('MainSettingPage icon load fail yyid=' + app.YYID);
                            })
                        } else {
                          Image($r('app.media.default_app_icon'))
                            .width(32)
                            .height(32)
                            .objectFit(ImageFit.Contain)
                        }

                        Text(app.YYMC)
                          .fontSize(13)
                          .fontColor($r('app.color.common_color_1'))
                          .maxLines(1)
                          .textOverflow({ overflow: TextOverflow.Ellipsis })
                          .margin({ top: 6 })
                          .padding({ left: 6, right: 6 })
                      }
                      .width('100%')
                      .padding({ top: 8, bottom: 6 })
                      .alignItems(HorizontalAlign.Center)

                      // adapter b 类：TYPE=="0" → delete / 其他 → addto
                      Image(group.TYPE === '0' ? $r('app.media.mobile_campus_delete')
                        : $r('app.media.mobile_campus_addto'))
                        .width(12)
                        .height(12)
                        .margin({ top: 4, right: 4 })
                        .objectFit(ImageFit.Contain)
                    }
                    .width('25%')
                    .clip(true)
                    .backgroundColor('#F9F9F9')
                    .onClick(() => {
                      this.onAppClick(group, app);
                    })
                  }, (app: MainAppItem) => group.TYPE + '_' + app.YYID + '_' + app.YYMC)
                }
                .width('100%')
                .padding({ left: 12, right: 12, top: 8, bottom: 16 })
                .backgroundColor('#F9F9F9')
                .visibility(group.DATA.length > 0 ? Visibility.Visible : Visibility.None)
              }
              .width('100%')
              .backgroundColor($r('app.color.white'))
              .margin({ top: 8 })
            }, (group: MainAppGroup) => group.TYPE + '_' + group.YYFL)
          }
          .width('100%')
        }
        .width('100%')
        .layoutWeight(1)
        .scrollBar(BarState.Off)
        .align(Alignment.Top)
        .backgroundColor('#F2F2F2')
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F2F2F2')
    .alignItems(HorizontalAlign.Start)
  }
}
