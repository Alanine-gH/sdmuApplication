import { router } from '@kit.ArkUI';

/**
 * 添加常用应用页 — 1:1 复刻 mobile_campus_activity_edit_common_app.xml
 *   + layout_header_edit_common_app.xml + item_header_edit_common_app.xml
 *   + item_child_edit_common_app.xml
 * 结构：MToolBar(标题"添加常用应用" + 右侧搜索图标 icon_work_search)
 *   + 背景 #F8F8F8 滚动区(左右 padding 15vp)
 *   + 分组卡片(白色圆角8)：标题 18fp 加粗 #333 高52/60 + 4列宫格应用
 *     item: 图标区 55x45(图标35vp + 角标18vp 减#FD5F65/加#57C06B) + 名称12fp #333 lines2 padding10
 *   + 卡片底部白色圆角条 8vp
 */
interface EditAppItem {
  key: string;
  name: string;
  icon: Resource;
  added: boolean;
}

interface EditAppGroup {
  key: string;
  title: string;
  headerHeight: number;
  items: EditAppItem[];
}

@Entry
@Component
struct EditCommonAppPage {
  @State groups: EditAppGroup[] = [
    {
      key: 'group_common',
      title: '常用应用',
      headerHeight: 52,
      items: [
        { key: 'a1', name: '一网通办', icon: $r('app.media.app_icon'), added: true },
        { key: 'a2', name: '图书馆', icon: $r('app.media.application'), added: true },
        { key: 'a3', name: '教务系统', icon: $r('app.media.report'), added: true },
        { key: 'a4', name: '一卡通', icon: $r('app.media.app_icon'), added: true }
      ]
    },
    {
      key: 'group_all',
      title: '全部应用',
      headerHeight: 60,
      items: [
        { key: 'b1', name: '成绩查询', icon: $r('app.media.report_blue'), added: false },
        { key: 'b2', name: '课表查询', icon: $r('app.media.application'), added: false },
        { key: 'b3', name: '校园资讯', icon: $r('app.media.app_icon'), added: false },
        { key: 'b4', name: '后勤服务', icon: $r('app.media.application'), added: false },
        { key: 'b5', name: '失物招领', icon: $r('app.media.app_icon'), added: false },
        { key: 'b6', name: '会议室预约', icon: $r('app.media.report'), added: false }
      ]
    }
  ];

  private toggleApp(groupId: string, appKey: string): void {
    for (let g = 0; g < this.groups.length; g++) {
      if (this.groups[g].key !== groupId) {
        continue;
      }
      for (let i = 0; i < this.groups[g].items.length; i++) {
        if (this.groups[g].items[i].key === appKey) {
          this.groups[g].items[i].added = !this.groups[g].items[i].added;
        }
      }
    }
  }

  private goSearch(): void {
    router.pushUrl({ url: 'pages/EditCommonAppSearchPage' });
  }

  @Builder
  statusBadge(added: boolean) {
    Stack() {
      Circle()
        .width(16)
        .height(16)
        .fill(added ? $r('app.color.color_jian') : $r('app.color.report_rate_green'))
      Column()
        .width(10)
        .height(2)
        .borderRadius(1)
        .backgroundColor($r('app.color.white'))
      if (!added) {
        Column()
          .width(2)
          .height(10)
          .borderRadius(1)
          .backgroundColor($r('app.color.white'))
      }
    }
    .width(18)
    .height(18)
    .alignContent(Alignment.Center)
  }

  @Builder
  appGrid(group: EditAppGroup) {
    Flex({ wrap: FlexWrap.Wrap }) {
      ForEach(group.items, (item: EditAppItem) => {
        Column() {
          Stack({ alignContent: Alignment.TopEnd }) {
            Column() {
              Image(item.icon)
                .width(35)
                .height(35)
                .objectFit(ImageFit.Cover)
            }
            .width(55)
            .height(45)
            .justifyContent(FlexAlign.End)
            .alignItems(HorizontalAlign.Center)

            this.statusBadge(item.added)
          }
          .width(55)
          .height(45)
          .margin({ top: 5 })

          Text(item.name)
            .fontSize(12)
            .fontColor('#333333')
            .textAlign(TextAlign.Center)
            .maxLines(2)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .width('100%')
            .padding(10)
        }
        .width('25%')
        .alignItems(HorizontalAlign.Center)
        .onClick(() => {
          this.toggleApp(group.key, item.key);
        })
      }, (item: EditAppItem): string => item.key)
    }
    .width('100%')
    .backgroundColor($r('app.color.white'))
  }

  build() {
    Column() {
      // MToolBar：标题 + 右侧搜索图标
      Row() {
        Text('＜')
          .fontSize(16)
          .fontColor($r('app.color.common_color_1'))
          .width(40)
          .height('100%')
          .textAlign(TextAlign.Center)
          .margin({ left: 15 })
          .onClick(() => {
            router.back();
          })
        Text('添加常用应用')
          .fontSize(16)
          .fontColor($r('app.color.common_color_1'))
          .layoutWeight(1)
          .textAlign(TextAlign.Center)
          .maxLines(1)
        Image($r('app.media.icon_work_search'))
          .width(22)
          .height(22)
          .padding(3)
          .margin({ right: 12 })
          .onClick(() => {
            this.goSearch();
          })
      }
      .width('100%')
      .height(44)
      .alignItems(VerticalAlign.Center)
      .backgroundColor($r('app.color.main_bg'))

      Scroll() {
        Column() {
          ForEach(this.groups, (group: EditAppGroup) => {
            Column() {
              // 卡片顶部圆角标题
              Text(group.title)
                .fontSize(18)
                .fontWeight(FontWeight.Bold)
                .fontColor('#333333')
                .width('100%')
                .height(group.headerHeight)
                .padding({ left: 14, right: 14 })
                .backgroundColor($r('app.color.white'))
                .borderRadius({ topLeft: 8, topRight: 8 })

              this.appGrid(group)

              // 卡片底部圆角条
              Column()
                .width('100%')
                .height(8)
                .backgroundColor($r('app.color.white'))
                .borderRadius({ bottomLeft: 8, bottomRight: 8 })
            }
            .width('100%')
          }, (group: EditAppGroup): string => group.key)
        }
        .padding({ left: 15, right: 15 })
      }
      .scrollBar(BarState.Off)
      .width('100%')
      .layoutWeight(1)
      .backgroundColor($r('app.color.edit_common_app_bg'))
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.edit_common_app_bg'))
  }
}
