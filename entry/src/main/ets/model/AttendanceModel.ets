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

// ===== [E4 attendance worker] 追加：attendance 包实体（源码 com.lysoft.android.lyyd.attendance.entity 1:1） =====

/** 源码 AttendanceIsBoss.java：GET isBoss 响应（isBoss=="1" 显示"院系月份统计"页签） */
export class AttendanceIsBoss {
  isBoss: string = '';
}

/** 源码 AttendanceByDayBean.java：单日考勤（上午/下午打卡字段） */
export class AttendanceByDayBean {
  attendanceGroup: string = '';
  classes: string = '';
  date: string = '';
  sbdkfs: string = '';
  sbdksj: string = '';
  sbdkzt: string = '';
  type: string = '';
  xbdkfs: string = '';
  xbdksj: string = '';
  xbdkzt: string = '';
}

/** 源码 AttendanceIndex.AttendanceRecordByMonthBean.ErrorRecordBean */
export class AttendanceErrorRecordBean {
  errorDetailName: string = '';
  errorDetailTimes: string = '';
  errorDetailType: string = '';
}

/** 源码 AttendanceIndex.AttendanceRecordByMonthBean */
export class AttendanceRecordByMonthBean {
  attendanceByDay: AttendanceByDayBean[] = [];
  dayOfAttendance: string = '';
  days: string = '';
  errorRecord: AttendanceErrorRecordBean[] = [];
}

/** 源码 AttendanceIndex.java：GET index 响应（个人考勤月历） */
export class AttendanceIndex {
  attendanceRecordByMonth: AttendanceRecordByMonthBean = new AttendanceRecordByMonthBean();
}

/** 源码 AttendanceBossIndex.AttendanceListBean.PeopleListBean */
export class AttendancePeopleListBean {
  departmentName: string = '';
  imgUrl: string = '';
  times: string = '';
  userId: string = '';
  userName: string = '';
}

/** 源码 AttendanceBossIndex.AttendanceListBean（考勤组） */
export class AttendanceGroupBean {
  groupName: string = '';
  groupType: string = '';
  peopleList: AttendancePeopleListBean[] = [];
}

/** 源码 AttendanceBossIndex.java：GET bossIndex 响应（院系月份统计） */
export class AttendanceBossIndex {
  attendanceList: AttendanceGroupBean[] = [];
  date: string = '';
  num: string = '';
}
