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

  // ===== [W10 timetable-series] 课表系列 3 页端点 =====
  // 源码 schedule/a.java ScheduleFactory + timetable/a.java AuditCourseFactory + timetable/c.java
  // TimetableFactory：均为 a()="api" b()="schedule" → /mobileapi_ydxy/api/schedule/<name>
  // 请求形态（netutil/e.java）：e.b=GET 参数进加密 data=；e.d=POST body 加密。
  //   - getClassList（GET 无参 → Classes[]{bjdm:Object,bjmc,sl:int}，TimeTableNetModel.G0）
  //   - getScheduleList（GET {xn,xq,bjmc,djz} → ScheduleOfWeekEntity[]，TimeTableNetModel.X）
  //   - addPersonalCourse（POST {kcmc,qsjsz,djj,xqj,skdd} 自定义加课 ScheduleModel.T0；
  //     POST {courseid,force} 审核加课 AuditCourseModel.C — 同名端点两形态；响应 data "1"=成功）
  //   - deletePersonalCourse（POST {jumpFromDetail,courseid} AddCourseModel.x；
  //     POST {xlh} schedule 包删除 ScheduleModel.W0 — 同名端点两形态；响应 "1"=成功）
  //   - courseDetail（GET {xlh,djz,xqj} → CourseDetailEntity，CourseDetailModel.B0）
  static readonly SCHEDULE_CLASS_LIST: string = '/mobileapi_ydxy/api/schedule/getClassList';
  static readonly SCHEDULE_GET_SCHEDULE_LIST: string = '/mobileapi_ydxy/api/schedule/getScheduleList';
  static readonly SCHEDULE_ADD_PERSONAL_COURSE: string = '/mobileapi_ydxy/api/schedule/addPersonalCourse';
  static readonly SCHEDULE_DELETE_PERSONAL_COURSE: string = '/mobileapi_ydxy/api/schedule/deletePersonalCourse';
  static readonly SCHEDULE_COURSE_DETAIL: string = '/mobileapi_ydxy/api/schedule/courseDetail';

  // ===== [W16 course-select] 蹭课链 3 页端点（timetable/a.java AuditCourseFactory
  // a()="api" b()="schedule" → /mobileapi_ydxy/api/schedule/<name>；2026-11-18 探针全实测）=====
  //   - getCkColleges（GET 无参 → AcademyEntity[]{xydm,xymc,tjcs}，ChooseAcademyModel.e0；实测 9 学院）
  //   - ckControl（GET 无参 → {searchFilterShow,timeFilterShow} "1"=开，ChooseAcademyModel.f0；实测均 1）
  //   - searchSchedule（GET 无参 → data=纯字符串 hint，ChooseAcademyModel.c/ChooseCoursePresenter.e；
  //     实测 '课程名称,老师,教室' → 搜索框 hint="请输入"+hint，SharedPreferences 键 supportSearchCourseKeyType）
  //   - getGradeList（GET 无参 → GradeEntity[]{nj,njmc}，ChooseCourseModel.c0；实测 4 年级）
  //   - getCkMajors（GET {xydm} → MajorEntity[]{zydm,zymc}，ChooseCourseModel.K；实测 7 专业）
  //   - getCollegeCourseNames（GET {pageSize:"20",pageNum,xydm[,zydm,nj]} → [{kcmc}]，
  //     ChooseCourseModel.s0；实测 9 学院全空数组 → 空态）
  //   - updateCourse（POST {xlh,kcmc,qsjsz,djj,xqj,skdd}，ScheduleModel.d1；响应 "true"=成功）
  static readonly SCHEDULE_CK_COLLEGES: string = '/mobileapi_ydxy/api/schedule/getCkColleges';
  static readonly SCHEDULE_CK_CONTROL: string = '/mobileapi_ydxy/api/schedule/ckControl';
  static readonly SCHEDULE_SEARCH_SCHEDULE: string = '/mobileapi_ydxy/api/schedule/searchSchedule';
  static readonly SCHEDULE_GRADE_LIST: string = '/mobileapi_ydxy/api/schedule/getGradeList';
  static readonly SCHEDULE_CK_MAJORS: string = '/mobileapi_ydxy/api/schedule/getCkMajors';
  static readonly SCHEDULE_COLLEGE_COURSE_NAMES: string = '/mobileapi_ydxy/api/schedule/getCollegeCourseNames';
  static readonly SCHEDULE_UPDATE_COURSE: string = '/mobileapi_ydxy/api/schedule/updateCourse';
  static readonly SUPERVISE_USER_COURSE: string = '/mobileapi_ydxy/api/superviseListen/getUserCourseList';
  static readonly SUPERVISE_NOT_LISTENING: string = '/mobileapi_ydxy/api/superviseListen/getNotListening';
  static readonly SUPERVISE_STALE_LISTENING: string = '/mobileapi_ydxy/api/superviseListen/getStaleListening';
  // [W21 supervise] 筛选学院清单 / 教师搜索 / 评价提交（SuperviseModel Y0/c1/U0；probe_w21 全实测）
  static readonly SUPERVISE_DEPARTMENT_LIST: string = '/mobileapi_ydxy/api/superviseListen/getDepartmentList';
  static readonly SUPERVISE_SEARCH_SECTOR: string = '/mobileapi_ydxy/api/superviseListen/searchSector';
  static readonly SUPERVISE_COMMENTS: string = '/mobileapi_ydxy/api/superviseListen/commentsListenCourse';
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
  // [W26 partial-finish] 源码 MainSettingActivity.N2 → YDXYAppModel.T0：
  //   e.d(f.g("configApp"), k.m({yyid, type})) → /mobileapi_ydxy/api/app/configApp（POST_CONTENT 加密通道）
  static readonly APP_CONFIG: string = '/mobileapi_ydxy/api/app/configApp';
  // [W26 partial-finish] StudyReportActivity（student_report/b.java ReportFactory a()="api" b()=null
  //   c()="mobileapi_ydxy"）g(path)=/mobileapi_ydxy/api/<path>：
  //   WebView 直载目标 gradeReport/index；DetailActivity TermInfo → gradeReport/getRecentTermInfo
  static readonly GRADE_REPORT_INDEX: string = '/mobileapi_ydxy/api/gradeReport/index';
  static readonly GRADE_REPORT_TERM: string = '/mobileapi_ydxy/api/gradeReport/getRecentTermInfo';
  // [P-B placeholder] GradeReportActvity（manifest action sdgy_gradeReport）WebView 直载目标
  //   ReportFactory.g(b.f14965a="rank/gradeReport") = /mobileapi_ydxy/api/rank/gradeReport
  //   探针实测：带免登头 200 HTML 10601B（title=绩点排行）/裸请求 code=0006 → 头必须。
  static readonly GRADE_RANK_INDEX: string = '/mobileapi_ydxy/api/rank/gradeReport';
  // GradeReportModel.a/c POST rank/gradeReport/praise|cancelPraise {broder,phb}（JS桥 ybginterface）
  static readonly GRADE_RANK_PRAISE: string = '/mobileapi_ydxy/api/rank/gradeReport/praise';
  static readonly GRADE_RANK_CANCEL_PRAISE: string = '/mobileapi_ydxy/api/rank/gradeReport/cancelPraise';
  static readonly INFORMATION_MK_CONFIG: string = '/mobileapi_ydxy/api/homepageModule/getInfomationMKConfig';

  // ===== [P-A placeholder-fix] 5 个可达占位页真实端点（源码级，probe_pa_placeholder.py 实测） =====
  // ReportFactory（student_report/b.java a()="api" b()=null c()=mobileapi_ydxy）：
  //   g(path) = /mobileapi_ydxy/api/<path>；报表页为 WebView 免登 H5 loadUrl 目标。
  // 实测（2026-11-18）：onecardReport/breakfast/getPersonal H5 HTTP 200（title 消费排行/我的主页）；
  //   libraryReport H5 HTTP 404（服务器未部署该页 → HAP 忠实呈现真实网络错误态，不编造排名）；
  //   onecard praise/cancelPraise code=0；termInfo GET code=0（xn=2026-2027 xq=1）。
  static readonly RANK_LIBRARY_REPORT: string = '/mobileapi_ydxy/api/rank/libraryReport';
  static readonly RANK_LIBRARY_PRAISE: string = '/mobileapi_ydxy/api/rank/libraryReport/praise';
  static readonly RANK_LIBRARY_CANCEL_PRAISE: string = '/mobileapi_ydxy/api/rank/libraryReport/cancelPraise';
  static readonly RANK_ONECARD_REPORT: string = '/mobileapi_ydxy/api/rank/onecardReport';
  static readonly RANK_ONECARD_PRAISE: string = '/mobileapi_ydxy/api/rank/onecardReport/praise';
  static readonly RANK_ONECARD_CANCEL_PRAISE: string = '/mobileapi_ydxy/api/rank/onecardReport/cancelPraise';
  static readonly RANK_BREAKFAST_PERSONAL: string = '/mobileapi_ydxy/api/rank/breakfast/getPersonal';
  // ChangeNickNameFactory（module/c/e.java a()="api" b()="user"）→ /mobileapi_ydxy/api/user/<name>；
  //   d.java V0/W0/X0/Y0：updateQq{qq}/updateWechat{wechat}/cleanQq{}/cleanWechat{}（实测全 code=0）。
  static readonly USER_UPDATE_QQ: string = '/mobileapi_ydxy/api/user/updateQq';
  static readonly USER_UPDATE_WECHAT: string = '/mobileapi_ydxy/api/user/updateWechat';
  static readonly USER_CLEAN_QQ: string = '/mobileapi_ydxy/api/user/cleanQq';
  static readonly USER_CLEAN_WECHAT: string = '/mobileapi_ydxy/api/user/cleanWechat';
  // SchoolSearchFactory（school/d.java a()="open" b()="schoolMap"）→ /mobileapi_ydxy/open/schoolMap/data；
  //   SchoolSearchModel.T0 bVar.j=false 明文 GET（probe 实测 code=0：AREA 1 条山东管理学院，BUBBLE 空）。
  static readonly SCHOOL_MAP_DATA: string = '/mobileapi_ydxy/open/schoolMap/data';

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

  // ===== W9 contact-series 追加：搜索/黄页/OA部门选择端点（源码级） =====
  // ContactModel.c1（contact/e/a.java）：e.b(g("searchAddressBook")) + {pageNum,pageSize,keyword}
  //   pageSize = AgooConstants.ACK_PACK_ERROR = "15"（org/android/agoo/common/AgooConstants.java:8 实测值）
  //   2026-11-17 实测：教师接口恒 0001 系统异常；学生接口 code=0 返回 SearchAddressBook[]
  static readonly CONTACT_SEARCH: string = '/mobileapi_ydxy/api/addressbook/searchAddressBook';
  static readonly CONTACT_SEARCH_STU: string = '/mobileapi_ydxy/api/addressbook/searchAddressBookForStu';
  // ContactModel.e1：h("userMessage","searchUser") → /api/userMessage/searchUser
  //   [W25 misc-b 探针勘误] netconstant.a.e(SCHOOL, c(), a(), str, str2) 拼接 = /<c>/<str2>/<str>：
  //   h(a,b)=/api/<b>/<a>（2026-11-18 实测 /api/userMessage/userInfo 200；/api/addressbook/userMessage/* 404）
  static readonly CONTACT_SEARCH_USER: string = '/mobileapi_ydxy/api/userMessage/searchUser';
  // ===== W25 misc-b 追加：班级通讯录/个人详情端点（源码级） =====
  // ContactModel.X0（contact/e/a.java）：e.b(g("getClassAddressbook")) + {bjid}，GET 加密 data 列表回调 R0
  static readonly CONTACT_CLASS_ADDRESSBOOK: string = '/mobileapi_ydxy/api/addressbook/getClassAddressbook';
  // ContactModel.f1：e.b(g(Constants.KEY_USER_ID)) + {gh}；com.taobao.accs.common.Constants.KEY_USER_ID="userInfo"（源码字面值）
  static readonly CONTACT_USER_INFO: string = '/mobileapi_ydxy/api/addressbook/userInfo';
  // ContactModel.g1：e.b(h("userMessage", Constants.KEY_USER_ID="userInfo")) + {gh,searchType}
  //   [W25 misc-b 探针勘误] h(a,b)=/api/<b>/<a> → /api/userMessage/userInfo（实测 200 title="个人信息"）
  static readonly CONTACT_USER_MESSAGE_USERID: string = '/mobileapi_ydxy/api/userMessage/userInfo';
  // ContactModel.a1/b1：e.d(g("hideRole"/"openRole"), {gh}) 加密 POST
  static readonly CONTACT_HIDE_ROLE: string = '/mobileapi_ydxy/api/addressbook/hideRole';
  static readonly CONTACT_OPEN_ROLE: string = '/mobileapi_ydxy/api/addressbook/openRole';
  // ===== W25 misc-b 追加：科研项目列表端点（源码级） =====
  // ReimburseModel.V0（reimburse/d/b.java）：e.b(ReimburseFactory.g("reimbursement"))，ReimburseFactory
  //   a()="api" b()="project"；GET 无参 → Reimbursement[]
  static readonly REIMBURSEMENT_LIST: string = '/mobileapi_ydxy/api/project/reimbursement';
  // ===== W25 misc-b 追加：图书馆阅读链端点（源码级） =====
  // MobileCampusReadingModel（reading/b/a.java）：reading/a.java Factory a()="api" b()="library"
  //   d(SCHOOL,name)=/mobileapi_ydxy/api/library/<name>；e.d=加密 POST data；e.b=GET
  // cancelCollect {COLLECTXLH} 加密 POST（详情/搜索页取消收藏）
  static readonly READING_CANCEL_COLLECT: string = '/mobileapi_ydxy/api/library/cancelCollect';
  // collectBook {SJMC,TP,CBS,ZZ,GCD,SQH,CBRQ,THM} 加密 POST（注意 body 键名=THM，值=TXM 条形码）
  static readonly READING_COLLECT_BOOK: string = '/mobileapi_ydxy/api/library/collectBook';
  // getMyCollect 裸 GET（列表回调 R0；e.b 无 query 参数）
  static readonly READING_MY_COLLECT: string = '/mobileapi_ydxy/api/library/getMyCollect';
  // searchMyCollect {startIndex,pageSize:ACK_REMOVE_PACKAGE="10",keyword} 加密 POST 列表回调 R0
  static readonly READING_SEARCH_COLLECT: string = '/mobileapi_ydxy/api/library/searchMyCollect';
  // [W28 final-b] 图书馆首页（MobileCampusReadingModel.V0：e.b 裸 GET getHomePageData 无参）
  static readonly READING_HOME_PAGE: string = '/mobileapi_ydxy/api/library/getHomePageData';
  // [W28 final-b] 历史借阅（MobileCampusReadingModel.X0：POST getReturnData {pageNum,pageSize:"10"} 加密）
  static readonly READING_RETURN_DATA: string = '/mobileapi_ydxy/api/library/getReturnData';
  // ===== W25 misc-b 追加：今日日程链端点（源码级） =====
  // ScheduleModel（schedule/c/a.java）：schedule/a.java Factory a()="api" b()="schedule"→/mobileapi_ydxy/api/schedule/*
  // getListByMonth {year_month:"yyyy-MM"} 加密 POST 列表回调 R0（ScheduleMainActivity a3()）
  static readonly SCHEDULE_LIST_BY_MONTH: string = '/mobileapi_ydxy/api/schedule/getListByMonth';
  // getDetailsSchedule {xlh} 加密 POST → ScheduleDetail
  static readonly SCHEDULE_DETAIL: string = '/mobileapi_ydxy/api/schedule/getDetailsSchedule';
  // deleteSchedule {xlh} 加密 POST（data="1"=成功）
  static readonly SCHEDULE_DELETE: string = '/mobileapi_ydxy/api/schedule/deleteSchedule';
  // updateSchedule {xlh,startTime,endTime,title,scheduleContent,scheduleColor,scheduleRemind,locate,remindTime}
  //   （AnalyticsConfig.RTD_START_TIME="startTime" 源码字面值；加密 POST；data="1"=成功）
  static readonly SCHEDULE_UPDATE: string = '/mobileapi_ydxy/api/schedule/updateSchedule';
  // ===== W25 misc-b 追加：校园概况端点（源码级） =====
  // SchoolIntroModel.T0（school/g/a.java）：e.b(SchoolIntroFactory.g("index")) + bVar.j=false（明文通道）；
  //   SchoolIntroFactory（school/b.java）a()="open" b()="schoolIntro" → /mobileapi_ydxy/open/schoolIntro/index；
  //   GET 无参 → Index{banner, module[{ICON,NAME,URL}]}
  //   [W25-review 修正] 原 /api/campusView/index 误引 SchoolFactory（school/a.java，仅 SchoolModel
  //   点赞/传图接口使用），SchoolIntroModel 实际引用 school.b → open/schoolIntro/index。
  static readonly SCHOOL_VIEW_INDEX: string = '/mobileapi_ydxy/open/schoolIntro/index';
  // ===== [W27 final-a] 校园风光链（SchoolModel school/g/c.java + SchoolFactory school/a.java）=====
  // W0：e.b(ServerType.SCHOOL, c()="mobileapi_ydxy", "open", b()="campusView", "TypeForPic")
  //   → /mobileapi_ydxy/open/campusView/TypeForPic（bVar.j=false → HttpClient.plainBizGet 明文 GET）
  //   参数 {type:"newest"|"hottest"|"my", userId}（登录时附 userId）→ TypeForPic[]
  static readonly CAMPUS_VIEW_TYPE_FOR_PIC: string = '/mobileapi_ydxy/open/campusView/TypeForPic';
  // T0：g("addLike") = /mobileapi_ydxy/api/campusView/addLike POST {PICID}（data "true"）
  static readonly CAMPUS_ADD_LIKE: string = '/mobileapi_ydxy/api/campusView/addLike';
  // U0：e.f(g("addMyPIC"), files) POST_MULTIPART keyName="imgs"（上传成功 data "1"）
  static readonly CAMPUS_ADD_MY_PIC: string = '/mobileapi_ydxy/api/campusView/addMyPIC';
  // V0：g("delMyPic") = /mobileapi_ydxy/api/campusView/delMyPic POST {PICID} → DeletePic{flag}
  static readonly CAMPUS_DEL_MY_PIC: string = '/mobileapi_ydxy/api/campusView/delMyPic';
  // ===== W25 misc-b 追加：易班聚合链端点（源码级） =====
  // YiBanModel（module/e/b/a.java）：e/a.java Factory a()="api" b()="yiban"→/mobileapi_ydxy/api/yiban/*
  // showData {yiban_data_type:"Ad"} 加密 POST 列表（banner）→ YDXYBannerInfo[]
  static readonly YIBAN_SHOW_DATA_AD: string = '/mobileapi_ydxy/api/yiban/showData';
  // application 加密 POST 列表（应用分组）→ YDAPPInfo[]
  static readonly YIBAN_APPLICATION: string = '/mobileapi_ydxy/api/yiban/application';
  // showData {yiban_data_type:"Toutiao"} 加密 POST 列表（头条）→ YiBanNews[]
  static readonly YIBAN_SHOW_DATA_TOUTIAO: string = '/mobileapi_ydxy/api/yiban/showData';
  // GetArticleList {page,pagesize:ACK_PACK_ERROR="15"} 加密 POST 列表（易瞄瞄）→ YiBanArticle[]
  static readonly YIBAN_ARTICLE_LIST: string = '/mobileapi_ydxy/api/yiban/GetArticleList';
  // getDetailByArticleId {news_id} 加密 POST → YiBanArticle（易瞄瞄详情）
  static readonly YIBAN_ARTICLE_DETAIL: string = '/mobileapi_ydxy/api/yiban/getDetailByArticleId';
  // ContactYellowPageModel.U0（contact/e/b.java）：e.b(g("yellowPage"))，e.b=GET
  //   ContactYellowPageFactory（contact/b.java）：a()="open" b()="addressbook"
  //   2026-11-17 实测：裸 GET（无 data 参数）code=0；带 data= 加密空对象 404 → 走 HttpClient.getNoParams
  static readonly YELLOW_PAGE: string = '/mobileapi_ydxy/open/addressbook/yellowPage';
  // ContactYellowPageModel.T0：e.b(g("getYellowByType")) + {dm}；实测 data= 加密 GET code=0
  static readonly YELLOW_BY_TYPE: string = '/mobileapi_ydxy/open/addressbook/getYellowByType';
  // SelectModel.T0（oa/b/c/a.java）：e.b(SelectFactory.g("getDepartment")) + {deptId}
  //   SelectFactory（oa/b/b.java）：a()="api" b()="select"；OA DepartmentListActivity 用 deptId=bmdm（空则"-1"）
  //   2026-11-17 实测：{deptId:"-1"} code=0 → Department{title:"组织架构(907人)", departmentList:[...]}
  static readonly OA_DEPARTMENT: string = '/mobileapi_ydxy/api/select/getDepartment';
  /** AgooConstants.ACK_PACK_ERROR（搜索 pageSize 常量，源码字面值） */
  static readonly CONTACT_SEARCH_PAGE_SIZE: string = '15';

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
  // ===== [W14 todo-series] 待办搜索/常用意见/详情端点（TodoModel.n1/d1/Y0/C 源码级） =====
  static readonly OA_TODO_SEARCH: string = '/mobileapi_ydxy/api/java/todoitem/search';
  static readonly OA_TODO_REMARK: string = '/mobileapi_ydxy/api/java/todoitem/remark';
  static readonly OA_TODO_UPDATE_OPINION: string = '/mobileapi_ydxy/api/java/todoitem/updateOpinion';
  static readonly OA_TODO_TRANSACTION_DETAILS: string = '/mobileapi_ydxy/api/java/todoitem/transactionDetails';

  // ===== [W23 oa-remain] OA 待办链剩余 8 页端点（源码级） =====
  // TodoModel（oa/c/d/a.java）+ TodoPImpl（oa/c/e/a.java）：
  //   e1→getReturnToAnyNode（e.b=GET {docUnid,currentNodeid} → ReturnToAnyNode[]{NODEID,NODENAME}，
  //      TodoProcedureActivity"回退到任意环节"弹层；2026-11-18 实测假 docUnid code=0 data=[]）
  //   U0→addOpinion（e.d POST {remark} → data "1"；处理页"添加常用意见"弹窗）
  //   W0→circulate（e.d POST {processId,docUnid,userInfos:"GH#BMDM,"拼接去尾} → CirculateReadActivity
  //      提交；实测假参 0001 系统异常=端点存活）
  //   l1→runProcess（e.d POST {docXml,actionid,processid,docUnid,nextNodeid,nextUserList,remark} →
  //      RunProcess{msg,orUnid,...}；TodoProcedureActivity 主提交；实测假参 code=0）
  static readonly OA_TODO_RETURN_TO_ANY_NODE: string = '/mobileapi_ydxy/api/java/todoitem/getReturnToAnyNode';
  static readonly OA_TODO_ADD_OPINION: string = '/mobileapi_ydxy/api/java/todoitem/addOpinion';
  static readonly OA_TODO_CIRCULATE: string = '/mobileapi_ydxy/api/java/todoitem/circulate';
  static readonly OA_TODO_RUN_PROCESS: string = '/mobileapi_ydxy/api/java/todoitem/runProcess';
  //   i1→openProcess（e.d POST {processid, docUnid} → TodoOpenProcess{currentNodeConfig,
  //      nextNodeConfig, currentNodeId}；TodoProcedureActivity 主处理页渲染数据源）
  static readonly OA_TODO_OPEN_PROCESS: string = '/mobileapi_ydxy/api/java/todoitem/openProcess';
  // SelectModel（oa/b/c/a.java）SelectFactory（oa/b/b.java api/select）：
  //   Y0→getSubDeptList {deptId,processId,userFilterNodeId}（CarbonCopyListActivity 页签-按组织架构，
  //      实测空参 code=0 title"组织架构(0人)" resultData=[]）
  //   a1→getSubRoleList {deptId}（页签-按角色，实测 1145 rows）
  //   Z0→getSubUserGroupList {groupId}（页签-人员分组，实测 0 rows）
  //   c1→searchDepartment {keyword}（TodoSearchDepartmentActivity，实测"学院"→多条 BMMC/BMDM/count）
  static readonly OA_SELECT_SUB_DEPT_LIST: string = '/mobileapi_ydxy/api/select/getSubDeptList';
  static readonly OA_SELECT_SUB_ROLE_LIST: string = '/mobileapi_ydxy/api/select/getSubRoleList';
  static readonly OA_SELECT_SUB_USER_GROUP: string = '/mobileapi_ydxy/api/select/getSubUserGroupList';
  static readonly OA_SELECT_SEARCH_DEPARTMENT: string = '/mobileapi_ydxy/api/select/searchDepartment';
  // DocFactory（oa/b/a.java api/docNum）DocNumberActivity 四列联动：
  //   U0→getDocNumCategory 无参（data={content:"[{id,text}]"}）；W0→getDocNumWord {categoryId}；
  //   V0→getDocNumSerialNo {wordId}（空时 content='{"msg":""}'）；X0→getYear 无参（[{year:2024..}]）
  static readonly OA_DOCNUM_CATEGORY: string = '/mobileapi_ydxy/api/docNum/getDocNumCategory';
  static readonly OA_DOCNUM_WORD: string = '/mobileapi_ydxy/api/docNum/getDocNumWord';
  static readonly OA_DOCNUM_SERIAL_NO: string = '/mobileapi_ydxy/api/docNum/getDocNumSerialNo';
  static readonly OA_DOCNUM_YEAR: string = '/mobileapi_ydxy/api/docNum/getYear';
  // InspectionFactory（inspection/a.java api/dormitoryCheck）InspectionModel（inspection/b/a.java）：
  //   Y0→getCheckRecordsList 无参（GET → CheckRecord[]{XLH,JCJLMC}，实测 []）
  //   b1→getLdmcList {recordXlh}（e.d POST → Ldmc[]{LDMC}，实测 []）
  //   c1→getRecordsDetail {recordXlh,ldmc}（e.d POST → RecordsDetail{hadScoreSize,datalist:[{name,data:[{QSH,RECORDDETAILXLH,TYPE}]}]}，
  //      实测 {hadScoreSize:0,datalist:[{data:[],name:"notCheckList"}]}）
  //   V0→addDormitoryCheckRecords {recordName}（e.d POST → DormitoryCheckRecords{recordXlh}，实测 code=0）
  //   d1→updateRecordName {recordName,recordXlh}；X0→deleteDormitoryCheckRecords {recordXlh}（实测 code=0）
  static readonly INSPECTION_RECORDS_LIST: string = '/mobileapi_ydxy/api/dormitoryCheck/getCheckRecordsList';
  static readonly INSPECTION_LDMC_LIST: string = '/mobileapi_ydxy/api/dormitoryCheck/getLdmcList';
  static readonly INSPECTION_RECORDS_DETAIL: string = '/mobileapi_ydxy/api/dormitoryCheck/getRecordsDetail';
  static readonly INSPECTION_ADD_RECORDS: string = '/mobileapi_ydxy/api/dormitoryCheck/addDormitoryCheckRecords';
  static readonly INSPECTION_UPDATE_RECORD_NAME: string = '/mobileapi_ydxy/api/dormitoryCheck/updateRecordName';
  static readonly INSPECTION_DELETE_RECORDS: string = '/mobileapi_ydxy/api/dormitoryCheck/deleteDormitoryCheckRecords';
  // [W27 final-a] 巡检排名（InspectionModel.a1 / InspectionPImpl.h）：
  //   POST getHadScoreList {recordXlh, ldmc} → NewHadScore[]{QSH,RANKNUM,SCORE,XLH}（实测 code=0 空表）
  static readonly INSPECTION_SCORE_LIST: string = '/mobileapi_ydxy/api/dormitoryCheck/getHadScoreList';
  // ReimburseFactory（reimburse/b.java api/project）ReimburseModel（reimburse/d/b.java）：
  //   U0→reimbursed {PROJECT_NUMBER}（e.d → Reimbursed[]{AMOUNT,PROJECT_NAME,REIMBURSE_DATE,...}；
  //      2026-11-18 实测空 PROJECT_NUMBER code=0001 → 真实错误态）
  //   W0→unreimbursed {PROJECT_NUMBER}（e.d 同形态；实测同 0001）
  static readonly PROJECT_REIMBURSED: string = '/mobileapi_ydxy/api/project/reimbursed';
  static readonly PROJECT_UNREIMBURSED: string = '/mobileapi_ydxy/api/project/unreimbursed';

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

  // ===== [W12 message-series] 通知列表/EMC 详情请求形态锚 =====
  // MainNotificationV2Activity.Y2 → h.d.i(str) → MessageModel.W0：e.d(g("getDateMessage"))=POST body {page}
  // （无 stateCode！与 MessageListActivity 的 X0 {stateCode,page} 不同源码入口，2026-11-18 实测两形态同返回）。
  // 条目点击 b3 → h.d.p → MessageModel.Z0：e.b(g("updateState"))=GET {xlh, isEmc?}（无 batchId）。
  static readonly NOTIFICATION_GET_DATE_MESSAGE: string = '/mobileapi_ydxy/api/messageShow/getDateMessage';
  static readonly NOTIFICATION_UPDATE_STATE: string = '/mobileapi_ydxy/api/messageShow/updateState';

  // ===== [W12 message-series] 校圈消息 push 链（PushModel.java c/b/c/b/b.java 源码级） =====
  // URL = netconstant/d.b() = lianyi_url_release = https://www.yibaogao.com（独立于校内域名）。
  // 通道 = 加密管道（j 默认 true：AT=AES(7字段)、UC=onlyCode、AppType=ydxy、body=AES(JSON)）+
  //   额外请求头 xxdm（PushModel 里 bVarD.f13170c.put("xxdm") → f13170c 为请求头 map，
  //   值 = 登录会话 schoolId，HAP 取 LoginSession.schoolId）。
  // 2026-11-18 实测：https SSL UNEXPECTED_EOF / http 502 —— 校园网不可达，HAP 真实空态落地。
  static readonly PUSH_HOST: string = 'https://www.yibaogao.com';
  static readonly PUSH_GET_MSG_LIST: string = '/mobileapi/campus/push/getPushMsgList';
  static readonly PUSH_HAS_READ: string = '/mobileapi/campus/push/hasRead';
  static readonly PUSH_GET_NO_READ_COUNT: string = '/mobileapi/campus/push/getNoReadCount';
  // 源码 social/d/a.java f14337c = d.d() + "/mobileapi_ydxy/api/user/getAvatarByUser"（校内域名，GET data=加密）
  static readonly SOCIAL_AVATAR_BY_USER: string = '/mobileapi_ydxy/api/user/getAvatarByUser';

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
  // [W13 meeting-series] 会议详情/公告/签到链端点（meeting/d/a.java MeetingModel 源码级）
  // 请求形态：e.b(path)=GET（参数进 f13171d → data= 加密）；e.d(path,json)=POST_CONTENT（body 加密）
  static readonly MEETING_GET_MEETING_OBJ: string = '/mobileapi_ydxy/api/meeting/getMeetingObj'  // MeetingModel.c1：GET {xlh} → MeetingObj（详情主接口）;
  static readonly MEETING_FIND_MEETING_FEEDBACK: string = '/mobileapi_ydxy/api/meeting/findMeetingFeedBack'  // MeetingModel.a1：POST {meetingId} → MeetingAnnouncement[]（公告列表/角标计数）;
  static readonly MEETING_UP_JOIN: string = '/mobileapi_ydxy/api/meeting/upJoin'  // MeetingModel.r1：POST {xlh,zt,reason}（zt=1参加/0不参加）;
  static readonly MEETING_CANCEL_MEETING: string = '/mobileapi_ydxy/api/meeting/cancelMeeting'  // MeetingModel.W0：POST {meetingXLH,cancel_remark}（发起人取消会议）;
  static readonly MEETING_ADD_MEETING_FEEDBACK: string = '/mobileapi_ydxy/api/meeting/addMeetingFeedBack'  // MeetingModel.T0：POST {meetingId,message}（发布会议公告）;
  static readonly MEETING_GET_SIGN_USER: string = '/mobileapi_ydxy/api/meeting/getSignUser'  // MeetingModel.g1：GET {hyid} → SignUser[]（已签名单）;
  static readonly MEETING_GET_NO_SIGN_USER: string = '/mobileapi_ydxy/api/meeting/getNoSignUser'  // MeetingModel.e1：GET {hyid} → SignUser[]（未签名单）;
  static readonly MEETING_SIGN: string = '/mobileapi_ydxy/api/meeting/sign'  // MeetingModel.p1：POST {hyid}（本人扫码签到）;
  static readonly MEETING_TO_SIGN: string = '/mobileapi_ydxy/api/meeting/toSign'  // MeetingModel.q1：POST {hyid,yhid}（给未签人签到）;
  static readonly MEETING_NO_SIGN: string = '/mobileapi_ydxy/api/meeting/noSign'  // MeetingModel.n1：POST {hyid,yhid}（取消已签人签到）;
  // [W18 meeting-remain] 会议链剩余页端点（MeetingWeekDetailActivity/MeetingStaffSituationActivity/
  // MeetingReportEditActivity/MeetingReportShowActivity/MeetingSelectorActivity 源码级）
  static readonly MEETING_GET_WEEK_PLAN_DETAILS: string = '/mobileapi_ydxy/api/meeting/getWeekPlanDetails'  // MeetingModel.i1：GET {xlh} → MeetingWeekDetail（周程详情，实测 code=0 全字段）;
  static readonly MEETING_ADD_MY_WEEK_PLAN: string = '/mobileapi_ydxy/api/meeting/addMyWeekPlan'  // MeetingModel.U0：POST {xlh}（添加到个人会议，实测无效 xlh code=2014）;
  static readonly MEETING_CANCEL_WEEK_PLAN: string = '/mobileapi_ydxy/api/meeting/cancelWeekPlan'  // MeetingModel.X0：POST {xlh}（取消添加，实测无效 xlh code=2004）;
  static readonly MEETING_SHOW_MEETING_REPORT: string = '/mobileapi_ydxy/api/meeting/showMeetingReport'  // MeetingModel.k1：POST_CONTENT {meetingXLH=HYID} → Report（实测无报告会议 code=0001）;
  static readonly MEETING_DEL_MEETING_REPORT: string = '/mobileapi_ydxy/api/meeting/delMeetingReport'  // MeetingModel.j1：POST {meetingXLH}（实测无效 xlh code=0 data=false）;
  static readonly MEETING_OPEN_MEETING_REPORT: string = '/mobileapi_ydxy/api/meeting/openMeetingReport'  // MeetingModel.o1：POST {meetingId,openType:"on"/"off"}（实测无效 openType code=开放会议报告给参会人员失败）;
  static readonly MEETING_SAVE_MEETING_REPORT: string = '/mobileapi_ydxy/api/meeting/saveMeetingReport'  // MeetingModel.l1：POST_MULTIPART {meetingXLH=HYID,content,PIC[]}（新建报告）;
  static readonly MEETING_UPDATE_MEETING_REPORT: string = '/mobileapi_ydxy/api/meeting/updateMeetingReport'  // MeetingModel.m1：POST_MULTIPART {detelePicXLH,meetingXLH,content,oldPicXLH,PIC[]}（更新报告）;
  static readonly SELECT_MEETING: string = '/mobileapi_ydxy/api/select/meeting'  // SelectModel.b1：GET 无参 → MeetingSelector[] 树（实测 code=0：校区→楼栋→房间递归 data）;
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

  // ===== [W4 sms-login] 手机号登录端点（源码 IdentifyCodeModel.java = module/b/g/f.java，Python 全链路实测通） =====
  // 1) POST /open/auth/checkLoginPhone {phoneNum} → {timeFrequency:90, canSendSms:true}
  // 2) POST /open/auth/SendSms {phoneNum} → code=0（真实下发短信到用户手机）
  // 3) POST /open/auth/loginBySms body=AES(LoginSumbitEntity{userId:"",passw:"",schoolId:"SDGY",
  //    phoneNum,checkCode,clientVersion,serverApiVersion,androidClientVersionCode,deviceModel,
  //    deviceType,deviceVersion,deviceId}) → UserEntity（与密码登录同结构）
  static readonly CHECK_LOGIN_PHONE: string = '/mobileapi_ydxy/open/auth/checkLoginPhone';
  static readonly SEND_SMS: string = '/mobileapi_ydxy/open/auth/SendSms';
  static readonly LOGIN_BY_SMS: string = '/mobileapi_ydxy/open/auth/loginBySms';
  /** 源码 timeFrequency 服务器下发默认 90s（checkLoginPhone 响应，异常回退值） */
  static readonly SMS_TIME_FREQUENCY: number = 90;

  // ===== [W19 workapply] OA 业务申请链 6 页端点（ApplyPImpl/ApplyModel/WorkApplyFactory 源码级） =====
  // 源码 oa/d/a.java WorkApplyFactory：a()="api" b()="java/businessApply" c()=mobileapi_ydxy
  //   ServerType.SCHOOL → netconstant/a.f 拼接 = d.d() + "/mobileapi_ydxy/api/java/businessApply/<name>"。
  // 请求形态（ApplyModel.java）：
  //   U0→processList（e.b 纯 GET 无参 → WorkApply[]{folderId,folderName,processId,processName}）
  //   V0→formConfig（e.b GET {processid} → WorkApplyDetail{formFieldConfigList,itemBasicInfoMap.bpmRequestRuleUrl}）
  //   W0→myApply（e.b GET {pageSize,pageNum} → MyApplyList{rows,total}；pageSize 字面量 "1000"）
  //   X0→screen（e.b GET {pageSize,pageNum,processid} → MyApplyList；pageSize=AgooConstants.ACK_REMOVE_PACKAGE="10"）
  //   Y0→sendBuss（e.d POST body {property,message} → String；详情页催办）
  // 2026-11-18 探针实测（temp/probe_w19_workapply.py）：processList code=0 4 流程（信访事项受理/
  //   通知公告/会议室申请/处级干部外出报备 folderId=001004002）；myApply total=0 rows=0（测试账号无
  //   OA 申请→真实空态）；screen rows=0；formConfig 11 真实字段 bpmRequestRuleUrl=
  //   'http://oa.sdmu.edu.cn//bpm/r?wf_num='。详情页复用 transactionDetails（OA_TODO_TRANSACTION_DETAILS）。
  static readonly WORKAPPLY_PROCESS_LIST: string = '/mobileapi_ydxy/api/java/businessApply/processList';
  static readonly WORKAPPLY_FORM_CONFIG: string = '/mobileapi_ydxy/api/java/businessApply/formConfig';
  static readonly WORKAPPLY_MY_APPLY: string = '/mobileapi_ydxy/api/java/businessApply/myApply';
  static readonly WORKAPPLY_SCREEN: string = '/mobileapi_ydxy/api/java/businessApply/screen';
  static readonly WORKAPPLY_SEND_BUSS: string = '/mobileapi_ydxy/api/java/businessApply/sendBuss';
  /** 源码 WorkApplyActivity.W2/X2 字面量 "1000"（myApply 分页 pageSize） */
  static readonly WORKAPPLY_MY_PAGE_SIZE: string = '1000';
  /** 源码 WorkApplyScreenActivity.L2 AgooConstants.ACK_REMOVE_PACKAGE="10"（screen pageSize） */
  static readonly WORKAPPLY_SCREEN_PAGE_SIZE: string = '10';

  // ===== [W15 score-series] 成绩链 4 页端点（StudentSearchModel/ClassmateModel/ScoreModel/HandleExamCourseModel 源码级） =====
  // 请求形态（netutil/e.java）：e.b(path)=GET（参数进加密 data=）；e.d(path,json)=POST body 加密。
  // StudentScoreFactory(score/a.java)：a()="api" b()="avgCheck" → /mobileapi_ydxy/api/avgCheck/<name>
  //   getStudentMsg=V0：GET {xh} → StudentMessage[{xn,xq,data:[{kcmc,xscj,bjpm}]}]
  //   （2026-11-18 实测：本账号学号 code=0001 系统异常 → 学生成绩单真实空态）
  static readonly SCORE_STUDENT_MSG: string = '/mobileapi_ydxy/api/avgCheck/getStudentMsg';
  // [W27 final-a] 学生名单（StudentSearchModel score/c/b.java）：
  //   T0 getClazz：GET {params}（"params" 键 = com.heytap.mcssdk.constant.b.D 字面值；值=ScoreMainFragment
  //     拼接 "xn_xq,xn_xq"）→ ClassAndId[]（教师侧接口，测试账号 0001 真实错误态）
  //   W0 getStudents：GET {bjid} → StudentEntity[]（登录态 code=0 空表）
  static readonly SCORE_GET_CLAZZ: string = '/mobileapi_ydxy/api/avgCheck/getClazz';
  static readonly SCORE_GET_STUDENTS: string = '/mobileapi_ydxy/api/avgCheck/getStudents';
  // TimetableFactory(timetable/c.java)：a()="api" b()="schedule" → /mobileapi_ydxy/api/schedule/<name>
  //   matchGateMsg=ClassmateModel.N：GET {xn,xq,dm,djz,xqj,djj} → ClassmateEntity[{xh,xm,xb,bjmc,qjlb}]
  //   （2026-11-18 实测：数据分析及可视化 98 人 / 操作系统 89 人 code=0 全通）
  static readonly SCHEDULE_MATCH_GATE_MSG: string = '/mobileapi_ydxy/api/schedule/matchGateMsg';
  //   highestScoreMsg=ClassmateModel.q0：GET {xn,xq,kcmc,zgfzscj} → ClassmateEntity[]（最高分保持者）
  //   （2026-11-18 实测：操作系统 zgfzscj=96.8 → 保持者 1 人 code=0 通）
  static readonly SCHEDULE_HIGHEST_SCORE_MSG: string = '/mobileapi_ydxy/api/schedule/highestScoreMsg';
  // ScoreFactory(student_score/a.java)：a()="api" b()="grade" → /mobileapi_ydxy/api/grade/<name>
  //   sendComment=ScoreModel.T0：POST {xn,xq,kcdm,plnr} → data "true"（发布留言）
  //   （2026-11-18 实测空参 data 解密='true'，服务器不校验内容空——HAP 侧保留源码内容空拦截）
  static readonly GRADE_SEND_COMMENT: string = '/mobileapi_ydxy/api/grade/sendComment';
  // [W27 final-a] 成绩留言列表/删除（ScoreModel student_score/b/b.java）：
  //   comments=ScoreModel.m：GET {xn,xq,kcdm,pageNum,pageSize} → CommentInfo[]（实测 code=0 空表）
  //   deleteComment=ScoreModel.Z：POST {xlh} → data "true"
  static readonly GRADE_DELETE_COMMENT: string = '/mobileapi_ydxy/api/grade/deleteComment';
  // ExaminationFactory(examination/a.java)：a()="api" b()="exam" → /mobileapi_ydxy/api/exam/<name>
  //   operatorExam=HandleExamCourseModel.u：POST {zwh,zkzh,txlx,kssj,kslx,ksdd,kmmc,jssj}
  //   （2026-11-18 实测空参 0001 系统异常——kmmc 必填语义；正常提交 data "true"）
  static readonly EXAM_OPERATOR: string = '/mobileapi_ydxy/api/exam/operatorExam';
  //   recommentList=HandleExamCourseModel.S：GET {kslx:"0"期末|"1"等级, kmmc} → RecommentListEntity[]
  //   （2026-11-18 实测 code=0 items=0 真实空）
  static readonly EXAM_RECOMMENT_LIST: string = '/mobileapi_ydxy/api/exam/recommentList';
  //   adoptExam=HandleExamCourseModel.r0：POST {kslx,kmmc,cnxlh,zwh}（采纳推荐 → data "true"）
  static readonly EXAM_ADOPT: string = '/mobileapi_ydxy/api/exam/adoptExam';
  //   opposeExam=HandleExamCourseModel.n0：POST {xlh,cz:"0"|"1"}（报错 → data "false"/"true"）
  static readonly EXAM_OPPOSE: string = '/mobileapi_ydxy/api/exam/opposeExam';
  // [W27 final-a] 考试列表链（ExaminationFactory examination/a.java a()="api" b()="exam"）：
  //   ExamModel.Y → beginExamList（GET 无参）→ ComingExamEntity[]
  //   ExamModel.z → endExamList（GET 无参）→ FinishExamEntity[]
  //   ExamModel.p0 → editExamList（GET {kslx:"0"期末|"1"等级}）→ AddExamEntity[]（实测 kslx=0 真实 6 行）
  //   deleteExam → POST {kslx,kmmc}
  static readonly EXAM_BEGIN_LIST: string = '/mobileapi_ydxy/api/exam/beginExamList';
  static readonly EXAM_END_LIST: string = '/mobileapi_ydxy/api/exam/endExamList';
  static readonly EXAM_EDIT_LIST: string = '/mobileapi_ydxy/api/exam/editExamList';
  static readonly EXAM_DELETE: string = '/mobileapi_ydxy/api/exam/deleteExam';

  // ===== [W17 profile-series] 个人资料编辑链 4 页端点（ChangeNickNameActivity/
  // MobileCampusInputEmailActivity/MobileCampusInputPhoneActivity/MobileCampusBindPhoneActivity 源码级） =====
  // Factory 拼接公式（netconstant/a.f）= 学校服务器 + "/" + mobileapi_ydxy + "/" + a() + "/" + b() + "/" + name；
  // 请求形态（netutil/e.java）：e.d(path,json)=POST_CONTENT body=AES(JSON)（全部走 HttpClient.bizRequest POST）。
  //   ChangeNickNameFactory(module/c/e.java) a()="api" b()="user" → ChangeNickNameModel.T0：
  //     POST updateNickname {nickname}（成功后另发连乙同步，见 NICKNAME_SYNC_*）
  static readonly USER_UPDATE_NICKNAME: string = '/mobileapi_ydxy/api/user/updateNickname';
  //   BindEmailFactory(module/c/c.java) a()="api" b()="bindPhone" → BindEmailModel.T0：
  //     POST saveEmail {userId, userType, email_url}
  static readonly BIND_EMAIL_SAVE: string = '/mobileapi_ydxy/api/bindPhone/saveEmail';
  //   BindPhoneFactory(module/c/d.java) a()="api" b()="bindPhone" → BindPhoneModel：
  //     T0 POST queryBindPhoneStatus {code:userId, type:userType} → PhoneStatus；
  //     U0 POST savePhone {code:userId, type:userType, phone}
  static readonly BIND_PHONE_STATUS: string = '/mobileapi_ydxy/api/bindPhone/queryBindPhoneStatus';
  static readonly BIND_PHONE_SAVE: string = '/mobileapi_ydxy/api/bindPhone/savePhone';
  //   VerifyCodeModel(baseapp/c/b/b/e/b/b.java) 直拼 Constant.a（无 Factory 中段）：
  //     d.c() + "/" + mobileapi_ydxy + "/api/common/getVercode|verifyVercode"
  //     getVercode {schoolId, userId, mobile, type(设备验证"4"/绑定"1"), [SchoolCircle]}
  //     verifyVercode {schoolId, userId, mobile, vercode, [SchoolCircle]}
  static readonly VERIFY_CODE_GET: string = '/mobileapi_ydxy/api/common/getVercode';
  static readonly VERIFY_CODE_VERIFY: string = '/mobileapi_ydxy/api/common/verifyVercode';
  //   BindFactory(module/b/a.java) a()="api" b()="user" ServerType.LIANYI（d.c()=学校服务器同域）：
  //     POST bindMobile {mobile}（设备验证流程绑定手机）
  static readonly USER_BIND_MOBILE: string = '/mobileapi_ydxy/api/user/bindMobile';
  //   BindDeviceFactory(module/c/b.java) a()="api" b()="bindDevice" → BindDeviceModel.T0：
  //     POST add {IMEI:s.g(), sbmc:s.m()=Build.MODEL}
  static readonly BIND_DEVICE_ADD: string = '/mobileapi_ydxy/api/bindDevice/add';
  //   LoginFactory(module/b/c.java) a()="open" b()=null → LoginModel.N0（InputPhone 返回退出回调 W2）：
  //     POST auth/logout {userId, userType}
  static readonly AUTH_LOGOUT_SCHOOL: string = '/mobileapi_ydxy/open/auth/logout';
  //   ChangeNickNameModel.U0：netconstant/d.b() = lianyi_url_release = https://www.yibaogao.com
  //     + /mobileapi/campus/user/updateNickname {nickname} + 请求头 xxdm（pushBizPost 通道，W12 实测不可达保留）
  static readonly NICKNAME_SYNC_HOST: string = 'https://www.yibaogao.com';
  static readonly NICKNAME_SYNC: string = '/mobileapi/campus/user/updateNickname';

  // ===== [W20 social] 校圈链 6 页端点（SocialModel social/d/b/b.java + MarketModel social/c/b/a.java +
  // FriendshipFactory friendship/a.java + PostPublicPresenter social/d/c/e.java + MarketPImpl social/c/c/b.java 源码级）=====
  // 双通道实证（源码 hasSchoolCirclePhone 分支）：
  //   true  → ServerType.LIANYI = netconstant/d.b() = https://www.yibaogao.com
  //           + /mobileapi_ydxy/api/circle|market|friendShip/<name>；e.b=GET(data=加密参数)、
  //           e.d=POST(body 加密)、e.f=POST_MULTIPART(content/type 等进表单)，均附明文请求头 xxdm。
  //           2026-11-18 复测（probe_w20_social.py [G]）：WinError 10054 / SSL UNEXPECTED_EOF ——
  //           域名校园网不可达（W12 结论一致）→ HAP 写通道真实尝试后落真实错误态，绝不编造成功。
  //   false → 校内 d.d() + /mobileapi_ydxy/api/campus/circleOpen/<name>（POST e.d 形态）。
  //           2026-11-18 实测（probe_w20_social.py [A][B][C]）：9 端点全部 HTTP200 code=0001
  //           系统异常 —— 端点/路由/协议在、数据层未启用 → 真实错误态（0001 message 透传）。
  //   校内直连例外：addviewnum=SocialModel.K0(ServerType.SCHOOL，实测 code=0 data="false")；
  //     getAvatarByUser=f14337c（实测 code=0 data=[{TX:null,USERID}]）；
  //     getUserInfo=c/b/b/b/a.f12833b（实测 code=0 全字段：userName/nickname/sex/userType/
  //     department/professionName/className/avatar/…）。
  // ---- 校内 circleOpen 读链（读帖/评论/点赞、集市详情/评论/点赞、列表） ----
  static readonly CIRCLE_OPEN_GET_CIRCLE_INFO: string = '/mobileapi_ydxy/api/campus/circleOpen/getCircleInfo';
  static readonly CIRCLE_OPEN_GET_CIRCLE_COMMENTS: string = '/mobileapi_ydxy/api/campus/circleOpen/getCircleComments';
  static readonly CIRCLE_OPEN_GET_CIRCLE_LIKES: string = '/mobileapi_ydxy/api/campus/circleOpen/getCircleLikes';
  static readonly CIRCLE_OPEN_GET_CIRCLE_LIST: string = '/mobileapi_ydxy/api/campus/circleOpen/getCircleList';
  static readonly CIRCLE_OPEN_GET_HOT_CIRCLE_LIST: string = '/mobileapi_ydxy/api/campus/circleOpen/getHotCircleList';
  static readonly CIRCLE_OPEN_GET_MARKET_INFO: string = '/mobileapi_ydxy/api/campus/circleOpen/getMarketInfo';
  static readonly CIRCLE_OPEN_GET_MARKET_COMMENTS: string = '/mobileapi_ydxy/api/campus/circleOpen/getMarketComments';
  static readonly CIRCLE_OPEN_GET_MARKET_LIKES: string = '/mobileapi_ydxy/api/campus/circleOpen/getMarketLikes';
  // [W28 review] getMarketList/serchMarketList 均 e.d POST_CONTENT（MarketModel.h1/Y0 实证）
  static readonly CIRCLE_OPEN_GET_MARKET_LIST: string = '/mobileapi_ydxy/api/campus/circleOpen/getMarketList';
  static readonly CIRCLE_OPEN_SERCH_MARKET_LIST: string = '/mobileapi_ydxy/api/campus/circleOpen/serchMarketList';
  // ---- 校内 circle/addviewnum（SocialModel.K0 实证 ServerType.SCHOOL） ----
  static readonly CIRCLE_ADDVIEWNUM: string = '/mobileapi_ydxy/api/circle/addviewnum';
  // ---- LIANYI push 域：circle（SocialModel，源码忠实；实测不可达 → 真实错误态） ----
  static readonly CIRCLE_LIANYI_PREFIX: string = '/mobileapi_ydxy/api/circle/';
  // postInfo/comments/likes=freshNewList=hotCircleList=concernCircleList=getSomeoneCircleList/
  // getCircleRecentlyPic=getUserScores 为 e.b GET(data=)；其余为 e.d POST；post 为 e.f multipart。
  static readonly CIRCLE_LIANYI_POSTINFO: string = '/mobileapi_ydxy/api/circle/postInfo';
  static readonly CIRCLE_LIANYI_COMMENTS: string = '/mobileapi_ydxy/api/circle/comments';
  static readonly CIRCLE_LIANYI_LIKES: string = '/mobileapi_ydxy/api/circle/likes';
  static readonly CIRCLE_LIANYI_LIKE_OPERATOR: string = '/mobileapi_ydxy/api/circle/likeOperator';
  static readonly CIRCLE_LIANYI_SEND_COMMENT: string = '/mobileapi_ydxy/api/circle/sendComment';
  static readonly CIRCLE_LIANYI_DELETE_COMMENT: string = '/mobileapi_ydxy/api/circle/deleteComment';
  static readonly CIRCLE_LIANYI_HIDE_COMMENT: string = '/mobileapi_ydxy/api/circle/hideComment';
  static readonly CIRCLE_LIANYI_DELETE_CIRCLE: string = '/mobileapi_ydxy/api/circle/deleteCircle';
  static readonly CIRCLE_LIANYI_HIDE_CIRCLE: string = '/mobileapi_ydxy/api/circle/hideCircle';
  static readonly CIRCLE_LIANYI_STICK_CIRCLE: string = '/mobileapi_ydxy/api/circle/stickCircle';
  static readonly CIRCLE_LIANYI_REPORT_CIRCLE: string = '/mobileapi_ydxy/api/circle/reportCircle';
  static readonly CIRCLE_LIANYI_POST: string = '/mobileapi_ydxy/api/circle/post';
  static readonly CIRCLE_LIANYI_GET_SOMEONE: string = '/mobileapi_ydxy/api/circle/getSomeoneCircleList';
  static readonly CIRCLE_LIANYI_RECENT_PIC: string = '/mobileapi_ydxy/api/circle/getCircleRecentlyPic';
  // [P-B placeholder] NewNewsActivity/Ex 数据源（SocialFactory h="freshNewList"/i="freshpapers"，ServerType.LIANYI）
  //   SocialNewsPage：hasSchoolCirclePhone=false → 校内 circleOpen/getCircleList（已有常量，实测 code=0001）；
  //   头条文章 → freshpapers；SocialNewNewsPage(Ex)：列表 → freshNewList（push 域，实测 SSL EOF 不可达）。
  static readonly CIRCLE_LIANYI_FRESH_NEW_LIST: string = '/mobileapi_ydxy/api/circle/freshNewList';
  static readonly CIRCLE_LIANYI_FRESH_PAPERS: string = '/mobileapi_ydxy/api/circle/freshpapers';
  // ---- LIANYI push 域：market（MarketFactory a()="api" b()="market"，全部 ServerType.LIANYI） ----
  static readonly MARKET_LIANYI_PREFIX: string = '/mobileapi_ydxy/api/market/';
  static readonly MARKET_LIANYI_POSTINFO: string = '/mobileapi_ydxy/api/market/postInfo';
  static readonly MARKET_LIANYI_COMMENTS: string = '/mobileapi_ydxy/api/market/comments';
  static readonly MARKET_LIANYI_LIKES: string = '/mobileapi_ydxy/api/market/likes';
  static readonly MARKET_LIANYI_LIKE_OPERATOR: string = '/mobileapi_ydxy/api/market/likeOperator';
  static readonly MARKET_LIANYI_SEND_COMMENT: string = '/mobileapi_ydxy/api/market/sendComment';
  static readonly MARKET_LIANYI_DELETE_COMMENT: string = '/mobileapi_ydxy/api/market/deleteComment';
  static readonly MARKET_LIANYI_HIDE_COMMENT: string = '/mobileapi_ydxy/api/market/hideComment';
  static readonly MARKET_LIANYI_DELETE_CIRCLE: string = '/mobileapi_ydxy/api/market/deleteCircle';
  static readonly MARKET_LIANYI_HIDE_CIRCLE: string = '/mobileapi_ydxy/api/market/hideCircle';
  static readonly MARKET_LIANYI_STICK_CIRCLE: string = '/mobileapi_ydxy/api/market/stickCircle';
  static readonly MARKET_LIANYI_ALTER_CLASSIFY: string = '/mobileapi_ydxy/api/market/alterClassify';
  static readonly MARKET_LIANYI_REGROUNDING: string = '/mobileapi_ydxy/api/market/reGrounding';
  static readonly MARKET_LIANYI_TURNOVER: string = '/mobileapi_ydxy/api/market/turnover';
  static readonly MARKET_LIANYI_ADD_TOP: string = '/mobileapi_ydxy/api/market/addTop';
  static readonly MARKET_LIANYI_GET_USER_SCORES: string = '/mobileapi_ydxy/api/market/getUserScores';
  static readonly MARKET_LIANYI_POST: string = '/mobileapi_ydxy/api/market/post';
  // [W28 final-b] 集市列表 school-circle 通道（MarketModel.g1/h1：e.b GET(data=加密参数)）：
  //   freshNewList {lastId}、serchFreshNewList {lastId,marketType,marketStatus,keyWord}
  static readonly MARKET_LIANYI_FRESH_NEW_LIST: string = '/mobileapi_ydxy/api/market/freshNewList';
  static readonly MARKET_LIANYI_SERCH_FRESH_NEW_LIST: string = '/mobileapi_ydxy/api/market/serchFreshNewList';
  // ---- LIANYI push 域：friendShip（FriendshipFactory a()="api" b()="friendShip"，
  //      i()=d(ServerType.LIANYI) —— 关注/取关/备注/关系/粉丝/关注列表全在 push 域） ----
  static readonly FRIENDSHIP_LIANYI_PREFIX: string = '/mobileapi_ydxy/api/friendShip/';
  static readonly FRIENDSHIP_GET_RELATIONSHIP: string = '/mobileapi_ydxy/api/friendShip/getRelationship';
  static readonly FRIENDSHIP_ADD_FRIEND: string = '/mobileapi_ydxy/api/friendShip/addFriend';
  static readonly FRIENDSHIP_DELETE_FRIEND: string = '/mobileapi_ydxy/api/friendShip/deleteFriend';
  static readonly FRIENDSHIP_UPDATE_NOTE_NAME: string = '/mobileapi_ydxy/api/friendShip/updateNoteName';
  static readonly FRIENDSHIP_GET_MY_FANS: string = '/mobileapi_ydxy/api/friendShip/getMyFans';
  static readonly FRIENDSHIP_GET_MY_FOLLOWS: string = '/mobileapi_ydxy/api/friendShip/getMyFollows';

  // ===== [W22 launch-chain] 启动/登录链端点（TabModel/ScanLoginModel/VerificationModel 源码级） =====
  // Factory 拼接公式（netconstant/a.f）= 学校服务器 + "/mobileapi_ydxy" + "/" + a() + "/" + b() + "/" + name；
  // 请求形态（netutil/e.java）：e.b(path)=GET（参数进 f13171d → data=AES）；e.d(path,json)=POST（body=AES）。
  //   TabFactory（launch 模块经 module/app/util/c.a()=d.c() 直拼）→ TabModel.i：
  //     T0 GET getUserTabs（无参）→ RemoteHomeTabBean[]（LoginedLaunchActivity 预取，实测 code=0 4 组：
  //     首页/资讯/…，字段 NAVIGATION_ID/NAVIGATION_BAR/NAVIGATION_NAME/DEFAULT_SELECTED/STATUS/SORT/JSID/TITLE）
  static readonly TAB_GET_USER_TABS: string = '/mobileapi_ydxy/api/getUserTabs';
  //   ScanLoginFactory(module/b/e.java)：a()="api" b()="scan" c()=mobile_api → ScanLoginModel(module/b/f.java)：
  //     T0 POST accessGate {url}（实测假 url code=0 data={}）；U0 POST bpm {bpmUrl}；
  //     V0 GET index {url}（ScanLoginActivity.M2 确认登录，实测假 url code=1"暂不支持"——服务器在、
  //        路由在、业务态真实）；W0 GET index {url,longitude,latitude}（会议签到链复用）
  static readonly SCAN_ACCESS_GATE: string = '/mobileapi_ydxy/api/scan/accessGate';
  static readonly SCAN_BPM: string = '/mobileapi_ydxy/api/scan/bpm';
  static readonly SCAN_INDEX: string = '/mobileapi_ydxy/api/scan/index';
  //   VerificationModel(module/app/model/d.java) 直拼 c.e().getSchoolUrl() + /mobileapi_ydxy/api/juherenzheng/：
  //     U0 POST checkPass {password}（SettingActivity 手势密码行"校验密码"弹窗，实测错密码 code=1033
  //     "密码错误，验证失败"）；T0 POST getApplicationSecurity {appid}（本链路未用，保留）
  static readonly JUHERENZHENG_CHECK_PASS: string = '/mobileapi_ydxy/api/juherenzheng/checkPass';
  static readonly JUHERENZHENG_APP_SECURITY: string = '/mobileapi_ydxy/api/juherenzheng/getApplicationSecurity';

  // ===== [W28 final-b] 发票助手端点（RatepayingFactory module/c/f.java a()="api" b()="ratepaying"，
  //   RatepayingModel.T0 → e.b(GET) getDetail 无参 → Ratepaying[]）=====
  static readonly RECEIPT_ASSIST_DETAIL: string = '/mobileapi_ydxy/api/ratepaying/getDetail';

  // ===== [P-C placeholder] 3 个可达占位页真实现端点（源码级 + Python probe_p_c_placeholder.py 实测）=====
  // SuperviseFactory（supervise/a.java）a()="api" b()="superviseListen" → /mobileapi_ydxy/api/superviseListen/<name>；
  // SuperviseModel（supervise/c/a.java）：e.d=POST body（k.m map）→ Q0；e.b=GET data= → R0。
  // 请求形态对照 W21：本批 5 端点均 e.d POST 加密 body；假参探针均端点存活（0001/false）→ 真实空/错误态。
  //   W0 detailsCourse  {xlh} → DetailsCourse（SuperviseLectureAddActivity.R2 课程详情）
  //   T0 addListenCourse {courseId,listenTime,remind,remindtime} → String（新增督导提交，data "true"=成功）
  //   X0 detailsListen  {xlh} → DetailsListen（SuperviseLectureFinishActivity.T2 已完成详情）
  //   V0 deleteListen   {xlh} → String（删除听课，data "true"=成功）
  //   d1 updateListenCourse {dj,ydrs,sdrs,nr,listenTime,remind,remindtime,xlh} → String（保存评价，data "true"=成功）
  static readonly SUPERVISE_DETAILS_COURSE: string = '/mobileapi_ydxy/api/superviseListen/detailsCourse';
  static readonly SUPERVISE_ADD_LISTEN: string = '/mobileapi_ydxy/api/superviseListen/addListenCourse';
  static readonly SUPERVISE_DETAILS_LISTEN: string = '/mobileapi_ydxy/api/superviseListen/detailsListen';
  static readonly SUPERVISE_DELETE_LISTEN: string = '/mobileapi_ydxy/api/superviseListen/deleteListen';
  static readonly SUPERVISE_UPDATE_LISTEN: string = '/mobileapi_ydxy/api/superviseListen/updateListenCourse';
  // ReimburseFactory（reimburse/b.java）a()="api" b()="project" f12640d="detail" →
  //   ReimburseModel.T0（reimburse/d/b.java）e.d POST {PROJECT_NUMBER} → Detail；
  //   考证：/reimburse/detail 映射 ProjectDetailActivity（非 V2=/new_reimburse/detail、非 AchievementListActivity）。
  //   探针：POST body HTTP200 空体 / GET data= code=0001；测试账号无项目 → 真实空态。
  static readonly PROJECT_DETAIL: string = '/mobileapi_ydxy/api/project/detail';
}
