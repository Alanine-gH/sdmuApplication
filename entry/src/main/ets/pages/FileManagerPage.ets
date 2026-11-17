import { TitleBar } from '../components/TitleBar';

/**
 * 下载文件管理页 — 1:1 复刻 mobile_campus_activity_file_manager.xml
 * 结构：toolbar_normal + MultiStateView(main_bg 白)：
 *   - 文件列表 RecyclerView：条目 marginV 10dip、
 *     CheckBox(marginStart 15dip) + word图标(marginStart 20dip、marginEnd 24dip) +
 *     文件名 17.5fp(px35÷2) #333333 + 创建时间 11.5fp(px23÷2) #333333
 *   - 空态 empty_view：提示文本 12fp #CECECE padding 15vp(px30÷2)
 */
class DownloadFile {
  name: string = '';
  createTime: string = '';

  constructor(name: string, createTime: string) {
    this.name = name;
    this.createTime = createTime;
  }
}

@Entry
@Component
struct FileManagerPage {
  @State files: DownloadFile[] = [];

  @Builder
  fileItem(file: DownloadFile) {
    Row() {
      // rb_select：CheckBox 占位（无选中态时透明）
      Row()
        .width(20)
        .height(20)
        .margin({ left: 15 })

      // 文件类型图标
      Image($r('app.media.mobile_campus_oa_word'))
        .width(32)
        .height(32)
        .margin({ left: 20, right: 24 })

      Column() {
        Text(file.name)
          .fontSize(17.5)
          .fontColor($r('app.color.common_color_1'))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        Text(file.createTime)
          .fontSize(11.5)
          .fontColor($r('app.color.common_color_1'))
          .margin({ top: 2 })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
    }
    .width('100%')
    .padding({ top: 10, bottom: 10 })
    .alignItems(VerticalAlign.Center)
    .backgroundColor($r('app.color.white'))
    .onClick(() => {
      this.getUIContext().getPromptAction().showToast({ message: '文件管理功能已就绪' });
    })
  }

  build() {
    Column() {
      TitleBar({ title: '下载文件管理', showBack: true })

      if (this.files.length === 0) {
        // empty_view 空态：12fp #CECECE、padding 15vp
        Column() {
          Text('暂无下载文件')
            .fontSize(12)
            .fontColor($r('app.color.common_color_4'))
            .padding(15)
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
        .backgroundColor($r('app.color.main_bg'))
      } else {
        List() {
          ForEach(this.files, (file: DownloadFile) => {
            ListItem() {
              this.fileItem(file)
            }
          }, (file: DownloadFile) => file.name)
        }
        .width('100%')
        .layoutWeight(1)
        .backgroundColor($r('app.color.main_bg'))
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.main_bg'))
  }
}
