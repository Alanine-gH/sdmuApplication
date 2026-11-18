/**
 * 督导（superviseListen）模块模型 — [W21 supervise]
 * 源码 supervise/entity/* Gson 字段 1:1（禁编造）：
 *   UserCourseList.java {detail: List<DetailBean>, xqj: int}（2026-11-18 探针实测 7 组 xqj=0..6）
 *   UserCourseList.DetailBean {DJJ,KCDM,KCMC,SKDD,SKDX,SKLSXM,XLH,...}
 *   NotListening.java / StaleListening.java（待听课/已过期，ISEVALUATE=="0"→未评价）
 *   DepartmentList.java {BMDM,BMMC}（筛选学院清单）
 *   SearchSector.java {GH,XM,BMMC}（教师搜索）
 */

/** 源码 UserCourseList.DetailBean（主列表行：tvSection=DJJ / tvTitle=KCMC / tvMajor=SKDD(type0)或SKLSXM(type1)） */
export class SuperviseCourseItem {
  DJJ: string;
  KCMC: string;
  SKDD: string;
  SKLSXM: string;
  XLH: string;

  constructor(DJJ: string, KCMC: string, SKDD: string, SKLSXM: string, XLH: string) {
    this.DJJ = DJJ;
    this.KCMC = KCMC;
    this.SKDD = SKDD;
    this.SKLSXM = SKLSXM;
    this.XLH = XLH;
  }
}

/** 源码 UserCourseList（周视图按日分组：xqj 0..6 = 周日..周六，WeekView.java FIRST_DAY=1 SUNDAY 开头） */
export class SuperviseDayGroup {
  xqj: number;
  detail: SuperviseCourseItem[];

  constructor(xqj: number, detail: SuperviseCourseItem[]) {
    this.xqj = xqj;
    this.detail = detail;
  }
}

/** 源码 NotListening.java / StaleListening.java 列表字段（我的听课两 Tab 行） */
export class SuperviseListenRecord {
  XLH: string;
  LISTENTIME: string;
  KCMC: string;
  SKLSXM: string;
  SKDD: string;
  XQJ: string;
  DJJ: string;
  ISEVALUATE: string;

  constructor(XLH: string, LISTENTIME: string, KCMC: string, SKLSXM: string, SKDD: string,
    XQJ: string, DJJ: string, ISEVALUATE: string) {
    this.XLH = XLH;
    this.LISTENTIME = LISTENTIME;
    this.KCMC = KCMC;
    this.SKLSXM = SKLSXM;
    this.SKDD = SKDD;
    this.XQJ = XQJ;
    this.DJJ = DJJ;
    this.ISEVALUATE = ISEVALUATE;
  }
}

/** 源码 DepartmentList.java（筛选页学院滚轮：tvSchool=BMMC，提交 bjData.BMDM） */
export class SuperviseDepartment {
  BMDM: string;
  BMMC: string;

  constructor(BMDM: string, BMMC: string) {
    this.BMDM = BMDM;
    this.BMMC = BMMC;
  }
}

/** 源码 SearchSector.java（教师搜索行：tvName=XM / tvMajor=BMMC；回传 XM+GH） */
export class SuperviseTeacher {
  GH: string;
  XM: string;
  BMMC: string;

  constructor(GH: string, XM: string, BMMC: string) {
    this.GH = GH;
    this.XM = XM;
    this.BMMC = BMMC;
  }
}
