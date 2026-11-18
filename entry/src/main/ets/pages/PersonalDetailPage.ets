import { router } from '@kit.ArkUI';
import { BusinessError } from '@kit.BasicServicesKit';
import { ApiService } from '../network/ApiService';
import { ApiResponse } from '../model/ResponseModel';
import { MobileCampusUserInfo } from '../model/MobileCampusUserInfoModel';
import { TitleBar } from '../components/TitleBar';
import { LoadingView } from '../components/LoadingView';
import { LoginSession } from '../network/LoginSession';
import { PreferencesUtil } from '../data/PreferencesUtil';
import { Constants } from '../data/Constants';

/**
 * 我的资料页 — 1:1 翻译原 APK PersonalDetailNewActivity.java（568 行）：
 *
 * 【数据源】POST /mobileapi_ydxy/api/user/getUserInfo
 *   body = {targetSchoolId, targetUserId, targetUserType, type}（AES 加密，源码 c/h/b/a.R）
 *   响应解密 = MobileCampusUserInfo（37 字段）
 *
 * 【头部 X2()】头像 = userName 首字圆（e3()：无 avatar 时取首字）；名字 = nickname 空则 userName；
 *   学院 = department。
 *
 * 【基础信息 c3(int userType)】字段顺序与源码逐行对应（U2 空值跳行）：
 *   学生：姓名 userName / 身份"学生" / 学号 userId / 学院 department /
 *         专业 professionName / 班级 className / 入学年份 grade / 公积金账号 commonAccount
 *   教师：姓名 / 身份"教师" / 工号 userId / 部门(parentDepartment/department) / 职位 position /
 *         短号 / 出生日期 / 民族 / 最高学位 / 参加工作日期 / 来校日期 / 办公地址 / 公积金账号
 *
 * 【绑定信息 d3()】服务器 SystemSwitch.MySetup 开关（myqq/mywechat/myphone/myemail）控制显示，
 *   四项 = QQ/微信/手机/邮箱（可编辑行，空值也显示，点击跳绑定页）。
 *   服务器未下发开关时（mySetup == null）整区不显示 —— 与源码一致。
 */
interface InfoRow {
  key: string;
  value: string;
  editable: boolean;
}

@Entry
@Component
struct PersonalDetailPage {
  @State info: MobileCampusUserInfo = new MobileCampusUserInfo();
  /** 登录会话兜底字段（首屏直出，接口回来后覆盖） */
  @State fallbackName: string = '';
  @State fallbackCollege: string = '';
  @State fallbackUserId: string = '';
  @State fallbackType: string = '1';
  @State isLoading: boolean = true;
  @State showBindSection: boolean = false;
  /** 服务器开关（SystemSwitch.MySetup）：0/1 显示，null 不显示（源码 d3） */
  @State myqq: string = '';
  @State mywechat: string = '';
  @State myphone: string = '';
  @State myemail: string = '';
  /** [W17 profile-series] 源码 T2：queryBindPhoneStatus → PhoneStatus（bindPhone/message/hasPhone），
   *  供"手机"行进入 InputPhonePage 携参（PersonalDetailNewActivity.b case"手机"） */
  @State phoneStatusBind: string = '0';
  private phoneStatusNeedSms: boolean = false;
  private phoneStatusHasPhone: boolean = false;
  /** onPageShow 首次跳过（aboutToAppear 已拉过），返回本页时刷新（源码 EventBus code=4 → X2 重拉） */
  private hasShownOnce: boolean = false;

  aboutToAppear(): void {
    // 首屏：登录会话真值直出（不依赖网络）
    this.fallbackName = LoginSession.sessionName;
    this.fallbackCollege = LoginSession.sessionCollege;
    this.fallbackUserId = LoginSession.userId;
    this.fallbackType = LoginSession.userType === '' ? '1' : LoginSession.userType;
    PreferencesUtil.getString(Constants.KEY_USER_NAME, '')
      .then((v: string) => { if (this.fallbackName === '') { this.fallbackName = v; } });
    PreferencesUtil.getString(Constants.KEY_USER_DEPARTMENT, '')
      .then((v: string) => { if (this.fallbackCollege === '') { this.fallbackCollege = v; } });
    this.fetchUserInfo();
  }

  /** 源码 X2()：POST getUserInfo{targetSchoolId,targetUserId,targetUserType,type}（e 加密） */
  private fetchUserInfo(): void {
    if (LoginSession.userId === '') {
      this.isLoading = false;
      return;
    }
    ApiService.getUserInfo(LoginSession.userId)
      .then((response: ApiResponse<MobileCampusUserInfo>) => {
        if (response.code === 1000) {
          // 登录失效统一处理已在网络层触发（HttpClient.bizRequest 拦截：清会话+toast+跳登录）
          return;
        }
        if (response.code === 0 && response.data.userName !== '') {
          this.info = response.data;
          // 源码 d3()：渲染绑定区同时 T2() 拉取 PhoneStatus
          this.fetchPhoneStatus();
        }
        this.isLoading = false;
      })
      .catch((error: BusinessError) => {
        ApiService.logError('PersonalDetail getUserInfo fail: ' + error.message);
        this.isLoading = false;
      });
  }

  /** [W17 profile-series] 源码 T2()：BindPhoneModel.T0 POST queryBindPhoneStatus
   *  {code:userId, type:userType} → PhoneStatus{bindPhone, message, hasPhone}；
   *  f.g：code=="0" 且非空才覆盖 GlobalParamInfo（失败静默）。
   */
  private fetchPhoneStatus(): void {
    ApiService.queryBindPhoneStatus()
      .then((response: ApiResponse<Object>) => {
        if (response.code !== 0) {
          return;
        }
        const raw: Object = response.data;
        if (typeof raw !== 'string') {
          return;
        }
        const rec: Record<string, Object> = JSON.parse(raw as string) as Record<string, Object>;
        const bind: Object | undefined = rec['bindPhone'];
        if (typeof bind === 'string') {
          this.phoneStatusBind = bind as string;
        }
        const msg: Object | undefined = rec['message'];
        if (typeof msg === 'boolean') {
          this.phoneStatusNeedSms = msg as boolean;
        }
        const has: Object | undefined = rec['hasPhone'];
        if (typeof has === 'boolean') {
          this.phoneStatusHasPhone = has as boolean;
        }
      })
      .catch((error: BusinessError) => {
        ApiService.logError('queryBindPhoneStatus fail: ' + error.message);
      });
  }

  /** 源码 c2(EventBusBean)：code==4（昵称修改链广播）→ X2() 重拉 getUserInfo；
   *  HAP 等价 = 从编辑页返回时（onPageShow 非首显）重拉。
   */
  onPageShow(): void {
    if (this.hasShownOnce) {
      this.fetchUserInfo();
    }
    this.hasShownOnce = true;
  }

  private identityLabel(): string {
    const t = this.info.userType !== '' ? this.info.userType : this.fallbackType;
    return t === '2' ? '教师' : '学生';
  }

  /** 源码 c3(int)：基础信息行列表（U2 空值跳行） */
  private baseRows(): InfoRow[] {
    const rows: InfoRow[] = [];
    const name = this.info.userName !== '' ? this.info.userName : this.fallbackName;
    const uid = this.info.userId !== '' ? this.info.userId : this.fallbackUserId;
    const type = this.info.userType !== '' ? this.info.userType : this.fallbackType;
    if (type === '2') {
      this.addRow(rows, '姓名', name);
      rows.push({ key: '身份', value: '教师', editable: false });
      this.addRow(rows, '工号', uid);
      // 部门 = parentDepartment / department（源码）
      this.addRow(rows, '部门', this.info.department !== '' ? this.info.department : this.fallbackCollege);
      this.addRow(rows, '职位', this.info.professionName !== '' ? this.info.professionName : '');
      this.addRow(rows, '短号', '');
      this.addRow(rows, '出生日期', '');
      this.addRow(rows, '民族', '');
      this.addRow(rows, '最高学位', '');
      this.addRow(rows, '参加工作日期', '');
      this.addRow(rows, '来校日期', '');
      this.addRow(rows, '办公地址', '');
      this.addRow(rows, '公积金账号', this.info.commonAccount);
    } else {
      this.addRow(rows, '姓名', name);
      rows.push({ key: '身份', value: '学生', editable: false });
      this.addRow(rows, '学号', uid);
      this.addRow(rows, '学院', this.info.department !== '' ? this.info.department : this.fallbackCollege);
      this.addRow(rows, '专业', this.info.professionName);
      this.addRow(rows, '班级', this.info.className);
      this.addRow(rows, '入学年份', this.info.grade);
      this.addRow(rows, '公积金账号', this.info.commonAccount);
    }
    return rows;
  }

  /** 源码 U2：QQ/微信/手机/邮箱空值也显示；其余字段空值跳行 */
  private addRow(rows: InfoRow[], key: string, value: string): void {
    if (key === 'QQ' || key === '微信' || key === '手机' || key === '邮箱') {
      rows.push({ key: key, value: value, editable: true });
      return;
    }
    if (value === '') {
      return;
    }
    rows.push({ key: key, value: value, editable: false });
  }

  /** 源码 d3：绑定区显示条件 = 服务器 mySetup 任一开关为 0/1 */
  private bindVisible(): boolean {
    return this.myqq !== '' || this.mywechat !== '' || this.myphone !== '' || this.myemail !== '';
  }

  /** 绑定区行（源码 d3 顺序：QQ/微信/手机/邮箱） */
  private bindRows(): InfoRow[] {
    const rows: InfoRow[] = [];
    if (this.myqq === '0' || this.myqq === '1') {
      rows.push({ key: 'QQ', value: this.info.bindQq, editable: true });
    }
    if (this.mywechat === '0' || this.mywechat === '1') {
      rows.push({ key: '微信', value: this.info.bindWechat, editable: true });
    }
    if (this.myphone === '0' || this.myphone === '1') {
      rows.push({ key: '手机', value: this.info.bindMobile, editable: true });
    }
    if (this.myemail === '0' || this.myemail === '1') {
      rows.push({ key: '邮箱', value: this.info.email, editable: true });
    }
    return rows;
  }

  build() {
    Column() {
      TitleBar({ title: '我的资料', showBack: true })

      if (this.isLoading) {
        LoadingView()
      } else {
        Scroll() {
          Column() {
            // ===== 头部（源码 X2/e3）：红圆首字 + 名字 + 学院 =====
            // [W17 profile-series] 源码 d（llNicknameLayout onClick）：SystemSwitch.nickName="0"
            // → toast"暂不支持修改昵称"，否则携带 bundle{nickname} 进入 ChangeNickNameActivity
            // （ARouter /personal/changeNickName）；HAP 未持久化 SystemSwitch → null 分支 = 可点击
            Row() {
              Stack({ alignContent: Alignment.Center }) {
                Text(this.displayHeadName().substring(0, 1))
                  .fontSize(24)
                  .fontColor($r('app.color.white'))
              }
              .width(60)
              .height(60)
              .borderRadius(30)
              .backgroundColor($r('app.color.sdmu_primary'))

              Column() {
                Text(this.displayHeadName())
                  .fontSize(19)
                  .fontColor($r('app.color.common_color_1'))
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
                Text(this.headCollege())
                  .fontSize(15)
                  .fontColor($r('app.color.user_job_gray'))
                  .margin({ top: 6 })
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
              }
              .alignItems(HorizontalAlign.Start)
              .margin({ left: 12 })
              .layoutWeight(1)

              Image($r('app.media.arrow_right2'))
                .width(16)
                .height(16)
            }
            .width('100%')
            .padding({ left: 16, right: 12, top: 14, bottom: 14 })
            .alignItems(VerticalAlign.Center)
            .backgroundColor($r('app.color.white'))
            .margin({ top: 10 })
            .onClick(() => {
              router.pushUrl({
                url: 'pages/ChangeNickNamePage',
                params: { 'nickname': this.info.nickname } as Record<string, string>
              });
            })

            // ===== 基础信息（源码 c3 顺序，空值跳行） =====
            ForEach(this.baseRows(), (row: InfoRow) => {
              Column() {
                Row()
                  .height(1)
                  .backgroundColor($r('app.color.common_color_6'))
                  .margin({ left: 15 })

                Row() {
                  Text(row.key)
                    .fontSize(16)
                    .fontColor($r('app.color.common_color_1'))
                    .width(120)
                  Text(row.value)
                    .fontSize(16)
                    .fontColor($r('app.color.common_color_1'))
                    .textAlign(TextAlign.End)
                    .layoutWeight(1)
                    .maxLines(1)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                }
                .width('100%')
                .padding(15)
                .alignItems(VerticalAlign.Center)
                .backgroundColor($r('app.color.white'))
              }
              .width('100%')
              .backgroundColor($r('app.color.white'))
            }, (row: InfoRow) => row.key + '_' + row.value)

            // ===== 绑定信息区（源码 d3：服务器开关控制） =====
            if (this.bindVisible()) {
              Column() {
                Row() {
                  Row()
                    .width(3)
                    .height(14)
                    .backgroundColor($r('app.color.sdmu_primary'))
                    .margin({ right: 8 })
                  Text('绑定信息')
                    .fontSize(15)
                    .fontColor($r('app.color.common_color_1'))
                }
                .width('100%')
                .height(38)
                .padding({ left: 12, right: 12 })
                .alignItems(VerticalAlign.Center)
              }
              .width('100%')
              .margin({ top: 10 })
              .backgroundColor($r('app.color.main_bg'))

              ForEach(this.bindRows(), (row: InfoRow) => {
                Column() {
                  Row()
                    .height(1)
                    .backgroundColor($r('app.color.common_color_6'))
                    .margin({ left: 15 })

                  Row() {
                    Text(row.key)
                      .fontSize(16)
                      .fontColor($r('app.color.common_color_1'))
                      .width(120)
                    Text(row.value === '' ? '--' : row.value)
                      .fontSize(16)
                      .fontColor($r('app.color.sdmu_primary'))
                      .textAlign(TextAlign.End)
                      .layoutWeight(1)
                      .maxLines(1)
                      .textOverflow({ overflow: TextOverflow.Ellipsis })
                    Image($r('app.media.arrow_right2'))
                      .width(14)
                      .height(14)
                      .margin({ left: 8 })
                  }
                  .width('100%')
                  .padding(15)
                  .alignItems(VerticalAlign.Center)
                  .backgroundColor($r('app.color.white'))
                  .onClick(() => {
                    // [W17 profile-series] 源码 b（PersonalDetail2Adapter 回调）逐行还原：
                    // 手机 → myphone!="1" → toast"暂不支持修改"，否则 h2(e.a.m=InputPhoneActivity)
                    //   bundle{bindPhoneState, needSmsVertify, hasBindPhone, currentBindPhone, source:"1"}；
                    // 邮箱 → myemail!="1" → toast"暂不支持修改"，否则 h2(e.a.n=InputEmailActivity, null)；
                    // QQ/微信 → mySetup 开关非 "1" → toast，否则 g2(e.a.p1=ChangeQqAndWechatActivity)
                    if (row.key === '手机') {
                      if (this.myphone !== '1') {
                        this.getUIContext().getPromptAction().showToast({ message: '暂不支持修改' });
                        return;
                      }
                      router.pushUrl({
                        url: 'pages/InputPhonePage',
                        params: {
                          'bindPhoneState': this.phoneStatusBind,
                          'needSmsVertify': this.phoneStatusNeedSms,
                          'hasBindPhone': this.phoneStatusHasPhone,
                          'currentBindPhone': this.info.bindMobile,
                          'source': '1'
                        } as Record<string, Object>
                      });
                    } else if (row.key === '邮箱') {
                      if (this.myemail !== '1') {
                        this.getUIContext().getPromptAction().showToast({ message: '暂不支持修改' });
                        return;
                      }
                      router.pushUrl({ url: 'pages/InputEmailPage' });
                    } else if (row.key === 'QQ') {
                      if (this.myqq !== '1') {
                        this.getUIContext().getPromptAction().showToast({ message: '暂不支持修改' });
                        return;
                      }
                      router.pushUrl({
                        url: 'pages/ChangeQqWechatPage',
                        params: { 'title': row.key, 'content': this.info.bindQq } as Record<string, string>
                      });
                    } else if (row.key === '微信') {
                      if (this.mywechat !== '1') {
                        this.getUIContext().getPromptAction().showToast({ message: '暂不支持修改' });
                        return;
                      }
                      router.pushUrl({
                        url: 'pages/ChangeQqWechatPage',
                        params: { 'title': row.key, 'content': this.info.bindWechat } as Record<string, string>
                      });
                    }
                  })
                }
                .width('100%')
                .backgroundColor($r('app.color.white'))
              }, (row: InfoRow) => 'bind_' + row.key + '_' + row.value)
            }

            // 底部留白
            Row()
              .height(20)
              .width('100%')
          }
          .width('100%')
          .alignItems(HorizontalAlign.Start)
        }
        .width('100%')
        .layoutWeight(1)
        .scrollBar(BarState.Off)
        .align(Alignment.Top)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.common_color_5'))
  }

  /** 头部名字：源码 q.setText(nickname) 空 → userName；再空 → 登录会话名 */
  private displayHeadName(): string {
    if (this.info.nickname !== '') {
      return this.info.nickname;
    }
    if (this.info.userName !== '') {
      return this.info.userName;
    }
    return this.fallbackName;
  }

  private headCollege(): string {
    if (this.info.department !== '') {
      return this.info.department;
    }
    return this.fallbackCollege;
  }
}
