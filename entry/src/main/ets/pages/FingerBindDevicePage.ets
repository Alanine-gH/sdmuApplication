import { router } from '@kit.ArkUI';
import { BusinessError } from '@kit.BasicServicesKit';
import { TitleBar } from '../components/TitleBar';
import { ApiService } from '../network/ApiService';
import { LoginSession } from '../network/LoginSession';
import { ApiResponse } from '../model/ResponseModel';
import { Constants } from '../data/Constants';

/**
 * 指纹绑定设备页 — 1:1 复刻 FingerBindDeviceActivity（141 行）+ mobile_campus_activity_setting_bind_device.xml
 * [W22 launch-chain] 源码级翻译：
 *   布局：toolbar_normal（T1 标题 = R$string.mobile_campus_my_bind_device = "设备绑定"）+ ScrollView：
 *     View 24dip=12vp + 账号行 + View 20dip=10vp + 姓名/性别/所属部门/身份证号/手机号/手机唯一码行
 *     （行：白底 paddingH 24dip=12vp，label 100dip=50vp 宽 #555555 16fp paddingTB 15dip=7.5vp，
 *     值 16fp black maxLines 2，行间分隔线 0.5dip ml 12vp）
 *     + tvBindDevice bg mobile_campus_shape_bind_device(#1790FF 圆角 px_to_dip_44=22vp)
 *       paddingTB 12dip=6vp marginH 12vp mt 20dip=10vp"绑定设备"
 *     + tvHasQuestion"激活遇到问题了？"（XML visibility=gone，源码无显示逻辑 → 保真省略渲染）。
 *   y(Intent)：w = extra "result" → Gson = PolymerizationResultBean（仅取 domain）。
 *   L2()：行值 = d.a.c() UserEntity 字段（tvAccount=userId/tvName=userName/tvGender=sex/
 *     tvDepartment=department/tvIcCardNum=identity/tvPhone=mobileNo）；HAP 会话持久化子集
 *     （userId/sessionName/sessionCollege/sessionPhone）→ sex/identity 未持久化留空（零容忍不编造）。
 *   tvAndroidId = J2(context) = Settings.System ANDROID_ID（HAP 等价 = 会话设备唯一码
 *     Constants.DEVICE_ID，与 AT 头 deviceId 同源）；K2() = Build.MODEL → Constants.DEVICE_MODEL。
 *   tvBindDevice → u.U0("1", androidId, model) → POST {domain}/lyuapServer/cam/v1/bindApp
 *     {typeId:"1", phoneId, phoneName=Base64(model)} → g→toast"绑定成功"+finish；f→toast(message)。
 * 入口链：PolymerizationPage（cam/v1/verify 未绑/失败分支）→ 本页。
 */
interface PolyResultBean {
  browserId?: string;
  buildTime?: number;
  domain?: string;
  loginType?: string;
}

@Entry
@Component
struct FingerBindDevicePage {
  /** 源码 v：raw result；w：PolymerizationResultBean（domain） */
  private resultJson: string = '';
  private domain: string = '';
  /** 行值（源码 L2()） */
  @State accountText: string = '';
  @State nameText: string = '';
  @State genderText: string = '';
  @State departmentText: string = '';
  @State idCardText: string = '';
  @State phoneText: string = '';
  @State androidIdText: string = '';

  aboutToAppear(): void {
    // 源码 y(Intent)：w = Gson(result)
    const params: object | undefined = router.getParams() as object | undefined;
    if (params !== undefined && params !== null) {
      const rec = params as Record<string, Object>;
      const result: Object = rec['result'];
      if (typeof result === 'string') {
        this.resultJson = result as string;
        try {
          const pr: Record<string, Object> = JSON.parse(this.resultJson) as Record<string, Object>;
          const d: Object = pr['domain'];
          this.domain = typeof d === 'string' ? d as string : '';
        } catch (error) {
          this.domain = '';
        }
      }
    }
    // 源码 f1()：I2() 填行 + u = new f(this.w.getDomain())
    this.accountText = LoginSession.userId;
    this.nameText = LoginSession.sessionName;
    // UserEntity.sex / identity：HAP 会话未持久化（parseUserEntity 无该字段）→ 留空
    this.genderText = '';
    this.departmentText = LoginSession.sessionCollege;
    this.idCardText = '';
    this.phoneText = LoginSession.sessionPhone;
    // 源码 J2(context)：Settings.System ANDROID_ID → HAP 等价设备唯一码
    this.androidIdText = Constants.DEVICE_ID;
  }

  /** 源码 onClick tvBindDevice：u.U0("1", J2(context), K2()) → bindApp */
  private async bindDevice(): Promise<void> {
    if (this.domain === '') {
      // 源码 domain 缺失无从请求（防御停留）
      this.getUIContext().getPromptAction().showToast({ message: '扫描出错' });
      return;
    }
    try {
      const resp: ApiResponse<Object> = await ApiService.polyBindApp(this.domain, '1',
        Constants.DEVICE_ID, Constants.DEVICE_MODEL);
      if (resp.code === 0) {
        // 源码 a.g：m("绑定成功") + finish()
        this.getUIContext().getPromptAction().showToast({ message: '绑定成功' });
        router.back();
      } else {
        // 源码 a.f：m(str2) toast 服务器 message
        this.getUIContext().getPromptAction().showToast({ message: resp.message });
      }
    } catch (error) {
      const be = error as BusinessError;
      ApiService.logError('polyBindApp fail: ' + be.message);
      this.getUIContext().getPromptAction().showToast({ message: '网络请求失败，请重试' });
    }
  }

  @Builder
  private infoRow(label: string, infoText: string) {
    Row() {
      Text(label)
        .fontSize(16)
        .fontColor('#555555')
        .width(50)
        .padding({ top: 7.5, bottom: 7.5 })

      Text(infoText)
        .fontSize(16)
        .fontColor($r('app.color.black'))
        .maxLines(2)
        .layoutWeight(1)
        .alignSelf(ItemAlign.Center)
    }
    .width('100%')
    .backgroundColor($r('app.color.white'))
    .padding({ left: 12, right: 12 })
    .alignItems(VerticalAlign.Center)
  }

  @Builder
  private rowDivider() {
    Divider()
      .color($r('app.color.common_color_5'))
      .strokeWidth(0.5)
      .width('100%')
      .margin({ left: 12 })
  }

  build() {
    Column() {
      // toolbar_normal：T1 标题 = "设备绑定"
      TitleBar({ title: '设备绑定', showBack: true })

      Scroll() {
        Column() {
          Row()
            .width('100%')
            .height(12)

          this.infoRow('账号', this.accountText)

          Row()
            .width('100%')
            .height(10)

          this.infoRow('姓名', this.nameText)
          this.rowDivider()
          this.infoRow('性别', this.genderText)
          this.rowDivider()
          this.infoRow('所属部门', this.departmentText)
          this.rowDivider()
          this.infoRow('身份证号', this.idCardText)
          this.rowDivider()
          this.infoRow('手机号', this.phoneText)
          this.rowDivider()
          this.infoRow('手机唯一码', this.androidIdText)

          Text('绑定设备')
            .fontSize(16)
            .fontColor($r('app.color.white'))
            .textAlign(TextAlign.Center)
            .width('calc(100% - 24vp)')
            .padding({ top: 6, bottom: 6 })
            .borderRadius(22)
            .backgroundColor('#1790FF')
            .margin({ left: 12, right: 12, top: 10 })
            .onClick(() => {
              this.bindDevice();
            })

          // tvHasQuestion"激活遇到问题了？"：XML visibility=gone 且源码无显示逻辑 → 保真省略
        }
        .width('100%')
      }
      .width('100%')
      .layoutWeight(1)
      .scrollBar(BarState.Off)
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.common_color_6'))
  }
}
