import { BusinessError, pasteboard } from '@kit.BasicServicesKit';
import { common } from '@kit.AbilityKit';
import { TitleBar } from '../components/TitleBar';
import { EmptyView } from '../components/EmptyView';
import { ApiService, SchoolMapArea, SchoolMapBubble } from '../network/ApiService';
import { PetalMapHelper } from '../common/PetalMapHelper';
import { BreakpointSystem } from '../common/BreakpointSystem';

/**
 * 校园地图页 — 1:1 还原 SchoolFunctionMapActivity + BaseMapActivity（manifest L456 action sdgy_schoolMap）。
 *
 * 【源码依据】layout mobile_campus_school_activity_function_map.xml：
 *   toolbar_normal（BaseMapActivity.T1 标题"校园地图"）+ mv_map（高德 MapView）+ tl_layout（AutoFixedTabLayout
 *   校区页签，a4() 用 AREA_NAME 建 tab）+ ed_search（ClearableEditText hint"查找地点"）+
 *   rl_remind/rv_search（BottomSheet 地点列表 RvLoadMoreAdapter）+ ll_head/ll_foot（路线规划面板）。
 * 【数据】SchoolMapSearchPimpl.c() → SchoolSearchModel.T0（school/g/d.java）bVar.j=false 明文 GET
 *   open/schoolMap/data → Data{AREA[],BUBBLE[]}。g$onSuccess：code=="0" 时 k0.addAll(BUBBLE)、l0.addAll(AREA)、a4() 建页签。
 *   2026-11-18 probe 实测 code=0：AREA=[{AREA_NAME:"山东管理学院",CENCRE_NAME:"山东管理学院",
 *     LAT:36.5305363958,LAN:116.7842602730,CITY:"济南市",AREA_STATUS:"1"}]，BUBBLE 空。
 * 【HAP 保真边界】APK 地图瓦片/POI 搜索/路径规划依赖高德 SDK（com.amap.api.maps+services），
 *   HAP 工程无在线地图 SDK → 按方法论如实还原"校区页签 + 查找地点 + 地点列表（真实服务端数据）"骨架，
 *   不硬编造地图坐标/路线；地点列表展示源码 Data 字段（名称/中心/经纬度/城市）。
 *   点"到这去"仅展示来源经纬度（真实数据），路线导航能力依赖地图 SDK 不在本批范围。
 */
@Entry
@Component
struct SchoolMapPage {
  @State areas: SchoolMapArea[] = [];
  @State bubbles: SchoolMapBubble[] = [];
  @State keyword: string = '';
  @State selectedArea: number = 0;
  @State loading: boolean = true;
  /** 源码 V3()：步行=2 / 骑行=3 / 驾车=0（cb_walk/cb_ride/cb_drive 单选） */
  @State routeMode: number = 2;
  @StorageProp('currentBreakpoint') currentBreakpoint: string = 'sm';
  @StorageProp('avoidAreaBottomVp') avoidAreaBottomVp: number = 0;

  aboutToAppear(): void {
    this.loadData();
  }

  private toast(message: string): void {
    this.getUIContext().getPromptAction().showToast({ message: message });
  }

  private copyCoordinates(name: string, lat: string, lan: string): void {
    const text: string = `${name} (${lat}, ${lan})`;
    try {
      const data: pasteboard.PasteData = pasteboard.createData(pasteboard.MIMETYPE_TEXT_PLAIN, text);
      pasteboard.getSystemPasteboard().setData(data).then(() => {
        this.toast('已复制坐标：' + text);
      }).catch(() => {
        this.toast('复制失败');
      });
    } catch {
      this.toast('复制失败');
    }
  }

  private showMapUnavailableFallback(title: string, message: string, name: string, lat: string, lan: string): void {
    AlertDialog.show({
      title: title,
      message: `${message}\n地点：${name}\n坐标（GCJ-02）：${lat}, ${lan}`,
      autoCancel: true,
      alignment: DialogAlignment.Center,
      primaryButton: {
        value: '关闭',
        action: () => {
        }
      },
      secondaryButton: {
        value: '复制坐标',
        action: () => {
          this.copyCoordinates(name, lat, lan);
        }
      }
    });
  }

  private async openPoiLocation(name: string, lat: string, lan: string, city: string, sub: string): Promise<void> {
    const ctx = this.getUIContext().getHostContext() as common.Context;
    const addr: string = city !== '' ? `${city} ${sub}`.trim() : sub;
    const res = await PetalMapHelper.openPoiDetail(ctx, lat, lan, name, addr);
    if (res.success) {
      return;
    }
    if (res.unavailable) {
      this.showMapUnavailableFallback('查看校园位置', res.message, name, lat, lan);
    } else {
      this.toast(res.message);
    }
  }

  private async navigateToPlace(name: string, lat: string, lan: string): Promise<void> {
    const ctx = this.getUIContext().getHostContext() as common.Context;
    const res = await PetalMapHelper.openRoutePlan(ctx, lat, lan, name, this.routeMode);
    if (res.success) {
      return;
    }
    if (res.unavailable) {
      this.showMapUnavailableFallback(`${this.modeLabel()}导航`, res.message, name, lat, lan);
    } else {
      this.toast(res.message);
    }
  }

  private async loadData(): Promise<void> {
    try {
      const resp = await ApiService.getSchoolMapData();
      if (resp.code === 0) {
        this.areas = resp.data.AREA;
        this.bubbles = resp.data.BUBBLE;
      }
    } catch (error) {
      const be = error as BusinessError;
      ApiService.logError('SchoolMapPage loadData fail: ' + be.message);
    } finally {
      this.loading = false;
    }
  }

  /** 源码 ed_search 本地等价：AREA/BUBBLE 名称 contains 过滤（高德 POI 搜索 HAP 无 SDK，按已加载真实地点过滤） */
  private filteredAreas(): SchoolMapArea[] {
    if (this.keyword.trim() === '') {
      return this.areas;
    }
    return this.areas.filter((a: SchoolMapArea) =>
      a.AREA_NAME.includes(this.keyword.trim()) || a.CENCRE_NAME.includes(this.keyword.trim()));
  }

  private filteredBubbles(): SchoolMapBubble[] {
    if (this.keyword.trim() === '') {
      return this.bubbles;
    }
    return this.bubbles.filter((b: SchoolMapBubble) => b.BUBBLE_NAME.includes(this.keyword.trim()));
  }

  private modeLabel(): string {
    if (this.routeMode === 3) {
      return '骑行';
    }
    return this.routeMode === 0 ? '驾车' : '步行';
  }

  build() {
    Column() {
      TitleBar({ title: '校园地图', showBack: true })

      // tl_layout 校区页签（源码 a4()：for AREA → newTab(AREA_NAME)）
      if (this.areas.length > 0) {
        Scroll() {
          Row({ space: 18 }) {
            ForEach(this.areas, (area: SchoolMapArea, idx: number) => {
              Text(area.AREA_NAME)
                .fontSize(14)
                .fontColor(this.selectedArea === idx ? $r('app.color.sdmu_primary') : $r('app.color.common_color_3'))
                .padding({ bottom: 8 })
                .onClick(() => {
                  this.selectedArea = idx;
                })
            }, (area: SchoolMapArea) => 'area_' + area.XLH)
          }
        }
        .scrollable(ScrollDirection.Horizontal)
        .width('100%')
        .padding({ left: 15, right: 15, top: 10 })
        .backgroundColor($r('app.color.white'))
      }

      // ed_search hint"查找地点"
      Column() {
        TextInput({ text: this.keyword, placeholder: '查找地点' })
          .width('100%')
          .height(35)
          .padding({ left: 8, right: 8 })
          .fontSize(14)
          .placeholderColor('#b5b5b5')
          .backgroundColor($r('app.color.common_color_5'))
          .borderRadius(4)
          .onChange((value: string) => {
            this.keyword = value;
          })

        // 路线方式（源码 cb_walk/cb_ride/cb_drive → V3() 2/3/0）
        Row({ space: 12 }) {
          ForEach([2, 3, 0], (mode: number) => {
            Text(mode === 2 ? '步行' : (mode === 3 ? '骑行' : '驾车'))
              .fontSize(13)
              .fontColor(this.routeMode === mode ? $r('app.color.white') : $r('app.color.common_color_1'))
              .padding({ left: 14, right: 14, top: 6, bottom: 6 })
              .borderRadius(14)
              .backgroundColor(this.routeMode === mode ? $r('app.color.sdmu_primary') : $r('app.color.common_color_5'))
              .onClick(() => {
                this.routeMode = mode;
              })
          }, (mode: number) => 'mode_' + mode)
        }
        .width('100%')
        .padding({ top: 12 })
      }
      .width('100%')
      .constraintSize({ maxWidth: BreakpointSystem.getContentMaxWidth(this.currentBreakpoint) })
      .padding({ left: 15, right: 15, top: 16 })

      // rl_remind/rv_search 地点列表（真实 Data.BUBBLE/AREA）
      if (this.loading) {
        LoadingProgress().width(40).height(40).color($r('app.color.sdmu_primary')).margin({ top: 24 })
      } else if (this.filteredAreas().length === 0 && this.filteredBubbles().length === 0) {
        EmptyView({ tipText: '暂无地点数据' })
      } else {
        Scroll() {
          Column() {
            ForEach(this.filteredAreas(), (area: SchoolMapArea) => {
              this.PlaceRow(area.AREA_NAME, area.CENCRE_NAME, area.LAT, area.LAN, area.CITY)
            }, (area: SchoolMapArea) => 'pa_' + area.XLH)
            ForEach(this.filteredBubbles(), (bubble: SchoolMapBubble) => {
              this.PlaceRow(bubble.BUBBLE_NAME, bubble.AREA_NAME, bubble.LAT, bubble.LAN, '')
            }, (bubble: SchoolMapBubble) => 'pb_' + bubble.XLH)
          }
          .width('100%')
          .constraintSize({ maxWidth: BreakpointSystem.getContentMaxWidth(this.currentBreakpoint) })
          .padding({ bottom: Math.max(12, this.avoidAreaBottomVp) })
        }
        .width('100%')
        .layoutWeight(1)
        .margin({ top: 8 })
      }
    }
    .width('100%')
    .height('100%')
    .alignItems(HorizontalAlign.Center)
    .backgroundColor($r('app.color.main_bg'))
  }

  /** RvLoadMoreAdapter 地点行：名称 + 中心/区域 + 经纬度 + 花瓣地图跳转按钮 */
  @Builder
  PlaceRow(name: string, sub: string, lat: string, lan: string, city: string) {
    Column() {
      Row() {
        Text(name)
          .fontSize(16)
          .fontColor($r('app.color.common_color_1'))
          .layoutWeight(1)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        Text(this.modeLabel()).fontSize(11).fontColor($r('app.color.sdmu_primary'))
          .margin({ left: 8 }).padding({ left: 6, right: 6, top: 2, bottom: 2 })
          .borderRadius(8).backgroundColor($r('app.color.common_color_5'))
      }
      .width('100%')
      if (sub !== '') {
        Text(sub).fontSize(13).fontColor($r('app.color.common_color_3')).margin({ top: 4 })
      }
      Text((city !== '' ? city + '  ' : '') + '纬度 ' + lat + '  经度 ' + lan)
        .fontSize(12).fontColor($r('app.color.common_color_3')).margin({ top: 4 })
      Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.End }) {
        Text('查看位置')
          .fontSize(12)
          .fontColor('#1B68B7')
          .backgroundColor('#EBF4FC')
          .borderRadius(12)
          .padding({ left: 10, right: 10, top: 5, bottom: 5 })
          .margin({ left: 8, top: 8 })
          .onClick(() => {
            this.openPoiLocation(name, lat, lan, city, sub);
          })
        Text('到这去')
          .fontSize(12)
          .fontColor($r('app.color.white'))
          .backgroundColor($r('app.color.sdmu_primary'))
          .borderRadius(12)
          .padding({ left: 12, right: 12, top: 5, bottom: 5 })
          .margin({ left: 8, top: 8 })
          .onClick(() => {
            this.navigateToPlace(name, lat, lan);
          })
      }
      .width('100%')
      Divider()
        .color($r('app.color.common_color_5'))
        .strokeWidth(0.5)
        .width('100%')
        .margin({ top: 10 })
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
    .padding({ left: 15, right: 15, top: 12, bottom: 4 })
    .backgroundColor($r('app.color.white'))
    .onClick(() => {
      this.navigateToPlace(name, lat, lan);
    })
  }
}
