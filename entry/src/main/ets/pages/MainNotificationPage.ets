import { router } from '@kit.ArkUI';
import { BusinessError } from '@kit.BasicServicesKit';
import { promptAction } from '@kit.ArkUI';
import { ApiService } from '../network/ApiService';
import { ApiResponse } from '../model/ResponseModel';
import { MainNotificationV2, MessageExtAppBean, MessageSystemSwitch } from '../model/MessageModel';
import { TitleBar } from '../components/TitleBar';
import { LoadingView } from '../components/LoadingView';

/**
 * 消息列表页（主页通知）— 1:1 翻译 MainNotificationV2Activity.java（main/view，路由
 * /main/notification_new = strings mobile_campus_router_main_notification，layout
 * mobile_campus_activity_main_notification_new.xml）。
 *
 * 【入口实况（源码级核查 2026-11-18）】APK 中跳 A0 的只有三处：
 *   1. WMHFragment cbMsn（fragment_wmh 顶部 RelativeLayout android:visibility="gone" 内，实际不可见）；
 *   2. MainActivity.onNewIntent("switchToApp") 推送深链 → MainFragmentV3.h2()；
 *   3. 旧版 MainFragment（SDMU 主页实际用 MainFragmentV3 页签，不启用）的通知卡"更多"。
 *   → 真实 APK 学生端该页无可点入口，HAP 保持路由可达（main_pages.json 已注册），不伪造主页入口。
 * 【数据流】h.d.i → MessageModel.W0：POST getDateMessage {page}（无 stateCode！15行/页，实测 code=0）。
 *   f1 初始 r=1；成功 a3/g 后 r++（J2）；上拉 d.b()=Y2 取下一页 W2 追加；空页 setPullUpToLoadEnable(false)。
 *   下拉 d.a() 为空实现且 m.setEnabled(false) → 无下拉刷新。
 * 【状态】a.b 有数据→v 内容态 / q2 空态（EMPTY_NOTICE=插图 mobile_campus_page_notice，strings empty=""）；
 *   a.e 且 r==1 → u2 错误态；a.f → toast m(str2)。
 * 【条目】MainMessageNewAdapter + item_view_notification_new.xml：标题 17fp + 未读红点(shape_message_badge
 *   8dip holo_red_light，!isAllRead && STATE=='1')、brief=SENDTIME 空隐藏否则"发布日期："+SENDTIME、
 *   右箭头、checkbox 恒隐（canSelect 未启用）。
 * 【点击】先 b3 标记已读 updateState {xlh, isEmc?}（STATE 1→2）；isEmc==1 → C0 详情(无CONTENT，详情页拉
 *   EmcMessageContent)；EXT 无 LX → C0 详情(带 CONTENT/SENDBY)；EXT 有 LX → app util a.f LX 分流
 *   （16→详情 2/4/6/8/15→H5 5→请先安装应用 1/7→无原生路由 toast）。
 * 【长按】isEmc!=1 → 确认弹窗"是否删除该消息？"→ delete {xlh, isEmc?} → 移除行。
 * 【全部已读】toolbar 右键 toolBar_text_but，SystemSwitch.all_messages_read=="1" 才显示（HAP 未持久化
 *   → MessageSystemSwitch.current()==null 分支隐藏，链路保留）；点击确认"确定将所有消息状态置为已读吗？"
 *   → allUpdateState → 响应 "1" → setAllRead(true) 全部红点消失。
 */

/** C0 路由参数（EmcMessageDetailActivity.y(Intent) bundle，EmcMessageDetailPage 同键） */
interface NotificationNavParams {
  channelCode: string;
  xlh: string;
  title: string;
  sendTime: string;
  content: string;
  sendBy: string;
}

/** WebViewPage 路由参数（EXT LX=2/4/6/8/15 H5 分流） */
interface NotificationWebParams {
  url: string;
  title: string;
}

@Entry
@Component
struct MainNotificationPage {
  @State rows: MainNotificationV2[] = [];
  /** MultiStateView：loading / content / empty / error */
  @State viewState: string = 'loading';
  /** RefreshFragment.g 分页号（f1 初值 1，成功后 J2 自增） */
  @State page: number = 1;
  /** PullToRefreshLayout pullUpToLoadEnable（空页置 false） */
  @State canLoadMore: boolean = true;
  @State loadingMore: boolean = false;
  /** MainMessageNewAdapter.isAllRead：全部已读成功后红点全隐 */
  @State allRead: boolean = false;
  /** R2 开关 all_messages_read（systemSwitch==null → '' → 按钮隐藏） */
  @State swAllRead: string = '';

  aboutToAppear(): void {
    const sw: MessageSystemSwitch | null = MessageSystemSwitch.current();
    this.swAllRead = sw === null ? '' : sw.allMessagesRead;
    this.loadData(false);
  }

  /** 源码 Y2()：h.d.i(page) → getDateMessage {page}；isLoadMore=false → a3 替换 */
  private loadData(isLoadMore: boolean): void {
    if (isLoadMore) {
      this.loadingMore = true;
    }
    ApiService.getNotificationList(this.page)
      .then((response: ApiResponse<MainNotificationV2[]>) => {
        this.loadingMore = false;
        if (response.code === 1000) {
          return;
        }
        if (response.code !== 0) {
          ApiService.logError('Notification list fail: ' + response.message);
          if (!isLoadMore) {
            this.viewState = 'error';
          } else {
            promptAction.showToast({ message: response.message });
          }
          return;
        }
        const list: MainNotificationV2[] = response.data;
        // 源码 a.g()：r==1 → a3(替换)；空列表 → 空态；否则追加 W2
        if (isLoadMore) {
          this.rows = this.rows.concat(list);
        } else {
          this.rows = list;
        }
        if (list.length === 0) {
          this.canLoadMore = false;
        } else {
          this.page = this.page + 1;
          this.canLoadMore = true;
        }
        this.viewState = this.rows.length > 0 ? 'content' : 'empty';
      })
      .catch((error: BusinessError) => {
        this.loadingMore = false;
        ApiService.logError('Notification list fail: ' + error.message);
        // 源码 a.e()：r==1（首屏）→ u2 错误态
        if (!isLoadMore && this.page === 1) {
          this.viewState = 'error';
        }
      });
  }

  /** 源码 b3()：h.d.p → updateState {xlh, isEmc?}；回调 b()=onFinished（成功/失败均触发）STATE '1'→'2' */
  private markRead(item: MainNotificationV2): void {
    ApiService.updateNotificationState(item.XLH, item.isEmc)
      .then((_response: ApiResponse<Object>) => {
        if (item.STATE === '1') {
          item.STATE = '2';
        }
      })
      .catch((_error: BusinessError) => {
        // 源码 onFinished 同样在异常后触发 b()：完成即置已读
        if (item.STATE === '1') {
          item.STATE = '2';
        }
      });
  }

  /** 源码 b.onItemClick：标记已读 → isEmc/EXT 分流 */
  private onItemTap(item: MainNotificationV2): void {
    this.markRead(item);
    if (item.isEmc === 1) {
      this.openDetail(item, false);
      return;
    }
    const ext: MessageExtAppBean | null = item.EXT;
    if (ext === null || ext.LX === '') {
      this.openDetail(item, true);
      return;
    }
    this.jumpByLx(ext);
  }

  /** 源码 Z2()：bundle{channelCode,xlh,title,SENDTIME(+CONTENT/SENDBY when z)} → e.a.C0 详情 */
  private openDetail(item: MainNotificationV2, withContent: boolean): void {
    const params: NotificationNavParams = {
      channelCode: item.channelCode,
      xlh: item.XLH,
      title: item.TITLE,
      sendTime: item.SENDTIME,
      content: withContent ? item.CONTENT : '',
      sendBy: withContent ? item.SENDBY : ''
    };
    router.pushUrl({ url: 'pages/EmcMessageDetailPage', params: params });
  }

  /** 源码 app util a.f：EXT LX 分流（与 MessageListPage.jumpByLx 同链；EXT 直用不注入 xx 字段） */
  private jumpByLx(ext: MessageExtAppBean): void {
    if (ext.LX === '16') {
      const params: NotificationNavParams = {
        channelCode: '',
        xlh: '',
        title: ext.xxTitle,
        sendTime: ext.xxTime,
        content: ext.xxContent,
        sendBy: ext.xxSender
      };
      router.pushUrl({ url: 'pages/EmcMessageDetailPage', params: params });
      return;
    }
    if (ext.LX === '2' || ext.LX === '4' || ext.LX === '6' || ext.LX === '8' || ext.LX === '15') {
      const params: NotificationWebParams = { url: ext.URL, title: ext.YYMC };
      router.pushUrl({ url: 'pages/WebViewPage', params: params });
      return;
    }
    if (ext.LX === '5') {
      promptAction.showToast({ message: '请先安装应用' });
      return;
    }
    // LX 1/7：原生路由/小程序 → HAP 无 AppRouter，等价 ActivityNotFound 分支
    promptAction.showToast({ message: '程序猿正在加班加点赶功能' });
  }

  /** 源码 c.onItemLongClick（isEmc!=1）→ 确认弹窗 → X2 → delete {xlh, isEmc?} → f.g 移除行 */
  private onItemLongPress(item: MainNotificationV2, pos: number): void {
    if (item.isEmc === 1) {
      return;
    }
    promptAction.showDialog({
      title: '删除',
      message: '是否删除该消息？',
      buttons: [{ text: '取消', color: '#333333' }, { text: '删除', color: '#333333' }]
    }).then((result: promptAction.ShowDialogSuccessResponse) => {
      const index: number = result.index;
      if (index !== 1) {
        return;
      }
      ApiService.deleteNotification(item.XLH, item.isEmc)
        .then((response: ApiResponse<Object>) => {
          if (response.code === 0) {
            const rest: MainNotificationV2[] = this.rows.slice();
            rest.splice(pos, 1);
            this.rows = rest;
            if (this.rows.length === 0) {
              this.viewState = 'empty';
            }
          } else {
            promptAction.showToast({ message: response.message });
          }
        })
        .catch((error: BusinessError) => {
          ApiService.logError('Notification delete fail: ' + error.message);
        });
    });
  }

  /** 源码 e.onClick（全部已读）→ 确认 → allUpdateState → "1" → setAllRead(true) */
  private onAllReadClick(): void {
    promptAction.showDialog({
      title: '',
      message: '确定将所有消息状态置为已读吗？',
      buttons: [{ text: '取消', color: '#333333' }, { text: '确定', color: '#333333' }]
    }).then((result: promptAction.ShowDialogSuccessResponse) => {
      const index: number = result.index;
      if (index !== 1) {
        return;
      }
      ApiService.allUpdateMessageState()
        .then((response: ApiResponse<Object>) => {
          const data = response.data;
          if (response.code === 0 && typeof data === 'string' && (data as string) === '1') {
            this.allRead = true;
          }
        })
        .catch((error: BusinessError) => {
          ApiService.logError('Notification allUpdateState fail: ' + error.message);
        });
    });
  }

  /**
   * mobile_campus_item_view_notification_new.xml + MainMessageNewAdapter.getView：
   * 白底 padL/T=px28/2=14vp，内容列再 + marginLeft12（checkbox gone 后 RelativeLayout 锚点塌缩，
   * 依赖项自身 margin 仍生效 → 有效左缩进 14+12=26vp）；标题行（标题 17fp + 未读红点 8dip
   * holo_red_light + compoundDrawablePadding y.a(8)=8dip）+ brief 14fp（SENDTIME 空隐藏）+
   * 右箭头 marginRight=px24/2=12；行容器 marginBottom=px24/2=12 → 底分隔线 common_color_6 1vp。
   */
  @Builder
  notificationItem(item: MainNotificationV2, pos: number) {
    Column() {
      Column() {
        Row() {
          Column() {
            Row() {
              if (!this.allRead && item.STATE === '1') {
                // mobile_campus_shape_message_badge：oval 8dip holo_red_light，drawablePadding 8dip
                Circle()
                  .width(8)
                  .height(8)
                  .fill('#FFFF4444')
                  .margin({ right: 8 })
              }
              Text(item.TITLE)
                .fontSize(17)
                .fontColor($r('app.color.common_color_1'))
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
                .layoutWeight(1)
            }
            .width('100%')
            .padding({ right: 12 })
            .margin({ bottom: 8 })
            .alignItems(VerticalAlign.Center)

            if (item.SENDTIME !== '') {
              Text('发布日期：' + item.SENDTIME)
                .fontSize(14)
                .fontColor($r('app.color.common_color_3'))
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
                .width('100%')
            }
          }
          .alignItems(HorizontalAlign.Start)
          .layoutWeight(1)

          Image($r('app.media.mobile_campus_main_message_arrow'))
            .width(16)
            .height(16)
            .margin({ right: 12 })
            .objectFit(ImageFit.Contain)
        }
        .width('100%')
        .margin({ bottom: 12 })
        .alignItems(VerticalAlign.Center)

        // item_main_notification_divider：common_color_6 高 px_to_dip_2=1vp
        Divider()
          .color($r('app.color.common_color_6'))
          .strokeWidth(1)
      }
      .width('100%')
      .backgroundColor($r('app.color.white'))
      .padding({ left: 26, top: 14 })
      .onClick(() => {
        this.onItemTap(item);
      })
      .gesture(LongPressGesture({ duration: 500 }).onAction(() => {
        this.onItemLongPress(item, pos);
      }))
    }
    .width('100%')
  }

  build() {
    Column() {
      TitleBar({ title: '消息', rightText: this.swAllRead === '1' ? '全部已读' : '',
        onRightClick: (): void => {
          this.onAllReadClick();
        } })
      // View：common_color_6 高 px_to_dip_16=8vp + px_to_dip_2=1vp
      Column()
        .width('100%')
        .height(8)
        .backgroundColor($r('app.color.common_color_6'))
      Column()
        .width('100%')
        .height(1)
        .backgroundColor($r('app.color.common_color_6'))

      Column() {
        if (this.viewState === 'loading') {
          LoadingView()
        } else if (this.viewState === 'empty') {
          // EMPTY_NOTICE：mobile_campus_page_notice 插图（strings empty=""，无文案）
          Image($r('app.media.mobile_campus_page_notice'))
            .width(160)
            .objectFit(ImageFit.Contain)
        } else if (this.viewState === 'error') {
          // error_view：mobile_campus_page_error + 重试（重试=重拉当前页）
          Column() {
            Image($r('app.media.mobile_campus_page_error'))
              .width(120)
              .objectFit(ImageFit.Contain)
            Text('重试')
              .fontSize(15)
              .fontColor($r('app.color.white'))
              .textAlign(TextAlign.Center)
              .padding({ left: 17, right: 17, top: 3, bottom: 3 })
              .backgroundColor($r('app.color.blue_default'))
              .margin({ top: 16 })
              .onClick(() => {
                this.viewState = 'loading';
                this.loadData(false);
              })
          }
          .width('100%')
          .height('100%')
          .justifyContent(FlexAlign.Center)
        } else {
          // common_refresh_lv_rl：ListView + 上拉加载（下拉已禁用）
          List({ space: 0 }) {
            ForEach(this.rows, (item: MainNotificationV2, pos: number) => {
              ListItem() {
                this.notificationItem(item, pos)
              }
            }, (item: MainNotificationV2, pos: number) => pos.toString() + '-' + item.XLH +
              '-' + item.STATE + '-' + this.allRead.toString())
            if (this.loadingMore && this.canLoadMore) {
              ListItem() {
                LoadingView()
              }
            }
          }
          .width('100%')
          .height('100%')
          .scrollBar(BarState.Off)
          .onReachEnd(() => {
            if (this.canLoadMore && !this.loadingMore) {
              this.loadData(true);
            }
          })
        }
      }
      .width('100%')
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.main_bg'))
  }
}
