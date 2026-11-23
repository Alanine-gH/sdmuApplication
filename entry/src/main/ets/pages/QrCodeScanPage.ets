import { router } from '@kit.ArkUI';
import { common, Want } from '@kit.AbilityKit';
import { scanBarcode, scanCore } from '@kit.ScanKit';
import { geoLocationManager } from '@kit.LocationKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { BreakpointSystem } from '../common/BreakpointSystem';
import { HttpClient } from '../network/HttpClient';
import { ApiService } from '../network/ApiService';
import { ApiResponse } from '../model/ResponseModel';
import { ScanJumpUrl } from '../model/ContactModel';
import { LoginSession } from '../network/LoginSession';
import { Constants } from '../data/Constants';

/**
 * 扫码页 — 1:1 复刻 activity_qr_code_scan.xml + QrCodeScanActivity 行为（[W26 partial-finish]）：
 *
 * 【布局】黑底 + 返回图标 56×56 pad16 marginT60 + 中部扫描线区（icon_scan_line 3500ms 循环，
 *   源码 b 类 AnimatorSet translationY 0→height）+ 底部 100vp 闪光灯提示 + 黑色操作条 100vp
 *   右侧"相册"（源码 llLight/llAlbum）。
 * 【扫码】源码 SurfaceView+zxing 自绘相机（b 类 CommonHandler → ScanUtil.decodeWithBitmap
 *   HmsScanAnalyzerOptions）+ 相册 PICK(59731)→CROP(59732)→decodeWithBitmap(photoMode)。
 *   HAP 等价：@kit.ScanKit scanBarcode.startScan（系统扫码 UI 内置闪光灯/相册，结果
 *   originalValue 同 HmsScan.getOriginalValue 通道）；本页保留 APK 布局壳，进入即起扫
 *   （MeetingDetailPage/W13 已验证同款通道），壳上"相册"按钮复起扫（系统 UI 自带相册入口，
 *   通道等价映射，无编造解码）。
 * 【结果分流】MainActivity.onActivityResult(17)（QrCodeScanActivity.H2 取 originalValue）逐行：
 *   空 → toast "二维码解析失败，请重试"；
 *   JSON 成功（k.g → map）：type!=null&&contains LY_CAS_CAM → /main/PolymerizationActivity{result}；
 *   type!=null&&!contains app_id → /scan/login{result}（ScanLoginPage 确认页）；
 *   contains meetingSign → y3(result,1)；qrcode_type!=null → e.a.d0=/meeting/attend{result}；
 *   type!=null&&contains app_id → v3(result)（定位打卡）；
 *   contains common_fixedClock → y3(result,2)。
 *   非 JSON（catch 内 else-if 链**无 return，全分支保真继续向下**）：
 *   contains /api/g/rq → scan/index{url:JSON(NXMZBean{app_id:"wangxun",type:"CAS_APP",url}),longitude:"",latitude:""};
 *   contains /paysec/pay/cm → url+userCode=AES/CBC(userId)（module/d/a.java AESUtils）；
 *   contains oa_meeting_scan → scan/index{url}；contains /spa/meeting/static4mobile/index.html#
 *   /signResult → y3(result,3)；startsWith cs=selfprint → y3(result,4)；
 *   contains /pages/account/login/erweima → y3(result,5)；
 *   else → ACTION_VIEW（HAP startAbility viewData，失败 → QrCodeScanResultPage{QrCodeScanResult}）；
 *   各分支执行后统一继续 → 含 /bpm/rule → scan/bpm{bpmUrl}→jumpUrl；
 *   含 open.weixin.qq.com → scan/accessGate{url}→jumpUrl；
 *   最终：url+"&ticket="+enc(4字段AT)+"_"+UC+"_xinzhongxin&appKey=ydxy" → 轻应用（a.k LX=4 h5）。
 * 【y3】ScanLoginPImpl.g → scan/index{url} → data：type=2 → 非{} → AppBean{YYID=data,LX=2} springboard /
 *   JSON{type:1,jumpUrl,yyid} → AppBean{URL,LX=2} h5 直载；type=3/5 → a.m isLoadOnly 直载；
 *   其余（1/4）→ toast(message)。
 */
interface HttpHeader {
  headerKey: string;
  headerValue: string;
}

@Entry
@Component
struct QrCodeScanPage {
  @State scanLineOffset: number = 0;
  @State flashHint: string = '扫二维码/条码';
  @StorageProp('isCompactHeight') isCompactHeight: boolean = false;
  @StorageProp('avoidAreaTopVp') avoidAreaTopVp: number = 0;
  @StorageProp('avoidAreaBottomVp') avoidAreaBottomVp: number = 0;
  @StorageProp('avoidAreaLeftVp') avoidAreaLeftVp: number = 0;
  @StorageProp('avoidAreaRightVp') avoidAreaRightVp: number = 0;
  private scanAreaHeight: number = 0;
  private timerId: number = -1;
  /** 防重入：扫码中不再触发（源码连续扫码由 zxing 循环承担，HAP 每次 startScan 一次会话） */
  private scanning: boolean = false;

  aboutToAppear(): void {
    this.timerId = setInterval(() => {
      this.scanLineOffset = this.scanLineOffset >= 1 ? 0 : this.scanLineOffset + 0.02;
    }, 30);
    // 源码 SurfaceCreated → J2() 起相机连续扫码；HAP 进入即起系统扫码（W13 通道）
    this.startScan();
  }

  aboutToDisappear(): void {
    if (this.timerId >= 0) {
      clearInterval(this.timerId);
      this.timerId = -1;
    }
  }

  /** 源码 zxing 循环扫码 + 相册 decodeWithBitmap 的 ScanKit 等价入口 */
  private startScan(): void {
    if (this.scanning) {
      return;
    }
    this.scanning = true;
    const options: scanBarcode.ScanOptions = { scanTypes: [scanCore.ScanType.QR_CODE] };
    scanBarcode.startScan(options)
      .then((result: scanBarcode.ScanResult) => {
        this.scanning = false;
        // 源码 QrCodeScanActivity.H2(intent)：originalValue 提取
        this.dispatchScanResult(result.originalValue);
      })
      .catch((error: BusinessError) => {
        this.scanning = false;
        ApiService.logError('QrCodeScanPage startScan fail: ' + error.message);
      });
  }

  /** 源码 MainActivity.onActivityResult 17 分支（L1463-1571）逐行分流 */
  private dispatchScanResult(result: string): void {
    if (result === '') {
      // 源码 L1468：Toast "二维码解析失败，请重试"
      this.getUIContext().getPromptAction().showToast({ message: '二维码解析失败，请重试' });
      return;
    }
    let mapG: Record<string, Object> | null = null;
    try {
      const parsed: Object = JSON.parse(result);
      if (parsed !== null && typeof parsed === 'object' && !Array.isArray(parsed)) {
        mapG = parsed as Record<string, Object>;
      }
    } catch (error) {
      // 源码 k.g 异常 → 非 JSON 分支
      mapG = null;
    }
    if (mapG !== null) {
      this.dispatchJsonResult(mapG, result);
      return;
    }
    this.dispatchPlainResult(result);
  }

  /** 源码 L1517-1544 JSON 分流（逐分支 return） */
  private dispatchJsonResult(mapG: Record<string, Object>, result: string): void {
    const hasType: boolean = mapG['type'] !== undefined && mapG['type'] !== null;
    if (hasType && result.indexOf('LY_CAS_CAM') >= 0) {
      // 源码 L1519：g2("/main/PolymerizationActivity", bundle{result})
      router.pushUrl({ url: 'pages/PolymerizationPage', params: { 'result': result } });
      return;
    }
    if (hasType && result.indexOf('app_id') < 0) {
      // 源码 L1523：g2(e.a.q=/scan/login, bundle{result}) → ScanLoginPage 确认页
      router.pushUrl({ url: 'pages/ScanLoginPage', params: { 'result': result } });
      return;
    }
    if (result.indexOf('meetingSign') >= 0) {
      this.y3(result, 1);
      return;
    }
    if (mapG['qrcode_type'] !== undefined && mapG['qrcode_type'] !== null) {
      // 源码 L1531：g2(e.a.d0=/meeting/attend, bundle{result})
      router.pushUrl({ url: 'pages/MeetingAttendPage', params: { 'result': result } });
      return;
    }
    if (hasType && result.indexOf('app_id') >= 0) {
      this.v3(result);
      return;
    }
    if (result.indexOf('common_fixedClock') >= 0) {
      this.y3(result, 2);
      return;
    }
    // 源码 L1542：无命中分支（静默）
  }

  /** 源码 L1474-1515 非 JSON 分支链（catch 内 else-if 无 return——全分支保真继续向下，
   *  最终统一落入 L1545 起的 bpm/微信/zfpt ticket 判定，与 APK 逐行一致） */
  private async dispatchPlainResult(result: string): Promise<void> {
    if (result.indexOf('/api/g/rq') >= 0) {
      // 源码 NXMZBean{app_id:"wangxun", type:"CAS_APP", url} → W0 scan/index{url,longitude:"",latitude:""}
      const bean: Record<string, string> = { 'app_id': 'wangxun', 'type': 'CAS_APP', 'url': result };
      this.scanIndexToWeb(JSON.stringify(bean));
    } else if (result.indexOf('/paysec/pay/cm') >= 0) {
      // 源码 L1483-1494：userCode=URLEncoder.encode(AES/CBC(userId)) 拼接；
      // 加密异常时 userId 保持原值（源码 userId 初始值兜底）
      let userCode: string = LoginSession.userId;
      try {
        userCode = encodeURIComponent(ApiService.encryptPayUserCode(LoginSession.userId));
      } catch (error) {
        const be = error as BusinessError;
        ApiService.logError('QrCodeScanPage userCode enc fail: ' + be.message);
      }
      const glue: string = result.indexOf('?') >= 0 ? '&' : '?';
      this.openWeb(result + glue + 'userCode=' + userCode, false);
    } else if (result.indexOf('oa_meeting_scan') >= 0) {
      // 源码 L1496：ScanLoginPImpl.g → V0 scan/index{url}
      this.scanIndexToWeb(result);
    } else if (result.indexOf('/spa/meeting/static4mobile/index.html#/signResult') >= 0) {
      this.y3(result, 3);
    } else if (result.startsWith('cs=selfprint')) {
      this.y3(result, 4);
    } else if (result.indexOf('/pages/account/login/erweima') >= 0) {
      this.y3(result, 5);
    } else {
      // 源码 L1504-1513：ACTION_VIEW（失败 → QrCodeScanResultActivity）
      let viewOk: boolean = false;
      try {
        const context = this.getUIContext().getHostContext() as common.UIAbilityContext;
        const want: Want = { action: 'ohos.want.action.viewData', uri: result };
        await context.startAbility(want);
        viewOk = true;
      } catch (error) {
        const be = error as BusinessError;
        ApiService.logError('QrCodeScanPage VIEW fail: ' + be.message);
      }
      if (!viewOk) {
        router.pushUrl({ url: 'pages/QrCodeScanResultPage', params: { 'QrCodeScanResult': result } });
      }
    }
    // 源码 mapG=null 后继续：bpm/微信分支 + 最终 ticket URL（无 return 保真）
    this.finalTicketDispatch(result);
  }

  /** 源码 L1545-1570：bpm/微信分支 + 最终 ticket URL 轻应用直载 */
  private finalTicketDispatch(result: string): void {
    if (!result.startsWith('http://zfpt.wru.edu.cn:8082')) {
      if (result.indexOf('/bpm/rule') >= 0) {
        // 源码 k3：ScanLoginPImpl.e → scan/bpm{bpmUrl} → jumpUrl → a.k
        ApiService.scanBpm(result)
          .then((response: ApiResponse<ScanJumpUrl>) => {
            if (response.code === 0 && response.data.jumpUrl !== '') {
              this.openWeb(response.data.jumpUrl, false);
            }
          })
          .catch(() => {
            ApiService.logError('QrCodeScanPage scanBpm error');
          });
        return;
      }
      if (result.indexOf('open.weixin.qq.com') >= 0) {
        // 源码 j3：ScanLoginPImpl.d → scan/accessGate{url} → jumpUrl → a.k
        ApiService.scanAccessGate(result)
          .then((response: ApiResponse<ScanJumpUrl>) => {
            if (response.code === 0 && response.data.jumpUrl !== '') {
              this.openWeb(response.data.jumpUrl, false);
            }
          })
          .catch(() => {
            ApiService.logError('QrCodeScanPage scanAccessGate error');
          });
        return;
      }
      return;
    }
    // 源码 L1557-1570：url+"&ticket="+enc(4字段AT)+"_"+UC+"_xinzhongxin&appKey=ydxy" → a.k
    let ticket: string = '';
    try {
      ticket = HttpClient.buildWebEncryptedAccessToken();
    } catch (error) {
      const be = error as BusinessError;
      ApiService.logError('QrCodeScanPage ticket enc fail: ' + be.message);
    }
    const uc: string = LoginSession.onlyCode === '' ? Constants.UNIQUE_CODE : LoginSession.onlyCode;
    const finalUrl: string = result + '&ticket=' + encodeURIComponent(ticket) + '_' + uc +
      '_xinzhongxin&appKey=ydxy';
    this.openWeb(finalUrl, false);
  }

  /** 源码 y3(str, type)：scan/index{url} → h 类 g(code,msg,?,data) 分流 */
  private y3(url: string, type: number): void {
    ApiService.scanLoginIndex(url)
      .then((response: ApiResponse<Object>) => {
        if (response.code === 1000) {
          return;
        }
        const data: string = typeof response.data === 'string' ? response.data as string : '';
        if (response.code !== 0) {
          // 源码 h 类 f(...) → x2(str2)（toast）
          this.toast(response.message);
          return;
        }
        if (type === 2) {
          // 源码 h 类 g() type==2：非 {} → AppBean{YYID=data,LX=2} springboard；
          // JSON{type:1,jumpUrl,yyid} → AppBean{URL=jumpUrl,LX=2} h5 直载
          if (!data.startsWith('{') || !data.endsWith('}')) {
            this.openLight(data, '', false);
            return;
          }
          try {
            const extra: Record<string, Object> = JSON.parse(data) as Record<string, Object>;
            const extraType: Object = extra['type'];
            if (typeof extraType === 'string' && (extraType as string) === '1') {
              const jumpUrl: Object = extra['jumpUrl'];
              const yyid: Object = extra['yyid'];
              this.openLight(typeof yyid === 'string' ? yyid as string : '',
                typeof jumpUrl === 'string' ? jumpUrl as string : '', true);
            }
          } catch (error) {
            const be = error as BusinessError;
            ApiService.logError('QrCodeScanPage extra parse fail: ' + be.message);
          }
          return;
        }
        if (type === 3 || type === 5) {
          // 源码 a.m(activity, "", data)：isLoadOnly 直载
          this.openWeb(data, true);
          return;
        }
        // 源码 h 类 else（type=1/4）：x2(str2) toast
        this.toast(response.message);
      })
      .catch(() => {
        ApiService.logError('QrCodeScanPage scanIndex error');
        this.toast('服务器繁忙，请稍后再试');
      });
  }

  /** 源码 v3(str)：定位 → scan/index{url,longitude,latitude} → a.k 直载 */
  private v3(url: string): void {
    try {
      const req: geoLocationManager.CurrentLocationRequest = {
        priority: geoLocationManager.LocationRequestPriority.FIRST_FIX,
        scenario: geoLocationManager.LocationRequestScenario.UNSET,
        maxAccuracy: 0
      };
      geoLocationManager.getCurrentLocation(req)
        .then((location: geoLocationManager.Location) => {
          const lon: string = String(location.longitude);
          const lat: string = String(location.latitude);
          if (location.longitude === 0 || location.latitude === 0) {
            // 源码 j 类 b()：getLastKnownLocation 经纬度 0/0 → m("获取经纬度出错，请重试")
            this.toast('获取经纬度出错，请重试');
            return;
          }
          ApiService.scanIndexLocation(url, lon, lat)
            .then((response: ApiResponse<Object>) => {
              const data: string = typeof response.data === 'string' ? response.data as string : '';
              if (response.code === 0 && data !== '') {
                this.openWeb(data, false);
              }
            })
            .catch(() => {
              ApiService.logError('QrCodeScanPage scanIndexLocation error');
            });
        })
        .catch((error: BusinessError) => {
          ApiService.logError('QrCodeScanPage location fail: ' + error.message);
        });
    } catch (error) {
      const be = error as BusinessError;
      ApiService.logError('QrCodeScanPage location api fail: ' + be.message);
    }
  }

  /** 源码 c/d 类 g(code,msg,?,data) → a.k(activity, "", data)：LX=4 h5 轻应用直载；
   *  请求 = W0 scan/index{url, longitude:"", latitude:""}（源码 h(json,"","") 三参全发） */
  private scanIndexToWeb(url: string): void {
    ApiService.scanLoginIndex(url, '', '')
      .then((response: ApiResponse<Object>) => {
        const data: string = typeof response.data === 'string' ? response.data as string : '';
        if (response.code === 0 && data !== '') {
          this.openWeb(data, false);
        }
      })
      .catch(() => {
        ApiService.logError('QrCodeScanPage scanIndexToWeb error');
      });
  }

  /** 源码 a.k：AppBean{YYID:xgma_yyid, URL, LX:"4"} h5=true → 轻应用直载（AT+UC 头） */
  private openWeb(url: string, loadOnly: boolean): void {
    router.pushUrl({ url: 'pages/LightAppPage',
      params: { 'title': '', 'url': url, 'yyid': 'xgma_yyid', 'lx': '4',
        'h5': '1', 'loadOnly': loadOnly ? '1' : '0' } as Record<string, string> });
  }

  /** 源码 w.g(e.a.v, AppBean)：LX=2 springboard（h5=false）/ h5=true 直载 URL */
  private openLight(yyid: string, url: string, h5: boolean): void {
    router.pushUrl({ url: 'pages/LightAppPage',
      params: { 'title': '', 'url': url, 'yyid': yyid, 'lx': '2',
        'h5': h5 ? '1' : '0' } as Record<string, string> });
  }

  /** 源码 x2(str)（YBGToastUtil.n）等价 */
  private toast(msg: string): void {
    if (msg !== '') {
      this.getUIContext().getPromptAction().showToast({ message: msg });
    }
  }

  build() {
    Stack() {
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor(Color.Black)
        .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])

      Column() {
        Row() {
          Image($r('app.media.icon_scan_back'))
            .width(24)
            .height(24)
            .padding(16)
            .objectFit(ImageFit.Contain)
            .onClick(() => {
              router.back();
            })
        }
        .width('100%')
        .height(56)
        .padding({ left: this.avoidAreaLeftVp, right: this.avoidAreaRightVp })
        .margin({ top: Math.max(12, this.avoidAreaTopVp + 12) })
        .justifyContent(FlexAlign.Start)
        .alignItems(VerticalAlign.Center)

        // 源码 llLine/ivLine：扫描线 3500ms 循环（b 类 AnimatorSet translationY）
        Stack() {
          Image($r('app.media.icon_scan_line'))
            .width('100%')
            .objectFit(ImageFit.Fill)
            .offset({ y: this.scanLineOffset * this.scanAreaHeight })
        }
        .width('100%')
        .layoutWeight(1)
        .clip(true)
        .onAreaChange((oldArea: Area, newArea: Area) => {
          this.scanAreaHeight = Number(newArea.height);
        })

        // 源码 llLight：闪光灯提示（ScanKit 系统 UI 内置闪光灯，壳上文案保真）
        Scroll() {
          Column() {
            Column() {
              Image($r('app.media.icon_scan_light_close'))
                .width(19)
                .height(33)
                .objectFit(ImageFit.Contain)

              Text(this.flashHint)
                .fontSize(14)
                .fontColor($r('app.color.white'))
                .margin({ top: 8 })
            }
            .padding({ left: 20, right: 20 })
            .alignItems(HorizontalAlign.Center)
            .onClick(() => {
              this.startScan();
            })
          }
          .width('100%')
          .justifyContent(FlexAlign.Start)
          .alignItems(HorizontalAlign.Center)
        }
        .width('100%')
        .height(this.isCompactHeight ? 64 : 100)
        .scrollBar(BarState.Off)
      }
      .width('100%')
      .height('100%')

      Column() {
        Row() {
          Column() {
            Image($r('app.media.icon_scan_album'))
              .width(23)
              .height(23)
              .objectFit(ImageFit.Contain)

            Text('相册')
              .fontSize(12)
              .fontColor($r('app.color.white'))
              .margin({ top: 8 })
          }
          .padding({ left: 20, right: 20, top: 15, bottom: 15 })
          .margin({ right: 21 })
          .alignItems(HorizontalAlign.Center)
          .onClick(() => {
            // 源码 llAlbum：PICK→CROP→decodeWithBitmap(photoMode)；ScanKit 系统 UI
            // 内置相册入口（通道等价，无编造解码）→ 复起扫
            this.startScan();
          })
        }
        .width('100%')
        .height((this.isCompactHeight ? 64 : 100) + this.avoidAreaBottomVp)
        .padding({
          left: this.avoidAreaLeftVp,
          right: this.avoidAreaRightVp,
          bottom: this.avoidAreaBottomVp
        })
        .backgroundColor(Color.Black)
        .justifyContent(FlexAlign.End)
        .alignItems(VerticalAlign.Center)
        .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.BOTTOM])
      }
      .width('100%')
      .height('100%')
      .justifyContent(FlexAlign.End)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(Color.Black)
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
  }
}
