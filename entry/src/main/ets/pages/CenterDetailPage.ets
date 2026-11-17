import { TitleBar } from '../components/TitleBar';

/**
 * 中心详情页 — 1:1 复刻 mobile_campus_activity_student_center.xml（CenterDetailActivity，VirtualLayoutManager 多段列表）：
 * toolbar_normal + RecyclerView（背景色取 colors[0]）+ 各子模块（mobile_campus_view_main_office_hall /
 * student_style / course_show / center_news.xml）+ 底部 20vp 占位（mobile_campus_activity_center_bottom.xml）。
 * 段结构：标题行(marginT20 padH12：3vp 白色竖条 r30 + 名称 20fp 白 padH8) + 对应内容。
 * 办事大厅：Grid 4列 r12 白卡(图标48 marginT16 + 名称 12fp 黑 bold 2行 marginT15 marginB5，padV5 两侧5)
 * 学生风采：横向等宽卡(高160 r8 图片 + 底部 #99000000 蒙层：名称14fp白/学院 12fp白 marginT8)
 * 课程展示：CardView marginH10 marginT20 marginB10 r5 阴影 + Banner 130vp r8
 * 动态：白卡 r8 marginH12 marginT10 内列表(15fp 黑 pad 12/10，分隔线 #7DEEAE 0.5 marginH10) + 查看更多 14fp #7DEEAE
 */
interface CenterAppItem {
  id: string;
  name: string;
}

interface CenterStyleItem {
  id: string;
  name: string;
  college: string;
  img: Resource;
}

interface CenterNewsItem {
  id: string;
  title: string;
}

@Entry
@Component
struct CenterDetailPage {
  @State centerName: string = '学生发展中心';
  @State centerBgColor: string = '#1B68B7';
  @State officeApps: CenterAppItem[] = [
    { id: 'a1', name: '课程信息查询' },
    { id: 'a2', name: '成绩查询' },
    { id: 'a3', name: '校园卡查询' },
    { id: 'a4', name: '图书馆' },
    { id: 'a5', name: '教室查询' },
    { id: 'a6', name: '请假申请' },
    { id: 'a7', name: '奖学金' },
    { id: 'a8', name: '报修服务' }
  ];
  @State styleList: CenterStyleItem[] = [
    { id: 's1', name: '张明', college: '信息工程学院', img: $r('app.media.social_banner_default') },
    { id: 's2', name: '李华', college: '信息工程学院', img: $r('app.media.market_top') },
    { id: 's3', name: '王芳', college: '会计学院', img: $r('app.media.mobile_campus_reading_bg_card') }
  ];
  @State newsList: CenterNewsItem[] = [
    { id: 'n1', title: '计算机文化基础' },
    { id: 'n2', title: '关于开展2026年春季学期学风建设活动的通知' },
    { id: 'n3', title: '学生发展中心开放日安排' }
  ];

  private bannerImgs: Resource[] = [
    $r('app.media.social_banner_default'),
    $r('app.media.market_top')
  ];

  @Builder
  sectionHeader(name: string) {
    Row() {
      Row()
        .width(3)
        .backgroundColor($r('app.color.white'))
        .borderRadius(30)
        .margin({ top: 2, bottom: 2 })
        .alignSelf(ItemAlign.Stretch)

      Text(name)
        .fontSize(20)
        .fontColor($r('app.color.white'))
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .padding({ left: 8, right: 8 })
    }
    .width('100%')
    .padding({ left: 12, right: 12 })
    .margin({ top: 20 })
  }

  @Builder
  officeHallSection() {
    Column() {
      this.sectionHeader('办事大厅')

      Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.Start }) {
        ForEach(this.officeApps, (item: CenterAppItem) => {
          Row() {
            Row()
              .width(5)

            Column() {
              Image($r('app.media.default_app_icon'))
                .width(48)
                .height(48)
                .margin({ top: 16 })

              Text(item.name)
                .fontSize(12)
                .fontWeight(FontWeight.Bold)
                .fontColor($r('app.color.black'))
                .maxLines(2)
                .textAlign(TextAlign.Center)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
                .padding({ left: 5, right: 5 })
                .margin({ top: 15, bottom: 5 })
            }
            .width('100%')
            .backgroundColor($r('app.color.white'))
            .borderRadius(12)
            .alignItems(HorizontalAlign.Center)

            Row()
              .width(5)
          }
          .width('25%')
          .padding({ top: 5, bottom: 5 })
          .alignItems(VerticalAlign.Center)
        }, (item: CenterAppItem) => item.id)
      }
      .width('100%')
      .padding({ left: 5, right: 5 })
      .margin({ top: 5 })
    }
    .width('100%')
  }

  @Builder
  studentStyleSection() {
    Column() {
      this.sectionHeader('学生风采')

      Row() {
        ForEach(this.styleList, (item: CenterStyleItem) => {
          Stack({ alignContent: Alignment.BottomStart }) {
            Image(item.img)
              .width('100%')
              .height('100%')
              .borderRadius(8)
              .objectFit(ImageFit.Cover)

            Column() {
              Text(item.name)
                .fontSize(14)
                .fontColor($r('app.color.white'))
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
                .padding({ left: 5, right: 5 })
                .width('100%')

              Text(item.college)
                .fontSize(12)
                .fontColor($r('app.color.white'))
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
                .padding({ left: 5, right: 5 })
                .margin({ top: 8 })
                .width('100%')
            }
            .width('100%')
            .padding({ top: 5, bottom: 5 })
            .backgroundColor('#99000000')
            .borderRadius({ bottomLeft: 8, bottomRight: 8 })
          }
          .layoutWeight(1)
          .height(160)
          .padding(5)
        }, (item: CenterStyleItem) => item.id)
      }
      .width('100%')
      .margin({ top: 5 })
    }
    .width('100%')
  }

  @Builder
  courseShowSection() {
    Column() {
      Stack() {
        Swiper() {
          ForEach(this.bannerImgs, (img: Resource, idx: number) => {
            Image(img)
              .width('100%')
              .height('100%')
              .objectFit(ImageFit.Cover)
          }, (img: Resource, idx: number) => `banner_${idx}`)
        }
        .width('100%')
        .height(130)
        .borderRadius(8)
        .autoPlay(true)
        .interval(3000)
      }
      .width('100%')
      .margin({ left: 10, right: 10, top: 20, bottom: 10 })
      .borderRadius(5)
      .clip(true)
      .shadow({ radius: 2, color: 'rgba(0,0,0,0.25)', offsetY: 1 })
    }
    .width('100%')
  }

  @Builder
  newsSection() {
    Column() {
      this.sectionHeader('动态')

      Column() {
        Column() {
          ForEach(this.newsList, (item: CenterNewsItem, idx: number) => {
            Column() {
              Text(item.title)
                .fontSize(15)
                .fontColor($r('app.color.black'))
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
                .width('100%')
                .padding({ left: 12, right: 12, top: 10, bottom: 10 })

              if (idx < this.newsList.length - 1) {
                Divider()
                  .color('#7DEEAE')
                  .strokeWidth(0.5)
                  .margin({ left: 10, right: 10 })
              }
            }
            .width('100%')
            .alignItems(HorizontalAlign.Start)
          }, (item: CenterNewsItem) => item.id)

          Text('查看更多')
            .fontSize(14)
            .fontColor('#7DEEAE')
            .textAlign(TextAlign.Center)
            .width('100%')
            .padding({ top: 10, bottom: 10 })
        }
        .width('100%')
        .backgroundColor($r('app.color.white'))
        .borderRadius(8)
        .padding({ top: 5 })
      }
      .width('100%')
      .margin({ left: 12, right: 12, top: 10 })
    }
    .width('100%')
  }

  build() {
    Column() {
      TitleBar({ title: this.centerName, showBack: true })

      Scroll() {
        Column() {
          this.officeHallSection()
          this.studentStyleSection()
          this.courseShowSection()
          this.newsSection()
          Row()
            .width('100%')
            .height(20)
        }
        .width('100%')
        .backgroundColor(this.centerBgColor)
        .alignItems(HorizontalAlign.Start)
      }
      .width('100%')
      .layoutWeight(1)
      .scrollBar(BarState.Off)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.centerBgColor)
    .alignItems(HorizontalAlign.Start)
  }
}
