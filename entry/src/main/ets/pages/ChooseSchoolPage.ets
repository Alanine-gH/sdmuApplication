import { router } from '@kit.ArkUI';
import { HttpClient } from '../network/HttpClient';
import { ApiResponse } from '../model/ResponseModel';
import { LoginSession } from '../network/LoginSession';
import { PreferencesUtil } from '../data/PreferencesUtil';
import { BreakpointSystem } from '../common/BreakpointSystem';

/**
 * 选择学校页 — 源码级复刻 ChooseSchoolActivity（launch 包，登录链"登录帮助"选校入口）。
 * 源码：mobile_campus_choose_school 布局 = toolbar(gone) + 头部 45dip main_bg
 * （btn_back nav_back_btn pad(30,8) + round_shape_large_round_coner_grey_bg 搜索框
 * marginL/T/B 10px + search_icon 36dip marginL 10px + edit 15fp hint"搜索学校名称"）+
 * divider_horizontal_grey_thin + common_refresh_lv_rl（ListView + MultiStateView）；
 * 接口：CloudAppModel.U0（CloudAppFactory ydxy_url_release + /cloud_app/open/cloudApp/getList，
 * j=false 明文 GET {startIndex,pageSize:"20",keyword}，20 条/页 <20 停止）；
 * SchoolItemAdapter：logo 36vp（b.x(campusLoginIcon)：http(s) 原样否则 serverUrl +
 * /mobileapi/open/common/post/picture?uuid=）+ schoolName 15fp maxEms15 padV 15vp +
 * status!=0/1 → 灰色"维护中"（maintaining）+ arrow_right2；status==0/1 → 深色；
 * 交互：TextWatcher onTextChanged 实时重拉（W2 重置 startIndex）、IME search → 刷新、
 * 下拉重置/上拉 s++ 翻页；点击 → SchoolEntityUtils.h(entity)（持久化选中学校 + 重置会话）
 * → u=isFirst → e.a.u 登录页，否则 setResult+finish。
 * 实测 2026-11-18：ydxy.ly-sky.com:8098 校园网不可达（SSL EOF）→ 真实错误态+重试。
 */
class SchoolEntityBean {
  id: number = 0;
  schoolName: string = '';
  serverUrl: string = '';
  campusLoginIcon: string = '';
  status: number = 0;
}

const CLOUD_LIST_URL: string = 'https://ydxy.ly-sky.com:8098/cloud_app/open/cloudApp/getList';
const PAGE_SIZE: number = 20;
const SELECTED_SCHOOL_KEY: string = 'selected_school';

@Entry
@Component
struct ChooseSchoolPage {
  @State schools: SchoolEntityBean[] = [];
  @State loading: boolean = false;
  @State error: boolean = false;
  @State searchText: string = '';
  /** Refresh 容器刷新态（PullToRefreshLayout 下拉刷新等价） */
  @State isRefreshing: boolean = false;
  @StorageProp('currentBreakpoint') currentBreakpoint: string = 'sm';
  @StorageProp('avoidAreaBottomVp') avoidAreaBottomVp: number = 0;
  @StorageProp('avoidAreaLeftVp') avoidAreaLeftVp: number = 0;
  @StorageProp('avoidAreaRightVp') avoidAreaRightVp: number = 0;
  @StorageProp('keyboardHeightVp') keyboardHeightVp: number = 0;
  /** y(Intent)：isFirst=true → 登录前选校（选完进登录页） */
  private isFirst: boolean = false;
  /** U2：s++（上拉翻页游标） */
  private pageIndex: number = 0;
  /** b 响应：arrayList.size()<20 → setHasNoMoreData(true) */
  private noMore: boolean = false;
  /** TextWatcher 防抖（onTextChanged 每字符触发 W2 源码行为） */
  private searchTimer: number = -1;

  aboutToAppear(): void {
    const params: object | undefined = router.getParams() as object | undefined;
    if (params !== null && params !== undefined) {
      const record = params as Record<string, Object>;
      const first: Object = record['isFirst'];
      if (typeof first === 'boolean') {
        this.isFirst = first as boolean;
      }
    }
    this.reload();
  }

  /** V2(str)：r.f(new b).d(startIndex, "20", keyword) — 明文 GET（j=false，feedbackGet 同款头） */
  private fetchPage(startIndex: number, keyword: string, append: boolean): void {
    const params: Record<string, string> = {
      'startIndex': String(startIndex),
      'pageSize': String(PAGE_SIZE),
      'keyword': keyword
    };
    this.loading = true;
    HttpClient.feedbackGet(CLOUD_LIST_URL, params)
      .then((response: ApiResponse<Object>) => {
        this.loading = false;
        const code: number = HttpClient.normalizeCode(response.code);
        if (code !== 0) {
          if (!append && this.schools.length === 0) {
            this.error = true;
          }
          return;
        }
        this.error = false;
        const list: SchoolEntityBean[] = [];
        if (typeof response.data === 'string') {
          try {
            const raw: Object[] = JSON.parse(response.data as string) as Object[];
            for (const one of raw) {
              const rec = one as Record<string, Object>;
              const bean = new SchoolEntityBean();
              const num = rec['id'];
              bean.id = typeof num === 'number' ? num as number : 0;
              const pick = (k: string): string => {
                const v: Object = rec[k];
                return typeof v === 'string' ? v as string : '';
              };
              bean.schoolName = pick('schoolName');
              bean.serverUrl = pick('serverUrl');
              bean.campusLoginIcon = pick('campusLoginIcon');
              const st = rec['status'];
              bean.status = typeof st === 'number' ? st as number : 0;
              list.push(bean);
            }
          } catch (err) {
            // 解析失败按空数据处理（禁 mock）
          }
        }
        // b.g()："0".equals(code) → <20 停止加载；空且非追加 → q2 空态
        this.noMore = list.length < PAGE_SIZE;
        if (!append) {
          this.schools = list;
        } else {
          this.schools = this.schools.concat(list);
        }
      })
      .catch(() => {
        this.loading = false;
        if (!append) {
          this.error = true;
        }
      });
  }

  /** W2(str)：s=0 + t.clear() + V2(str) */
  private reload(): void {
    this.pageIndex = 0;
    this.fetchPage(0, this.searchText.trim(), false);
  }

  /** g.b() 上拉：U2(s++) + V2(str) */
  private loadMore(): void {
    if (this.noMore || this.loading) {
      return;
    }
    this.pageIndex++;
    this.fetchPage(this.pageIndex, this.searchText.trim(), true);
  }

  /** b.x(str)：http(s) 原样，否则 serverUrl + /mobileapi/open/common/post/picture?uuid= */
  private logoUrl(school: SchoolEntityBean): string {
    const icon: string = school.campusLoginIcon;
    if (icon === '') {
      return '';
    }
    if (icon.startsWith('http://') || icon.startsWith('https://')) {
      return icon;
    }
    return school.serverUrl + '/mobileapi/open/common/post/picture?uuid=' + icon;
  }

  /** h.onItemClick：SchoolEntityUtils.h(entity) → isFirst ? LoginPage : setResult+finish */
  private async chooseSchool(school: SchoolEntityBean): Promise<void> {
    // SchoolEntityUtils.h：持久化选中学校（a.e）+ b.f()/b.j(null) 重置协商会话
    const record: Record<string, Object> = {
      'id': school.id,
      'schoolName': school.schoolName,
      'serverUrl': school.serverUrl,
      'campusLoginIcon': school.campusLoginIcon,
      'status': school.status
    };
    await PreferencesUtil.putString(SELECTED_SCHOOL_KEY, JSON.stringify(record));
    await LoginSession.clearSession();
    if (this.isFirst) {
      // g2(f13133a, e.a.u, null)：登录页（u = mobile_campus_launch_login）
      router.replaceUrl({ url: 'pages/LoginPage' });
    } else {
      router.back();
    }
  }

  build() {
    Column() {
      // 头部 45dip main_bg：返回 + 搜索框
      Column() {
        Row() {
          Image($r('app.media.nav_back_btn'))
            .width(15)
            .height(15)
            .objectFit(ImageFit.Contain)
            .padding({ left: 15, right: 15, top: 4, bottom: 4 })
            .onClick(() => {
              // d()：finish
              router.back();
            })

          Row() {
            Image($r('app.media.search_icon'))
              .width(18)
              .height(18)
              .objectFit(ImageFit.Contain)
              .margin({ left: 5 })

            TextInput({ text: this.searchText, placeholder: '搜索学校名称' })
              .fontSize(15)
              .fontColor($r('app.color.common_color_1'))
              .placeholderColor($r('app.color.common_color_3'))
              .placeholderFont({ size: 15 })
              .backgroundColor(Color.Transparent)
              .border({ width: 0 })
              .padding({ right: 8 })
              .layoutWeight(1)
              .height('100%')
              .enterKeyType(EnterKeyType.Search)
              .onChange((value: string) => {
                // c onTextChanged：W2(trim) 实时搜索（300ms 防抖收敛网络抖动）
                this.searchText = value;
                if (this.searchTimer >= 0) {
                  clearTimeout(this.searchTimer);
                }
                this.searchTimer = setTimeout(() => {
                  this.reload();
                }, 300);
              })
              .onSubmit(() => {
                // f IME search：X2() 隐键盘 + W2
                clearTimeout(this.searchTimer);
                this.reload();
              })
          }
          .layoutWeight(1)
          .height(35)
          .borderRadius(25)
          .backgroundColor($r('app.color.common_color_6'))
          .margin({ left: 5, top: 5, bottom: 5 })
          .alignItems(VerticalAlign.Center)
        }
        .width('100%')
        .height(44)
        .padding({ left: this.avoidAreaLeftVp, right: this.avoidAreaRightVp })
        .constraintSize({ maxWidth: BreakpointSystem.getContentMaxWidth(this.currentBreakpoint) })
        .alignSelf(ItemAlign.Center)
        .alignItems(VerticalAlign.Center)

        Divider()
          .color($r('app.color.common_color_5'))
          .strokeWidth(0.5)
          .width('100%')
      }
      .width('100%')
      .height(45)
      .backgroundColor($r('app.color.main_bg'))
      .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP])

      // common_refresh_lv_rl：列表 / 空态 / 错误态
      if (this.error) {
        Column() {
          Text('加载失败，请检查网络后重试')
            .fontSize(14)
            .fontColor($r('app.color.explain_color'))
          Text('重试')
            .fontSize(14)
            .fontColor($r('app.color.sdmu_primary'))
            .padding({ left: 20, right: 20, top: 8, bottom: 8 })
            .onClick(() => {
              this.reload();
            })
        }
        .width('100%')
        .constraintSize({ maxWidth: BreakpointSystem.getContentMaxWidth(this.currentBreakpoint) })
        .alignSelf(ItemAlign.Center)
        .padding({
          left: this.avoidAreaLeftVp,
          right: this.avoidAreaRightVp,
          bottom: this.avoidAreaBottomVp
        })
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
        .backgroundColor($r('app.color.main_bg'))
      } else if (this.schools.length === 0 && !this.loading) {
        Column() {
          Text('暂无学校数据')
            .fontSize(14)
            .fontColor($r('app.color.explain_color'))
        }
        .width('100%')
        .constraintSize({ maxWidth: BreakpointSystem.getContentMaxWidth(this.currentBreakpoint) })
        .alignSelf(ItemAlign.Center)
        .padding({
          left: this.avoidAreaLeftVp,
          right: this.avoidAreaRightVp,
          bottom: this.avoidAreaBottomVp
        })
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
        .backgroundColor($r('app.color.main_bg'))
      } else {
        Refresh({ refreshing: this.isRefreshing }) {
          List() {
          ForEach(this.schools, (school: SchoolEntityBean) => {
            ListItem() {
              Column() {
                // mobile_campus_school_item：logo 36vp marginL15 + 名称 15fp padV15 maxEms15
                // + extra_info"维护中" + arrow_right2 marginR15 + 底 divider
                Row() {
                  if (this.logoUrl(school) === '') {
                    Image($r('app.media.default_app_icon'))
                      .width(36)
                      .height(36)
                      .objectFit(ImageFit.Cover)
                      .margin({ left: 15 })
                  } else {
                    Image(this.logoUrl(school))
                      .width(36)
                      .height(36)
                      .objectFit(ImageFit.Cover)
                      .alt($r('app.media.default_app_icon'))
                      .margin({ left: 15 })
                  }

                  Text(school.schoolName)
                    .fontSize(15)
                    .fontColor(school.status === 0 || school.status === 1
                      ? $r('app.color.common_color_1') : $r('app.color.common_color_3'))
                    .maxLines(1)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                    .padding({ top: 15, bottom: 15 })
                    .margin({ left: 15, right: 4 })
                    .layoutWeight(1)

                  if (school.status !== 0 && school.status !== 1) {
                    // maintaining："维护中"（TextSize4.Color4 灰色）
                    Text('维护中')
                      .fontSize(13)
                      .fontColor($r('app.color.common_color_3'))
                      .margin({ right: 4 })
                  }

                  Image($r('app.media.arrow_right'))
                    .width(14)
                    .height(14)
                    .objectFit(ImageFit.Contain)
                    .margin({ right: 15 })
                }
                .width('100%')
                .alignItems(VerticalAlign.Center)
                .backgroundColor($r('app.color.white'))
                .onClick(() => {
                  this.chooseSchool(school);
                })

                Divider()
                  .color($r('app.color.divider_grey'))
                  .strokeWidth(0.5)
                  .width('100%')
              }
              .width('100%')
            }
          }, (school: SchoolEntityBean) => 'sch_' + String(school.id) + '_' + school.schoolName)

          if (this.loading) {
            ListItem() {
              Text('加载中...')
                .fontSize(13)
                .fontColor($r('app.color.explain_color'))
                .width('100%')
                .textAlign(TextAlign.Center)
                .padding(12)
            }
          }
        }
        .width('100%')
        .constraintSize({ maxWidth: BreakpointSystem.getContentMaxWidth(this.currentBreakpoint) })
        .alignSelf(ItemAlign.Center)
        .padding({ left: this.avoidAreaLeftVp, right: this.avoidAreaRightVp })
        .contentEndOffset(this.keyboardHeightVp + this.avoidAreaBottomVp)
        .layoutWeight(1)
        .scrollBar(BarState.Off)
        .onReachEnd(() => {
          // g.b()：上拉下一页（<20 停止）
          this.loadMore();
        })
        }
        .onRefreshing(() => {
          // g.a()：下拉重置（PullToRefreshLayout.setOnPullToRefreshListener 等价）
          this.reload();
          this.isRefreshing = false;
        })
        .width('100%')
        .layoutWeight(1)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.main_bg'))
  }
}
