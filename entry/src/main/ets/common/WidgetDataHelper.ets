import { preferences } from '@kit.ArkData';
import { Context } from '@kit.AbilityKit';
import { formBindingData, formProvider } from '@kit.FormKit';
import { CourseItem } from '../model/CourseModel';

export interface WidgetCourseSummary {
  name: string;
  time: string;
  place: string;
}

export interface CompactWidgetCourse {
  n: string;
  p: string;
  d: number;
  s: number;
  e: number;
  w: number;
  wk: string;
}

export interface WidgetGridCell {
  name: string;
  place: string;
  colorIdx: number;
  isToday: boolean;
}

const WIDGET_PREF_NAME = 'sdmu_widget_store';
const KEY_WEEK_LABEL = 'widget_week_label';
const KEY_COURSES_JSON = 'widget_courses_json';
const KEY_ALL_COURSES_JSON = 'widget_all_courses_json';
const KEY_CURRENT_WEEK = 'widget_current_week';
const KEY_MAX_WEEK = 'widget_max_week';
const KEY_FORM_IDS = 'widget_form_ids';

/**
 * 桌面服务卡片数据共享、周课表网格计算与交互刷新助手
 */
export class WidgetDataHelper {
  public static saveFormId(context: Context, formId: string): void {
    try {
      const store = preferences.getPreferencesSync(context, { name: WIDGET_PREF_NAME });
      const raw = store.getSync(KEY_FORM_IDS, '[]') as string;
      const ids: string[] = JSON.parse(raw) as string[];
      if (ids.indexOf(formId) < 0) {
        ids.push(formId);
        store.putSync(KEY_FORM_IDS, JSON.stringify(ids));
        store.flushSync();
      }
    } catch {
      // 忽略缓存读写异常
    }
  }

  public static removeFormId(context: Context, formId: string): void {
    try {
      const store = preferences.getPreferencesSync(context, { name: WIDGET_PREF_NAME });
      const raw = store.getSync(KEY_FORM_IDS, '[]') as string;
      const ids: string[] = (JSON.parse(raw) as string[]).filter((id: string) => id !== formId);
      store.putSync(KEY_FORM_IDS, JSON.stringify(ids));
      store.deleteSync('mode_' + formId);
      store.deleteSync('week_' + formId);
      store.deleteSync('day_' + formId);
      store.flushSync();
    } catch {
      // 忽略
    }
  }

  public static clampWeek(week: number, maxWeek: number): number {
    const safeMax: number = maxWeek > 0 ? maxWeek : 20;
    if (week < 1) {
      return 1;
    }
    if (week > safeMax) {
      return safeMax;
    }
    return week;
  }

  public static sectionToSlot(sectionStart: number): number {
    if (sectionStart <= 2) {
      return 0;
    }
    if (sectionStart <= 4) {
      return 1;
    }
    if (sectionStart <= 6) {
      return 2;
    }
    if (sectionStart <= 8) {
      return 3;
    }
    return 4;
  }

  private static hashCourseColor(name: string): number {
    let h: number = 0;
    for (let i = 0; i < name.length; i++) {
      h = (h * 31 + name.charCodeAt(i)) % 997;
    }
    return Math.abs(h) % 6;
  }

  private static parseIntSafe(text: string): number {
    let digits: string = '';
    for (let i = 0; i < text.length; i++) {
      const ch: string = text.charAt(i);
      if (ch >= '0' && ch <= '9') {
        digits += ch;
      }
    }
    return digits === '' ? 0 : Number(digits);
  }

  public static isCourseInWeek(c: CompactWidgetCourse, targetWeek: number): boolean {
    if (c.w > 0) {
      return c.w === targetWeek;
    }
    const raw: string = c.wk || '';
    if (raw === '') {
      return true;
    }
    const odd: boolean = raw.indexOf('单') >= 0;
    const even: boolean = raw.indexOf('双') >= 0;
    let cleaned: string = '';
    for (let i = 0; i < raw.length; i++) {
      const ch: string = raw.charAt(i);
      if ((ch >= '0' && ch <= '9') || ch === '-' || ch === ',' || ch === '~') {
        cleaned += ch;
      } else if (ch === '，' || ch === '、' || ch === '/') {
        cleaned += ',';
      }
    }
    const out: number[] = [];
    const tokens: string[] = cleaned.split(',');
    for (const token of tokens) {
      const seg: string = token.trim();
      if (seg.length === 0) {
        continue;
      }
      const dash: number = seg.indexOf('-');
      if (dash > 0) {
        const from: number = WidgetDataHelper.parseIntSafe(seg.substring(0, dash));
        const to: number = WidgetDataHelper.parseIntSafe(seg.substring(dash + 1));
        for (let i = from; i <= to; i++) {
          if (i >= 1 && !(odd && i % 2 === 0) && !(even && i % 2 === 1) && out.indexOf(i) < 0) {
            out.push(i);
          }
        }
      } else {
        const n: number = WidgetDataHelper.parseIntSafe(seg);
        if (n >= 1 && !(odd && n % 2 === 0) && !(even && n % 2 === 1) && out.indexOf(n) < 0) {
          out.push(n);
        }
      }
    }
    return out.length === 0 || out.indexOf(targetWeek) >= 0;
  }

  /** 保存全学期课表并刷新全部已添桌面卡片 */
  public static saveSemesterSchedule(
    context: Context,
    currentWeek: number,
    maxWeek: number,
    courses: CourseItem[]
  ): void {
    try {
      const store = preferences.getPreferencesSync(context, { name: WIDGET_PREF_NAME });
      const compact: CompactWidgetCourse[] = courses.map((c: CourseItem): CompactWidgetCourse => {
        return {
          n: c.name,
          p: c.location,
          d: c.dayOfWeek,
          s: c.sectionStart,
          e: c.sectionEnd,
          w: c.djz,
          wk: c.week
        };
      });
      store.putSync(KEY_ALL_COURSES_JSON, JSON.stringify(compact));
      store.putSync(KEY_CURRENT_WEEK, currentWeek > 0 ? currentWeek : 1);
      store.putSync(KEY_MAX_WEEK, maxWeek > 0 ? maxWeek : 20);
      store.flushSync();
      WidgetDataHelper.notifyAllForms(context);
    } catch {
      // 忽略
    }
  }

  /** 兼容旧调用：保存今日课程摘要 */
  public static saveTodaySchedule(context: Context, weekLabel: string, courses: WidgetCourseSummary[]): void {
    try {
      const store = preferences.getPreferencesSync(context, { name: WIDGET_PREF_NAME });
      const sliced = courses.slice(0, 4);
      store.putSync(KEY_WEEK_LABEL, weekLabel);
      store.putSync(KEY_COURSES_JSON, JSON.stringify(sliced));
      store.flushSync();
      WidgetDataHelper.notifyAllForms(context);
    } catch {
      // 忽略
    }
  }

  public static buildWeeklyFormPayload(
    weekNum: number,
    maxWeek: number,
    allCourses: CompactWidgetCourse[],
    mode: string,
    selectedDay: number,
    todayWeekday: number
  ): Record<string, Object> {
    const safeMax: number = maxWeek > 0 ? maxWeek : 20;
    const safeWeek: number = WidgetDataHelper.clampWeek(weekNum, safeMax);
    const safeToday: number = todayWeekday >= 1 && todayWeekday <= 7 ? todayWeekday : 1;
    const safeDay: number = selectedDay >= 1 && selectedDay <= 7 ? selectedDay : safeToday;
    const viewMode: string = mode === 'day' ? 'day' : 'week';

    const weekList: CompactWidgetCourse[] = [];
    let hasWeekend: boolean = false;
    let todayCount: number = 0;

    for (const c of allCourses) {
      if (WidgetDataHelper.isCourseInWeek(c, safeWeek)) {
        weekList.push(c);
        if (c.d >= 6) {
          hasWeekend = true;
        }
        if (c.d === safeToday) {
          todayCount++;
        }
      }
    }

    const gridCols: number = hasWeekend ? 7 : 5;
    const gridCells: WidgetGridCell[] = [];
    for (let slot = 0; slot < 5; slot++) {
      for (let day = 1; day <= gridCols; day++) {
        gridCells.push({
          name: '',
          place: '',
          colorIdx: -1,
          isToday: day === safeToday
        });
      }
    }

    for (const c of weekList) {
      if (c.d >= 1 && c.d <= gridCols) {
        const slot: number = WidgetDataHelper.sectionToSlot(c.s);
        const idx: number = slot * gridCols + (c.d - 1);
        if (idx >= 0 && idx < gridCells.length && gridCells[idx].name === '') {
          gridCells[idx] = {
            name: c.n,
            place: c.p,
            colorIdx: WidgetDataHelper.hashCourseColor(c.n),
            isToday: c.d === safeToday
          };
        }
      }
    }

    const dayListRaw: CompactWidgetCourse[] = weekList.filter((c: CompactWidgetCourse) => c.d === safeDay);
    dayListRaw.sort((a: CompactWidgetCourse, b: CompactWidgetCourse) => a.s - b.s);
    const dayCourses: WidgetCourseSummary[] = dayListRaw.slice(0, 6).map((c: CompactWidgetCourse): WidgetCourseSummary => {
      return {
        name: c.n,
        time: `第${c.s}-${c.e}节`,
        place: c.p
      };
    });

    const weekTitle: string = `第${safeWeek}周`;
    const summaryText: string = weekList.length > 0
      ? `第${safeWeek}周 · 本周${weekList.length}节课，今日${todayCount}节`
      : '暂无缓存课表，点击查看完整课表';

    const c1: WidgetCourseSummary | null = dayCourses.length > 0 ? dayCourses[0] : null;
    const c2: WidgetCourseSummary | null = dayCourses.length > 1 ? dayCourses[1] : null;
    const c3: WidgetCourseSummary | null = dayCourses.length > 2 ? dayCourses[2] : null;
    const c4: WidgetCourseSummary | null = dayCourses.length > 3 ? dayCourses[3] : null;

    return {
      'viewMode': viewMode,
      'weekNum': safeWeek,
      'maxWeek': safeMax,
      'weekTitle': weekTitle,
      'todayWeekday': safeToday,
      'selectedDay': safeDay,
      'gridCols': gridCols,
      'gridCells': gridCells,
      'dayCourses': dayCourses,
      'weekCourseCount': weekList.length,
      'todayCourseCount': todayCount,
      'title': weekTitle,
      'subtitle': summaryText,
      'courseCount': dayCourses.length,
      'c1Name': c1 ? c1.name : '',
      'c1Info': c1 ? `${c1.time} ${c1.place}`.trim() : '',
      'c2Name': c2 ? c2.name : '',
      'c2Info': c2 ? `${c2.time} ${c2.place}`.trim() : '',
      'c3Name': c3 ? c3.name : '',
      'c3Info': c3 ? `${c3.time} ${c3.place}`.trim() : '',
      'c4Name': c4 ? c4.name : '',
      'c4Info': c4 ? `${c4.time} ${c4.place}`.trim() : '',
      'cardTitle': '校园快捷入口'
    };
  }

  public static loadFormData(context: Context, formId: string = ''): Record<string, Object> {
    const jsDay: number = new Date().getDay();
    const todayWeekday: number = jsDay === 0 ? 7 : jsDay;
    let allCourses: CompactWidgetCourse[] = [];
    let currentWeek: number = 1;
    let maxWeek: number = 20;
    let mode: string = 'week';
    let weekNum: number = 1;
    let selectedDay: number = todayWeekday;

    try {
      const store = preferences.getPreferencesSync(context, { name: WIDGET_PREF_NAME });
      const rawAll = store.getSync(KEY_ALL_COURSES_JSON, '[]') as string;
      allCourses = JSON.parse(rawAll) as CompactWidgetCourse[];
      currentWeek = store.getSync(KEY_CURRENT_WEEK, 1) as number;
      maxWeek = store.getSync(KEY_MAX_WEEK, 20) as number;
      if (formId !== '') {
        mode = store.getSync('mode_' + formId, 'week') as string;
        weekNum = store.getSync('week_' + formId, currentWeek) as number;
        selectedDay = store.getSync('day_' + formId, todayWeekday) as number;
      } else {
        weekNum = currentWeek;
      }
    } catch {
      allCourses = [];
    }

    return WidgetDataHelper.buildWeeklyFormPayload(
      weekNum,
      maxWeek,
      allCourses,
      mode,
      selectedDay,
      todayWeekday
    );
  }

  /** 处理桌面卡片按钮交互：切周 / 切本周与今日视图 / 选星期 */
  public static handleFormEvent(context: Context, formId: string, message: string): void {
    try {
      const payload = JSON.parse(message) as Record<string, Object>;
      const action: string = typeof payload['action'] === 'string' ? payload['action'] as string : '';
      const store = preferences.getPreferencesSync(context, { name: WIDGET_PREF_NAME });
      const defaultWeek: number = store.getSync(KEY_CURRENT_WEEK, 1) as number;
      const maxWeek: number = store.getSync(KEY_MAX_WEEK, 20) as number;
      let weekNum: number = store.getSync('week_' + formId, defaultWeek) as number;

      if (action === 'prevWeek') {
        weekNum = WidgetDataHelper.clampWeek(weekNum - 1, maxWeek);
        store.putSync('week_' + formId, weekNum);
      } else if (action === 'nextWeek') {
        weekNum = WidgetDataHelper.clampWeek(weekNum + 1, maxWeek);
        store.putSync('week_' + formId, weekNum);
      } else if (action === 'setMode') {
        const mode: string = payload['mode'] === 'day' ? 'day' : 'week';
        store.putSync('mode_' + formId, mode);
      } else if (action === 'selectDay') {
        const dayVal = payload['day'];
        if (typeof dayVal === 'number' && dayVal >= 1 && dayVal <= 7) {
          store.putSync('day_' + formId, dayVal);
          store.putSync('mode_' + formId, 'day');
        }
      }
      store.flushSync();

      const nextData = WidgetDataHelper.loadFormData(context, formId);
      formProvider.updateForm(formId, formBindingData.createFormBindingData(nextData)).catch(() => {
        // 卡片已移除时忽略
      });
    } catch {
      // 忽略异常事件
    }
  }

  /** 兼容旧单测：直接构建今日摘要负载 */
  public static buildPayload(weekLabel: string, courses: WidgetCourseSummary[]): Record<string, Object> {
    const c1: WidgetCourseSummary | null = courses.length > 0 ? courses[0] : null;
    const c2: WidgetCourseSummary | null = courses.length > 1 ? courses[1] : null;
    const c3: WidgetCourseSummary | null = courses.length > 2 ? courses[2] : null;
    const c4: WidgetCourseSummary | null = courses.length > 3 ? courses[3] : null;
    return {
      'title': weekLabel !== '' ? weekLabel : '今日课表',
      'subtitle': courses.length === 0 ? '暂无今日课程，点击查看完整课表' : `今日共 ${courses.length} 节课程`,
      'courseCount': courses.length,
      'c1Name': c1 ? c1.name : '',
      'c1Info': c1 ? `${c1.time} ${c1.place}`.trim() : '',
      'c2Name': c2 ? c2.name : '',
      'c2Info': c2 ? `${c2.time} ${c2.place}`.trim() : '',
      'c3Name': c3 ? c3.name : '',
      'c3Info': c3 ? `${c3.time} ${c3.place}`.trim() : '',
      'c4Name': c4 ? c4.name : '',
      'c4Info': c4 ? `${c4.time} ${c4.place}`.trim() : '',
      'cardTitle': '校园快捷入口'
    };
  }

  private static notifyAllForms(context: Context): void {
    try {
      const store = preferences.getPreferencesSync(context, { name: WIDGET_PREF_NAME });
      const raw = store.getSync(KEY_FORM_IDS, '[]') as string;
      const ids: string[] = JSON.parse(raw) as string[];
      for (const id of ids) {
        const data = formBindingData.createFormBindingData(WidgetDataHelper.loadFormData(context, id));
        formProvider.updateForm(id, data).catch(() => {
          // 卡片已移除时忽略
        });
      }
    } catch {
      // 忽略
    }
  }
}
