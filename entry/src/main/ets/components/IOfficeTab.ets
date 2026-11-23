import { BusinessError } from '@kit.BasicServicesKit';
import { ApiService } from '../network/ApiService';
import { ApiResponse } from '../model/ResponseModel';
import { TodoItem } from '../model/TodoModel';
import { BreakpointSystem } from '../common/BreakpointSystem';

/**
 * I办公 Tab — 按 APK 实拍（学生账号登录后）：
 * 整页空态「暂时没有内容，先去其他的吧~」
 * （mobile_campus_view_empty 布局：空态插图 + 17fp 蓝灰提示字，居中）。
 * 学生端服务端 getOffice 下发为空 → 与 APK 行为一致展示空态；
 * 保留 getTodoList 拉取逻辑，若服务端后续下发待办则切回列表渲染。
 */
@Component
export struct IOfficeTab {
  @State isEmpty: boolean = true;
  @State todoCount: number = 0;
  @State todoItems: TodoItem[] = [];
  @StorageProp('currentBreakpoint') currentBreakpoint: string = 'sm';
  @StorageProp('heightBreakpoint') heightBreakpoint: string = 'lg';
  @StorageProp('isLandscape') isLandscape: boolean = false;
  @StorageProp('isCompactHeight') isCompactHeight: boolean = false;
  @StorageProp('avoidAreaBottomVp') avoidAreaBottomVp: number = 0;

  private useSideRail(): boolean {
    return BreakpointSystem.shouldUseSideRail(
      this.currentBreakpoint,
      this.heightBreakpoint,
      this.isLandscape
    );
  }

  aboutToAppear(): void {
    ApiService.getTodoList()
      .then((response: ApiResponse<TodoItem[]>) => {
        this.todoItems = ApiService.isSuccess(response) ? response.data : [];
        this.todoCount = this.todoItems.length;
        // 与 APK 一致：无数据即空态
        this.isEmpty = this.todoCount === 0;
      })
      .catch((_error: BusinessError) => {
        this.todoItems = [];
        this.isEmpty = true;
      });
  }

  build() {
    Scroll() {
      Column() {
        if (this.isEmpty) {
          // 空态：插图 + 提示文字，整页居中；紧凑高窗自动缩放插图避免裁切
          Column() {
            Image($r('app.media.mobile_campus_page_empty'))
              .width(this.isCompactHeight ? 140 : 220)
              .height(this.isCompactHeight ? 114 : 180)
              .objectFit(ImageFit.Contain)
            Text('暂时没有内容，先去其他的吧~')
              .fontSize(this.isCompactHeight ? 15 : 18)
              .fontColor($r('app.color.menu_divider'))
              .margin({ top: this.isCompactHeight ? 12 : 24 })
          }
          .width('100%')
          .constraintSize({ minHeight: this.isCompactHeight ? 200 : 360 })
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)
          .backgroundColor($r('app.color.common_color_6'))
        } else {
          // 服务端有数据时的响应式卡片列表（宽屏双列，窄屏单列）
          GridRow({ columns: { xs: 1, sm: 1, md: 2, lg: 2, xl: 2 }, gutter: { x: 12, y: 12 } }) {
            ForEach(this.todoItems, (item: TodoItem) => {
              GridCol({ span: 1 }) {
                Column() {
                  Text(item.title)
                    .fontSize(16)
                    .fontColor($r('app.color.common_color_1'))
                    .maxLines(2)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                }
                .width('100%')
                .padding(12)
                .borderRadius(12)
                .alignItems(HorizontalAlign.Start)
                .backgroundColor($r('app.color.white'))
                .hoverEffect(HoverEffect.Highlight)
              }
            }, (item: TodoItem) => item.id)
          }
          .width('100%')
        }
      }
      .width('100%')
      .padding({
        left: 12,
        right: 12,
        top: 12,
        bottom: this.useSideRail() ? Math.max(16, this.avoidAreaBottomVp + 16) : Math.max(92, this.avoidAreaBottomVp + 76)
      })
    }
    .scrollable(ScrollDirection.Vertical)
    .width('100%')
    .height('100%')
    .align(Alignment.Top)
    .backgroundColor($r('app.color.common_color_6'))
  }
}
