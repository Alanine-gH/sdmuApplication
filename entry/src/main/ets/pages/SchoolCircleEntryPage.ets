import { router } from '@kit.ArkUI';
import { TitleBar } from '../components/TitleBar';
import { LoginSession } from '../network/LoginSession';
import { BreakpointSystem } from '../common/BreakpointSystem';

/**
 * 校圈入口页 — 1:1 复刻 social_main_activity.xml（SocialMainActivity）
 * 结构：LinearLayout(vertical) + toolbar_normal + FrameLayout(fl_container)
 * 容器内容为校圈社区空态（social_no_pager.xml）：
 *   - 社区空态插图 social_no_page.png、左右 margin 25vp(px50÷2)
 *   - 提示文案 12fp(px24÷2) common_color_4 居中、padding 30vp(px60÷2)
 * 【工具栏右键（SocialMainActivity.T1/T2 源码级）】T1: gVar.n("校圈") + m=gVar.k(social_more)；
 *   Y0: m.setOnClickListener(b) → T2 弹 PopupMenu(mobile_campus_social_menu)：
 *   我的帖子(post)/我的关注(follow)/我的粉丝(fans)/我的消息(iMessage)。
 *   我的帖子 → MyPostActivity{user_id,user_name,user_type,school_id}（本人四参，源码 Q2()）
 *     → pages/MyPostPage（W20 已翻译）；我的消息 iMessage → R2() → SocialMessageActivity
 *     = pages/SocialMessagePage（W12 已翻译）；我的关注/我的粉丝 → FriendshipUserListActivity
 *     {UserListType: FOLLOWING|FOLLOWER}（HAP 未翻译范围外，保留菜单项无跳转）。
 * 【浮动发布按钮（fragment_social.xml floatBtn，SocialFragmentEx.f → PostPublishActivity
 *   {post_type:"2"}）】→ pages/PostPublishPage{postType:"2"}（W20 已翻译）。
 */
@Entry
@Component
struct SchoolCircleEntryPage {
  @State emptyTips: string = '说点新鲜事儿分享给同学们吧~';
  /** SocialMainActivity.T2：PopupMenu 展开态 */
  @State showMenu: boolean = false;
  @StorageProp('currentBreakpoint') currentBreakpoint: string = 'sm';
  @StorageProp('windowWidthVp') windowWidthVp: number = 360;
  @StorageProp('windowHeightVp') windowHeightVp: number = 780;
  @StorageProp('avoidAreaBottomVp') avoidAreaBottomVp: number = 0;
  @StorageProp('avoidAreaLeftVp') avoidAreaLeftVp: number = 0;
  @StorageProp('avoidAreaRightVp') avoidAreaRightVp: number = 0;

  build() {
    Stack({ alignContent: Alignment.TopStart }) {
      Column() {
        TitleBar({ title: '校圈', showBack: true,
          rightIcon: $r('app.media.social_more'),
          onRightClick: (): void => {
            // SocialMainActivity.b → T2(view)：PopupMenu(mobile_campus_social_menu)
            this.showMenu = !this.showMenu;
          } })

        Stack({ alignContent: Alignment.BottomEnd }) {
          Scroll() {
            // social_no_pager 空态视图
            Column() {
              Image($r('app.media.social_no_page'))
                .margin({ left: 25, right: 25 })

              Text(this.emptyTips)
                .fontSize(12)
                .fontColor($r('app.color.common_color_4'))
                .textAlign(TextAlign.Center)
                .padding(30)
            }
            .width('100%')
            .constraintSize({ maxWidth: BreakpointSystem.getContentMaxWidth(this.currentBreakpoint) })
            .alignSelf(ItemAlign.Center)
            .padding({
              left: this.avoidAreaLeftVp,
              right: this.avoidAreaRightVp,
              bottom: this.avoidAreaBottomVp
            })
            .alignItems(HorizontalAlign.Center)
          }
          .width('100%')
          .height('100%')
          .scrollBar(BarState.Off)
          .align(Alignment.Top)

          // fragment_social.xml floatBtn：SocialFragmentEx.f → PostPublishActivity{post_type:"2"}
          Image($r('app.media.market_publish'))
            .width(48)
            .height(48)
            .margin({ right: 15 + this.avoidAreaRightVp, bottom: 20 + this.avoidAreaBottomVp })
            .onClick(() => {
              router.pushUrl({ url: 'pages/PostPublishPage', params: { 'postType': '2' } });
            })
        }
        .width('100%')
        .layoutWeight(1)
      }
      .width('100%')
      .height('100%')

      if (this.showMenu) {
        this.popupMenu()
      }
    }
    .width('100%')
    .height('100%')
  }

  /** mobile_campus_social_menu：post/follow/fans/iMessage 四项（白底列表，右上角锚定） */
  @Builder
  popupMenu() {
    Stack({ alignContent: Alignment.TopEnd }) {
      // 遮罩（点击收起，同 PopupMenu dismiss）
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor('#66000000')
        .onClick(() => {
          this.showMenu = false;
        })
      Scroll() {
        Column() {
          Text('我的帖子')
            .fontSize(15)
            .fontColor($r('app.color.common_color_1'))
            .padding({ left: 16, right: 24, top: 12, bottom: 12 })
            .width('100%')
            .hoverEffect(HoverEffect.Highlight)
            .onClick(() => {
              // SocialMainActivity T2 post → MyPostActivity{user_id,user_name,user_type,school_id}
              this.showMenu = false;
              router.pushUrl({
                url: 'pages/MyPostPage',
                params: {
                  'user_id': LoginSession.userId,
                  'user_name': '',
                  'user_type': LoginSession.userType,
                  'school_id': LoginSession.schoolId
                }
              });
            })
          Divider()
            .color($r('app.color.common_color_6'))
            .strokeWidth(0.5)
          Text('我的关注')
            .fontSize(15)
            .fontColor($r('app.color.common_color_1'))
            .padding({ left: 16, right: 24, top: 12, bottom: 12 })
            .width('100%')
            .hoverEffect(HoverEffect.Highlight)
            .onClick(() => {
              this.showMenu = false;
              router.pushUrl({ url: 'pages/FriendUserListPage', params: { 'UserListType': 'FOLLOWING' } });
            })
          Divider()
            .color($r('app.color.common_color_6'))
            .strokeWidth(0.5)
          Text('我的粉丝')
            .fontSize(15)
            .fontColor($r('app.color.common_color_1'))
            .padding({ left: 16, right: 24, top: 12, bottom: 12 })
            .width('100%')
            .hoverEffect(HoverEffect.Highlight)
            .onClick(() => {
              this.showMenu = false;
              router.pushUrl({ url: 'pages/FriendUserListPage', params: { 'UserListType': 'FOLLOWER' } });
            })
          Divider()
            .color($r('app.color.common_color_6'))
            .strokeWidth(0.5)
          Text('我的消息')
            .fontSize(15)
            .fontColor($r('app.color.common_color_1'))
            .padding({ left: 16, right: 24, top: 12, bottom: 12 })
            .width('100%')
            .hoverEffect(HoverEffect.Highlight)
            .onClick(() => {
              // SocialMainActivity.c.iMessage → R2() → X1(SocialMessageActivity)
              this.showMenu = false;
              router.pushUrl({ url: 'pages/SocialMessagePage' });
            })
        }
        .width('100%')
      }
      .scrollBar(BarState.Off)
      .backgroundColor($r('app.color.white'))
      .borderRadius(4)
      .width(Math.min(160, BreakpointSystem.getDialogMaxWidth(this.currentBreakpoint, this.windowWidthVp)))
      .constraintSize({ maxHeight: BreakpointSystem.getDialogMaxHeight(this.windowHeightVp) })
      .margin({ top: 45, right: Math.max(8, this.avoidAreaRightVp + 8) })
      .onClick(() => {
        // 拦截菜单点击
      })
    }
    .width('100%')
    .height('100%')
  }
}
