import { router, promptAction } from '@kit.ArkUI';
import { BusinessError } from '@kit.BasicServicesKit';
import { TitleBar } from '../components/TitleBar';
import { LoadingView } from '../components/LoadingView';
import { ApiService } from '../network/ApiService';
import { ApiResponse } from '../model/ResponseModel';
import { LoginSession } from '../network/LoginSession';
import { SocialUserInfo } from '../model/SocialModels';
import { Constants } from '../data/Constants';

/**
 * 用户主页（校圈他人资料+帖子列表入口）— 1:1 复刻 UserDetailActivity（my_user_detail.xml）+
 * MyUserPresenter/FriendAdapterPresenter1。
 * 【通道实证 2026-11-18 probe_w20_social.py】
 *   - 资料 = GetUserInfoModel.R → POST /mobileapi_ydxy/api/user/getUserInfo
 *     {targetSchoolId,targetUserId,targetUserType,type:""}（校内，实测 code=0 全字段：
 *     userName/nickname/sex/userType/department/professionName/className/avatar/schoolName）
 *     → 真实渲染（实体消费字段：学院/专业/班级行、姓名行、性别图标）；
 *   - 最近图片 getCircleRecentlyPic @ push 域（实测不可达）→ 空隐藏；
 *   - 关注关系 getRelationship / addFriend / deleteFriend / updateNoteName @ push 域（FriendshipFactory
 *     i()=d(ServerType.LIANYI) 实证）→ 实测不可达：关系加载失败按源码 setRelationship(null) 静默保持
 *     默认"关注"态；关注/取关失败 toast network_or_service_error"连接不到网络，请稍后再试"；
 *   - 帖子入口 f3() → MyPostActivity {user_id,user_name,user_type,school_id}。
 */
@Entry
@Component
struct UserDetailPage {
  @State user: SocialUserInfo | null = null;
  @State pageState: number = 0; // 0=loading 1=content 2=error
  @State errMsg: string = '';
  @State followStatus: string = '0'; // 0=未关注 1=已关注 3=互相关注（RelationObj.status，push 域不可达默认 0）
  @State recentPics: string[] = [];
  private targetId: string = '';
  private targetType: string = '';
  private targetSchoolId: string = '';

  aboutToAppear(): void {
    const params: Record<string, Object> = (router.getParams() ?? {}) as Record<string, Object>;
    const pick = (k: string): string => {
      const v: Object | undefined = params[k];
      return typeof v === 'string' ? v as string : '';
    };
    this.targetId = pick('targetId');
    this.targetType = pick('targetUserType');
    this.targetSchoolId = pick('targetSchoolId') === '' ? LoginSession.schoolId : pick('targetSchoolId');
    this.loadUser();
    this.loadRecentPics();
    this.loadRelationship();
  }

  /** 源码 V.c()：目标资料（校内 getUserInfo，实测 code=0） */
  private async loadUser(): Promise<void> {
    if (this.targetId === '') {
      this.errMsg = '缺少用户参数';
      this.pageState = 2;
      return;
    }
    this.pageState = 0;
    const result = await ApiService.getTargetUserInfo(this.targetSchoolId, this.targetId, this.targetType);
    if (result.code !== 0) {
      this.errMsg = result.message;
      this.pageState = 2;
      return;
    }
    this.user = SocialUserInfo.fromRecord(ApiService.asRecord(result.data));
    this.pageState = 1;
  }

  /** 源码 V.b()：最近图片 getCircleRecentlyPic @ push 域（不可达 → 隐藏） */
  private loadRecentPics(): void {
    ApiService.pushGetCircleRecentPics(this.targetId, this.targetType, this.targetSchoolId)
      .then((response: ApiResponse<Object>) => {
        if (response.code !== 0) {
          return;
        }
        const raw: Object[] = Array.isArray(response.data) ? response.data as Object[] : [];
        const pics: string[] = [];
        for (const one of raw) {
          const pic: string = typeof one === 'string' ? one as string : '';
          if (pic !== '') {
            pics.push(pic);
          }
        }
        this.recentPics = pics.slice(0, 3);
      })
      .catch((error: BusinessError) => ApiService.logError('recent pics: ' + error.message));
  }

  /** 源码 W.d()：关注关系（push 域不可达 → 源码 setRelationship(null) 静默保持默认态） */
  private loadRelationship(): void {
    ApiService.pushGetRelationship(this.targetId, this.targetType, this.targetSchoolId)
      .then((response: ApiResponse<Object>) => {
        if (response.code !== 0) {
          return;
        }
        const rec: Record<string, Object> = ApiService.asRecord(response.data);
        const status: string = ApiService.pick(rec, ['status']);
        if (status === '1' || status === '3') {
          this.followStatus = status;
        }
      })
      .catch((error: BusinessError) => ApiService.logError('relationship: ' + error.message));
  }

  /** 源码 i3/b()：关注 addFriend（push 域 → 真实失败 toast network_or_service_error；
   *  成功 toast"关注成功"后 W.d() 重拉关系） */
  private follow(): void {
    ApiService.pushAddFriend(this.targetId, this.targetType, this.targetSchoolId, '')
      .then((response: ApiResponse<Object>) => {
        if (response.code === 0) {
          promptAction.showToast({ message: '关注成功' });
          this.loadRelationship();
        } else {
          promptAction.showToast({ message: '连接不到网络，请稍后再试' });
        }
      })
      .catch((error: BusinessError) => promptAction.showToast({ message: '连接不到网络，请稍后再试' }));
  }

  /** 源码 k3/a()：取关确认 deleteFriend（成功 W.d() 重拉关系，失败 toast network_or_service_error） */
  private unfollowConfirm(): void {
    AlertDialog.show({
      message: '是否确定不再关注该人',
      primaryButton: { value: '取消', action: (): void => { } },
      secondaryButton: {
        value: '确定',
        action: (): void => {
          ApiService.pushDeleteFriend(this.targetId, this.targetType, this.targetSchoolId)
            .then((response: ApiResponse<Object>) => {
              if (response.code === 0) {
                this.loadRelationship();
              } else {
                promptAction.showToast({ message: '连接不到网络，请稍后再试' });
              }
            })
            .catch((error: BusinessError) => promptAction.showToast({ message: '连接不到网络，请稍后再试' }));
        }
      }
    });
  }

  /** 源码 b/f3()：帖子列表入口 */
  private goPosts(): void {
    router.pushUrl({
      url: 'pages/MyPostPage',
      params: {
        'user_id': this.targetId,
        'user_name': this.user === null ? '' : (this.user as SocialUserInfo).userName,
        'user_type': this.targetType,
        'school_id': this.targetSchoolId
      }
    });
  }

  private avatarSrc(): ResourceStr {
    if (this.user !== null && (this.user as SocialUserInfo).avatar !== '') {
      const a: string = (this.user as SocialUserInfo).avatar;
      return a.startsWith('http') ? a : Constants.SOCKET_HOST + '/' + a;
    }
    return $r('app.media.default_avatar');
  }

  /** 源码 my_user_detail_add 按钮：关注/已关注/互相关注三态 */
  @Builder
  followButton() {
    Row() {
      Text(this.followStatus === '3' ? '互相关注' : this.followStatus === '1' ? '已关注' : '关注')
        .fontSize(14)
        .fontColor(Color.White)
        .backgroundColor($r('app.color.common_color_12'))
        .borderRadius(14)
        .padding({ left: 18, right: 18, top: 6, bottom: 6 })
        .onClick(() => {
          if (this.followStatus === '0') {
            this.follow();
          } else {
            this.unfollowConfirm();
          }
        })
    }
    .width('100%')
    .justifyContent(FlexAlign.Center)
    .margin({ top: 12 })
  }

  /** 源码 资料行（学院/专业/班级，空隐藏） */
  @Builder
  infoRow(label: string, value: string) {
    Row() {
      Text(label)
        .fontSize(14)
        .fontColor($r('app.color.common_color_3'))
        .width(60)
      Text(value)
        .fontSize(14)
        .fontColor($r('app.color.common_color_1'))
        .layoutWeight(1)
    }
    .width('100%')
    .margin({ top: 8 })
  }

  /** 源码 my_user_detail 头部：背景头像 + 居中头像 + 姓名+性别 + 真实姓名 */
  @Builder
  profileHead(u: SocialUserInfo) {
    Stack({ alignContent: Alignment.TopStart }) {
      Column()
        .width('100%')
        .height(180)
        .backgroundColor($r('app.color.common_color_12'))
        .opacity(0.5)
      Column() {
        Blank()
          .height(30)
        Image(this.avatarSrc())
          .width(72)
          .height(72)
          .borderRadius(36)
          .objectFit(ImageFit.Cover)
        Row({ space: 4 }) {
          Text(u.displayName())
            .fontSize(17)
            .fontColor(Color.White)
            .fontWeight(FontWeight.Bold)
          Text(u.sex === '男' ? '♂' : u.sex === '女' ? '♀' : '')
            .fontSize(15)
            .fontColor(u.sex === '男' ? '#6ec6ff' : '#ff9db3')
            .visibility(u.sex === '男' || u.sex === '女' ? Visibility.Visible : Visibility.None)
        }
        .margin({ top: 8 })
        Text(u.userName)
          .fontSize(13)
          .fontColor(Color.White)
          .opacity(0.9)
          .visibility(u.userName === '' ? Visibility.None : Visibility.Visible)
          .margin({ top: 2 })
      }
      .width('100%')
      .alignItems(HorizontalAlign.Center)
    }
    .width('100%')
    .height(180)
  }

  build() {
    Column() {
      TitleBar({
        title: '',
        showBack: true,
        onBack: (): void => {
          router.back();
        }
      })
      if (this.pageState === 0) {
        LoadingView()
          .layoutWeight(1)
      } else if (this.pageState === 2) {
        Column({ space: 12 }) {
          Text('ⓘ')
            .fontSize(44)
            .fontColor($r('app.color.common_color_4'))
          Text(this.errMsg === '' ? '加载失败' : this.errMsg)
            .fontSize(14)
            .fontColor($r('app.color.common_color_3'))
            .textAlign(TextAlign.Center)
            .padding({ left: 30, right: 30 })
          Text('重试')
            .fontSize(14)
            .fontColor($r('app.color.common_color_12'))
            .onClick(() => {
              this.loadUser();
            })
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else if (this.user !== null) {
        Scroll() {
          Column() {
            this.profileHead(this.user as SocialUserInfo)
            Column() {
              this.infoRow('学院', (this.user as SocialUserInfo).department)
              this.infoRow('专业', (this.user as SocialUserInfo).professionName)
              this.infoRow('班级', (this.user as SocialUserInfo).className)
              this.followButton()
              Row() {
                Text('TA的帖子')
                  .fontSize(14)
                  .fontColor($r('app.color.common_color_1'))
                Blank()
                Text('›')
                  .fontSize(16)
                  .fontColor($r('app.color.common_color_3'))
              }
              .width('100%')
              .height(44)
              .padding({ left: 15, right: 15 })
              .margin({ top: 14 })
              .backgroundColor($r('app.color.white'))
              .onClick(() => {
                this.goPosts();
              })
            }
            .width('100%')
            .padding(15)
          }
          .width('100%')
        }
        .width('100%')
        .layoutWeight(1)
        .scrollBar(BarState.Off)
        .backgroundColor($r('app.color.main_bg'))
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.main_bg'))
  }
}
