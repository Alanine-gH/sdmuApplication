import { router } from '@kit.ArkUI';
import { TitleBar } from '../components/TitleBar';

/** 好友模型 — social_friendship_user_item.xml */
class FriendUserInfo {
  id: string;
  noteName: string;
  sex: string;
  department: string;
  isFriend: boolean;
  isTeacher: boolean;

  constructor(id: string, noteName: string, sex: string, department: string, isFriend: boolean, isTeacher: boolean) {
    this.id = id;
    this.noteName = noteName;
    this.sex = sex;
    this.department = department;
    this.isFriend = isFriend;
    this.isTeacher = isTeacher;
  }
}

function buildFriendUsers(): FriendUserInfo[] {
  return [
    new FriendUserInfo('u1', '小柚子', '女', '信息科学与技术学院 · 数据科学与大数据技术', true, false),
    new FriendUserInfo('u2', '阿树', '男', '信息科学与技术学院 · 软件工程', true, false),
    new FriendUserInfo('u3', '李明老师', '男', '信息科学与技术学院 · 教师团队', true, true),
    new FriendUserInfo('u4', '南方有雨', '女', '人文学院 · 汉语言文学', false, false),
    new FriendUserInfo('u5', '晚风', '男', '机械工程学院 · 机械设计制造及其自动化', false, false),
    new FriendUserInfo('u6', '柚子茶', '女', '经济管理学院 · 会计学', false, false),
    new FriendUserInfo('u7', '王华老师', '男', '经济管理学院 · 教师团队', true, true)
  ];
}

/**
 * 好友列表 — 按源布局 1:1 复刻 social_list_fragment.xml + social_friendship_user_item.xml：
 *   LinearLayout vertical
 *   - include toolbar_normal（标题“好友”）
 *   - List：social_friendship_user_item（padding 15/12）
 *     - 头像 px_to_dip_100=50vp，右下角 teacher_icon（教师）
 *     - 备注名 TextSize1（16fp）+ 性别图标 margin-left 4
 *     - 院系 TextSize4（12fp common_color_3）margin-top 4
 *     - 好友状态图标 padding 6，margin 10
 */
@Entry
@Component
struct FriendUserListPage {
  @State users: FriendUserInfo[] = buildFriendUsers();

  build() {
    Column() {
      TitleBar({ title: '好友' })
      List() {
        ForEach(this.users, (user: FriendUserInfo) => {
          ListItem() {
            Row() {
              Stack({ alignContent: Alignment.BottomEnd }) {
                Image($r('app.media.default_avatar'))
                  .width(50)
                  .height(50)
                  .borderRadius(25)
                if (user.isTeacher) {
                  Image($r('app.media.teacher_icon'))
                    .width(14)
                    .height(14)
                }
              }
              .width(50)
              .height(50)

              Column() {
                Row() {
                  Text(user.noteName)
                    .fontSize(16)
                    .fontColor($r('app.color.common_color_1'))
                    .maxLines(1)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                    .layoutWeight(1)
                  Text(user.sex)
                    .fontSize(12)
                    .fontColor(user.sex === '女' ? '#FF6C6C' : '#18B4ED')
                    .margin({ left: 4 })
                }
                .width('100%')
                .alignItems(VerticalAlign.Center)

                Text(user.department)
                  .fontSize(12)
                  .fontColor($r('app.color.common_color_3'))
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
                  .width('100%')
                  .margin({ top: 4 })
              }
              .layoutWeight(1)
              .height(50)
              .justifyContent(FlexAlign.Center)
              .margin({ left: 10 })

              Text(user.isFriend ? '已添加' : '+ 加好友')
                .fontSize(12)
                .fontColor(user.isFriend ? $r('app.color.common_color_3') : $r('app.color.ybg_blue'))
                .padding({ left: 6, right: 6, top: 3, bottom: 3 })
                .border({ width: 0.5, color: user.isFriend ? $r('app.color.common_color_5') : $r('app.color.ybg_blue') })
                .borderRadius(12)
                .margin({ left: 10, right: 10 })
            }
            .width('100%')
            .padding({ left: 15, right: 15, top: 12, bottom: 12 })
            .backgroundColor($r('app.color.main_bg'))
            .onClick(() => {
              router.pushUrl({ url: 'pages/UserDetailPage' });
            })
          }
        }, (user: FriendUserInfo) => user.id)
      }
      .width('100%')
      .layoutWeight(1)
      .backgroundColor($r('app.color.common_color_6'))
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.common_color_6'))
  }
}
