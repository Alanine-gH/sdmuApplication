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

// ===== W9 contact-series 追加：搜索/黄页/部门实体（源码 contact/entity + oa/selector/entity 字段 1:1） =====

/** 搜索结果子项（SearchAddressBook.AddressBookListBean；course 为学生搜索实测扩展字段） */
export class ContactSearchAddressBookItem {
  BDSJH: string = '';
  SJHM: string = '';
  TX: string = '';
  XB: string = '';
  XLH: string = '';
  XM: string = '';
  ZW: string = '';
  course: string = '';
}

/** 搜索结果分组（SearchAddressBook：按部门 bmmc 分组） */
export class ContactSearchAddressBook {
  addressBookList: ContactSearchAddressBookItem[] = [];
  bmdm: string = '';
  bmmc: string = '';
  isYellowCard: string = '';
}

/** 黄页分类条目（YellowPage.DataListBean.TypeListBean） */
export class ContactYellowTypeListBean {
  DM: string = '';
  GXSJ: string = '';
  MC: string = '';
  MS: string = '';
  XLH: string = '';
  YXJ: string = '';
}

/** 黄页常用电话条目（YellowPage.DataListBean.CommonlyPhoneListBean） */
export class ContactYellowCommonBean {
  ADDRESS: string = '';
  DH: string = '';
  EMAIL: string = '';
  GXSJ: string = '';
  MC: string = '';
  TP: string = '';
  XLH: string = '';
  YXJ: string = '';
}

/** 黄页分组（YellowPage.DataListBean：name="typeList"|"commonlyPhoneList"） */
export class ContactYellowPageGroup {
  commonlyPhoneList: ContactYellowCommonBean[] = [];
  name: string = '';
  typeList: ContactYellowTypeListBean[] = [];
}

/** 黄页列表（YellowPage） */
export class ContactYellowPage {
  dataList: ContactYellowPageGroup[] = [];
  departmentName: string = '';
}

/** 黄页分类电话条目（YellowType.DepPhoneListBean） */
export class ContactYellowDepPhoneBean {
  ADDRESS: string = '';
  EMAIL: string = '';
  SJBMDM: string = '';
  SJHM: string = '';
  XLH: string = '';
  XM: string = '';
  YXJ: string = '';
}

/** 黄页分类响应（YellowType） */
export class ContactYellowTypeResult {
  currentDep: string = '';
  DepPhoneList: ContactYellowDepPhoneBean[] = [];
  name: string = '';
}

/** OA 部门选择条目（Department.DepartmentListBean，含服务器实测扩展 PXH/TYPE） */
export class OaDepartmentBean {
  BMDM: string = '';
  BMLX: string = '';
  BMMC: string = '';
  PXH: string = '';
  SJBMDM: string = '';
  TYPE: string = '';
  XLH: string = '';
  count: number = 0;
  isChildren: string = '';
}

/** OA 部门选择响应（Department） */
export class OaDepartment {
  departmentList: OaDepartmentBean[] = [];
  title: string = '';
}

// ===== W25 misc-b 追加：班级通讯录/个人详情实体（源码 contact/entity 字段 1:1） =====

/** 班级通讯录学生条目（ClassAddressBook.java 字段 1:1） */
export class ContactClassStudentBean {
  BDSJH: string = '';
  BJID: string = '';
  SJHM: string = '';
  XB: string = '';
  XH: string = '';
  XLH: string = '';
  XM: string = '';
}

/** 行电话（源码 ClassContactAdapter.j：BDSJH 空 → SJHM） */
export function contactClassPhoneOf(bean: ContactClassStudentBean): string {
  return bean.BDSJH !== '' ? bean.BDSJH : bean.SJHM;
}

/** 个人详情 userInfo（AddressBookUserInfo.UserInfoBean 字段 1:1） */
export class ContactAddressBookUser {
  BDSJH: string = '';
  BGDH: string = '';
  BGDZ: string = '';
  BMDM: string = '';
  BMMC: string = '';
  CARDNO: string = '';
  DZYJ: string = '';
  GH: string = '';
  GW: string = '';
  QXZ: string = '';
  RZBD_QQ: string = '';
  RZBD_WX: string = '';
  SJDH: string = '';
  SJHM: string = '';
  TX: string = '';
  XB: string = '';
  XH: string = '';
  XLH: string = '';
  XM: string = '';
  ZW: string = '';
  classId: string = '';
  className: string = '';
  course: string = '';
  nativePlace: string = '';
  professionName: string = '';
  studentSex: string = '';
  teacherId: string = '';
  teacherName: string = '';
  teacherPhone: string = '';
  userType: string = '';
}

/** 个人详情响应（AddressBookUserInfo 字段 1:1） */
export class ContactAddressBookUserInfo {
  name: string = '';
  roleType: string = '';
  title: string = '';
  type: string = '';
  userInfo: ContactAddressBookUser = new ContactAddressBookUser();
}

/** [W25 misc-b] 科研项目条目（reimburse/entity/Reimbursement.java 字段 1:1） */
export class ReimbursementEntry {
  AMOUNT: number = 0;
  BUSINESS_NUMBER: string = '';
  BUSINESS_TYPE: string = '';
  DEPT_NUMBER: number = 0;
  DESC: string = '';
  FIZZEZ_AMOUNT: string = '';
  PROJECT_NAME: string = '';
  PROJECT_NUMBER: string = '';
  REIMBURSE_AMOUNT: string = '';
  REIMBURSE_DATE: number = 0;
  REIMBURSE_PEOPLE: string = '';
  REIMBURSE_TYPE: string = '';
  STATUS: string = '';
  SUB_NUMBER: string = '';
  TEACHERID: number = 0;
  USABLE_AMOUNT: string = '';
}

/** [P-C] 源码 reimburse/entity/Detail.java（项目详情 T0 project/detail → Detail，字段 Gson 1:1） */
export class ReimburseProjectDetail {
  CONTRACT_AMOUNT: string = '';
  OUTSIDE_AMOUNT: string = '';
  PAY_AMOUNT: string = '';
  PROJECT_MEMBER: string = '';
  PROJECT_NAME: string = '';
  PROJECT_STATUS: string = '';
  PROJECT_TYPE: string = '';
  RECEIVE_AMOUNT: string = '';
}

/** [W25 misc-b] 图书数据（reading/entity/BaseReadingData.java 字段 1:1；SearchMyCollect/Search 继承其全部字段）
 *  [W28 final-b] 追加 CurrentBorrowBean 三字段 JYRQ/YHRQ/DAY（当前借阅列表专用，BaseReadingData 无）。 */
export class ReadingBookEntry {
  CBRQ: string = '';
  CBS: string = '';
  COLLECTXLH: string = '';
  GCD: string = '';
  ISBN: string = '';
  JG: string = '';
  SJMC: string = '';
  SQH: string = '';
  TMH: string = '';
  TP: string = '';
  TXM: string = '';
  YS: string = '';
  ZGZT: string = '';
  ZZ: string = '';
  // CurrentBorrowBean 追加字段（HomePageData 当前借阅）
  DAY: string = '';
  JYRQ: string = '';
  YHRQ: string = '';
}

/** [W25 misc-b] 今日日程条目（schedule/entity/ScheduleItem.DetailBean 字段 1:1） */
export class ScheduleDetailRow {
  address: string = '';
  djj: string = '';
  dsz: string = '';
  is_current_user_plan: string = '';
  is_join: number = 0;
  is_urgency: number = 0;
  jssj: string = '';
  kcdm: string = '';
  kcmc: string = '';
  kssj: string = '';
  locate: string = '';
  meeting_type: number = 0;
  qsjsz: string = '';
  qxly: string = '';
  schedule_color: string = '';
  schedule_content: string = '';
  schedule_id: string = '';
  schedule_remind: string = '';
  schedule_type: string = '';
  skdd: string = '';
  skdx: string = '';
  skdx1: string = '';
  status: string = '';
  task_id: string = '';
  task_type: string = '';
  title: string = '';
  week: string = '';
  xlh: string = '';
  xqj: string = '';
}

/** [W25 misc-b] 今日日程月数据（ScheduleItem{rq, detail[]}） */
export class ScheduleMonthItem {
  rq: string = '';
  detail: ScheduleDetailRow[] = [];
}

/** [W25 misc-b] 日程详情（schedule/entity/ScheduleDetail.java 字段 1:1） */
export class ScheduleDetailEntry {
  END_TIME: string = '';
  KSRQ: string = '';
  LOCATE: string = '';
  REMIND_TIME: string = '';
  SCHEDULE_COLOR: string = '';
  SCHEDULE_CONTENT: string = '';
  SCHEDULE_ID: string = '';
  SCHEDULE_REMIND: string = '';
  SCHEDULE_TYPE: string = '';
  TASK_ID: string = '';
  TASK_TYPE: string = '';
  TITLE: string = '';
}

/** [W25 misc-b] 校园概况入口（school/entity/Index.java 字段 1:1） */
export class SchoolViewModuleBean {
  ICON: string = '';
  NAME: string = '';
  URL: string = '';
}

export class SchoolViewIndex {
  banner: string = '';
  module: SchoolViewModuleBean[] = [];
}

// ===== W25 misc-b：易班聚合链实体（源码 module/yiban + app/entity 字段 1:1） =====

/** 易班 banner（YDXYBannerInfo） */
export class YiBanBannerEntry {
  BT: string = '';
  GXSJ: string = '';
  JHZT: string = '';
  LX: string = '';
  PXH: string = '';
  TP: string = '';
  URL: string = '';
  XLH: string = '';
}

/** 易班应用条目（AppBean 本页消费字段：图标/名称/跳转） */
export class YiBanAppItem {
  ICON: string = '';
  NAME: string = '';
  URL: string = '';
  LX: string = '';
  YYID: string = '';
}

/** 易班应用分组（YDAPPInfo{YYFL, DATA:AppBean[]}） */
export class YiBanAppGroup {
  DATA: YiBanAppItem[] = [];
  ISSHOWCOMMONAPP: string = '';
  SHOWNUMBER: number = 0;
  TYPE: string = '';
  YYFL: string = '';
}

/** 易班头条（YiBanNews） */
export class YiBanNewsEntry {
  LX: string = '';
  PXH: number = 0;
  TITLE: string = '';
  TP: string = '';
  URL: string = '';
  XLH: string = '';
  image: string = '';
  title: string = '';
  url: string = '';
}

/** 易瞄瞄图片（YiBanArticle.ImageListBean） */
export class YiBanArticleImage {
  image_url: string = '';
}

/** 易瞄瞄文章（YiBanArticle） */
export class YiBanArticleEntry {
  content: string = '';
  contentNum: number = -1;
  image_list: YiBanArticleImage[] = [];
  news_content: string = '';
  news_id: string = '';
  news_sendtime: string = '';
  news_title: string = '';
  yb_schoolname: string = '';
  yb_userhead: string = '';
  yb_userid: string = '';
  yb_usernick: string = '';
}

// ===== [W26 partial-finish] 设置页/学习报告/扫码分流实体（源码字段 1:1）=====

/** 应用项（AppBean.java 字段 1:1：设置页宫格子项与分流 AppBean 构造共用） */
export class MainAppItem {
  LX: string = '';
  PXH: string = '';
  URL: string = '';
  YYID: string = '';
  YYMC: string = '';
  YYTB: string = '';
}

/** 应用分组（YDAPPInfo.java：TYPE 分组标识 / YYFL 分组标题 / DATA 应用列表） */
export class MainAppGroup {
  DATA: MainAppItem[] = [];
  TYPE: string = '';
  YYFL: string = '';
}

/** 扫码跳转（ScanURL.java：scan/accessGate、scan/bpm 响应 data，jumpUrl 轻应用直载） */
export class ScanJumpUrl {
  jumpUrl: string = '';
}

/** 学期信息（studyReport/entity/TermInfo.java：getRecentTermInfo 响应 data） */
export class StudyTermInfo {
  XN: string = '';
  XQ: string = '';
}

// ===== [W27 final-a] 校园风光实体（school/entity/TypeForPic.java 字段 1:1） =====

/** 校园风光图片（TypeForPic）：HEIGHT/WIDTH 原图尺寸用于 2 列瀑布流高度；MY 页签 verifyState 控制署名 */
export class SchoolSceneryItem {
  HEIGHT: string = '';
  ISLIKE: number = 0;
  LIKE_COUNT: number = 0;
  PICID: string = '';
  PIC_URL: string = '';
  VERIFY: string = '';
  WIDTH: string = '';
  XM: string = '';
  verifyState: string = '';
}

/** 删除图片响应（school/entity/DeletePic.java） */
export class SchoolDeletePic {
  flag: boolean = false;
}

// ===== [W28 final-b] 图书馆首页 / 发票助手实体（源码字段 1:1） =====

/** 图书馆首页（reading/entity/HomePageData.java：status/borrowNum/userId/overdue/arrearage/currentBorrow[]） */
export class ReadingHomeData {
  status: string = '';
  borrowNum: string = '';
  userId: string = '';
  overdue: string = '';
  arrearage: string = '';
  currentBorrow: ReadingBookEntry[] = [];
}

/** 历史借阅响应（reading/entity/ReturnData.java：returnData[] 为 BaseReadingData） */
export class ReadingReturnData {
  returnData: ReadingBookEntry[] = [];
}

/** 发票抬头（module/my/entity/Ratepaying.java 字段 1:1） */
export class RatepayingEntry {
  CREATETIME: string = '';
  DHHM: string = '';
  DWDZ: string = '';
  KHYH: string = '';
  MC: string = '';
  ORDERBY: string = '';
  QRCODE: string = '';
  SH: string = '';
  STATUS: string = '';
  TYPE: string = '';
  XLH: string = '';
  YHZH: string = '';
}
