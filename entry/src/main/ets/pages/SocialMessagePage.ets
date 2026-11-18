import { BusinessError } from '@kit.BasicServicesKit';
import { router } from '@kit.ArkUI';
import { ApiService } from '../network/ApiService';
import { ApiResponse } from '../model/ResponseModel';
import { SocialPushMessageItem, SocialPushUserTx } from '../model/MessageModel';
import { TitleBar } from '../components/TitleBar';
import { LoadingView } from '../components/LoadingView';

/**
 * 校圈消息页 — 1:1 翻译 SocialMessageActivity.java（lyyd/social/social/view，layout
 * common_refresh_lv_rl_toolbar，toolbar 标题"消息"）。
 *
 * 【数据流】MsgPresenter.b("circle", page, 20) → PushModel.l：POST
 *   https://www.yibaogao.com/mobileapi/campus/push/getPushMsgList {type:"circle",page,pageSize:"20"}
 *   + 请求头 xxdm=登录会话 schoolId（f13170c=请求头 map，源码实证）；响应 G(MessageList)。
 *   2026-11-18 探针实测：该域名校园网不可达（https SSL UNEXPECTED_EOF / http 502）→ HAP 落
 *   源码同款错误态（G(null)→t0(ERROR)），重试重拉；绝不编造数据。
 * 【条目】SocialMessageAdapter + message_social_item.xml：头像40（default 兜底）+ 昵称14fp
 *   + 时间12fp#999（readStatus=='0' 且时间非空 → 左侧 msg_red_point 8dip 红点）+ 类型14fp#767676
 *   （ext.type 0=关注了你/1=赞了你/2=评论了/其他=回复了你；2/其他且 pl_content 非空显示正文15fp）
 *   + 头像补链 a.f：picture 空且 userId 非空 → getAvatarByUser {userIds} 批量取 TX。
 * 【时间】baselibrary util e.d：今天=秒前/分钟前/1小时前/HH:mm，昨天=昨天HH:mm，其余=MM-dd HH:mm。
 * 【点击】T2 标记已读 hasRead {id, type:"circle"}（成功 readStatus='1'）；contentType 分流：
 *   circleActive → circle_type=='1' ? pages/MarkDetailPage{id,targetUserId}（W20 已翻译）
 *   : pages/PostDetailPage{id,targetUserId,type:3}（W20 已翻译）；circleFocus →
 *   FriendshipUserListActivity（HAP 未翻译范围外，保留无跳转）。
 * 【分页】下拉 a.a() u=1 重拉；上拉 a.b() u++ 追加；空页 setHasNoMoreData(true)。
 */

@Entry
@Component
struct SocialMessagePage {
  @State rows: SocialPushMessageItem[] = [];
  /** MultiStateView：loading / content / empty / error（G(null)→ERROR，空→EMPTY_MESSAGE） */
  @State viewState: string = 'loading';
  /** 源码 u=1/v=20：页码与每页条数 */
  @State page: number = 1;
  private readonly pageSize: number = 20;
  @State canLoadMore: boolean = true;
  @State loadingMore: boolean = false;
  /** SocialUserAvatarUtil 头像缓存 map<userId, TX> */
  private avatarMap: Map<string, string> = new Map();

  aboutToAppear(): void {
    this.loadData(false);
  }

  /** 源码 a.a()/a.b()：u=1 重拉 / u++ 追加 → b("circle", u, v) */
  private loadData(isLoadMore: boolean): void {
    if (isLoadMore) {
      this.loadingMore = true;
    } else {
      this.page = 1;
    }
    ApiService.getPushMsgList('circle', this.page, this.pageSize)
      .then((response: ApiResponse<Object>) => {
        this.loadingMore = false;
        if (response.code !== 0) {
          // 源码 MsgPresenter.a.f → G(null) → t0(ERROR)
          ApiService.logError('Social push list fail: ' + response.message);
          if (!isLoadMore) {
            this.viewState = 'error';
          }
          return;
        }
        const list: SocialPushMessageItem[] = this.parseItems(response.data);
        if (!isLoadMore) {
          this.rows = list;
        } else {
          this.rows = this.rows.concat(list);
        }
        // 源码 G()：list 空 → setHasNoMoreData(true)；否则 timestamp 留存（HAP 无后续用途）
        if (list.length === 0) {
          this.canLoadMore = false;
        } else {
          this.page = this.page + 1;
          this.canLoadMore = true;
          this.prefetchAvatars();
        }
        this.viewState = this.rows.length > 0 ? 'content' : 'empty';
      })
      .catch((error: BusinessError) => {
        this.loadingMore = false;
        ApiService.logError('Social push list fail: ' + error.message);
        if (!isLoadMore) {
          this.viewState = 'error';
        }
      });
  }

  /** MessageList{list: MessageItem[]} → SocialPushMessageItem[]（bizJson 已解密为对象） */
  private parseItems(data: Object): SocialPushMessageItem[] {
    const out: SocialPushMessageItem[] = [];
    if (data === null || data === undefined) {
      return out;
    }
    let raw: Object[] = [];
    if (Array.isArray(data)) {
      raw = data as Object[];
    } else {
      const rec = data as Record<string, Object>;
      const listVal: Object = rec['list'];
      if (Array.isArray(listVal)) {
        raw = listVal as Object[];
      }
    }
    for (const one of raw) {
      out.push(SocialPushMessageItem.fromRecord(one as Record<string, Object>));
    }
    return out;
  }

  /** 源码 a.f(list, c)：picture 空且 userId 非空 → getAvatarByUser 批量取 TX 存 map */
  private prefetchAvatars(): void {
    const need: string[] = [];
    for (const row of this.rows) {
      const ext = row.ext;
      if (ext !== null && ext.picture === '' && ext.userId !== '' && !this.avatarMap.has(ext.userId)) {
        need.push(ext.userId);
        this.avatarMap.set(ext.userId, '');
      }
    }
    if (need.length === 0) {
      return;
    }
    ApiService.getSocialAvatars(need.join(','))
      .then((response: ApiResponse<Object>) => {
        if (response.code !== 0) {
          return;
        }
        const raw: Object[] = Array.isArray(response.data) ? response.data as Object[] : [];
        for (const one of raw) {
          const tx: SocialPushUserTx = SocialPushUserTx.fromRecord(one as Record<string, Object>);
          if (tx.USERID !== '') {
            this.avatarMap.set(tx.USERID, tx.TX);
          }
        }
        // 触发列表重渲染（头像 map 非状态，手动刷新数组引用）
        this.rows = this.rows.slice();
      })
      .catch((error: BusinessError) => {
        ApiService.logError('Social avatar fail: ' + error.message);
      });
  }

  /** 源码 a.b(picture, userId)：picture 非空用原值，否则查 TX map */
  private avatarOf(item: SocialPushMessageItem): string {
    const ext = item.ext;
    if (ext !== null && ext.picture !== '') {
      return ext.picture;
    }
    if (ext !== null && this.avatarMap.has(ext.userId)) {
      const cached: string | undefined = this.avatarMap.get(ext.userId);
      return cached === undefined ? '' : cached;
    }
    return '';
  }

  /** 源码 adapter.getView 类型文案映射 */
  private typeText(item: SocialPushMessageItem): string {
    const ext = item.ext;
    const t: string = ext === null ? '' : ext.type;
    if (t === '0') {
      return '关注了你';
    }
    if (t === '1') {
      return '赞了你';
    }
    if (t === '2') {
      return '评论了';
    }
    return '回复了你';
  }

  /** 源码 baselibrary util e.d(sendTime, "")：相对时间格式（今天/昨天/其余） */
  private formatTime(sendTime: string): string {
    if (sendTime === '') {
      return '';
    }
    try {
      const date: Date = new Date(sendTime.replace(/-/g, '/'));
      // 源码 SimpleDateFormat.parse 失败 → catch 返回 ""；JS NaN 同样回落空串
      if (Number.isNaN(date.getTime())) {
        return '';
      }
      const now: Date = new Date();
      if (now.getTime() < date.getTime()) {
        return '';
      }
      const sameDay: boolean = now.getFullYear() === date.getFullYear()
        && now.getMonth() === date.getMonth() && now.getDate() === date.getDate();
      const diffMin: number = Math.floor((now.getTime() - date.getTime()) / 60000);
      const pad = (n: number): string => {
        return n < 10 ? '0' + n.toString() : n.toString();
      };
      if (sameDay) {
        if (diffMin === 0) {
          return Math.floor(Math.abs(now.getTime() - date.getTime()) / 1000) + '秒前';
        }
        if (diffMin > 0 && diffMin <= 60) {
          return diffMin + '分钟前';
        }
        if (diffMin <= 120) {
          return '1小时前';
        }
        return pad(date.getHours()) + ':' + pad(date.getMinutes());
      }
      const yesterday: boolean = now.getFullYear() === date.getFullYear()
        && now.getMonth() === date.getMonth()
        && now.getDate() === date.getDate() + 1;
      if (yesterday) {
        return '昨天' + pad(date.getHours()) + ':' + pad(date.getMinutes());
      }
      return pad(date.getMonth() + 1) + '-' + pad(date.getDate()) + ' ' + pad(date.getHours()) + ':' +
        pad(date.getMinutes());
    } catch (error) {
      return '';
    }
  }

  /** 源码 T2()：p.c(item, "circle") → hasRead {id, type}；o0 成功 readStatus='1' */
  private markRead(item: SocialPushMessageItem): void {
    ApiService.pushHasRead(item.id, 'circle')
      .then((response: ApiResponse<Object>) => {
        if (response.code === 0) {
          item.readStatus = '1';
        }
      })
      .catch((error: BusinessError) => {
        ApiService.logError('Social push hasRead fail: ' + error.message);
      });
  }

  /** 源码 b.onItemClick：T2 标记已读 + contentType 分流。
   *  circleActive → ext.circle_type=='1' ? MarkDetailActivity{id,targetUserId}
   *    : PostDetailActivity{id,targetUserId,type:3} —— 两目标 W20 已翻译，补全真实跳转；
   *  circleFocus → FriendshipUserListActivity（HAP 未翻译范围外，保留无跳转）。 */
  private onItemTap(item: SocialPushMessageItem): void {
    this.markRead(item);
    const ext = item.ext;
    if (item.contentType !== 'circleActive' || ext === null) {
      return;
    }
    const params: Record<string, Object> = {
      'id': ext.circleId,
      'targetUserId': ext.userId,
      'type': 3
    };
    if (ext.circle_type === '1') {
      router.pushUrl({ url: 'pages/MarkDetailPage', params: params });
    } else {
      router.pushUrl({ url: 'pages/PostDetailPage', params: params });
    }
  }

  /**
   * message_social_item.xml + SocialMessageAdapter.getView：
   * main_bg 白底 pad L/R=px30/2=15vp T/B=px20/2=10vp；头像 40vp；昵称 14fp maxLength10；
   * 时间 12fp #999 右对齐（未读→左侧 8dip #FFFF0000 红点 padding 4）；类型 14fp #767676；
   * 正文 15fp #333 padT=px7/2≈3.5vp。
   */
  @Builder
  messageItem(item: SocialPushMessageItem) {
    Row() {
      Image(this.avatarOf(item) === '' ? $r('app.media.default_avatar') : this.avatarOf(item))
        .width(40)
        .height(40)
        .objectFit(ImageFit.Cover)
        .margin({ right: 15 })

      Column() {
        Row() {
          Text(this.nameOf(item))
            .fontSize(14)
            .fontColor($r('app.color.common_color_1'))
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .constraintSize({ maxWidth: 120 })
          Blank()
            .layoutWeight(1)
          if (item.readStatus === '0' && this.formatTime(item.sendTime) !== '') {
            // msg_red_point：oval 8dip #ffff0000，drawablePadding px8/2=4vp
            Circle()
              .width(8)
              .height(8)
              .fill('#FFFF0000')
              .margin({ right: 4 })
          }
          Text(this.formatTime(item.sendTime))
            .fontSize(12)
            .fontColor($r('app.color.common_color_3'))
        }
        .width('100%')
        .alignItems(VerticalAlign.Center)

        Text(this.typeText(item))
          .fontSize(14)
          .fontColor($r('app.color.common_color_28'))
          .width('100%')
          .margin({ top: 4 })

        if (this.contentOf(item) !== '') {
          Text(this.contentOf(item))
            .fontSize(15)
            .fontColor($r('app.color.common_color_1'))
            .width('100%')
            .padding({ top: 3.5 })
        }
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
    }
    .width('100%')
    .backgroundColor($r('app.color.main_bg'))
    .padding({ left: 15, right: 15, top: 10, bottom: 10 })
    .alignItems(VerticalAlign.Center)
    .onClick(() => {
      this.onItemTap(item);
    })
  }

  /** adapter：昵称 = ext.userName（EmojiconTextView maxLength=10 源码截断） */
  private nameOf(item: SocialPushMessageItem): string {
    const ext = item.ext;
    const name: string = ext === null ? '' : ext.userName;
    return name.length > 10 ? name.substring(0, 10) : name;
  }

  /** adapter：type=2/其他 且 pl_content 非空才显示正文 */
  private contentOf(item: SocialPushMessageItem): string {
    const ext = item.ext;
    if (ext === null) {
      return '';
    }
    const t: string = ext.type;
    if (t === '0' || t === '1') {
      return '';
    }
    return ext.pl_content;
  }

  build() {
    Column() {
      TitleBar({ title: '消息' })
      Column() {
        if (this.viewState === 'loading') {
          LoadingView()
        } else if (this.viewState === 'empty') {
          // EMPTY_MESSAGE：mobile_campus_page_message 插图（strings empty=""，无文案）
          Image($r('app.media.mobile_campus_page_message'))
            .width(160)
            .objectFit(ImageFit.Contain)
        } else if (this.viewState === 'error') {
          // t0(ERROR)：mobile_campus_page_error + 重试（重拉 page=1）
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
          // common_refresh_lv：ListView + 上拉加载
          List({ space: 0 }) {
            ForEach(this.rows, (item: SocialPushMessageItem) => {
              ListItem() {
                this.messageItem(item)
              }
            }, (item: SocialPushMessageItem) => item.id + '-' + item.readStatus)
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
