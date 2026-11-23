import { generateBarcode, scanCore } from '@kit.ScanKit';
import { image } from '@kit.ImageKit';
import { photoAccessHelper } from '@kit.MediaLibraryKit';
import { fileIo as fs } from '@kit.CoreFileKit';
import { common } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';

export interface ContactQrParams {
  name: string;
  org?: string;
  title?: string;
  phone?: string;
  tel?: string;
  email?: string;
  address?: string;
}

export interface BarcodeGenerateResult {
  success: boolean;
  pixelMap: image.PixelMap | null;
  content: string;
  message: string;
}

export interface BarcodeSaveResult {
  success: boolean;
  uri: string;
  message: string;
}

/**
 * 离线二维码生成与安全保存助手（@kit.ScanKit generateBarcode + SaveButton + photoAccessHelper）
 * - QR 码严格控制在 512 字符上限及 [200, 4096] px 尺寸范围内
 * - 保存相册仅在 SaveButton SUCCESS 回调内调用，无需 WRITE_IMAGEVIDEO 权限
 */
export class BarcodeHelper {
  public static readonly MAX_QR_CHARS: number = 512;
  public static readonly DEFAULT_QR_SIZE_PX: number = 480;

  /** 纯函数：将二维码尺寸限制在 SDK 允许的 [200, 4096] px 区间 */
  public static clampBarcodeSize(sizePx: number): number {
    if (!Number.isFinite(sizePx) || sizePx <= 0) {
      return BarcodeHelper.DEFAULT_QR_SIZE_PX;
    }
    return Math.min(4096, Math.max(200, Math.round(sizePx)));
  }

  /** 纯函数：统一换行并按字符上限截断（默认 512 字符） */
  public static truncateQrContent(raw: string, maxChars: number = BarcodeHelper.MAX_QR_CHARS): string {
    if (!raw) {
      return '';
    }
    const normalized: string = raw.replace(/\r\n/g, '\n').replace(/\r/g, '\n').trim();
    if (normalized === '') {
      return '';
    }
    const safeCap: number = Number.isFinite(maxChars) && maxChars > 0
      ? Math.min(BarcodeHelper.MAX_QR_CHARS, Math.floor(maxChars))
      : BarcodeHelper.MAX_QR_CHARS;
    if (normalized.length <= safeCap) {
      return normalized;
    }
    return normalized.substring(0, safeCap);
  }

  private static cleanField(raw?: string): string {
    if (!raw) {
      return '';
    }
    return raw.replace(/[\r\n]+/g, ' ').trim();
  }

  /** 纯函数：构造不超过 512 字符的 vCard 3.0 联系人名片载荷 */
  public static buildContactVCard(params: ContactQrParams): string {
    const name: string = BarcodeHelper.cleanField(params.name);
    const org: string = BarcodeHelper.cleanField(params.org);
    const title: string = BarcodeHelper.cleanField(params.title);
    const phone: string = BarcodeHelper.cleanField(params.phone);
    const tel: string = BarcodeHelper.cleanField(params.tel);
    const email: string = BarcodeHelper.cleanField(params.email);
    const address: string = BarcodeHelper.cleanField(params.address);

    if (
      name === '' &&
      org === '' &&
      title === '' &&
      phone === '' &&
      tel === '' &&
      email === '' &&
      address === ''
    ) {
      return '';
    }

    const lines: string[] = ['BEGIN:VCARD', 'VERSION:3.0'];
    if (name !== '') {
      lines.push(`N:${name};;;`);
      lines.push(`FN:${name}`);
    }
    if (org !== '') {
      lines.push(`ORG:${org}`);
    }
    if (title !== '') {
      lines.push(`TITLE:${title}`);
    }
    if (phone !== '') {
      lines.push(`TEL;TYPE=CELL:${phone}`);
    }
    if (tel !== '') {
      lines.push(`TEL;TYPE=WORK:${tel}`);
    }
    if (email !== '') {
      lines.push(`EMAIL:${email}`);
    }
    if (address !== '') {
      lines.push(`ADR;TYPE=WORK:;;${address};;;;`);
    }
    lines.push('END:VCARD');

    const full: string = lines.join('\n');
    if (full.length <= BarcodeHelper.MAX_QR_CHARS) {
      return full;
    }

    // 超长时优先保留核心名片字段并确保 END:VCARD 完整闭合
    const coreLines: string[] = ['BEGIN:VCARD', 'VERSION:3.0'];
    if (name !== '') {
      coreLines.push(`FN:${name.substring(0, 64)}`);
    }
    if (phone !== '') {
      coreLines.push(`TEL;TYPE=CELL:${phone.substring(0, 40)}`);
    } else if (tel !== '') {
      coreLines.push(`TEL;TYPE=WORK:${tel.substring(0, 40)}`);
    }
    if (email !== '') {
      coreLines.push(`EMAIL:${email.substring(0, 80)}`);
    }
    if (org !== '') {
      coreLines.push(`ORG:${org.substring(0, 64)}`);
    }
    if (title !== '') {
      coreLines.push(`TITLE:${title.substring(0, 48)}`);
    }
    if (address !== '') {
      coreLines.push(`ADR;TYPE=WORK:;;${address.substring(0, 64)};;;;`);
    }
    const footer: string = '\nEND:VCARD';
    const bodyLimit: number = BarcodeHelper.MAX_QR_CHARS - footer.length;
    const compactBody: string = coreLines.join('\n');
    if (compactBody.length <= bodyLimit) {
      return compactBody + footer;
    }
    return compactBody.substring(0, bodyLimit) + footer;
  }

  /** 纯函数：构造科研/报销项目二维码摘要（<= 512 字符） */
  public static buildProjectQrPayload(
    projectNumber: string,
    name: string,
    type: string,
    status: string,
    contractAmt: string,
    receiveAmt: string,
    payAmt: string
  ): string {
    const parts: string[] = [];
    const num: string = BarcodeHelper.cleanField(projectNumber);
    const pName: string = BarcodeHelper.cleanField(name);
    const pType: string = BarcodeHelper.cleanField(type);
    const pStatus: string = BarcodeHelper.cleanField(status);
    const pContract: string = BarcodeHelper.cleanField(contractAmt);
    const pReceive: string = BarcodeHelper.cleanField(receiveAmt);
    const pPay: string = BarcodeHelper.cleanField(payAmt);

    if (num !== '') {
      parts.push(`项目编号:${num}`);
    }
    if (pName !== '') {
      parts.push(`项目名称:${pName}`);
    }
    if (pType !== '') {
      parts.push(`项目类型:${pType}`);
    }
    if (pStatus !== '') {
      parts.push(`状态:${pStatus}`);
    }
    if (pContract !== '') {
      parts.push(`合同额:${pContract}`);
    }
    if (pReceive !== '') {
      parts.push(`到款额:${pReceive}`);
    }
    if (pPay !== '') {
      parts.push(`已支出:${pPay}`);
    }
    if (parts.length === 0) {
      return '';
    }
    return BarcodeHelper.truncateQrContent(parts.join('\n'), BarcodeHelper.MAX_QR_CHARS);
  }

  /** 纯函数：构造课程信息二维码摘要（<= 512 字符） */
  public static buildCourseQrPayload(
    courseName: string,
    weekTime: string,
    session: string,
    place: string,
    classtime: string,
    teacher: string
  ): string {
    const parts: string[] = [];
    const name: string = BarcodeHelper.cleanField(courseName);
    const week: string = BarcodeHelper.cleanField(weekTime);
    const sec: string = BarcodeHelper.cleanField(session);
    const room: string = BarcodeHelper.cleanField(place);
    const clock: string = BarcodeHelper.cleanField(classtime);
    const tea: string = BarcodeHelper.cleanField(teacher);

    if (name !== '') {
      parts.push(`课程:${name}`);
    }
    if (week !== '') {
      parts.push(`周次:${week}`);
    }
    if (sec !== '') {
      parts.push(`节次:${sec}`);
    }
    if (clock !== '') {
      parts.push(`时间:${clock}`);
    }
    if (room !== '') {
      parts.push(`地点:${room}`);
    }
    if (tea !== '') {
      parts.push(`教师:${tea}`);
    }
    if (parts.length === 0) {
      return '';
    }
    return BarcodeHelper.truncateQrContent(parts.join('\n'), BarcodeHelper.MAX_QR_CHARS);
  }

  /** 纯函数：将 ScanKit / 保存错误码映射为可读中文提示 */
  public static formatBarcodeError(code: number): string {
    if (code === 201) {
      return '未获得相册写入权限，请点击保存按钮授权';
    }
    if (code === 401) {
      return '二维码内容或尺寸超出限制';
    }
    if (code === 1000500001) {
      return '二维码生成服务暂不可用';
    }
    return '二维码操作失败，请稍后重试';
  }

  /** 生成本地二维码 PixelMap */
  public static async generateQrPixelMap(
    content: string,
    sizePx: number = BarcodeHelper.DEFAULT_QR_SIZE_PX
  ): Promise<BarcodeGenerateResult> {
    const bounded: string = BarcodeHelper.truncateQrContent(content, BarcodeHelper.MAX_QR_CHARS);
    if (bounded === '') {
      return {
        success: false,
        pixelMap: null,
        content: '',
        message: '二维码内容为空'
      };
    }
    const safeSize: number = BarcodeHelper.clampBarcodeSize(sizePx);
    try {
      const options: generateBarcode.CreateOptions = {
        scanType: scanCore.ScanType.QR_CODE,
        width: safeSize,
        height: safeSize,
        backgroundColor: 0xFFFFFF,
        pixelMapColor: 0x000000,
        margin: 2,
        level: generateBarcode.ErrorCorrectionLevel.LEVEL_M
      };
      const pixelMap: image.PixelMap = await generateBarcode.createBarcode(bounded, options);
      return {
        success: true,
        pixelMap: pixelMap,
        content: bounded,
        message: ''
      };
    } catch (err) {
      const be = err as BusinessError;
      return {
        success: false,
        pixelMap: null,
        content: bounded,
        message: BarcodeHelper.formatBarcodeError(be.code ?? -1)
      };
    }
  }

  /**
   * 仅应在 SaveButton OnClickResult.SUCCESS 回调内调用：
   * 将 PixelMap 打包写入系统相册（packToFile 完成前禁止释放 PixelMap）
   */
  public static async savePixelMapToGallery(
    context: common.Context,
    pixelMap: image.PixelMap | null
  ): Promise<BarcodeSaveResult> {
    if (!context || pixelMap === null) {
      return {
        success: false,
        uri: '',
        message: '二维码尚未生成，无法保存'
      };
    }
    let file: fs.File | null = null;
    let packer: image.ImagePacker | null = null;
    try {
      const helper: photoAccessHelper.PhotoAccessHelper = photoAccessHelper.getPhotoAccessHelper(context);
      const uri: string = await helper.createAsset(photoAccessHelper.PhotoType.IMAGE, 'png');
      file = fs.openSync(uri, fs.OpenMode.READ_WRITE | fs.OpenMode.TRUNC);
      packer = image.createImagePacker();
      const packOpts: image.PackingOption = {
        format: 'image/png',
        quality: 100
      };
      await packer.packToFile(pixelMap, file.fd, packOpts);
      return {
        success: true,
        uri: uri,
        message: '已保存到相册'
      };
    } catch (err) {
      const be = err as BusinessError;
      return {
        success: false,
        uri: '',
        message: BarcodeHelper.formatBarcodeError(be.code ?? -1)
      };
    } finally {
      if (packer !== null) {
        try {
          packer.release();
        } catch {
          // 忽略释放异常
        }
      }
      if (file !== null) {
        try {
          fs.closeSync(file);
        } catch {
          // 忽略关闭异常
        }
      }
    }
  }
}
