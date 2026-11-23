import { reminderAgentManager } from '@kit.BackgroundTasksKit';
import { calendarManager } from '@kit.CalendarKit';
import { common } from '@kit.AbilityKit';

/**
 * P3：系统代理提醒 + 系统日历写入助手
 * - 代理提醒：应用被杀掉后仍由系统准时触发（课前/考试提醒）
 * - 系统日历：用户手动触发写入个人日程
 */
export class ReminderCalendarHelper {
  /** 发布单次日历代理提醒，返回 reminderId；失败返回 -1 */
  public static async publishCalendarReminder(
    title: string,
    content: string,
    triggerDate: Date
  ): Promise<number> {
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
      return await reminderAgentManager.publishReminder(req);
    } catch {
      return -1;
    }
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

  /** 写入系统日历事件 */
  public static async addCalendarEvent(
    context: common.UIAbilityContext,
    title: string,
    description: string,
    startTimeMs: number,
    endTimeMs: number,
    location?: string
  ): Promise<boolean> {
    try {
      const mgr: calendarManager.CalendarManager = calendarManager.getCalendarManager(context);
      const calendar: calendarManager.Calendar = await mgr.getCalendar();
      const event: calendarManager.Event = {
        type: calendarManager.EventType.NORMAL,
        title: title,
        description: description,
        startTime: startTimeMs,
        endTime: endTimeMs,
        location: location ? { location: location } : undefined
      };
      await calendar.addEvent(event);
      return true;
    } catch {
      return false;
    }
  }
}
