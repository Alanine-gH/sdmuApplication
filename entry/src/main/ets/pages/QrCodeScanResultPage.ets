import { router } from '@kit.ArkUI';
import { TitleBar } from '../components/TitleBar';

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
