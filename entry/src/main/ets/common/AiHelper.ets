import { textRecognition } from '@kit.CoreVisionKit';
import { image } from '@kit.ImageKit';

/**
 * P5：端侧 AI 能力助手（CoreVisionKit 文字识别 OCR）
 */
export class AiHelper {
  /** 从 PixelMap 识别文字（用于票据/报销单端侧 OCR 自动填充） */
  public static async recognizeTextFromPixelMap(pixelMap: image.PixelMap): Promise<string> {
    try {
      const visionInfo: textRecognition.VisionInfo = {
        pixelMap: pixelMap
      };
      const result: textRecognition.TextRecognitionResult = await textRecognition.recognizeText(visionInfo);
      return result.value ? result.value : '';
    } catch {
      return '';
    }
  }
}
