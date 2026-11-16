export class AttendanceItem {
  id: string;
  courseName: string;
  status: string;
  time: string;
  type: string;
  location: string;

  constructor(id: string, courseName: string, status: string, time: string, type: string,
    location: string) {
    this.id = id;
    this.courseName = courseName;
    this.status = status;
    this.time = time;
    this.type = type;
    this.location = location;
  }
}
