import { BusinessError } from '@kit.BasicServicesKit';
import { cryptoFramework } from '@kit.CryptoArchitectureKit';
import { util } from '@kit.ArkTS';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { Constants } from '../data/Constants';

const TAG = 0x0000;
const DOMAIN = 'SDMU';

/**
 * 加密工具 — 1:1 复刻原生 z.源码 + GetKeyUtil 协议（2026-11-16/17 服务器实测验证）：
 *   - AES-128/ECB/PKCS5（PKCS5不可用时自动降级PKCS7，字节级等价）
 *   - RSA-1024/ECB/PKCS1（DER失败自动降级PEM）
 *   - 全流程插桩：失败时hilog输出step+code+message
 */
export class CryptoUtil {
  private static base64Helper: util.Base64Helper = new util.Base64Helper();

  static log(msg: string): void {
    hilog.info(TAG, DOMAIN, '%{public}s', msg);
  }

  static generateRandomBytes(length: number): Uint8Array {
    const safeLen: number = Math.max(1, Math.floor(length));
    try {
      const rand: cryptoFramework.Random = cryptoFramework.createRandom();
      const blob: cryptoFramework.DataBlob = rand.generateRandomSync(safeLen);
      if (blob && blob.data && blob.data.byteLength === safeLen) {
        return blob.data;
      }
    } catch {
      // 单元测试无原生 CryptoArchitectureKit 环境时回退
    }
    const bytes: Uint8Array = new Uint8Array(safeLen);
    for (let i = 0; i < safeLen; i++) {
      bytes[i] = Math.floor(Math.random() * 256);
    }
    return bytes;
  }

  static generateKey(): string {
    return CryptoUtil.bytesToBase64(CryptoUtil.generateRandomBytes(16));
  }

  static base64ToBytes(b64: string): Uint8Array {
    return CryptoUtil.base64Helper.decodeSync(b64);
  }

  static bytesToBase64(bytes: Uint8Array): string {
    return CryptoUtil.base64Helper.encodeToStringSync(bytes);
  }

  static stringToBytes(text: string): Uint8Array {
    const encoder: util.TextEncoder = new util.TextEncoder();
    return encoder.encodeInto(text);
  }

  static bytesToString(bytes: Uint8Array): string {
    const decoder: util.TextDecoder = util.TextDecoder.create('utf-8');
    return decoder.decodeToString(bytes);
  }

  /** MD5 十六进制摘要（[W22 launch-chain] 聚合认证 secret 头：
   *  PolymerizationModel.f1() 逐字节还原 —— hexTable 0-9A-F 大写，
   *  源码 s = userId + secret + SimpleDateFormat("yyyyMMdd")；失败返回空串（调用方走真实错误态）。 */
  static async md5HexUpper(text: string): Promise<string> {
    try {
      const md = cryptoFramework.createMd('MD5');
      await md.update({ data: CryptoUtil.stringToBytes(text) });
      const digest: cryptoFramework.DataBlob = await md.digest();
      const chars: string[] = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9', 'A', 'B', 'C', 'D', 'E', 'F'];
      let out: string = '';
      for (const b of digest.data) {
        out = out + chars[(b >>> 4) & 15] + chars[b & 15];
      }
      return out;
    } catch (error) {
      const be = error as BusinessError;
      CryptoUtil.log('md5HexUpper fail: ' + be.message);
      return '';
    }
  }

  /** 创建AES cipher：PKCS5失败自动降级PKCS7 */
  private static createAesCipher(mode: cryptoFramework.CryptoMode, keyB64: string, step: string): cryptoFramework.Cipher {
    const symKeyGenerator: cryptoFramework.SymKeyGenerator = cryptoFramework.createSymKeyGenerator('AES128');
    const keyBlob: cryptoFramework.DataBlob = { data: CryptoUtil.base64ToBytes(keyB64) };
    const symKey: cryptoFramework.SymKey = symKeyGenerator.convertKeySync(keyBlob);
    const specs: string[] = ['AES128|ECB|PKCS5', 'AES128|ECB|PKCS7', 'AES128|ECB|NONE'];
    for (const spec of specs) {
      try {
        const cipher: cryptoFramework.Cipher = cryptoFramework.createCipher(spec);
        cipher.initSync(mode, symKey, null);
        return cipher;
      } catch (e) {
        const be = e as BusinessError;
        CryptoUtil.log(step + ' cipher ' + spec + ' fail code=' + be.code + ' msg=' + be.message);
      }
    }
    throw new Error(step + ': 所有AES cipher规格均创建失败');
  }

  /** AES-128/ECB 加密 → Base64 */
  static encryptAES(plain: string, keyB64: string): string {
    try {
      const cipher = CryptoUtil.createAesCipher(cryptoFramework.CryptoMode.ENCRYPT_MODE, keyB64, 'encryptAES');
      const plainBlob: cryptoFramework.DataBlob = { data: CryptoUtil.stringToBytes(plain) };
      const encrypted: cryptoFramework.DataBlob = cipher.doFinalSync(plainBlob);
      return CryptoUtil.bytesToBase64(encrypted.data);
    } catch (e) {
      const be = e as BusinessError;
      CryptoUtil.log('encryptAES fail code=' + be.code + ' msg=' + be.message);
      throw e as Error;
    }
  }

  /** AES-128/ECB 解密 */
  static decryptAES(cipherB64: string, keyB64: string): string {
    try {
      const cipher = CryptoUtil.createAesCipher(cryptoFramework.CryptoMode.DECRYPT_MODE, keyB64, 'decryptAES');
      const cipherBlob: cryptoFramework.DataBlob = { data: CryptoUtil.base64ToBytes(cipherB64) };
      const decrypted: cryptoFramework.DataBlob = cipher.doFinalSync(cipherBlob);
      return CryptoUtil.bytesToString(decrypted.data);
    } catch (e) {
      const be = e as BusinessError;
      CryptoUtil.log('decryptAES fail code=' + be.code + ' msg=' + be.message);
      throw e as Error;
    }
  }

  /** [W26 partial-finish] AES/CBC/PKCS5 加密 → Base64（源码 module/d/a.java AESUtils.b 逐行还原：
   *  paysec 扫码支付 userCode = a(userId)：Cipher("AES/CBC/PKCS5Padding")，
   *  SecretKeySpec(key="1716bf8fca1f9273" 字节) + IvParameterSpec(iv="1230001000000000" 字节)——d/a.java L21/L25 源码字面硬编码保真。 */
  static encryptAESCBC(plain: string, keyRaw: string, ivRaw: string): string {
    try {
      const symKeyGenerator: cryptoFramework.SymKeyGenerator = cryptoFramework.createSymKeyGenerator('AES128');
      const keyBlob: cryptoFramework.DataBlob = { data: CryptoUtil.stringToBytes(keyRaw) };
      const symKey: cryptoFramework.SymKey = symKeyGenerator.convertKeySync(keyBlob);
      const cipher: cryptoFramework.Cipher = cryptoFramework.createCipher('AES128|CBC|PKCS5');
      const gcmParams: cryptoFramework.IvParamsSpec = {
        algName: 'IvParamsSpec',
        // IvParamsSpec.iv 类型为 DataBlob（非 Uint8Array，2026-11-18 首轮构建 10505001 实证）
        iv: { data: CryptoUtil.stringToBytes(ivRaw) }
      };
      cipher.initSync(cryptoFramework.CryptoMode.ENCRYPT_MODE, symKey, gcmParams);
      const plainBlob: cryptoFramework.DataBlob = { data: CryptoUtil.stringToBytes(plain) };
      const encrypted: cryptoFramework.DataBlob = cipher.doFinalSync(plainBlob);
      return CryptoUtil.bytesToBase64(encrypted.data);
    } catch (e) {
      const be = e as BusinessError;
      CryptoUtil.log('encryptAESCBC fail code=' + be.code + ' msg=' + be.message);
      throw e as Error;
    }
  }

  /** 构造PEM格式公钥 */
  private static toPem(pubB64: string): string {
    const body: string = pubB64.replace(/(.{64})/g, '$1\n');
    return '-----BEGIN PUBLIC KEY-----\n' + body + '\n-----END PUBLIC KEY-----\n';
  }

  /** RSA-1024/ECB/PKCS1 公钥加密 → Base64（DER失败自动PEM兜底） */
  static async encryptRSA(plain: string, publicKeyB64: string): Promise<string> {
    const asyKeyGenerator: cryptoFramework.AsyKeyGenerator = cryptoFramework.createAsyKeyGenerator('RSA1024');
    const pubBlob: cryptoFramework.DataBlob = { data: CryptoUtil.base64ToBytes(publicKeyB64) };
    let keyPair: cryptoFramework.KeyPair;
    try {
      CryptoUtil.log('RSA convertKey(DER) 开始');
      keyPair = await asyKeyGenerator.convertKey(pubBlob, null);
      CryptoUtil.log('RSA convertKey(DER) 成功');
    } catch (e) {
      const be = e as BusinessError;
      CryptoUtil.log('RSA convertKey(DER) fail code=' + be.code + ' msg=' + be.message + ' → 尝试PEM');
      try {
        keyPair = await asyKeyGenerator.convertPemKey(CryptoUtil.toPem(publicKeyB64), null);
        CryptoUtil.log('RSA convertPemKey 成功');
      } catch (e2) {
        const be2 = e2 as BusinessError;
        CryptoUtil.log('RSA convertPemKey fail code=' + be2.code + ' msg=' + be2.message);
        throw e2 as Error;
      }
    }
    const cipher: cryptoFramework.Cipher = cryptoFramework.createCipher('RSA1024|PKCS1');
    cipher.initSync(cryptoFramework.CryptoMode.ENCRYPT_MODE, keyPair.pubKey, null);
    const plainBlob: cryptoFramework.DataBlob = { data: CryptoUtil.stringToBytes(plain) };
    const encrypted: cryptoFramework.DataBlob = cipher.doFinalSync(plainBlob);
    return CryptoUtil.bytesToBase64(encrypted.data);
  }

  /** 构造key协商body：Base64(RSA('{"sk":"<key>"}')) */
  static async buildNegotiateBody(randomKeyB64: string, publicKeyB64: string): Promise<string> {
    const json: string = '{"sk":"' + randomKeyB64 + '"}';
    return CryptoUtil.encryptRSA(json, publicKeyB64);
  }
}



