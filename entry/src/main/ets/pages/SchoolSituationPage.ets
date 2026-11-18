import { router } from '@kit.ArkUI';
import { TitleBar } from '../components/TitleBar';
import { ApiService } from '../network/ApiService';
import { ApiResponse } from '../model/ResponseModel';
import { SchoolViewIndex, SchoolViewModuleBean } from '../model/ContactModel';
import { Constants } from '../data/Constants';

/**
 * 校园概况页 — 源码级翻译（SchoolSituationActivity.java 逐行 → ArkTS，[W25 misc-b]）：
 *
 * 【布局】mobile_campus_school_activity_situation.xml：toolbar("校园概况") + banner 140dip(px_to_dip_280)
 *   fitXY + 三行色块宫格（weight 0.5/0.7/1.0）：
 *   行1（weight 0.5）：学校介绍(weight1.2 #537DE3)/校歌(weight0.7 #C2C2C2) + 校训(weight0.8 #DAC267)
 *   行2（weight 0.7）：院系介绍(weight2.0 #CFAF6B) + 校徽(weight0.8 #7CA7D3)
 *   行3（weight 1.0）：历史沿革(#B6B6B6)；块内 18dip 图标 + 17fp(font_size_2=px_to_sp_34) 白字 ml8；
 *   XML visibility=invisible，数据到位 O2() → visible
 * 【数据】N2() → SchoolIntroModel.T0：GET open/schoolIntro/index（bVar.j=false 明文通道 plainBizGet；
 *   SchoolIntroFactory a()="open" b()="schoolIntro"，[W25-review 修正] 原 campusView/index 为误引
 *   SchoolFactory 的错误拼接）→ Index{banner, module[{ICON,NAME,URL}]}；banner/ICON → 网络图（netconstant 域+URL）
 * 【跳转】b 类：块点击 → /app/web{navigationBarTitle:NAME, url:d.d()+URL}
 *   （e.a.w=mobile_campus_router_web；HAP WebViewPage 接收 {url,title}，两键并传等价）
 * 【图标】module[i] 顺序填充 6 块（s 列表序=学校介绍/校歌/校训/院系介绍/校徽/历史沿革）；ICON 空→图标 gone
 */
interface SchoolBlock {
  icon: Resource;
  label: string;
  color: string;
}

@Entry
@Component
struct SchoolSituationPage {
  @State bannerUrl: string = '';
  @State modules: SchoolViewModuleBean[] = [];
  @State isLoading: boolean = true;
  /** 源码 s 列表序：学校介绍/校歌/校训/院系介绍/校徽/历史沿革（XML 固定布局/文案/色值） */
  private readonly blocks: SchoolBlock[] = [
    { icon: $r('app.media.mobile_campus_school_w'), label: '学校介绍', color: '#537DE3' },
    { icon: $r('app.media.mobile_campus_school_song'), label: '校歌', color: '#C2C2C2' },
    { icon: $r('app.media.mobile_campus_school_motto'), label: '校训', color: '#DAC267' },
    { icon: $r('app.media.mobile_campus_school_college'), label: '院系介绍', color: '#CFAF6B' },
    { icon: $r('app.media.mobile_campus_school_logo'), label: '校徽', color: '#7CA7D3' },
    { icon: $r('app.media.mobile_campus_school_history'), label: '历史沿革', color: '#B6B6B6' }
  ];

  aboutToAppear(): void {
    this.loadData();
  }

  /** 源码 N2()：SchoolIntroModel.T0 GET open/schoolIntro/index（明文通道） */
  private loadData(): void {
    ApiService.getSchoolViewIndex()
      .then((response: ApiResponse<SchoolViewIndex>) => {
        this.isLoading = false;
        if (response.code === 1000) {
          return;
        }
        if (response.code !== 0) {
          const msg: string = response.message === '' ? '服务器繁忙，请稍后再试' : response.message;
          this.getUIContext().getPromptAction().showToast({ message: msg });
          return;
        }
        // 源码 a 类 g()：banner 网络图 + u=module + O2()
        //   [W25-review 修正] APK banner 走 CommonFactory.a(str)=d.d()+"/mobileapi_ydxy/open/image/"+str
        this.bannerUrl = response.data.banner === '' ? ''
          : Constants.SOCKET_HOST + '/mobileapi_ydxy/open/image/' + response.data.banner;
        this.modules = response.data.module;
      })
      .catch(() => {
        ApiService.logError('SchoolSituationPage load error');
        this.isLoading = false;
      });
  }

  /** 源码 P2(i)：module[i]（越界 → 块保持 invisible） */
  private moduleOf(idx: number): SchoolViewModuleBean | null {
    if (idx < this.modules.length) {
      return this.modules[idx];
    }
    return null;
  }

  private iconUrlOf(bean: SchoolViewModuleBean | null): string {
    if (bean === null || bean.ICON === '') {
      return '';
    }
    // 源码 P2：icon 走 CommonFactory.a(str)=d.d()+"/mobileapi_ydxy/open/image/"+str
    return Constants.SOCKET_HOST + '/mobileapi_ydxy/open/image/' + bean.ICON;
  }

  /** 源码 b 类：块点击 → /app/web{navigationBarTitle, url:d.d()+URL} */
  private openModule(bean: SchoolViewModuleBean): void {
    router.pushUrl({ url: 'pages/WebViewPage',
      params: {
        'navigationBarTitle': bean.NAME,
        'title': bean.NAME,
        'url': Constants.SOCKET_HOST + bean.URL
      } as Record<string, string> });
  }

  build() {
    Column() {
      TitleBar({ title: '校园概况', showBack: true })

      if (this.isLoading) {
        LoadingPlaceholder()
      } else {
        Scroll() {
          Column() {
            // banner 140dip fitXY
            if (this.bannerUrl !== '') {
              Image(this.bannerUrl)
                .width('100%')
                .height(140)
                .objectFit(ImageFit.Fill)
            } else {
              Column()
                .width('100%')
                .height(140)
            }

            // 行1：学校介绍(1.2) 校歌(0.7) + 校训(0.8)
            Row() {
              this.blockItem(0, 1.2, 16, true)
              this.blockItem(1, 0.7, 8, true)
              this.blockItem(2, 0.8, 16, true)
            }
            .width('100%')
            .height(80)
            .margin({ top: 0 })

            // 行2：院系介绍(2.0) 校徽(0.8)
            Row() {
              this.blockItem(3, 2.0, 8, false)
              this.blockItem(4, 0.8, 16, false)
            }
            .width('100%')
            .height(112)
            .margin({ top: 0 })

            // 行3：历史沿革(整行)
            this.blockItem(5, 1, 16, false)

            Blank()
              .height(16)
          }
          .width('100%')
        }
        .width('100%')
        .layoutWeight(1)
        .scrollBar(BarState.Off)
        .align(Alignment.Top)
        .backgroundColor($r('app.color.white'))
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.white'))
  }

  /** 色块：icon 18dip + 17fp 白字 ml8；module 越界 → invisible */
  @Builder
  blockItem(idx: number, weight: number, marginH: number, showMarginTop: boolean) {
    Stack({ alignContent: Alignment.Center }) {
      Row() {
        Image(this.blocks[idx].icon)
          .width(18)
          .height(18)
          .visibility(this.iconUrlOf(this.moduleOf(idx)) === '' && this.moduleOf(idx) !== null
            ? Visibility.None : Visibility.Visible)
        if (this.iconUrlOf(this.moduleOf(idx)) !== '') {
          Image(this.iconUrlOf(this.moduleOf(idx)))
            .width(18)
            .height(18)
            .margin({ left: 8 })
        }
        Text(this.blocks[idx].label)
          .fontSize(17)
          .fontColor($r('app.color.ybg_white'))
          .margin({ left: 8 })
      }
      .alignItems(VerticalAlign.Center)
    }
    .layoutWeight(weight)
    .height('100%')
    .backgroundColor(this.blocks[idx].color)
    .margin({
      left: idx === 1 || idx === 4 ? 8 : marginH,
      right: idx === 2 || idx === 4 ? 16 : 0,
      top: showMarginTop ? 8 : 0,
      bottom: idx === 5 ? 16 : 0
    })
    .visibility(this.moduleOf(idx) !== null ? Visibility.Visible : Visibility.Hidden)
    .onClick(() => {
      const bean: SchoolViewModuleBean | null = this.moduleOf(idx);
      if (bean !== null) {
        this.openModule(bean);
      }
    })
  }
}

/** 加载占位（源码 banner/色块 XML invisible 态等价：数据前仅 toolbar） */
@Component
struct LoadingPlaceholder {
  build() {
    Column()
      .width('100%')
      .layoutWeight(1)
      .backgroundColor($r('app.color.white'))
  }
}
