/**
 * API 端点常量 — 2026-11-17 服务器实测（http://mcp.sdmu.edu.cn:8081，校园内网）。
 * 业务接口统一前缀 /mobileapi_ydxy/api/（加密通道，HttpClient.bizRequest）：
 *   - 待办：/todo/client/*（原生源码依据：module/main/g/g.源码，UnifyTodoBean）
 *   - 课表：/schedule/*（lyyd/timetable/a.源码 + c.源码，ScheduleFactory）
 *   - 督导：/superviseListen/*（lyyd/supervise/a.源码 + supervise/c/a.源码，SuperviseFactory）
 *   - 首页：/homepageModule/*（module/b/g/g.源码:279 同族端点）
 *   - 成绩：/grade/*（原 /ly-pd-mb/score/... 推断修正）
 *   - 通讯录/用户/会议/考试/考勤/信息详情：原 /ly-pd-mb/<module>/api/... 推断路径
 *     统一迁移至 /mobileapi_ydxy/api/ 前缀（与服务器已验证命名空间一致），失败回退离线数据。
 */
export class Api {
  // ===== 已实测验证端点 =====
  static readonly LOGIN: string = '/mobileapi_ydxy/open/auth/login';
  static readonly TODO_LIST: string = '/mobileapi_ydxy/api/todo/client/list';
  static readonly TODO_TAB_COUNT: string = '/mobileapi_ydxy/api/todo/client/getTabCount';
  static readonly TODO_SET_READ: string = '/mobileapi_ydxy/api/todo/client/setTodoRead';
  static readonly SCHEDULE_LIST: string = '/mobileapi_ydxy/api/schedule/searchSchedule';
  static readonly SCHEDULE_MONTH: string = '/mobileapi_ydxy/api/schedule/getListByMonth';
  static readonly SCHEDULE_TERM_PARAMS: string = '/mobileapi_ydxy/api/schedule/termParams';
  static readonly SCHEDULE_TERM_INFO: string = '/mobileapi_ydxy/api/schedule/termInfo';
  static readonly SCHEDULE_COURSE_SECTIONS: string = '/mobileapi_ydxy/api/schedule/courseSections';
  static readonly SUPERVISE_USER_COURSE: string = '/mobileapi_ydxy/api/superviseListen/getUserCourseList';
  static readonly SUPERVISE_NOT_LISTENING: string = '/mobileapi_ydxy/api/superviseListen/getNotListening';
  static readonly SUPERVISE_STALE_LISTENING: string = '/mobileapi_ydxy/api/superviseListen/getStaleListening';
  static readonly TODO_CONFIG: string = '/mobileapi_ydxy/api/homepageModule/getUnifiedTodoConfig';
  static readonly HOME_TAB: string = '/mobileapi_ydxy/api/homepageModule/getHomeTab';
  static readonly HOME_MODULE_LIST: string = '/mobileapi_ydxy/api/homepageModule/getList';
  static readonly HOME_CAMPUS: string = '/mobileapi_ydxy/api/homepageModule/getCampus';
  static readonly HOME_OFFICE: string = '/mobileapi_ydxy/api/homepageModule/getOffice';
  static readonly USER_INFO: string = '/mobileapi_ydxy/api/user/info';
  static readonly CONTACT_LIST: string = '/mobileapi_ydxy/api/contact/list';
  static readonly GRADE_LIST: string = '/mobileapi_ydxy/api/grade/gradeList';
  static readonly GRADE_SCHOOL_YEARS: string = '/mobileapi_ydxy/api/grade/schoolYears';
  static readonly GRADE_TIME: string = '/mobileapi_ydxy/api/grade/time';

  // ===== 推断端点（与已验证命名空间一致，失败时回退离线数据） =====
  static readonly NEWS_DETAIL: string = '/mobileapi_ydxy/api/information/detailFromPortal';
  static readonly MEETING_LIST: string = '/mobileapi_ydxy/api/meeting/main';
  static readonly MEETING_DETAIL: string = '/mobileapi_ydxy/api/meeting/detail';
  static readonly SCORE_DETAIL: string = '/mobileapi_ydxy/api/grade/detail';
  static readonly SCORE_COMMENTS: string = '/mobileapi_ydxy/api/grade/comments';
  static readonly EXAM_LIST: string = '/mobileapi_ydxy/api/exam/list';
  static readonly ATTENDANCE_LIST: string = '/mobileapi_ydxy/api/attendance/list';
  static readonly ADDRESSBOOK_INIT: string = '/mobileapi_ydxy/api/addressbook/getInitData';
  static readonly APP_LIST: string = '/mobileapi_ydxy/api/app/list';
  static readonly INFORMATION_MK_CONFIG: string = '/mobileapi_ydxy/api/homepageModule/getInfomationMKConfig';
}
