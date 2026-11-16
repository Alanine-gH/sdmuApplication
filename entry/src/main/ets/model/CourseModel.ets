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
