/**
 * 消息模块模型 — 逐行翻译原生实体（MessageListActivity + MessageFragment 数据流）：
 *   - MainNotificationV2 ← module/main/entity/MainNotificationV2.java
 *     {BATCHID, CONTENT, EXT, SENDBY, SENDTIME, STATE, TITLE, XLH, channelCode, isEmc, isSelected}
 *   - MessageExtAppBean ← AppBean/AppInfo 中消息跳转用字段子集
 *     （LX/URL/YYID/YYMC/xxTitle/xxContent/xxSender/xxTime；V2 的 EXT 字段是 AppBean 对象本身）
 *   STATE 语义（MessageFragment.d.onItemClick / f.g）：'1'=未读，'2'=已读
 * 请求源码实证（MessageModel.java module/main/g/e.java + MessageFactory.java module/main/e.java）：
 *   a()="api" b()="messageShow" c()="mobileapi_ydxy" ServerType.SCHOOL
 *   → /mobileapi_ydxy/api/messageShow/<name>
 */
export class MessageExtAppBean {
  /** AppInfo.LX（跳转类型：1原生路由 2/4/6/8 H5 5三方 7小程序 15浏览器 16消息详情） */
  LX: string = '';
  URL: string = '';
  YYID: string = '';
  YYMC: string = '';
  xxTitle: string = '';
  xxContent: string = '';
  xxSender: string = '';
  xxTime: string = '';

  static fromRecord(rec: Record<string, Object>): MessageExtAppBean {
    const bean: MessageExtAppBean = new MessageExtAppBean();
    const keys: string[] = ['LX', 'URL', 'YYID', 'YYMC', 'xxTitle', 'xxContent', 'xxSender', 'xxTime'];
    for (const key of keys) {
      const v: Object = rec[key];
      if (typeof v === 'string') {
        bean.setField(key, v as string);
      }
    }
    return bean;
  }

  setField(key: string, value: string): void {
    if (key === 'LX') { this.LX = value; } else if (key === 'URL') { this.URL = value; }
    else if (key === 'YYID') { this.YYID = value; } else if (key === 'YYMC') { this.YYMC = value; }
    else if (key === 'xxTitle') { this.xxTitle = value; } else if (key === 'xxContent') { this.xxContent = value; }
    else if (key === 'xxSender') { this.xxSender = value; } else if (key === 'xxTime') { this.xxTime = value; }
  }
}

export class MainNotificationV2 {
  BATCHID: string = '';
  CONTENT: string = '';
  /** EXT 为 AppBean 对象（MainNotificationV2.EXT 类型 AppBean；空对象=无跳转扩展） */
  EXT: MessageExtAppBean | null = null;
  SENDBY: string = '';
  SENDTIME: string = '';
  STATE: string = '';
  TITLE: string = '';
  XLH: string = '';
  channelCode: string = '';
  isEmc: number = 0;
  isSelected: boolean = false;

  static fromRecord(rec: Record<string, Object>): MainNotificationV2 {
    const row: MainNotificationV2 = new MainNotificationV2();
    const stringKeys: string[] = ['BATCHID', 'CONTENT', 'SENDBY', 'SENDTIME', 'STATE', 'TITLE', 'XLH', 'channelCode'];
    for (const key of stringKeys) {
      const v: Object = rec[key];
      if (typeof v === 'string') {
        row.setField(key, v as string);
      } else if (typeof v === 'number') {
        row.setField(key, String(v as number));
      }
    }
    const emc: Object = rec['isEmc'];
    if (typeof emc === 'number') {
      row.isEmc = emc as number;
    } else if (typeof emc === 'string') {
      const n: number = Number(emc as string);
      if (!Number.isNaN(n)) {
        row.isEmc = n;
      }
    }
    // EXT：对象形态（AppBean）；老接口字符串形态（MainNotification.EXT，EXT_PARAMS.DATA 内壳）按源码 getEXT() 逻辑解
    const ext: Object = rec['EXT'];
    if (typeof ext === 'object' && ext !== null) {
      row.EXT = MessageExtAppBean.fromRecord(ext as Record<string, Object>);
    } else if (typeof ext === 'string') {
      row.EXT = MainNotificationV2.parseExtString(ext as string);
    }
    return row;
  }

  /** 源码 MainNotification.getEXT()：EXT 字符串 → JSONObject.EXT_PARAMS.DATA → AppBean */
  private static parseExtString(extStr: string): MessageExtAppBean | null {
    if (extStr === '') {
      return null;
    }
    try {
      const outer: Object = JSON.parse(extStr) as Object;
      const outerRec: Record<string, Object> = outer as Record<string, Object>;
      const params: Object = outerRec['EXT_PARAMS'];
      if (typeof params !== 'object' || params === null) {
        return null;
      }
      const data: Object = (params as Record<string, Object>)['DATA'];
      if (typeof data !== 'object' || data === null) {
        return null;
      }
      return MessageExtAppBean.fromRecord(data as Record<string, Object>);
    } catch (error) {
      return null;
    }
  }

  setField(key: string, value: string): void {
    if (key === 'BATCHID') { this.BATCHID = value; } else if (key === 'CONTENT') { this.CONTENT = value; }
    else if (key === 'SENDBY') { this.SENDBY = value; } else if (key === 'SENDTIME') { this.SENDTIME = value; }
    else if (key === 'STATE') { this.STATE = value; } else if (key === 'TITLE') { this.TITLE = value; }
    else if (key === 'XLH') { this.XLH = value; } else if (key === 'channelCode') { this.channelCode = value; }
  }
}

/**
 * [W12 message-series] 校圈消息实体 — 逐字段翻译 push 模块（work/multimodule/push/entity）：
 *   - SocialPushMessageItem ← MessageItem.java {content, contentType, ext, id, readStatus, sendTime, state, title, type, url}
 *   - SocialPushMessageExt  ← MessageExt.java {circleId, circle_type, ext_params, likeTime, picture, pl_content, type, userId, userName, userType}
 *   - SocialPushMessageList ← MessageList.java {list: MessageItem[], timestamp}
 * 请求源码实证（PushModel.java c/b/c/b/b.java）：POST https://www.yibaogao.com/mobileapi/campus/push/<name>
 *   {type:"circle", page, pageSize:"20"} + 请求头 xxdm=登录会话 schoolId；响应 data 加密。
 * 2026-11-18 实测：该域名校园网不可达（https SSL EOF / http 502）→ 页面按失败走真实空态。
 */
export class SocialPushMessageExt {
  circleId: string = '';
  circle_type: string = '';
  likeTime: string = '';
  picture: string = '';
  pl_content: string = '';
  type: string = '';
  userId: string = '';
  userName: string = '';
  userType: string = '';

  static fromRecord(rec: Record<string, Object>): SocialPushMessageExt {
    const ext: SocialPushMessageExt = new SocialPushMessageExt();
    const keys: string[] = ['circleId', 'circle_type', 'likeTime', 'picture', 'pl_content', 'type', 'userId', 'userName', 'userType'];
    for (const key of keys) {
      const v: Object = rec[key];
      if (typeof v === 'string') {
        if (key === 'circleId') { ext.circleId = v as string; }
        else if (key === 'circle_type') { ext.circle_type = v as string; }
        else if (key === 'likeTime') { ext.likeTime = v as string; }
        else if (key === 'picture') { ext.picture = v as string; }
        else if (key === 'pl_content') { ext.pl_content = v as string; }
        else if (key === 'type') { ext.type = v as string; }
        else if (key === 'userId') { ext.userId = v as string; }
        else if (key === 'userName') { ext.userName = v as string; }
        else if (key === 'userType') { ext.userType = v as string; }
      }
    }
    return ext;
  }
}

export class SocialPushMessageItem {
  content: string = '';
  contentType: string = '';
  ext: SocialPushMessageExt | null = null;
  id: string = '';
  readStatus: string = '';
  sendTime: string = '';
  state: string = '';
  title: string = '';
  type: string = '';
  url: string = '';

  static fromRecord(rec: Record<string, Object>): SocialPushMessageItem {
    const row: SocialPushMessageItem = new SocialPushMessageItem();
    const keys: string[] = ['content', 'contentType', 'id', 'readStatus', 'sendTime', 'state', 'title', 'type', 'url'];
    for (const key of keys) {
      const v: Object = rec[key];
      if (typeof v === 'string') {
        if (key === 'content') { row.content = v as string; }
        else if (key === 'contentType') { row.contentType = v as string; }
        else if (key === 'id') { row.id = v as string; }
        else if (key === 'readStatus') { row.readStatus = v as string; }
        else if (key === 'sendTime') { row.sendTime = v as string; }
        else if (key === 'state') { row.state = v as string; }
        else if (key === 'title') { row.title = v as string; }
        else if (key === 'type') { row.type = v as string; }
        else if (key === 'url') { row.url = v as string; }
      }
    }
    const ext: Object = rec['ext'];
    if (typeof ext === 'object' && ext !== null) {
      row.ext = SocialPushMessageExt.fromRecord(ext as Record<string, Object>);
    }
    return row;
  }
}

/** SocialUserAvatarUtil 补头像链：SocialModel.J → GET getAvatarByUser {userIds:"a,b"} → UserTX[]{USERID, TX} */
export class SocialPushUserTx {
  USERID: string = '';
  TX: string = '';

  static fromRecord(rec: Record<string, Object>): SocialPushUserTx {
    const row: SocialPushUserTx = new SocialPushUserTx();
    const uid: Object = rec['USERID'];
    if (typeof uid === 'string') {
      row.USERID = uid as string;
    } else if (typeof uid === 'number') {
      row.USERID = String(uid as number);
    }
    const tx: Object = rec['TX'];
    if (typeof tx === 'string') {
      row.TX = tx as string;
    }
    return row;
  }
}

/**
 * SystemSwitch 消息开关子集 — 源码 GlobalParamInfo.getSystemSwitch() 的三个开关：
 *   messages_page_tabs（"2"=未读/已读双页签）、all_messages_read、all_messages_delete、
 *   batch_messages_delete（"1"=启用）。
 * HAP 与 ContactPage 同等现状：登录响应未下发/未持久化 SystemSwitch → 返回 null，
 * 等价源码 systemSwitch==null 分支（MessageListActivity.Q2/R2）。
 */
export class MessageSystemSwitch {
  messagesPageTabs: string = '';
  allMessagesRead: string = '';
  allMessagesDelete: string = '';
  batchMessagesDelete: string = '';

  static current(): MessageSystemSwitch | null {
    // 等价源码 systemSwitch==null：会话无该字段（ContactPage.ets 同款结论），开关全部视为未启用
    return null;
  }
}
