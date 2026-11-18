export class ScoreItem {
  id: string;
  courseName: string;
  score: number;
  credit: number;
  gpa: number;
  semester: string;
  type: string;

  constructor(id: string, courseName: string, score: number, credit: number, gpa: number,
    semester: string, type: string) {
    this.id = id;
    this.courseName = courseName;
    this.score = score;
    this.credit = credit;
    this.gpa = gpa;
    this.semester = semester;
    this.type = type;
  }
}

export class ExamItem {
  id: string;
  courseName: string;
  time: string;
  location: string;
  type: string;

  constructor(id: string, courseName: string, time: string, location: string, type: string) {
    this.id = id;
    this.courseName = courseName;
    this.time = time;
    this.location = location;
    this.type = type;
  }
}

export class ScoreStatEntry {
  label: string;
  statValue: string;

  constructor(label: string, statValue: string) {
    this.label = label;
    this.statValue = statValue;
  }
}

export class ScoreDetailEntry {
  courseName: string;
  totalScore: string;
  avgScore: string;
  maxScore: string;
  failRate: string;
  personalScore: string;
  statCells: ScoreStatEntry[];

  constructor(courseName: string, totalScore: string, avgScore: string, maxScore: string, failRate: string,
    personalScore: string, statCells: ScoreStatEntry[]) {
    this.courseName = courseName;
    this.totalScore = totalScore;
    this.avgScore = avgScore;
    this.maxScore = maxScore;
    this.failRate = failRate;
    this.personalScore = personalScore;
    this.statCells = statCells;
  }
}

export class ScoreRankEntry {
  rankNo: string;
  rankName: string;
  anonymous: boolean;
  rankPoint: string;
  likeNum: string;

  constructor(rankNo: string, rankName: string, anonymous: boolean, rankPoint: string, likeNum: string) {
    this.rankNo = rankNo;
    this.rankName = rankName;
    this.anonymous = anonymous;
    this.rankPoint = rankPoint;
    this.likeNum = likeNum;
  }
}

export class ScoreCommentEntry {
  avatarText: string;
  commentName: string;
  commentTime: string;
  commentContent: string;

  constructor(avatarText: string, commentName: string, commentTime: string, commentContent: string) {
    this.avatarText = avatarText;
    this.commentName = commentName;
    this.commentTime = commentTime;
    this.commentContent = commentContent;
  }
}

export class ScoreDetailData {
  detailList: ScoreDetailEntry[];
  rankList: ScoreRankEntry[];
  commentList: ScoreCommentEntry[];

  constructor(detailList: ScoreDetailEntry[], rankList: ScoreRankEntry[], commentList: ScoreCommentEntry[]) {
    this.detailList = detailList;
    this.rankList = rankList;
    this.commentList = commentList;
  }
}

// ===== [W15 score-series] 成绩链实体（源码 Gson 字段 1:1） =====

/** StudentMessage.DataBean（score/entity/StudentMessage.java）：单科成绩行 */
export class StudentScoreChild {
  kcmc: string;
  xscj: string;
  bjpm: string;

  constructor(kcmc: string, xscj: string, bjpm: string) {
    this.kcmc = kcmc;
    this.xscj = xscj;
    this.bjpm = bjpm;
  }
}

/** StudentMessage（score/entity/StudentMessage.java）：学年学期分组 */
export class StudentScoreGroup {
  xn: string;
  xq: string;
  children: StudentScoreChild[];

  constructor(xn: string, xq: string, children: StudentScoreChild[]) {
    this.xn = xn;
    this.xq = xq;
    this.children = children;
  }
}

// ===== [W27 final-a] 考试/留言/学生名单/巡检排名实体（源码 Gson 字段 1:1） =====

/** ComingExamEntity（examination/entity/ComingExamEntity.java）：未考列表行（继承 ExamCourseInfo） */
export class ComingExamEntity {
  JSSJ: string = '';
  KMMC: string = '';
  KSDD: string = '';
  KSLX: string = '';
  KSSJ: string = '';
  LX: string = '';
  TGRXH: string = '';
  TXLX: string = '';
  TXSJ: string = '';
  XN: string = '';
  XQ: string = '';
  ZKZH: string = '';
  ZWH: string = '';
}

/** FinishExamEntity（examination/entity/FinishExamEntity.java）：已考列表行 */
export class FinishExamEntity {
  JSSJ: string = '';
  KMMC: string = '';
  KSDD: string = '';
  KSLX: string = '';
  KSSJ: string = '';
  LX: string = '';
  TGRXH: string = '';
  TXLX: string = '';
  TXSJ: string = '';
  XN: string = '';
  XQ: string = '';
  ZKZH: string = '';
  ZWH: string = '';
}

/** CommentInfo（student_score/entity/CommentInfo.java）：成绩留言行（字段名源码大写） */
export class ScoreCommentInfo {
  AVATAR: string = '';
  PLNR: string = '';
  PLSJ: string = '';
  XH: string = '';
  XLH: string = '';
  XM: string = '';
}

/** ClassAndId（score/entity/ClassAndId.java）：学生成绩单班级页签 {clazz,code} */
export class ClassAndId {
  clazz: string = '';
  code: string = '';
}

/** StudentEntity（score/entity/StudentEntity.java）：学生名单行 */
export class StudentEntity {
  xh: string = '';
  xm: string = '';
}

/** NewHadScore（inspection/entity/NewHadScore.java）：巡检排名行 */
export class NewHadScore {
  QSH: string = '';
  RANKNUM: number = 0;
  SCORE: string = '';
  XLH: string = '';
}

/** ClassmateEntity（timetable/entity/ClassmateEntity.java）：上课学生/最高分保持者行 */
export class ClassmateEntry {
  xm: string;
  xb: string;
  xh: string;
  bjmc: string;
  qjlb: string;

  constructor(xm: string, xb: string, xh: string, bjmc: string, qjlb: string) {
    this.xm = xm;
    this.xb = xb;
    this.xh = xh;
    this.bjmc = bjmc;
    this.qjlb = qjlb;
  }
}
