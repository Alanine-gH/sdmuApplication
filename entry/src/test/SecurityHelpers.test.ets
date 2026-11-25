import { describe, it, expect } from '@ohos/hypium';
import { UrlSecurityHelper } from '../main/ets/common/UrlSecurityHelper';
import { CryptoUtil } from '../main/ets/network/CryptoUtil';
import { BiometricAuthHelper } from '../main/ets/common/BiometricAuthHelper';

export default function securityHelpersTest() {
  describe('securityHelpersTest', () => {
    it('safeHttpUrlValidation', 0, () => {
      expect(UrlSecurityHelper.isSafeHttpUrl('https://mcp.sdmu.edu.cn/home')).assertTrue();
      expect(UrlSecurityHelper.isSafeHttpUrl('http://mcp.sdmu.edu.cn:8081/mobileapi_ydxy')).assertTrue();
      expect(UrlSecurityHelper.isSafeHttpUrl('javascript:alert(1)')).assertFalse();
      expect(UrlSecurityHelper.isSafeHttpUrl('file:///etc/passwd')).assertFalse();
      expect(UrlSecurityHelper.isSafeHttpUrl('data:text/html,<script>1</script>')).assertFalse();
      expect(UrlSecurityHelper.isSafeHttpUrl('http://sdmu.edu.cn@untrusted.example/')).assertFalse();
      expect(UrlSecurityHelper.isSafeHttpUrl('')).assertFalse();
    });

    it('trustedAuthHostValidation', 0, () => {
      expect(UrlSecurityHelper.isTrustedAuthHost('http://mcp.sdmu.edu.cn:8081/test')).assertTrue();
      expect(UrlSecurityHelper.isTrustedAuthHost('https://oa.sdmu.edu.cn/bpm')).assertTrue();
      expect(UrlSecurityHelper.isTrustedAuthHost('http://zfpt.wru.edu.cn:8082/a')).assertTrue();
      expect(UrlSecurityHelper.isTrustedAuthHost('https://www.yibaogao.com/api')).assertTrue();
      expect(UrlSecurityHelper.isTrustedAuthHost('https://ydxy.ly-sky.com:8098/app')).assertTrue();
      expect(UrlSecurityHelper.isTrustedAuthHost('https://sdmu.edu.cn.evil.example/')).assertFalse();
      expect(UrlSecurityHelper.isTrustedAuthHost('https://untrusted.example/paysec/pay/cm')).assertFalse();
      expect(UrlSecurityHelper.isTrustedAuthHost('https://mcp.sdmu.edu.cn@evil.example/')).assertFalse();
    });

    it('trustedCampusSslHostValidation', 0, () => {
      expect(UrlSecurityHelper.isTrustedCampusSslHost('https://portal.sdmu.edu.cn/')).assertTrue();
      expect(UrlSecurityHelper.isTrustedCampusSslHost('https://sdmu.edu.cn/')).assertTrue();
      expect(UrlSecurityHelper.isTrustedCampusSslHost('https://external.example/')).assertFalse();
    });

    it('safeExternalUriValidation', 0, () => {
      expect(UrlSecurityHelper.isSafeExternalUri('https://www.sdmu.edu.cn')).assertTrue();
      expect(UrlSecurityHelper.isSafeExternalUri('tel:10086')).assertTrue();
      expect(UrlSecurityHelper.isSafeExternalUri('sms:10086')).assertTrue();
      expect(UrlSecurityHelper.isSafeExternalUri('mailto:admin@sdmu.edu.cn')).assertTrue();
      expect(UrlSecurityHelper.isSafeExternalUri('file:///data/local/tmp/a')).assertFalse();
      expect(UrlSecurityHelper.isSafeExternalUri('javascript:void(0)')).assertFalse();
      expect(UrlSecurityHelper.isSafeExternalUri('content://media/external/images/1')).assertFalse();
    });

    it('sanitizeFileNameAndMultipartToken', 0, () => {
      const cleanedName: string = UrlSecurityHelper.sanitizeFileName('../../evil/..\\report?.pdf');
      expect(cleanedName.indexOf('..') < 0).assertTrue();
      expect(cleanedName.indexOf('/') < 0).assertTrue();
      expect(cleanedName.indexOf('\\') < 0).assertTrue();
      expect(cleanedName.indexOf('?') < 0).assertTrue();

      const cleanedToken: string = UrlSecurityHelper.sanitizeMultipartToken('pic"\r\nX-Inject: 1');
      expect(cleanedToken.indexOf('\r') < 0).assertTrue();
      expect(cleanedToken.indexOf('\n') < 0).assertTrue();
      expect(cleanedToken.indexOf('"') < 0).assertTrue();
    });

    it('redactSecretMasking', 0, () => {
      expect(UrlSecurityHelper.redactSecret('')).assertEqual('<empty>');
      expect(UrlSecurityHelper.redactSecret('abcd')).assertEqual('***(4)');
      expect(UrlSecurityHelper.redactSecret('syw3vWQt2MuL')).assertEqual('syw3***(12)');
    });

    it('cryptoAndChallengeRandomness', 0, () => {
      const b1: Uint8Array = CryptoUtil.generateRandomBytes(16);
      const b2: Uint8Array = CryptoUtil.generateRandomBytes(16);
      expect(b1.byteLength).assertEqual(16);
      expect(b2.byteLength).assertEqual(16);
      let anyDiff: boolean = false;
      for (let i = 0; i < 16; i++) {
        if (b1[i] !== b2[i]) {
          anyDiff = true;
          break;
        }
      }
      expect(anyDiff).assertTrue();

      const c1: Uint8Array = BiometricAuthHelper.generateChallenge(16);
      expect(c1.byteLength).assertEqual(16);
    });
  });
}
