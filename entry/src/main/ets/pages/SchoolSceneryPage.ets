// 数据源：无服务器接口，页面数据为内置示例数据（离线演示用），未接 ApiService。
import { TitleBar } from '../components/TitleBar';

/** 校园风光条目模型 */
class SceneryItem {
  id: string;
  title: string;
  likeNum: string;
  category: number;

  constructor(id: string, title: string, likeNum: string, category: number) {
    this.id = id;
    this.title = title;
    this.likeNum = likeNum;
    this.category = category;
  }
}

/** 校园风光内置示例数据（山东管理学院） */
function buildSceneryItems(): SceneryItem[] {
  const items: SceneryItem[] = [
    new SceneryItem('S1', '明德楼', '128', 1),
    new SceneryItem('S2', '图书馆', '356', 1),
    new SceneryItem('S3', '博文楼', '96', 1),
    new SceneryItem('S4', '学生公寓', '201', 2),
    new SceneryItem('S5', '餐厅生活区', '158', 2),
    new SceneryItem('S6', '田径运动场', '412', 3),
    new SceneryItem('S7', '篮球场', '187', 3),
    new SceneryItem('S8', '校园林荫道', '265', 0)
  ];
  return items;
}

/** 当前分类下的风光数据 */
function filterSceneryItems(items: SceneryItem[], category: number): SceneryItem[] {
  if (category === 0) {
    return items;
  }
  return items.filter((s: SceneryItem): boolean => s.category === category);
}

/**
 * 校园风光页 — 按源布局 1:1 复刻 mobile_campus_school_activity_scenery.xml：
 *   LinearLayout vertical（fill_parent）
 *   - include toolbar_normal（标题“校园风光”）
 *   - TabLayout：height=px_to_dip_72=36vp、textSize=px_to_dip_30=15fp、
 *     tabIndicatorColor/tabSelectedTextColor=mobile_campus_primary_color_default、
 *     tabTextColor=common_color_3、tabMaxWidth=72.0dip=36vp
 *   - ViewPager → mobile_campus_school_fragment_scenery.xml
 *     （PullToRefreshLayout + MultiStateView + RecyclerView padding=7.0dip=7vp）
 *     条目 mobile_campus_school_view_scenery.xml：
 *     ImageView（fill_parent、scaleType=centerCrop、minWidth=px_to_dip_330=165vp）
 *     + 底部 RelativeLayout bg=#4D000000、height=px_to_dip_48=24vp、
 *       paddingLeft/Right=px_to_dip_32=16vp：tvLikeNum（drawableLeft=like、drawablePadding=8.0dip=8vp）
 *       居左 + tvTitle 居右，均白字。
 */
@Entry
@Component
struct SchoolSceneryPage {
  @State currentTab: number = 0;
  @State sceneryList: SceneryItem[] = filterSceneryItems(buildSceneryItems(), 0);

  /** TabLayout 指示器颜色 mobile_campus_primary_color_default=#1B68B7、文字未选 common_color_3 */
  @Builder
  sceneryTabItem(name: string, index: number) {
    Column() {
      Text(name)
        .fontSize(15) // px_to_dip_30/2=15fp
        .fontColor(this.currentTab === index ? $r('app.color.mobile_campus_primary_color_default') : $r('app.color.common_color_3'))
      // tabIndicatorColor=mobile_campus_primary_color_default
      Row()
        .width(24)
        .height(2)
        .backgroundColor(this.currentTab === index ? $r('app.color.mobile_campus_primary_color_default') : Color.Transparent)
        .margin({ top: 3 })
    }
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .height('100%')
    .constraintSize({ maxWidth: 36 }) // tabMaxWidth=72.0dip=36vp
    .padding({ left: 16, right: 16 })
    .onClick(() => {
      this.currentTab = index;
      this.sceneryList = filterSceneryItems(buildSceneryItems(), index);
    })
  }

  /**
   * mobile_campus_school_view_scenery.xml — 风光条目。
   * FrameLayout：ImageView（centerCrop）+ 底部 24vp 半透明黑条（#4D000000）。
   */
  @Builder
  sceneryItem(item: SceneryItem) {
    Stack({ alignContent: Alignment.BottomStart }) {
      // img：fill_parent、scaleType=centerCrop、minWidth=px_to_dip_330=165vp
      Image($r('app.media.mobile_campus_school_default'))
        .width('100%')
        .height(180)
        .objectFit(ImageFit.Cover)
      // 底部 RelativeLayout：bg=#4D000000、height=px_to_dip_48=24vp、paddingLeft/Right=px_to_dip_32=16vp
      Row() {
        // tvLikeNum：drawableLeft=@drawable/mobile_campus_school_like、drawablePadding=8.0dip=8vp、白字、居左居中
        Row() {
          Image($r('app.media.mobile_campus_school_like'))
            .width(16)
            .height(16)
            .objectFit(ImageFit.Contain)
          Text(item.likeNum)
            .fontSize(12)
            .fontColor($r('app.color.white'))
            .margin({ left: 8 }) // drawablePadding=8.0dip=8vp
        }
        .alignItems(VerticalAlign.Center)
        // tvTitle：白字、alignParentRight、centerVertical
        Text(item.title)
          .fontSize(12)
          .fontColor($r('app.color.white'))
      }
      .alignItems(VerticalAlign.Center)
      .width('100%')
      .height(24) // px_to_dip_48/2=24vp
      .padding({ left: 16, right: 16 }) // px_to_dip_32/2=16vp
      .backgroundColor('#4D000000')
    }
    .width('100%')
    .height(180)
    .clip(true)
  }

  build() {
    // mobile_campus_school_activity_scenery.xml 根 LinearLayout vertical（fill_parent）
    Column() {
      // include toolbar_normal
      TitleBar({ title: '校园风光', showBack: true })
      // TabLayout：height=px_to_dip_72=36vp
      Row() {
        this.sceneryTabItem('全部', 0)
        this.sceneryTabItem('教学', 1)
        this.sceneryTabItem('生活', 2)
        this.sceneryTabItem('运动', 3)
      }
      .width('100%')
      .height(36) // px_to_dip_72/2=36vp
      .justifyContent(FlexAlign.Center)
      .backgroundColor($r('app.color.white'))
      // ViewPager → fragment_scenery：RecyclerView padding=7.0dip=7vp
      List() {
        ForEach(this.sceneryList, (item: SceneryItem) => {
          ListItem() {
            this.sceneryItem(item)
          }
        }, (item: SceneryItem) => item.id)
      }
      .width('100%')
      .layoutWeight(1)
      .padding(7) // 7.0dip=7vp
      .backgroundColor($r('app.color.common_color_6'))
      .scrollBar(BarState.Off)
      .divider({ strokeWidth: 7, color: $r('app.color.common_color_6') })
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.white'))
  }
}
