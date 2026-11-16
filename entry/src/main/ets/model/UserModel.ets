export class UserInfo {
  userId: string;
  name: string;
  studentNo: string;
  className: string;
  college: string;
  major: string;
  grade: string;
  phone: string;
  email: string;
  avatar: string;
  token: string;

  constructor(userId: string, name: string, studentNo: string, className: string,
    college: string, major: string, grade: string, phone: string, email: string,
    avatar: string, token: string) {
    this.userId = userId;
    this.name = name;
    this.studentNo = studentNo;
    this.className = className;
    this.college = college;
    this.major = major;
    this.grade = grade;
    this.phone = phone;
    this.email = email;
    this.avatar = avatar;
    this.token = token;
  }
}
