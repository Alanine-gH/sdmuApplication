import { router } from '@kit.ArkUI';
import { TitleBar } from '../components/TitleBar';
import { EmptyView } from '../components/EmptyView';
import { LoadingView } from '../components/LoadingView';
import { ApiService } from '../network/ApiService';
import { ApiResponse } from '../model/ResponseModel';
import { LoginSession } from '../network/LoginSession';
import { Constants } from '../data/Constants';
import { ClassmateEntry } from '../model/ScoreModel';
import { BusinessError } from '@kit.BasicServicesKit';

/**
 * 同学列表页 — 1:1 翻译原 APK ClassmatesListActivity.java（timetable/view）+ ClassmatesListAdapter
 * + base_user_info_item.xml。
 *
 * 【入口链】CourseDetailActivity d/e 回调（HAP CourseDetailPage.goClassmates 已 1:1 传参）：
 *   pagetype=2 最高分保持者：{xn,xq,kcmc,zgfzscj,num=zgfbczrs,djz,xqj,djj}
 *   pagetype=1 上课学生：{xn,xq,dm,num=skrs,djz,xqj,djj}
 * 【标题】T1：pagetype==1 → "上课学生"（+num 非空追加 "(num)"）；否则 "最高分保持者"（同追加）。
 *   数据回调覆盖：S0 → "上课学生(size)" / u0 → "最高分保持者(size)"（ad.r="(" ad.s=")" 半角）。
 * 【数据】pagetype==1 → ClassmateModel.N：GET api/schedule/matchGateMsg {xn,xq,dm,djz,xqj,djj}
 *   （2026-11-18 实测 98/89 人 code=0）；否则 → ClassmateModel.q0：GET highestScoreMsg {xn,xq,kcmc,zgfzscj}
 *   （实测 zgfzscj=96.8 → 1 人 code=0）。空 → MultiStateView 空态；失败 → 有数据 toast / 无数据错误态。
 *   下拉刷新/f2(onResume) 重拉；pagetype==1 点击 item 源码空实现（无跳转）。
 * 【行 UI】base_user_info_item：padding 15/12、头像 50vp（LianYiCommonFactory.g：
 *   serverUrl + /mobileapi/open/common/{schoolId}/{xh}/1）+ 昵称 xm 17fp#333 + 性别图标
 *   （男 my_user_boy / 女 my_user_girl / 其他隐藏，margin 4vp）+ 第二行 bjmc 14fp#999 + 右侧 qjlb
 *   12fp #ff6c6c（ybg_red，空隐藏）。
 */
@Entry
@Component
struct ClassmatesListPage {
  @State pageTitle: string = '';
  @State classmateList: ClassmateEntry[] = [];
  @State isLoading: boolean = true;
  @State loadFailed: boolean = false;
  // 源码 y(Intent) 十参
  private xn: string = '';
  private xq: string = '';
  private dm: string = '';
  private kcmc: string = '';
  private zgfzscj: string = '';
  private num: string = '';
  private djz: string = '';
  private xqj: string = '';
  private djj: string = '';
  private pagetype: number = 1;

  private isGateType(): boolean {
    // 源码 S2()：this.z == 1 → 上课学生（matchGateMsg）
    return this.pagetype === 1;
  }

  aboutToAppear(): void {
    const params: Record<string, Object> | undefined =
      router.getParams() as Record<string, Object> | undefined;
    if (params) {
      this.xn = this.strOf(params['xn']);
      this.xq = this.strOf(params['xq']);
      this.dm = this.strOf(params['dm']);
      this.kcmc = this.strOf(params['kcmc']);
      this.zgfzscj = this.strOf(params['zgfzscj']);
      this.num = this.strOf(params['num']);
      this.djz = this.strOf(params['djz']);
      this.xqj = this.strOf(params['xqj']);
      this.djj = this.strOf(params['djj']);
      const pt: Object = params['pagetype'];
      this.pagetype = typeof pt === 'number' ? pt : Number(pt);
      if (Number.isNaN(this.pagetype)) {
        this.pagetype = 1;
      }
    }
    // 源码 T1：标题 + num 非空追加 "(" + num + ")"（ad.r="(" ad.s=")" 半角）
    this.pageTitle = this.isGateType() ? '上课学生' : '最高分保持者';
    if (this.num !== '') {
      this.pageTitle = this.pageTitle + '(' + this.num + ')';
    }
    this.fetchList();
  }

  private strOf(v: Object): string {
    if (typeof v === 'string') {
      return v as string;
    }
    if (typeof v === 'number') {
      return String(v as number);
    }
    return '';
  }

  /** 源码 f1/f2/下拉刷新 a()：按 pagetype 分流 b(...6参)/c(...4参) */
  private fetchList(): void {
    this.isLoading = true;
    this.loadFailed = false;
    const call: Promise<ApiResponse<ClassmateEntry[]>> = this.isGateType() ?
      ApiService.getMatchGateMsg(this.xn, this.xq, this.dm, this.djz, this.xqj, this.djj) :
      ApiService.getHighestScoreMsg(this.xn, this.xq, this.kcmc, this.zgfzscj);
    call.then((response: ApiResponse<ClassmateEntry[]>) => {
      if (response.code === 1000) {
        return;
      }
      if (response.code === 0) {
        this.applyList(response.data);
      } else {
        // 源码 M/p1：有数据 toast msg；无数据 t0(ERROR)
        this.loadFailed = this.classmateList.length === 0;
        if (this.classmateList.length > 0 && response.message !== '') {
          this.getUIContext().getPromptAction().showToast({ message: response.message });
        }
      }
      this.isLoading = false;
    }).catch((error: BusinessError) => {
      ApiService.logError('ClassmatesList fetch fail: ' + error.message);
      this.loadFailed = this.classmateList.length === 0;
      this.isLoading = false;
    });
  }

  /** 源码 S0/u0：空 → q2 空态；非空 → 标题覆盖"…（size）" */
  private applyList(list: ClassmateEntry[]): void {
    this.classmateList = list;
    if (list.length === 0) {
      return;
    }
    const base: string = this.isGateType() ? '上课学生' : '最高分保持者';
    this.pageTitle = base + '(' + list.length + ')';
  }

  /** 源码 ClassmatesListAdapter.convert i.e：头像 URL = LianYiCommonFactory.g(schoolId, xh, "1")
   *  = serverUrl(Constants.SOCKET_HOST=netconstant.d.c()) + "/mobileapi/open/common/" + schoolId + "/" + xh + "/1" */
  private avatarUrlOf(entry: ClassmateEntry): string {
    if (entry.xh === '') {
      return '';
    }
    return LoginSession.schoolId === '' ? '' :
      Constants.SOCKET_HOST + '/mobileapi/open/common/' + LoginSession.schoolId + '/' +
      entry.xh + '/1';
  }

  @Builder
  classmateRow(entry: ClassmateEntry) {
    Row() {
      // base_user_info_item_iv_avatar 50vp default_avatar
      Image(this.avatarUrlOf(entry) === '' ? $r('app.media.default_avatar') : this.avatarUrlOf(entry))
        .width(50)
        .height(50)
        .borderRadius(25)
        .objectFit(ImageFit.Cover)
        .alt($r('app.media.default_avatar'))
      Column() {
        Row() {
          Text(entry.xm)
            .fontSize(17)
            .fontColor($r('app.color.common_color_1'))
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
          // 性别图标：男 boy / 女 girl / 其他 gone（源码 convert xb 分支）
          if (entry.xb === '男') {
            Image($r('app.media.my_user_boy'))
              .width(14)
              .height(14)
              .margin({ left: 4, top: 2 })
          } else if (entry.xb === '女') {
            Image($r('app.media.my_user_girl'))
              .width(14)
              .height(14)
              .margin({ left: 4, top: 2 })
          }
          // extra_info：qjlb 请假类别（ybg_red，空 gone）
          if (entry.qjlb !== '') {
            Text(entry.qjlb)
              .fontSize(12)
              .fontColor($r('app.color.ybg_red'))
              .maxLines(1)
              .margin({ left: 12 })
              .layoutWeight(1)
              .textAlign(TextAlign.End)
          }
        }
        .width('100%')
        .alignItems(VerticalAlign.Center)
        Text(entry.bjmc)
          .fontSize(14)
          .fontColor($r('app.color.common_color_3'))
          .maxLines(1)
          .margin({ top: 4 })
          .width('100%')
      }
      .layoutWeight(1)
      .margin({ left: 8 })
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .padding({ left: 15, right: 15, top: 12, bottom: 12 })
    .backgroundColor($r('app.color.white'))
    .alignItems(VerticalAlign.Center)
  }

  build() {
    Column() {
      TitleBar({ title: this.pageTitle, showBack: true })
      if (this.isLoading && this.classmateList.length === 0) {
        LoadingView()
      } else if (this.classmateList.length === 0 && this.loadFailed) {
        // 源码 t0(Page.ERROR)：错误态重试
        EmptyView({ tipText: '加载失败，请稍后再试' })
      } else if (this.classmateList.length === 0) {
        // 源码 q2：空数据态
        EmptyView({ tipText: '暂无数据' })
      } else {
        // RefreshLayout(ListView)：下拉刷新重拉（源码 PullToRefreshLayout a.a()）；pagetype=1 点击空实现
        Refresh({ refreshing: false }) {
          List() {
            ForEach(this.classmateList, (entry: ClassmateEntry) => {
              ListItem() {
                this.classmateRow(entry)
              }
            }, (entry: ClassmateEntry) => entry.xh + '-' + entry.xm)
          }
          .width('100%')
          .height('100%')
          .scrollBar(BarState.Off)
          .divider({ strokeWidth: 0.4, color: $r('app.color.common_color_5'), startMargin: 0, endMargin: 0 })
          .backgroundColor($r('app.color.main_bg'))
        }
        .width('100%')
        .layoutWeight(1)
        .onRefreshing(() => {
          this.fetchList();
        })
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.main_bg'))
  }
}
