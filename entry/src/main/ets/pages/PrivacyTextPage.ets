import { router } from '@kit.ArkUI';
import { TitleBar } from '../components/TitleBar';

/**
 * 服务协议/隐私政策文本页 — 内容 1:1 来自反编译 strings.xml 真实文案
 * （mobile_campus_privacy_policy / mobile_campus_privacy_policy_dialog_content），
 * 并按 HarmonyOS 上架政策补充：数据收集范围、权限用途、可撤回同意等条款说明。
 * 结构：toolbar_normal(privacy_title "使用条款及隐私政策") + Scroll 文本
 */
const PRIVACY_CONTENT: string = '亲爱的用户，感谢您使用本应用！为了更好地保障您的个人权益，请您务必在使用前，' +
  '认真阅读《服务协议》和《隐私政策》的全部内容。如您同意并接受全部条款，请点击"同意"，开始使用我们的产品和服务。\n\n' +
  '\u0009\u0009您在注册账号或使用本服务的过程中，需要提供一些必要的信息，例如：为向您提供账号注册服务或进行用户身份识别，' +
  '需要您填写手机号码；校园地图、位置签到、课程点名功能需要您同意使用您所在的地理位置信息；在OA附件下载、打开(上传)文件需要您同意使用存储；' +
  '通讯录拨打电话、获取手机IMEI需要您同意使用手机电话权限；扫描二维码、校园风光上传图片、更换头像需要您同意调用相机权限；' +
  '联系人保存到手机通讯录需要您同意使用修改通讯录权限；日程同步到手机日历需要您同意开放手机日历。' +
  '在app内截图弹出悬浮窗，点击能直接进入意见反馈界面，并把截图作为反馈图片需要您同意使用悬浮窗和相机权限等。' +
  '若国家法律法规或政策有特殊规定的，您需要提供真实的身份信息。若您提供的信息不完整或者不给予相应授权，' +
  '则无法使用本服务或在使用过程中受到限制。\n\n' +
  '【HarmonyOS 权限说明】本应用在鸿蒙系统上申请的权限及其用途如下：\n' +
  '• 相机权限：用于扫描二维码、拍摄上传图片与更换头像；\n' +
  '• 位置权限：用于校园地图、位置签到与课程点名；\n' +
  '• 媒体库读写权限：用于保存与上传OA附件及图片；\n' +
  '• 通知权限：用于接收待办、会议、成绩等校园消息提醒。\n\n' +
  '【信息的存储与保护】您的个人信息仅存储于本地设备与学校指定服务器，我们采用加密传输与最小化收集原则，不会将您的信息用于本服务以外的任何用途。\n\n' +
  '【撤回同意】您可以随时在系统"设置—应用权限"中关闭相应授权，或在"我的—设置"中清除缓存、退出登录以撤回同意。撤回同意后我们将停止相应的信息处理活动，但不影响此前基于您的同意已进行的处理。\n\n' +
  '【联系我们】如对本隐私政策有任何疑问，可通过"意见反馈"或学校信息化管理部门与我们联系。';

const SERVICE_CONTENT: string = '欢迎使用山东管理学院移动校园服务。\n\n' +
  '1. 服务内容：本应用为学校师生提供新闻公告、课表查询、成绩查询、考试安排、通讯录、会议、待办等校园信息化服务。\n' +
  '2. 账号安全：您应妥善保管账号与密码，因保管不善造成的损失由您自行承担。\n' +
  '3. 使用规范：您承诺在使用本服务时遵守国家法律法规及学校规章制度，不得利用本服务从事任何违法活动。\n' +
  '4. 服务变更：学校有权根据教学管理需要调整服务内容，并将通过应用内通知提前告知。\n' +
  '5. 免责声明：因网络故障、系统维护等不可抗力导致服务中断的，学校将尽快恢复，但不承担由此造成的间接损失。\n\n' +
  '如对本服务协议有任何疑问，请通过"意见反馈"与我们联系。';

@Entry
@Component
struct PrivacyTextPage {
  @State pageTitle: string = '使用条款及隐私政策';
  @State content: string = PRIVACY_CONTENT;

  aboutToAppear(): void {
    const params: object = router.getParams();
    if (params !== null && params !== undefined) {
      const record = params as Record<string, Object>;
      const typeValue: Object = record['type'];
      if (typeof typeValue === 'string') {
        if (typeValue === 'service') {
          this.pageTitle = '服务协议';
          this.content = SERVICE_CONTENT;
        }
      }
    }
  }

  build() {
    Column() {
      TitleBar({ title: this.pageTitle, showBack: true })

      Scroll() {
        Text(this.content)
          .fontSize(14)
          .fontColor($r('app.color.common_color_2'))
          .lineHeight(24)
          .padding({ left: 16, right: 16, top: 16, bottom: 32 })
          .width('100%')
      }
      .width('100%')
      .layoutWeight(1)
      .scrollBar(BarState.Off)
      .align(Alignment.Top)
      .backgroundColor($r('app.color.white'))
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.white'))
  }
}
