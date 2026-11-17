import { router } from '@kit.ArkUI';

/**
 * 应用更新弹窗页 — 1:1 复刻源布局 activity_custom_app_update / activity_update_type2~12 / download_dialog_super
 * variant=1: activity_custom_app_update（16vp 圆角白卡 + 标题 + 说明 + 取消/立即更新双按钮）
 * variant=2/3/5/6/7/9/10: activity_update_type2 同族（整幅背景图 + 版本标签 + 说明 + 单个立即更新按钮 + 下方关闭）
 * variant=4: activity_update_type4（左上关闭 + 说明 + 单按钮）
 * variant=8/12: activity_update_type8/12（说明 + 暂不更新/立即更新双按钮 + 下方关闭）
 * variant=11: activity_update_type11（右上关闭 + 版本标签 + 双按钮）
 * 换算规则：dip→vp、sp→fp 一比一（源布局实测值）
 */
const UPDATE_CONTENT: string = '【新增】短视频首页增加今日热门\n【新增】校园风光支持高清大图浏览\n' +
  '【优化】修复部分机型课表显示异常的问题\n【优化】提升应用启动速度与整体稳定性';

@Entry
@Component
struct AppUpdatePage {
  @State variant: number = 1;
  @State versionText: string = 'V6.2.0';
  @State contentText: string = UPDATE_CONTENT;

  aboutToAppear(): void {
    const params: object = router.getParams();
    if (params !== null && params !== undefined) {
      const record = params as Record<string, Object>;
      const v: Object = record['variant'];
      if (typeof v === 'number') {
        this.variant = v;
      }
    }
  }

  /** 各 variant 对应的背景图资源（实测源布局 mipmap 引用） */
  private bgRes(): Resource {
    if (this.variant >= 3 && this.variant <= 12) {
      return $r(`app.media.dialog_bg_type_${this.variant}`);
    }
    return $r('app.media.dialog_update_bg');
  }

  /** 是否为"下方关闭图标"族（type2/3/5/6/7/9/10/12） */
  private isCloseBelow(): boolean {
    return this.variant === 2 || this.variant === 3 || this.variant === 5 || this.variant === 6 ||
      this.variant === 7 || this.variant === 9 || this.variant === 10 || this.variant === 12;
  }

  /** 是否为双按钮族（type8/11/12） */
  private isDualButton(): boolean {
    return this.variant === 8 || this.variant === 11 || this.variant === 12;
  }

  /** 是否显示版本标签（type4 与 download_dialog_super 无版本标签） */
  private hasVersion(): boolean {
    return this.variant !== 4;
  }

  /** 说明区左右留白 */
  private contentPad(): number {
    if (this.variant === 4 || this.variant === 11 || this.variant === 12) {
      return 60;
    }
    return 30;
  }

  private goDownload(): void {
    router.replaceUrl({ url: 'pages/DownloadDialogPage' });
  }

  private closeUpdate(): void {
    router.back();
  }

  @Builder
  /** variant=1：activity_custom_app_update —— 16vp 圆角白卡 */
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
            this.closeUpdate();
          })

        Divider()
          .vertical(true)
          .color($r('app.color.update_dialog_divider'))
          .strokeWidth(0.5)
          .height('100%')

        Text('立即更新')
          .fontSize(17)
          .fontColor($r('app.color.mobile_campus_primary_color'))
          .textAlign(TextAlign.Center)
          .maxLines(1)
          .layoutWeight(1)
          .padding({ left: 20, right: 20, top: 11.5, bottom: 11.5 })
          .onClick(() => {
            this.goDownload();
          })
      }
      .width('100%')
    }
    .width('100%')
    .borderRadius(16)
    .backgroundColor($r('app.color.white'))
  }

  @Builder
  /** variant=8/11/12：双按钮区（暂不更新描边 / 立即更新实底） */
  dualButtons() {
    Row() {
      Text('暂不更新')
        .fontSize(14)
        .fontColor($r('app.color.update_btn_pink'))
        .textAlign(TextAlign.Center)
        .maxLines(1)
        .layoutWeight(1)
        .padding({ top: this.variant === 11 ? 7 : 4, bottom: this.variant === 11 ? 7 : 4 })
        .borderRadius(25)
        .border({
          width: 1,
          color: this.variant === 12 ? $r('app.color.update_btn_orange') : $r('app.color.update_btn_pink')
        })
        .margin({
          left: this.variant === 8 ? 35 : (this.variant === 12 ? 45 : 55),
          right: this.variant === 8 ? 5 : 7
        })
        .onClick(() => {
          this.closeUpdate();
        })

      Text('立即更新')
        .fontSize(14)
        .fontColor(this.variant === 8 ? $r('app.color.update_btn_red') : '#FFFFFFFF')
        .textAlign(TextAlign.Center)
        .maxLines(1)
        .layoutWeight(1)
        .padding({ top: this.variant === 11 ? 7 : 4, bottom: this.variant === 11 ? 7 : 4 })
        .borderRadius(25)
        .backgroundColor(this.variant === 8 ? $r('app.color.white') :
        (this.variant === 11 ? $r('app.color.update_btn_orange_light') : $r('app.color.update_btn_orange')))
        .margin({
          left: this.variant === 8 ? 5 : 7,
          right: this.variant === 8 ? 35 : (this.variant === 12 ? 45 : 55)
        })
        .onClick(() => {
          this.goDownload();
        })
    }
    .width('100%')
    .margin({ top: this.variant === 8 ? 25 : (this.variant === 12 ? 15 : 25), bottom: 40 })
  }

  @Builder
  /** 整幅背景图族：版本标签 + 说明 + 按钮区 */
  bgStyle() {
    Column() {
      // 顶部区域：版本标签 / 关闭按钮位置按 variant 区分
      if (this.variant === 11) {
        Stack({ alignContent: Alignment.TopEnd }) {
          Text(this.versionText)
            .fontSize(17)
            .fontWeight(FontWeight.Bold)
            .fontColor('#FFFFFFFF')
            .padding({ left: 10, right: 10, top: 2, bottom: 20 })
            .margin({ top: 100, right: 50 })
        }
        .width('100%')
        .layoutWeight(5)
      } else if (this.variant === 4) {
        Stack({ alignContent: Alignment.TopStart }) {
          Image($r('app.media.update_close'))
            .objectFit(ImageFit.Contain)
            .width(20)
            .height(20)
            .padding(10)
            .margin({ left: 30, top: 25 })
            .onClick(() => {
              this.closeUpdate();
            })
        }
        .width('100%')
        .layoutWeight(3)
      } else if (this.variant === 8) {
        Stack({ alignContent: Alignment.BottomEnd }) {
          Text(this.versionText)
            .fontSize(14)
            .fontColor('#FFFFFFFF')
            .padding({ left: 10, right: 10, top: 2, bottom: 2 })
            .margin({ right: 30, bottom: 15 })
        }
        .width('100%')
        .layoutWeight(8)
      } else if (this.variant === 12) {
        Row() {
          Text(this.versionText)
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor('#FFFFFFFF')
            .padding({ left: 10, right: 10, top: 2, bottom: 2 })
            .margin({ left: 30, bottom: 15 })
        }
        .width('100%')
        .layoutWeight(5)
      } else {
        Stack({ alignContent: Alignment.TopStart }) {
          Text(this.versionText)
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor('#FFFFFFFF')
            .padding({ left: 10, right: 10, top: 2, bottom: 2 })
            .margin({ left: 20, top: 28 })
        }
        .width('100%')
        .layoutWeight(1)
      }

      // 说明文本
      Text(this.contentText)
        .fontSize(14)
        .fontColor($r('app.color.update_content_gray'))
        .lineHeight(21)
        .padding({ left: this.contentPad(), right: this.contentPad() })
        .width('100%')
        .layoutWeight(this.variant === 11 ? 8 : 4)
        .constraintSize({ minHeight: 100 })

      // 按钮区
      if (this.isDualButton()) {
        this.dualButtons()
      } else {
        Text('立即更新')
          .fontSize(14)
          .fontColor('#FFFFFFFF')
          .textAlign(TextAlign.Center)
          .padding(10)
          .borderRadius(25)
          .backgroundColor($r('app.color.update_light_orange'))
          .margin({
            left: this.variant === 4 ? 80 : 30,
            right: this.variant === 4 ? 80 : 30,
            top: this.variant === 4 ? 10 : 30,
            bottom: this.variant === 4 ? 40 : 30
          })
          .width('100%')
          .onClick(() => {
            this.goDownload();
          })
      }
    }
    .width('100%')
    .height('100%')
  }

  build() {
    if (this.variant === 1) {
      // activity_custom_app_update：半透明遮罩 + 居中 16vp 圆角白卡
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
      // type2~12：整幅背景图卡片区（layoutWeight 1）+ 可选下方关闭行
      Column() {
        Stack() {
          Image(this.bgRes())
            .objectFit(ImageFit.Fill)
            .width('100%')
            .height('100%')

          this.bgStyle()
        }
        .width('100%')
        .layoutWeight(1)

        if (this.variant === 11) {
          // type11：右上角关闭
          Column() {
            Image($r('app.media.update_close_img'))
              .objectFit(ImageFit.Contain)
              .width(20)
              .height(20)
              .padding(10)
              .onClick(() => {
                this.closeUpdate();
              })
          }
          .width('100%')
          .height(0)
        } else if (this.isCloseBelow()) {
          // type2/3/5/6/7/9/10/12：卡片下方居中关闭图标
          Column() {
            Image($r('app.media.update_close_img'))
              .objectFit(ImageFit.Contain)
              .width(20)
              .height(20)
              .padding(10)
              .onClick(() => {
                this.closeUpdate();
              })
          }
          .width('100%')
          .justifyContent(FlexAlign.Center)
          .margin({ top: 10 })
        } else {
          Column()
            .width('100%')
            .height(0)
        }
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#FF1A1A1A')
    }
  }
}
