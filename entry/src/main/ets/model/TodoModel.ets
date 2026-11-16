export class TodoItem {
  id: string;
  title: string;
  status: string;
  type: string;
  deadline: string;
  priority: string;
  fromUser: string;
  content: string;

  constructor(id: string, title: string, status: string, type: string, deadline: string,
    priority: string, fromUser: string, content: string) {
    this.id = id;
    this.title = title;
    this.status = status;
    this.type = type;
    this.deadline = deadline;
    this.priority = priority;
    this.fromUser = fromUser;
    this.content = content;
  }
}
