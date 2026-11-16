import { ApiService } from '../network/ApiService';
import { TodoItem } from '../model/TodoModel';
import { TitleBar } from '../components/TitleBar';
import { EmptyView } from '../components/EmptyView';
import { LoadingView } from '../components/LoadingView';

/**
 * 待办列表页：状态Tag + 展开详情。
 */
@Entry
@Component
struct TodoPage {
  @State todoList: TodoItem[] = [];
  @State isLoading: boolean = true;
  @State expandedId: string = '';

  aboutToAppear(): void {
    ApiService.getTodoList()
      .then((response) => {
        this.todoList = response.data;
        this.isLoading = false;
      })
      .catch(() => {
        this.todoList = [];
        this.isLoading = false;
      });
  }

  build() {
    Column() {
      TitleBar({ title: '待办事项', showBack: true })
      if (this.isLoading) {
        LoadingView()
      } else {
        if (this.todoList.length === 0) {
          EmptyView()
        } else {
          List() {
            ForEach(this.todoList, (item: TodoItem) => {
              ListItem() {
                Column({ space: 8 }) {
                  Row() {
                    Text(item.title)
                      .fontSize(15)
                      .fontWeight(FontWeight.Medium)
                      .fontColor($r('app.color.sdmu_text_primary'))
                      .maxLines(1)
                      .textOverflow({ overflow: TextOverflow.Ellipsis })
                      .layoutWeight(1)
                    Text(item.status === '1' ? '已完成' : '待处理')
                      .fontSize(11)
                      .fontColor(item.status === '1' ?
                        $r('app.color.sdmu_success') : $r('app.color.sdmu_warning'))
                      .padding({ left: 8, right: 8, top: 3, bottom: 3 })
                      .borderRadius(10)
                      .backgroundColor(item.status === '1' ? '#1452C41A' : '#14FAAD14')
                  }
                  .width('100%')
                  Row() {
                    Text('来源: ' + item.fromUser)
                      .fontSize(12)
                      .fontColor($r('app.color.sdmu_text_hint'))
                    Blank()
                    Text('截止: ' + item.deadline)
                      .fontSize(12)
                      .fontColor($r('app.color.sdmu_text_hint'))
                  }
                  .width('100%')
                  if (this.expandedId === item.id) {
                    Text(item.content)
                      .fontSize(13)
                      .lineHeight(22)
                      .fontColor($r('app.color.sdmu_text_secondary'))
                      .width('100%')
                      .padding({ top: 8, bottom: 8 })
                      .backgroundColor($r('app.color.sdmu_bg'))
                      .borderRadius(6)
                  }
                }
                .padding(14)
                .borderRadius(10)
                .backgroundColor($r('app.color.sdmu_card_bg'))
                .margin({ left: 12, right: 12, top: 10 })
                .onClick(() => {
                  if (this.expandedId === item.id) {
                    this.expandedId = '';
                  } else {
                    this.expandedId = item.id;
                  }
                })
              }
            }, (item: TodoItem) => item.id)
          }
          .width('100%')
          .layoutWeight(1)
          .backgroundColor($r('app.color.sdmu_bg'))
          .scrollBar(BarState.Off)
        }
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.sdmu_bg'))
  }
}
