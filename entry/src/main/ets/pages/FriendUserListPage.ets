import { router, promptAction } from '@kit.ArkUI';
import { BusinessError } from '@kit.BasicServicesKit';
import { TitleBar } from '../components/TitleBar';
import { LoadingView } from '../components/LoadingView';
import { ApiService, BizJsonResult } from '../network/ApiService';

/**
 * 好友/关注列表页 — 源码级翻译 FriendshipUserListActivity（[P-B placeholder]）：
 * 【入口】SocialTab "好友"（无参→UserListType.FOLLOWING）/ 校圈菜单"我的关注"(FOLLOWING)
 *   "我的粉丝"(FOLLOWER) → params.UserListType。
 * 【源码 f1()】s=getIntent().getSerializableExtra("UserListType")；
 *   hasSchoolCirclePhone=false（探针实测登录响应无此字段→false）时直接
 *   t(o, EMPTY_FOLLOW)="你还没有关注别人哦"(empty_attentioin) /
 *   t(o, EMPTY_FAN)="你还有没有粉丝哦"(empty_fans)，不发首屏请求。
 * 【下拉 a.a()/上拉 a.b()】重置 t=1 / K2()+setHasNoMoreData(false) 后 R2()：
 *   FOLLOWING→FriendPresenter.c→LIANYI getMyFollows；FOLLOWER→.b→LIANYI getMyFans
 *   {pageNum,pageSize:"10"}；push 域实测 SSL EOF 不可达 → 真实错误态（q0/R 回调 null→m toast）。
 * 【行项】social_friendship_user_item：头像50vp(default_circle 兜底)+教师角标(userType=="2")+
 *   性别(boy/girl,男/女)+昵称(小奕的粉丝→空回退 userName)+部门；关注态图：
 *   BOTH_FOLLOWING→互相关注(可点取消)、FOLLOWING 列表且非互关→隐藏、FOLLOWER 列表→添加(可点关注)。
 * 【点击】→UserDetailActivity{targetId,targetSchoolId,targetUserType,position(10001)}（HAP 对应页）。
 */
interface FriendRow {
  userId: string;
  schoolId: string;
  userType: string;
  avatar: string;
  noteName: string;
  nickName: string;
  department: string;
  sex: string;
  status: string; // FOLLOWING / FOLLOWED / BOTH_FOLLOWING
}

@Entry
@Component
struct FriendUserListPage {
  @State following: boolean = true;
  @State rows: FriendRow[] = [];
  @State viewState: string = 'empty'; // loading / content / empty / error
  @State refreshing: boolean = false;
  private page: number = 1;

  aboutToAppear(): void {
    const params: Record<string, Object> = (router.getParams() ?? {}) as Record<string, Object>;
    const t: Object | undefined = params['UserListType'];
    this.following = !(typeof t === 'string' && t as string === 'FOLLOWER');
    // 源码 f1()：hasSchoolCirclePhone=false → 直接空态，不发首屏请求
    this.viewState = 'empty';
  }

  /** 源码 R2()：下拉/上拉触发真实列表请求（push 域不可达 → 真实错误态） */
  private load(isRefresh: boolean): void {
    if (isRefresh) {
      this.page = 1;
    }
    this.refreshing = true;
    this.viewState = 'loading';
    ApiService.pushGetFriendList(this.following, this.page)
      .then((result: BizJsonResult) => {
        this.refreshing = false;
        if (result.code !== 0) {
          this.viewState = 'error';
          promptAction.showToast({ message: result.message === '' ? '连接不到网络，请稍后再试' : result.message });
          return;
        }
        const rows: FriendRow[] = this.parseRows(result.data);
        if (isRefresh) {
          this.rows = rows;
        } else {
          this.rows = this.rows.concat(rows);
        }
        this.viewState = this.rows.length > 0 ? 'content' : 'empty';
        if (rows.length > 0) {
          this.page = this.page + 1;
        }
      })
      .catch((error: BusinessError) => {
        this.refreshing = false;
        this.viewState = 'error';
        ApiService.logError('friend list fail: ' + error.message);
        promptAction.showToast({ message: '连接不到网络，请稍后再试' });
      });
  }

  /** FriendPresenter.g() 逐字段解析：noteName/sex/nickName/userName/department/userId/schoolId/
   *  userType/avatar，mutuallyFollw=="1"→BOTH_FOLLOWING，否则 FOLLOWING/FOLLOWED */
  private parseRows(data: Object): FriendRow[] {
    const out: FriendRow[] = [];
    const raw: Object[] = ApiService.extractArray(data);
    for (const one of raw) {
      const rec: Record<string, Object> = ApiService.asRecord(one);
      const row: FriendRow = {
        userId: ApiService.pick(rec, ['userId']),
        schoolId: ApiService.pick(rec, ['schoolId']),
        userType: ApiService.pick(rec, ['userType']),
        avatar: ApiService.pick(rec, ['avatar']),
        noteName: ApiService.pick(rec, ['noteName']),
        nickName: ApiService.pick(rec, ['nickName', 'userName']),
        department: ApiService.pick(rec, ['department']),
        sex: ApiService.pick(rec, ['sex']),
        status: (ApiService.pick(rec, ['mutuallyFollw']) === '1' || ApiService.pick(rec, ['mutuallyFollw']) === 'true')
          ? 'BOTH_FOLLOWING' : (this.following ? 'FOLLOWING' : 'FOLLOWED')
      };
      out.push(row);
    }
    return out;
  }

  /** 源码 adapter.convert：noteName 优先，空/小奕的粉丝→nickName(FOLLOWER 分支为 userName) */
  private displayName(row: FriendRow): string {
    let name: string = row.noteName;
    if (name === '' || name === '小奕的粉丝') {
      name = row.nickName;
    }
    return name === '小奕的粉丝' ? '' : name;
  }

  private onItemTap(row: FriendRow): void {
    if (row.userId === '') {
      // 源码 R$string.no_user="该用户未登录过，暂时无法联系"
      promptAction.showToast({ message: '该用户未登录过，暂时无法联系' });
      return;
    }
    router.pushUrl({
      url: 'pages/UserDetailPage',
      params: { 'targetId': row.userId, 'targetSchoolId': row.schoolId, 'targetUserType': row.userType }
    });
  }

  @Builder
  friendItem(row: FriendRow) {
    Row() {
      Image(row.avatar === '' ? $r('app.media.default_circle') : row.avatar)
        .width(50).height(50).borderRadius(25).objectFit(ImageFit.Cover)
      Column() {
        Row() {
          Text(this.displayName(row))
            .fontSize(16).fontColor($r('app.color.common_color_1'))
            .maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
          if (row.sex === '男' || row.sex === '女') {
            Text(row.sex === '男' ? '♂' : '♀')
              .fontSize(14).fontColor(row.sex === '男' ? '#3A7BFF' : '#FF5F5F')
              .margin({ left: 6 })
          }
          if (row.userType === '2') {
            Image($r('app.media.teacher_icon')).width(14).height(14).margin({ left: 4 })
          }
        }
        Text(row.department)
          .fontSize(13).fontColor($r('app.color.common_color_3'))
          .margin({ top: 4 }).maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .alignItems(HorizontalAlign.Start).layoutWeight(1).margin({ left: 12 })
      if (row.status === 'BOTH_FOLLOWING') {
        Text('互相关注').fontSize(12).fontColor($r('app.color.common_color_3'))
          .padding({ left: 8, right: 8, top: 4, bottom: 4 })
          .borderRadius(3).backgroundColor($r('app.color.common_color_5'))
      } else if (!this.following) {
        Text('+ 关注').fontSize(12).fontColor($r('app.color.white'))
          .padding({ left: 8, right: 8, top: 4, bottom: 4 })
          .borderRadius(3).backgroundColor($r('app.color.sdmu_primary'))
      }
    }
    .width('100%')
    .padding({ left: 15, right: 15, top: 12, bottom: 12 })
    .backgroundColor($r('app.color.white'))
    .onClick(() => { this.onItemTap(row); })
  }

  build() {
    Column() {
      TitleBar({ title: this.following ? '我关注的' : '关注我的', showBack: true })
      Stack() {
        if (this.viewState === 'loading') {
          LoadingView()
        } else if (this.viewState === 'empty') {
          Column() {
            Image(this.following ? $r('app.media.empty_attentioin') : $r('app.media.empty_fans'))
              .width(160).objectFit(ImageFit.Contain)
            Text(this.following ? '你还没有关注别人哦' : '你还有没有粉丝哦')
              .fontSize(14).fontColor($r('app.color.sdmu_text_hint')).margin({ top: 16 })
          }
          .width('100%').height('100%').justifyContent(FlexAlign.Center)
        } else if (this.viewState === 'error') {
          Column() {
            Image($r('app.media.mobile_campus_page_internet')).width(120).objectFit(ImageFit.Contain)
            Text('网络好像有点问题，过一会再试吧')
              .fontSize(14).fontColor($r('app.color.sdmu_text_hint')).margin({ top: 16 })
            Text('重试').fontSize(15).fontColor($r('app.color.white'))
              .padding({ left: 17, right: 17, top: 4, bottom: 4 })
              .backgroundColor($r('app.color.blue_default')).margin({ top: 16 })
              .onClick(() => { this.load(true); })
          }
          .width('100%').height('100%').justifyContent(FlexAlign.Center)
        } else {
          List() {
            ForEach(this.rows, (row: FriendRow) => { ListItem() { this.friendItem(row); } },
              (row: FriendRow) => row.userId)
          }
          .width('100%').height('100%')
          .onReachEnd(() => { if (!this.refreshing) { this.load(false); } })
        }
      }
      .width('100%').layoutWeight(1)
    }
    .width('100%').height('100%')
    .backgroundColor($r('app.color.main_bg'))
  }
}
