/**
 * API 端点常量 — 提取自反编译 smali（com.lysoft.android.report.mobile_campus.module.main.g.g / h）。
 * 域名见 Constants.SOCKET_HOST（https://portal.ly-sky.com）。
 * 说明：通讯录/会议/成绩/课表等模块在原安卓 App 中为 H5 路由（/contact/*、/meeting/* 等），
 * 未在可恢复的 dex 中提取到 REST 常量，此处按 /ly-pd-mb/<module>/api/... 模式推断，失败时回退离线数据。
 */
export class Api {
  // ===== 从 smali 提取的真实端点 =====
  static readonly TODO_LIST: string = '/ly-pd-mb/todo/api/todo/client/list';
  static readonly TODO_TAB_COUNT: string = '/ly-pd-mb/todo/api/todo/client/getTabCount';
  static readonly TODO_SET_READ: string = '/ly-pd-mb/todo/api/todo/client/setTodoRead';
  static readonly NEWS_LIST: string = '/ly-pd-mb/information/api/information/listFromPortal';
  static readonly NEWS_DETAIL: string = '/ly-pd-mb/information/api/information/detailFromPortal';
  static readonly NEWS_SET_READ: string = '/ly-pd-mb/information/api/information/setRead';
  static readonly TODO_CONFIG: string = '/mobileapi_ydxy/api/homepageModule/getUnifiedTodoConfig';
  static readonly INFORMATION_MK_CONFIG: string = '/mobileapi_ydxy/api/homepageModule/getInfomationMKConfig';

  // ===== 未在 dex 中提取到（推断路径，离线降级兜底） =====
  static readonly LOGIN: string = '/ly-pd-mb/user/api/user/login';
  static readonly USER_INFO: string = '/ly-pd-mb/user/api/user/info';
  static readonly CONTACT_LIST: string = '/ly-pd-mb/contact/api/contact/list';
  static readonly MEETING_LIST: string = '/ly-pd-mb/meeting/api/meeting/main';
  static readonly MEETING_DETAIL: string = '/ly-pd-mb/meeting/api/meeting/detail';
  static readonly SCHEDULE_LIST: string = '/ly-pd-mb/schedule/api/schedule/list';
  static readonly SCORE_LIST: string = '/ly-pd-mb/score/api/score/list';
  static readonly EXAM_LIST: string = '/ly-pd-mb/exam/api/exam/list';
  static readonly ATTENDANCE_LIST: string = '/ly-pd-mb/attendance/api/attendance/list';
}
