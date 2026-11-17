import { TitleBar } from '../components/TitleBar';

/**
 * 步数设置页 — 按反编译布局 1:1 复刻 mobile_campus_activity_app_sport_steps_setting.xml：
 *   LinearLayout vertical
 *   - MToolBar（标题“设置”）
 *   - 说明文字 12sp explainColor padding left/right=15 top=16：“打开后将在榜单中显示您的对应名称”
 *   - 4 个选项行（padding=15）：名称 16sp 黑色 paddingLeft=15、右侧“当前显示”14sp #3A7DF0（不可见）+ 16x16vp 选择图标
 */
@Entry
@Component
struct SportStepsSettingPage {
  @State selected: number = 0;
  private optionLabels: string[] = ['姓名全称', '姓氏 + 老师', '姓氏 + **', '******'];

  build() {
    Column() {
      TitleBar({ title: '设置' })
      // 说明文字：12sp explainColor、paddingLeft/Right=15 paddingTop=16、单行
      Text('打开后将在榜单中显示您的对应名称')
        .fontSize(12)
        .fontColor($r('app.color.explain_color'))
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .width('100%')
        .padding({ left: 15, right: 15, top: 16 })

      ForEach(this.optionLabels, (label: string, index: number) => {
        Row() {
          Text(label)
            .fontSize(16)
            .fontColor($r('app.color.black'))
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .padding({ left: 15 })
            .layoutWeight(1)
          // tvDesc “当前显示”：14sp #3A7DF0 paddingRight=8、选中项显示
          Text('当前显示')
            .fontSize(14)
            .fontColor($r('app.color.sport_steps_blue'))
            .padding({ right: 8 })
            .visibility(this.selected === index ? Visibility.Visible : Visibility.None)
          Image(this.selected === index ? $r('app.media.sport_steps_setting_btn_select') :
            $r('app.media.sport_steps_setting_btn_un_select'))
            .width(16)
            .height(16)
            .objectFit(ImageFit.Contain)
        }
        .width('100%')
        .padding(15)
        .alignItems(VerticalAlign.Center)
        .onClick(() => {
          this.selected = index;
        })
      }, (label: string, index: number) => 'option_' + index.toString() + '_' + label)
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.main_bg'))
  }
}
