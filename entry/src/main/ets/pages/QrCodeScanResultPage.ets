import { router } from '@kit.ArkUI';
import { TitleBar } from '../components/TitleBar';
import { PasteHelper } from '../common/PasteHelper';

/**
 * 扫码结果页 — 源码级翻译（QrCodeScanResultActivity.java 逐行 → ArkTS，[W25 misc-b]）：
 *
 * 【布局】activity_qr_code_scan_result.xml：竖向根 + toolbar_normal + tvContent 16sp black pad15 可复制
 * 【入参】y(Intent)/f1()：tvContent = getIntent().getStringExtra("QrCodeScanResult")（源码键名；
 *   兼容 'content' 键避免旧调用方断链）
 * 【入口】AppSearchActivity 扫码结果无 URI 可解析时 → QrCodeScanResultActivity{QrCodeScanResult}；
 *   标题：源码 H0()=null 且 T1 未设置 → toolbar 无标题文本
 */
@Entry
@Component
struct QrCodeScanResultPage {
  @State resultContent: string = ''; // 零容忍：不展示编造扫码结果，内容仅来自真实扫码参数

  aboutToAppear(): void {
    const params = router.getParams() as Record<string, string>;
    if (params !== null && params !== undefined) {
      const q = params['QrCodeScanResult'];
      if (q !== undefined && q !== null) {
        this.resultContent = q;
        return;
      }
      const c = params['content'];
      this.resultContent = c !== undefined && c !== null ? c : '';
    }
  }

  build() {
    Column() {
      // 源码 toolbar 无标题（H0()=null 且 T1 无 gVar.n()）
      TitleBar({ title: '', showBack: true })

      Scroll() {
        Column() {
          Column() {
            Text(this.resultContent)
              .fontSize(16)
              .fontColor($r('app.color.black'))
              .width('100%')
              .copyOption(CopyOptions.InApp)
          }
          .width('100%')
          .padding(15)
          .backgroundColor($r('app.color.white'))

          Row({ space: 12 }) {
            PasteButton({
              icon: PasteIconStyle.LINES,
              text: PasteDescription.PASTE,
              buttonType: ButtonType.Capsule
            })
              .height(34)
              .fontSize(13)
              .iconSize(13)
              .fontColor($r('app.color.white'))
              .iconColor($r('app.color.white'))
              .backgroundColor($r('app.color.sdmu_primary'))
              .padding({ left: 14, right: 14, top: 6, bottom: 6 })
              .onClick(async (_event: ClickEvent, result: PasteButtonOnClickResult) => {
                if (result !== PasteButtonOnClickResult.SUCCESS) {
                  this.getUIContext().getPromptAction().showToast({ message: '未获得剪贴板授权' });
                  return;
                }
                const res = await PasteHelper.readPlainTextFromSystemPasteboard();
                if (!res.success) {
                  this.getUIContext().getPromptAction().showToast({ message: res.message });
                  return;
                }
                this.resultContent = res.text;
                this.getUIContext().getPromptAction().showToast({ message: '已从剪贴板导入内容' });
              })

            if (PasteHelper.isHttpUrl(this.resultContent)) {
              Text('打开链接')
                .fontSize(13)
                .fontColor($r('app.color.white'))
                .backgroundColor('#18B4ED')
                .borderRadius(17)
                .height(34)
                .textAlign(TextAlign.Center)
                .padding({ left: 16, right: 16 })
                .onClick(() => {
                  router.pushUrl({
                    url: 'pages/WebViewPage',
                    params: {
                      navigationBarTitle: '扫码结果',
                      url: this.resultContent.trim(),
                      isZoom: true
                    }
                  });
                })
            }
          }
          .width('100%')
          .padding({ left: 15, right: 15, top: 12, bottom: 16 })
          .alignItems(VerticalAlign.Center)
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)
      }
      .width('100%')
      .layoutWeight(1)
      .scrollBar(BarState.Off)
      .align(Alignment.Top)
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.white'))
    .alignItems(HorizontalAlign.Start)
  }
}
