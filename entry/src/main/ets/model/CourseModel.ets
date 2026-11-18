export class CourseItem {
  id: string;
  name: string;
  teacher: string;
  location: string;
  week: string;
  dayOfWeek: number;
  sectionStart: number;
  sectionEnd: number;
  credit: number;
  type: string;
  // 源码 ScheduleOfTermEntity.djz：服务器按教学周次拆行（APK 本地查询 timetable_djz==当前周）；
  // 0 表示行数据无周次（走 week 字符串解析兜底）
  djz: number;
  // 源码 ScheduleOfTermEntity.xlh 原文（本服务器为"{1-5周,7-16周}"周次描述，courseDetail GET 的 xlh 参数）
  xlh: string;

  constructor(id: string, name: string, teacher: string, location: string, week: string,
    dayOfWeek: number, sectionStart: number, sectionEnd: number, credit: number, type: string,
    djz: number = 0, xlh: string = '') {
    this.id = id;
    this.name = name;
    this.teacher = teacher;
    this.location = location;
    this.week = week;
    this.dayOfWeek = dayOfWeek;
    this.sectionStart = sectionStart;
    this.sectionEnd = sectionEnd;
    this.credit = credit;
    this.type = type;
    this.djz = djz;
    this.xlh = xlh;
  }
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

/** ApiService.pickNumber 同款（W16 AuditAcademyEntry.tjcs 等数字字段用） */
function ApiServicePickNumber(rec: Record<string, Object>, keys: string[]): number {
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

/**
 * 源码 TermParamsEntity.java（gettimetable 模块）1:1：termParams/termInfo 响应学期参数。
 * ksrq=学期开始日期、jsrq=结束日期（yyyy-MM-dd），dqxq=1 表示当前学期；
 * APK GetTimeTableUtil.e() 用 (now-ksrq)/7天+1 计算当前周。
 */
export class ScheduleTermParams {
  xn: string;
  xq: string;
  ksrq: string;
  jsrq: string;
  dqxq: string;
  xlh: string;
  zksxq: number;

  constructor() {
    this.xn = '';
    this.xq = '';
    this.ksrq = '';
    this.jsrq = '';
    this.dqxq = '';
    this.xlh = '';
    this.zksxq = 0;
  }

  hasStart(): boolean {
    return this.ksrq.length >= 10;
  }
}

// ===== 课表周次计算（源码 GetTimeTableUtil.java 1:1，三处共用：SchedulePage/ScheduleGrid/ICampusTab） =====

/** 服务器实测当前学期（2026-11-17 termInfo）兜底：xn=2026-2027 xq=1 */
export const SCHEDULE_FALLBACK_START: string = '2026-08-24';
export const SCHEDULE_FALLBACK_END: string = '2027-01-15';
export const DAY_MS: number = 86400000;
/** GetTimeTableUtil.e() 间隔：7 天毫秒数 */
export const WEEK_MS: number = 604800000;

/** 'yyyy-MM-dd' → 本地时区当天 00:00 毫秒；非法返回 -1 */
export function parseYmdMs(ymd: string): number {
  if (ymd.length < 10) {
    return -1;
  }
  const y: number = Number(ymd.substring(0, 4));
  const m: number = Number(ymd.substring(5, 7));
  const d: number = Number(ymd.substring(8, 10));
  if (Number.isNaN(y) || Number.isNaN(m) || Number.isNaN(d) || m < 1 || m > 12 || d < 1 || d > 31) {
    return -1;
  }
  return new Date(y, m - 1, d).getTime();
}

/** GetTimeTableUtil.e() 1:1：now 不在 [ksrq,jsrq] 返回 -1，否则 (now-ksrq)/7天 + 1 */
export function apkCurrentWeek(startMs: number, endMs: number, nowMs: number): number {
  if (startMs <= 0 || endMs <= 0) {
    return -1;
  }
  if (nowMs < startMs || nowMs > endMs) {
    return -1;
  }
  return Math.floor((nowMs - startMs) / WEEK_MS) + 1;
}

/** GetTimeTableUtil.r() 1:1：总周数 = (jsrq+1天-ksrq)/7 向上取整 */
export function apkTotalWeeks(startMs: number, endMs: number): number {
  if (startMs <= 0 || endMs <= 0) {
    return -1;
  }
  const days: number = Math.floor((endMs - startMs) / DAY_MS) + 1;
  return days % 7 === 0 ? days / 7 : Math.floor(days / 7) + 1;
}

const SECTION_START_TIMES: string[] = ['08:00', '08:55', '09:50', '10:45', '11:40', '14:00',
  '14:55', '15:50', '16:45', '18:30', '19:20', '20:10'];

function addMinutes(timeText: string, minutes: number): string {
  const parts: string[] = timeText.split(':');
  const hour: number = Number(parts[0]);
  const minute: number = Number(parts[1]) + minutes;
  const total: number = hour * 60 + minute;
  const endHour: number = Math.floor(total / 60);
  const endMinute: number = total % 60;
  const hourText: string = endHour < 10 ? '0' + endHour : endHour.toString();
  const minuteText: string = endMinute < 10 ? '0' + endMinute : endMinute.toString();
  return hourText + ':' + minuteText;
}

/**
 * 将节次区间（如第 1-2 节）转换为时间文本（如 08:00 - 09:40），用于课表卡片展示。
 */
export function sectionTimeLabel(sectionStart: number, sectionEnd: number): string {
  if (sectionStart < 1 || sectionStart > SECTION_START_TIMES.length) {
    return '';
  }
  const startText: string = SECTION_START_TIMES[sectionStart - 1];
  const endIdx: number = sectionEnd >= sectionStart && sectionEnd <= SECTION_START_TIMES.length ?
    sectionEnd : sectionStart;
  const endText: string = addMinutes(SECTION_START_TIMES[endIdx - 1], 45);
  return startText + ' - ' + endText;
}

export class ScheduleItem {
  id: string;
  title: string;
  time: string;
  location: string;
  type: string;

  constructor(id: string, title: string, time: string, location: string, type: string) {
    this.id = id;
    this.title = title;
    this.time = time;
    this.location = location;
    this.type = type;
  }
}

// ===== [W16 course-select] 蹭课链实体（timetable/entity Gson 字段 1:1，2026-11-18 探针实测形态） =====

/** 源码 AcademyEntity.java（getCkColleges 响应元素）：xydm/xymc/tjcs（courseList 本链未用） */
export class AuditAcademyEntry {
  xydm: string = '';
  xymc: string = '';
  tjcs: number = 0;

  static fromRecord(rec: Record<string, Object>): AuditAcademyEntry {
    const e: AuditAcademyEntry = new AuditAcademyEntry();
    e.xydm = ApiServicePick(rec, ['xydm']);
    e.xymc = ApiServicePick(rec, ['xymc']);
    e.tjcs = ApiServicePickNumber(rec, ['tjcs']);
    return e;
  }
}

/** 源码 GradeEntity.java（getGradeList 响应元素，实测 大一nj=2026…大四nj=2023） */
export class AuditGradeEntry {
  nj: string = '';
  njmc: string = '';

  static fromRecord(rec: Record<string, Object>): AuditGradeEntry {
    const e: AuditGradeEntry = new AuditGradeEntry();
    e.nj = ApiServicePick(rec, ['nj']);
    e.njmc = ApiServicePick(rec, ['njmc']);
    return e;
  }
}

/** 源码 MajorEntity.java（getCkMajors 响应元素） */
export class AuditMajorEntry {
  zydm: string = '';
  zymc: string = '';

  static fromRecord(rec: Record<string, Object>): AuditMajorEntry {
    const e: AuditMajorEntry = new AuditMajorEntry();
    e.zydm = ApiServicePick(rec, ['zydm']);
    e.zymc = ApiServicePick(rec, ['zymc']);
    return e;
  }
}

/**
 * 源码 AuditCourseParams.java（ckControl 响应）：searchFilterShow/timeFilterShow 为 "1"=开；
 * isSupport* 派生布尔在 ChooseAcademyPresenter b 类 g() 内计算（"1".equals(xxx)），
 * TimetableAuditCourseSharePreferencesUtil 持久化键 isSupportAuditCourseSearchFilter/TimeFilter。
 */
export class AuditControlParams {
  searchFilterShow: string = '';
  timeFilterShow: string = '';

  static fromRecord(rec: Record<string, Object>): AuditControlParams {
    const e: AuditControlParams = new AuditControlParams();
    e.searchFilterShow = ApiServicePick(rec, ['searchFilterShow']);
    e.timeFilterShow = ApiServicePick(rec, ['timeFilterShow']);
    return e;
  }

  supportSearchFilter(): boolean {
    return this.searchFilterShow === '1';
  }

  supportTimeFilter(): boolean {
    return this.timeFilterShow === '1';
  }
}

/** 源码 getCollegeCourseNames 响应行：ChooseCoursePresenter d 回调仅取 kcmc（2026-11-18 实测空表） */
export class AuditCourseNameEntry {
  kcmc: string = '';

  static fromRecord(rec: Record<string, Object>): AuditCourseNameEntry {
    const e: AuditCourseNameEntry = new AuditCourseNameEntry();
    e.kcmc = ApiServicePick(rec, ['kcmc']);
    return e;
  }
}

// ===== [W10 timetable-series] 课表系列实体（源码 gettimetable 模块 Gson 字段 1:1） =====

/** 源码 ScheduleOfWeekEntity.java（getScheduleList 响应元素，17 字段 public） */
export class ScheduleWeekCourse {
  bjmc: string = '';
  djj: string = '';
  djz: string = '';
  jsjc: string = '';
  jxnr: string = '';
  kcdm: string = '';
  kcfl: string = '';
  kcmc: string = '';
  kcxz: string = '';
  ksjc: string = '';
  skdd: string = '';
  skls: string = '';
  xf: string = '';
  xlh: string = '';
  xn: string = '';
  xq: string = '';
  xqj: string = '';

  static fromRecord(rec: Record<string, Object>): ScheduleWeekCourse {
    const e: ScheduleWeekCourse = new ScheduleWeekCourse();
    e.bjmc = ApiServicePick(rec, ['bjmc']);
    e.djj = ApiServicePick(rec, ['djj']);
    e.djz = ApiServicePick(rec, ['djz']);
    e.jsjc = ApiServicePick(rec, ['jsjc']);
    e.jxnr = ApiServicePick(rec, ['jxnr']);
    e.kcdm = ApiServicePick(rec, ['kcdm']);
    e.kcfl = ApiServicePick(rec, ['kcfl']);
    e.kcmc = ApiServicePick(rec, ['kcmc']);
    e.kcxz = ApiServicePick(rec, ['kcxz']);
    e.ksjc = ApiServicePick(rec, ['ksjc']);
    e.skdd = ApiServicePick(rec, ['skdd']);
    e.skls = ApiServicePick(rec, ['skls']);
    e.xf = ApiServicePick(rec, ['xf']);
    e.xlh = ApiServicePick(rec, ['xlh']);
    e.xn = ApiServicePick(rec, ['xn']);
    e.xq = ApiServicePick(rec, ['xq']);
    e.xqj = ApiServicePick(rec, ['xqj']);
    return e;
  }
}

/** 源码 CourseSectionsEntity.java（courseSections 响应元素；djjStr 为序数文案派生字段不落库） */
export class CourseSectionsEntry {
  djj: string = '';
  sksj: string = '';
  xksj: string = '';

  static fromRecord(rec: Record<string, Object>): CourseSectionsEntry {
    const e: CourseSectionsEntry = new CourseSectionsEntry();
    e.djj = ApiServicePick(rec, ['djj']);
    e.sksj = ApiServicePick(rec, ['sksj']);
    e.xksj = ApiServicePick(rec, ['xksj']);
    return e;
  }
}

/** 源码 Classes.java（getClassList 响应元素；bjdm 源码为 Object，按字符串取值） */
export class ClassEntry {
  bjdm: string = '';
  bjmc: string = '';
  sl: number = 0;

  static fromRecord(rec: Record<string, Object>): ClassEntry {
    const e: ClassEntry = new ClassEntry();
    e.bjdm = ApiServicePick(rec, ['bjdm']);
    e.bjmc = ApiServicePick(rec, ['bjmc']);
    const sl: Object = rec['sl'];
    e.sl = typeof sl === 'number' ? sl as number : Number(sl as string) || 0;
    return e;
  }
}

/** 源码 CourseDetailEntity.LeaveStudent.java（请假学生，11 字段） */
export class LeaveStudentEntry {
  application_time: string = '';
  class_name: string = '';
  end_date: string = '';
  jsjc: string = '';
  ksjc: string = '';
  profession: string = '';
  reason: string = '';
  sex: string = '';
  start_date: string = '';
  student_name: string = '';
  student_no: string = '';

  static fromRecord(rec: Record<string, Object>): LeaveStudentEntry {
    const e: LeaveStudentEntry = new LeaveStudentEntry();
    e.application_time = ApiServicePick(rec, ['application_time']);
    e.class_name = ApiServicePick(rec, ['class_name']);
    e.end_date = ApiServicePick(rec, ['end_date']);
    e.jsjc = ApiServicePick(rec, ['jsjc']);
    e.ksjc = ApiServicePick(rec, ['ksjc']);
    e.profession = ApiServicePick(rec, ['profession']);
    e.reason = ApiServicePick(rec, ['reason']);
    e.sex = ApiServicePick(rec, ['sex']);
    e.start_date = ApiServicePick(rec, ['start_date']);
    e.student_name = ApiServicePick(rec, ['student_name']);
    e.student_no = ApiServicePick(rec, ['student_no']);
    return e;
  }
}

/** 源码 CourseDetailEntity.java（courseDetail/freeCourseParticulars 响应；展示用字段子集） */
export class CourseDetailEntry {
  classId: string = '';
  courseId: string = '';
  djj: string = '';
  dm: string = '';
  dsz: string = '';
  gkl: string = '';
  kcdm: string = '';
  kcmc: string = '';
  leaveStudent: LeaveStudentEntry[] = [];
  lszgf: string = '';
  nansbl: string = '';
  nvsbl: string = '';
  pjf: string = '';
  qsjsz: string = '';
  skbj: string = '';
  skdd: string = '';
  skls: string = '';
  skrs: string = '';
  sksj: string = '';
  xlh: string = '';
  xn: string = '';
  xq: string = '';
  xqj: string = '';
  zgfbczrs: string = '';
  zgfzscj: string = '';

  static fromRecord(rec: Record<string, Object>): CourseDetailEntry {
    const e: CourseDetailEntry = new CourseDetailEntry();
    e.classId = ApiServicePick(rec, ['classId', 'classid']);
    e.courseId = ApiServicePick(rec, ['courseId', 'courseid']);
    e.djj = ApiServicePick(rec, ['djj']);
    e.dm = ApiServicePick(rec, ['dm']);
    e.dsz = ApiServicePick(rec, ['dsz']);
    e.gkl = ApiServicePick(rec, ['gkl']);
    e.kcdm = ApiServicePick(rec, ['kcdm']);
    e.kcmc = ApiServicePick(rec, ['kcmc']);
    e.lszgf = ApiServicePick(rec, ['lszgf']);
    e.nansbl = ApiServicePick(rec, ['nansbl']);
    e.nvsbl = ApiServicePick(rec, ['nvsbl']);
    e.pjf = ApiServicePick(rec, ['pjf']);
    e.qsjsz = ApiServicePick(rec, ['qsjsz']);
    e.skbj = ApiServicePick(rec, ['skbj']);
    e.skdd = ApiServicePick(rec, ['skdd']);
    e.skls = ApiServicePick(rec, ['skls']);
    e.skrs = ApiServicePick(rec, ['skrs']);
    e.sksj = ApiServicePick(rec, ['sksj']);
    e.xlh = ApiServicePick(rec, ['xlh']);
    e.xn = ApiServicePick(rec, ['xn']);
    e.xq = ApiServicePick(rec, ['xq']);
    e.xqj = ApiServicePick(rec, ['xqj']);
    e.zgfbczrs = ApiServicePick(rec, ['zgfbczrs']);
    e.zgfzscj = ApiServicePick(rec, ['zgfzscj']);
    const rawLeave: Object = rec['leaveStudent'];
    if (Array.isArray(rawLeave)) {
      for (const one of rawLeave as Object[]) {
        e.leaveStudent.push(LeaveStudentEntry.fromRecord(one as Record<string, Object>));
      }
    }
    return e;
  }
}
