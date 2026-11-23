import { describe, beforeAll, beforeEach, afterEach, afterAll, it, expect } from '@ohos/hypium';
import { BreakpointSystem } from '../main/ets/common/BreakpointSystem';

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
  });
}