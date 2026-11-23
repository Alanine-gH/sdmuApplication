/**
 * 待办排序弹窗页 — 1:1 复刻 layout_dialog_unify_todo_sort.xml
 * + mobile_campus_item_unify_todo_sort.xml：
 * - 外层 LinearLayout 竖向白底 fill 尺寸（底部面板样式呈现）；
 * - 头部行：tvCancel "取消" 16sp(=16fp) #999999 pad 20/13dip(=20/13vp)；
 *   标题 "系统来源" 17sp(=17fp) bold #333333 居中 pad 20/13 权重 1；
 *   tvOk "确定" 16sp(=16fp) #1B68B7 pad 20/13；
 * - 列表条目：tvContent 16sp(=16fp) #333333 pad 20/12dip(=20/12vp) maxLines 1。
 */
import { router } from '@kit.ArkUI';
import { BreakpointSystem } from '../common/BreakpointSystem';

class TodoSortOption {
  optionId: string = '';
  optionLabel: string = '';

  constructor(optionId: string, optionLabel: string) {
    this.optionId = optionId;
    this.optionLabel = optionLabel;
  }
}

@Entry
@Component
struct SortDialogPage {
  @State selectedIndex: number = 0;
  @StorageProp('currentBreakpoint') currentBreakpoint: string = 'sm';
  @StorageProp('windowHeightVp') windowHeightVp: number = 640;
  @StorageProp('avoidAreaBottomVp') avoidAreaBottomVp: number = 0;
  @StorageProp('avoidAreaLeftVp') avoidAreaLeftVp: number = 0;
  @StorageProp('avoidAreaRightVp') avoidAreaRightVp: number = 0;
  private sortOptions: TodoSortOption[] = [
    new TodoSortOption('all', '全部来源'),
    new TodoSortOption('oa', 'OA系统'),
    new TodoSortOption('jw', '教务系统'),
    new TodoSortOption('hr', '人事系统'),
    new TodoSortOption('lib', '图书馆系统'),
    new TodoSortOption('card', '一卡通系统'),
    new TodoSortOption('fin', '财务系统')
  ];

  build() {
    Column() {
      // 排序面板：白底
      Column() {
        // 头部行：取消 / 系统来源 / 确定
        Row() {
          Text('取消')
            .fontSize(16)
            .fontColor('#999999')
            .padding({ left: 20, right: 20, top: 13, bottom: 13 })
            .onClick(() => {
              router.back();
            })

          Text('系统来源')
            .fontSize(17)
            .fontWeight(FontWeight.Bold)
            .fontColor('#333333')
            .textAlign(TextAlign.Center)
            .layoutWeight(1)
            .padding({ left: 20, right: 20, top: 13, bottom: 13 })

          Text('确定')
            .fontSize(16)
            .fontColor('#1B68B7')
            .padding({ left: 20, right: 20, top: 13, bottom: 13 })
            .onClick(() => {
              router.back();
            })
        }
        .width('100%')
        .alignItems(VerticalAlign.Center)

        // 来源列表
        Scroll() {
          Column() {
            ForEach(this.sortOptions, (option: TodoSortOption, index: number) => {
              Text(option.optionLabel)
                .fontSize(16)
                .fontColor(index === this.selectedIndex ? '#1B68B7' : '#333333')
                .padding({ left: 20, right: 20, top: 12, bottom: 12 })
                .width('100%')
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
                .onClick(() => {
                  this.selectedIndex = index;
                })
            }, (option: TodoSortOption) => option.optionId)
          }
          .width('100%')
        }
        .width('100%')
        .layoutWeight(1)
        .scrollBar(BarState.Off)
        .align(Alignment.Top)
      }
      .width('100%')
      .height('75%')
      .constraintSize({
        maxWidth: BreakpointSystem.getContentMaxWidth(this.currentBreakpoint),
        maxHeight: BreakpointSystem.getDialogMaxHeight(this.windowHeightVp)
      })
      .padding({
        left: this.avoidAreaLeftVp,
        right: this.avoidAreaRightVp,
        bottom: this.avoidAreaBottomVp
      })
      .backgroundColor($r('app.color.white'))
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#99000000')
    .justifyContent(FlexAlign.End)
    .alignItems(HorizontalAlign.Center)
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
  }
}
