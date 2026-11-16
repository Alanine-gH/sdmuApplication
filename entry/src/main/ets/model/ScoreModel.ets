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
