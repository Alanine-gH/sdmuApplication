import { router } from '@kit.ArkUI';
import { userAuth } from '@kit.UserAuthenticationKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { TitleBar } from '../components/TitleBar';
import { ApiService } from '../network/ApiService';
import { ApiResponse } from '../model/ResponseModel';
import { Constants } from '../data/Constants';
import { BreakpointSystem } from '../common/BreakpointSystem';

/**
 * 扫码聚合中转页 — 源码级复刻 PolymerizationActivity（103 行）+ mobile_campus_polymerization.xml
 * [W22 launch-chain 初版 → W25 misc-b 重写]（指纹登录/绑定设备链的中转枢纽）：
 *   布局：toolbar_normal（H0()=null → 标题空），无其他内容。
 *   y(Intent)：m = extra "result"（MainActivity L1519 扫得 JSON 含 type 且含 LY_CAS_CAM →
 *     g2("/main/PolymerizationActivity")）；n = Gson(result) = PolymerizationResultBean
 *     {browserId, buildTime, domain, loginType, service, type}。
 *   f1()：FingerHelper.b()（指纹硬件检出 + 已录指纹）→ androidId =
 *     Settings.System.getString(ANDROID_ID)（HAP 等价 = 会话设备唯一码 Constants.DEVICE_ID，
 *     与 AT 头 deviceId 同源）→ PolymerizationModel.W0（ApiService.polymerizationVerify，
 *     HttpClient.plainJsonPost 外部域明文 JSON POST 通道）：
 *     POST {domain}/lyuapServer/cam/v1/verify {phoneId}（头 Z0：appid=SystemSwitch null→""/
 *     secret=md5(userId+secret+yyyyMMdd)/userId=base64(userId)，
 *     m=polymerization.a 响应归一 {meta:{success,message}} → code 0/1；网络失败 code=-1 停留）：
 *       g（success=true，本机已绑）→ w.c("设备登录"=/my/FingerLoginActivity, {result}) + finish；
 *       f（未绑/失败）→ w.c("绑定设备"=/my/FingerBindDeviceActivity, {result}) + finish。
 *   b()==false：toast（源码 f0.c："此设备不支持指纹识别"/"此设备没有可用指纹信息,请去系统录入指纹信息"）
 *   并停留（源码无后续动作）。
 * 入口链：QrCodeScanPage 扫码结果（HAP 扫码能力未接线 → 本页入口参数驱动）→ 本页 →
 * FingerLoginPage / FingerBindDevicePage。
 */
interface PolyResultBean {
  browserId?: string;
  buildTime?: number;
  domain?: string;
  loginType?: string;
  service?: string;
  type?: string;
}

@Entry
@Component
struct PolymerizationPage {
  /** 源码 m：扫码下发的原始 JSON */
  private resultJson: string = '';
  /** 源码 n：PolymerizationResultBean */
  private bean: PolyResultBean | null = null;
  @StorageProp('currentBreakpoint') currentBreakpoint: string = 'sm';
  @StorageProp('avoidAreaBottomVp') avoidAreaBottomVp: number = 0;

  aboutToAppear(): void {
    const params: object | undefined = router.getParams() as object | undefined;
    if (params !== undefined && params !== null) {
      const rec = params as Record<string, Object>;
      const result: Object = rec['result'];
      if (typeof result === 'string') {
        this.resultJson = result as string;
        this.parseBean();
      }
    }
    this.f1();
  }

  /** 源码 y(Intent) 后半：Gson(result) → PolymerizationResultBean */
  private parseBean(): void {
    try {
      const rec: Record<string, Object> = JSON.parse(this.resultJson) as Record<string, Object>;
      const bean: PolyResultBean = {};
      const pick = (k: string): string => {
        const v: Object = rec[k];
        return typeof v === 'string' ? v as string : '';
      };
      bean.browserId = pick('browserId');
      bean.domain = pick('domain');
      bean.loginType = pick('loginType');
      bean.service = pick('service');
      bean.type = pick('type');
      const bt: Object = rec['buildTime'];
      bean.buildTime = typeof bt === 'number' ? bt as number : Number(bt);
      this.bean = bean;
    } catch (error) {
      // 解析失败保持 null（源码 Gson 异常同态；f1 判空停留）
      this.bean = null;
    }
  }

  /** 源码 f1()：指纹可用 → cam/v1/verify → 设备登录/绑定设备分流 */
  private async f1(): Promise<void> {
    // FingerHelper.b()：硬件+已录指纹校验（HAP userAuth.getAvailableStatus 等价；SDK 为同步 void）
    try {
      userAuth.getAvailableStatus(userAuth.UserAuthType.FINGERPRINT, 10000);
    } catch (error) {
      const be = error as BusinessError;
      ApiService.logError('fingerprint unavailable: ' + be.code);
      // 源码 f0.c(this, "此设备没有可用指纹信息,请去系统录入指纹信息")
      this.getUIContext().getPromptAction().showToast({ message: '此设备没有可用指纹信息,请去系统录入指纹信息' });
      return;
    }
    if (this.bean === null || (this.bean.domain ?? '') === '') {
      // 源码 n.getDomain() 无值时无从请求（防御停留，不等价编造域名）
      this.getUIContext().getPromptAction().showToast({ message: '扫描出错' });
      return;
    }
    const domain: string = this.bean.domain as string;
    try {
      // [W25 misc-b 重写] 源码 PolymerizationModel.W0：头=Z0()（secret=md5(userId+bindApp_secret+
      // yyyyMMdd)，SystemSwitch null → secretSource=""）、body={phoneId}、j=false 明文 JSON。
      // resp.code：0=meta.success=true(g 回调)、1=meta.success=false(f 回调)、-1=网络失败（源码无响应
      // 不走 g/f 回调 → 页面停留）。
      const resp: ApiResponse<string> = await ApiService.polymerizationVerify(domain, Constants.DEVICE_ID);
      if (resp.code === 0) {
        // 源码 g 回调：w.c(R$string.mobile_campus_device_login="/my/FingerLoginActivity") + finish
        router.replaceUrl({ url: 'pages/FingerLoginPage', params: { 'result': this.resultJson } });
      } else if (resp.code === 1) {
        // 源码 f 回调：w.c(R$string.mobile_campus_bind_device="/my/FingerBindDeviceActivity") + finish
        router.replaceUrl({ url: 'pages/FingerBindDevicePage', params: { 'result': this.resultJson } });
      } else {
        // 网络失败：源码无响应无回调 → 停留本页（不编造分流）
        this.getUIContext().getPromptAction().showToast({ message: '网络请求失败，请稍后再试' });
      }
    } catch (error) {
      // 网络异常同态：源码无回调 → 停留
      const be = error as BusinessError;
      ApiService.logError('polymerizationVerify fail: ' + be.message);
    }
  }

  build() {
    // mobile_campus_polymerization.xml：仅 toolbar_normal
    Column() {
      TitleBar({ title: '', showBack: true })
      Scroll() {
        Column()
          .width('100%')
          .constraintSize({ maxWidth: BreakpointSystem.getContentMaxWidth(this.currentBreakpoint) })
          .alignSelf(ItemAlign.Center)
          .padding({ bottom: this.avoidAreaBottomVp })
      }
      .width('100%')
      .layoutWeight(1)
      .scrollBar(BarState.Off)
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.white'))
  }
}
