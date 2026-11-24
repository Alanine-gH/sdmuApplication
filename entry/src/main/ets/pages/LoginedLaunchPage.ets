import { router } from '@kit.ArkUI';
import { common } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { BreakpointSystem } from '../common/BreakpointSystem';
import { LoginSession } from '../network/LoginSession';
import { ApiService, RemoteHomeTabEntry } from '../network/ApiService';
import { LunarCalendar } from '../model/LunarCalendar';
import { PreferencesUtil } from '../data/PreferencesUtil';
import { GestureManager, GesturePwdBean } from '../model/GestureManager';
import { BiometricAuthHelper, BiometricCapability } from '../common/BiometricAuthHelper';

/**
 * 已登录启动页 — 1:1 复刻 LoginedLaunchActivity（284 行）+ mobile_campus_logined_launch.xml
 * [W22 launch-chain] 源码级翻译：
 *   布局：FrameLayout：ivBg（XML src=本地 mipmap mobile_campus_logined_launch，bottom+centerCrop；
 *     f1 再被 SchoolEntityUtils.a().getCampusLoginLaunch() 覆盖 —— 单校包同为本地图，渲染一致）
 *     + llLayout(vertical 恒 loaded 可见)：nameView 20fp/ml15/mt37.5、dateView1 14fp/ml15/mt40/mb5、
 *     dateView2 15fp/ml15，色 common_color_1。
 *   f1()：
 *     1) 启动即预取 getUserTabs（TabModel.T0 → module/d/d.a 缓存 "tab_datas_login" JSON，HAP=Prefs）；
 *     2) SystemSwitch 欢迎图分支：HAP 未持久化 SystemSwitch → 等价 systemSwitch==null 跳过（源码原样）；
 *     3) llLayout：农历 LunarCalendar.b(y,m+1,d,false) → J2() 问候（串含初/十/廿/卅/月尾 → 时段问候，
 *        否则"今天是X"；周末/凌晨/上午/下午/晚上）；q=userType=="1"?"同学":"老师"；
 *        dateView1 = "dd MON"（dd RelativeSizeSpan(4f)=56fp）；dateView2 = "星期X"
 *        （b.a.d.a.e(q(),new Date()) 调用后结果被丢弃，保真仅注释）；GJKF/HLJWY 三行白字分校分支；
 *     4) 1500ms → K2() → g2(e.a.f10993a=/launch/main)（HAP Index，jpush_extra 本端空）。
 *   未登录防御分支（源码 !b.b() → 1000ms → K2）保真：sessionKey 空 → 1s → Index（Index 再弹登录页）。
 * 入口链：CampusFirstPage（已登录分支）→ 本页 → Index（MainActivity）。
 */
const MONTH_EN: string[] = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

@Entry
@Component
struct LoginedLaunchPage {
  /** nameView 文本（空 = 源码 setVisibility(4) 隐藏） */
  @State nameText: string = '';
  @State showName: boolean = false;
  /** dateView1 日（2 位，56fp）与英文月 */
  @State dayText: string = '';
  @State monthText: string = '';
  /** dateView2 星期串 */
  @State weekText: string = '';
  @StorageProp('currentBreakpoint') currentBreakpoint: string = 'sm';
  @StorageProp('avoidAreaTopVp') avoidAreaTopVp: number = 0;
  @StorageProp('avoidAreaBottomVp') avoidAreaBottomVp: number = 0;
  @StorageProp('avoidAreaLeftVp') avoidAreaLeftVp: number = 0;
  @StorageProp('avoidAreaRightVp') avoidAreaRightVp: number = 0;
  private timerId: number = -1;

  aboutToAppear(): void {
    this.f1();
  }

  aboutToDisappear(): void {
    if (this.timerId !== -1) {
      clearTimeout(this.timerId);
      this.timerId = -1;
    }
  }

  /** 源码 f1() 逐行还原 */
  private f1(): void {
    const schoolId: string = LoginSession.schoolId;
    // 源码 this.k = ("CDJS".equals(schoolId) || "NXJS".equals(schoolId)) ? false : true（未再引用，保真）
    // 1) 启动即预取 getUserTabs → 缓存 tab_datas_login（module/d/d.a）
    ApiService.getUserTabs()
      .then((resp) => {
        if (resp.code === 0) {
          // 源码 HomeTabUtils.a(list)：x.f("tab_datas_login", Gson(list))，null → "[]"
          const json: string = resp.data.length > 0 ? JSON.stringify(resp.data) : '[]';
          PreferencesUtil.putString('tab_datas_login', json)
            .catch((error: BusinessError) => {
              LoginSession.log('cache tab_datas_login fail: ' + error.message);
            });
        }
      })
      .catch((error: BusinessError) => {
        ApiService.logError('getUserTabs fail: ' + error.message);
      });
    // 2) SystemSwitch.app_welcome_page_url 分支：HAP 未持久化 SystemSwitch → 等价 null 跳过
    if (LoginSession.sessionKey === '') {
      // 源码 !b.b() → 1000ms → K2（防御分支，CampusFirst 已按登录态分流）
      this.timerId = setTimeout(() => {
        this.goK2();
      }, 1000);
      return;
    }
    // 3) llLayout 可见（源码 this.p.setVisibility(0)）
    const now: Date = new Date();
    const lunar: string = new LunarCalendar().lunarString(now.getFullYear(), now.getMonth() + 1,
      now.getDate(), false);
    // 源码 q = userType=="1" ? "同学" : "老师"
    const title: string = LoginSession.userType === '1' ? '同学' : '老师';
    if (LoginSession.sessionName === '') {
      this.showName = false;
    } else {
      this.showName = true;
      this.nameText = LoginSession.sessionName + this.greeting(lunar, title, now);
    }
    this.dayText = String(now.getDate()).length < 2 ? '0' + now.getDate() : String(now.getDate());
    this.monthText = MONTH_EN[now.getMonth()];
    // 源码 strE = schedule.e.a.e(new Date(), "星期")；b.a.d.a.e(q(), new Date()) 调用后丢弃（节假日工具预热）
    this.weekText = '星期' + this.weekChar(now.getDay());
    // 4) 源码 ivBg：SchoolEntityUtils.a().getCampusLoginLaunch()（单校包 = 本地 mipmap，XML 已同图）
    //    GJKF/HLJWY 白字分校分支（schoolId 恒 SDGY → 不触发，保真注释）
    this.timerId = setTimeout(() => {
      this.goK2();
    }, 1500);
  }

  /** 源码 J2(str)：农历串干净（非空、无 初/十/廿/卅、不以"月"结尾）→ "今天是X"；否则时段问候 */
  private greeting(lunar: string, title: string, now: Date): string {
    const isClean: boolean = lunar !== '' && lunar.indexOf('初') < 0 && lunar.indexOf('十') < 0 &&
      lunar.indexOf('廿') < 0 && lunar.indexOf('卅') < 0 && !lunar.endsWith('月');
    if (isClean) {
      return title + ' 今天是' + lunar;
    }
    // getDay()：0=周日 6=周六（源码 Calendar.get(7)：1=周日 7=周六）
    if (now.getDay() === 0 || now.getDay() === 6) {
      return title + ' 周末愉快';
    }
    const hour: number = now.getHours();
    if (hour >= 0 && hour < 6) {
      return title + ' 凌晨好';
    }
    if (hour >= 6 && hour < 12) {
      return title + ' 上午好';
    }
    if (hour >= 12 && hour < 18) {
      return title + ' 下午好';
    }
    if (hour < 8 || hour >= 24) {
      return title + '好';
    }
    return title + ' 晚上好';
  }

  /** 源码 schedule.e.a.h(day)：1=日 2=一 … 7=六（Calendar.get(7) → JS getDay()+1） */
  private weekChar(jsDay: number): string {
    switch (jsDay + 1) {
      case 1:
        return '日';
      case 2:
        return '一';
      case 3:
        return '二';
      case 4:
        return '三';
      case 5:
        return '四';
      case 6:
        return '五';
      case 7:
        return '六';
      default:
        return '';
    }
  }

  /** 源码 K2()：bundle{jpush_extra} → 若已开启手势密码或生物识别锁，先进入身份验证页解锁 */
  private async goK2(): Promise<void> {
    if (LoginSession.sessionKey !== '') {
      try {
        const bean: GesturePwdBean | null = await GestureManager.find(GestureManager.resolveUserId());
        const ctx = this.getUIContext().getHostContext() as common.UIAbilityContext;
        const bioEnabled: boolean = await BiometricAuthHelper.isBiometricUnlockEnabled(ctx);
        const cap: BiometricCapability = BiometricAuthHelper.checkCapability();
        const needBioLock: boolean = bioEnabled && BiometricAuthHelper.shouldOfferBiometricToggle(cap);
        if ((bean !== null && bean.gesturePwds.length > 0) || needBioLock) {
          router.replaceUrl({
            url: 'pages/GesturePwdVerifyPage',
            params: {
              'jsonStr': bean !== null ? JSON.stringify(bean) : '',
              'mode': 'unlock'
            } as Record<string, string>
          });
          return;
        }
      } catch {
        // 忽略本地锁探测异常，回落直接进入主页
      }
    }
    router.replaceUrl({ url: 'pages/Index', params: { 'jpushExtra': '' } });
  }

  build() {
    Stack() {
      // ivBg：XML src=mobile_campus_logined_launch，layout_gravity=bottom + centerCrop（全屏覆盖）
      Image($r('app.media.mobile_campus_logined_launch'))
        .width('100%')
        .height('100%')
        .objectFit(ImageFit.Cover)
        .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])

      // llLayout（源码 f1 加载完成后 setVisibility(0)）
      Scroll() {
        Column() {
          // nameView：userName + J2 问候；userName 空 → INVISIBLE（源码 setVisibility(4)）
          Text(this.nameText)
            .fontSize(20)
            .fontColor($r('app.color.common_color_1'))
            .margin({ left: 15, top: Math.max(37.5, this.avoidAreaTopVp + 12) })
            .visibility(this.showName ? Visibility.Visible : Visibility.Hidden)

          // dateView1：SpannableStringBuilder("dd MON")，dd RelativeSizeSpan(4.0f)=56fp
          Text() {
            Span(this.dayText)
              .fontSize(56)
            Span(' ' + this.monthText)
              .fontSize(14)
          }
          .fontColor($r('app.color.common_color_1'))
          .margin({ left: 15, top: 40, bottom: 5 })

          // dateView2：星期X
          Text(this.weekText)
            .fontSize(15)
            .fontColor($r('app.color.common_color_1'))
            .margin({ left: 15 })
        }
        .width('100%')
        .constraintSize({ maxWidth: BreakpointSystem.getContentMaxWidth(this.currentBreakpoint) })
        .padding({
          left: this.avoidAreaLeftVp,
          right: this.avoidAreaRightVp,
          bottom: this.avoidAreaBottomVp
        })
        .alignItems(HorizontalAlign.Start)
      }
      .width('100%')
      .height('100%')
      .scrollBar(BarState.Off)
      .align(Alignment.Top)
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.white'))
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
  }
}
