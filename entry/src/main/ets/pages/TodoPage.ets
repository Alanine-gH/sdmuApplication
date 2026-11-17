import { router } from '@kit.ArkUI';
import { ApiService } from '../network/ApiService';
import { ApiResponse } from '../model/ResponseModel';
import { TodoItem } from '../model/TodoModel';
import { BusinessError } from '@kit.BasicServicesKit';
import { TitleBar } from '../components/TitleBar';
import { LoadingView } from '../components/LoadingView';

interface TodoTab {
  tabId: number;
  label: string;
}

/**
 * 待办事项页 — 1:1 复刻（px_to_dip_N = N/2 vp, px_to_sp_N = N/2 fp）：
 * mobile_campus_activity_unify_todo.xml：bg #F2F2F2 + toolbar + 白色内容区（搜索行 padV6 + 排序tv 15sp #1B68B7 w120 + vLine 12vp + tab 行 40vp + vLine1 0.5 + 列表区）
 * mobile_campus_item_unify_todo_detail.xml：条目白底 顶分隔线 0.5 #E7E7E7 pad12 tag 38×38 r6 12sp + 标题 16sp #333 mB4 + 13sp #999 行 mT4（图标 drawablePadding 6）
 * mobile_campus_view_todo_item.xml：日程类条目 白底 padV6 marginL px_to_dip_30=15vp 标题 14fp #333 + 时间/地点 12fp #808080 + office_arrow
 * mobile_campus_view_todo_empty.xml：空态 padV px_to_dip_50=25vp 居中 线 14×1vp #8F9FAF + 文本 px_to_sp_32=16fp #8F9FAF marginH px_to_dip_30=15vp
 */
@Entry
@Component
struct TodoPage {
  @State allTodos: TodoItem[] = [];
  @State shownTodos: TodoItem[] = [];
  @State tabs: TodoTab[] = [{ tabId: 0, label: '全部' }, { tabId: 1, label: '待办' }, { tabId: 2, label: '已办' }];
  @State currentTab: number = 0;
  @State keyword: string = '';
  @State sortLabel: string = '全部';
  @State isLoading: boolean = true;
  @State isOffline: boolean = false;
  @State offlineReason: string = '';

  aboutToAppear(): void {
    ApiService.getTodoList()
      .then((response: ApiResponse<TodoItem[]>) => {
        const data: TodoItem[] = response.data;
        if (data.length > 0) {
          this.allTodos = data;
        } else if (response.code !== 0) {
          console.info('TodoPage degrade: code=' + response.code + ' msg=' + response.message);
        }
        if (response.code !== 0) {
          this.isOffline = true;
          this.offlineReason = response.message;
        } else {
          this.isOffline = false;
          this.offlineReason = '';
        }
        this.applyFilter();
        this.isLoading = false;
      })
      .catch((error: BusinessError) => {
        console.info('TodoPage load fail: ' + error.message);
        this.allTodos = [];
        this.shownTodos = [];
        this.isOffline = true;
        this.offlineReason = '网络请求失败: ' + error.message;
        this.isLoading = false;
      });
  }

  private applyFilter(): void {
    const filtered: TodoItem[] = [];
    for (const item of this.allTodos) {
      if (this.currentTab === 1 && item.status !== '0') {
        continue;
      }
      if (this.currentTab === 2 && item.status !== '1') {
        continue;
      }
      if (this.keyword !== '' && item.title.indexOf(this.keyword) < 0) {
        continue;
      }
      filtered.push(item);
    }
    if (this.sortLabel === '最新') {
      filtered.sort((left: TodoItem, right: TodoItem): number => {
        return right.deadline.localeCompare(left.deadline);
      });
    } else if (this.sortLabel === '最早') {
      filtered.sort((left: TodoItem, right: TodoItem): number => {
        return left.deadline.localeCompare(right.deadline);
      });
    }
    this.shownTodos = filtered;
  }

  private cycleSort(): void {
    if (this.sortLabel === '全部') {
      this.sortLabel = '最新';
    } else if (this.sortLabel === '最新') {
      this.sortLabel = '最早';
    } else {
      this.sortLabel = '全部';
    }
    this.applyFilter();
  }

  private tagColor(item: TodoItem): Resource {
    if (item.status === '1') {
      return $r('app.color.mobile_campus_todo_tag_green');
    }
    if (item.type === '高' || item.type === '重要') {
      return $r('app.color.mobile_campus_todo_tag_red');
    }
    return $r('app.color.mobile_campus_todo_tag_blue');
  }

  private tagText(item: TodoItem): string {
    if (item.status === '1') {
      return '已';
    }
    return '待';
  }

  build() {
    Column() {
      TitleBar({ title: '待办事项', showBack: true })

      if (this.isLoading) {
        LoadingView()
      } else {
        // MultiStateView 内容区：llLayout 白底
        Column() {
          // 搜索行: paddingTop/Bottom 6dip
          Row() {
            // etContent: 13sp padL12 padR12 padV7 mL15 bg#F2F2F2 r3 + 搜索图标 drawablePadding 8.5
            Row() {
              Image($r('app.media.icon_unify_todo_search'))
                .width(14)
                .height(14)
                .margin({ right: 8 })
              TextInput({ placeholder: '输入标题进行搜索...', text: this.keyword })
                .fontSize(13)
                .placeholderColor($r('app.color.common_color_3'))
                .placeholderFont({ size: 13 })
                .fontColor($r('app.color.common_color_1'))
                .backgroundColor(Color.Transparent)
                .padding(0)
                .height(30)
                .layoutWeight(1)
                .onChange((value: string) => {
                  this.keyword = value;
                  this.applyFilter();
                })
            }
            .height(30)
            .borderRadius(3)
            .backgroundColor($r('app.color.common_color_6'))
            .padding({ left: 12, right: 12, top: 0, bottom: 0 })
            .alignItems(VerticalAlign.Center)
            .layoutWeight(1)
            .margin({ left: 15, right: 0 })

            // tvSort: 15sp #1B68B7 w120 padL10 padR15 + 排序图标 drawablePadding 8.5
            Row() {
              Text(this.sortLabel)
                .fontSize(15)
                .fontColor($r('app.color.mobile_campus_primary_color_default'))
                .maxLines(1)
              Image($r('app.media.icon_unify_todo_sort'))
                .width(14)
                .height(14)
                .margin({ left: 8 })
            }
            .height(30)
            .width(120)
            .padding({ left: 10, right: 15 })
            .alignItems(VerticalAlign.Center)
            .justifyContent(FlexAlign.End)
            .onClick(() => {
              this.cycleSort();
            })
          }
          .width('100%')
          .padding({ top: 6, bottom: 6 })
          .backgroundColor($r('app.color.white'))

          // vLine: 12dip #F2F2F2
          Row()
            .height(12)
            .width('100%')
            .backgroundColor($r('app.color.common_color_6'))

          // mTabLayout: MagicIndicator 40dip 高
          Row() {
            ForEach(this.tabs, (tab: TodoTab) => {
              Column() {
                Text(tab.label)
                  .fontSize(15)
                  .fontColor(this.currentTab === tab.tabId ? $r('app.color.mobile_campus_primary_color_default') :
                    $r('app.color.common_color_3'))
                  .padding({ top: 5, bottom: 5 })
                  .onClick(() => {
                    this.currentTab = tab.tabId;
                    this.applyFilter();
                  })
                if (this.currentTab === tab.tabId) {
                  // 选中指示条 50×3 圆角2
                  Row()
                    .width(50)
                    .height(3)
                    .borderRadius(2)
                    .backgroundColor($r('app.color.mobile_campus_primary_color_default'))
                } else {
                  Row()
                    .width(50)
                    .height(3)
                    .backgroundColor($r('app.color.white'))
                }
              }
              .justifyContent(FlexAlign.Center)
              .layoutWeight(1)
            }, (tab: TodoTab) => tab.tabId.toString())
          }
          .width('100%')
          .height(40)
          .backgroundColor($r('app.color.white'))

          // vLine1: 0.5dip #F2F2F2
          Divider()
            .color($r('app.color.common_color_6'))
            .strokeWidth(0.5)
            .width('100%')

          if (this.isOffline) {
            Text('离线降级（' + this.offlineReason + '），当前展示本地模拟数据')
              .fontSize(12)
              .fontColor($r('app.color.mobile_campus_primary_color_default'))
              .width('100%')
              .textAlign(TextAlign.Center)
              .padding({ top: 6, bottom: 6 })
              .backgroundColor($r('app.color.common_color_6'))
          }

          // mViewPager2 列表区 bg #F2F2F2
          if (this.shownTodos.length === 0) {
            // mobile_campus_view_todo_empty.xml
            Column() {
              Row() {
                Row()
                  .width(14)
                  .height(1)
                  .backgroundColor($r('app.color.mobile_campus_todo_empty_text'))
                Text('暂无待办事务')
                  .fontSize(16)
                  .fontColor($r('app.color.mobile_campus_todo_empty_text'))
                  .margin({ left: 15, right: 15 })
                Row()
                  .width(14)
                  .height(1)
                  .backgroundColor($r('app.color.mobile_campus_todo_empty_text'))
              }
              .alignItems(VerticalAlign.Center)
            }
            .width('100%')
            .padding({ top: 25, bottom: 25 })
            .backgroundColor($r('app.color.white'))
            .justifyContent(FlexAlign.Center)
          } else {
            List() {
              ForEach(this.shownTodos, (item: TodoItem) => {
                if (item.type === '日程') {
                  // mobile_campus_view_todo_item.xml（日程/会议类条目）
                  ListItem() {
                    this.scheduleTodoRow(item)
                  }
                } else {
                  // mobile_campus_item_unify_todo_detail.xml
                  ListItem() {
                    this.unifyTodoRow(item)
                  }
                }
              }, (item: TodoItem) => item.id)
            }
            .width('100%')
            .layoutWeight(1)
            .backgroundColor($r('app.color.mobile_campus_bg_color'))
            .scrollBar(BarState.Off)
          }
        }
        .width('100%')
        .layoutWeight(1)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.mobile_campus_bg_color'))
  }

  // mobile_campus_item_unify_todo_detail.xml
  @Builder
  unifyTodoRow(item: TodoItem) {
    Column() {
      // 顶部分隔线 0.5dip #E7E7E7
      Divider()
        .color($r('app.color.common_color_5'))
        .strokeWidth(0.5)
        .width('100%')

      Row() {
        // tag: 38×38 r6 12sp + vUnread(4×4 红, gone)
        Stack({ alignContent: Alignment.TopEnd }) {
          Text(this.tagText(item))
            .fontSize(12)
            .fontColor($r('app.color.white'))
            .width(38)
            .height(38)
            .textAlign(TextAlign.Center)
            .borderRadius(6)
            .backgroundColor(this.tagColor(item))
        }
        .width(38)
        .height(38)

        Column() {
          // tvTitle: 16sp #333 marginBottom 4
          Text(item.title)
            .fontSize(16)
            .fontColor($r('app.color.common_color_1'))
            .width('100%')
            .maxLines(2)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .margin({ bottom: 4 })

          // tvApplyPeople: 13sp #999 图标 drawablePadding 6 marginTop 4
          if (item.fromUser !== '') {
            Row() {
              Image($r('app.media.icon_unify_todo_apply_people'))
                .width(13)
                .height(13)
                .margin({ right: 6 })
              Text(item.fromUser)
                .fontSize(13)
                .fontColor($r('app.color.common_color_3'))
                .maxLines(1)
            }
            .margin({ top: 4 })
            .alignItems(VerticalAlign.Center)
          }

          // tvApplyTime / tvReachTime: 时间
          if (item.deadline !== '') {
            Row() {
              Image($r('app.media.icon_unify_todo_apply_time'))
                .width(13)
                .height(13)
                .margin({ right: 6 })
              Text(item.deadline)
                .fontSize(13)
                .fontColor($r('app.color.common_color_3'))
                .maxLines(1)
            }
            .margin({ top: 4 })
            .alignItems(VerticalAlign.Center)
          }

          // tvCurrentNode: 当前节点
          if (item.priority !== '' && item.priority !== '高' && item.priority !== '中' && item.priority !== '低') {
            Row() {
              Image($r('app.media.icon_unify_todo_current_node'))
                .width(13)
                .height(13)
                .margin({ right: 6 })
              Text(item.priority)
                .fontSize(13)
                .fontColor($r('app.color.common_color_3'))
                .maxLines(1)
            }
            .margin({ top: 4 })
            .alignItems(VerticalAlign.Center)
          }
        }
        .alignItems(HorizontalAlign.Start)
        .padding({ left: 12, right: 12 })
        .layoutWeight(1)
      }
      .width('100%')
      .padding(12)
      .alignItems(VerticalAlign.Center)
      .backgroundColor($r('app.color.white'))
    }
    .width('100%')
    .backgroundColor($r('app.color.white'))
    .onClick(() => {
      ApiService.setTodoRead(item.id)
        .then(() => {
        })
        .catch(() => {
        });
      router.pushUrl({ url: 'pages/TodoReadPage' });
    })
  }

  // mobile_campus_view_todo_item.xml（日程类）
  @Builder
  scheduleTodoRow(item: TodoItem) {
    Row() {
      Column() {
        // tvTitle: px_to_sp_28=14fp #333 单行
        Text(item.title)
          .fontSize(14)
          .fontColor($r('app.color.common_color_1'))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        // tvTime/tvLocation: px_to_sp_24=12fp #808080 marginTop px_to_dip_12=6vp
        Row() {
          Text(item.deadline)
            .fontSize(12)
            .fontColor($r('app.color.tab_unselected'))
            .maxLines(1)
          Text(item.fromUser)
            .fontSize(12)
            .fontColor($r('app.color.tab_unselected'))
            .maxLines(1)
            .margin({ left: 36 })
        }
        .margin({ top: 6 })
        .alignItems(VerticalAlign.Center)
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      // office_arrow: marginStart px_to_dip_48=24vp marginEnd px_to_dip_30=15vp
      Image($r('app.media.mobile_campus_office_arrow'))
        .width(16)
        .height(16)
        .margin({ left: 24, right: 15 })
    }
    .width('100%')
    .padding({ top: 6, bottom: 6 })
    .backgroundColor($r('app.color.white'))
    .onClick(() => {
      router.pushUrl({ url: 'pages/ScheduleDetailPage' });
    })
  }
}

