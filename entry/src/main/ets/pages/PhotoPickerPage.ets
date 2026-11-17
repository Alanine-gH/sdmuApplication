import { router } from '@kit.ArkUI';
import { TitleBar } from '../components/TitleBar';

/**
 * 相册选择页 — 1:1 复刻源布局 activity_photo_picker.xml + fragment_photo_picker.xml + item_photo.xml
 * 结构：toolbar_normal(图片) + 九宫格照片列表（方形图 + 选中半透明遮罩 + 右上勾选框）+ 底部操作条
 * 底部操作条：所有图片（左） / 预览（右，未选中时不可用） / 完成(n)
 */
interface PickerPhotoItem {
  photoId: number;
  selected: boolean;
}

@Entry
@Component
struct PhotoPickerPage {
  @State photoList: PickerPhotoItem[] = [];
  @State selectCount: number = 0;

  aboutToAppear(): void {
    const seeds: number[] = [];
    for (let i = 1; i <= 12; i++) {
      seeds.push(i);
    }
    this.photoList = seeds.map((id: number): PickerPhotoItem => {
      return { photoId: id, selected: false };
    });
  }

  private toggleSelect(item: PickerPhotoItem): void {
    const next: PickerPhotoItem[] = this.photoList.map((it: PickerPhotoItem): PickerPhotoItem => {
      if (it.photoId === item.photoId) {
        return { photoId: it.photoId, selected: !it.selected };
      }
      return it;
    });
    this.photoList = next;
    this.selectCount = this.photoList.filter((it: PickerPhotoItem): boolean => it.selected).length;
  }

  @Builder
  /** item_photo.xml：方格图 + 选中遮罩 + 右上勾选框 */
  photoCell(item: PickerPhotoItem) {
    Stack({ alignContent: Alignment.TopEnd }) {
      Image($r('app.media.up_photo_bg'))
        .objectFit(ImageFit.Cover)
        .width('100%')
        .height('100%')
        .padding(2)

      if (item.selected) {
        Column()
          .width('100%')
          .height('100%')
          .margin(2)
          .backgroundColor('#99000000')
      }

      // 勾选框：未选中空心圆 / 选中实心 + 勾
      Stack() {
        if (item.selected) {
          Text('✓')
            .fontSize(10)
            .fontColor('#FFFFFFFF')
            .textAlign(TextAlign.Center)
        }
      }
      .width(18)
      .height(18)
      .borderRadius(9)
      .backgroundColor(item.selected ? $r('app.color.mobile_campus_primary_color') : '#00000000')
      .border({ width: 1.5, color: '#FFFFFFFF' })
      .margin(5)
      .padding(5)
    }
    .width('100%')
    .aspectRatio(1)
    .onClick(() => {
      this.toggleSelect(item);
    })
  }

  build() {
    Column() {
      TitleBar({ title: '图片', showBack: true })

      // 相册九宫格
      Grid() {
        ForEach(this.photoList, (item: PickerPhotoItem) => {
          GridItem() {
            this.photoCell(item)
          }
        }, (item: PickerPhotoItem) => `photo_${item.photoId}`)
      }
      .columnsTemplate('1fr 1fr 1fr')
      .columnsGap(2)
      .rowsGap(2)
      .width('100%')
      .layoutWeight(1)
      .backgroundColor($r('app.color.ybg_white'))

      // fragment_photo_picker 底部操作条：所有图片 / 预览 / 完成(n)
      Row() {
        Text('所有图片')
          .fontSize(14)
          .fontColor($r('app.color.mobile_campus_primary_color'))
          .textAlign(TextAlign.Center)
          .padding(10)
          .borderRadius(4)
          .backgroundColor($r('app.color.common_color_6'))

        Blank()

        Text('预览')
          .fontSize(14)
          .fontColor(this.selectCount > 0 ? $r('app.color.mobile_campus_primary_color') : $r('app.color.common_color_3'))
          .textAlign(TextAlign.Center)
          .padding(10)
          .borderRadius(4)
          .backgroundColor($r('app.color.common_color_6'))
          .enabled(this.selectCount > 0)
          .onClick(() => {
            if (this.selectCount > 0) {
              router.pushUrl({ url: 'pages/PhotoPagerPage' });
            }
          })

        Text(`完成(${this.selectCount})`)
          .fontSize(14)
          .fontColor($r('app.color.mobile_campus_primary_color'))
          .textAlign(TextAlign.Center)
          .padding({ left: 10, right: 10, top: 10, bottom: 10 })
          .borderRadius(4)
          .backgroundColor($r('app.color.common_color_6'))
          .margin({ left: 12 })
          .onClick(() => {
            router.back();
          })
      }
      .width('100%')
      .padding({ left: 12, right: 12, top: 8, bottom: 8 })
      .alignItems(VerticalAlign.Center)
      .backgroundColor($r('app.color.ybg_white'))
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.ybg_white'))
  }
}
