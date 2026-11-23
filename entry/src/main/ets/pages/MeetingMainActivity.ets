import { router } from '@kit.ArkUI';
import { ApiService } from '../network/ApiService';
import { BusinessError } from '@kit.BasicServicesKit';

/**
 * 会议主页（转发壳）— MeetingMainActivity.java 源码关系核对结论（[W18 meeting-remain]）
 * 【APK 结构】MeetingActivity.java(33行) f1() → g2(this, a.Z=null) → RouteConstant.Z =
 *   R.string.mobile_campus_meeting_main = "/meeting/main" → MeetingMainActivity
 *   （TabLayout + ViewPager + getMeetTab 开关 + MeetingArrangementFragment/MeetingWeekPlanFragment）。
 *   即 MeetingMainActivity 是会议主列表的实体 Activity。
 * 【HAP 对应】实体已由 E3 完整源码级翻译进 MeetingPage.ets（注释自证：本页 = MeetingActivity
 *   转发目标 + MeetingMainActivity + 两 Fragment 的完整翻译，getMeetTab/getJoinList/getPastList/
 *   getCurrentOrWeek/termInfoForTeacher/getWeekPlan 全接）。MeetingMainActivity.ets 原占位
 *   "页面开发中"与本实体重复且无调用方（宫格 CampusAppFragmentPage / Index 深链表全部指向
 *   pages/MeetingPage）。
 * 【本页处置】按"同一源码实现不重复翻译"原则，本页作为路由壳等价于 APK MeetingActivity 壳的
 *   转发语义：进入即 replaceUrl 到 pages/MeetingPage（实体页），不渲染任何编造内容。
 *   若后续有路由指向本页（如外部深链），最终渲染与 MeetingPage 完全一致。
 */
@Entry
@Component
struct MeetingMainActivity {
  aboutToAppear(): void {
    try {
      router.replaceUrl({ url: 'pages/MeetingPage' }).catch((error: BusinessError) => {
        ApiService.logError('MeetingMainActivity redirect fail: ' + error.message);
      });
    } catch (error) {
      const err = error as BusinessError;
      ApiService.logError('MeetingMainActivity redirect throw: ' + err.message);
    }
  }

  build() {
    // 转发壳：aboutToAppear 即重定向，不渲染会议内容（实体见 MeetingPage）
    Column()
      .width('100%')
      .height('100%')
      .backgroundColor($r('app.color.main_bg'))
      .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
  }
}
