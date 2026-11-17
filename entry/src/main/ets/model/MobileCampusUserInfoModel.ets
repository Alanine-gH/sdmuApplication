/**
 * MobileCampusUserInfo — 1:1 对应原 APK
 * com.lysoft.android.report.mobile_campus.module.my.getuserinfo.entity.MobileCampusUserInfo
 * 数据源：POST /mobileapi_ydxy/api/user/getUserInfo（AES 加密，响应解密后 JSON 直映射）
 * 源码依据：PersonalDetailNewActivity.c3()/d3() 学生/教师资料渲染字段。
 */
export class MobileCampusUserInfo {
  userName: string = '';
  nickname: string = '';
  userId: string = '';
  userType: string = '';
  department: string = '';
  professionName: string = '';
  className: string = '';
  grade: string = '';
  commonAccount: string = '';
  bindQq: string = '';
  bindWechat: string = '';
  bindMobile: string = '';
  email: string = '';
  avatar: string = '';
  sex: string = '';
  schoolName: string = '';

  /** 从服务器解密 JSON 记录填充（仅拷贝已知字段，未知名忽略） */
  static fromRecord(rec: Record<string, Object>): MobileCampusUserInfo {
    const u = new MobileCampusUserInfo();
    const pick = (k: string): string => {
      const v: Object | undefined = rec[k];
      return typeof v === 'string' ? v as string : '';
    };
    u.userName = pick('userName');
    u.nickname = pick('nickname');
    u.userId = pick('userId');
    u.userType = pick('userType');
    u.department = pick('department');
    u.professionName = pick('professionName');
    u.className = pick('className');
    u.grade = pick('grade');
    u.commonAccount = pick('commonAccount');
    u.bindQq = pick('bindQq');
    u.bindWechat = pick('bindWechat');
    u.bindMobile = pick('bindMobile');
    u.email = pick('email');
    u.avatar = pick('avatar');
    u.sex = pick('sex');
    u.schoolName = pick('schoolName');
    return u;
  }
}
