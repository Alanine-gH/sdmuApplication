/**
 * 后台更新宿主页 — 源码级翻译（UpdateBackgroundActivity.java，[W25 misc-b]）：
 *
 * 【源码】com.cretin.www.cretinautoupdatelibrary.activity.UpdateBackgroundActivity extends RootActivity：
 *   三方 cretin 自动更新库"后台静默下载"型宿主 Activity——onCreate 为壳（StubApp native），I1() 返回 null
 *   （无 UpdateConfiguration），无任何自有布局与 UI（配套下载经 UpdateService/DownloadService 后台完成）。
 *   APK 中该 Activity 由更新库内部拉起，非用户入口页。
 * 【HAP 等价】透明空壳页（无 toolbar、无内容、无编造更新详情/进度）——原占位版含假更新文案与假进度
 *   动画已清除（禁 mock）；HAP 包体系无 APK 下载安装语义，静默下载宿主行为保留为无 UI 中转。
 */
@Entry
@Component
struct UpdateBackgroundPage {
  build() {
    Column()
      .width('100%')
      .height('100%')
      .backgroundColor(Color.Transparent)
  }
}
