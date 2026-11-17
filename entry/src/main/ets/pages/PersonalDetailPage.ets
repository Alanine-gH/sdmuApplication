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

    // 实时：getUserInfo 接口（源码 c/h/b/a.R 的真实参数）
    if (LoginSession.userId !== '') {
      ApiService.getUserInfo(LoginSession.userId)
        .then((response: ApiResponse<MobileCampusUserInfo>) => {
          if (response.code === 1000) {
            // 源码同款行为：会话过期（session_key 约 30-60 分钟失效）→ 引导重新登录
            this.getUIContext().getPromptAction().showToast({ message: '登录已失效，请重新登录' });
            router.replaceUrl({ url: 'pages/LoginPage' });
            return;
          }
          if (response.code === 0 && response.data.userName !== '') {
            this.info = response.data;
          }
          this.isLoading = false;
        })
        .catch((error: BusinessError) => {
          ApiService.logError('PersonalDetail getUserInfo fail: ' + error.message);
          this.isLoading = false;
        });
    } else {
      this.isLoading = false;
    }
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
                    // 源码：手机→绑定手机页(MobileCampusBindPhoneActivity)；QQ/微信/邮箱→对应绑定页
                    if (row.key === '手机') {
                      router.pushUrl({ url: 'pages/BindPhonePage' });
                    } else if (row.key === '邮箱') {
                      router.pushUrl({ url: 'pages/BindEmailPage' });
                    } else if (row.key === 'QQ' || row.key === '微信') {
                      router.pushUrl({ url: 'pages/ChangeQqWechatPage' });
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
