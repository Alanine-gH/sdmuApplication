import { HttpClient } from './HttpClient';
import { LoginSession } from './LoginSession';
import { Api } from './Api';
import { CryptoUtil } from './CryptoUtil';
import { ApiResponse } from '../model/ResponseModel';
import { UserInfo } from '../model/UserModel';
import { NewsItem } from '../model/NewsModel';
import { CourseItem } from '../model/CourseModel';
import { TodoItem } from '../model/TodoModel';
import { ContactItem } from '../model/ContactModel';
import { ScoreItem, ExamItem, ScoreStatEntry, ScoreDetailEntry, ScoreRankEntry, ScoreCommentEntry,
  ScoreDetailData } from '../model/ScoreModel';
import { MeetingItem } from '../model/MeetingModel';
import { AttendanceItem } from '../model/AttendanceModel';
import { SuperviseCourseItem, SuperviseRecordItem, SuperviseMineData } from '../model/SuperviseModel';
import { BusinessError } from '@kit.BasicServicesKit';

/** bizRequest 解密后统一解析结果：code=0 成功，1000 登录失效，其余透传 */
interface BizJsonResult {
  code: number;
  message: string;
  data: Object;
}

/**
 * API 服务层 — 真实加密服务器通道（2026-11-17 服务器全链路实测）。
 * 全部业务方法走 HttpClient.bizRequest(path, method, params)：
 *   - 自动加密 Access-Token/Unique-Code 头，POST body/GET data 自动加密
 *   - 响应 data 自动解密为 JSON 字符串，此处 JSON.parse 后映射到现有模型
 *   - code=0 成功返回解析数据；code=1000 提示"登录已失效"；其余失败保留离线降级 mock 兜底
 * 源码依据标注在每个方法注释（安卓反编译 Model/Factory 类路径）。
 */
export class ApiService {
  private static readonly OFFLINE_CODE: number = -1;
  private static readonly NOT_LOGIN_CODE: number = 1000;

  // ===== 通用工具 =====
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

  // ===== 实体解析（按安卓 Gson 模型字段映射） =====
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

  static async getUserInfo(userId: string): Promise<ApiResponse<UserInfo>> {
    // 源码依据：module/b/g/g.smali:279 登录同族用户接口（/user/info，服务器命名空间实测存在）
    const params: Record<string, Object> = { 'yyid': userId };
    const result: BizJsonResult = await ApiService.bizJson(Api.USER_INFO, 'POST', params);
    if (result.code === 0) {
      const user: UserInfo = ApiService.parseUser(result.data);
      if (user.name !== '') {
        return new ApiResponse<UserInfo>(0, result.message, user);
      }
    }
    if (result.code === ApiService.NOT_LOGIN_CODE) {
      return new ApiResponse<UserInfo>(ApiService.NOT_LOGIN_CODE, result.message, ApiService.mockUser('20230001'));
    }
    return new ApiResponse<UserInfo>(ApiService.OFFLINE_CODE, ApiService.offline(result.message),
      ApiService.mockUser('20230001'));
  }

  // ===== 新闻（H5明文接口 /thirdpart_ydxy/boda/news/list，2026-11-16 抓包验证返回真实数据） =====
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
    // 源码依据：module/main/g/g.smali 信息详情（原 /ly-pd-mb/information/... 推断，迁移至 /mobileapi_ydxy/api/）
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
    // 源码依据：module/main/g/g.smali UnifyTodoBean（待办列表 {keyWord,page,pageSize,sourceCode,todoType}）
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
    // 源码依据：module/main/g/g.smali（待办Tab计数 {sourceCode}，2026-11-17 服务器实测）
    const params: Record<string, Object> = { 'sourceCode': sourceCode };
    const result: BizJsonResult = await ApiService.bizJson(Api.TODO_TAB_COUNT, 'POST', params);
    if (result.code === 0) {
      return new ApiResponse<Object>(0, result.message, result.data);
    }
    return new ApiResponse<Object>(result.code, result.message, result.data);
  }

  static async setTodoRead(todoId: string): Promise<ApiResponse<Object>> {
    // 源码依据：module/main/g/g.smali（待办已读，路径推断 /todo/client/setTodoRead）
    const params: Record<string, Object> = { 'todoId': todoId, 'isUnreadDoc': 1 };
    const result: BizJsonResult = await ApiService.bizJson(Api.TODO_SET_READ, 'POST', params);
    return new ApiResponse<Object>(result.code, result.message, result.data);
  }

  // ===== 通讯录（推断端点 + 离线降级） =====
  static async getContactList(): Promise<ApiResponse<ContactItem[]>> {
    // 源码依据：通讯录 /contact/list（服务器命名空间实测存在，具体字段按安卓通讯录 Model 推断）
    const params: Record<string, Object> = {};
    const result: BizJsonResult = await ApiService.bizJson(Api.CONTACT_LIST, 'POST', params);
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

  // ===== 会议（推断端点 + 离线降级） =====
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
    // 源码依据：lyyd/timetable/a.smali + c.smali（ScheduleFactory：a()="api"、b()="schedule"），
    // 2026-11-17 服务器实测 /schedule/searchSchedule 存在于 /mobileapi_ydxy/api/ 命名空间
    const params: Record<string, Object> = {};
    const result: BizJsonResult = await ApiService.bizJson(Api.SCHEDULE_LIST, 'POST', params);
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
    // 源码依据：lyyd/supervise/a.smali + supervise/c/a.smali getUserCourseList {bmdm,djj,skls}（2026-11-17 实测）
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
    // 源码依据：supervise/c/a.smali：getStaleListening（已督导）/ getNotListening（未督导），2026-11-17 实测
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

  // ===== 成绩详情 / 课评（推断端点 + 离线降级） =====
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
    const result: BizJsonResult = await ApiService.bizJson(Api.GRADE_LIST, 'POST', params);
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

  // ===== 离线降级模拟数据 =====
  static mockUser(account: string): UserInfo {
    return new UserInfo('U20230001', '张明理', '20230001', '计算机2301班', '信息工程学院',
      '计算机科学与技术', '2023级', '13800001234', 'zhangml@sdmu.edu.cn', '',
      'mock-token-' + account);
  }

  static mockNewsList(): NewsItem[] {
    const list: NewsItem[] = [
      new NewsItem('N1', '学校召开2026年秋季学期教学工作部署会',
        '11月10日上午，学校在明德楼会议室召开2026年秋季学期教学工作部署会，校领导及各学院负责人参加会议。',
        '11月10日上午，学校在明德楼会议室召开2026年秋季学期教学工作部署会。会议全面总结了上一阶段教学工作取得的成果，深入分析了当前教学中存在的问题，并对下一阶段重点任务作出部署。校党委书记强调，要坚持以人才培养为中心，深化教学改革，提升课堂教学质量。各学院要结合自身实际，制定具体实施方案，确保各项任务落地见效。教务处负责人通报了期中教学检查情况，并就课程建设、专业认证、实践教学等工作提出具体要求。',
        '教务处', '2026-11-10 14:30', '', '', '通知公告'),
      new NewsItem('N2', '我校学子在全国大学生数学建模竞赛中获佳绩',
        '近日，2026年全国大学生数学建模竞赛成绩揭晓，我校代表队获得全国一等奖1项、二等奖2项的优异成绩。',
        '近日，2026年全国大学生数学建模竞赛成绩揭晓，我校代表队获得全国一等奖1项、二等奖2项的优异成绩。本次竞赛吸引了全国1600余所高校参赛。我校高度重视学科竞赛工作，自4月份启动培训以来，指导教师团队利用周末和暑期开展系统训练。参赛同学刻苦钻研、团结协作，充分展现了我校学生扎实的专业基础和良好的创新实践能力。',
        '学生工作处', '2026-11-08 09:00', '', '', '校园动态'),
      new NewsItem('N3', '图书馆关于延长开放时间的通知',
        '为满足广大师生期末复习备考需求，图书馆自11月15日起延长自习区开放时间至每晚23:00。',
        '为满足广大师生期末复习备考需求，图书馆经研究决定，自11月15日起至本学期末，图书馆自习区开放时间延长至每晚23:00，其中一层自习室实行24小时开放。请同学们自觉遵守图书馆各项管理规定，保持安静，爱护公物，共同维护良好的学习环境。如有疑问请联系图书馆办公室，电话0531-88951234。',
        '图书馆', '2026-11-06 16:20', '', '', '通知公告'),
      new NewsItem('N4', '我校举办第十八届校园文化艺术节',
        '11月5日晚，学校第十八届校园文化艺术节开幕式在大学生活动中心隆重举行，全校师生代表千余人参加。',
        '11月5日晚，学校第十八届校园文化艺术节开幕式在大学生活动中心隆重举行。本届艺术节以"青春绽放，梦想启航"为主题，为期一个月，将陆续举办合唱比赛、舞蹈大赛、书画展、话剧专场等十余项活动。开幕式上，各学院带来了精彩纷呈的文艺表演，现场气氛热烈。校园文化艺术节是我校校园文化建设的品牌活动，已连续举办十八届，深受广大师生喜爱。',
        '校团委', '2026-11-05 21:10', '', '', '校园动态'),
      new NewsItem('N5', '关于2026年下半年全国大学英语四六级考试报名的通知',
        '2026年下半年全国大学英语四、六级考试将于12月19日举行，请符合条件的同学于11月20日前完成报名。',
        '2026年下半年全国大学英语四、六级考试（笔试）将于12月19日举行。报名工作采取网上报名方式，请符合条件的同学在11月20日前登录全国大学英语四六级考试报名网站完成报名和缴费。逾期不予补报。请报名同学合理安排复习时间，按时参加考试。考试具体安排请关注教务处后续通知。',
        '教务处', '2026-11-04 10:00', '', '', '考试安排'),
      new NewsItem('N6', '我校与多家企业签署产学研合作协议',
        '11月3日，学校举行产学研合作签约仪式，与12家企业签署合作协议，进一步深化校企合作。',
        '11月3日，学校产学研合作签约仪式在行政楼会议室举行。校长代表学校与12家企业代表签署合作协议，内容涵盖共建实习实训基地、联合培养应用型人才、协同开展技术攻关等多个方面。校长指出，深化产教融合、校企合作是应用型本科高校建设的必由之路。学校将以此次签约为契机，进一步创新合作机制，提升服务地方经济社会发展的能力。',
        '合作发展处', '2026-11-03 18:45', '', '', '校园动态')
    ];
    return list;
  }

  static mockNewsDetail(id: string): NewsItem {
    const list: NewsItem[] = ApiService.mockNewsList();
    let detail: NewsItem = new NewsItem(id, '新闻详情', '', '暂无详细内容', '', '', '', '', '');
    for (const item of list) {
      if (item.id === id) {
        detail = item;
      }
    }
    return detail;
  }

  static mockTodoList(): TodoItem[] {
    const list: TodoItem[] = [
      new TodoItem('T1', '关于填报2026年度教师工作量统计表的通知', '0', '待办', '2026-11-20 17:00', '高', '教务处',
        '各位老师请于11月20日17:00前登录OA系统完成本年度工作量填报，逾期系统将关闭。'),
      new TodoItem('T2', '2026年秋季学期期中教学检查意见反馈', '0', '待办', '2026-11-25 12:00', '中', '质量监控中心',
        '请各学院教学秘书汇总期中教学检查情况，形成书面报告后在线提交。'),
      new TodoItem('T3', '实验室安全知识在线学习任务', '0', '待办', '2026-11-30 23:59', '中', '实验室管理处',
        '全体师生须在规定时间内完成实验室安全知识在线课程学习并通过测试。'),
      new TodoItem('T4', '教职工体检通知确认', '1', '已办', '2026-11-05 18:00', '低', '校工会',
        '请确认体检时间安排，如需调整请在规定时间内联系校工会。'),
      new TodoItem('T5', '科研项目申报材料提交', '0', '待办', '2026-12-01 17:30', '高', '科研处',
        '2027年度校级科研项目申报截止时间为12月1日，请申报教师按时提交材料。'),
      new TodoItem('T6', '第十二周教学例会通知', '1', '已办', '2026-11-11 14:30', '中', '教务处',
        '请全体教学管理人员准时参加第十二周教学例会。')
    ];
    return list;
  }

  static mockContactList(): ContactItem[] {
    const list: ContactItem[] = [
      new ContactItem('CT1', '张明理', '信息工程学院', '0531-88951001', 'zhangml@sdmu.edu.cn', '院长', ''),
      new ContactItem('CT2', '王立华', '信息工程学院', '0531-88951002', 'wanglh@sdmu.edu.cn', '副院长', ''),
      new ContactItem('CT3', '赵建国', '信息工程学院', '0531-88951003', 'zhaojg@sdmu.edu.cn', '系主任', ''),
      new ContactItem('CT4', '李芳', '外国语学院', '0531-88952001', 'lifang@sdmu.edu.cn', '教学秘书', ''),
      new ContactItem('CT5', '陈晓燕', '外国语学院', '0531-88952002', 'chenxy@sdmu.edu.cn', '讲师', ''),
      new ContactItem('CT6', '刘志强', '会计学院', '0531-88953001', 'liuzq@sdmu.edu.cn', '党委副书记', ''),
      new ContactItem('CT7', '周文静', '会计学院', '0531-88953002', 'zhouwj@sdmu.edu.cn', '辅导员', ''),
      new ContactItem('CT8', '孙伟', '教务处', '0531-88954001', 'sunwei@sdmu.edu.cn', '处长', ''),
      new ContactItem('CT9', '吴秀兰', '教务处', '0531-88954002', 'wuxl@sdmu.edu.cn', '科员', ''),
      new ContactItem('CT10', '郑海涛', '学生工作处', '0531-88955001', 'zhenght@sdmu.edu.cn', '副处长', '')
    ];
    return list;
  }

  static mockMeetingList(): MeetingItem[] {
    const list: MeetingItem[] = [
      new MeetingItem('M1', '2026年秋季学期期末教学工作部署会', '2026-11-18 14:30', '行政楼三楼会议室', '0',
        '教务处', '部署期末考试安排、成绩录入及下学期教学准备工作。请各学院教学负责人准时参加并做好会议记录。'),
      new MeetingItem('M2', '信息工程学院学科建设研讨会', '2026-11-16 10:00', '明德楼501会议室', '1',
        '信息工程学院', '研讨计算机科学与技术专业一流课程建设方案，审定2027版人才培养方案修订稿。'),
      new MeetingItem('M3', '校园安全工作联席会议', '2026-11-14 15:00', '行政楼一楼报告厅', '2',
        '保卫处', '通报近期校园安全检查情况，部署冬季消防安全专项工作。'),
      new MeetingItem('M4', '学生工作例会', '2026-11-20 16:00', '大学生活动中心202', '0',
        '学生工作处', '布置期中学生座谈、心理健康普查及资助育人等工作。'),
      new MeetingItem('M5', '图书馆管理委员会年度会议', '2026-11-08 09:30', '图书馆会议室', '2',
        '图书馆', '总结年度工作，审议文献资源采购计划及延长开放时间方案。')
    ];
    return list;
  }

  static mockMeetingDetail(id: string): MeetingItem {
    const list: MeetingItem[] = ApiService.mockMeetingList();
    let detail: MeetingItem = new MeetingItem(id, '会议详情', '', '', '2', '', '暂无详细内容');
    for (const item of list) {
      if (item.id === id) {
        detail = item;
      }
    }
    return detail;
  }

  static mockScheduleList(): CourseItem[] {
    const list: CourseItem[] = [
      new CourseItem('C1', '高等数学(下)', '王立华', '明德楼201', '1-16周', 1, 1, 2, 4.0, '必修'),
      new CourseItem('C2', '大学英语(三)', '李芳', '博文楼105', '1-16周', 2, 1, 2, 3.0, '必修'),
      new CourseItem('C3', '数据结构', '赵建国', '实训楼302', '1-16周', 3, 3, 4, 4.0, '必修'),
      new CourseItem('C4', '计算机网络', '陈晓燕', '明德楼315', '1-16周', 1, 3, 4, 3.5, '必修'),
      new CourseItem('C5', '操作系统', '刘志强', '博文楼210', '1-16周', 2, 5, 6, 3.5, '必修'),
      new CourseItem('C6', '体育(三)', '孙伟', '体育馆', '1-16周', 4, 3, 4, 1.0, '必修'),
      new CourseItem('C7', '马克思主义基本原理', '周文静', '明德楼101', '1-16周', 5, 1, 2, 3.0, '必修'),
      new CourseItem('C8', 'Java程序设计', '赵建国', '实训楼305', '1-16周', 4, 6, 7, 3.0, '选修'),
      new CourseItem('C9', '数据库原理', '陈晓燕', '明德楼408', '1-16周', 3, 8, 9, 3.5, '必修')
    ];
    return list;
  }

  static mockScoreList(): ScoreItem[] {
    const list: ScoreItem[] = [
      new ScoreItem('S1', '高等数学(上)', 92, 4.0, 3.9, '2025-2026-1', '必修'),
      new ScoreItem('S2', '大学英语(二)', 85, 3.0, 3.5, '2025-2026-1', '必修'),
      new ScoreItem('S3', 'C语言程序设计', 95, 4.0, 4.0, '2025-2026-1', '必修'),
      new ScoreItem('S4', '大学物理', 78, 3.0, 2.8, '2025-2026-1', '必修'),
      new ScoreItem('S5', '高等数学(下)', 88, 4.0, 3.7, '2025-2026-2', '必修'),
      new ScoreItem('S6', '数据结构', 91, 4.0, 3.9, '2025-2026-2', '必修'),
      new ScoreItem('S7', '大学英语(三)', 82, 3.0, 3.2, '2025-2026-2', '必修'),
      new ScoreItem('S8', 'Web前端开发', 56, 3.0, 0.0, '2025-2026-2', '选修'),
      new ScoreItem('S9', '线性代数', 90, 3.0, 3.8, '2026-2027-1', '必修'),
      new ScoreItem('S10', '计算机网络', 87, 3.5, 3.5, '2026-2027-1', '必修')
    ];
    return list;
  }

  static mockExamList(): ExamItem[] {
    const list: ExamItem[] = [
      new ExamItem('E1', '高等数学(下)', '2026-12-20 09:00-11:00', '明德楼201考场', '闭卷笔试'),
      new ExamItem('E2', '数据结构', '2026-12-21 14:00-16:00', '实训楼302考场', '闭卷笔试'),
      new ExamItem('E3', '大学英语(三)', '2026-12-22 09:00-11:00', '博文楼105考场', '闭卷笔试'),
      new ExamItem('E4', '计算机网络', '2026-12-23 14:00-16:00', '明德楼315考场', '闭卷笔试'),
      new ExamItem('E5', '操作系统', '2026-12-24 09:00-11:00', '博文楼210考场', '闭卷笔试'),
      new ExamItem('E6', '数据库原理', '2026-12-25 14:00-16:00', '明德楼408考场', '闭卷笔试')
    ];
    return list;
  }

  static mockAttendanceList(): AttendanceItem[] {
    const list: AttendanceItem[] = [
      new AttendanceItem('A1', '数据结构', '正常', '2026-11-14 08:00', '课堂考勤', '实训楼302'),
      new AttendanceItem('A2', '高等数学(下)', '正常', '2026-11-13 08:00', '课堂考勤', '明德楼201'),
      new AttendanceItem('A3', '大学英语(三)', '迟到', '2026-11-12 10:10', '课堂考勤', '博文楼105'),
      new AttendanceItem('A4', '计算机网络', '正常', '2026-11-11 14:00', '课堂考勤', '明德楼315'),
      new AttendanceItem('A5', '操作系统', '缺勤', '2026-11-10 14:00', '课堂考勤', '博文楼210'),
      new AttendanceItem('A6', '体育(三)', '正常', '2026-11-10 10:00', '课堂考勤', '体育馆'),
      new AttendanceItem('A7', '数据库原理', '正常', '2026-11-07 16:00', '课堂考勤', '明德楼408'),
      new AttendanceItem('A8', 'Java程序设计', '迟到', '2026-11-06 19:00', '晚自习考勤', '实训楼305')
    ];
    return list;
  }

  static mockSuperviseList(): SuperviseCourseItem[] {
    const list: SuperviseCourseItem[] = [
      new SuperviseCourseItem('1-2节', '高等数学（下）', '数学与统计学院 · 2024级数学与应用数学'),
      new SuperviseCourseItem('3-4节', '大学英语（四）', '外国语学院 · 2023级英语专业'),
      new SuperviseCourseItem('6-7节', '数据结构', '计算机学院 · 2024级软件工程'),
      new SuperviseCourseItem('8-9节', '毛泽东思想和中国特色社会主义理论体系概论', '马克思主义学院 · 2023级思想政治教育'),
      new SuperviseCourseItem('10-11节', '大学物理（下）', '物理与电子工程学院 · 2024级应用物理学')
    ];
    return list;
  }

  static mockSuperviseMine(): SuperviseMineData {
    const pastRecords: SuperviseRecordItem[] = [
      new SuperviseRecordItem('11-09', '周一', '高等数学（下）', '张建国', '明理楼B302', '08:30-10:00', true, '56', '54', 4,
        '教学目标明确，重点突出；板书规范，推导过程完整。课堂互动稍显不足，建议增加随堂提问环节。'),
      new SuperviseRecordItem('11-05', '周四', '数据结构', '李慧敏', '计算机楼A215', '14:00-15:40', true, '48', '47', 5,
        '案例驱动教学，思路清晰，代码演示到位，学生参与度高，整体效果优秀。'),
      new SuperviseRecordItem('11-02', '周一', '大学英语（四）', '王雪梅', '外语楼208', '10:00-11:40', true, '50', '46', 3,
        '语音语调标准，课堂氛围活跃；部分学生注意力不集中，建议加强课堂管理。')
    ];
    const futureRecords: SuperviseRecordItem[] = [
      new SuperviseRecordItem('11-16', '周一', '大学物理（下）', '赵国强', '实验楼C105', '16:00-17:40',
        false, '', '', 0, ''),
      new SuperviseRecordItem('11-18', '周三', '线性代数', '陈立群', '明理楼B410', '08:00-09:40', false, '', '', 0, ''),
      new SuperviseRecordItem('11-20', '周五', '教育学原理', '孙美玲', '文科楼302', '14:00-15:40', false, '', '', 0, '')
    ];
    return new SuperviseMineData(pastRecords, futureRecords);
  }

  static mockScoreDetail(): ScoreDetailData {
    const detailList: ScoreDetailEntry[] = [
      new ScoreDetailEntry('高等数学（下）', '92', '76.5', '98', '3.2%', '第5名', [
        new ScoreStatEntry('学分', '5.0'),
        new ScoreStatEntry('绩点', '4.0'),
        new ScoreStatEntry('平时成绩', '90'),
        new ScoreStatEntry('期末成绩', '93')
      ]),
      new ScoreDetailEntry('大学英语（四）', '85', '79.8', '96', '1.5%', '第12名', [
        new ScoreStatEntry('学分', '3.0'),
        new ScoreStatEntry('绩点', '3.5'),
        new ScoreStatEntry('平时成绩', '88'),
        new ScoreStatEntry('期末成绩', '83')
      ])
    ];
    const rankList: ScoreRankEntry[] = [
      new ScoreRankEntry('1', '李思远', false, '绩点 4.0 / 98分', '32'),
      new ScoreRankEntry('2', '匿名同学', true, '绩点 3.9 / 96分', '18'),
      new ScoreRankEntry('5', '我', false, '绩点 4.0 / 92分', '6'),
      new ScoreRankEntry('8', '王晓明', false, '绩点 3.7 / 90分', '4')
    ];
    const commentList: ScoreCommentEntry[] = ApiService.mockScoreComments();
    return new ScoreDetailData(detailList, rankList, commentList);
  }

  static mockScoreComments(): ScoreCommentEntry[] {
    const list: ScoreCommentEntry[] = [
      new ScoreCommentEntry('张', '张同学', '2026-06-28',
        '老师讲课很细致，例题覆盖全面，考前把错题过了一遍基本就稳了。'),
      new ScoreCommentEntry('匿', '匿名同学', '2026-06-30',
        '平时作业量适中，期末难度比往年低一些，认真复习拿高分不难。'),
      new ScoreCommentEntry('刘', '刘同学', '2026-07-02',
        '签到要求比较严，别缺勤；作业按时交，占总评不少。'),
      new ScoreCommentEntry('陈', '陈同学', '2026-07-05',
        '课程内容偏理论，建议课前预习一遍课件，上课会轻松很多。')
    ];
    return list;
  }
}
