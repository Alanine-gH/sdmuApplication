import { BusinessError } from '@kit.BasicServicesKit';
import { ApiService } from '../network/ApiService';
import { ApiResponse } from '../model/ResponseModel';
import { TodoItem } from '../model/TodoModel';

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

  aboutToAppear(): void {
    ApiService.getTodoList()
      .then((response: ApiResponse<TodoItem[]>) => {
        this.todoCount = ApiService.isSuccess(response) ? response.data.length : 0;
        // 与 APK 一致：无数据即空态
        this.isEmpty = this.todoCount === 0;
      })
      .catch((error: BusinessError) => {
        this.isEmpty = true;
      });
  }

  build() {
    Column() {
      if (this.isEmpty) {
        // 空态：插图 + 提示文字，整页居中
        Column() {
          Image($r('app.media.mobile_campus_page_empty'))
            .width(220)
            .height(180)
            .objectFit(ImageFit.Contain)
          Text('暂时没有内容，先去其他的吧~')
            .fontSize(18)
            .fontColor($r('app.color.menu_divider'))
            .margin({ top: 24 })
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
        .backgroundColor($r('app.color.common_color_6'))
      } else {
        // 服务端有数据时的占位列表（与 APK 教师端待办卡一致）
        Column() {
          ForEach([], (item: TodoItem) => {
            Text(item.title)
              .fontSize(16)
              .fontColor($r('app.color.common_color_1'))
              .padding(12)
          }, (item: TodoItem) => item.id)
        }
        .width('100%')
        .layoutWeight(1)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.common_color_6'))
  }
}
