import { liveViewManager } from '@kit.LiveViewKit';

/**
 * P6：本地实况窗助手（LiveViewKit，无需学校服务端即可在本地创建/更新/结束会议或考试倒计时胶囊）
 */
export class LiveViewIntentHelper {
  /** 启动本地实况窗（如会议/考试倒计时） */
  public static async startLocalLiveView(
    id: number,
    title: string,
    contentText: string
  ): Promise<boolean> {
    try {
      const defaultView: liveViewManager.LiveView = {
        id: id,
        event: 'QUEUE',
        liveViewData: {
          primary: {
            title: title,
            content: [{ text: contentText }],
            keepTime: 15
          }
        }
      };
      await liveViewManager.startLiveView(defaultView);
      return true;
    } catch {
      return false;
    }
  }

  /** 结束本地实况窗 */
  public static async stopLocalLiveView(id: number): Promise<boolean> {
    try {
      const view: liveViewManager.LiveView = {
        id: id,
        event: 'QUEUE',
        liveViewData: {
          primary: {
            title: '',
            content: [{ text: '' }],
            keepTime: 0
          }
        }
      };
      await liveViewManager.stopLiveView(view);
      return true;
    } catch {
      return false;
    }
  }
}
