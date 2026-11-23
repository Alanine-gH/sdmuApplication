import { describe, beforeAll, beforeEach, afterEach, afterAll, it, expect } from '@ohos/hypium';
import { BreakpointSystem } from '../main/ets/common/BreakpointSystem';
import { WidgetDataHelper, CompactWidgetCourse, WidgetGridCell, WidgetCourseSummary } from '../main/ets/common/WidgetDataHelper';

export default function localUnitTest() {
  describe('localUnitTest', () => {
    // Defines a test suite. Two parameters are supported: test suite name and test suite function.
    beforeAll(() => {
      // Presets an action, which is performed only once before all test cases of the test suite start.
      // This API supports only one parameter: preset action function.
    });
    beforeEach(() => {
      // Presets an action, which is performed before each unit test case starts.
      // The number of execution times is the same as the number of test cases defined by **it**.
      // This API supports only one parameter: preset action function.
    });
    afterEach(() => {
      // Presets a clear action, which is performed after each unit test case ends.
      // The number of execution times is the same as the number of test cases defined by **it**.
      // This API supports only one parameter: clear action function.
    });
    afterAll(() => {
      // Presets a clear action, which is performed after all test cases of the test suite end.
      // This API supports only one parameter: clear action function.
    });
    it('assertContain', 0, () => {
      let a = 'abc';
      let b = 'b';
      expect(a).assertContain(b);
      expect(a).assertEqual(a);
    });
    it('breakpointSystemCompute', 0, () => {
      expect(BreakpointSystem.computeBreakpoint(360)).assertEqual('sm');
      expect(BreakpointSystem.computeBreakpoint(599)).assertEqual('sm');
      expect(BreakpointSystem.computeBreakpoint(600)).assertEqual('md');
      expect(BreakpointSystem.computeBreakpoint(839)).assertEqual('md');
      expect(BreakpointSystem.computeBreakpoint(840)).assertEqual('lg');
      expect(BreakpointSystem.getContentMaxWidth('sm')).assertEqual('100%');
      expect(BreakpointSystem.getContentMaxWidth('md')).assertEqual(720);
      expect(BreakpointSystem.getContentMaxWidth('lg')).assertEqual(1080);
      expect(BreakpointSystem.getAppGridColumns('sm')).assertEqual(4);
      expect(BreakpointSystem.getAppGridColumns('md')).assertEqual(6);
      expect(BreakpointSystem.getAppGridColumns('lg')).assertEqual(8);
    });
    it('widgetPayloadBuild', 0, () => {
      const emptyPayload = WidgetDataHelper.buildPayload('第12周·今日课表', []);
      expect(emptyPayload['courseCount']).assertEqual(0);
      expect(emptyPayload['title']).assertEqual('第12周·今日课表');
      const onePayload = WidgetDataHelper.buildPayload('第12周·今日课表', [
        { name: '操作系统', time: '第1-2节', place: '信工楼302' }
      ]);
      expect(onePayload['courseCount']).assertEqual(1);
      expect(onePayload['c1Name']).assertEqual('操作系统');
      expect(onePayload['c1Info']).assertEqual('第1-2节 信工楼302');
    });
    it('weeklyWidgetGridAndFilter', 0, () => {
      const courses: CompactWidgetCourse[] = [
        { n: '数据结构', p: 'A101', d: 1, s: 1, e: 2, w: 3, wk: '1-16' },
        { n: '大学英语', p: 'B202', d: 1, s: 5, e: 6, w: 3, wk: '1-16' },
        { n: '线性代数', p: 'C303', d: 3, s: 3, e: 4, w: 0, wk: '1-16(单)' }
      ];
      // 第3周仅周一~周五有课 → 5列×5行=25格
      const w3 = WidgetDataHelper.buildWeeklyFormPayload(3, 20, courses, 'week', 1, 1);
      expect(w3['gridCols']).assertEqual(5);
      const cells3 = w3['gridCells'] as WidgetGridCell[];
      expect(cells3.length).assertEqual(25);
      expect(cells3[0].name).assertEqual('数据结构');
      expect(cells3[1 * 5 + 2].name).assertEqual('线性代数');
      expect(w3['weekCourseCount']).assertEqual(3);

      // 日视图按节次排序
      const dayCourses = w3['dayCourses'] as WidgetCourseSummary[];
      expect(dayCourses.length).assertEqual(2);
      expect(dayCourses[0].name).assertEqual('数据结构');
      expect(dayCourses[1].name).assertEqual('大学英语');

      // 第4周（双周）：djz=3 与 单周课程均不显示
      const w4 = WidgetDataHelper.buildWeeklyFormPayload(4, 20, courses, 'week', 1, 1);
      expect(w4['weekCourseCount']).assertEqual(0);

      // 含周六课程 → 自动扩展为 7 列（35 格）
      const withWeekend: CompactWidgetCourse[] = [
        { n: '创新实践', p: '实训楼', d: 6, s: 1, e: 2, w: 5, wk: '' }
      ];
      const w5 = WidgetDataHelper.buildWeeklyFormPayload(5, 20, withWeekend, 'week', 6, 6);
      expect(w5['gridCols']).assertEqual(7);
      expect((w5['gridCells'] as WidgetGridCell[]).length).assertEqual(35);
      expect(WidgetDataHelper.clampWeek(0, 20)).assertEqual(1);
      expect(WidgetDataHelper.clampWeek(25, 20)).assertEqual(20);
    });
  });
}