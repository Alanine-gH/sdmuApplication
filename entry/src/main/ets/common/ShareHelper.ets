import { systemShare } from '@kit.ShareKit';
import { uniformTypeDescriptor as utd } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';

/**
 * P4：系统分享与碰一碰分享助手（Share Kit）
 */
export class ShareHelper {
  /** 拉起系统分享面板（支持碰一碰/隔空传送/系统分享） */
  public static async shareText(
    context: common.UIAbilityContext,
    title: string,
    content: string,
    url?: string
  ): Promise<boolean> {
    try {
      const shareData: systemShare.SharedData = new systemShare.SharedData({
        utd: url ? utd.UniformDataType.HYPERLINK : utd.UniformDataType.PLAIN_TEXT,
        title: title,
        content: url ? url : content,
        description: content
      });
      const controller: systemShare.ShareController = new systemShare.ShareController(shareData);
      await controller.show(context, {
        selectionMode: systemShare.SelectionMode.SINGLE,
        previewMode: systemShare.SharePreviewMode.DEFAULT
      });
      return true;
    } catch {
      return false;
    }
  }
}
