import { hilog } from '@kit.PerformanceAnalysisKit';
import { HttpClient } from './HttpClient';
import { LoginSession } from './LoginSession';
import { Constants } from '../data/Constants';
import { Api } from './Api';
import { CryptoUtil } from './CryptoUtil';
import { ApiResponse } from '../model/ResponseModel';
import { UserInfo } from '../model/UserModel';
import { MobileCampusUserInfo } from '../model/MobileCampusUserInfoModel';
import { NewsItem } from '../model/NewsModel';
import { CourseItem, ScheduleTermParams, SCHEDULE_FALLBACK_START, SCHEDULE_FALLBACK_END,
  CourseSectionsEntry, ClassEntry, ScheduleWeekCourse, CourseDetailEntry,
  AuditAcademyEntry, AuditGradeEntry, AuditMajorEntry, AuditControlParams,
  AuditCourseNameEntry } from '../model/CourseModel';
import { TodoItem } from '../model/TodoModel';
import { ContactItem } from '../model/ContactModel';
// T2 contact-worker 追加：通讯录初始化实体（源码 InitData.java）
import { ContactInitData, ContactClassAddressBookBean, ContactCourseTeacherBean,
  ContactRootOrganizationBean, ContactTopContactListBean } from '../model/ContactModel';
// W9 contact-series 追加：搜索/黄页/OA部门选择实体（源码 SearchAddressBook/YellowPage/YellowType/Department）
import { ContactSearchAddressBook, ContactSearchAddressBookItem, ContactYellowPage,
  ContactYellowPageGroup, ContactYellowTypeListBean, ContactYellowCommonBean,
  ContactYellowTypeResult, ContactYellowDepPhoneBean, OaDepartment, OaDepartmentBean } from '../model/ContactModel';
// [W25 misc-b] 班级通讯录/个人详情实体（源码 ClassAddressBook/AddressBookUserInfo）
import { ContactClassStudentBean, ContactAddressBookUserInfo, ContactAddressBookUser, ReimbursementEntry,
  ReadingBookEntry, ReadingHomeData, RatepayingEntry, ScheduleDetailRow, ScheduleMonthItem, ScheduleDetailEntry,
  SchoolViewIndex, SchoolViewModuleBean, YiBanBannerEntry, YiBanAppGroup, YiBanAppItem,
  YiBanNewsEntry, YiBanArticleEntry, YiBanArticleImage, SchoolSceneryItem, SchoolDeletePic } from '../model/ContactModel';
// [W26 partial-finish] 设置页/学习报告/扫码分流实体（源码 YDAPPInfo/AppBean/ScanURL/TermInfo）
import { MainAppGroup, MainAppItem, ScanJumpUrl, StudyTermInfo } from '../model/ContactModel';
import { ScoreItem, ExamItem, ScoreStatEntry, ScoreDetailEntry, ScoreRankEntry, ScoreCommentEntry,
  ScoreDetailData, ComingExamEntity, FinishExamEntity, ScoreCommentInfo, ClassAndId, StudentEntity,
  NewHadScore } from '../model/ScoreModel';
// [W15 score-series] 成绩链实体（源码 StudentMessage/ClassmateEntity Gson 字段 1:1）
import { StudentScoreGroup, StudentScoreChild, ClassmateEntry } from '../model/ScoreModel';
import { MeetingItem } from '../model/MeetingModel';
import { AttendanceItem, AttendanceIsBoss, AttendanceIndex, AttendanceErrorRecordBean,
  AttendanceByDayBean, AttendanceBossIndex, AttendanceGroupBean,
  AttendancePeopleListBean, AttendanceDetail, AttendanceDetailErrorRecord } from '../model/AttendanceModel';
import { TodoTabOA, OaTodoRow, OaTodoList, OaChannel, OaTodoSearchGroup, OaFormField, OaTodoDetail,
  OaWorkApplyFlowNode, OaWorkApplyAttach, WorkApplyEntry, OaWorkApplyRow, OaWorkApplyList,
  OaWorkApplyDetail,
  OaSubDeptUser, OaSubDeptResult, OaReturnToAnyNode, OaTodoOpenProcess, OaCurrentNodeConfig,
  OaNextNodeConfig, OaNextNodeUser, OaRunProcessResult, OaDocNumEntity, OaInspectionRecord,
  OaLdmc, OaDormitoryRecord, OaRecordsDetail, OaInspectionGroup, OaInspectionDorm,
  OaReimbursed } from '../model/OaTodoModel';
import { MainNotificationV2 } from '../model/MessageModel';
// [W21 supervise] 督评链实体（源码 supervise/entity/* Gson 字段 1:1）
import { SuperviseCourseItem, SuperviseDayGroup, SuperviseListenRecord,
  SuperviseDepartment, SuperviseTeacher } from '../model/SuperviseModel';
// [E3 meeting worker] 会议模块实体（源码 meeting/entity/* + gettimetable TermParamsEntity）
import { MeetingTabEntity, JoinListEntity, JoinListItem, WeekPlanEntity, CurrentDayEntity,
  TermParamsEntity as MeetingTermParams } from '../model/MeetingApiModel';
// [W13 meeting-series] 详情/公告/签到链实体（meeting/entity/* 源码 1:1）
import { MeetingObjEntity, MeetingAttachmentEntity, MeetingExtraEntity, MeetingExtraDataEntity,
  MeetingAnnouncementEntity, SignUserEntity } from '../model/MeetingApiModel';
// [W18 meeting-remain] 周程详情/会议报告/会议室选择器实体
import { MeetingWeekDetailEntity, MeetingReportEntity, MeetingSelectorEntity } from '../model/MeetingApiModel';
import { BusinessError } from '@kit.BasicServicesKit';

/**
 * bizRequest 解密后统一解析结果：code=0 成功，1000 登录失效，其余透传
 * （[W21 协作修复] PostDetailPage 跨页引用 → 导出）
 */
export interface BizJsonResult {
  code: number;
  message: string;
  data: Object;
}

/**
 * 反馈问题模块类型 — 1:1 对应源码 com.lysoft.android.lyyd.feedback.entity.FeedbackTypes
 * （public int id; public String name;）
 */
export class FeedbackTypeEntry {
  id: number;
  name: string;

  constructor(id: number, name: string) {
    this.id = id;
    this.name = name;
  }
}

/**
 * 反馈记录条目 — 1:1 对应源码 com.lysoft.android.lyyd.feedback.entity.FeedbackRecord（列表字段）
 */
export class FeedbackRecordEntry {
  id: number;
  content: string;
  time: number;
  status: string;
  typeName: string;
  imgs: string[];

  constructor(id: number, content: string, time: number, status: string, typeName: string,
    imgs: string[]) {
    this.id = id;
    this.content = content;
    this.time = time;
    this.status = status;
    this.typeName = typeName;
    this.imgs = imgs;
  }
}

/**
 * API 服务层 — 真实加密服务器通道（2026-11-17 服务器全链路实测）。
 * 全部业务方法走 HttpClient.bizRequest(path, method, params)：
 *   - 自动加密 Access-Token/Unique-Code 头，POST body/GET data 自动加密
 *   - 响应 data 自动解密为 JSON 字符串，此处 JSON.parse 后映射到现有模型
 *   - code=0 成功返回解析数据；其余失败返回空数据（页面显示空态）
 *   - code=1000 登录已失效：统一拦截在 HttpClient.bizRequest（=APK NetUtils.f 统一点），
 *     自动清会话+toast"登录已失效，请重新登录"+跳登录页（clear 栈），页面只依赖不重复处理
 * 源码依据标注在每个方法注释（原生源码 Model/Factory 类路径）。
 */
export class ApiService {
  private static readonly OFFLINE_CODE: number = -1;
  private static readonly NOT_LOGIN_CODE: number = 1000;

  // ===== 通用工具 =====
  /** 统一错误日志（hilog SDMU tag） */
  static logError(msg: string): void {
    hilog.info(0x0000, 'SDMU', 'apisvc %{public}s', msg);
  }

  static isSuccess(resp: ApiResponse<Object>): boolean {
    return resp.code === 0 || resp.code === 200;
  }

  static offline(message: string): string {
    return '离线数据: ' + message;
  }

  static asRecord(data: Object): Record<string, Object> {
    if (data === null || data === undefined || typeof data !== 'object') {
      return {} as Record<string, Object>;
    }
    return data as Record<string, Object>;
  }

  static pick(rec: Record<string, Object>, keys: string[]): string {
    for (const key of keys) {
      const v: Object = rec[key];
      if (typeof v === 'string') {
        return v as string;
      }
      if (typeof v === 'number') {
        return String(v as number);
      }
    }
    return '';
  }

  static pickNumber(rec: Record<string, Object>, keys: string[]): number {
    for (const key of keys) {
      const v: Object = rec[key];
      if (typeof v === 'number') {
        return v as number;
      }
      if (typeof v === 'string') {
        const n: number = Number(v as string);
        if (!Number.isNaN(n)) {
          return n;
        }
      }
    }
    return 0;
  }

  static extractArray(data: Object): Object[] {
    if (data === null || data === undefined) {
      return [];
    }
    if (Array.isArray(data)) {
      return data as Object[];
    }
    const rec: Record<string, Object> = ApiService.asRecord(data);
    const listKeys: string[] = ['list', 'rows', 'records', 'datas', 'data', 'content', 'todoList'];
    for (const key of listKeys) {
      const v: Object = rec[key];
      if (Array.isArray(v)) {
        return v as Object[];
      }
    }
    return [];
  }

  /**
   * 加密请求统一封装：bizRequest → 解密 JSON 字符串 → JSON.parse。
   * code=1000 统一处理在 HttpClient.bizRequest 完成（清会话+toast+跳登录，防循环），
   * 此处 NOT_LOGIN_CODE 分支仅做码值/message 透传，供页面识别后走空态 return。
   */
  static async bizJson(path: string, method: string, params: Record<string, Object>): Promise<BizJsonResult> {
    const response: ApiResponse<Object> = await HttpClient.bizRequest(path, method, params);
    if (response.code === ApiService.NOT_LOGIN_CODE) {
      // 统一层已处理（toast+跳登录），此处只透传码值
      const notLogin: BizJsonResult = { code: ApiService.NOT_LOGIN_CODE, message: '登录已失效', data: new Object() };
      return notLogin;
    }
    if (response.code === 0) {
      if (typeof response.data === 'string' && (response.data as string) !== '') {
        try {
          const parsed: Object = JSON.parse(response.data as string) as Object;
          const ok: BizJsonResult = { code: 0, message: response.message, data: parsed };
          return ok;
        } catch (error) {
          const err = error as BusinessError;
          CryptoUtil.log('bizJson parse fail @' + path + ' code=' + err.code + ' msg=' + err.message);
          const parseFail: BizJsonResult = { code: ApiService.OFFLINE_CODE, message: '解密数据解析失败', data: new Object() };
          return parseFail;
        }
      }
      const empty: BizJsonResult = { code: ApiService.OFFLINE_CODE,
        message: response.message === '' ? '响应数据为空' : response.message, data: new Object() };
      return empty;
    }
    const fail: BizJsonResult = { code: response.code, message: response.message, data: response.data };
    return fail;
  }

  // ===== 实体解析（按原生 Gson 模型字段映射） =====
  static parseUser(data: Object): UserInfo {
    const rec: Record<string, Object> = ApiService.asRecord(data);
    return new UserInfo(
      ApiService.pick(rec, ['userId', 'id', 'yyid']),
      ApiService.pick(rec, ['name', 'trueName', 'userName']),
      ApiService.pick(rec, ['studentNo', 'studentId', 'userNo']),
      ApiService.pick(rec, ['className', 'class']),
      ApiService.pick(rec, ['academy', 'college', 'department']),
      ApiService.pick(rec, ['profession', 'major']),
      ApiService.pick(rec, ['grade']),
      ApiService.pick(rec, ['mobile', 'phone', 'tel']),
      ApiService.pick(rec, ['email', 'mail']),
      ApiService.pick(rec, ['avatar', 'photoUrl']),
      ApiService.pick(rec, ['token', 'accessToken'])
    );
  }

  static parseNews(data: Object): NewsItem {
    const rec: Record<string, Object> = ApiService.asRecord(data);
    return new NewsItem(
      ApiService.pick(rec, ['id', 'inforId']),
      ApiService.pick(rec, ['title', 'inforTile']),
      ApiService.pick(rec, ['brief', 'summary', 'subTitle']),
      ApiService.pick(rec, ['content', 'infoContent']),
      ApiService.pick(rec, ['sourceName', 'source', 'author']),
      ApiService.pick(rec, ['publishTime', 'createTime', 'time']),
      ApiService.pick(rec, ['url']),
      ApiService.pick(rec, ['imageUrl', 'coverUrl', 'picUrl']),
      ApiService.pick(rec, ['columnId', 'inforType', 'category'])
    );
  }

  static parseTodo(data: Object): TodoItem {
    const rec: Record<string, Object> = ApiService.asRecord(data);
    // UnifyTodoBean: todoId/title/state/sourceCode/arrivalTime/nodeName/applyPeopleName/url
    const state: string = ApiService.pick(rec, ['state', 'status', 'todoState']);
    let status: string = '0';
    if (state === '1' || state === 'done' || state === '2' || state === 'end') {
      status = '1';
    }
    const arrival: string = ApiService.pick(rec, ['arrivalTime', 'reachTime', 'time']);
    return new TodoItem(
      ApiService.pick(rec, ['todoId', 'id']),
      ApiService.pick(rec, ['title', 'todoTitle']),
      status,
      ApiService.pick(rec, ['sourceCode', 'isDyOrYy']),
      arrival,
      ApiService.pick(rec, ['nodeName', 'currentNode']),
      ApiService.pick(rec, ['applyPeopleName', 'applyPeople', 'fromUser']),
      ApiService.pick(rec, ['url', 'content'])
    );
  }

  static parseContact(data: Object): ContactItem {
    const rec: Record<string, Object> = ApiService.asRecord(data);
    return new ContactItem(
      ApiService.pick(rec, ['id', 'contactId', 'userId']),
      ApiService.pick(rec, ['name', 'teacherName', 'userName']),
      ApiService.pick(rec, ['department', 'deptName', 'academy']),
      ApiService.pick(rec, ['phone', 'mobile', 'tel']),
      ApiService.pick(rec, ['email', 'mail']),
      ApiService.pick(rec, ['position', 'career', 'duty']),
      ApiService.pick(rec, ['avatar', 'photoUrl'])
    );
  }

  static parseMeeting(data: Object): MeetingItem {
    const rec: Record<string, Object> = ApiService.asRecord(data);
    const state: string = ApiService.pick(rec, ['state', 'status', 'meetingState']);
    let status: string = '0';
    if (state === '1' || state === 'ing' || state === 'doing') {
      status = '1';
    } else if (state === '2' || state === 'end' || state === 'over') {
      status = '2';
    }
    return new MeetingItem(
      ApiService.pick(rec, ['id', 'meetingId', 'weekPlanId']),
      ApiService.pick(rec, ['title', 'topic', 'meetingTitle']),
      ApiService.pick(rec, ['time', 'startTime', 'meetingTime']),
      ApiService.pick(rec, ['location', 'local', 'address']),
      status,
      ApiService.pick(rec, ['organizer', 'compereName', 'createName']),
      ApiService.pick(rec, ['content', 'description', 'detail'])
    );
  }

  static parseScore(data: Object): ScoreItem {
    const rec: Record<string, Object> = ApiService.asRecord(data);
    return new ScoreItem(
      ApiService.pick(rec, ['id', 'scoreId']),
      ApiService.pick(rec, ['name', 'courseName']),
      ApiService.pickNumber(rec, ['score', 'totalScore']),
      ApiService.pickNumber(rec, ['credit', 'credits']),
      ApiService.pickNumber(rec, ['creditPoint', 'gpa']),
      ApiService.pick(rec, ['term', 'schoolYear', 'xnxq']),
      ApiService.pick(rec, ['type', 'courseType'])
    );
  }

  static parseExam(data: Object): ExamItem {
    const rec: Record<string, Object> = ApiService.asRecord(data);
    return new ExamItem(
      ApiService.pick(rec, ['id', 'examId']),
      ApiService.pick(rec, ['name', 'courseName']),
      ApiService.pick(rec, ['time', 'examTime', 'startTime']),
      ApiService.pick(rec, ['location', 'examPlace', 'place']),
      ApiService.pick(rec, ['type', 'examType'])
    );
  }

  /**
   * 源码 ScheduleOfTermEntity.java（gettimetable 模块）字段 1:1：
   *   kcmc=课程名 skdd=上课地点 skdx=上课对象(教师) ksjc/jsjc=开始/结束节次 xqj=星期几
   *   kcdm=课程代码 djz=教学周次(按周拆行) xlh=内嵌周次描述"{1-5周,7-16周}"
   * 2026-11-17 服务器实测 123 行按 djz=1..18 拆行。
   */
  static parseCourse(data: Object): CourseItem {
    const rec: Record<string, Object> = ApiService.asRecord(data);
    const djz: number = ApiService.pickNumber(rec, ['djz']);
    return new CourseItem(
      ApiService.pick(rec, ['id', 'courseId', 'kcdm']),
      ApiService.pick(rec, ['name', 'courseName', 'kcmc']),
      ApiService.pick(rec, ['teacher', 'teacherName', 'skdx', 'jsxm']),
      ApiService.pick(rec, ['place', 'classRoom', 'skdd', 'jsmc']),
      ApiService.pickCourseWeekText(rec),
      ApiService.pickNumber(rec, ['day', 'weekDay', 'xqj']),
      ApiService.pickNumber(rec, ['startNode', 'startSection', 'ksjc', 'jc']),
      ApiService.pickNumber(rec, ['endNode', 'endSection', 'jsjc']),
      ApiService.pickNumber(rec, ['credit', 'credits', 'xf']),
      ApiService.pick(rec, ['type', 'courseType', 'kcxz']),
      djz,
      ApiService.pick(rec, ['xlh'])
    );
  }

  /** 从 xlh 提取周次描述（"…第5-6节{1-5周,7-16周}…" → "1-5周,7-16周"），无则空串 */
  static pickCourseWeekText(rec: Record<string, Object>): string {
    const xlh: string = ApiService.pick(rec, ['xlh']);
    const braceStart: number = xlh.indexOf('{');
    const braceEnd: number = xlh.indexOf('}');
    if (braceStart >= 0 && braceEnd > braceStart) {
      return xlh.substring(braceStart + 1, braceEnd);
    }
    return ApiService.pick(rec, ['weeks', 'weekRange', 'zcd']);
  }

  static parseAttendance(data: Object): AttendanceItem {
    const rec: Record<string, Object> = ApiService.asRecord(data);
    return new AttendanceItem(
      ApiService.pick(rec, ['id', 'attendanceId']),
      ApiService.pick(rec, ['name', 'courseName']),
      ApiService.pick(rec, ['status', 'state', 'attendState']),
      ApiService.pick(rec, ['time', 'createTime', 'checkTime']),
      ApiService.pick(rec, ['type', 'attendType']),
      ApiService.pick(rec, ['location', 'place', 'classRoom'])
    );
  }

  /**
   * [W21 supervise] 源码 UserCourseList.DetailBean 解析（主列表行字段）：
   *   tvSection=DJJ（>3 字符截 "前3...节" 在 UI 层）、tvTitle=KCMC、tvMajor=SKDD(type0)/SKLSXM(type1)、XLH=路由参数
   */
  static parseSuperviseCourse(data: Object): SuperviseCourseItem {
    const rec: Record<string, Object> = ApiService.asRecord(data);
    return new SuperviseCourseItem(
      ApiService.pick(rec, ['DJJ']),
      ApiService.pick(rec, ['KCMC']),
      ApiService.pick(rec, ['SKDD']),
      ApiService.pick(rec, ['SKLSXM']),
      ApiService.pick(rec, ['XLH'])
    );
  }

  /** [W21 supervise] 源码 NotListening/StaleListening 行解析（我的听课两 Tab；字段全大写 Gson 1:1） */
  static parseSuperviseListen(data: Object): SuperviseListenRecord {
    const rec: Record<string, Object> = ApiService.asRecord(data);
    return new SuperviseListenRecord(
      ApiService.pick(rec, ['XLH']),
      ApiService.pick(rec, ['LISTENTIME']),
      ApiService.pick(rec, ['KCMC']),
      ApiService.pick(rec, ['SKLSXM']),
      ApiService.pick(rec, ['SKDD']),
      ApiService.pick(rec, ['XQJ']),
      ApiService.pick(rec, ['DJJ']),
      ApiService.pick(rec, ['ISEVALUATE'])
    );
  }

  static parseScoreDetail(data: Object): ScoreDetailEntry {
    const rec: Record<string, Object> = ApiService.asRecord(data);
    const cells: ScoreStatEntry[] = [];
    const rawCells: Object[] = ApiService.extractArray(rec['statCells'] === undefined ? new Object() : rec['statCells']);
    for (const one of rawCells) {
      const cellRec: Record<string, Object> = ApiService.asRecord(one);
      cells.push(new ScoreStatEntry(
        ApiService.pick(cellRec, ['label', 'name']),
        ApiService.pick(cellRec, ['statValue', 'value'])
      ));
    }
    return new ScoreDetailEntry(
      ApiService.pick(rec, ['courseName', 'kcmc', 'name']),
      ApiService.pick(rec, ['totalScore', 'score']),
      ApiService.pick(rec, ['avgScore', 'average']),
      ApiService.pick(rec, ['maxScore', 'highest']),
      ApiService.pick(rec, ['failRate', 'fail']),
      ApiService.pick(rec, ['personalScore', 'rank']),
      cells
    );
  }

  static parseScoreRank(data: Object): ScoreRankEntry {
    const rec: Record<string, Object> = ApiService.asRecord(data);
    const anonymousText: string = ApiService.pick(rec, ['anonymous', 'isAnonymous']);
    return new ScoreRankEntry(
      ApiService.pick(rec, ['rankNo', 'rank', 'no']),
      ApiService.pick(rec, ['rankName', 'name', 'userName']),
      anonymousText === '1' || anonymousText === 'true',
      ApiService.pick(rec, ['rankPoint', 'point']),
      ApiService.pick(rec, ['likeNum', 'likes'])
    );
  }

  static parseScoreComment(data: Object): ScoreCommentEntry {
    const rec: Record<string, Object> = ApiService.asRecord(data);
    const nameText: string = ApiService.pick(rec, ['commentName', 'name', 'userName']);
    let avatar: string = ApiService.pick(rec, ['avatarText', 'avatar']);
    if (avatar === '' && nameText !== '') {
      avatar = nameText.substring(0, 1);
    }
    return new ScoreCommentEntry(
      avatar,
      nameText,
      ApiService.pick(rec, ['commentTime', 'time', 'createTime']),
      ApiService.pick(rec, ['commentContent', 'content', 'nr'])
    );
  }

  // ===== 登录 / 用户 =====
  static async login(account: string, password: string): Promise<ApiResponse<UserInfo>> {
    // 真实登录链路（2026-11-16 服务器全链路验证通过）：
    // key协商 → onlyCode → AES加密完整LoginSumbitEntity → /open/auth/login → 解密响应拿真实用户信息
    const resp: ApiResponse<UserInfo> = await LoginSession.login(account, password);
    if (resp.code === 0 && resp.data.name !== '') {
      return resp;
    }
    return new ApiResponse<UserInfo>(ApiService.OFFLINE_CODE, ApiService.offline(resp.message),
      ApiService.mockUser(account));
  }

  /** 源码 ScoreModel.T0：GET getSemester → 学年学期（ScoreTabEntity） */
  static async getSemester(): Promise<ApiResponse<Record<string, Object>>> {
    const result: BizJsonResult = await ApiService.bizJson(Api.SCORE_SEMESTER, 'GET', {});
    if (result.code === 0) {
      const rec = result.data as Record<string, Object>;
      return new ApiResponse<Record<string, Object>>(0, result.message, rec);
    }
    return new ApiResponse<Record<string, Object>>(result.code, result.message, {} as Record<string, Object>);
  }

  /** 源码 ScoreModel.V0：POST hasSubject {xn,xq} → {code:int} */
  static async hasSubject(xn: string, xq: string): Promise<ApiResponse<Record<string, Object>>> {
    const params: Record<string, Object> = { 'xn': xn, 'xq': xq };
    const result: BizJsonResult = await ApiService.bizJson(Api.SCORE_HAS_SUBJECT, 'POST', params);
    if (result.code === 0) {
      const rec = result.data as Record<string, Object>;
      return new ApiResponse<Record<string, Object>>(0, result.message, rec);
    }
    return new ApiResponse<Record<string, Object>>(result.code, result.message, {} as Record<string, Object>);
  }

  static async getUserInfo(userId: string): Promise<ApiResponse<MobileCampusUserInfo>> {
    // 源码 1:1：MobileCampusUserInfoModel.R(schoolId, userId, userType, "")
    // body = {targetSchoolId, targetUserId, targetUserType, type}（AES 加密）
    const params: Record<string, Object> = {
      'targetSchoolId': LoginSession.schoolId === '' ? 'sdmu' : LoginSession.schoolId,
      'targetUserId': userId,
      'targetUserType': LoginSession.userType === '' ? '1' : LoginSession.userType,
      'type': ''
    };
    const result: BizJsonResult = await ApiService.bizJson(Api.USER_INFO, 'POST', params);
    if (result.code === 0) {
      const rec = result.data as Record<string, Object>;
      const user: MobileCampusUserInfo = MobileCampusUserInfo.fromRecord(rec);
      if (user.userName !== '') {
        return new ApiResponse<MobileCampusUserInfo>(0, result.message, user);
      }
    }
    // 失败返回空数据（页面保持登录会话真值，不展示任何假数据）
    return new ApiResponse<MobileCampusUserInfo>(result.code === 0 ? ApiService.OFFLINE_CODE : result.code,
      result.message, new MobileCampusUserInfo());
  }

  // ===== 新闻（H5明文接口 /thirdpart_ydxy/boda/news/list，2026-11-16 实测验证返回真实数据） =====
  static async getNewsList(): Promise<ApiResponse<NewsItem[]>> {
    // H5接口：GET /thirdpart_ydxy/boda/news/list?contentID=1418094565&currentPage=1&pageSize=20
    // 返回明文JSON：{"code":"0","msg":"ok","data":[{date,picurl,treeid,author,id,title,url}...]}
    const path: string = '/thirdpart_ydxy/boda/news/list?contentID=1418094565&userID=&myOwner=1418094565' +
      '&myContentId=197475&currentPage=1&pageSize=20';
    const response: ApiResponse<Object> = await HttpClient.get(path);
    if (ApiService.isSuccess(response)) {
      const items: NewsItem[] = [];
      const raw: Object[] = ApiService.extractArray(response.data);
      for (const one of raw) {
        items.push(ApiService.parseH5News(one));
      }
      if (items.length > 0) {
        return new ApiResponse<NewsItem[]>(response.code, response.message, items);
      }
    }
    return new ApiResponse<NewsItem[]>(ApiService.OFFLINE_CODE, ApiService.offline(response.message),
      ApiService.mockNewsList());
  }

  /** H5新闻条目解析：{date,picurl,treeid,author,id,title,url} → NewsItem */
  static parseH5News(one: Object): NewsItem {
    const rec: Record<string, Object> = one as Record<string, Object>;
    const pickStr = (key: string): string => {
      const v: Object = rec[key];
      return typeof v === 'string' ? v as string : '';
    };
    const id: string = pickStr('id');
    const title: string = pickStr('title');
    const date: string = pickStr('date');
    const url: string = pickStr('url');
    const picurl: string = pickStr('picurl');
    const author: string = pickStr('author');
    return new NewsItem(id, title, title, '', author === '' ? '学校要闻' : author, date, url, picurl, '学校要闻');
  }

  static async getNewsDetail(id: string): Promise<ApiResponse<NewsItem>> {
    // 源码依据：module/main/g/g.源码 信息详情（原 /ly-pd-mb/information/... 推断，迁移至 /mobileapi_ydxy/api/）
    const params: Record<string, Object> = { 'id': id, 'type': '2' };
    const result: BizJsonResult = await ApiService.bizJson(Api.NEWS_DETAIL, 'POST', params);
    if (result.code === 0) {
      const detail: NewsItem = ApiService.parseNews(result.data);
      if (detail.title !== '') {
        return new ApiResponse<NewsItem>(0, result.message, detail);
      }
    }
    if (result.code === ApiService.NOT_LOGIN_CODE) {
      return new ApiResponse<NewsItem>(ApiService.NOT_LOGIN_CODE, result.message, ApiService.mockNewsDetail(id));
    }
    return new ApiResponse<NewsItem>(ApiService.OFFLINE_CODE, ApiService.offline(result.message),
      ApiService.mockNewsDetail(id));
  }

  // ===== 待办（真实端点 /mobileapi_ydxy/api/todo/client/*，2026-11-17 服务器实测） =====
  static async getTodoList(): Promise<ApiResponse<TodoItem[]>> {
    // 源码依据：module/main/g/g.源码 UnifyTodoBean（待办列表 {keyWord,page,pageSize,sourceCode,todoType}）
    const params: Record<string, Object> = {
      'keyWord': '',
      'page': 1,
      'pageSize': 20,
      'sourceCode': '',
      'todoType': ''
    };
    const result: BizJsonResult = await ApiService.bizJson(Api.TODO_LIST, 'POST', params);
    if (result.code === 0) {
      const items: TodoItem[] = [];
      const raw: Object[] = ApiService.extractArray(result.data);
      for (const one of raw) {
        items.push(ApiService.parseTodo(one));
      }
      return new ApiResponse<TodoItem[]>(0, result.message, items);
    }
    if (result.code === ApiService.NOT_LOGIN_CODE) {
      return new ApiResponse<TodoItem[]>(ApiService.NOT_LOGIN_CODE, result.message, ApiService.mockTodoList());
    }
    return new ApiResponse<TodoItem[]>(ApiService.OFFLINE_CODE, ApiService.offline(result.message),
      ApiService.mockTodoList());
  }

  static async getTodoTabCount(sourceCode: string): Promise<ApiResponse<Object>> {
    // 源码依据：module/main/g/g.源码（待办Tab计数 {sourceCode}，2026-11-17 服务器实测）
    const params: Record<string, Object> = { 'sourceCode': sourceCode };
    const result: BizJsonResult = await ApiService.bizJson(Api.TODO_TAB_COUNT, 'POST', params);
    if (result.code === 0) {
      return new ApiResponse<Object>(0, result.message, result.data);
    }
    return new ApiResponse<Object>(result.code, result.message, result.data);
  }

  static async setTodoRead(todoId: string): Promise<ApiResponse<Object>> {
    // 源码依据：module/main/g/g.源码（待办已读，路径推断 /todo/client/setTodoRead）
    const params: Record<string, Object> = { 'todoId': todoId, 'isUnreadDoc': 1 };
    const result: BizJsonResult = await ApiService.bizJson(Api.TODO_SET_READ, 'POST', params);
    return new ApiResponse<Object>(result.code, result.message, result.data);
  }

  // ===== 通讯录（推断端点 + 降级） =====
  static async getContactList(): Promise<ApiResponse<ContactItem[]>> {
    // 源码依据：通讯录 /contact/list（服务器命名空间实测存在，具体字段按原生通讯录 Model 推断）
    const params: Record<string, Object> = {};
    const result: BizJsonResult = await ApiService.bizJson(Api.CONTACT_LIST, 'GET', params);
    if (result.code === 0) {
      const items: ContactItem[] = [];
      const raw: Object[] = ApiService.extractArray(result.data);
      for (const one of raw) {
        items.push(ApiService.parseContact(one));
      }
      return new ApiResponse<ContactItem[]>(0, result.message, items);
    }
    if (result.code === ApiService.NOT_LOGIN_CODE) {
      return new ApiResponse<ContactItem[]>(ApiService.NOT_LOGIN_CODE, result.message, ApiService.mockContactList());
    }
    return new ApiResponse<ContactItem[]>(ApiService.OFFLINE_CODE, ApiService.offline(result.message),
      ApiService.mockContactList());
  }

  // ===== 会议（推断端点 + 降级） =====
  static async getMeetingList(): Promise<ApiResponse<MeetingItem[]>> {
    // 源码依据：会议模块原始实现为 H5 路由/插件 dex（不可恢复），/meeting/main 为命名空间推断
    const params: Record<string, Object> = {};
    const result: BizJsonResult = await ApiService.bizJson(Api.MEETING_LIST, 'POST', params);
    if (result.code === 0) {
      const items: MeetingItem[] = [];
      const raw: Object[] = ApiService.extractArray(result.data);
      for (const one of raw) {
        items.push(ApiService.parseMeeting(one));
      }
      return new ApiResponse<MeetingItem[]>(0, result.message, items);
    }
    if (result.code === ApiService.NOT_LOGIN_CODE) {
      return new ApiResponse<MeetingItem[]>(ApiService.NOT_LOGIN_CODE, result.message, ApiService.mockMeetingList());
    }
    return new ApiResponse<MeetingItem[]>(ApiService.OFFLINE_CODE, ApiService.offline(result.message),
      ApiService.mockMeetingList());
  }

  static async getMeetingDetail(id: string): Promise<ApiResponse<MeetingItem>> {
    // 源码依据：会议模块原始实现为 H5 路由/插件 dex（不可恢复），/meeting/detail 为命名空间推断
    const params: Record<string, Object> = { 'id': id };
    const result: BizJsonResult = await ApiService.bizJson(Api.MEETING_DETAIL, 'POST', params);
    if (result.code === 0) {
      const detail: MeetingItem = ApiService.parseMeeting(result.data);
      if (detail.title !== '') {
        return new ApiResponse<MeetingItem>(0, result.message, detail);
      }
    }
    if (result.code === ApiService.NOT_LOGIN_CODE) {
      return new ApiResponse<MeetingItem>(ApiService.NOT_LOGIN_CODE, result.message, ApiService.mockMeetingDetail(id));
    }
    return new ApiResponse<MeetingItem>(ApiService.OFFLINE_CODE, ApiService.offline(result.message),
      ApiService.mockMeetingDetail(id));
  }

  // ===== 课表（真实端点 /mobileapi_ydxy/api/schedule/*，GetTimetableFactory a()="api" b()="schedule"） =====

  /** 学期参数缓存：termInfo/termParams 会话内取一次（APK 缓存 key "terParams"/"currentTerm" 语义） */
  private static cachedTermParams: ScheduleTermParams | null = null;

  /**
   * 源码 GetTimeTableUtil.p()/q()：学期起始日真实来源。
   *   1) GET termInfo（无参）→ 当前学期单对象 {xn,xq,ksrq,jsrq,dqxq,xlh}
   *   2) 失败降级 GET termParams（无参）→ 学期数组，取 dqxq=="1"（GetTimeTableUtil.d()）
   *   3) 双失败兜底 2026-11-17 服务器实测当前学期（xn=2026-2027 xq=1 ksrq=2026-08-24），
   *      保证 scheduleOfTerm 仍带有效 xn/xq（APK 同语义：本地 SharedPreferences 缓存兜底）
   */
  static async getScheduleTermParams(): Promise<ApiResponse<ScheduleTermParams>> {
    if (ApiService.cachedTermParams !== null && ApiService.cachedTermParams.hasStart()) {
      return new ApiResponse<ScheduleTermParams>(0, 'cache', ApiService.cachedTermParams);
    }
    const infoResult: BizJsonResult = await ApiService.bizJson(Api.SCHEDULE_TERM_INFO, 'GET', {});
    ApiService.logError('TT termInfo code=' + infoResult.code + ' msg=' + infoResult.message);
    if (infoResult.code === 0 && ApiService.asRecord(infoResult.data)['ksrq'] !== undefined) {
      const term: ScheduleTermParams = ApiService.parseTermParams(infoResult.data);
      ApiService.logError('TT termInfo ksrq=' + term.ksrq + ' jsrq=' + term.jsrq + ' xn=' + term.xn + ' xq=' + term.xq);
      if (term.hasStart()) {
        ApiService.cachedTermParams = term;
        return new ApiResponse<ScheduleTermParams>(0, infoResult.message, term);
      }
    }
    const listResult: BizJsonResult = await ApiService.bizJson(Api.SCHEDULE_TERM_PARAMS, 'GET', {});
    ApiService.logError('TT termParams code=' + listResult.code + ' msg=' + listResult.message);
    if (listResult.code === 0) {
      const raw: Object[] = ApiService.extractArray(listResult.data);
      ApiService.logError('TT termParams rows=' + raw.length);
      let fallback: ScheduleTermParams | null = null;
      for (const one of raw) {
        const term: ScheduleTermParams = ApiService.parseTermParams(one);
        // GetTimeTableUtil.d()：dqxq=="1" 为当前学期
        if (term.dqxq === '1' && term.hasStart()) {
          ApiService.cachedTermParams = term;
          return new ApiResponse<ScheduleTermParams>(0, listResult.message, term);
        }
        if (fallback === null && term.hasStart()) {
          fallback = term;
        }
      }
      if (fallback !== null) {
        ApiService.cachedTermParams = fallback;
        return new ApiResponse<ScheduleTermParams>(0, listResult.message, fallback);
      }
    }
    // 双接口失败兜底：2026-11-17 服务器实测当前学期参数（与 APK 本地缓存兜底语义一致）
    const fallbackTerm: ScheduleTermParams = new ScheduleTermParams();
    fallbackTerm.xn = '2026-2027';
    fallbackTerm.xq = '1';
    fallbackTerm.ksrq = SCHEDULE_FALLBACK_START;
    fallbackTerm.jsrq = SCHEDULE_FALLBACK_END;
    ApiService.logError('TT termParams fallback xn=' + fallbackTerm.xn + ' ksrq=' + fallbackTerm.ksrq);
    return new ApiResponse<ScheduleTermParams>(ApiService.OFFLINE_CODE, ApiService.offline(listResult.message),
      fallbackTerm);
  }

  /** TermParamsEntity{xn,xq,ksrq,jsrq,dqxq,xlh,zksxq} 解析 */
  static parseTermParams(data: Object): ScheduleTermParams {
    const rec: Record<string, Object> = ApiService.asRecord(data);
    const term: ScheduleTermParams = new ScheduleTermParams();
    term.xn = ApiService.pick(rec, ['xn']);
    term.xq = ApiService.pick(rec, ['xq']);
    term.ksrq = ApiService.pick(rec, ['ksrq']);
    term.jsrq = ApiService.pick(rec, ['jsrq']);
    term.dqxq = ApiService.pick(rec, ['dqxq']);
    term.xlh = ApiService.pick(rec, ['xlh']);
    term.zksxq = ApiService.pickNumber(rec, ['zksxq']);
    return term;
  }

  /**
   * 源码 TimeTableNetModel.d0()：GET scheduleOfTerm {xn, xq} → ScheduleOfTermEntity[]（按 djz 周次拆行）。
   * 2026-11-17 实测：无 xn/xq 返回 code=0 空数组；带 xn/xq 返回 123 行。
   * 学期参数取自 getScheduleTermParams（termInfo→termParams 降级）。
   */
  static async getScheduleList(): Promise<ApiResponse<CourseItem[]>> {
    const termResult: ApiResponse<ScheduleTermParams> = await ApiService.getScheduleTermParams();
    const term: ScheduleTermParams = termResult.data;
    ApiService.logError('TT scheduleOfTerm termXn=' + term.xn + ' termXq=' + term.xq);
    const params: Record<string, Object> = { 'xn': term.xn, 'xq': term.xq };
    const result: BizJsonResult = await ApiService.bizJson(Api.SCHEDULE_LIST, 'GET', params);
    if (result.code === 0) {
      const items: CourseItem[] = [];
      const raw: Object[] = ApiService.extractArray(result.data);
      for (const one of raw) {
        items.push(ApiService.parseCourse(one));
      }
      ApiService.logError('TT scheduleOfTerm ok rows=' + raw.length + ' parsed=' + items.length);
      return new ApiResponse<CourseItem[]>(0, result.message, items);
    }
    ApiService.logError('TT scheduleOfTerm fail code=' + result.code + ' msg=' + result.message);
    if (result.code === ApiService.NOT_LOGIN_CODE) {
      return new ApiResponse<CourseItem[]>(ApiService.NOT_LOGIN_CODE, result.message, ApiService.mockScheduleList());
    }
    return new ApiResponse<CourseItem[]>(ApiService.OFFLINE_CODE, ApiService.offline(result.message),
      ApiService.mockScheduleList());
  }

  // ===== [W10 timetable-series] 课表系列 3 页数据层（源码 TimeTableNetModel/ScheduleModel/CourseDetailModel） =====

  /** 源码 TimeTableNetModel.d.g0：GET courseSections（无参）→ CourseSectionsEntity[]{djj,sksj,xksj}
   *  （h 类 c 包装缓存 str4 → d.a.k() 本地缓存语义：HAP 走 PreferencesUtil，见 CustomTimetablePage） */
  static async getCourseSections(): Promise<ApiResponse<CourseSectionsEntry[]>> {
    const result: BizJsonResult = await ApiService.bizJson(Api.SCHEDULE_COURSE_SECTIONS, 'GET', {});
    if (result.code === 0) {
      const list: CourseSectionsEntry[] = [];
      for (const one of ApiService.extractArray(result.data)) {
        list.push(CourseSectionsEntry.fromRecord(ApiService.asRecord(one)));
      }
      return new ApiResponse<CourseSectionsEntry[]>(0, result.message, list);
    }
    return new ApiResponse<CourseSectionsEntry[]>(result.code, result.message, []);
  }

  /** 源码 TimeTableNetModel.d.G0：GET getClassList（无参）→ Classes[]{bjdm,bjmc,sl} */
  static async getClassList(): Promise<ApiResponse<ClassEntry[]>> {
    const result: BizJsonResult = await ApiService.bizJson(Api.SCHEDULE_CLASS_LIST, 'GET', {});
    if (result.code === 0) {
      const list: ClassEntry[] = [];
      for (const one of ApiService.extractArray(result.data)) {
        list.push(ClassEntry.fromRecord(ApiService.asRecord(one)));
      }
      return new ApiResponse<ClassEntry[]>(0, result.message, list);
    }
    return new ApiResponse<ClassEntry[]>(result.code, result.message, []);
  }

  /** 源码 TimeTableNetModel.d.X：GET getScheduleList {xn,xq,bjmc,djz} → ScheduleOfWeekEntity[]
   *  djz=教学周次（服务器按周过滤），响应即该班该周全部课行（g(list) 按 xqj 分天由页面完成） */
  static async getScheduleListByClass(xn: string, xq: string, bjmc: string,
    djz: string): Promise<ApiResponse<ScheduleWeekCourse[]>> {
    const params: Record<string, Object> = { 'xn': xn, 'xq': xq, 'bjmc': bjmc, 'djz': djz };
    const result: BizJsonResult = await ApiService.bizJson(Api.SCHEDULE_GET_SCHEDULE_LIST, 'GET', params);
    if (result.code === 0) {
      const list: ScheduleWeekCourse[] = [];
      for (const one of ApiService.extractArray(result.data)) {
        list.push(ScheduleWeekCourse.fromRecord(ApiService.asRecord(one)));
      }
      return new ApiResponse<ScheduleWeekCourse[]>(0, result.message, list);
    }
    return new ApiResponse<ScheduleWeekCourse[]>(result.code, result.message, []);
  }

  /** 源码 ScheduleModel.c.a.T0：POST addPersonalCourse {kcmc,qsjsz,djj,xqj,skdd}（自定义加课）
   *  响应 data="1"(STATUS_TRUE)=成功，空 data 直接走 bizRequest（sendSms 同款防误判） */
  static async addPersonalCourse(kcmc: string, qsjsz: string, djj: string, xqj: string,
    skdd: string): Promise<ApiResponse<Object>> {
    const params: Record<string, Object> = {
      'kcmc': kcmc,
      'qsjsz': qsjsz,
      'djj': djj,
      'xqj': xqj,
      'skdd': skdd
    };
    const response: ApiResponse<Object> = await HttpClient.bizRequest(Api.SCHEDULE_ADD_PERSONAL_COURSE, 'POST', params);
    return new ApiResponse<Object>(response.code, response.message, response.data);
  }

  /** 源码 AddCourseModel.d.a.x：POST deletePersonalCourse {jumpFromDetail,courseid}（课程删除）
   *  courseid：classid 非空取 classid，否则 xlh（CourseDetailActivity.b）；响应 "1"=成功 */
  static async deletePersonalCourse(courseid: string, jumpFromDetail: boolean): Promise<ApiResponse<Object>> {
    const params: Record<string, Object> = {
      'jumpFromDetail': jumpFromDetail ? '1' : '0',
      'courseid': courseid
    };
    const response: ApiResponse<Object> = await HttpClient.bizRequest(Api.SCHEDULE_DELETE_PERSONAL_COURSE, 'POST', params);
    return new ApiResponse<Object>(response.code, response.message, response.data);
  }

  /** 源码 CourseDetailModel.d.e.B0：GET courseDetail {xlh,djz,xqj} → CourseDetailEntity
   *  （xlh=课行周次描述原文，djz=教学周次，xqj=星期几；J0 渲染挂科率/平均分/男女比例等） */
  static async getCourseDetail(xlh: string, djz: string, xqj: string): Promise<ApiResponse<CourseDetailEntry>> {
    const params: Record<string, Object> = { 'xlh': xlh, 'djz': djz, 'xqj': xqj };
    const result: BizJsonResult = await ApiService.bizJson(Api.SCHEDULE_COURSE_DETAIL, 'GET', params);
    if (result.code === 0) {
      const detail: CourseDetailEntry = CourseDetailEntry.fromRecord(ApiService.asRecord(result.data));
      return new ApiResponse<CourseDetailEntry>(0, result.message, detail);
    }
    return new ApiResponse<CourseDetailEntry>(result.code, result.message, new CourseDetailEntry());
  }

  // ===== [W16 course-select] 蹭课链数据层（2026-11-18 探针全实测，temp/probe_w16_course_select*.py） =====

  /** 源码 ChooseAcademyModel.d.b.e0：GET getCkColleges（无参）→ AcademyEntity[]（实测 9 学院） */
  static async getCkColleges(): Promise<ApiResponse<AuditAcademyEntry[]>> {
    const result: BizJsonResult = await ApiService.bizJson(Api.SCHEDULE_CK_COLLEGES, 'GET', {});
    if (result.code === 0) {
      const list: AuditAcademyEntry[] = [];
      for (const one of ApiService.extractArray(result.data)) {
        list.push(AuditAcademyEntry.fromRecord(ApiService.asRecord(one)));
      }
      return new ApiResponse<AuditAcademyEntry[]>(0, result.message, list);
    }
    return new ApiResponse<AuditAcademyEntry[]>(result.code, result.message, []);
  }

  /** 源码 ChooseAcademyModel.d.b.f0：GET ckControl（无参）→ {searchFilterShow,timeFilterShow}（实测均 1） */
  static async getCkControl(): Promise<ApiResponse<AuditControlParams>> {
    const result: BizJsonResult = await ApiService.bizJson(Api.SCHEDULE_CK_CONTROL, 'GET', {});
    if (result.code === 0) {
      return new ApiResponse<AuditControlParams>(0, result.message,
        AuditControlParams.fromRecord(ApiService.asRecord(result.data)));
    }
    return new ApiResponse<AuditControlParams>(result.code, result.message, new AuditControlParams());
  }

  /**
   * 源码 ChooseAcademyModel.d.b.c / ChooseCoursePresenter.e：GET searchSchedule（无参）。
   * 响应 data 为纯字符串（实测 '课程名称,老师,教室'，非 JSON）→ bizRequest 直取解密原文；
   * 兼容服务端偶发 JSON 引号形态（"..."）解析剥壳。
   */
  static async getAuditSearchHint(): Promise<ApiResponse<string>> {
    const response: ApiResponse<Object> = await HttpClient.bizRequest(Api.SCHEDULE_SEARCH_SCHEDULE, 'GET', {});
    if (response.code !== 0) {
      return new ApiResponse<string>(response.code, response.message, '');
    }
    const raw: Object = response.data;
    if (typeof raw === 'string') {
      const text: string = raw as string;
      try {
        const parsed: Object = JSON.parse(text) as Object;
        if (typeof parsed === 'string') {
          return new ApiResponse<string>(0, response.message, parsed as string);
        }
      } catch {
        // 纯文本 hint 原样返回（探针实测形态）
      }
      return new ApiResponse<string>(0, response.message, text);
    }
    return new ApiResponse<string>(0, response.message, '');
  }

  /** 源码 ChooseCourseModel.d.c.c0：GET getGradeList（无参）→ GradeEntity[]（实测 4 年级） */
  static async getAuditGradeList(): Promise<ApiResponse<AuditGradeEntry[]>> {
    const result: BizJsonResult = await ApiService.bizJson(Api.SCHEDULE_GRADE_LIST, 'GET', {});
    if (result.code === 0) {
      const list: AuditGradeEntry[] = [];
      for (const one of ApiService.extractArray(result.data)) {
        list.push(AuditGradeEntry.fromRecord(ApiService.asRecord(one)));
      }
      return new ApiResponse<AuditGradeEntry[]>(0, result.message, list);
    }
    return new ApiResponse<AuditGradeEntry[]>(result.code, result.message, []);
  }

  /** 源码 ChooseCourseModel.d.c.K：GET getCkMajors {xydm} → MajorEntity[]（实测 7 专业） */
  static async getCkMajors(xydm: string): Promise<ApiResponse<AuditMajorEntry[]>> {
    const params: Record<string, Object> = { 'xydm': xydm };
    const result: BizJsonResult = await ApiService.bizJson(Api.SCHEDULE_CK_MAJORS, 'GET', params);
    if (result.code === 0) {
      const list: AuditMajorEntry[] = [];
      for (const one of ApiService.extractArray(result.data)) {
        list.push(AuditMajorEntry.fromRecord(ApiService.asRecord(one)));
      }
      return new ApiResponse<AuditMajorEntry[]>(0, result.message, list);
    }
    return new ApiResponse<AuditMajorEntry[]>(result.code, result.message, []);
  }

  /**
   * 源码 ChooseCourseModel.d.c.s0：GET getCollegeCourseNames
   * {pageSize:"20",pageNum,xydm[,zydm,nj]} → [{kcmc}]；pageSize 源码写死 20（d 回调仅取 kcmc）。
   * 2026-11-18 探针：9 学院全空数组 → 页面呈现 APK 空态。
   */
  static async getCollegeCourseNames(pageNum: number, xydm: string, zydm: string,
    nj: string): Promise<ApiResponse<AuditCourseNameEntry[]>> {
    const params: Record<string, Object> = {
      'pageSize': '20',
      'pageNum': String(pageNum),
      'xydm': xydm
    };
    if (zydm !== '') {
      params['zydm'] = zydm;
    }
    if (nj !== '') {
      params['nj'] = nj;
    }
    const result: BizJsonResult = await ApiService.bizJson(Api.SCHEDULE_COLLEGE_COURSE_NAMES, 'GET', params);
    if (result.code === 0) {
      const list: AuditCourseNameEntry[] = [];
      for (const one of ApiService.extractArray(result.data)) {
        list.push(AuditCourseNameEntry.fromRecord(ApiService.asRecord(one)));
      }
      return new ApiResponse<AuditCourseNameEntry[]>(0, result.message, list);
    }
    return new ApiResponse<AuditCourseNameEntry[]>(result.code, result.message, []);
  }

  /**
   * 源码 ScheduleModel.c.a.d1（schedule/view/EditCourseActivity.T2 → x.v().x(...)）：
   * POST updateCourse {xlh,kcmc,qsjsz,djj,xqj,skdd}；响应 data=="true"(STATUS_TRUE)=成功，
   * data 可能为空 → bizRequest 直取（addPersonalCourse/sendSms 同款防误判）。
   */
  static async updateCourse(xlh: string, kcmc: string, qsjsz: string, djj: string, xqj: string,
    skdd: string): Promise<ApiResponse<Object>> {
    const params: Record<string, Object> = {
      'xlh': xlh,
      'kcmc': kcmc,
      'qsjsz': qsjsz,
      'djj': djj,
      'xqj': xqj,
      'skdd': skdd
    };
    const response: ApiResponse<Object> = await HttpClient.bizRequest(Api.SCHEDULE_UPDATE_COURSE, 'POST', params);
    return new ApiResponse<Object>(response.code, response.message, response.data);
  }

  // ===== [W21 supervise] 督评链 5 页数据层（源码 supervise/a.java SuperviseFactory a()="api"
  //  b()="superviseListen" → /mobileapi_ydxy/api/superviseListen/<name>；
  //  c/a.java SuperviseModel：e.b=GET data= / e.d=POST body；2026-11-18 probe_w21_supervise.py 全实测）=====

  /**
   * 源码 SuperviseModel.b1（MainActivity.Q2 → d.a.q(String...)}）：POST getUserCourseList。
   * 两种形态：{skls}（搜索回传 GH，adapter type=0 tvMajor=SKDD）/ {bmdm,djj}（筛选回传，type=1 tvMajor=SKLSXM）。
   * 响应为 UserCourseList[]{detail, xqj} 7 组（xqj 0..6=周日..周六，WeekView FIRST_DAY=1 周日开头）；
   * 2026-11-18 实测：空参/筛选/搜索三形态均 code=0，测试账号 detail 全空 → 真实空态。
   */
  static async getSuperviseDayGroups(skls: string, bmdm: string, djj: string):
    Promise<ApiResponse<SuperviseDayGroup[]>> {
    // 源码 b1 分支 1:1：strArr.length>1 → 仅 {bmdm,djj}；否则仅 {skls}（不混发空键）
    const params: Record<string, Object> = skls !== '' ? { 'skls': skls } :
      { 'bmdm': bmdm, 'djj': djj };
    const result: BizJsonResult = await ApiService.bizJson(Api.SUPERVISE_USER_COURSE, 'POST', params);
    if (result.code === 0) {
      const groups: SuperviseDayGroup[] = [];
      const raw: Object[] = ApiService.extractArray(result.data);
      for (const one of raw) {
        const rec: Record<string, Object> = ApiService.asRecord(one);
        const rows: SuperviseCourseItem[] = [];
        for (const child of ApiService.parseChildArray(one, 'detail')) {
          rows.push(ApiService.parseSuperviseCourse(child));
        }
        groups.push(new SuperviseDayGroup(ApiService.pickNumber(rec, ['xqj']), rows));
      }
      return new ApiResponse<SuperviseDayGroup[]>(0, result.message, groups);
    }
    return new ApiResponse<SuperviseDayGroup[]>(result.code, result.message, []);
  }

  /** 源码 SuperviseModel.Z0（MineListenFragment.Q1）：GET getNotListening（待听课）→ NotListening[]
   *  2026-11-18 实测 code=0 空数组（测试账号无待听课）→ 真实空态 */
  static async getSuperviseNotListening(): Promise<ApiResponse<SuperviseListenRecord[]>> {
    const result: BizJsonResult = await ApiService.bizJson(Api.SUPERVISE_NOT_LISTENING, 'GET', {});
    if (result.code === 0) {
      const items: SuperviseListenRecord[] = [];
      const raw: Object[] = ApiService.extractArray(result.data);
      for (const one of raw) {
        items.push(ApiService.parseSuperviseListen(one));
      }
      return new ApiResponse<SuperviseListenRecord[]>(0, result.message, items);
    }
    return new ApiResponse<SuperviseListenRecord[]>(result.code, result.message, []);
  }

  /** 源码 SuperviseModel.a1（MinePastListFragment.R1）：GET getStaleListening（已过期）→ StaleListening[]
   *  2026-11-18 实测 code=0 空数组 → 真实空态 */
  static async getSuperviseStaleListening(): Promise<ApiResponse<SuperviseListenRecord[]>> {
    const result: BizJsonResult = await ApiService.bizJson(Api.SUPERVISE_STALE_LISTENING, 'GET', {});
    if (result.code === 0) {
      const items: SuperviseListenRecord[] = [];
      const raw: Object[] = ApiService.extractArray(result.data);
      for (const one of raw) {
        items.push(ApiService.parseSuperviseListen(one));
      }
      return new ApiResponse<SuperviseListenRecord[]>(0, result.message, items);
    }
    return new ApiResponse<SuperviseListenRecord[]>(result.code, result.message, []);
  }

  /** 源码 SuperviseModel.Y0（FilterActivity.Q2）：GET getDepartmentList（无参）→ DepartmentList[]{BMDM,BMMC}
   *  2026-11-18 实测 19 学院（创新创业学院/马克思主义学院/体育教学部...） */
  static async getSuperviseDepartments(): Promise<ApiResponse<SuperviseDepartment[]>> {
    const result: BizJsonResult = await ApiService.bizJson(Api.SUPERVISE_DEPARTMENT_LIST, 'GET', {});
    if (result.code === 0) {
      const items: SuperviseDepartment[] = [];
      const raw: Object[] = ApiService.extractArray(result.data);
      for (const one of raw) {
        const rec: Record<string, Object> = ApiService.asRecord(one);
        items.push(new SuperviseDepartment(ApiService.pick(rec, ['BMDM']), ApiService.pick(rec, ['BMMC'])));
      }
      return new ApiResponse<SuperviseDepartment[]>(0, result.message, items);
    }
    return new ApiResponse<SuperviseDepartment[]>(result.code, result.message, []);
  }

  /** 源码 SuperviseModel.c1（SearchActivity.T2）：POST searchSector {xm} → SearchSector[]{GH,XM,BMMC}
   *  2026-11-18 实测 {xm:'张'} 95 行 / {xm:''} 全量行 */
  static async searchSuperviseTeacher(xm: string): Promise<ApiResponse<SuperviseTeacher[]>> {
    const params: Record<string, Object> = { 'xm': xm };
    const result: BizJsonResult = await ApiService.bizJson(Api.SUPERVISE_SEARCH_SECTOR, 'POST', params);
    if (result.code === 0) {
      const items: SuperviseTeacher[] = [];
      const raw: Object[] = ApiService.extractArray(result.data);
      for (const one of raw) {
        const rec: Record<string, Object> = ApiService.asRecord(one);
        items.push(new SuperviseTeacher(ApiService.pick(rec, ['GH']), ApiService.pick(rec, ['XM']),
          ApiService.pick(rec, ['BMMC'])));
      }
      return new ApiResponse<SuperviseTeacher[]>(0, result.message, items);
    }
    return new ApiResponse<SuperviseTeacher[]>(result.code, result.message, []);
  }

  /**
   * 源码 SuperviseModel.U0（EvaluateActivity.L2）：POST commentsListenCourse {dj,ydrs,sdrs,nr,xlh}
   *  dj=评分整型串、ydrs=应到、sdrs=实到、nr=教学评价、xlh=路由参数。
   *  源码 c.g：data=="true"(STATUS_TRUE) 成功 → toast"评论成功"+setResult+finish；否则 toast(message)。
   *  2026-11-18 实测：假 xlh → code=0001 系统异常（端点存活，xlh 业务校验在服务端）。
   */
  static async submitSuperviseComment(dj: string, ydrs: string, sdrs: string, nr: string,
    xlh: string): Promise<ApiResponse<string>> {
    const params: Record<string, Object> = {
      'dj': dj, 'ydrs': ydrs, 'sdrs': sdrs, 'nr': nr, 'xlh': xlh
    };
    const result: BizJsonResult = await ApiService.bizJson(Api.SUPERVISE_COMMENTS, 'POST', params);
    if (result.code === 0) {
      return new ApiResponse<string>(0, result.message, ApiService.plainOf(result));
    }
    return new ApiResponse<string>(result.code, result.message, '');
  }

  // ===== 成绩详情 / 课评（推断端点 + 降级） =====
  static async getScoreDetail(): Promise<ApiResponse<ScoreDetailData>> {
    // 源码依据：成绩模块原始实现为 H5 路由/插件 dex（不可恢复），/grade/detail 为命名空间推断
    const params: Record<string, Object> = {};
    const result: BizJsonResult = await ApiService.bizJson(Api.SCORE_DETAIL, 'POST', params);
    if (result.code === 0) {
      const rec: Record<string, Object> = ApiService.asRecord(result.data);
      const detailList: ScoreDetailEntry[] = [];
      const rawDetails: Object[] = ApiService.extractArray(rec['detailList'] === undefined ?
        result.data : rec['detailList']);
      for (const one of rawDetails) {
        detailList.push(ApiService.parseScoreDetail(one));
      }
      const rankList: ScoreRankEntry[] = [];
      const rawRanks: Object[] = ApiService.extractArray(rec['rankList'] === undefined ? new Object() : rec['rankList']);
      for (const one of rawRanks) {
        rankList.push(ApiService.parseScoreRank(one));
      }
      const commentList: ScoreCommentEntry[] = [];
      const rawComments: Object[] = ApiService.extractArray(rec['commentList'] === undefined ?
        new Object() : rec['commentList']);
      for (const one of rawComments) {
        commentList.push(ApiService.parseScoreComment(one));
      }
      return new ApiResponse<ScoreDetailData>(0, result.message,
        new ScoreDetailData(detailList, rankList, commentList));
    }
    if (result.code === ApiService.NOT_LOGIN_CODE) {
      return new ApiResponse<ScoreDetailData>(ApiService.NOT_LOGIN_CODE, result.message, ApiService.mockScoreDetail());
    }
    return new ApiResponse<ScoreDetailData>(ApiService.OFFLINE_CODE, ApiService.offline(result.message),
      ApiService.mockScoreDetail());
  }

  // ===== [W15 score-series] 成绩链 4 页数据层（源码 StudentSearchModel/ClassmateModel/ScoreModel/HandleExamCourseModel） =====

  /**
   * 写端点响应 data 为裸 "true"/"false" 字符串（解密后 JSON.parse → boolean）或对象包裹。
   * 源码 netutil/c.g(str3) 判断 data 非空即成功，此处还原为 plain 字符串。
   */
  private static plainOf(result: BizJsonResult): string {
    if (typeof result.data === 'boolean') {
      return (result.data as boolean) ? 'true' : 'false';
    }
    if (typeof result.data === 'string') {
      return result.data as string;
    }
    const rec: Record<string, Object> = ApiService.asRecord(result.data);
    return ApiService.pick(rec, ['result', 'data']);
  }

  /**
   * 源码 StudentSearchModel.V0（score/c/b.java）：GET getStudentMsg {xh} → StudentMessage[]
   * StudentScoreActivity.K2 → b.n(new a).j(studentId)。
   * 2026-11-18 实测：测试学号 code=0001 系统异常 → 页面真实空态。
   */
  static async getStudentScoreMsg(xh: string): Promise<ApiResponse<StudentScoreGroup[]>> {
    const params: Record<string, Object> = { 'xh': xh };
    const result: BizJsonResult = await ApiService.bizJson(Api.SCORE_STUDENT_MSG, 'GET', params);
    if (result.code === 0) {
      const groups: StudentScoreGroup[] = [];
      const raw: Object[] = ApiService.extractArray(result.data);
      for (const one of raw) {
        const rec: Record<string, Object> = ApiService.asRecord(one);
        const children: StudentScoreChild[] = [];
        const rawChildren: Object[] = ApiService.extractArray(rec['data']);
        for (const child of rawChildren) {
          const crec: Record<string, Object> = ApiService.asRecord(child);
          children.push(new StudentScoreChild(
            ApiService.pick(crec, ['kcmc']),
            ApiService.pick(crec, ['xscj']),
            ApiService.pick(crec, ['bjpm'])
          ));
        }
        groups.push(new StudentScoreGroup(ApiService.pick(rec, ['xn']), ApiService.pick(rec, ['xq']), children));
      }
      return new ApiResponse<StudentScoreGroup[]>(0, result.message, groups);
    }
    return new ApiResponse<StudentScoreGroup[]>(result.code, result.message, []);
  }

  /**
   * 源码 ClassmateModel.N（timetable/d/d.java）：GET matchGateMsg {xn,xq,dm,djz,xqj,djj} → ClassmateEntity[]
   * ClassmatesListActivity pagetype=1（上课学生）。2026-11-18 实测 98 人/89 人 code=0。
   */
  static async getMatchGateMsg(xn: string, xq: string, dm: string, djz: string, xqj: string,
    djj: string): Promise<ApiResponse<ClassmateEntry[]>> {
    const params: Record<string, Object> = { 'xn': xn, 'xq': xq, 'dm': dm, 'djz': djz, 'xqj': xqj, 'djj': djj };
    return ApiService.fetchClassmates(Api.SCHEDULE_MATCH_GATE_MSG, params);
  }

  /**
   * 源码 ClassmateModel.q0：GET highestScoreMsg {xn,xq,kcmc,zgfzscj} → ClassmateEntity[]
   * ClassmatesListActivity pagetype=2（最高分保持者）。2026-11-18 实测 zgfzscj=96.8 → 1 人 code=0。
   */
  static async getHighestScoreMsg(xn: string, xq: string, kcmc: string,
    zgfzscj: string): Promise<ApiResponse<ClassmateEntry[]>> {
    const params: Record<string, Object> = { 'xn': xn, 'xq': xq, 'kcmc': kcmc, 'zgfzscj': zgfzscj };
    return ApiService.fetchClassmates(Api.SCHEDULE_HIGHEST_SCORE_MSG, params);
  }

  /** ClassmateEntity {xh,xm,xb,bjmc,qjlb} 统一解析（qjlb 仅请假名单场景非空） */
  private static async fetchClassmates(path: string,
    params: Record<string, Object>): Promise<ApiResponse<ClassmateEntry[]>> {
    const result: BizJsonResult = await ApiService.bizJson(path, 'GET', params);
    if (result.code === 0) {
      const items: ClassmateEntry[] = [];
      const raw: Object[] = ApiService.extractArray(result.data);
      for (const one of raw) {
        const rec: Record<string, Object> = ApiService.asRecord(one);
        items.push(new ClassmateEntry(
          ApiService.pick(rec, ['xm']),
          ApiService.pick(rec, ['xb']),
          ApiService.pick(rec, ['xh']),
          ApiService.pick(rec, ['bjmc']),
          ApiService.pick(rec, ['qjlb'])
        ));
      }
      return new ApiResponse<ClassmateEntry[]>(0, result.message, items);
    }
    return new ApiResponse<ClassmateEntry[]>(result.code, result.message, []);
  }

  /**
   * 源码 ScoreModel.T0（student_score/b/b.java）：POST sendComment {xn,xq,kcdm,plnr} → data "true"
   * ScoreCommentPostActivity.b 点击 → h.b(xn,xq,kcdm,trim 内容)。成功 g0(str) 非空 → setResult(change)+finish。
   * 2026-11-18 实测：接口通（空参 data='true'，服务器不校验内容空——内容空拦截保留在页面源码分支）。
   */
  static async sendScoreComment(xn: string, xq: string, kcdm: string,
    plnr: string): Promise<ApiResponse<string>> {
    const params: Record<string, Object> = { 'xn': xn, 'xq': xq, 'kcdm': kcdm, 'plnr': plnr };
    const result: BizJsonResult = await ApiService.bizJson(Api.GRADE_SEND_COMMENT, 'POST', params);
    if (result.code === 0) {
      return new ApiResponse<string>(0, result.message, ApiService.plainOf(result));
    }
    return new ApiResponse<string>(result.code, result.message, '');
  }

  /**
   * 源码 HandleExamCourseModel.u（examination/b/d.java）：POST operatorExam 8 字段 → data "true"
   * HandleExamCourseActivity.c3 → C.g(SumbitHandleExamEntity)（kssj 用 tag 原始值，jssj 恒空串）。
   * 成功 h1() → setResult(dataischange)+finish（无 toast）；失败 m(str2) toast。
   * 2026-11-18 实测：空 kmmc 0001 系统异常（必填语义）。
   */
  static async submitOperatorExam(kmmc: string, kssj: string, ksdd: string, zwh: string, zkzh: string,
    txlx: string, kslx: string): Promise<ApiResponse<string>> {
    const params: Record<string, Object> = {
      'zwh': zwh, 'zkzh': zkzh, 'txlx': txlx, 'kssj': kssj,
      'kslx': kslx, 'ksdd': ksdd, 'kmmc': kmmc, 'jssj': ''
    };
    const result: BizJsonResult = await ApiService.bizJson(Api.EXAM_OPERATOR, 'POST', params);
    if (result.code === 0) {
      return new ApiResponse<string>(0, result.message, ApiService.plainOf(result));
    }
    return new ApiResponse<string>(result.code, result.message, '');
  }

  /**
   * 源码 HandleExamCourseModel.S：GET recommentList {kslx:"0"期末|"1"等级, kmmc} → RecommentListEntity[]
   * HandleExamCourseActivity.a3（edit 进页自动拉推荐）。2026-11-18 实测 code=0 items=0 真实空。
   * RecommentListEntity{XLH,KMMC,KSLX,AGREENUM,OPPOSENUM,ISOPPOSE,XM,ZWH} 当前仅连通性记录，
   * 同考试人区源码 XML gone + i0 空实现 → 页面不渲染（保真）。
   */
  static async getExamRecommentList(kslx: string, kmmc: string): Promise<ApiResponse<Object[]>> {
    const params: Record<string, Object> = { 'kslx': kslx, 'kmmc': kmmc };
    const result: BizJsonResult = await ApiService.bizJson(Api.EXAM_RECOMMENT_LIST, 'GET', params);
    if (result.code === 0) {
      return new ApiResponse<Object[]>(0, result.message, ApiService.extractArray(result.data));
    }
    return new ApiResponse<Object[]>(result.code, result.message, []);
  }

  /**
   * 源码 HandleExamCourseModel.r0：POST adoptExam {kslx,kmmc,cnxlh,zwh} → data "true"
   * 推荐条目"采纳"回调 e.a()（AGREENUM+1 本地 + C.b(recomment, zwh)）。
   */
  static async adoptExam(kslx: string, kmmc: string, cnxlh: string, zwh: string): Promise<ApiResponse<string>> {
    const params: Record<string, Object> = { 'kslx': kslx, 'kmmc': kmmc, 'cnxlh': cnxlh, 'zwh': zwh };
    const result: BizJsonResult = await ApiService.bizJson(Api.EXAM_ADOPT, 'POST', params);
    if (result.code === 0) {
      return new ApiResponse<string>(0, result.message, ApiService.plainOf(result));
    }
    return new ApiResponse<string>(result.code, result.message, '');
  }

  /**
   * 源码 HandleExamCourseModel.n0：POST opposeExam {xlh,cz:"0"|"1"} → data "true"/"false"
   * 推荐条目"报错"回调 b3（ISOPPOSE=="0"→cz="1" 翻转）。
   */
  static async opposeExam(xlh: string, cz: string): Promise<ApiResponse<string>> {
    const params: Record<string, Object> = { 'xlh': xlh, 'cz': cz };
    const result: BizJsonResult = await ApiService.bizJson(Api.EXAM_OPPOSE, 'POST', params);
    if (result.code === 0) {
      return new ApiResponse<string>(0, result.message, ApiService.plainOf(result));
    }
    return new ApiResponse<string>(result.code, result.message, '');
  }

  static async getScoreList(): Promise<ApiResponse<ScoreItem[]>> {
    // 源码依据：/grade/gradeList（2026-11-17 服务器命名空间实测存在）
    const params: Record<string, Object> = {};
    const result: BizJsonResult = await ApiService.bizJson(Api.GRADE_LIST, 'GET', params);
    if (result.code === 0) {
      const items: ScoreItem[] = [];
      const raw: Object[] = ApiService.extractArray(result.data);
      for (const one of raw) {
        items.push(ApiService.parseScore(one));
      }
      return new ApiResponse<ScoreItem[]>(0, result.message, items);
    }
    if (result.code === ApiService.NOT_LOGIN_CODE) {
      return new ApiResponse<ScoreItem[]>(ApiService.NOT_LOGIN_CODE, result.message, ApiService.mockScoreList());
    }
    return new ApiResponse<ScoreItem[]>(ApiService.OFFLINE_CODE, ApiService.offline(result.message),
      ApiService.mockScoreList());
  }

  static async getExamList(): Promise<ApiResponse<ExamItem[]>> {
    // 源码依据：考试模块原始实现为 H5 路由/插件 dex（不可恢复），/exam/list 为命名空间推断
    const params: Record<string, Object> = {};
    const result: BizJsonResult = await ApiService.bizJson(Api.EXAM_LIST, 'POST', params);
    if (result.code === 0) {
      const items: ExamItem[] = [];
      const raw: Object[] = ApiService.extractArray(result.data);
      for (const one of raw) {
        items.push(ApiService.parseExam(one));
      }
      return new ApiResponse<ExamItem[]>(0, result.message, items);
    }
    if (result.code === ApiService.NOT_LOGIN_CODE) {
      return new ApiResponse<ExamItem[]>(ApiService.NOT_LOGIN_CODE, result.message, ApiService.mockExamList());
    }
    return new ApiResponse<ExamItem[]>(ApiService.OFFLINE_CODE, ApiService.offline(result.message),
      ApiService.mockExamList());
  }

  static async getAttendanceList(): Promise<ApiResponse<AttendanceItem[]>> {
    // 源码依据：考勤模块原始实现为 H5 路由/插件 dex（不可恢复），/attendance/list 为命名空间推断
    const params: Record<string, Object> = {};
    const result: BizJsonResult = await ApiService.bizJson(Api.ATTENDANCE_LIST, 'POST', params);
    if (result.code === 0) {
      const items: AttendanceItem[] = [];
      const raw: Object[] = ApiService.extractArray(result.data);
      for (const one of raw) {
        items.push(ApiService.parseAttendance(one));
      }
      return new ApiResponse<AttendanceItem[]>(0, result.message, items);
    }
    if (result.code === ApiService.NOT_LOGIN_CODE) {
      return new ApiResponse<AttendanceItem[]>(ApiService.NOT_LOGIN_CODE, result.message,
        ApiService.mockAttendanceList());
    }
    return new ApiResponse<AttendanceItem[]>(ApiService.OFFLINE_CODE, ApiService.offline(result.message),
      ApiService.mockAttendanceList());
  }

  // ===== T3 misc-worker：修改密码（源码实证 MobileCampusUserPImpl.d → c/h/b/a.T0）=====
  /** 源码 c/h/b/a.T0：POST changePasswByOldPassw {passw,passwNew,passwNewAgain}
   *  业务错误码 1020-1024 原生显示在 tvErrorTips，其余 toast —— code/message 原样透传给页面。
   */
  static async changePasswByOldPassw(oldPwd: string, newPwd: string,
    confirmPwd: string): Promise<ApiResponse<Object>> {
    const params: Record<string, Object> = {
      'passw': oldPwd,
      'passwNew': newPwd,
      'passwNewAgain': confirmPwd
    };
    const result: BizJsonResult = await ApiService.bizJson(Api.CHANGE_PASSW_BY_OLD, 'POST', params);
    return new ApiResponse<Object>(result.code, result.message, result.data);
  }

  /** 源码 MyPageFragment.c2 → c/h/b/a.U0：GET getChangePasswUrlFromSchool
   *  响应 {type, lyyd3_change_password_fromSchool}：0=原生表单 / 1=确认弹窗 / 2=H5改密
   */
  static async getChangePasswUrlFromSchool(): Promise<ApiResponse<Record<string, Object>>> {
    const result: BizJsonResult = await ApiService.bizJson(Api.GET_CHANGE_PASSW_URL, 'GET', {});
    if (result.code === 0) {
      const rec = result.data as Record<string, Object>;
      return new ApiResponse<Record<string, Object>>(0, result.message, rec);
    }
    return new ApiResponse<Record<string, Object>>(result.code, result.message, {} as Record<string, Object>);
  }

  // ===== T3 misc-worker：意见反馈（源码实证 FeedbackPImpl + FeedbackModel）=====
  /** FeedbackTypes.java：{id:int, name:String}（问题模块类型） */
  static parseFeedbackTypes(data: Object): FeedbackTypeEntry[] {
    const items: FeedbackTypeEntry[] = [];
    const raw: Object[] = ApiService.extractArray(data);
    for (const one of raw) {
      const rec: Record<string, Object> = one as Record<string, Object>;
      items.push(new FeedbackTypeEntry(ApiService.pickNumber(rec, ['id']), ApiService.pick(rec, ['name'])));
    }
    return items;
  }

  /** 源码 FeedbackModel.X0：GET types（无参数；响应 data 明文数组，j=false 不解密） */
  static async getFeedbackTypes(): Promise<ApiResponse<FeedbackTypeEntry[]>> {
    const url: string = Api.FEEDBACK_HOST_DEFAULT + Api.FEEDBACK_TYPES;
    const resp: ApiResponse<Object> = await HttpClient.feedbackGet(url, {});
    if (resp.code === 0) {
      const types: FeedbackTypeEntry[] = ApiService.parseFeedbackTypes(resp.data);
      return new ApiResponse<FeedbackTypeEntry[]>(0, resp.message, types);
    }
    return new ApiResponse<FeedbackTypeEntry[]>(resp.code, resp.message, []);
  }

  /** 源码 FeedbackModel.V0：GET announcement {schoolId}（响应 data 明文 String 公告文本） */
  static async getFeedbackAnnouncement(): Promise<ApiResponse<string>> {
    const url: string = Api.FEEDBACK_HOST_DEFAULT + Api.FEEDBACK_ANNOUNCEMENT;
    const fields: Record<string, string> = { 'schoolId': LoginSession.schoolId };
    const resp: ApiResponse<Object> = await HttpClient.feedbackGet(url, fields);
    if (resp.code === 0 && typeof resp.data === 'string') {
      return new ApiResponse<string>(0, resp.message, resp.data as string);
    }
    return new ApiResponse<string>(resp.code, resp.message, '');
  }

  /** 源码 FeedbackModel.T0 + FeedbackPImpl.g：POST_MULTIPART submit/ciphertext
   *  data 字段 = AES(固定key, JSON(Bean3))（j=false 无外层加密，原样透传，HttpClient 通道同源码）；
   *  Bean3 = {userId,userName,xxdm,content,tel,typeId,mac}；mac=s.m()=设备型号；
   *  图片逐个以 keyName="imgs" 追加 multipart；响应 data 明文 Boolean（j=false）。
   */
  static async submitFeedback(content: string, contact: string, typeId: string,
    photoUris: string[]): Promise<ApiResponse<Object>> {
    try {
      const inner: Record<string, Object> = {
        'userId': LoginSession.userId,
        'userName': LoginSession.sessionName,
        'xxdm': LoginSession.schoolId,
        'content': content,
        'tel': contact,
        'typeId': typeId,
        'mac': Constants.DEVICE_MODEL
      };
      const innerKeyB64: string = CryptoUtil.bytesToBase64(
        CryptoUtil.base64ToBytes(Api.FEEDBACK_ENCRYPT_KEY_B64));
      const innerEnc: string = CryptoUtil.encryptAES(JSON.stringify(inner), innerKeyB64);
      const outerFields: Record<string, string> = { 'data': innerEnc };
      const url: string = Api.FEEDBACK_HOST_DEFAULT + Api.FEEDBACK_SUBMIT;
      return await HttpClient.feedbackSubmitMultipart(url, outerFields, photoUris);
    } catch (error) {
      ApiService.logError('submitFeedback fail: ' + (error as BusinessError).message);
      return new ApiResponse<Object>(ApiService.OFFLINE_CODE, '网络请求失败', new Object());
    }
  }

  /** 源码 FeedbackRecordActivity.M2 → FeedbackModel.W0：GET records/ciphertext
   *  data 字段 = AES(固定key, JSON(Bean1{userId,xxdm}))（j=false 无外层加密，普通 query 对透传）；
   *  响应 data 明文 JSON 数组（j=false）。schoolId 优先 lyyd3SchoolId（工程会话无此字段，用 schoolId）。
   */
  static async getFeedbackRecords(): Promise<ApiResponse<FeedbackRecordEntry[]>> {
    const empty: FeedbackRecordEntry[] = [];
    try {
      const inner: Record<string, Object> = {
        'userId': LoginSession.userId,
        'xxdm': LoginSession.schoolId
      };
      const innerKeyB64: string = CryptoUtil.bytesToBase64(
        CryptoUtil.base64ToBytes(Api.FEEDBACK_ENCRYPT_KEY_B64));
      const innerEnc: string = CryptoUtil.encryptAES(JSON.stringify(inner), innerKeyB64);
      const outerFields: Record<string, string> = { 'data': innerEnc };
      const url: string = Api.FEEDBACK_HOST_DEFAULT + Api.FEEDBACK_RECORDS;
      const resp: ApiResponse<Object> = await HttpClient.feedbackGet(url, outerFields);
      if (resp.code === 0) {
        const items: FeedbackRecordEntry[] = [];
        const raw: Object[] = ApiService.extractArray(resp.data);
        for (const one of raw) {
          const rec: Record<string, Object> = one as Record<string, Object>;
          const imgUrls: string[] = [];
          const rawImgs: Object[] = ApiService.extractArray(rec['imgUrls'] === undefined ?
            rec['imgs'] : rec['imgUrls']);
          for (const img of rawImgs) {
            if (typeof img === 'string') {
              imgUrls.push(img as string);
            }
          }
          items.push(new FeedbackRecordEntry(
            ApiService.pickNumber(rec, ['id']),
            ApiService.pick(rec, ['content']),
            ApiService.pickNumber(rec, ['time']),
            ApiService.pick(rec, ['status']),
            ApiService.pick(rec, ['typeName']),
            imgUrls
          ));
        }
        return new ApiResponse<FeedbackRecordEntry[]>(0, resp.message, items);
      }
      return new ApiResponse<FeedbackRecordEntry[]>(resp.code, resp.message, empty);
    } catch (error) {
      ApiService.logError('getFeedbackRecords fail: ' + (error as BusinessError).message);
      return new ApiResponse<FeedbackRecordEntry[]>(ApiService.OFFLINE_CODE, '网络请求失败', empty);
    }
  }

  /** 源码 FeedbackRecordAdapter.getStateString：status → 文案 */
  static feedbackStateText(status: string): string {
    if (status === '0') {
      return '待处理';
    }
    if (status === '1') {
      return '处理中';
    }
    if (status === '2') {
      return '不处理';
    }
    if (status === '3') {
      return '已处理';
    }
    if (status === '4') {
      return '已上报';
    }
    return '';
  }

  // ===== [TodoPage worker] OA 待办（TodoMainActivity+TodoFragment 源码级翻译） =====
  /** 源码 TodoModel.g1：GET tab → TodoTab[]（TodoMainActivity.O2 → P.S(...).z()） */
  static async getOaTodoTabs(): Promise<ApiResponse<TodoTabOA[]>> {
    const result: BizJsonResult = await ApiService.bizJson(Api.OA_TODO_TAB, 'GET', {});
    if (result.code === 0) {
      const tabs: TodoTabOA[] = [];
      const raw: Object[] = ApiService.extractArray(result.data);
      for (const one of raw) {
        tabs.push(TodoTabOA.fromRecord(ApiService.asRecord(one)));
      }
      return new ApiResponse<TodoTabOA[]>(0, result.message, tabs);
    }
    return new ApiResponse<TodoTabOA[]>(result.code, result.message, []);
  }

  /** 源码 TodoModel.f1（P.B）：GET list {pageSize:"10", pageNum, rule} → TodoListBean{rows,total}
   *  2026-11-17 实测：参数进加密 data=，明文 query 返回 0001；pageSize=AgooConstants.ACK_REMOVE_PACKAGE="10"
   *  RowsBean 字段逆转义：TodoMainItemAdapter.setDatas/addDatas → TodoUtils.o（反射 unescapeHtml3） */
  static async getOaTodoList(rule: string, pageNum: number): Promise<ApiResponse<OaTodoList>> {
    const params: Record<string, Object> = {
      'pageSize': '10',
      'pageNum': String(pageNum),
      'rule': rule
    };
    const result: BizJsonResult = await ApiService.bizJson(Api.OA_TODO_LIST, 'GET', params);
    if (result.code === 0) {
      const rec: Record<string, Object> = ApiService.asRecord(result.data);
      const list: OaTodoList = new OaTodoList();
      list.total = ApiService.pick(rec, ['total']);
      const raw: Object[] = ApiService.extractArray(result.data);
      for (const one of raw) {
        list.rows.push(ApiService.parseOaTodoRow(one));
      }
      return new ApiResponse<OaTodoList>(0, result.message, list);
    }
    return new ApiResponse<OaTodoList>(result.code, result.message, new OaTodoList());
  }

  /** TodoListBean.rows 单行解析 + TodoUtils.o 全字段逆转义 */
  static parseOaTodoRow(one: Object): OaTodoRow {
    const row: OaTodoRow = OaTodoRow.fromRecord(ApiService.asRecord(one));
    const keys: string[] = ['addName_cn', 'appid', 'author', 'author_cn', 'bpmRequestRuleUrl', 'content',
      'currentnodeid', 'currentnodename', 'docCreated', 'docNumber', 'draftDep_cn', 'followStatus', 'hj',
      'loseEfficacyTime', 'mj', 'nodeName', 'orUnid', 'processId', 'processName', 'startTime', 'subject',
      'totalTime', 'type', 'url'];
    for (const key of keys) {
      row.setField(key, ApiService.unescapeHtml3(row.getField(key)));
    }
    return row;
  }

  /** 源码 TodoModel.c1：GET messagesChannel → MessageChannelBean[]（添加关注渠道弹窗；实测本服务器 code=-1 oa关注服务异常，走空列表） */
  static async getOaTodoChannels(): Promise<ApiResponse<OaChannel[]>> {
    const result: BizJsonResult = await ApiService.bizJson(Api.OA_TODO_MESSAGES_CHANNEL, 'GET', {});
    if (result.code === 0) {
      const channels: OaChannel[] = [];
      const raw: Object[] = ApiService.extractArray(result.data);
      for (const one of raw) {
        const rec: Record<string, Object> = ApiService.asRecord(one);
        const ch: OaChannel = new OaChannel();
        ch.terminalId = ApiService.pick(rec, ['terminalId', 'id']);
        ch.terminalName = ApiService.pick(rec, ['terminalName', 'name']);
        const sel: Object = rec['isSelect'];
        ch.isSelect = sel === true || sel === 'true' || sel === 1 || sel === '1';
        channels.push(ch);
      }
      return new ApiResponse<OaChannel[]>(0, result.message, channels);
    }
    return new ApiResponse<OaChannel[]>(result.code, result.message, []);
  }

  /** 源码 TodoModel.T0（P.n）：POST addFollows {docUnids, channels(逗号拼接 terminalId)} */
  static async addOaFollows(docUnids: string, channels: string): Promise<ApiResponse<Object>> {
    const params: Record<string, Object> = { 'docUnids': docUnids, 'channels': channels };
    const result: BizJsonResult = await ApiService.bizJson(Api.OA_TODO_ADD_FOLLOWS, 'POST', params);
    return new ApiResponse<Object>(result.code, result.message, result.data);
  }

  /** 源码 TodoModel.V0（P.p）：POST deleteFollows {docUnids} */
  static async deleteOaFollows(docUnids: string): Promise<ApiResponse<Object>> {
    const params: Record<string, Object> = { 'docUnids': docUnids };
    const result: BizJsonResult = await ApiService.bizJson(Api.OA_TODO_DELETE_FOLLOWS, 'POST', params);
    return new ApiResponse<Object>(result.code, result.message, result.data);
  }

  // ===== [W14 todo-series] TodoReadActivity / TodoSearchActivity / TodoFastreplyActivity / EditTodoDetailActivity 数据管道 =====

  /** 源码 TodoModel.h1（P.A）：GET newTab → TodoTab[]（TodoReadActivity.N2 → n.V(...).A()） */
  static async getOaTodoNewTabs(): Promise<ApiResponse<TodoTabOA[]>> {
    const result: BizJsonResult = await ApiService.bizJson(Api.OA_TODO_NEW_TAB, 'GET', {});
    if (result.code === 0) {
      const tabs: TodoTabOA[] = [];
      const raw: Object[] = ApiService.extractArray(result.data);
      for (const one of raw) {
        tabs.push(TodoTabOA.fromRecord(ApiService.asRecord(one)));
      }
      return new ApiResponse<TodoTabOA[]>(0, result.message, tabs);
    }
    return new ApiResponse<TodoTabOA[]>(result.code, result.message, []);
  }

  /** 源码 TodoModel.n1（P.D）：GET search {keyword, pageNum, pageSize:"20"(TodoPImpl.D 固定串)} → TodoSearch[]{name,type,rows}
   *  2026-11-18 实测：明文 query 返回 0001 系统异常；参数进加密 data=（与 list 同管道，bizJson 形态正确） */
  static async searchOaTodo(keyword: string, pageNum: number): Promise<ApiResponse<OaTodoSearchGroup[]>> {
    const params: Record<string, Object> = {
      'keyword': keyword,
      'pageNum': String(pageNum),
      'pageSize': '20'
    };
    const result: BizJsonResult = await ApiService.bizJson(Api.OA_TODO_SEARCH, 'GET', params);
    if (result.code === 0) {
      const groups: OaTodoSearchGroup[] = [];
      const raw: Object[] = ApiService.extractArray(result.data);
      for (const one of raw) {
        const rec: Record<string, Object> = ApiService.asRecord(one);
        const group: OaTodoSearchGroup = new OaTodoSearchGroup();
        group.name = ApiService.unescapeHtml3(ApiService.pick(rec, ['name']));
        group.type = ApiService.pick(rec, ['type']);
        const rowsRaw: Object[] = ApiService.extractArray(one);
        for (const rowOne of rowsRaw) {
          group.rows.push(ApiService.parseOaTodoRow(rowOne));
        }
        groups.push(group);
      }
      return new ApiResponse<OaTodoSearchGroup[]>(0, result.message, groups);
    }
    return new ApiResponse<OaTodoSearchGroup[]>(result.code, result.message, []);
  }

  /** 源码 TodoModel.d1（P.x）：GET remark → String[]（TodoFastreplyActivity.X2 → o.O(...).x()） */
  static async getOaFastReplies(): Promise<ApiResponse<string[]>> {
    const result: BizJsonResult = await ApiService.bizJson(Api.OA_TODO_REMARK, 'GET', {});
    if (result.code === 0) {
      const replies: string[] = [];
      const raw: Object[] = ApiService.extractArray(result.data);
      for (const one of raw) {
        if (typeof one === 'string') {
          replies.push(one as string);
        } else {
          replies.push(ApiService.pick(ApiService.asRecord(one), ['remark', 'name', 'value']));
        }
      }
      return new ApiResponse<string[]>(0, result.message, replies);
    }
    return new ApiResponse<string[]>(result.code, result.message, []);
  }

  /** 源码 TodoModel.Y0（P.s）：POST updateOpinion {remark:"[!_!]".join(list)}（TodoFastreplyActivity.s(str)→f12039a.Y0） */
  static async updateOaFastReplies(joined: string): Promise<ApiResponse<Object>> {
    const params: Record<string, Object> = { 'remark': joined };
    const result: BizJsonResult = await ApiService.bizJson(Api.OA_TODO_UPDATE_OPINION, 'POST', params);
    return new ApiResponse<Object>(result.code, result.message, result.data);
  }

  /** 源码 TodoModel.j1（P.C）：GET transactionDetails {xlh, todo_type, currentnodeid} → TodoDetail
   *  （TodoDetailActivity.E3：xlh=orUnid、todo_type=type、currentnodeid=bean.currentnodeid 空传""） */
  static async getOaTodoDetail(xlh: string, todoType: string, currentnodeid: string): Promise<ApiResponse<OaTodoDetail>> {
    const params: Record<string, Object> = {
      'xlh': xlh,
      'todo_type': todoType,
      'currentnodeid': currentnodeid
    };
    const result: BizJsonResult = await ApiService.bizJson(Api.OA_TODO_TRANSACTION_DETAILS, 'GET', params);
    if (result.code === 0) {
      const rec: Record<string, Object> = ApiService.asRecord(result.data);
      const detail: OaTodoDetail = new OaTodoDetail();
      const fields: Object[] = ApiService.extractArray(rec['formFieldConfigList']);
      for (const one of fields) {
        const form: OaFormField = OaFormField.fromRecord(ApiService.asRecord(one));
        form.fieldValue = ApiService.unescapeHtml3(form.fieldValue);
        form.fieldScreenName = ApiService.unescapeHtml3(form.fieldScreenName);
        form.fieldRemark = ApiService.unescapeHtml3(form.fieldRemark);
        form.fieldAnotherValue = ApiService.unescapeHtml3(form.fieldAnotherValue);
        detail.formFieldConfigList.push(form);
      }
      const infoOne: Object = rec['itemBasicInfoMap'];
      if (infoOne !== null && infoOne !== undefined) {
        detail.itemBasicInfoMap = ApiService.parseOaTodoRow(infoOne);
      }
      // [W19 workapply] 详情页消费区：processFlowDocList + bpmAttachList（ProcedureLayout/附件 widget 同源）
      for (const one of ApiService.parseChildArray(result.data, 'processFlowDocList')) {
        detail.processFlowDocList.push(OaWorkApplyFlowNode.fromRecord(ApiService.asRecord(one)));
      }
      for (const one of ApiService.parseChildArray(result.data, 'bpmAttachList')) {
        detail.bpmAttachList.push(OaWorkApplyAttach.fromRecord(ApiService.asRecord(one)));
      }
      return new ApiResponse<OaTodoDetail>(0, result.message, detail);
    }
    return new ApiResponse<OaTodoDetail>(result.code, result.message, new OaTodoDetail());
  }

  /** 源码 TodoUtils.p：commons-lang3 StringEscapeUtils.unescapeHtml3 单遍扫描（named+numeric 实体，&amp;lt; → &lt; 单层） */
  static unescapeHtml3(input: string): string {
    if (input.indexOf('&') < 0) {
      return input;
    }
    let out: string = '';
    let i: number = 0;
    while (i < input.length) {
      if (input[i] !== '&') {
        out += input[i];
        i++;
        continue;
      }
      const semi: number = input.indexOf(';', i + 1);
      if (semi < 0 || semi > i + 12) {
        out += input[i];
        i++;
        continue;
      }
      const body: string = input.substring(i + 1, semi);
      const decoded: string = ApiService.unescapeEntity(body);
      if (decoded === '') {
        out += input[i];
        i++;
      } else {
        out += decoded;
        i = semi + 1;
      }
    }
    return out;
  }

  /** 单个实体名 → 字符（未识别返回 '' 保持原样） */
  private static unescapeEntity(body: string): string {
    if (body.length > 1 && body[0] === '#') {
      const isHex: boolean = body[1] === 'x' || body[1] === 'X';
      const num: number = Number(isHex ? body.substring(2) : body.substring(1));
      if (!Number.isNaN(num) && num > 0 && num <= 0x10ffff) {
        try {
          return String.fromCodePoint(num);
        } catch (error) {
          return '';
        }
      }
      return '';
    }
    if (body === 'amp') {
      return '&';
    }
    if (body === 'lt') {
      return '<';
    }
    if (body === 'gt') {
      return '>';
    }
    if (body === 'quot') {
      return '"';
    }
    if (body === 'apos') {
      return '\'';
    }
    if (body === 'nbsp') {
      return '\u00A0';
    }
    if (body === 'copy') {
      return '\u00A9';
    }
    if (body === 'reg') {
      return '\u00AE';
    }
    if (body === 'hellip') {
      return '\u2026';
    }
    if (body === 'mdash') {
      return '\u2014';
    }
    if (body === 'ndash') {
      return '\u2013';
    }
    if (body === 'middot') {
      return '\u00B7';
    }
    return '';
  }

  // ===== [W19 workapply] 业务申请链 6 页数据层（ApplyPImpl→ApplyModel 源码级，2026-11-18 探针实测） =====

  /** 源码 WorkApplyAdapter.h()/WorkApplyListAdapter.h()：c.b.o 单字段 HTML 逆转义 */
  private static unescapeWorkApplyRow(row: OaWorkApplyRow): OaWorkApplyRow {
    const keys: string[] = ['addname_cn', 'appid', 'author_cn', 'bussStatus', 'currentNodeName',
      'currentnodeid', 'docCreated', 'docNumber', 'orUnid', 'processName', 'processid', 'subject'];
    for (const key of keys) {
      row.setField(key, ApiService.unescapeHtml3(ApiService.getFieldOf(row, key)));
    }
    return row;
  }

  /** OaWorkApplyRow 单字段读取（镜像 setField） */
  private static getFieldOf(row: OaWorkApplyRow, key: string): string {
    if (key === 'addname_cn') { return row.addname_cn; } else if (key === 'appid') { return row.appid; }
    else if (key === 'author_cn') { return row.author_cn; } else if (key === 'bussStatus') { return row.bussStatus; }
    else if (key === 'currentNodeName') { return row.currentNodeName; } else if (key === 'currentnodeid') { return row.currentnodeid; }
    else if (key === 'docCreated') { return row.docCreated; } else if (key === 'docNumber') { return row.docNumber; }
    else if (key === 'orUnid') { return row.orUnid; } else if (key === 'processName') { return row.processName; }
    else if (key === 'processid') { return row.processid; } else if (key === 'subject') { return row.subject; }
    return '';
  }

  /**
   * 源码 ApplyModel.U0（WorkApplyActivity.V2）：GET processList（无参）→ WorkApply[]
   * 2026-11-18 实测 code=0：4 流程（信访事项受理/通知公告/会议室申请/处级干部外出报备）。
   */
  static async getWorkApplyProcessList(): Promise<ApiResponse<WorkApplyEntry[]>> {
    const result: BizJsonResult = await ApiService.bizJson(Api.WORKAPPLY_PROCESS_LIST, 'GET', {});
    if (result.code === 0) {
      const list: WorkApplyEntry[] = [];
      for (const one of ApiService.extractArray(result.data)) {
        list.push(WorkApplyEntry.fromRecord(ApiService.asRecord(one)));
      }
      return new ApiResponse<WorkApplyEntry[]>(0, result.message, list);
    }
    return new ApiResponse<WorkApplyEntry[]>(result.code, result.message, []);
  }

  /**
   * 源码 ApplyModel.W0（WorkApplyActivity.W2）：GET myApply {pageSize:"1000", pageNum} → MyApplyList
   * rows 逐行 HTML 逆转义（WorkApplyListAdapter.h）。2026-11-18 实测 total=0 rows=0（真实空态）。
   */
  static async getMyApplyList(pageNum: number): Promise<ApiResponse<OaWorkApplyList>> {
    const params: Record<string, Object> = {
      'pageSize': Api.WORKAPPLY_MY_PAGE_SIZE,
      'pageNum': String(pageNum)
    };
    const result: BizJsonResult = await ApiService.bizJson(Api.WORKAPPLY_MY_APPLY, 'GET', params);
    if (result.code === 0) {
      const list: OaWorkApplyList = ApiService.parseMyApplyList(result.data);
      return new ApiResponse<OaWorkApplyList>(0, result.message, list);
    }
    return new ApiResponse<OaWorkApplyList>(result.code, result.message, new OaWorkApplyList());
  }

  /**
   * 源码 ApplyModel.X0（WorkApplyScreenActivity.L2 / WorkApplyActivity.X2）：
   * GET screen {pageSize:AgooConstants.ACK_REMOVE_PACKAGE="10", pageNum, processid} → MyApplyList
   */
  static async screenMyApplyList(pageNum: string, processid: string): Promise<ApiResponse<OaWorkApplyList>> {
    const params: Record<string, Object> = {
      'pageSize': Api.WORKAPPLY_SCREEN_PAGE_SIZE,
      'pageNum': pageNum,
      'processid': processid
    };
    const result: BizJsonResult = await ApiService.bizJson(Api.WORKAPPLY_SCREEN, 'GET', params);
    if (result.code === 0) {
      const list: OaWorkApplyList = ApiService.parseMyApplyList(result.data);
      return new ApiResponse<OaWorkApplyList>(0, result.message, list);
    }
    return new ApiResponse<OaWorkApplyList>(result.code, result.message, new OaWorkApplyList());
  }

  /** MyApplyList{rows,total} 统一解析（含 HTML 逆转义） */
  private static parseMyApplyList(data: Object): OaWorkApplyList {
    const rec: Record<string, Object> = ApiService.asRecord(data);
    const list: OaWorkApplyList = new OaWorkApplyList();
    list.total = ApiService.pick(rec, ['total']);
    for (const one of ApiService.extractArray(data)) {
      list.rows.push(ApiService.unescapeWorkApplyRow(OaWorkApplyRow.fromRecord(ApiService.asRecord(one))));
    }
    return list;
  }

  /**
   * 源码 ApplyModel.V0（WorkApplyFormConfigActivity.e3）：GET formConfig {processid} → WorkApplyDetail
   * formFieldConfigList 逆转义（WorkApplyDetail 页 m3 渲染前 c.b.o 语义）。
   * 2026-11-18 实测：信访事项受理 11 字段，bpmRequestRuleUrl='http://oa.sdmu.edu.cn//bpm/r?wf_num='。
   */
  static async getWorkApplyFormConfig(processid: string): Promise<ApiResponse<OaWorkApplyDetail>> {
    const params: Record<string, Object> = { 'processid': processid };
    const result: BizJsonResult = await ApiService.bizJson(Api.WORKAPPLY_FORM_CONFIG, 'GET', params);
    if (result.code === 0) {
      const rec: Record<string, Object> = ApiService.asRecord(result.data);
      const detail: OaWorkApplyDetail = new OaWorkApplyDetail();
      for (const one of ApiService.parseChildArray(result.data, 'formFieldConfigList')) {
        const form: OaFormField = OaFormField.fromRecord(ApiService.asRecord(one));
        form.fieldValue = ApiService.unescapeHtml3(form.fieldValue);
        form.fieldScreenName = ApiService.unescapeHtml3(form.fieldScreenName);
        form.fieldRemark = ApiService.unescapeHtml3(form.fieldRemark);
        form.fieldAnotherValue = ApiService.unescapeHtml3(form.fieldAnotherValue);
        detail.formFieldConfigList.push(form);
      }
      const infoOne: Object = rec['itemBasicInfoMap'];
      if (infoOne !== null && infoOne !== undefined) {
        detail.bpmRequestRuleUrl =
          ApiService.pick(ApiService.asRecord(infoOne), ['bpmRequestRuleUrl']);
      }
      return new ApiResponse<OaWorkApplyDetail>(0, result.message, detail);
    }
    return new ApiResponse<OaWorkApplyDetail>(result.code, result.message, new OaWorkApplyDetail());
  }

  /**
   * 源码 ApplyModel.Y0（WorkApplyDetailActivity.s3 催办）：POST sendBuss body {property, message}
   * property = {LX:"1",processId,YYID:"todoitem_detail",yhid:author,XLH:orUnid,nodeName}；
   * message = {title,content}=subject。写端点：测试账号无 OA 数据，探针跳过实测（管道与源码一致）。
   */
  static async sendWorkApplyUrge(property: string, message: string): Promise<ApiResponse<Object>> {
    const params: Record<string, Object> = { 'property': property, 'message': message };
    const result: BizJsonResult = await ApiService.bizJson(Api.WORKAPPLY_SEND_BUSS, 'POST', params);
    return new ApiResponse<Object>(result.code, result.message, result.data);
  }

  // ===== [E2 message worker] 消息模块（MessageListActivity+MessageFragment 源码级翻译） =====
  /** 源码 MessageModel.X0：POST getDateMessage {stateCode, page} → MainNotificationV2[]
   *  stateCode：1=未读 2=已读 3=全部（MessageFragment m）；page：RefreshFragment.g */
  static async getMessageList(stateCode: string, page: number): Promise<ApiResponse<MainNotificationV2[]>> {
    const params: Record<string, Object> = { 'stateCode': stateCode, 'page': String(page) };
    const result: BizJsonResult = await ApiService.bizJson(Api.MESSAGE_GET_DATE_MESSAGE, 'POST', params);
    if (result.code === 0) {
      const rows: MainNotificationV2[] = [];
      const raw: Object[] = ApiService.extractArray(result.data);
      for (const one of raw) {
        rows.push(MainNotificationV2.fromRecord(ApiService.asRecord(one)));
      }
      return new ApiResponse<MainNotificationV2[]>(0, result.message, rows);
    }
    return new ApiResponse<MainNotificationV2[]>(result.code, result.message, []);
  }

  /** 源码 MessageModel.U0（h.d.f）：GET delete {xlh, isEmc?}（isEmc==1 才传 "1"，源码 TextUtils.isEmpty 分支） */
  static async deleteMessage(xlh: string, isEmc: number): Promise<ApiResponse<Object>> {
    const params: Record<string, Object> = { 'xlh': xlh };
    if (isEmc === 1) {
      params['isEmc'] = '1';
    }
    const result: BizJsonResult = await ApiService.bizJson(Api.MESSAGE_DELETE, 'GET', params);
    return new ApiResponse<Object>(result.code, result.message, result.data);
  }

  /** 源码 MessageModel.a1（h.d.q）：GET updateState {xlh, batchId, isEmc?}（标记已读） */
  static async updateMessageState(xlh: string, batchId: string, isEmc: number): Promise<ApiResponse<Object>> {
    const params: Record<string, Object> = { 'xlh': xlh, 'batchId': batchId };
    if (isEmc === 1) {
      params['isEmc'] = '1';
    }
    const result: BizJsonResult = await ApiService.bizJson(Api.MESSAGE_UPDATE_STATE, 'GET', params);
    return new ApiResponse<Object>(result.code, result.message, result.data);
  }

  /** 源码 MessageModel.T0（h.d.e）：POST batchdelete {xlhs}（xlhs=JSON 数组串，M2 批量删除） */
  static async batchDeleteMessages(xlhs: string[]): Promise<ApiResponse<Object>> {
    const ids: string[] = xlhs;
    const params: Record<string, Object> = { 'xlhs': JSON.stringify(ids) };
    const result: BizJsonResult = await ApiService.bizJson(Api.MESSAGE_BATCH_DELETE, 'POST', params);
    return new ApiResponse<Object>(result.code, result.message, result.data);
  }

  /** 源码 MessageModel.V0（h.d.g）：POST alldelete {stateCode}
   *  O2：单页签=3，双页签 t==0=1（未读）t!=0=2（已读） */
  static async allDeleteMessages(stateCode: string): Promise<ApiResponse<Object>> {
    const params: Record<string, Object> = { 'stateCode': stateCode };
    const result: BizJsonResult = await ApiService.bizJson(Api.MESSAGE_ALL_DELETE, 'POST', params);
    return new ApiResponse<Object>(result.code, result.message, result.data);
  }

  /** 源码 MessageModel.Y0（h.d.k）：GET allUpdateState（无参数，全部标记已读） */
  static async allUpdateMessageState(): Promise<ApiResponse<Object>> {
    const result: BizJsonResult = await ApiService.bizJson(Api.MESSAGE_ALL_UPDATE_STATE, 'GET', {});
    return new ApiResponse<Object>(result.code, result.message, result.data);
  }

  // ===== [W12 message-series] 通知列表（MainNotificationV2Activity）/ EMC 消息详情 =====

  /** 源码 MessageModel.W0（h.d.i）：POST getDateMessage {page}（MainNotificationV2Activity.Y2 只传 page，无 stateCode；
   *  2026-11-18 实测 15 行/页，与 {stateCode:"3",page} 同返回） */
  static async getNotificationList(page: number): Promise<ApiResponse<MainNotificationV2[]>> {
    const params: Record<string, Object> = { 'page': String(page) };
    const result: BizJsonResult = await ApiService.bizJson(Api.NOTIFICATION_GET_DATE_MESSAGE, 'POST', params);
    if (result.code === 0) {
      const rows: MainNotificationV2[] = [];
      const raw: Object[] = ApiService.extractArray(result.data);
      for (const one of raw) {
        rows.push(MainNotificationV2.fromRecord(ApiService.asRecord(one)));
      }
      return new ApiResponse<MainNotificationV2[]>(0, result.message, rows);
    }
    return new ApiResponse<MainNotificationV2[]>(result.code, result.message, []);
  }

  /** 源码 MessageModel.Z0（h.d.p）：GET updateState {xlh, isEmc?}（MainNotificationV2Activity.b3 标记已读，无 batchId） */
  static async updateNotificationState(xlh: string, isEmc: number): Promise<ApiResponse<Object>> {
    const params: Record<string, Object> = { 'xlh': xlh };
    if (isEmc === 1) {
      params['isEmc'] = '1';
    }
    const result: BizJsonResult = await ApiService.bizJson(Api.NOTIFICATION_UPDATE_STATE, 'GET', params);
    return new ApiResponse<Object>(result.code, result.message, result.data);
  }

  /** 源码 MessageModel.delete（h.d.f → U0）：GET delete {xlh, isEmc?}（MainNotificationV2Activity.X2 长按删除） */
  static async deleteNotification(xlh: string, isEmc: number): Promise<ApiResponse<Object>> {
    return ApiService.deleteMessage(xlh, isEmc);
  }

  /**
   * 源码 MessageDetailModel.T0（main/g/d.java）：GET EmcMessageContent {magId:xlh, channelCode}，j=false 明文管道。
   * 2026-11-18 实测 code=0，data=明文正文串（"【上课通知】明天有课…"）。
   */
  static async getEmcMessageContent(magId: string, channelCode: string): Promise<ApiResponse<Object>> {
    const params: Record<string, string> = { 'magId': magId, 'channelCode': channelCode };
    return HttpClient.plainBizGet(Api.EMC_MESSAGE_CONTENT, params);
  }

  // ===== [W12 message-series] 校圈消息 push 链（PushModel 源码级；域名校园网不可达→真实空态） =====

  /** 源码 PushModel.l（MsgPresenter.b）：POST getPushMsgList {type:"circle", page, pageSize:"20"} + xxdm 头 */
  static async getPushMsgList(type: string, page: number, pageSize: number): Promise<ApiResponse<Object>> {
    const params: Record<string, Object> = {
      'type': type, 'page': String(page), 'pageSize': String(pageSize)
    };
    return HttpClient.pushBizPost(Api.PUSH_HOST + Api.PUSH_GET_MSG_LIST, params);
  }

  /** 源码 PushModel.b0（MsgPresenter.c）：POST hasRead {id, type} + xxdm 头（条目点击标记已读） */
  static async pushHasRead(id: string, type: string): Promise<ApiResponse<Object>> {
    const params: Record<string, Object> = { 'id': id, 'type': type };
    return HttpClient.pushBizPost(Api.PUSH_HOST + Api.PUSH_HAS_READ, params);
  }

  /** 源码 PushModel.I0（CountPresenter.b）：POST getNoReadCount {type} + xxdm 头（"N条新消息"角标） */
  static async getPushNoReadCount(type: string): Promise<ApiResponse<Object>> {
    const params: Record<string, Object> = { 'type': type };
    return HttpClient.pushBizPost(Api.PUSH_HOST + Api.PUSH_GET_NO_READ_COUNT, params);
  }

  /**
   * 源码 SocialModel.J（social/d/b/b.java）：GET getAvatarByUser {userIds:"id1,id2"}（校内域名，e.b=GET data=）。
   * SocialUserAvatarUtil 补头像链（ext.picture 空时按 userId 批量取 TX）。
   */
  static async getSocialAvatars(userIds: string): Promise<ApiResponse<Object>> {
    const params: Record<string, Object> = { 'userIds': userIds };
    const result: BizJsonResult = await ApiService.bizJson(Api.SOCIAL_AVATAR_BY_USER, 'GET', params);
    if (result.code === 0) {
      const rows: Object[] = ApiService.extractArray(result.data);
      const list: Object[] = [];
      for (const one of rows) {
        list.push(one);
      }
      return new ApiResponse<Object>(0, result.message, list as Object);
    }
    return new ApiResponse<Object>(result.code, result.message, new Object());
  }

  // ===== [W20 social] 校圈链 6 页（SocialModel/MarketModel/FriendshipFactory 源码级双通道） =====
  // 校内 circleOpen 读链：2026-11-18 实测全部 code=0001 系统异常（端点在、数据层未启用）
  //   → 调用方按 code!=0 走真实错误态（message 透传），绝不编造帖子/评论/点赞数据。
  // push 域（yibaogao.com）：2026-11-18 实测不可达（WinError 10054/SSL EOF）
  //   → 真实网络失败，message='网络请求失败: ...'。

  /** SocialModel.y0（hasSchoolCirclePhone=false 分支）：POST getCircleInfo {id} */
  static async getCircleInfo(id: string): Promise<BizJsonResult> {
    return ApiService.bizJson(Api.CIRCLE_OPEN_GET_CIRCLE_INFO, 'POST', { 'id': id });
  }

  /** SocialModel.o0：POST getCircleComments {circleId,pageNum,pageSize} */
  static async getCircleComments(circleId: string, pageNum: number, pageSize: number): Promise<BizJsonResult> {
    const params: Record<string, Object> = {
      'circleId': circleId, 'pageNum': String(pageNum), 'pageSize': String(pageSize)
    };
    return ApiService.bizJson(Api.CIRCLE_OPEN_GET_CIRCLE_COMMENTS, 'POST', params);
  }

  /** SocialModel.E：POST getCircleLikes {circleId} */
  static async getCircleLikes(circleId: string): Promise<BizJsonResult> {
    return ApiService.bizJson(Api.CIRCLE_OPEN_GET_CIRCLE_LIKES, 'POST', { 'circleId': circleId });
  }

  /** MarketModel.d1：POST getMarketInfo {id} */
  static async getMarketInfo(id: string): Promise<BizJsonResult> {
    return ApiService.bizJson(Api.CIRCLE_OPEN_GET_MARKET_INFO, 'POST', { 'id': id });
  }

  /** MarketModel.b1：POST getMarketComments {circleId,pageNum,pageSize} */
  static async getMarketComments(circleId: string, pageNum: number, pageSize: number): Promise<BizJsonResult> {
    const params: Record<string, Object> = {
      'circleId': circleId, 'pageNum': pageNum, 'pageSize': pageSize
    };
    return ApiService.bizJson(Api.CIRCLE_OPEN_GET_MARKET_COMMENTS, 'POST', params);
  }

  /** MarketModel.f1：POST getMarketLikes {circleId} */
  static async getMarketLikes(circleId: string): Promise<BizJsonResult> {
    return ApiService.bizJson(Api.CIRCLE_OPEN_GET_MARKET_LIKES, 'POST', { 'circleId': circleId });
  }

  // ===== [W28 final-b] 集市列表链（MarketActivity/MarketPImpl 源码级）=====
  /** MarketModel.h1（hasSchoolCirclePhone=false）：POST_CONTENT getMarketList {lastId}
   *  （e.d body=加密 JSON，[W28 review] 实证 MarketModel.java L166-170） */
  static async getMarketList(lastId: string): Promise<BizJsonResult> {
    return ApiService.bizJson(Api.CIRCLE_OPEN_GET_MARKET_LIST, 'POST', { 'lastId': lastId });
  }

  /** MarketModel.Y0（hasSchoolCirclePhone=false）：POST_CONTENT serchMarketList
   *  {lastId[,marketType,marketStatus],keyWord}（e.d body=加密 JSON；
   *  [W28 review] 源码 Y0 仅在 marketType/marketStatus 至少一个非空时才放入 map） */
  static async searchMarketList(lastId: string, marketType: string, marketStatus: string,
    keyWord: string): Promise<BizJsonResult> {
    const params: Record<string, Object> = { 'lastId': lastId };
    if (marketType !== '' || marketStatus !== '') {
      params['marketType'] = marketType;
      params['marketStatus'] = marketStatus;
    }
    params['keyWord'] = keyWord;
    return ApiService.bizJson(Api.CIRCLE_OPEN_SERCH_MARKET_LIST, 'POST', params);
  }

  /** MarketModel.g1（hasSchoolCirclePhone=true）：GET freshNewList {lastId} @ push 域 */
  static async pushGetMarketFreshList(lastId: string): Promise<BizJsonResult> {
    const response: ApiResponse<Object> = await HttpClient.pushBizGet(
      Api.PUSH_HOST + Api.MARKET_LIANYI_FRESH_NEW_LIST, { 'lastId': lastId });
    return ApiService.parsePushBizResult(response);
  }

  /** MarketModel.X0（hasSchoolCirclePhone=true）：GET serchFreshNewList
   *  {lastId[,marketType,marketStatus],keyWord} @ push 域（源码条件拼参） */
  static async pushSearchMarketFreshList(lastId: string, marketType: string, marketStatus: string,
    keyWord: string): Promise<BizJsonResult> {
    const params: Record<string, Object> = { 'lastId': lastId };
    if (marketType !== '' || marketStatus !== '') {
      params['marketType'] = marketType;
      params['marketStatus'] = marketStatus;
    }
    params['keyWord'] = keyWord;
    const response: ApiResponse<Object> = await HttpClient.pushBizGet(
      Api.PUSH_HOST + Api.MARKET_LIANYI_SERCH_FRESH_NEW_LIST, params);
    return ApiService.parsePushBizResult(response);
  }

  /** pushBizGet/pushBizPost 响应 → BizJsonResult（push 域响应 data 同样为加密串，HttpClient 已解） */
  static parsePushBizResult(response: ApiResponse<Object>): BizJsonResult {
    if (response.code !== 0) {
      return { code: response.code, message: response.message, data: response.data };
    }
    if (typeof response.data === 'string' && (response.data as string) !== '') {
      try {
        const parsed: Object = JSON.parse(response.data as string) as Object;
        return { code: 0, message: response.message, data: parsed };
      } catch (error) {
        const be = error as BusinessError;
        ApiService.logError('push parse fail: ' + be.message);
        return { code: ApiService.OFFLINE_CODE, message: '解密数据解析失败', data: new Object() };
      }
    }
    return { code: 0, message: response.message, data: response.data };
  }

  /** SocialModel.K0：POST addviewnum {xlh}（校内直连，实测 code=0 data="false"） */
  static async addViewNum(xlh: string): Promise<ApiResponse<Object>> {
    return HttpClient.bizRequest(Api.CIRCLE_ADDVIEWNUM, 'POST', { 'xlh': xlh });
  }

  /** GetUserInfoModel.R（c/b/b/b/b/a.java）：POST getUserInfo {targetSchoolId,targetUserId,targetUserType,type} */
  static async getTargetUserInfo(targetSchoolId: string, targetUserId: string,
    targetUserType: string): Promise<BizJsonResult> {
    const params: Record<string, Object> = {
      'targetSchoolId': targetSchoolId, 'targetUserId': targetUserId,
      'targetUserType': targetUserType, 'type': ''
    };
    return ApiService.bizJson(Api.USER_INFO, 'POST', params);
  }

  // ---- push 域写/读通道（源码忠实；实测不可达 → 真实错误态） ----

  /** SocialModel.J0：POST likeOperator {circleId,setLike} + xxdm 头 */
  static async pushLikeOperator(circleId: string, setLike: string): Promise<ApiResponse<Object>> {
    return HttpClient.pushBizPost(Api.PUSH_HOST + Api.CIRCLE_LIANYI_LIKE_OPERATOR,
      { 'circleId': circleId, 'setLike': setLike });
  }

  /** SocialModel.w0：POST sendComment {content,circleId,targetUserId,targetUserType,targetUserSchool,commentId} */
  static async pushSendComment(content: string, circleId: string, targetUserId: string,
    targetUserType: string, targetUserSchool: string, commentId: string): Promise<ApiResponse<Object>> {
    const params: Record<string, Object> = {
      'content': content, 'circleId': circleId, 'targetUserId': targetUserId,
      'targetUserType': targetUserType, 'targetUserSchool': targetUserSchool, 'commentId': commentId
    };
    return HttpClient.pushBizPost(Api.PUSH_HOST + Api.CIRCLE_LIANYI_SEND_COMMENT, params);
  }

  /** SocialModel.C0：POST deleteComment {circleId,id} */
  static async pushDeleteComment(circleId: string, id: string): Promise<ApiResponse<Object>> {
    return HttpClient.pushBizPost(Api.PUSH_HOST + Api.CIRCLE_LIANYI_DELETE_COMMENT,
      { 'circleId': circleId, 'id': id });
  }

  /** SocialModel.U：POST deleteCircle {id} */
  static async pushDeleteCircle(id: string): Promise<ApiResponse<Object>> {
    return HttpClient.pushBizPost(Api.PUSH_HOST + Api.CIRCLE_LIANYI_DELETE_CIRCLE, { 'id': id });
  }

  /** SocialModel.a0：POST hideCircle {id} */
  static async pushHideCircle(id: string): Promise<ApiResponse<Object>> {
    return HttpClient.pushBizPost(Api.PUSH_HOST + Api.CIRCLE_LIANYI_HIDE_CIRCLE, { 'id': id });
  }

  /** SocialModel.i0：POST hideComment {id} */
  static async pushHideComment(id: string): Promise<ApiResponse<Object>> {
    return HttpClient.pushBizPost(Api.PUSH_HOST + Api.CIRCLE_LIANYI_HIDE_COMMENT, { 'id': id });
  }

  /** SocialModel.k：POST stickCircle {id,place,operator}（置顶/取消置顶 hot_top|fresh_top × up|down） */
  static async pushStickCircle(id: string, place: string, operator: string): Promise<ApiResponse<Object>> {
    const params: Record<string, Object> = { 'id': id, 'place': place, 'operator': operator };
    return HttpClient.pushBizPost(Api.PUSH_HOST + Api.CIRCLE_LIANYI_STICK_CIRCLE, params);
  }

  /** SocialModel.V：POST reportCircle {id,content}（举报） */
  static async pushReportCircle(id: string, content: string): Promise<ApiResponse<Object>> {
    return HttpClient.pushBizPost(Api.PUSH_HOST + Api.CIRCLE_LIANYI_REPORT_CIRCLE,
      { 'id': id, 'content': content });
  }

  /** SocialModel.H0：GET getSomeoneCircleList {lastId,userId,userType,schoolId}（我的/TA的帖子列表） */
  static async pushGetSomeoneCircleList(lastId: string, userId: string, userType: string,
    schoolId: string): Promise<ApiResponse<Object>> {
    const params: Record<string, Object> = {
      'lastId': lastId, 'userId': userId, 'userType': userType, 'schoolId': schoolId
    };
    return HttpClient.pushBizGet(Api.PUSH_HOST + Api.CIRCLE_LIANYI_GET_SOMEONE, params);
  }

  /** SocialModel.W：GET getCircleRecentlyPic {userId,userType,schoolId}（他人主页最近图片） */
  static async pushGetCircleRecentPics(userId: string, userType: string,
    schoolId: string): Promise<ApiResponse<Object>> {
    const params: Record<string, Object> = {
      'userId': userId, 'userType': userType, 'schoolId': schoolId
    };
    return HttpClient.pushBizGet(Api.PUSH_HOST + Api.CIRCLE_LIANYI_RECENT_PIC, params);
  }

  /** SocialModel.f：multipart post {content,type:"1"} + pic1..N（校圈发帖，e.f 管道） */
  static async pushPublishPost(content: string, photoUris: string[]): Promise<ApiResponse<Object>> {
    const fields: Record<string, string> = { 'content': content, 'type': '1' };
    return HttpClient.pushMultipartPost(Api.PUSH_HOST + Api.CIRCLE_LIANYI_POST, fields, photoUris);
  }

  /** MarketModel.k1：multipart post {content,type:"2",marketType,score,time} + pic1..N（集市发帖） */
  static async pushPublishMarket(content: string, marketType: string, time: string, score: string,
    photoUris: string[]): Promise<ApiResponse<Object>> {
    const fields: Record<string, string> = {
      'content': content, 'type': '2', 'marketType': marketType,
      'score': score, 'time': time
    };
    return HttpClient.pushMultipartPost(Api.PUSH_HOST + Api.MARKET_LIANYI_POST, fields, photoUris);
  }

  /** MarketModel.i1：GET getUserScores {}（竞价积分余额） */
  static async pushGetUserScores(): Promise<ApiResponse<Object>> {
    return HttpClient.pushBizGet(Api.PUSH_HOST + Api.MARKET_LIANYI_GET_USER_SCORES, {});
  }

  /** MarketModel.l1：POST likeOperator {circleId,setLike} */
  static async pushMarketLikeOperator(circleId: string, setLike: string): Promise<ApiResponse<Object>> {
    return HttpClient.pushBizPost(Api.PUSH_HOST + Api.MARKET_LIANYI_LIKE_OPERATOR,
      { 'circleId': circleId, 'setLike': setLike });
  }

  /** MarketModel.n1：POST sendComment {circleId,content,targetUserId,targetUserType,targetUserSchool[,commentId]} */
  static async pushMarketSendComment(content: string, circleId: string, targetUserId: string,
    targetUserType: string, targetUserSchool: string, commentId: string): Promise<ApiResponse<Object>> {
    const params: Record<string, Object> = {
      'circleId': circleId, 'content': content, 'targetUserId': targetUserId,
      'targetUserType': targetUserType, 'targetUserSchool': targetUserSchool
    };
    if (commentId !== '') {
      params['commentId'] = commentId;
    }
    return HttpClient.pushBizPost(Api.PUSH_HOST + Api.MARKET_LIANYI_SEND_COMMENT, params);
  }

  /** MarketModel.W0：POST deleteComment {circleId,id} */
  static async pushMarketDeleteComment(circleId: string, id: string): Promise<ApiResponse<Object>> {
    return HttpClient.pushBizPost(Api.PUSH_HOST + Api.MARKET_LIANYI_DELETE_COMMENT,
      { 'circleId': circleId, 'id': id });
  }

  /** MarketModel.i0：POST hideComment {id} */
  static async pushMarketHideComment(id: string): Promise<ApiResponse<Object>> {
    return HttpClient.pushBizPost(Api.PUSH_HOST + Api.MARKET_LIANYI_HIDE_COMMENT, { 'id': id });
  }

  /** MarketModel.V0：POST deleteCircle {id} */
  static async pushMarketDeleteCircle(id: string): Promise<ApiResponse<Object>> {
    return HttpClient.pushBizPost(Api.PUSH_HOST + Api.MARKET_LIANYI_DELETE_CIRCLE, { 'id': id });
  }

  /** MarketModel.j1：POST hideCircle {id} */
  static async pushMarketHideCircle(id: string): Promise<ApiResponse<Object>> {
    return HttpClient.pushBizPost(Api.PUSH_HOST + Api.MARKET_LIANYI_HIDE_CIRCLE, { 'id': id });
  }

  /** MarketModel.o1：POST stickCircle {id,place,operator} */
  static async pushMarketStickCircle(id: string, place: string, operator: string): Promise<ApiResponse<Object>> {
    const params: Record<string, Object> = { 'id': id, 'place': place, 'operator': operator };
    return HttpClient.pushBizPost(Api.PUSH_HOST + Api.MARKET_LIANYI_STICK_CIRCLE, params);
  }

  /** MarketModel.U0：POST alterClassify {circleId,circleType}（分类切换 校圈↔集市） */
  static async pushMarketAlterClassify(circleId: string, circleType: string): Promise<ApiResponse<Object>> {
    return HttpClient.pushBizPost(Api.PUSH_HOST + Api.MARKET_LIANYI_ALTER_CLASSIFY,
      { 'circleId': circleId, 'circleType': circleType });
  }

  /** MarketModel.m1：POST reGrounding {id}（重新上架） */
  static async pushMarketReGrounding(id: string): Promise<ApiResponse<Object>> {
    return HttpClient.pushBizPost(Api.PUSH_HOST + Api.MARKET_LIANYI_REGROUNDING, { 'id': id });
  }

  /** MarketModel.Z0：POST turnover {id}（确认为已成交） */
  static async pushMarketTurnover(id: string): Promise<ApiResponse<Object>> {
    return HttpClient.pushBizPost(Api.PUSH_HOST + Api.MARKET_LIANYI_TURNOVER, { 'id': id });
  }

  /** MarketModel.T0：POST addTop {bidScore,bidduration,bidunitprice,circleId}（竞价置顶） */
  static async pushMarketAddTop(bidScore: string, bidduration: string, bidunitprice: string,
    circleId: string): Promise<ApiResponse<Object>> {
    const params: Record<string, Object> = {
      'bidScore': bidScore, 'bidduration': bidduration,
      'bidunitprice': bidunitprice, 'circleId': circleId
    };
    return HttpClient.pushBizPost(Api.PUSH_HOST + Api.MARKET_LIANYI_ADD_TOP, params);
  }

  /** FriendModel.A（friendship/f/a.java）：POST getRelationship {targetUserId,targetUserType,targetSchoolId} */
  static async pushGetRelationship(targetUserId: string, targetUserType: string,
    targetSchoolId: string): Promise<ApiResponse<Object>> {
    const params: Record<string, Object> = {
      'targetUserId': targetUserId, 'targetUserType': targetUserType, 'targetSchoolId': targetSchoolId
    };
    return HttpClient.pushBizPost(Api.PUSH_HOST + Api.FRIENDSHIP_GET_RELATIONSHIP, params);
  }

  /** FriendModel.F0：POST addFriend {targetUserId,targetUserType,targetSchoolId,noteName} */
  static async pushAddFriend(targetUserId: string, targetUserType: string, targetSchoolId: string,
    noteName: string): Promise<ApiResponse<Object>> {
    const params: Record<string, Object> = {
      'targetUserId': targetUserId, 'targetUserType': targetUserType,
      'targetSchoolId': targetSchoolId, 'noteName': noteName
    };
    return HttpClient.pushBizPost(Api.PUSH_HOST + Api.FRIENDSHIP_ADD_FRIEND, params);
  }

  /** FriendModel.j：POST deleteFriend {targetUserId,targetUserType,targetSchoolId} */
  static async pushDeleteFriend(targetUserId: string, targetUserType: string,
    targetSchoolId: string): Promise<ApiResponse<Object>> {
    const params: Record<string, Object> = {
      'targetUserId': targetUserId, 'targetUserType': targetUserType, 'targetSchoolId': targetSchoolId
    };
    return HttpClient.pushBizPost(Api.PUSH_HOST + Api.FRIENDSHIP_DELETE_FRIEND, params);
  }

  /** FriendModel.k0：POST updateNoteName {targetUserId,targetUserType,targetSchoolId,noteName} */
  static async pushUpdateNoteName(targetUserId: string, targetUserType: string, targetSchoolId: string,
    noteName: string): Promise<ApiResponse<Object>> {
    const params: Record<string, Object> = {
      'targetUserId': targetUserId, 'targetUserType': targetUserType,
      'targetSchoolId': targetSchoolId, 'noteName': noteName
    };
    return HttpClient.pushBizPost(Api.PUSH_HOST + Api.FRIENDSHIP_UPDATE_NOTE_NAME, params);
  }

  // ===== 降级空数据（假数据已全部清除） =====
  static mockUser(account: string): UserInfo {
    // 假数据已清除：失败路径返回空 UserInfo（真数据来自登录响应持久化字段）
    return new UserInfo('', '', '', '', '', '', '', '', '', '', '');
  }

  static mockNewsList(): NewsItem[] {
    return [];
  }

  static mockNewsDetail(id: string): NewsItem {
    return new NewsItem(id, '', '', '', '', '', '', '', '');
  }

  static mockTodoList(): TodoItem[] {
    return [];
  }

  static mockContactList(): ContactItem[] {
    return [];
  }

  static mockMeetingList(): MeetingItem[] {
    return [];
  }

  static mockMeetingDetail(id: string): MeetingItem {
    return new MeetingItem(id, '', '', '', '', '', '');
  }

  static mockScheduleList(): CourseItem[] {
    return [];
  }

  static mockScoreList(): ScoreItem[] {
    return [];
  }

  static mockExamList(): ExamItem[] {
    return [];
  }

  static mockAttendanceList(): AttendanceItem[] {
    return [];
  }

  static mockScoreDetail(): ScoreDetailData {
    const detailList: ScoreDetailEntry[] = [];
    const rankList: ScoreRankEntry[] = [];
    const commentList: ScoreCommentEntry[] = [];
    return new ScoreDetailData(detailList, rankList, commentList);
  }

  // ===== T2 contact-worker 追加：通讯录模块（源码 contact/e/a.java ContactModel） =====
  /** 源码 ContactModel.Y0：GET getInitData（教师通讯录初始化，无参数）→ InitData[] */
  static async getContactInitData(): Promise<ApiResponse<ContactInitData[]>> {
    const result: BizJsonResult = await ApiService.bizJson(Api.CONTACT_LIST, 'GET', {});
    if (result.code === 0) {
      return new ApiResponse<ContactInitData[]>(0, result.message, ApiService.parseContactInitList(result.data));
    }
    return new ApiResponse<ContactInitData[]>(result.code, result.message, []);
  }

  /** 源码 ContactModel.Z0：GET getStudentInitData（学生通讯录初始化，无参数）→ InitData[] */
  static async getContactStudentInitData(): Promise<ApiResponse<ContactInitData[]>> {
    const result: BizJsonResult = await ApiService.bizJson(Api.CONTACT_STUDENT_INIT, 'GET', {});
    if (result.code === 0) {
      return new ApiResponse<ContactInitData[]>(0, result.message, ApiService.parseContactInitList(result.data));
    }
    return new ApiResponse<ContactInitData[]>(result.code, result.message, []);
  }

  /** 源码 ContactModel.U0：delTopContact {gh}（移除常用联系人）→ String */
  static async delTopContact(gh: string): Promise<ApiResponse<boolean>> {
    const params: Record<string, Object> = { 'gh': gh };
    const result: BizJsonResult = await ApiService.bizJson(Api.CONTACT_DEL_TOP, 'POST', params);
    return new ApiResponse<boolean>(result.code, result.message, result.code === 0);
  }

  /** 源码 ContactModel.T0：addTopContact {scyhid,type}（拨号后记为常用联系人）→ String */
  static async addTopContact(scyhid: string, type: string): Promise<ApiResponse<boolean>> {
    const params: Record<string, Object> = { 'scyhid': scyhid, 'type': type };
    const result: BizJsonResult = await ApiService.bizJson(Api.CONTACT_ADD_TOP, 'POST', params);
    return new ApiResponse<boolean>(result.code, result.message, result.code === 0);
  }

  /** InitData[] 解析入口（兼容裸数组/包装对象两种响应形态） */
  static parseContactInitList(data: Object): ContactInitData[] {
    const list: ContactInitData[] = [];
    let raw: Object[];
    if (Array.isArray(data)) {
      raw = data as Object[];
    } else {
      raw = ApiService.extractArray(data);
    }
    for (const one of raw) {
      list.push(ApiService.parseContactInit(one));
    }
    return list;
  }

  /** 对象字段取子数组（无则空数组） */
  static parseChildArray(parent: Object, key: string): Object[] {
    const rec: Record<string, Object> = ApiService.asRecord(parent);
    const v: Object = rec[key];
    if (Array.isArray(v)) {
      return v as Object[];
    }
    return [];
  }

  /** InitData 单条解析（Gson 字段 1:1） */
  static parseContactInit(one: Object): ContactInitData {
    const rec: Record<string, Object> = ApiService.asRecord(one);
    const item: ContactInitData = new ContactInitData();
    item.type = ApiService.pick(rec, ['type']);
    item.name = ApiService.pick(rec, ['name']);
    for (const o of ApiService.parseChildArray(one, 'classAddressBook')) {
      item.classAddressBook.push(ApiService.parseContactClassBean(o));
    }
    for (const o of ApiService.parseChildArray(one, 'myCourseTeachers')) {
      item.myCourseTeachers.push(ApiService.parseContactCourseTeacher(o));
    }
    for (const o of ApiService.parseChildArray(one, 'myTeacher')) {
      item.myTeacher.push(ApiService.parseContactTopBean(o));
    }
    for (const o of ApiService.parseChildArray(one, 'topContactList')) {
      item.topContactList.push(ApiService.parseContactTopBean(o));
    }
    for (const o of ApiService.parseChildArray(one, 'rootOrganization')) {
      item.rootOrganization.push(ApiService.parseContactOrgBean(o));
    }
    return item;
  }

  /** ClassAddressBookBean 解析（BJID/BJMC/JSID） */
  static parseContactClassBean(one: Object): ContactClassAddressBookBean {
    const rec: Record<string, Object> = ApiService.asRecord(one);
    const bean: ContactClassAddressBookBean = new ContactClassAddressBookBean();
    bean.BJID = ApiService.pick(rec, ['BJID']);
    bean.BJMC = ApiService.pick(rec, ['BJMC']);
    bean.JSID = ApiService.pick(rec, ['JSID']);
    return bean;
  }

  /** CourseTeacherBean 解析（avatar/course/phone/sex/userId/userName） */
  static parseContactCourseTeacher(one: Object): ContactCourseTeacherBean {
    const rec: Record<string, Object> = ApiService.asRecord(one);
    const bean: ContactCourseTeacherBean = new ContactCourseTeacherBean();
    bean.avatar = ApiService.pick(rec, ['avatar']);
    bean.course = ApiService.pick(rec, ['course']);
    bean.phone = ApiService.pick(rec, ['phone']);
    bean.sex = ApiService.pick(rec, ['sex']);
    bean.userId = ApiService.pick(rec, ['userId']);
    bean.userName = ApiService.pick(rec, ['userName']);
    return bean;
  }

  /** RootOrganizationBean 解析（BMDM/BMMC/PXH/SJBMDM/XLH） */
  static parseContactOrgBean(one: Object): ContactRootOrganizationBean {
    const rec: Record<string, Object> = ApiService.asRecord(one);
    const bean: ContactRootOrganizationBean = new ContactRootOrganizationBean();
    bean.BMDM = ApiService.pick(rec, ['BMDM']);
    bean.BMMC = ApiService.pick(rec, ['BMMC']);
    bean.PXH = ApiService.pick(rec, ['PXH']);
    bean.SJBMDM = ApiService.pick(rec, ['SJBMDM']);
    bean.XLH = ApiService.pick(rec, ['XLH']);
    return bean;
  }

  /** TopContactListBean 解析（大写缩写字段 1:1；BDCS/ROWNUM 数字） */
  static parseContactTopBean(one: Object): ContactTopContactListBean {
    const rec: Record<string, Object> = ApiService.asRecord(one);
    const bean: ContactTopContactListBean = new ContactTopContactListBean();
    bean.BDCS = ApiService.pickNumber(rec, ['BDCS']);
    bean.BDSJH = ApiService.pick(rec, ['BDSJH']);
    bean.BMDM = ApiService.pick(rec, ['BMDM']);
    bean.BMMC = ApiService.pick(rec, ['BMMC']);
    bean.GH = ApiService.pick(rec, ['GH']);
    bean.INTRO = ApiService.pick(rec, ['INTRO']);
    bean.ROWNUM = ApiService.pickNumber(rec, ['ROWNUM']);
    bean.SCYHID = ApiService.pick(rec, ['SCYHID']);
    bean.SJHM = ApiService.pick(rec, ['SJHM']);
    bean.TJFS = ApiService.pick(rec, ['TJFS']);
    bean.TJSJ = ApiService.pick(rec, ['TJSJ']);
    bean.TX = ApiService.pick(rec, ['TX']);
    bean.XB = ApiService.pick(rec, ['XB']);
    bean.XLH = ApiService.pick(rec, ['XLH']);
    bean.XM = ApiService.pick(rec, ['XM']);
    bean.ZW = ApiService.pick(rec, ['ZW']);
    return bean;
  }

  // ===== W9 contact-series 追加：搜索/黄页/OA部门选择（源码 contact/e/a.java + contact/e/b.java + oa/b/c/a.java） =====

  /** 搜索结果分组解析（SearchAddressBook[]，兼容裸数组/包装对象） */
  static parseSearchBookList(data: Object): ContactSearchAddressBook[] {
    const list: ContactSearchAddressBook[] = [];
    let raw: Object[];
    if (Array.isArray(data)) {
      raw = data as Object[];
    } else {
      raw = ApiService.extractArray(data);
    }
    for (const one of raw) {
      const rec: Record<string, Object> = ApiService.asRecord(one);
      const group: ContactSearchAddressBook = new ContactSearchAddressBook();
      group.bmdm = ApiService.pick(rec, ['bmdm']);
      group.bmmc = ApiService.pick(rec, ['bmmc']);
      group.isYellowCard = ApiService.pick(rec, ['isYellowCard']);
      for (const o of ApiService.parseChildArray(one, 'addressBookList')) {
        const kr: Record<string, Object> = ApiService.asRecord(o);
        const item: ContactSearchAddressBookItem = new ContactSearchAddressBookItem();
        item.BDSJH = ApiService.pick(kr, ['BDSJH']);
        item.SJHM = ApiService.pick(kr, ['SJHM']);
        item.TX = ApiService.pick(kr, ['TX']);
        item.XB = ApiService.pick(kr, ['XB']);
        item.XLH = ApiService.pick(kr, ['XLH']);
        item.XM = ApiService.pick(kr, ['XM']);
        item.ZW = ApiService.pick(kr, ['ZW']);
        item.course = ApiService.pick(kr, ['course']);
        group.addressBookList.push(item);
      }
      list.push(group);
    }
    return list;
  }

  /** 源码 ContactModel.c1/d1：GET searchAddressBook|searchAddressBookForStu
   *  {pageNum, pageSize:AgooConstants.ACK_PACK_ERROR="15", keyword}。
   *  源码分流（ContactSearchActivity h/b/g + ContactPImpl.t/u）：userType=="1"→m3→u→d1
   *  searchAddressBookForStu；userType=="2"→l3→t→c1 searchAddressBook（"2"=教师，
   *  ContactSubFragment:613 仅"2"可开学生查询开关）。
   *  2026-11-17 实测：searchAddressBook 恒 0001（服务器端异常），ForStu code=0 —— 失败即返回空数组走空态。 */
  static async searchAddressBook(pageNum: string, keyword: string): Promise<ApiResponse<ContactSearchAddressBook[]>> {
    const params: Record<string, Object> = {
      'pageNum': pageNum,
      'pageSize': Api.CONTACT_SEARCH_PAGE_SIZE,
      'keyword': keyword
    };
    const path: string = LoginSession.userType === '1' ? Api.CONTACT_SEARCH_STU : Api.CONTACT_SEARCH;
    const result: BizJsonResult = await ApiService.bizJson(path, 'GET', params);
    if (result.code === 0) {
      return new ApiResponse<ContactSearchAddressBook[]>(0, result.message,
        ApiService.parseSearchBookList(result.data));
    }
    return new ApiResponse<ContactSearchAddressBook[]>(result.code, result.message, []);
  }

  /** 源码 ContactModel.e1：GET userMessage/searchUser {searchType,pageNum,pageSize,keyword}
   *  （contactSearchType 非空入口用；HAP 搜索页为独立入口无该参数，保留源码等价方法） */
  static async searchUser(searchType: string, pageNum: string,
    keyword: string): Promise<ApiResponse<ContactSearchAddressBook[]>> {
    const params: Record<string, Object> = {
      'searchType': searchType,
      'pageNum': pageNum,
      'pageSize': Api.CONTACT_SEARCH_PAGE_SIZE,
      'keyword': keyword
    };
    const result: BizJsonResult = await ApiService.bizJson(Api.CONTACT_SEARCH_USER, 'GET', params);
    if (result.code === 0) {
      return new ApiResponse<ContactSearchAddressBook[]>(0, result.message,
        ApiService.parseSearchBookList(result.data));
    }
    return new ApiResponse<ContactSearchAddressBook[]>(result.code, result.message, []);
  }

  /** [W25 misc-b] 源码 ContactModel.X0：GET getClassAddressbook {bjid} → ClassAddressBook[]（班级通讯录列表） */
  static async getClassAddressbook(bjid: string): Promise<ApiResponse<ContactClassStudentBean[]>> {
    const params: Record<string, Object> = { 'bjid': bjid };
    const result: BizJsonResult = await ApiService.bizJson(Api.CONTACT_CLASS_ADDRESSBOOK, 'GET', params);
    if (result.code !== 0) {
      return new ApiResponse<ContactClassStudentBean[]>(result.code, result.message, []);
    }
    const list: ContactClassStudentBean[] = [];
    for (const one of ApiService.extractArray(result.data)) {
      const rec: Record<string, Object> = ApiService.asRecord(one);
      const bean: ContactClassStudentBean = new ContactClassStudentBean();
      bean.BDSJH = ApiService.pick(rec, ['BDSJH']);
      bean.BJID = ApiService.pick(rec, ['BJID']);
      bean.SJHM = ApiService.pick(rec, ['SJHM']);
      bean.XB = ApiService.pick(rec, ['XB']);
      bean.XH = ApiService.pick(rec, ['XH']);
      bean.XLH = ApiService.pick(rec, ['XLH']);
      bean.XM = ApiService.pick(rec, ['XM']);
      list.push(bean);
    }
    return new ApiResponse<ContactClassStudentBean[]>(0, result.message, list);
  }

  /** [W25 misc-b] 源码 ContactPImpl.l3（ContactPersonalDetailActivity）：
   *  contactSearchType 空 → ContactModel.f1 GET userInfo {gh}；非空 → ContactModel.g1 GET
   *  userMessage/userInfo {gh,searchType}（Constants.KEY_USER_ID="userInfo" 源码字面值）→ AddressBookUserInfo */
  static async getContactUserInfo(gh: string,
    searchType: string): Promise<ApiResponse<ContactAddressBookUserInfo>> {
    const empty: ContactAddressBookUserInfo = new ContactAddressBookUserInfo();
    const params: Record<string, Object> = { 'gh': gh };
    const path: string = searchType === '' ? Api.CONTACT_USER_INFO : Api.CONTACT_USER_MESSAGE_USERID;
    if (searchType !== '') {
      params['searchType'] = searchType;
    }
    const result: BizJsonResult = await ApiService.bizJson(path, 'GET', params);
    if (result.code !== 0) {
      return new ApiResponse<ContactAddressBookUserInfo>(result.code, result.message, empty);
    }
    const rec: Record<string, Object> = ApiService.asRecord(result.data);
    const info: ContactAddressBookUserInfo = new ContactAddressBookUserInfo();
    info.name = ApiService.pick(rec, ['name']);
    info.roleType = ApiService.pick(rec, ['roleType']);
    info.title = ApiService.pick(rec, ['title']);
    info.type = ApiService.pick(rec, ['type']);
    const userRec: Record<string, Object> = ApiService.asRecord(rec['userInfo']);
    info.userInfo = ApiService.parseContactAddressUser(userRec);
    return new ApiResponse<ContactAddressBookUserInfo>(0, result.message, info);
  }

  /** AddressBookUserInfo.UserInfoBean 字段解析（Gson 1:1）
   *  [W23 协作解堵] ContactAddressBookUser 定义于 ContactModel（194 行，BDSJH 等全字段），
   *  原 import 缺失致 Cannot find name（W25 misc-b 在途遗漏）→ 补 import 即可。 */
  static parseContactAddressUser(rec: Record<string, Object>): ContactAddressBookUser {
    const bean: ContactAddressBookUser = new ContactAddressBookUser();
    bean.BDSJH = ApiService.pick(rec, ['BDSJH']);
    bean.BGDH = ApiService.pick(rec, ['BGDH']);
    bean.BGDZ = ApiService.pick(rec, ['BGDZ']);
    bean.BMDM = ApiService.pick(rec, ['BMDM']);
    bean.BMMC = ApiService.pick(rec, ['BMMC']);
    bean.CARDNO = ApiService.pick(rec, ['CARDNO']);
    bean.DZYJ = ApiService.pick(rec, ['DZYJ']);
    bean.GH = ApiService.pick(rec, ['GH']);
    bean.GW = ApiService.pick(rec, ['GW']);
    bean.QXZ = ApiService.pick(rec, ['QXZ']);
    bean.RZBD_QQ = ApiService.pick(rec, ['RZBD_QQ']);
    bean.RZBD_WX = ApiService.pick(rec, ['RZBD_WX']);
    bean.SJDH = ApiService.pick(rec, ['SJDH']);
    bean.SJHM = ApiService.pick(rec, ['SJHM']);
    bean.TX = ApiService.pick(rec, ['TX']);
    bean.XB = ApiService.pick(rec, ['XB']);
    bean.XH = ApiService.pick(rec, ['XH']);
    bean.XLH = ApiService.pick(rec, ['XLH']);
    bean.XM = ApiService.pick(rec, ['XM']);
    bean.ZW = ApiService.pick(rec, ['ZW']);
    bean.classId = ApiService.pick(rec, ['classId']);
    bean.className = ApiService.pick(rec, ['className']);
    bean.course = ApiService.pick(rec, ['course']);
    bean.nativePlace = ApiService.pick(rec, ['nativePlace']);
    bean.professionName = ApiService.pick(rec, ['professionName']);
    bean.studentSex = ApiService.pick(rec, ['studentSex']);
    bean.teacherId = ApiService.pick(rec, ['teacherId']);
    bean.teacherName = ApiService.pick(rec, ['teacherName']);
    bean.teacherPhone = ApiService.pick(rec, ['teacherPhone']);
    bean.userType = ApiService.pick(rec, ['userType']);
    return bean;
  }

  /** [W25 misc-b] 源码 ContactPImpl.k3→ContactModel.U0：POST delTopContact {gh}（移除常用联系人，data="1"=成功） */
  static async removeTopContact(gh: string): Promise<ApiResponse<string>> {
    const params: Record<string, Object> = { 'gh': gh };
    const result: BizJsonResult = await ApiService.bizJson(Api.CONTACT_DEL_TOP, 'POST', params);
    return new ApiResponse<string>(result.code, result.message,
      result.code === 0 && typeof result.data === 'string' ? result.data as string : '');
  }

  /** [W25 misc-b] 源码 ContactPImpl.h3→ContactModel.T0：POST addTopContact {scyhid,type}（type="1"=more 弹窗添加） */
  static async addToTopContact(scyhid: string, type: string): Promise<ApiResponse<string>> {
    const params: Record<string, Object> = { 'scyhid': scyhid, 'type': type };
    const result: BizJsonResult = await ApiService.bizJson(Api.CONTACT_ADD_TOP, 'POST', params);
    return new ApiResponse<string>(result.code, result.message,
      result.code === 0 && typeof result.data === 'string' ? result.data as string : '');
  }

  /** [W25 misc-b] 源码 ContactPImpl.m3→ContactModel.a1：POST hideRole {gh}（data="1"→more 态切"1"） */
  static async hideRole(gh: string): Promise<ApiResponse<string>> {
    const params: Record<string, Object> = { 'gh': gh };
    const result: BizJsonResult = await ApiService.bizJson(Api.CONTACT_HIDE_ROLE, 'POST', params);
    return new ApiResponse<string>(result.code, result.message,
      result.code === 0 && typeof result.data === 'string' ? result.data as string : '');
  }

  /** [W25 misc-b] 源码 ContactPImpl.n3→ContactModel.b1：POST openRole {gh} → OpenRole{msg}
   *  （msg=="已对其开放手机号码查看权限"||"已开放权限"→more 态切"2"；toast=msg） */
  static async openRole(gh: string): Promise<ApiResponse<string>> {
    const params: Record<string, Object> = { 'gh': gh };
    const result: BizJsonResult = await ApiService.bizJson(Api.CONTACT_OPEN_ROLE, 'POST', params);
    const rec: Record<string, Object> = result.code === 0 ? ApiService.asRecord(result.data) : {};
    const msg: string = ApiService.pick(rec, ['msg']);
    return new ApiResponse<string>(result.code, msg, msg);
  }

  // ===== [W25 misc-b] 聚合认证链（扫码 LY_CAS_CAM → 设备绑定/登录，源码 module/main/g/f.java PolymerizationModel）=====

  // [W26 polyHeaders 收敛] b64Encode（PolymerizationModel.Y0 等价）随误植版 polymerizationHeaders
  // 一并移除：polyHeaders（L4151 区）已用 CryptoUtil.bytesToBase64/stringToBytes 同款实现。

  /** [W26 polyHeaders 收敛] 源码 PolymerizationModel.Z0（main/g/f.java L166-182）统一实现为
   *  ApiService.polyHeaders（W22 版，公式与源码逐行一致：GlobalParamInfo 未持久化 → appId=""、
   *  secretKey="" → secret=md5(userId+""+yyyyMMdd)（b1("")，MD5 大写 hex=f1()）；
   *  userId 头=Base64(userId)（Y0））。原 W25 polymerizationHeaders 误植硬编码常量且缺日期
   *  （md5(userId+secret+常量)）与 Z0 不符，按收敛决定删除——lyuapServer 全源码仅 f.java 一处，
   *  cam/v1/* 三端点统一走 polyHeaders（见本文件 L4146 注释）。 */
  static async polymerizationVerify(domain: string, phoneId: string): Promise<ApiResponse<string>> {
    const body: Record<string, string> = { 'phoneId': phoneId };
    const headers: Record<string, string> = await ApiService.polyHeaders();
    const response: ApiResponse<Object> = await HttpClient.plainJsonPost(domain + '/lyuapServer/cam/v1/verify',
      headers, JSON.stringify(body));
    if (response.code !== 0) {
      // 网络层失败（外部域不可达等）：源码无响应不走 g/f 回调 → 页面停留白屏，HAP 透传失败码
      return new ApiResponse<string>(-1, response.message, '');
    }
    const rec: Record<string, Object> = ApiService.asRecord(response.data);
    const meta: Record<string, Object> = ApiService.asRecord(rec['meta']);
    const success: boolean = meta['success'] === true;
    const msg: string = ApiService.pick(meta, ['message']);
    return new ApiResponse<string>(success ? 0 : 1, msg, '');
  }

  /** [W25 misc-b] 源码 ReimburseModel.V0（reimburse/d/b.java）：GET project/reimbursement 无参
   *  → Reimbursement[]（科研项目列表，ReimburseP.f()） */
  static async getReimbursementList(): Promise<ApiResponse<ReimbursementEntry[]>> {
    const result: BizJsonResult = await ApiService.bizJson(Api.REIMBURSEMENT_LIST, 'GET', {});
    if (result.code !== 0) {
      return new ApiResponse<ReimbursementEntry[]>(result.code, result.message, []);
    }
    const list: ReimbursementEntry[] = [];
    for (const one of ApiService.extractArray(result.data)) {
      const rec: Record<string, Object> = ApiService.asRecord(one);
      const bean: ReimbursementEntry = new ReimbursementEntry();
      bean.AMOUNT = ApiService.pickNumber(rec, ['AMOUNT']);
      bean.BUSINESS_NUMBER = ApiService.pick(rec, ['BUSINESS_NUMBER']);
      bean.BUSINESS_TYPE = ApiService.pick(rec, ['BUSINESS_TYPE']);
      bean.DEPT_NUMBER = ApiService.pickNumber(rec, ['DEPT_NUMBER']);
      bean.DESC = ApiService.pick(rec, ['DESC']);
      bean.FIZZEZ_AMOUNT = ApiService.pick(rec, ['FIZZEZ_AMOUNT']);
      bean.PROJECT_NAME = ApiService.pick(rec, ['PROJECT_NAME']);
      bean.PROJECT_NUMBER = ApiService.pick(rec, ['PROJECT_NUMBER']);
      bean.REIMBURSE_AMOUNT = ApiService.pick(rec, ['REIMBURSE_AMOUNT']);
      bean.REIMBURSE_DATE = ApiService.pickNumber(rec, ['REIMBURSE_DATE']);
      bean.REIMBURSE_PEOPLE = ApiService.pick(rec, ['REIMBURSE_PEOPLE']);
      bean.REIMBURSE_TYPE = ApiService.pick(rec, ['REIMBURSE_TYPE']);
      bean.STATUS = ApiService.pick(rec, ['STATUS']);
      bean.SUB_NUMBER = ApiService.pick(rec, ['SUB_NUMBER']);
      bean.TEACHERID = ApiService.pickNumber(rec, ['TEACHERID']);
      bean.USABLE_AMOUNT = ApiService.pick(rec, ['USABLE_AMOUNT']);
      list.push(bean);
    }
    return new ApiResponse<ReimbursementEntry[]>(0, result.message, list);
  }

  /** ReadingBookEntry（BaseReadingData）解析（Gson 字段 1:1；SearchMyCollect 附加 USERID/XLH） */
  static parseReadingBook(one: Object): ReadingBookEntry {
    const rec: Record<string, Object> = ApiService.asRecord(one);
    const bean: ReadingBookEntry = new ReadingBookEntry();
    bean.CBRQ = ApiService.pick(rec, ['CBRQ']);
    bean.CBS = ApiService.pick(rec, ['CBS']);
    bean.COLLECTXLH = ApiService.pick(rec, ['COLLECTXLH']);
    bean.GCD = ApiService.pick(rec, ['GCD']);
    bean.ISBN = ApiService.pick(rec, ['ISBN']);
    bean.JG = ApiService.pick(rec, ['JG']);
    bean.SJMC = ApiService.pick(rec, ['SJMC']);
    bean.SQH = ApiService.pick(rec, ['SQH']);
    bean.TMH = ApiService.pick(rec, ['TMH']);
    bean.TP = ApiService.pick(rec, ['TP']);
    bean.TXM = ApiService.pick(rec, ['TXM']);
    bean.YS = ApiService.pick(rec, ['YS']);
    bean.ZGZT = ApiService.pick(rec, ['ZGZT']);
    bean.ZZ = ApiService.pick(rec, ['ZZ']);
    return bean;
  }

  /** [W25 misc-b] 源码 MobileCampusReadingModel.V0（reading/b/a.java）：GET library/getMyCollect
   *  无参（ReimburseP 同款 e.b 裸 GET 列表）→ SearchMyCollect[]（我的收藏，ReadingSearchActivity f3()） */
  static async getReadingMyCollect(): Promise<ApiResponse<ReadingBookEntry[]>> {
    const result: BizJsonResult = await ApiService.bizJson(Api.READING_MY_COLLECT, 'GET', {});
    if (result.code !== 0) {
      return new ApiResponse<ReadingBookEntry[]>(result.code, result.message, []);
    }
    const list: ReadingBookEntry[] = [];
    for (const one of ApiService.extractArray(result.data)) {
      list.push(ApiService.parseReadingBook(one));
    }
    return new ApiResponse<ReadingBookEntry[]>(0, result.message, list);
  }

  /** [W25 misc-b] 源码 MobileCampusReadingModel.Y0：POST library/searchMyCollect
   *  {startIndex,pageSize:ACK_REMOVE_PACKAGE="10",keyword}（加密 data）→ Search[]（列表回调） */
  static async searchReadingCollect(startIndex: string, keyword: string): Promise<ApiResponse<ReadingBookEntry[]>> {
    const params: Record<string, Object> = {
      'startIndex': startIndex,
      'pageSize': '10',
      'keyword': keyword
    };
    const result: BizJsonResult = await ApiService.bizJson(Api.READING_SEARCH_COLLECT, 'POST', params);
    if (result.code !== 0) {
      return new ApiResponse<ReadingBookEntry[]>(result.code, result.message, []);
    }
    const list: ReadingBookEntry[] = [];
    for (const one of ApiService.extractArray(result.data)) {
      list.push(ApiService.parseReadingBook(one));
    }
    return new ApiResponse<ReadingBookEntry[]>(0, result.message, list);
  }

  /** [W25 misc-b] 源码 MobileCampusReadingModel.T0：POST library/cancelCollect {COLLECTXLH}
   *  （data="1"=成功） */
  static async cancelReadingCollect(collectXlh: string): Promise<ApiResponse<string>> {
    const params: Record<string, Object> = { 'COLLECTXLH': collectXlh };
    const result: BizJsonResult = await ApiService.bizJson(Api.READING_CANCEL_COLLECT, 'POST', params);
    return new ApiResponse<string>(result.code, result.message,
      result.code === 0 && typeof result.data === 'string' ? result.data as string : '');
  }

  /** [W25 misc-b] 源码 MobileCampusReadingModel.U0：POST library/collectBook
   *  {SJMC,TP,CBS,ZZ,GCD,SQH,CBRQ,THM}（THM=条形码 TXM 值；data=返回收藏 XLH） */
  static async collectReadingBook(sjmc: string, tp: string, cbs: string, zz: string,
    gcd: string, sqh: string, cbrq: string, txm: string): Promise<ApiResponse<string>> {
    const params: Record<string, Object> = {
      'SJMC': sjmc,
      'TP': tp,
      'CBS': cbs,
      'ZZ': zz,
      'GCD': gcd,
      'SQH': sqh,
      'CBRQ': cbrq,
      'THM': txm
    };
    const result: BizJsonResult = await ApiService.bizJson(Api.READING_COLLECT_BOOK, 'POST', params);
    return new ApiResponse<string>(result.code, result.message,
      result.code === 0 && typeof result.data === 'string' ? result.data as string : '');
  }

  /** [W28 final-b] 源码 MobileCampusReadingModel.V0：GET library/getHomePageData 无参
   *  （e.b 裸 GET）→ HomePageData{status,borrowNum,userId,overdue,arrearage,currentBorrow[]} */
  static async getReadingHomePage(): Promise<ApiResponse<ReadingHomeData>> {
    const result: BizJsonResult = await ApiService.bizJson(Api.READING_HOME_PAGE, 'GET', {});
    const home: ReadingHomeData = new ReadingHomeData();
    if (result.code !== 0) {
      return new ApiResponse<ReadingHomeData>(result.code, result.message, home);
    }
    const rec: Record<string, Object> = ApiService.asRecord(result.data);
    home.status = ApiService.pick(rec, ['status']);
    home.borrowNum = ApiService.pick(rec, ['borrowNum']);
    home.userId = ApiService.pick(rec, ['userId']);
    home.overdue = ApiService.pick(rec, ['overdue']);
    home.arrearage = ApiService.pick(rec, ['arrearage']);
    for (const one of ApiService.extractArray(rec['currentBorrow'])) {
      const bean: ReadingBookEntry = ApiService.parseReadingBook(one);
      const item: Record<string, Object> = ApiService.asRecord(one);
      bean.DAY = ApiService.pick(item, ['DAY']);
      bean.JYRQ = ApiService.pick(item, ['JYRQ']);
      bean.YHRQ = ApiService.pick(item, ['YHRQ']);
      home.currentBorrow.push(bean);
    }
    return new ApiResponse<ReadingHomeData>(0, result.message, home);
  }

  /** [W28 final-b] 源码 MobileCampusReadingModel.X0：POST library/getReturnData
   *  {pageNum,pageSize:ACK_REMOVE_PACKAGE="10"}（e.d 加密 POST）→ ReturnData{returnData[]} */
  static async getReadingReturnData(pageNum: string): Promise<ApiResponse<ReadingBookEntry[]>> {
    const params: Record<string, Object> = { 'pageNum': pageNum, 'pageSize': '10' };
    const result: BizJsonResult = await ApiService.bizJson(Api.READING_RETURN_DATA, 'POST', params);
    if (result.code !== 0) {
      return new ApiResponse<ReadingBookEntry[]>(result.code, result.message, []);
    }
    const rec: Record<string, Object> = ApiService.asRecord(result.data);
    const list: ReadingBookEntry[] = [];
    for (const one of ApiService.extractArray(rec['returnData'])) {
      list.push(ApiService.parseReadingBook(one));
    }
    return new ApiResponse<ReadingBookEntry[]>(0, result.message, list);
  }

  /** [W28 final-b] 源码 RatepayingModel.T0：GET ratepaying/getDetail 无参
   *  （RatepayingFactory api/ratepaying，e.b GET）→ Ratepaying[] */
  static async getReceiptAssistList(): Promise<ApiResponse<RatepayingEntry[]>> {
    const result: BizJsonResult = await ApiService.bizJson(Api.RECEIPT_ASSIST_DETAIL, 'GET', {});
    if (result.code !== 0) {
      return new ApiResponse<RatepayingEntry[]>(result.code, result.message, []);
    }
    const list: RatepayingEntry[] = [];
    for (const one of ApiService.extractArray(result.data)) {
      const rec: Record<string, Object> = ApiService.asRecord(one);
      const bean: RatepayingEntry = new RatepayingEntry();
      bean.CREATETIME = ApiService.pick(rec, ['CREATETIME']);
      bean.DHHM = ApiService.pick(rec, ['DHHM']);
      bean.DWDZ = ApiService.pick(rec, ['DWDZ']);
      bean.KHYH = ApiService.pick(rec, ['KHYH']);
      bean.MC = ApiService.pick(rec, ['MC']);
      bean.ORDERBY = ApiService.pick(rec, ['ORDERBY']);
      bean.QRCODE = ApiService.pick(rec, ['QRCODE']);
      bean.SH = ApiService.pick(rec, ['SH']);
      bean.STATUS = ApiService.pick(rec, ['STATUS']);
      bean.TYPE = ApiService.pick(rec, ['TYPE']);
      bean.XLH = ApiService.pick(rec, ['XLH']);
      bean.YHZH = ApiService.pick(rec, ['YHZH']);
      list.push(bean);
    }
    return new ApiResponse<RatepayingEntry[]>(0, result.message, list);
  }

  /** ScheduleDetailRow 解析（ScheduleItem.DetailBean Gson 1:1） */
  static parseScheduleRow(one: Object): ScheduleDetailRow {
    const rec: Record<string, Object> = ApiService.asRecord(one);
    const bean: ScheduleDetailRow = new ScheduleDetailRow();
    bean.address = ApiService.pick(rec, ['address']);
    bean.djj = ApiService.pick(rec, ['djj']);
    bean.dsz = ApiService.pick(rec, ['dsz']);
    bean.is_current_user_plan = ApiService.pick(rec, ['is_current_user_plan']);
    bean.is_join = ApiService.pickNumber(rec, ['is_join']);
    bean.is_urgency = ApiService.pickNumber(rec, ['is_urgency']);
    bean.jssj = ApiService.pick(rec, ['jssj']);
    bean.kcdm = ApiService.pick(rec, ['kcdm']);
    bean.kcmc = ApiService.pick(rec, ['kcmc']);
    bean.kssj = ApiService.pick(rec, ['kssj']);
    bean.locate = ApiService.pick(rec, ['locate']);
    bean.meeting_type = ApiService.pickNumber(rec, ['meeting_type']);
    bean.qsjsz = ApiService.pick(rec, ['qsjsz']);
    bean.qxly = ApiService.pick(rec, ['qxly']);
    bean.schedule_color = ApiService.pick(rec, ['schedule_color']);
    bean.schedule_content = ApiService.pick(rec, ['schedule_content']);
    bean.schedule_id = ApiService.pick(rec, ['schedule_id']);
    bean.schedule_remind = ApiService.pick(rec, ['schedule_remind']);
    bean.schedule_type = ApiService.pick(rec, ['schedule_type']);
    bean.skdd = ApiService.pick(rec, ['skdd']);
    bean.skdx = ApiService.pick(rec, ['skdx']);
    bean.skdx1 = ApiService.pick(rec, ['skdx1']);
    bean.status = ApiService.pick(rec, ['status']);
    bean.task_id = ApiService.pick(rec, ['task_id']);
    bean.task_type = ApiService.pick(rec, ['task_type']);
    bean.title = ApiService.pick(rec, ['title']);
    bean.week = ApiService.pick(rec, ['week']);
    bean.xlh = ApiService.pick(rec, ['xlh']);
    bean.xqj = ApiService.pick(rec, ['xqj']);
    return bean;
  }

  /** [W25 misc-b] 源码 ScheduleModel.b1（schedule/c/a.java）：POST schedule/getListByMonth
   *  {year_month:"yyyy-MM"}（加密 data 列表回调）→ ScheduleItem[]（今日日程月数据） */
  static async getScheduleListByMonth(yearMonth: string): Promise<ApiResponse<ScheduleMonthItem[]>> {
    const params: Record<string, Object> = { 'year_month': yearMonth };
    const result: BizJsonResult = await ApiService.bizJson(Api.SCHEDULE_LIST_BY_MONTH, 'POST', params);
    if (result.code !== 0) {
      return new ApiResponse<ScheduleMonthItem[]>(result.code, result.message, []);
    }
    const list: ScheduleMonthItem[] = [];
    for (const one of ApiService.extractArray(result.data)) {
      const rec: Record<string, Object> = ApiService.asRecord(one);
      const item: ScheduleMonthItem = new ScheduleMonthItem();
      item.rq = ApiService.pick(rec, ['rq']);
      for (const d of ApiService.parseChildArray(one, 'detail')) {
        item.detail.push(ApiService.parseScheduleRow(d));
      }
      list.push(item);
    }
    return new ApiResponse<ScheduleMonthItem[]>(0, result.message, list);
  }

  /** [W25 misc-b] 源码 ScheduleModel.a1：POST schedule/getDetailsSchedule {xlh} → ScheduleDetail */
  static async getScheduleDetail(xlh: string): Promise<ApiResponse<ScheduleDetailEntry>> {
    const empty: ScheduleDetailEntry = new ScheduleDetailEntry();
    const params: Record<string, Object> = { 'xlh': xlh };
    const result: BizJsonResult = await ApiService.bizJson(Api.SCHEDULE_DETAIL, 'POST', params);
    if (result.code !== 0) {
      return new ApiResponse<ScheduleDetailEntry>(result.code, result.message, empty);
    }
    const rec: Record<string, Object> = ApiService.asRecord(result.data);
    const bean: ScheduleDetailEntry = new ScheduleDetailEntry();
    bean.END_TIME = ApiService.pick(rec, ['END_TIME']);
    bean.KSRQ = ApiService.pick(rec, ['KSRQ']);
    bean.LOCATE = ApiService.pick(rec, ['LOCATE']);
    bean.REMIND_TIME = ApiService.pick(rec, ['REMIND_TIME']);
    bean.SCHEDULE_COLOR = ApiService.pick(rec, ['SCHEDULE_COLOR']);
    bean.SCHEDULE_CONTENT = ApiService.pick(rec, ['SCHEDULE_CONTENT']);
    bean.SCHEDULE_ID = ApiService.pick(rec, ['SCHEDULE_ID']);
    bean.SCHEDULE_REMIND = ApiService.pick(rec, ['SCHEDULE_REMIND']);
    bean.SCHEDULE_TYPE = ApiService.pick(rec, ['SCHEDULE_TYPE']);
    bean.TASK_ID = ApiService.pick(rec, ['TASK_ID']);
    bean.TASK_TYPE = ApiService.pick(rec, ['TASK_TYPE']);
    bean.TITLE = ApiService.pick(rec, ['TITLE']);
    return new ApiResponse<ScheduleDetailEntry>(0, result.message, bean);
  }

  /** [W25 misc-b] 源码 ScheduleModel.X0：POST schedule/deleteSchedule {xlh}（data="1"=成功） */
  static async deleteSchedule(xlh: string): Promise<ApiResponse<string>> {
    const params: Record<string, Object> = { 'xlh': xlh };
    const result: BizJsonResult = await ApiService.bizJson(Api.SCHEDULE_DELETE, 'POST', params);
    return new ApiResponse<string>(result.code, result.message,
      result.code === 0 && typeof result.data === 'string' ? result.data as string : '');
  }

  /** [W25 misc-b] 源码 ScheduleModel.e1：POST schedule/updateSchedule
   *  {xlh,startTime,endTime,title,scheduleContent,scheduleColor,scheduleRemind,locate,remindTime} */
  static async updateSchedule(xlh: string, startTime: string, endTime: string, title: string,
    scheduleContent: string, scheduleColor: string, scheduleRemind: string,
    locate: string, remindTime: string): Promise<ApiResponse<string>> {
    const params: Record<string, Object> = {
      'xlh': xlh,
      'startTime': startTime,
      'endTime': endTime,
      'title': title,
      'scheduleContent': scheduleContent,
      'scheduleColor': scheduleColor,
      'scheduleRemind': scheduleRemind,
      'locate': locate,
      'remindTime': remindTime
    };
    const result: BizJsonResult = await ApiService.bizJson(Api.SCHEDULE_UPDATE, 'POST', params);
    return new ApiResponse<string>(result.code, result.message,
      result.code === 0 && typeof result.data === 'string' ? result.data as string : '');
  }

  /** [W25 misc-b] 源码 SchoolIntroModel.T0（school/g/a.java）：GET schoolIntro/index
   *  bVar.j=false 明文通道（无 Access-Token 加密，plainBizGet 等价）→ Index{banner, module[]}
   *  [W25-review 修正] Factory=SchoolIntroFactory（school/b.java，a()="open" b()="schoolIntro"），
   *  原 /api/campusView/index 为误引 SchoolFactory 的错误拼接。 */
  static async getSchoolViewIndex(): Promise<ApiResponse<SchoolViewIndex>> {
    const empty: SchoolViewIndex = new SchoolViewIndex();
    const response: ApiResponse<Object> = await HttpClient.plainBizGet(Api.SCHOOL_VIEW_INDEX, {});
    if (response.code !== 0) {
      return new ApiResponse<SchoolViewIndex>(response.code, response.message, empty);
    }
    const rec: Record<string, Object> = ApiService.asRecord(response.data);
    const index: SchoolViewIndex = new SchoolViewIndex();
    index.banner = ApiService.pick(rec, ['banner']);
    for (const one of ApiService.parseChildArray(response.data, 'module')) {
      const mr: Record<string, Object> = ApiService.asRecord(one);
      const bean: SchoolViewModuleBean = new SchoolViewModuleBean();
      bean.ICON = ApiService.pick(mr, ['ICON']);
      bean.NAME = ApiService.pick(mr, ['NAME']);
      bean.URL = ApiService.pick(mr, ['URL']);
      index.module.push(bean);
    }
    return new ApiResponse<SchoolViewIndex>(0, response.message, index);
  }

  /** [W25 misc-b] 源码 YiBanModel.Y0/X0：POST yiban/showData {yiban_data_type:"Ad"} → YDXYBannerInfo[] */
  static async getYiBanBanners(): Promise<ApiResponse<YiBanBannerEntry[]>> {
    const params: Record<string, Object> = { 'yiban_data_type': 'Ad' };
    const result: BizJsonResult = await ApiService.bizJson(Api.YIBAN_SHOW_DATA_AD, 'POST', params);
    if (result.code !== 0) {
      return new ApiResponse<YiBanBannerEntry[]>(result.code, result.message, []);
    }
    const list: YiBanBannerEntry[] = [];
    for (const one of ApiService.extractArray(result.data)) {
      const rec: Record<string, Object> = ApiService.asRecord(one);
      const bean: YiBanBannerEntry = new YiBanBannerEntry();
      bean.BT = ApiService.pick(rec, ['BT']);
      bean.GXSJ = ApiService.pick(rec, ['GXSJ']);
      bean.JHZT = ApiService.pick(rec, ['JHZT']);
      bean.LX = ApiService.pick(rec, ['LX']);
      bean.PXH = ApiService.pick(rec, ['PXH']);
      bean.TP = ApiService.pick(rec, ['TP']);
      bean.URL = ApiService.pick(rec, ['URL']);
      bean.XLH = ApiService.pick(rec, ['XLH']);
      list.push(bean);
    }
    return new ApiResponse<YiBanBannerEntry[]>(0, result.message, list);
  }

  /** [W25 misc-b] 源码 YiBanModel.U0：POST yiban/application（e.d(g(...),null) 空 body）→ YDAPPInfo[] */
  static async getYiBanApplications(): Promise<ApiResponse<YiBanAppGroup[]>> {
    const result: BizJsonResult = await ApiService.bizJson(Api.YIBAN_APPLICATION, 'POST', {});
    if (result.code !== 0) {
      return new ApiResponse<YiBanAppGroup[]>(result.code, result.message, []);
    }
    const list: YiBanAppGroup[] = [];
    for (const one of ApiService.extractArray(result.data)) {
      const rec: Record<string, Object> = ApiService.asRecord(one);
      const group: YiBanAppGroup = new YiBanAppGroup();
      group.ISSHOWCOMMONAPP = ApiService.pick(rec, ['ISSHOWCOMMONAPP']);
      group.SHOWNUMBER = ApiService.pickNumber(rec, ['SHOWNUMBER']);
      group.TYPE = ApiService.pick(rec, ['TYPE']);
      group.YYFL = ApiService.pick(rec, ['YYFL']);
      for (const a of ApiService.parseChildArray(one, 'DATA')) {
        const ar: Record<string, Object> = ApiService.asRecord(a);
        const item: YiBanAppItem = new YiBanAppItem();
        item.ICON = ApiService.pick(ar, ['ICON']);
        item.NAME = ApiService.pick(ar, ['NAME']);
        item.URL = ApiService.pick(ar, ['URL']);
        item.LX = ApiService.pick(ar, ['LX']);
        item.YYID = ApiService.pick(ar, ['YYID', 'yyid']);
        group.DATA.push(item);
      }
      list.push(group);
    }
    return new ApiResponse<YiBanAppGroup[]>(0, result.message, list);
  }

  /** [W25 misc-b] 源码 YiBanModel.T0：POST yiban/showData {yiban_data_type:"Toutiao"} → YiBanNews[]
   *  （Fragment b 类：>3 条仅取前 3） */
  static async getYiBanNews(): Promise<ApiResponse<YiBanNewsEntry[]>> {
    const params: Record<string, Object> = { 'yiban_data_type': 'Toutiao' };
    const result: BizJsonResult = await ApiService.bizJson(Api.YIBAN_SHOW_DATA_TOUTIAO, 'POST', params);
    if (result.code !== 0) {
      return new ApiResponse<YiBanNewsEntry[]>(result.code, result.message, []);
    }
    const list: YiBanNewsEntry[] = [];
    for (const one of ApiService.extractArray(result.data)) {
      const rec: Record<string, Object> = ApiService.asRecord(one);
      const bean: YiBanNewsEntry = new YiBanNewsEntry();
      bean.LX = ApiService.pick(rec, ['LX']);
      bean.PXH = ApiService.pickNumber(rec, ['PXH']);
      bean.TITLE = ApiService.pick(rec, ['TITLE']);
      bean.TP = ApiService.pick(rec, ['TP']);
      bean.URL = ApiService.pick(rec, ['URL']);
      bean.XLH = ApiService.pick(rec, ['XLH']);
      bean.image = ApiService.pick(rec, ['image']);
      bean.title = ApiService.pick(rec, ['title']);
      bean.url = ApiService.pick(rec, ['url']);
      list.push(bean);
    }
    return new ApiResponse<YiBanNewsEntry[]>(0, result.message, list);
  }

  /** [W25 misc-b] 源码 YiBanModel.W0：POST yiban/GetArticleList
   *  {page, pagesize:AgooConstants.ACK_PACK_ERROR="15"} → YiBanArticle[] */
  static async getYiBanArticles(page: string): Promise<ApiResponse<YiBanArticleEntry[]>> {
    const params: Record<string, Object> = { 'page': page, 'pagesize': '15' };
    const result: BizJsonResult = await ApiService.bizJson(Api.YIBAN_ARTICLE_LIST, 'POST', params);
    if (result.code !== 0) {
      return new ApiResponse<YiBanArticleEntry[]>(result.code, result.message, []);
    }
    const list: YiBanArticleEntry[] = [];
    for (const one of ApiService.extractArray(result.data)) {
      list.push(ApiService.parseYiBanArticle(one));
    }
    return new ApiResponse<YiBanArticleEntry[]>(0, result.message, list);
  }

  /** YiBanArticle 解析（Gson 字段 1:1） */
  static parseYiBanArticle(one: Object): YiBanArticleEntry {
    const rec: Record<string, Object> = ApiService.asRecord(one);
    const bean: YiBanArticleEntry = new YiBanArticleEntry();
    bean.content = ApiService.pick(rec, ['content']);
    bean.contentNum = ApiService.pickNumber(rec, ['contentNum']);
    bean.news_content = ApiService.pick(rec, ['news_content']);
    bean.news_id = ApiService.pick(rec, ['news_id']);
    bean.news_sendtime = ApiService.pick(rec, ['news_sendtime']);
    bean.news_title = ApiService.pick(rec, ['news_title']);
    bean.yb_schoolname = ApiService.pick(rec, ['yb_schoolname']);
    bean.yb_userhead = ApiService.pick(rec, ['yb_userhead']);
    bean.yb_userid = ApiService.pick(rec, ['yb_userid']);
    bean.yb_usernick = ApiService.pick(rec, ['yb_usernick']);
    for (const img of ApiService.parseChildArray(one, 'image_list')) {
      const ir: Record<string, Object> = ApiService.asRecord(img);
      const image: YiBanArticleImage = new YiBanArticleImage();
      image.image_url = ApiService.pick(ir, ['image_url']);
      bean.image_list.push(image);
    }
    return bean;
  }

  /** [W25 misc-b] 源码 YiBanModel.V0：POST yiban/getDetailByArticleId {news_id} → YiBanArticle */
  static async getYiBanArticleDetail(newsId: string): Promise<ApiResponse<YiBanArticleEntry>> {
    const params: Record<string, Object> = { 'news_id': newsId };
    const result: BizJsonResult = await ApiService.bizJson(Api.YIBAN_ARTICLE_DETAIL, 'POST', params);
    if (result.code !== 0) {
      return new ApiResponse<YiBanArticleEntry>(result.code, result.message,
        new YiBanArticleEntry());
    }
    return new ApiResponse<YiBanArticleEntry>(0, result.message,
      ApiService.parseYiBanArticle(result.data));
  }

  /** 源码 ContactYellowPageModel.U0：裸 GET yellowPage（ContactYellowPageFactory open/addressbook）
   *  实测：裸 GET（无 data 参数）code=0；带加密 data= 404 → HttpClient.getNoParams */
  static async getYellowPage(): Promise<ApiResponse<ContactYellowPage>> {
    const empty: ContactYellowPage = new ContactYellowPage();
    const response: ApiResponse<Object> = await HttpClient.getNoParams(Api.YELLOW_PAGE);
    if (response.code === 0 && typeof response.data === 'string' && (response.data as string) !== '') {
      try {
        const parsed: Object = JSON.parse(response.data as string) as Object;
        const rec: Record<string, Object> = ApiService.asRecord(parsed);
        const page: ContactYellowPage = new ContactYellowPage();
        page.departmentName = ApiService.pick(rec, ['departmentName']);
        for (const o of ApiService.parseChildArray(parsed, 'dataList')) {
          const gr: Record<string, Object> = ApiService.asRecord(o);
          const group: ContactYellowPageGroup = new ContactYellowPageGroup();
          group.name = ApiService.pick(gr, ['name']);
          for (const t of ApiService.parseChildArray(o, 'typeList')) {
            const tr: Record<string, Object> = ApiService.asRecord(t);
            const bean: ContactYellowTypeListBean = new ContactYellowTypeListBean();
            bean.DM = ApiService.pick(tr, ['DM']);
            bean.GXSJ = ApiService.pick(tr, ['GXSJ']);
            bean.MC = ApiService.pick(tr, ['MC']);
            bean.MS = ApiService.pick(tr, ['MS']);
            bean.XLH = ApiService.pick(tr, ['XLH']);
            bean.YXJ = ApiService.pick(tr, ['YXJ']);
            group.typeList.push(bean);
          }
          for (const c of ApiService.parseChildArray(o, 'commonlyPhoneList')) {
            const cr: Record<string, Object> = ApiService.asRecord(c);
            const bean: ContactYellowCommonBean = new ContactYellowCommonBean();
            bean.ADDRESS = ApiService.pick(cr, ['ADDRESS']);
            bean.DH = ApiService.pick(cr, ['DH']);
            bean.EMAIL = ApiService.pick(cr, ['EMAIL']);
            bean.GXSJ = ApiService.pick(cr, ['GXSJ']);
            bean.MC = ApiService.pick(cr, ['MC']);
            bean.TP = ApiService.pick(cr, ['TP']);
            bean.XLH = ApiService.pick(cr, ['XLH']);
            bean.YXJ = ApiService.pick(cr, ['YXJ']);
            group.commonlyPhoneList.push(bean);
          }
          page.dataList.push(group);
        }
        return new ApiResponse<ContactYellowPage>(0, response.message, page);
      } catch {
        ApiService.logError('getYellowPage parse fail');
        return new ApiResponse<ContactYellowPage>(ApiService.OFFLINE_CODE, '解析失败', empty);
      }
    }
    return new ApiResponse<ContactYellowPage>(response.code, response.message, empty);
  }

  /** 源码 ContactYellowPageModel.T0：GET getYellowByType {dm}（实测 data= 加密 GET code=0） */
  static async getYellowByType(dm: string): Promise<ApiResponse<ContactYellowTypeResult>> {
    const params: Record<string, Object> = { 'dm': dm };
    const result: BizJsonResult = await ApiService.bizJson(Api.YELLOW_BY_TYPE, 'GET', params);
    const empty: ContactYellowTypeResult = new ContactYellowTypeResult();
    if (result.code === 0) {
      const rec: Record<string, Object> = ApiService.asRecord(result.data);
      const bean: ContactYellowTypeResult = new ContactYellowTypeResult();
      bean.currentDep = ApiService.pick(rec, ['currentDep']);
      bean.name = ApiService.pick(rec, ['name']);
      for (const o of ApiService.parseChildArray(result.data, 'DepPhoneList')) {
        const dr: Record<string, Object> = ApiService.asRecord(o);
        const dep: ContactYellowDepPhoneBean = new ContactYellowDepPhoneBean();
        dep.ADDRESS = ApiService.pick(dr, ['ADDRESS']);
        dep.EMAIL = ApiService.pick(dr, ['EMAIL']);
        dep.SJBMDM = ApiService.pick(dr, ['SJBMDM']);
        dep.SJHM = ApiService.pick(dr, ['SJHM']);
        dep.XLH = ApiService.pick(dr, ['XLH']);
        dep.XM = ApiService.pick(dr, ['XM']);
        dep.YXJ = ApiService.pick(dr, ['YXJ']);
        bean.DepPhoneList.push(dep);
      }
      return new ApiResponse<ContactYellowTypeResult>(0, result.message, bean);
    }
    return new ApiResponse<ContactYellowTypeResult>(result.code, result.message, empty);
  }

  /** OA DepartmentListActivity.T2（SelectPImpl.j）：GET select/getDepartment {deptId}（空则"-1"）
   *  实测：{deptId:"-1"} code=0 → Department{title, departmentList[]} */
  static async getOaDepartment(deptId: string): Promise<ApiResponse<OaDepartment>> {
    const params: Record<string, Object> = { 'deptId': deptId === '' ? '-1' : deptId };
    const result: BizJsonResult = await ApiService.bizJson(Api.OA_DEPARTMENT, 'GET', params);
    const empty: OaDepartment = new OaDepartment();
    if (result.code === 0) {
      const rec: Record<string, Object> = ApiService.asRecord(result.data);
      const bean: OaDepartment = new OaDepartment();
      bean.title = ApiService.pick(rec, ['title']);
      for (const o of ApiService.parseChildArray(result.data, 'departmentList')) {
        const dr: Record<string, Object> = ApiService.asRecord(o);
        const item: OaDepartmentBean = new OaDepartmentBean();
        item.BMDM = ApiService.pick(dr, ['BMDM']);
        item.BMLX = ApiService.pick(dr, ['BMLX']);
        item.BMMC = ApiService.pick(dr, ['BMMC']);
        item.PXH = ApiService.pick(dr, ['PXH']);
        item.SJBMDM = ApiService.pick(dr, ['SJBMDM']);
        item.TYPE = ApiService.pick(dr, ['TYPE']);
        item.XLH = ApiService.pick(dr, ['XLH']);
        item.count = ApiService.pickNumber(dr, ['count']);
        item.isChildren = ApiService.pick(dr, ['isChildren']);
        bean.departmentList.push(item);
      }
      return new ApiResponse<OaDepartment>(0, result.message, bean);
    }
    return new ApiResponse<OaDepartment>(result.code, result.message, empty);
  }



  /** [E1 news worker] NewsFragment.K1():865 加载地址：
   *  s.g("lapp/springboard") + "?yyid=" + j.getYYID()
   *  = SCHOOL 服务器 + /mobileapi_ydxy/api/lapp/springboard?yyid=bodaNews
   *  （yyid 来源 MainActivity.f1():1392 AppBean.setYYID("bodaNews")，isH5=false 分支）。
   */
  static buildNewsPageUrl(): string {
    return Constants.SOCKET_HOST + Api.LAPP_SPRINGBOARD + '?yyid=' + Api.NEWS_YYID;
  }

  /** [E1 news worker] NewsFragment.K1():849-856 headers 构造：
   *  strE = d.a.e(null,false) = Hawk "randomBase64AESKey"（协商 AES key）→ LoginSession.aesKey；
   *  Access-Token = c.i(e2().get("Access-Token"), strE)（BaseSecretUtil.i = z.d AES 加密）
   *  其中 e2():932-941 只填 userId/userType/sessionKey/xxdm 四字段（TextUtils.isEmpty→""），
   *  k.m()=GsonBuilder().disableHtmlEscaping().create().toJson()，Gson 默认跳过 null 字段
   *  → 明文 JSON = {"sessionKey","userId","userType","xxdm"}（声明顺序，四字段）；
   *  Unique-Code = d.a.d() = Hawk "onlyCode"（协商响应 AES 解密产物；见 GetKeyUtil b.java:117）。
   *  strE 为空（未登录/未协商）返回 null → 页面按 K1 B1(r) 走非内容态。
   */
  static async getNewsPageWebViewHeaders(): Promise<NewsWebViewHeaders | null> {
    if (LoginSession.aesKey === '') {
      return null;
    }
    const token: Record<string, string> = {
      'sessionKey': LoginSession.sessionKey,
      'userId': LoginSession.userId,
      'userType': LoginSession.userType,
      'xxdm': LoginSession.schoolId
    };
    const accessToken: string = await CryptoUtil.encryptAES(JSON.stringify(token), LoginSession.aesKey);
    const headers: NewsWebViewHeaders = { accessToken: accessToken, uniqueCode: LoginSession.onlyCode };
    return headers;
  }

  // ===== [E3 meeting worker] 会议模块（MeetingActivity→MeetingMainActivity→两 Fragment 源码级翻译）=====

  /** 源码 MeetingModel.d1（MeetingMainActivity.L2）：GET getMeetTab（无参）→ MeetingTab{myMeeting,weekplan} */
  static async getMeetingTab(): Promise<ApiResponse<MeetingTabEntity>> {
    const result: BizJsonResult = await ApiService.bizJson(Api.MEETING_GET_MEET_TAB, 'GET', {});
    if (result.code === 0) {
      const tab: MeetingTabEntity = MeetingTabEntity.fromRecord(ApiService.asRecord(result.data));
      return new ApiResponse<MeetingTabEntity>(0, result.message, tab);
    }
    return new ApiResponse<MeetingTabEntity>(result.code, result.message, new MeetingTabEntity());
  }

  /** 源码 MeetingModel.b1（MeetingArrangementFragment.V1 onResume）：GET getJoinList（无参）→ JoinList[] */
  static async getMeetingJoinList(): Promise<ApiResponse<JoinListEntity[]>> {
    const result: BizJsonResult = await ApiService.bizJson(Api.MEETING_GET_JOIN_LIST, 'GET', {});
    if (result.code === 0) {
      const groups: JoinListEntity[] = [];
      const raw: Object[] = ApiService.extractArray(result.data);
      for (const one of raw) {
        groups.push(ApiService.parseMeetingJoinGroup(one));
      }
      return new ApiResponse<JoinListEntity[]>(0, result.message, groups);
    }
    return new ApiResponse<JoinListEntity[]>(result.code, result.message, []);
  }

  /** 源码 MeetingModel.f1（W1 上拉加载）：GET getPastList {currentPage,pageSize:"20"} → JoinList.DATABean[] */
  static async getMeetingPastList(currentPage: string): Promise<ApiResponse<JoinListItem[]>> {
    const params: Record<string, Object> = { 'currentPage': currentPage, 'pageSize': '20' };
    const result: BizJsonResult = await ApiService.bizJson(Api.MEETING_GET_PAST_LIST, 'GET', params);
    if (result.code === 0) {
      const items: JoinListItem[] = [];
      const raw: Object[] = ApiService.extractArray(result.data);
      for (const one of raw) {
        items.push(ApiService.parseMeetingJoinItem(one));
      }
      return new ApiResponse<JoinListItem[]>(0, result.message, items);
    }
    return new ApiResponse<JoinListItem[]>(result.code, result.message, []);
  }

  /** 源码 ScheduleModel.T0（MeetingWeekPlanFragment.a2）：POST getCurrentOrWeek {} → CurrentDay{date,week,xqj} */
  static async getMeetingCurrentOrWeek(): Promise<ApiResponse<CurrentDayEntity>> {
    const result: BizJsonResult = await ApiService.bizJson(Api.SCHEDULE_GET_CURRENT_OR_WEEK, 'POST', {});
    if (result.code === 0) {
      const rec: Record<string, Object> = ApiService.asRecord(result.data);
      const day: CurrentDayEntity = new CurrentDayEntity();
      day.date = ApiService.pick(rec, ['date']);
      day.week = ApiService.pickNumber(rec, ['week']);
      day.xqj = ApiService.pickNumber(rec, ['xqj']);
      return new ApiResponse<CurrentDayEntity>(0, result.message, day);
    }
    return new ApiResponse<CurrentDayEntity>(result.code, result.message, new CurrentDayEntity());
  }

  /** 源码 ScheduleModel.U0（b2）：GET termInfoForTeacher（无参）→ TermParamsEntity{ksrq,jsrq,...} */
  static async getMeetingTermInfoForTeacher(): Promise<ApiResponse<MeetingTermParams>> {
    const result: BizJsonResult = await ApiService.bizJson(Api.SCHEDULE_TERM_INFO_FOR_TEACHER, 'GET', {});
    if (result.code === 0) {
      const rec: Record<string, Object> = ApiService.asRecord(result.data);
      const term: MeetingTermParams = new MeetingTermParams();
      term.dqxq = ApiService.pick(rec, ['dqxq']);
      term.jsrq = ApiService.pick(rec, ['jsrq']);
      term.ksrq = ApiService.pick(rec, ['ksrq']);
      term.scheduleEnableAddClass = ApiService.pick(rec, ['scheduleEnableAddClass']);
      term.scheduleMaxClassNum = ApiService.pick(rec, ['scheduleMaxClassNum']);
      term.xlh = ApiService.pick(rec, ['xlh']);
      term.xn = ApiService.pick(rec, ['xn']);
      term.xq = ApiService.pick(rec, ['xq']);
      term.zksxq = ApiService.pick(rec, ['zksxq']);
      return new ApiResponse<MeetingTermParams>(0, result.message, term);
    }
    return new ApiResponse<MeetingTermParams>(result.code, result.message, new MeetingTermParams());
  }

  /** 源码 MeetingModel.h1（c2）：GET getWeekPlan {week} → WeekPlan[] */
  static async getMeetingWeekPlan(week: string): Promise<ApiResponse<WeekPlanEntity[]>> {
    const params: Record<string, Object> = { 'week': week };
    const result: BizJsonResult = await ApiService.bizJson(Api.MEETING_GET_WEEK_PLAN, 'GET', params);
    if (result.code === 0) {
      const items: WeekPlanEntity[] = [];
      const raw: Object[] = ApiService.extractArray(result.data);
      for (const one of raw) {
        items.push(ApiService.parseMeetingWeekPlan(one));
      }
      return new ApiResponse<WeekPlanEntity[]>(0, result.message, items);
    }
    return new ApiResponse<WeekPlanEntity[]>(result.code, result.message, []);
  }

  /** JoinList 单组解析（NAME/TYPE/DATA[]） */
  static parseMeetingJoinGroup(one: Object): JoinListEntity {
    const rec: Record<string, Object> = ApiService.asRecord(one);
    const group: JoinListEntity = new JoinListEntity();
    group.NAME = ApiService.pick(rec, ['NAME']);
    group.TYPE = ApiService.pick(rec, ['TYPE']);
    for (const child of ApiService.parseChildArray(one, 'DATA')) {
      group.DATA.push(ApiService.parseMeetingJoinItem(child));
    }
    return group;
  }

  /** JoinList.DATABean 单条解析（16 字段 Gson 1:1） */
  static parseMeetingJoinItem(one: Object): JoinListItem {
    const rec: Record<string, Object> = ApiService.asRecord(one);
    const item: JoinListItem = new JoinListItem();
    item.ADDRESS = ApiService.pick(rec, ['ADDRESS']);
    item.IS_CURRENT_USER_PLAN = ApiService.pick(rec, ['IS_CURRENT_USER_PLAN']);
    item.IS_EXIST_MEETING_REPORT = ApiService.pick(rec, ['IS_EXIST_MEETING_REPORT']);
    item.IS_JOIN = ApiService.pickNumber(rec, ['IS_JOIN']);
    item.IS_MUST_JOIN = ApiService.pick(rec, ['IS_MUST_JOIN']);
    item.IS_URGENCY = ApiService.pickNumber(rec, ['IS_URGENCY']);
    item.JSSJ = ApiService.pick(rec, ['JSSJ']);
    item.KSSJ = ApiService.pick(rec, ['KSSJ']);
    item.MEETING_TYPE = ApiService.pick(rec, ['MEETING_TYPE']);
    item.QXLY = ApiService.pick(rec, ['QXLY']);
    item.RN = ApiService.pickNumber(rec, ['RN']);
    item.STATUS = ApiService.pick(rec, ['STATUS']);
    item.TASK_TYPE = ApiService.pick(rec, ['TASK_TYPE']);
    item.TITLE = ApiService.pick(rec, ['TITLE']);
    item.WEEK = ApiService.pick(rec, ['WEEK']);
    item.XLH = ApiService.pick(rec, ['XLH']);
    return item;
  }

  /** WeekPlan 单条解析（12 字段 Gson 1:1，BZ/FJID Object→字符串） */
  static parseMeetingWeekPlan(one: Object): WeekPlanEntity {
    const rec: Record<string, Object> = ApiService.asRecord(one);
    const item: WeekPlanEntity = new WeekPlanEntity();
    item.BZ = ApiService.pick(rec, ['BZ']);
    item.CYRY = ApiService.pick(rec, ['CYRY']);
    item.DD = ApiService.pick(rec, ['DD']);
    item.FJID = ApiService.pick(rec, ['FJID']);
    item.JSSJ = ApiService.pick(rec, ['JSSJ']);
    item.KSSJ = ApiService.pick(rec, ['KSSJ']);
    item.LXDH = ApiService.pick(rec, ['LXDH']);
    item.WEEK = ApiService.pick(rec, ['WEEK']);
    item.XLH = ApiService.pick(rec, ['XLH']);
    item.ZBDW = ApiService.pick(rec, ['ZBDW']);
    item.ZCR = ApiService.pick(rec, ['ZCR']);
    item.ZT = ApiService.pick(rec, ['ZT']);
    return item;
  }

  // ===== [W13 meeting-series] 会议详情/公告/签到链（MeetingDetailActivity/MeetingAttendActivity/
  // MeetingAnnouncementActivity/MeetingSignActivity 源码级，经 MeetingPImpl→MeetingModel 管道）=====

  /** 源码 MeetingModel.c1（MeetingDetailActivity.p3）：GET getMeetingObj {xlh} → MeetingObj */
  static async getMeetingObj(xlh: string): Promise<ApiResponse<MeetingObjEntity>> {
    const params: Record<string, Object> = { 'xlh': xlh };
    const result: BizJsonResult = await ApiService.bizJson(Api.MEETING_GET_MEETING_OBJ, 'GET', params);
    if (result.code === 0) {
      return new ApiResponse<MeetingObjEntity>(0, result.message, ApiService.parseMeetingObj(result.data));
    }
    return new ApiResponse<MeetingObjEntity>(result.code, result.message, new MeetingObjEntity());
  }

  /** 源码 MeetingModel.a1（详情公告角标 o3 / MeetingAnnouncementActivity.V2）：POST findMeetingFeedBack {meetingId} → MeetingAnnouncement[] */
  static async findMeetingFeedback(meetingId: string): Promise<ApiResponse<MeetingAnnouncementEntity[]>> {
    const params: Record<string, Object> = { 'meetingId': meetingId };
    const result: BizJsonResult = await ApiService.bizJson(Api.MEETING_FIND_MEETING_FEEDBACK, 'POST', params);
    if (result.code === 0) {
      const items: MeetingAnnouncementEntity[] = [];
      const raw: Object[] = ApiService.extractArray(result.data);
      for (const one of raw) {
        items.push(ApiService.parseMeetingAnnouncement(one));
      }
      return new ApiResponse<MeetingAnnouncementEntity[]>(0, result.message, items);
    }
    return new ApiResponse<MeetingAnnouncementEntity[]>(result.code, result.message, []);
  }

  /** 源码 MeetingModel.r1（MeetingDetailActivity.r3 参加/不参会）：POST upJoin {xlh,zt,reason} */
  static async upJoinMeeting(xlh: string, zt: string, reason: string): Promise<ApiResponse<string>> {
    const params: Record<string, Object> = { 'xlh': xlh, 'zt': zt, 'reason': reason };
    const result: BizJsonResult = await ApiService.bizJson(Api.MEETING_UP_JOIN, 'POST', params);
    if (result.code === 0) {
      return new ApiResponse<string>(0, result.message, ApiService.pick(ApiService.asRecord(result.data), ['data']));
    }
    return new ApiResponse<string>(result.code, result.message, '');
  }

  /** 源码 MeetingModel.W0（WeekPlanDetailView 取消会议 g.a）：POST cancelMeeting {meetingXLH,cancel_remark} */
  static async cancelMeeting(meetingXLH: string, cancelRemark: string): Promise<ApiResponse<string>> {
    const params: Record<string, Object> = { 'meetingXLH': meetingXLH, 'cancel_remark': cancelRemark };
    const result: BizJsonResult = await ApiService.bizJson(Api.MEETING_CANCEL_MEETING, 'POST', params);
    if (result.code === 0) {
      return new ApiResponse<string>(0, result.message, ApiService.pick(ApiService.asRecord(result.data), ['data']));
    }
    return new ApiResponse<string>(result.code, result.message, '');
  }

  /** 源码 MeetingModel.T0（MeetingAnnouncementActivity.X2 发布公告）：POST addMeetingFeedBack {meetingId,message} */
  static async addMeetingFeedback(meetingId: string, message: string): Promise<ApiResponse<string>> {
    const params: Record<string, Object> = { 'meetingId': meetingId, 'message': message };
    const result: BizJsonResult = await ApiService.bizJson(Api.MEETING_ADD_MEETING_FEEDBACK, 'POST', params);
    if (result.code === 0) {
      return new ApiResponse<string>(0, result.message, ApiService.pick(ApiService.asRecord(result.data), ['data']));
    }
    return new ApiResponse<string>(result.code, result.message, '');
  }

  /** 源码 MeetingModel.g1（MeetingSignActivity.a3 已签名单）：GET getSignUser {hyid} → SignUser[] */
  static async getMeetingSignUser(hyid: string): Promise<ApiResponse<SignUserEntity[]>> {
    const params: Record<string, Object> = { 'hyid': hyid };
    const result: BizJsonResult = await ApiService.bizJson(Api.MEETING_GET_SIGN_USER, 'GET', params);
    if (result.code === 0) {
      const items: SignUserEntity[] = [];
      const raw: Object[] = ApiService.extractArray(result.data);
      for (const one of raw) {
        items.push(ApiService.parseSignUser(one));
      }
      return new ApiResponse<SignUserEntity[]>(0, result.message, items);
    }
    return new ApiResponse<SignUserEntity[]>(result.code, result.message, []);
  }

  /** 源码 MeetingModel.e1（MeetingSignActivity.b3 未签名单）：GET getNoSignUser {hyid} → SignUser[] */
  static async getMeetingNoSignUser(hyid: string): Promise<ApiResponse<SignUserEntity[]>> {
    const params: Record<string, Object> = { 'hyid': hyid };
    const result: BizJsonResult = await ApiService.bizJson(Api.MEETING_GET_NO_SIGN_USER, 'GET', params);
    if (result.code === 0) {
      const items: SignUserEntity[] = [];
      const raw: Object[] = ApiService.extractArray(result.data);
      for (const one of raw) {
        items.push(ApiService.parseSignUser(one));
      }
      return new ApiResponse<SignUserEntity[]>(0, result.message, items);
    }
    return new ApiResponse<SignUserEntity[]>(result.code, result.message, []);
  }

  /** 源码 MeetingModel.p1（MeetingAttendActivity.K2 / MeetingSignActivity.d3 长按自签）：POST sign {hyid} */
  static async signMeeting(hyid: string): Promise<ApiResponse<string>> {
    const params: Record<string, Object> = { 'hyid': hyid };
    const result: BizJsonResult = await ApiService.bizJson(Api.MEETING_SIGN, 'POST', params);
    if (result.code === 0) {
      return new ApiResponse<string>(0, result.message, ApiService.pick(ApiService.asRecord(result.data), ['data']));
    }
    return new ApiResponse<string>(result.code, result.message, '');
  }

  /** 源码 MeetingModel.q1（MeetingSignActivity.e3 未签人签到）：POST toSign {hyid,yhid} */
  static async toSignMeeting(hyid: string, yhid: string): Promise<ApiResponse<string>> {
    const params: Record<string, Object> = { 'hyid': hyid, 'yhid': yhid };
    const result: BizJsonResult = await ApiService.bizJson(Api.MEETING_TO_SIGN, 'POST', params);
    if (result.code === 0) {
      return new ApiResponse<string>(0, result.message, ApiService.pick(ApiService.asRecord(result.data), ['data']));
    }
    return new ApiResponse<string>(result.code, result.message, '');
  }

  /** 源码 MeetingModel.n1（MeetingSignActivity.f3 取消已签）：POST noSign {hyid,yhid} */
  static async noSignMeeting(hyid: string, yhid: string): Promise<ApiResponse<string>> {
    const params: Record<string, Object> = { 'hyid': hyid, 'yhid': yhid };
    const result: BizJsonResult = await ApiService.bizJson(Api.MEETING_NO_SIGN, 'POST', params);
    if (result.code === 0) {
      return new ApiResponse<string>(0, result.message, ApiService.pick(ApiService.asRecord(result.data), ['data']));
    }
    return new ApiResponse<string>(result.code, result.message, '');
  }

  /** MeetingObj 解析（26 字段 Gson 1:1；CHRS/IS_JOIN/IS_SIGN int，其余字符串） */
  static parseMeetingObj(data: Object): MeetingObjEntity {
    const rec: Record<string, Object> = ApiService.asRecord(data);
    const obj: MeetingObjEntity = new MeetingObjEntity();
    obj.ADDRESS = ApiService.pick(rec, ['ADDRESS']);
    for (const one of ApiService.parseChildArray(rec, 'ATTACHMENT_LIST')) {
      const ar: Record<string, Object> = ApiService.asRecord(one);
      const att: MeetingAttachmentEntity = new MeetingAttachmentEntity();
      att.DOWNLOAD_URL = ApiService.pick(ar, ['DOWNLOAD_URL']);
      att.FILENAME = ApiService.pick(ar, ['FILENAME']);
      obj.ATTACHMENT_LIST.push(att);
    }
    obj.CHLD = ApiService.pick(rec, ['CHLD']);
    obj.CHRS = ApiService.pickNumber(rec, ['CHRS']);
    obj.CHRY = ApiService.pick(rec, ['CHRY']);
    for (const one of ApiService.parseChildArray(rec, 'EXTRA')) {
      obj.EXTRA.push(ApiService.parseMeetingExtra(one));
    }
    obj.FNBRY = ApiService.pick(rec, ['FNBRY']);
    obj.GUUID = ApiService.pick(rec, ['GUUID']);
    obj.HYID = ApiService.pick(rec, ['HYID']);
    obj.IS_CURRENT_USER_PLAN = ApiService.pick(rec, ['IS_CURRENT_USER_PLAN']);
    obj.IS_JOIN = ApiService.pickNumber(rec, ['IS_JOIN']);
    obj.IS_SHOW = ApiService.pick(rec, ['IS_SHOW']);
    obj.IS_SIGN = ApiService.pickNumber(rec, ['IS_SIGN']);
    obj.JBDW = ApiService.pick(rec, ['JBDW']);
    obj.JSSJ = ApiService.pick(rec, ['JSSJ']);
    obj.KSSJ = ApiService.pick(rec, ['KSSJ']);
    obj.LXR = ApiService.pick(rec, ['LXR']);
    obj.LXRDH = ApiService.pick(rec, ['LXRDH']);
    obj.QXLY = ApiService.pick(rec, ['QXLY']);
    obj.STATUS = ApiService.pick(rec, ['STATUS']);
    obj.TITLE = ApiService.pick(rec, ['TITLE']);
    obj.WEEK = ApiService.pick(rec, ['WEEK']);
    obj.XLH = ApiService.pick(rec, ['XLH']);
    obj.XWRY = ApiService.pick(rec, ['XWRY']);
    obj.ZCR = ApiService.pick(rec, ['ZCR']);
    obj.feedBackType = ApiService.pick(rec, ['feedBackType']);
    obj.meetingReportType = ApiService.pick(rec, ['meetingReportType']);
    return obj;
  }

  /** MeetingObj.EXTRABean 解析（{LENGTH:int, TYPE, DATA[]}） */
  static parseMeetingExtra(one: Object): MeetingExtraEntity {
    const rec: Record<string, Object> = ApiService.asRecord(one);
    const extra: MeetingExtraEntity = new MeetingExtraEntity();
    extra.LENGTH = ApiService.pickNumber(rec, ['LENGTH']);
    extra.TYPE = ApiService.pick(rec, ['TYPE']);
    for (const child of ApiService.parseChildArray(one, 'DATA')) {
      const cr: Record<string, Object> = ApiService.asRecord(child);
      const row: MeetingExtraDataEntity = new MeetingExtraDataEntity();
      row.BCJYY = ApiService.pick(cr, ['BCJYY']);
      row.EMAIL = ApiService.pick(cr, ['EMAIL']);
      row.EMAIL_SEND = ApiService.pick(cr, ['EMAIL_SEND']);
      row.MEETING_ID = ApiService.pick(cr, ['MEETING_ID']);
      row.MESSAGE_SEND = ApiService.pick(cr, ['MESSAGE_SEND']);
      row.NAME = ApiService.pick(cr, ['NAME']);
      row.PHONE = ApiService.pick(cr, ['PHONE']);
      row.XLH = ApiService.pick(cr, ['XLH']);
      row.YHID = ApiService.pick(cr, ['YHID']);
      row.YHNAME = ApiService.pick(cr, ['YHNAME']);
      extra.DATA.push(row);
    }
    return extra;
  }

  /** MeetingAnnouncement 解析（6 字段 Gson 1:1） */
  static parseMeetingAnnouncement(one: Object): MeetingAnnouncementEntity {
    const rec: Record<string, Object> = ApiService.asRecord(one);
    const item: MeetingAnnouncementEntity = new MeetingAnnouncementEntity();
    item.CREATE_TIME = ApiService.pick(rec, ['CREATE_TIME']);
    item.ID = ApiService.pick(rec, ['ID']);
    item.MEETING_ID = ApiService.pick(rec, ['MEETING_ID']);
    item.MESSAGE = ApiService.pick(rec, ['MESSAGE']);
    item.USER_ID = ApiService.pick(rec, ['USER_ID']);
    item.USER_NAME = ApiService.pick(rec, ['USER_NAME']);
    return item;
  }

  /** SignUser 解析（4 字段 Gson 1:1，BCJYY Object→字符串） */
  static parseSignUser(one: Object): SignUserEntity {
    const rec: Record<string, Object> = ApiService.asRecord(one);
    const item: SignUserEntity = new SignUserEntity();
    item.BCJYY = ApiService.pick(rec, ['BCJYY']);
    item.XLH = ApiService.pick(rec, ['XLH']);
    item.YHID = ApiService.pick(rec, ['YHID']);
    item.YHNAME = ApiService.pick(rec, ['YHNAME']);
    return item;
  }

  // ===== [W18 meeting-remain] 会议链剩余页（MeetingWeekDetailActivity/MeetingReportEditActivity/
  // MeetingReportShowActivity/MeetingSelectorActivity 源码级，经 MeetingPImpl→MeetingModel/
  // SelectPImpl→SelectModel 管道；探针 probe_w18_meeting_remain.py 实测）=====

  /** 源码 MeetingModel.i1（MeetingWeekDetailActivity.Y2）：GET getWeekPlanDetails {xlh} → MeetingWeekDetail（实测 code=0 全字段） */
  static async getMeetingWeekPlanDetails(xlh: string): Promise<ApiResponse<MeetingWeekDetailEntity>> {
    const params: Record<string, Object> = { 'xlh': xlh };
    const result: BizJsonResult = await ApiService.bizJson(Api.MEETING_GET_WEEK_PLAN_DETAILS, 'GET', params);
    if (result.code === 0) {
      return new ApiResponse<MeetingWeekDetailEntity>(0, result.message,
        ApiService.parseMeetingWeekDetail(result.data));
    }
    return new ApiResponse<MeetingWeekDetailEntity>(result.code, result.message, new MeetingWeekDetailEntity());
  }

  /** MeetingWeekDetail 解析（13 字段 Gson 1:1，FJID Object→字符串） */
  static parseMeetingWeekDetail(data: Object): MeetingWeekDetailEntity {
    const rec: Record<string, Object> = ApiService.asRecord(data);
    const item: MeetingWeekDetailEntity = new MeetingWeekDetailEntity();
    item.BZ = ApiService.pick(rec, ['BZ']);
    item.CYRY = ApiService.pick(rec, ['CYRY']);
    item.DD = ApiService.pick(rec, ['DD']);
    item.FJID = ApiService.pick(rec, ['FJID']);
    item.IS_MY_WEEK_PLAN = ApiService.pick(rec, ['IS_MY_WEEK_PLAN']);
    item.JSSJ = ApiService.pick(rec, ['JSSJ']);
    item.KSSJ = ApiService.pick(rec, ['KSSJ']);
    item.LXDH = ApiService.pick(rec, ['LXDH']);
    item.WEEK = ApiService.pick(rec, ['WEEK']);
    item.XLH = ApiService.pick(rec, ['XLH']);
    item.ZBDW = ApiService.pick(rec, ['ZBDW']);
    item.ZCR = ApiService.pick(rec, ['ZCR']);
    item.ZT = ApiService.pick(rec, ['ZT']);
    return item;
  }

  /** 源码 MeetingModel.U0（MeetingWeekDetailActivity.W2 添加到个人会议）：POST addMyWeekPlan {xlh}（实测无效 xlh code=2014"周程详情出错"） */
  static async addMyWeekPlan(xlh: string): Promise<ApiResponse<string>> {
    const params: Record<string, Object> = { 'xlh': xlh };
    const result: BizJsonResult = await ApiService.bizJson(Api.MEETING_ADD_MY_WEEK_PLAN, 'POST', params);
    if (result.code === 0) {
      return new ApiResponse<string>(0, result.message, ApiService.pick(ApiService.asRecord(result.data), ['data']));
    }
    return new ApiResponse<string>(result.code, result.message, '');
  }

  /** 源码 MeetingModel.X0（MeetingWeekDetailActivity.X2 取消添加）：POST cancelWeekPlan {xlh}（实测无效 xlh code=2004"周程会议取消失败"） */
  static async cancelWeekPlan(xlh: string): Promise<ApiResponse<string>> {
    const params: Record<string, Object> = { 'xlh': xlh };
    const result: BizJsonResult = await ApiService.bizJson(Api.MEETING_CANCEL_WEEK_PLAN, 'POST', params);
    if (result.code === 0) {
      return new ApiResponse<string>(0, result.message, ApiService.pick(ApiService.asRecord(result.data), ['data']));
    }
    return new ApiResponse<string>(result.code, result.message, '');
  }

  /** 源码 MeetingModel.k1（MeetingReportShowActivity.b3）：POST_CONTENT showMeetingReport {meetingXLH=HYID} → Report
   *  （e.d 管道=body AES(JSON)；实参 HYID 实证：b3() 传 this.q=intent"HYID"；实测无报告会议 code=0001） */
  static async showMeetingReport(meetingXLH: string): Promise<ApiResponse<MeetingReportEntity>> {
    const params: Record<string, Object> = { 'meetingXLH': meetingXLH };
    const result: BizJsonResult = await ApiService.bizJson(Api.MEETING_SHOW_MEETING_REPORT, 'POST', params);
    if (result.code === 0) {
      const rec: Record<string, Object> = ApiService.asRecord(result.data);
      const bean: MeetingReportEntity = new MeetingReportEntity();
      bean.MEETING_CONTENT = ApiService.pick(rec, ['MEETING_CONTENT']);
      bean.MEETING_XLH = ApiService.pick(rec, ['MEETING_XLH']);
      bean.PIC = ApiService.pick(rec, ['PIC']);
      bean.STATE = ApiService.pick(rec, ['STATE']);
      return new ApiResponse<MeetingReportEntity>(0, result.message, bean);
    }
    return new ApiResponse<MeetingReportEntity>(result.code, result.message, new MeetingReportEntity());
  }

  /** 源码 MeetingModel.j1（MeetingReportShowActivity.Z2 删除报告）：POST delMeetingReport {meetingXLH}
   *  成功判定 data=="1"（ITagManager.STATUS_TRUE；实测无报告会议 data=false → 失败分支） */
  static async delMeetingReport(meetingXLH: string): Promise<ApiResponse<Object>> {
    const params: Record<string, Object> = { 'meetingXLH': meetingXLH };
    const result: BizJsonResult = await ApiService.bizJson(Api.MEETING_DEL_MEETING_REPORT, 'POST', params);
    return new ApiResponse<Object>(result.code, result.message, result.data);
  }

  /** 源码 MeetingModel.o1（MeetingReportShowActivity.f3 开关可见性）：POST openMeetingReport {meetingId,openType:"on"/"off"}
   *  成功判定 code==0（h.g "0".equals(str)；实测无效 openType code=开放会议报告给参会人员失败） */
  static async openMeetingReport(meetingId: string, openType: string): Promise<ApiResponse<Object>> {
    const params: Record<string, Object> = { 'meetingId': meetingId, 'openType': openType };
    const result: BizJsonResult = await ApiService.bizJson(Api.MEETING_OPEN_MEETING_REPORT, 'POST', params);
    return new ApiResponse<Object>(result.code, result.message, result.data);
  }

  /** 源码 MeetingModel.l1（MeetingReportEditActivity.d3 新建报告）：POST_MULTIPART saveMeetingReport
   *  {meetingXLH=HYID, content} + PIC 文件（SubmitFileBean.setKeyName("PIC")） */
  static async saveMeetingReport(meetingXLH: string, content: string,
    pics: string[]): Promise<ApiResponse<Object>> {
    const fields: Record<string, string> = { 'meetingXLH': meetingXLH, 'content': content };
    const response: ApiResponse<Object> = await HttpClient.bizMultipartPost(
      Api.MEETING_SAVE_MEETING_REPORT, fields, pics);
    return response;
  }

  /** 源码 MeetingModel.m1（MeetingReportEditActivity.f3 更新报告）：POST_MULTIPART updateMeetingReport
   *  {detelePicXLH, meetingXLH, content, oldPicXLH} + PIC 文件 */
  static async updateMeetingReport(meetingXLH: string, content: string, oldPicXLH: string,
    detelePicXLH: string, pics: string[]): Promise<ApiResponse<Object>> {
    const fields: Record<string, string> = {
      'detelePicXLH': detelePicXLH,
      'meetingXLH': meetingXLH,
      'content': content,
      'oldPicXLH': oldPicXLH
    };
    const response: ApiResponse<Object> = await HttpClient.bizMultipartPost(
      Api.MEETING_UPDATE_MEETING_REPORT, fields, pics);
    return response;
  }

  /** 源码 SelectModel.b1（MeetingSelectorActivity.O2）：GET select/meeting 无参 → MeetingSelector[] 树
   *  （实测 code=0：校区→楼栋→房间递归 data；data 空=叶子=可选中） */
  static async getMeetingSelector(): Promise<ApiResponse<MeetingSelectorEntity[]>> {
    const result: BizJsonResult = await ApiService.bizJson(Api.SELECT_MEETING, 'GET', {});
    if (result.code === 0) {
      const items: MeetingSelectorEntity[] = [];
      for (const one of ApiService.extractArray(result.data)) {
        items.push(ApiService.parseMeetingSelector(one));
      }
      return new ApiResponse<MeetingSelectorEntity[]>(0, result.message, items);
    }
    return new ApiResponse<MeetingSelectorEntity[]>(result.code, result.message, []);
  }

  /** MeetingSelector 解析（5 字段 Gson 1:1，data 递归） */
  static parseMeetingSelector(one: Object): MeetingSelectorEntity {
    const rec: Record<string, Object> = ApiService.asRecord(one);
    const item: MeetingSelectorEntity = new MeetingSelectorEntity();
    item.id = ApiService.pick(rec, ['id']);
    item.name = ApiService.pick(rec, ['name']);
    item.text = ApiService.pick(rec, ['text']);
    item.type = ApiService.pick(rec, ['type']);
    for (const child of ApiService.parseChildArray(one, 'data')) {
      item.data.push(ApiService.parseMeetingSelector(child));
    }
    return item;
  }

  /** 报告保存/更新响应成功判定（源码 g(): !"\"1\"".equals(str4) → 失败；服务器实测形态含 bool） */
  static meetingReportDataOk(data: Object): boolean {
    if (typeof data === 'boolean') {
      return data as boolean;
    }
    if (typeof data === 'string') {
      return (data as string) === '1' || (data as string) === '"1"';
    }
    return false;
  }

  // ===== [E4 attendance worker] 考勤模块（AttendancePresenter c/e/a/a/a/c/a + AttendanceModel 源码级） =====
  /** 源码 AttendanceModel.W0（AttendanceMainActivity.M2→isBoss）：GET isBoss 无参数 → AttendanceIsBoss */
  static async getAttendanceIsBoss(): Promise<ApiResponse<AttendanceIsBoss>> {
    const result: BizJsonResult = await ApiService.bizJson(Api.ATTENDANCE_IS_BOSS, 'GET', {});
    if (result.code === 0) {
      const rec: Record<string, Object> = ApiService.asRecord(result.data);
      const bean: AttendanceIsBoss = new AttendanceIsBoss();
      bean.isBoss = ApiService.pick(rec, ['isBoss']);
      return new ApiResponse<AttendanceIsBoss>(0, result.message, bean);
    }
    return new ApiResponse<AttendanceIsBoss>(result.code, result.message, new AttendanceIsBoss());
  }

  /** 源码 AttendanceModel.V0：POST index body={month:"yyyyMM"} → AttendanceIndex（个人考勤月历）
   *  e.d(url, k.m(map)) = POST_CONTENT（body=JSON 加密），非 GET */
  static async getAttendanceIndex(month: string): Promise<ApiResponse<AttendanceIndex>> {
    const params: Record<string, Object> = { 'month': month };
    const result: BizJsonResult = await ApiService.bizJson(Api.ATTENDANCE_INDEX, 'POST', params);
    if (result.code === 0) {
      return new ApiResponse<AttendanceIndex>(0, result.message, ApiService.parseAttendanceIndex(result.data));
    }
    return new ApiResponse<AttendanceIndex>(result.code, result.message, new AttendanceIndex());
  }

  /** AttendanceIndex 解析：attendanceRecordByMonth{days,dayOfAttendance,attendanceByDay,errorRecord} */
  static parseAttendanceIndex(data: Object): AttendanceIndex {
    const rec: Record<string, Object> = ApiService.asRecord(data);
    const raw: Object = rec['attendanceRecordByMonth'];
    const monthRec: Record<string, Object> = ApiService.asRecord(raw === undefined ? new Object() : raw);
    const bean: AttendanceIndex = new AttendanceIndex();
    bean.attendanceRecordByMonth.days = ApiService.pick(monthRec, ['days']);
    bean.attendanceRecordByMonth.dayOfAttendance = ApiService.pick(monthRec, ['dayOfAttendance']);
    for (const one of ApiService.parseChildArray(monthRec, 'attendanceByDay')) {
      bean.attendanceRecordByMonth.attendanceByDay.push(ApiService.parseAttendanceByDay(one));
    }
    for (const one of ApiService.parseChildArray(monthRec, 'errorRecord')) {
      const r: Record<string, Object> = ApiService.asRecord(one);
      const err: AttendanceErrorRecordBean = new AttendanceErrorRecordBean();
      err.errorDetailName = ApiService.pick(r, ['errorDetailName']);
      err.errorDetailTimes = ApiService.pick(r, ['errorDetailTimes']);
      err.errorDetailType = ApiService.pick(r, ['errorDetailType']);
      bean.attendanceRecordByMonth.errorRecord.push(err);
    }
    return bean;
  }

  /** AttendanceByDayBean 解析（Gson 字段 1:1） */
  static parseAttendanceByDay(one: Object): AttendanceByDayBean {
    const r: Record<string, Object> = ApiService.asRecord(one);
    const bean: AttendanceByDayBean = new AttendanceByDayBean();
    bean.attendanceGroup = ApiService.pick(r, ['attendanceGroup']);
    bean.classes = ApiService.pick(r, ['classes']);
    bean.date = ApiService.pick(r, ['date']);
    bean.sbdkfs = ApiService.pick(r, ['sbdkfs']);
    bean.sbdksj = ApiService.pick(r, ['sbdksj']);
    bean.sbdkzt = ApiService.pick(r, ['sbdkzt']);
    bean.type = ApiService.pick(r, ['type']);
    bean.xbdkfs = ApiService.pick(r, ['xbdkfs']);
    bean.xbdksj = ApiService.pick(r, ['xbdksj']);
    bean.xbdkzt = ApiService.pick(r, ['xbdkzt']);
    return bean;
  }

  /** 源码 AttendanceModel.T0：POST bossIndex body={month:"yyyy-MM"} → AttendanceBossIndex（院系月份统计） */
  static async getAttendanceBossIndex(month: string): Promise<ApiResponse<AttendanceBossIndex>> {
    const params: Record<string, Object> = { 'month': month };
    const result: BizJsonResult = await ApiService.bizJson(Api.ATTENDANCE_BOSS_INDEX, 'POST', params);
    if (result.code === 0) {
      return new ApiResponse<AttendanceBossIndex>(0, result.message,
        ApiService.parseAttendanceBossIndex(result.data));
    }
    return new ApiResponse<AttendanceBossIndex>(result.code, result.message, new AttendanceBossIndex());
  }

  /** AttendanceBossIndex 解析：num + attendanceList[{groupName,groupType,peopleList}] */
  static parseAttendanceBossIndex(data: Object): AttendanceBossIndex {
    const rec: Record<string, Object> = ApiService.asRecord(data);
    const bean: AttendanceBossIndex = new AttendanceBossIndex();
    bean.num = ApiService.pick(rec, ['num']);
    bean.date = ApiService.pick(rec, ['date']);
    for (const one of ApiService.parseChildArray(rec, 'attendanceList')) {
      const g: Record<string, Object> = ApiService.asRecord(one);
      const group: AttendanceGroupBean = new AttendanceGroupBean();
      group.groupName = ApiService.pick(g, ['groupName']);
      // 2026-11-17 实测 bossIndex 响应键为 "type"（"Leave"/"Travel"/"Go-out"/"NotSigned"/"Absense"）
      group.groupType = ApiService.pick(g, ['groupType', 'type']);
      for (const p of ApiService.parseChildArray(g, 'peopleList')) {
        const pr: Record<string, Object> = ApiService.asRecord(p);
        const person: AttendancePeopleListBean = new AttendancePeopleListBean();
        person.departmentName = ApiService.pick(pr, ['departmentName']);
        person.imgUrl = ApiService.pick(pr, ['imgUrl']);
        person.times = ApiService.pick(pr, ['times']);
        person.userId = ApiService.pick(pr, ['userId']);
        person.userName = ApiService.pick(pr, ['userName']);
        group.peopleList.push(person);
      }
      bean.attendanceList.push(group);
    }
    return bean;
  }

  // ===== [W4 sms-login] 手机号登录三接口（源码 IdentifyCodeModel.java = module/b/g/f.java，Python 全链路实测通） =====
  /** 源码 f.T0：POST /open/auth/checkLoginPhone {phoneNum} → {timeFrequency:90, canSendSms:true}
   *  timeFrequency 为服务器下发倒计时秒数（识别码页"Xs后重发"），缺失回退 90s。
   */
  static async checkLoginPhone(phoneNum: string): Promise<ApiResponse<CheckLoginPhoneResult>> {
    const params: Record<string, Object> = { 'phoneNum': phoneNum };
    const result: BizJsonResult = await ApiService.bizJson(Api.CHECK_LOGIN_PHONE, 'POST', params);
    if (result.code === 0) {
      const rec: Record<string, Object> = ApiService.asRecord(result.data);
      const out: CheckLoginPhoneResult = new CheckLoginPhoneResult();
      const tf: number = ApiService.pickNumber(rec, ['timeFrequency']);
      out.timeFrequency = tf > 0 ? tf : Api.SMS_TIME_FREQUENCY;
      const can: Object = rec['canSendSms'];
      out.canSendSms = can === true || can === 'true' || can === 1 || can === '1';
      return new ApiResponse<CheckLoginPhoneResult>(0, result.message, out);
    }
    return new ApiResponse<CheckLoginPhoneResult>(result.code, result.message, new CheckLoginPhoneResult());
  }

  /** 源码 f.V0：POST /open/auth/SendSms {phoneNum} → code=0（真实下发短信到用户手机）
   *  注意：SendSms 成功响应 data 为空，bizJson 的"code=0+空data→失败"包装会误判，
   *  故此处直接走 HttpClient.bizRequest（同一加密 POST 管道）以 code=0 为准。
   */
  static async sendSms(phoneNum: string): Promise<ApiResponse<Object>> {
    const params: Record<string, Object> = { 'phoneNum': phoneNum };
    const response: ApiResponse<Object> = await HttpClient.bizRequest(Api.SEND_SMS, 'POST', params);
    return new ApiResponse<Object>(response.code, response.message, response.data);
  }

  /** 源码 f.U0：POST /open/auth/loginBySms body=AES(LoginSumbitEntity) → UserEntity
   *  实体与密码登录 LoginSumbitEntity 全字段同构（17 字段：userId/passw 置空，phoneNum+checkCode 认证，
   *  schoolId="SDGY"；city/province/latitude/longitude/imei 由 InitSumbitCommonEntity.initSumbitEntity
   *  置空串 —— 与 LoginSession.login() 密码 body 的空值形态一致）。
   *  成功路径：解密 UserEntity → LoginSession.parseUserEntity 填充会话全字段 → persistSession
   *  持久化（等价密码登录成功路径，重启免协商）→ 返回 UserInfo。
   */
  static async loginBySms(phoneNum: string, checkCode: string): Promise<ApiResponse<UserInfo>> {
    const entity: Record<string, Object> = {
      'userId': '',
      'passw': '',
      'schoolId': 'SDGY',
      'phoneNum': phoneNum,
      'checkCode': checkCode,
      'city': '',
      'province': '',
      'clientVersion': Constants.CLIENT_VERSION,
      'serverApiVersion': Constants.CLIENT_VERSION,
      'androidClientVersionCode': '68',
      'deviceModel': Constants.DEVICE_MODEL,
      'deviceType': '1',
      'deviceVersion': '14',
      'latitude': '',
      'longitude': '',
      'imei': '',
      'deviceId': Constants.DEVICE_ID
    };
    const result: BizJsonResult = await ApiService.bizJson(Api.LOGIN_BY_SMS, 'POST', entity);
    if (result.code === 0) {
      // UserEntity 与密码登录同结构：复用 parseUserEntity 填充 sessionKey/userId/userType/
      // schoolId/姓名院系班级年级手机全字段，再持久化
      const user: UserInfo = LoginSession.parseUserEntity(JSON.stringify(result.data));
      if (user.userId === '') {
        return new ApiResponse<UserInfo>(ApiService.OFFLINE_CODE, '登录响应解析失败',
          ApiService.mockUser(phoneNum));
      }
      await LoginSession.persistSession();
      LoginSession.log('短信登录成功 userId=' + user.userId + ' name=' + user.name);
      return new ApiResponse<UserInfo>(0, result.message === '' ? '请求成功' : result.message, user);
    }
    if (result.code === ApiService.NOT_LOGIN_CODE) {
      return new ApiResponse<UserInfo>(result.code, result.message, ApiService.mockUser(phoneNum));
    }
    return new ApiResponse<UserInfo>(result.code,
      result.message === '' ? '验证码错误或已过期' : result.message, ApiService.mockUser(phoneNum));
  }

  // ===== [W17 profile-series] 个人资料编辑链 4 页数据层（ChangeNickNameActivity/
  // MobileCampusInputEmailActivity/MobileCampusInputPhoneActivity/MobileCampusBindPhoneActivity 源码级） =====
  // 通道：源码 e.d(path,json)=POST_CONTENT body=AES(JSON)（同 sendSms 的 bizRequest 直连管道，
  // 响应 data 多为空串/简单串，绕过 bizJson 的空 data 包装以 code 为准）。

  /** 源码 ChangeNickNameModel.T0：POST updateNickname {nickname} → data 串
   *  业务成功（code=0）后页面另发 syncNicknameToLianyi（源码 b$a.g → U0）。
   */
  static async updateNickname(nickname: string): Promise<ApiResponse<Object>> {
    const params: Record<string, Object> = { 'nickname': nickname };
    const response: ApiResponse<Object> = await HttpClient.bizRequest(Api.USER_UPDATE_NICKNAME, 'POST', params);
    return new ApiResponse<Object>(response.code, response.message, response.data);
  }

  /** 源码 ChangeNickNameModel.U0：POST https://www.yibaogao.com/mobileapi/campus/user/updateNickname
   *  {nickname} + 请求头 xxdm（PushModel 同款连乙加密通道 pushBizPost；W12 实测该域名不可达，失败静默——
   *  源码 C0401a 回调仅隐藏 loading，不影响主流程）。
   */
  static async syncNicknameToLianyi(nickname: string): Promise<ApiResponse<Object>> {
    const params: Record<string, Object> = { 'nickname': nickname };
    const response: ApiResponse<Object> =
      await HttpClient.pushBizPost(Api.NICKNAME_SYNC_HOST + Api.NICKNAME_SYNC, params);
    return new ApiResponse<Object>(response.code, response.message, response.data);
  }

  /** 源码 BindEmailModel.T0：POST saveEmail {userId, userType, email_url} → SavePhoneResult */
  static async saveEmail(email: string): Promise<ApiResponse<Object>> {
    const params: Record<string, Object> = {
      'userId': LoginSession.userId,
      'userType': LoginSession.userType,
      'email_url': email
    };
    const response: ApiResponse<Object> = await HttpClient.bizRequest(Api.BIND_EMAIL_SAVE, 'POST', params);
    return new ApiResponse<Object>(response.code, response.message, response.data);
  }

  /** 源码 BindPhoneModel.U0：POST savePhone {code:userId, type:userType, phone} → SavePhoneResult
   *  f.java 分发：code=="0" 进 g 回调（成功），code!="0" 进 f 回调 toast(message)。
   */
  static async savePhone(phone: string): Promise<ApiResponse<Object>> {
    const params: Record<string, Object> = {
      'code': LoginSession.userId,
      'type': LoginSession.userType,
      'phone': phone
    };
    const response: ApiResponse<Object> = await HttpClient.bizRequest(Api.BIND_PHONE_SAVE, 'POST', params);
    return new ApiResponse<Object>(response.code, response.message, response.data);
  }

  /** 源码 BindPhoneModel.T0：POST queryBindPhoneStatus {code:userId, type:userType} → PhoneStatus
   *  {bindPhone:"0"/"1"/"2", bind_card, hasPhone, hasSchoolCirclePhone, message}（PersonalDetailNewActivity.T2）。
   */
  static async queryBindPhoneStatus(): Promise<ApiResponse<Object>> {
    const params: Record<string, Object> = {
      'code': LoginSession.userId,
      'type': LoginSession.userType
    };
    const response: ApiResponse<Object> = await HttpClient.bizRequest(Api.BIND_PHONE_STATUS, 'POST', params);
    return new ApiResponse<Object>(response.code, response.message, response.data);
  }

  /** 源码 VerifyCodeModel.M0：POST getVercode {schoolId, userId, mobile, type, [SchoolCircle]}
   *  type：设备验证流程="4"，绑定流程="1"（MobileCampusBindPhoneActivity.i3）；
   *  isCircle（校圈绑定）追加 SchoolCircle 键（umeng pro am.e="SchoolCircle"）；
   *  GXMD 学校追加 codeNum="6"（M0 内 schoolId 判断，与 VerifyCodeView 6 格配套）。
   */
  static async getVerifyCode(mobile: string, type: string, isCircle: boolean): Promise<ApiResponse<Object>> {
    const params: Record<string, Object> = {
      'schoolId': LoginSession.schoolId,
      'userId': LoginSession.userId,
      'mobile': mobile,
      'type': type
    };
    if (isCircle) {
      params['SchoolCircle'] = 'SchoolCircle';
    }
    if (LoginSession.schoolId === 'GXMD') {
      params['codeNum'] = '6';
    }
    const response: ApiResponse<Object> = await HttpClient.bizRequest(Api.VERIFY_CODE_GET, 'POST', params);
    return new ApiResponse<Object>(response.code, response.message, response.data);
  }

  /** 源码 VerifyCodeModel.F：POST verifyVercode {schoolId, userId, mobile, vercode, [SchoolCircle]} */
  static async verifyVerifyCode(mobile: string, vercode: string, isCircle: boolean): Promise<ApiResponse<Object>> {
    const params: Record<string, Object> = {
      'schoolId': LoginSession.schoolId,
      'userId': LoginSession.userId,
      'mobile': mobile,
      'vercode': vercode
    };
    if (isCircle) {
      params['SchoolCircle'] = 'SchoolCircle';
    }
    const response: ApiResponse<Object> = await HttpClient.bizRequest(Api.VERIFY_CODE_VERIFY, 'POST', params);
    return new ApiResponse<Object>(response.code, response.message, response.data);
  }

  /** 源码 BindModel.G（module/b/g/a.java）：POST /mobileapi_ydxy/api/user/bindMobile {mobile}
   *  设备验证流程（BindPhoneActivity 非 justBindPhone 分支 h3 → u.c().b(phone)）。
   */
  static async bindMobileLianyi(mobile: string): Promise<ApiResponse<Object>> {
    const params: Record<string, Object> = { 'mobile': mobile };
    const response: ApiResponse<Object> = await HttpClient.bizRequest(Api.USER_BIND_MOBILE, 'POST', params);
    return new ApiResponse<Object>(response.code, response.message, response.data);
  }

  /** 源码 BindDeviceModel.T0：POST bindDevice/add {IMEI:s.g()=设备ID, sbmc:s.m()=Build.MODEL}
   *  设备验证绑定成功后登记设备（BindPhoneActivity.g3）。
   */
  static async bindDeviceAdd(): Promise<ApiResponse<Object>> {
    const params: Record<string, Object> = {
      'IMEI': Constants.DEVICE_ID,
      'sbmc': Constants.DEVICE_MODEL
    };
    const response: ApiResponse<Object> = await HttpClient.bizRequest(Api.BIND_DEVICE_ADD, 'POST', params);
    return new ApiResponse<Object>(response.code, response.message, response.data);
  }

  /** 源码 LoginModel.N0：POST /mobileapi_ydxy/open/auth/logout {userId, userType}
   *  InputPhone 返回弹窗点"退出"回调（W2 → module/b/h/b.k）。
   */
  static async authLogout(): Promise<ApiResponse<Object>> {
    const params: Record<string, Object> = {
      'userId': LoginSession.userId,
      'userType': LoginSession.userType
    };
    const response: ApiResponse<Object> = await HttpClient.bizRequest(Api.AUTH_LOGOUT_SCHOOL, 'POST', params);
    return new ApiResponse<Object>(response.code, response.message, response.data);
  }

  // ===== [W22 launch-chain] 启动/登录链接口（TabModel/ScanLoginModel/VerificationModel/PolymerizationModel 源码级） =====

  /** 源码 TabModel.T0：GET /api/getUserTabs（无参）→ RemoteHomeTabBean[]
   *  LoginedLaunchActivity.f1 启动即预取（响应 → HomeTabUtils.a 缓存 "tab_datas_login"，
   *  2026-11-18 探针实测 code=0 4 组：首页/资讯/…全字段）。
   */
  static async getUserTabs(): Promise<ApiResponse<RemoteHomeTabEntry[]>> {
    const response: ApiResponse<Object> = await HttpClient.getNoParams(Api.TAB_GET_USER_TABS);
    const out: RemoteHomeTabEntry[] = [];
    if (response.code !== 0 || typeof response.data !== 'string' || (response.data as string) === '') {
      return new ApiResponse<RemoteHomeTabEntry[]>(response.code, response.message, out);
    }
    try {
      const arr: Object[] = JSON.parse(response.data as string) as Object[];
      for (const one of arr) {
        const rec: Record<string, Object> = ApiService.asRecord(one);
        const e: RemoteHomeTabEntry = new RemoteHomeTabEntry();
        e.navigationId = ApiService.pick(rec, ['NAVIGATION_ID']);
        e.navigationBar = ApiService.pick(rec, ['NAVIGATION_BAR']);
        e.navigationName = ApiService.pick(rec, ['NAVIGATION_NAME']);
        e.defaultSelected = ApiService.pick(rec, ['DEFAULT_SELECTED']);
        e.status = ApiService.pick(rec, ['STATUS']);
        e.sort = ApiService.pick(rec, ['SORT']);
        e.jsid = ApiService.pick(rec, ['JSID']);
        e.title = ApiService.pick(rec, ['TITLE']);
        e.identifying = ApiService.pick(rec, ['IDENTIFYING']);
        out.push(e);
      }
      return new ApiResponse<RemoteHomeTabEntry[]>(0, response.message, out);
    } catch (error) {
      const be = error as BusinessError;
      ApiService.logError('getUserTabs parse fail: ' + be.message);
      return new ApiResponse<RemoteHomeTabEntry[]>(ApiService.OFFLINE_CODE, '响应解析失败', out);
    }
  }

  /** 源码 ScanLoginModel.V0：GET /api/scan/index {url}（ScanLoginActivity.M2 确认登录）
   *  2026-11-18 探针实测假 url code=1 "暂不支持"（data 无内容）；成功 data 为 String。
   *  可选 longitude/latitude：MainActivity /api/g/rq 与 v3 定位分支走 W0 三参形态
   *  （url+longitude+latitude，空串也发）；不传时保持 V0 单 url 参（y3 分支）。
   */
  static async scanLoginIndex(url: string, longitude?: string, latitude?: string):
    Promise<ApiResponse<Object>> {
    const params: Record<string, Object> = { 'url': url };
    if (longitude !== undefined) {
      params['longitude'] = longitude;
    }
    if (latitude !== undefined) {
      params['latitude'] = latitude;
    }
    const response: ApiResponse<Object> = await HttpClient.bizRequest(Api.SCAN_INDEX, 'GET', params);
    return new ApiResponse<Object>(response.code, response.message, response.data);
  }

  // ===== [W26 partial-finish] 扫码结果分流/学习报告/设置页数据管道（源码级） =====

  /** 源码 ScanLoginModel.T0（module/b/f.java）：POST_CONTENT /api/scan/accessGate {url}
   *  （MainActivity.j3 open.weixin.qq.com 分支 → ScanURL{jumpUrl} 轻应用直载） */
  static async scanAccessGate(url: string): Promise<ApiResponse<ScanJumpUrl>> {
    const params: Record<string, Object> = { 'url': url };
    const result: BizJsonResult = await ApiService.bizJson(Api.SCAN_ACCESS_GATE, 'POST', params);
    const out: ScanJumpUrl = new ScanJumpUrl();
    if (result.code !== 0) {
      return new ApiResponse<ScanJumpUrl>(result.code, result.message, out);
    }
    const rec: Record<string, Object> = ApiService.asRecord(result.data);
    out.jumpUrl = ApiService.pick(rec, ['jumpUrl']);
    return new ApiResponse<ScanJumpUrl>(0, result.message, out);
  }

  /** 源码 ScanLoginModel.U0：POST_CONTENT /api/scan/bpm {bpmUrl}
   *  （MainActivity.k3 /bpm/rule 分支 → ScanURL{jumpUrl}） */
  static async scanBpm(bpmUrl: string): Promise<ApiResponse<ScanJumpUrl>> {
    const params: Record<string, Object> = { 'bpmUrl': bpmUrl };
    const result: BizJsonResult = await ApiService.bizJson(Api.SCAN_BPM, 'POST', params);
    const out: ScanJumpUrl = new ScanJumpUrl();
    if (result.code !== 0) {
      return new ApiResponse<ScanJumpUrl>(result.code, result.message, out);
    }
    const rec: Record<string, Object> = ApiService.asRecord(result.data);
    out.jumpUrl = ApiService.pick(rec, ['jumpUrl']);
    return new ApiResponse<ScanJumpUrl>(0, result.message, out);
  }

  /** 源码 ScanLoginModel.W0：GET /api/scan/index {url, longitude, latitude}
   *  （MainActivity.v3 定位打卡分支 → data String URL） */
  static async scanIndexLocation(url: string, longitude: string, latitude: string): Promise<ApiResponse<Object>> {
    const params: Record<string, Object> = { 'url': url, 'longitude': longitude, 'latitude': latitude };
    const response: ApiResponse<Object> = await HttpClient.bizRequest(Api.SCAN_INDEX, 'GET', params);
    return new ApiResponse<Object>(response.code, response.message, response.data);
  }

  /** 源码 student_report/g/b/b.java StudyReportModel.d：
   *  e.b(StudyReportFactory.g("getRecentTermInfo")) → GET 加密通道 → TermInfo{XN,XQ}
   *  （2026-11-18 探针实测 code=0 XN=2025-2026 XQ=1 真实数据）
   */
  static async getStudyReportTermInfo(): Promise<ApiResponse<StudyTermInfo>> {
    const response: ApiResponse<Object> = await HttpClient.bizRequest(Api.GRADE_REPORT_TERM, 'GET', {});
    const out: StudyTermInfo = new StudyTermInfo();
    if (response.code !== 0) {
      return new ApiResponse<StudyTermInfo>(response.code, response.message, out);
    }
    const rec: Record<string, Object> = ApiService.asRecord(response.data);
    out.XN = ApiService.pick(rec, ['XN']);
    out.XQ = ApiService.pick(rec, ['XQ']);
    return new ApiResponse<StudyTermInfo>(0, response.message, out);
  }

  /** 源码 YDXYAppModel.T0（module/app/model/f.java）：e.d(g("configApp"), k.m({yyid, type:"2"})）
   *  POST_CONTENT 加密通道 → YDAPPInfo{TYPE, DATA[]}（MainSettingActivity.N2 添加/移除常用；
   *  2026-11-18 探针实测假 yyid code=0001 系统异常真实错误态，端点存活）
   */
  static async configMainApp(yyid: string): Promise<ApiResponse<MainAppGroup>> {
    const params: Record<string, Object> = { 'yyid': yyid, 'type': '2' };
    const result: BizJsonResult = await ApiService.bizJson(Api.APP_CONFIG, 'POST', params);
    const out: MainAppGroup = new MainAppGroup();
    if (result.code !== 0) {
      return new ApiResponse<MainAppGroup>(result.code, result.message, out);
    }
    const rec: Record<string, Object> = ApiService.asRecord(result.data);
    out.TYPE = ApiService.pick(rec, ['TYPE']);
    out.YYFL = ApiService.pick(rec, ['YYFL']);
    for (const one of ApiService.extractArray(result.data)) {
      const itemRec: Record<string, Object> = ApiService.asRecord(one);
      const item: MainAppItem = new MainAppItem();
      item.YYID = ApiService.pick(itemRec, ['YYID']);
      item.YYMC = ApiService.pick(itemRec, ['YYMC']);
      item.LX = ApiService.pick(itemRec, ['LX']);
      item.URL = ApiService.pick(itemRec, ['URL']);
      item.YYTB = ApiService.pick(itemRec, ['YYTB']);
      item.PXH = ApiService.pick(itemRec, ['PXH']);
      out.DATA.push(item);
    }
    return new ApiResponse<MainAppGroup>(0, result.message, out);
  }

  /** [W26 partial-finish] 源码 module/d/a.java AESUtils.a(userId)：AES/CBC/PKCS5(userId,
   *  key=f16217b="1716bf8fca1f9273" 字节, iv=f16218c="1230001000000000" 字节) → Base64
   *  （d/a.java L21/L25 源码字面硬编码保真，同 SportSteps 时间戳先例）。
   *  MainActivity /paysec/pay/cm 分支：userCode=URLEncoder.encode(加密userId) 拼进支付 URL。 */
  static encryptPayUserCode(userId: string): string {
    return CryptoUtil.encryptAESCBC(userId, '1716bf8fca1f9273', '1230001000000000');
  }

  /** 源码 VerificationModel.U0：POST /api/juherenzheng/checkPass {password}
   *  SettingActivity 手势密码行无已存手势时"校验密码"弹窗回调
   *  （2026-11-18 探针实测错密码 code=1033 "密码错误，验证失败"；成功 data String）。
   */
  static async checkGesturePassword(password: string): Promise<ApiResponse<Object>> {
    const params: Record<string, Object> = { 'password': password };
    const response: ApiResponse<Object> = await HttpClient.bizRequest(Api.JUHERENZHENG_CHECK_PASS, 'POST', params);
    return new ApiResponse<Object>(response.code, response.message, response.data);
  }

  /** 聚合认证请求头（PolymerizationModel.Z0 逐行还原）：
   *  GlobalParamInfo.getSystemSwitch()==null（HAP 同现状未持久化 SystemSwitch）→
   *  appId = ""、secretKey = "" → secret = md5(userId + "" + yyyyMMdd)（大写 hex），
   *  userId 头 = Base64(userId)（Y0）。domain 为扫码下发 PolymerizationResultBean.domain。
   */
  static async polyHeaders(): Promise<Record<string, string>> {
    const now: Date = new Date();
    const monthValue: number = now.getMonth() + 1;
    const mm: string = monthValue < 10 ? '0' + monthValue : String(monthValue);
    const dayValue: number = now.getDate();
    const dd: string = dayValue < 10 ? '0' + dayValue : String(dayValue);
    const dateStr: string = String(now.getFullYear()) + mm + dd;
    const secret: string = await CryptoUtil.md5HexUpper(LoginSession.userId + '' + dateStr);
    const headers: Record<string, string> = {
      'appid': '',
      'secret': secret,
      'userId': CryptoUtil.bytesToBase64(CryptoUtil.stringToBytes(LoginSession.userId))
    };
    return headers;
  }

  /** 源码 PolymerizationModel.X0：POST {domain}/lyuapServer/cam/v1/login {browserId, buildTime, typeId}
   *  FingerLoginActivity.L2：指纹校验通过后确认/取消电脑端登录（typeId "1"=确认 "0"=取消）。
   *  （W25-review：verify 端点已由 polymerizationVerify 承接，polyVerify 死代码移除。）
   */
  static async polyLogin(domain: string, browserId: string, buildTime: string,
    typeId: string): Promise<ApiResponse<Object>> {
    const headers: Record<string, string> = await ApiService.polyHeaders();
    const body: Record<string, Object> = { 'browserId': browserId, 'buildTime': buildTime, 'typeId': typeId };
    const response: ApiResponse<Object> =
      await HttpClient.polyPostJson(domain + '/lyuapServer/cam/v1/login', headers, body);
    return new ApiResponse<Object>(response.code, response.message, response.data);
  }

  /** 源码 PolymerizationModel.T0：POST {domain}/lyuapServer/cam/v1/bindBrowser {browserId, buildTime, typeId}
   *  FingerLoginActivity loginType=="scan_qrcode_login" 分支：先绑浏览器再确认登录。
   */
  static async polyBindBrowser(domain: string, browserId: string, buildTime: string,
    typeId: string): Promise<ApiResponse<Object>> {
    const headers: Record<string, string> = await ApiService.polyHeaders();
    const body: Record<string, Object> = { 'browserId': browserId, 'buildTime': buildTime, 'typeId': typeId };
    const response: ApiResponse<Object> =
      await HttpClient.polyPostJson(domain + '/lyuapServer/cam/v1/bindBrowser', headers, body);
    return new ApiResponse<Object>(response.code, response.message, response.data);
  }

  /** 源码 PolymerizationModel.U0：POST {domain}/lyuapServer/cam/v1/bindApp {typeId, phoneId, phoneName}
   *  FingerBindDeviceActivity.tvBindDevice：typeId="1"、phoneId=设备唯一码、
   *  phoneName=Base64(Build.MODEL)（Y0）。
   */
  static async polyBindApp(domain: string, typeId: string, phoneId: string,
    phoneName: string): Promise<ApiResponse<Object>> {
    const headers: Record<string, string> = await ApiService.polyHeaders();
    const body: Record<string, Object> = {
      'typeId': typeId,
      'phoneId': phoneId,
      'phoneName': CryptoUtil.bytesToBase64(CryptoUtil.stringToBytes(phoneName))
    };
    const response: ApiResponse<Object> =
      await HttpClient.polyPostJson(domain + '/lyuapServer/cam/v1/bindApp', headers, body);
    return new ApiResponse<Object>(response.code, response.message, response.data);
  }

  // ===== [W23 oa-remain] OA 待办链剩余 8 页数据管道（源码级） =====

  /** 源码 TodoModel.e1（P.y）：GET getReturnToAnyNode {docUnid, currentNodeid} → ReturnToAnyNode[]
   *  （TodoProcedureActivity h3 → f 回调 s.setData("回退环节",list)；2026-11-18 实测假 docUnid code=0 []） */
  static async getOaReturnToAnyNodes(docUnid: string, currentNodeid: string): Promise<ApiResponse<OaReturnToAnyNode[]>> {
    const params: Record<string, Object> = { 'docUnid': docUnid, 'currentNodeid': currentNodeid };
    const result: BizJsonResult = await ApiService.bizJson(Api.OA_TODO_RETURN_TO_ANY_NODE, 'GET', params);
    if (result.code === 0) {
      const list: OaReturnToAnyNode[] = [];
      for (const one of ApiService.extractArray(result.data)) {
        list.push(OaReturnToAnyNode.fromRecord(ApiService.asRecord(one)));
      }
      return new ApiResponse<OaReturnToAnyNode[]>(0, result.message, list);
    }
    return new ApiResponse<OaReturnToAnyNode[]>(result.code, result.message, []);
  }

  /** 源码 TodoModel.U0（P.o）：POST addOpinion {remark} → data "1"
   *  （TodoProcedureActivity/TodoFastreplyActivity 添加常用意见弹窗；实测 code=0 "1"） */
  static async addOaOpinion(remark: string): Promise<ApiResponse<Object>> {
    const params: Record<string, Object> = { 'remark': remark };
    const result: BizJsonResult = await ApiService.bizJson(Api.OA_TODO_ADD_OPINION, 'POST', params);
    return new ApiResponse<Object>(result.code, result.message, result.data);
  }

  /** 源码 TodoModel.W0（P.q）：POST circulate {processId, docUnid, userInfos:"GH#BMDM,"拼接去尾}
   *  （CirculateReadActivity 提交；2026-11-18 实测假参 0001 系统异常=端点存活） */
  static async circulateOaTodo(processId: string, docUnid: string, userInfos: string): Promise<ApiResponse<Object>> {
    const params: Record<string, Object> = {
      'processId': processId,
      'docUnid': docUnid,
      'userInfos': userInfos
    };
    const result: BizJsonResult = await ApiService.bizJson(Api.OA_TODO_CIRCULATE, 'POST', params);
    return new ApiResponse<Object>(result.code, result.message, result.data);
  }

  /** 源码 TodoModel.l1（P.H）：POST runProcess {docXml,actionid,processid,docUnid,nextNodeid,nextUserList,remark}
   *  （TodoProcedureActivity C3 → q 回调；实测假参 code=0；响应 RunProcess{msg,orUnid}） */
  static async runOaProcess(params: Record<string, Object>): Promise<ApiResponse<OaRunProcessResult>> {
    const result: BizJsonResult = await ApiService.bizJson(Api.OA_TODO_RUN_PROCESS, 'POST', params);
    if (result.code === 0) {
      const rec: Record<string, Object> = ApiService.asRecord(result.data);
      const run: OaRunProcessResult = new OaRunProcessResult();
      run.msg = ApiService.pick(rec, ['msg']);
      run.orUnid = ApiService.pick(rec, ['orUnid']);
      return new ApiResponse<OaRunProcessResult>(0, result.message, run);
    }
    return new ApiResponse<OaRunProcessResult>(result.code, result.message, new OaRunProcessResult());
  }

  /** 源码 openProcess 请求（TodoModel.i1 → P.E）：POST {processid, docUnid} → TodoOpenProcess
   *  （TodoProcedureActivity B3 → s 回调 J3 渲染） */
  static async openOaProcess(processid: string, docUnid: string): Promise<ApiResponse<OaTodoOpenProcess>> {
    const params: Record<string, Object> = { 'processid': processid, 'docUnid': docUnid };
    const result: BizJsonResult = await ApiService.bizJson(Api.OA_TODO_OPEN_PROCESS, 'POST', params);
    if (result.code === 0) {
      const rec: Record<string, Object> = ApiService.asRecord(result.data);
      const op: OaTodoOpenProcess = new OaTodoOpenProcess();
      op.currentNodeId = ApiService.pick(rec, ['currentNodeId']);
      for (const one of ApiService.extractArray(rec['currentNodeConfig'])) {
        op.currentNodeConfig.push(OaCurrentNodeConfig.fromRecord(ApiService.asRecord(one)));
      }
      for (const one of ApiService.extractArray(rec['nextNodeConfig'])) {
        const node: OaNextNodeConfig = OaNextNodeConfig.fromRecord(ApiService.asRecord(one));
        const usersRaw: Object[] = ApiService.extractArray(ApiService.asRecord(one)['selectUserMapList']);
        for (const u of usersRaw) {
          const urec: Record<string, Object> = ApiService.asRecord(u);
          const nu: OaNextNodeUser = new OaNextNodeUser();
          nu.userId = ApiService.pick(urec, ['userId']);
          nu.userName = ApiService.pick(urec, ['userName']);
          node.selectUserMapList.push(nu);
        }
        op.nextNodeConfig.push(node);
      }
      return new ApiResponse<OaTodoOpenProcess>(0, result.message, op);
    }
    return new ApiResponse<OaTodoOpenProcess>(result.code, result.message, new OaTodoOpenProcess());
  }

  /** 源码 SelectModel.Y0（SelectPImpl.o）：GET getSubDeptList {deptId,processId,userFilterNodeId}
   *  → SubDepartment{title,resultData}（CarbonCopyListActivity g3；实测空参 code=0 title"组织架构(0人)"） */
  static async getOaSubDeptList(deptId: string, processId: string, userFilterNodeId: string):
    Promise<ApiResponse<OaSubDeptResult>> {
    const params: Record<string, Object> = {
      'deptId': deptId,
      'processId': processId,
      'userFilterNodeId': userFilterNodeId
    };
    const result: BizJsonResult = await ApiService.bizJson(Api.OA_SELECT_SUB_DEPT_LIST, 'GET', params);
    if (result.code === 0) {
      return new ApiResponse<OaSubDeptResult>(0, result.message, ApiService.parseOaSubDeptResult(result.data));
    }
    return new ApiResponse<OaSubDeptResult>(result.code, result.message, new OaSubDeptResult());
  }

  /** 源码 SelectModel.a1（SelectPImpl.q）：GET getSubRoleList {deptId} → SubDepartment
   *  （CarbonCopyListActivity i3 页签-按角色；实测 1145 rows） */
  static async getOaSubRoleList(deptId: string): Promise<ApiResponse<OaSubDeptResult>> {
    const params: Record<string, Object> = { 'deptId': deptId };
    const result: BizJsonResult = await ApiService.bizJson(Api.OA_SELECT_SUB_ROLE_LIST, 'GET', params);
    if (result.code === 0) {
      return new ApiResponse<OaSubDeptResult>(0, result.message, ApiService.parseOaSubDeptResult(result.data));
    }
    return new ApiResponse<OaSubDeptResult>(result.code, result.message, new OaSubDeptResult());
  }

  /** 源码 SelectModel.Z0（SelectPImpl.p）：GET getSubUserGroupList {groupId} → SubDepartment
   *  （CarbonCopyListActivity h3 页签-人员分组；实测 0 rows） */
  static async getOaSubUserGroupList(groupId: string): Promise<ApiResponse<OaSubDeptResult>> {
    const params: Record<string, Object> = { 'groupId': groupId };
    const result: BizJsonResult = await ApiService.bizJson(Api.OA_SELECT_SUB_USER_GROUP, 'GET', params);
    if (result.code === 0) {
      return new ApiResponse<OaSubDeptResult>(0, result.message, ApiService.parseOaSubDeptResult(result.data));
    }
    return new ApiResponse<OaSubDeptResult>(result.code, result.message, new OaSubDeptResult());
  }

  /** SubDepartment 响应解析（title + resultData 行） */
  private static parseOaSubDeptResult(data: Object): OaSubDeptResult {
    const rec: Record<string, Object> = ApiService.asRecord(data);
    const out: OaSubDeptResult = new OaSubDeptResult();
    out.title = ApiService.pick(rec, ['title']);
    for (const one of ApiService.extractArray(rec['resultData'])) {
      out.resultData.push(OaSubDeptUser.fromRecord(ApiService.asRecord(one)));
    }
    return out;
  }

  /** 源码 SelectModel.c1（SelectPImpl.t）：GET searchDepartment {keyword}
   *  → Department{title,departmentList:[{BMDM,BMMC,count,isChildren}]}
   *  （TodoSearchDepartmentActivity S2；实测"学院"→多条真实部门） */
  static async searchOaDepartments(keyword: string): Promise<ApiResponse<OaSubDeptResult>> {
    const params: Record<string, Object> = { 'keyword': keyword };
    const result: BizJsonResult = await ApiService.bizJson(Api.OA_SELECT_SEARCH_DEPARTMENT, 'GET', params);
    if (result.code === 0) {
      const rec: Record<string, Object> = ApiService.asRecord(result.data);
      const out: OaSubDeptResult = new OaSubDeptResult();
      out.title = ApiService.pick(rec, ['title']);
      for (const one of ApiService.extractArray(rec['departmentList'])) {
        const drec: Record<string, Object> = ApiService.asRecord(one);
        const u: OaSubDeptUser = new OaSubDeptUser();
        u.BMDM = ApiService.pick(drec, ['BMDM']);
        u.BMMC = ApiService.pick(drec, ['BMMC']);
        u.count = ApiService.pickNumber(drec, ['count']);
        u.TYPE = ApiService.pick(drec, ['isChildren']) === '0' ? '0' : '0';
        out.resultData.push(u);
      }
      return new ApiResponse<OaSubDeptResult>(0, result.message, out);
    }
    return new ApiResponse<OaSubDeptResult>(result.code, result.message, new OaSubDeptResult());
  }

  /** DocNumCategory 响应 content 字段解析：data={content:"[{id,text}]"}（探针实测形态；
   *  空时 content='{"msg":""}' → 返回空列表） */
  private static parseDocNumEntities(data: Object): OaDocNumEntity[] {
    const rec: Record<string, Object> = ApiService.asRecord(data);
    const content: string = ApiService.pick(rec, ['content']);
    if (content === '' || content.indexOf('[') < 0) {
      return [];
    }
    try {
      const parsed: Object = JSON.parse(content) as Object;
      const out: OaDocNumEntity[] = [];
      for (const one of ApiService.extractArray(parsed)) {
        const erec: Record<string, Object> = ApiService.asRecord(one);
        const e: OaDocNumEntity = new OaDocNumEntity();
        e.id = ApiService.pick(erec, ['id']);
        e.text = ApiService.pick(erec, ['text']);
        out.push(e);
      }
      return out;
    } catch (error) {
      const err = error as BusinessError;
      ApiService.logError('parseDocNumEntities fail: ' + err.message);
      return [];
    }
  }

  /** 源码 SelectModel.U0（SelectPImpl.k）：GET getDocNumCategory 无参 → DocNumCategory
   *  （DocNumberActivity b3；2026-11-18 实测 code=0 content 5 类） */
  static async getOaDocNumCategory(): Promise<ApiResponse<OaDocNumEntity[]>> {
    const result: BizJsonResult = await ApiService.bizJson(Api.OA_DOCNUM_CATEGORY, 'GET', {});
    if (result.code === 0) {
      return new ApiResponse<OaDocNumEntity[]>(0, result.message, ApiService.parseDocNumEntities(result.data));
    }
    return new ApiResponse<OaDocNumEntity[]>(result.code, result.message, []);
  }

  /** 源码 SelectModel.W0（SelectPImpl.m）：GET getDocNumWord {categoryId} → DocNumWord
   *  （DocNumberActivity d3 分类联动；实测鲁管院发等） */
  static async getOaDocNumWords(categoryId: string): Promise<ApiResponse<OaDocNumEntity[]>> {
    const params: Record<string, Object> = { 'categoryId': categoryId };
    const result: BizJsonResult = await ApiService.bizJson(Api.OA_DOCNUM_WORD, 'GET', params);
    if (result.code === 0) {
      return new ApiResponse<OaDocNumEntity[]>(0, result.message, ApiService.parseDocNumEntities(result.data));
    }
    return new ApiResponse<OaDocNumEntity[]>(result.code, result.message, []);
  }

  /** 源码 SelectModel.V0（SelectPImpl.l）：GET getDocNumSerialNo {wordId} → DocNumSerialNo
   *  （DocNumberActivity c3 字号联动；实测空 wordId content='{"msg":""}' → 空列表） */
  static async getOaDocNumSerialNos(wordId: string): Promise<ApiResponse<OaDocNumEntity[]>> {
    const params: Record<string, Object> = { 'wordId': wordId };
    const result: BizJsonResult = await ApiService.bizJson(Api.OA_DOCNUM_SERIAL_NO, 'GET', params);
    if (result.code === 0) {
      return new ApiResponse<OaDocNumEntity[]>(0, result.message, ApiService.parseDocNumEntities(result.data));
    }
    return new ApiResponse<OaDocNumEntity[]>(result.code, result.message, []);
  }

  /** 源码 SelectModel.X0（SelectPImpl.n）：GET getYear 无参 → DocNumYear[]{year:number}
   *  （DocNumberActivity e3；实测 2024..2028） */
  static async getOaDocNumYears(): Promise<ApiResponse<number[]>> {
    const result: BizJsonResult = await ApiService.bizJson(Api.OA_DOCNUM_YEAR, 'GET', {});
    if (result.code === 0) {
      const years: number[] = [];
      for (const one of ApiService.extractArray(result.data)) {
        const rec: Record<string, Object> = ApiService.asRecord(one);
        years.push(ApiService.pickNumber(rec, ['year']));
      }
      return new ApiResponse<number[]>(0, result.message, years);
    }
    return new ApiResponse<number[]>(result.code, result.message, []);
  }

  /** 源码 InspectionModel.Y0（InspectionPImpl.f）：GET getCheckRecordsList 无参 → CheckRecord[]
   *  （InspectionRecordActivity N2；2026-11-18 实测测试账号 [] 真实空态） */
  static async getInspectionRecords(): Promise<ApiResponse<OaInspectionRecord[]>> {
    const result: BizJsonResult = await ApiService.bizJson(Api.INSPECTION_RECORDS_LIST, 'GET', {});
    if (result.code === 0) {
      const list: OaInspectionRecord[] = [];
      for (const one of ApiService.extractArray(result.data)) {
        list.push(OaInspectionRecord.fromRecord(ApiService.asRecord(one)));
      }
      return new ApiResponse<OaInspectionRecord[]>(0, result.message, list);
    }
    return new ApiResponse<OaInspectionRecord[]>(result.code, result.message, []);
  }

  /** 源码 InspectionModel.b1（InspectionPImpl.i）：POST getLdmcList {recordXlh} → Ldmc[]
   *  （InspectionActivity p3；实测 [] 真实空态） */
  static async getInspectionLdmcList(recordXlh: string): Promise<ApiResponse<OaLdmc[]>> {
    const params: Record<string, Object> = { 'recordXlh': recordXlh };
    const result: BizJsonResult = await ApiService.bizJson(Api.INSPECTION_LDMC_LIST, 'POST', params);
    if (result.code === 0) {
      const list: OaLdmc[] = [];
      for (const one of ApiService.extractArray(result.data)) {
        list.push(OaLdmc.fromRecord(ApiService.asRecord(one)));
      }
      return new ApiResponse<OaLdmc[]>(0, result.message, list);
    }
    return new ApiResponse<OaLdmc[]>(result.code, result.message, []);
  }

  /** 源码 InspectionModel.c1（InspectionPImpl.j）：POST getRecordsDetail {recordXlh, ldmc} → RecordsDetail
   *  （InspectionActivity q3；实测 {hadScoreSize:0,datalist:[{name:"notCheckList",data:[]}]}） */
  static async getInspectionRecordsDetail(recordXlh: string, ldmc: string): Promise<ApiResponse<OaRecordsDetail>> {
    const params: Record<string, Object> = { 'recordXlh': recordXlh, 'ldmc': ldmc };
    const result: BizJsonResult = await ApiService.bizJson(Api.INSPECTION_RECORDS_DETAIL, 'POST', params);
    if (result.code === 0) {
      const rec: Record<string, Object> = ApiService.asRecord(result.data);
      const out: OaRecordsDetail = new OaRecordsDetail();
      out.hadScoreSize = ApiService.pickNumber(rec, ['hadScoreSize']);
      for (const one of ApiService.extractArray(rec['datalist'])) {
        const grec: Record<string, Object> = ApiService.asRecord(one);
        const group: OaInspectionGroup = new OaInspectionGroup();
        group.name = ApiService.pick(grec, ['name']);
        for (const dorm of ApiService.extractArray(grec['data'])) {
          group.data.push(OaInspectionDorm.fromRecord(ApiService.asRecord(dorm)));
        }
        out.datalist.push(group);
      }
      return new ApiResponse<OaRecordsDetail>(0, result.message, out);
    }
    return new ApiResponse<OaRecordsDetail>(result.code, result.message, new OaRecordsDetail());
  }

  /** 源码 InspectionModel.V0（InspectionPImpl.c）：POST addDormitoryCheckRecords {recordName}
   *  → DormitoryCheckRecords{recordXlh}（InspectionActivity n3 新增记录；实测 code=0） */
  static async addInspectionRecord(recordName: string): Promise<ApiResponse<OaDormitoryRecord>> {
    const params: Record<string, Object> = { 'recordName': recordName };
    const result: BizJsonResult = await ApiService.bizJson(Api.INSPECTION_ADD_RECORDS, 'POST', params);
    if (result.code === 0) {
      const rec: Record<string, Object> = ApiService.asRecord(result.data);
      const out: OaDormitoryRecord = new OaDormitoryRecord();
      out.recordXlh = ApiService.pick(rec, ['recordXlh']);
      return new ApiResponse<OaDormitoryRecord>(0, result.message, out);
    }
    return new ApiResponse<OaDormitoryRecord>(result.code, result.message, new OaDormitoryRecord());
  }

  /** 源码 InspectionModel.d1（InspectionPImpl.k）：POST updateRecordName {recordName, recordXlh}
   *  （InspectionActivity w3 更新标题；实测 code=0） */
  static async updateInspectionRecordName(recordName: string, recordXlh: string): Promise<ApiResponse<Object>> {
    const params: Record<string, Object> = { 'recordName': recordName, 'recordXlh': recordXlh };
    const result: BizJsonResult = await ApiService.bizJson(Api.INSPECTION_UPDATE_RECORD_NAME, 'POST', params);
    return new ApiResponse<Object>(result.code, result.message, result.data);
  }

  /** 源码 InspectionModel.X0（InspectionPImpl.e）：POST deleteDormitoryCheckRecords {recordXlh}
   *  （InspectionActivity o3 删除；实测 code=0） */
  static async deleteInspectionRecord(recordXlh: string): Promise<ApiResponse<Object>> {
    const params: Record<string, Object> = { 'recordXlh': recordXlh };
    const result: BizJsonResult = await ApiService.bizJson(Api.INSPECTION_DELETE_RECORDS, 'POST', params);
    return new ApiResponse<Object>(result.code, result.message, result.data);
  }

  /** 源码 ReimburseModel.U0（ReimburseP.e）：POST reimbursed {PROJECT_NUMBER} → Reimbursed[]
   *  （ExpenseFragment Q1 已报销页签；2026-11-18 实测空 PROJECT_NUMBER code=0001 真实错误态） */
  static async getReimbursedList(projectNumber: string): Promise<ApiResponse<OaReimbursed[]>> {
    const params: Record<string, Object> = { 'PROJECT_NUMBER': projectNumber };
    const result: BizJsonResult = await ApiService.bizJson(Api.PROJECT_REIMBURSED, 'POST', params);
    if (result.code === 0) {
      const list: OaReimbursed[] = [];
      for (const one of ApiService.extractArray(result.data)) {
        list.push(OaReimbursed.fromRecord(ApiService.asRecord(one)));
      }
      return new ApiResponse<OaReimbursed[]>(0, result.message, list);
    }
    return new ApiResponse<OaReimbursed[]>(result.code, result.message, []);
  }

  /** 源码 ReimburseModel.W0（ReimburseP.j）：POST unreimbursed {PROJECT_NUMBER} → Reimbursed[]
   *  （UnExpenseFragment Q1 未报销页签；实测同 0001） */
  static async getUnreimbursedList(projectNumber: string): Promise<ApiResponse<OaReimbursed[]>> {
    const params: Record<string, Object> = { 'PROJECT_NUMBER': projectNumber };
    const result: BizJsonResult = await ApiService.bizJson(Api.PROJECT_UNREIMBURSED, 'POST', params);
    if (result.code === 0) {
      const list: OaReimbursed[] = [];
      for (const one of ApiService.extractArray(result.data)) {
        list.push(OaReimbursed.fromRecord(ApiService.asRecord(one)));
      }
      return new ApiResponse<OaReimbursed[]>(0, result.message, list);
    }
    return new ApiResponse<OaReimbursed[]>(result.code, result.message, []);
  }

  /**
   * [W23 oa-remain] TodoDetailActivity.C3() 等价：edited_todo_form（W14 vms JSON）→ 提交 map +
   * selectfile 文件分组。规则逐分支对齐 C3（管道 B，1567 进处理页）：
   *   fieldReadOnly=="true" 跳过；subject→SUBJECT；picker 五类→fieldName+relevance 另一值；
   *   read 跳过；file→filePaths 分组（keyName selectfile）；其余（select/meetingPicker 等）→直接 put
   *   ——C3 无 meeting 拆","/_show 分支（那是 WorkApplyFormConfigActivity 5348 c3 专属，见管道 A）。
   *   收尾 TodoUtils.a(map)（oa/c/b.java）：逐值 StringEscapeUtils.escapeHtml3（基础实体+ISO-8859-1
   *   命名实体，CJK 不转义）+ null/空 → ""。WF_CopyUserList 在处理页才并入 map，不经转义。
   */
  static buildTodoFormMap(formJson: string): TodoFormExtract {
    const out: TodoFormExtract = new TodoFormExtract();
    try {
      const parsed: Object = JSON.parse(formJson) as Object;
      for (const one of ApiService.extractArray(parsed)) {
        const vmRec: Record<string, Object> = ApiService.asRecord(one);
        const fieldRec: Record<string, Object> = ApiService.asRecord(vmRec['field']);
        const field: OaFormField = OaFormField.fromRecord(fieldRec);
        if (field.fieldReadOnly === 'true') {
          continue;
        }
        const t: string = field.fieldType;
        const name: string = field.fieldName;
        if (name.toLowerCase() === 'subject') {
          out.map['SUBJECT'] = field.fieldValue;
        } else if (t === 'singleUserPicker' || t === 'multiUserPicker' || t === 'singleDeptPicker' ||
          t === 'multiDeptPicker' || t === 'docNumberPicker') {
          out.map[name] = field.fieldValue;
          const rel: string = ApiService.ruleRelevance(field.fieldRule);
          if (rel !== '') {
            out.map[rel] = field.fieldAnotherValue;
          }
        } else if (t.toLowerCase() === 'read') {
          continue;
        } else if (t === 'file') {
          const group: ProcFileGroupPlain = new ProcFileGroupPlain();
          group.fdName = name;
          if (field.fieldValue !== '') {
            for (const p of field.fieldValue.split(',')) {
              if (p !== '') {
                group.filePaths.push(p);
              }
            }
          }
          if (group.filePaths.length > 0) {
            out.fileGroups.push(group);
          }
        } else {
          // 源码 C3 else：select/meetingPicker 等一律直接 put（无 _show/meeting 拆分）
          out.map[name] = field.fieldValue;
        }
      }
      // 源码 C3 收尾：com.lysoft.android.lyyd.oa.c.b.a(map)（TodoUtils.a：escapeHtml3 + 空→""）
      for (const key of Object.keys(out.map)) {
        out.map[key] = ApiService.escapeHtml3(out.map[key]);
      }
    } catch (error) {
      const err = error as BusinessError;
      ApiService.logError('buildTodoFormMap fail: ' + err.message);
    }
    return out;
  }

  /**
   * TodoUtils.b = org.apache.commons.lang3.StringEscapeUtils.escapeHtml3 等价：
   * 基础实体（&amp; &lt; &gt; &quot; &apos;，& 最先）+ ISO-8859-1 命名实体表；CJK 等高位字符原样。
   */
  private static readonly HTML3_BASIC: string[][] = [
    ['&', '&amp;'], ['<', '&lt;'], ['>', '&gt;'], ['"', '&quot;'], ['\'', '&apos;']
  ];
  private static readonly HTML3_ISO: string[][] = [
    ['\u00A0', '&nbsp;'], ['\u00A1', '&iexcl;'], ['\u00A2', '&cent;'], ['\u00A3', '&pound;'],
    ['\u00A4', '&curren;'], ['\u00A5', '&yen;'], ['\u00A6', '&brvbar;'], ['\u00A7', '&sect;'],
    ['\u00A8', '&uml;'], ['\u00A9', '&copy;'], ['\u00AA', '&ordf;'], ['\u00AB', '&laquo;'],
    ['\u00AC', '&not;'], ['\u00AD', '&shy;'], ['\u00AE', '&reg;'], ['\u00AF', '&macr;'],
    ['\u00B0', '&deg;'], ['\u00B1', '&plusmn;'], ['\u00B2', '&sup2;'], ['\u00B3', '&sup3;'],
    ['\u00B4', '&acute;'], ['\u00B5', '&micro;'], ['\u00B6', '&para;'], ['\u00B7', '&middot;'],
    ['\u00B8', '&cedil;'], ['\u00B9', '&sup1;'], ['\u00BA', '&ordm;'], ['\u00BB', '&raquo;'],
    ['\u00BC', '&frac14;'], ['\u00BD', '&frac12;'], ['\u00BE', '&frac34;'], ['\u00BF', '&iquest;'],
    ['\u00C0', '&Agrave;'], ['\u00C1', '&Aacute;'], ['\u00C2', '&Acirc;'], ['\u00C3', '&Atilde;'],
    ['\u00C4', '&Auml;'], ['\u00C5', '&Aring;'], ['\u00C6', '&AElig;'], ['\u00C7', '&Ccedil;'],
    ['\u00C8', '&Egrave;'], ['\u00C9', '&Eacute;'], ['\u00CA', '&Ecirc;'], ['\u00CB', '&Euml;'],
    ['\u00CC', '&Igrave;'], ['\u00CD', '&Iacute;'], ['\u00CE', '&Icirc;'], ['\u00CF', '&Iuml;'],
    ['\u00D0', '&ETH;'], ['\u00D1', '&Ntilde;'], ['\u00D2', '&Ograve;'], ['\u00D3', '&Oacute;'],
    ['\u00D4', '&Ocirc;'], ['\u00D5', '&Otilde;'], ['\u00D6', '&Ouml;'], ['\u00D7', '&times;'],
    ['\u00D8', '&Oslash;'], ['\u00D9', '&Ugrave;'], ['\u00DA', '&Uacute;'], ['\u00DB', '&Ucirc;'],
    ['\u00DC', '&Uuml;'], ['\u00DD', '&Yacute;'], ['\u00DE', '&THORN;'], ['\u00DF', '&szlig;'],
    ['\u00E0', '&agrave;'], ['\u00E1', '&aacute;'], ['\u00E2', '&acirc;'], ['\u00E3', '&atilde;'],
    ['\u00E4', '&auml;'], ['\u00E5', '&aring;'], ['\u00E6', '&aelig;'], ['\u00E7', '&ccedil;'],
    ['\u00E8', '&egrave;'], ['\u00E9', '&eacute;'], ['\u00EA', '&ecirc;'], ['\u00EB', '&euml;'],
    ['\u00EC', '&igrave;'], ['\u00ED', '&iacute;'], ['\u00EE', '&icirc;'], ['\u00EF', '&iuml;'],
    ['\u00F0', '&eth;'], ['\u00F1', '&ntilde;'], ['\u00F2', '&ograve;'], ['\u00F3', '&oacute;'],
    ['\u00F4', '&ocirc;'], ['\u00F5', '&otilde;'], ['\u00F6', '&ouml;'], ['\u00F7', '&divide;'],
    ['\u00F8', '&oslash;'], ['\u00F9', '&ugrave;'], ['\u00FA', '&uacute;'], ['\u00FB', '&ucirc;'],
    ['\u00FC', '&uuml;'], ['\u00FD', '&yacute;'], ['\u00FE', '&thorn;'], ['\u00FF', '&yuml;']
  ];

  static escapeHtml3(value: string): string {
    let out: string = value;
    for (const pair of ApiService.HTML3_BASIC) {
      out = out.split(pair[0]).join(pair[1]);
    }
    for (const pair of ApiService.HTML3_ISO) {
      out = out.split(pair[0]).join(pair[1]);
    }
    return out;
  }

  /** fieldRule JSON 的 relevance 键（TodoDetailActivity.D3/F3 等价） */
  static ruleRelevance(fieldRule: string): string {
    if (fieldRule === '') {
      return '';
    }
    try {
      const rec: Record<string, Object> = JSON.parse(fieldRule) as Record<string, Object>;
      const v: Object = rec['relevance'];
      return typeof v === 'string' ? (v as string) : '';
    } catch (error) {
      const err = error as BusinessError;
      ApiService.logError('ruleRelevance fail: ' + err.message);
      return '';
    }
  }

  // ===== [W27 final-a] 校园风光 / 个人考勤详情 / 考试列表 / 成绩留言 / 学生名单 / 巡检排名 =====

  /**
   * 源码 SchoolModel.W0（school/g/c.java）：bVar.j=false 明文 GET
   * /mobileapi_ydxy/open/campusView/TypeForPic?type=...&userId=...
   * 2026-11-18 探针实测：newest/hottest 各 13 条真实图片（PICID/PIC_URL/LIKE_COUNT/WIDTH/HEIGHT）。
   */
  static async getSchoolSceneryList(type: string): Promise<ApiResponse<SchoolSceneryItem[]>> {
    const params: Record<string, string> = { 'type': type };
    if (LoginSession.userId !== '') {
      params['userId'] = LoginSession.userId;
    }
    const response: ApiResponse<Object> = await HttpClient.plainBizGet(Api.CAMPUS_VIEW_TYPE_FOR_PIC, params);
    if (response.code !== 0) {
      return new ApiResponse<SchoolSceneryItem[]>(response.code, response.message, []);
    }
    const items: SchoolSceneryItem[] = [];
    for (const one of ApiService.extractArray(response.data)) {
      const rec: Record<string, Object> = ApiService.asRecord(one);
      const item: SchoolSceneryItem = new SchoolSceneryItem();
      item.HEIGHT = ApiService.pick(rec, ['HEIGHT']);
      item.WIDTH = ApiService.pick(rec, ['WIDTH']);
      item.PICID = ApiService.pick(rec, ['PICID']);
      item.PIC_URL = ApiService.pick(rec, ['PIC_URL']);
      item.XM = ApiService.pick(rec, ['XM']);
      item.VERIFY = ApiService.pick(rec, ['VERIFY']);
      item.verifyState = ApiService.pick(rec, ['verifyState']);
      item.ISLIKE = ApiService.pickNumber(rec, ['ISLIKE']);
      item.LIKE_COUNT = ApiService.pickNumber(rec, ['LIKE_COUNT']);
      items.push(item);
    }
    return new ApiResponse<SchoolSceneryItem[]>(0, response.message, items);
  }

  /** 源码 SchoolModel.T0：POST addLike {PICID} → data "true"（点赞成功文案依据） */
  static async addCampusLike(picId: string): Promise<ApiResponse<string>> {
    const result: BizJsonResult = await ApiService.bizJson(Api.CAMPUS_ADD_LIKE, 'POST', { 'PICID': picId });
    if (result.code === 0) {
      return new ApiResponse<string>(0, result.message, ApiService.plainOf(result));
    }
    return new ApiResponse<string>(result.code, result.message, '');
  }

  /** 源码 SchoolModel.V0：POST delMyPic {PICID} → DeletePic{flag} */
  static async deleteCampusPic(picId: string): Promise<ApiResponse<SchoolDeletePic>> {
    const result: BizJsonResult = await ApiService.bizJson(Api.CAMPUS_DEL_MY_PIC, 'POST', { 'PICID': picId });
    if (result.code === 0) {
      const rec: Record<string, Object> = ApiService.asRecord(result.data);
      const bean: SchoolDeletePic = new SchoolDeletePic();
      const flag: Object = rec['flag'];
      bean.flag = typeof flag === 'boolean' ? (flag as boolean) : ApiService.pick(rec, ['flag']) === 'true';
      return new ApiResponse<SchoolDeletePic>(0, result.message, bean);
    }
    return new ApiResponse<SchoolDeletePic>(result.code, result.message, new SchoolDeletePic());
  }

  /** 源码 SchoolModel.U0：POST_MULTIPART addMyPIC keyName="imgs"（上传成功 data "1"） */
  static async uploadCampusPhotos(fileUris: string[]): Promise<ApiResponse<string>> {
    const response: ApiResponse<Object> = await HttpClient.bizMultipartPost(Api.CAMPUS_ADD_MY_PIC, {},
      fileUris, 'imgs');
    if (response.code !== 0) {
      return new ApiResponse<string>(response.code, response.message, '');
    }
    const data: Object = response.data;
    const text: string = typeof data === 'string' ? (data as string) : '';
    return new ApiResponse<string>(0, response.message, text);
  }

  /** 源码 AttendanceModel.U0（c/e/a/a/a/b/a）：POST detail {month:"yyyy-MM", id:userId} → AttendanceDetail */
  static async getAttendanceDetail(month: string, id: string): Promise<ApiResponse<AttendanceDetail>> {
    const params: Record<string, Object> = { 'month': month, 'id': id };
    const result: BizJsonResult = await ApiService.bizJson(Api.ATTENDANCE_DETAIL, 'POST', params);
    if (result.code === 0) {
      return new ApiResponse<AttendanceDetail>(0, result.message, ApiService.parseAttendanceDetail(result.data));
    }
    return new ApiResponse<AttendanceDetail>(result.code, result.message, new AttendanceDetail());
  }

  static parseAttendanceDetail(data: Object): AttendanceDetail {
    const rec: Record<string, Object> = ApiService.asRecord(data);
    const bean: AttendanceDetail = new AttendanceDetail();
    bean.attendanceGroup = ApiService.pick(rec, ['attendanceGroup']);
    bean.classes = ApiService.pick(rec, ['classes']);
    bean.date = ApiService.pick(rec, ['date']);
    bean.dayOfAttendance = ApiService.pick(rec, ['dayOfAttendance']);
    bean.days = ApiService.pick(rec, ['days']);
    bean.departmentName = ApiService.pick(rec, ['departmentName']);
    bean.imgUrl = ApiService.pick(rec, ['imgUrl']);
    bean.userName = ApiService.pick(rec, ['userName']);
    for (const one of ApiService.parseChildArray(rec, 'attendanceByDay')) {
      bean.attendanceByDay.push(ApiService.parseAttendanceByDay(one));
    }
    for (const one of ApiService.parseChildArray(rec, 'errorRecord')) {
      const r: Record<string, Object> = ApiService.asRecord(one);
      const err: AttendanceDetailErrorRecord = new AttendanceDetailErrorRecord();
      err.errorDetailName = ApiService.pick(r, ['errorDetailName']);
      err.errorDetailTimes = ApiService.pick(r, ['errorDetailTimes']);
      err.errorDetailType = ApiService.pick(r, ['errorDetailType']);
      bean.errorRecord.push(err);
    }
    return bean;
  }

  /** 源码 ExamModel.Y（examination/b/b.java）：GET beginExamList 无参 → ComingExamEntity[] */
  static async getComingExamList(): Promise<ApiResponse<ComingExamEntity[]>> {
    const result: BizJsonResult = await ApiService.bizJson(Api.EXAM_BEGIN_LIST, 'GET', {});
    if (result.code !== 0) {
      return new ApiResponse<ComingExamEntity[]>(result.code, result.message, []);
    }
    const list: ComingExamEntity[] = [];
    for (const one of ApiService.extractArray(result.data)) {
      const rec: Record<string, Object> = ApiService.asRecord(one);
      const bean: ComingExamEntity = new ComingExamEntity();
      bean.JSSJ = ApiService.pick(rec, ['JSSJ']);
      bean.KMMC = ApiService.pick(rec, ['KMMC']);
      bean.KSDD = ApiService.pick(rec, ['KSDD']);
      bean.KSLX = ApiService.pick(rec, ['KSLX']);
      bean.KSSJ = ApiService.pick(rec, ['KSSJ']);
      bean.LX = ApiService.pick(rec, ['LX']);
      bean.TGRXH = ApiService.pick(rec, ['TGRXH']);
      bean.TXLX = ApiService.pick(rec, ['TXLX']);
      bean.TXSJ = ApiService.pick(rec, ['TXSJ']);
      bean.XN = ApiService.pick(rec, ['XN']);
      bean.XQ = ApiService.pick(rec, ['XQ']);
      bean.ZKZH = ApiService.pick(rec, ['ZKZH']);
      bean.ZWH = ApiService.pick(rec, ['ZWH']);
      list.push(bean);
    }
    return new ApiResponse<ComingExamEntity[]>(0, result.message, list);
  }

  /** 源码 ExamModel.z（examination/b/c.java）：GET endExamList 无参 → FinishExamEntity[] */
  static async getFinishExamList(): Promise<ApiResponse<FinishExamEntity[]>> {
    const result: BizJsonResult = await ApiService.bizJson(Api.EXAM_END_LIST, 'GET', {});
    if (result.code !== 0) {
      return new ApiResponse<FinishExamEntity[]>(result.code, result.message, []);
    }
    const list: FinishExamEntity[] = [];
    for (const one of ApiService.extractArray(result.data)) {
      const rec: Record<string, Object> = ApiService.asRecord(one);
      const bean: FinishExamEntity = new FinishExamEntity();
      bean.JSSJ = ApiService.pick(rec, ['JSSJ']);
      bean.KMMC = ApiService.pick(rec, ['KMMC']);
      bean.KSDD = ApiService.pick(rec, ['KSDD']);
      bean.KSLX = ApiService.pick(rec, ['KSLX']);
      bean.KSSJ = ApiService.pick(rec, ['KSSJ']);
      bean.LX = ApiService.pick(rec, ['LX']);
      bean.XN = ApiService.pick(rec, ['XN']);
      bean.XQ = ApiService.pick(rec, ['XQ']);
      bean.ZWH = ApiService.pick(rec, ['ZWH']);
      list.push(bean);
    }
    return new ApiResponse<FinishExamEntity[]>(0, result.message, list);
  }

  /** 源码 ExamComingPresenter.d → ExamModel.w：POST deleteExam {kslx,kmmc} */
  static async deleteExam(kslx: string, kmmc: string): Promise<ApiResponse<string>> {
    const result: BizJsonResult = await ApiService.bizJson(Api.EXAM_DELETE, 'POST',
      { 'kslx': kslx, 'kmmc': kmmc });
    return new ApiResponse<string>(result.code, result.message, ApiService.plainOf(result));
  }

  /** 源码 AddExamListFragmentModel.p0：GET editExamList {kslx} → AddExamEntity[]（字段同 ComingExamEntity） */
  static async getAddExamList(kslx: string): Promise<ApiResponse<ComingExamEntity[]>> {
    const result: BizJsonResult = await ApiService.bizJson(Api.EXAM_EDIT_LIST, 'GET', { 'kslx': kslx });
    if (result.code !== 0) {
      return new ApiResponse<ComingExamEntity[]>(result.code, result.message, []);
    }
    const list: ComingExamEntity[] = [];
    for (const one of ApiService.extractArray(result.data)) {
      const rec: Record<string, Object> = ApiService.asRecord(one);
      const bean: ComingExamEntity = new ComingExamEntity();
      bean.KMMC = ApiService.pick(rec, ['KMMC']);
      bean.KSSJ = ApiService.pick(rec, ['KSSJ']);
      bean.KSLX = ApiService.pick(rec, ['KSLX']);
      bean.LX = ApiService.pick(rec, ['LX']);
      bean.ZWH = ApiService.pick(rec, ['ZWH']);
      bean.ZKZH = ApiService.pick(rec, ['ZKZH']);
      list.push(bean);
    }
    return new ApiResponse<ComingExamEntity[]>(0, result.message, list);
  }

  /** 源码 ScoreModel.m：GET comments {xn,xq,kcdm,pageNum,pageSize} → CommentInfo[] */
  static async getScoreCommentList(xn: string, xq: string, kcdm: string, pageNum: number,
    pageSize: number): Promise<ApiResponse<ScoreCommentInfo[]>> {
    const params: Record<string, Object> = {
      'xn': xn, 'xq': xq, 'kcdm': kcdm, 'pageNum': String(pageNum), 'pageSize': String(pageSize)
    };
    const result: BizJsonResult = await ApiService.bizJson(Api.SCORE_COMMENTS, 'GET', params);
    if (result.code !== 0) {
      return new ApiResponse<ScoreCommentInfo[]>(result.code, result.message, []);
    }
    const list: ScoreCommentInfo[] = [];
    for (const one of ApiService.extractArray(result.data)) {
      const rec: Record<string, Object> = ApiService.asRecord(one);
      const bean: ScoreCommentInfo = new ScoreCommentInfo();
      bean.AVATAR = ApiService.pick(rec, ['AVATAR']);
      bean.PLNR = ApiService.pick(rec, ['PLNR']);
      bean.PLSJ = ApiService.pick(rec, ['PLSJ']);
      bean.XH = ApiService.pick(rec, ['XH']);
      bean.XLH = ApiService.pick(rec, ['XLH']);
      bean.XM = ApiService.pick(rec, ['XM']);
      list.push(bean);
    }
    return new ApiResponse<ScoreCommentInfo[]>(0, result.message, list);
  }

  /** 源码 ScoreModel.Z：POST deleteComment {xlh} → data "true" */
  static async deleteScoreComment(xlh: string): Promise<ApiResponse<string>> {
    const result: BizJsonResult = await ApiService.bizJson(Api.GRADE_DELETE_COMMENT, 'POST', { 'xlh': xlh });
    return new ApiResponse<string>(result.code, result.message, ApiService.plainOf(result));
  }

  /** 源码 StudentSearchModel.T0：POST getClazz {params} → ClassAndId[]{clazz,code} */
  static async getStudentClassList(params: string): Promise<ApiResponse<ClassAndId[]>> {
    const result: BizJsonResult = await ApiService.bizJson(Api.SCORE_GET_CLAZZ, 'POST', { 'params': params });
    if (result.code !== 0) {
      return new ApiResponse<ClassAndId[]>(result.code, result.message, []);
    }
    const list: ClassAndId[] = [];
    for (const one of ApiService.extractArray(result.data)) {
      const rec: Record<string, Object> = ApiService.asRecord(one);
      const bean: ClassAndId = new ClassAndId();
      bean.clazz = ApiService.pick(rec, ['clazz']);
      bean.code = ApiService.pick(rec, ['code']);
      list.push(bean);
    }
    return new ApiResponse<ClassAndId[]>(0, result.message, list);
  }

  /** 源码 StudentSearchModel.W0：POST getStudents {bjid} → StudentEntity[]{xh,xm} */
  static async getStudentsByClass(bjid: string): Promise<ApiResponse<StudentEntity[]>> {
    const result: BizJsonResult = await ApiService.bizJson(Api.SCORE_GET_STUDENTS, 'POST', { 'bjid': bjid });
    if (result.code !== 0) {
      return new ApiResponse<StudentEntity[]>(result.code, result.message, []);
    }
    const list: StudentEntity[] = [];
    for (const one of ApiService.extractArray(result.data)) {
      const rec: Record<string, Object> = ApiService.asRecord(one);
      const bean: StudentEntity = new StudentEntity();
      bean.xh = ApiService.pick(rec, ['xh']);
      bean.xm = ApiService.pick(rec, ['xm']);
      list.push(bean);
    }
    return new ApiResponse<StudentEntity[]>(0, result.message, list);
  }

  /** 源码 InspectionModel.a1（inspection/b/a.java）：POST getHadScoreList {recordXlh,ldmc} → NewHadScore[] */
  static async getInspectionRankList(recordXlh: string, ldmc: string): Promise<ApiResponse<NewHadScore[]>> {
    const result: BizJsonResult = await ApiService.bizJson(Api.INSPECTION_SCORE_LIST, 'POST',
      { 'recordXlh': recordXlh, 'ldmc': ldmc });
    if (result.code !== 0) {
      return new ApiResponse<NewHadScore[]>(result.code, result.message, []);
    }
    const list: NewHadScore[] = [];
    for (const one of ApiService.extractArray(result.data)) {
      const rec: Record<string, Object> = ApiService.asRecord(one);
      const bean: NewHadScore = new NewHadScore();
      bean.QSH = ApiService.pick(rec, ['QSH']);
      bean.SCORE = ApiService.pick(rec, ['SCORE']);
      bean.XLH = ApiService.pick(rec, ['XLH']);
      bean.RANKNUM = ApiService.pickNumber(rec, ['RANKNUM']);
      list.push(bean);
    }
    return new ApiResponse<NewHadScore[]>(0, result.message, list);
  }
}

/** buildTodoFormMap 输出（C3 bundle data+allSubmitFiles 等价） */
export class TodoFormExtract {
  map: Record<string, string> = {};
  fileGroups: ProcFileGroupPlain[] = [];
}

/** selectfile 附件组（AllSubmitFileBean 等价：fdName + 文件路径） */
export class ProcFileGroupPlain {
  fdName: string = '';
  filePaths: string[] = [];
}

/** [E1 news worker] NewsFragment.K1() WebView 加载头（源码 HashMap map 两个字段） */
export interface NewsWebViewHeaders {
  accessToken: string;
  uniqueCode: string;
}

/** [W4 sms-login] checkLoginPhone 响应实体（源码 IdentifyCodeModel.java 内联 Bean：
 *  public int timeFrequency; public boolean canSendSms;）
 */
export class CheckLoginPhoneResult {
  timeFrequency: number = Api.SMS_TIME_FREQUENCY;
  canSendSms: boolean = false;
}

/** [W22 launch-chain] RemoteHomeTabBean（源码 launch/entity/RemoteHomeTabBean.java 九字段 1:1，
 *  2026-11-18 探针实测字段全大写：NAVIGATION_ID/NAVIGATION_BAR/NAVIGATION_NAME/
 *  DEFAULT_SELECTED/STATUS/SORT/JSID/TITLE/IDENTIFYING）
 */
export class RemoteHomeTabEntry {
  navigationId: string = '';
  navigationBar: string = '';
  navigationName: string = '';
  defaultSelected: string = '';
  status: string = '';
  sort: string = '';
  jsid: string = '';
  title: string = '';
  identifying: string = '';
}

