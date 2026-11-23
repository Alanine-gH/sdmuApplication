import { router } from '@kit.ArkUI';
import { PreferencesUtil } from '../data/PreferencesUtil';
import { Constants } from '../data/Constants';
import { LoginSession } from '../network/LoginSession';
import { ThemeConstants } from '../common/ThemeConstants';
import { ImmersiveLightHelper } from '../common/ImmersiveLightHelper';
import { BreakpointSystem } from '../common/BreakpointSystem';

/**
 * 我的 Tab — 1:1 复刻 mobile_campus_fragment_my_page.xml
 * 结构：LinearLayout(mobile_campus_bg_color #F2F2F2)
 *   - toolbar_normal：45vp 白底，标题 17fp(px_to_sp_34) common_color_1 居中，底部细分隔线
 *   - layoutDetail：白底、marginTop 12vp(px24/2)、paddingH 12vp、高 88vp(px176/2)
 *     头像 64vp(px128/2) + 用户名 18.5fp #333333 + 单位信息 16fp #7D7D7D + arrow_right2
 *   - llLayout1：意见反馈、修改密码
 *   - llLayout2：下载地址、下载文件管理
 *   - 设置：一行
 *   - tvLogout：退出登录 17fp #E96161 居中、白底、paddingV 10vp(px20/2)、marginTop 32vp(px64/2)
 * 菜单行：高 48vp(px96/2)、文字 17fp #333333、icon drawablePadding 12vp(px24/2)、右箭头
 */
@Component
export struct MineTab {
  @State userName: string = '';
  @State userDepartment: string = '';
  @State userType: string = '1';
  @StorageProp('currentBreakpoint') currentBreakpoint: string = 'sm';
  @StorageProp('heightBreakpoint') heightBreakpoint: string = 'lg';
  @StorageProp('isLandscape') isLandscape: boolean = false;
  @StorageProp('isCompactHeight') isCompactHeight: boolean = false;
  @StorageProp('avoidAreaBottomVp') avoidAreaBottomVp: number = 0;

  private useSideRail(): boolean {
    return BreakpointSystem.shouldUseSideRail(
      this.currentBreakpoint,
      this.heightBreakpoint,
      this.isLandscape
    );
  }

  aboutToAppear(): void {
    PreferencesUtil.getString(Constants.KEY_USER_NAME, '')
      .then((name: string) => {
        this.userName = name;
      });
    PreferencesUtil.getString(Constants.KEY_USER_DEPARTMENT, '')
      .then((dept: string) => {
        this.userDepartment = dept;
      });
    // UserEntity.userType：1 学生 / 2 教师（源码同口径）
    this.userType = LoginSession.userType === '' ? '1' : LoginSession.userType;
  }

  /** 源码 e2()：退出前确认弹窗（确认要退出登录吗？取消/确认） */
  private showLogoutConfirm(): void {
    AlertDialog.show({
      title: '提示',
      message: '确认要退出登录吗？',
      primaryButton: {
        value: '取消',
        action: () => {
        }
      },
      secondaryButton: {
        value: '确认',
        fontColor: $r('app.color.sdmu_primary'),
        action: () => {
          this.doLogout();
        }
      },
      cancel: () => {
      }
    });
  }

  private async doLogout(): Promise<void> {
    await PreferencesUtil.clear();
    this.getUIContext().getPromptAction().showToast({ message: '已退出登录' });
    router.replaceUrl({ url: 'pages/LoginPage' });
  }

  /** APK 实拍：菜单行右侧无箭头，仅用户卡有 >；图标 tint 红色 */
  @Builder
  menuRow(icon: Resource, label: string | Resource, target: string) {
    Row() {
      Image(icon)
        .width(24)
        .height(24)
        .margin({ right: 16 })
        .colorFilter(ThemeConstants.TINT_RED)
      Text(label)
        .fontSize(17)
        .fontColor($r('app.color.common_color_1'))
        .layoutWeight(1)
    }
    .width('100%')
    .height(48)
    .padding({ left: 16, right: 16 })
    .alignItems(VerticalAlign.Center)
    .backgroundColor(Color.Transparent)
    .borderRadius(12)
    .hoverEffect(HoverEffect.Highlight)
    .clickEffect({ level: ClickEffectLevel.LIGHT, scale: 0.98 })
    .onClick(() => {
      router.pushUrl({ url: target });
    })
  }

  build() {
    Scroll() {
      Column() {
        // toolbar_normal：45vp 白底 + 标题「我」17fp 居中 + 细分隔线（APK 实拍标题为单字"我"）
        Column() {
          Text('我')
            .fontSize(17)
            .fontColor($r('app.color.common_color_1'))
            .height(44)
            .textAlign(TextAlign.Center)
          Divider()
            .color($r('app.color.common_color_5'))
            .strokeWidth(0.5)
            .width('100%')
        }
        .width('100%')
        .height(45)
        .justifyContent(FlexAlign.Center)
        .backgroundColor($r('app.color.main_bg'))

        // layoutDetail：白底用户卡。APK 实拍：红圆头像(姓名首字白字) + 姓名同行身份(学生)
        // + 第二行学院 + 右侧 >；高 88vp、paddingH、marginTop 12vp
        Row() {
          // 红色圆形头像：姓名首字白字
          Stack({ alignContent: Alignment.Center }) {
            Text(this.userName === '' ? '' : this.userName.substring(0, 1))
              .fontSize(26)
              .fontColor($r('app.color.white'))
          }
          .width(64)
          .height(64)
          .borderRadius(32)
          .backgroundColor($r('app.color.sdmu_primary'))

          // 姓名 + 身份同行；第二行学院
          Column() {
            Row() {
              Text(this.userName)
                .fontSize(19)
                .fontColor($r('app.color.common_color_1'))
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
              Text(this.userType === '2' ? '教师' : '学生')
                .fontSize(14)
                .fontColor($r('app.color.user_job_gray'))
                .margin({ left: 10 })
            }
            .alignItems(VerticalAlign.Center)

            Text(this.userDepartment)
              .fontSize(16)
              .fontColor($r('app.color.user_job_gray'))
              .margin({ top: 8 })
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
          }
          .alignItems(HorizontalAlign.Start)
          .margin({ left: 12 })
          .layoutWeight(1)

          // imgArrow：arrow_right2
          Image($r('app.media.arrow_right2'))
            .width(16)
            .height(16)
        }
        .width('100%')
        .height(88)
        .padding({ left: 16, right: 12 })
        .margin({ top: 12 })
        .borderRadius(16)
        .alignItems(VerticalAlign.Center)
        .backgroundColor(ImmersiveLightHelper.fallbackBg($r('app.color.white')))
        .systemMaterial(ImmersiveLightHelper.cardMaterial())
        .hoverEffect(HoverEffect.Highlight)
        .clickEffect({ level: ClickEffectLevel.LIGHT, scale: 0.98 })
        .onClick(() => {
          router.pushUrl({ url: 'pages/PersonalDetailPage' });
        })

        // 菜单分组：手机/竖屏单列，lg/xl 平板双列排布
        GridRow({ columns: { xs: 1, sm: 1, md: 1, lg: 2, xl: 2 }, gutter: { x: 12, y: 12 } }) {
          GridCol({ span: 1 }) {
            // llLayout1：意见反馈、修改密码
            Column() {
              this.menuRow($r('app.media.mobile_campus_opinion'), $r('app.string.opinion_feedback'), 'pages/FeedbackPage')
              this.menuRow($r('app.media.mobile_campus_question'), $r('app.string.modify_password'), 'pages/ModifyPasswordPage')
            }
            .width('100%')
            .borderRadius(16)
            .backgroundColor(ImmersiveLightHelper.fallbackBg($r('app.color.white')))
            .systemMaterial(ImmersiveLightHelper.cardMaterial())
          }

          GridCol({ span: 1 }) {
            // llLayout2：下载地址、下载文件管理
            Column() {
              this.menuRow($r('app.media.mobile_campus_download'), $r('app.string.download_address'), 'pages/DownloadAddressPage')
              this.menuRow($r('app.media.mobile_campus_filemanager'), $r('app.string.mobile_campus_file_manage'), 'pages/FileManagerPage')
            }
            .width('100%')
            .borderRadius(16)
            .backgroundColor(ImmersiveLightHelper.fallbackBg($r('app.color.white')))
            .systemMaterial(ImmersiveLightHelper.cardMaterial())
          }

          GridCol({ span: 1 }) {
            // 设置
            Column() {
              this.menuRow($r('app.media.mobile_campus_setting'), $r('app.string.mobile_campus_setting'), 'pages/SettingPage')
            }
            .width('100%')
            .borderRadius(16)
            .backgroundColor(ImmersiveLightHelper.fallbackBg($r('app.color.white')))
            .systemMaterial(ImmersiveLightHelper.cardMaterial())
          }
        }
        .width('100%')
        .margin({ top: 12 })

        // tvLogout：退出登录
        Text($r('app.string.logout'))
          .fontSize(17)
          .fontColor($r('app.color.logout_red'))
          .width('100%')
          .constraintSize({ maxWidth: 480 })
          .height(48)
          .textAlign(TextAlign.Center)
          .margin({ top: 28 })
          .borderRadius(24)
          .backgroundColor(ImmersiveLightHelper.fallbackBg($r('app.color.white')))
          .systemMaterial(ImmersiveLightHelper.secondaryButtonMaterial())
          .hoverEffect(HoverEffect.Highlight)
          .clickEffect({ level: ClickEffectLevel.LIGHT, scale: 0.97 })
          .onClick(() => {
            this.showLogoutConfirm();
          })
      }
      .width('100%')
      .padding({
        left: 12,
        right: 12,
        bottom: this.useSideRail() ? Math.max(20, this.avoidAreaBottomVp + 16) : Math.max(92, this.avoidAreaBottomVp + 76)
      })
    }
    .width('100%')
    .height('100%')
    .scrollBar(BarState.Off)
    .align(Alignment.Top)
    .backgroundColor('#EEF1F6')
  }
}
