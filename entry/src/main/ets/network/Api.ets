/**
 * API 端点常量 — 提取自反编译 smali（dex2_smali / dex3_smali，com.lysoft.android.*）。
 * 域名见 Constants.SOCKET_HOST（https://portal.ly-sky.com）。
 * 真实端点来源：
 *   - module/main/g/g.smali、h.smali：新闻 / 待办（/ly-pd-mb/...，POST JSON）
 *   - module/b/g/g.smali:279：登录（/mobileapi_ydxy/open/auth/login，LoginSumbitEntity）
 *   - lyyd/timetable/a.smali + c.smali（ScheduleFactory/AuditCourseFactory）：课表 /mobileapi/api/schedule/<action>
 *   - lyyd/supervise/a.smali + supervise/c/a.smali（SuperviseFactory）：督导 /mobileapi/api/superviseListen/<action>
 * 成绩/考试/考勤/通讯录/会议/督导明细等在原安卓 App 中为 H5 路由或插件 dex（不可恢复），
 * 未提取到 REST 常量，按 /ly-pd-mb/<module>/api/... 模式推断，失败时回退离线数据。
 */
export class Api {
  // ===== 从 smali 提取的真实端点 =====
  static readonly LOGIN: string = '/mobileapi_ydxy/open/auth/login';
  static readonly USER_PROFILE: string = '/mobileapi/campus/user/getUserProfile';
  static readonly TODO_LIST: string = '/ly-pd-mb/todo/api/todo/client/list';
  static readonly TODO_TAB_COUNT: string = '/ly-pd-mb/todo/api/todo/client/getTabCount';
  static readonly TODO_SET_READ: string = '/ly-pd-mb/todo/api/todo/client/setTodoRead';
  static readonly NEWS_LIST: string = '/ly-pd-mb/information/api/information/listFromPortal';
  static readonly NEWS_DETAIL: string = '/ly-pd-mb/information/api/information/detailFromPortal';
  static readonly NEWS_SET_READ: string = '/ly-pd-mb/information/api/information/setRead';
  static readonly TODO_CONFIG: string = '/mobileapi_ydxy/api/homepageModule/getUnifiedTodoConfig';
  static readonly INFORMATION_MK_CONFIG: string = '/mobileapi_ydxy/api/homepageModule/getInfomationMKConfig';
  // 课表（ScheduleFactory：a()="api"、b()="schedule" → /mobileapi/api/schedule/<action>）
  static readonly SCHEDULE_LIST: string = '/mobileapi/api/schedule/searchSchedule';
  static readonly SCHEDULE_MONTH: string = '/mobileapi/api/schedule/getListByMonth';
  static readonly SCHEDULE_GRADE_LIST: string = '/mobileapi/api/schedule/getGradeList';
  // 督导（SuperviseFactory：a()="api"、b()="superviseListen" → /mobileapi/api/superviseListen/<action>）
  static readonly SUPERVISE_USER_COURSE: string = '/mobileapi/api/superviseListen/getUserCourseList';
  static readonly SUPERVISE_NOT_LISTENING: string = '/mobileapi/api/superviseListen/getNotListening';
  static readonly SUPERVISE_STALE_LISTENING: string = '/mobileapi/api/superviseListen/getStaleListening';
  static readonly SUPERVISE_DEPARTMENT: string = '/mobileapi/api/superviseListen/getDepartmentList';

  // ===== 未在 dex 中提取到（推断路径，离线降级兜底） =====
  static readonly USER_INFO: string = '/ly-pd-mb/user/api/user/info';
  static readonly CONTACT_LIST: string = '/ly-pd-mb/contact/api/contact/list';
  static readonly MEETING_LIST: string = '/ly-pd-mb/meeting/api/meeting/main';
  static readonly MEETING_DETAIL: string = '/ly-pd-mb/meeting/api/meeting/detail';
  static readonly SCORE_LIST: string = '/ly-pd-mb/score/api/score/list';
  static readonly SCORE_DETAIL: string = '/ly-pd-mb/score/api/score/detail';
  static readonly SCORE_COMMENTS: string = '/ly-pd-mb/score/api/score/comments';
  static readonly EXAM_LIST: string = '/ly-pd-mb/exam/api/exam/list';
  static readonly ATTENDANCE_LIST: string = '/ly-pd-mb/attendance/api/attendance/list';
}
