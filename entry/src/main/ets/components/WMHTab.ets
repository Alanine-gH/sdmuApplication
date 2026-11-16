import { router } from '@kit.ArkUI';
import { ApiService } from '../network/ApiService';
import { NewsItem } from '../model/NewsModel';

/**
 * 微门户 Tab — 复刻 mobile_campus_fragment_wmh.xml：
 * RecyclerView @color/common_color_6 背景 + 右下角 45vp 圆形悬浮“顶部”按钮（#97000C）。
 * 子项复刻：
 *   - Banner 轮播（Swiper，圆点指示器 #97000C）
 *   - mobile_campus_view_main_notice.xml（通知公告卡）
 *   - mobile_campus_view_main_schedule.xml（今日课表卡：课程名/教室/时间 3 行）
 *   - mobile_campus_view_main_group_title.xml（分组标题“应用中心”）
 *   - mobile_campus_view_main_app.xml（4 列应用宫格）
 *   - mobile_campus_view_main_news.xml（新闻条目，同 HomeTab newsRow 样式）
 *   - mobile_campus_view_main_empty.xml（空态）
 */
class AppEntry {
  name: string = '';
  target: string = '';
  icon: Resource = $r('app.media.icon_share');

  constructor(name: string, target: string, icon: Resource) {
    this.name = name;
    this.target = target;
    this.icon = icon;
  }
}

class CourseCard {
  num: string = '';
  title: string = '';
  location: string = '';
  time: string = '';

  constructor(num: string, title: string, location: string, time: string) {
    this.num = num;
    this.title = title;
    this.location = location;
    this.time = time;
  }
}

@Component
export struct WMHTab {
  private scroller: Scroller = new Scroller();
  @State newsList: NewsItem[] = [];
  @State showTop: boolean = false;
  private courses: CourseCard[] = [
    new CourseCard('1', '高等数学（下）', '明德楼 302 教室', '08:00 - 09:40'),
    new CourseCard('2', '大学英语（四）', '博文楼 210 教室', '10:00 - 11:40'),
    new CourseCard('3', '数据结构', '致知楼 105 教室', '14:00 - 15:40')
  ];
  private entries: AppEntry[] = [
    new AppEntry('新闻公告', 'pages/NewsPage', $r('app.media.icon_share')),
    new AppEntry('我的课表', 'pages/SchedulePage', $r('app.media.mobile_campus_main_schedule')),
    new AppEntry('待办事项', 'pages/TodoPage', $r('app.media.icon_unify_todo_sort')),
    new AppEntry('我的成绩', 'pages/ScorePage', $r('app.media.examination_table')),
    new AppEntry('考试安排', 'pages/ExamPage', $r('app.media.examination_time')),
    new AppEntry('通讯录', 'pages/ContactPage', $r('app.media.mobile_campus_contact_call')),
    new AppEntry('会议', 'pages/MeetingPage', $r('app.media.mobile_campus_meeting_time_s')),
    new AppEntry('考勤记录', 'pages/AttendancePage', $r('app.media.attendance_time'))
  ];

  aboutToAppear(): void {
    ApiService.getNewsList()
      .then((response) => {
        this.newsList = response.data;
      })
      .catch(() => {
        this.newsList = [];
      });
  }

  /**
   * Banner 轮播单页：高 120vp、圆角 8vp、margin 12vp。
   */
  @Builder
  bannerCell(item: NewsItem) {
    Stack({ alignContent: Alignment.BottomStart }) {
      Image($r('app.media.mobile_campus_main_new_default'))
        .width('100%')
        .height('100%')
        .objectFit(ImageFit.Cover)
        .borderRadius(8)
      Text(item.title)
        .fontSize(14)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.white'))
        .backgroundColor($r('app.color.mobile_campus_banner_title_bg'))
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .margin({ left: 8 })
    }
    .width('100%')
    .height('100%')
    .onClick(() => {
      router.pushUrl({ url: 'pages/NewsDetailPage', params: { id: item.id } });
    })
  }

  /**
   * mobile_campus_view_main_notice.xml — 通知公告卡。
   * tvTitle：px_to_dip_30/2=15fp、common_color_1；
   * tvDate 行：px_to_dip_28/2=14fp、common_color_3、marginTop px_to_dip_16/2=8vp；
   * padding px_to_dip_24/2=12vp、底部 1vp 分隔线 common_color_6。
   */
  @Builder
  noticeCard(item: NewsItem) {
    Column() {
      Text(item.title)
        .fontSize(15)
        .fontColor($r('app.color.common_color_1'))
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .width('100%')
      Row() {
        Text('发布日期：')
          .fontSize(14)
          .fontColor($r('app.color.common_color_3'))
        Text(item.publishTime)
          .fontSize(14)
          .fontColor($r('app.color.common_color_3'))
      }
      .margin({ top: 8 })
      Divider()
        .color($r('app.color.common_color_6'))
        .strokeWidth(1)
        .width('100%')
    }
    .width('100%')
    .padding(12)
    .backgroundColor($r('app.color.white'))
    .onClick(() => {
      router.pushUrl({ url: 'pages/NewsDetailPage', params: { id: item.id } });
    })
  }

  /**
   * mobile_campus_view_main_schedule.xml — 今日课表卡（课程名/教室/时间 3 行）。
   * tvNum：px_to_sp_42/2=21fp、#DFE4EA(menu_divider)、宽 px_to_dip_90/2=45vp、居中；
   * tvTitle：px_to_sp_34/2=17fp、common_color_1；
   * tvLocation：px_to_dip_28/2=14fp、common_color_3、marginTop px_to_dip_16/2=8vp。
   */
  @Builder
  scheduleCard(course: CourseCard) {
    Column() {
      Row() {
        Text(course.num)
          .fontSize(21)
          .fontColor($r('app.color.menu_divider'))
          .width(45)
          .textAlign(TextAlign.Center)
        Column() {
          Text(course.title)
            .fontSize(17)
            .fontColor($r('app.color.common_color_1'))
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .width('100%')
          Text(course.location)
            .fontSize(14)
            .fontColor($r('app.color.common_color_3'))
            .margin({ top: 8 })
          Text(course.time)
            .fontSize(14)
            .fontColor($r('app.color.common_color_3'))
            .margin({ top: 4 })
        }
        .padding(12)
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)
      Divider()
        .color($r('app.color.common_color_6'))
        .strokeWidth(1)
        .width('100%')
    }
    .width('100%')
    .backgroundColor($r('app.color.white'))
    .onClick(() => {
      router.pushUrl({ url: 'pages/SchedulePage' });
    })
  }

  /**
   * mobile_campus_view_main_group_title.xml — 分组标题。
   * 高 px_to_dip_80/2=40vp、padding 左右 px_to_dip_24/2=12vp、
   * 文字 px_to_sp_30/2=15fp、mobile_campus_primary_color、
   * 左侧图标 mobile_campus_main_schedule、drawablePadding px_to_dip_16/2=8vp、
   * 底部 1vp 分隔线 common_color_6。
   */
  @Builder
  groupTitle(title: string) {
    Column() {
      Row() {
        Image($r('app.media.mobile_campus_main_schedule'))
          .width(16)
          .height(16)
          .margin({ right: 8 })
        Text(title)
          .fontSize(15)
          .fontColor($r('app.color.mobile_campus_primary_color'))
      }
      .height(40)
      .padding({ left: 12, right: 12 })
      .alignItems(VerticalAlign.Center)
      Divider()
        .color($r('app.color.common_color_6'))
        .strokeWidth(1)
        .width('100%')
    }
    .width('100%')
    .backgroundColor($r('app.color.white'))
  }

  /**
   * mobile_campus_view_main_app.xml — 4 列宫格 item：
   * 白底、icon 32dip+margin 8dip、名称 px_to_sp_30/2=15fp 加粗 common_color_1 单行。
   */
  @Builder
  appGridCell(entry: AppEntry) {
    Column() {
      Image(entry.icon)
        .width(32)
        .height(32)
        .margin(8)
        .objectFit(ImageFit.Cover)
      Text(entry.name)
        .fontSize(15)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.common_color_1'))
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
    }
    .width('100%')
    .padding({ top: 10, bottom: 10 })
    .backgroundColor($r('app.color.white'))
    .alignItems(HorizontalAlign.Center)
    .onClick(() => {
      router.pushUrl({ url: entry.target });
    })
  }

  /**
   * mobile_campus_view_main_news.xml — 新闻条目（同 HomeTab newsRow 样式）。
   */
  @Builder
  newsRow(item: NewsItem) {
    Column() {
      Row() {
        Image($r('app.media.mobile_campus_main_new_default'))
          .width(72)
          .height(72)
          .margin({ top: 8, bottom: 8, left: 12, right: 12 })
          .objectFit(ImageFit.Cover)
        Column() {
          Text(item.title)
            .fontSize(14)
            .fontColor($r('app.color.common_color_1'))
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .margin({ top: 8, bottom: 8, left: 12, right: 48 })
          Text(item.summary)
            .fontSize(13)
            .fontColor($r('app.color.common_color_3'))
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .margin({ bottom: 8, left: 12, right: 48 })
          Text(item.publishTime)
            .fontSize(13)
            .fontColor($r('app.color.common_color_3'))
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .margin({ bottom: 8, left: 12, right: 48 })
          Divider()
            .color($r('app.color.common_color_6'))
            .strokeWidth(1)
            .width('100%')
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)
    }
    .width('100%')
    .backgroundColor($r('app.color.white'))
    .onClick(() => {
      router.pushUrl({ url: 'pages/NewsDetailPage', params: { id: item.id } });
    })
  }

  /**
   * mobile_campus_view_main_empty.xml — 空态。
   * 图片 200x120vp、提示 px_to_dip_26/2=13fp common_color_3、marginTop px_to_dip_24/2=12vp。
   */
  @Builder
  emptyView() {
    Column() {
      Image($r('app.media.mobile_campus_page_empty'))
        .width(200)
        .height(120)
        .objectFit(ImageFit.Cover)
      Text('暂无新闻')
        .fontSize(13)
        .fontColor($r('app.color.common_color_3'))
        .margin({ top: 12 })
    }
    .width('100%')
    .padding({ top: 5, bottom: 5 })
    .backgroundColor($r('app.color.white'))
    .alignItems(HorizontalAlign.Center)
  }

  build() {
    // RecyclerView 背景 common_color_6 + 右下角悬浮“顶部”按钮
    Stack({ alignContent: Alignment.BottomEnd }) {
      Scroll(this.scroller) {
        Column() {
          // Banner 轮播：高 120vp 圆角 8vp margin 12vp、圆点指示器 #97000C
          if (this.newsList.length > 0) {
            Swiper() {
              ForEach(this.newsList, (item: NewsItem) => {
                this.bannerCell(item)
              }, (item: NewsItem) => 'wmh_banner_' + item.id)
            }
            .width('100%')
            .height(120)
            .margin(12)
            .autoPlay(true)
            .interval(4000)
            .indicatorStyle({ selectedColor: $r('app.color.mobile_campus_primary_color') })
          } else {
            Image($r('app.media.mobile_campus_main_new_default'))
              .width('100%')
              .height(120)
              .margin(12)
              .objectFit(ImageFit.Cover)
              .borderRadius(8)
          }

          // 通知公告卡（取新闻列表第一条）
          if (this.newsList.length > 0) {
            this.noticeCard(this.newsList[0])
          }

          // 今日课表卡（本地内置数据）
          ForEach(this.courses, (course: CourseCard) => {
            this.scheduleCard(course)
          }, (course: CourseCard) => 'course_' + course.num)

          // 分组标题“应用中心”
          this.groupTitle('应用中心')

          // 4 列应用宫格
          Grid() {
            ForEach(this.entries, (entry: AppEntry) => {
              GridItem() {
                this.appGridCell(entry)
              }
            }, (entry: AppEntry) => entry.target)
          }
          .width('100%')
          .columnsTemplate('1fr 1fr 1fr 1fr')

          // 新闻列表
          if (this.newsList.length > 0) {
            ForEach(this.newsList, (item: NewsItem) => {
              this.newsRow(item)
            }, (item: NewsItem) => 'wmh_news_' + item.id)
          } else {
            this.emptyView()
          }
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)
      }
      .width('100%')
      .height('100%')
      .backgroundColor($r('app.color.common_color_6'))
      .scrollBar(BarState.Off)
      .onScroll(() => {
        this.showTop = this.scroller.currentOffset().yOffset > 0;
      })

      // llFloat：45vp 圆形 #97000C、margin 右/下 15vp、icon_home_top 16vp + “顶部” 11fp 白字
      if (this.showTop) {
        Column() {
          Image($r('app.media.icon_home_top'))
            .width(16)
            .height(16)
          Text('顶部')
            .fontSize(11)
            .fontColor($r('app.color.white'))
        }
        .width(45)
        .height(45)
        .borderRadius(22.5)
        .backgroundColor($r('app.color.mobile_campus_primary_color'))
        .margin({ right: 15, bottom: 15 })
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
        .onClick(() => {
          this.scroller.scrollEdge(Edge.Top);
          this.showTop = false;
        })
      }
    }
    .width('100%')
    .height('100%')
  }
}
