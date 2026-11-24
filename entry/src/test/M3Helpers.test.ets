import { describe, it, expect } from '@ohos/hypium';
import { userAuth } from '@kit.UserAuthenticationKit';
import { asset } from '@kit.AssetStoreKit';
import {
  NluEntityHelper,
  RawNluEntity,
  NLU_ENTITY_DATETIME,
  NLU_ENTITY_LOCATION,
  NLU_ENTITY_PHONE_NO,
  NLU_ENTITY_EMAIL,
  NLU_ENTITY_URL
} from '../main/ets/common/NluEntityHelper';
import { TtsReaderHelper, TtsSessionMachine } from '../main/ets/common/TtsReaderHelper';
import { BiometricAuthHelper, BiometricCapability } from '../main/ets/common/BiometricAuthHelper';
import { SecureAssetHelper, LoginSecretBundle } from '../main/ets/common/SecureAssetHelper';
import { BreakpointSystem, CreaseRegionVp } from '../main/ets/common/BreakpointSystem';
import { AdaptiveLayoutHelper } from '../main/ets/common/AdaptiveLayoutHelper';
import { ReminderCalendarHelper } from '../main/ets/common/ReminderCalendarHelper';
import { FilePreviewHelper } from '../main/ets/common/FilePreviewHelper';

export default function m3HelpersTest() {
  describe('m3HelpersTest', () => {
    it('nluEntityHelperPureAndEmptyExtract', 0, async () => {
      const htmlRaw: string =
        '<script>alert(1)</script><style>.a{}</style><p>通知&amp;公告：请于&nbsp;2026年11月25日 14:30&nbsp;前往&lt;办公楼101&gt;</p><br/>详情见 &quot;https://www.sdmu.edu.cn/a.html&quot;&#39;';
      const cleaned: string = NluEntityHelper.cleanSourceText(htmlRaw);
      expect(cleaned).assertContain('通知&公告：请于 2026年11月25日 14:30 前往<办公楼101>');
      expect(cleaned).assertContain('"https://www.sdmu.edu.cn/a.html"\'');
      expect(cleaned.indexOf('<script>') < 0).assertTrue();
      expect(NluEntityHelper.cleanSourceText('   ')).assertEqual('');

      expect(NluEntityHelper.chunkText('').length).assertEqual(0);
      expect(NluEntityHelper.chunkText('短文本测试。').length).assertEqual(1);
      const longSentenceA: string = '第一句教学通知内容，请各学院按时提交材料并通知相关师生参加会议。';
      const longSentenceB: string = '第二句教学通知内容，请于本周五前完成系统确认与信息核对工作！';
      const combinedText: string = `${longSentenceA}${longSentenceB}${longSentenceA}${longSentenceB}`;
      const chunks: string[] = NluEntityHelper.chunkText(combinedText, 60);
      expect(chunks.length >= 2).assertTrue();
      for (const ch of chunks) {
        expect(ch.length <= 60).assertTrue();
      }

      expect(NluEntityHelper.normalizeEntityText(NLU_ENTITY_URL, 'https://sdmu.edu.cn/news。'))
        .assertEqual('https://sdmu.edu.cn/news');
      expect(NluEntityHelper.normalizeEntityText(NLU_ENTITY_URL, '(https://sdmu.edu.cn/p)'))
        .assertEqual('https://sdmu.edu.cn/p');
      expect(NluEntityHelper.normalizeEntityText(NLU_ENTITY_URL, 'https://sdmu.edu.cn/p)'))
        .assertEqual('https://sdmu.edu.cn/p');
      expect(NluEntityHelper.normalizeEntityText(NLU_ENTITY_PHONE_NO, '138 0013\u00A08000'))
        .assertEqual('13800138000');
      expect(NluEntityHelper.normalizeEntityText(NLU_ENTITY_EMAIL, '<dean@sdmu.edu.cn>;'))
        .assertEqual('dean@sdmu.edu.cn');

      expect(NluEntityHelper.mapEntityToAction(NLU_ENTITY_DATETIME)).assertEqual('calendar');
      expect(NluEntityHelper.mapEntityToAction(NLU_ENTITY_LOCATION)).assertEqual('location');
      expect(NluEntityHelper.mapEntityToAction(NLU_ENTITY_PHONE_NO)).assertEqual('dial');
      expect(NluEntityHelper.mapEntityToAction(NLU_ENTITY_EMAIL)).assertEqual('email');
      expect(NluEntityHelper.mapEntityToAction(NLU_ENTITY_URL)).assertEqual('url');

      expect(NluEntityHelper.getActionLabel(NLU_ENTITY_DATETIME)).assertEqual('加日程');
      expect(NluEntityHelper.getActionLabel(NLU_ENTITY_LOCATION)).assertEqual('复制地点');
      expect(NluEntityHelper.getActionLabel(NLU_ENTITY_PHONE_NO)).assertEqual('拨号');
      expect(NluEntityHelper.getActionLabel(NLU_ENTITY_EMAIL)).assertEqual('发邮件');
      expect(NluEntityHelper.getActionLabel(NLU_ENTITY_URL)).assertEqual('打开链接');

      expect(NluEntityHelper.getTypeLabel(NLU_ENTITY_DATETIME)).assertEqual('时间');
      expect(NluEntityHelper.getTypeLabel(NLU_ENTITY_LOCATION)).assertEqual('地点');
      expect(NluEntityHelper.getTypeLabel(NLU_ENTITY_PHONE_NO)).assertEqual('电话');
      expect(NluEntityHelper.getTypeLabel(NLU_ENTITY_EMAIL)).assertEqual('邮箱');
      expect(NluEntityHelper.getTypeLabel(NLU_ENTITY_URL)).assertEqual('链接');

      expect(NluEntityHelper.parseDatetimeMs('{"timestamp": 1700000000}', '')).assertEqual(1700000000000);
      expect(NluEntityHelper.parseDatetimeMs('{"timestamp": 1700000000123}', '')).assertEqual(1700000000123);
      const parsedFull: number | null = NluEntityHelper.parseDatetimeMs('{bad', '2026年11月25日 14:30');
      expect(parsedFull).assertEqual(new Date(2026, 10, 25, 14, 30, 0, 0).getTime());
      const ref2026: number = new Date(2026, 10, 1, 8, 0, 0, 0).getTime();
      const parsedMd: number | null = NluEntityHelper.parseDatetimeMs('', '12月5日 09:15', ref2026);
      expect(parsedMd).assertEqual(new Date(2026, 11, 5, 9, 15, 0, 0).getTime());
      expect(NluEntityHelper.parseDatetimeMs('', '无效日期') === null).assertTrue();

      const rawList: RawNluEntity[] = [
        { text: 'https://sdmu.edu.cn/a。', type: NLU_ENTITY_URL },
        { text: 'HTTPS://SDMU.EDU.CN/a', type: NLU_ENTITY_URL },
        { text: 'invalidurl', type: NLU_ENTITY_URL },
        { text: '138 0013 8000', type: NLU_ENTITY_PHONE_NO },
        { text: '12', type: NLU_ENTITY_PHONE_NO },
        { text: 'bad-email', type: NLU_ENTITY_EMAIL },
        { text: 'info@sdmu.edu.cn', type: NLU_ENTITY_EMAIL },
        { text: '办公楼101', type: NLU_ENTITY_LOCATION },
        { text: '2026年11月25日 14:30', type: NLU_ENTITY_DATETIME }
      ];
      const chips = NluEntityHelper.deduplicateEntities(rawList, 4, ref2026);
      expect(chips.length).assertEqual(4);
      expect(chips[0].text).assertEqual('https://sdmu.edu.cn/a');
      expect(chips[1].text).assertEqual('13800138000');
      expect(chips[2].text).assertEqual('info@sdmu.edu.cn');
      expect(chips[3].text).assertEqual('办公楼101');

      const meetingSrc: string = NluEntityHelper.buildMeetingNluSource(
        '教学工作会',
        '行政楼302',
        '2026-11-26 09:00',
        '2026-11-26 11:00',
        '王老师',
        '0531-89630001'
      );
      expect(meetingSrc).assertContain('会议：教学工作会');
      expect(meetingSrc).assertContain('时间：2026-11-26 09:00 至 2026-11-26 11:00');
      expect(meetingSrc).assertContain('地点：行政楼302');
      expect(meetingSrc).assertContain('联系电话：0531-89630001');

      expect(NluEntityHelper.formatNluError(200)).assertContain('超时');
      expect(NluEntityHelper.formatNluError(401)).assertContain('参数无效');
      expect(NluEntityHelper.formatNluError(1011200001)).assertContain('不支持');

      const emptyRes = await NluEntityHelper.extractEntities('');
      expect(emptyRes.supported).assertTrue();
      expect(emptyRes.entities.length).assertEqual(0);
      expect(emptyRes.message).assertEqual('');
    });

    it('ttsReaderHelperAndSessionMachine', 0, () => {
      const cleaned: string = TtsReaderHelper.cleanTtsText(
        '<p>欢迎收听&nbsp;校园新闻！</p>详情访问 https://www.sdmu.edu.cn/a?b=1 <br/>第二段内容。'
      );
      expect(cleaned.indexOf('https://') < 0).assertTrue();
      expect(cleaned).assertContain('欢迎收听 校园新闻！');
      expect(cleaned).assertContain('第二段内容。');

      const textForSplit: string =
        '第一段校园通知已正式发布，请各位同学认真阅读。第二段教务处提醒本周开始课程预选！第三段实验室安全检查将于明早启动？';
      const chunks: string[] = TtsReaderHelper.splitSpeechChunks(textForSplit, 30);
      expect(chunks.length >= 3).assertTrue();
      for (const chunk of chunks) {
        expect(chunk.length <= 30).assertTrue();
      }
      expect(TtsReaderHelper.splitSpeechChunks('   ').length).assertEqual(0);

      const reqId1: string = TtsReaderHelper.buildRequestId(1);
      const reqIdFallback: string = TtsReaderHelper.buildRequestId(0);
      expect(/^[a-zA-Z0-9]+$/.test(reqId1)).assertTrue();
      expect(/^[a-zA-Z0-9]+$/.test(reqIdFallback)).assertTrue();
      expect(reqId1).assertEqual('sdmuTts1');
      expect(reqIdFallback).assertEqual('sdmuTts1');

      expect(TtsReaderHelper.formatTtsError(401)).assertContain('参数无效');
      expect(TtsReaderHelper.formatTtsError(1002300001)).assertContain('超出限制');
      expect(TtsReaderHelper.formatTtsError(1002300002)).assertContain('中文');
      expect(TtsReaderHelper.formatTtsError(1002300003)).assertContain('发音人');
      expect(TtsReaderHelper.formatTtsError(1002300005)).assertContain('初始化失败');

      const machine: TtsSessionMachine = new TtsSessionMachine();
      const prepared: string[] = machine.prepare('第一段新闻内容，说明活动安排。第二段补充说明，欢迎全体师生参加。', 20);
      expect(prepared.length).assertEqual(2);
      expect(machine.getSnapshot().state).assertEqual('idle');

      const firstChunk: string = machine.markPlaying();
      expect(firstChunk).assertEqual(prepared[0]);
      expect(machine.getSnapshot().state).assertEqual('playing');
      expect(machine.getSnapshot().currentIndex).assertEqual(0);

      // completeType === 0（仅合成完成）绝对不推进段落
      const onSynthOnly: string | null = machine.handleComplete(0);
      expect(onSynthOnly === null).assertTrue();
      expect(machine.getSnapshot().currentIndex).assertEqual(0);
      expect(machine.getSnapshot().state).assertEqual('playing');

      // 暂停与恢复生命周期
      machine.pause();
      expect(machine.getSnapshot().state).assertEqual('paused');
      expect(machine.handleComplete(1) === null).assertTrue();
      const resumedChunk: string = machine.resume();
      expect(resumedChunk).assertEqual(prepared[0]);
      expect(machine.getSnapshot().state).assertEqual('playing');

      // completeType === 1 推进至第二段
      const secondChunk: string | null = machine.handleComplete(1);
      expect(secondChunk).assertEqual(prepared[1]);
      expect(machine.getSnapshot().currentIndex).assertEqual(1);
      expect(machine.getSnapshot().state).assertEqual('playing');

      // 末段 completeType === 1 结束后归位 idle
      const endResult: string | null = machine.handleComplete(1);
      expect(endResult === null).assertTrue();
      expect(machine.getSnapshot().state).assertEqual('idle');
      expect(machine.getSnapshot().currentIndex).assertEqual(0);

      // stop & fail 状态转换
      machine.markPlaying();
      machine.stop();
      expect(machine.getSnapshot().state).assertEqual('idle');
      expect(machine.getSnapshot().currentIndex).assertEqual(0);
      machine.fail('引擎不可用');
      expect(machine.getSnapshot().state).assertEqual('error');
      expect(machine.getSnapshot().errorMessage).assertEqual('引擎不可用');
    });

    it('biometricAuthHelperPureAndState', 0, async () => {
      const bothTypes = BiometricAuthHelper.buildAvailableAuthTypes(true, true, true);
      expect(bothTypes.length).assertEqual(3);
      expect(bothTypes[0]).assertEqual(userAuth.UserAuthType.FACE);
      expect(bothTypes[1]).assertEqual(userAuth.UserAuthType.FINGERPRINT);
      expect(bothTypes[2]).assertEqual(userAuth.UserAuthType.PIN);
      expect(BiometricAuthHelper.buildAvailableAuthTypes(false, false, false).length).assertEqual(0);

      expect(BiometricAuthHelper.generateChallenge().byteLength).assertEqual(16);
      expect(BiometricAuthHelper.generateChallenge(0).byteLength).assertEqual(1);
      expect(BiometricAuthHelper.generateChallenge(64).byteLength).assertEqual(32);
      expect(BiometricAuthHelper.generateChallenge(NaN).byteLength).assertEqual(16);

      expect(BiometricAuthHelper.mapAuthResultCode(userAuth.UserAuthResultCode.SUCCESS).success).assertTrue();
      expect(BiometricAuthHelper.mapAuthResultCode(userAuth.UserAuthResultCode.FAIL).success).assertFalse();
      expect(BiometricAuthHelper.mapAuthResultCode(userAuth.UserAuthResultCode.CANCELED).canceled).assertTrue();
      const widgetCancel = BiometricAuthHelper.mapAuthResultCode(userAuth.UserAuthResultCode.CANCELED_FROM_WIDGET);
      expect(widgetCancel.canceled).assertTrue();
      expect(widgetCancel.fallbackToCustom).assertTrue();
      expect(BiometricAuthHelper.mapAuthResultCode(userAuth.UserAuthResultCode.TIMEOUT).message).assertContain('超时');
      expect(BiometricAuthHelper.mapAuthResultCode(userAuth.UserAuthResultCode.LOCKED).locked).assertTrue();
      expect(BiometricAuthHelper.mapAuthResultCode(userAuth.UserAuthResultCode.NOT_ENROLLED).notEnrolled).assertTrue();
      expect(BiometricAuthHelper.mapAuthResultCode(userAuth.UserAuthResultCode.TYPE_NOT_SUPPORT).fallbackToCustom)
        .assertTrue();
      expect(BiometricAuthHelper.mapAuthResultCode(userAuth.UserAuthResultCode.BUSY).message).assertContain('忙');

      const capBio: BiometricCapability = {
        faceAvailable: false,
        fingerprintAvailable: true,
        pinAvailable: true,
        anyBiometric: true,
        anyAvailable: true,
        authTypes: [userAuth.UserAuthType.FINGERPRINT, userAuth.UserAuthType.PIN],
        description: '已启用：指纹'
      };
      const capNone: BiometricCapability = {
        faceAvailable: false,
        fingerprintAvailable: false,
        pinAvailable: false,
        anyBiometric: false,
        anyAvailable: false,
        authTypes: [],
        description: '不可用'
      };
      expect(BiometricAuthHelper.shouldOfferBiometricToggle(capBio)).assertTrue();
      expect(BiometricAuthHelper.shouldOfferBiometricToggle(capNone)).assertFalse();

      expect(BiometricAuthHelper.shouldShowBiometricVerify(true, capBio, false)).assertTrue();
      expect(BiometricAuthHelper.shouldShowBiometricVerify(true, capBio, true)).assertFalse();
      expect(BiometricAuthHelper.shouldShowBiometricVerify(false, capBio, false)).assertFalse();
      expect(BiometricAuthHelper.shouldShowBiometricVerify(true, capNone, false)).assertFalse();

      const bioOnly = BiometricAuthHelper.getBiometricOnlyTypes(capBio);
      expect(bioOnly.length).assertEqual(1);
      expect(bioOnly[0]).assertEqual(userAuth.UserAuthType.FINGERPRINT);

      const widgetWithPin = BiometricAuthHelper.buildWidgetParam(
        '生物识别',
        [userAuth.UserAuthType.FINGERPRINT, userAuth.UserAuthType.PIN],
        '使用手势密码'
      );
      expect(widgetWithPin.title).assertEqual('生物识别');
      expect(widgetWithPin.navigationButtonText === undefined).assertTrue();

      const widgetBioOnly = BiometricAuthHelper.buildWidgetParam(
        '生物识别',
        [userAuth.UserAuthType.FACE, userAuth.UserAuthType.FINGERPRINT],
        '使用手势密码'
      );
      expect(widgetBioOnly.navigationButtonText).assertEqual('使用手势密码');

      expect(BiometricAuthHelper.normalizeBiometricFlag(true, false)).assertTrue();
      expect(BiometricAuthHelper.normalizeBiometricFlag('true', false)).assertTrue();
      expect(BiometricAuthHelper.normalizeBiometricFlag('1', false)).assertTrue();
      expect(BiometricAuthHelper.normalizeBiometricFlag('false', true)).assertFalse();
      expect(BiometricAuthHelper.normalizeBiometricFlag(0, true)).assertFalse();
      expect(BiometricAuthHelper.normalizeBiometricFlag(NaN, true)).assertTrue();
      expect(BiometricAuthHelper.normalizeBiometricFlag(undefined, false)).assertFalse();

      BiometricAuthHelper.resetStateForTest(null);
      const defaultState: boolean = await BiometricAuthHelper.isBiometricUnlockEnabled();
      expect(defaultState).assertFalse();
      await BiometricAuthHelper.setBiometricUnlockEnabled(true);
      expect(await BiometricAuthHelper.isBiometricUnlockEnabled()).assertTrue();
      BiometricAuthHelper.resetStateForTest(false);
      expect(await BiometricAuthHelper.isBiometricUnlockEnabled()).assertFalse();
      BiometricAuthHelper.resetStateForTest(null);
    });

    it('secureAssetHelperPureAndR3Compliance', 0, () => {
      const sample: string = 'sdmu_密钥_2026!';
      const encoded: Uint8Array = SecureAssetHelper.encodeUtf8(sample);
      expect(encoded.byteLength > sample.length).assertTrue();
      expect(SecureAssetHelper.decodeUtf8(encoded)).assertEqual(sample);
      expect(SecureAssetHelper.decodeUtf8(new Uint8Array(0))).assertEqual('');

      expect(SecureAssetHelper.isSecretWithinLimit('')).assertFalse();
      let exact1024: string = '';
      for (let i = 0; i < 1024; i++) {
        exact1024 += 'a';
      }
      expect(SecureAssetHelper.isSecretWithinLimit(exact1024)).assertTrue();
      expect(SecureAssetHelper.isSecretWithinLimit(exact1024 + 'b')).assertFalse();
      let cjkOver1024: string = '';
      for (let i = 0; i < 342; i++) {
        cjkOver1024 += '管';
      }
      expect(SecureAssetHelper.isSecretWithinLimit(cjkOver1024)).assertFalse();

      const addAttr = SecureAssetHelper.buildAddAttributes('sdmu_login_secrets', sample);
      expect(addAttr.get(asset.Tag.SYNC_TYPE)).assertEqual(asset.SyncType.NEVER);
      expect(addAttr.has(asset.Tag.IS_PERSISTENT)).assertFalse();
      expect(addAttr.get(asset.Tag.ACCESSIBILITY)).assertEqual(asset.Accessibility.DEVICE_FIRST_UNLOCKED);
      expect(addAttr.get(asset.Tag.AUTH_TYPE)).assertEqual(asset.AuthType.NONE);

      const queryAttr = SecureAssetHelper.buildQueryAttributes('sdmu_login_secrets');
      expect(queryAttr.get(asset.Tag.RETURN_TYPE)).assertEqual(asset.ReturnType.ALL);
      expect(SecureAssetHelper.decodeUtf8(queryAttr.get(asset.Tag.ALIAS) as Uint8Array)).assertEqual('sdmu_login_secrets');

      const removeAttr = SecureAssetHelper.buildRemoveAttributes('sdmu_login_secrets');
      expect(SecureAssetHelper.decodeUtf8(removeAttr.get(asset.Tag.ALIAS) as Uint8Array))
        .assertEqual('sdmu_login_secrets');

      const resultRow: asset.AssetMap = new Map();
      resultRow.set(asset.Tag.SECRET, SecureAssetHelper.encodeUtf8('secret_payload'));
      expect(SecureAssetHelper.extractSecretFromResults([resultRow])).assertEqual('secret_payload');
      expect(SecureAssetHelper.extractSecretFromResults([])).assertEqual('');

      expect(SecureAssetHelper.formatAssetError(201)).assertContain('权限');
      expect(SecureAssetHelper.formatAssetError(24000017)).assertContain('不支持');
      expect(SecureAssetHelper.formatAssetError(24000002)).assertContain('未找到');

      const bundle: LoginSecretBundle = {
        aesKey: 'k123',
        onlyCode: 'u456',
        sessionKey: 's789'
      };
      const packed: string = SecureAssetHelper.packLoginSecretBundle(bundle);
      const unpacked = SecureAssetHelper.unpackLoginSecretBundle(packed);
      expect(unpacked !== null).assertTrue();
      if (unpacked !== null) {
        expect(unpacked.aesKey).assertEqual('k123');
        expect(unpacked.onlyCode).assertEqual('u456');
        expect(unpacked.sessionKey).assertEqual('s789');
      }
      expect(SecureAssetHelper.unpackLoginSecretBundle('') === null).assertTrue();
      expect(SecureAssetHelper.unpackLoginSecretBundle('{"aesKey":"","onlyCode":"","sessionKey":""}') === null)
        .assertTrue();
    });

    it('m2HardeningBoundaryEdgeCases', 0, () => {
      const dlgW: number = BreakpointSystem.getDialogMaxWidth('md', Infinity);
      const dlgH: number = BreakpointSystem.getDialogMaxHeight(Infinity);
      expect(Number.isFinite(dlgW)).assertTrue();
      expect(Number.isFinite(dlgH)).assertTrue();
      expect(dlgW).assertEqual(328);
      expect(dlgH).assertEqual(525);

      const sheetW = AdaptiveLayoutHelper.getSheetMaxWidth('md', Infinity);
      expect(typeof sheetW === 'number' && Number.isFinite(sheetW as number)).assertTrue();
      expect(sheetW).assertEqual(520);

      const smPane = AdaptiveLayoutHelper.getSplitPaneConfig('sm', Infinity);
      expect(smPane.useTwoPane).assertFalse();
      expect(smPane.masterMinWidthVp).assertEqual(360);

      const pastDate: Date = new Date(1600000000000);
      expect(ReminderCalendarHelper.validateReminderDate(pastDate, NaN).valid).assertFalse();
      expect(ReminderCalendarHelper.validateReminderDate(new Date(NaN), 1700000000000).valid).assertFalse();

      const nowMs: number = 1700000000000;
      const futureMs: number = nowMs + 120 * 60000;
      expect(ReminderCalendarHelper.computeExamReminderTriggerMs(futureMs, NaN, NaN)).assertEqual(-1);
      expect(ReminderCalendarHelper.computeExamReminderTriggerMs(futureMs, NaN, nowMs))
        .assertEqual(nowMs + 60 * 60000);

      expect(FilePreviewHelper.sanitizeFileName('', '..')).assertEqual('attachment');
      const cachedA: string = FilePreviewHelper.buildCachedFileName('https://mcp.sdmu.edu.cn/a/doc.pdf', 'doc.pdf');
      const cachedB: string = FilePreviewHelper.buildCachedFileName('https://mcp.sdmu.edu.cn/b/doc.pdf', 'doc.pdf');
      expect(cachedA !== cachedB).assertTrue();
      expect(cachedA.endsWith('_doc.pdf')).assertTrue();

      expect(FilePreviewHelper.isUnexpectedHtmlResponse('report.pdf', 'text/html; charset=utf-8', '')).assertTrue();
      expect(FilePreviewHelper.isUnexpectedHtmlResponse('report.pdf', 'application/octet-stream', '  <!DOCTYPE html>'))
        .assertTrue();
      expect(FilePreviewHelper.isUnexpectedHtmlResponse('index.html', 'text/html', '<html></html>')).assertFalse();
      expect(FilePreviewHelper.isUnexpectedHtmlResponse('report.pdf', 'application/pdf', '%PDF-1.7')).assertFalse();

      expect(FilePreviewHelper.getPreviewMimeType('main.cpp')).assertEqual('text/x-c++src');
      expect(FilePreviewHelper.getPreviewMimeType('lib.c')).assertEqual('text/x-csrc');
      expect(FilePreviewHelper.getPreviewMimeType('defs.h')).assertEqual('text/x-chdr');
      expect(FilePreviewHelper.getPreviewMimeType('App.java')).assertEqual('text/x-java');
    });

    it('p2GridSplitSheetAndCreaseCalculations', 0, () => {
      const horizCrease: CreaseRegionVp = { left: 0, top: 300, width: 700, height: 24 };
      const vertCrease: CreaseRegionVp = { left: 300, top: 0, width: 20, height: 700 };

      expect(AdaptiveLayoutHelper.isHorizontalCrease(horizCrease)).assertTrue();
      expect(AdaptiveLayoutHelper.isHorizontalCrease(vertCrease)).assertFalse();
      expect(AdaptiveLayoutHelper.isHorizontalCrease(null)).assertFalse();

      expect(AdaptiveLayoutHelper.shouldAvoidCrease(horizCrease, 3)).assertTrue();
      expect(AdaptiveLayoutHelper.shouldAvoidCrease(vertCrease, 3)).assertFalse();
      expect(AdaptiveLayoutHelper.shouldAvoidCrease(horizCrease, 1)).assertFalse();

      expect(AdaptiveLayoutHelper.getCreaseAvoidHeightVp(horizCrease, 3)).assertEqual(24);
      expect(AdaptiveLayoutHelper.getCreaseAvoidHeightVp(vertCrease, 3)).assertEqual(0);
      expect(AdaptiveLayoutHelper.getCreaseAvoidHeightVp(horizCrease, 1)).assertEqual(0);

      expect(AdaptiveLayoutHelper.computeCreaseUpperHeightVp(horizCrease, 3, 340)).assertEqual(292);
      expect(AdaptiveLayoutHelper.computeCreaseUpperHeightVp(horizCrease, 3, 210)).assertEqual(210);
      expect(AdaptiveLayoutHelper.computeCreaseUpperHeightVp(vertCrease, 3, 340)).assertEqual(340);

      const lgCustomPane = AdaptiveLayoutHelper.getSplitPaneConfigWithRatio('lg', 1200, 3, 2);
      expect(lgCustomPane.useTwoPane).assertTrue();
      expect(lgCustomPane.masterRatio).assertEqual(3);
      expect(lgCustomPane.detailRatio).assertEqual(2);
      const smCustomPane = AdaptiveLayoutHelper.getSplitPaneConfigWithRatio('sm', 390, 3, 2);
      expect(smCustomPane.useTwoPane).assertFalse();

      expect(AdaptiveLayoutHelper.computeGridHeightVp(0, 4, 60, 10, 12)).assertEqual(0);
      expect(AdaptiveLayoutHelper.computeGridHeightVp(5, 4, 60, 10, 12)).assertEqual(142);

      expect(AdaptiveLayoutHelper.computeWaterFlowColWidthVp(800, 720, 3, 12)).assertEqual(224);
      expect(AdaptiveLayoutHelper.computeAspectScaledHeightVp(400, 300, 200, 165)).assertEqual(150);
      expect(AdaptiveLayoutHelper.computeAspectScaledHeightVp(0, 300, 200, 165)).assertEqual(165);

      expect(AdaptiveLayoutHelper.getSheetPreferType('md', false)).assertEqual(SheetType.CENTER);
      expect(AdaptiveLayoutHelper.getSheetPreferType('lg', false)).assertEqual(SheetType.CENTER);
      expect(AdaptiveLayoutHelper.getSheetPreferType('sm', true)).assertEqual(SheetType.CENTER);
      expect(AdaptiveLayoutHelper.getSheetPreferType('sm', false)).assertEqual(SheetType.BOTTOM);
    });
  });
}
