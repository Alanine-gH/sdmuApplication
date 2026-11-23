import { router } from '@kit.ArkUI';
import { Constants } from '../data/Constants';

/**
 * 中心详情页 — 源码级复刻 CenterDetailActivity（main 包，主页中心模块 y(Intent jsonStr) 进入）。
 * 源码：mobile_campus_activity_student_center 布局 = toolbar_normal(title=CenterBean.name) +
 * VirtualLayoutManager/DelegateAdapter（无网络请求，全量渲染路由参 jsonStr 的 ZhyBean.CenterBean）；
 * O2：背景 = colors.split(",")[0]（ACCEPT_TIME_SEPARATOR_SP=","），subModuleList 按 type 分发：
 *   "1" → OfficeHallView（mobile_campus_view_main_office_hall：标题行 3dip 白条+20sp 白组名
 *   marginTop 20 + 4 列宫格 padH5；item 白圆角 12 图标 24vp marginT 16dip + 名称 12sp bold 黑
 *   lines2 marginT 15dip；点击 → module/app/util/a.f(AppBean{LX:2,YYID:id,YYMC:name})）；
 *   "2" → StudentStyleView（横滚 item 宽 size>3?(w-10)*5/17:(w-10)/3、RoundedImageView 圆角8
 *   高 160dip + 底部 #99000000 user_name 14sp / dept_name 12sp；点击 → e.a.v LightApp{LX:2}）；
 *   "3" → CourseShowView（标题行 XML gone 保真省略 + Banner 130dip CardView 圆角 10dip margin(20,20,20,10)
 *   轮播 3s CircleIndicator；点击 → e.a.v + YYID=h5_credit_clever）；
 *   "4" → CenterNewsView（白卡圆角8 margin(12,10,12)：≤5 条 NewsBean 15sp 黑 pad(12,10)
 *   + 分隔线 0.5dip color[0] marginH10 + tvMore"查看更多" 14sp color[0]；item 点击 → a.k(url)
 *   WebView；tvMore → /main/NewsActivity（HAP 未翻译，按钮保真无跳转））；
 *   底部 CenterBottomAdapter = 20dip 空白。
 */
class CenterAllApp {
  icon: string = '';
  id: string = '';
  name: string = '';
  type: string = '';
  url: string = '';
}

class CenterStyleBanner {
  icon: string = '';
  user_name: string = '';
  dept_name: string = '';
  url: string = '';
}

class CenterCourseBanner {
  icon: string = '';
  id: string = '';
  name: string = '';
  url: string = '';
}

class CenterNewsItem {
  id: string = '';
  name: string = '';
  url: string = '';
}

class CenterSubModule {
  type: string = '';
  name: string = '';
  allApps: CenterAllApp[] = [];
  styleBanner: CenterStyleBanner[] = [];
  courseBanner: CenterCourseBanner[] = [];
  news: CenterNewsItem[] = [];
}

class CenterBeanData {
  name: string = '';
  colors: string = '';
  subModuleList: CenterSubModule[] = [];
}

@Entry
@Component
struct CenterDetailPage {
  @State center: CenterBeanData = new CenterBeanData();
  /** O2：colors.split(",")[0] → RecyclerView 背景 */
  @State bgColor: string = '#ffffff';
  /** 每个学生风采 item 宽（px）：size>3 ? (w-10)*5/17 : (w-10)/3 —— vp 化后 /2 */
  @State styleItemWidth: number = 100;

  aboutToAppear(): void {
    const params: object | undefined = router.getParams() as object | undefined;
    if (params !== null && params !== undefined) {
      const record = params as Record<string, Object>;
      const json: Object = record['jsonStr'];
      if (typeof json === 'string' && (json as string) !== '') {
        this.parseCenter(json as string);
      }
    }
  }

  /** y(Intent)：jsonStr → ZhyBean.CenterBean（含 subModuleList 按 type 分桶） */
  private parseCenter(json: string): void {
    try {
      const rec = JSON.parse(json) as Record<string, Object>;
      const bean = new CenterBeanData();
      const pick = (r: Record<string, Object>, k: string): string => {
        const v: Object = r[k];
        return typeof v === 'string' ? v as string : '';
      };
      bean.name = pick(rec, 'name');
      bean.colors = pick(rec, 'colors');
      const subs: Object[] = Array.isArray(rec['subModuleList']) ? rec['subModuleList'] as Object[] : [];
      for (const s of subs) {
        const sr = s as Record<string, Object>;
        const sub = new CenterSubModule();
        sub.type = pick(sr, 'type');
        sub.name = pick(sr, 'name');
        const allAppsArr: Object[] = Array.isArray(sr['allApps']) ? sr['allApps'] as Object[] : [];
        for (const a of allAppsArr) {
          const ar = a as Record<string, Object>;
          const app = new CenterAllApp();
          app.icon = pick(ar, 'icon');
          app.id = pick(ar, 'id');
          app.name = pick(ar, 'name');
          app.type = pick(ar, 'type');
          app.url = pick(ar, 'url');
          sub.allApps.push(app);
        }
        const styleArr: Object[] = Array.isArray(sr['styleBanner']) ? sr['styleBanner'] as Object[] : [];
        for (const a of styleArr) {
          const ar = a as Record<string, Object>;
          const item = new CenterStyleBanner();
          item.icon = pick(ar, 'icon');
          item.user_name = pick(ar, 'user_name');
          item.dept_name = pick(ar, 'dept_name');
          item.url = pick(ar, 'url');
          sub.styleBanner.push(item);
        }
        const courseArr: Object[] = Array.isArray(sr['courseBanner']) ? sr['courseBanner'] as Object[] : [];
        for (const a of courseArr) {
          const ar = a as Record<string, Object>;
          const item = new CenterCourseBanner();
          item.icon = pick(ar, 'icon');
          item.id = pick(ar, 'id');
          item.name = pick(ar, 'name');
          item.url = pick(ar, 'url');
          sub.courseBanner.push(item);
        }
        const newsArr: Object[] = Array.isArray(sr['news']) ? sr['news'] as Object[] : [];
        for (const a of newsArr) {
          const ar = a as Record<string, Object>;
          const item = new CenterNewsItem();
          item.id = pick(ar, 'id');
          item.name = pick(ar, 'name');
          item.url = pick(ar, 'url');
          sub.news.push(item);
        }
        bean.subModuleList.push(sub);
      }
      this.center = bean;
      // O2：colors.split(",")[0] 背景
      if (bean.colors !== '') {
        const first: string = bean.colors.split(',')[0];
        if (first !== '') {
          this.bgColor = first;
        }
      }
    } catch (err) {
      // 解析失败保持空态（禁 mock）
    }
  }

  /** 图标 URL：http(s) 原样，否则服务端图标公式（ServerIcon 同口径） */
  private iconUrl(icon: string): string {
    if (icon === '') {
      return '';
    }
    if (icon.startsWith('http://') || icon.startsWith('https://')) {
      return icon;
    }
    return Constants.SOCKET_HOST + '/mobileapi_ydxy/open/image/' + icon;
  }

  /** type1 点击：a.f(AppBean{LX:"2",YYID:id,YYMC:name}) → LightAppPage（springboard yyid） */
  private openHallApp(app: CenterAllApp): void {
    router.pushUrl({
      url: 'pages/LightAppPage',
      params: { title: app.name, url: app.url, yyid: app.id, lx: '2' }
    });
  }

  /** type2 点击：w.g(e.a.v, bundle{appInfo{LX:2,YYMC,URL},h5:true}) */
  private openStyle(item: CenterStyleBanner, name: string): void {
    router.pushUrl({
      url: 'pages/LightAppPage',
      params: { title: name, url: item.url, yyid: '', lx: '2' }
    });
  }

  /** type3 点击：w.g(e.a.v, bundle{appInfo{LX:2,YYID:h5_credit_clever,YYMC,URL},h5:true}) */
  private openCourse(item: CenterCourseBanner, name: string): void {
    router.pushUrl({
      url: 'pages/LightAppPage',
      params: { title: name, url: item.url, yyid: 'h5_credit_clever', lx: '2' }
    });
  }

  /** type4 item 点击：a.k(K1(), "", news.url) → WebView */
  private openNewsUrl(item: CenterNewsItem): void {
    if (item.url === '') {
      return;
    }
    router.pushUrl({ url: 'pages/WebViewPage', params: { url: item.url } });
  }

  /** 组标题行：3dip 白条 + 20sp 白组名（paddingH 12 marginTop 20） */
  @Builder
  moduleTitle(name: string) {
    Row() {
      Row()
        .width(1.5)
        .height(24)
        .borderRadius(15)
        .backgroundColor(Color.White)
        .margin({ top: 1, bottom: 1 })
      Text(name)
        .fontSize(20)
        .fontColor(Color.White)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .padding({ left: 4, right: 4 })
    }
    .width('100%')
    .padding({ left: 12, right: 12 })
    .margin({ top: 10 })
    .alignItems(VerticalAlign.Center)
  }

  /** OfficeHallView：4 列宫格（item 宽 = (100% - 25vp)/4 由 Grid 1fr 等价） */
  @Builder
  officeHall(sub: CenterSubModule) {
    Column() {
      this.moduleTitle(sub.name)
      Grid() {
        ForEach(sub.allApps, (app: CenterAllApp) => {
          GridItem() {
            Column() {
              if (this.iconUrl(app.icon) === '') {
                Image($r('app.media.default_app_icon'))
                  .width(24)
                  .height(24)
                  .objectFit(ImageFit.Contain)
                  .margin({ top: 8 })
              } else {
                Image(this.iconUrl(app.icon))
                  .width(24)
                  .height(24)
                  .objectFit(ImageFit.Contain)
                  .margin({ top: 8 })
              }
              Text(app.name)
                .fontSize(12)
                .fontWeight(FontWeight.Bold)
                .fontColor(Color.Black)
                .textAlign(TextAlign.Center)
                .maxLines(2)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
                .padding({ left: 2.5, right: 2.5 })
                .margin({ top: 7.5, bottom: 2.5 })
            }
            .width('100%')
            .alignItems(HorizontalAlign.Center)
            .borderRadius(6)
            .backgroundColor(Color.White)
            .onClick(() => {
              this.openHallApp(app);
            })
          }
        }, (app: CenterAllApp) => 'hall_' + app.id + '_' + app.name)
      }
      .columnsTemplate('1fr 1fr 1fr 1fr')
      .width('100%')
      .padding({ left: 2.5, right: 2.5 })
      .margin({ top: 2.5 })
      .height(Math.ceil(sub.allApps.length / 4) * 62)
    }
    .width('100%')
  }

  /** StudentStyleView：横滚学生风采（RoundedImageView 圆角 8 高 80vp + 底部黑半透明姓名/学院） */
  @Builder
  studentStyle(sub: CenterSubModule) {
    Column() {
      this.moduleTitle(sub.name)
      Scroll() {
        Row() {
          ForEach(sub.styleBanner, (item: CenterStyleBanner) => {
            Stack({ alignContent: Alignment.Bottom }) {
              if (this.iconUrl(item.icon) === '') {
                Column()
                  .width(this.styleItemWidth)
                  .height(80)
                  .backgroundColor(Color.White)
              } else {
                Image(this.iconUrl(item.icon))
                  .width(this.styleItemWidth)
                  .height(80)
                  .objectFit(ImageFit.Cover)
                  .borderRadius(4)
              }
              Column() {
                Text(item.user_name)
                  .fontSize(14)
                  .fontColor(Color.White)
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
                  .padding({ left: 2.5, right: 2.5 })
                Text(item.dept_name)
                  .fontSize(12)
                  .fontColor(Color.White)
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
                  .padding({ left: 2.5, right: 2.5 })
                  .margin({ top: 4 })
              }
              .width('100%')
              .padding({ top: 2.5, bottom: 2.5 })
              .alignItems(HorizontalAlign.Start)
              .backgroundColor('#99000000')
              .borderRadius({ bottomLeft: 4, bottomRight: 4 })
            }
            .width(this.styleItemWidth)
            .margin({ left: 2.5, right: 2.5 })
            .onClick(() => {
              this.openStyle(item, sub.name);
            })
          }, (item: CenterStyleBanner) => 'style_' + item.user_name + '_' + item.dept_name)
        }
        .padding({ left: 2.5, right: 2.5 })
      }
      .scrollable(ScrollDirection.Horizontal)
      .scrollBar(BarState.Off)
      .width('100%')
      .margin({ top: 2.5 })
    }
    .width('100%')
  }

  /** CourseShowView：Banner 轮播 65vp（标题行 XML gone 保真省略） */
  @Builder
  courseShow(sub: CenterSubModule) {
    Column() {
      Swiper() {
        ForEach(sub.courseBanner, (item: CenterCourseBanner) => {
          Stack() {
            if (this.iconUrl(item.icon) === '') {
              Image($r('app.media.default_app_icon'))
                .width('100%')
                .height('100%')
                .objectFit(ImageFit.Cover)
            } else {
              Image(this.iconUrl(item.icon))
                .width('100%')
                .height('100%')
                .objectFit(ImageFit.Cover)
            }
          }
          .width('100%')
          .height('100%')
          .onClick(() => {
            this.openCourse(item, sub.name);
          })
        }, (item: CenterCourseBanner) => 'course_' + item.id + '_' + item.name)
      }
      .autoPlay(true)
      .interval(3000)
      .indicator(new DotIndicator().selectedColor('#ffffff'))
      .borderRadius(5)
      .width('100%')
      .height(65)
    }
    .width('100%')
    .padding({ left: 10, right: 10, top: 10, bottom: 5 })
    .alignItems(HorizontalAlign.Center)
  }

  /** CenterNewsView：白卡圆角 8 ≤5 条新闻 + 查看更多 */
  @Builder
  centerNews(sub: CenterSubModule, accent: string) {
    Column() {
      this.moduleTitle(sub.name)
      Column() {
        Column() {
          List() {
            ForEach(sub.news.slice(0, 5), (item: CenterNewsItem) => {
              ListItem() {
                Column() {
                  Text(item.name)
                    .fontSize(15)
                    .fontColor(Color.Black)
                    .maxLines(1)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                    .padding({ left: 6, right: 6, top: 5, bottom: 5 })
                    .width('100%')
                  Row() {
                    Row()
                      .width('100%')
                      .height(0.25)
                      .backgroundColor(accent)
                  }
                  .width('100%')
                  .padding({ left: 5, right: 5 })
                }
                .width('100%')
                .onClick(() => {
                  this.openNewsUrl(item);
                })
              }
            }, (item: CenterNewsItem) => 'news_' + item.id + '_' + item.name)
          }
          .width('100%')
          .height(Math.min(sub.news.length, 5) * 26 + 6)
          .scrollBar(BarState.Off)

          Text('查看更多')
            .fontSize(14)
            .fontColor(accent)
            .textAlign(TextAlign.Center)
            .width('100%')
            .padding({ top: 5, bottom: 5 })
            .onClick(() => {
              // tvMore → /main/NewsActivity（HAP 页集无该页，按钮保真不跳转）
            })
        }
        .width('100%')
        .borderRadius(4)
        .backgroundColor(Color.White)
        .padding({ left: 2.5, right: 2.5, top: 2.5 })
      }
      .width('100%')
      .padding({ left: 6, right: 6, top: 5 })
    }
    .width('100%')
  }

  build() {
    Column() {
      // toolbar_normal：title = CenterBean.name（无参缺省"中心详情"）
      Row() {
        Image($r('app.media.nav_back_btn'))
          .width(20)
          .height(20)
          .objectFit(ImageFit.Contain)
          .padding({ left: 15, right: 5 })
          .onClick(() => {
            router.back();
          })
        Text(this.center.name === '' ? '中心详情' : this.center.name)
          .fontSize(17)
          .fontColor($r('app.color.common_color_1'))
          .layoutWeight(1)
          .textAlign(TextAlign.Center)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        Blank()
          .width(30)
      }
      .width('100%')
      .height(44)
      .alignItems(VerticalAlign.Center)
      .backgroundColor($r('app.color.main_bg'))
      .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP])

      if (this.center.subModuleList.length === 0) {
        // 无路由参（y() jsonStr 缺失）→ 空态（禁编造）
        Column() {
          Text('暂无内容')
            .fontSize(14)
            .fontColor($r('app.color.explain_color'))
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
        .backgroundColor(this.bgColor)
      } else {
        Scroll() {
          Column() {
            ForEach(this.center.subModuleList, (sub: CenterSubModule) => {
              if (sub.type === '1') {
                this.officeHall(sub)
              } else if (sub.type === '2') {
                this.studentStyle(sub)
              } else if (sub.type === '3') {
                this.courseShow(sub)
              } else if (sub.type === '4') {
                this.centerNews(sub, this.bgColor)
              }
            }, (sub: CenterSubModule) => 'sub_' + sub.type + '_' + sub.name)
            // CenterBottomAdapter：20dip 底部空白
            Row()
              .width('100%')
              .height(10)
          }
          .width('100%')
        }
        .scrollable(ScrollDirection.Vertical)
        .scrollBar(BarState.Off)
        .width('100%')
        .layoutWeight(1)
        .backgroundColor(this.bgColor)
      }
    }
    .width('100%')
    .height('100%')
  }
}
