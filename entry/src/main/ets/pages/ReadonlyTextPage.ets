import { TitleBar } from '../components/TitleBar';

/**
 * 只读文本页 — 1:1 复刻源布局 activity_readonly_text.xml
 * 结构：toolbar_normal + ScrollView(readonly_content 只读 EditText)
 * 原生 EditText 不可编辑（editable=false / inputType=none），此处用只读 Text 等价还原
 */
const READONLY_CONTENT: string = '一、总则\n\n' +
  '1. 本页用于展示系统下发的只读内容，内容不可编辑。\n\n' +
  '2. 只读文本通常用于公告详情、帮助说明、条款展示等场景。\n\n' +
  '二、说明\n\n' +
  '1. 页面加载时从服务端或本地缓存获取文本内容并填充展示；\n' +
  '2. 文本超出屏幕高度时可通过滚动查看全部内容；\n' +
  '3. 若内容加载失败，将展示错误提示并支持重新加载。';

@Entry
@Component
struct ReadonlyTextPage {
  @State pageTitle: string = '详情';

  build() {
    Column() {
      TitleBar({ title: this.pageTitle, showBack: true })

      Scroll() {
        Text(READONLY_CONTENT)
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
