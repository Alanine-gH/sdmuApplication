import { reminderAgentManager } from '@kit.BackgroundTasksKit';
import { notificationManager } from '@kit.NotificationKit';
import { calendarManager } from '@kit.CalendarKit';
import { abilityAccessCtrl, bundleManager, common, PermissionRequestResult, Permissions } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';

export interface ReminderValidationResult {
  valid: boolean;
  reason: string;
}

export interface CalendarRangeValidationResult {
  valid: boolean;
  normalizedEndMs: number;
  reason: string;
}

export interface ReminderOpResult {
  success: boolean;
  reminderId: number;
  permissionDenied: boolean;
  message: string;
}

export interface CalendarOpResult {
  success: boolean;
  eventId: number;
  permissionDenied: boolean;
  message: string;
}

export interface CourseTimeWindow {
  startMs: number;
  endMs: number;
  reminderMs: number;
  label: string;
}

export interface PermissionCheckResult {
  granted: boolean;
  message: string;
}

export interface NotificationCheckResult {
  enabled: boolean;
  message: string;
}

interface ClockRange {
  startHour: number;
  startMinute: number;
  endHour: number;
  endMinute: number;
}

const SECTION_START_TIMES: string[] = [
  '08:00', '08:55', '10:00', '10:55', '14:00', '14:55',
  '16:00', '16:55', '19:00', '19:55', '20:50', '21:45'
];
const CALENDAR_PERMISSIONS: Permissions[] = [
  'ohos.permission.READ_CALENDAR',
  'ohos.permission.WRITE_CALENDAR'
];
const DEFAULT_COURSE_DURATION_MIN: number = 90;
const SINGLE_SECTION_DURATION_MIN: number = 45;

/**
 * 系统代理提醒 + 系统日历写入助手
 * - 代理提醒：应用被杀掉后仍由系统准时触发（课前/考试/日程提醒）
 * - 系统日历：动态申请日历权限后写入个人日程，返回结构化结果与可读降级提示
 */
export class ReminderCalendarHelper {
  /** 纯函数：校验提醒时间是否为有效未来时间 */
  public static validateReminderDate(triggerDate: Date, nowMs: number = Date.now()): ReminderValidationResult {
    if (!triggerDate || Number.isNaN(triggerDate.getTime())) {
      return { valid: false, reason: '提醒时间格式无效' };
    }
    if (triggerDate.getTime() <= nowMs) {
      return { valid: false, reason: '提醒时间需晚于当前时间' };
    }
    return { valid: true, reason: '' };
  }

  /** 纯函数：校验并规范化日历事件时间区间 */
  public static validateCalendarRange(startTimeMs: number, endTimeMs: number): CalendarRangeValidationResult {
    if (!Number.isFinite(startTimeMs) || startTimeMs <= 0) {
      return { valid: false, normalizedEndMs: 0, reason: '开始时间无效' };
    }
    const normalizedEndMs: number = (!Number.isFinite(endTimeMs) || endTimeMs <= startTimeMs)
      ? startTimeMs + 3600000
      : endTimeMs;
    return { valid: true, normalizedEndMs: normalizedEndMs, reason: '' };
  }

  /** 纯函数：计算考试前提醒触发时间（默认提前 60 分钟，不足则回退至考前 5 分钟；已过期返回 -1） */
  public static computeExamReminderTriggerMs(
    examStartMs: number,
    leadMinutes: number = 60,
    nowMs: number = Date.now()
  ): number {
    if (!Number.isFinite(examStartMs) || examStartMs <= nowMs) {
      return -1;
    }
    const safeLead: number = leadMinutes > 0 ? leadMinutes : 60;
    const preferredMs: number = examStartMs - safeLead * 60 * 1000;
    if (preferredMs > nowMs) {
      return preferredMs;
    }
    const fallbackMs: number = examStartMs - 5 * 60 * 1000;
    if (fallbackMs > nowMs) {
      return fallbackMs;
    }
    return -1;
  }

  /** 纯函数：解析课程下一次上课起止时间及 15 分钟前提醒时间 */
  public static computeNextCourseWindow(
    xqj: string,
    session: string,
    classtime: string,
    now: Date = new Date()
  ): CourseTimeWindow | null {
    const weekday: number = ReminderCalendarHelper.resolveWeekday(xqj, session);
    if (weekday < 1 || weekday > 7) {
      return null;
    }

    const range = ReminderCalendarHelper.resolveClockRange(classtime, session);
    if (range === null) {
      return null;
    }

    const jsDay: number = now.getDay();
    const todayWeekday: number = jsDay === 0 ? 7 : jsDay;
    const deltaDays: number = (weekday - todayWeekday + 7) % 7;

    const startDate: Date = new Date(
      now.getFullYear(),
      now.getMonth(),
      now.getDate() + deltaDays,
      range.startHour,
      range.startMinute,
      0,
      0
    );
    if (startDate.getTime() <= now.getTime()) {
      startDate.setDate(startDate.getDate() + 7);
    }

    const endDate: Date = new Date(
      startDate.getFullYear(),
      startDate.getMonth(),
      startDate.getDate(),
      range.endHour,
      range.endMinute,
      0,
      0
    );
    const startMs: number = startDate.getTime();
    const endMs: number = endDate.getTime() > startMs
      ? endDate.getTime()
      : startMs + DEFAULT_COURSE_DURATION_MIN * 60 * 1000;
    const reminderMs: number = startMs - 15 * 60 * 1000;

    const pad = (n: number): string => n < 10 ? '0' + String(n) : String(n);
    const label: string = `${startDate.getMonth() + 1}月${startDate.getDate()}日 ${pad(startDate.getHours())}:${pad(startDate.getMinutes())}`;

    return {
      startMs: startMs,
      endMs: endMs,
      reminderMs: reminderMs,
      label: label
    };
  }

  private static resolveWeekday(xqj: string, session: string): number {
    const trimmedXqj: string = (xqj || '').trim();
    if (/^[1-7]$/.test(trimmedXqj)) {
      return Number(trimmedXqj);
    }
    const combined: string = `${trimmedXqj} ${session || ''}`;
    const cnMap: Record<string, number> = {
      '周一': 1, '星期一': 1,
      '周二': 2, '星期二': 2,
      '周三': 3, '星期三': 3,
      '周四': 4, '星期四': 4,
      '周五': 5, '星期五': 5,
      '周六': 6, '星期六': 6,
      '周日': 7, '周天': 7, '星期日': 7, '星期天': 7
    };
    const keys: string[] = Object.keys(cnMap);
    for (const k of keys) {
      if (combined.indexOf(k) >= 0) {
        return cnMap[k];
      }
    }
    return 0;
  }

  private static resolveClockRange(
    classtime: string,
    session: string
  ): ClockRange | null {
    const timeText: string = (classtime || '').trim();
    const rangeMatch: RegExpMatchArray | null =
      timeText.match(/(\d{1,2}):(\d{2})\s*[-~至\u2013\u2014]+\s*(\d{1,2}):(\d{2})/);
    if (rangeMatch !== null) {
      const sh: number = Number(rangeMatch[1]);
      const sm: number = Number(rangeMatch[2]);
      const eh: number = Number(rangeMatch[3]);
      const em: number = Number(rangeMatch[4]);
      if (sh <= 23 && sm <= 59 && eh <= 23 && em <= 59) {
        return { startHour: sh, startMinute: sm, endHour: eh, endMinute: em };
      }
    }

    const singleMatch: RegExpMatchArray | null = timeText.match(/(\d{1,2}):(\d{2})/);
    if (singleMatch !== null) {
      const sh: number = Number(singleMatch[1]);
      const sm: number = Number(singleMatch[2]);
      if (sh <= 23 && sm <= 59) {
        const endTotal: number = sh * 60 + sm + DEFAULT_COURSE_DURATION_MIN;
        return {
          startHour: sh,
          startMinute: sm,
          endHour: Math.floor(endTotal / 60) % 24,
          endMinute: endTotal % 60
        };
      }
    }

    const secText: string = (session || '').trim();
    const secRange: RegExpMatchArray | null = secText.match(/(\d{1,2})\s*[-~至\u2013\u2014]+\s*(\d{1,2})/);
    let startSec: number = 0;
    let endSec: number = 0;
    if (secRange !== null) {
      startSec = Number(secRange[1]);
      endSec = Number(secRange[2]);
    } else {
      const secSingle: RegExpMatchArray | null = secText.match(/(\d{1,2})\s*节/);
      if (secSingle !== null) {
        startSec = Number(secSingle[1]);
        endSec = startSec;
      }
    }

    if (startSec >= 1 && startSec <= SECTION_START_TIMES.length) {
      const safeEndSec: number = Math.min(Math.max(endSec, startSec), SECTION_START_TIMES.length);
      const startParts: string[] = SECTION_START_TIMES[startSec - 1].split(':');
      const endStartParts: string[] = SECTION_START_TIMES[safeEndSec - 1].split(':');
      const sh: number = Number(startParts[0]);
      const sm: number = Number(startParts[1]);
      const endTotalMin: number = Number(endStartParts[0]) * 60 + Number(endStartParts[1]) + SINGLE_SECTION_DURATION_MIN;
      return {
        startHour: sh,
        startMinute: sm,
        endHour: Math.floor(endTotalMin / 60) % 24,
        endMinute: endTotalMin % 60
      };
    }

    return null;
  }

  /** 纯函数：将系统提醒/日历错误码映射为清晰提示 */
  public static formatReminderError(code: number, fallbackMsg?: string): string {
    if (code === 201) {
      return '未获得系统提醒或日历权限，请在设置中授权后重试';
    }
    if (code === 1700001) {
      return '系统通知未开启，请先允许应用发送通知';
    }
    if (code === 1700002) {
      return '系统提醒数量已达上限，请清理旧提醒后重试';
    }
    if (code === 23900004) {
      return '系统日历服务暂不可用，请稍后重试';
    }
    if (code === 401) {
      return '提醒或日程参数无效';
    }
    if (fallbackMsg !== undefined && fallbackMsg !== '') {
      return fallbackMsg;
    }
    return '操作失败，当前设备可能不支持该系统服务';
  }

  /** 检查并动态申请系统日历读写权限 */
  public static async ensureCalendarPermissions(
    context: common.UIAbilityContext
  ): Promise<PermissionCheckResult> {
    if (!context) {
      return { granted: false, message: '缺少应用上下文，无法申请日历权限' };
    }
    try {
      const atManager: abilityAccessCtrl.AtManager = abilityAccessCtrl.createAtManager();
      const bundleInfo: bundleManager.BundleInfo = bundleManager.getBundleInfoForSelfSync(
        bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_APPLICATION
      );
      const tokenId: number = bundleInfo.appInfo.accessTokenId;
      const missing: Permissions[] = [];
      for (const perm of CALENDAR_PERMISSIONS) {
        const status: abilityAccessCtrl.GrantStatus = atManager.checkAccessTokenSync(tokenId, perm);
        if (status !== abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED) {
          missing.push(perm);
        }
      }
      if (missing.length === 0) {
        return { granted: true, message: '' };
      }
      const result: PermissionRequestResult = await atManager.requestPermissionsFromUser(context, missing);
      const allGranted: boolean = result.authResults.length > 0 &&
        result.authResults.every((res: number) => res === 0);
      if (allGranted) {
        return { granted: true, message: '' };
      }
      return {
        granted: false,
        message: '未授予日历读写权限，请在系统设置中允许访问日历'
      };
    } catch (err) {
      const be = err as BusinessError;
      return {
        granted: false,
        message: ReminderCalendarHelper.formatReminderError(be.code ?? -1, '日历权限申请失败')
      };
    }
  }

  /** 确保系统通知已开启（publishReminder 依赖 notificationManager 授权） */
  public static async ensureNotificationEnabled(
    context?: common.UIAbilityContext
  ): Promise<NotificationCheckResult> {
    try {
      const enabled: boolean = await notificationManager.isNotificationEnabled();
      if (enabled) {
        return { enabled: true, message: '' };
      }
      if (context) {
        await notificationManager.requestEnableNotification(context);
        const rechecked: boolean = await notificationManager.isNotificationEnabled();
        if (rechecked) {
          return { enabled: true, message: '' };
        }
      }
      return {
        enabled: false,
        message: '未开启通知权限，无法发送后台提醒'
      };
    } catch (err) {
      const be = err as BusinessError;
      return {
        enabled: false,
        message: ReminderCalendarHelper.formatReminderError(be.code ?? 1700001, '通知权限检查失败')
      };
    }
  }

  /** 发布单次日历代理提醒并返回结构化结果 */
  public static async publishCalendarReminderWithResult(
    title: string,
    content: string,
    triggerDate: Date,
    context?: common.UIAbilityContext
  ): Promise<ReminderOpResult> {
    const check = ReminderCalendarHelper.validateReminderDate(triggerDate);
    if (!check.valid) {
      return {
        success: false,
        reminderId: -1,
        permissionDenied: false,
        message: check.reason
      };
    }

    const notifyCheck = await ReminderCalendarHelper.ensureNotificationEnabled(context);
    if (!notifyCheck.enabled) {
      return {
        success: false,
        reminderId: -1,
        permissionDenied: true,
        message: notifyCheck.message
      };
    }

    try {
      const req: reminderAgentManager.ReminderRequestCalendar = {
        reminderType: reminderAgentManager.ReminderType.REMINDER_TYPE_CALENDAR,
        dateTime: {
          year: triggerDate.getFullYear(),
          month: triggerDate.getMonth() + 1,
          day: triggerDate.getDate(),
          hour: triggerDate.getHours(),
          minute: triggerDate.getMinutes(),
          second: 0
        },
        title: title,
        content: content,
        snoozeTimes: 1,
        timeInterval: 5 * 60
      };
      const id: number = await reminderAgentManager.publishReminder(req);
      return {
        success: true,
        reminderId: id,
        permissionDenied: false,
        message: '已设置系统提醒'
      };
    } catch (err) {
      const be = err as BusinessError;
      const code: number = be.code ?? -1;
      return {
        success: false,
        reminderId: -1,
        permissionDenied: code === 201 || code === 1700001,
        message: ReminderCalendarHelper.formatReminderError(code, '设置系统提醒失败')
      };
    }
  }

  /** 兼容旧调用：发布单次日历代理提醒，返回 reminderId；失败返回 -1 */
  public static async publishCalendarReminder(
    title: string,
    content: string,
    triggerDate: Date,
    context?: common.UIAbilityContext
  ): Promise<number> {
    const res = await ReminderCalendarHelper.publishCalendarReminderWithResult(title, content, triggerDate, context);
    return res.success ? res.reminderId : -1;
  }

  /** 取消代理提醒 */
  public static async cancelReminder(reminderId: number): Promise<boolean> {
    if (reminderId < 0) {
      return false;
    }
    try {
      await reminderAgentManager.cancelReminder(reminderId);
      return true;
    } catch {
      return false;
    }
  }

  /** 写入系统日历事件并返回结构化结果 */
  public static async addCalendarEventWithResult(
    context: common.UIAbilityContext,
    title: string,
    description: string,
    startTimeMs: number,
    endTimeMs: number,
    location?: string,
    reminderMinutes?: number[]
  ): Promise<CalendarOpResult> {
    const rangeCheck = ReminderCalendarHelper.validateCalendarRange(startTimeMs, endTimeMs);
    if (!rangeCheck.valid) {
      return {
        success: false,
        eventId: -1,
        permissionDenied: false,
        message: rangeCheck.reason
      };
    }

    const permCheck = await ReminderCalendarHelper.ensureCalendarPermissions(context);
    if (!permCheck.granted) {
      return {
        success: false,
        eventId: -1,
        permissionDenied: true,
        message: permCheck.message
      };
    }

    try {
      const mgr: calendarManager.CalendarManager = calendarManager.getCalendarManager(context);
      const calendar: calendarManager.Calendar = await mgr.getCalendar();
      const event: calendarManager.Event = {
        type: calendarManager.EventType.NORMAL,
        title: title,
        description: description,
        startTime: startTimeMs,
        endTime: rangeCheck.normalizedEndMs,
        location: location && location !== '' ? { location: location } : undefined,
        reminderTime: reminderMinutes && reminderMinutes.length > 0 ? reminderMinutes : [15]
      };
      const eventId: number = await calendar.addEvent(event);
      return {
        success: true,
        eventId: eventId,
        permissionDenied: false,
        message: '已添加到系统日历'
      };
    } catch (err) {
      const be = err as BusinessError;
      const code: number = be.code ?? -1;
      return {
        success: false,
        eventId: -1,
        permissionDenied: code === 201,
        message: ReminderCalendarHelper.formatReminderError(code, '写入系统日历失败')
      };
    }
  }

  /** 兼容旧调用：写入系统日历事件 */
  public static async addCalendarEvent(
    context: common.UIAbilityContext,
    title: string,
    description: string,
    startTimeMs: number,
    endTimeMs: number,
    location?: string
  ): Promise<boolean> {
    const res = await ReminderCalendarHelper.addCalendarEventWithResult(
      context, title, description, startTimeMs, endTimeMs, location
    );
    return res.success;
  }
}
