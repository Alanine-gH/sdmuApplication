import { EmptyView } from './EmptyView';
import { LoadingView } from './LoadingView';

/**
 * 列表页通用状态容器：加载中 / 空数据 / 正常内容。
 */
@Component
export struct ListStateView {
  @Prop isLoading: boolean = false;
  @Prop isEmpty: boolean = false;

  build() {
    Column() {
      if (this.isLoading) {
        LoadingView()
      } else {
        if (this.isEmpty) {
          EmptyView()
        }
      }
    }
    .width('100%')
    .height('100%')
  }
}
