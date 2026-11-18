/**
 * [W20 social] 校圈链实体 — 1:1 对应原 APK social 包实体（INotProguard Gson 模型字段名保真）：
 *   - SocialPost    ← social/social/entity/PostListEntity.java（MarketItemEntity 空继承同构）
 *   - SocialComment ← social/social/entity/CommentInfo.java（评论主条）
 *   - SocialSubComment ← social/social/entity/CommentList.java（评论子回复）
 *   - SocialLike    ← social/social/entity/LikeInfo.java
 *   - UserScore     ← social/market/entity/UserScore.java（竞价积分）
 *   - SocialUserInfo ← getuserinfo/entity/UserInfo.java 消费字段（键名按 2026-11-18 getUserInfo
 *     实测响应：userName/nickname/sex/userType/department/professionName/className/avatar/…）
 *   - SocialUserTx  ← social/social/entity/UserTX.java（getAvatarByUser 补链 {TX,USERID}）
 * 解析走 ApiService.pick（string|number→string，null→''），零编造：字段缺失即空串。
 */
import { ApiService } from '../network/ApiService';

export class SocialPost {
  id: string = '';
  userId: string = '';
  userName: string = '';
  nickName: string = '';
  userType: string = '';
  userSchool: string = '';
  avatar: string = '';
  unit: string = '';
  content: string = '';
  pictures: string = '';
  originalPictures: string = '';
  isOldData: string = '';
  publishTime: string = '';
  serversTime: string = '';
  commentNum: string = '0';
  likeNum: string = '0';
  isLike: string = '0';
  hotTop: string = '0';
  freshTop: string = '0';
  marketStatus: string = '0';
  marketTop: string = '0';
  marketType: string = '';
  type: string = '';
  status: string = '';

  static fromRecord(rec: Record<string, Object>): SocialPost {
    const p = new SocialPost();
    p.id = ApiService.pick(rec, ['id']);
    p.userId = ApiService.pick(rec, ['userId']);
    p.userName = ApiService.pick(rec, ['userName']);
    p.nickName = ApiService.pick(rec, ['nickName', 'nickname']);
    p.userType = ApiService.pick(rec, ['userType']);
    p.userSchool = ApiService.pick(rec, ['userSchool', 'schoolId']);
    p.avatar = ApiService.pick(rec, ['avatar']);
    p.unit = ApiService.pick(rec, ['unit']);
    p.content = ApiService.pick(rec, ['content']);
    p.pictures = ApiService.pick(rec, ['pictures']);
    p.originalPictures = ApiService.pick(rec, ['originalPictures']);
    p.isOldData = ApiService.pick(rec, ['isOldData']);
    p.publishTime = ApiService.pick(rec, ['publishTime']);
    p.serversTime = ApiService.pick(rec, ['serversTime']);
    p.commentNum = ApiService.pick(rec, ['commentNum']);
    p.likeNum = ApiService.pick(rec, ['likeNum']);
    p.isLike = ApiService.pick(rec, ['isLike']) === '' ? '0' : ApiService.pick(rec, ['isLike']);
    p.hotTop = ApiService.pick(rec, ['hotTop']) === '' ? '0' : ApiService.pick(rec, ['hotTop']);
    p.freshTop = ApiService.pick(rec, ['freshTop']) === '' ? '0' : ApiService.pick(rec, ['freshTop']);
    p.marketStatus = ApiService.pick(rec, ['marketStatus']) === '' ? '0' : ApiService.pick(rec, ['marketStatus']);
    p.marketTop = ApiService.pick(rec, ['marketTop']) === '' ? '0' : ApiService.pick(rec, ['marketTop']);
    p.marketType = ApiService.pick(rec, ['marketType']);
    p.type = ApiService.pick(rec, ['type']);
    p.status = ApiService.pick(rec, ['status']);
    return p;
  }

  static listFrom(rows: Object[]): SocialPost[] {
    const list: SocialPost[] = [];
    for (const row of rows) {
      list.push(SocialPost.fromRecord(row as Record<string, Object>));
    }
    return list;
  }

  /** 展示名：源码 G3()/CommentAdapter —— 昵称空或"小奕的粉丝"回退 userName */
  displayName(): string {
    if (this.nickName === '' || this.nickName === '小奕的粉丝') {
      return this.userName;
    }
    return this.nickName;
  }

  /** 源码 H3()：图片串逗号分隔 → 数组（最多 9 图） */
  pictureList(): string[] {
    if (this.pictures === '') {
      return [];
    }
    const parts: string[] = this.pictures.split(',');
    const out: string[] = [];
    for (let i = 0; i < parts.length && i < 9; i++) {
      if (parts[i] !== '') {
        out.push(parts[i]);
      }
    }
    return out;
  }
}

export class SocialSubComment {
  id: string = '';
  circleId: string = '';
  commentId: string = '';
  commentTime: string = '';
  content: string = '';
  nickName: string = '';
  status: string = '';
  targetNickName: string = '';
  targetUserId: string = '';
  targetUserName: string = '';
  targetUserType: string = '';
  targetUserSchool: string = '';
  unit: string = '';
  userId: string = '';
  userName: string = '';
  userSchool: string = '';
  userType: string = '';

  static fromRecord(rec: Record<string, Object>): SocialSubComment {
    const c = new SocialSubComment();
    c.id = ApiService.pick(rec, ['id']);
    c.circleId = ApiService.pick(rec, ['circleId']);
    c.commentId = ApiService.pick(rec, ['commentId']);
    c.commentTime = ApiService.pick(rec, ['commentTime']);
    c.content = ApiService.pick(rec, ['content']);
    c.nickName = ApiService.pick(rec, ['nickName', 'nickname']);
    c.status = ApiService.pick(rec, ['status']);
    c.targetNickName = ApiService.pick(rec, ['targetNickName']);
    c.targetUserId = ApiService.pick(rec, ['targetUserId']);
    c.targetUserName = ApiService.pick(rec, ['targetUserName']);
    c.targetUserType = ApiService.pick(rec, ['targetUserType']);
    c.targetUserSchool = ApiService.pick(rec, ['targetUserSchool']);
    c.unit = ApiService.pick(rec, ['unit']);
    c.userId = ApiService.pick(rec, ['userId']);
    c.userName = ApiService.pick(rec, ['userName']);
    c.userSchool = ApiService.pick(rec, ['userSchool']);
    c.userType = ApiService.pick(rec, ['userType']);
    return c;
  }

  displayName(): string {
    if (this.nickName === '' || this.nickName === '小奕的粉丝') {
      return this.userName;
    }
    return this.nickName;
  }
}

export class SocialComment {
  id: string = '';
  circleId: string = '';
  commentId: string = '';
  commentTime: string = '';
  content: string = '';
  nickName: string = '';
  serversTime: string = '';
  status: string = '';
  unit: string = '';
  userId: string = '';
  userName: string = '';
  userSchool: string = '';
  userType: string = '';
  targetUserId: string = '';
  targetUserType: string = '';
  targetUserSchool: string = '';
  targetUnit: string = '';
  subList: SocialSubComment[] = [];

  static fromRecord(rec: Record<string, Object>): SocialComment {
    const c = new SocialComment();
    c.id = ApiService.pick(rec, ['id']);
    c.circleId = ApiService.pick(rec, ['circleId']);
    c.commentId = ApiService.pick(rec, ['commentId']);
    c.commentTime = ApiService.pick(rec, ['commentTime']);
    c.content = ApiService.pick(rec, ['content']);
    c.nickName = ApiService.pick(rec, ['nickName', 'nickname']);
    c.serversTime = ApiService.pick(rec, ['serversTime']);
    c.status = ApiService.pick(rec, ['status']);
    c.unit = ApiService.pick(rec, ['unit']);
    c.userId = ApiService.pick(rec, ['userId']);
    c.userName = ApiService.pick(rec, ['userName']);
    c.userSchool = ApiService.pick(rec, ['userSchool']);
    c.userType = ApiService.pick(rec, ['userType']);
    c.targetUserId = ApiService.pick(rec, ['targetUserId']);
    c.targetUserType = ApiService.pick(rec, ['targetUserType']);
    c.targetUserSchool = ApiService.pick(rec, ['targetUserSchool']);
    c.targetUnit = ApiService.pick(rec, ['targetUnit']);
    const subs: Object[] = ApiService.extractArray(rec['subList'] ?? new Object());
    for (const sub of subs) {
      c.subList.push(SocialSubComment.fromRecord(sub as Record<string, Object>));
    }
    return c;
  }

  static listFrom(rows: Object[]): SocialComment[] {
    // 源码 PostDetailPresenter d/e.g()：status=="1"（已屏蔽）的主条与子条均剔除
    const list: SocialComment[] = [];
    for (const row of rows) {
      const c = SocialComment.fromRecord(row as Record<string, Object>);
      if (c.status === '1') {
        continue;
      }
      const kept: SocialSubComment[] = [];
      for (const sub of c.subList) {
        if (sub.status !== '1') {
          kept.push(sub);
        }
      }
      c.subList = kept;
      list.push(c);
    }
    return list;
  }

  displayName(): string {
    if (this.nickName === '' || this.nickName === '小奕的粉丝') {
      return this.userName;
    }
    return this.nickName;
  }
}

export class SocialLike {
  id: string = '';
  circleId: string = '';
  nickName: string = '';
  status: string = '';
  unit: string = '';
  userId: string = '';
  userName: string = '';
  userSchool: string = '';
  userType: string = '';

  static listFrom(rows: Object[]): SocialLike[] {
    const list: SocialLike[] = [];
    for (const row of rows) {
      const rec: Record<string, Object> = row as Record<string, Object>;
      const l = new SocialLike();
      l.id = ApiService.pick(rec, ['id']);
      l.circleId = ApiService.pick(rec, ['circleId']);
      l.nickName = ApiService.pick(rec, ['nickName', 'nickname']);
      l.status = ApiService.pick(rec, ['status']);
      l.unit = ApiService.pick(rec, ['unit']);
      l.userId = ApiService.pick(rec, ['userId']);
      l.userName = ApiService.pick(rec, ['userName']);
      l.userSchool = ApiService.pick(rec, ['userSchool']);
      l.userType = ApiService.pick(rec, ['userType']);
      list.push(l);
    }
    return list;
  }

  /** 源码 E3()：点赞人名链，"小奕的粉丝"剔除、空昵称回退 userName */
  displayName(): string {
    if (this.nickName === '' || this.nickName === '小奕的粉丝') {
      return this.userName;
    }
    return this.nickName;
  }
}

export class UserScore {
  existTop: string = '';
  usableScores: string = '0';
  minUnitprice: string = '0';
  scoresRole: string = '';
  bidDuration: string = '';
  bidUnitPrice: string = '';

  static fromRecord(rec: Record<string, Object>): UserScore {
    const u = new UserScore();
    u.existTop = ApiService.pick(rec, ['existTop']);
    u.usableScores = ApiService.pick(rec, ['usableScores']);
    u.minUnitprice = ApiService.pick(rec, ['minUnitprice']);
    u.scoresRole = ApiService.pick(rec, ['scoresRole']);
    const min: Record<string, Object> =
      (rec['minScores'] ?? {}) as Record<string, Object>;
    u.bidDuration = ApiService.pick(min, ['bidduration']);
    u.bidUnitPrice = ApiService.pick(min, ['bidunitprice']);
    return u;
  }
}

export class SocialUserInfo {
  userId: string = '';
  userName: string = '';
  nickname: string = '';
  sex: string = '';
  userType: string = '';
  department: string = '';
  professionName: string = '';
  className: string = '';
  avatar: string = '';
  schoolName: string = '';
  noteName: string = '';

  /** 键名按 2026-11-18 getUserInfo 实测响应（nickname/professionName/department 为服务器键） */
  static fromRecord(rec: Record<string, Object>): SocialUserInfo {
    const u = new SocialUserInfo();
    u.userId = ApiService.pick(rec, ['userId']);
    u.userName = ApiService.pick(rec, ['userName']);
    u.nickname = ApiService.pick(rec, ['nickname']);
    u.sex = ApiService.pick(rec, ['sex']);
    u.userType = ApiService.pick(rec, ['userType']);
    u.department = ApiService.pick(rec, ['department']);
    u.professionName = ApiService.pick(rec, ['professionName']);
    u.className = ApiService.pick(rec, ['className']);
    u.avatar = ApiService.pick(rec, ['avatar']);
    u.schoolName = ApiService.pick(rec, ['schoolName']);
    return u;
  }

  /** 源码 u()：r = 昵称空回退真实姓名 */
  displayName(): string {
    return this.nickname === '' ? this.userName : this.nickname;
  }
}

export class SocialUserTx {
  userId: string = '';
  tx: string = '';

  static listFrom(rows: Object[]): Map<string, string> {
    const map: Map<string, string> = new Map();
    for (const row of rows) {
      const rec: Record<string, Object> = row as Record<string, Object>;
      const uid = ApiService.pick(rec, ['USERID']);
      const tx = ApiService.pick(rec, ['TX']);
      if (uid !== '') {
        map.set(uid, tx);
      }
    }
    return map;
  }
}
