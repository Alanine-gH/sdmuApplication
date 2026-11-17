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
import { CourseItem } from '../model/CourseModel';
import { TodoItem } from '../model/TodoModel';
import { ContactItem } from '../model/ContactModel';
// T2 contact-worker 追加：通讯录初始化实体（源码 InitData.java）
import { ContactInitData, ContactClassAddressBookBean, ContactCourseTeacherBean,
  ContactRootOrganizationBean, ContactTopContactListBean } from '../model/ContactModel';
import { ScoreItem, ExamItem, ScoreStatEntry, ScoreDetailEntry, ScoreRankEntry, ScoreCommentEntry,
  ScoreDetailData } from '../model/ScoreModel';
import { MeetingItem } from '../model/MeetingModel';
import { AttendanceItem, AttendanceIsBoss, AttendanceIndex, AttendanceErrorRecordBean,
  AttendanceByDayBean, AttendanceBossIndex, AttendanceGroupBean,
  AttendancePeopleListBean } from '../model/AttendanceModel';
import { TodoTabOA, OaTodoRow, OaTodoList, OaChannel } from '../model/OaTodoModel';
import { MainNotificationV2 } from '../model/MessageModel';
import { SuperviseCourseItem, SuperviseRecordItem, SuperviseMineData } from '../model/SuperviseModel';
// [E3 meeting worker] 会议模块实体（源码 meeting/entity/* + gettimetable TermParamsEntity）
import { MeetingTabEntity, JoinListEntity, JoinListItem, WeekPlanEntity, CurrentDayEntity,
  TermParamsEntity as MeetingTermParams } from '../model/MeetingApiModel';
import { BusinessError } from '@kit.BasicServicesKit';

/** bizRequest 解密后统一解析结果：code=0 成功，1000 登录失效，其余透传 */
interface BizJsonResult {
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
 *   - code=0 成功返回解析数据；code=1000 提示"登录已失效"；其余失败返回空数据（页面显示空态）
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

  /** 加密请求统一封装：bizRequest → 解密 JSON 字符串 → JSON.parse；1000 映射为登录已失效 */
  static async bizJson(path: string, method: string, params: Record<string, Object>): Promise<BizJsonResult> {
    const response: ApiResponse<Object> = await HttpClient.bizRequest(path, method, params);
    if (response.code === ApiService.NOT_LOGIN_CODE) {
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

  static parseCourse(data: Object): CourseItem {
    const rec: Record<string, Object> = ApiService.asRecord(data);
    return new CourseItem(
      ApiService.pick(rec, ['id', 'courseId']),
      ApiService.pick(rec, ['name', 'courseName', 'kcmc']),
      ApiService.pick(rec, ['teacher', 'teacherName', 'jsxm']),
      ApiService.pick(rec, ['place', 'classRoom', 'jsmc']),
      ApiService.pick(rec, ['weeks', 'weekRange', 'zcd']),
      ApiService.pickNumber(rec, ['day', 'weekDay', 'xqj']),
      ApiService.pickNumber(rec, ['startNode', 'startSection', 'jc']),
      ApiService.pickNumber(rec, ['endNode', 'endSection']),
      ApiService.pickNumber(rec, ['credit', 'credits', 'xf']),
      ApiService.pick(rec, ['type', 'courseType', 'kcxz'])
    );
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

  static parseSuperviseCourse(data: Object): SuperviseCourseItem {
    const rec: Record<string, Object> = ApiService.asRecord(data);
    return new SuperviseCourseItem(
      ApiService.pick(rec, ['djj', 'section', 'jieci']),
      ApiService.pick(rec, ['kcmc', 'courseName', 'name']),
      ApiService.pick(rec, ['bmmc', 'majorInfo', 'zymc', 'className'])
    );
  }

  static parseSuperviseRecord(data: Object, evaluated: boolean): SuperviseRecordItem {
    const rec: Record<string, Object> = ApiService.asRecord(data);
    const dateText: string = ApiService.pick(rec, ['skrq', 'date', 'listenTime', 'time']);
    const weekText: string = ApiService.pick(rec, ['xqbm', 'week', 'weekLabel']);
    const timeText: string = ApiService.pick(rec, ['skkssj', 'skj', 'section', 'skTime']);
    const scoreNum: number = ApiService.pickNumber(rec, ['dj', 'score', 'star']);
    return new SuperviseRecordItem(
      dateText,
      weekText,
      ApiService.pick(rec, ['kcmc', 'courseName', 'title']),
      ApiService.pick(rec, ['skls', 'teacher', 'jsxm']),
      ApiService.pick(rec, ['skdd', 'location', 'place', 'jsmc']),
      timeText,
      evaluated,
      ApiService.pick(rec, ['ydrs', 'expectNum']),
      ApiService.pick(rec, ['sdrs', 'actualNum']),
      scoreNum,
      ApiService.pick(rec, ['nr', 'comment', 'content'])
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

  // ===== 课表（真实端点 /mobileapi_ydxy/api/schedule/searchSchedule，ScheduleFactory） =====
  static async getScheduleList(): Promise<ApiResponse<CourseItem[]>> {
    // 源码依据：lyyd/timetable/a.源码 + c.源码（ScheduleFactory：a()="api"、b()="schedule"），
    // 2026-11-17 服务器实测 /schedule/searchSchedule 存在于 /mobileapi_ydxy/api/ 命名空间
    const params: Record<string, Object> = {};
    const result: BizJsonResult = await ApiService.bizJson(Api.SCHEDULE_LIST, 'GET', params);
    if (result.code === 0) {
      const items: CourseItem[] = [];
      const raw: Object[] = ApiService.extractArray(result.data);
      for (const one of raw) {
        items.push(ApiService.parseCourse(one));
      }
      return new ApiResponse<CourseItem[]>(0, result.message, items);
    }
    if (result.code === ApiService.NOT_LOGIN_CODE) {
      return new ApiResponse<CourseItem[]>(ApiService.NOT_LOGIN_CODE, result.message, ApiService.mockScheduleList());
    }
    return new ApiResponse<CourseItem[]>(ApiService.OFFLINE_CODE, ApiService.offline(result.message),
      ApiService.mockScheduleList());
  }

  // ===== 督导（真实端点 /mobileapi_ydxy/api/superviseListen/*，SuperviseFactory） =====
  static async getSuperviseList(): Promise<ApiResponse<SuperviseCourseItem[]>> {
    // 源码依据：lyyd/supervise/a.源码 + supervise/c/a.源码 getUserCourseList {bmdm,djj,skls}（2026-11-17 实测）
    const params: Record<string, Object> = {
      'bmdm': '',
      'djj': '',
      'skls': ''
    };
    const result: BizJsonResult = await ApiService.bizJson(Api.SUPERVISE_USER_COURSE, 'POST', params);
    if (result.code === 0) {
      const items: SuperviseCourseItem[] = [];
      const raw: Object[] = ApiService.extractArray(result.data);
      for (const one of raw) {
        items.push(ApiService.parseSuperviseCourse(one));
      }
      return new ApiResponse<SuperviseCourseItem[]>(0, result.message, items);
    }
    if (result.code === ApiService.NOT_LOGIN_CODE) {
      return new ApiResponse<SuperviseCourseItem[]>(ApiService.NOT_LOGIN_CODE, result.message,
        ApiService.mockSuperviseList());
    }
    return new ApiResponse<SuperviseCourseItem[]>(ApiService.OFFLINE_CODE, ApiService.offline(result.message),
      ApiService.mockSuperviseList());
  }

  static async getSuperviseMine(): Promise<ApiResponse<SuperviseMineData>> {
    // 源码依据：supervise/c/a.源码：getStaleListening（已督导）/ getNotListening（未督导），2026-11-17 实测
    const params: Record<string, Object> = {};
    const staleResult: BizJsonResult = await ApiService.bizJson(Api.SUPERVISE_STALE_LISTENING, 'POST', params);
    const notResult: BizJsonResult = await ApiService.bizJson(Api.SUPERVISE_NOT_LISTENING, 'POST', params);
    const staleOk: boolean = staleResult.code === 0;
    const notOk: boolean = notResult.code === 0;
    if (staleOk || notOk) {
      const pastRecords: SuperviseRecordItem[] = [];
      const futureRecords: SuperviseRecordItem[] = [];
      if (staleOk) {
        const raw: Object[] = ApiService.extractArray(staleResult.data);
        for (const one of raw) {
          pastRecords.push(ApiService.parseSuperviseRecord(one, true));
        }
      }
      if (notOk) {
        const raw: Object[] = ApiService.extractArray(notResult.data);
        for (const one of raw) {
          futureRecords.push(ApiService.parseSuperviseRecord(one, false));
        }
      }
      const message: string = staleResult.message !== '' ? staleResult.message : notResult.message;
      return new ApiResponse<SuperviseMineData>(0, message, new SuperviseMineData(pastRecords, futureRecords));
    }
    const failCode: number = staleResult.code === ApiService.NOT_LOGIN_CODE
      || notResult.code === ApiService.NOT_LOGIN_CODE ? ApiService.NOT_LOGIN_CODE : ApiService.OFFLINE_CODE;
    const failMessage: string = staleResult.message !== '' ? staleResult.message : notResult.message;
    if (failCode === ApiService.NOT_LOGIN_CODE) {
      return new ApiResponse<SuperviseMineData>(ApiService.NOT_LOGIN_CODE, '登录已失效', ApiService.mockSuperviseMine());
    }
    return new ApiResponse<SuperviseMineData>(ApiService.OFFLINE_CODE, ApiService.offline(failMessage),
      ApiService.mockSuperviseMine());
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

  static async getScoreComments(): Promise<ApiResponse<ScoreCommentEntry[]>> {
    // 源码依据：课评模块原始实现为 H5 路由/插件 dex（不可恢复），/grade/comments 为命名空间推断
    const params: Record<string, Object> = {};
    const result: BizJsonResult = await ApiService.bizJson(Api.SCORE_COMMENTS, 'POST', params);
    if (result.code === 0) {
      const items: ScoreCommentEntry[] = [];
      const raw: Object[] = ApiService.extractArray(result.data);
      for (const one of raw) {
        items.push(ApiService.parseScoreComment(one));
      }
      return new ApiResponse<ScoreCommentEntry[]>(0, result.message, items);
    }
    if (result.code === ApiService.NOT_LOGIN_CODE) {
      return new ApiResponse<ScoreCommentEntry[]>(ApiService.NOT_LOGIN_CODE, result.message,
        ApiService.mockScoreComments());
    }
    return new ApiResponse<ScoreCommentEntry[]>(ApiService.OFFLINE_CODE, ApiService.offline(result.message),
      ApiService.mockScoreComments());
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

  static mockSuperviseList(): SuperviseCourseItem[] {
    return [];
  }

  static mockSuperviseMine(): SuperviseMineData {
    const pastRecords: SuperviseRecordItem[] = [];
    const futureRecords: SuperviseRecordItem[] = [];
    return new SuperviseMineData(pastRecords, futureRecords);
  }

  static mockScoreDetail(): ScoreDetailData {
    const detailList: ScoreDetailEntry[] = [];
    const rankList: ScoreRankEntry[] = [];
    const commentList: ScoreCommentEntry[] = [];
    return new ScoreDetailData(detailList, rankList, commentList);
  }

  static mockScoreComments(): ScoreCommentEntry[] {
    return [];
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

  // ===== [E1 news worker] 新闻页 WebView 加载公式（NewsFragment.java K1() 源码级还原） =====

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
}

/** [E1 news worker] NewsFragment.K1() WebView 加载头（源码 HashMap map 两个字段） */
export interface NewsWebViewHeaders {
  accessToken: string;
  uniqueCode: string;
}

