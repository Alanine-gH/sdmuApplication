import { ApiService } from '../network/ApiService';
import { UserInfo } from '../model/UserModel';
import { TitleBar } from '../components/TitleBar';
import { LoadingView } from '../components/LoadingView';

/**
 * 个人资料页：头像 + 信息行列表。
 */
@Entry
@Component
struct PersonalDetailPage {
  @State user: UserInfo = new UserInfo('', '', '', '', '', '', '', '', '', '', '');

  aboutToAppear(): void {
    ApiService.getUserInfo('20230001')
      .then((response) => {
        this.user = response.data;
      })
      .catch(() => {
        this.user = new UserInfo('', '暂无数据', '', '', '', '', '', '', '', '', '');
      });
  }

  @Builder
  infoRow(label: string, value: string) {
    Row() {
      Text(label)
        .fontSize(14)
        .fontColor($r('app.color.sdmu_text_hint'))
        .width(90)
      Text(value)
        .fontSize(15)
        .fontColor($r('app.color.sdmu_text_primary'))
        .layoutWeight(1)
    }
    .width('100%')
    .height(50)
    .padding({ left: 16, right: 16 })
    .backgroundColor($r('app.color.sdmu_card_bg'))
    .border({ width: { bottom: 1 }, color: $r('app.color.sdmu_divider') })
  }

  build() {
    Column() {
      TitleBar({ title: '个人资料', showBack: true })
      LoadingView()
        .visibility(this.user.name === '' ? Visibility.Visible : Visibility.None)
      Scroll() {
        Column() {
          Column({ space: 8 }) {
            Text('山')
              .fontSize(32)
              .fontColor(Color.White)
              .width(72)
              .height(72)
              .textAlign(TextAlign.Center)
              .backgroundColor($r('app.color.sdmu_primary'))
              .borderRadius(36)
            Text(this.user.name)
              .fontSize(18)
              .fontWeight(FontWeight.Bold)
              .fontColor($r('app.color.sdmu_text_primary'))
          }
          .width('100%')
          .padding({ top: 24, bottom: 24 })
          .alignItems(HorizontalAlign.Center)

          this.infoRow('姓名', this.user.name)
          this.infoRow('学号', this.user.studentNo)
          this.infoRow('学院', this.user.college)
          this.infoRow('专业', this.user.major)
          this.infoRow('班级', this.user.className)
          this.infoRow('年级', this.user.grade)
          this.infoRow('手机', this.user.phone)
          this.infoRow('邮箱', this.user.email)
        }
        .width('100%')
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)
      .align(Alignment.Top)
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.sdmu_bg'))
  }
}
