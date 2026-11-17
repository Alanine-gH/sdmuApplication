// 数据源：无服务器接口，页面数据为内置示例数据（离线演示用），未接 ApiService。
import { promptAction } from '@kit.ArkUI';
import { TitleBar } from '../components/TitleBar';

/** 概况条目模型：icon / 名称 / 背景色 / 弹窗结构化文本 */
class SituationEntry {
  icon: Resource;
  name: string;
  bgColor: Resource;
  content: string;

  constructor(icon: Resource, name: string, bgColor: Resource, content: string) {
    this.icon = icon;
    this.name = name;
    this.bgColor = bgColor;
    this.content = content;
  }
}

/** 学校概况内置结构化文本（山东管理学院） */
function buildSituationEntries(): SituationEntry[] {
  const entries: SituationEntry[] = [
    new SituationEntry($r('app.media.mobile_campus_school_w'), '学校介绍',
      $r('app.color.mobile_campus_school_introduction_background_color'),
      '山东管理学院是山东省教育厅主管的全日制普通本科高校，坐落于泉城济南。学校坚持“以学生为中心”的办学理念，形成了以管理学为主体，经济学、工学、文学、艺术学等多学科协调发展的学科格局。\n\n学校现有明水主校区等多个校区，占地面积千余亩，馆藏图书百万余册，建有现代化图书馆、实验实训中心和体育运动场馆，为师生提供了良好的学习生活环境。'),
    new SituationEntry($r('app.media.mobile_campus_school_song'), '校歌',
      $r('app.color.mobile_campus_school_song_background_color'),
      '《山东管理学院校歌》\n\n校歌由学校集体作词作曲，旋律昂扬向上，歌词体现了学校深厚的文化底蕴和师生奋发进取的精神风貌，常在学校重大活动和典礼中演唱。'),
    new SituationEntry($r('app.media.mobile_campus_school_motto'), '校训',
      $r('app.color.mobile_campus_school_motto_background_color'),
      '校训：明德弘毅，博学笃行\n\n“明德”取自《大学》“大学之道，在明明德”，寓意立德修身；“弘毅”取自《论语》“士不可以不弘毅”，寓意志存高远、意志坚强；“博学笃行”语出《中庸》，寓意广博学习、躬身实践。'),
    new SituationEntry($r('app.media.mobile_campus_school_college'), '院系介绍',
      $r('app.color.mobile_campus_school_college_background_color'),
      '学校设有工商管理学院、会计学院、人文学院、经贸学院、信息工程学院、艺术学院、劳动关系学院等多个二级学院，开设本科、专科专业数十个，在校生万余人，专任教师中高级职称比例逐年提升。'),
    new SituationEntry($r('app.media.mobile_campus_school_logo'), '校徽',
      $r('app.color.mobile_campus_school_logo_background_color'),
      '校徽整体呈圆形，中心图案由学校标志性建筑与书本造型构成，外环上方为学校中文名称，下方为英文校名。校徽以蓝色为主色调，象征知识的深邃与育人使命的庄重。'),
    new SituationEntry($r('app.media.mobile_campus_school_history'), '历史沿革',
      $r('app.color.mobile_campus_school_history_background_color'),
      '学校办学历史可追溯至二十世纪，历经干部培训、成人教育、高等职业教育等办学阶段，后经山东省人民政府批准设立为普通本科高校，定名山东管理学院。\n\n多年来，学校坚持应用型人才培养定位，不断深化教育教学改革，办学水平与社会声誉稳步提升。')
  ];
  return entries;
}

/**
 * 学校概况页 — 按反编译布局 1:1 复刻 mobile_campus_school_activity_situation.xml：
 *   LinearLayout vertical（fill_parent）
 *   - include toolbar_normal（标题“学校概况”）
 *   - school_image_view：height=px_to_dip_280=140vp、scaleType=fitXY
 *   - 行1（weight 0.5）：school_introdection（weight 1.2、bg=#537DE3）+ school_song（weight 0.7、bg=#C2C2C2）
 *     + school_motto（weight 0.8、bg=#DAC267）
 *   - 行2（weight 0.7）：school_college（weight 2.0、bg=#CFAF6B）+ school_logo（weight 0.8、bg=#7CA7D3）
 *   - 行3（weight 1.0）：school_history（bg=#B6B6B6、通栏）
 *   单元格：FrameLayout gravity=center → ImageView 18.0dip=18vp + TextView（font_size_2=px_to_sp_34=17fp、白字、
 *   marginLeft=px_to_dip_16=8vp）；单元格间 marginLeft=px_to_dip_16=8vp、marginTop=px_to_dip_16=8vp。
 */
@Entry
@Component
struct SchoolSituationPage {
  @State entryList: SituationEntry[] = buildSituationEntries();

  /** 单元格：FrameLayout(bgColor) gravity=center → 图标 18vp + 白字 17fp（marginLeft=px_to_dip_16=8vp） */
  @Builder
  situationCell(entry: SituationEntry) {
    Row() {
      Image(entry.icon)
        .width(18) // 18.0dip=18vp
        .height(18) // 18.0dip=18vp
        .objectFit(ImageFit.Contain)
      Text(entry.name)
        .fontSize(17) // font_size_2=px_to_sp_34=17fp
        .fontColor($r('app.color.white'))
        .margin({ left: 8 }) // px_to_dip_16/2=8vp
    }
    .justifyContent(FlexAlign.Center)
    .alignItems(VerticalAlign.Center)
    .width('100%')
    .height('100%')
    .backgroundColor(entry.bgColor)
    .onClick(() => {
      promptAction.showDialog({
        title: entry.name,
        message: entry.content
      });
    })
  }

  build() {
    // mobile_campus_school_activity_situation.xml 根 LinearLayout vertical（fill_parent）
    Column() {
      // include toolbar_normal
      TitleBar({ title: '学校概况', showBack: true })
      // school_image_view：height=px_to_dip_280=140vp、scaleType=fitXY
      Image($r('app.media.mobile_campus_top'))
        .width('100%')
        .height(140) // px_to_dip_280/2=140vp
        .objectFit(ImageFit.Fill)
      // 行1（weight 0.5）：introdection(1.2) + song(0.7) + motto(0.8)
      Row() {
        Row() {
          this.situationCell(this.entryList[0])
        }
        .layoutWeight(12) // layout_weight=1.2
        .height('100%')
        .margin({ left: 8 }) // px_to_dip_16/2=8vp

        Row() {
          this.situationCell(this.entryList[1])
        }
        .layoutWeight(7) // layout_weight=0.7
        .height('100%')
        .margin({ left: 8 }) // px_to_dip_16/2=8vp

        Row() {
          this.situationCell(this.entryList[2])
        }
        .layoutWeight(8) // layout_weight=0.8
        .height('100%')
        .margin({ left: 8, right: 8 }) // px_to_dip_16/2=8vp
      }
      .width('100%')
      .layoutWeight(5) // 行高 weight=0.5
      .margin({ top: 8 }) // px_to_dip_16/2=8vp
      // 行2（weight 0.7）：college(2.0) + logo(0.8)
      Row() {
        Row() {
          this.situationCell(this.entryList[3])
        }
        .layoutWeight(20) // layout_weight=2.0
        .height('100%')
        .margin({ left: 8 }) // px_to_dip_16/2=8vp

        Row() {
          this.situationCell(this.entryList[4])
        }
        .layoutWeight(8) // layout_weight=0.8
        .height('100%')
        .margin({ left: 8, right: 8 }) // px_to_dip_16/2=8vp
      }
      .width('100%')
      .layoutWeight(7) // 行高 weight=0.7
      .margin({ top: 8 }) // px_to_dip_16/2=8vp
      // 行3（weight 1.0）：history 通栏
      Row() {
        this.situationCell(this.entryList[5])
      }
      .width('100%')
      .layoutWeight(10) // 行高 weight=1.0
      .margin({ left: 8, right: 8, top: 8, bottom: 8 }) // px_to_dip_16/2=8vp
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.main_bg'))
  }
}
