import { router } from '@kit.ArkUI';

/**
 * 新鲜事页 — 1:1 复刻 social_news_head.xml：
 * read_container（divider_normal + 阅读头行 + social_read_item 列表 + 校园入口）
 * 背景 common_color_6，内容区 main_bg 白色
 */
interface ReadNewsItem {
  id: number;
  title: string;
  time: string;
  readNum: string;
  image: Resource;
}

@Entry
@Component
struct SocialNewNewsPage {
  @State readNewsList: ReadNewsItem[] = [
    {
      id: 1,
      title: '关于举办2026年校园文化艺术节的通知',
      time: '11-15 10:20',
      readNum: '阅读 1024',
      image: $r('app.media.social_banner_default')
    },
    {
      id: 2,
      title: '图书馆近期开放时间调整公告',
      time: '11-14 16:35',
      readNum: '阅读 866',
      image: $r('app.media.mobile_campus_main_new_default')
    },
    {
      id: 3,
      title: '我校学子在省运动会中再创佳绩',
      time: '11-13 09:00',
      readNum: '阅读 2043',
      image: $r('app.media.mobile_campus_main_head_logo')
    }
  ];

  @Builder
  readItemBuilder(item: ReadNewsItem) {
    Row() {
      Image(item.image)
        .width(110)
        .height(70)
        .objectFit(ImageFit.Fill)
        .borderRadius(2)
      Column() {
        Text(item.title)
          .fontSize(16)
          .fontColor($r('app.color.common_color_1'))
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .padding({ left: 15 })
          .width('100%')
        Row() {
          Text(item.time)
            .fontSize(14)
            .fontColor($r('app.color.common_color_3'))
            .padding({ left: 15 })
            .layoutWeight(1)
          Text(item.readNum)
            .fontSize(14)
            .fontColor($r('app.color.common_color_3'))
            .textAlign(TextAlign.End)
            .layoutWeight(1)
        }
        .width('100%')
        .padding({ top: 10 })
        .alignItems(VerticalAlign.Center)
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .padding({ left: 15, right: 15, top: 10, bottom: 10 })
    .alignItems(VerticalAlign.Center)
    .onClick(() => {
      router.pushUrl({ url: 'pages/NewsDetailPage', params: { title: item.title } });
    })
  }

  build() {
    Column() {
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
        Text('新鲜事')
          .fontSize(16)
          .fontColor($r('app.color.common_color_1'))
          .layoutWeight(1)
          .textAlign(TextAlign.Center)
          .maxLines(1)
        Blank()
          .width(40)
      }
      .width('100%')
      .height(44)
      .alignItems(VerticalAlign.Center)
      .backgroundColor($r('app.color.main_bg'))
      Divider()
        .color($r('app.color.common_color_5'))
        .strokeWidth(0.5)
        .width('100%')

      Scroll() {
        Column() {
          Divider()
            .color($r('app.color.common_color_6'))
            .strokeWidth(4)
            .width('100%')
          Divider()
            .color($r('app.color.common_color_5'))
            .strokeWidth(0.5)
            .width('100%')

          Row() {
            Image($r('app.media.social_reading'))
              .width(18)
              .height(18)
              .objectFit(ImageFit.Contain)
              .margin({ top: 1 })
            Text('阅读')
              .fontSize(14)
              .fontColor($r('app.color.common_color_3'))
              .margin({ left: 5 })
              .layoutWeight(1)
            Row() {
              Text('更多')
                .fontSize(14)
                .fontColor($r('app.color.common_color_4'))
              Image($r('app.media.arrow_right2'))
                .width(12)
                .height(12)
                .objectFit(ImageFit.Contain)
                .margin({ top: 1 })
            }
            .alignItems(VerticalAlign.Center)
          }
          .width('100%')
          .padding({ left: 15, right: 15, top: 10, bottom: 10 })
          .alignItems(VerticalAlign.Center)

          Divider()
            .color($r('app.color.common_color_5'))
            .strokeWidth(0.5)
            .width('100%')

          ForEach(this.readNewsList, (item: ReadNewsItem) => {
            this.readItemBuilder(item)
            Divider()
              .color($r('app.color.common_color_5'))
              .strokeWidth(0.5)
              .width('100%')
          }, (item: ReadNewsItem) => item.id.toString())

          Divider()
            .color($r('app.color.common_color_6'))
            .strokeWidth(4)
            .width('100%')
          Divider()
            .color($r('app.color.common_color_5'))
            .strokeWidth(0.5)
            .width('100%')

          Row() {
            Image($r('app.media.social_location'))
              .width(18)
              .height(18)
              .objectFit(ImageFit.Contain)
              .margin({ top: 1 })
            Text('校园')
              .fontSize(14)
              .fontColor($r('app.color.common_color_3'))
              .margin({ left: 5 })
          }
          .width('100%')
          .padding({ left: 15, right: 15, top: 10, bottom: 10 })
          .alignItems(VerticalAlign.Center)

          Divider()
            .color($r('app.color.common_color_5'))
            .strokeWidth(0.5)
            .width('100%')
        }
        .width('100%')
        .backgroundColor($r('app.color.main_bg'))
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)
      .align(Alignment.Top)
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.common_color_6'))
  }
}
