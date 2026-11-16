export class ContactItem {
  id: string;
  name: string;
  department: string;
  phone: string;
  email: string;
  position: string;
  avatar: string;

  constructor(id: string, name: string, department: string, phone: string, email: string,
    position: string, avatar: string) {
    this.id = id;
    this.name = name;
    this.department = department;
    this.phone = phone;
    this.email = email;
    this.position = position;
    this.avatar = avatar;
  }
}
