import { liveViewManager } from '@kit.LiveViewKit';
import { Want, wantAgent } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { CourseItem } from '../model/CourseModel';

export interface LiveViewOpResult {
  ok: boolean;
  message: string;
}

export interface CourseTimeSlot {
  startMin: number;
  endMin: number;
  startText: string;
  endText: string;
}

export interface PickedCourseInfo {
  course: CourseItem;
  statusLabel: string;
  timeRange: string;
  keepMinutes: number;
}

const SECTION_TIMES: CourseTimeSlot[] = [
  { startMin: 8 * 60, endMin: 8 * 60 + 45, startText: '08:00', endText: '08:45' },
  { startMin: 8 * 60 + 55, endMin: 9 * 60 + 40, startText: '08:55', endText: '09:40' },
  { startMin: 10 * 60, endMin: 10 * 60 + 45, startText: '10:00', endText: '10:45' },
  { startMin: 10 * 60 + 55, endMin: 11 * 60 + 40, startText: '10:55', endText: '11:40' },
  { startMin: 14 * 60, endMin: 14 * 60 + 45, startText: '14:00', endText: '14:45' },
  { startMin: 14 * 60 + 55, endMin: 15 * 60 + 40, startText: '14:55', endText: '15:40' },
  { startMin: 16 * 60, endMin: 16 * 60 + 45, startText: '16:00', endText: '16:45' },
  { startMin: 16 * 60 + 55, endMin: 17 * 60 + 40, startText: '16:55', endText: '17:40' },
  { startMin: 19 * 60, endMin: 19 * 60 + 45, startText: '19:00', endText: '19:45' },
  { startMin: 19 * 60 + 55, endMin: 20 * 60 + 40, startText: '19:55', endText: '20:40' },
  { startMin: 20 * 60 + 50, endMin: 21 * 60 + 35, startText: '20:50', endText: '21:35' },
  { startMin: 21 * 60 + 45, endMin: 22 * 60 + 30, startText: '21:45', endText: '22:30' }
];

const COURSE_LIVE_VIEW_ID: number = 90101;

/**
 * 本地实况窗助手（LiveViewKit：课表实况胶囊 + 会议/考试倒计时胶囊）
 */
export class LiveViewIntentHelper {
  private static courseSeq: number = 1;

  public static sectionRangeText(sectionStart: number, sectionEnd: number): string {
    const sIdx: number = Math.max(0, Math.min(SECTION_TIMES.length - 1, sectionStart - 1));
    const eIdx: number = Math.max(sIdx, Math.min(SECTION_TIMES.length - 1, sectionEnd - 1));
    return SECTION_TIMES[sIdx].startText + '-' + SECTION_TIMES[eIdx].endText;
  }

  public static pickCurrentOrNextCourse(
    courses: CourseItem[],
    todayWeek: number,
    now: Date = new Date()
  ): PickedCourseInfo | null {
    const jsDay: number = now.getDay();
    const todayWeekday: number = jsDay === 0 ? 7 : jsDay;
    const nowMin: number = now.getHours() * 60 + now.getMinutes();

    const todayList: CourseItem[] = courses.filter((c: CourseItem) => {
      if (c.dayOfWeek !== todayWeekday) {
        return false;
      }
      if (c.djz > 0 && todayWeek > 0) {
        return c.djz === todayWeek;
      }
      return true;
    });
    todayList.sort((a: CourseItem, b: CourseItem) => a.sectionStart - b.sectionStart);

    for (const c of todayList) {
      const sIdx: number = Math.max(0, Math.min(SECTION_TIMES.length - 1, c.sectionStart - 1));
      const eIdx: number = Math.max(sIdx, Math.min(SECTION_TIMES.length - 1, c.sectionEnd - 1));
      const startMin: number = SECTION_TIMES[sIdx].startMin;
      const endMin: number = SECTION_TIMES[eIdx].endMin;
      const range: string = SECTION_TIMES[sIdx].startText + '-' + SECTION_TIMES[eIdx].endText;

      if (nowMin >= startMin && nowMin <= endMin) {
        return {
          course: c,
          statusLabel: '上课中',
          timeRange: range,
          keepMinutes: Math.max(15, endMin - nowMin + 5)
        };
      }
      if (startMin > nowMin) {
        const diff: number = startMin - nowMin;
        return {
          course: c,
          statusLabel: diff <= 30 ? '即将上课' : SECTION_TIMES[sIdx].startText,
          timeRange: range,
          keepMinutes: Math.min(180, Math.max(30, endMin - nowMin + 5))
        };
      }
    }
    return null;
  }

  private static async buildScheduleWantAgent(): Promise<Object | undefined> {
    try {
      const wantAgentInfo: wantAgent.WantAgentInfo = {
        wants: [
          {
            bundleName: 'com.sdmu.sdmuapplication',
            abilityName: 'EntryAbility',
            parameters: { targetPage: 'pages/SchedulePage' }
          } as Want
        ],
        actionType: wantAgent.OperationType.START_ABILITIES,
        requestCode: 90101,
        actionFlags: [wantAgent.WantAgentFlags.UPDATE_PRESENT_FLAG]
      };
      const agent = await wantAgent.getWantAgent(wantAgentInfo);
      return agent;
    } catch {
      return undefined;
    }
  }

  /** 启动或更新课表实况窗胶囊（状态栏 + 锁屏展示课程时间与教室） */
  public static async startCourseLiveView(
    course: CourseItem,
    statusLabel: string = ''
  ): Promise<LiveViewOpResult> {
    const timeRange: string = LiveViewIntentHelper.sectionRangeText(course.sectionStart, course.sectionEnd);
    const sIdx: number = Math.max(0, Math.min(SECTION_TIMES.length - 1, course.sectionStart - 1));
    const label: string = statusLabel !== '' ? statusLabel : SECTION_TIMES[sIdx].startText;
    const place: string = course.location !== '' ? course.location : '教室待定';
    const seq: number = LiveViewIntentHelper.courseSeq++;

    try {
      const clickAction = await LiveViewIntentHelper.buildScheduleWantAgent();
      const view: liveViewManager.LiveView = {
        id: COURSE_LIVE_VIEW_ID,
        event: 'QUEUE',
        sequence: seq,
        isMute: false,
        liveViewData: {
          primary: {
            title: course.name,
            content: [
              { text: timeRange + ' 第' + course.sectionStart + '-' + course.sectionEnd + '节' },
              { text: ' · ' + place, textColor: '#FF97000C' }
            ],
            keepTime: 60,
            clickAction: clickAction
          },
          capsule: {
            type: liveViewManager.CapsuleType.CAPSULE_TYPE_TEXT,
            status: 1,
            icon: '',
            title: label,
            content: course.name + ' · ' + place,
            backgroundColor: '#FF97000C'
          }
        }
      };
      try {
        await liveViewManager.startLiveView(view);
        return { ok: true, message: '已开启课表实况窗胶囊' };
      } catch (startErr) {
        const be = startErr as BusinessError;
        if (be.code === 1003500006) {
          await liveViewManager.updateLiveView(view);
          return { ok: true, message: '已更新课表实况窗胶囊' };
        }
        if (be.code === 1003500004 || be.code === 1003500005) {
          return { ok: false, message: '当前设备或签名暂未开启实况窗能力' };
        }
        return { ok: false, message: '实况窗启动失败：' + (be.message || String(be.code)) };
      }
    } catch {
      return { ok: false, message: '当前设备暂不支持实况窗服务' };
    }
  }

  /** 进入课表页时自动同步今日正在上/下一节课程到实况窗（失败静默降级） */
  public static async syncTodayCourseLiveView(courses: CourseItem[], todayWeek: number): Promise<void> {
    const picked: PickedCourseInfo | null = LiveViewIntentHelper.pickCurrentOrNextCourse(courses, todayWeek);
    if (picked === null) {
      return;
    }
    await LiveViewIntentHelper.startCourseLiveView(picked.course, picked.statusLabel);
  }

  /** 启动本地实况窗（如会议/考试倒计时） */
  public static async startLocalLiveView(
    id: number,
    title: string,
    contentText: string
  ): Promise<boolean> {
    try {
      const defaultView: liveViewManager.LiveView = {
        id: id,
        event: 'QUEUE',
        liveViewData: {
          primary: {
            title: title,
            content: [{ text: contentText }],
            keepTime: 15
          }
        }
      };
      await liveViewManager.startLiveView(defaultView);
      return true;
    } catch {
      return false;
    }
  }

  /** 结束本地实况窗 */
  public static async stopLocalLiveView(id: number): Promise<boolean> {
    try {
      const view: liveViewManager.LiveView = {
        id: id,
        event: 'QUEUE',
        liveViewData: {
          primary: {
            title: '',
            content: [{ text: '' }],
            keepTime: 0
          }
        }
      };
      await liveViewManager.stopLiveView(view);
      return true;
    } catch {
      return false;
    }
  }
}
