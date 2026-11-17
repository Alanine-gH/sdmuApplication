// 数据源：无服务器接口，页面数据为内置示例数据（离线演示用），未接 ApiService。
import { TitleBar } from '../components/TitleBar';

/**
 * 校园地图页 — 1:1 复刻 mobile_campus_school_activity_function_map.xml +
 * mobile_campus_school_bottom.xml + mobile_campus_school_item_search_head.xml +
 * mobile_campus_school_route_plan_foot.xml
 *
 * function_map.xml：LinearLayout vertical + toolbar_normal + CoordinatorLayout（RelativeLayout）：
 *   MapView（铺满，原生复刻为地图占位）+ AutoFixedTabLayout（顶部白底）+
 *   ClearableEditText 搜索（school_shape_search_bg 圆角 6dip #FDFDFD、高 35.0dip、
 *   marginH px_to_dip_15=7.5vp、marginTop px_to_dip_20=10vp、drawableLeft=school_search_g 9dip、
 *   hint"查找地点"、px_to_sp_28=14fp）+ bottom（对齐底部，高 px_to_dip_168=84vp）+
 *   route_plan_foot（对齐底部）
 *
 * bottom.xml：RelativeLayout 高 84vp：iv_location（marginL px_to_dip_32=16vp、居中）+
 *   rl_plan（mobile_campus_school_plan_bg：#007EFF、圆角 20dip、px_to_dip_212x88=106x44vp、居中）：
 *   way 图标 + "路线"（marginL px_to_dip_24=12vp）
 *
 * item_search_head.xml：ll_route_location 白底高 px_to_dip_144=72vp：
 *   上 24vp 空 + #F2F2F2 24vp 条 + Relative 96vp：local2 图标（marginL px_to_dip_40=20vp、
 *   marginR px_to_dip_24=12vp）+ "我的位置"
 *
 * route_plan_foot.xml：白底：rv_plan_list 高 px_to_dip_176=88vp + #CDCDCD 0.5vp 分隔线 +
 *   tv_Navi"导航"（navigation_bg：白底 2px #007EFF 描边、圆角 8px=4vp、高 px_to_dip_71=35.5vp、
 *   margin px_to_dip_21=10.5vp）
 */
class SchoolMapPlace {
  name: string;
  distance: string;

  constructor(name: string, distance: string) {
    this.name = name;
    this.distance = distance;
  }
}

@Entry
@Component
struct SchoolMapPage {
  @State currentTabIndex: number = 0;
  @State searchKey: string = '';
  @State showRoutePlan: boolean = false;
  private tabNames: string[] = ['教学楼', '宿舍', '食堂', '图书馆', '体育馆'];
  private searchPlaces: SchoolMapPlace[] = [
    new SchoolMapPlace('第一教学楼', '距你 320m'),
    new SchoolMapPlace('第二教学楼', '距你 480m'),
    new SchoolMapPlace('图书馆', '距你 550m')
  ];

  build() {
    Column() {
      TitleBar({ title: '校园地图' })
      // CoordinatorLayout 内容
      Stack() {
        // MapView 原生复刻：地图占位
        Column() {
          Column()
            .width('100%')
            .height('100%')
            .backgroundColor('#E8F0E4')
        }
        .width('100%')
        .height('100%')

        // AutoFixedTabLayout（顶部白底）
        Column() {
          Scroll() {
            Row() {
              ForEach(this.tabNames, (name: string, index: number) => {
                Text(name)
                  .fontSize(14)
                  .fontColor(index === this.currentTabIndex
                    ? $r('app.color.mobile_campus_primary_color_default')
                    : $r('app.color.common_color_1'))
                  .height(40)
                  .padding({ left: 12, right: 12 })
                  .textAlign(TextAlign.Center)
                  .onClick(() => {
                    this.currentTabIndex = index;
                  })
              }, (name: string) => name)
            }
          }
          .scrollable(ScrollDirection.Horizontal)
          .width('100%')
          .backgroundColor($r('app.color.white'))

          // ClearableEditText 搜索框
          Row() {
            Image($r('app.media.mobile_campus_school_search_g'))
              .width(16)
              .height(16)
              .margin({ right: 9 }) // drawablePadding 9dip
            TextInput({ text: this.searchKey, placeholder: '查找地点' })
              .fontSize(14) // px_to_sp_28/2=14fp
              .fontColor($r('app.color.common_color_1'))
              .placeholderColor('#B5B5B5')
              .placeholderFont({ size: 14 })
              .backgroundColor(Color.Transparent)
              .padding(0)
              .layoutWeight(1)
              .height(30)
              .onChange((value: string) => {
                this.searchKey = value;
              })
          }
          .width('100%')
          .height(35) // 35.0dip
          .padding({ left: 8, right: 8 })
          .margin({ left: 7.5, right: 7.5, top: 10 }) // px_to_dip_15/2=7.5、px_to_dip_20/2=10
          .borderRadius(6) // school_shape_search_bg 圆角 6dip
          .backgroundColor('#FDFDFD')
          .alignItems(VerticalAlign.Center)

          // ll_route_search：搜索结果列表（#F2F2F2 底）
          if (this.searchKey.trim().length > 0) {
            List() {
              ForEach(this.searchPlaces, (place: SchoolMapPlace, index: number) => {
                ListItem() {
                  Row() {
                    Text(place.name)
                      .fontSize(14)
                      .fontColor($r('app.color.common_color_1'))
                      .layoutWeight(1)
                    Text(place.distance)
                      .fontSize(12)
                      .fontColor($r('app.color.common_color_3'))
                  }
                  .width('100%')
                  .height(44)
                  .padding({ left: 12, right: 12 })
                  .backgroundColor($r('app.color.white'))
                }
              }, (place: SchoolMapPlace) => place.name)
            }
            .width('100%')
            .layoutWeight(1)
            .backgroundColor('#F2F2F2')
          }
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)

        // mobile_campus_school_bottom.xml：底部 84vp
        Stack({ alignContent: Alignment.Center }) {
          // iv_location：marginL 16vp、垂直居中
          Image($r('app.media.mobile_campus_school_mylocal'))
            .width(28)
            .height(28)
            .objectFit(ImageFit.Contain)
            .margin({ right: 180 })
          // rl_plan：路线按钮 106x44、#007EFF、圆角 20dip
          Row() {
            Image($r('app.media.mobile_campus_school_way'))
              .width(18)
              .height(18)
              .objectFit(ImageFit.Contain)
            Text('路线')
              .fontSize(14)
              .fontColor($r('app.color.white'))
              .margin({ left: 12 }) // px_to_dip_24/2=12vp
          }
          .width(106) // px_to_dip_212/2=106vp
          .height(44) // px_to_dip_88/2=44vp
          .borderRadius(20) // 圆角 20.0dip
          .backgroundColor('#007EFF')
          .justifyContent(FlexAlign.Center)
          .onClick(() => {
            this.showRoutePlan = !this.showRoutePlan;
          })
        }
        .width('100%')
        .height(84) // px_to_dip_168/2=84vp
        .alignContent(Alignment.Bottom)

        // route_plan_foot：路线规划面板（点路线显示）
        if (this.showRoutePlan) {
          Column() {
            // item_search_head.xml：ll_route_location 白底 72vp
            Column() {
              Blank()
                .height(12) // px_to_dip_24/2=12vp
              Column()
                .width('100%')
                .height(12)
                .backgroundColor('#F2F2F2')
              Row() {
                Image($r('app.media.mobile_campus_school_local2'))
                  .width(20)
                  .height(20)
                  .objectFit(ImageFit.Contain)
                  .margin({ left: 20, right: 12 }) // px_to_dip_40/2=20、px_to_dip_24/2=12
                Text('我的位置')
                  .fontSize(14)
                  .fontColor($r('app.color.common_color_1'))
              }
              .width('100%')
              .layoutWeight(1)
              .alignItems(VerticalAlign.Center)
            }
            .width('100%')
            .height(72) // px_to_dip_144/2=72vp
            .backgroundColor($r('app.color.white'))

            // rv_plan_list：高 88vp
            Column() {
              Row() {
                Text('步行')
                  .fontSize(13)
                  .fontColor($r('app.color.common_color_1'))
                  .layoutWeight(1)
                Text('约 8 分钟')
                  .fontSize(13)
                  .fontColor($r('app.color.common_color_3'))
              }
              .width('100%')
              .layoutWeight(1)
              .padding({ left: 12, right: 12 })
              .alignItems(VerticalAlign.Center)

              Row() {
                Text('骑行')
                  .fontSize(13)
                  .fontColor($r('app.color.common_color_1'))
                  .layoutWeight(1)
                Text('约 3 分钟')
                  .fontSize(13)
                  .fontColor($r('app.color.common_color_3'))
              }
              .width('100%')
              .layoutWeight(1)
              .padding({ left: 12, right: 12 })
              .alignItems(VerticalAlign.Center)
            }
            .width('100%')
            .height(88) // px_to_dip_176/2=88vp

            Divider()
              .color('#CDCDCD')
              .strokeWidth(0.5)
              .width('100%')
            // tv_Navi："导航"
            Text('导航')
              .fontSize(14)
              .fontColor($r('app.color.common_color_1'))
              .textAlign(TextAlign.Center)
              .width('100%')
              .height(35.5) // px_to_dip_71/2=35.5vp
              .margin(10.5) // px_to_dip_21/2=10.5vp
              .borderRadius(4) // 圆角 8.0px=4vp
              .border({ width: 1, color: '#007EFF' })
              .backgroundColor($r('app.color.white'))
              .onClick(() => {
                this.showRoutePlan = false;
              })
          }
          .width('100%')
          .backgroundColor($r('app.color.white'))
          .alignItems(HorizontalAlign.Start)
        }
      }
      .width('100%')
      .layoutWeight(1)
      .alignContent(Alignment.Bottom)
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.main_bg'))
  }
}
