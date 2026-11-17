import { TitleBar } from '../components/TitleBar';

/**
 * 报告编辑 — 1:1 复刻（px_to_dip_N = N/2 vp, px_to_sp_N = N/2 fp）：
 * mobile_campus_meeting_activity_report_edit.xml：toolbar + edit_content
 *   （TextInput 竖排 flex1 padding 25/20/25/20）+ 底部 40vp 行（相机 marginStart 13 / 相册 marginStart 15）
 *   + photoAdapter 横向照片列表 padding 8
 */

interface ReportPhoto {
  photoId: string;
  label: string;
  color: string;
}

@Entry
@Component
struct MeetingReportEditPage {
  @State reportText: string = '会议围绕秋季学期教学安排展开：\n各学院汇报期中教学检查情况…';
  @State photos: ReportPhoto[] = [
    { photoId: 'p1', label: 'IMG_001', color: '#E7E7E7' },
    { photoId: 'p2', label: 'IMG_002', color: '#D0D0D0' },
    { photoId: 'p3', label: 'IMG_003', color: '#E7E7E7' }
  ];

  build() {
    Column() {
      TitleBar({ title: '报告编辑', showBack: true })

      // edit_content：paddingLeft/Right 25 paddingTop/Bottom 20
      TextArea({ text: this.reportText, placeholder: '请输入会议报告内容' })
        .fontSize(16)
        .fontColor($r('app.color.common_color_1'))
        .placeholderColor($r('app.color.common_color_35'))
        .placeholderFont({ size: 16 })
        .backgroundColor($r('app.color.white'))
        .padding({ left: 25, right: 25, top: 20, bottom: 20 })
        .width('100%')
        .layoutWeight(1)
        .onChange((value: string) => {
          this.reportText = value;
        })

      // 底部相机/相册行 40vp
      Row() {
        Image($r('app.media.mobile_campus_meeting_camera'))
          .width(22)
          .height(22)
          .margin({ left: 13 })
          .onClick(() => {
            this.getUIContext().getPromptAction().showToast({ message: '打开相机' });
          })

        Image($r('app.media.mobile_campus_meeting_image'))
          .width(22)
          .height(22)
          .margin({ left: 15 })
          .onClick(() => {
            this.getUIContext().getPromptAction().showToast({ message: '打开相册' });
          })
      }
      .width('100%')
      .height(40)
      .alignItems(VerticalAlign.Center)

      // photoAdapter：横向照片 padding 8
      Scroll() {
        Row() {
          ForEach(this.photos, (photo: ReportPhoto) => {
            Column() {
              Text(photo.label)
                .fontSize(11)
                .fontColor($r('app.color.common_color_3'))
            }
            .width(60)
            .height(60)
            .backgroundColor(photo.color)
            .justifyContent(FlexAlign.Center)
            .alignItems(HorizontalAlign.Center)
            .margin({ right: 8 })
          }, (photo: ReportPhoto) => photo.photoId)
        }
        .padding(8)
      }
      .width('100%')
      .scrollable(ScrollDirection.Horizontal)
      .scrollBar(BarState.Off)
      .backgroundColor($r('app.color.white'))
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.white'))
  }
}
