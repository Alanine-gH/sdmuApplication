import { TitleBar } from '../components/TitleBar';

/**
 * 消息详情模型 — 服务不可达时使用内置示例数据。
 */
export class EmcMessageDetail {
  title: string;
  time: string;
  sendBy: string;
  content: string;

  constructor(title: string, time: string, sendBy: string, content: string) {
    this.title = title;
    this.time = time;
    this.sendBy = sendBy;
    this.content = content;
  }
}

/** 消息详情示例数据 */
function buildEmcMessageDetail(): EmcMessageDetail {
  return new EmcMessageDetail(
    '关于开展2026年度消防安全专项检查的通知',
    '2026-11-17 09:30',
    '发送人：安全保卫处',
    '各学院、各部门：\n\n为切实加强校园消防安全工作，预防和减少火灾事故的发生，保障师生员工生命财产安全，学校决定于2026年11月20日至11月30日在全校范围内开展消防安全专项检查工作。\n\n一、检查范围\n教学楼、实验楼、图书馆、学生宿舍、食堂、体育馆等人员密集场所及重点防火部位。\n\n二、检查内容\n1. 消防安全责任制度落实情况；\n2. 疏散通道、安全出口是否畅通；\n3. 消防设施、器材是否完好有效；\n4. 用电用气是否存在违规现象。\n\n三、工作要求\n各单位要高度重视此次专项检查工作，认真组织自查，对发现的问题及时整改，确保校园消防安全形势持续稳定。\n\n特此通知。'
  );
}

/**
 * 消息详情页 — 按源布局 1:1 复刻 mobile_campus_activity_emc_message_detail.xml：
 *   LinearLayout vertical（白底）
 *   - include toolbar_normal（TitleBar）
 *   - MultiStateView marginTop=px_to_dip_24=12vp → NestedScrollView：
 *     LinearLayout 白底 padding left/right=px_to_dip_32=16vp：
 *     - tvTitle 20sp 粗体 #333333 marginTop/Bottom=24vp
 *     - tvTime 13sp #999999
 *     - tvSendBy 13sp #999999 marginTop=px_to_dip_32=16vp
 *     - View 分隔线 1vp #F2F2F2 marginTop=px_to_dip_40=20vp
 *     - tvContent 17sp #333333 padding top/bottom=24vp lineSpacingExtra=8dip
 */
@Entry
@Component
struct EmcMessageDetailPage {
  @State detail: EmcMessageDetail = buildEmcMessageDetail();

  build() {
    Column() {
      TitleBar({ title: '消息详情' })
      Scroll() {
        Column() {
          // tvTitle：20sp 粗体 #333333、marginTop/Bottom=24vp
          Text(this.detail.title)
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor('#333333')
            .margin({ top: 24, bottom: 24 })
            .width('100%')
          // tvTime：13sp #999999
          Text(this.detail.time)
            .fontSize(13)
            .fontColor('#999999')
            .width('100%')
          // tvSendBy：13sp #999999、marginTop=px_to_dip_32=16vp
          Text(this.detail.sendBy)
            .fontSize(13)
            .fontColor('#999999')
            .margin({ top: 16 })
            .width('100%')
          // 分隔线：1vp #F2F2F2、marginTop=px_to_dip_40=20vp
          Divider()
            .color('#F2F2F2')
            .strokeWidth(1)
            .margin({ top: 20 })
          // tvContent：17sp #333333、padding top/bottom=24vp、行距 8vp
          Text(this.detail.content)
            .fontSize(17)
            .fontColor('#333333')
            .lineHeight(25)
            .padding({ top: 24, bottom: 24 })
            .width('100%')
        }
        .width('100%')
        .padding({ left: 16, right: 16 })
        .alignItems(HorizontalAlign.Start)
      }
      .width('100%')
      .layoutWeight(1)
      .margin({ top: 12 })
      .align(Alignment.Top)
      .scrollBar(BarState.Off)
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.main_bg'))
  }
}
