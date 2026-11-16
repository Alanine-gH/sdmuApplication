export class MeetingItem {
  id: string;
  title: string;
  time: string;
  location: string;
  status: string;
  organizer: string;
  content: string;

  constructor(id: string, title: string, time: string, location: string, status: string,
    organizer: string, content: string) {
    this.id = id;
    this.title = title;
    this.time = time;
    this.location = location;
    this.status = status;
    this.organizer = organizer;
    this.content = content;
  }
}
