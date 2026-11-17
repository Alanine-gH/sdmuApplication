import { router } from '@kit.ArkUI';
import { TitleBar } from '../components/TitleBar';

/**
 * 主页设置页（添加提醒/常用功能管理）— 1:1 复刻 mobile_campus_activity_message_setting.xml + MainSettingAdapter：
 * 背 #F2F2F2 + toolbar（原页隐藏工具栏，此处保留返回能力）+ ExpandableListView（白底 divider 无）：
 * 分组标题 mobile_campus_apppage_app_title.xml：padH12 + 4vp primary 竖条 + 名称 14fp #999 marginL8
 * 子项 mobile_campus_apppage_gridview.xml：pad 12/16 白底 + app item(#F9F9F9：图标32 marginT8 + 名称13fp #333
 * marginT6 + 右上角 12×12 加/减图标 margin 4/4)
 */
interface MainSettingGroup {
  id: string;
  title: string;
  isQuick: boolean;
  apps: MainSettingApp[];
}

interface MainSettingApp {
  id: string;
  name: string;
}

@Entry
@Component
struct MainSettingPage {
  @State groups: MainSettingGroup[] = [
    {
      id: 'g1',
      title: '常用功能',
      isQuick: true,
      apps: [
        { id: 'g1a1', name: '课程查询' },
        { id: 'g1a2', name: '成绩查询' },
        { id: 'g1a3', name: '校园卡' },
        { id: 'g1a4', name: '图书馆' },
        { id: 'g1a5', name: '会议签到' },
        { id: 'g1a6', name: '请假申请' },
        { id: 'g1a7', name: '报修服务' },
        { id: 'g1a8', name: '失物招领' }
      ]
    },
    {
      id: 'g2',
      title: '可选功能',
      isQuick: false,
      apps: [
        { id: 'g2a1', name: '奖学金' },
        { id: 'g2a2', name: '助学金' },
        { id: 'g2a3', name: '心理咨询' },
        { id: 'g2a4', name: '宿舍报修' },
        { id: 'g2a5', name: '就业指导' },
        { id: 'g2a6', name: '档案查询' },
        { id: 'g2a7', name: '一卡通充值' },
        { id: 'g2a8', name: '缴费服务' }
      ]
    }
  ];

  build() {
    Column() {
      TitleBar({ title: '添加提醒', showBack: true })

      Scroll() {
        Column() {
          ForEach(this.groups, (group: MainSettingGroup) => {
            Column() {
              Row() {
                Row()
                  .width(4)
                  .backgroundColor($r('app.color.mobile_campus_primary_color'))
                  .margin({ left: 12, right: 8 })
                  .alignSelf(ItemAlign.Stretch)

                Text(group.title)
                  .fontSize(14)
                  .fontColor($r('app.color.common_color_3'))
                  .padding({ top: 8, bottom: 8 })
              }
              .width('100%')
              .alignItems(VerticalAlign.Center)

              Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.Start }) {
                ForEach(group.apps, (app: MainSettingApp) => {
                  Stack({ alignContent: Alignment.TopEnd }) {
                    Column() {
                      Image($r('app.media.default_app_icon'))
                        .width(32)
                        .height(32)

                      Text(app.name)
                        .fontSize(13)
                        .fontColor($r('app.color.common_color_1'))
                        .maxLines(1)
                        .textOverflow({ overflow: TextOverflow.Ellipsis })
                        .margin({ top: 6 })
                        .padding({ left: 6, right: 6 })
                    }
                    .width('100%')
                    .padding({ top: 8, bottom: 6 })
                    .alignItems(HorizontalAlign.Center)

                    Image(group.isQuick ? $r('app.media.mobile_campus_delete') : $r('app.media.mobile_campus_addto'))
                      .width(12)
                      .height(12)
                      .margin({ top: 4, right: 4 })
                      .objectFit(ImageFit.Contain)
                  }
                  .width('25%')
                  .clip(true)
                  .backgroundColor('#F9F9F9')
                  .onClick(() => {
                    if (group.isQuick) {
                      this.removeApp(group, app);
                    } else {
                      this.addApp(group, app);
                    }
                  })
                }, (app: MainSettingApp) => app.id)
              }
              .width('100%')
              .padding({ left: 12, right: 12, top: 8, bottom: 16 })
              .backgroundColor('#F9F9F9')
            }
            .width('100%')
            .backgroundColor($r('app.color.white'))
            .margin({ top: 8 })
          }, (group: MainSettingGroup) => group.id)
        }
        .width('100%')
      }
      .width('100%')
      .layoutWeight(1)
      .scrollBar(BarState.Off)
      .backgroundColor('#F2F2F2')
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F2F2F2')
    .alignItems(HorizontalAlign.Start)
  }

  private removeApp(group: MainSettingGroup, app: MainSettingApp): void {
    const targetGroup: MainSettingGroup | undefined = this.groups.find((g: MainSettingGroup): boolean => g.id === group.id);
    if (targetGroup !== undefined) {
      targetGroup.apps = targetGroup.apps.filter((a: MainSettingApp): boolean => a.id !== app.id);
      this.groups = this.groups.slice();
    }
  }

  private addApp(group: MainSettingGroup, app: MainSettingApp): void {
    const quickGroup: MainSettingGroup | undefined = this.groups.find((g: MainSettingGroup): boolean => g.isQuick);
    const targetGroup: MainSettingGroup | undefined = this.groups.find((g: MainSettingGroup): boolean => g.id === group.id);
    if (quickGroup === undefined || targetGroup === undefined) {
      return;
    }
    targetGroup.apps = targetGroup.apps.filter((a: MainSettingApp): boolean => a.id !== app.id);
    quickGroup.apps.unshift({ id: app.id, name: app.name });
    this.groups = this.groups.slice();
  }
}
