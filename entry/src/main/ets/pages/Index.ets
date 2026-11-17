import { LoginSession } from '../network/LoginSession';
import { router } from '@kit.ArkUI';
import { PreferencesUtil } from '../data/PreferencesUtil';
import { Constants } from '../data/Constants';
import { WMHTab } from '../components/WMHTab';
import { ICampusTab } from '../components/ICampusTab';
import { IOfficeTab } from '../components/IOfficeTab';
import { MineTab } from '../components/MineTab';

/**
 * 应用 Tab — 复刻 mobile_campus_view_main_app.xml 行布局：
 * 白底列表行：icon 32vp(margin 8vp) + 名称 15fp(px_to_sp_30) 加粗 common_color_1 单行。
 */
class AppEntry {
  name: string = '';
  target: string = '';

  constructor(name: string, target: string) {
    this.name = name;
    this.target = target;
  }
}

@Component
struct AppsTab {
  private entries: AppEntry[] = [
    new AppEntry('新闻公告', 'pages/NewsPage'),
    new AppEntry('我的课表', 'pages/SchedulePage'),
    new AppEntry('待办事项', 'pages/TodoPage'),
    new AppEntry('我的成绩', 'pages/ScorePage'),
    new AppEntry('考试安排', 'pages/ExamPage'),
    new AppEntry('通讯录', 'pages/ContactPage'),
    new AppEntry('会议', 'pages/MeetingPage'),
    new AppEntry('考勤记录', 'pages/AttendancePage'),
    new AppEntry('个人资料', 'pages/PersonalDetailPage')
  ];

  @Builder
  appRow(entry: AppEntry) {
    Row() {
      Image($r('app.media.icon_share'))
        .width(32)
        .height(32)
        .margin(8)
        .objectFit(ImageFit.Cover)
      Text(entry.name)
        .fontSize(15)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.common_color_1'))
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .margin({ left: 12 })
        .layoutWeight(1)
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 10, bottom: 10 })
    .alignItems(VerticalAlign.Center)
    .backgroundColor($r('app.color.white'))
    .onClick(() => {
      router.pushUrl({ url: entry.target });
    })
  }

  build() {
    Column() {
      List() {
        ForEach(this.entries, (entry: AppEntry) => {
          ListItem() {
            this.appRow(entry)
          }
        }, (entry: AppEntry) => entry.target)
      }
      .width('100%')
      .layoutWeight(1)
      .backgroundColor($r('app.color.white'))
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.white'))
  }
}

/**
 * 校圈 Tab — 复刻 social_main_activity.xml：
 * toolbar_normal(45vp 白底标题) + fl_container 空容器（内容由社交模块运行时加载）。
 */
@Component
struct SocialTab {
  build() {
    Column() {
      Column() {
        Text($r('app.string.school_community'))
          .fontSize(17)
          .fontColor($r('app.color.common_color_1'))
          .height(44)
          .textAlign(TextAlign.Center)
        Divider()
          .color($r('app.color.common_color_5'))
          .strokeWidth(0.5)
          .width('100%')
      }
      .width('100%')
      .height(45)
      .justifyContent(FlexAlign.Center)
      .backgroundColor($r('app.color.main_bg'))

      // fl_container
      Column() {
      }
      .width('100%')
      .layoutWeight(1)
      .backgroundColor($r('app.color.white'))
    }
    .width('100%')
    .height('100%')
  }
}

/**
 * 报告 Tab — 复刻 mobile_campus_fragment_main_v3.xml：
 *   - 顶部 44vp 白底校名横幅图（fitXY）
 *   - SlidingTabLayout：高 44vp、指示器 #97000C 宽 28vp 高 3vp 圆角 1.5、
 *     文字选中 #333333 加粗 14fp / 未选中 #808080 14fp、tab padding 15vp
 *   - ViewPager 内容（微门户/I校园/I办公，Tab 数据源与 Android 端一致由服务端菜单下发）
 */
@Component
struct ReportTab {
  @State subTabIndex: number = 0;

  @Builder
  subTabLabel(label: string | Resource, index: number) {
    Column() {
      Text(label)
        .fontSize(14)
        .fontColor($r('app.color.common_color_1'))
        .fontWeight(FontWeight.Bold)
        .padding({ left: 15, right: 15 })
      // 指示器：px_to_dip_56/2=28vp 宽、px_to_dip_6/2=3vp 高、圆角 1.5vp
      Row()
        .width(28)
        .height(3)
        .borderRadius(1.5)
        .backgroundColor($r('app.color.mobile_campus_primary_color'))
        .margin({ top: 4 })
    }
    .height(44)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .onClick(() => {
      this.subTabIndex = index;
    })
  }

  @Builder
  subTabLabelUnselected(label: string | Resource, index: number) {
    Column() {
      Text(label)
        .fontSize(14)
        .fontColor($r('app.color.tab_unselected'))
        .fontWeight(FontWeight.Normal)
        .padding({ left: 15, right: 15 })
      // 占位保持高度一致
      Row()
        .width(28)
        .height(3)
        .margin({ top: 4 })
    }
    .height(44)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .onClick(() => {
      this.subTabIndex = index;
    })
  }

  build() {
    Column() {
      // 顶部校名横幅：44vp 白底、fitXY
      Row() {
        Image($r('app.media.mobile_campus_main_head_logo'))
          .width('100%')
          .height(44)
          .objectFit(ImageFit.Fill)
      }
      .width('100%')
      .height(44)
      .backgroundColor($r('app.color.main_bg'))

      // SlidingTabLayout：微门户 / I校园 / I办公
      Row() {
        if (this.subTabIndex === 0) {
          this.subTabLabel('微门户', 0)
        } else {
          this.subTabLabelUnselected('微门户', 0)
        }
        if (this.subTabIndex === 1) {
          this.subTabLabel('I校园', 1)
        } else {
          this.subTabLabelUnselected('I校园', 1)
        }
        if (this.subTabIndex === 2) {
          this.subTabLabel('I办公', 2)
        } else {
          this.subTabLabelUnselected('I办公', 2)
        }
      }
      .width('100%')
      .height(44)
      .justifyContent(FlexAlign.Center)

      // ViewPager 内容
      if (this.subTabIndex === 0) {
        WMHTab()
          .width('100%')
          .layoutWeight(1)
      } else if (this.subTabIndex === 1) {
        ICampusTab()
          .width('100%')
          .layoutWeight(1)
      } else {
        IOfficeTab()
          .width('100%')
          .layoutWeight(1)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.main_bg'))
  }
}

/**
 * 主页 — 复刻 mobile_campus_activity_main.xml + main_bottom_bar_rgroup.xml：
 * NoScrollViewPager + BadgeLayout(底部 RadioGroup)：
 *   报告 / 应用 / 校圈 / 我的，RadioButton 文字 12fp(px_to_sp_24)、
 *   选中色 ybg_blue #18B4ED、未选中 common_color_3 #999999、bg main_bg、paddingBottom 2vp(px4/2)。
 */
@Entry
@Component
struct Index {
  @State isReady: boolean = false;
  @State isLogged: boolean = false;
  @State currentTabIndex: number = 0;

  aboutToAppear(): void {
    // 启动即恢复持久化会话（UC/aesKey/sessionKey），业务请求免重新协商
    LoginSession.restoreSession();
    PreferencesUtil.getBoolean(Constants.KEY_IS_LOGIN, false)
      .then((logged: boolean) => {
        this.isLogged = logged;
        this.isReady = true;
        if (!logged) {
          router.replaceUrl({ url: 'pages/LoginPage' });
        }
      })
      .catch(() => {
        this.isReady = true;
        this.isLogged = false;
        router.replaceUrl({ url: 'pages/LoginPage' });
      });
  }

  @Builder
  bottomTab(iconNormal: Resource, iconChecked: Resource, label: string | Resource, index: number) {
    if (this.currentTabIndex === index) {
      Column() {
        Image(iconChecked)
          .width(24)
          .height(24)
        Text(label)
          .fontSize(12)
          .fontColor($r('app.color.ybg_blue'))
          .margin({ top: 2 })
      }
      .height(50)
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
      .backgroundColor($r('app.color.main_bg'))
    } else {
      Column() {
        Image(iconNormal)
          .width(24)
          .height(24)
        Text(label)
          .fontSize(12)
          .fontColor($r('app.color.common_color_3'))
          .margin({ top: 2 })
      }
      .height(50)
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
      .backgroundColor($r('app.color.main_bg'))
    }
  }

  build() {
    Column() {
      if (this.isReady && this.isLogged) {
        Tabs({ barPosition: BarPosition.End }) {
          TabContent() {
            ReportTab()
          }
          .tabBar(this.bottomTab($r('app.media.report'), $r('app.media.report_select'),
            $r('app.string.report_noun'), 0))
          TabContent() {
            AppsTab()
          }
          .tabBar(this.bottomTab($r('app.media.application'), $r('app.media.application_select'),
            $r('app.string.app_label'), 1))
          TabContent() {
            SocialTab()
          }
          .tabBar(this.bottomTab($r('app.media.schoolcircle'), $r('app.media.schoolcircle_select'),
            $r('app.string.school_community'), 2))
          TabContent() {
            MineTab()
          }
          .tabBar(this.bottomTab($r('app.media.mine'), $r('app.media.mine_select'),
            $r('app.string.my'), 3))
        }
        .scrollable(true)
        .barMode(BarMode.Fixed)
        .onChange((index: number) => {
          this.currentTabIndex = index;
        })
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.main_bg'))
  }
}



