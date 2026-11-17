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
  static readonly TODO_LIST: string = '/mobileapi_ydxy/api/homepageModule/getList'  // 实测：统一待办走主页模块getList;
  static readonly TODO_TAB_COUNT: string = '/mobileapi_ydxy/api/todo/client/getTabCount';
  static readonly TODO_SET_READ: string = '/mobileapi_ydxy/api/todo/client/setTodoRead';
  static readonly SCHEDULE_LIST: string = '/mobileapi_ydxy/api/schedule/scheduleOfTerm'  // 实测：课表按学期;
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
    // 源码实证：PersonalDetailNewActivity → MobileCampusUserInfoModel(c/h/b/a.R) →
  // c/h/a.java: d.c() + "/" + mobileapi_ydxy + "/api/user/" + "getUserInfo"
  static readonly USER_INFO: string = '/mobileapi_ydxy/api/user/getUserInfo';
  // 源码实证：ScoreModel.java(score/c/a) + ScoreFactory.java(score/a)：a()="api" b()="avgCheck" c()="mobileapi_ydxy"
  static readonly SCORE_SEMESTER: string = '/mobileapi_ydxy/api/avgCheck/getSemester';
  static readonly SCORE_HAS_SUBJECT: string = '/mobileapi_ydxy/api/avgCheck/hasSubject';
  static readonly SCORE_SUB_SCORE: string = '/mobileapi_ydxy/api/avgCheck/getSubScore';

static readonly USER_PLACE_PERMISSION: string = '/mobileapi_ydxy/api/userplace/findOpenPermission'  // 实测路径;
  static readonly CONTACT_LIST: string = '/mobileapi_ydxy/api/addressbook/getInitData'  // 实测：通讯录初始化;
  static readonly GRADE_LIST: string = '/mobileapi_ydxy/api/grade/gradeList';
  static readonly GRADE_SCHOOL_YEARS: string = '/mobileapi_ydxy/api/grade/schoolYears';
  static readonly GRADE_TIME: string = '/mobileapi_ydxy/api/grade/time';

  // ===== 推断端点（与已验证命名空间一致，失败时回退离线数据） =====
  static readonly NEWS_DETAIL: string = '/mobileapi_ydxy/api/information/detailFromPortal';
  static readonly MEETING_LIST: string = '/mobileapi_ydxy/api/meeting/canCreateMeeting'  // 实测路径;
  static readonly MEETING_DETAIL: string = '/mobileapi_ydxy/api/meeting/detail';
  static readonly SCORE_DETAIL: string = '/mobileapi_ydxy/api/grade/detail';
  static readonly SCORE_COMMENTS: string = '/mobileapi_ydxy/api/grade/comments';
  static readonly EXAM_LIST: string = '/mobileapi_ydxy/api/grade/time'  // 实测：考试时间来源;
  static readonly ATTENDANCE_LIST: string = '/mobileapi_ydxy/api/messageShow/getDateMessage'  // 实测：日期消息;
  static readonly ADDRESSBOOK_INIT: string = '/mobileapi_ydxy/api/addressbook/getInitData';
  static readonly APP_LIST: string = '/mobileapi_ydxy/api/app/list';
  static readonly INFORMATION_MK_CONFIG: string = '/mobileapi_ydxy/api/homepageModule/getInfomationMKConfig';

  // ===== T2 contact-worker 追加：通讯录模块端点 =====
  // 源码依据：contact/a.java ContactFactory（a()="api" b()="addressbook" c()=R.string.mobile_api="mobileapi_ydxy"）
  //   g(name) = /mobileapi_ydxy/api/addressbook/<name>；h(a,b) = /mobileapi_ydxy/api/<a>/<b>
  //   （contact/e/a.java ContactModel 逐行还原）
  static readonly CONTACT_STUDENT_INIT: string = '/mobileapi_ydxy/api/addressbook/getStudentInitData'  // ContactModel.Z0 学生初始化;
  static readonly CONTACT_DEL_TOP: string = '/mobileapi_ydxy/api/addressbook/delTopContact'  // ContactModel.U0 {gh} 移除常用联系人;
  static readonly CONTACT_ADD_TOP: string = '/mobileapi_ydxy/api/addressbook/addTopContact'  // ContactModel.T0 {scyhid,type} 拨号记常用;
  // 子页端点还原备用（部门/班级/搜索/详情页 worker 使用）：
  //   getAddressBook{bmdm} / getStudentAddressBook{bmdm} / getClassAddressbook{bjid} /
  //   searchAddressBook{pageNum,pageSize,keyword} / searchAddressBookForStu{同左} /
  //   userMessage/searchUser{searchType,pageNum,pageSize,keyword} / userMessage/userId{gh,searchType} /
  //   hideRole{gh} / openRole{gh}

  // ===== T3 misc-worker 追加：修改密码端点（源码实证 module/c/h/a.java f16169a）=====
  // c/h/a.java: d.c() + "/" + mobileapi_ydxy + "/api/user/" + "changePasswByOldPassw"
  // 与 USER_INFO 同前缀（/api/user/ 命名空间已实测打通）
  static readonly CHANGE_PASSW_BY_OLD: string = '/mobileapi_ydxy/api/user/changePasswByOldPassw';
  // MyPageFragment.c2()：点击"修改密码"先调 getChangePasswUrlFromSchool
  // → {type:"0"原生表单|"1"确认弹窗|"2"H5, lyyd3_change_password_fromSchool}
  static readonly GET_CHANGE_PASSW_URL: string = '/mobileapi_ydxy/api/user/getChangePasswUrlFromSchool';

  // ===== T3 misc-worker 追加：意见反馈端点（源码实证 FeedbackFactory.java d(ServerType.SCHOOL)）=====
  // URL = feedbackUrl(SystemSwitch.mySetup.feedbackUrl 服务器下发，默认 ydxy_url_release
  // = https://ydxy.ly-sky.com:8098) + "/appstores/open/feedback/" + path
  // 学校内网部署无下发开关时回退默认厂商地址；路径结构忠实源码。
  static readonly FEEDBACK_HOST_DEFAULT: string = 'https://ydxy.ly-sky.com:8098';
  static readonly FEEDBACK_TYPES: string = '/appstores/open/feedback/types';
  static readonly FEEDBACK_ANNOUNCEMENT: string = '/appstores/open/feedback/announcement';
  static readonly FEEDBACK_SUBMIT: string = '/appstores/open/feedback/submit/ciphertext';
  static readonly FEEDBACK_RECORDS: string = '/appstores/open/feedback/records/ciphertext';
  static readonly FEEDBACK_DETAIL: string = '/appstores/open/feedback/getFeedbackDetail/ciphertext';
  // 源码 FeedbackModel.java 反编译原文常量 "VmxNbUkzTkRBdE5UWmpNaQ=="（BaseSecretUtil.i 加密 key，
  // z.a() 先 Base64 解码一次得到 16 字节 AES-128 key；提交/记录/详情 data 字段用）
  static readonly FEEDBACK_ENCRYPT_KEY_B64: string = 'VmxNbUkzTkRBdE5UWmpNaQ==';

  // ===== [TodoPage worker] OA 待办端点（TodoFragment/TodoMainActivity 源码级） =====
  // 源码 TodoFactory：a()="api" b()="java/todoitem" c()="mobileapi_ydxy" ServerType.SCHOOL
  //   → d.d() + "/mobileapi_ydxy/api/java/todoitem/<name>"（netconstant/a.f 拼接公式）
  // 2026-11-17 服务器实测（sdmu_decompile/temp/sdmu_todo_probe.py、probe2.py）：
  //   tab/newTab/list 均 code=0；list 参数必须放加密 data= 内：
  //   {pageSize:"10"(AgooConstants.ACK_REMOVE_PACKAGE), pageNum:N, rule:<TodoTab.BPM_GZ>}
  //   参数名 rule ← TodoModel.f1 里 com.heytap.mcssdk.constant.b.p = "rule"；
  //   明文 query 传参会返回 0001 系统异常（lead 探针失败根因）。
  //   实测五 rule：db=R_S017_B002 yb=R_S017_B003 dy=R_S017_B004 yy=R_S017_B067 jb=R_S017_B034，
  //   返回 {"rows":[],"total":"0"}（TodoListBean）。
  static readonly OA_TODO_TAB: string = '/mobileapi_ydxy/api/java/todoitem/tab';
  static readonly OA_TODO_NEW_TAB: string = '/mobileapi_ydxy/api/java/todoitem/newTab';
  static readonly OA_TODO_LIST: string = '/mobileapi_ydxy/api/java/todoitem/list';
  static readonly OA_TODO_ADD_FOLLOWS: string = '/mobileapi_ydxy/api/java/todoitem/addFollows';
  static readonly OA_TODO_DELETE_FOLLOWS: string = '/mobileapi_ydxy/api/java/todoitem/deleteFollows';
  static readonly OA_TODO_MESSAGES_CHANNEL: string = '/mobileapi_ydxy/api/java/todoitem/messagesChannel';

  // ===== [E2 message worker] 消息模块端点（MessageListActivity/MessageFragment 源码级翻译） =====
  // 源码 MessageFactory（module/main/e.java）：a()="api" b()="messageShow" c()="mobileapi_ydxy"
  //   ServerType.SCHOOL → d.d() + "/mobileapi_ydxy/api/messageShow/<name>"（netconstant/a.f 拼接公式）。
  // 命名空间已实测验证（本表 ATTENDANCE_LIST 同 URL 注释"实测：日期消息"）。
  // 方法还原（HttpRequestParamsBuilderUtil e.java）：
  //   e.b(path)=GET 参数进加密 data=（f13171d map）；e.d(path,json)=POST_CONTENT body=json 加密。
  //   getDateMessage=X0(e.d) → POST body {stateCode, page}；delete=U0(e.b) → GET {xlh, isEmc?}；
  //   updateState=a1(e.b) → GET {xlh, batchId, isEmc?}；batchdelete=T0(e.d) → POST {xlhs:JSON数组串}；
  //   alldelete=V0(e.d) → POST {stateCode}；allUpdateState=Y0(e.b 无参数) → GET {}。
  // stateCode：MessageFragment m（1=未读 2=已读 3=全部）；page：RefreshFragment.g。
  static readonly MESSAGE_GET_DATE_MESSAGE: string = '/mobileapi_ydxy/api/messageShow/getDateMessage';
  static readonly MESSAGE_DELETE: string = '/mobileapi_ydxy/api/messageShow/delete';
  static readonly MESSAGE_UPDATE_STATE: string = '/mobileapi_ydxy/api/messageShow/updateState';
  static readonly MESSAGE_BATCH_DELETE: string = '/mobileapi_ydxy/api/messageShow/batchdelete';
  static readonly MESSAGE_ALL_DELETE: string = '/mobileapi_ydxy/api/messageShow/alldelete';
  static readonly MESSAGE_ALL_UPDATE_STATE: string = '/mobileapi_ydxy/api/messageShow/allUpdateState';
  // 源码 MessageDetailFactory（module/main/d.java）：a()="open" b()="" → /mobileapi_ydxy/open/EmcMessageContent
  // MessageDetailModel.T0(e.b)：GET {magId:xlh, channelCode}，j=false（响应 data 明文 String）。
  // EmcMessageDetailActivity CONTENT 为空时拉取（详情页 worker 使用，此处一并落锚）。
  static readonly EMC_MESSAGE_CONTENT: string = '/mobileapi_ydxy/open/EmcMessageContent';

  // ===== [E1 news worker] 新闻页 WebView 加载（NewsFragment.java 源码级） =====
  // 源码 AppsFactory(c/a/c/a/a.java)：f12800b="lapp/springboard"，a()="api"，b()=null，
  //   c()=R.string.mobile_api="mobileapi_ydxy"；g(str)=d(ServerType.SCHOOL,str)
  //   → netconstant/a.f 拼接公式 = d.d()(SCHOOL 服务器) + "/mobileapi_ydxy" + "/api" + "/lapp/springboard"
  static readonly LAPP_SPRINGBOARD: string = '/mobileapi_ydxy/api/lapp/springboard';
  // 源码 MainActivity.f1():1391-1393 实证：AppBean.setYYID("bodaNews") → NewsFragment.h2(json,false)
  static readonly NEWS_YYID: string = 'bodaNews';

  // ===== [E3 meeting worker] 会议模块端点（MeetingActivity/MeetingMainActivity 源码级） =====
  // 源码 meeting/a.java MeetingFactory：a()="api" b()="meeting" c()=R.string.mobile_api="mobileapi_ydxy"
  //   g(name) = AbstractHttpUrlFactory.e(ServerType.SCHOOL,...) = d.d()(SchoolEntityUtils serverUrl)
  //             + "/" + mobileapi_ydxy + "/" + "api" + "/" + "meeting" + "/" + name
  // 源码 meeting/b.java ScheduleFactory（周程 tab 的 ScheduleModel 用）：a()="api" b()="schedule"
  //   → /mobileapi_ydxy/api/schedule/<name>（与已实测课表命名空间同源）
  // 请求形态（源码 netutil/e.java HttpRequestParamsBuilderUtil）：
  //   e.b(path)=GET（参数进 f13171d → data= 加密）；e.d(path,json)=POST_CONTENT（body 加密）
  static readonly MEETING_GET_MEET_TAB: string = '/mobileapi_ydxy/api/meeting/getMeetTab'  // MeetingModel.d1：GET 无参 → MeetingTab{myMeeting,weekplan};
  static readonly MEETING_GET_JOIN_LIST: string = '/mobileapi_ydxy/api/meeting/getJoinList'  // MeetingModel.b1：GET 无参 → JoinList[];
  static readonly MEETING_GET_PAST_LIST: string = '/mobileapi_ydxy/api/meeting/getPastList'  // MeetingModel.f1：GET {currentPage,pageSize:"20"} → JoinList.DATABean[];
  static readonly MEETING_GET_WEEK_PLAN: string = '/mobileapi_ydxy/api/meeting/getWeekPlan'  // MeetingModel.h1：GET {week} → WeekPlan[];
  static readonly SCHEDULE_GET_CURRENT_OR_WEEK: string = '/mobileapi_ydxy/api/schedule/getCurrentOrWeek'  // ScheduleModel.T0：POST {} → CurrentDay{date,week,xqj};
  static readonly SCHEDULE_TERM_INFO_FOR_TEACHER: string = '/mobileapi_ydxy/api/schedule/termInfoForTeacher'  // ScheduleModel.U0：GET 无参 → TermParamsEntity;

  // ===== [E4 attendance worker] 考勤模块端点（AttendanceFactory.java 源码级） =====
  // 源码 c/e/a/a/a/a.java AttendanceFactory：a()="api" b()="attendanceByMonth"
  //   c()=R.string.mobile_api="mobileapi_ydxy"（HttpRequestPath1_Module.f12863a），ServerType.SCHOOL
  //   AbstractHttpUrlFactory.f 拼接 = 学校服务器 + "/mobileapi_ydxy" + "/api" + "/attendanceByMonth" + "/" + name
  // 源码 c/e/a/a/a/b/a.java AttendanceModel：
  //   W0→isBoss（e.b 纯 GET 无参）；V0→index{month:"yyyyMM"}；T0→bossIndex{month:"yyyy-MM"}；
  //   U0→detail{month,id}（AttendancePersonalActivity 详情页用）
  static readonly ATTENDANCE_IS_BOSS: string = '/mobileapi_ydxy/api/attendanceByMonth/isBoss';
  static readonly ATTENDANCE_INDEX: string = '/mobileapi_ydxy/api/attendanceByMonth/index';
  static readonly ATTENDANCE_BOSS_INDEX: string = '/mobileapi_ydxy/api/attendanceByMonth/bossIndex';
  static readonly ATTENDANCE_DETAIL: string = '/mobileapi_ydxy/api/attendanceByMonth/detail';
}
