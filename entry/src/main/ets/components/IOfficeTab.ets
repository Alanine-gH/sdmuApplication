import { router } from '@kit.ArkUI';
import { BusinessError } from '@kit.BasicServicesKit';
import { ApiService } from '../network/ApiService';
import { ApiResponse } from '../model/ResponseModel';
import { NewsItem } from '../model/NewsModel';
import { TodoItem } from '../model/TodoModel';

/**
 * I办公 Tab — 复刻 IOfficeFragment（PullToRefreshLayout + RecyclerView #F2F2F2）。
 * 内容模块：
 *   - mobile_campus_view_main_notice.xml（通知公告卡）
 *   - mobile_campus_view_main_group_title.xml（分组标题）
 *   - mobile_campus_item_home_unify_todo.xml（待办条目：标题16fp#333333 + 截止时间13fp#999999）
 *   - layout_home_unify_todo_empty.xml（待办空态）
 */

class IOfficeNoticeInfo {
  title: string;
  date: string;

  constructor(title: string, date: string) {
    this.title = title;
    this.date = date;
  }
}

class IOfficeTodoInfo {
  title: string;
  applyPeople: string;
  deadline: string;

  constructor(title: string, applyPeople: string, deadline: string) {
    this.title = title;
    this.applyPeople = applyPeople;
    this.deadline = deadline;
  }
}

@Component
export struct IOfficeTab {
  @State noticeList: IOfficeNoticeInfo[] = [
    new IOfficeNoticeInfo('关于2026年寒假放假及下学期开学安排的通知', '2026-11-10')
  ];
  @State todoList: IOfficeTodoInfo[] = [
    new IOfficeTodoInfo('教职工年度考核表填报', '人事处', '2026-11-20 17:30'),
    new IOfficeTodoInfo('实验室安全隐患排查整改', '教务处', '2026-11-25 12:00'),
    new IOfficeTodoInfo('科研项目经费预算复核确认', '科研处', '2026-11-30 18:00')
  ];
  @State showBackTop: boolean = false;
  scroller: Scroller = new Scroller();

  aboutToAppear(): void {
    ApiService.getNewsList()
      .then((response: ApiResponse<NewsItem[]>) => {
        if (response.data.length > 0) {
          this.noticeList = response.data.map((news: NewsItem): IOfficeNoticeInfo => {
            return new IOfficeNoticeInfo(news.title, news.publishTime);
          });
        }
      })
      .catch((error: BusinessError) => {
      });
    ApiService.getTodoList()
      .then((response: ApiResponse<TodoItem[]>) => {
        if (response.data.length > 0) {
          this.todoList = response.data.map((todo: TodoItem): IOfficeTodoInfo => {
            return new IOfficeTodoInfo(todo.title, todo.fromUser, todo.deadline);
          });
        }
      })
      .catch((error: BusinessError) => {
      });
  }

  /**
   * mobile_campus_view_main_group_title.xml — 分组标题。
   * 高 px_to_dip_80=40vp、padding 左右 px_to_dip_24=12vp、
   * 标题 px_to_sp_30=15fp @color/mobile_campus_primary_color + icon（drawablePadding px_to_dip_16=8vp）。
   */
  @Builder
  groupTitleCell(title: string, icon: Resource) {
    Column() {
      Row() {
        Image(icon)
          .width(20)
          .height(20)
        Text(title)
          .fontSize(15)
          .fontColor($r('app.color.mobile_campus_primary_color'))
          .margin({ left: 8 })
      }
      .height(40)
      .width('100%')
      .padding({ left: 12, right: 12 })
      .alignItems(VerticalAlign.Center)
      .alignSelf(ItemAlign.Stretch)

      Divider()
        .color($r('app.color.common_color_6'))
        .strokeWidth(1)
    }
    .width('100%')
    .backgroundColor($r('app.color.white'))
  }

  /**
   * mobile_campus_view_main_notice.xml — 通知公告卡。
   * padding px_to_dip_24=12vp；标题 px_to_dip_30=15fp #333333；
   * “发布日期：” + 日期 px_to_dip_28=14fp #999999、marginTop px_to_dip_16=8vp。
   */
  @Builder
  noticeEntryCell(notice: IOfficeNoticeInfo) {
    Column() {
      Text(notice.title)
        .fontSize(15)
        .fontColor($r('app.color.common_color_1'))
        .maxLines(2)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .width('100%')
      Row() {
        Text('发布日期：')
          .fontSize(14)
          .fontColor($r('app.color.common_color_3'))
        Text(notice.date)
          .fontSize(14)
          .fontColor($r('app.color.common_color_3'))
      }
      .margin({ top: 8 })
      .alignItems(VerticalAlign.Center)
    }
    .width('100%')
    .padding(12)
    .backgroundColor($r('app.color.white'))
    .onClick(() => {
      router.pushUrl({ url: 'pages/NewsPage' });
    })
  }

  /**
   * mobile_campus_item_home_unify_todo.xml — 待办条目。
   * 高 96dip；标题行：红点 4dip(margin 5dip) + 标题 16.0sp=16fp #333333；
   * 下部：申请人/截止时间 13.0sp=13fp #999999（icon drawablePadding 6dip、行距 4dip）
   * + 右侧标签“办事大厅”（padding 8/5dip、圆角 6dip）；底部 0.5dip 分割线 #E7E7E7。
   */
  @Builder
  todoEntryCell(todo: IOfficeTodoInfo) {
    Column() {
      Row() {
        Column()
          .width(4)
          .height(4)
          .borderRadius(2)
          .backgroundColor($r('app.color.mobile_campus_todo_unread'))
          .margin({ left: 5, top: 5, right: 5 })
        Text(todo.title)
          .fontSize(16)
          .fontColor($r('app.color.common_color_1'))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .layoutWeight(1)
      }
      .width('100%')
      .padding({ top: 12 })
      .alignItems(VerticalAlign.Center)

      Row() {
        Column() {
          Row() {
            Image($r('app.media.icon_unify_todo_apply_people'))
              .width(14)
              .height(14)
            Text(todo.applyPeople)
              .fontSize(13)
              .fontColor($r('app.color.common_color_3'))
              .margin({ left: 6 })
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
          }
          .width('100%')
          .alignItems(VerticalAlign.Center)

          Row() {
            Image($r('app.media.icon_unify_todo_reach_time'))
              .width(14)
              .height(14)
            Text(todo.deadline)
              .fontSize(13)
              .fontColor($r('app.color.common_color_3'))
              .margin({ left: 6 })
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
          }
          .width('100%')
          .margin({ top: 4 })
          .alignItems(VerticalAlign.Center)
        }
        .padding({ left: 14, right: 14 })
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)

        Text('办事大厅')
          .fontSize(12)
          .fontColor($r('app.color.white'))
          .backgroundColor($r('app.color.blue_default'))
          .borderRadius(6)
          .padding({ left: 8, right: 8, top: 5, bottom: 5 })
          .margin({ right: 13 })
      }
      .width('100%')
      .layoutWeight(1)
      .alignItems(VerticalAlign.Center)

      Divider()
        .color($r('app.color.common_color_5'))
        .strokeWidth(0.5)
    }
    .width('100%')
    .height(96)
    .backgroundColor($r('app.color.white'))
    .onClick(() => {
      router.pushUrl({ url: 'pages/TodoPage' });
    })
  }

  /**
   * layout_home_unify_todo_empty.xml — 待办空态。
   * 图 240x105dip + “暂无数据”16.0sp=16fp #BBD2E3。
   */
  @Builder
  todoEmptyCell() {
    Column() {
      Image($r('app.media.icon_unify_todo_empty'))
        .width(240)
        .height(105)
        .objectFit(ImageFit.Contain)
        .margin({ bottom: 10 })
      Text('暂无数据')
        .fontSize(16)
        .fontColor($r('app.color.mobile_campus_unify_todo_empty_text'))
    }
    .width('100%')
    .padding({ top: 20, bottom: 20 })
    .backgroundColor($r('app.color.white'))
    .alignItems(HorizontalAlign.Center)
  }

  build() {
    Column() {
      Stack({ alignContent: Alignment.BottomEnd }) {
        // RecyclerView：#F2F2F2
        Scroll(this.scroller) {
          Column() {
            this.groupTitleCell('通知公告', $r('app.media.mobile_campus_icon_notice'))
            ForEach(this.noticeList, (notice: IOfficeNoticeInfo) => {
              this.noticeEntryCell(notice)
              Divider()
                .color($r('app.color.common_color_6'))
                .strokeWidth(1)
            }, (notice: IOfficeNoticeInfo) => 'office_notice_' + notice.date + '_' + notice.title)

            this.groupTitleCell('办公', $r('app.media.mobile_campus_oa_word'))
            if (this.todoList.length > 0) {
              ForEach(this.todoList, (todo: IOfficeTodoInfo) => {
                this.todoEntryCell(todo)
              }, (todo: IOfficeTodoInfo) => 'office_todo_' + todo.title + '_' + todo.deadline)
            } else {
              this.todoEmptyCell()
            }
          }
          .width('100%')
          .padding({ bottom: 12 })
          .backgroundColor($r('app.color.common_color_6'))
        }
        .scrollable(ScrollDirection.Vertical)
        .width('100%')
        .height('100%')
        .onScroll((xOffset: number, yOffset: number) => {
          this.showBackTop = this.scroller.currentOffset().yOffset > 200;
        })

        // imgTop：右下回顶按钮，layout_margin=8dip
        if (this.showBackTop) {
          Image($r('app.media.mobile_campus_top'))
            .width(40)
            .height(40)
            .margin(8)
            .objectFit(ImageFit.Contain)
            .onClick(() => {
              this.scroller.scrollTo({ xOffset: 0, yOffset: 0 });
              this.showBackTop = false;
            })
        }
      }
      .width('100%')
      .height('100%')
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.white'))
    .padding({ top: 9 })
  }
}
