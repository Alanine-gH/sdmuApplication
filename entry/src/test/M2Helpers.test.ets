import { describe, it, expect } from '@ohos/hypium';
import { mapCommon, petalMaps } from '@kit.MapKit';
import { BarcodeHelper } from '../main/ets/common/BarcodeHelper';
import { FilePreviewHelper } from '../main/ets/common/FilePreviewHelper';
import { PetalMapHelper } from '../main/ets/common/PetalMapHelper';
import { AdaptiveLayoutHelper } from '../main/ets/common/AdaptiveLayoutHelper';
import { BreakpointSystem } from '../main/ets/common/BreakpointSystem';
import { PrivacyWindowHelper } from '../main/ets/common/PrivacyWindowHelper';
import { ReminderCalendarHelper } from '../main/ets/common/ReminderCalendarHelper';
import { PasteHelper } from '../main/ets/common/PasteHelper';

export default function m2HelpersTest() {
  describe('m2HelpersTest', () => {
    it('barcodeHelperPureChecks', 0, () => {
      expect(BarcodeHelper.clampBarcodeSize(100)).assertEqual(200);
      expect(BarcodeHelper.clampBarcodeSize(480)).assertEqual(480);
      expect(BarcodeHelper.clampBarcodeSize(5000)).assertEqual(4096);
      expect(BarcodeHelper.clampBarcodeSize(0)).assertEqual(480);
      expect(BarcodeHelper.clampBarcodeSize(NaN)).assertEqual(480);
      expect(BarcodeHelper.clampBarcodeSize(Infinity)).assertEqual(480);

      expect(BarcodeHelper.truncateQrContent('')).assertEqual('');
      expect(BarcodeHelper.truncateQrContent('  hello\r\nworld  ')).assertEqual('hello\nworld');
      let longStr: string = '';
      for (let i = 0; i < 600; i++) {
        longStr += 'x';
      }
      expect(BarcodeHelper.truncateQrContent(longStr).length).assertEqual(512);
      expect(BarcodeHelper.truncateQrContent(longStr, 128).length).assertEqual(128);

      const emptyCard: string = BarcodeHelper.buildContactVCard({ name: '' });
      expect(emptyCard).assertEqual('');
      const validCard: string = BarcodeHelper.buildContactVCard({
        name: '张三',
        org: '计算机学院',
        title: '讲师',
        phone: '13800138000',
        tel: '0531-89630000',
        email: 'zhangsan@sdmu.edu.cn',
        address: '长清校区'
      });
      expect(validCard).assertContain('BEGIN:VCARD');
      expect(validCard).assertContain('FN:张三');
      expect(validCard).assertContain('TEL;TYPE=CELL:13800138000');
      expect(validCard).assertContain('END:VCARD');
      expect(validCard.length <= 512).assertTrue();

      const hugeCard: string = BarcodeHelper.buildContactVCard({
        name: longStr,
        org: longStr,
        title: longStr,
        phone: longStr,
        tel: longStr,
        email: longStr,
        address: longStr
      });
      expect(hugeCard.length <= 512).assertTrue();
      expect(hugeCard.endsWith('END:VCARD')).assertTrue();

      expect(BarcodeHelper.buildProjectQrPayload('', '', '', '', '', '', '')).assertEqual('');
      const projPayload: string = BarcodeHelper.buildProjectQrPayload(
        'P2026', '校园科研项目', '纵向', '在研', '10000 元', '5000 元', '2000 元'
      );
      expect(projPayload).assertContain('项目编号:P2026');
      expect(projPayload.length <= 512).assertTrue();

      expect(BarcodeHelper.buildCourseQrPayload('', '', '', '', '', '')).assertEqual('');
      const coursePayload: string = BarcodeHelper.buildCourseQrPayload(
        '高等数学', '1-16周', '周三 1-2节', 'A101', '08:00-09:40', '李四'
      );
      expect(coursePayload).assertContain('课程:高等数学');
      expect(coursePayload.length <= 512).assertTrue();

      expect(BarcodeHelper.formatBarcodeError(201)).assertContain('权限');
      expect(BarcodeHelper.formatBarcodeError(401)).assertContain('限制');
      expect(BarcodeHelper.formatBarcodeError(1000500001)).assertContain('不可用');
    });

    it('filePreviewHelperPureChecks', 0, () => {
      expect(FilePreviewHelper.extractExtension('report.PDF?token=1#p2')).assertEqual('pdf');
      expect(FilePreviewHelper.extractExtension('/cache/meeting/通知.Docx')).assertEqual('docx');
      expect(FilePreviewHelper.extractExtension('noext')).assertEqual('');

      expect(FilePreviewHelper.getPreviewMimeType('a.pdf')).assertEqual('application/pdf');
      expect(FilePreviewHelper.getPreviewMimeType('a.docx')).assertEqual(
        'application/vnd.openxmlformats-officedocument.wordprocessingml.document'
      );
      expect(FilePreviewHelper.getPreviewMimeType('a.xlsx')).assertEqual(
        'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
      );
      expect(FilePreviewHelper.getPreviewMimeType('a.pptx')).assertEqual(
        'application/vnd.openxmlformats-officedocument.presentationml.presentation'
      );
      expect(FilePreviewHelper.getPreviewMimeType('a.csv')).assertEqual('text/csv');
      expect(FilePreviewHelper.getPreviewMimeType('a.ofd')).assertEqual('general.ofd');
      expect(FilePreviewHelper.getPreviewMimeType('a.png')).assertEqual('image/png');
      expect(FilePreviewHelper.getPreviewMimeType('a.unknown')).assertEqual('');

      expect(FilePreviewHelper.isPdfFileName('test.PDF')).assertTrue();
      expect(FilePreviewHelper.isPdfFileName('test.docx')).assertFalse();
      expect(FilePreviewHelper.isPreviewKitSupportedExt('slide.pptx')).assertTrue();
      expect(FilePreviewHelper.isPreviewKitSupportedExt('archive.rar')).assertFalse();

      expect(FilePreviewHelper.resolveDownloadUrl('')).assertEqual('');
      expect(FilePreviewHelper.resolveDownloadUrl('https://example.com/a.pdf')).assertEqual('https://example.com/a.pdf');
      expect(FilePreviewHelper.resolveDownloadUrl('/attach/a.pdf')).assertContain('/attach/a.pdf');

      expect(FilePreviewHelper.sanitizeFileName('')).assertEqual('attachment');
      expect(FilePreviewHelper.sanitizeFileName('../../evil/doc:1*.pdf?a=1')).assertEqual('doc_1_.pdf');
    });

    it('petalMapHelperPureChecks', 0, () => {
      const valid = PetalMapHelper.parseCoordinatePair('36.5305363958', '116.7842602730');
      expect(valid !== null).assertTrue();
      if (valid !== null) {
        expect(valid.latitude).assertEqual(36.5305363958);
        expect(valid.longitude).assertEqual(116.7842602730);
      }

      expect(PetalMapHelper.parseCoordinatePair('0', '0') === null).assertTrue();
      expect(PetalMapHelper.parseCoordinatePair('NaN', '116.78') === null).assertTrue();
      expect(PetalMapHelper.parseCoordinatePair('90', '116.78') === null).assertTrue();
      expect(PetalMapHelper.parseCoordinatePair('36.5', '180') === null).assertTrue();
      expect(PetalMapHelper.parseCoordinatePair('36.5', '-180') !== null).assertTrue();

      expect(PetalMapHelper.mapRouteModeToVehicleType(0)).assertEqual(petalMaps.VehicleType.DRIVING);
      expect(PetalMapHelper.mapRouteModeToVehicleType(2)).assertEqual(petalMaps.VehicleType.WALKING);
      expect(PetalMapHelper.mapRouteModeToVehicleType(3)).assertEqual(petalMaps.VehicleType.CYCLING);
      expect(PetalMapHelper.mapRouteModeToVehicleType(99)).assertEqual(petalMaps.VehicleType.WALKING);

      expect(PetalMapHelper.buildRoutePlanParams('', '116', '校门', 2) === null).assertTrue();
      const route = PetalMapHelper.buildRoutePlanParams('36.53', '116.78', '山东管理学院', 3);
      expect(route !== null).assertTrue();
      if (route !== null) {
        expect(route.destinationName).assertEqual('山东管理学院');
        expect(route.vehicleType).assertEqual(petalMaps.VehicleType.CYCLING);
        expect(route.coordinateType).assertEqual(mapCommon.CoordinateType.GCJ02);
      }

      const poi = PetalMapHelper.buildPoiDetailParams('36.53', '116.78', '', '济南市长清区');
      expect(poi !== null).assertTrue();
      if (poi !== null) {
        expect(poi.destinationName).assertEqual('位置详情');
        expect(poi.zoom).assertEqual(17);
        expect(poi.destinationAddress).assertEqual('济南市长清区');
        expect(poi.coordinateType).assertEqual(mapCommon.CoordinateType.GCJ02);
      }

      expect(PetalMapHelper.formatMapError(1002600014).unavailable).assertTrue();
      expect(PetalMapHelper.formatMapError(801).unavailable).assertTrue();
      expect(PetalMapHelper.formatMapError(401).unavailable).assertFalse();
    });

    it('m1HardeningAndP1LayoutEdgeCases', 0, async () => {
      expect(AdaptiveLayoutHelper.buildColumnsTemplate(Infinity)).assertEqual('1fr');
      expect(AdaptiveLayoutHelper.buildColumnsTemplate(NaN)).assertEqual('1fr');
      expect(AdaptiveLayoutHelper.buildColumnsTemplate(100).split(' ').length).assertEqual(24);
      expect(AdaptiveLayoutHelper.isHalfFoldedStatus(22)).assertTrue();

      expect(BreakpointSystem.convertCreaseRectToVp(0, 0, NaN, 10, 3) === null).assertTrue();
      expect(BreakpointSystem.convertCreaseRectToVp(0, 0, Infinity, 10, 3) === null).assertTrue();
      expect(BreakpointSystem.getGridColumns('xs', 1)).assertEqual(1);
      expect(BreakpointSystem.getGridColumns('xs', Infinity)).assertEqual(3);
      expect(BreakpointSystem.computeGestureGridSize(NaN, Infinity)).assertEqual(288);
      expect(BreakpointSystem.computeGestureGridSize(320, 700)).assertEqual(272);

      expect(PrivacyWindowHelper.normalizePrivacyFlag(NaN, false)).assertFalse();
      expect(PrivacyWindowHelper.normalizePrivacyFlag(Infinity, true)).assertTrue();
      expect(PrivacyWindowHelper.computeTargetPrivacyMode(true, NaN)).assertFalse();
      PrivacyWindowHelper.resetStateForTest(true);
      const wsEnter = await PrivacyWindowHelper.enterSensitivePage('   ');
      expect(wsEnter.activeCount).assertEqual(0);
      expect(wsEnter.privacyMode).assertFalse();
      PrivacyWindowHelper.resetStateForTest(null);

      const refNow: Date = new Date(2026, 10, 23, 7, 30, 0, 0);
      const enDashWin = ReminderCalendarHelper.computeNextCourseWindow('3', '周三 1\u20132节', '08:00\u201309:40', refNow);
      expect(enDashWin !== null).assertTrue();
      if (enDashWin !== null) {
        expect(enDashWin.endMs - enDashWin.startMs).assertEqual(100 * 60000);
      }

      expect(PasteHelper.isHttpUrl('http://')).assertFalse();
      expect(PasteHelper.isHttpUrl('https://')).assertFalse();
      expect(PasteHelper.isHttpUrl('https://sdmu.edu.cn bad')).assertFalse();
      expect(PasteHelper.isHttpUrl('https://sdmu.edu.cn/path')).assertTrue();
    });
  });
}
