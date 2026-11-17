import { router } from '@kit.ArkUI';
import { TitleBar } from '../components/TitleBar';

/**
 * 扫码结果页 — 1:1 复刻 activity_qr_code_scan_result.xml：
 * 竖向根 + toolbar_normal + 结果文本 16fp 黑 pad15 可复制
 */
class ScanResultParams {
  content: string = '';
}

@Entry
@Component
struct QrCodeScanResultPage {
  @State resultContent: string = 'https://portal.sdmu.edu.cn/scan?ticket=8f3a2c';

  aboutToAppear(): void {
    const params: object | undefined = router.getParams() as object | undefined;
    if (params !== undefined && params instanceof ScanResultParams) {
      this.resultContent = params.content;
    }
  }

  build() {
    Column() {
      TitleBar({ title: '扫码结果', showBack: true })

      Text(this.resultContent)
        .fontSize(16)
        .fontColor($r('app.color.black'))
        .padding(15)
        .width('100%')
        .copyOption(CopyOptions.InApp)
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.white'))
    .alignItems(HorizontalAlign.Start)
  }
}
