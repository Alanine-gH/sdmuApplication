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
