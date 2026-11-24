import { describe, it, expect } from '@ohos/hypium';
import {
  VisionEnhancementHelper,
  DEFAULT_VISION_SEARCH_SCOPE,
  VisionSearchMatchItem,
  VisionCaptionCandidate
} from '../main/ets/common/VisionEnhancementHelper';
import {
  PerformanceSchedulerHelper,
  FAST_SCENE_APP_LAUNCH,
  FAST_SCENE_PAGE_LOAD,
  FAST_STATE_BEGIN,
  FAST_STATE_END,
  FAST_DURATION_SHORT,
  FAST_DURATION_MEDIUM,
  FAST_DURATION_LONG
} from '../main/ets/common/PerformanceSchedulerHelper';
import {
  HoldingHandHelper,
  HOLDING_HAND_NOT_HELD,
  HOLDING_HAND_LEFT,
  HOLDING_HAND_RIGHT,
  HOLDING_HAND_BOTH,
  HOLDING_HAND_UNKNOWN
} from '../main/ets/common/HoldingHandHelper';
import { WidgetDataHelper } from '../main/ets/common/WidgetDataHelper';
import { ImmersiveLightHelper } from '../main/ets/common/ImmersiveLightHelper';

export default function m4HelpersTest() {
  describe('m4HelpersTest', () => {
    it('visionEnhancementHelperPureChecks', 0, async () => {
      // Scope sanitization (1..32 alphanumeric)
      expect(VisionEnhancementHelper.sanitizeSearchScope('')).assertEqual(DEFAULT_VISION_SEARCH_SCOPE);
      expect(VisionEnhancementHelper.sanitizeSearchScope('---')).assertEqual(DEFAULT_VISION_SEARCH_SCOPE);
      expect(VisionEnhancementHelper.sanitizeSearchScope('campus_2026!@#')).assertEqual('campus2026');
      const longScope = 'a'.repeat(50);
      expect(VisionEnhancementHelper.sanitizeSearchScope(longScope).length).assertEqual(32);

      // Query sanitization (1..100)
      expect(VisionEnhancementHelper.sanitizeSearchQuery('   ')).assertEqual('');
      expect(VisionEnhancementHelper.sanitizeSearchQuery('  图书馆晚霞  ')).assertEqual('图书馆晚霞');
      expect(VisionEnhancementHelper.sanitizeSearchQuery('x'.repeat(120)).length).assertEqual(100);

      // Image path validation (1..128)
      expect(VisionEnhancementHelper.isValidImagePathForIndex('')).assertFalse();
      expect(VisionEnhancementHelper.isValidImagePathForIndex('/data/storage/el2/base/cache/a.jpg')).assertTrue();
      expect(VisionEnhancementHelper.isValidImagePathForIndex('p'.repeat(129))).assertFalse();

      // Super-resolution eligibility
      expect(VisionEnhancementHelper.isEligibleForSuperResolution(32, 32)).assertFalse();
      expect(VisionEnhancementHelper.isEligibleForSuperResolution(800, 600)).assertTrue();
      expect(VisionEnhancementHelper.isEligibleForSuperResolution(5000, 3000)).assertFalse();

      // DocumentScanner originalUris size constraints
      expect(VisionEnhancementHelper.validateDocScanOriginalUriSize(200, 500)).assertFalse();
      expect(VisionEnhancementHelper.validateDocScanOriginalUriSize(1200, 1600)).assertTrue();
      expect(VisionEnhancementHelper.validateDocScanOriginalUriSize(1000, 3500)).assertFalse();

      // Filter and rank search results
      const rawItems: VisionSearchMatchItem[] = [
        { imagePath: '/cache/img1.jpg', scope: 'sdmu', similarity: 0.42 },
        { imagePath: '/cache/img2.jpg', scope: 'sdmu', similarity: 0.88 },
        { imagePath: '/cache/img1.jpg', scope: 'sdmu', similarity: 0.91 },
        { imagePath: '/cache/img3.jpg', scope: 'sdmu', similarity: 0.01 }
      ];
      const ranked = VisionEnhancementHelper.filterAndRankSearchResults(rawItems, 0.1, 10);
      expect(ranked.length).assertEqual(2);
      expect(ranked[0].imagePath).assertEqual('/cache/img2.jpg');
      expect(ranked[1].imagePath).assertEqual('/cache/img1.jpg');

      // Caption fallback matching
      const candidates: VisionCaptionCandidate[] = [
        { id: '101', title: '秋日图书馆', imagePath: '/a.jpg' },
        { id: '102', title: '教学楼晨光', imagePath: '/b.jpg' }
      ];
      const matched = VisionEnhancementHelper.matchCaptionsFallback('图书馆', candidates);
      expect(matched.length).assertEqual(1);
      expect(matched[0]).assertEqual('101');

      // Error formatting & null super-res safety
      expect(VisionEnhancementHelper.formatVisionError(1018700001).includes('超分')).assertTrue();
      expect(VisionEnhancementHelper.formatVisionError(1013100002).includes('文搜图')).assertTrue();
      const nullSr = await VisionEnhancementHelper.enhancePixelMapSuperResolution(null);
      expect(nullSr.success).assertFalse();
      expect(nullSr.pixelMap === null).assertTrue();
    });

    it('performanceSchedulerHelperPureChecks', 0, () => {
      expect(PerformanceSchedulerHelper.getMinIntervalMs(FAST_DURATION_SHORT)).assertEqual(3100);
      expect(PerformanceSchedulerHelper.getMinIntervalMs(FAST_DURATION_MEDIUM)).assertEqual(30500);
      expect(PerformanceSchedulerHelper.getMinIntervalMs(FAST_DURATION_LONG)).assertEqual(180500);

      // Thread ID sanitization (positive integers, unique, max 16)
      const tids = PerformanceSchedulerHelper.sanitizeThreadIds([
        -5, 0, NaN, 101, 102, 101, 103, 104, 105, 106, 107, 108, 109, 110, 111, 112, 113, 114, 115, 116, 117, 118
      ]);
      expect(tids.length).assertEqual(16);
      expect(tids[0]).assertEqual(101);
      expect(tids[15]).assertEqual(116);

      // Throttle state check
      const recordMap = new Map<string, number>();
      expect(
        PerformanceSchedulerHelper.canReportPerfHint(FAST_SCENE_APP_LAUNCH, FAST_DURATION_SHORT, 1000, recordMap)
      ).assertTrue();
      expect(
        PerformanceSchedulerHelper.canReportPerfHint(FAST_SCENE_APP_LAUNCH, FAST_DURATION_SHORT, 2500, recordMap)
      ).assertFalse();
      expect(
        PerformanceSchedulerHelper.canReportPerfHint(FAST_SCENE_APP_LAUNCH, FAST_DURATION_SHORT, 4200, recordMap)
      ).assertTrue();

      const payload = PerformanceSchedulerHelper.buildPerfHintPayload(
        FAST_SCENE_PAGE_LOAD,
        FAST_STATE_BEGIN,
        FAST_DURATION_SHORT,
        [2001]
      );
      expect(payload.sceneType).assertEqual(FAST_SCENE_PAGE_LOAD);
      expect(payload.sceneState).assertEqual(FAST_STATE_BEGIN);
      expect(payload.tids.length).assertEqual(1);

      const endPayload = PerformanceSchedulerHelper.buildPerfHintPayload(999, FAST_STATE_END, 99);
      expect(endPayload.sceneType).assertEqual(FAST_SCENE_PAGE_LOAD);
      expect(endPayload.sceneState).assertEqual(FAST_STATE_END);
      expect(endPayload.durationType).assertEqual(FAST_DURATION_SHORT);

      expect(PerformanceSchedulerHelper.formatPerfHintError(1027700005).includes('节流')).assertTrue();
      expect(PerformanceSchedulerHelper.showHdsOrFallbackSnackBar(null, '测试标题')).assertFalse();
    });

    it('holdingHandHelperPureChecks', 0, () => {
      expect(HoldingHandHelper.normalizeHoldingHandStatus(HOLDING_HAND_LEFT)).assertEqual(HOLDING_HAND_LEFT);
      expect(HoldingHandHelper.normalizeHoldingHandStatus(HOLDING_HAND_RIGHT)).assertEqual(HOLDING_HAND_RIGHT);
      expect(HoldingHandHelper.normalizeHoldingHandStatus(HOLDING_HAND_BOTH)).assertEqual(HOLDING_HAND_BOTH);
      expect(HoldingHandHelper.normalizeHoldingHandStatus(HOLDING_HAND_NOT_HELD)).assertEqual(HOLDING_HAND_NOT_HELD);
      expect(HoldingHandHelper.normalizeHoldingHandStatus(99)).assertEqual(HOLDING_HAND_UNKNOWN);

      expect(HoldingHandHelper.getHoldingHandLabel(HOLDING_HAND_LEFT)).assertEqual('左手握持');
      expect(HoldingHandHelper.getHoldingHandLabel(HOLDING_HAND_RIGHT)).assertEqual('右手握持');

      // Left-hand FAB alignment only on single-pane xs/sm
      expect(HoldingHandHelper.shouldAlignFabLeft(HOLDING_HAND_LEFT, 'sm', false)).assertTrue();
      expect(HoldingHandHelper.shouldAlignFabLeft(HOLDING_HAND_LEFT, 'xs', false)).assertTrue();
      expect(HoldingHandHelper.shouldAlignFabLeft(HOLDING_HAND_LEFT, 'md', false)).assertFalse();
      expect(HoldingHandHelper.shouldAlignFabLeft(HOLDING_HAND_LEFT, 'lg', false)).assertFalse();
      expect(HoldingHandHelper.shouldAlignFabLeft(HOLDING_HAND_LEFT, 'sm', true)).assertFalse();
      expect(HoldingHandHelper.shouldAlignFabLeft(HOLDING_HAND_RIGHT, 'sm', false)).assertFalse();

      const leftAlign = HoldingHandHelper.computeFabHandAlignment(HOLDING_HAND_LEFT, 'sm', 0, 0, 50, false);
      expect(leftAlign.alignLeft).assertTrue();
      expect(leftAlign.leftMarginVp).assertEqual(62);

      const rightAlign = HoldingHandHelper.computeFabHandAlignment(HOLDING_HAND_RIGHT, 'sm', 0, 4, 50, false);
      expect(rightAlign.alignLeft).assertFalse();
      expect(rightAlign.rightMarginVp).assertEqual(14);
    });

    it('multiDimensionWidgetPureChecks', 0, () => {
      expect(WidgetDataHelper.DIMENSION_2_2).assertEqual(2);
      expect(WidgetDataHelper.DIMENSION_2_4).assertEqual(3);
      expect(WidgetDataHelper.DIMENSION_4_4).assertEqual(4);

      const schedWant = WidgetDataHelper.buildScheduleWidgetWant();
      expect(schedWant.parameters?.['ohos.extra.param.key.form_name']).assertEqual('schedule_widget');
      expect(schedWant.parameters?.['ohos.extra.param.key.form_dimension']).assertEqual(4);

      const quick22Want = WidgetDataHelper.buildQuickEntryWidgetWant();
      expect(quick22Want.parameters?.['ohos.extra.param.key.form_name']).assertEqual('quick_entry_widget');
      expect(quick22Want.parameters?.['ohos.extra.param.key.form_dimension']).assertEqual(2);

      const quick24Want = WidgetDataHelper.buildQuickEntryWideWidgetWant();
      expect(quick24Want.parameters?.['ohos.extra.param.key.form_name']).assertEqual('quick_entry_widget');
      expect(quick24Want.parameters?.['ohos.extra.param.key.form_dimension']).assertEqual(3);

      // ImmersiveLightHelper fallbackBg must never return transparent and hide primary buttons
      expect(ImmersiveLightHelper.fallbackBg('#97000C')).assertEqual('#97000C');
    });
  });
}
