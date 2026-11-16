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

  constructor(id: string, name: string, teacher: string, location: string, week: string,
    dayOfWeek: number, sectionStart: number, sectionEnd: number, credit: number, type: string) {
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
  }
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
