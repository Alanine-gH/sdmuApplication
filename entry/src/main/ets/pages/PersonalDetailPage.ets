import { ApiService } from '../network/ApiService';
import { UserInfo } from '../model/UserModel';
import { TitleBar } from '../components/TitleBar';
import { LoadingView } from '../components/LoadingView';

interface InfoRow {
  rowId: string;
  key: string;
  value: string;
}

/**
 * 个人资料页 — 1:1 复刻（px_to_dip_N = N/2 vp, px_to_sp_N = N/2 fp）：
 * my_user_detail.xml：bg divider_grey(#E7E7E7) + 头部(my_person 高 px_to_dip_220=110vp + 头像 ly_logo px_to_dip_128=64vp mL px_to_dip_30=15vp y偏移 px_to_dip_156=78vp) + my_user_detail_info + 底栏(白底 pad px_to_dip_30=15vp my_user_add + 关注)
 * my_user_detail_info.xml：白底 头部行(padH px_to_dip_30=15vp padV px_to_dip_20=10vp View 75×1 + 姓名 px_to_sp_36=18fp #333 + 男孩图标) + 姓名/学院/专业/班级行(键 px_to_dip_150=75vp px_to_sp_30=15fp #555 值 15fp #333) + 0.5 分隔线
 * mobile_campus_my_item_personalinfo_stringnoteditable.xml：行顶 1dip #F2F2F2 mL15 + 白底 pad px_to_dip_30=15vp 键 120dip px_to_sp_32=16fp #333 值 16fp #333 右对齐 layoutWeight1
 */
@Entry
@Component
struct PersonalDetailPage {
  @State user: UserInfo = new UserInfo('', '', '', '', '', '', '', '', '', '', '');
  @State isLoading: boolean = true;
  @State isOffline: boolean = false;

  aboutToAppear(): void {
    ApiService.getUserInfo('20230001')
      .then((response) => {
        this.user = response.data;
        this.isOffline = response.code === -1;
        this.isLoading = false;
      })
      .catch(() => {
        this.user = new UserInfo('', '暂无数据', '', '', '', '', '', '', '', '', '');
        this.isLoading = false;
      });
  }

  private infoRows(): InfoRow[] {
    const rows: InfoRow[] = [
      { rowId: 'studentNo', key: '学号', value: this.user.studentNo },
      { rowId: 'grade', key: '年级', value: this.user.grade },
      { rowId: 'phone', key: '手机', value: this.user.phone },
      { rowId: 'email', key: '邮箱', value: this.user.email }
    ];
    return rows;
  }

  build() {
    Column() {
      TitleBar({ title: '个人资料', showBack: true })

      if (this.isLoading) {
        LoadingView()
      } else {
        Scroll() {
          Column() {
            // ===== 头部：my_person 背景图 + 头像 =====
            Stack({ alignContent: Alignment.TopStart }) {
              // my_user_big_person / my_user_my_person: 高 px_to_dip_220=110vp
              Image($r('app.media.my_person'))
                .width('100%')
                .height(110)
                .objectFit(ImageFit.Cover)
              // my_user_person: ly_logo px_to_dip_128=64vp mL px_to_dip_30=15vp layout_below backguoud(78vp)
              Image($r('app.media.ly_logo'))
                .width(64)
                .height(64)
                .borderRadius(4)
                .margin({ left: 15 })
                .offset({ y: 78 })
            }
            .width('100%')
            .height(110)

            // ===== my_user_detail_info.xml =====
            Column() {
              // 头部行: padH 15 padV 10 + View 75×1 + 姓名 18fp #333 + 男孩图标
              Row() {
                Row()
                  .width(75)
                  .height(1)
                Text(this.user.name)
                  .fontSize(18)
                  .fontColor($r('app.color.common_color_1'))
                  .maxLines(1)
                  .margin({ left: 12 })
                Image($r('app.media.my_user_boy'))
                  .width(16)
                  .height(16)
                  .margin({ left: 12 })
              }
              .width('100%')
              .padding({ left: 15, right: 15, top: 10, bottom: 10 })
              .alignItems(VerticalAlign.Center)
              .backgroundColor($r('app.color.white'))

              Divider()
                .color($r('app.color.common_color_5'))
                .strokeWidth(0.5)
                .width('100%')
              Divider()
                .color($r('app.color.common_color_6'))
                .strokeWidth(8)
                .width('100%')
              Divider()
                .color($r('app.color.common_color_5'))
                .strokeWidth(0.5)
                .width('100%')

              // 姓名 true_name
              this.userDetailInfoRow('姓名', this.user.name)
              // 学院 academy
              this.userDetailInfoRow('学院', this.user.college)
              // 专业 profession
              this.userDetailInfoRow('专业', this.user.major)
              // 班级 student_class
              this.userDetailInfoRow('班级', this.user.className)
            }
            .width('100%')
            .backgroundColor($r('app.color.white'))

            // ===== mobile_campus_my_item_personalinfo_stringnoteditable.xml =====
            ForEach(this.infoRows(), (infoRow: InfoRow) => {
              Column() {
                // 行顶分隔线: 1dip common_color_6 mL15
                Row()
                  .height(1)
                  .backgroundColor($r('app.color.common_color_6'))
                  .margin({ left: 15 })

                Row() {
                  Text(infoRow.key)
                    .fontSize(16)
                    .fontColor($r('app.color.common_color_1'))
                    .width(120)
                  Text(infoRow.value)
                    .fontSize(16)
                    .fontColor($r('app.color.common_color_1'))
                    .textAlign(TextAlign.End)
                    .layoutWeight(1)
                }
                .width('100%')
                .padding(15)
                .alignItems(VerticalAlign.Center)
                .backgroundColor($r('app.color.white'))
              }
              .width('100%')
              .backgroundColor($r('app.color.white'))
            }, (infoRow: InfoRow) => infoRow.rowId)

            if (this.isOffline) {
              Text('离线数据: 服务器不可达，当前展示本地模拟数据')
                .fontSize(12)
                .fontColor($r('app.color.mobile_campus_primary_color_default'))
                .width('100%')
                .textAlign(TextAlign.Center)
                .padding({ top: 6, bottom: 6 })
                .backgroundColor($r('app.color.common_color_6'))
                .margin({ top: 12 })
            }

            // 底部留白
            Row()
              .height(20)
              .width('100%')
          }
          .width('100%')
          .alignItems(HorizontalAlign.Start)
        }
        .width('100%')
        .layoutWeight(1)
        .scrollBar(BarState.Off)
        .align(Alignment.Top)

        // ===== my_user_detail_button: 白底 pad px_to_dip_30=15vp 关注行 =====
        Row() {
          Image($r('app.media.my_user_add'))
            .width(16)
            .height(16)
          Text('关注')
            .fontSize(15)
            .fontColor($r('app.color.common_color_1'))
            .margin({ left: 15 })
        }
        .width('100%')
        .padding(15)
        .justifyContent(FlexAlign.Center)
        .backgroundColor($r('app.color.main_bg'))
        .onClick(() => {
          this.getUIContext().getPromptAction().showToast({ message: '已关注' });
        })
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.common_color_5'))
  }

  // my_user_detail_info.xml 信息行: 键 75vp 15fp #555 + 值 15fp #333 padH 15 padV 10 + 0.5 分隔线
  @Builder
  userDetailInfoRow(key: string, value: string) {
    Column() {
      Row() {
        Text(key)
          .fontSize(15)
          .fontColor($r('app.color.common_color_2'))
          .width(75)
        Text(value)
          .fontSize(15)
          .fontColor($r('app.color.common_color_1'))
          .layoutWeight(1)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .margin({ left: 0, right: 13 })
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
    .backgroundColor($r('app.color.white'))
  }
}
