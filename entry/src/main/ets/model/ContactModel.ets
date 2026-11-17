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

// ===== T2 contact-worker 追加：通讯录初始化实体（源码 contact/entity/InitData.java 字段 1:1 映射） =====

/** 班级通讯录 Bean（InitData.ClassAddressBookBean） */
export class ContactClassAddressBookBean {
  BJID: string = '';
  BJMC: string = '';
  JSID: string = '';
}

/** 我的课程教师 Bean（InitData.CourseTeacherBean） */
export class ContactCourseTeacherBean {
  avatar: string = '';
  course: string = '';
  phone: string = '';
  sex: string = '';
  userId: string = '';
  userName: string = '';
}

/** 根组织 Bean（InitData.RootOrganizationBean） */
export class ContactRootOrganizationBean {
  BMDM: string = '';
  BMMC: string = '';
  PXH: string = '';
  SJBMDM: string = '';
  XLH: string = '';
}

/** 常用联系人/我的教师 Bean（InitData.TopContactListBean） */
export class ContactTopContactListBean {
  BDCS: number = 0;
  BDSJH: string = '';
  BMDM: string = '';
  BMMC: string = '';
  GH: string = '';
  INTRO: string = '';
  ROWNUM: number = 0;
  SCYHID: string = '';
  SJHM: string = '';
  TJFS: string = '';
  TJSJ: string = '';
  TX: string = '';
  XB: string = '';
  XLH: string = '';
  XM: string = '';
  ZW: string = '';
}

/** 通讯录初始化数据（InitData，type 决定分组类型） */
export class ContactInitData {
  classAddressBook: ContactClassAddressBookBean[] = [];
  myCourseTeachers: ContactCourseTeacherBean[] = [];
  myTeacher: ContactTopContactListBean[] = [];
  name: string = '';
  rootOrganization: ContactRootOrganizationBean[] = [];
  topContactList: ContactTopContactListBean[] = [];
  type: string = '';
}
