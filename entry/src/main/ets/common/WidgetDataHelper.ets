import { preferences } from '@kit.ArkData';
import { Context } from '@kit.AbilityKit';
import { formBindingData, formProvider } from '@kit.FormKit';

export interface WidgetCourseSummary {
  name: string;
  time: string;
  place: string;
}

const WIDGET_PREF_NAME = 'sdmu_widget_store';
const KEY_WEEK_LABEL = 'widget_week_label';
const KEY_COURSES_JSON = 'widget_courses_json';
const KEY_FORM_IDS = 'widget_form_ids';

/**
 * 桌面服务卡片数据共享与刷新助手
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
      store.flushSync();
    } catch {
      // 忽略
    }
  }

  public static saveTodaySchedule(context: Context, weekLabel: string, courses: WidgetCourseSummary[]): void {
    try {
      const store = preferences.getPreferencesSync(context, { name: WIDGET_PREF_NAME });
      const sliced = courses.slice(0, 4);
      store.putSync(KEY_WEEK_LABEL, weekLabel);
      store.putSync(KEY_COURSES_JSON, JSON.stringify(sliced));
      store.flushSync();
      WidgetDataHelper.notifyAllForms(context, weekLabel, sliced);
    } catch {
      // 忽略
    }
  }

  public static loadFormData(context: Context): Record<string, Object> {
    let weekLabel = '今日课表';
    let courses: WidgetCourseSummary[] = [];
    try {
      const store = preferences.getPreferencesSync(context, { name: WIDGET_PREF_NAME });
      weekLabel = store.getSync(KEY_WEEK_LABEL, '今日课表') as string;
      const raw = store.getSync(KEY_COURSES_JSON, '[]') as string;
      courses = JSON.parse(raw) as WidgetCourseSummary[];
    } catch {
      courses = [];
    }
    return WidgetDataHelper.buildPayload(weekLabel, courses);
  }

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

  private static notifyAllForms(context: Context, weekLabel: string, courses: WidgetCourseSummary[]): void {
    try {
      const store = preferences.getPreferencesSync(context, { name: WIDGET_PREF_NAME });
      const raw = store.getSync(KEY_FORM_IDS, '[]') as string;
      const ids: string[] = JSON.parse(raw) as string[];
      const data = formBindingData.createFormBindingData(WidgetDataHelper.buildPayload(weekLabel, courses));
      for (const id of ids) {
        formProvider.updateForm(id, data).catch(() => {
          // 卡片已移除时忽略
        });
      }
    } catch {
      // 忽略
    }
  }
}
