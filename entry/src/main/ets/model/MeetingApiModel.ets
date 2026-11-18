/**
 * [E3 meeting worker] 会议模块实体 — 源码 1:1 逐字段翻译
 * （com.lysoft.android.lyyd.meeting.entity.* + gettimetable TermParamsEntity）
 *
 * MeetingPage.ets（MeetingActivity→MeetingMainActivity→两 Fragment）数据层模型。
 * 字段名保持 Gson 反序列化原名（大写缩写字段原样），不重命名。
 */

/** 源码 MeetingTab.java：getMeetTab 响应 {myMeeting, weekplan}，"on"=显示对应页签 */
export class MeetingTabEntity {
  myMeeting: string = '';
  weekplan: string = '';

  static fromRecord(rec: Record<string, Object>): MeetingTabEntity {
    const tab: MeetingTabEntity = new MeetingTabEntity();
    tab.myMeeting = ApiServicePick(rec, ['myMeeting']);
    tab.weekplan = ApiServicePick(rec, ['weekplan']);
    return tab;
  }
}

/** 源码 JoinList.java：getJoinList 响应元素 {NAME, TYPE, DATA[]}（TYPE="past" 为已结束分组） */
export class JoinListEntity {
  NAME: string = '';
  TYPE: string = '';
  DATA: JoinListItem[] = [];
}

/** 源码 JoinList.DATABean.java：16 字段 1:1（IS_JOIN/RN/IS_URGENCY 为 int） */
export class JoinListItem {
  ADDRESS: string = '';
  IS_CURRENT_USER_PLAN: string = '';
  IS_EXIST_MEETING_REPORT: string = '';
  IS_JOIN: number = 0;
  IS_MUST_JOIN: string = '';
  IS_URGENCY: number = 0;
  JSSJ: string = '';
  KSSJ: string = '';
  MEETING_TYPE: string = '';
  QXLY: string = '';
  RN: number = 0;
  STATUS: string = '';
  TASK_TYPE: string = '';
  TITLE: string = '';
  WEEK: string = '';
  XLH: string = '';
}

/** 源码 WeekPlan.java：getWeekPlan 响应元素 12 字段 1:1（BZ/FJID 源码为 Object，按字符串取值） */
export class WeekPlanEntity {
  BZ: string = '';
  CYRY: string = '';
  DD: string = '';
  FJID: string = '';
  JSSJ: string = '';
  KSSJ: string = '';
  LXDH: string = '';
  WEEK: string = '';
  XLH: string = '';
  ZBDW: string = '';
  ZCR: string = '';
  ZT: string = '';
}

/** 源码 CurrentDay.java：getCurrentOrWeek 响应 {date, week:int, xqj:int} */
export class CurrentDayEntity {
  date: string = '';
  week: number = 0;
  xqj: number = 0;
}

/** 源码 TermParamsEntity.java（gettimetable 模块）：termInfoForTeacher 响应，周程视图学期参数 */
export class TermParamsEntity {
  dqxq: string = '';
  jsrq: string = '';
  ksrq: string = '';
  scheduleEnableAddClass: string = '';
  scheduleMaxClassNum: string = '';
  xlh: string = '';
  xn: string = '';
  xq: string = '';
  zksxq: string = '';
}

/** 源码 CalendarItem.java：周视图日期格（calendar→dateText/dayNum，isToday 标记服务器当日） */
export class CalendarItemEntity {
  dateText: string = '';
  dayNum: string = '';
  isToday: boolean = false;
  hasData: boolean = false;
}

// ===== [W13 meeting-series] 详情/公告/签到链实体（meeting/entity/* 源码 1:1）=====

/** 源码 MeetingObj.ATTACHMENTLISTBean：会议附件 {DOWNLOAD_URL, FILENAME} */
export class MeetingAttachmentEntity {
  DOWNLOAD_URL: string = '';
  FILENAME: string = '';
}

/** 源码 MeetingObj.EXTRABean.DATABean：参会/不参会人员明细 10 字段 */
export class MeetingExtraDataEntity {
  BCJYY: string = '';
  EMAIL: string = '';
  EMAIL_SEND: string = '';
  MEETING_ID: string = '';
  MESSAGE_SEND: string = '';
  NAME: string = '';
  PHONE: string = '';
  XLH: string = '';
  YHID: string = '';
  YHNAME: string = '';
}

/** 源码 MeetingObj.EXTRABean：{LENGTH:int, TYPE, DATA[]}（TYPE=JOIN_LIST/NO_JOIN_LIST） */
export class MeetingExtraEntity {
  DATA: MeetingExtraDataEntity[] = [];
  LENGTH: number = 0;
  TYPE: string = '';
}

/** 源码 MeetingObj.java：getMeetingObj 响应 26 字段 Gson 1:1（CHRS/IS_JOIN/IS_SIGN 为 int） */
export class MeetingObjEntity {
  ADDRESS: string = '';
  ATTACHMENT_LIST: MeetingAttachmentEntity[] = [];
  CHLD: string = '';
  CHRS: number = 0;
  CHRY: string = '';
  EXTRA: MeetingExtraEntity[] = [];
  FNBRY: string = '';
  GUUID: string = '';
  HYID: string = '';
  IS_CURRENT_USER_PLAN: string = '';
  IS_JOIN: number = 0;
  IS_SHOW: string = '';
  IS_SIGN: number = 0;
  JBDW: string = '';
  JSSJ: string = '';
  KSSJ: string = '';
  LXR: string = '';
  LXRDH: string = '';
  QXLY: string = '';
  STATUS: string = '';
  TITLE: string = '';
  WEEK: string = '';
  XLH: string = '';
  XWRY: string = '';
  ZCR: string = '';
  feedBackType: string = '';
  meetingReportType: string = '';
}

/** 源码 MeetingAnnouncement.java：findMeetingFeedBack 响应元素 6 字段 */
export class MeetingAnnouncementEntity {
  CREATE_TIME: string = '';
  ID: string = '';
  MEETING_ID: string = '';
  MESSAGE: string = '';
  USER_ID: string = '';
  USER_NAME: string = '';
}

/** 源码 SignUser.java：getSignUser/getNoSignUser 响应元素（BCJYY 源码为 Object，按字符串取值） */
export class SignUserEntity {
  BCJYY: string = '';
  XLH: string = '';
  YHID: string = '';
  YHNAME: string = '';
}

/** 源码 Sign.java：扫码 result JSON（MeetingAttendActivity 解析取 meetingId） */
export class MeetingSignQrEntity {
  meetingId: string = '';
  qrcode_type: string = '';
}

// ===== [W18 meeting-remain] 会议链剩余页实体（meeting/entity/* + oa/selector/entity 源码 1:1）=====

/** 源码 MeetingWeekDetail.java：getWeekPlanDetails 响应 13 字段（FJID 源码为 Object，按字符串取值） */
export class MeetingWeekDetailEntity {
  BZ: string = '';
  CYRY: string = '';
  DD: string = '';
  FJID: string = '';
  IS_MY_WEEK_PLAN: string = '';
  JSSJ: string = '';
  KSSJ: string = '';
  LXDH: string = '';
  WEEK: string = '';
  XLH: string = '';
  ZBDW: string = '';
  ZCR: string = '';
  ZT: string = '';
}

/** 源码 Report.java：showMeetingReport 响应 4 字段 */
export class MeetingReportEntity {
  MEETING_CONTENT: string = '';
  MEETING_XLH: string = '';
  PIC: string = '';
  STATE: string = '';
}

/** 源码 MeetingSelector.java：api/select/meeting 响应树节点（data 递归子级） */
export class MeetingSelectorEntity {
  data: MeetingSelectorEntity[] = [];
  id: string = '';
  name: string = '';
  text: string = '';
  type: string = '';
}

/** ApiService.pick 环形依赖规避：模型文件内独立实现等价取值（仅本文件解析用） */
export function ApiServicePick(rec: Record<string, Object>, keys: string[]): string {
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
