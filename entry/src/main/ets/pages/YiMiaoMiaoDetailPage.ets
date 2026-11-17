import { TitleBar } from '../components/TitleBar';

/**
 * 易喵喵详情页 — 1:1 复刻 mobile_campus_activity_yiban_ymm.xml
 * 结构：LinearLayout(vertical, center_horizontal) + toolbar_normal
 *   - ScrollView > LinearLayout(vertical)：
 *     - social_post_item：头像 40x40(px80÷2)、昵称 16fp(px32÷2)、学校/时间 12fp(px24÷2)、正文 15fp(px30÷2)
 *       item padding l/r 15(px30÷2) t 10(px20÷2) b 7(px14÷2)
 *     - View 高 2vp(px4÷2)
 *     - 评论/点赞操作栏 RelativeLayout（默认 gone，数据内置）
 * 内置数据：一条易喵喵帖子。
 */
@Entry
@Component
struct YiMiaoMiaoDetailPage {
  @State nickName: string = '易喵喵小助手';
  @State schoolName: string = '山东管理学院';
  @State publishTime: string = '10分钟前';
  @State contentText: string = '今天食堂二楼新出了麻辣香锅，欢迎大家去品尝~';
  @State commentCount: string = '12';
  @State likeCount: string = '58';

  build() {
    Column() {
      TitleBar({ title: '易喵喵', showBack: true })

      Scroll() {
        Column() {
          // include social_post_item
          Column() {
            Row() {
              Stack({ alignContent: Alignment.BottomEnd }) {
                Image($r('app.media.default_avatar'))
                  .width(40)
                  .height(40)
                  .borderRadius(20)

                Image($r('app.media.social_grade'))
                  .width(14)
                  .height(14)
              }
              .width(40)
              .height(40)

              Column() {
                Row() {
                  Text(this.nickName)
                    .fontSize(16)
                    .fontColor($r('app.color.common_color_1'))
                    .maxLines(1)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                    .layoutWeight(1)
                }
                .width('100%')

                Row() {
                  Text(this.schoolName)
                    .fontSize(12)
                    .fontColor($r('app.color.common_color_3'))
                    .layoutWeight(1)
                    .maxLines(1)

                  Text(this.publishTime)
                    .fontSize(12)
                    .fontColor($r('app.color.common_color_3'))
                    .textAlign(TextAlign.End)
                }
                .width('100%')
              }
              .alignItems(HorizontalAlign.Start)
              .padding({ left: 5 })
              .layoutWeight(1)
            }
            .width('100%')
            .alignItems(VerticalAlign.Center)
            .margin({ bottom: 5 })

            Text(this.contentText)
              .fontSize(15)
              .fontColor($r('app.color.common_color_1'))
              .width('100%')
              .padding({ top: 5, bottom: 4 })
          }
          .width('100%')
          .padding({ left: 15, right: 15, top: 10, bottom: 7 })

          Column()
            .width('100%')
            .height(2)

          // 评论/点赞操作栏（原布局 visibility gone）
          Row() {
            Row() {
              Image($r('app.media.social_comment'))
                .width(16)
                .height(16)
              Text(this.commentCount)
                .fontSize(15)
                .fontColor($r('app.color.common_color_3'))
                .padding({ left: 7 })
            }
            .padding({ top: 10, right: 40, bottom: 10 })

            Row() {
              Image($r('app.media.social_like'))
                .width(16)
                .height(16)
              Text(this.likeCount)
                .fontSize(15)
                .fontColor($r('app.color.common_color_3'))
                .padding({ left: 7 })
            }
            .padding({ top: 10, right: 40, bottom: 10 })
          }
          .width('100%')
          .padding({ left: 15, right: 15 })
          .visibility(Visibility.None)
        }
        .width('100%')
      }
      .scrollBar(BarState.Off)
      .width('100%')
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.main_bg'))
  }
}
