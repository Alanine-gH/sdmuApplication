import { router } from '@kit.ArkUI';
import { request } from '@kit.BasicServicesKit';

/**
 * 应用更新页 — 源码级复刻 CustomAppUpdateActivity（baselibrary appUpdate 包，
 * DialogActivityTheme 对话框形态；onCreate 为加固 native，布局走 cretin 库 activity_update
 * type 族：默认 type2 + 设置页弹窗源布局 activity_custom_app_update）。
 * RootActivity 行为链：
 *   - tv_update（立即更新）→ G1()：a.x() 正在下载则 return；否则按钮文案"正在下载0%"
 *     （downloading 实值）→ K1()→E1()：非 WiFi 弹"提示/取消/确认"（wifi_tips）→ F1()：
 *     AppUpdateUtils.v().j(md5 回调).n(config) 真实下载 APK；
 *   - c 下载回调：start→"正在下载0%"、e(percent)→"正在下载N%"、complete→"立即更新"
 *     （btn_update_now 实值=已就绪）、d→"立即更新"+toast apk_file_download_fail"安装文件下载失败"；
 *   - a（取消）→ D1()（v().k() 取消下载）+ finish()；iv_close → finish()；
 *   - MD5 校验失败 → f0.c toast"文件MD5校验失败"。
 * 数据（versionText/contentText/apkUrl/md5）= DownloadInfo（cretin b.a 实体）经启动参数传入，
 * 无更新场景源码不会拉起本页；HAP 无 APK 安装器 → 下载完成后按源码恢复"立即更新"文案
 * （安装步骤为 Android 系统行为，无 HAP 等价）。
 */
@Entry
@Component
struct AppUpdatePage {
  /** variant=1：activity_custom_app_update 白卡（设置页"检测更新"弹窗源布局）；其余：type2 背景图族 */
  @State variant: number = 2;
  /** DownloadInfo 字段（路由参；缺省空串，不编造更新日志） */
  @State versionText: string = '';
  @State contentText: string = '';
  private apkUrl: string = '';
  private apkMd5: string = '';
  /** tv_update 文案（RootActivity.c 回调状态机） */
  @State btnText: string = '立即更新';
  @State downloading: boolean = false;
  private downloadTask: request.agent.Task | null = null;

  aboutToAppear(): void {
    const params: object | undefined = router.getParams() as object | undefined;
    if (params !== null && params !== undefined) {
      const record = params as Record<string, Object>;
      const v: Object = record['variant'];
      if (typeof v === 'number') {
        this.variant = v as number;
      }
      const ver: Object = record['versionText'];
      if (typeof ver === 'string') {
        this.versionText = ver as string;
      }
      const content: Object = record['contentText'];
      if (typeof content === 'string') {
        this.contentText = content as string;
      }
      const url: Object = record['apkUrl'];
      if (typeof url === 'string') {
        this.apkUrl = url as string;
      }
      const md5: Object = record['apkMd5'];
      if (typeof md5 === 'string') {
        this.apkMd5 = md5 as string;
      }
    }
    // variant 缺省 type2（cretin 默认对话框布局）
    if (this.variant !== 1) {
      this.variant = 2;
    }
    this.btnText = '立即更新';
  }

  /** G1()：a.x() 正在下载 return；否则开始下载（F1 等价 request.agent） */
  private startDownload(): void {
    if (this.downloading) {
      // com.cretin...a.x()：进行中幂等
      return;
    }
    if (this.apkUrl === '') {
      // 无下载目标（源码该页仅在服务端下发更新时拉起）→ 走失败回调链如实提示
      this.onDownloadFail();
      return;
    }
    this.downloading = true;
    this.btnText = '正在下载0%';
    this.doDownload();
  }

  /** F1()：request.agent 真实下载（进度→c.e(percent)，完成→c.c，失败→c.d） */
  private doDownload(): void {
    const ctx: Context | undefined = this.getUIContext().getHostContext();
    if (ctx === undefined || ctx === null) {
      this.onDownloadFail();
      return;
    }
    const cfg: request.agent.Config = {
      action: request.agent.Action.DOWNLOAD,
      url: this.apkUrl,
      saveas: 'update.apk'
    };
    request.agent.create(ctx, cfg)
      .then((task: request.agent.Task) => {
        this.downloadTask = task;
        // c.a downloadStart / c.e downloading=N%
        task.on('progress', (progress: request.agent.Progress) => {
          const total: number = progress.sizes.length > 0 ? progress.sizes[0] : 0;
          const percent: number = Math.floor(progress.processed * 100 / Math.max(total, 1));
          this.btnText = '正在下载' + String(percent) + '%';
        });
        task.on('completed', (progress: request.agent.Progress) => {
          // c.c downloadComplete → btn_update_now（已就绪；HAP 无 APK 安装器等价）
          this.downloading = false;
          this.btnText = '立即更新';
        });
        task.on('failed', (progress: request.agent.Progress) => {
          this.onDownloadFail();
        });
        task.start()
          .catch(() => {
            this.onDownloadFail();
          });
      })
      .catch(() => {
        this.onDownloadFail();
      });
  }

  /** c.d：d(str) → 按钮复位 + toast apk_file_download_fail"安装文件下载失败" */
  private onDownloadFail(): void {
    this.downloading = false;
    this.btnText = '立即更新';
    this.getUIContext().getPromptAction().showToast({ message: '安装文件下载失败' });
  }

  /** a（取消）：D1() 取消下载 + finish */
  private cancelDownload(): void {
    if (this.downloadTask !== null) {
      this.downloadTask.stop()
        .catch(() => {
        });
    }
    this.downloading = false;
    router.back();
  }

  @Builder
  /** variant=1：activity_custom_app_update 白卡（DialogActivityTheme 遮罩） */
  cardStyle() {
    Column() {
      Text('发现新版本，是否更新？')
        .fontSize(17)
        .fontWeight(FontWeight.Bold)
        .fontColor('#FF000000')
        .textAlign(TextAlign.Center)
        .maxLines(1)
        .width('100%')
        .padding({ top: 24 })

      Text(this.contentText)
        .fontSize(16)
        .fontColor($r('app.color.explain_color'))
        .textAlign(TextAlign.Center)
        .lineHeight(24)
        .padding({ left: 20, right: 20, top: 24, bottom: 24 })
        .width('100%')

      Divider()
        .color($r('app.color.update_dialog_divider'))
        .strokeWidth(0.5)
        .width('100%')

      Row() {
        Text('取消')
          .fontSize(17)
          .fontColor('#FF999999')
          .textAlign(TextAlign.Center)
          .maxLines(1)
          .layoutWeight(1)
          .padding({ left: 20, right: 20, top: 11.5, bottom: 11.5 })
          .onClick(() => {
            // tvLeftText → a：D1() + finish
            this.cancelDownload();
          })

        Divider()
          .vertical(true)
          .color($r('app.color.update_dialog_divider'))
          .strokeWidth(0.5)
          .height('100%')

        Text(this.btnText)
          .fontSize(17)
          .fontColor($r('app.color.sdmu_primary'))
          .textAlign(TextAlign.Center)
          .maxLines(1)
          .layoutWeight(1)
          .padding({ left: 20, right: 20, top: 11.5, bottom: 11.5 })
          .onClick(() => {
            // tvRightText → b：G1()
            this.startDownload();
          })
      }
      .width('100%')
    }
    .width('100%')
    .borderRadius(16)
    .backgroundColor($r('app.color.white'))
  }

  build() {
    if (this.variant === 1) {
      // DialogActivityTheme：半透明遮罩 + 居中白卡
      Stack() {
        Column()
          .width('100%')
          .height('100%')
          .backgroundColor($r('app.color.alpha_20'))

        Column() {
          this.cardStyle()
        }
        .width('86%')
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#FF1A1A1A')
    } else {
      // type2：dialog_update_bg 整幅背景 + tv_version + tv_content + tv_update + 下方 iv_close
      Column() {
        Stack() {
          Image($r('app.media.dialog_update_bg'))
            .objectFit(ImageFit.Fill)
            .width('100%')
            .height('100%')

          Column() {
            Blank()
              .height(84)
            if (this.versionText !== '') {
              // tv_version：16sp bold 白 margin(20,28) padH10 padV2
              Text(this.versionText)
                .fontSize(16)
                .fontWeight(FontWeight.Bold)
                .fontColor('#FFFFFFFF')
                .padding({ left: 10, right: 10, top: 2, bottom: 2 })
                .width('100%')
            }
            // tv_content：14sp #4b4b4b marginH30 maxLines10
            Text(this.contentText)
              .fontSize(14)
              .fontColor('#FF4B4B4B')
              .lineHeight(19)
              .maxLines(10)
              .padding({ left: 30, right: 30 })
              .width('100%')
              .layoutWeight(1)

            // tv_update：light_orange_button_round marginH30 V30
            Text(this.btnText)
              .fontSize(14)
              .fontColor(Color.White)
              .textAlign(TextAlign.Center)
              .padding(10)
              .borderRadius(25)
              .backgroundColor($r('app.color.update_light_orange'))
              .margin({ left: 30, right: 30, top: 15, bottom: 15 })
              .width('calc(100% - 60vp)')
              .onClick(() => {
                // b：G1()
                this.startDownload();
              })
          }
          .width('100%')
          .height('100%')
        }
        .width('100%')
        .layoutWeight(1)

        // iv_close：下方居中关闭
        Column() {
          Image($r('app.media.update_close_img'))
            .objectFit(ImageFit.Contain)
            .width(20)
            .height(20)
            .padding(10)
            .onClick(() => {
              // RootActivity.iv_close → finish
              router.back();
            })
        }
        .width('100%')
        .justifyContent(FlexAlign.Center)
        .margin({ top: 5 })
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#FF1A1A1A')
    }
  }
}
