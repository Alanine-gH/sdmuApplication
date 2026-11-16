export class SuperviseCourseItem {
  section: string;
  courseTitle: string;
  majorInfo: string;

  constructor(section: string, courseTitle: string, majorInfo: string) {
    this.section = section;
    this.courseTitle = courseTitle;
    this.majorInfo = majorInfo;
  }
}

export class SuperviseRecordItem {
  dateLabel: string;
  weekLabel: string;
  title: string;
  teacher: string;
  location: string;
  time: string;
  evaluated: boolean;
  attendanceExpect: string;
  attendanceActual: string;
  score: number;
  comment: string;

  constructor(dateLabel: string, weekLabel: string, title: string, teacher: string, location: string,
    time: string, evaluated: boolean, attendanceExpect: string, attendanceActual: string, score: number,
    comment: string) {
    this.dateLabel = dateLabel;
    this.weekLabel = weekLabel;
    this.title = title;
    this.teacher = teacher;
    this.location = location;
    this.time = time;
    this.evaluated = evaluated;
    this.attendanceExpect = attendanceExpect;
    this.attendanceActual = attendanceActual;
    this.score = score;
    this.comment = comment;
  }
}

export class SuperviseMineData {
  pastRecords: SuperviseRecordItem[];
  futureRecords: SuperviseRecordItem[];

  constructor(pastRecords: SuperviseRecordItem[], futureRecords: SuperviseRecordItem[]) {
    this.pastRecords = pastRecords;
    this.futureRecords = futureRecords;
  }
}
