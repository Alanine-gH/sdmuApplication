import { TitleBar } from '../components/TitleBar';

interface FormConfigRow {
  id: string;
  label: string;
  content: string;
}

/**
 * 表单配置页 — 1:1 复刻 mobile_campus_oa_activity_workapply_formconfig.xml：
 * toolbar + ScrollView(bg common_color_6) 内 edit_container 白底 + divider_horizontal_grey_normal(高8)
 * 表单项(oa_widget_select_layout 结构)：padL12 padT15 标签16fp common_color_3 宽80 mr12
 *   内容16fp common_color_1 arrow_right2 mr10 分隔线 mt16 高0.5 common_color_5(位于标签右侧之下)
 * apply_submit：提交(17fp primary bg 白字 padV10) 底部
 */
@Entry
@Component
struct WorkApplyFormConfigPage {
  @State rows: FormConfigRow[] = [
    { id: 'fc1', label: '申请类型', content: '呈批件' },
    { id: 'fc2', label: '文号', content: '院办(2026) 1号' },
    { id: 'fc3', label: '紧急程度', content: '普通' },
    { id: 'fc4', label: '主办部门', content: '教务处' },
    { id: 'fc5', label: '抄送人员', content: '请选择' },
    { id: 'fc6', label: '主题词', content: '教学管理' },
    { id: 'fc7', label: '办理期限', content: '15个工作日' }
  ];

  private toast(msg: string): void {
    this.getUIContext().getPromptAction().showToast({ message: msg });
  }

  build() {
    Column() {
      TitleBar({ title: '表单配置', showBack: true })

      Scroll() {
        Column() {
          // divider_horizontal_grey_normal：高8 common_color_6
          Column()
            .width('100%')
            .height(8)
            .backgroundColor($r('app.color.common_color_6'))

          // edit_container 白底
          Column() {
            ForEach(this.rows, (row: FormConfigRow) => {
              this.configRow(row)
            }, (row: FormConfigRow) => row.id)
          }
          .width('100%')
          .backgroundColor($r('app.color.white'))
        }
        .width('100%')
      }
      .width('100%')
      .layoutWeight(1)
      .scrollBar(BarState.Off)
      .align(Alignment.Top)

      // apply_submit：提交 17fp primary 白底 padV10
      Text('提交')
        .fontSize(17)
        .fontColor($r('app.color.mobile_campus_primary_color_default'))
        .width('100%')
        .padding({ top: 10, bottom: 10 })
        .textAlign(TextAlign.Center)
        .backgroundColor($r('app.color.white'))
        .onClick(() => {
          this.toast('表单配置已提交');
        })
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.common_color_6'))
  }

  // oa_widget_select_layout 结构
  @Builder
  configRow(row: FormConfigRow) {
    Column() {
      Row() {
        // 标签容器 宽80 mr12
        Row() {
          Text('*')
            .fontSize(17)
            .fontWeight(FontWeight.Bold)
            .fontColor($r('app.color.ybg_red'))
            .margin({ right: 4 })
          Text(row.label)
            .fontSize(16)
            .fontColor($r('app.color.common_color_3'))
        }
        .width(80)
        .margin({ right: 12 })
        .alignItems(VerticalAlign.Center)

        // 内容16fp common_color_1
        Text(row.content)
          .fontSize(16)
          .fontColor($r('app.color.common_color_1'))
          .layoutWeight(1)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        // arrow_right2 mr10
        Image($r('app.media.arrow_right2'))
          .width(16)
          .height(16)
          .margin({ right: 10 })
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)

      // 分隔线 mt16 高0.5 位于标签右侧之下
      Divider()
        .color($r('app.color.common_color_5'))
        .strokeWidth(0.5)
        .margin({ top: 16, left: 92 })
    }
    .width('100%')
    .padding({ left: 12, top: 15 })
    .backgroundColor($r('app.color.white'))
    .onClick(() => {
      this.toast(row.label);
    })
  }
}
