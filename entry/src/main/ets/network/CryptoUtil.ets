import { cryptoFramework } from '@kit.CryptoArchitectureKit';
import { util } from '@kit.ArkTS';
import { Constants } from '../data/Constants';

/**
 * 加密工具 — 1:1 复刻安卓版 baselibrary/framework/util/z.smali + GetKeyUtil 协议：
 *   - AES-128/ECB/PKCS5Padding（z.smali "AES/ECB/PKCS5Padding"）
 *   - RSA-1024/ECB/PKCS1Padding（z.smali "RSA/ECB/PKCS1Padding"）
 *   - key协商：随机16字节key → Base64 → {"sk":key} → RSA公钥加密 → Base64
 *     POST /open/security/asym/key（头 Asym-Key: private）
 *   2026-11-16 已在真实服务器验证协商与响应解密全链路。
 */
export class CryptoUtil {
  private static base64Helper: util.Base64Helper = new util.Base64Helper();

  /** 随机16字节key → Base64（对应安卓 c.k(): KeyGenerator("AES")） */
  static generateKey(): string {
    const bytes: Uint8Array = new Uint8Array(16);
    for (let i = 0; i < 16; i++) {
      const r: number = Math.floor(Math.random() * 256);
      bytes[i] = r;
    }
    return CryptoUtil.bytesToBase64(bytes);
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

  /** AES-128/ECB/PKCS5 加密 → Base64（对应 z.encryptAES） */
  static async encryptAES(plain: string, keyB64: string): Promise<string> {
    const symKeyGenerator: cryptoFramework.SymKeyGenerator = cryptoFramework.createSymKeyGenerator('AES128');
    const keyBlob: cryptoFramework.DataBlob = { data: CryptoUtil.base64ToBytes(keyB64) };
    const symKey: cryptoFramework.SymKey = await symKeyGenerator.convertKey(keyBlob);
    const cipher: cryptoFramework.Cipher = cryptoFramework.createCipher('AES128|ECB|PKCS5');
    cipher.initSync(cryptoFramework.CryptoMode.ENCRYPT_MODE, symKey, null);
    const plainBlob: cryptoFramework.DataBlob = { data: CryptoUtil.stringToBytes(plain) };
    const encrypted: cryptoFramework.DataBlob = await cipher.doFinal(plainBlob);
    return CryptoUtil.bytesToBase64(encrypted.data);
  }

  /** AES-128/ECB/PKCS5 解密（对应 z.decryptAES） */
  static async decryptAES(cipherB64: string, keyB64: string): Promise<string> {
    const symKeyGenerator: cryptoFramework.SymKeyGenerator = cryptoFramework.createSymKeyGenerator('AES128');
    const keyBlob: cryptoFramework.DataBlob = { data: CryptoUtil.base64ToBytes(keyB64) };
    const symKey: cryptoFramework.SymKey = await symKeyGenerator.convertKey(keyBlob);
    const cipher: cryptoFramework.Cipher = cryptoFramework.createCipher('AES128|ECB|PKCS5');
    cipher.initSync(cryptoFramework.CryptoMode.DECRYPT_MODE, symKey, null);
    const cipherBlob: cryptoFramework.DataBlob = { data: CryptoUtil.base64ToBytes(cipherB64) };
    const decrypted: cryptoFramework.DataBlob = await cipher.doFinal(cipherBlob);
    return CryptoUtil.bytesToString(decrypted.data);
  }

  /** RSA-1024/ECB/PKCS1 公钥加密 → Base64（对应 z.encryptRSAByPublicKey） */
  static async encryptRSA(plain: string, publicKeyB64: string): Promise<string> {
    const asyKeyGenerator: cryptoFramework.AsyKeyGenerator = cryptoFramework.createAsyKeyGenerator('RSA1024');
    const pubBlob: cryptoFramework.DataBlob = { data: CryptoUtil.base64ToBytes(publicKeyB64) };
    const emptyBlob: cryptoFramework.DataBlob = { data: new Uint8Array() };
    const keyPair: cryptoFramework.KeyPair = await asyKeyGenerator.convertKey(emptyBlob, pubBlob);
    const cipher: cryptoFramework.Cipher = cryptoFramework.createCipher('RSA1024|PKCS1');
    cipher.initSync(cryptoFramework.CryptoMode.ENCRYPT_MODE, keyPair.pubKey, null);
    const plainBlob: cryptoFramework.DataBlob = { data: CryptoUtil.stringToBytes(plain) };
    const encrypted: cryptoFramework.DataBlob = await cipher.doFinal(plainBlob);
    return CryptoUtil.bytesToBase64(encrypted.data);
  }

  /**
   * 构造key协商body（1:1 复刻 GetKeyUtil.p方法）：
   * body = Base64(RSA公钥加密('{"sk":"<随机key>"}'))
   */
  static async buildNegotiateBody(randomKeyB64: string): Promise<string> {
    const json: string = '{"sk":"' + randomKeyB64 + '"}';
    return CryptoUtil.encryptRSA(json, Constants.RSA_PUBLIC_KEY);
  }
}


