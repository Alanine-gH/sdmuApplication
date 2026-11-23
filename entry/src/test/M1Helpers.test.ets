import { describe, it, expect } from '@ohos/hypium';
import { BreakpointSystem, CreaseRegionVp } from '../main/ets/common/BreakpointSystem';
import { AdaptiveLayoutHelper } from '../main/ets/common/AdaptiveLayoutHelper';
import { ReminderCalendarHelper } from '../main/ets/common/ReminderCalendarHelper';
import { PasteHelper } from '../main/ets/common/PasteHelper';
import { PrivacyWindowHelper } from '../main/ets/common/PrivacyWindowHelper';
import { WidgetDataHelper } from '../main/ets/common/WidgetDataHelper';

export default function m1HelpersTest() {
  describe('m1HelpersTest', () => {
    it('breakpointSystemExtendedWidthAndHeight', 0, () => {
      expect(BreakpointSystem.computeBreakpoint(280)).assertEqual('xs');
      expect(BreakpointSystem.computeBreakpoint(319)).assertEqual('xs');
      expect(BreakpointSystem.computeBreakpoint(320)).assertEqual('sm');
      expect(BreakpointSystem.computeBreakpoint(599)).assertEqual('sm');
      expect(BreakpointSystem.computeBreakpoint(600)).assertEqual('md');
      expect(BreakpointSystem.computeBreakpoint(839)).assertEqual('md');
      expect(BreakpointSystem.computeBreakpoint(840)).assertEqual('lg');
      expect(BreakpointSystem.computeBreakpoint(1439)).assertEqual('lg');
      expect(BreakpointSystem.computeBreakpoint(1440)).assertEqual('xl');

      expect(BreakpointSystem.computeHeightBreakpoint(800, 500)).assertEqual('sm');
      expect(BreakpointSystem.computeHeightBreakpoint(800, 800)).assertEqual('md');
      expect(BreakpointSystem.computeHeightBreakpoint(400, 800)).assertEqual('lg');
      expect(BreakpointSystem.computeHeightBreakpoint(0, 800)).assertEqual('sm');

      expect(BreakpointSystem.computeAspectRatio(400, 800)).assertEqual(2);
      expect(BreakpointSystem.computeAspectRatio(0, 800)).assertEqual(0);

      expect(BreakpointSystem.shouldUseSideRail('lg', 'lg', false)).assertTrue();
      expect(BreakpointSystem.shouldUseSideRail('xl', 'md', false)).assertTrue();
      expect(BreakpointSystem.shouldUseSideRail('sm', 'sm', true)).assertTrue();
      expect(BreakpointSystem.shouldUseSideRail('md', 'sm', false)).assertTrue();
      expect(BreakpointSystem.shouldUseSideRail('sm', 'lg', false)).assertFalse();
      expect(BreakpointSystem.shouldUseSideRail('md', 'md', false)).assertFalse();

      expect(BreakpointSystem.isCompactWidth('xs')).assertTrue();
      expect(BreakpointSystem.isCompactWidth('sm')).assertTrue();
      expect(BreakpointSystem.isCompactWidth('md')).assertFalse();

      expect(BreakpointSystem.mapWidthBreakpoint(0)).assertEqual('xs');
      expect(BreakpointSystem.mapWidthBreakpoint(4)).assertEqual('xl');
      expect(BreakpointSystem.mapHeightBreakpoint(0)).assertEqual('sm');
      expect(BreakpointSystem.mapHeightBreakpoint(2)).assertEqual('lg');

      expect(BreakpointSystem.getContentMaxWidth('xs')).assertEqual('100%');
      expect(BreakpointSystem.getContentMaxWidth('xl')).assertEqual(1200);
      expect(BreakpointSystem.getAppGridColumns('xs')).assertEqual(3);
      expect(BreakpointSystem.getAppGridColumns('xl')).assertEqual(10);
      expect(BreakpointSystem.getListColumns('md')).assertEqual(1);
      expect(BreakpointSystem.getListColumns('xl')).assertEqual(2);
      expect(BreakpointSystem.getGridColumns('xs', 4)).assertEqual(3);
      expect(BreakpointSystem.getGridColumns('lg', 4)).assertEqual(8);
    });

    it('breakpointSystemDialogGestureAndCrease', 0, () => {
      expect(BreakpointSystem.getDialogMaxWidth('sm', 360)).assertEqual(328);
      expect(BreakpointSystem.getDialogMaxWidth('lg', 1200)).assertEqual(560);
      expect(BreakpointSystem.getDialogMaxHeight(800)).assertEqual(656);
      expect(BreakpointSystem.computeGestureGridSize(360, 780)).assertEqual(312);
      expect(BreakpointSystem.computeGestureGridSize(900, 400)).assertEqual(180);

      expect(BreakpointSystem.pxToVpWithDensity(300, 3)).assertEqual(100);
      expect(BreakpointSystem.pxToVpWithDensity(-10, 3)).assertEqual(0);
      const crease = BreakpointSystem.convertCreaseRectToVp(0, 900, 2100, 60, 3);
      expect(crease !== null).assertTrue();
      if (crease !== null) {
        expect(crease.top).assertEqual(300);
        expect(crease.width).assertEqual(700);
        expect(crease.height).assertEqual(20);
      }
      expect(BreakpointSystem.convertCreaseRectToVp(0, 0, 0, 0, 3) === null).assertTrue();
    });

    it('adaptiveLayoutHelperPureChecks', 0, () => {
      expect(AdaptiveLayoutHelper.buildColumnsTemplate(1)).assertEqual('1fr');
      expect(AdaptiveLayoutHelper.buildColumnsTemplate(4)).assertEqual('1fr 1fr 1fr 1fr');
      expect(AdaptiveLayoutHelper.buildColumnsTemplate(0)).assertEqual('1fr');

      expect(AdaptiveLayoutHelper.shouldUseCenterSheet('sm', false)).assertFalse();
      expect(AdaptiveLayoutHelper.shouldUseCenterSheet('sm', true)).assertTrue();
      expect(AdaptiveLayoutHelper.shouldUseCenterSheet('md', false)).assertTrue();
      expect(AdaptiveLayoutHelper.getSheetMaxWidth('sm', 390)).assertEqual('100%');
      expect(AdaptiveLayoutHelper.getSheetMaxWidth('md', 760)).assertEqual(520);
      expect(AdaptiveLayoutHelper.getSheetMaxWidth('lg', 1200)).assertEqual(600);

      const phonePane = AdaptiveLayoutHelper.getSplitPaneConfig('sm', 390);
      expect(phonePane.useTwoPane).assertFalse();
      const tabletPane = AdaptiveLayoutHelper.getSplitPaneConfig('lg', 1200);
      expect(tabletPane.useTwoPane).assertTrue();
      expect(tabletPane.masterRatio).assertEqual(2);
      expect(tabletPane.detailRatio).assertEqual(3);

      expect(AdaptiveLayoutHelper.isHalfFoldedStatus(3)).assertTrue();
      expect(AdaptiveLayoutHelper.isHalfFoldedStatus(1)).assertFalse();
      const crease: CreaseRegionVp = { left: 0, top: 300, width: 700, height: 24 };
      expect(AdaptiveLayoutHelper.shouldAvoidCrease(crease, 3)).assertTrue();
      expect(AdaptiveLayoutHelper.getCreaseAvoidHeightVp(crease, 3)).assertEqual(24);
      expect(AdaptiveLayoutHelper.getCreaseAvoidHeightVp(crease, 1)).assertEqual(0);
    });

    it('reminderCalendarHelperPureChecks', 0, () => {
      const nowMs: number = 1700000000000;
      const pastCheck = ReminderCalendarHelper.validateReminderDate(new Date(nowMs - 1000), nowMs);
      expect(pastCheck.valid).assertFalse();
      const futureCheck = ReminderCalendarHelper.validateReminderDate(new Date(nowMs + 60000), nowMs);
      expect(futureCheck.valid).assertTrue();

      const badRange = ReminderCalendarHelper.validateCalendarRange(0, 1000);
      expect(badRange.valid).assertFalse();
      const normRange = ReminderCalendarHelper.validateCalendarRange(nowMs, nowMs);
      expect(normRange.valid).assertTrue();
      expect(normRange.normalizedEndMs).assertEqual(nowMs + 3600000);

      const examFar = ReminderCalendarHelper.computeExamReminderTriggerMs(nowMs + 120 * 60000, 60, nowMs);
      expect(examFar).assertEqual(nowMs + 60 * 60000);
      const examNear = ReminderCalendarHelper.computeExamReminderTriggerMs(nowMs + 20 * 60000, 60, nowMs);
      expect(examNear).assertEqual(nowMs + 15 * 60000);
      const examExpired = ReminderCalendarHelper.computeExamReminderTriggerMs(nowMs - 1000, 60, nowMs);
      expect(examExpired).assertEqual(-1);

      // 2026-11-23 is Monday (day=1)
      const refNow: Date = new Date(2026, 10, 23, 7, 30, 0, 0);
      const w1 = ReminderCalendarHelper.computeNextCourseWindow('3', '周三 1-2节', '08:00 - 09:40', refNow);
      expect(w1 !== null).assertTrue();
      if (w1 !== null) {
        expect(w1.startMs > refNow.getTime()).assertTrue();
        expect(w1.endMs - w1.startMs).assertEqual(100 * 60000);
        expect(w1.reminderMs).assertEqual(w1.startMs - 15 * 60000);
      }

      const w2 = ReminderCalendarHelper.computeNextCourseWindow('', '周一 1-2节', '', refNow);
      expect(w2 !== null).assertTrue();
      if (w2 !== null) {
        expect(w2.startMs > refNow.getTime()).assertTrue();
        expect(w2.reminderMs).assertEqual(w2.startMs - 15 * 60000);
      }

      const wNull = ReminderCalendarHelper.computeNextCourseWindow('', '', '', refNow);
      expect(wNull === null).assertTrue();

      expect(ReminderCalendarHelper.formatReminderError(201)).assertContain('权限');
      expect(ReminderCalendarHelper.formatReminderError(1700001)).assertContain('通知');
      expect(ReminderCalendarHelper.formatReminderError(1700002)).assertContain('上限');
      expect(ReminderCalendarHelper.formatReminderError(23900004)).assertContain('日历');
    });

    it('pasteHelperPureChecks', 0, () => {
      expect(PasteHelper.normalizePastedText('  hello\r\nworld  ')).assertEqual('hello\nworld');
      expect(PasteHelper.normalizeSingleLine('  foo\nbar\tbaz  ', 7)).assertEqual('foo bar');

      const merged1 = PasteHelper.mergeContentWithLimit('', '反馈内容', 300);
      expect(merged1.text).assertEqual('反馈内容');
      expect(merged1.truncated).assertFalse();

      let longText: string = '';
      for (let i = 0; i < 310; i++) {
        longText += 'a';
      }
      const merged2 = PasteHelper.mergeContentWithLimit('前缀', longText, 300);
      expect(merged2.text.length).assertEqual(300);
      expect(merged2.truncated).assertTrue();

      expect(PasteHelper.isHttpUrl('https://www.sdmu.edu.cn')).assertTrue();
      expect(PasteHelper.isHttpUrl('http://mcp.sdmu.edu.cn:8081')).assertTrue();
      expect(PasteHelper.isHttpUrl('javascript:alert(1)')).assertFalse();
      expect(PasteHelper.isHttpUrl('普通文本')).assertFalse();

      expect(PasteHelper.extractTextFromPasteData('首选', 'https://a.cn', '备选')).assertEqual('首选');
      expect(PasteHelper.extractTextFromPasteData('', 'https://a.cn', '备选')).assertEqual('备选');
      expect(PasteHelper.extractTextFromPasteData('', 'https://a.cn', '')).assertEqual('https://a.cn');
    });

    it('privacyWindowHelperPureAndRefCount', 0, async () => {
      expect(PrivacyWindowHelper.computeTargetPrivacyMode(true, 1)).assertTrue();
      expect(PrivacyWindowHelper.computeTargetPrivacyMode(true, 2)).assertTrue();
      expect(PrivacyWindowHelper.computeTargetPrivacyMode(true, 0)).assertFalse();
      expect(PrivacyWindowHelper.computeTargetPrivacyMode(false, 2)).assertFalse();

      expect(PrivacyWindowHelper.normalizePrivacyFlag(undefined, true)).assertTrue();
      expect(PrivacyWindowHelper.normalizePrivacyFlag('true', false)).assertTrue();
      expect(PrivacyWindowHelper.normalizePrivacyFlag('false', true)).assertFalse();
      expect(PrivacyWindowHelper.normalizePrivacyFlag(0, true)).assertFalse();

      expect(PrivacyWindowHelper.isSensitivePageName('LoginPage')).assertTrue();
      expect(PrivacyWindowHelper.isSensitivePageName('PhoneLoginPage')).assertTrue();
      expect(PrivacyWindowHelper.isSensitivePageName('GesturePwdVerifyPage')).assertTrue();
      expect(PrivacyWindowHelper.isSensitivePageName('GesturePwdSettingPage')).assertTrue();
      expect(PrivacyWindowHelper.isSensitivePageName('ModifyPasswordPage')).assertTrue();
      expect(PrivacyWindowHelper.isSensitivePageName('PersonalDetailPage')).assertTrue();
      expect(PrivacyWindowHelper.isSensitivePageName('ReceiptDetailPage')).assertTrue();
      expect(PrivacyWindowHelper.isSensitivePageName('Index')).assertFalse();
      expect(PrivacyWindowHelper.isSensitivePageName('SettingPage')).assertFalse();

      PrivacyWindowHelper.resetStateForTest(true);
      const r1 = await PrivacyWindowHelper.enterSensitivePage('LoginPage');
      expect(r1.activeCount).assertEqual(1);
      expect(r1.privacyMode).assertTrue();
      const r2 = await PrivacyWindowHelper.enterSensitivePage('PhoneLoginPage');
      expect(r2.activeCount).assertEqual(2);
      const r3 = await PrivacyWindowHelper.leaveSensitivePage('LoginPage');
      expect(r3.activeCount).assertEqual(1);
      expect(r3.privacyMode).assertTrue();
      const r4 = await PrivacyWindowHelper.leaveSensitivePage('PhoneLoginPage');
      expect(r4.activeCount).assertEqual(0);
      expect(r4.privacyMode).assertFalse();
      PrivacyWindowHelper.resetStateForTest(null);
    });

    it('widgetWantBuildersPureChecks', 0, () => {
      const scheduleWant = WidgetDataHelper.buildScheduleWidgetWant();
      expect(scheduleWant.bundleName).assertEqual('com.sdmu.sdmuapplication');
      expect(scheduleWant.abilityName).assertEqual('EntryFormAbility');
      const sParams = scheduleWant.parameters as Record<string, Object>;
      expect(sParams['ohos.extra.param.key.module_name']).assertEqual('entry');
      expect(sParams['ohos.extra.param.key.form_name']).assertEqual('schedule_widget');
      expect(sParams['ohos.extra.param.key.form_dimension']).assertEqual(4);

      const quickWant = WidgetDataHelper.buildQuickEntryWidgetWant();
      const qParams = quickWant.parameters as Record<string, Object>;
      expect(qParams['ohos.extra.param.key.form_name']).assertEqual('quick_entry_widget');
      expect(qParams['ohos.extra.param.key.form_dimension']).assertEqual(2);

      const fallbackWant = WidgetDataHelper.buildFormManagerWant('', 0);
      const fParams = fallbackWant.parameters as Record<string, Object>;
      expect(fParams['ohos.extra.param.key.form_name']).assertEqual('schedule_widget');
      expect(fParams['ohos.extra.param.key.form_dimension']).assertEqual(4);
    });
  });
}
