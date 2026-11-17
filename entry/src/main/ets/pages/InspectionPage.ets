import { router } from '@kit.ArkUI';
import { TitleBar } from '../components/TitleBar';

/**
 * 巡检主页 — 1:1 复刻自：
 *   inspection_activity.xml（#F2F2F2 背景 + ExpandableListView + 底部更多条 rlMore）
 *   inspection_view_header.xml（记录卡片 + 选择宿舍）
 *   inspection_item_group.xml（分组头：待检寝室）
 *   inspection_view_item.xml（寝室行：302室 + 拍照 + 箭头）
 */

class DormRoomItem {
  name: string;

  constructor(name: string) {
    this.name = name;
  }
}

@Component
struct InspectionRoomRow {
  @Prop roomName: string = '';

  build() {
    Column() {
      Row() {
        Text(this.roomName)
          .fontSize(16)
          .fontColor($r('app.color.common_color_1'))
          .height('100%')
          .textAlign(TextAlign.Center)
        Blank()
        Image($r('app.media.inspection_photo'))
          .width(24)
          .height(24)
          .objectFit(ImageFit.Contain)
        Image($r('app.media.inspection_arrow_right'))
          .width(16)
          .height(16)
          .objectFit(ImageFit.Contain)
          .margin({ left: 8 })
      }
      .width('100%')
      .height(45)
      .padding({ left: 50, right: 15 })
      .alignItems(VerticalAlign.Center)

      Divider()
        .color($r('app.color.inspection_divider'))
        .strokeWidth(0.5)
        .width('100%')
    }
    .width('100%')
    .backgroundColor($r('app.color.white'))
    .onClick(() => {
      router.pushUrl({ url: 'pages/InspectionNewPage' });
    })
  }
}

@Entry
@Component
struct InspectionPage {
  @State recordTitle: string = '第16周  宿舍检查记录';
  @State isEditingTitle: boolean = false;
  @State showDormList: boolean = true;
  @State dormRooms: DormRoomItem[] = [
    new DormRoomItem('302室'),
    new DormRoomItem('303室'),
    new DormRoomItem('304室'),
    new DormRoomItem('305室')
  ];

  build() {
    Column() {
      // toolbar_normal
      TitleBar({ title: '寝室检查', showBack: true })

      // MultiStateView content
      Scroll() {
        Column() {
          // inspection_view_header：记录卡片 inspection_shape_record
          Column() {
            // tvUpdate 修改（common_color_7 + change 图标）
            Row() {
              Image($r('app.media.change'))
                .width(16)
                .height(16)
                .objectFit(ImageFit.Contain)
              Text('修改')
                .fontSize(12)
                .fontColor($r('app.color.common_color_7'))
                .margin({ left: 4 })
            }
            .width('100%')
            .justifyContent(FlexAlign.End)
            .onClick(() => {
              this.isEditingTitle = !this.isEditingTitle;
            })

            // img + tvTitle
            Row() {
              Image($r('app.media.inspection_pic'))
                .width(56)
                .height(56)
                .objectFit(ImageFit.Contain)
              if (this.isEditingTitle) {
                TextInput({ text: this.recordTitle })
                  .fontSize(17)
                  .fontColor($r('app.color.common_color_1'))
                  .backgroundColor(Color.Transparent)
                  .padding(0)
                  .margin({ left: 24, right: 24 })
                  .layoutWeight(1)
                  .maxLength(15)
                  .onChange((value: string) => {
                    this.recordTitle = value;
                  })
              } else {
                Text(this.recordTitle)
                  .fontSize(17)
                  .fontColor($r('app.color.common_color_1'))
                  .maxLines(2)
                  .margin({ left: 24, right: 24 })
                  .layoutWeight(1)
              }
            }
            .width('100%')
            .alignItems(VerticalAlign.Center)
          }
          .width('100%')
          .padding(15)
          .backgroundColor($r('app.color.white'))
          .borderRadius(4)
          .margin(15)

          // tvSelect 选择宿舍
          Row() {
            Text('选择宿舍')
              .fontSize(17)
              .fontColor($r('app.color.common_color_1'))
            Image($r('app.media.arrow_down2'))
              .width(16)
              .height(16)
              .objectFit(ImageFit.Contain)
              .margin({ left: 8 })
          }
          .width('100%')
          .alignItems(VerticalAlign.Center)
          .margin(15)
          .onClick(() => {
            this.showDormList = !this.showDormList;
          })

          if (this.showDormList) {
            // inspection_item_group：分组头 inspection_shape_check
            Row() {
              Image($r('app.media.inspection_check'))
                .width(20)
                .height(20)
                .objectFit(ImageFit.Contain)
              Text('待检寝室')
                .fontSize(14)
                .fontColor($r('app.color.common_color_31'))
                .margin({ left: 15 })
            }
            .width('100%')
            .height(40)
            .padding({ left: 15 })
            .alignItems(VerticalAlign.Center)
            .backgroundColor($r('app.color.white'))
            .border({ width: 0.5, color: $r('app.color.inspection_divider') })

            // inspection_view_item：寝室列表
            ForEach(this.dormRooms, (room: DormRoomItem) => {
              InspectionRoomRow({ roomName: room.name })
            }, (room: DormRoomItem) => room.name)
          }
        }
        .width('100%')
      }
      .width('100%')
      .layoutWeight(1)
      .align(Alignment.TopStart)
      .scrollBar(BarState.On)

      // rlMore（源布局 visibility=gone，保持隐藏还原）
      Row() {
        Row() {
          Image($r('app.media.instection_star'))
            .width(18)
            .height(18)
            .objectFit(ImageFit.Contain)
          Text('星级评分')
            .fontSize(17)
            .fontColor($r('app.color.white'))
            .margin({ left: 10 })
        }
        .alignItems(VerticalAlign.Center)

        Blank()

        Row() {
          Text('点击查看更多')
            .fontSize(17)
            .fontColor($r('app.color.white'))
          Image($r('app.media.my_check_while'))
            .width(16)
            .height(16)
            .objectFit(ImageFit.Contain)
            .margin({ left: 8 })
        }
        .alignItems(VerticalAlign.Center)
        .onClick(() => {
          router.pushUrl({ url: 'pages/InspectionRankPage' });
        })
      }
      .width('calc(100% - 30vp)')
      .height(62)
      .padding(12)
      .alignItems(VerticalAlign.Center)
      .backgroundColor($r('app.color.inspection_more_green'))
      .borderRadius(4)
      .margin({ left: 15, right: 15, bottom: 27 })
      .visibility(Visibility.None)
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.common_color_6'))
  }
}
